<?php

namespace App\Listeners;

use App\Models\WebPushSubscription;
use Illuminate\Auth\Events\Logout;

class RemoveBrowserPushOnLogout
{
    public function handle(Logout $event): void
    {
        $token = request()->cookie(WebPushSubscription::COOKIE);
        if ($event->guard === 'web' && $event->user && is_string($token) && $token !== '') {
            WebPushSubscription::where('user_id', $event->user->getAuthIdentifier())
                ->where('device_token_hash', hash('sha256', $token))->delete();
        }
    }
}
