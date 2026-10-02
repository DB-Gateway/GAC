<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use App\Notifications\PicTaskCompleted;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
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

    public function test_each_mobile_five_s_user_notifies_the_gm_and_same_branch_bom(): void
    {
        [, $gm, $bom, $otherBranchBom, $inactiveBom] = $this->users();
        $otherBranchGm = User::factory()->create([
            'branch' => 'Cebu',
            'user_type' => User::ROLE_GENERAL_MANAGER,
            'account_status' => 'active',
        ]);
        $otherBranchAdmin = User::factory()->create([
            'branch' => 'Cebu',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
        $unassignedAdmin = User::factory()->create([
            'branch' => null,
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
        $this->travelTo('2026-08-29 18:30:00');

        $checklists = [
            [User::ROLE_5S_SALES, 'sales', 'sales', 'Sales'],
            [User::ROLE_5S_SERVICE, 'service', 'service', 'Service'],
            [User::ROLE_5S_UTILITIES, 'restroom', 'restroom', 'Utilities'],
        ];

        foreach ($checklists as $index => [$role, $slug, $area, $label]) {
            $fiveSUser = User::factory()->create([
                'name' => "{$label} 5S User",
                'branch' => 'Pasong Tamo',
                'user_type' => $role,
                'account_status' => 'active',
            ]);
            $template = ChecklistTemplate::where('slug', $slug)->firstOrFail();

            Sanctum::actingAs($fiveSUser);
            $response = $this->postJson(
                route('api.checklists.submit', $template),
                $this->fiveSSubmissionPayload($template)
            )
                ->assertCreated()
                ->assertJsonPath('submission.status', 'submitted');

            foreach ([$gm, $bom] as $recipient) {
                $notification = $recipient->notifications()
                    ->get()
                    ->first(fn ($record): bool => data_get($record->data, 'submission_id') === $response->json('submission.id'));

                $this->assertNotNull($notification);

                $this->assertSame('five_s_checklist_submitted', $notification->data['event']);
                $this->assertSame("{$label} 5S checklist submitted", $notification->data['title']);
                $this->assertSame($response->json('submission.id'), $notification->data['submission_id']);
                $this->assertSame($fiveSUser->id, $notification->data['completed_by_user_id']);
                $this->assertSame($role, $notification->data['completed_by_role']);
                $this->assertSame('five_s', $notification->data['standards_type']);
                $this->assertSame($area, $notification->data['five_s_area']);
            }

            $this->assertCount($index + 1, $gm->notifications()->get());
            $this->assertCount($index + 1, $bom->notifications()->get());
            $this->assertCount(0, $fiveSUser->notifications()->get());
        }

        $this->assertCount(0, $otherBranchBom->notifications()->get());
        $this->assertCount(0, $otherBranchGm->notifications()->get());
        $this->assertCount(0, $otherBranchAdmin->notifications()->get());
        $this->assertCount(0, $unassignedAdmin->notifications()->get());
        $this->assertCount(0, $inactiveBom->notifications()->get());
        $this->assertDatabaseCount('notifications', 6);
    }

    public function test_viewing_a_five_s_notification_opens_the_matching_summary(): void
    {
        [, $gm] = $this->users();
        $fiveSUser = User::factory()->create([
            'name' => 'Service 5S User',
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_5S_SERVICE,
            'account_status' => 'active',
        ]);
        $template = ChecklistTemplate::where('slug', 'service')->firstOrFail();

        Sanctum::actingAs($fiveSUser);
        $submissionResponse = $this->postJson(
            route('api.checklists.submit', $template),
            $this->fiveSSubmissionPayload($template)
        )->assertCreated();

        $notification = $gm->notifications()->sole();

        $this->actingAs($gm)
            ->get(route('notifications.view-task', $notification->id))
            ->assertRedirect(route('dashboard', [
                'tab' => 'overview',
                'form' => 'five_s',
                'five_s_area' => 'service',
                'branch' => 'Pasong Tamo',
                'user_id' => $fiveSUser->id,
                'user_type' => User::ROLE_5S_SERVICE,
                'submission_id' => $submissionResponse->json('submission.id'),
            ]));
    }

    public function test_utilities_notification_names_the_restroom_category_and_type(): void
    {
        $inspector = User::factory()->make([
            'name' => 'Utilities Inspector',
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_5S_UTILITIES,
        ]);

        foreach ([
            ['customer', 'male', 'Customer Area - Male'],
            ['customer', 'female', 'Customer Area - Female'],
            ['customer', 'pwd', 'Customer Area - PWD'],
            ['office', 'male', 'Office - Male'],
            ['office', 'female', 'Office - Female'],
        ] as [$category, $type, $label]) {
            $submission = new ChecklistSubmission([
                'branch' => 'Pasong Tamo',
                'restroom_area' => $category,
                'restroom_gender' => $type,
                'template_snapshot' => ['slug' => 'restroom-1-'.$type, 'name' => 'Utilities 5S'],
                'scores' => ['bad' => 0],
            ]);

            $data = (new PicTaskCompleted($submission, $inspector))->toArray($inspector);

            $this->assertSame("Utilities 5S checklist submitted ({$label})", $data['title']);
            $this->assertStringContainsString("{$label} Utilities 5S checklist", $data['message']);
        }
    }

    public function test_checklist_without_a_branch_does_not_notify_a_manager(): void
    {
        $inspector = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_5S_SALES,
        ]);
        $manager = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_GENERAL_MANAGER,
        ]);
        $submission = new ChecklistSubmission([
            'branch' => null,
            'template_snapshot' => ['slug' => 'sales', 'name' => 'Sales 5S'],
        ]);

        $this->assertSame(0, app(\App\Services\TaskCompletionNotifier::class)->send($submission, $inspector));
        $this->assertCount(0, $manager->notifications()->get());
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

        $this->getJson(route('notifications.status'))
            ->assertOk()
            ->assertJsonPath('current_count', 0)
            ->assertJsonPath('history_count', 1)
            ->assertJsonPath('history_html', fn (string $html): bool => str_contains($html, $gmNotification->id));

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
            ->assertSee('New');

        $this->actingAs($gm)
            ->patchJson(route('notifications.mark-all-viewed'))
            ->assertOk()
            ->assertJsonPath('marked_count', 1);

        $this->actingAs($gm)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('unreadTaskNotificationCount', 0)
            ->assertViewHas('taskNotifications', fn ($notifications): bool => $notifications->isEmpty())
            ->assertViewHas('taskNotificationHistory', fn ($notifications): bool => $notifications->count() === 1)
            ->assertDontSee('id="notificationsBadge"', false)
            ->assertSee('Seen');

        $this->assertNull($bom->notifications()->sole()->read_at);

        $this->actingAs($pic)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('canReceiveTaskNotifications', false)
            ->assertViewHas('taskNotifications', fn ($notifications): bool => $notifications->isEmpty())
            ->assertDontSee('PIC task completions');
    }

    public function test_notification_status_endpoint_returns_the_live_unread_count_and_current_feed(): void
    {
        [$pic, $gm] = $this->users();
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();

        $this->actingAs($pic)
            ->postJson(route('checklists.submit', $template), $this->submissionPayload($template))
            ->assertCreated();

        $notification = $gm->notifications()->sole();

        $statusResponse = $this->actingAs($gm)
            ->getJson(route('notifications.status'))
            ->assertOk()
            ->assertJsonPath('unread_count', 1)
            ->assertJsonPath('current_count', 1)
            ->assertJsonPath('html', fn (string $html): bool => str_contains($html, (string) $notification->id)
                && str_contains($html, 'PIC task completed')
                && str_contains($html, 'New'));

        $this->assertStringContainsString('no-store', (string) $statusResponse->headers->get('Cache-Control'));

        $this->actingAs($gm)
            ->patchJson(route('notifications.mark-all-viewed'))
            ->assertOk();

        $this->actingAs($gm)
            ->getJson(route('notifications.status'))
            ->assertOk()
            ->assertJsonPath('unread_count', 0)
            ->assertJsonPath('current_count', 0)
            ->assertJsonPath('html', fn (string $html): bool => ! str_contains($html, $notification->id))
            ->assertJsonPath('history_count', 1)
            ->assertJsonPath('history_html', fn (string $html): bool => str_contains($html, $notification->id)
                && str_contains($html, 'Seen notification'));

        $this->actingAs($pic)
            ->getJson(route('notifications.status'))
            ->assertForbidden();
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
                ->assertSee('New');
        }

        $this->actingAs($gm)
            ->patchJson(route('notifications.mark-all-viewed'))
            ->assertOk()
            ->assertJsonPath('marked_count', 1);

        $this->actingAs($gm)
            ->get(route('checklists.index', ['checklist' => 'sales']))
            ->assertOk()
            ->assertSee('Seen');
    }

    public function test_view_task_moves_the_notification_from_current_to_master_detail_history(): void
    {
        [$pic, $gm, $bom] = $this->users();
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();

        $this->actingAs($pic)
            ->postJson(route('checklists.submit', $template), $this->submissionPayload($template))
            ->assertCreated();

        $gmNotification = $gm->notifications()->sole();

        $this->actingAs($gm)
            ->get(route('notifications.view-task', $gmNotification->id))
            ->assertRedirect();

        $archivedNotification = $gmNotification->fresh();
        $this->assertNotNull($archivedNotification->read_at);
        $this->assertNotNull(data_get($archivedNotification->data, 'archived_at'));
        $this->assertNull(data_get($bom->notifications()->sole()->data, 'archived_at'));

        $this->actingAs($gm)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('taskNotifications', fn ($notifications): bool => $notifications->isEmpty())
            ->assertViewHas('taskNotificationHistory', fn ($notifications): bool => $notifications->count() === 1)
            ->assertViewHas('unreadTaskNotificationCount', 0)
            ->assertSee('No notifications currently')
            ->assertSee('notificationHistoryTab', false)
            ->assertSee('notification-history-layout', false)
            ->assertSee('notification-history-list', false)
            ->assertSee('notification-history-details', false)
            ->assertSee('Open Task Again');

        $this->actingAs($gm)
            ->get(route('checklists.index', ['checklist' => 'sales']))
            ->assertOk()
            ->assertSee('No notifications currently')
            ->assertSee('notification-history-layout', false)
            ->assertSee('Open Task Again');
    }

    public function test_only_visible_notification_ids_are_marked_seen_and_moved_to_history(): void
    {
        [$pic, $gm, $bom] = $this->users();
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $payload = $this->submissionPayload($template);
        $this->actingAs($pic)->postJson(route('checklists.submit', $template), $payload)->assertCreated();
        $payload['date'] = '2026-08-28';
        $this->postJson(route('checklists.submit', $template), $payload)->assertCreated();

        $notifications = $bom->notifications()->get();
        $seen = $notifications->first();
        $unseen = $notifications->last();
        $otherRecipient = $gm->notifications()->first();

        $this->actingAs($bom)->patchJson(route('notifications.mark-all-viewed'), [
            'ids' => [$seen->id, $otherRecipient->id],
        ])->assertOk()->assertJsonPath('marked_count', 1)->assertJsonPath('ids', [$seen->id]);

        $seenAt = $seen->fresh()->read_at->toISOString();
        $this->assertNull($unseen->fresh()->read_at);
        $this->assertNull($otherRecipient->fresh()->read_at);
        $this->getJson(route('notifications.status'))->assertOk()
            ->assertJsonPath('current_count', 1)
            ->assertJsonPath('unread_count', 1)
            ->assertJsonPath('history_count', 1)
            ->assertJsonPath('html', fn (string $html): bool => str_contains($html, $unseen->id) && ! str_contains($html, $seen->id))
            ->assertJsonPath('history_html', fn (string $html): bool => str_contains($html, $seen->id) && ! str_contains($html, $unseen->id));

        $this->travel(1)->minutes();
        $this->patchJson(route('notifications.mark-all-viewed'), ['ids' => [$seen->id]])
            ->assertOk()->assertJsonPath('marked_count', 0);
        $this->patchJson(route('notifications.mark-all-viewed'), ['ids' => []])
            ->assertOk()->assertJsonPath('marked_count', 0);
        $this->assertSame($seenAt, $seen->fresh()->read_at->toISOString());
        $this->assertNull($unseen->fresh()->read_at);
    }

    public function test_previously_seen_notifications_are_in_history_without_a_view_task_click(): void
    {
        [$pic, $gm] = $this->users();
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $this->actingAs($pic)->postJson(route('checklists.submit', $template), $this->submissionPayload($template))->assertCreated();
        $notification = $gm->notifications()->sole();
        $notification->markAsRead();
        $this->assertNull(data_get($notification->fresh()->data, 'archived_at'));

        $this->actingAs($gm)->get(route('dashboard'))->assertOk()
            ->assertViewHas('taskNotifications', fn ($notifications): bool => $notifications->isEmpty())
            ->assertViewHas('taskNotificationHistory', fn ($notifications): bool => $notifications->modelKeys() === [$notification->id]);
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

    /**
     * @return array{date: string, responses: array<int, array<string, mixed>>}
     */
    private function fiveSSubmissionPayload(ChecklistTemplate $template): array
    {
        $timeSlots = collect($template->settings['time_slots'] ?? [])
            ->pluck('key')
            ->mapWithKeys(fn (string $slot): array => [$slot => 'good'])
            ->all();

        return [
            'date' => '2026-08-29',
            'responses' => $template->items()
                ->orderBy('id')
                ->get()
                ->map(fn (ChecklistItem $item): array => [
                    'item_id' => $item->id,
                    'status' => 'yes',
                    ...($timeSlots === [] ? [] : [
                        'details' => ['slots' => $timeSlots],
                    ]),
                ])
                ->all(),
        ];
    }
}
