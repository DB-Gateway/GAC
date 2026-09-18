<?php

namespace App\Notifications;

use App\Models\ChecklistResponse;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class FindingFollowUpRequested extends Notification
{
    use Queueable;

    public function __construct(
        private readonly ChecklistResponse $response,
        private readonly User $requestedBy
    ) {}

    /**
     * @return list<string>
     */
    public function via(object $notifiable): array
    {
        return ['database'];
    }

    /**
     * Keep enough context to return the BOM to the exact finding.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        $this->response->loadMissing(['submission.template', 'submission.submittedBy', 'submission.user', 'item']);
        $submission = $this->response->submission;
        $templateSlug = trim((string) (
            data_get($submission?->template_snapshot, 'slug')
                ?: $submission?->template?->slug
        ));
        $templateName = trim((string) (
            data_get($submission?->template_snapshot, 'name')
                ?: $submission?->template?->name
        )) ?: 'Checklist audit';
        $question = trim((string) (
            data_get($this->response->item_snapshot, 'prompt')
                ?: $this->response->item?->prompt
                ?: $this->response->item_key
        ));
        $branch = trim((string) $submission?->branch) ?: 'Unassigned branch';
        $auditor = $submission?->submittedBy ?? $submission?->user;
        $auditorId = $submission?->submitted_by_user_id ?: $submission?->user_id;
        $auditorRole = $submission?->submitted_by_user_type ?: $auditor?->user_type;

        return [
            'event' => 'finding_follow_up_requested',
            'title' => 'Finding follow-up requested',
            'message' => "{$this->requestedBy->name} requested BOM follow-up on {$this->response->item_key} for {$branch}.",
            'response_id' => $this->response->getKey(),
            'submission_id' => $submission?->getKey(),
            'item_key' => $this->response->item_key,
            'question' => $question,
            'finding' => $this->response->finding ?: $this->response->remark,
            'template_name' => $templateName,
            'template_slug' => $templateSlug ?: null,
            'standards_type' => match ($templateSlug) {
                'dealer-operations-standards-sales' => 'sales',
                'dealer-operations-standards' => 'aftersales',
                default => null,
            },
            'branch' => $branch,
            'audit_date' => $submission?->audit_date?->toDateString(),
            'auditor_user_id' => $auditorId,
            'auditor_name' => $submission?->submitted_by_name ?: $auditor?->name,
            'auditor_role' => $auditorRole,
            'requested_by_user_id' => $this->requestedBy->getKey(),
            'requested_by_name' => $this->requestedBy->name,
            'requested_by_role' => $this->requestedBy->roleCode(),
            'requested_at' => now()->toISOString(),
        ];
    }
}
