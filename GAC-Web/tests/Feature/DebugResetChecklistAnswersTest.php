<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistResponse;
use App\Models\ChecklistSection;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\BranchRestroom;
use App\Models\DealerChecklistSetting;
use App\Models\Report;
use App\Models\User;
use App\Notifications\ChecklistDraftReminder;
use App\Notifications\FindingFollowUpRequested;
use App\Notifications\PicTaskCompleted;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
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
        $response->assertSee('id="sidebarDebugResetDatabaseBtn"', false);
        $response->assertSee('Reset Database Data', false);
        $response->assertSee('Reset Checklist', false);
        $response->assertSee('id="sidebarDebugResetDraftsBtn"', false);
        $response->assertSee('Reset Drafts', false);
        $response->assertSee('id="sidebarDebugResetSubformsBtn"', false);
        $response->assertSee('Reset Subforms', false);
        $response->assertSee('id="sidebarDebugResetDocumentationBtn"', false);
        $response->assertSee('Reset Documentation', false);
        $response->assertSee('id="sidebarDebugResetNotificationsBtn"', false);
        $response->assertSee('Reset Notifications', false);
        $response->assertSee('name="debugResetTarget"', false);
        $response->assertSee('value="drafts"', false);
        $response->assertSee('value="subforms"', false);
        $response->assertSee('value="documentation"', false);
        $response->assertSee('value="notifications"', false);
        $response->assertSee('value="database"', false);
        $response->assertSee('name="include_notifications"', false);
        $response->assertSee('dealer-operations-standards-subform', false);
        $response->assertSee('dealer-operations-standards-documentation', false);
        $response->assertSee('id="debugResetModalOverlay"', false);
        $response->assertSee('Debug: Reset Checklist Answers', false);
        $response->assertSee('Only checklist answers', false);

        $this->actingAs($user)
            ->get(route('checklists.index', ['checklist' => 'sales']))
            ->assertOk()
            ->assertSee('<option value="all" selected>All Checklists (All Types)</option>', false)
            ->assertSee('<option value="sales">Current Checklist (Sales)</option>', false);
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

    public function test_debug_reset_all_ignores_page_date_and_clears_every_5s_checklist(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $submissions = collect(['gateway-5s', 'sales', 'service', 'restroom'])
            ->map(function (string $slug) use ($user): ChecklistSubmission {
                $template = ChecklistTemplate::where('slug', $slug)->firstOrFail();
                $item = $template->items()->firstOrFail();
                $submission = ChecklistSubmission::create([
                    'checklist_template_id' => $template->id,
                    'user_id' => $user->id,
                    'branch' => 'Pasong Tamo',
                    'scope_key' => 'pasong-tamo',
                    'audit_date' => $slug === 'sales' ? '2026-09-25' : '2026-09-24',
                    'status' => 'submitted',
                    'template_version' => $template->version,
                    'template_snapshot' => [],
                ]);

                ChecklistResponse::create([
                    'checklist_submission_id' => $submission->id,
                    'checklist_item_id' => $item->id,
                    'item_key' => $item->key,
                    'status' => 'yes',
                    'item_snapshot' => [],
                ]);

                return $submission;
            });

        $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'all',
            'scope' => 'all',
            'target' => 'all',
            'date' => '2026-09-25',
            'branch' => 'Pasong Tamo',
        ])->assertOk()
            ->assertJsonPath('stats.deleted_submissions', 4)
            ->assertJsonPath('stats.deleted_responses', 4);

        foreach ($submissions as $submission) {
            $this->assertDatabaseMissing('checklist_submissions', ['id' => $submission->id]);
        }
    }

    public function test_debug_database_reset_clears_operational_tables_and_preserves_users_and_dropdown_data(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $item = $template->items()->firstOrFail();
        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-25',
            'status' => 'submitted',
            'template_version' => $template->version,
            'template_snapshot' => [],
        ]);
        ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'yes',
            'item_snapshot' => [],
        ]);
        Report::create([
            'type' => 'export',
            'title' => 'Detached historical export',
            'data_snapshot' => [],
            'generated_at' => now(),
        ]);
        DB::table('notifications')->insert([
            'id' => (string) Str::uuid(),
            'type' => 'OtherSystemNotification',
            'notifiable_type' => User::class,
            'notifiable_id' => $user->id,
            'data' => '{}',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('user_usage_events')->insert([
            'user_id' => $user->id,
            'channel' => 'web',
            'event' => 'login',
            'occurred_at' => now(),
        ]);
        DB::table('jobs')->insert([
            'queue' => 'default', 'payload' => '{}', 'attempts' => 0,
            'available_at' => time(), 'created_at' => time(),
        ]);
        DB::table('job_batches')->insert([
            'id' => 'test-batch', 'name' => 'test', 'total_jobs' => 1,
            'pending_jobs' => 1, 'failed_jobs' => 0,
            'failed_job_ids' => '[]', 'created_at' => time(),
        ]);
        DB::table('failed_jobs')->insert([
            'uuid' => (string) Str::uuid(), 'connection' => 'database',
            'queue' => 'default', 'payload' => '{}', 'exception' => 'test',
        ]);
        DB::table('cache')->insert(['key' => 'test', 'value' => 'cached', 'expiration' => time() + 3600]);
        DB::table('cache_locks')->insert(['key' => 'test', 'owner' => 'test', 'expiration' => time() + 3600]);
        DB::table('sessions')->insert([
            'id' => 'preserved-session', 'user_id' => $user->id,
            'payload' => 'test', 'last_activity' => time(),
        ]);

        $restroom = BranchRestroom::create([
            'branch' => 'Pasong Tamo', 'name' => 'Test Restroom',
        ]);
        $setting = DealerChecklistSetting::create([
            'dealer' => 'Pasong Tamo',
            'category' => DealerChecklistSetting::CATEGORY_5S_SALES,
            'is_enabled' => true,
            'updated_by_user_id' => $user->id,
        ]);
        $templateCount = ChecklistTemplate::count();
        $sectionCount = ChecklistSection::count();
        $itemCount = ChecklistItem::count();

        $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'target' => 'database',
            'template' => 'sales',
            'scope' => 'current',
            'date' => '2026-09-25',
        ])->assertOk()
            ->assertJsonPath('stats.deleted_by_table.checklist_submissions', 1)
            ->assertJsonPath('stats.deleted_by_table.reports', 1)
            ->assertJsonPath('stats.deleted_by_table.notifications', 1);

        foreach (['reports', 'checklist_responses', 'checklist_submissions', 'notifications',
            'user_usage_events', 'jobs', 'job_batches', 'failed_jobs', 'cache_locks', 'cache'] as $table) {
            $this->assertSame(0, DB::table($table)->count(), $table);
        }

        $this->assertDatabaseHas('users', ['id' => $user->id]);
        $this->assertDatabaseHas('sessions', ['id' => 'preserved-session']);
        $this->assertDatabaseHas('branch_restrooms', ['id' => $restroom->id]);
        $this->assertDatabaseHas('dealer_checklist_settings', ['id' => $setting->id]);
        $this->assertSame($templateCount, ChecklistTemplate::count());
        $this->assertSame($sectionCount, ChecklistSection::count());
        $this->assertSame($itemCount, ChecklistItem::count());
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

    public function test_debug_reset_can_target_only_drafts_and_preserve_submitted_records(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $item = $template->items()->firstOrFail();

        $draft = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'draft',
            'template_version' => $template->version,
            'template_snapshot' => [],
        ]);
        ChecklistResponse::create([
            'checklist_submission_id' => $draft->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'yes',
            'item_snapshot' => [],
        ]);

        $submitted = ChecklistSubmission::create([
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
            'checklist_submission_id' => $submitted->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'item_snapshot' => [],
        ]);

        $this->assertSame(2, ChecklistSubmission::count());
        $this->assertSame(2, ChecklistResponse::count());

        $response = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'gateway-5s',
            'scope' => 'all',
            'target' => 'drafts',
        ]);

        $response->assertOk();
        $response->assertJsonPath('stats.deleted_submissions', 1);
        $response->assertJsonPath('stats.deleted_drafts', 1);
        $response->assertJsonPath('stats.deleted_submitted', 0);
        $response->assertJsonPath('stats.deleted_responses', 1);
        $response->assertJsonPath('stats.templates_preserved', true);

        // Draft submission is gone
        $this->assertDatabaseMissing('checklist_submissions', ['id' => $draft->id]);
        // Submitted submission is still present
        $this->assertDatabaseHas('checklist_submissions', ['id' => $submitted->id]);
        $this->assertSame(1, ChecklistSubmission::count());
        $this->assertSame(1, ChecklistResponse::count());
    }

    public function test_debug_reset_can_target_only_submitted_and_preserve_drafts(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $item = $template->items()->firstOrFail();

        $draft = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'draft',
            'template_version' => $template->version,
            'template_snapshot' => [],
        ]);
        ChecklistResponse::create([
            'checklist_submission_id' => $draft->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'yes',
            'item_snapshot' => [],
        ]);

        $submitted = ChecklistSubmission::create([
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
            'checklist_submission_id' => $submitted->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'item_snapshot' => [],
        ]);

        $response = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'gateway-5s',
            'scope' => 'all',
            'target' => 'submitted',
        ]);

        $response->assertOk();
        $response->assertJsonPath('stats.deleted_submissions', 1);
        $response->assertJsonPath('stats.deleted_drafts', 0);
        $response->assertJsonPath('stats.deleted_submitted', 1);

        // Submitted record is gone
        $this->assertDatabaseMissing('checklist_submissions', ['id' => $submitted->id]);
        // Draft is still present
        $this->assertDatabaseHas('checklist_submissions', ['id' => $draft->id]);
        $this->assertSame(1, ChecklistSubmission::count());
        $this->assertSame(1, ChecklistResponse::count());
    }

    public function test_debug_reset_drafts_cleans_up_associated_draft_reminder_notifications(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $draft = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'draft',
            'template_version' => $template->version,
            'template_snapshot' => [],
        ]);

        DB::table('notifications')->insert([
            'id' => (string) Str::uuid(),
            'type' => ChecklistDraftReminder::class,
            'notifiable_type' => User::class,
            'notifiable_id' => $user->id,
            'data' => json_encode([
                'submission_id' => $draft->id,
                'message' => 'Finish your drafted checklist',
            ]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->assertSame(1, DB::table('notifications')->where('type', ChecklistDraftReminder::class)->count());

        $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'gateway-5s',
            'scope' => 'all',
            'target' => 'drafts',
        ])->assertOk();

        $this->assertDatabaseMissing('checklist_submissions', ['id' => $draft->id]);
        $this->assertSame(0, DB::table('notifications')->where('type', ChecklistDraftReminder::class)->count());
    }

    public function test_debug_reset_scoped_to_current_branch_and_date_with_drafts_target(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();

        $draftCurrent = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'draft',
            'template_version' => $template->version,
            'template_snapshot' => [],
        ]);

        $draftOtherDate = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-08',
            'status' => 'draft',
            'template_version' => $template->version,
            'template_snapshot' => [],
        ]);

        $submittedCurrent = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => $template->version,
            'template_snapshot' => [],
        ]);

        $response = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'gateway-5s',
            'scope' => 'current',
            'target' => 'drafts',
            'date' => '2026-09-09',
            'branch' => 'Pasong Tamo',
        ]);

        $response->assertOk();
        $response->assertJsonPath('stats.deleted_drafts', 1);
        $response->assertJsonPath('stats.deleted_submitted', 0);

        $this->assertDatabaseMissing('checklist_submissions', ['id' => $draftCurrent->id]);
        $this->assertDatabaseHas('checklist_submissions', ['id' => $draftOtherDate->id]);
        $this->assertDatabaseHas('checklist_submissions', ['id' => $submittedCurrent->id]);
    }

    public function test_debug_reset_all_also_clears_task_completion_and_follow_up_notifications_history(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $item = $template->items()->firstOrFail();

        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => $template->version,
            'template_snapshot' => ['slug' => 'gateway-5s', 'name' => 'Gateway 5S'],
        ]);

        $response = ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'item_snapshot' => ['prompt' => 'Item prompt'],
        ]);

        $notif1Id = (string) Str::uuid();
        DB::table('notifications')->insert([
            'id' => $notif1Id,
            'type' => PicTaskCompleted::class,
            'notifiable_type' => User::class,
            'notifiable_id' => $user->id,
            'data' => json_encode([
                'submission_id' => $submission->id,
                'template_slug' => 'gateway-5s',
                'event' => 'pic_task_completed',
            ]),
            'read_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $notif2Id = (string) Str::uuid();
        DB::table('notifications')->insert([
            'id' => $notif2Id,
            'type' => FindingFollowUpRequested::class,
            'notifiable_type' => User::class,
            'notifiable_id' => $user->id,
            'data' => json_encode([
                'submission_id' => $submission->id,
                'response_id' => $response->id,
                'template_slug' => 'gateway-5s',
                'archived_at' => now()->toIso8601String(),
            ]),
            'read_at' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->assertSame(2, DB::table('notifications')->count());

        $resetResponse = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'gateway-5s',
            'scope' => 'all',
            'target' => 'all',
            'include_notifications' => true,
        ]);

        $resetResponse->assertOk();
        $resetResponse->assertJsonPath('stats.deleted_submissions', 1);
        $resetResponse->assertJsonPath('stats.deleted_notifications', 2);

        $this->assertDatabaseMissing('checklist_submissions', ['id' => $submission->id]);
        $this->assertDatabaseMissing('checklist_responses', ['id' => $response->id]);
        $this->assertDatabaseMissing('notifications', ['id' => $notif1Id]);
        $this->assertDatabaseMissing('notifications', ['id' => $notif2Id]);
    }

    public function test_debug_reset_can_target_only_notification_history_without_deleting_checklist_submissions(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $item = $template->items()->firstOrFail();

        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => $template->version,
            'template_snapshot' => ['slug' => 'gateway-5s', 'name' => 'Gateway 5S'],
        ]);

        $response = ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'item_snapshot' => ['prompt' => 'Item prompt'],
        ]);

        $notifId = (string) Str::uuid();
        DB::table('notifications')->insert([
            'id' => $notifId,
            'type' => PicTaskCompleted::class,
            'notifiable_type' => User::class,
            'notifiable_id' => $user->id,
            'data' => json_encode([
                'submission_id' => $submission->id,
                'template_slug' => 'gateway-5s',
                'event' => 'pic_task_completed',
            ]),
            'read_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $resetResponse = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'gateway-5s',
            'scope' => 'all',
            'target' => 'notifications',
        ]);

        $resetResponse->assertOk();
        $resetResponse->assertJsonPath('stats.deleted_submissions', 0);
        $resetResponse->assertJsonPath('stats.deleted_responses', 0);
        $resetResponse->assertJsonPath('stats.deleted_notifications', 1);

        $this->assertDatabaseHas('checklist_submissions', ['id' => $submission->id]);
        $this->assertDatabaseHas('checklist_responses', ['id' => $response->id]);
        $this->assertDatabaseMissing('notifications', ['id' => $notifId]);
    }

    public function test_debug_reset_can_exclude_notification_history_when_specified(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();

        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => $template->version,
            'template_snapshot' => ['slug' => 'gateway-5s', 'name' => 'Gateway 5S'],
        ]);

        $notifId = (string) Str::uuid();
        DB::table('notifications')->insert([
            'id' => $notifId,
            'type' => PicTaskCompleted::class,
            'notifiable_type' => User::class,
            'notifiable_id' => $user->id,
            'data' => json_encode([
                'submission_id' => $submission->id,
                'template_slug' => 'gateway-5s',
            ]),
            'read_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $resetResponse = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'gateway-5s',
            'scope' => 'all',
            'target' => 'submitted',
            'include_notifications' => false,
        ]);

        $resetResponse->assertOk();
        $resetResponse->assertJsonPath('stats.deleted_submissions', 1);
        $resetResponse->assertJsonPath('stats.deleted_notifications', 0);

        $this->assertDatabaseMissing('checklist_submissions', ['id' => $submission->id]);
        $this->assertDatabaseHas('notifications', ['id' => $notifId]);
    }

    public function test_debug_reset_can_target_subforms_and_clear_both_standalone_and_embedded_responses(): void
    {
        $migration = require database_path('migrations/2026_09_07_001100_create_dos_subform_and_documentation_templates.php');
        $ref = new \ReflectionClass($migration);
        $seedSubform = $ref->getMethod('seedSubformTemplate');
        $seedSubform->setAccessible(true);
        $seedSubform->invoke($migration);

        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $subformTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards-subform')->firstOrFail();
        $dosTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $subItem = $subformTemplate->sections->flatMap->items->firstOrFail();
        $dosItem23 = $dosTemplate->sections->flatMap->items->firstWhere('key', 'dos-as-23')
            ?? $dosTemplate->sections->flatMap->items->first();

        // 1. Standalone subform submission
        $standaloneSubform = ChecklistSubmission::create([
            'checklist_template_id' => $subformTemplate->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => $subformTemplate->version,
            'template_snapshot' => [],
        ]);
        ChecklistResponse::create([
            'checklist_submission_id' => $standaloneSubform->id,
            'checklist_item_id' => $subItem->id,
            'item_key' => $subItem->key,
            'status' => 'yes',
            'item_snapshot' => [],
        ]);

        // 2. DOS submission with embedded subform answers
        $dosSubmission = ChecklistSubmission::create([
            'checklist_template_id' => $dosTemplate->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => $dosTemplate->version,
            'template_snapshot' => [],
        ]);
        $dosResp23 = ChecklistResponse::create([
            'checklist_submission_id' => $dosSubmission->id,
            'checklist_item_id' => $dosItem23->id,
            'item_key' => $dosItem23->key,
            'status' => 'yes',
            'item_snapshot' => [],
            'details' => [
                'subform_answers' => [
                    'subform-sr-1' => 'yes',
                    'subform-sr-2' => 'no',
                ],
                'eligibility' => 'show_subform',
            ],
        ]);

        $this->assertSame(2, ChecklistSubmission::count());

        // Perform debug reset targeting subforms
        $resetResponse = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'dealer-operations-standards-subform',
            'scope' => 'all',
            'target' => 'subforms',
        ]);

        $resetResponse->assertOk();
        $resetResponse->assertJsonPath('stats.deleted_submissions', 1);
        $resetResponse->assertJsonPath('stats.cleared_embedded_subforms', 1);

        // Standalone subform submission is deleted
        $this->assertDatabaseMissing('checklist_submissions', ['id' => $standaloneSubform->id]);

        // DOS submission is preserved, but embedded subform answers are cleared
        $this->assertDatabaseHas('checklist_submissions', ['id' => $dosSubmission->id]);
        $freshResp23 = $dosResp23->fresh();
        $this->assertArrayNotHasKey('subform_answers', (array) ($freshResp23->details ?? []));
        $this->assertArrayNotHasKey('eligibility', (array) ($freshResp23->details ?? []));
        $this->assertNull($freshResp23->status);
    }

    public function test_debug_reset_can_target_documentation_and_clear_both_standalone_and_embedded_samples(): void
    {
        $migration = require database_path('migrations/2026_09_07_001100_create_dos_subform_and_documentation_templates.php');
        $ref = new \ReflectionClass($migration);
        $seedDoc = $ref->getMethod('seedDocumentationTemplate');
        $seedDoc->setAccessible(true);
        $seedDoc->invoke($migration);

        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $docTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards-documentation')->firstOrFail();
        $dosTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $docItem = $docTemplate->sections->flatMap->items->firstOrFail();
        $dosItem61 = $dosTemplate->sections->flatMap->items->firstWhere('key', 'dos-as-61')
            ?? $dosTemplate->sections->flatMap->items->last();

        // 1. Standalone doc submission
        $standaloneDoc = ChecklistSubmission::create([
            'checklist_template_id' => $docTemplate->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => $docTemplate->version,
            'template_snapshot' => [],
        ]);
        ChecklistResponse::create([
            'checklist_submission_id' => $standaloneDoc->id,
            'checklist_item_id' => $docItem->id,
            'item_key' => $docItem->key,
            'status' => 'yes',
            'item_snapshot' => [],
        ]);

        // 2. DOS submission with embedded documentation samples
        $dosSubmission = ChecklistSubmission::create([
            'checklist_template_id' => $dosTemplate->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => $dosTemplate->version,
            'template_snapshot' => [],
            'context' => [
                'documentation_samples' => [
                    ['ro_number' => 'RO-1001', 'answers' => []],
                ],
            ],
        ]);
        $dosResp61 = ChecklistResponse::create([
            'checklist_submission_id' => $dosSubmission->id,
            'checklist_item_id' => $dosItem61->id,
            'item_key' => $dosItem61->key,
            'status' => 'yes',
            'item_snapshot' => [],
            'details' => [
                'documentation_samples' => [
                    ['ro_number' => 'RO-1001', 'answers' => ['doc-rc-1' => 'yes']],
                ],
                'documentation_answers' => ['doc-rc-1' => 'yes'],
            ],
        ]);

        $this->assertSame(2, ChecklistSubmission::count());

        // Perform debug reset targeting documentation
        $resetResponse = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'dealer-operations-standards-documentation',
            'scope' => 'all',
            'target' => 'documentation',
        ]);

        $resetResponse->assertOk();
        $resetResponse->assertJsonPath('stats.deleted_submissions', 1);
        $resetResponse->assertJsonPath('stats.cleared_embedded_documentation', 1);

        // Standalone documentation submission is deleted
        $this->assertDatabaseMissing('checklist_submissions', ['id' => $standaloneDoc->id]);

        // DOS submission is preserved, but embedded documentation samples and context are cleared
        $this->assertDatabaseHas('checklist_submissions', ['id' => $dosSubmission->id]);
        $freshDosSub = $dosSubmission->fresh();
        $this->assertArrayNotHasKey('documentation_samples', (array) ($freshDosSub->context ?? []));

        $freshResp61 = $dosResp61->fresh();
        $this->assertArrayNotHasKey('documentation_samples', (array) ($freshResp61->details ?? []));
        $this->assertArrayNotHasKey('documentation_answers', (array) ($freshResp61->details ?? []));
        $this->assertNull($freshResp61->status);
    }

    public function test_debug_reset_all_on_dos_resets_standalone_subforms_and_documentation(): void
    {
        $migration = require database_path('migrations/2026_09_07_001100_create_dos_subform_and_documentation_templates.php');
        $ref = new \ReflectionClass($migration);
        $seedSubform = $ref->getMethod('seedSubformTemplate');
        $seedSubform->setAccessible(true);
        $seedSubform->invoke($migration);
        $seedDoc = $ref->getMethod('seedDocumentationTemplate');
        $seedDoc->setAccessible(true);
        $seedDoc->invoke($migration);

        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $dosTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $subformTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards-subform')->firstOrFail();
        $docTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards-documentation')->firstOrFail();

        $subDos = ChecklistSubmission::create([
            'checklist_template_id' => $dosTemplate->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => 1,
            'template_snapshot' => [],
        ]);

        $subSubform = ChecklistSubmission::create([
            'checklist_template_id' => $subformTemplate->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => 1,
            'template_snapshot' => [],
        ]);

        $subDoc = ChecklistSubmission::create([
            'checklist_template_id' => $docTemplate->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'scope_key' => 'pasong-tamo',
            'audit_date' => '2026-09-09',
            'status' => 'submitted',
            'template_version' => 1,
            'template_snapshot' => [],
        ]);

        $this->assertSame(3, ChecklistSubmission::count());

        // Reset DOS checklist
        $resetResponse = $this->actingAs($user)->postJson(route('debug.checklists.reset-answers'), [
            'template' => 'dealer-operations-standards',
            'scope' => 'all',
            'target' => 'all',
        ]);

        $resetResponse->assertOk();
        $resetResponse->assertJsonPath('stats.deleted_submissions', 3);
        $this->assertSame(0, ChecklistSubmission::count());
    }
}
