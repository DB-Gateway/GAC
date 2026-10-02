<?php

namespace App\Services;

use App\Http\Controllers\ChecklistController;
use App\Models\BranchRestroom;
use App\Models\ChecklistItem;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\DealerChecklistSetting;
use App\Models\User;
use App\Notifications\UtilitiesInspectionNotice;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UtilitiesInspectionService
{
    public function sync(User $user, ?CarbonImmutable $now = null): void
    {
        if ($user->account_status !== 'active' || ! $user->isUtility()) {
            return;
        }

        if ($user->branch && ! DealerChecklistSetting::isChecklistEnabled($user->branch, 'restroom')) {
            return;
        }

        $now = ($now ?? CarbonImmutable::now('Asia/Manila'))->setTimezone('Asia/Manila');
        $template = ChecklistTemplate::whereIn('slug', ['restroom', 'utilities'])
            ->where('is_active', true)->first();
        if (! $template || ($template->settings['validation_mode'] ?? null) !== 'time_slots') {
            return;
        }

        // Share the submission controller's template lock. Concurrent scheduler
        // ticks, inbox polls and manual submissions cannot submit a slot twice.
        DB::transaction(function () use ($user, $now, $template): void {
            $template = ChecklistTemplate::whereKey($template->id)->lockForUpdate()->firstOrFail();
            $template->load([
                'sections' => fn ($query) => $query->where('is_active', true),
                'sections.items' => fn ($query) => $query->where('is_active', true),
            ]);
            $template->retainAccessibleItemsFor($user);
            $items = $template->sections->flatMap->items;
            $slotKeys = collect($template->settings['time_slots'] ?? [])
                ->map(fn ($slot) => is_array($slot) ? ($slot['key'] ?? null) : $slot)
                ->filter(fn ($slot) => is_string($slot) && preg_match('/^(?:[01]\d|2[0-3]):[0-5]\d$/', $slot))
                ->unique()->sort()->values();

            $branchRestrooms = filled($user->branch)
                ? BranchRestroom::query()
                    ->whereRaw('LOWER(TRIM(branch)) = ?', [mb_strtolower(trim((string) $user->branch))])
                    ->where('is_active', true)
                    ->orderBy('sort_order')
                    ->orderBy('id')
                    ->get()
                    ->filter(fn (BranchRestroom $r): bool => $r->enabledGenders() !== [])
                    ->values()
                : collect();

            // Check if any split submissions already exist for this user.
            // If the branch only has legacy unsplit submissions, process as
            // a single target to avoid creating duplicate missed-slot entries.
            $hasSplitSubmissions = $branchRestrooms->isNotEmpty()
                && ChecklistSubmission::where('checklist_template_id', $template->id)
                    ->where('user_id', $user->id)
                    ->where(function ($q): void {
                        $q->whereNotNull('branch_restroom_id')
                            ->orWhereNotNull('restroom_area')
                            ->orWhereNotNull('restroom_gender');
                    })
                    ->exists();

            $targets = $hasSplitSubmissions
                ? $branchRestrooms->flatMap(fn (BranchRestroom $r): array => collect($r->enabledGenders())
                    ->map(fn (string $gender): array => [
                        'template' => $template->resolveRouteBinding($r->slugForGender($gender)) ?? $template,
                        'restroom_id' => $r->id,
                        'gender' => $gender,
                    ])
                    ->all())->values()->all()
                : [['template' => $template, 'restroom_id' => null, 'gender' => null]];

            // Include yesterday only for windows that close after midnight.
            foreach ([$now->subDay()->startOfDay(), $now->startOfDay()] as $day) {
                $date = $day->toDateString();

                foreach ($targets as $target) {
                    /** @var ChecklistTemplate $targetTemplate */
                    $targetTemplate = $target['template'];
                    $restroomId = $target['restroom_id'];
                    $gender = $target['gender'];

                    $submissionQuery = ChecklistSubmission::where('checklist_template_id', $template->id)
                        ->where('user_id', $user->id)
                        ->whereDate('audit_date', $date)
                        ->where('scope_key', hash('sha256', mb_strtolower(trim($user->branch ?: 'unassigned'))));

                    if ($restroomId !== null && $gender !== null) {
                        $submissionQuery->where('branch_restroom_id', $restroomId)
                            ->where('restroom_gender', $gender);
                    } else {
                        $submissionQuery->whereNull('branch_restroom_id');
                    }

                    $submission = $submissionQuery->with('responses')->latest('id')->first();
                    $responses = $submission?->responses->keyBy('item_key') ?? collect();
                    $missed = [];

                    foreach ($slotKeys as $slot) {
                        $deadline = $day->setTimeFromTimeString($slot)->addHour();
                        // Newly created accounts cannot have missed earlier work.
                        if ($user->created_at && $deadline->lessThanOrEqualTo($user->created_at)) {
                            continue;
                        }
                        if ($deadline->addMinute()->isBefore($now->startOfDay())) {
                            continue;
                        }
                        $activeItems = $items->filter(fn ($item) => $this->active($item, $slot));
                        if ($activeItems->isEmpty()) {
                            continue;
                        }
                        $submitted = $activeItems->every(function ($item) use ($responses, $submission, $slot): bool {
                            $details = $responses->get($item->key)?->details ?? [];
                            if (in_array($slot, $details['submitted_slots'] ?? [], true)) {
                                return true;
                            }
                            // Legacy submitted sheets may predate submitted_slots.
                            return ! array_key_exists('submitted_slots', $details)
                                && $submission?->status === 'submitted'
                                && in_array($details['slots'][$slot] ?? null, ['good', 'not_good', '/', 'X', 'x'], true);
                        });
                        if ($submitted) {
                            continue;
                        }
                        if ($now->greaterThanOrEqualTo($deadline->addMinute())) {
                            $missed[] = $slot;
                            continue;
                        }
                        if ($now->lessThan($deadline->subMinutes(10))) {
                            continue;
                        }
                        $dueNow = $now->greaterThanOrEqualTo($deadline);
                        $remaining = max(1, (int) ceil($now->diffInSeconds($deadline) / 60));
                        $this->notice($user, $targetTemplate, $date, $slot,
                            $dueNow ? 'utilities_due_now' : 'utilities_due_soon',
                            $dueNow ? 'Utilities inspection due now' : "Utilities inspection due in {$remaining} minutes",
                            'Finish and submit your '.$day->setTimeFromTimeString($slot)->format('g:i A')
                                .' Utilities inspection '.($dueNow ? 'now.' : 'by '.$deadline->format('g:i A').'.')
                                .' If you miss the deadline, the failed checklist will be submitted to your GM and BOM supervisors.'
                        );
                    }

                    if ($missed === []) {
                        continue;
                    }
                    $payload = $items->map(function ($item) use ($responses, $missed): array {
                        $response = $responses->get($item->key);
                        $details = $response?->details ?? [];
                        foreach ($missed as $slot) {
                            if ($this->active($item, $slot)) {
                                // An unsubmitted inspection fails even if answers
                                // were saved in a draft. Other slots stay unchanged.
                                $details['slots'][$slot] = 'not_good';
                                $details['submitted_slots'] = array_values(array_unique([
                                    ...($details['submitted_slots'] ?? []), $slot,
                                ]));
                                $details['missed_slots'] = array_values(array_unique([
                                    ...($details['missed_slots'] ?? []), $slot,
                                ]));
                            }
                        }

                        return [
                            'item_id' => $item->id,
                            'item_key' => $item->key,
                            'status' => null,
                            'remark' => $response?->remark,
                            'finding' => $response?->finding,
                            'action_plan' => $response?->action_plan,
                            'commitment_date' => $response?->commitment_date?->format('Y-m-d H:i:s'),
                            'escalation_target' => $response?->escalation_target,
                            'attachment_path' => $response?->attachment_path,
                            'details' => $details,
                        ];
                    })->all();

                    // Reuse normal validation, scoring, report snapshots and manager
                    // routing. This attribute is internal, never a client input.
                    $request = Request::create('/internal/utilities-deadline', 'POST', [
                        'date' => $date,
                        'branch' => $user->branch,
                        'context' => $submission?->context,
                        'responses' => $payload,
                    ]);
                    $request->setUserResolver(fn () => $user);
                    $request->headers->set('X-Client-Time', $now->toIso8601String());
                    $request->attributes->set('utilities_missed_slots', $missed);
                    $result = app(ChecklistController::class)->submit($request, $targetTemplate, app(TaskCompletionNotifier::class));
                    $submissionId = $result->getData(true)['submission']['id'];
                    foreach ($missed as $slot) {
                        $this->notice($user, $targetTemplate, $date, $slot, 'utilities_inspection_missed',
                            'You missed your Utilities inspection',
                            'You missed your '.$day->setTimeFromTimeString($slot)->format('g:i A')
                                .' Utilities task. The failed checklist has been automatically submitted to your GM and BOM supervisors for review.',
                            $submissionId
                        );
                    }
                }
            }
        });
    }

    private function active(ChecklistItem $item, string $slot): bool
    {
        $active = $item->metadata['active_slots'] ?? null;

        return ! is_array($active) || in_array($slot, $active, true);
    }

    private function notice(User $user, ChecklistTemplate $template, string $date, string $slot, string $event, string $title, string $message, ?int $submissionId = null): void
    {
        if ($user->notifications()->where('type', UtilitiesInspectionNotice::class)
            ->where('data->event', $event)->where('data->audit_date', $date)
            ->where('data->template_slug', $template->slug)->where('data->slot_key', $slot)->exists()) {
            return;
        }
        $user->notify(new UtilitiesInspectionNotice([
            'event' => $event, 'title' => $title, 'message' => $message,
            'template_slug' => $template->slug, 'template_name' => $template->name,
            'audit_date' => $date, 'slot_key' => $slot, 'submission_id' => $submissionId,
            'branch' => $user->branch,
        ]));
    }
}
