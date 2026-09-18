<?php

namespace App\Http\Controllers;

use App\Models\ChecklistSubmission;
use App\Models\User;
use App\Notifications\ChecklistDraftReminder;
use App\Services\DraftFollowUpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DraftFollowUpController extends Controller
{
    public function index(Request $request, DraftFollowUpService $drafts): JsonResponse
    {
        $manager = $this->manager($request);
        $records = $drafts->pendingDrafts($manager);

        return response()->json(['drafts' => $records->map($drafts->details(...))->values()])->header('Cache-Control', 'no-store');
    }

    public function remind(Request $request, ChecklistSubmission $submission, DraftFollowUpService $drafts): JsonResponse
    {
        $manager = $this->manager($request);
        abort_unless($manager->hasAdministrativeAccess()
            || (filled($manager->branch) && mb_strtolower(trim((string) $manager->branch)) === mb_strtolower(trim((string) $submission->branch))), 403);

        return DB::transaction(function () use ($submission, $drafts, $manager): JsonResponse {
            $draft = ChecklistSubmission::query()->whereKey($submission->id)->lockForUpdate()->firstOrFail();
            abort_unless($draft->status === 'draft', 409, 'This checklist has already been submitted. Refresh the draft list.');
            $details = $drafts->details($draft);
            abort_unless($details['can_remind'], 422, $details['unavailable_reason']);

            $recent = $draft->user->notifications()->where('type', ChecklistDraftReminder::class)
                ->where('data->submission_id', $draft->id)->where('created_at', '>=', now()->subMinute())->latest()->first();
            if ($recent) {
                return response()->json(['message' => 'A reminder was just sent to this user.', 'already_sent' => true, 'sent_at' => $recent->created_at->toISOString()]);
            }

            $draft->user->notify(new ChecklistDraftReminder($details, $manager));

            return response()->json(['message' => 'Reminder sent to '.$details['user_name'].' in the mobile app.', 'already_sent' => false, 'sent_at' => now()->toISOString()], 201);
        });
    }

    private function manager(Request $request): User
    {
        $user = $request->user();
        abort_unless($user?->receivesTaskCompletionNotifications() === true, 403, 'Only GM and BOM users can follow up on drafted checklists.');

        return $user;
    }
}
