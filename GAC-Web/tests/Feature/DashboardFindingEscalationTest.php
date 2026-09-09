<?php

namespace Tests\Feature;

use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class DashboardFindingEscalationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo('2026-08-29 10:00:00');
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_gm_and_branch_bom_can_open_selected_audit_findings_with_checker_reason_and_photo(): void
    {
        [$submission, $finding] = $this->createNoFinding();
        $bom = User::factory()->create([
            'name' => 'Brenda BOM',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);
        $gm = User::factory()->create([
            'name' => 'George GM',
            'user_type' => 'GM',
            'branch' => 'Cebu',
        ]);

        foreach ([$bom, $gm] as $manager) {
            $page = $this->actingAs($manager)->get(route('dashboard', [
                'form' => 'sales',
                'branch' => 'Pasong Tamo',
                'submission_id' => $submission->id,
            ]));

            $page
                ->assertOk()
                ->assertViewHas('summarySheet', function (array $summary) use ($finding): bool {
                    $row = $summary['nonCompliantFindings']->first();

                    return $summary['canManageFindings'] === true
                        && $summary['cards']['count_no'] === 1
                        && $summary['nonCompliantFindings']->count() === 1
                        && $row['response_id'] === $finding->id
                        && $row['checked_by_name'] === 'Sally Checker'
                        && $row['checker_role'] === 'SALES MANAGER'
                        && $row['finding'] === 'Showroom directional sign is damaged.'
                        && $row['attachment_url'] === Storage::disk('public')->url('checklist-attachments/sign.jpg')
                        && $row['recommended_escalation'] === 'MARKETING / PURCHASING';
                })
                ->assertSee('data-summary-modal-target="summaryFindingsModal"', false)
                ->assertSee('data-summary-modal-target="summaryEscalationModal"', false)
                ->assertSee('Showroom directional sign is damaged.')
                ->assertSee('Sally Checker')
                ->assertSee('View full photo')
                ->assertSee('value="marketing_purchasing"', false)
                ->assertSee('value="mmpc_training_team"', false)
                ->assertDontSee('value="as_brand_head"', false);
        }
    }

    public function test_critical_notification_opens_the_selected_no_findings_table(): void
    {
        [$submission] = $this->createNoFinding();
        $manager = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($manager)
            ->get(route('dashboard', [
                'form' => 'sales',
                'branch' => 'Pasong Tamo',
                'submission_id' => $submission->id,
            ]))
            ->assertOk()
            ->assertSee('data-notification-action-target="summaryFindingsModal"', false)
            ->assertSee('View NO findings')
            ->assertSee('summary-card-action summary-card-action-secondary', false);
    }

    public function test_escalation_choices_match_the_sales_and_aftersales_workbooks(): void
    {
        $sales = ChecklistResponse::escalationTargetOptionsFor('dealer-operations-standards-sales');
        $aftersales = ChecklistResponse::escalationTargetOptionsFor('dealer-operations-standards');

        $this->assertSame([
            'bom',
            'ce_central',
            'central_admin',
            'dnd',
            'general_manager',
            'general_manager_ce_central',
            'inventory',
            'it',
            'logistic',
            'marketing',
            'marketing_purchasing',
            'marketing_property_management',
            'mmpc_cs_team',
            'mmpc_training_team',
            'n_a',
            'property_management',
            'purchasing',
        ], array_keys($sales));
        $this->assertSame([
            'as_brand_head',
            'as_head',
            'brand_head',
            'ce_central',
            'general_manager',
        ], array_keys($aftersales));
        $this->assertSame('general_manager_ce_central', ChecklistResponse::normalizeEscalationTarget("GENERAL MANAGER\nCE CENTRAL"));
        $this->assertSame('marketing_property_management', ChecklistResponse::normalizeEscalationTarget('MARKETINGPM'));
        $this->assertSame('marketing_purchasing', ChecklistResponse::normalizeEscalationTarget('MARKETING / PURCHASING'));
        $this->assertSame('as_brand_head', ChecklistResponse::normalizeEscalationTarget('AS BRAND HEAD'));
    }

    public function test_non_manager_cannot_see_manager_finding_details_or_escalation_controls(): void
    {
        [$submission] = $this->createNoFinding();
        $pic = User::factory()->create([
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($pic)
            ->get(route('dashboard', [
                'form' => 'sales',
                'submission_id' => $submission->id,
            ]))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['canManageFindings'] === false
                && $summary['nonCompliantFindings']->isEmpty())
            ->assertDontSee('data-summary-modal-target="summaryFindingsModal"', false)
            ->assertDontSee('data-summary-modal-target="summaryEscalationModal"', false)
            ->assertDontSee('Showroom directional sign is damaged.');
    }

    public function test_manager_can_assign_escalation_without_changing_the_no_result(): void
    {
        [$submission, $finding] = $this->createNoFinding();
        $gm = User::factory()->create([
            'name' => 'George GM',
            'user_type' => 'GM',
            'branch' => 'Cebu',
        ]);

        $this->actingAs($gm)->patchJson(route('reports.responses.escalations'), [
            'responses' => [[
                'id' => $finding->id,
                'escalation_target' => 'AS BRAND HEAD',
            ]],
        ])->assertUnprocessable()
            ->assertJsonPath('message', 'The selected escalation recipient is not available for this checklist.');

        $result = $this->actingAs($gm)->patchJson(route('reports.responses.escalations'), [
            'responses' => [[
                'id' => $finding->id,
                'escalation_target' => 'MARKETING / PURCHASING',
            ]],
        ]);

        $result
            ->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('updated_count', 1)
            ->assertJsonPath('responses.0.id', $finding->id)
            ->assertJsonPath('responses.0.escalation_target', 'marketing_purchasing');

        $finding->refresh();
        $this->assertSame('no', $finding->status);
        $this->assertSame('marketing_purchasing', $finding->escalation_target);
        $this->assertSame('marketing_purchasing', data_get($finding->details, 'escalation'));
        $this->assertSame('George GM', data_get($finding->details, 'escalation_assignment.assigned_by_name'));
        $this->assertFalse($finding->isOverridden());

        $submission->refresh();
        $this->assertSame(1, $submission->scores['no']);
        $this->assertSame(0, $submission->scores['yes']);

        $this->assertDatabaseHas('reports', [
            'type' => 'checklist_response_escalation',
            'generated_by_user_id' => $gm->id,
            'checklist_submission_id' => $submission->id,
        ]);
    }

    public function test_escalation_endpoint_enforces_manager_branch_scope_and_no_status(): void
    {
        [, $finding] = $this->createNoFinding(branch: 'Cebu');
        $otherBranchBom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);
        $pic = User::factory()->create([
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'branch' => 'Cebu',
        ]);
        $gm = User::factory()->create([
            'user_type' => 'GM',
            'branch' => 'Pasong Tamo',
        ]);
        $payload = [
            'responses' => [[
                'id' => $finding->id,
                'escalation_target' => 'IT',
            ]],
        ];

        $this->actingAs($otherBranchBom)
            ->patchJson(route('reports.responses.escalations'), $payload)
            ->assertForbidden();
        $this->actingAs($pic)
            ->patchJson(route('reports.responses.escalations'), $payload)
            ->assertForbidden();

        $finding->update(['status' => 'yes']);

        $this->actingAs($gm)
            ->patchJson(route('reports.responses.escalations'), $payload)
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Only responses currently marked NO can be escalated.');

        $this->assertNull($finding->fresh()->escalation_target);
    }

    public function test_manager_can_use_an_aftersales_workbook_escalation_recipient(): void
    {
        [, $finding] = $this->createNoFinding(templateSlug: 'dealer-operations-standards');
        $gm = User::factory()->create([
            'user_type' => 'GM',
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($gm)
            ->patchJson(route('reports.responses.escalations'), [
                'responses' => [[
                    'id' => $finding->id,
                    'escalation_target' => 'AS BRAND HEAD',
                ]],
            ])
            ->assertOk()
            ->assertJsonPath('responses.0.escalation_target', 'as_brand_head');

        $this->assertSame('no', $finding->fresh()->status);
        $this->assertSame('as_brand_head', $finding->fresh()->escalation_target);
    }

    public function test_bom_can_assign_an_escalation_for_its_own_branch(): void
    {
        [, $finding] = $this->createNoFinding();
        $bom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($bom)
            ->patchJson(route('reports.responses.escalations'), [
                'responses' => [[
                    'id' => $finding->id,
                    'escalation_target' => 'CE CENTRAL',
                ]],
            ])
            ->assertOk()
            ->assertJsonPath('responses.0.escalation_target', 'ce_central');

        $this->assertSame('no', $finding->fresh()->status);
        $this->assertSame('ce_central', $finding->fresh()->escalation_target);
    }

    public function test_bulk_escalation_is_rejected_atomically_when_one_finding_is_outside_bom_scope(): void
    {
        [, $ownFinding] = $this->createNoFinding();
        [, $otherFinding] = $this->createNoFinding(branch: 'Cebu');
        $bom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($bom)
            ->patchJson(route('reports.responses.escalations'), [
                'responses' => [
                    ['id' => $ownFinding->id, 'escalation_target' => 'BOM'],
                    ['id' => $otherFinding->id, 'escalation_target' => 'BOM'],
                ],
            ])
            ->assertForbidden();

        $this->assertNull($ownFinding->fresh()->escalation_target);
        $this->assertNull($otherFinding->fresh()->escalation_target);
        $this->assertDatabaseMissing('reports', ['type' => 'checklist_response_escalation']);
    }

    /**
     * @return array{0: ChecklistSubmission, 1: ChecklistResponse}
     */
    private function createNoFinding(
        string $branch = 'Pasong Tamo',
        string $templateSlug = 'dealer-operations-standards-sales'
    ): array {
        $template = ChecklistTemplate::query()
            ->where('slug', $templateSlug)
            ->firstOrFail();
        $item = $template->items()->with('section')->firstOrFail();
        $checker = User::factory()->create([
            'name' => 'Sally Checker',
            'user_type' => User::ROLE_SALES_MANAGER,
            'branch' => $branch,
        ]);
        $submission = ChecklistSubmission::query()->create([
            'checklist_template_id' => $template->id,
            'user_id' => $checker->id,
            'submitted_by_user_id' => $checker->id,
            'submitted_by_name' => $checker->name,
            'submitted_by_email' => $checker->email,
            'submitted_by_user_type' => $checker->user_type,
            'status' => 'submitted',
            'branch' => $branch,
            'scope_key' => hash('sha256', mb_strtolower($branch)),
            'audit_date' => '2026-08-20',
            'template_version' => $template->version,
            'context' => ['auditor' => $checker->name, 'branch' => $branch],
            'template_snapshot' => ['slug' => $template->slug, 'name' => $template->name],
            'scores' => [
                'total' => 1,
                'answered' => 1,
                'yes' => 0,
                'no' => 1,
                'na' => 0,
                'applicable' => 1,
                'percentage' => 0,
            ],
            'submitted_at' => now(),
        ]);
        $metadata = array_merge($item->metadata ?? [], [
            'number' => 1,
            'coverage' => 'Facilities',
            'checker' => 'SALES MANAGER',
            'pic' => 'GM',
            'escalation' => 'MARKETING / PURCHASING',
        ]);
        $finding = ChecklistResponse::query()->create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'finding' => 'Showroom directional sign is damaged.',
            'action_plan' => 'Replace the damaged sign.',
            'attachment_path' => 'checklist-attachments/sign.jpg',
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'sort_order' => $item->sort_order,
                'metadata' => $metadata,
                'section' => [
                    'title' => $item->section->title,
                    'sort_order' => $item->section->sort_order,
                ],
            ],
        ]);

        return [$submission, $finding];
    }
}
