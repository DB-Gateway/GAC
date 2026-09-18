<?php

namespace App\Http\Controllers;

use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use App\Services\AftersalesSubformDocService;
use App\Services\NotificationService;
use Carbon\CarbonImmutable;
use Illuminate\Contracts\View\View;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class DashboardController extends Controller
{
    private const DOS_SLUG = 'dealer-operations-standards';

    private const DOS_SLUGS = [
        self::DOS_SLUG,
        'dealer-operations-standards-sales',
    ];

    /**
     * Display live dashboard metrics for the authenticated user's access scope.
     */
    public function index(Request $request, NotificationService $notificationService): View
    {
        $now = now();
        $monthStart = $now->copy()->startOfMonth();
        $monthEnd = $now->copy()->endOfMonth();
        $relations = [
            'template:id,slug,name',
            'user:id,name,email',
            'submittedBy:id,name,email',
            'responses.item.section',
        ];

        $currentMonth = (clone $this->reportableSubmissionQuery($request))
            ->with($relations)
            ->whereBetween('audit_date', [$monthStart->toDateString(), $monthEnd->toDateString()])
            ->orderByDesc('audit_date')
            ->orderByDesc('id')
            ->get();
        $submittedThisMonth = $currentMonth->where('status', 'submitted')->values();
        $draftsThisMonth = $currentMonth->where('status', 'draft')->values();
        $dosSubmittedThisMonth = $submittedThisMonth
            ->filter(fn (ChecklistSubmission $submission): bool => $this->isDosSubmission($submission))
            ->values();
        $dosDraftsThisMonth = $draftsThisMonth
            ->filter(fn (ChecklistSubmission $submission): bool => $this->isDosSubmission($submission))
            ->values();
        $submittedAggregate = $this->aggregate($submittedThisMonth);
        $currentAggregate = $this->aggregate($currentMonth);
        $criticalFindings = $submittedThisMonth->sum(
            fn (ChecklistSubmission $submission): int => $submission->responses
                ->filter(fn (ChecklistResponse $response): bool => $this->normalizedStatus($response->status) === 'no')
                ->count()
        );
        $dosWorkload = $dosSubmittedThisMonth->count() + $dosDraftsThisMonth->count();

        $summary = [
            'overall_compliance' => $submittedAggregate['score'],
            'dos_completed' => $dosSubmittedThisMonth->count(),
            'pending_audits' => $draftsThisMonth->count(),
            'critical_findings' => $criticalFindings,
            'dos_completion_rate' => $this->percentage($dosSubmittedThisMonth->count(), $dosWorkload),
            'pending_rate' => $this->percentage($draftsThisMonth->count(), $currentMonth->count()),
            'findings_rate' => $this->percentage($criticalFindings, $currentAggregate['answered']),
            'submitted_count' => $submittedThisMonth->count(),
        ];

        $userRole = $request->user()?->roleCode();
        $isAdministrator = $request->user()?->hasAdministrativeAccess() === true;
        $canViewFindings = $userRole === User::ROLE_ADMINISTRATOR;
        $canManageEscalations = $userRole === User::ROLE_BRANCH_OPERATIONS_MANAGER;
        $canAccessFollowUp = $canViewFindings || $canManageEscalations;
        $canViewUserUsages = $isAdministrator || $canManageEscalations;
        $requestedTab = mb_strtolower(trim((string) $request->query('tab', 'overview')));
        $activeTab = in_array($requestedTab, ['overview', 'follow-up', 'reports', 'users', 'override'], true)
            ? $requestedTab
            : 'overview';

        if ($activeTab === 'users' && ! $canViewUserUsages) {
            $activeTab = 'overview';
        }

        if ($activeTab === 'follow-up' && ! $canAccessFollowUp) {
            $activeTab = 'overview';
        }

        $overrideChecklists = collect(config('checklists.navigation_groups'))->pluck('items')->flatten(1);
        $selectedOverrideChecklist = null;
        if ($activeTab === 'override') {
            abort_unless($request->user()?->canOverrideChecklistResponses(), 403);
            $validated = $request->validate([
                'checklist' => ['nullable', 'string', Rule::in($overrideChecklists->pluck('slug')->all())],
            ]);
            $selectedOverrideChecklist = $validated['checklist'] ?? 'dealer-operations-standards';
        }

        $summarySheet = $this->summarySheetData($request);
        $canOpenSummaryFindings = $activeTab === 'overview'
            && $summarySheet['canViewFindings'] === true
            && $summarySheet['nonCompliantFindings']->isNotEmpty();

        $notifications = collect();

        $draftAlert = $notificationService->getPendingDraftAlert($request->user());
        if ($draftAlert) {
            $notifications->push($draftAlert);
        } elseif (! $request->user()?->receivesTaskCompletionNotifications() && $summary['pending_audits'] > 0) {
            $notifications->push([
                'type' => 'warning',
                'icon' => 'fa-clock',
                'title' => 'Saved audits awaiting submission',
                'message' => trans_choice(
                    ':count draft is still pending for :month.|:count drafts are still pending for :month.',
                    $summary['pending_audits'],
                    ['count' => $summary['pending_audits'], 'month' => $monthStart->format('F Y')]
                ),
            ]);
        }

        if ($summary['critical_findings'] > 0) {
            $notifications->push([
                'type' => 'critical',
                'icon' => 'fa-circle-exclamation',
                'title' => 'Audit findings require attention',
                'message' => trans_choice(
                    ':count non-compliant response is recorded this month.|:count non-compliant responses are recorded this month.',
                    $summary['critical_findings'],
                    ['count' => $summary['critical_findings']]
                ),
                'action' => $canOpenSummaryFindings ? [
                    'target' => 'summaryFindingsModal',
                    'label' => 'View NO findings',
                ] : null,
            ]);
        }

        $taskNotificationData = $notificationService->getTaskNotificationData($request->user());

        $reportFilters = $this->reportFilters($request);
        if ($activeTab === 'override') {
            $reportFilters['template'] = $selectedOverrideChecklist;
        }
        $reportSubmissions = $this->filteredReportSubmissionQuery($request, $reportFilters)
            ->with($relations)
            ->get();
        $reportData = $this->reportAnalytics($reportSubmissions, $request->user());
        if ($activeTab === 'override') {
            $reportData['reportFindings'] = $reportData['reportFindings']
                ->filter(fn (array $finding): bool => in_array($finding['status'], ['no', 'x'], true))
                ->values();

            $allOverrideFilters = $reportFilters;
            $allOverrideFilters['template'] = null;
            $allOverrideSubmissions = $this->filteredReportSubmissionQuery($request, $allOverrideFilters)
                ->with($relations)
                ->get();
            $allFindings = $this->reportFindings($allOverrideSubmissions, $request->user())
                ->filter(fn (array $finding): bool => in_array($finding['status'], ['no', 'x'], true));
            $findingsCountsBySlug = $allFindings->groupBy('template_slug')->map->count();

            $overrideChecklists = $overrideChecklists->map(function (array $item) use ($findingsCountsBySlug): array {
                $item['no_count'] = (int) ($findingsCountsBySlug->get($item['slug']) ?? 0);

                return $item;
            });
        }

        $followUpResponseId = (int) $request->query('follow_up_response_id', 0);
        $canOverrideAny = $request->user()?->canOverrideChecklistResponses() ?? false;

        $viewData = [
            'summarySheet' => $summarySheet,
            'dashboardSummary' => $summary,
            'monthlyTrend' => $this->monthlyDosTrend($request, $monthStart, $monthEnd, $relations),
            'dosCategories' => $this->dosCategorySummaries($dosSubmittedThisMonth),
            'recentActivities' => $this->recentActivities($request, $relations),
            'branchRankings' => $this->branchRankings($submittedThisMonth),
            'calendar' => $this->calendarData($currentMonth, $monthStart, $now),
            'notifications' => $notifications,
            ...$taskNotificationData,
            'notificationBadgeCount' => $taskNotificationData['unreadTaskNotificationCount'],
            'dashboardScope' => $request->user()?->hasAdministrativeAccess() === true
                ? 'All branches'
                : (trim((string) $request->user()?->branch) ?: 'No assigned branch'),
            'activeTab' => $activeTab,
            'overrideChecklists' => $overrideChecklists,
            'selectedOverrideChecklist' => $selectedOverrideChecklist,
            'isAdministrator' => $isAdministrator,
            'canViewFindings' => $canViewFindings,
            'canManageEscalations' => $canManageEscalations,
            'canAccessFollowUp' => $canAccessFollowUp,
            'followUpResponseId' => $followUpResponseId,
            'canOverrideAny' => $canOverrideAny,
            'canViewUserUsages' => $canViewUserUsages,
            'reportFilters' => $reportFilters,
            'reportScope' => [
                'type' => $isAdministrator ? 'all_branches' : 'assigned_branch',
                'branch' => $isAdministrator ? null : $this->nullableFilter($request->user()?->branch),
            ],
            'reportBranchOptions' => $this->reportableSubmissionQuery($request)
                ->whereNotNull('branch')
                ->where('branch', '<>', '')
                ->distinct()
                ->orderBy('branch')
                ->pluck('branch'),
            'reportTemplateOptions' => $this->reportTemplateOptions($request),
            'escalationOptions' => ChecklistResponse::escalationTargetOptions(),
            ...$reportData,
        ];

        if ($canViewUserUsages) {
            $viewData = [...$viewData, ...$this->userAnalytics($request)];
        }

        return view('dashboard', $viewData);
    }

    /**
     * Normalize the filters used by the dashboard reporting tab.
     *
     * @return array{month: string, branch: ?string, template: ?string, status: ?string}
     */
    private function reportFilters(Request $request): array
    {
        $validated = $request->validate([
            'month' => ['nullable', 'string'],
            'branch' => ['nullable', 'string', 'max:255'],
            'template' => ['nullable', 'string', 'max:100'],
            'module' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', 'in:all,draft,submitted'],
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
        ];
    }

    /**
     * @param  array{month: string, branch: ?string, template: ?string, status: ?string}  $filters
     */
    private function filteredReportSubmissionQuery(Request $request, array $filters): Builder
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
            ->whereBetween('audit_date', [$startOfMonth, $endOfMonth])
            ->when($filters['branch'], fn (Builder $query, string $branch): Builder => $query->where('branch', $branch))
            ->when($filters['template'], function (Builder $query, string $template): Builder {
                return $query->where(function (Builder $templateQuery) use ($template): void {
                    $templateQuery
                        ->whereHas(
                            'template',
                            fn (Builder $currentTemplate): Builder => $currentTemplate->where('slug', $template)
                        )
                        ->orWhere(function (Builder $archivedTemplate) use ($template): void {
                            $archivedTemplate
                                ->whereNull('checklist_template_id')
                                ->where('template_snapshot->slug', $template);
                        });
                });
            })
            ->when($filters['status'], fn (Builder $query, string $status): Builder => $query->where('status', $status))
            ->orderByDesc('audit_date')
            ->orderByDesc('id');
    }

    /**
     * Return current templates plus snapshot-only templates visible to this user.
     *
     * @return Collection<int, array{slug: string, name: string, is_archived: bool}>
     */
    private function reportTemplateOptions(Request $request): Collection
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
     * Include submitted audits and drafts that contain at least one saved answer.
     * Non-administrators only see records from their assigned branch.
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

        if ($request->user()?->hasAdministrativeAccess() === true) {
            return $query;
        }

        $user = $request->user();
        $branch = mb_strtolower(trim((string) $user?->branch));

        if ($branch === '') {
            return $query->whereRaw('0 = 1');
        }

        $query->whereRaw('LOWER(TRIM(branch)) = ?', [$branch]);

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
     * @param  list<string>  $relations
     * @return Collection<int, array{label: string, month_key: string, score: ?float, count: int, active: bool}>
     */
    private function monthlyDosTrend(
        Request $request,
        mixed $monthStart,
        mixed $monthEnd,
        array $relations
    ): Collection {
        $firstMonth = $monthStart->copy()->subMonths(5);
        $submissions = (clone $this->reportableSubmissionQuery($request))
            ->with($relations)
            ->where('status', 'submitted')
            ->whereBetween('audit_date', [$firstMonth->toDateString(), $monthEnd->toDateString()])
            ->orderBy('audit_date')
            ->get()
            ->filter(fn (ChecklistSubmission $submission): bool => $this->isDosSubmission($submission))
            ->groupBy(fn (ChecklistSubmission $submission): string => $submission->audit_date?->format('Y-m') ?? 'undated');

        return collect(range(0, 5))->map(function (int $offset) use ($firstMonth, $monthStart, $submissions): array {
            $month = $firstMonth->copy()->addMonths($offset);
            $records = $submissions->get($month->format('Y-m'), collect());

            return [
                'label' => $month->format('M'),
                'month_key' => $month->format('Y-m'),
                'score' => $this->aggregate($records)['score'],
                'count' => $records->count(),
                'active' => $month->isSameMonth($monthStart),
            ];
        });
    }

    /**
     * @return Collection<int, array{label: string, score: ?float, yes: int, no: int, na: int}>
     */
    private function dosCategorySummaries(Collection $submissions): Collection
    {
        $categories = collect();

        foreach ($submissions as $submission) {
            foreach ($submission->responses as $response) {
                $status = $this->normalizedStatus($response->status);

                if (! in_array($status, ['yes', 'no', 'na'], true)) {
                    continue;
                }

                $label = trim((string) (
                    data_get($response->item_snapshot, 'section.title')
                    ?? data_get($response->item_snapshot, 'section_title')
                    ?? $response->item?->section?->title
                    ?? 'General'
                ));
                $sortOrder = (int) (
                    data_get($response->item_snapshot, 'section.sort_order')
                    ?? $response->item?->section?->sort_order
                    ?? PHP_INT_MAX
                );
                $key = mb_strtolower($label);
                $category = $categories->get($key, [
                    'label' => $label ?: 'General',
                    'sort_order' => $sortOrder,
                    'yes' => 0,
                    'no' => 0,
                    'na' => 0,
                ]);
                $category[$status]++;
                $category['sort_order'] = min($category['sort_order'], $sortOrder);
                $categories->put($key, $category);
            }
        }

        return $categories
            ->map(function (array $category): array {
                $category['score'] = $this->percentage($category['yes'], $category['yes'] + $category['no']);

                return $category;
            })
            ->sortBy([['sort_order', 'asc'], ['label', 'asc']])
            ->values();
    }

    /**
     * @param  list<string>  $relations
     * @return Collection<int, array<string, mixed>>
     */
    private function recentActivities(Request $request, array $relations): Collection
    {
        return (clone $this->reportableSubmissionQuery($request))
            ->with($relations)
            ->orderByDesc('updated_at')
            ->orderByDesc('id')
            ->limit(6)
            ->get()
            ->map(function (ChecklistSubmission $submission): array {
                $timestamp = $submission->submitted_at ?? $submission->updated_at;

                return [
                    'user' => $submission->submittedBy?->name
                        ?? $submission->user?->name
                        ?? data_get($submission->context, 'auditor')
                        ?? 'User unavailable',
                    'action' => $this->templateName($submission),
                    'branch' => $this->branchName($submission),
                    'status' => $submission->status,
                    'status_label' => $submission->status === 'submitted' ? 'Submitted' : 'Draft',
                    'date' => $timestamp?->format('M j, Y g:i A') ?? 'Date unavailable',
                ];
            });
    }

    /**
     * @return Collection<int, array{rank: int, branch: string, score: ?float, count: int, status: string}>
     */
    private function branchRankings(Collection $submissions): Collection
    {
        return $submissions
            ->groupBy(fn (ChecklistSubmission $submission): string => mb_strtolower($this->branchName($submission)))
            ->map(function (Collection $records): array {
                $score = $this->aggregate($records)['score'];

                return [
                    'branch' => $this->branchName($records->first()),
                    'score' => $score,
                    'count' => $records->count(),
                    'status' => match (true) {
                        $score === null => 'No score',
                        $score >= 90 => 'Excellent',
                        $score >= 80 => 'Good',
                        default => 'Needs Review',
                    },
                ];
            })
            ->sort(function (array $left, array $right): int {
                return ($right['score'] ?? -1) <=> ($left['score'] ?? -1)
                    ?: strcasecmp($left['branch'], $right['branch']);
            })
            ->values()
            ->map(fn (array $row, int $index): array => [
                'rank' => $index + 1,
                ...$row,
            ]);
    }

    /**
     * @return array{label: string, leading_blanks: int, days: Collection<int, array<string, mixed>>}
     */
    private function calendarData(Collection $submissions, mixed $monthStart, mixed $now): array
    {
        $byDate = $submissions->groupBy(
            fn (ChecklistSubmission $submission): string => $submission->audit_date?->toDateString() ?? 'undated'
        );
        $days = collect(range(1, $monthStart->daysInMonth))->map(function (int $day) use ($byDate, $monthStart, $now): array {
            $date = $monthStart->copy()->day($day);
            $records = $byDate->get($date->toDateString(), collect());

            return [
                'number' => $day,
                'date' => $date->toDateString(),
                'is_today' => $date->isSameDay($now),
                'audit_count' => $records->count(),
                'submitted_count' => $records->where('status', 'submitted')->count(),
                'draft_count' => $records->where('status', 'draft')->count(),
            ];
        });

        return [
            'label' => $monthStart->format('F Y'),
            'leading_blanks' => (int) $monthStart->dayOfWeek,
            'days' => $days,
        ];
    }

    /**
     * Build the report summary, breakdowns, history, and findings shown inside the dashboard.
     *
     * @return array<string, mixed>
     */
    private function reportAnalytics(Collection $submissions, ?User $viewer = null): array
    {
        $findings = $this->reportFindings($submissions, $viewer);
        $summary = $this->reportAggregate($submissions);
        $summary['audit_count'] = $submissions->count();
        $summary['submitted_count'] = $submissions->where('status', 'submitted')->count();
        $summary['draft_count'] = $submissions->where('status', 'draft')->count();
        $summary['findings_count'] = $findings->count();
        $summary['no_count'] = $findings->filter(fn (array $f): bool => in_array($f['status'], ['no', 'x'], true) || $f['is_overridden'])->count();
        $summary['escalation_count'] = $findings->filter(fn (array $f): bool => filled($f['escalation_target']))->count();
        $summary['overdue_count'] = $findings->filter(fn (array $f): bool => $f['is_overdue'] === true)->count();
        $summary['overridden_count'] = $findings->filter(fn (array $f): bool => $f['is_overridden'] === true)->count();

        $history = $submissions
            ->take(25)
            ->map(function (ChecklistSubmission $submission): array {
                $metric = $this->reportSubmissionMetric($submission);

                return [
                    'id' => $submission->getKey(),
                    'audit_date' => $submission->audit_date?->format('Y-m-d'),
                    'template_name' => $this->templateName($submission),
                    'template_slug' => $this->templateSlug($submission),
                    'branch' => $this->branchName($submission),
                    'auditor' => $submission->submittedBy?->name
                        ?? $submission->user?->name
                        ?? data_get($submission->context, 'auditor')
                        ?? 'Not recorded',
                    'status' => $submission->status,
                    'findings_count' => $this->submissionFindingCount($submission),
                    ...$metric,
                ];
            })
            ->values();

        $monthly = $this->reportGroupSummaries(
            $submissions,
            fn (ChecklistSubmission $submission): string => $submission->audit_date?->format('Y-m') ?? 'undated',
            fn (ChecklistSubmission $submission): array => [
                'label' => $submission->audit_date?->format('M Y') ?? 'Undated',
                'sort_key' => $submission->audit_date?->format('Y-m') ?? '0000-00',
            ]
        )->sortBy('sort_key')->values();

        return [
            'reportSummary' => $summary,
            'reportHistory' => $history,
            'reportFindings' => $findings,
            'reportModuleSummaries' => $this->reportGroupSummaries(
                $submissions,
                fn (ChecklistSubmission $submission): string => $this->templateSlug($submission),
                fn (ChecklistSubmission $submission): array => [
                    'label' => $this->templateName($submission),
                    'slug' => $this->templateSlug($submission),
                ]
            ),
            'reportBranchSummaries' => $this->reportGroupSummaries(
                $submissions,
                fn (ChecklistSubmission $submission): string => mb_strtolower($this->branchName($submission)),
                fn (ChecklistSubmission $submission): array => ['label' => $this->branchName($submission)]
            ),
            'reportMonthlySummaries' => $monthly->slice(-12)->values(),
        ];
    }

    /**
     * Extract non-compliant and overridden findings across all filtered report submissions.
     *
     * @return Collection<int, array<string, mixed>>
     */
    private function reportFindings(Collection $submissions, ?User $viewer = null): Collection
    {
        $findings = collect();

        foreach ($submissions as $submission) {
            foreach ($submission->responses as $response) {
                if ($this->isHourlyRestroom($submission)) {
                    $badSlots = collect(data_get($response->details, 'slots', []))
                        ->filter(fn (mixed $value): bool => $this->isBadSlotMark($value));

                    foreach ($badSlots as $slot => $value) {
                        $findings->push($this->reportFindingRow($submission, $response, 'x', (string) $slot, $viewer));
                    }

                    if ($badSlots->isEmpty() && (in_array($this->normalizedStatus($response->status), ['no', 'na'], true) || $response->isOverridden())) {
                        $findings->push($this->reportFindingRow($submission, $response, $this->normalizedStatus($response->status), null, $viewer));
                    }

                    continue;
                }

                $status = $this->normalizedStatus($response->status);

                if (in_array($status, ['no', 'na'], true) || $response->isOverridden()) {
                    $findings->push($this->reportFindingRow($submission, $response, $status, null, $viewer));
                }
            }
        }

        return $findings;
    }

    /**
     * @return array<string, mixed>
     */
    private function reportFindingRow(ChecklistSubmission $submission, mixed $response, string $status, ?string $slot = null, ?User $viewer = null): array
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

        $reportTimezone = config('gac.report_timezone', 'Asia/Manila');
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
        $commitmentDateInput = null;
        $isOverdue = false;
        $dueStatus = null;

        if ($commitmentDate) {
            $commitmentLocal = $commitmentDate->copy()->timezone($reportTimezone);
            $commitmentDateFormatted = $commitmentLocal->format('d M Y, h:i A');
            $commitmentDateInput = $commitmentLocal->format('Y-m-d');
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

        $attachmentUrl = filled($response->attachment_path)
            ? Storage::disk('public')->url($response->attachment_path)
            : null;

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
            'attachment_url' => $attachmentUrl,
            'escalation_target' => $escalationTargetNormalized ?? $escalationTarget,
            'escalation_target_label' => $escalationTargetLabel,
            'commitment_date' => $commitmentDateFormatted,
            'commitment_date_formatted' => $commitmentDateFormatted,
            'commitment_date_input' => $commitmentDateInput,
            'commitment_date_local' => $commitmentDate?->copy()->timezone($reportTimezone)->format('Y-m-d\TH:i'),
            'is_overdue' => $isOverdue,
            'due_status' => $dueStatus,
            'is_overridden' => $isOverridden,
            'override_details' => $isOverridden ? [
                'reason' => data_get($override, 'reason'),
                'overridden_by_name' => data_get($override, 'overridden_by_name'),
                'overridden_by_role' => data_get($override, 'overridden_by_role'),
                'overridden_at' => data_get($override, 'overridden_at'),
            ] : null,
            'can_override' => $canOverride,
        ];
    }

    /**
     * @param  callable(ChecklistSubmission): string  $keyBy
     * @param  callable(ChecklistSubmission): array<string, mixed>  $describe
     * @return Collection<int, array<string, mixed>>
     */
    private function reportGroupSummaries(Collection $submissions, callable $keyBy, callable $describe): Collection
    {
        return $submissions
            ->groupBy($keyBy)
            ->map(function (Collection $records) use ($describe): array {
                return [
                    ...$describe($records->first()),
                    'count' => $records->count(),
                    'findings_count' => $records
                        ->sum(fn (ChecklistSubmission $submission): int => $this->submissionFindingCount($submission)),
                    ...$this->reportAggregate($records),
                ];
            })
            ->sortBy('label', SORT_NATURAL | SORT_FLAG_CASE)
            ->values();
    }

    private function submissionFindingCount(ChecklistSubmission $submission): int
    {
        return $submission->responses->sum(function (mixed $response) use ($submission): int {
            $status = $this->normalizedStatus($response->status);

            if (! $this->isHourlyRestroom($submission)) {
                return in_array($status, ['no', 'na'], true) ? 1 : 0;
            }

            $slots = collect(is_array(data_get($response->details, 'slots'))
                ? data_get($response->details, 'slots')
                : []);
            $failedSlots = $slots->filter(fn (mixed $mark): bool => $this->isBadSlotMark($mark))->count();

            return $failedSlots > 0
                ? $failedSlots
                : (in_array($status, ['no', 'na'], true) ? 1 : 0);
        });
    }

    /**
     * Use the reporting rules for per-record scores, including the Restroom
     * checklist's time-slot score fields and saved percentages.
     *
     * @return array{score: ?float, completion: ?float, yes: int, no: int, na: int, applicable: int, answered: int, total: int}
     */
    private function reportSubmissionMetric(ChecklistSubmission $submission): array
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
            $fallbackGood = $slotMarks->filter(fn (mixed $mark): bool => $this->isGoodSlotMark($mark))->count();
            $fallbackBad = $slotMarks->filter(fn (mixed $mark): bool => $this->isBadSlotMark($mark))->count();
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

        return [
            'score' => $this->numericScore($scores, 'percentage') ?? $this->percentage($yes, $applicable),
            'completion' => $this->numericScore($scores, 'completion_percentage') ?? $this->percentage($answered, $total),
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
    private function reportAggregate(Collection $submissions): array
    {
        $totals = ['yes' => 0, 'no' => 0, 'na' => 0, 'applicable' => 0, 'answered' => 0, 'total' => 0];

        foreach ($submissions as $submission) {
            $metric = $this->reportSubmissionMetric($submission);

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
     * User data is assembled only for administrators and branch managers.
     * Branch managers can see accounts in their assigned branch only.
     *
     * @return array<string, mixed>
     */
    private function userAnalytics(Request $request): array
    {
        $query = User::query();

        if ($request->user()?->hasAdministrativeAccess() !== true) {
            $branch = mb_strtolower(trim((string) $request->user()?->branch));

            if ($branch === '') {
                $query->whereRaw('0 = 1');
            } else {
                $query->whereRaw('LOWER(TRIM(branch)) = ?', [$branch]);
            }
        }

        $users = $query->get(['id', 'name', 'email', 'branch', 'user_type', 'account_status', 'created_at']);
        $total = $users->count();
        $normalizedStatus = fn (User $user): string => mb_strtolower(trim((string) $user->account_status)) === 'active'
            ? 'active'
            : 'inactive';
        $statusCounts = $users->countBy($normalizedStatus);
        $roleOptions = User::roleOptions();

        $roleSummaries = collect($roleOptions)->map(function (string $label, string $code) use ($users, $total): array {
            $count = $users->filter(fn (User $user): bool => $user->roleCode() === $code)->count();

            return [
                'code' => $code,
                'label' => $label,
                'count' => $count,
                'percentage' => $this->percentage($count, $total),
            ];
        })->values();

        $statusSummaries = collect([
            'active' => 'Active',
            'inactive' => 'Inactive',
        ])->map(function (string $label, string $status) use ($statusCounts, $total): array {
            $count = (int) $statusCounts->get($status, 0);

            return [
                'status' => $status,
                'label' => $label,
                'count' => $count,
                'percentage' => $this->percentage($count, $total),
            ];
        })->values();

        $branchSummaries = $users
            ->groupBy(fn (User $user): string => mb_strtolower(trim((string) $user->branch)) ?: 'unassigned')
            ->map(function (Collection $branchUsers): array {
                $label = trim((string) $branchUsers->first()?->branch) ?: 'Unassigned';

                return [
                    'label' => $label,
                    'count' => $branchUsers->count(),
                    'active' => $branchUsers
                        ->filter(fn (User $user): bool => mb_strtolower((string) $user->account_status) === 'active')
                        ->count(),
                    'inactive' => $branchUsers
                        ->reject(fn (User $user): bool => mb_strtolower(trim((string) $user->account_status)) === 'active')
                        ->count(),
                ];
            })
            ->sort(function (array $left, array $right): int {
                return $right['count'] <=> $left['count'] ?: strcasecmp($left['label'], $right['label']);
            })
            ->values();

        $recentUsers = $users
            ->sortByDesc(fn (User $user) => $user->created_at)
            ->take(10)
            ->map(fn (User $user): array => [
                'id' => $user->getKey(),
                'name' => $user->name,
                'email' => $user->email,
                'branch' => trim((string) $user->branch) ?: 'Unassigned',
                'role' => $user->roleLabel(),
                'status' => $normalizedStatus($user),
                'created_at' => $user->created_at?->format('M j, Y') ?? 'Date unavailable',
            ])
            ->values();

        return [
            'userStats' => [
                'total' => $total,
                'active' => (int) $statusCounts->get('active', 0),
                'inactive' => (int) $statusCounts->get('inactive', 0),
                'pic' => $roleSummaries->firstWhere('code', User::ROLE_PERSON_IN_CHARGE)['count'] ?? 0,
                'bom' => $roleSummaries->firstWhere('code', User::ROLE_BRANCH_OPERATIONS_MANAGER)['count'] ?? 0,
                'admin' => $roleSummaries->firstWhere('code', User::ROLE_ADMINISTRATOR)['count'] ?? 0,
            ],
            'userRoleSummaries' => $roleSummaries,
            'userStatusSummaries' => $statusSummaries,
            'userBranchSummaries' => $branchSummaries,
            'recentUsers' => $recentUsers,
        ];
    }

    /**
     * @return array{score: ?float, completion: ?float, yes: int, no: int, na: int, applicable: int, answered: int, total: int}
     */
    private function aggregate(Collection $submissions): array
    {
        $totals = ['yes' => 0, 'no' => 0, 'na' => 0, 'applicable' => 0, 'answered' => 0, 'total' => 0];

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
     * @return array{yes: int, no: int, na: int, applicable: int, answered: int, total: int}
     */
    private function submissionMetric(ChecklistSubmission $submission): array
    {
        $scores = is_array($submission->scores) ? $submission->scores : [];
        $statuses = $submission->responses
            ->map(fn (mixed $response): string => $this->normalizedStatus($response->status))
            ->countBy();
        $slotMarks = $submission->responses
            ->flatMap(fn (mixed $response): array => is_array(data_get($response->details, 'slots'))
                ? data_get($response->details, 'slots')
                : []);
        $fallbackGood = $slotMarks->filter(fn (mixed $mark): bool => $this->isGoodSlotMark($mark))->count();
        $fallbackBad = $slotMarks->filter(fn (mixed $mark): bool => $this->isBadSlotMark($mark))->count();
        $yes = $this->integerScore($scores, 'yes', $this->integerScore($scores, 'good', $fallbackGood ?: (int) $statuses->get('yes', 0)));
        $no = $this->integerScore($scores, 'no', $this->integerScore($scores, 'bad', $fallbackBad ?: (int) $statuses->get('no', 0)));
        $na = $this->integerScore($scores, 'na', (int) $statuses->get('na', 0));
        $answered = $this->integerScore($scores, 'answered', $this->integerScore($scores, 'slots_answered', $yes + $no + $na));
        $total = $this->integerScore($scores, 'total', $this->integerScore($scores, 'slot_total', $answered));
        $applicable = $this->integerScore($scores, 'applicable', $yes + $no);

        return compact('yes', 'no', 'na', 'applicable', 'answered', 'total');
    }

    private function integerScore(array $scores, string $key, int $fallback): int
    {
        return array_key_exists($key, $scores) && is_numeric($scores[$key])
            ? max(0, (int) $scores[$key])
            : max(0, $fallback);
    }

    private function numericScore(array $scores, string $key): ?float
    {
        if (! array_key_exists($key, $scores) || ! is_numeric($scores[$key])) {
            return null;
        }

        return round(min(100, max(0, (float) $scores[$key])), 1);
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
            'dos', 'dealer operations standards' => self::DOS_SLUG,
            '5s', '5s checklist', 'gateway 5s' => 'gateway-5s',
            'restroom checklist' => 'restroom',
            default => $value,
        };
    }

    private function percentage(int $numerator, int $denominator): ?float
    {
        return $denominator > 0 ? round(($numerator / $denominator) * 100, 1) : null;
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

    /**
     * @param  Collection<int, mixed>  $items
     * @param  Collection<string, ChecklistResponse>  $responsesByKey
     * @param  list<string>  $timeSlotKeys
     * @return array{yes: int, no: int, answered: int, total: int}
     */
    private function timeSlotMetrics(Collection $items, Collection $responsesByKey, array $timeSlotKeys): array
    {
        $yes = 0;
        $no = 0;

        foreach ($items as $item) {
            $slots = data_get($responsesByKey->get($item->key)?->details, 'slots', []);
            if (! is_array($slots)) {
                continue;
            }

            foreach ($timeSlotKeys as $slotKey) {
                if (! array_key_exists($slotKey, $slots)) {
                    continue;
                }

                if ($this->isGoodSlotMark($slots[$slotKey])) {
                    $yes++;
                } elseif ($this->isBadSlotMark($slots[$slotKey])) {
                    $no++;
                }
            }
        }

        return [
            'yes' => $yes,
            'no' => $no,
            'answered' => $yes + $no,
            'total' => $items->count() * count($timeSlotKeys),
        ];
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
        if ($this->templateSlug($submission) !== 'restroom') {
            return false;
        }

        $settings = data_get($submission->template_snapshot, 'settings', []);

        $mode = is_array($settings) ? ($settings['validation_mode'] ?? null) : null;
        if ($mode !== null) {
            return $mode === 'time_slots';
        }

        // Older snapshots may not include template settings; infer the
        // legacy mode from the stored slot maps in that case.
        return $submission->responses->contains(
            fn (mixed $response): bool => is_array(data_get($response->details, 'slots'))
        );
    }

    private function isDosSubmission(ChecklistSubmission $submission): bool
    {
        return in_array($this->templateSlug($submission), self::DOS_SLUGS, true);
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

    private function templateName(ChecklistSubmission $submission): string
    {
        return $submission->template?->name
            ?? data_get($submission->template_snapshot, 'name')
            ?? 'Archived checklist';
    }

    private function branchName(ChecklistSubmission $submission): string
    {
        return trim((string) ($submission->branch ?: data_get($submission->context, 'branch'))) ?: 'Unassigned';
    }

    /**
     * Build the Summary Sheet data for the home dashboard overview,
     * modeled after the official FY25 DOS and Gateway 5S Excel workbooks.
     *
     * @return array<string, mixed>
     */
    private function summarySheetData(Request $request): array
    {
        $salesSlug = 'dealer-operations-standards-sales';
        $aftersalesSlug = self::DOS_SLUG; // 'dealer-operations-standards'
        $fiveSSlugs = [
            'sales' => 'sales',
            'service' => 'service',
            'restroom' => 'restroom',
        ];

        // Determine the requested DOS or 5S summary.
        $requestedForm = mb_strtolower(trim((string) ($request->query('form') ?? $request->query('checklist') ?? '')));
        $userAllowedSlugs = $this->dosAllowedChecklistSlugs($request);

        if ($userAllowedSlugs !== null) {
            if (! in_array($salesSlug, $userAllowedSlugs, true) && in_array($aftersalesSlug, $userAllowedSlugs, true)) {
                $requestedForm = 'aftersales';
            } elseif (in_array($salesSlug, $userAllowedSlugs, true) && ! in_array($aftersalesSlug, $userAllowedSlugs, true)) {
                $requestedForm = 'sales';
            }
        }

        $activeForm = match (true) {
            in_array($requestedForm, ['aftersales', 'service', 'dos', 'dealer-operations-standards'], true) => 'aftersales',
            in_array($requestedForm, ['5s', 'five-s', 'five_s', 'gateway-5s'], true) => 'five_s',
            default => 'sales',
        };

        $viewerAllowedSlugs = $request->user()?->allowedChecklistSlugs();
        $fiveSAreaOptions = collect([
            'sales' => 'Sales',
            'service' => 'Service',
            'restroom' => 'Restroom / Utility',
        ])->when(
            is_array($viewerAllowedSlugs),
            fn (Collection $areas): Collection => $areas->filter(
                fn (string $label, string $slug): bool => in_array($slug, $viewerAllowedSlugs, true)
            )
        );

        if ($fiveSAreaOptions->isEmpty()) {
            $fiveSAreaOptions = collect([
                'sales' => 'Sales',
                'service' => 'Service',
                'restroom' => 'Restroom / Utility',
            ]);
        }

        $requestedFiveSArea = mb_strtolower(trim((string) $request->query('five_s_area', '')));
        $fiveSArea = $fiveSAreaOptions->has($requestedFiveSArea)
            ? $requestedFiveSArea
            : (string) $fiveSAreaOptions->keys()->first();
        $fiveSAreaLabel = $fiveSAreaOptions->get($fiveSArea, ucfirst($fiveSArea));

        $activeSlug = match ($activeForm) {
            'aftersales' => $aftersalesSlug,
            'five_s' => $fiveSSlugs[$fiveSArea],
            default => $salesSlug,
        };
        $activeFormTitle = match ($activeForm) {
            'aftersales' => 'AFTERSALES STANDARDS COMPLIANCE AUDIT FORM FY2025',
            'five_s' => $fiveSArea === 'restroom'
                ? 'RESTROOM - UTILITY 5S CHECKLIST'
                : mb_strtoupper($fiveSAreaLabel).' 5S CHECKLIST',
            default => 'SALES STANDARDS COMPLIANCE AUDIT FORM FY2025',
        };
        $activeFormLabel = match ($activeForm) {
            'aftersales' => 'Aftersales Standards',
            'five_s' => $fiveSAreaLabel.' 5S Checklist',
            default => 'Sales Standards',
        };

        // Load active template
        $template = ChecklistTemplate::query()
            ->with(['sections.items' => fn ($q) => $q->where('is_active', true)->orderBy('sort_order')])
            ->where('slug', $activeSlug)
            ->first();

        $allItems = $template?->sections->flatMap->items ?? collect();
        $isFiveS = $activeForm === 'five_s';
        $isUtilityChecklist = $isFiveS && $activeSlug === 'restroom';
        $isTimeSlotChecklist = $isFiveS
            && $activeSlug === 'restroom'
            && data_get($template?->settings, 'validation_mode') === 'time_slots';
        $timeSlotOptions = $isTimeSlotChecklist
            ? collect(data_get($template?->settings, 'time_slots', []))
                ->map(function (mixed $slot): ?array {
                    $key = is_array($slot) ? ($slot['key'] ?? null) : $slot;
                    if (! is_string($key) || $key === '') {
                        return null;
                    }

                    return [
                        'value' => $key,
                        'label' => is_array($slot) && filled($slot['label'] ?? null)
                            ? (string) $slot['label']
                            : $key,
                    ];
                })
                ->filter()
                ->values()
            : collect();
        $timeSlotKeys = $timeSlotOptions->pluck('value')->all();
        $requestedUtilityTime = trim((string) $request->query('utility_time', ''));
        $selectedUtilityTime = $timeSlotOptions->contains(
            fn (array $option): bool => $option['value'] === $requestedUtilityTime
        ) ? $requestedUtilityTime : null;
        $selectedUtilityTimeLabel = $selectedUtilityTime
            ? data_get($timeSlotOptions->firstWhere('value', $selectedUtilityTime), 'label')
            : 'All Times';
        $activeTimeSlotKeys = $selectedUtilityTime ? [$selectedUtilityTime] : $timeSlotKeys;
        $totalQuestions = $allItems->count();

        // Determine branch scope
        $isAdministrator = $request->user()?->hasAdministrativeAccess() === true;
        $canSelectSummaryUser = $request->user()?->receivesTaskCompletionNotifications() === true;
        $canSwitchSummaryMode = $canSelectSummaryUser && $activeForm === 'aftersales';
        if ($request->has('score_view')) {
            $requestedSummaryMode = mb_strtolower(trim((string) $request->query('score_view', 'overall')));
        } elseif ($request->has('submission_id')) {
            $requestedSummaryMode = 'user';
        } else {
            $requestedSummaryMode = $canSwitchSummaryMode ? 'overall' : 'user';
        }
        $summaryMode = $canSwitchSummaryMode && $requestedSummaryMode === 'overall'
            ? 'overall'
            : 'user';
        $userBranch = trim((string) $request->user()?->branch);

        // Available branches
        $availableBranches = ChecklistSubmission::query()
            ->whereNotNull('branch')
            ->where('branch', '<>', '')
            ->distinct()
            ->orderBy('branch')
            ->pluck('branch')
            ->values();

        if (! $isAdministrator && $userBranch !== '') {
            $selectedBranch = $userBranch;
        } else {
            $queryBranch = trim((string) $request->query('branch', ''));
            if ($queryBranch !== '' && $availableBranches->contains(fn ($b) => strcasecmp($b, $queryBranch) === 0)) {
                $selectedBranch = $availableBranches->first(fn ($b) => strcasecmp($b, $queryBranch) === 0);
            } else {
                $selectedBranch = $availableBranches->first() ?? 'Pasong Tamo';
            }
        }

        // Submissions for this template and branch
        $submissionsQuery = (clone $this->reportableSubmissionQuery($request))
            ->where(function (Builder $q) use ($activeSlug): void {
                $q->whereHas('template', fn (Builder $t) => $t->where('slug', $activeSlug))
                    ->orWhere('template_snapshot->slug', $activeSlug);
            });

        if ($selectedBranch !== '') {
            $submissionsQuery->whereRaw('LOWER(TRIM(branch)) = ?', [mb_strtolower($selectedBranch)]);
        }

        $availableUsers = collect();
        $selectedUser = null;

        if ($canSelectSummaryUser) {
            $availableUserIds = (clone $submissionsQuery)
                ->get(['user_id', 'submitted_by_user_id'])
                ->flatMap(fn (ChecklistSubmission $submission): array => [
                    $submission->submitted_by_user_id,
                    $submission->user_id,
                ])
                ->filter()
                ->unique()
                ->values();

            $availableUsers = User::query()
                ->whereKey($availableUserIds->all())
                ->orderBy('name')
                ->orderBy('id')
                ->get(['id', 'name', 'email', 'branch', 'user_type']);

            if ($summaryMode === 'user') {
                $requestedUserId = (int) $request->query('user_id', 0);
                if ($requestedUserId > 0) {
                    $selectedUser = $availableUsers->first(
                        fn (User $user): bool => (int) $user->getKey() === $requestedUserId
                    );
                }

                $selectedUser ??= $availableUsers->first();

                if ($selectedUser) {
                    $selectedUserId = $selectedUser->getKey();
                    $submissionsQuery->where(function (Builder $userQuery) use ($selectedUserId): void {
                        $userQuery
                            ->where('user_id', $selectedUserId)
                            ->orWhere('submitted_by_user_id', $selectedUserId);
                    });
                }
            }
        }

        $availableSubmissions = (clone $submissionsQuery)
            ->orderByDesc('audit_date')
            ->orderByDesc('id')
            ->get([
                'id',
                'user_id',
                'submitted_by_user_id',
                'branch',
                'audit_date',
                'status',
                'checklist_template_id',
                'created_at',
            ])
            ->map(function ($sub) {
                $submissionDate = $sub->audit_date ?? $sub->created_at;
                $sub->period_label = $this->formatAuditMonthPeriod($submissionDate, false);
                $sub->period_with_year = $this->formatAuditMonthPeriod($submissionDate, true);
                $sub->audit_year = $submissionDate?->format('Y');

                return $sub;
            });

        // The Restroom / Utility checklist is completed daily. Month-and-day
        // navigation resolves the latest saved audit for the selected date.
        $utilityAuditMonths = $isUtilityChecklist
            ? $availableSubmissions
                ->map(function (ChecklistSubmission $submission): ?array {
                    $submissionDate = $submission->audit_date ?? $submission->created_at;

                    return $submissionDate ? [
                        'value' => $submissionDate->format('Y-m'),
                        'label' => $submissionDate->format('F Y'),
                    ] : null;
                })
                ->filter()
                ->unique('value')
                ->values()
            : collect();
        $requestedUtilityMonth = trim((string) $request->query('utility_month', ''));
        $requestedUtilityMonth = $utilityAuditMonths->contains(
            fn (array $option): bool => $option['value'] === $requestedUtilityMonth
        ) ? $requestedUtilityMonth : null;
        $requestedUtilityDay = trim((string) $request->query('utility_day', ''));
        $requestedUtilityDay = $isUtilityChecklist
            && preg_match('/^\d{4}-\d{2}-\d{2}$/', $requestedUtilityDay) === 1
            && $availableSubmissions->contains(function (ChecklistSubmission $submission) use ($requestedUtilityDay): bool {
                $submissionDate = $submission->audit_date ?? $submission->created_at;

                return $submissionDate?->toDateString() === $requestedUtilityDay;
            })
                ? $requestedUtilityDay
                : null;

        if ($requestedUtilityDay) {
            $requestedUtilityMonth = substr($requestedUtilityDay, 0, 7);
        }

        $eligibleAftersalesUserIds = $summaryMode === 'overall'
            ? $availableUsers
                ->filter(function (User $user) use ($activeSlug): bool {
                    $allowedSlugs = $user->allowedChecklistSlugs();

                    return $user->isDosOperationalRole()
                        && is_array($allowedSlugs)
                        && in_array($activeSlug, $allowedSlugs, true);
                })
                ->map(fn (User $user): int => (int) $user->getKey())
                ->values()
                ->all()
            : [];
        $availableOverallAuditDates = $summaryMode === 'overall'
            ? $availableSubmissions
                ->filter(function (ChecklistSubmission $submission) use ($eligibleAftersalesUserIds): bool {
                    $submitterId = $submission->submitted_by_user_id ?: $submission->user_id;

                    return $submitterId !== null
                        && in_array((int) $submitterId, $eligibleAftersalesUserIds, true)
                        && $submission->audit_date !== null;
                })
                ->map(fn (ChecklistSubmission $submission): array => [
                    'value' => $submission->audit_date->toDateString(),
                    'label' => $submission->audit_date->format('F j, Y'),
                ])
                ->unique('value')
                ->values()
            : collect();
        $requestedOverallAuditDate = trim((string) $request->query('audit_date', ''));
        $selectedOverallAuditDate = $summaryMode === 'overall'
            && $availableOverallAuditDates->contains(
                fn (array $option): bool => $option['value'] === $requestedOverallAuditDate
            )
                ? $requestedOverallAuditDate
                : null;

        // Find selected submission
        $requestedSubId = (int) $request->query('submission_id', 0);
        $selectedSubmission = null;
        if ($summaryMode === 'user' && $requestedSubId > 0) {
            $selectedSubmission = (clone $submissionsQuery)
                ->with(['responses.item.section', 'submittedBy', 'user'])
                ->where('id', $requestedSubId)
                ->first();
        }

        if ($summaryMode === 'user' && ! $selectedSubmission && $requestedUtilityDay) {
            $selectedSubmission = (clone $submissionsQuery)
                ->with(['responses.item.section', 'submittedBy', 'user'])
                ->whereDate('audit_date', $requestedUtilityDay)
                ->orderByDesc('id')
                ->first();
        }

        if ($summaryMode === 'user' && ! $selectedSubmission && $requestedUtilityMonth) {
            $selectedSubmission = (clone $submissionsQuery)
                ->with(['responses.item.section', 'submittedBy', 'user'])
                ->whereYear('audit_date', (int) substr($requestedUtilityMonth, 0, 4))
                ->whereMonth('audit_date', (int) substr($requestedUtilityMonth, 5, 2))
                ->orderByDesc('audit_date')
                ->orderByDesc('id')
                ->first();
        }

        if ($summaryMode === 'user' && ! $selectedSubmission && $availableSubmissions->isNotEmpty()) {
            $latestId = $availableSubmissions->first()->id;
            $selectedSubmission = (clone $submissionsQuery)
                ->with(['responses.item.section', 'submittedBy', 'user'])
                ->where('id', $latestId)
                ->first();
        }

        $selectedUtilityDate = $isUtilityChecklist
            ? ($selectedSubmission?->audit_date ?? $selectedSubmission?->created_at)
            : null;
        $selectedUtilityMonth = $selectedUtilityDate?->format('Y-m')
            ?? $requestedUtilityMonth
            ?? data_get($utilityAuditMonths->first(), 'value');
        $utilityAuditDays = $isUtilityChecklist && $selectedUtilityMonth
            ? $availableSubmissions
                ->filter(function (ChecklistSubmission $submission) use ($selectedUtilityMonth): bool {
                    $submissionDate = $submission->audit_date ?? $submission->created_at;

                    return $submissionDate?->format('Y-m') === $selectedUtilityMonth;
                })
                ->map(function (ChecklistSubmission $submission): ?array {
                    $submissionDate = $submission->audit_date ?? $submission->created_at;

                    return $submissionDate ? [
                        'value' => $submissionDate->toDateString(),
                        'label' => $submissionDate->format('l, F j'),
                    ] : null;
                })
                ->filter()
                ->unique('value')
                ->values()
            : collect();
        $selectedUtilityDay = $selectedUtilityDate?->toDateString()
            ?? data_get($utilityAuditDays->first(), 'value');

        // Per-user mode scores only the workbook items assigned to that user's
        // checker role. Overall Aftersales mode combines one visible audit from
        // each operational user, using either their latest audit or the audit
        // recorded on the specifically selected date.
        $aggregateSubmissions = collect();
        $responsesByKey = collect();

        if ($summaryMode === 'overall') {
            $aggregateSubmissions = (clone $submissionsQuery)
                ->with(['responses.item.section', 'submittedBy', 'user'])
                ->when(
                    $selectedOverallAuditDate,
                    fn (Builder $query, string $auditDate): Builder => $query->whereDate('audit_date', $auditDate)
                )
                ->orderByDesc('audit_date')
                ->orderByDesc('id')
                ->get()
                ->filter(function (ChecklistSubmission $submission) use ($eligibleAftersalesUserIds): bool {
                    $submitterId = $submission->submitted_by_user_id ?: $submission->user_id;

                    return $submitterId !== null
                        && in_array((int) $submitterId, $eligibleAftersalesUserIds, true);
                })
                ->unique(fn (ChecklistSubmission $submission): string => 'user:'.(
                    $submission->submitted_by_user_id ?: $submission->user_id
                ))
                ->values();

            foreach ($aggregateSubmissions as $aggregateSubmission) {
                foreach ($aggregateSubmission->responses as $response) {
                    $responseKey = $response->item_key ?: ($response->item?->key ?? '');

                    if ($responseKey !== '' && ! $responsesByKey->has($responseKey)) {
                        $responsesByKey->put($responseKey, $response);
                    }
                }
            }
        } elseif ($selectedSubmission) {
            $responsesByKey = $selectedSubmission->responses
                ->keyBy(fn ($response) => $response->item_key ?: ($response->item?->key ?? ''));
        }

        $scoreUser = $summaryMode === 'user'
            ? ($selectedUser ?? $request->user())
            : null;
        $scoredItems = $allItems;

        if ($summaryMode === 'user') {
            $scoreRole = User::roleCodeFor(
                $selectedSubmission?->submitted_by_user_type ?: $scoreUser?->user_type
            );
            $roleAssignedItems = $allItems
                ->filter(fn ($item): bool => User::roleCodeFor(
                    data_get($item->metadata, 'checker')
                ) === $scoreRole)
                ->values();

            if ($roleAssignedItems->isNotEmpty()) {
                $scoredItems = $roleAssignedItems;
            }
        }

        $countYes = 0;
        $countNo = 0;
        $countNa = 0;

        if ($isTimeSlotChecklist) {
            $slotMetrics = $this->timeSlotMetrics($scoredItems, $responsesByKey, $activeTimeSlotKeys);
            $countYes = $slotMetrics['yes'];
            $countNo = $slotMetrics['no'];
        } else {
            foreach ($scoredItems as $item) {
                $r = $responsesByKey->get($item->key);
                $st = $r ? $this->normalizedStatus($r->status) : '';
                if ($st === 'yes') {
                    $countYes++;
                } elseif ($st === 'no') {
                    $countNo++;
                } elseif ($st === 'na') {
                    $countNa++;
                }
            }
        }

        $salesCategoryBaselines = ['Basic' => 14, 'Standard' => 66, 'Beyond' => 10];
        $salesCoverageBaselines = [
            'Facilities' => 23,
            'Systems' => 4,
            'Manpower' => 5,
            'Lead Generation and Management' => 9,
            'Needs Analysis' => 3,
            'Customer Engagement and Showroom Operations' => 8,
            'Product Presentation and Test Drive' => 6,
            'Deal and Closing Management' => 2,
            'Application Process Support' => 3,
            'Sales Operation Management' => 8,
            'Vehicle Release Management' => 11,
            'Post-Release Customer Management' => 3,
            'Mandatory Reports' => 5,
        ];

        $aftersalesCategoryBaselines = ['Basic' => 8, 'Standard' => 63, 'Beyond' => 4];
        $aftersalesCoverageBaselines = [
            'Facilities' => 12,
            'Systems' => 4,
            'Manpower' => 5,
            'Pro-active Customer Contact' => 3,
            'Customer Appointment' => 5,
            'Personalized Customer Reception' => 8,
            'Menu Pricing / Commitment of Price and Time Delivery' => 3,
            'Customer Care and Communication' => 7,
            'Workshop Scheduling' => 5,
            'Advance Info to Parts Store' => 2,
            'Repair Order Processing and Quality of Work' => 4,
            'Repair Order Completion and Invoicing' => 4,
            'Customer Information and Car Return' => 5,
            'Customer After Service Contact' => 3,
            'Concern Prevention and Resolution' => 5,
        ];

        $fiveSCoverageBaselines = $template?->sections
            ->mapWithKeys(fn ($section): array => [
                $section->title => $section->items->count() * ($isTimeSlotChecklist ? count($activeTimeSlotKeys) : 1),
            ])
            ->all() ?? [];
        $activeCategoryBaselines = match ($activeForm) {
            'aftersales' => $aftersalesCategoryBaselines,
            'five_s' => [
                '5S Checklist' => $scoredItems->count() * ($isTimeSlotChecklist ? count($activeTimeSlotKeys) : 1),
            ],
            default => $salesCategoryBaselines,
        };
        $activeCoverageBaselines = match ($activeForm) {
            'aftersales' => $aftersalesCoverageBaselines,
            'five_s' => $fiveSCoverageBaselines,
            default => $salesCoverageBaselines,
        };
        $totalQuestions = $isTimeSlotChecklist
            ? $scoredItems->count() * count($activeTimeSlotKeys)
            : ($summaryMode === 'overall'
                ? array_sum($activeCategoryBaselines)
                : $scoredItems->count());

        $answeredCount = $countYes + $countNo + $countNa;
        $completionRate = $totalQuestions > 0 ? round(($answeredCount / $totalQuestions) * 100, 1) : 0.0;
        $isCompletionBelowTarget = $completionRate < 90.0;

        // Table 1: Overall Audit Score
        $tiersDefinition = $isFiveS
            ? ['5S Checklist' => ['target' => null, 'label' => $fiveSAreaLabel.' 5S']]
            : [
                'Basic' => ['target' => 100, 'label' => 'Basic'],
                'Standard' => ['target' => 80, 'label' => 'Standard'],
                'Beyond' => ['target' => null, 'label' => 'Beyond'],
            ];

        $overallScores = [];
        $tierNumber = 1;
        $usesBeyondBonus = $summaryMode === 'overall' && $activeForm === 'aftersales';
        $baseTotalApplicable = 0;
        $baseTotalScore = 0;
        $beyondApplicable = 0;
        $beyondScore = 0;

        foreach ($tiersDefinition as $tierName => $def) {
            $tierItems = $isFiveS
                ? $scoredItems
                : $scoredItems->filter(
                    fn ($i) => strcasecmp(trim((string) data_get($i->metadata, 'level', data_get($i->metadata, 'category', ''))), $tierName) === 0
                );

            $tierNa = 0;
            $tierYes = 0;

            if ($isTimeSlotChecklist) {
                $tierSlotMetrics = $this->timeSlotMetrics($tierItems, $responsesByKey, $activeTimeSlotKeys);
                $tierYes = $tierSlotMetrics['yes'];
            } else {
                foreach ($tierItems as $ti) {
                    $r = $responsesByKey->get($ti->key);
                    $st = $r ? $this->normalizedStatus($r->status) : '';
                    if ($st === 'na') {
                        $tierNa++;
                    } elseif ($st === 'yes') {
                        $tierYes++;
                    }
                }
            }

            $baselineCount = $isTimeSlotChecklist
                ? $tierSlotMetrics['total']
                : ($summaryMode === 'overall'
                    ? ($activeCategoryBaselines[$tierName] ?? $tierItems->count())
                    : $tierItems->count());
            $tierApplicable = max(0, $baselineCount - $tierNa);
            $tierPct = $tierApplicable > 0 ? round(($tierYes / $tierApplicable) * 100, 1) : 0.0;

            $rating = '—';
            if ($def['target'] !== null && $baselineCount > 0) {
                $passes = ($tierApplicable > 0 || $baselineCount > 0) && ($tierPct >= $def['target']);
                $rating = $passes ? 'PASS' : 'FAIL';
            }

            $overallScores[] = [
                'no' => $tierNumber++,
                'category' => $def['label'],
                'target' => $def['target'],
                'total' => $tierApplicable,
                'score' => $tierYes,
                'percent' => $tierPct,
                'rating' => $rating,
            ];

            if ($usesBeyondBonus && $tierName === 'Beyond') {
                $beyondApplicable = $tierApplicable;
                $beyondScore = $tierYes;
            } else {
                $baseTotalApplicable += $tierApplicable;
                $baseTotalScore += $tierYes;
            }
        }

        $baseTotalPct = $baseTotalApplicable > 0
            ? round(($baseTotalScore / $baseTotalApplicable) * 100, 1)
            : 0.0;
        $beyondBonusApplied = $usesBeyondBonus
            && ($baseTotalScore * 100) < ($baseTotalApplicable * 80)
            ? min($beyondScore, max(0, $baseTotalApplicable - $baseTotalScore))
            : 0;
        $overallTotalApplicable = $baseTotalApplicable;
        $overallTotalScore = min(
            $overallTotalApplicable,
            $baseTotalScore + $beyondBonusApplied
        );
        $beyondBonusPercentagePoints = $usesBeyondBonus && $overallTotalApplicable > 0
            ? round(($beyondBonusApplied / $overallTotalApplicable) * 100, 1)
            : 0.0;
        $overallTotalPct = $overallTotalApplicable > 0
            ? round(($overallTotalScore / $overallTotalApplicable) * 100, 1)
            : 0.0;

        $requiredTierRows = collect($overallScores)
            ->filter(fn (array $row): bool => $row['target'] !== null
                && in_array($row['rating'], ['PASS', 'FAIL'], true));
        $overallPasses = $overallTotalApplicable > 0
            && $overallTotalPct >= 80.0
            && ($usesBeyondBonus
                || $requiredTierRows->every(fn (array $row): bool => $row['rating'] === 'PASS'));
        $overallRating = $isFiveS ? '—' : ($overallPasses ? 'PASS' : 'FAIL');

        $overallSummaryRow = [
            'category' => 'TOTAL',
            'total' => $overallTotalApplicable,
            'score' => $overallTotalScore,
            'percent' => $overallTotalPct,
            'rating' => $overallRating,
            'uses_beyond_bonus' => $usesBeyondBonus,
            'base_score' => $baseTotalScore,
            'base_percent' => $baseTotalPct,
            'beyond_total' => $beyondApplicable,
            'beyond_score' => $beyondScore,
            'beyond_bonus_applied' => $beyondBonusApplied,
            'beyond_bonus_percentage_points' => $beyondBonusPercentagePoints,
        ];

        // Table 2: Compliance Per Category (Coverage breakdown)
        $orderedCoverageList = array_keys($activeCoverageBaselines);

        $itemsByCoverage = $scoredItems->groupBy(function ($item) {
            $cov = trim((string) data_get($item->metadata, 'coverage', $item->section?->title ?? 'General'));

            return $cov !== '' ? $cov : 'General';
        });

        if ($summaryMode === 'user') {
            $assignedCoverage = $itemsByCoverage->keys();
            $orderedCoverageList = collect($orderedCoverageList)
                ->filter(fn (string $coverage): bool => $assignedCoverage->contains($coverage))
                ->concat($assignedCoverage->diff($orderedCoverageList))
                ->values()
                ->all();
        }

        $coverageRows = [];
        $coverageNo = 1;
        $covTotalSum = 0;
        $covScoreSum = 0;

        foreach ($orderedCoverageList as $covName) {
            $covItems = $itemsByCoverage->get($covName, collect());
            if ($covItems->isEmpty()) {
                $covItems = $scoredItems->filter(
                    fn ($i) => strcasecmp(trim((string) data_get($i->metadata, 'coverage', $i->section?->title ?? '')), $covName) === 0
                );
            }

            $cNa = 0;
            $cYes = 0;

            if ($isTimeSlotChecklist) {
                $coverageSlotMetrics = $this->timeSlotMetrics($covItems, $responsesByKey, $activeTimeSlotKeys);
                $cYes = $coverageSlotMetrics['yes'];
            } else {
                foreach ($covItems as $ci) {
                    $r = $responsesByKey->get($ci->key);
                    $st = $r ? $this->normalizedStatus($r->status) : '';
                    if ($st === 'na') {
                        $cNa++;
                    } elseif ($st === 'yes') {
                        $cYes++;
                    }
                }
            }

            $cBaseline = $isTimeSlotChecklist
                ? $coverageSlotMetrics['total']
                : ($summaryMode === 'overall'
                    ? ($activeCoverageBaselines[$covName] ?? $covItems->count())
                    : $covItems->count());
            $cApplicable = max(0, $cBaseline - $cNa);
            $cPct = $cApplicable > 0 ? round(($cYes / $cApplicable) * 100, 1) : 0.0;

            $coverageRows[] = [
                'no' => $coverageNo++,
                'coverage' => $covName,
                'total' => $cApplicable,
                'score' => $cYes,
                'percent' => $cPct,
            ];

            $covTotalSum += $cApplicable;
            $covScoreSum += $cYes;
        }

        $covOverallPct = $covTotalSum > 0 ? round(($covScoreSum / $covTotalSum) * 100, 1) : 0.0;
        $coverageSummaryRow = [
            'total' => $covTotalSum,
            'score' => $covScoreSum,
            'percent' => $covOverallPct,
        ];

        // Metadata block
        $auditDateRaw = $selectedSubmission?->audit_date
            ?? ($selectedOverallAuditDate ? Carbon::parse($selectedOverallAuditDate) : null)
            ?? $aggregateSubmissions->max('audit_date')
            ?? now();
        $selectedOverallAuditDateLabel = $selectedOverallAuditDate
            ? Carbon::parse($selectedOverallAuditDate)->format('F j, Y')
            : null;
        $auditDateFormatted = $summaryMode === 'overall'
            ? ($selectedOverallAuditDateLabel
                ?? ($aggregateSubmissions->isNotEmpty() ? 'Latest audit per user' : 'No recorded audits'))
            : $this->formatAuditMonthPeriod($auditDateRaw, false);
        $auditDateWithYear = $summaryMode === 'overall'
            ? ($selectedOverallAuditDateLabel
                ?? ($aggregateSubmissions->isNotEmpty() ? 'Latest visible user audits' : 'No recorded audits'))
            : $this->formatAuditMonthPeriod($auditDateRaw, true);
        $auditorName = $summaryMode === 'overall'
            ? trans_choice(
                ':count Aftersales user|:count Aftersales users',
                $aggregateSubmissions->count(),
                ['count' => $aggregateSubmissions->count()]
            )
            : ($selectedSubmission?->submittedBy?->name
                ?? $selectedSubmission?->user?->name
                ?? data_get($selectedSubmission?->context, 'auditor')
                ?? $scoreUser?->name
                ?? 'Auditor');

        $auditStatus = $summaryMode === 'overall' && $aggregateSubmissions->isNotEmpty()
            ? 'aggregate'
            : ($selectedSubmission?->status ?? 'unrecorded');
        $auditStatusLabel = match ($auditStatus) {
            'submitted' => 'Submitted',
            'draft' => 'Draft / In Progress',
            'aggregate' => 'Overall Aftersales Users',
            default => 'No Saved Audit',
        };
        $viewerRole = $request->user()?->roleCode();
        $canViewFindings = $viewerRole === User::ROLE_ADMINISTRATOR;
        $canManageEscalations = $viewerRole === User::ROLE_BRANCH_OPERATIONS_MANAGER;
        $canManageFindings = $canViewFindings || $canManageEscalations;
        $findingSubmissions = $summaryMode === 'overall'
            ? $aggregateSubmissions
            : collect([$selectedSubmission])->filter();
        $nonCompliantFindings = $canManageFindings
            ? $findingSubmissions
                ->flatMap(
                    fn (ChecklistSubmission $submission): Collection => $this->summaryNonCompliantFindings(
                        $submission,
                        $isTimeSlotChecklist ? $selectedUtilityTime : null
                    )
                )
                ->values()
            : collect();
        $requestedFollowUpResponseId = $canManageEscalations
            ? (int) $request->query('follow_up_response_id', 0)
            : 0;
        $followUpResponseId = $requestedFollowUpResponseId > 0
            && $nonCompliantFindings->contains(
                fn (array $finding): bool => (int) $finding['response_id'] === $requestedFollowUpResponseId
            )
                ? $requestedFollowUpResponseId
                : null;

        return [
            'activeForm' => $activeForm,
            'activeSlug' => $activeSlug,
            'activeFormTitle' => $activeFormTitle,
            'activeFormLabel' => $activeFormLabel,
            'fiveSArea' => $fiveSArea,
            'fiveSAreaLabel' => $fiveSAreaLabel,
            'fiveSAreaOptions' => $fiveSAreaOptions,
            'isUtilityChecklist' => $isUtilityChecklist,
            'isTimeSlotChecklist' => $isTimeSlotChecklist,
            'timeSlotCount' => count($timeSlotKeys),
            'activeTimeSlotCount' => count($activeTimeSlotKeys),
            'utilityTimeOptions' => $timeSlotOptions,
            'selectedUtilityTime' => $selectedUtilityTime,
            'selectedUtilityTimeLabel' => $selectedUtilityTimeLabel,
            'dealer' => 'Gateway Motors',
            'outlet' => $selectedBranch,
            'date' => $auditDateFormatted,
            'date_with_year' => $auditDateWithYear,
            'period' => $auditDateFormatted,
            'year' => $auditDateRaw->format('Y'),
            'auditor' => $auditorName,
            'status' => $auditStatus,
            'statusLabel' => $auditStatusLabel,
            'submission' => $selectedSubmission,
            'summaryMode' => $summaryMode,
            'canSwitchSummaryMode' => $canSwitchSummaryMode,
            'scoreContextLabel' => $summaryMode === 'overall'
                ? 'Overall Aftersales Users'
                : ($scoreUser?->name ?? 'Selected User'),
            'scoreContextRole' => $summaryMode === 'user' ? $scoreUser?->roleLabel() : null,
            'aggregateUserCount' => $aggregateSubmissions->count(),
            'canManageFindings' => $canManageFindings,
            'canViewFindings' => $canViewFindings,
            'canManageEscalations' => $canManageEscalations,
            'followUpResponseId' => $followUpResponseId,
            'nonCompliantFindings' => $nonCompliantFindings,
            'escalationOptions' => ChecklistResponse::escalationTargetOptionsFor($activeSlug),
            'cards' => [
                'total_questions' => $totalQuestions,
                'answered' => $answeredCount,
                'completion_rate' => $completionRate,
                'is_below_target' => $isCompletionBelowTarget,
                'count_yes' => $countYes,
                'count_no' => $countNo,
                'count_na' => $countNa,
                'item_total' => $scoredItems->count(),
                'coverage_count' => count($activeCoverageBaselines),
            ],
            'overallScores' => $overallScores,
            'overallSummaryRow' => $overallSummaryRow,
            'coverageRows' => $coverageRows,
            'coverageSummaryRow' => $coverageSummaryRow,
            'printCoverageOrder' => array_keys($activeCoverageBaselines),
            'availableBranches' => $availableBranches,
            'selectedBranch' => $selectedBranch,
            'canSelectUser' => $canSelectSummaryUser,
            'availableUsers' => $availableUsers,
            'selectedUser' => $selectedUser,
            'selectedUserId' => $selectedUser?->getKey(),
            'selectedUserType' => $selectedUser?->roleCode(),
            'availableSubmissions' => $availableSubmissions,
            'selectedSubmissionId' => $selectedSubmission?->id,
            'utilityAuditMonths' => $utilityAuditMonths,
            'selectedUtilityMonth' => $selectedUtilityMonth,
            'utilityAuditDays' => $utilityAuditDays,
            'selectedUtilityDay' => $selectedUtilityDay,
            'availableOverallAuditDates' => $availableOverallAuditDates,
            'selectedOverallAuditDate' => $selectedOverallAuditDate,
            'checklistRoute' => route('checklists.index', [
                'checklist' => $activeSlug,
                'branch' => $selectedBranch,
            ]),
            'subformDocData' => $activeForm === 'aftersales'
                ? app(AftersalesSubformDocService::class)->getSubformAndDocumentationResults(
                    $selectedBranch,
                    $summaryMode === 'overall' ? $selectedOverallAuditDate : ($selectedSubmission?->audit_date?->toDateString()),
                    $selectedSubmission?->id,
                    $summaryMode,
                    $selectedUser?->getKey()
                )
                : [
                    'has_submissions' => false,
                    'has_subform' => false,
                    'has_documentation' => false,
                    'button_label' => '',
                    'badge_label' => '',
                    'audit_date' => '',
                    'auditor' => '',
                    'branch' => $selectedBranch ?? '',
                    'subform' => [],
                    'documentation' => [],
                ],
        ];
    }

    /**
     * Build the manager-facing register behind the Non-Compliant card. The
     * workbook checker/escalation metadata is shown beside the actual user who
     * submitted the audit so managers can distinguish responsibility from the
     * recorded checker.
     *
     * @return Collection<int, array<string, mixed>>
     */
    private function summaryNonCompliantFindings(
        ?ChecklistSubmission $submission,
        ?string $selectedTimeSlot = null
    ): Collection {
        if (! $submission) {
            return collect();
        }

        $submission->loadMissing(['responses.item.section', 'submittedBy', 'user']);
        $submitter = $submission->submittedBy ?? $submission->user;
        $checkedByName = $submission->submitted_by_name
            ?: $submitter?->name
            ?: data_get($submission->context, 'auditor')
            ?: 'Not recorded';
        $checkedByRole = User::roleLabelFor(
            $submission->submitted_by_user_type ?: $submitter?->user_type
        );
        $checkedTimestamp = $submission->submitted_at ?? $submission->updated_at;
        $checkedAt = $checkedTimestamp
            ? $checkedTimestamp->copy()->timezone(config('gac.report_timezone', 'Asia/Manila'))->format('d M Y, h:i A')
            : null;

        return $submission->responses
            ->filter(function (ChecklistResponse $response) use ($selectedTimeSlot): bool {
                if ($selectedTimeSlot === null) {
                    return $this->normalizedStatus($response->status) === 'no';
                }

                return $this->isBadSlotMark(data_get($response->details, 'slots.'.$selectedTimeSlot));
            })
            ->sortBy(function (ChecklistResponse $response): array {
                return [
                    (int) (data_get($response->item_snapshot, 'section.sort_order')
                        ?? $response->item?->section?->sort_order
                        ?? PHP_INT_MAX),
                    (int) (data_get($response->item_snapshot, 'sort_order')
                        ?? $response->item?->sort_order
                        ?? PHP_INT_MAX),
                    $response->getKey(),
                ];
            })
            ->map(function (ChecklistResponse $response) use ($submission, $checkedByName, $checkedByRole, $checkedAt): array {
                $snapshot = is_array($response->item_snapshot) ? $response->item_snapshot : [];
                $snapshotMetadata = data_get($snapshot, 'metadata');
                $metadata = is_array($snapshotMetadata)
                    ? $snapshotMetadata
                    : (is_array($response->item?->metadata) ? $response->item->metadata : []);
                $question = trim((string) (
                    data_get($snapshot, 'prompt')
                    ?? $response->item?->prompt
                    ?? $response->item_key
                ));
                $area = trim((string) (
                    data_get($metadata, 'coverage')
                    ?? data_get($snapshot, 'section.title')
                    ?? $response->item?->section?->title
                    ?? 'General'
                ));
                $finding = $response->finding
                    ?: data_get($response->details, 'finding')
                    ?: $response->remark
                    ?: data_get($response->details, 'remark')
                    ?: data_get($response->details, 'note')
                    ?: 'No finding or reason was recorded.';
                $actionPlan = $response->action_plan
                    ?: data_get($response->details, 'action_plan')
                    ?: data_get($response->details, 'action');
                $currentEscalation = ChecklistResponse::normalizeEscalationTarget(
                    $response->escalation_target
                        ?? data_get($response->details, 'escalation_target')
                        ?? data_get($response->details, 'escalation')
                );
                $attachmentUrl = filled($response->attachment_path)
                    ? Storage::disk('public')->url($response->attachment_path)
                    : null;

                return [
                    'response_id' => $response->getKey(),
                    'submission_id' => $submission->getKey(),
                    'item_key' => $response->item_key,
                    'question_number' => data_get($metadata, 'number'),
                    'question' => $question !== '' ? $question : $response->item_key,
                    'category' => trim((string) (
                        data_get($metadata, 'level')
                        ?? data_get($metadata, 'category')
                    )),
                    'area' => $area !== '' ? $area : 'General',
                    'subject' => trim((string) data_get($metadata, 'subject')),
                    'person_accountable' => trim((string) (
                        data_get($metadata, 'person_accountable')
                        ?? data_get($metadata, 'pic')
                    )),
                    'checker_role' => trim((string) data_get($metadata, 'checker')) ?: $checkedByRole,
                    'checked_by_name' => $checkedByName,
                    'checked_by_role' => $checkedByRole,
                    'checked_at' => $checkedAt,
                    'finding' => $finding,
                    'bom_task' => trim((string) data_get($metadata, 'bom_task')),
                    'action_plan' => $actionPlan,
                    'attachment_url' => $attachmentUrl,
                    'recommended_escalation' => trim((string) data_get($metadata, 'escalation')),
                    'escalation_target' => $currentEscalation,
                    'escalation_target_label' => $response->escalationTargetLabel(),
                    'commitment_date' => $response->commitment_date
                        ?->copy()
                        ->timezone(config('gac.report_timezone', 'Asia/Manila'))
                        ->format('d M Y, h:i A'),
                    'commitment_date_input' => $response->commitment_date
                        ?->copy()
                        ->timezone(config('gac.report_timezone', 'Asia/Manila'))
                        ->format('Y-m-d'),
                ];
            })
            ->values();
    }

    /**
     * Format a date strictly to month-to-month period (e.g. "September to October").
     */
    public function formatAuditMonthPeriod(\DateTimeInterface|string|null $date, bool $withYear = false): string
    {
        if (! $date) {
            $date = now();
        } elseif (is_string($date)) {
            $date = Carbon::parse($date);
        }

        $month = (int) $date->format('n');
        $year = $date->format('Y');

        // Bi-monthly cycle: 1-2 (January to February), 3-4 (March to April),
        // 5-6 (May to June), 7-8 (July to August), 9-10 (September to October), 11-12 (November to December)
        $startMonth = ($month % 2 === 1) ? $month : $month - 1;
        $endMonth = $startMonth + 1;

        $startName = Carbon::create(null, $startMonth, 1)->format('F');
        $endName = Carbon::create(null, $endMonth, 1)->format('F');

        $period = "{$startName} to {$endName}";

        return $withYear ? "{$period} {$year}" : $period;
    }
}
