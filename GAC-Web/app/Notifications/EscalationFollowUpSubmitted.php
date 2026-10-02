<?php

namespace App\Notifications;

use Illuminate\Notifications\Notification;

class EscalationFollowUpSubmitted extends Notification
{
    public function __construct(private readonly array $followUp) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        $isCompiled = ! empty($this->followUp['is_compiled']) || ! empty($this->followUp['questions']);
        $count = count($this->followUp['questions'] ?? []);
        $itemLabel = $isCompiled
            ? 'Utilities inspection ('.$count.' questions)'
            : ($this->followUp['item_key'] ?? 'checklist finding');

        return array_merge($this->followUp, [
            'event' => 'escalation_follow_up_submitted',
            'title' => 'Escalation follow-up received',
            'message' => $this->followUp['sender_name'].' followed up on '.$itemLabel.': '.$this->followUp['remarks'],
            'is_compiled' => $isCompiled,
            'compiled_count' => $isCompiled ? $count : null,
            'completed_by_user_id' => $this->followUp['sender_user_id'],
            'completed_by_name' => $this->followUp['sender_name'],
            'completed_by_role' => $this->followUp['sender_role'],
        ]);
    }
}
