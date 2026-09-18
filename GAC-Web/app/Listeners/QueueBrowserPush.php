<?php

namespace App\Listeners;

use App\Jobs\SendBrowserPush;
use App\Models\User;
use App\Models\WebPushSubscription;
use App\Services\WebPushService;
use Illuminate\Notifications\DatabaseNotification;
use Illuminate\Notifications\Events\NotificationSent;

class QueueBrowserPush
{
    public function handle(NotificationSent $event): void
    {
        if ($event->channel !== 'database' || ! $event->notifiable instanceof User
            || ! $event->response instanceof DatabaseNotification || ! WebPushService::configured()
            || $event->notifiable->account_status !== 'active') {
            return;
        }

        WebPushSubscription::where('user_id', $event->notifiable->id)->each(function ($device) use ($event): void {
            SendBrowserPush::dispatch($device->id, $event->notifiable->id, $event->response->id);
        });
    }
}
