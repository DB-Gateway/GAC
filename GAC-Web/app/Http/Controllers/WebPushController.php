<?php

namespace App\Http\Controllers;

use App\Models\WebPushSubscription;
use App\Notifications\ChecklistDraftReminder;
use App\Notifications\EscalationFollowUpSubmitted;
use App\Notifications\FindingFollowUpRequested;
use App\Notifications\PicTaskCompleted;
use App\Rules\BrowserPushEndpoint;
use App\Services\WebPushService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class WebPushController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        abort_unless(WebPushService::configured(), 503, 'Device notifications are not configured yet.');
        abort_if($request->hasHeader('X-GAC-Account') && $request->header('X-GAC-Account') !== (string) $request->user()->id,
            409, 'Your signed-in account changed. Please reload this page.');

        $data = $request->validate([
            'endpoint' => ['required', 'string', 'max:2048', new BrowserPushEndpoint],
            'keys' => ['required', 'array'],
            'keys.p256dh' => ['required', 'string', 'regex:/^[A-Za-z0-9_-]{87}=?$/'],
            'keys.auth' => ['required', 'string', 'regex:/^[A-Za-z0-9_-]{22}(==)?$/'],
        ]);
        $publicKey = base64_decode(strtr($data['keys']['p256dh'], '-_', '+/'), true);
        abort_unless(strlen($publicKey ?: '') === 65 && $publicKey[0] === "\x04", 422, 'Invalid subscription public key.');

        $token = $request->cookie(WebPushSubscription::COOKIE) ?: Str::random(64);
        $tokenHash = hash('sha256', $token);
        $endpointHash = hash('sha256', $data['endpoint']);

        // One browser subscription belongs to the account currently using that device.
        DB::transaction(function () use ($request, $data, $tokenHash, $endpointHash): void {
            WebPushSubscription::where('device_token_hash', $tokenHash)
                ->where('endpoint_hash', '!=', $endpointHash)->delete();
            // A new ID also invalidates queued jobs if this browser switches accounts and back again.
            WebPushSubscription::where('endpoint_hash', $endpointHash)
                ->where('user_id', '!=', $request->user()->id)->delete();
            WebPushSubscription::updateOrCreate(['endpoint_hash' => $endpointHash], [
                'user_id' => $request->user()->id,
                'endpoint' => $data['endpoint'],
                'public_key' => $data['keys']['p256dh'],
                'auth_token' => $data['keys']['auth'],
                'device_token_hash' => $tokenHash,
            ]);
        });

        return response()->json(['enabled' => true])->cookie(
            WebPushSubscription::COOKIE, $token, 60 * 24 * 365,
            config('session.path', '/'), config('session.domain'), $request->isSecure(), true, false, 'lax'
        );
    }

    public function destroy(Request $request): JsonResponse
    {
        abort_if($request->hasHeader('X-GAC-Account') && $request->header('X-GAC-Account') !== (string) $request->user()->id,
            409, 'Your signed-in account changed. Please reload this page.');
        $data = $request->validate(['endpoint' => ['sometimes', 'nullable', 'string', 'max:2048']]);
        $query = WebPushSubscription::where('user_id', $request->user()->id);
        if (! empty($data['endpoint'])) {
            $query->where('endpoint_hash', hash('sha256', $data['endpoint']))->delete();
        } elseif ($token = $request->cookie(WebPushSubscription::COOKIE)) {
            $query->where('device_token_hash', hash('sha256', $token))->delete();
        }

        return response()->json(['enabled' => false]);
    }

    public function open(Request $request, string $notification): RedirectResponse
    {
        $record = $request->user()->notifications()->findOrFail($notification);
        if (in_array($record->type, [PicTaskCompleted::class, FindingFollowUpRequested::class, EscalationFollowUpSubmitted::class], true)) {
            return redirect()->route('notifications.view-task', $record->id);
        }

        if ($record->type === ChecklistDraftReminder::class
            && $request->user()->canAccessChecklist($record->data['template_slug'] ?? '')) {
            $record->markAsRead();

            return redirect()->route('checklists.index', [
                'checklist' => $record->data['template_slug'],
                'date' => $record->data['audit_date'] ?? null,
                'branch' => $record->data['branch'] ?? null,
            ]);
        }

        return redirect()->route('dashboard');
    }

    public function manifest(): JsonResponse
    {
        return response()->json([
            'id' => url('/'),
            'name' => 'Gateway Audit Compliance',
            'short_name' => 'GAC',
            'start_url' => route('dashboard'),
            'scope' => url('/').'/',
            'display' => 'standalone',
            'background_color' => '#f5f6f8',
            'theme_color' => '#b91c1c',
            'icons' => [
                ['src' => asset('images/push-icon-192.png'), 'sizes' => '192x192', 'type' => 'image/png'],
                ['src' => asset('images/push-icon-512.png'), 'sizes' => '512x512', 'type' => 'image/png'],
            ],
        ])->header('Content-Type', 'application/manifest+json');
    }
}
