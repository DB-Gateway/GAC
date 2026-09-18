<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChecklistResponse;
use App\Models\Report;
use App\Models\User;
use App\Notifications\EscalationFollowUpSubmitted;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Throwable;

class EscalationFollowUpController extends Controller
{
    public const REMARKS = [
        'in_progress' => 'Corrective action in progress',
        'awaiting_approval' => 'Awaiting approval or budget',
        'awaiting_materials' => 'Awaiting supplies or replacement parts',
        'repair_scheduled' => 'Repair or maintenance scheduled',
        'cleaning_completed' => 'Cleaning or organization completed',
        'records_updating' => 'Documents or records being updated',
        'training_scheduled' => 'Staff briefing or training scheduled',
        'awaiting_it' => 'Awaiting IT or system access support',
        'ready_for_verification' => 'Completed; ready for verification',
        'others' => 'Others',
    ];

    public function store(Request $request, string $notification): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->account_status === 'active', 403, 'Your account is not active.');
        $record = $user->notifications()->whereKey($notification)->firstOrFail();
        abort_unless(data_get($record->data, 'event') === 'finding_escalated', 422, 'Only escalation notifications accept a follow-up.');
        abort_if(data_get($record->data, 'has_follow_up') === true && ! Report::where('type', 'escalation_follow_up')
            ->where('generated_by_user_id', $user->getKey())
            ->where('data_snapshot->source_notification_id', $record->getKey())
            ->where('data_snapshot->request_id', $request->input('request_id'))
            ->exists(), 409, 'A follow-up has already been submitted for this escalation.');

        $validated = $request->validate([
            'request_id' => ['required', 'string', 'size:32', 'regex:/^[a-f0-9]+$/'],
            'remark_option' => ['required', Rule::in(array_keys(self::REMARKS))],
            'remarks' => ['exclude_unless:remark_option,others', 'required', 'string', 'max:2000', 'regex:/\S/u'],
            'photos' => ['sometimes', 'array', 'max:3'],
            'photos.*' => ['required', 'file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:10240'],
        ], [
            'remarks.required' => 'Enter your follow-up remarks.',
            'remarks.regex' => 'Enter your follow-up remarks.',
            'remark_option.required' => 'Choose a remark to continue.',
        ]);

        $response = ChecklistResponse::with('submission.template')
            ->findOrFail(data_get($record->data, 'response_id'));
        $submission = $response->submission;
        $slug = data_get($submission?->template_snapshot, 'slug') ?: $submission?->template?->slug;
        abort_unless($submission && (int) $submission->user_id === (int) $user->getKey()
            && mb_strtolower(trim((string) $submission->branch)) === mb_strtolower(trim((string) $user->branch))
            && $user->canAccessChecklist((string) $slug), 403, 'This finding is no longer assigned to your account.');

        $manager = User::find(data_get($record->data, 'sender_user_id'));
        abort_unless($manager && $manager->account_status === 'active'
            && $manager->receivesTaskCompletionNotifications(), 422, 'The original escalating manager is no longer available. Contact your branch manager.');

        $storedPaths = [];
        try {
            [$report, $created] = DB::transaction(function () use ($user, $record, $validated, $request, $submission, $manager, &$storedPaths): array {
                // Serialize retries before checking the request ID.
                $record = $user->notifications()->whereKey($record->getKey())->lockForUpdate()->firstOrFail();
                $existing = Report::where('type', 'escalation_follow_up')
                    ->where('generated_by_user_id', $user->getKey())
                    ->where('data_snapshot->source_notification_id', $record->getKey())
                    ->first();
                if ($existing) {
                    if (data_get($existing->data_snapshot, 'request_id') === $validated['request_id']) {
                        return [$existing, false];
                    }
                    abort(409, 'A follow-up has already been submitted for this escalation.');
                }

                $photos = [];
                foreach ($request->file('photos', []) as $photo) {
                    $path = $photo->store('escalation-follow-ups/'.$user->getKey(), 'public');
                    if (! $path) {
                        throw new \RuntimeException('The follow-up photo could not be stored.');
                    }
                    $storedPaths[] = $path;
                    $photos[] = ['path' => $path, 'url' => Storage::disk('public')->url($path)];
                }

                $remarks = $validated['remark_option'] === 'others'
                    ? trim($validated['remarks']) : self::REMARKS[$validated['remark_option']];
                $snapshot = array_merge(Arr::only($record->data, [
                    'response_id', 'submission_id', 'template_slug', 'template_name', 'item_key',
                    'question', 'finding', 'branch', 'audit_date', 'escalation_target',
                    'escalation_target_label', 'commitment_date', 'action_plan',
                ]), [
                    'source_notification_id' => $record->getKey(),
                    'request_id' => $validated['request_id'],
                    'remark_option' => $validated['remark_option'],
                    'remarks' => $remarks,
                    'photos' => $photos,
                    'sender_user_id' => $user->getKey(),
                    'sender_name' => $user->name,
                    'sender_role' => $user->roleCode(),
                    'recipient_user_id' => $manager->getKey(),
                    'recipient_name' => $manager->name,
                    'created_at' => now()->toISOString(),
                ]);

                $report = Report::create([
                    'checklist_submission_id' => $submission->getKey(),
                    'checklist_template_id' => $submission->checklist_template_id,
                    'generated_by_user_id' => $user->getKey(),
                    'type' => 'escalation_follow_up',
                    'title' => Str::limit('Escalation follow-up from '.$user->name, 255, ''),
                    'status' => 'completed',
                    'data_snapshot' => $snapshot,
                    'generated_at' => now(),
                ]);
                $manager->notify(new EscalationFollowUpSubmitted($snapshot + ['follow_up_id' => $report->getKey()]));

                $recordData = is_array($record->data) ? $record->data : [];
                $record->data = array_merge($recordData, [
                    'has_follow_up' => true,
                    'follow_up_submitted_at' => now()->toISOString(),
                    'follow_up_report_id' => $report->getKey(),
                    'follow_up_action_taken' => $remarks,
                    'follow_up_recipient_name' => $manager->name,
                ]);
                $record->save();

                return [$report, true];
            });
        } catch (Throwable $error) {
            if ($storedPaths !== []) {
                Storage::disk('public')->delete($storedPaths);
            }
            throw $error;
        }

        return response()->json([
            'message' => 'Follow-up sent to the escalating manager.',
            'follow_up' => [
                'id' => $report->getKey(),
                'remarks' => data_get($report->data_snapshot, 'remarks'),
                'recipient_name' => data_get($report->data_snapshot, 'recipient_name'),
                'created_at' => data_get($report->data_snapshot, 'created_at'),
            ],
        ], $created ? 201 : 200);
    }
}
