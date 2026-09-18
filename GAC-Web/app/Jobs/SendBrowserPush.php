<?php

namespace App\Jobs;

use App\Models\WebPushSubscription;
use App\Rules\BrowserPushEndpoint;
use App\Services\WebPushService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use RuntimeException;

class SendBrowserPush implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public int $timeout = 30;

    public function __construct(
        public readonly int $subscriptionId,
        public readonly int $userId,
        public readonly string $notificationId,
    ) {
        $this->onConnection(config('webpush.connection'));
        $this->onQueue(config('webpush.queue'));
        $this->afterCommit();
    }

    public function backoff(): array
    {
        return [30, 120];
    }

    public function handle(WebPushService $push): void
    {
        if (! WebPushService::configured()) {
            return;
        }

        $device = WebPushSubscription::with('user')->where('user_id', $this->userId)->find($this->subscriptionId);
        if (! $device || $device->user?->account_status !== 'active') {
            return;
        }
        $notification = $device->user->unreadNotifications()->find($this->notificationId);
        if (! $notification || $notification->created_at->lt($device->created_at)
            || $notification->created_at->lt(now()->subSeconds(config('webpush.ttl')))) {
            return;
        }

        if (Validator::make(['endpoint' => $device->endpoint], ['endpoint' => new BrowserPushEndpoint])->fails()) {
            $device->delete();

            return;
        }

        $report = $push->send($device, $notification);
        if ($report->isSubscriptionExpired()) {
            $device->delete();
        } elseif (! $report->isSuccess()) {
            $status = $report->getResponse()?->getStatusCode();
            // Never log endpoint URLs or encryption material.
            if ($status === null || $status === 429 || $status >= 500) {
                throw new RuntimeException('Browser push temporarily failed (HTTP '.($status ?? 'unavailable').').');
            }
            Log::warning('Browser push rejected.', ['subscription_id' => $device->id, 'status' => $status]);
        }
    }
}
