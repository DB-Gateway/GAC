<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistResponse;
use App\Models\ChecklistSection;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DebugResetChecklistAnswersTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_navigation_renders_debug_button_and_reset_checklist_control(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $response = $this->actingAs($user)->get(route('dashboard'));

        $response->assertOk();
        $response->assertSee('id="debugDropdown"', false);
        $response->assertSee('Debug', false);
        $response->assertSee('id="sidebarDebugResetBtn"', false);
        $response->assertSee('Reset Checklist', false);
        $response->assertSee('id="debugResetModalOverlay"', false);
        $response->assertSee('Debug: Reset Checklist Answers', false);
        $response->assertSee('Only checklist answers', false);
    }

    public function test_debug_reset_clears_only_answers_for_specific_checklist_and_preserves_templates_and_items(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $template5s = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $templateDos = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();

        $item5s = $template5s->items()->firstOrFail();
        $itemDos = $templateDos->items()->firstOrFail();

        // Save a submission for 5S
        $submission5s = ChecklistSubmission::create([
            'checklist_template_id' => $template5s->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => $template5s->version,
            'template_snapshot' => [],
        ]);

        ChecklistResponse::create([
            'checklist_submission_id' => $submission5s->id,
            'checklist_item_id' => $item5s->id,
            'item_key' => $item5s->key,
            'status' => 'yes',
            'item_snapshot' => [],
        ]);

        // Save a submission for DOS
        $submissionDos = ChecklistSubmission::create([
            'checklist_template_id' => $templateDos->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => $templateDos->version,
            'template_snapshot' => [],
        ]);

        ChecklistResponse::create([
            'checklist_submission_id' => $submissionDos->id,
            'checklist_item_id' => $itemDos->id,
            'item_key' => $itemDos->key,
            'status' => 'no',
            'item_snapshot' => [],
        ]);

        $initialTemplatesCount = ChecklistTemplate::count();
        $initialSectionsCount = ChecklistSection::count();
        $initialItemsCount = ChecklistItem::count();
        $initialUsersCount = User::count();

        $this->assertSame(2, ChecklistSubmission::count());
        $this->assertSame(2, ChecklistResponse::count());

        // Perform debug reset targeting gateway-5s only
        $response = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'gateway-5s',
            'scope' => 'all',
        ]);

        $response->assertOk();
        $response->assertJsonPath('stats.deleted_submissions', 1);
        $response->assertJsonPath('stats.deleted_responses', 1);
        $response->assertJsonPath('stats.templates_preserved', true);

        // Gateway 5S submissions and responses are wiped
        $this->assertDatabaseMissing('checklist_submissions', ['id' => $submission5s->id]);
        $this->assertSame(1, ChecklistSubmission::count());
        $this->assertSame(1, ChecklistResponse::count());

        // DOS submission and response still exist intact
        $this->assertDatabaseHas('checklist_submissions', ['id' => $submissionDos->id]);

        // Master structure and users remain completely untouched
        $this->assertSame($initialTemplatesCount, ChecklistTemplate::count());
        $this->assertSame($initialSectionsCount, ChecklistSection::count());
        $this->assertSame($initialItemsCount, ChecklistItem::count());
        $this->assertSame($initialUsersCount, User::count());
    }

    public function test_debug_reset_all_checklists_clears_all_answers_and_preserves_templates_and_items(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $template5s = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $templateDos = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();

        $item5s = $template5s->items()->firstOrFail();
        $itemDos = $templateDos->items()->firstOrFail();

        $submission5s = ChecklistSubmission::create([
            'checklist_template_id' => $template5s->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'draft',
            'template_version' => $template5s->version,
            'template_snapshot' => [],
        ]);

        ChecklistResponse::create([
            'checklist_submission_id' => $submission5s->id,
            'checklist_item_id' => $item5s->id,
            'item_key' => $item5s->key,
            'status' => 'yes',
            'item_snapshot' => [],
        ]);

        $submissionDos = ChecklistSubmission::create([
            'checklist_template_id' => $templateDos->id,
            'user_id' => $user->id,
            'branch' => 'San Fernando',
            'scope_key' => 'san-fernando',
            'audit_date' => '2026-09-08',
            'status' => 'submitted',
            'template_version' => $templateDos->version,
            'template_snapshot' => [],
        ]);

        ChecklistResponse::create([
            'checklist_submission_id' => $submissionDos->id,
            'checklist_item_id' => $itemDos->id,
            'item_key' => $itemDos->key,
            'status' => 'no',
            'item_snapshot' => [],
        ]);

        $initialTemplatesCount = ChecklistTemplate::count();
        $initialSectionsCount = ChecklistSection::count();
        $initialItemsCount = ChecklistItem::count();
        $initialUsersCount = User::count();

        // Perform debug reset for 'all' checklists
        $response = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'all',
            'scope' => 'all',
        ]);

        $response->assertOk();
        $response->assertJsonPath('stats.deleted_submissions', 2);
        $response->assertJsonPath('stats.deleted_responses', 2);
        $response->assertJsonPath('stats.templates_preserved', true);

        // All submission answers are cleared
        $this->assertSame(0, ChecklistSubmission::count());
        $this->assertSame(0, ChecklistResponse::count());

        // Master structure and users remain completely untouched
        $this->assertSame($initialTemplatesCount, ChecklistTemplate::count());
        $this->assertSame($initialSectionsCount, ChecklistSection::count());
        $this->assertSame($initialItemsCount, ChecklistItem::count());
        $this->assertSame($initialUsersCount, User::count());
    }

    public function test_debug_reset_scoped_to_current_branch_and_date_only_deletes_matching_submission(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $item = $template->items()->firstOrFail();

        $sub1 = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => $template->version,
            'template_snapshot' => [],
        ]);
        ChecklistResponse::create([
            'checklist_submission_id' => $sub1->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'yes',
            'item_snapshot' => [],
        ]);

        $sub2 = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-08',
            'status' => 'submitted',
            'template_version' => $template->version,
            'template_snapshot' => [],
        ]);
        ChecklistResponse::create([
            'checklist_submission_id' => $sub2->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'yes',
            'item_snapshot' => [],
        ]);

        $response = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'gateway-5s',
            'scope' => 'current',
            'date' => '2026-09-09',
            'branch' => 'Pasong Tamo',
        ]);

        $response->assertOk();
        $response->assertJsonPath('stats.deleted_submissions', 1);

        $this->assertDatabaseMissing('checklist_submissions', ['id' => $sub1->id]);
        $this->assertDatabaseHas('checklist_submissions', ['id' => $sub2->id]);
    }

    public function test_unauthenticated_request_cannot_reset_answers(): void
    {
        $this->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'all',
        ])->assertUnauthorized();
    }
}
