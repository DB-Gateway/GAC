<?php

namespace Tests\Feature;

use App\Jobs\SendBrowserPush;
use App\Models\User;
use App\Models\WebPushSubscription;
use App\Notifications\ChecklistDraftReminder;
use App\Services\WebPushService;
use GuzzleHttp\Client;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Middleware;
use GuzzleHttp\Psr7\Request as PushRequest;
use GuzzleHttp\Psr7\Response;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Str;
use Minishlink\WebPush\MessageSentReport;
use Mockery;
use RuntimeException;
use Tests\TestCase;

class BrowserPushNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config([
            'webpush.public_key' => 'test-public-key',
            'webpush.private_key' => 'test-private-key',
            'webpush.subject' => 'mailto:push@example.com',
        ]);
        Queue::fake();
    }

    public function test_subscription_requires_login_and_valid_browser_keys_and_endpoint(): void
    {
        $this->postJson(route('notifications.push.store'), $this->payload())->assertUnauthorized();
        $this->actingAs(User::factory()->create());
        foreach (['http://fcm.googleapis.com/a', 'https://127.0.0.1/a', 'https://fcm.googleapis.com.evil.test/a',
            'https://fcm.googleapis.com:444/a', 'https://user@fcm.googleapis.com/a'] as $endpoint) {
            $this->postJson(route('notifications.push.store'), $this->payload($endpoint))
                ->assertUnprocessable()->assertJsonValidationErrors('endpoint');
        }
        $this->postJson(route('notifications.push.store'), [
            'endpoint' => $this->payload()['endpoint'], 'keys' => ['p256dh' => 'bad', 'auth' => 'bad'],
        ])->assertUnprocessable()->assertJsonValidationErrors(['keys.p256dh', 'keys.auth']);
        $this->assertDatabaseCount('web_push_subscriptions', 0);
    }

    public function test_subscriptions_are_per_device_idempotent_and_reassigned_safely(): void
    {
        [$first, $second] = User::factory()->count(2)->create();
        $payload = $this->payload();
        $this->actingAs($first)->postJson(route('notifications.push.store'), $payload)
            ->assertOk()->assertJsonPath('enabled', true)->assertCookie(WebPushSubscription::COOKIE);
        $originalId = WebPushSubscription::sole()->id;
        $this->postJson(route('notifications.push.store'), $payload)->assertOk();
        $this->assertDatabaseCount('web_push_subscriptions', 1);
        $this->postJson(route('notifications.push.store'), $this->payload('https://web.push.apple.com/device-two'))->assertOk();
        $this->assertDatabaseCount('web_push_subscriptions', 2);

        $this->actingAs($second)->postJson(route('notifications.push.store'), $payload)->assertOk();
        $this->assertDatabaseMissing('web_push_subscriptions', ['id' => $originalId]);
        $this->assertDatabaseHas('web_push_subscriptions', ['user_id' => $second->id, 'endpoint_hash' => hash('sha256', $payload['endpoint'])]);
        $this->actingAs($first)->deleteJson(route('notifications.push.destroy'), ['endpoint' => $payload['endpoint']])->assertOk();
        $this->assertDatabaseCount('web_push_subscriptions', 2);
        $this->actingAs($second)->deleteJson(route('notifications.push.destroy'), ['endpoint' => $payload['endpoint']])->assertOk();
        $this->assertDatabaseCount('web_push_subscriptions', 1);
    }

    public function test_old_tabs_cannot_subscribe_after_the_signed_in_account_changes(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user)->withHeader('X-GAC-Account', (string) ($user->id + 1))
            ->postJson(route('notifications.push.store'), $this->payload())->assertConflict();
        $this->assertDatabaseCount('web_push_subscriptions', 0);
    }

    public function test_logout_removes_only_this_accounts_current_device(): void
    {
        $user = User::factory()->create();
        $device = $this->device($user, 'current-device');
        $other = $this->device($user, 'other-device');
        $this->actingAs($user)->withCookie(WebPushSubscription::COOKIE, 'current-device')
            ->post(route('logout'))->assertRedirect('/');
        $this->assertDatabaseMissing('web_push_subscriptions', ['id' => $device->id]);
        $this->assertDatabaseHas('web_push_subscriptions', ['id' => $other->id]);
    }

    public function test_database_notifications_queue_once_per_opted_in_recipient_device(): void
    {
        $recipient = User::factory()->create();
        $this->device($recipient, 'first');
        $this->device($recipient, 'second');
        $this->device(User::factory()->create(), 'different-user');
        $recipient->notify(new BrowserPushTestNotification);
        $notification = $recipient->notifications()->sole();
        Queue::assertPushed(SendBrowserPush::class, 2);
        Queue::assertPushed(SendBrowserPush::class, fn ($job) => $job->notificationId === $notification->id
            && $job->userId === $recipient->id && $job->connection === 'database' && $job->afterCommit === true);
    }

    public function test_no_jobs_are_queued_when_push_is_unconfigured_or_user_is_inactive(): void
    {
        $user = User::factory()->create(['account_status' => 'inactive']);
        $this->device($user);
        $user->notify(new BrowserPushTestNotification);
        $user->update(['account_status' => 'active']);
        config(['webpush.public_key' => null]);
        $user->notify(new BrowserPushTestNotification);
        Queue::assertNothingPushed();
        $this->assertDatabaseCount('notifications', 2);
        $this->actingAs($user)->postJson(route('notifications.push.store'), $this->payload())->assertStatus(503);
    }

    public function test_expired_subscriptions_are_removed_and_transient_failures_retry(): void
    {
        $user = User::factory()->create();
        $device = $this->device($user);
        $user->notify(new BrowserPushTestNotification);
        $notification = $user->notifications()->sole();
        $push = Mockery::mock(WebPushService::class);
        $push->shouldReceive('send')->once()->andReturn($this->report(410));
        (new SendBrowserPush($device->id, $user->id, $notification->id))->handle($push);
        $this->assertDatabaseMissing('web_push_subscriptions', ['id' => $device->id]);

        $device = $this->device($user, 'retry');
        $device->update(['created_at' => $notification->created_at]);
        $push->shouldReceive('send')->once()->andReturn($this->report(503));
        $this->expectException(RuntimeException::class);
        (new SendBrowserPush($device->id, $user->id, $notification->id))->handle($push);
    }

    public function test_read_notifications_and_deleted_or_reassigned_devices_are_not_sent(): void
    {
        $user = User::factory()->create();
        $device = $this->device($user);
        $user->notify(new BrowserPushTestNotification);
        $notification = $user->notifications()->sole();
        $job = new SendBrowserPush($device->id, $user->id, $notification->id);
        $push = Mockery::mock(WebPushService::class);
        $push->shouldNotReceive('send');
        $notification->markAsRead();
        $job->handle($push);
        $notification->update(['read_at' => null]);
        $user->update(['account_status' => 'inactive']);
        $job->handle($push);
        $user->update(['account_status' => 'active']);
        $device->update(['user_id' => User::factory()->create()->id]);
        $job->handle($push);
        $device->delete();
        $job->handle($push);
    }

    public function test_clicks_require_the_correct_account_and_static_worker_is_public(): void
    {
        $user = User::factory()->create();
        $user->notify(new BrowserPushTestNotification);
        $notification = $user->notifications()->sole();
        $url = route('notifications.push.open', $notification->id);
        $this->get($url)->assertRedirect(route('login'));
        $this->actingAs(User::factory()->create())->get($url)->assertNotFound();
        $this->actingAs($user)->get($url)->assertRedirect(route('dashboard'));
        $this->get(route('notifications.push.worker'))->assertOk()->assertHeader('Content-Type', 'application/javascript');
        $this->get(route('notifications.push.manifest'))->assertOk()->assertJsonPath('display', 'standalone');
    }

    public function test_draft_reminders_also_queue_push(): void
    {
        $user = User::factory()->create();
        $this->device($user);
        $user->notify(new ChecklistDraftReminder([
            'id' => 1, 'user_id' => $user->id, 'template_slug' => 'sales', 'template_name' => 'Sales',
            'audit_date' => '2026-09-14', 'branch' => 'Pasong Tamo', 'item_key' => null,
            'item_number' => null, 'slot_key' => null, 'customer_index' => null,
        ], User::factory()->create()));
        Queue::assertPushed(SendBrowserPush::class, 1);
        $notification = $user->notifications()->sole();
        $this->actingAs($user)->get(route('notifications.push.open', $notification->id))
            ->assertRedirect(route('checklists.index', ['checklist' => 'sales', 'date' => '2026-09-14', 'branch' => 'Pasong Tamo']));
        $this->assertNotNull($notification->fresh()->read_at);
    }

    public function test_real_transport_encrypts_and_signs_a_push_without_contacting_a_provider(): void
    {
        // Public test fixture: P-256's generator point and scalar 1. Never production keys.
        $encode = fn ($bytes) => rtrim(strtr(base64_encode($bytes), '+/', '-_'), '=');
        $public = $encode(hex2bin('046b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c2964fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5'));
        config(['webpush.public_key' => $public, 'webpush.private_key' => $encode(str_repeat("\0", 31)."\x01")]);
        $requests = [];
        $stack = HandlerStack::create(new MockHandler([new Response(201)]));
        $stack->push(Middleware::history($requests));
        $user = User::factory()->create();
        $device = $this->device($user);
        $device->update(['public_key' => $public]);
        $user->notify(new BrowserPushTestNotification);
        $report = (new WebPushService(new Client(['handler' => $stack])))
            ->send($device, $user->notifications()->sole());
        $this->assertTrue($report->isSuccess());
        $request = $requests[0]['request'];
        $this->assertSame('aes128gcm', $request->getHeaderLine('Content-Encoding'));
        $this->assertStringStartsWith('vapid ', $request->getHeaderLine('Authorization'));
        $this->assertStringNotContainsString('A new task update', (string) $request->getBody());
    }

    private function payload(string $endpoint = 'https://fcm.googleapis.com/gac-test'): array
    {
        return ['endpoint' => $endpoint, 'keys' => [
            'p256dh' => rtrim(strtr(base64_encode("\x04".str_repeat('a', 64)), '+/', '-_'), '='),
            'auth' => rtrim(strtr(base64_encode(str_repeat('b', 16)), '+/', '-_'), '='),
        ]];
    }

    public function test_authenticated_pages_render_browser_push_configuration_and_script(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->get(route('dashboard'));

        $response->assertOk()
            ->assertSee('id="browserPushConfig"', false)
            ->assertSee('js/browser-push.js', false)
            ->assertSee('data-push-status', false);
    }

    private function device(User $user, string $token = 'test-device'): WebPushSubscription
    {
        $payload = $this->payload('https://fcm.googleapis.com/'.Str::uuid());

        return WebPushSubscription::create([
            'user_id' => $user->id, 'endpoint' => $payload['endpoint'],
            'endpoint_hash' => hash('sha256', $payload['endpoint']),
            'public_key' => $payload['keys']['p256dh'], 'auth_token' => $payload['keys']['auth'],
            'device_token_hash' => hash('sha256', $token),
        ]);
    }

    private function report(int $status): MessageSentReport
    {
        return new MessageSentReport(new PushRequest('POST', $this->payload()['endpoint']), new Response($status), $status === 201);
    }
}

class BrowserPushTestNotification extends Notification
{
    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return ['title' => 'A new task update', 'message' => 'A checklist is ready to review.'];
    }
}
