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

        $isUtility = data_get($submission?->template_snapshot, 'slug') === 'restroom'
            || $submission?->template?->slug === 'restroom'
            || in_array($submission?->submitted_by_user_type, [User::ROLE_5S_UTILITIES], true);

        $compiledQuestions = [];
        if ($isUtility && $submission) {
            $submission->loadMissing(['responses.item.section', 'template.sections.items']);
            $responses = $submission->responses->keyBy('item_key');
            $items = $submission->template?->sections->flatMap->items
                ?? $submission->responses->map->item->filter();

            $index = 1;
            foreach ($items as $item) {
                if (! $item) {
                    continue;
                }
                $r = $responses->get($item->key);
                $metadata = is_array($item->metadata) ? $item->metadata : (is_array($r?->item_snapshot) ? data_get($r->item_snapshot, 'metadata', []) : []);
                $prompt = data_get($r?->item_snapshot, 'prompt') ?: ($item->prompt ?: $item->key);
                $sectionTitle = data_get($r?->item_snapshot, 'section.title') ?: ($item->section?->title ?: 'General');

                $compiledQuestions[] = [
                    'number' => data_get($metadata, 'number', $index),
                    'item_key' => $item->key,
                    'question' => $prompt,
                    'area' => $sectionTitle,
                    'status' => $r?->status ?: 'not_good',
                    'result' => 'X',
                    'response_id' => $r?->getKey(),
                ];
                $index++;
            }
        }

        $isCompiled = $isUtility && count($compiledQuestions) > 1;
        $compiledCount = count($compiledQuestions);

        return [
            'event' => 'finding_follow_up_requested',
            'title' => $isCompiled ? 'Follow-up requested on Utilities checklist' : 'Finding follow-up requested',
            'message' => $isCompiled
                ? "{$this->requestedBy->name} requested BOM follow-up on the Utilities inspection ({$compiledCount} questions) for {$branch}."
                : "{$this->requestedBy->name} requested BOM follow-up on {$this->response->item_key} for {$branch}.",
            'is_compiled' => $isCompiled,
            'compiled_count' => $isCompiled ? $compiledCount : null,
            'questions' => $isCompiled ? $compiledQuestions : null,
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
                'restroom' => 'five_s',
                default => null,
            },
            'five_s_area' => $templateSlug === 'restroom' ? 'restroom' : null,
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
