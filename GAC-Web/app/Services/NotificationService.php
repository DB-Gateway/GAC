<?php

namespace App\Services;

use App\Models\ChecklistSubmission;
use App\Models\User;
use App\Notifications\PicTaskCompleted;
use Illuminate\Support\Collection;

class NotificationService
{
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
        $canReceiveTaskNotifications = $user?->receivesTaskCompletionNotifications() === true;

        $taskNotificationFeed = $canReceiveTaskNotifications && $user !== null
            ? $user->notifications()
                ->where('type', PicTaskCompleted::class)
                ->latest()
                ->limit(100)
                ->get()
            : collect();

        $taskNotifications = $taskNotificationFeed
            ->reject(fn ($notification): bool => filled(data_get($notification->data, 'archived_at')))
            ->take(30)
            ->values();
        $taskNotificationHistory = $taskNotificationFeed
            ->filter(fn ($notification): bool => filled(data_get($notification->data, 'archived_at')))
            ->take(50)
            ->values();
        $unreadTaskNotificationCount = $taskNotifications
            ->filter(fn ($notification): bool => $notification->read_at === null)
            ->count();

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

        if ($draftsCount > 0) {
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
            'taskNotifications' => $taskNotifications,
            'taskNotificationHistory' => $taskNotificationHistory,
            'unreadTaskNotificationCount' => $unreadTaskNotificationCount,
            'canReceiveTaskNotifications' => $canReceiveTaskNotifications,
            'notifications' => $systemAlerts,
            'notificationBadgeCount' => $unreadTaskNotificationCount,
            'calendar' => ['label' => now()->format('F Y')],
        ];
    }
}
