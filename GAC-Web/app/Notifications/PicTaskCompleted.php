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
        private readonly User $completedBy
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

        return [
            'event' => 'five_s_checklist_submitted',
            'title' => "{$areaLabel} 5S checklist submitted",
            'message' => "{$completedByName} submitted the {$areaLabel} 5S checklist for {$branch} with {$issueSummary}.",
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
