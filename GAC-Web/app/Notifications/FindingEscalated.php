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

        $isUtility = data_get($submission->template_snapshot, 'slug') === 'restroom'
            || $submission->template?->slug === 'restroom'
            || in_array($submission->submitted_by_user_type, [User::ROLE_5S_UTILITIES], true);

        $compiledQuestions = [];
        if ($isUtility) {
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
            'event' => 'finding_escalated',
            'title' => $isCompiled ? 'BOM escalated missed Utilities checklist' : 'BOM escalated a checklist finding',
            'message' => $isCompiled
                ? "{$this->sender->name} escalated the missed Utilities inspection ({$compiledCount} questions) for {$submission->branch}. Tap to view the action plan."
                : "{$this->sender->name} escalated a finding on {$name}. Tap to view the action plan.",
            'is_compiled' => $isCompiled,
            'compiled_count' => $isCompiled ? $compiledCount : null,
            'questions' => $isCompiled ? $compiledQuestions : null,
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
