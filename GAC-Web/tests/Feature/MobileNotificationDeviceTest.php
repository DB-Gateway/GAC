<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class MobileNotificationDeviceTest extends TestCase
{
    use RefreshDatabase;

    public function test_device_inbox_survives_auth_expiry_and_cannot_access_interactive_api(): void
    {
        $user = User::factory()->create();
        $login = $this->postJson('/api/login', [
            'email' => $user->email, 'password' => 'password', 'notification_device_id' => (string) Str::uuid(),
        ])->assertOk();
        $token = $login->json('notification_token');
        PersonalAccessToken::findToken($login->json('token'))->delete();
        $this->travel(2)->days();
        config(['sanctum.expiration' => 15]);
        $id = (string) Str::uuid();
        $user->notifications()->create([
            'id' => $id, 'type' => 'test', 'data' => ['event' => 'finding_escalated', 'title' => 'Escalation', 'action_plan' => 'Repair'],
        ]);
        $this->withToken($token)->getJson('/api/device-notifications')
            ->assertOk()->assertJsonPath('notifications.0.id', $id)->assertJsonPath('unread_count', 1);
        $this->withToken($token)->patchJson('/api/device-notifications/'.$id.'/read')->assertOk();
        $this->assertNotNull($user->notifications()->sole()->read_at);

        config(['sanctum.expiration' => null]);
        $this->withToken($token)->getJson('/api/me')->assertForbidden();
        $this->withToken($token)->getJson('/api/checklists')->assertForbidden();
    }

    public function test_new_login_on_same_device_replaces_previous_recipient_and_preserves_other_devices(): void
    {
        $first = User::factory()->create();
        $second = User::factory()->create();
        $deviceId = (string) Str::uuid();
        $login = fn (User $user, string $device) => $this->postJson('/api/login', [
            'email' => $user->email, 'password' => 'password', 'notification_device_id' => $device,
        ])->assertOk()->json('notification_token');
        $old = $login($first, $deviceId);
        $otherDevice = $login($first, (string) Str::uuid());
        $new = $login($second, $deviceId);
        $this->assertNull(PersonalAccessToken::findToken($old));
        $this->assertSame($first->id, PersonalAccessToken::findToken($otherDevice)->tokenable_id);
        $this->assertSame($second->id, PersonalAccessToken::findToken($new)->tokenable_id);
        $this->withToken($old)->getJson('/api/device-notifications')->assertUnauthorized();
        $this->withToken($new)->getJson('/api/device-notifications')->assertOk()->assertJsonCount(0, 'notifications');
    }

    public function test_device_token_cannot_read_other_users_notifications_or_inactive_accounts(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $id = (string) Str::uuid();
        $other->notifications()->create(['id' => $id, 'type' => 'test', 'data' => ['title' => 'Private']]);
        $token = $user->createToken('notifications:test', ['notifications:read'])->plainTextToken;
        $this->withToken($token)->getJson('/api/device-notifications')->assertOk()->assertJsonCount(0, 'notifications');
        $this->withToken($token)->patchJson('/api/device-notifications/'.$id.'/read')->assertNotFound();
        $user->update(['account_status' => 'inactive']);
        $this->withToken($token)->getJson('/api/device-notifications')->assertUnauthorized();
    }
}
