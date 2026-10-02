<?php

namespace App\Http\Controllers;

use App\Models\ChecklistSubmission;
use App\Models\User;
use App\Notifications\EscalationFollowUpSubmitted;
use App\Notifications\FindingFollowUpRequested;
use App\Notifications\PicTaskCompleted;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Notifications\DatabaseNotification;

class TaskNotificationController extends Controller
{
    private const TASK_NOTIFICATION_TYPES = [
        PicTaskCompleted::class,
        FindingFollowUpRequested::class,
        EscalationFollowUpSubmitted::class,
    ];

    public function status(Request $request, NotificationService $notificationService): JsonResponse
    {
        $user = $this->recipient($request);
        $data = $notificationService->getTaskNotificationData($user);

        return response()->json([
            'current_count' => $data['taskNotifications']->count(),
            'unread_count' => $data['unreadTaskNotificationCount'],
            'history_count' => $data['taskNotificationHistory']->count(),
            'html' => view('partials.task-notifications-list', [
                'activeTaskNotifications' => $data['taskNotifications'],
            ])->render(),
            'history_html' => view('partials.task-notification-history', [
                'historicalTaskNotifications' => $data['taskNotificationHistory'],
            ])->render(),
        ])->header('Cache-Control', 'no-store, no-cache, must-revalidate');
    }

    public function viewTask(Request $request, string $notification): RedirectResponse
    {
        $record = $this->taskNotification($request, $notification);

        if ($record->read_at === null) {
            $record->markAsRead();
        }

        $data = is_array($record->data) ? $record->data : [];
        if (! filled(data_get($data, 'archived_at'))) {
            $data['archived_at'] = now()->toISOString();
            $record->data = $data;
            $record->save();
        }

        $templateSlug = trim((string) data_get($data, 'template_slug'));
        $standardsType = data_get($data, 'standards_type');
        $fiveSArea = data_get($data, 'five_s_area');
        $submissionId = (int) data_get($data, 'submission_id', 0);
        $submission = $submissionId > 0
            ? ChecklistSubmission::query()->find($submissionId)
            : null;
        $isRestroom = preg_match('/^restroom-\d+-(male|female|pwd)$/i', $templateSlug) === 1
            || $submission?->branch_restroom_id !== null;

        if (! in_array($standardsType, ['sales', 'aftersales', 'five_s'], true)) {
            $standardsType = $isRestroom ? 'five_s' : match ($templateSlug) {
                'dealer-operations-standards-sales' => 'sales',
                'dealer-operations-standards' => 'aftersales',
                'sales', 'service', 'restroom', 'utilities' => 'five_s',
                default => null,
            };
        }

        if ($standardsType === 'five_s' && ! in_array($fiveSArea, ['sales', 'service', 'restroom'], true)) {
            $fiveSArea = $isRestroom ? 'restroom' : match ($templateSlug) {
                'sales' => 'sales',
                'service' => 'service',
                'restroom', 'utilities' => 'restroom',
                default => null,
            };
        }

        $event = data_get($data, 'event');
        if (in_array($event, ['finding_follow_up_requested', 'escalation_follow_up_submitted'], true)) {
            $auditDate = trim((string) data_get($data, 'audit_date'));
            $auditMonth = preg_match('/^\d{4}-\d{2}/', $auditDate) === 1
                ? substr($auditDate, 0, 7)
                : null;

            return redirect()->route('dashboard', $this->filledParameters([
                'tab' => 'follow-up',
                'form' => $standardsType,
                'score_view' => 'user',
                'branch' => data_get($data, 'branch'),
                'template' => $templateSlug,
                'month' => $auditMonth,
                'user_id' => data_get($data, 'auditor_user_id') ?: data_get($data, 'completed_by_user_id'),
                'user_type' => data_get($data, 'auditor_role') ?: data_get($data, 'completed_by_role'),
                'submission_id' => data_get($data, 'submission_id'),
                'follow_up_response_id' => data_get($data, 'response_id'),
                'follow_up_event' => $event,
            ]));
        }

        if ($standardsType !== null) {
            return redirect()->route('dashboard', $this->filledParameters([
                'tab' => 'overview',
                'form' => $standardsType,
                'five_s_area' => $standardsType === 'five_s' ? $fiveSArea : null,
                'branch' => data_get($data, 'branch'),
                'user_id' => data_get($data, 'completed_by_user_id'),
                'user_type' => data_get($data, 'completed_by_role'),
                'submission_id' => data_get($data, 'submission_id'),
                'restroom_area' => $fiveSArea === 'restroom' ? ($submission?->restroom_area ?? data_get($data, 'restroom_area')) : null,
                'restroom_id' => $fiveSArea === 'restroom' ? ($submission?->branch_restroom_id ?? data_get($data, 'restroom_id')) : null,
                'restroom_gender' => $fiveSArea === 'restroom' ? ($submission?->restroom_gender ?? data_get($data, 'restroom_gender')) : null,
            ]));
        }

        return redirect()->route('dashboard', $this->filledParameters([
            'tab' => 'reports',
            'template' => $templateSlug,
            'branch' => data_get($data, 'branch'),
            'status' => 'submitted',
            'date_from' => data_get($data, 'audit_date'),
            'date_to' => data_get($data, 'audit_date'),
            'user_id' => data_get($data, 'completed_by_user_id'),
            'user_type' => data_get($data, 'completed_by_role'),
        ]));
    }

    public function markViewed(Request $request, string $notification): JsonResponse
    {
        $record = $this->taskNotification($request, $notification);

        if ($record->read_at === null) {
            $record->markAsRead();
            $record->refresh();
        }

        return response()->json([
            'id' => $record->getKey(),
            'status' => 'viewed',
            'viewed_at' => $record->read_at?->toISOString(),
        ]);
    }

    public function markAllViewed(Request $request): JsonResponse
    {
        $user = $this->recipient($request);
        $validated = $request->validate([
            'ids' => ['sometimes', 'array', 'max:30'],
            'ids.*' => ['required', 'uuid', 'distinct'],
        ]);
        $records = $user->unreadNotifications()
            ->whereIn('type', self::TASK_NOTIFICATION_TYPES)
            ->when(array_key_exists('ids', $validated), fn ($query) => $query->whereKey($validated['ids']))
            ->get();
        $viewedAt = now();

        if ($records->isNotEmpty()) {
            $user->unreadNotifications()
                ->whereIn('type', self::TASK_NOTIFICATION_TYPES)
                ->whereKey($records->modelKeys())
                ->update(['read_at' => $viewedAt]);
        }

        return response()->json([
            'status' => 'viewed',
            'marked_count' => $records->count(),
            'ids' => $records->modelKeys(),
            'viewed_at' => $viewedAt->toISOString(),
        ]);
    }

    private function recipient(Request $request): User
    {
        $user = $request->user();

        abort_unless(
            $user?->receivesTaskCompletionNotifications() === true,
            403,
            'Only the General Manager and Branch Operations Managers can view task notifications.'
        );

        return $user;
    }

    private function taskNotification(Request $request, string $notification): DatabaseNotification
    {
        $user = $this->recipient($request);

        /** @var DatabaseNotification $record */
        $record = $user->notifications()
            ->whereKey($notification)
            ->whereIn('type', self::TASK_NOTIFICATION_TYPES)
            ->firstOrFail();

        return $record;
    }

    /**
     * @param  array<string, mixed>  $parameters
     * @return array<string, mixed>
     */
    private function filledParameters(array $parameters): array
    {
        return array_filter(
            $parameters,
            static fn (mixed $value): bool => $value !== null && $value !== ''
        );
    }
}
