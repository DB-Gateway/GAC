<?php

namespace App\Services;

use App\Models\ChecklistSubmission;
use App\Models\User;
use App\Notifications\FindingFollowUpRequested;
use App\Notifications\EscalationFollowUpSubmitted;
use App\Notifications\PicTaskCompleted;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

class NotificationService
{
    public function getTaskNotificationData(?User $user): array
    {
        $canReceive = $user?->receivesTaskCompletionNotifications() === true;
        $query = $canReceive ? $user->notifications()->whereIn('type', [
            PicTaskCompleted::class,
            FindingFollowUpRequested::class,
            EscalationFollowUpSubmitted::class,
        ]) : null;

        // Previously seen notifications also belong in History, even when
        // they predate automatic archiving or were read through the mobile app.
        $current = $query ? (clone $query)->whereNull('read_at')->whereNull('data->archived_at') : null;

        return [
            'taskNotifications' => $current ? (clone $current)->latest()->limit(30)->get() : collect(),
            'taskNotificationHistory' => $query ? (clone $query)
                ->where(fn (Builder $query) => $query->whereNotNull('read_at')->orWhereNotNull('data->archived_at'))
                ->orderByDesc('read_at')->orderByDesc('updated_at')->limit(50)->get() : collect(),
            'unreadTaskNotificationCount' => $current ? $current->count() : 0,
            'canReceiveTaskNotifications' => $canReceive,
        ];
    }

    public function getPendingDraftAlert(?User $user): ?array
    {
        if (! $user?->receivesTaskCompletionNotifications()) {
            return null;
        }
        $count = app(DraftFollowUpService::class)->pendingDrafts($user)->count();
        if ($count === 0) {
            return null;
        }

        return [
            'type' => 'warning',
            'icon' => 'fa-clock',
            'title' => 'Saved audits awaiting submission',
            'message' => trans_choice(':count checklist draft is unfinished.|:count checklist drafts are unfinished.', $count, ['count' => $count]),
            'action' => ['target' => 'draftReminderModal', 'label' => 'Review drafts and notify users'],
        ];
    }

    /**
     * @return array{
     *     taskNotifications: Collection,
     *     taskNotificationHistory: Collection,
     *     unreadTaskNotificationCount: int,
     *     canReceiveTaskNotifications: bool,
     *     notifications: Collection,
     *     notificationBadgeCount: int,
     *     calendar: array{label: string}
     * }
     */
    public function getNotificationData(?User $user): array
    {
        $taskData = $this->getTaskNotificationData($user);

        $monthStart = now()->startOfMonth();
        $monthEnd = now()->endOfMonth();

        $currentMonthSubmissions = ChecklistSubmission::query()
            ->whereBetween('audit_date', [$monthStart->toDateString(), $monthEnd->toDateString()])
            ->with(['responses'])
            ->get();

        $draftsCount = $currentMonthSubmissions->where('status', 'draft')->count();

        $criticalFindings = $currentMonthSubmissions
            ->where('status', 'submitted')
            ->sum(fn (ChecklistSubmission $submission): int => $submission->responses
                ->filter(fn ($response): bool => mb_strtolower(trim((string) $response->status)) === 'no')
                ->count());

        $systemAlerts = collect();

        $draftAlert = $this->getPendingDraftAlert($user);
        if ($draftAlert) {
            $systemAlerts->push($draftAlert);
        } elseif (! $user?->receivesTaskCompletionNotifications() && $draftsCount > 0) {
            $systemAlerts->push([
                'type' => 'warning',
                'icon' => 'fa-clock',
                'title' => 'Saved audits awaiting submission',
                'message' => trans_choice(
                    ':count draft is still pending for :month.|:count drafts are still pending for :month.',
                    $draftsCount,
                    ['count' => $draftsCount, 'month' => $monthStart->format('F Y')]
                ),
            ]);
        }

        if ($criticalFindings > 0) {
            $systemAlerts->push([
                'type' => 'critical',
                'icon' => 'fa-circle-exclamation',
                'title' => 'Audit findings require attention',
                'message' => trans_choice(
                    ':count non-compliant response is recorded this month.|:count non-compliant responses are recorded this month.',
                    $criticalFindings,
                    ['count' => $criticalFindings]
                ),
            ]);
        }

        return [
            ...$taskData,
            'notifications' => $systemAlerts,
            'notificationBadgeCount' => $taskData['unreadTaskNotificationCount'],
            'calendar' => ['label' => now()->format('F Y')],
        ];
    }
}
