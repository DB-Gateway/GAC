<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Notifications\DatabaseNotification;
use Illuminate\Support\Str;

class NotificationController extends Controller
{
    /**
     * Return every database-notification type belonging to the signed-in user.
     */
    public function index(Request $request): JsonResponse
    {
        $notifications = $request->user()
            ->notifications()
            ->get();

        return response()->json([
            'notifications' => $notifications
                ->map(fn (DatabaseNotification $notification): array => $this->payload($notification))
                ->values(),
            'unread_count' => $notifications
                ->filter(fn (DatabaseNotification $notification): bool => $notification->unread())
                ->count(),
        ]);
    }

    /**
     * Mark one notification owned by the signed-in user as read.
     */
    public function markRead(Request $request, string $notification): JsonResponse
    {
        /** @var DatabaseNotification $record */
        $record = $request->user()
            ->notifications()
            ->whereKey($notification)
            ->firstOrFail();

        $record->markAsRead();
        $record->refresh();

        return response()->json([
            'message' => 'Notification marked as read.',
            'notification' => $this->payload($record),
            'unread_count' => $request->user()->unreadNotifications()->count(),
        ]);
    }

    /**
     * Mark all unread notifications owned by the signed-in user as read.
     */
    public function markAllRead(Request $request): JsonResponse
    {
        $unreadNotifications = $request->user()
            ->unreadNotifications()
            ->get();
        $readAt = now();

        if ($unreadNotifications->isNotEmpty()) {
            $request->user()
                ->unreadNotifications()
                ->whereKey($unreadNotifications->modelKeys())
                ->update(['read_at' => $readAt]);
        }

        return response()->json([
            'message' => 'Notifications marked as read.',
            'marked_count' => $unreadNotifications->count(),
            'ids' => $unreadNotifications->modelKeys(),
            'read_at' => $readAt->toISOString(),
            'unread_count' => 0,
        ]);
    }

    /**
     * Expose a stable mobile contract without leaking PHP notification class names.
     *
     * @return array<string, mixed>
     */
    private function payload(DatabaseNotification $notification): array
    {
        $data = is_array($notification->data) ? $notification->data : [];
        $type = trim((string) ($data['event'] ?? ''));

        if ($type === '') {
            $type = Str::snake(class_basename($notification->type));
        }

        $title = trim((string) ($data['title'] ?? ''));

        return [
            'id' => (string) $notification->getKey(),
            'type' => $type,
            'title' => $title !== '' ? $title : Str::headline($type),
            'message' => trim((string) ($data['message'] ?? '')),
            'data' => $data,
            'unread' => $notification->unread(),
            'read_at' => $notification->read_at?->toISOString(),
            'created_at' => $notification->created_at?->toISOString(),
        ];
    }
}
