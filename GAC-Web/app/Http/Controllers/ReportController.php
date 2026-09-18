<?php

namespace App\Http\Controllers;

use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\Report;
use App\Models\User;
use App\Notifications\FindingFollowUpRequested;
use App\Notifications\FindingEscalated;
use Carbon\CarbonImmutable;
use Illuminate\Contracts\View\View;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportController extends Controller
{
    private const RECENCY_OPTIONS = [
        '24h' => 'Last 24 hours',
        '7d' => 'Last 7 days',
        '30d' => 'Last 30 days',
        '90d' => 'Last 90 days',
    ];

    /**
     * Display the database-backed reporting workspace.
     */
    public function index(Request $request): View
    {
        $filters = $this->filters($request);
        $submissions = $this->submissionQuery($request, $filters)->get();
        $reportData = $this->reportData($submissions, $request->user());

        $selectedMonth = $filters['month'] ?? now()->format('Y-m');
        $selectedCarbon = null;
        try {
            $selectedCarbon = CarbonImmutable::parse($selectedMonth.'-01');
        } catch (\Throwable) {
            $selectedCarbon = now()->toImmutable();
        }

        return view('reports.index', [
            ...$reportData,
            'filters' => $filters,
            'selectedMonth' => $selectedMonth,
            'selectedMonthLabel' => $selectedCarbon->format('F Y'),
            'prevMonth' => $selectedCarbon->subMonth()->format('Y-m'),
            'nextMonth' => $selectedCarbon->addMonth()->format('Y-m'),
            'currentMonth' => now()->format('Y-m'),
            'reportScope' => $this->accessScope($request),
            'branchOptions' => $this->reportableSubmissionQuery($request)
                ->whereNotNull('branch')
                ->where('branch', '<>', '')
                ->distinct()
                ->orderBy('branch')
                ->pluck('branch'),
            'templateOptions' => $this->templateOptions($request),
            'statusOptions' => ['submitted', 'draft'],
            'roleOptions' => User::roleOptions(),
            'recencyOptions' => self::RECENCY_OPTIONS,
            'escalationOptions' => ChecklistResponse::escalationTargetOptions(),
            'canOverrideAny' => $request->user()?->canOverrideChecklistResponses() ?? false,
            'canViewFindings' => $request->user()?->roleCode() === User::ROLE_ADMINISTRATOR,
            'canManageEscalations' => $request->user()?->roleCode() === User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'followUpResponseId' => (int) $request->query('follow_up_response_id', 0),
            'reportTimezone' => $this->reportTimezone(),
        ]);
    }

    /**
     * Download the filtered audit history or findings register and record the export in reports.
     */
    public function export(Request $request): StreamedResponse
    {
        $filters = $this->filters($request);
        $submissions = $this->submissionQuery($request, $filters)->get();
        $reportData = $this->reportData($submissions, $request->user());

        if (($filters['export_type'] ?? '') === 'findings') {
            return $this->exportFindings($request, $filters, $submissions, $reportData);
        }

        $filename = 'gateway-audit-report-'.now()->format('Y-m-d-His').'.csv';

        $report = Report::query()->create([
            'checklist_template_id' => $filters['template']
                ? ChecklistTemplate::query()->where('slug', $filters['template'])->value('id')
                : null,
            'generated_by_user_id' => $request->user()?->getKey(),
            'type' => 'csv_export',
            'title' => 'Checklist audit CSV export',
            'status' => 'ready',
            'filters' => array_filter($filters, static fn (mixed $value): bool => $value !== null && $value !== ''),
            'data_snapshot' => [
                'format' => 'csv',
                'filename' => $filename,
                'row_count' => $submissions->count(),
                'submission_ids' => $submissions->pluck('id')->values()->all(),
                'summary' => $reportData['summary'],
                'access_scope' => $this->accessScope($request),
            ],
            'generated_at' => now(),
        ]);

        $history = $reportData['history'];

        return response()->streamDownload(function () use ($history, $report): void {
            $handle = fopen('php://output', 'wb');

            if ($handle === false) {
                return;
            }

            fwrite($handle, "\xEF\xBB\xBF");
            fputcsv($handle, [
                'Export ID',
                'Submission ID',
                'Audit Date',
                'Checklist',
                'Template Slug',
                'Branch',
                'Scope',
                'Submitted By',
                'Submitter Email',
                'User Type',
                'Status',
                'Score (%)',
                'Completion (%)',
                'YES / Good',
                'NO / Bad',
                'N/A',
                'Answered',
                'Expected',
                'Findings',
                'Submitted At ('.$this->reportTimezone().')',
            ], ',', '"', '\\', "\r\n");

            foreach ($history as $record) {
                fputcsv($handle, array_map($this->csvValue(...), [
                    $report->getKey(),
                    $record['id'],
                    $record['audit_date'],
                    $record['template_name'],
                    $record['template_slug'],
                    $record['branch'],
                    $record['scope'],
                    $record['submitter_name'],
                    $record['submitter_email'],
                    $record['submitter_role_label'],
                    $record['status'],
                    $record['score'],
                    $record['completion'],
                    $record['yes'],
                    $record['no'],
                    $record['na'],
                    $record['answered'],
                    $record['total'],
                    $record['findings_count'],
                    $record['submitted_at_local'],
                ]), ',', '"', '\\', "\r\n");
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    /**
     * Dedicated route to export findings / NO answers CSV.
     */
    public function exportFindingsCsv(Request $request): StreamedResponse
    {
        $request->merge(['export_type' => 'findings']);

        return $this->export($request);
    }

    private function exportFindings(Request $request, array $filters, Collection $submissions, array $reportData): StreamedResponse
    {
        $filename = 'gateway-audit-findings-'.now()->format('Y-m-d-His').'.csv';
        $findings = $reportData['findings'];

        $report = Report::query()->create([
            'checklist_template_id' => $filters['template']
                ? ChecklistTemplate::query()->where('slug', $filters['template'])->value('id')
                : null,
            'generated_by_user_id' => $request->user()?->getKey(),
            'type' => 'csv_export_findings',
            'title' => 'Checklist NO answers and findings CSV export',
            'status' => 'ready',
            'filters' => array_filter($filters, static fn (mixed $value): bool => $value !== null && $value !== ''),
            'data_snapshot' => [
                'format' => 'csv',
                'filename' => $filename,
                'row_count' => $findings->count(),
                'submission_ids' => $submissions->pluck('id')->values()->all(),
                'summary' => $reportData['summary'],
                'access_scope' => $this->accessScope($request),
            ],
            'generated_at' => now(),
        ]);

        return response()->streamDownload(function () use ($findings, $report): void {
            $handle = fopen('php://output', 'wb');

            if ($handle === false) {
                return;
            }

            fwrite($handle, "\xEF\xBB\xBF");
            fputcsv($handle, [
                'Export ID',
                'Submission ID',
                'Response ID',
                'Audit Date',
                'Branch',
                'Checklist',
                'Auditor',
                'Auditor Role',
                'Section / Area',
                'Item Code',
                'Check Item / Prompt',
                'Result',
                'Finding / Remark',
                'Action Plan',
                'BOM Suggested Escalation',
                'Commitment Date & Time',
                'Due / Overdue Status',
                'Overridden',
                'Overridden By',
                'Overridden Role',
                'Override Date',
                'Override Reason',
            ], ',', '"', '\\', "\r\n");

            foreach ($findings as $finding) {
                $override = $finding['override_details'] ?? [];
                fputcsv($handle, array_map($this->csvValue(...), [
                    $report->getKey(),
                    $finding['submission_id'],
                    $finding['response_id'],
                    $finding['audit_date'],
                    $finding['branch'],
                    $finding['template_name'],
                    $finding['auditor'],
                    $finding['auditor_role'],
                    $finding['area'],
                    $finding['item_key'],
                    $finding['item'],
                    $finding['result'],
                    $finding['detail'],
                    $finding['action_plan'],
                    $finding['escalation_target_label'] ?? 'None',
                    $finding['commitment_date_formatted'] ?? 'Not set',
                    $finding['due_status'] ?? ($finding['is_overdue'] ? 'Overdue' : '—'),
                    $finding['is_overridden'] ? 'YES' : 'NO',
                    $override['overridden_by_name'] ?? '—',
                    $override['overridden_by_role'] ?? '—',
                    isset($override['overridden_at']) ? Carbon::parse($override['overridden_at'])->timezone($this->reportTimezone())->format('d M Y, h:i A') : '—',
                    $override['reason'] ?? '—',
                ]), ',', '"', '\\', "\r\n");
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    /**
     * Override and edit a checklist response. Accessible strictly to BOM and GM.
     */
    public function overrideResponse(Request $request, ChecklistResponse $response): JsonResponse
    {
        $user = $request->user();
        if (! $user || ! $user->canOverrideChecklistResponse($response)) {
            return response()->json([
                'message' => 'Only Branch Operations Managers (BOM) and General Managers (GM) are authorized to override and edit checklist NO answers.',
            ], 403);
        }

        if ($request->has('escalation_target')) {
            $request->merge([
                'escalation_target' => ChecklistResponse::normalizeEscalationTarget(
                    $request->input('escalation_target')
                ),
            ]);
        }

        $allowedEscalations = array_keys(ChecklistResponse::escalationTargetOptions());

        $validated = $request->validate([
            'status' => ['required', 'string', Rule::in(['yes', 'no', 'na'])],
            'escalation_target' => ['nullable', 'string', Rule::in($allowedEscalations)],
            'commitment_date' => ['nullable', 'string'],
            'action_plan' => ['nullable', 'string', 'max:10000'],
            'finding' => ['nullable', 'string', 'max:10000'],
            'remark' => ['nullable', 'string', 'max:10000'],
            'override_reason' => ['nullable', 'string', 'max:1000'],
        ]);

        $submission = $response->submission;
        if (! $submission) {
            return response()->json(['message' => 'Submission not found for this response.'], 404);
        }

        $previousStatus = $response->status;
        $newStatus = Str::lower(trim($validated['status']));
        $reportTimezone = $this->reportTimezone();
        $normalizedCommitmentDate = null;
        if (! blank($validated['commitment_date'] ?? null)) {
            $parsed = null;
            foreach (['Y-m-d H:i:s', 'Y-m-d\TH:i:s', 'Y-m-d\TH:i', 'Y-m-d H:i', 'Y-m-d'] as $fmt) {
                try {
                    $d = CarbonImmutable::createFromFormat('!'.$fmt, trim($validated['commitment_date']), $reportTimezone);
                    if ($d !== false) {
                        $parsed = $d->format('Y-m-d H:i:s');
                        break;
                    }
                } catch (\Throwable) {
                }
            }
            $normalizedCommitmentDate = $parsed ?? $validated['commitment_date'];
        }

        $details = is_array($response->details) ? $response->details : [];
        if (! isset($details['original_status'])) {
            $details['original_status'] = $previousStatus;
        }

        $details['override'] = [
            'overridden_by_id' => $user->getKey(),
            'overridden_by_name' => $user->name,
            'overridden_by_role' => $user->roleLabel(),
            'overridden_at' => now()->toIso8601String(),
            'previous_status' => $previousStatus,
            'new_status' => $newStatus,
            'reason' => trim((string) ($validated['override_reason'] ?? 'Updated by '.$user->roleLabel())),
            'override_reason' => trim((string) ($validated['override_reason'] ?? 'Updated by '.$user->roleLabel())),
        ];

        $targetInput = $this->nullableFilter($validated['escalation_target'] ?? null);
        $escalationTarget = ChecklistResponse::normalizeEscalationTarget($targetInput);

        if ($escalationTarget) {
            $details['escalation_target'] = $escalationTarget;
            $details['escalation'] = $escalationTarget;
        } else {
            unset($details['escalation_target'], $details['escalation']);
        }

        $response->status = $newStatus;
        $response->escalation_target = $escalationTarget;
        $response->commitment_date = $normalizedCommitmentDate;
        if (array_key_exists('action_plan', $validated)) {
            $response->action_plan = $this->trimmedOrNull($validated['action_plan']);
        }
        if (array_key_exists('finding', $validated)) {
            $response->finding = $this->trimmedOrNull($validated['finding']);
        }
        if (array_key_exists('remark', $validated)) {
            $response->remark = $this->trimmedOrNull($validated['remark']);
        }
        $response->details = $details;
        $response->save();

        // Recalculate parent submission scores
        $submission->load('responses');
        $scores = is_array($submission->scores) ? $submission->scores : [];
        $statuses = $submission->responses->map(fn ($r) => Str::lower(trim((string) $r->status)))->countBy();
        $yes = (int) $statuses->get('yes', 0);
        $no = (int) $statuses->get('no', 0);
        $na = (int) $statuses->get('na', 0);
        $applicable = $yes + $no;
        $total = $submission->responses->count();
        $answered = $yes + $no + $na;
        $percentage = $applicable > 0 ? round(($yes / $applicable) * 100, 2) : 0;
        $completion = $total > 0 ? round(($answered / $total) * 100, 2) : 0;

        $submission->scores = array_merge($scores, [
            'yes' => $yes,
            'no' => $no,
            'na' => $na,
            'applicable' => $applicable,
            'total' => $total,
            'answered' => $answered,
            'percentage' => $percentage,
            'completion_percentage' => $completion,
        ]);
        $submission->save();

        // Record audit entry in reports table
        Report::query()->create([
            'checklist_submission_id' => $submission->getKey(),
            'checklist_template_id' => $submission->checklist_template_id,
            'generated_by_user_id' => $user->getKey(),
            'type' => 'checklist_response_override',
            'title' => "Checklist response overridden by {$user->name} ({$user->roleLabel()})",
            'status' => 'completed',
            'data_snapshot' => [
                'submission_id' => $submission->getKey(),
                'response_id' => $response->getKey(),
                'item_key' => $response->item_key,
                'previous_status' => $previousStatus,
                'new_status' => $newStatus,
                'escalation_target' => $response->escalation_target,
                'commitment_date' => $response->commitment_date?->toIso8601String(),
                'reason' => $validated['override_reason'] ?? null,
                'branch' => $submission->branch,
                'audit_date' => $submission->audit_date?->format('Y-m-d'),
            ],
            'generated_at' => now(),
        ]);

        $reportTimezone = $this->reportTimezone();

        return response()->json([
            'status' => 'success',
            'success' => true,
            'message' => 'Checklist finding override saved successfully.',
            'response' => [
                'id' => $response->getKey(),
                'status' => $response->status,
                'result' => strtoupper($response->status),
                'escalation_target' => $response->escalation_target,
                'escalation_target_label' => $response->escalationTargetLabel(),
                'commitment_date' => $response->commitment_date?->format('Y-m-d\TH:i:s'),
                'commitment_date_formatted' => $response->commitment_date?->copy()->timezone($reportTimezone)->format('d M Y, h:i A'),
                'action_plan' => $response->action_plan,
                'finding' => $response->finding,
                'detail' => $response->finding ?: $response->remark ?: 'Item updated.',
                'is_overridden' => true,
                'override_details' => $details['override'],
                'details' => $details,
            ],
            'submission' => [
                'id' => $submission->getKey(),
                'score' => $percentage,
                'completion' => $completion,
                'yes' => $yes,
                'no' => $no,
                'na' => $na,
            ],
        ]);
    }

    /**
     * Let a BOM update the escalation recipient, Action Plan, and planned
     * commitment date for one or more NO findings without changing the result.
     */
    public function updateEscalations(Request $request): JsonResponse
    {
        $user = $request->user();
        if (! $user || $user->roleCode() !== User::ROLE_BRANCH_OPERATIONS_MANAGER) {
            return response()->json([
                'message' => 'Only Branch Operations Managers (BOM) may update finding escalation details.',
            ], 403);
        }

        $normalizedUpdates = collect($request->input('responses', []))
            ->map(function (mixed $update): mixed {
                if (! is_array($update)) {
                    return $update;
                }

                if (array_key_exists('escalation_target', $update)) {
                    $update['escalation_target'] = ChecklistResponse::normalizeEscalationTarget(
                        $update['escalation_target']
                    );
                }

                return $update;
            })
            ->all();

        $request->merge(['responses' => $normalizedUpdates]);
        $allowedEscalations = array_keys(ChecklistResponse::escalationTargetOptions());
        $validated = $request->validate([
            'responses' => ['required', 'array', 'min:1', 'max:200'],
            'responses.*.id' => ['required', 'integer', 'distinct:strict', 'exists:checklist_responses,id'],
            'responses.*.escalation_target' => ['nullable', 'string', Rule::in($allowedEscalations)],
            'responses.*.action_plan' => ['nullable', 'string', 'max:10000'],
            'responses.*.commitment_date' => ['nullable', 'date_format:Y-m-d'],
        ]);

        $updates = collect($validated['responses'])->keyBy(fn (array $update): int => (int) $update['id']);
        $reportTimezone = $this->reportTimezone();
        $transactionResult = DB::transaction(function () use ($updates, $user, $reportTimezone): Collection|JsonResponse {
            $responses = ChecklistResponse::query()
                ->with('submission.template')
                ->whereIn('id', $updates->keys())
                ->lockForUpdate()
                ->get()
                ->keyBy(fn (ChecklistResponse $response): int => (int) $response->getKey());

            foreach ($updates as $responseId => $update) {
                $response = $responses->get((int) $responseId);

                if (! $response || ! $user->canOverrideChecklistResponse($response)) {
                    return response()->json([
                        'message' => 'You are not authorized to update one or more selected findings.',
                    ], 403);
                }

                if ($this->normalizedStatus($response->status) !== 'no') {
                    return response()->json([
                        'message' => 'Only responses currently marked NO can be updated here.',
                        'errors' => [
                            'responses' => ['Remove compliant or N/A responses and try again.'],
                        ],
                    ], 422);
                }

                $templateSlug = data_get($response->submission?->template_snapshot, 'slug')
                    ?: $response->submission?->template?->slug;
                $target = $update['escalation_target'] ?? null;
                $templateOptions = ChecklistResponse::escalationTargetOptionsFor($templateSlug);

                if (array_key_exists('escalation_target', $update)
                    && $target !== null
                    && ! array_key_exists($target, $templateOptions)) {
                    return response()->json([
                        'message' => 'The selected escalation recipient is not available for this checklist.',
                        'errors' => [
                            'responses' => ['Choose a recipient from the applicable checklist recipient list.'],
                        ],
                    ], 422);
                }

                $effectiveTarget = array_key_exists('escalation_target', $update)
                    ? $update['escalation_target'] : $response->escalation_target;
                $effectiveAction = array_key_exists('action_plan', $update)
                    ? $update['action_plan'] : $response->action_plan;
                $effectiveDate = array_key_exists('commitment_date', $update)
                    ? $update['commitment_date'] : $response->commitment_date;
                if (blank($effectiveTarget) || blank($effectiveAction) || blank($effectiveDate)) {
                    return response()->json([
                        'message' => 'Escalate To, Action Plan, and Commitment Date are required.',
                        'errors' => ['responses' => ['Complete all escalation fields before saving.']],
                    ], 422);
                }
            }

            return $updates->map(function (array $update, int|string $responseId) use ($responses, $user, $reportTimezone): ?array {
                /** @var ChecklistResponse $response */
                $response = $responses->get((int) $responseId);
                $submission = $response->submission;
                $details = is_array($response->details) ? $response->details : [];
                $previousTarget = ChecklistResponse::normalizeEscalationTarget(
                    $response->escalation_target
                        ?? data_get($details, 'escalation_target')
                        ?? data_get($details, 'escalation')
                );
                $target = array_key_exists('escalation_target', $update)
                    ? ChecklistResponse::normalizeEscalationTarget($update['escalation_target'])
                    : $previousTarget;
                $previousActionPlan = $this->trimmedOrNull(
                    $response->action_plan
                        ?? data_get($details, 'action_plan')
                        ?? data_get($details, 'action')
                );
                $actionPlan = array_key_exists('action_plan', $update)
                    ? $this->trimmedOrNull($update['action_plan'])
                    : $previousActionPlan;
                $previousCommitmentDate = $response->commitment_date
                    ?->copy()
                    ->timezone($reportTimezone)
                    ->format('Y-m-d');
                $commitmentDateInput = array_key_exists('commitment_date', $update)
                    ? $this->trimmedOrNull($update['commitment_date'])
                    : $previousCommitmentDate;
                $commitmentDateChanged = $previousCommitmentDate !== $commitmentDateInput;
                $commitmentDate = ! $commitmentDateChanged
                    ? $response->commitment_date
                    : ($commitmentDateInput === null
                        ? null
                        : CarbonImmutable::createFromFormat('!Y-m-d', $commitmentDateInput, $reportTimezone));

                if ($previousTarget === $target
                    && $previousActionPlan === $actionPlan
                    && $previousCommitmentDate === $commitmentDateInput) {
                    return null;
                }

                if ($target) {
                    $details['escalation_target'] = $target;
                    $details['escalation'] = $target;
                } else {
                    unset($details['escalation_target'], $details['escalation']);
                }

                if ($actionPlan) {
                    $details['action_plan'] = $actionPlan;
                } else {
                    unset($details['action_plan'], $details['action']);
                }

                if ($previousTarget !== $target) {
                    $details['escalation_assignment'] = [
                        'assigned_by_id' => $user->getKey(),
                        'assigned_by_name' => $user->name,
                        'assigned_by_role' => $user->roleLabel(),
                        'assigned_at' => now()->toIso8601String(),
                        'previous_target' => $previousTarget,
                        'new_target' => $target,
                    ];
                }

                $details['bom_follow_up'] = [
                    'updated_by_id' => $user->getKey(),
                    'updated_by_name' => $user->name,
                    'updated_by_role' => $user->roleLabel(),
                    'updated_at' => now()->toIso8601String(),
                    'previous_escalation_target' => $previousTarget,
                    'escalation_target' => $target,
                    'previous_action_plan' => $previousActionPlan,
                    'action_plan' => $actionPlan,
                    'previous_commitment_date' => $previousCommitmentDate,
                    'commitment_date' => $commitmentDateInput,
                ];

                $response->escalation_target = $target;
                $response->action_plan = $actionPlan;
                $response->commitment_date = $commitmentDate;
                $response->details = $details;
                $response->save();

                $owner = $submission?->user;
                if ($owner && $owner->account_status === 'active'
                    && mb_strtolower(trim((string) $owner->branch)) === mb_strtolower(trim((string) $submission->branch))
                    && $owner->canAccessChecklist((string) (data_get($submission->template_snapshot, 'slug') ?: $submission->template?->slug))) {
                    $owner->notify(new FindingEscalated($response, $user));
                }

                Report::query()->create([
                    'checklist_submission_id' => $submission?->getKey(),
                    'checklist_template_id' => $submission?->checklist_template_id,
                    'generated_by_user_id' => $user->getKey(),
                    'type' => 'checklist_response_escalation',
                    'title' => Str::limit(
                        "Checklist finding follow-up updated by {$user->name} ({$user->roleLabel()})",
                        255,
                        ''
                    ),
                    'status' => 'completed',
                    'data_snapshot' => [
                        'submission_id' => $submission?->getKey(),
                        'response_id' => $response->getKey(),
                        'item_key' => $response->item_key,
                        'previous_escalation_target' => $previousTarget,
                        'escalation_target' => $target,
                        'previous_action_plan' => $previousActionPlan,
                        'action_plan' => $actionPlan,
                        'previous_commitment_date' => $previousCommitmentDate,
                        'commitment_date' => $commitmentDateInput,
                        'branch' => $submission?->branch,
                        'audit_date' => $submission?->audit_date?->format('Y-m-d'),
                    ],
                    'generated_at' => now(),
                ]);

                return [
                    'id' => $response->getKey(),
                    'escalation_target' => $target,
                    'escalation_target_label' => $response->escalationTargetLabel(),
                    'action_plan' => $response->action_plan,
                    'commitment_date' => $response->commitment_date
                        ?->copy()
                        ->timezone($reportTimezone)
                        ->format('Y-m-d'),
                ];
            })->filter()->values();
        });

        if ($transactionResult instanceof JsonResponse) {
            return $transactionResult;
        }

        $saved = $transactionResult;

        return response()->json([
            'status' => 'success',
            'success' => true,
            'message' => trans_choice(
                ':count finding update was saved.|:count finding updates were saved.',
                $saved->count(),
                ['count' => $saved->count()]
            ),
            'updated_count' => $saved->count(),
            'responses' => $saved,
        ]);
    }

    /**
     * Notify the active BOM account(s) assigned to the finding's branch.
     */
    public function requestFindingFollowUp(Request $request, ChecklistResponse $response): JsonResponse
    {
        $user = $request->user();
        if (! $user || $user->roleCode() !== User::ROLE_ADMINISTRATOR) {
            return response()->json([
                'message' => 'Only the General Manager may request a BOM finding follow-up.',
            ], 403);
        }

        $response->loadMissing(['submission.template', 'submission.submittedBy', 'submission.user', 'item']);
        $submission = $response->submission;

        if (! $submission) {
            return response()->json(['message' => 'Submission not found for this response.'], 404);
        }

        if ($this->normalizedStatus($response->status) !== 'no') {
            return response()->json([
                'message' => 'Follow-up can only be requested for a finding currently marked NO.',
            ], 422);
        }

        $branch = mb_strtolower(trim((string) $submission->branch));
        if ($branch === '') {
            return response()->json([
                'message' => 'This finding has no branch, so a BOM recipient cannot be determined.',
            ], 422);
        }

        $recipients = User::query()
            ->where('account_status', 'active')
            ->whereRaw('LOWER(TRIM(branch)) = ?', [$branch])
            ->get()
            ->filter(fn (User $candidate): bool => $candidate->roleCode() === User::ROLE_BRANCH_OPERATIONS_MANAGER)
            ->values();

        if ($recipients->isEmpty()) {
            return response()->json([
                'message' => 'No active BOM user is assigned to this finding\'s branch.',
            ], 422);
        }

        $pendingRecipients = $recipients
            ->reject(function (User $recipient) use ($response): bool {
                return $recipient->notifications()
                    ->where('type', FindingFollowUpRequested::class)
                    ->latest()
                    ->limit(100)
                    ->get()
                    ->contains(fn ($notification): bool => (int) data_get($notification->data, 'response_id') === (int) $response->getKey()
                        && ! filled(data_get($notification->data, 'archived_at')));
            })
            ->values();

        if ($pendingRecipients->isNotEmpty()) {
            Notification::send($pendingRecipients, new FindingFollowUpRequested($response, $user));

            Report::query()->create([
                'checklist_submission_id' => $submission->getKey(),
                'checklist_template_id' => $submission->checklist_template_id,
                'generated_by_user_id' => $user->getKey(),
                'type' => 'finding_follow_up_request',
                'title' => Str::limit("BOM follow-up requested by {$user->name}", 255, ''),
                'status' => 'completed',
                'data_snapshot' => [
                    'submission_id' => $submission->getKey(),
                    'response_id' => $response->getKey(),
                    'item_key' => $response->item_key,
                    'branch' => $submission->branch,
                    'notified_user_ids' => $pendingRecipients->modelKeys(),
                ],
                'generated_at' => now(),
            ]);
        }

        $alreadyPendingCount = $recipients->count() - $pendingRecipients->count();
        $message = $pendingRecipients->isEmpty()
            ? 'A follow-up notification is already pending for the BOM user.'
            : trans_choice(
                'Follow-up sent to :count BOM user.|Follow-up sent to :count BOM users.',
                $pendingRecipients->count(),
                ['count' => $pendingRecipients->count()]
            );

        return response()->json([
            'status' => 'success',
            'success' => true,
            'message' => $message,
            'notified_count' => $pendingRecipients->count(),
            'already_pending_count' => $alreadyPendingCount,
            'response_id' => $response->getKey(),
        ]);
    }

    /**
     * Validate and normalize the filters shared by the page and CSV export.
     * `module` is accepted as an alias for backwards-compatible report URLs.
     *
     * @return array{month: ?string, branch: ?string, template: ?string, status: ?string, user_type: ?string, recency: ?string, date_from: ?string, date_to: ?string, findings_filter: string, export_type: string}
     */
    private function filters(Request $request): array
    {
        $validated = $request->validate([
            'month' => ['nullable', 'string'],
            'branch' => ['nullable', 'string', 'max:255'],
            'template' => ['nullable', 'string', 'max:100'],
            'module' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', 'in:all,draft,submitted'],
            'user_type' => ['nullable', Rule::in(['all', ...User::acceptedRoleValues()])],
            'recency' => ['nullable', Rule::in(['all', ...array_keys(self::RECENCY_OPTIONS)])],
            'recent' => ['nullable', Rule::in(['all', ...array_keys(self::RECENCY_OPTIONS)])],
            'findings_filter' => ['nullable', 'string', 'in:all,no,overdue,escalated,overridden'],
            'export_type' => ['nullable', 'string', 'in:submissions,findings'],
        ]);

        $monthInput = $this->nullableFilter($validated['month'] ?? null);
        if ($monthInput !== null && preg_match('/^\d{4}-\d{2}$/', $monthInput) === 1) {
            $month = $monthInput;
        } else {
            $month = now()->format('Y-m');
        }

        return [
            'month' => $month,
            'branch' => $this->nullableFilter($validated['branch'] ?? null),
            'template' => $this->templateFilter($validated['template'] ?? null)
                ?? $this->templateFilter($validated['module'] ?? null),
            'status' => $this->nullableFilter($validated['status'] ?? null),
            'user_type' => $this->userTypeFilter($validated['user_type'] ?? null),
            'recency' => $this->nullableFilter(
                $validated['recency'] ?? $validated['recent'] ?? null
            ),
            'findings_filter' => $this->nullableFilter($validated['findings_filter'] ?? null) ?? 'all',
            'export_type' => $validated['export_type'] ?? 'submissions',
        ];
    }

    /**
     * @param  array{month: string, branch: ?string, template: ?string, status: ?string, user_type: ?string, recency: ?string}  $filters
     */
    private function submissionQuery(Request $request, array $filters): Builder
    {
        $month = $filters['month'] ?? now()->format('Y-m');
        try {
            $startOfMonth = CarbonImmutable::parse($month.'-01')->startOfMonth()->toDateString();
            $endOfMonth = CarbonImmutable::parse($month.'-01')->endOfMonth()->toDateString();
        } catch (\Throwable) {
            $startOfMonth = now()->startOfMonth()->toDateString();
            $endOfMonth = now()->endOfMonth()->toDateString();
        }

        return $this->reportableSubmissionQuery($request)
            ->with([
                'template',
                'user:id,name,email,user_type',
                'submittedBy:id,name,email,user_type',
                'responses.item.section',
            ])
            ->whereBetween('audit_date', [$startOfMonth, $endOfMonth])
            ->when($filters['branch'], fn (Builder $query, string $branch): Builder => $query->where('branch', $branch))
            ->when($filters['template'], function (Builder $query, string $template): Builder {
                return $query->where(function (Builder $templateFilter) use ($template): void {
                    $templateFilter
                        ->whereHas(
                            'template',
                            fn (Builder $templateQuery): Builder => $templateQuery->where('slug', $template)
                        )
                        ->orWhere(function (Builder $archivedFilter) use ($template): void {
                            $archivedFilter
                                ->whereNull('checklist_template_id')
                                ->where('template_snapshot->slug', $template);
                        });
                });
            })
            ->when($filters['status'], fn (Builder $query, string $status): Builder => $query->where('status', $status))
            ->when(
                $filters['user_type'],
                fn (Builder $query, string $userType): Builder => $this->filterByUserType($query, $userType)
            )
            ->when($filters['recency'], function (Builder $query, string $recency): Builder {
                return $query
                    ->where('status', 'submitted')
                    ->whereNotNull('submitted_at')
                    ->where('submitted_at', '>=', $this->recencyCutoff($recency));
            })
            ->orderByDesc('submitted_at')
            ->orderByDesc('updated_at')
            ->orderByDesc('id');
    }

    /**
     * Start every report query from the same visibility and record-quality rules.
     * Submitted audits remain historical records. A draft is reportable only while
     * it contains an answered response, so untouched or reset drafts add no volume.
     */
    private function reportableSubmissionQuery(Request $request): Builder
    {
        $query = ChecklistSubmission::query()
            ->where(function (Builder $statusQuery): void {
                $statusQuery
                    ->where('status', 'submitted')
                    ->orWhere(function (Builder $draftQuery): void {
                        $draftQuery
                            ->where('status', 'draft')
                            ->where('scores->answered', '>', 0)
                            ->whereHas('responses');
                    });
            });

        if ($this->hasGlobalReportAccess($request)) {
            return $query;
        }

        $user = $request->user();
        $assignedBranch = trim((string) $user?->branch);

        if ($assignedBranch === '') {
            return $query->whereRaw('0 = 1');
        }

        $query->whereRaw(
            'LOWER(TRIM(branch)) = ?',
            [mb_strtolower($assignedBranch)]
        );

        if ($user?->isDosOperationalRole() === true) {
            $allowedSlugs = $user->allowedChecklistSlugs() ?? [];

            $query
                ->where('user_id', $user->getKey())
                ->where(function (Builder $templateQuery) use ($allowedSlugs): void {
                    $templateQuery
                        ->whereHas(
                            'template',
                            fn (Builder $template): Builder => $template->whereIn('slug', $allowedSlugs)
                        )
                        ->orWhere(function (Builder $archivedQuery) use ($allowedSlugs): void {
                            $archivedQuery
                                ->whereNull('checklist_template_id')
                                ->whereIn('template_snapshot->slug', $allowedSlugs);
                        });
                });
        }

        return $query;
    }

    /**
     * Return current templates plus snapshot-only templates visible to this user.
     *
     * @return Collection<int, array{slug: string, name: string, is_archived: bool}>
     */
    private function templateOptions(Request $request): Collection
    {
        $allowedSlugs = $this->dosAllowedChecklistSlugs($request);
        $currentTemplates = ChecklistTemplate::query()
            ->when(
                $allowedSlugs !== null,
                fn (Builder $query): Builder => $query->whereIn('slug', $allowedSlugs)
            )
            ->get(['slug', 'name'])
            ->map(fn (ChecklistTemplate $template): array => [
                'slug' => $template->slug,
                'name' => $template->name,
                'is_archived' => false,
            ]);

        $archivedTemplates = $this->reportableSubmissionQuery($request)
            ->whereNull('checklist_template_id')
            ->get(['template_snapshot'])
            ->map(function (ChecklistSubmission $submission): ?array {
                $slug = trim((string) data_get($submission->template_snapshot, 'slug'));

                if ($slug === '') {
                    return null;
                }

                return [
                    'slug' => $slug,
                    'name' => data_get($submission->template_snapshot, 'name') ?: 'Archived checklist',
                    'is_archived' => true,
                ];
            })
            ->filter();

        return $currentTemplates
            ->concat($archivedTemplates)
            ->unique('slug')
            ->sortBy('name', SORT_NATURAL | SORT_FLAG_CASE)
            ->values();
    }

    /**
     * @return array{
     *     summary: array<string, int|float|null>,
     *     history: Collection<int, array<string, mixed>>,
     *     findings: Collection<int, array<string, mixed>>,
     *     moduleSummaries: Collection<int, array<string, mixed>>,
     *     branchSummaries: Collection<int, array<string, mixed>>,
     *     monthlySummaries: Collection<int, array<string, mixed>>
     * }
     */
    private function reportData(Collection $submissions, ?User $viewer = null): array
    {
        $findings = $this->findings($submissions, $viewer);
        $findingsBySubmission = $findings->countBy('submission_id');
        $summary = $this->aggregate($submissions);
        $summary['audit_count'] = $submissions->count();
        $summary['submitted_count'] = $submissions->where('status', 'submitted')->count();
        $summary['draft_count'] = $submissions->where('status', 'draft')->count();
        $summary['findings_count'] = $findings->count();
        $summary['no_count'] = $findings->filter(fn (array $f): bool => in_array($f['status'], ['no', 'x'], true) || $f['is_overridden'])->count();
        $summary['escalation_count'] = $findings->filter(fn (array $f): bool => filled($f['escalation_target']))->count();
        $summary['overdue_count'] = $findings->filter(fn (array $f): bool => $f['is_overdue'] === true)->count();
        $summary['overridden_count'] = $findings->filter(fn (array $f): bool => $f['is_overridden'] === true)->count();

        $reportTimezone = $this->reportTimezone();
        $history = $submissions->map(function (ChecklistSubmission $submission) use ($findingsBySubmission, $reportTimezone): array {
            $metric = $this->submissionMetric($submission);
            $submitter = $submission->submittedBy ?? $submission->user;
            $submitterName = $submission->submitted_by_name
                ?: $submitter?->name
                ?: data_get($submission->context, 'auditor')
                ?: 'Not recorded';
            $submitterEmail = $submission->submitted_by_email ?: $submitter?->email;
            $submitterRole = $submission->submitted_by_user_type ?: $submitter?->user_type;
            $submitterRoleCode = User::roleCodeFor($submitterRole);

            return [
                'id' => $submission->getKey(),
                'audit_date' => $submission->audit_date?->format('Y-m-d'),
                'template_name' => $this->templateName($submission),
                'template_slug' => $this->templateSlug($submission),
                'is_restroom' => $this->isRestroom($submission),
                'is_restroom_hourly' => $this->isHourlyRestroom($submission),
                'branch' => $this->branchName($submission),
                'scope' => $submission->scope_key,
                'submitter_name' => $submitterName,
                'submitter_email' => $submitterEmail,
                'submitter_role_code' => $submitterRoleCode,
                'submitter_role_label' => User::roleLabelFor($submitterRole),
                'auditor' => $submitterName,
                'status' => $submission->status,
                'submitted_at' => $submission->submitted_at?->toIso8601String(),
                'submitted_at_local' => $submission->submitted_at
                    ?->copy()
                    ->timezone($reportTimezone)
                    ->format('Y-m-d H:i:s P'),
                'findings_count' => (int) $findingsBySubmission->get($submission->getKey(), 0),
                ...$metric,
            ];
        });

        return [
            'summary' => $summary,
            'history' => $history,
            'findings' => $findings,
            'moduleSummaries' => $this->groupSummaries($submissions, function (ChecklistSubmission $submission): string {
                return $this->templateSlug($submission) ?: 'deleted-'.$submission->checklist_template_id;
            }, function (ChecklistSubmission $submission): array {
                return [
                    'label' => $this->templateName($submission),
                    'slug' => $this->templateSlug($submission),
                    'is_restroom' => $this->isRestroom($submission),
                    'is_restroom_hourly' => $this->isHourlyRestroom($submission),
                ];
            }),
            'branchSummaries' => $this->groupSummaries(
                $submissions,
                fn (ChecklistSubmission $submission): string => $this->branchName($submission),
                fn (ChecklistSubmission $submission): array => ['label' => $this->branchName($submission)]
            ),
            'monthlySummaries' => $this->groupSummaries(
                $submissions,
                fn (ChecklistSubmission $submission): string => $submission->audit_date?->format('Y-m') ?? 'undated',
                fn (ChecklistSubmission $submission): array => [
                    'label' => $submission->audit_date?->format('M Y') ?? 'Undated',
                    'sort_key' => $submission->audit_date?->format('Y-m') ?? '0000-00',
                ]
            )->sortBy('sort_key')->values(),
        ];
    }

    /**
     * @return Collection<int, array<string, mixed>>
     */
    private function findings(Collection $submissions, ?User $viewer = null): Collection
    {
        $findings = collect();

        foreach ($submissions as $submission) {
            foreach ($submission->responses as $response) {
                if ($this->isHourlyRestroom($submission)) {
                    $badSlots = collect(data_get($response->details, 'slots', []))
                        ->filter(fn (mixed $value): bool => $this->isBadSlotMark($value));

                    foreach ($badSlots as $slot => $value) {
                        $findings->push($this->findingRow($submission, $response, 'x', (string) $slot, $viewer));
                    }

                    if ($badSlots->isEmpty() && (in_array($this->normalizedStatus($response->status), ['no', 'na'], true) || $response->isOverridden())) {
                        $findings->push($this->findingRow($submission, $response, $this->normalizedStatus($response->status), null, $viewer));
                    }

                    continue;
                }

                $status = $this->normalizedStatus($response->status);

                if (in_array($status, ['no', 'na'], true) || $response->isOverridden()) {
                    $findings->push($this->findingRow($submission, $response, $status, null, $viewer));
                }
            }
        }

        return $findings;
    }

    /**
     * @return array<string, mixed>
     */
    private function findingRow(ChecklistSubmission $submission, mixed $response, string $status, ?string $slot = null, ?User $viewer = null): array
    {
        $itemSnapshot = is_array($response->item_snapshot) ? $response->item_snapshot : [];
        $snapshotMetadata = data_get($itemSnapshot, 'metadata');
        $metadata = is_array($snapshotMetadata)
            ? $snapshotMetadata
            : (is_array($response->item?->metadata) ? $response->item->metadata : []);
        $area = trim((string) (
            data_get($metadata, 'coverage')
            ?? data_get($itemSnapshot, 'section.title')
            ?? data_get($itemSnapshot, 'section_title')
            ?? data_get($itemSnapshot, 'area')
            ?? $response->item?->section?->title
            ?? 'General'
        ));
        $item = trim((string) (
            data_get($itemSnapshot, 'prompt')
            ?? data_get($itemSnapshot, 'text')
            ?? data_get($itemSnapshot, 'label')
            ?? $response->item?->prompt
            ?? $response->item_key
        ));
        $fallback = $status === 'x'
            ? 'Condition marked X'.($slot ? ' at '.$slot : '').'.'
            : ($status === 'na' ? 'Item marked not applicable.' : 'Item marked non-compliant.');

        $escalationTarget = $response->escalation_target
            ?? data_get($response->details, 'escalation_target')
            ?? data_get($response->details, 'escalation');

        $escalationTargetNormalized = ChecklistResponse::normalizeEscalationTarget($escalationTarget);

        $escalationTargetLabel = $escalationTargetNormalized
            ? (ChecklistResponse::escalationTargetOptions()[$escalationTargetNormalized] ?? ucwords(str_replace('_', ' ', (string) $escalationTarget)))
            : null;

        $reportTimezone = $this->reportTimezone();
        $commitmentDate = $response->commitment_date;
        if (! $commitmentDate) {
            $rawCommitment = data_get($response->details, 'commitment_date') ?? data_get($response->details, 'target_date');
            if ($rawCommitment instanceof \DateTimeInterface) {
                $commitmentDate = Carbon::instance($rawCommitment);
            } elseif (is_string($rawCommitment) && trim($rawCommitment) !== '') {
                try {
                    $commitmentDate = Carbon::parse(trim($rawCommitment), $reportTimezone);
                } catch (\Throwable) {
                    $commitmentDate = null;
                }
            }
        }

        $commitmentDateFormatted = null;
        $isOverdue = false;
        $dueStatus = null;

        if ($commitmentDate) {
            $commitmentLocal = $commitmentDate->copy()->timezone($reportTimezone);
            $commitmentDateFormatted = $commitmentLocal->format('d M Y, h:i A');
            $nowLocal = now()->timezone($reportTimezone);
            if ($status === 'no' || $status === 'x') {
                if ($commitmentLocal->isPast()) {
                    $isOverdue = true;
                    $diffDays = (int) ceil($commitmentLocal->diffInHours($nowLocal) / 24);
                    $dueStatus = 'Overdue'.($diffDays > 0 ? ' by '.$diffDays.'d' : '');
                } else {
                    $diffDays = (int) ceil($nowLocal->diffInHours($commitmentLocal) / 24);
                    $dueStatus = $diffDays === 0 ? 'Due today' : 'Due in '.$diffDays.'d';
                }
            }
        }

        $findingText = $response->finding
            ?: data_get($response->details, 'finding')
            ?: $response->remark
            ?: data_get($response->details, 'remark')
            ?: data_get($response->details, 'note')
            ?: $fallback;

        $actionPlan = $response->action_plan
            ?: data_get($response->details, 'action_plan')
            ?: data_get($response->details, 'action');

        $override = data_get($response->details, 'override');
        $isOverridden = is_array($override);

        $submitter = $submission->submittedBy ?? $submission->user;
        $submitterName = $submission->submitted_by_name
            ?: $submitter?->name
            ?: data_get($submission->context, 'auditor')
            ?: 'Not recorded';

        $canOverride = $viewer ? $viewer->canOverrideChecklistResponse($response) : false;

        return [
            'response_id' => $response->getKey(),
            'submission_id' => $submission->getKey(),
            'audit_date' => $submission->audit_date?->format('Y-m-d'),
            'template_name' => $this->templateName($submission),
            'template_slug' => $this->templateSlug($submission),
            'is_restroom' => $this->isRestroom($submission),
            'is_restroom_hourly' => $this->isHourlyRestroom($submission),
            'branch' => $this->branchName($submission),
            'auditor' => $submitterName,
            'auditor_role' => User::roleLabelFor($submission->submitted_by_user_type ?: $submitter?->user_type),
            'area' => $area,
            'item_key' => $response->item_key,
            'item' => $item,
            'status' => $status,
            'result' => $status === 'x' ? 'X' : ($status === 'na' ? 'N/A' : ($isOverridden ? 'OVERRIDDEN ('.strtoupper($response->status).')' : 'NO')),
            'slot' => $slot,
            'question_number' => data_get($metadata, 'number'),
            'category' => trim((string) (data_get($metadata, 'level') ?? data_get($metadata, 'category'))),
            'subject' => trim((string) data_get($metadata, 'subject')),
            'person_accountable' => trim((string) (data_get($metadata, 'person_accountable') ?? data_get($metadata, 'pic'))),
            'checker_role' => trim((string) data_get($metadata, 'checker')),
            'bom_task' => trim((string) data_get($metadata, 'bom_task')),
            'recommended_escalation' => trim((string) data_get($metadata, 'escalation')),
            'detail' => $findingText,
            'action_plan' => $actionPlan,
            'escalation_target' => $escalationTargetNormalized ?? $escalationTarget,
            'escalation_target_label' => $escalationTargetLabel,
            'commitment_date' => $commitmentDate?->format('Y-m-d\TH:i:s'),
            'commitment_date_formatted' => $commitmentDateFormatted,
            'commitment_date_local' => $commitmentDate ? $commitmentDate->copy()->timezone($reportTimezone)->format('Y-m-d\TH:i') : null,
            'commitment_date_input' => $commitmentDate ? $commitmentDate->copy()->timezone($reportTimezone)->format('Y-m-d') : null,
            'is_overdue' => $isOverdue,
            'due_status' => $dueStatus,
            'attachment_url' => $this->attachmentUrl($response->attachment_path),
            'is_overridden' => $isOverridden,
            'override_details' => $override,
            'can_override' => $canOverride,
        ];
    }

    /**
     * @return array{score: ?float, completion: ?float, yes: int, no: int, na: int, applicable: int, answered: int, total: int}
     */
    private function submissionMetric(ChecklistSubmission $submission): array
    {
        $scores = is_array($submission->scores) ? $submission->scores : [];
        $statuses = $submission->responses
            ->map(fn (mixed $response): string => $this->normalizedStatus($response->status))
            ->countBy();

        if ($this->isHourlyRestroom($submission)) {
            $slotMarks = $submission->responses
                ->flatMap(fn (mixed $response): array => is_array(data_get($response->details, 'slots'))
                    ? data_get($response->details, 'slots')
                    : []);
            $fallbackGood = $slotMarks
                ->filter(fn (mixed $mark): bool => $this->isGoodSlotMark($mark))
                ->count();
            $fallbackBad = $slotMarks
                ->filter(fn (mixed $mark): bool => $this->isBadSlotMark($mark))
                ->count();
            $yes = $this->integerScore($scores, 'good', $fallbackGood);
            $no = $this->integerScore($scores, 'bad', $fallbackBad);
            $na = $this->integerScore($scores, 'na', (int) $statuses->get('na', 0));
            $total = $this->integerScore($scores, 'slot_total', $this->integerScore($scores, 'total', $yes + $no + $na));
            $answered = $this->integerScore($scores, 'slots_answered', $yes + $no + $na);
            $applicable = $yes + $no;
        } else {
            $yes = $this->integerScore($scores, 'yes', (int) $statuses->get('yes', 0));
            $no = $this->integerScore($scores, 'no', (int) $statuses->get('no', 0));
            $na = $this->integerScore($scores, 'na', (int) $statuses->get('na', 0));
            $total = $this->integerScore($scores, 'total', $submission->responses->count());
            $answered = $this->integerScore($scores, 'answered', $yes + $no + $na);
            $applicable = $this->integerScore($scores, 'applicable', $yes + $no);
        }

        $score = $this->numericScore($scores, 'percentage');
        $completion = $this->numericScore($scores, 'completion_percentage');

        return [
            'score' => $score ?? $this->percentage($yes, $applicable),
            'completion' => $completion ?? $this->percentage($answered, $total),
            'yes' => $yes,
            'no' => $no,
            'na' => $na,
            'applicable' => $applicable,
            'answered' => $answered,
            'total' => $total,
        ];
    }

    /**
     * @return array{score: ?float, completion: ?float, yes: int, no: int, na: int, applicable: int, answered: int, total: int}
     */
    private function aggregate(Collection $submissions): array
    {
        $totals = [
            'yes' => 0,
            'no' => 0,
            'na' => 0,
            'applicable' => 0,
            'answered' => 0,
            'total' => 0,
        ];

        foreach ($submissions as $submission) {
            $metric = $this->submissionMetric($submission);

            foreach (array_keys($totals) as $key) {
                $totals[$key] += $metric[$key];
            }
        }

        return [
            'score' => $this->percentage($totals['yes'], $totals['applicable']),
            'completion' => $this->percentage($totals['answered'], $totals['total']),
            ...$totals,
        ];
    }

    /**
     * @param  callable(ChecklistSubmission): string  $keyBy
     * @param  callable(ChecklistSubmission): array<string, mixed>  $describe
     * @return Collection<int, array<string, mixed>>
     */
    private function groupSummaries(Collection $submissions, callable $keyBy, callable $describe): Collection
    {
        return $submissions
            ->groupBy($keyBy)
            ->map(function (Collection $records) use ($describe): array {
                $aggregate = $this->aggregate($records);

                return [
                    ...$describe($records->first()),
                    'count' => $records->count(),
                    'findings_count' => $this->findings($records)->count(),
                    ...$aggregate,
                ];
            })
            ->sortBy('label', SORT_NATURAL | SORT_FLAG_CASE)
            ->values();
    }

    private function templateName(ChecklistSubmission $submission): string
    {
        return $submission->template?->name
            ?? data_get($submission->template_snapshot, 'name')
            ?? 'Archived checklist';
    }

    private function templateSlug(ChecklistSubmission $submission): string
    {
        return $submission->template?->slug
            ?? data_get($submission->template_snapshot, 'slug')
            ?? 'archived';
    }

    private function isRestroom(ChecklistSubmission $submission): bool
    {
        return $this->templateSlug($submission) === 'restroom';
    }

    private function isHourlyRestroom(ChecklistSubmission $submission): bool
    {
        if (! $this->isRestroom($submission)) {
            return false;
        }

        $settings = $submission->template?->settings;
        if (! is_array($settings)) {
            $settings = data_get($submission->template_snapshot, 'settings', []);
        }

        $mode = is_array($settings) ? ($settings['validation_mode'] ?? null) : null;
        if ($mode !== null) {
            return $mode === 'time_slots';
        }

        // Older snapshots may not have stored template settings. Preserve
        // their hourly interpretation when the response payload contains
        // the legacy slot map.
        return $submission->responses->contains(
            fn (mixed $response): bool => is_array(data_get($response->details, 'slots'))
        );
    }

    private function branchName(ChecklistSubmission $submission): string
    {
        return $submission->branch
            ?: data_get($submission->context, 'branch')
            ?: 'Unassigned';
    }

    /**
     * @return array{type: string, branch: ?string}
     */
    private function accessScope(Request $request): array
    {
        return [
            'type' => $this->hasGlobalReportAccess($request) ? 'all_branches' : 'assigned_branch',
            'branch' => $this->hasGlobalReportAccess($request)
                ? null
                : $this->nullableFilter($request->user()?->branch),
        ];
    }

    private function hasGlobalReportAccess(Request $request): bool
    {
        return $request->user()?->hasAdministrativeAccess() === true;
    }

    /**
     * DOS operational accounts have a single checklist workspace. Other roles
     * retain the existing branch-wide report template options.
     *
     * @return list<string>|null
     */
    private function dosAllowedChecklistSlugs(Request $request): ?array
    {
        $user = $request->user();

        return $user?->isDosOperationalRole() === true
            ? ($user->allowedChecklistSlugs() ?? [])
            : null;
    }

    private function filterByUserType(Builder $query, string $userType): Builder
    {
        $aliases = collect(User::acceptedRoleValues())
            ->push($userType)
            ->filter(fn (string $role): bool => User::roleCodeFor($role) === $userType)
            ->unique()
            ->values()
            ->all();

        return $query->where(function (Builder $roleQuery) use ($aliases): void {
            $roleQuery
                ->whereIn('submitted_by_user_type', $aliases)
                ->orWhere(function (Builder $legacyQuery) use ($aliases): void {
                    $legacyQuery
                        ->where(function (Builder $snapshotQuery): void {
                            $snapshotQuery
                                ->whereNull('submitted_by_user_type')
                                ->orWhere('submitted_by_user_type', '');
                        })
                        ->where(function (Builder $identityQuery) use ($aliases): void {
                            $identityQuery
                                ->whereHas(
                                    'submittedBy',
                                    fn (Builder $userQuery): Builder => $userQuery->whereIn('user_type', $aliases)
                                )
                                ->orWhere(function (Builder $ownerQuery) use ($aliases): void {
                                    $ownerQuery
                                        ->whereNull('submitted_by_user_id')
                                        ->whereHas(
                                            'user',
                                            fn (Builder $userQuery): Builder => $userQuery->whereIn('user_type', $aliases)
                                        );
                                });
                        });
                });
        });
    }

    private function recencyCutoff(string $recency): \DateTimeInterface
    {
        return match ($recency) {
            '24h' => now()->subHours(24),
            '7d' => now()->subDays(7),
            '30d' => now()->subDays(30),
            '90d' => now()->subDays(90),
            default => now()->subYears(100),
        };
    }

    private function userTypeFilter(mixed $value): ?string
    {
        $value = $this->nullableFilter($value);

        if ($value === null) {
            return null;
        }

        $roleCode = User::roleCodeFor($value);

        return array_key_exists($roleCode, User::roleOptions()) ? $roleCode : null;
    }

    private function reportTimezone(): string
    {
        return (string) config('gac.report_timezone', 'Asia/Manila');
    }

    private function normalizedStatus(mixed $status): string
    {
        $normalized = mb_strtolower(trim((string) $status));

        return in_array($normalized, ['n/a', 'not applicable'], true) ? 'na' : $normalized;
    }

    private function isGoodSlotMark(mixed $mark): bool
    {
        return in_array($this->normalizedStatus($mark), ['/', 'good', 'yes'], true);
    }

    private function isBadSlotMark(mixed $mark): bool
    {
        return in_array($this->normalizedStatus($mark), ['x', 'not_good', 'not-good', 'bad', 'no'], true);
    }

    private function nullableFilter(mixed $value): ?string
    {
        $value = trim((string) $value);

        return $value === '' || mb_strtolower($value) === 'all' ? null : $value;
    }

    private function templateFilter(mixed $value): ?string
    {
        $value = $this->nullableFilter($value);

        if ($value === null) {
            return null;
        }

        return match (mb_strtolower($value)) {
            'dos', 'dealer operations standards' => 'dealer-operations-standards',
            '5s', '5s checklist', 'gateway 5s' => 'gateway-5s',
            'restroom checklist' => 'restroom',
            default => $value,
        };
    }

    private function integerScore(array $scores, string $key, int $fallback): int
    {
        return isset($scores[$key]) && is_numeric($scores[$key])
            ? max(0, (int) $scores[$key])
            : max(0, $fallback);
    }

    private function numericScore(array $scores, string $key): ?float
    {
        if (! isset($scores[$key]) || ! is_numeric($scores[$key])) {
            return null;
        }

        return round(min(100, max(0, (float) $scores[$key])), 1);
    }

    private function percentage(int $numerator, int $denominator): ?float
    {
        return $denominator > 0 ? round(($numerator / $denominator) * 100, 1) : null;
    }

    private function csvValue(mixed $value): string
    {
        $value = (string) ($value ?? '');

        return preg_match('/^[\s]*[=+\-@]/u', $value) === 1 ? "'".$value : $value;
    }

    private function attachmentUrl(?string $path): ?string
    {
        if (! $path) {
            return null;
        }

        return Storage::disk('public')->url($path);
    }

    private function trimmedOrNull(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $trimmed = trim((string) $value);

        return $trimmed === '' ? null : $trimmed;
    }
}
