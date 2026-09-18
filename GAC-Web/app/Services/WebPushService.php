<?php

namespace App\Services;

use App\Models\WebPushSubscription;
use GuzzleHttp\Client;
use Illuminate\Notifications\DatabaseNotification;
use Minishlink\WebPush\MessageSentReport;
use Minishlink\WebPush\Subscription;
use Minishlink\WebPush\WebPush;
use Psr\Http\Client\ClientInterface;

class WebPushService
{
    public function __construct(private readonly ?ClientInterface $client = null) {}

    public static function configured(): bool
    {
        return filled(config('webpush.public_key')) && filled(config('webpush.private_key'))
            && filled(config('webpush.subject'));
    }

    public function send(WebPushSubscription $device, DatabaseNotification $notification): MessageSentReport
    {
        $push = new WebPush(['VAPID' => [
            'subject' => config('webpush.subject'),
            'publicKey' => config('webpush.public_key'),
            'privateKey' => config('webpush.private_key'),
        ]], ['TTL' => config('webpush.ttl'), 'urgency' => 'normal'], $this->client ?? new Client([
            'allow_redirects' => false,
            'connect_timeout' => 5,
            'timeout' => 15,
        ]));

        return $push->sendOneNotification(Subscription::create([
            'endpoint' => $device->endpoint,
            'keys' => ['p256dh' => $device->public_key, 'auth' => $device->auth_token],
            'contentEncoding' => 'aes128gcm',
        ]), json_encode([
            'id' => $notification->id,
            'title' => mb_substr(strip_tags($notification->data['title'] ?? 'GAC notification'), 0, 100),
            'body' => mb_substr(strip_tags($notification->data['message'] ?? 'You have a new notification.'), 0, 240),
            'url' => route('notifications.push.open', $notification->id, false),
        ], JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR));
    }
}
