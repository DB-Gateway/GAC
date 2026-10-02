<?php

namespace Tests\Feature;

use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class OverrideWorkspaceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo('2026-09-10 10:00:00');
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_each_checklist_switch_shows_only_its_no_answers(): void
    {
        $manager = $this->manager();
        $slugs = ['sales', 'service', 'dealer-operations-standards-sales', 'dealer-operations-standards', 'restroom'];
        $noAnswers = [];
        foreach ($slugs as $slug) {
            $noAnswers[$slug] = $this->finding($slug);
            $this->finding($slug, answer: 'yes');
            $this->finding($slug, answer: 'na');
            $resolved = $this->finding($slug, answer: 'yes');
            $resolved->update(['details' => ['override' => ['reason' => 'Resolved already']]]);
        }

        foreach ($slugs as $slug) {
            $page = $this->actingAs($manager)->get(route('dashboard', ['tab' => 'override', 'checklist' => $slug]));
            $page->assertOk()
                ->assertViewHas('activeTab', 'override')
                ->assertViewHas('selectedOverrideChecklist', $slug)
                ->assertViewHas('reportFindings', fn ($findings) => $findings->pluck('response_id')->all() === [$noAnswers[$slug]->id])
                ->assertSee('id="overrideDropdown" open', false)
                ->assertSee('class="checklist-workspace-switcher"', false)
                ->assertSee('role="tablist"', false)
                ->assertSee('role="tab"', false)
                ->assertSee('aria-selected="true"', false)
                ->assertSee('fa-car-side', false)
                ->assertSee('fa-screwdriver-wrench', false)
                ->assertSee('fa-clipboard-check', false)
                ->assertSee('fa-restroom', false)
                ->assertSee('<span class="checklist-workspace-count has-issues">1</span>', false)
                ->assertSee('data-endpoint="'.route('reports.responses.override', $noAnswers[$slug]).'"', false)
                ->assertSee('Override / Edit')
                ->assertDontSee('aria-label="Report breakdowns"', false)
                ->assertDontSee('Resolved already');

            foreach ($slugs as $switchSlug) {
                $page->assertSee('data-override-checklist="'.$switchSlug.'"', false);
            }
        }
    }

    public function test_filters_and_checklist_switches_preserve_the_selected_context(): void
    {
        $expected = $this->finding('sales', branch: 'Cebu', auditDate: '2026-08-20');
        $this->finding('sales', branch: 'Pasong Tamo', auditDate: '2026-08-20');
        $this->finding('sales', branch: 'Cebu', auditDate: '2026-09-10');
        $this->finding('sales', branch: 'Cebu', auditDate: '2026-08-20', auditStatus: 'draft');

        $this->actingAs($this->manager())->get(route('dashboard', [
            'tab' => 'override', 'checklist' => 'sales', 'branch' => 'Cebu', 'month' => '2026-08', 'status' => 'submitted',
            'template' => 'service',
        ]))->assertOk()
            ->assertViewHas('reportFindings', fn ($findings) => $findings->pluck('response_id')->all() === [$expected->id])
            ->assertSee(e(route('dashboard', [
                'tab' => 'override', 'checklist' => 'service', 'branch' => 'Cebu', 'month' => '2026-08', 'status' => 'submitted',
            ])), false);
    }

    public function test_bom_can_only_view_no_answers_in_their_assigned_branch(): void
    {
        $expected = $this->finding('sales');
        $this->finding('sales', branch: 'Cebu');
        $bom = $this->manager(User::ROLE_BRANCH_OPERATIONS_MANAGER);

        $this->actingAs($bom)->get(route('dashboard', ['tab' => 'override', 'checklist' => 'sales']))
            ->assertOk()
            ->assertViewHas('reportFindings', fn ($findings) => $findings->pluck('response_id')->all() === [$expected->id])
            ->assertDontSee('Cebu');

        $this->get(route('dashboard', ['tab' => 'override', 'checklist' => 'sales', 'branch' => 'Cebu']))
            ->assertOk()
            ->assertViewHas('reportFindings', fn ($findings) => $findings->isEmpty());

        $bom->update(['branch' => null]);
        $this->get(route('dashboard', ['tab' => 'override', 'checklist' => 'sales']))
            ->assertForbidden();
    }

    public function test_override_tab_requires_manager_access(): void
    {
        $this->get(route('dashboard', ['tab' => 'override']))->assertRedirect(route('login'));

        $pic = User::factory()->create([
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);
        $this->actingAs($pic)->get(route('dashboard'))->assertOk()->assertDontSee('id="overrideDropdown"', false);
        $this->get(route('dashboard', ['tab' => 'override', 'checklist' => 'sales']))->assertForbidden();
    }

    public function test_unknown_checklist_is_rejected_and_default_selection_has_an_empty_state(): void
    {
        $this->actingAs($this->manager())->getJson(route('dashboard', ['tab' => 'override', 'checklist' => 'unknown']))
            ->assertUnprocessable()->assertJsonValidationErrors('checklist');

        $this->get(route('dashboard', ['tab' => 'override']))
            ->assertOk()
            ->assertViewHas('selectedOverrideChecklist', 'dealer-operations-standards')
            ->assertSee('Aftersales DOS NO Answers')
            ->assertSee('Zero Flagged NO Answers for Selected Filters');
    }

    public function test_saved_override_leaves_the_no_table_and_remains_in_reports_with_its_audit_history(): void
    {
        $finding = $this->finding('sales');
        $manager = $this->manager();
        $this->actingAs($manager)->patchJson(route('reports.responses.override', $finding), [
            'status' => 'yes',
            'action_plan' => 'Replace and verify the damaged sign.',
            'finding' => 'Replacement verified on site.',
            'escalation_target' => 'property_management',
            'commitment_date' => '2026-09-12T14:30',
            'override_reason' => 'Verified by the manager.',
        ])->assertOk()->assertJsonPath('response.status', 'yes');

        $this->get(route('dashboard', ['tab' => 'override', 'checklist' => 'sales']))
            ->assertOk()
            ->assertViewHas('reportFindings', fn ($findings) => $findings->isEmpty());

        $this->get(route('reports.index', ['template' => 'sales']))
            ->assertOk()
            ->assertSee('Replacement verified on site.')
            ->assertSee('Verified by the manager.');

        $this->assertDatabaseHas('reports', [
            'type' => 'checklist_response_override',
            'checklist_submission_id' => $finding->checklist_submission_id,
            'generated_by_user_id' => $manager->id,
        ]);
    }

    public function test_archived_and_edited_no_answers_remain_available(): void
    {
        $finding = $this->finding('service');
        $finding->submission->update(['checklist_template_id' => null]);
        $finding->update(['details' => ['override' => ['reason' => 'Action plan updated']]]);

        $this->actingAs($this->manager())->get(route('dashboard', ['tab' => 'override', 'checklist' => 'service']))
            ->assertOk()
            ->assertViewHas('reportFindings', fn ($findings) => $findings->pluck('response_id')->all() === [$finding->id])
            ->assertSee('Action plan updated');
    }

    public function test_manager_can_override_finding_with_proof_attachment_and_timestamp_tracked(): void
    {
        Storage::fake('public');
        $finding = $this->finding('sales');
        $manager = $this->manager();

        $proofFile = UploadedFile::fake()->createWithContent('rectification_proof.png', base64_decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aDa8AAAAASUVORK5CYII='
        ));

        $response = $this->actingAs($manager)->post(route('reports.responses.override', $finding), [
            '_method' => 'PATCH',
            'status' => 'yes',
            'override_reason' => 'Rectified and verified with attached proof on-site.',
            'action_plan' => 'Completed immediate fix.',
            'proof' => $proofFile,
        ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('response.status', 'yes')
            ->assertJsonPath('response.override_details.overridden_by_name', $manager->name)
            ->assertJsonPath('response.override_details.overridden_at_formatted', '10 Sep 2026, 06:00 PM');

        $storedPath = $response->json('response.override_details.attachment_path');
        $storedUrl = $response->json('response.override_details.attachment_url');
        $this->assertNotNull($storedPath);
        $this->assertNotNull($storedUrl);
        Storage::disk('public')->assertExists($storedPath);

        // Reports view shows the override timestamp and proof attached
        $this->get(route('reports.index', ['template' => 'sales']))
            ->assertOk()
            ->assertSee('10 Sep 2026, 06:00 PM')
            ->assertSee('Rectified and verified with attached proof on-site.')
            ->assertSee('Proof Attached')
            ->assertSee($storedUrl);

        // Export findings CSV contains the override date and proof attachment link
        $csvResponse = $this->get(route('reports.export.findings', [
            'template' => 'sales',
        ]));
        $csvResponse->assertOk();
        $this->assertStringContainsString('Override Proof Attachment', $csvResponse->streamedContent());
        $this->assertStringContainsString('10 Sep 2026, 06:00 PM', $csvResponse->streamedContent());
        $this->assertStringContainsString($storedUrl, $csvResponse->streamedContent());

        // Report audit record includes override timestamp and attachment info
        $this->assertDatabaseHas('reports', [
            'type' => 'checklist_response_override',
            'checklist_submission_id' => $finding->checklist_submission_id,
            'generated_by_user_id' => $manager->id,
        ]);
    }

    public function test_override_workspace_renders_escalation_helpers_for_administrator_and_bom(): void
    {
        $this->finding('sales');

        foreach ([User::ROLE_ADMINISTRATOR, User::ROLE_BRANCH_OPERATIONS_MANAGER] as $role) {
            $user = $this->manager($role);
            $response = $this->actingAs($user)->get(route('dashboard', [
                'tab' => 'override',
                'checklist' => 'sales',
                'month' => '2026-09',
            ]));

            $response->assertOk()
                ->assertSee('function resolveEscalationOptions', false)
                ->assertSee('function populateEscalationSelect', false)
                ->assertSee('function openOverrideModal', false);
        }
    }

    private function manager(string $role = User::ROLE_ADMINISTRATOR): User
    {
        return User::factory()->create([
            'user_type' => $role,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);
    }

    private function finding(
        string $slug,
        string $answer = 'no',
        string $branch = 'Pasong Tamo',
        string $auditDate = '2026-09-10',
        string $auditStatus = 'submitted',
    ): ChecklistResponse {
        $template = ChecklistTemplate::where('slug', $slug)->firstOrFail();
        $item = $template->items()->firstOrFail();
        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'status' => $auditStatus,
            'branch' => $branch,
            'scope_key' => hash('sha256', strtolower($branch)),
            'audit_date' => $auditDate,
            'template_version' => $template->version,
            'template_snapshot' => ['slug' => $slug, 'name' => $template->name],
            'submitted_at' => $auditStatus === 'submitted' ? now() : null,
        ]);

        return ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => $answer,
            'finding' => $slug.' '.$answer.' finding',
            'item_snapshot' => ['key' => $item->key, 'prompt' => $item->prompt],
        ]);
    }
}
