<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\PicTaskCompleted;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\DatabaseNotification;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MobileNotificationApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_mobile_notification_routes_require_a_sanctum_token(): void
    {
        $notification = (string) Str::uuid();

        $this->getJson(route('api.notifications.index'))
            ->assertUnauthorized();
        $this->patchJson(route('api.notifications.read-all'))
            ->assertUnauthorized();
        $this->patchJson(route('api.notifications.read', $notification))
            ->assertUnauthorized();
    }

    public function test_pic_can_list_only_its_notifications_with_a_normalized_payload_for_all_types(): void
    {
        $pic = $this->pic();
        $otherPic = $this->pic();

        $older = $this->notificationFor(
            $pic,
            type: PicTaskCompleted::class,
            data: [
                'event' => 'pic_task_completed',
                'title' => 'Checklist accepted',
                'message' => 'Your checklist was accepted.',
                'submission_id' => 41,
            ],
            readAt: now()->subMinute(),
            createdAt: now()->subHour(),
        );
        $newer = $this->notificationFor(
            $pic,
            type: 'App\\Notifications\\TaskDueSoon',
            data: [
                'message' => 'Restroom check is due before 8:30 AM.',
                'checklist_slug' => 'restroom',
            ],
        );
        $other = $this->notificationFor(
            $otherPic,
            type: 'App\\Notifications\\TaskDueSoon',
            data: ['title' => 'Not yours', 'message' => 'Private notification.'],
        );

        Sanctum::actingAs($pic);

        $this->getJson(route('api.notifications.index'))
            ->assertOk()
            ->assertJsonCount(2, 'notifications')
            ->assertJsonPath('unread_count', 1)
            ->assertJsonPath('notifications.0.id', $newer->id)
            ->assertJsonPath('notifications.0.type', 'task_due_soon')
            ->assertJsonPath('notifications.0.title', 'Task Due Soon')
            ->assertJsonPath('notifications.0.message', 'Restroom check is due before 8:30 AM.')
            ->assertJsonPath('notifications.0.data.checklist_slug', 'restroom')
            ->assertJsonPath('notifications.0.unread', true)
            ->assertJsonPath('notifications.0.read_at', null)
            ->assertJsonPath('notifications.1.id', $older->id)
            ->assertJsonPath('notifications.1.type', 'pic_task_completed')
            ->assertJsonPath('notifications.1.title', 'Checklist accepted')
            ->assertJsonPath('notifications.1.unread', false)
            ->assertJsonMissing(['id' => $other->id]);
    }

    public function test_pic_can_mark_its_notification_read_but_cannot_mark_another_users_notification(): void
    {
        $pic = $this->pic();
        $otherPic = $this->pic();
        $own = $this->notificationFor(
            $pic,
            type: 'App\\Notifications\\TaskDueSoon',
            data: ['title' => 'Due soon', 'message' => 'Complete this task.'],
        );
        $other = $this->notificationFor(
            $otherPic,
            type: 'App\\Notifications\\TaskDueSoon',
            data: ['title' => 'Other task', 'message' => 'Not assigned to you.'],
        );

        Sanctum::actingAs($pic);

        $this->patchJson(route('api.notifications.read', $own->id))
            ->assertOk()
            ->assertJsonPath('notification.id', $own->id)
            ->assertJsonPath('notification.unread', false)
            ->assertJsonPath('unread_count', 0);

        $this->assertNotNull($own->fresh()->read_at);

        $this->patchJson(route('api.notifications.read', $other->id))
            ->assertNotFound();

        $this->assertNull($other->fresh()->read_at);
    }

    public function test_pic_read_all_marks_every_own_notification_type_and_leaves_other_users_unchanged(): void
    {
        $pic = $this->pic();
        $otherPic = $this->pic();
        $first = $this->notificationFor(
            $pic,
            type: PicTaskCompleted::class,
            data: ['event' => 'pic_task_completed'],
        );
        $second = $this->notificationFor(
            $pic,
            type: 'App\\Notifications\\CorrectiveActionRequested',
            data: ['event' => 'corrective_action_requested'],
        );
        $other = $this->notificationFor(
            $otherPic,
            type: 'App\\Notifications\\TaskDueSoon',
            data: ['event' => 'task_due_soon'],
        );

        Sanctum::actingAs($pic);

        $this->patchJson(route('api.notifications.read-all'))
            ->assertOk()
            ->assertJsonPath('marked_count', 2)
            ->assertJsonPath('unread_count', 0)
            ->assertJsonCount(2, 'ids')
            ->assertJsonFragment(['ids' => [$second->id, $first->id]]);

        $this->assertNotNull($first->fresh()->read_at);
        $this->assertNotNull($second->fresh()->read_at);
        $this->assertNull($other->fresh()->read_at);

        $this->patchJson(route('api.notifications.read-all'))
            ->assertOk()
            ->assertJsonPath('marked_count', 0)
            ->assertJsonPath('unread_count', 0);
    }

    private function pic(): User
    {
        return User::factory()->create([
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'pic_assignment_type' => User::PIC_ASSIGNMENT_UTILITIES,
            'account_status' => 'active',
        ]);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function notificationFor(
        User $user,
        string $type,
        array $data,
        mixed $readAt = null,
        mixed $createdAt = null,
    ): DatabaseNotification {
        return $user->notifications()->create([
            'id' => (string) Str::uuid(),
            'type' => $type,
            'data' => $data,
            'read_at' => $readAt,
            'created_at' => $createdAt ?? now(),
            'updated_at' => $createdAt ?? now(),
        ]);
    }
}
