<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistTemplate;
use App\Models\User;
use App\Notifications\PicTaskCompleted;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TaskCompletionNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo('2026-08-29 14:30:00');
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_pic_submission_notifies_the_gm_and_same_branch_bom_only_once(): void
    {
        [$pic, $gm, $bom, $otherBranchBom, $inactiveBom] = $this->users();
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $payload = $this->submissionPayload($template);

        $first = $this->actingAs($pic)
            ->postJson(route('checklists.submit', $template), $payload)
            ->assertCreated()
            ->assertJsonPath('submission.status', 'submitted');

        $this->assertDatabaseCount('notifications', 2);
        $this->assertCount(1, $gm->notifications()->get());
        $this->assertCount(1, $bom->notifications()->get());
        $this->assertCount(0, $otherBranchBom->notifications()->get());
        $this->assertCount(0, $inactiveBom->notifications()->get());
        $this->assertCount(0, $pic->notifications()->get());

        foreach ([$gm, $bom] as $recipient) {
            $notification = $recipient->notifications()->sole();

            $this->assertSame(PicTaskCompleted::class, $notification->type);
            $this->assertNull($notification->read_at);
            $this->assertSame('pic_task_completed', $notification->data['event']);
            $this->assertSame($first->json('submission.id'), $notification->data['submission_id']);
            $this->assertSame($pic->id, $notification->data['completed_by_user_id']);
            $this->assertSame('Pasong Tamo', $notification->data['branch']);
            $this->assertSame('Pasong Tamo', $notification->data['completed_by_branch']);
            $this->assertSame(User::ROLE_PERSON_IN_CHARGE, $notification->data['completed_by_role']);
            $this->assertNull($notification->data['standards_type']);
        }

        $this->actingAs($pic)
            ->postJson(route('checklists.submit', $template), $payload)
            ->assertOk()
            ->assertJsonPath('message', 'This checklist was already submitted.');

        $this->assertDatabaseCount('notifications', 2);
    }

    public function test_view_status_is_isolated_to_the_specific_gm_or_bom_recipient(): void
    {
        [$pic, $gm, $bom] = $this->users();
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();

        $this->actingAs($pic)
            ->postJson(route('checklists.submit', $template), $this->submissionPayload($template))
            ->assertCreated();

        $gmNotification = $gm->notifications()->sole();
        $bomNotification = $bom->notifications()->sole();

        $this->actingAs($gm)
            ->patchJson(route('notifications.mark-viewed', $gmNotification->id))
            ->assertOk()
            ->assertJsonPath('status', 'viewed')
            ->assertJsonPath('id', $gmNotification->id);

        $this->assertNotNull($gmNotification->fresh()->read_at);
        $this->assertNull($bomNotification->fresh()->read_at);

        $this->actingAs($bom)
            ->patchJson(route('notifications.mark-viewed', $gmNotification->id))
            ->assertNotFound();

        $this->actingAs($pic)
            ->patchJson(route('notifications.mark-viewed', $bomNotification->id))
            ->assertForbidden();
    }

    public function test_manager_dashboard_shows_and_marks_its_own_task_notifications_viewed(): void
    {
        [$pic, $gm, $bom] = $this->users();
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();

        $this->actingAs($pic)
            ->postJson(route('checklists.submit', $template), $this->submissionPayload($template))
            ->assertCreated();

        $this->actingAs($gm)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('canReceiveTaskNotifications', true)
            ->assertViewHas('unreadTaskNotificationCount', 1)
            ->assertViewHas('taskNotifications', fn ($notifications): bool => $notifications->count() === 1)
            ->assertSee('id="notificationsBadge"', false)
            ->assertSee('PIC task completed')
            ->assertSee('View Task')
            ->assertSee('Not viewed');

        $this->actingAs($gm)
            ->patchJson(route('notifications.mark-all-viewed'))
            ->assertOk()
            ->assertJsonPath('marked_count', 1);

        $this->actingAs($gm)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('unreadTaskNotificationCount', 0)
            ->assertDontSee('id="notificationsBadge"', false)
            ->assertSee('Viewed');

        $this->assertNull($bom->notifications()->sole()->read_at);

        $this->actingAs($pic)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('canReceiveTaskNotifications', false)
            ->assertViewHas('taskNotifications', fn ($notifications): bool => $notifications->isEmpty())
            ->assertDontSee('PIC task completions');
    }

    public function test_manager_checklist_editor_tabs_show_notification_badge_and_modal(): void
    {
        [$pic, $gm] = $this->users();
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();

        $this->actingAs($pic)
            ->postJson(route('checklists.submit', $template), $this->submissionPayload($template))
            ->assertCreated();

        foreach (['sales', 'service', 'dealer-operations-standards-sales', 'dealer-operations-standards', 'restroom'] as $checklist) {
            $response = $this->actingAs($gm)->get(route('checklists.index', ['checklist' => $checklist]));

            $response
                ->assertOk()
                ->assertSee('id="notificationsBtn"', false)
                ->assertSee('id="notificationsBadge"', false)
                ->assertSee('id="notificationsModal"', false)
                ->assertSee('PIC task completed')
                ->assertSee('Not viewed');
        }

        $this->actingAs($gm)
            ->patchJson(route('notifications.mark-all-viewed'))
            ->assertOk()
            ->assertJsonPath('marked_count', 1);

        $this->actingAs($gm)
            ->get(route('checklists.index', ['checklist' => 'sales']))
            ->assertOk()
            ->assertSee('Viewed');
    }

    /**
     * @return array{User, User, User, User, User}
     */
    private function users(): array
    {
        return [
            User::factory()->create([
                'name' => 'Gateway PIC',
                'branch' => 'Pasong Tamo',
                'user_type' => User::ROLE_PERSON_IN_CHARGE,
                'pic_assignment_type' => User::PIC_ASSIGNMENT_SALES_SERVICE,
            ]),
            User::factory()->create([
                'name' => 'General Manager',
                'branch' => 'Pasong Tamo',
                'user_type' => User::ROLE_ADMINISTRATOR,
            ]),
            User::factory()->create([
                'name' => 'Pasong Tamo BOM',
                'branch' => 'Pasong Tamo',
                'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            ]),
            User::factory()->create([
                'name' => 'Cebu BOM',
                'branch' => 'Cebu',
                'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            ]),
            User::factory()->create([
                'name' => 'Inactive BOM',
                'branch' => 'Pasong Tamo',
                'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
                'account_status' => 'inactive',
            ]),
        ];
    }

    /**
     * @return array{date: string, responses: array<int, array{item_id: int, status: string}>}
     */
    private function submissionPayload(ChecklistTemplate $template): array
    {
        return [
            'date' => '2026-08-29',
            'responses' => $template->items()
                ->orderBy('id')
                ->get()
                ->map(fn (ChecklistItem $item): array => [
                    'item_id' => $item->id,
                    'status' => 'yes',
                ])
                ->all(),
        ];
    }
}
