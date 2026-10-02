<?php

namespace App\Notifications;

use Illuminate\Notifications\Notification;

class UtilitiesInspectionNotice extends Notification
{
    public function __construct(private readonly array $data) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return [...$this->data, 'recipient_user_id' => $notifiable->id];
    }
}
