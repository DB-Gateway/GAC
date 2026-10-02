<?php

namespace App\Services;

use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\User;
use App\Notifications\PicTaskCompleted;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Notification;

class TaskCompletionNotifier
{
    /**
     * Notify the existing PIC audience, or route a DOS audit to management and its
     * explicitly selected escalation teams.
     */
    public function send(ChecklistSubmission $submission, User $completedBy, array $missedSlots = []): int
    {
        if (in_array($completedBy->roleCode(), [
            User::ROLE_5S_UTILITIES,
            User::ROLE_5S_SERVICE,
            User::ROLE_5S_SALES,
            User::ROLE_PERSON_IN_CHARGE,
        ], true)) {
            $recipients = $this->picRecipients($submission, $completedBy);
        } elseif ($this->isDosSubmission($submission)) {
            $recipients = $this->dosRecipients($submission, $completedBy);
        } else {
            $recipients = $this->picRecipients($submission, $completedBy);
        }

        if ($recipients->isEmpty()) {
            return 0;
        }

        Notification::send($recipients, new PicTaskCompleted($submission, $completedBy, $missedSlots));

        return $recipients->count();
    }

    private function picRecipients(ChecklistSubmission $submission, User $completedBy)
    {
        $branch = mb_strtolower(trim((string) $submission->branch));

        if ($branch === '') {
            return collect();
        }

        return User::query()
            ->where('account_status', 'active')
            ->whereKeyNot($completedBy->getKey())
            ->whereRaw('LOWER(TRIM(branch)) = ?', [$branch])
            ->where(function (Builder $query): void {
                $this->whereRoleIs($query, [
                    User::ROLE_ADMINISTRATOR,
                    User::ROLE_GENERAL_MANAGER,
                    User::ROLE_BRANCH_OPERATIONS_MANAGER,
                    'Administrator',
                    'Compliance Administrator',
                    'GAC Administrator',
                    'Gateway Administrator',
                    'GM',
                    'General Manager',
                    'Branch Operations Manager',
                ]);
            })
            ->get();
    }

    private function dosRecipients(ChecklistSubmission $submission, User $completedBy)
    {
        $submission->loadMissing('responses');
        $branch = mb_strtolower(trim((string) $submission->branch));

        if ($branch === '') {
            return collect();
        }
        $targets = $submission->responses
            ->filter(fn ($response): bool => in_array($response->status, ['no', 'na'], true))
            ->map(fn ($response): ?string => $this->responseEscalationTarget($response))
            ->filter()
            ->unique()
            ->values();
        $roles = [
            User::ROLE_ADMINISTRATOR,
            User::ROLE_GENERAL_MANAGER,
            'Administrator',
            'Compliance Administrator',
            'GAC Administrator',
            'Gateway Administrator',
            'GM',
            'General Manager',
        ];

        if ($targets->contains('purchasing')) {
            $roles = [...$roles, User::ROLE_PURCHASING, 'Purchasing Team'];
        }

        if ($targets->contains('property_management')) {
            $roles = [
                ...$roles,
                User::ROLE_PROPERTY_MANAGEMENT,
                'PM',
                'Property Management',
                'Property Mgmt',
                // Historical account labels retained as read aliases.
                'PURCHASING_MANAGER',
                'Purchasing Manager',
                'Purchasing Manager (PM)',
                'PM (Purchasing Manager)',
                'Purchasing Mgr',
            ];
        }

        if ($targets->contains('inventory')) {
            $roles = [...$roles, User::ROLE_INVENTORY, 'Inventory Team'];
        }

        $roles = [...$roles, User::ROLE_BRANCH_OPERATIONS_MANAGER, 'Branch Operations Manager'];

        return User::query()
            ->where('account_status', 'active')
            ->whereKeyNot($completedBy->getKey())
            ->whereRaw('LOWER(TRIM(branch)) = ?', [$branch])
            ->where(function (Builder $query) use ($roles): void {
                $this->whereRoleIs($query, $roles);
            })
            ->get();
    }

    private function responseEscalationTarget(mixed $response): ?string
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

    private function isDosSubmission(ChecklistSubmission $submission): bool
    {
        $slug = trim((string) (
            data_get($submission->template_snapshot, 'slug')
            ?: $submission->template?->slug
        ));

        return in_array($slug, [
            'dealer-operations-standards',
            'dealer-operations-standards-sales',
            'dealer-operations-standards-subform',
            'dealer-operations-standards-documentation',
        ], true);
    }

    /**
     * @param  list<string>  $roles
     */
    private function whereRoleIs(Builder $query, array $roles): void
    {
        $normalized = array_values(array_unique(array_map(
            static fn (string $role): string => mb_strtolower(trim($role)),
            $roles
        )));
        $placeholders = implode(', ', array_fill(0, count($normalized), '?'));

        $query->whereRaw("LOWER(TRIM(user_type)) IN ({$placeholders})", $normalized);
    }
}
