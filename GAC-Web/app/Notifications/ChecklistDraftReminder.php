<?php

namespace App\Notifications;

use App\Models\User;
use Illuminate\Notifications\Notification;

class ChecklistDraftReminder extends Notification
{
    public function __construct(private readonly array $draft, private readonly User $requestedBy) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        $question = $this->draft['item_number'] ? ' Resume at question #'.$this->draft['item_number'].'.' : ' Your saved answers are ready to review and submit.';

        return [
            'event' => 'checklist_draft_reminder',
            'title' => 'Finish your drafted checklist',
            'message' => $this->requestedBy->name.' asked you to finish '.$this->draft['template_name'].' for '.$this->draft['audit_date'].'.'.$question,
            'submission_id' => $this->draft['id'],
            'recipient_user_id' => $this->draft['user_id'],
            'template_slug' => $this->draft['template_slug'],
            'template_name' => $this->draft['template_name'],
            'audit_date' => $this->draft['audit_date'],
            'branch' => $this->draft['branch'],
            'item_key' => $this->draft['item_key'],
            'item_number' => $this->draft['item_number'],
            'slot_key' => $this->draft['slot_key'],
            'customer_index' => $this->draft['customer_index'],
            'requested_by_user_id' => $this->requestedBy->id,
            'requested_by_name' => $this->requestedBy->name,
            'requested_by_role' => $this->requestedBy->roleCode(),
            'requested_at' => now()->toISOString(),
        ];
    }
}
