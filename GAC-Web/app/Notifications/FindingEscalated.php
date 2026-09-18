<?php

namespace App\Notifications;

use App\Models\ChecklistResponse;
use App\Models\User;
use Illuminate\Notifications\Notification;

class FindingEscalated extends Notification
{
    public function __construct(private readonly ChecklistResponse $response, private readonly User $sender) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        $this->response->loadMissing(['submission.template', 'item']);
        $submission = $this->response->submission;
        $name = data_get($submission->template_snapshot, 'name') ?: $submission->template?->name;

        return [
            'event' => 'finding_escalated',
            'title' => 'BOM escalated a checklist finding',
            'message' => "{$this->sender->name} escalated a finding on {$name}. Tap to view the action plan.",
            'recipient_user_id' => $notifiable->getKey(),
            'response_id' => $this->response->getKey(),
            'submission_id' => $submission->getKey(),
            'template_slug' => data_get($submission->template_snapshot, 'slug') ?: $submission->template?->slug,
            'template_name' => $name,
            'item_key' => $this->response->item_key,
            'question' => data_get($this->response->item_snapshot, 'prompt') ?: $this->response->item?->prompt,
            'status' => $this->response->status,
            'attachment_path' => $this->response->attachment_path,
            'attachment_url' => filled($this->response->attachment_path)
                ? \Illuminate\Support\Facades\Storage::disk('public')->url($this->response->attachment_path)
                : null,
            'finding' => $this->response->finding ?: $this->response->remark,
            'branch' => $submission->branch,
            'audit_date' => $submission->audit_date?->toDateString(),
            'escalation_target' => $this->response->escalation_target,
            'escalation_target_label' => $this->response->escalationTargetLabel(),
            'commitment_date' => $this->response->commitment_date?->copy()
                ->timezone(config('gac.report_timezone', 'Asia/Manila'))->format('Y-m-d'),
            'action_plan' => $this->response->action_plan,
            'sender_user_id' => $this->sender->getKey(),
            'sender_name' => $this->sender->name,
            'sender_role' => $this->sender->roleCode(),
        ];
    }
}
