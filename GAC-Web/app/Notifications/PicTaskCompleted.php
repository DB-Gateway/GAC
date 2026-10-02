<?php

namespace App\Notifications;

use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class PicTaskCompleted extends Notification
{
    use Queueable;

    public function __construct(
        private readonly ChecklistSubmission $submission,
        private readonly User $completedBy,
        private readonly array $missedSlots = []
    ) {}

    /**
     * Store one notification row in the existing checklist notification stream.
     *
     * @return list<string>
     */
    public function via(object $notifiable): array
    {
        return ['database'];
    }

    /**
     * Keep a snapshot so the notification remains useful if a user or template is renamed.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        $templateName = trim((string) (
            data_get($this->submission->template_snapshot, 'name')
            ?: $this->submission->template?->name
        )) ?: 'Checklist task';
        $templateSlug = trim((string) (
            data_get($this->submission->template_snapshot, 'slug')
            ?: $this->submission->template?->slug
        ));
        $branch = trim((string) $this->submission->branch) ?: 'Unassigned branch';
        $completedByName = trim((string) $this->completedBy->name) ?: 'Person In Charge';
        $completedByBranch = trim((string) $this->completedBy->branch) ?: $branch;
        $completedByRole = $this->completedBy->roleCode();
        $standardsType = $this->standardsType($templateSlug);

        if ($this->isFiveSUser() && $this->fiveSArea($templateSlug) !== null) {
            return $this->fiveSPayload(
                $templateName,
                $templateSlug,
                $branch,
                $completedByName,
                $completedByBranch,
                $completedByRole
            );
        }

        if ($this->completedBy->isDosOperationalRole() && $this->isDosSubmission()) {
            return $this->dosPayload(
                $templateName,
                $templateSlug,
                $branch,
                $completedByName,
                $completedByBranch,
                $completedByRole,
                $standardsType
            );
        }

        return [
            'event' => 'pic_task_completed',
            'title' => 'PIC task completed',
            'message' => "{$completedByName} completed {$templateName} for {$branch}.",
            'submission_id' => $this->submission->getKey(),
            'template_name' => $templateName,
            'template_slug' => $templateSlug ?: null,
            'branch' => $branch,
            'audit_date' => $this->submission->audit_date?->toDateString(),
            'completed_by_user_id' => $this->completedBy->getKey(),
            'completed_by_name' => $completedByName,
            'completed_by_role' => $completedByRole,
            'completed_by_branch' => $completedByBranch,
            'standards_type' => $standardsType,
            'completed_at' => $this->submission->submitted_at?->toISOString(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function fiveSPayload(
        string $templateName,
        string $templateSlug,
        string $branch,
        string $completedByName,
        string $completedByBranch,
        string $completedByRole
    ): array {
        $area = $this->fiveSArea($templateSlug);
        $areaLabel = match ($area) {
            'sales' => 'Sales',
            'service' => 'Service',
            'restroom' => 'Utilities',
            default => 'Gateway',
        };
        $issueCount = $this->fiveSIssueCount($area);
        $issueSummary = $issueCount === 1 ? '1 issue' : "{$issueCount} issues";
        $missed = $area === 'restroom' && $this->missedSlots !== [];
        $slotLabels = implode(', ', $this->missedSlots);
        $restroomArea = strtolower(trim((string) ($this->submission->restroom_area
            ?: data_get($this->submission->template_snapshot, 'settings.restroom_area'))));
        $restroomGender = strtolower(trim((string) ($this->submission->restroom_gender
            ?: data_get($this->submission->template_snapshot, 'settings.restroom_gender'))));
        $restroomCategory = match ($restroomArea) {
            'customer' => 'Customer Area',
            'office' => 'Office',
            default => null,
        };
        $restroomType = in_array($restroomGender, ['male', 'female', 'pwd'], true)
            ? \App\Models\BranchRestroom::genderLabel($restroomGender)
            : null;
        $restroomDetail = $area === 'restroom'
            ? implode(' - ', array_filter([$restroomCategory, $restroomType]))
            : '';
        $restroomName = trim((string) data_get($this->submission->template_snapshot, 'settings.restroom_name'));
        $restroomLabel = $restroomDetail !== ''
            ? $restroomDetail.' Utilities 5S checklist'.($restroomName !== '' ? " ({$restroomName})" : '')
            : ($area === 'restroom' && $restroomName !== ''
                ? $restroomName.' Utilities 5S checklist'
                : $areaLabel.' 5S checklist');
        $inspectionLabel = $restroomDetail !== ''
            ? $restroomDetail.' Utilities inspection'
            : 'Utilities inspection';

        $compiledQuestions = [];
        if ($missed) {
            $this->submission->loadMissing(['responses.item.section', 'template.sections.items']);
            $responses = $this->submission->responses->keyBy('item_key');
            $items = $this->submission->template?->sections->flatMap->items
                ?? $this->submission->responses->map->item->filter();

            $index = 1;
            foreach ($items as $item) {
                if (! $item) {
                    continue;
                }
                $resp = $responses->get($item->key);
                $metadata = is_array($item->metadata) ? $item->metadata : [];
                $activeSlots = $metadata['active_slots'] ?? null;
                $isActiveForMissed = ! is_array($activeSlots)
                    || collect($this->missedSlots)->contains(fn ($s) => in_array($s, $activeSlots, true));
                if (! $isActiveForMissed) {
                    continue;
                }

                $sectionTitle = $item->section?->title
                    ?? data_get($item->metadata, 'coverage')
                    ?? 'General';

                $compiledQuestions[] = [
                    'number' => data_get($metadata, 'number', $index),
                    'item_key' => $item->key,
                    'question' => $item->prompt ?: $item->key,
                    'area' => $sectionTitle,
                    'status' => 'not_good',
                    'result' => 'X',
                    'response_id' => $resp?->getKey(),
                    'slots' => $this->missedSlots,
                ];
                $index++;
            }
        }

        $compiledCount = count($compiledQuestions);

        return [
            'event' => $missed ? 'utilities_inspection_missed' : 'five_s_checklist_submitted',
            'title' => $missed
                ? 'Missed Utilities inspection'.($restroomDetail !== '' ? " ({$restroomDetail})" : '').' — failed checklist'
                : "{$areaLabel} 5S checklist submitted".($restroomDetail !== '' ? " ({$restroomDetail})" : ''),
            'message' => $missed
                ? "{$completedByName} missed the {$slotLabels} {$inspectionLabel} for {$branch}. The failed checklist was automatically submitted for GM and BOM review."
                : "{$completedByName} submitted the {$restroomLabel} for {$branch} with {$issueSummary}.",
            'is_compiled' => $missed,
            'compiled_count' => $missed ? $compiledCount : null,
            'questions' => $missed ? $compiledQuestions : null,
            'missed_slots' => $this->missedSlots,
            'slot_key' => $this->missedSlots[0] ?? null,
            'submission_id' => $this->submission->getKey(),
            'template_name' => $templateName,
            'template_slug' => $templateSlug,
            'branch' => $branch,
            'audit_date' => $this->submission->audit_date?->toDateString(),
            'completed_by_user_id' => $this->completedBy->getKey(),
            'completed_by_name' => $completedByName,
            'completed_by_role' => $completedByRole,
            'completed_by_branch' => $completedByBranch,
            'standards_type' => 'five_s',
            'five_s_area' => $area,
            'restroom_id' => $area === 'restroom' ? $this->submission->branch_restroom_id : null,
            'restroom_area' => $area === 'restroom' ? $this->submission->restroom_area : null,
            'restroom_gender' => $area === 'restroom' ? $this->submission->restroom_gender : null,
            'finding_count' => $issueCount,
            'completed_at' => $this->submission->submitted_at?->toISOString(),
        ];
    }

    private function fiveSIssueCount(?string $area): int
    {
        if ($area === 'restroom') {
            return (int) data_get($this->submission->scores, 'bad', 0);
        }

        $this->submission->loadMissing('responses');

        return $this->submission->responses
            ->filter(fn ($response): bool => $response->status === 'no')
            ->count();
    }

    /**
     * @return array<string, mixed>
     */
    private function dosPayload(
        string $templateName,
        string $templateSlug,
        string $branch,
        string $completedByName,
        string $completedByBranch,
        string $completedByRole,
        ?string $standardsType
    ): array {
        $this->submission->loadMissing('responses');
        $findings = $this->submission->responses
            ->filter(fn ($response): bool => in_array($response->status, ['no', 'na'], true))
            ->map(function ($response): array {
                $target = $this->escalationTarget($response);

                return [
                    'item_key' => $response->item_key,
                    'checklist_item' => data_get($response->item_snapshot, 'prompt') ?: $response->item_key,
                    'status' => $response->status,
                    'finding' => $response->finding,
                    'action_plan' => $response->action_plan,
                    'commitment_date' => $response->commitment_date?->format('Y-m-d\TH:i:s'),
                    'escalation_target' => $target,
                ];
            })
            ->values();
        $targets = $this->submission->responses
            ->filter(fn ($response): bool => in_array($response->status, ['no', 'na'], true))
            ->map(fn ($response): ?string => $this->escalationTarget($response))
            ->filter()
            ->unique()
            ->values()
            ->all();
        $isDocumentation = in_array($templateSlug, [
            'dealer-operations-standards-documentation',
            'dos-documentation',
            'documentation',
        ], true);
        $sampleCount = 0;
        if ($isDocumentation) {
            $firstResponse = $this->submission->responses->first();
            $customers = data_get($firstResponse?->details, 'customers');
            if (is_array($customers)) {
                $sampleCount = count($customers);
            }
        }
        $findingCount = $findings->count();
        $findingSummary = $findingCount === 1 ? '1 finding' : "{$findingCount} findings";
        $message = $sampleCount > 0
            ? "{$completedByName} submitted {$templateName} for {$branch} ({$sampleCount} customer samples)."
            : "{$completedByName} submitted {$templateName} for {$branch} with {$findingSummary}.";

        return [
            'event' => 'dos_audit_submitted',
            'title' => 'DOS audit submitted',
            'message' => $message,
            'submission_id' => $this->submission->getKey(),
            'template_name' => $templateName,
            'template_slug' => $templateSlug ?: null,
            'branch' => $branch,
            'audit_date' => $this->submission->audit_date?->toDateString(),
            'completed_by_user_id' => $this->completedBy->getKey(),
            'completed_by_name' => $completedByName,
            'completed_by_role' => $completedByRole,
            'completed_by_branch' => $completedByBranch,
            'standards_type' => $standardsType,
            'customer_sample_count' => $sampleCount > 0 ? $sampleCount : null,
            'completed_at' => $this->submission->submitted_at?->toISOString(),
            'finding_count' => $findingCount,
            'escalation_targets' => $targets,
            'findings' => $findings->all(),
        ];
    }

    private function escalationTarget(mixed $response): ?string
    {
        $value = $response->escalation_target
            ?? data_get($response->details, 'escalation_target')
            ?? data_get($response->details, 'escalation');

        $normalized = ChecklistResponse::normalizeEscalationTarget($value);

        return is_string($normalized) && in_array($normalized, [
            'general_manager',
            'purchasing',
            'property_management',
            'inventory',
        ], true) ? $normalized : null;
    }

    private function isDosSubmission(): bool
    {
        $slug = trim((string) (
            data_get($this->submission->template_snapshot, 'slug')
            ?: $this->submission->template?->slug
        ));

        return in_array($slug, [
            'dealer-operations-standards',
            'dealer-operations-standards-sales',
            'dealer-operations-standards-subform',
            'dealer-operations-standards-documentation',
        ], true);
    }

    private function isFiveSUser(): bool
    {
        return in_array($this->completedBy->roleCode(), [
            User::ROLE_5S_SALES,
            User::ROLE_5S_SERVICE,
            User::ROLE_5S_UTILITIES,
        ], true);
    }

    private function fiveSArea(string $templateSlug): ?string
    {
        if (preg_match('/^restroom-\d+-(male|female|pwd)$/', $templateSlug) === 1) {
            return 'restroom';
        }

        return match ($templateSlug) {
            'sales' => 'sales',
            'service' => 'service',
            'restroom', 'utilities' => 'restroom',
            default => null,
        };
    }

    private function standardsType(string $templateSlug): ?string
    {
        return match ($templateSlug) {
            'dealer-operations-standards-sales' => 'sales',
            'dealer-operations-standards' => 'aftersales',
            default => null,
        };
    }
}
