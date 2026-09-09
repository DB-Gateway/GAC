<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Notifications\PicTaskCompleted;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Notifications\DatabaseNotification;

class TaskNotificationController extends Controller
{
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

        if (! in_array($standardsType, ['sales', 'aftersales'], true)) {
            $standardsType = match ($templateSlug) {
                'dealer-operations-standards-sales' => 'sales',
                'dealer-operations-standards' => 'aftersales',
                default => null,
            };
        }

        if ($standardsType !== null) {
            return redirect()->route('dashboard', $this->filledParameters([
                'tab' => 'overview',
                'form' => $standardsType,
                'branch' => data_get($data, 'branch'),
                'user_id' => data_get($data, 'completed_by_user_id'),
                'user_type' => data_get($data, 'completed_by_role'),
                'submission_id' => data_get($data, 'submission_id'),
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
        $records = $user->unreadNotifications()
            ->where('type', PicTaskCompleted::class)
            ->get();
        $viewedAt = now();

        if ($records->isNotEmpty()) {
            $user->unreadNotifications()
                ->where('type', PicTaskCompleted::class)
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
            ->where('type', PicTaskCompleted::class)
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
