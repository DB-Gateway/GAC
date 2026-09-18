<?php

namespace Tests\Feature;

use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use App\Notifications\ChecklistDraftReminder;
use App\Services\DraftFollowUpService;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DraftChecklistReminderTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo('2026-09-10 10:00:00');
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_gm_and_bom_warning_opens_the_draft_review_modal(): void
    {
        [$owner, $gm, $bom] = $this->users();
        $this->saveDraft($owner);
        foreach ([$gm, $bom] as $manager) {
            $this->actingAs($manager)->get(route('dashboard'))->assertOk()
                ->assertViewHas('notifications', fn ($alerts): bool => $alerts->contains(fn ($alert): bool => data_get($alert, 'action.target') === 'draftReminderModal'))
                ->assertSee('data-notification-action-target="draftReminderModal"', false)
                ->assertSee('Unfinished checklist drafts')
                ->assertSee('Send mobile reminder');
            $this->get(route('checklists.index', ['checklist' => 'sales']))->assertOk()
                ->assertSee('data-notification-action-target="draftReminderModal"', false);
        }
        $this->actingAs($owner)->get(route('dashboard'))->assertOk()->assertDontSee('id="draftReminderModal"', false);
    }

    public function test_gm_sees_all_drafts_and_bom_sees_only_its_branch_with_saved_question_details(): void
    {
        [$owner, $gm, $bom, $otherOwner] = $this->users();
        $draft = $this->saveDraft($owner);
        $otherDraft = $this->saveDraft($otherOwner);
        $items = $draft->template->sections()->with('items')->get()->flatMap->items;
        $this->actingAs($bom)->getJson(route('notifications.drafts.index'))->assertOk()
            ->assertJsonCount(1, 'drafts')
            ->assertJsonPath('drafts.0.id', $draft->id)
            ->assertJsonPath('drafts.0.user_name', $owner->name)
            ->assertJsonPath('drafts.0.audit_date', '2026-08-29')
            ->assertJsonPath('drafts.0.item_key', $items[1]->key)
            ->assertJsonPath('drafts.0.position_label', 'Saved at question')
            ->assertJsonPath('drafts.0.answered_count', 1)
            ->assertJsonPath('drafts.0.total_count', 44)
            ->assertJsonPath('drafts.0.can_remind', true)
            ->assertJsonMissing(['id' => $otherDraft->id]);
        $this->actingAs($gm)->getJson(route('notifications.drafts.index'))->assertOk()->assertJsonCount(2, 'drafts');
    }

    public function test_both_manager_roles_can_send_a_reminder_only_to_the_owner_in_the_mobile_inbox(): void
    {
        [$owner, $gm, $bom, $otherOwner] = $this->users();
        $draft = $this->saveDraft($owner);
        foreach ([$gm, $bom] as $manager) {
            $this->actingAs($manager)->postJson(route('notifications.drafts.remind', $draft))
                ->assertCreated()->assertJsonPath('already_sent', false);
            $notification = $owner->notifications()->latest()->firstOrFail();
            $this->assertSame(ChecklistDraftReminder::class, $notification->type);
            $this->assertSame($manager->id, $notification->data['requested_by_user_id']);
            $this->assertSame($draft->id, $notification->data['submission_id']);
            $this->assertSame('sales', $notification->data['template_slug']);
            $this->assertSame('2026-08-29', $notification->data['audit_date']);
            $this->assertSame(data_get($draft->context, 'draft_position.item_key'), $notification->data['item_key']);
            $this->assertNull($notification->read_at);
            $this->travel(61)->seconds();
        }
        Sanctum::actingAs($owner);
        $this->getJson(route('api.notifications.index'))->assertOk()
            ->assertJsonCount(2, 'notifications')
            ->assertJsonPath('notifications.0.type', 'checklist_draft_reminder')
            ->assertJsonPath('notifications.0.data.submission_id', $draft->id);
        $this->assertCount(0, $otherOwner->notifications()->get());
        $this->assertCount(0, $gm->notifications()->get());
    }

    public function test_other_users_and_other_branch_boms_cannot_send_or_view_draft_reminders(): void
    {
        [$owner, $gm, $bom, $otherOwner] = $this->users();
        $draft = $this->saveDraft($otherOwner);
        $this->actingAs($owner)->getJson(route('notifications.drafts.index'))->assertForbidden();
        $this->postJson(route('notifications.drafts.remind', $draft))->assertForbidden();
        $this->actingAs($bom)->postJson(route('notifications.drafts.remind', $draft))->assertForbidden();
        $this->assertDatabaseCount('notifications', 0);
    }

    public function test_submitted_deleted_or_inaccessible_drafts_cannot_receive_reminders(): void
    {
        [$owner, $gm] = $this->users();
        $draft = $this->saveDraft($owner);
        $owner->update(['account_status' => 'inactive']);
        $this->actingAs($gm)->postJson(route('notifications.drafts.remind', $draft))->assertUnprocessable();
        $owner->update(['account_status' => 'active']);
        $draft->update(['status' => 'submitted']);
        $this->postJson(route('notifications.drafts.remind', $draft))->assertConflict();
        $this->getJson(route('notifications.drafts.index'))->assertOk()->assertJsonCount(0, 'drafts');
        $draft->delete();
        $this->postJson(route('notifications.drafts.remind', $draft->id))->assertNotFound();
        $this->assertDatabaseCount('notifications', 0);
    }

    public function test_repeated_clicks_do_not_create_duplicate_reminders(): void
    {
        [$owner, $gm, $bom] = $this->users();
        $draft = $this->saveDraft($owner);
        $this->actingAs($gm)->postJson(route('notifications.drafts.remind', $draft))->assertCreated();
        $this->actingAs($bom)->postJson(route('notifications.drafts.remind', $draft))->assertOk()->assertJsonPath('already_sent', true);
        $this->assertDatabaseCount('notifications', 1);
        $this->getJson(route('notifications.drafts.index'))->assertOk()
            ->assertJsonPath('drafts.0.last_reminded_at', fn ($value): bool => is_string($value));
    }

    public function test_older_drafts_use_the_next_unanswered_question_when_no_saved_position_exists(): void
    {
        [$owner] = $this->users();
        $draft = $this->saveDraft($owner);
        $draft->update(['context' => ['draft_position' => ['item_key' => 'removed-item']]]);
        $details = app(DraftFollowUpService::class)->details($draft);
        $this->assertSame('Next unanswered question', $details['position_label']);
        $this->assertSame($draft->template->sections()->with('items')->get()->flatMap->items[1]->key, $details['item_key']);
    }

    public function test_dos_progress_counts_only_questions_assigned_to_the_draft_owner(): void
    {
        $owner = User::factory()->create(['user_type' => User::ROLE_AFTERSALES_MANAGER, 'branch' => 'Pasong Tamo']);
        $template = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $allowed = $template->sections()->with('items')->get()->flatMap->items->filter(fn ($item) => $owner->canAccessChecklistItem($template->slug, data_get($item->metadata, 'checker')))->values();
        $response = $this->actingAs($owner)->postJson(route('checklists.save-draft', $template), [
            'date' => '2026-09-10',
            'responses' => [['item_id' => $allowed[0]->id, 'status' => 'yes']],
        ])->assertCreated();
        $details = app(DraftFollowUpService::class)->details(ChecklistSubmission::findOrFail($response->json('submission.id')));
        $this->assertSame($allowed->count(), $details['total_count']);
        $this->assertSame(1, $details['answered_count']);
        $this->assertSame($allowed[1]->key, $details['item_key']);
    }

    public function test_only_the_most_recent_draft_is_returned_when_user_name_and_user_type_match(): void
    {
        [$owner, $gm, $bom] = $this->users();
        $olderDraft = $this->saveDraft($owner);

        $this->travel(10)->minutes();
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $items = $template->sections()->with('items')->get()->flatMap->items;
        $response = $this->actingAs($owner)->postJson(route('checklists.save-draft', $template), [
            'date' => '2026-08-30',
            'responses' => [
                ['item_id' => $items[0]->id, 'status' => 'yes'],
                ['item_id' => $items[1]->id, 'status' => 'yes'],
            ],
            'context' => ['draft_position' => ['item_key' => $items[2]->key]],
        ])->assertCreated();
        $newerDraft = ChecklistSubmission::findOrFail($response->json('submission.id'));

        // Both drafts exist in the database for the same user name and user_type
        $this->assertDatabaseCount('checklist_submissions', 2);

        // API should return only the 1 most recent draft for that user and user_type
        $this->actingAs($bom)->getJson(route('notifications.drafts.index'))
            ->assertOk()
            ->assertJsonCount(1, 'drafts')
            ->assertJsonPath('drafts.0.id', $newerDraft->id)
            ->assertJsonPath('drafts.0.user_name', $owner->name)
            ->assertJsonPath('drafts.0.user_type', $owner->roleCode())
            ->assertJsonMissing(['id' => $olderDraft->id]);

        // Dashboard notification alert count should also be 1
        $this->actingAs($bom)->get(route('dashboard'))
            ->assertOk()
            ->assertSee('1 checklist draft is unfinished');
    }

    private function users(): array
    {
        return [
            User::factory()->create(['name' => 'Sales Auditor', 'user_type' => User::ROLE_5S_SALES, 'branch' => 'Pasong Tamo']),
            User::factory()->create(['user_type' => User::ROLE_ADMINISTRATOR, 'branch' => 'Pasong Tamo']),
            User::factory()->create(['user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER, 'branch' => 'Pasong Tamo']),
            User::factory()->create(['user_type' => User::ROLE_5S_SALES, 'branch' => 'Cebu']),
        ];
    }

    private function saveDraft(User $owner): ChecklistSubmission
    {
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $items = $template->sections()->with('items')->get()->flatMap->items;
        $response = $this->actingAs($owner)->postJson(route('checklists.save-draft', $template), [
            'date' => '2026-08-29',
            'responses' => [['item_id' => $items[0]->id, 'status' => 'yes']],
            'context' => ['draft_position' => ['item_key' => $items[1]->key]],
        ])->assertCreated();

        return ChecklistSubmission::findOrFail($response->json('submission.id'));
    }
}
