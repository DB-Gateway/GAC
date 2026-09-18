<?php

namespace App\Http\Controllers;

use App\Models\ChecklistItem;
use App\Models\ChecklistResponse;
use App\Models\ChecklistSection;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\Report;
use App\Models\User;
use App\Notifications\ChecklistDraftReminder;
use App\Notifications\FindingFollowUpRequested;
use App\Notifications\PicTaskCompleted;
use App\Services\AftersalesSubformDocService;
use App\Services\TaskCompletionNotifier;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class ChecklistController extends Controller
{
    private const ESCALATION_TARGETS = [
        'general_manager',
        'purchasing',
        'property_management',
        'inventory',
    ];

    private const CHECKLIST_WORKSPACE = [
        'dealer-operations-standards' => [
            'label' => 'Dealer Operations', 'title' => 'Dealer Operations Standards',
            'subtitle' => 'Aftersales standards and audit controls',
            'eyebrow' => 'Gateway dealer operations compliance audit',
            'stylesheet' => 'css/DOS-des.css', 'body_class' => 'gateway-page-dos',
            'variant' => 'dos', 'icon' => 'fa-clipboard-check',
        ],
        'dealer-operations-standards-sales' => [
            'label' => 'Sales Standards', 'title' => 'Dealer Operations Standards - Sales',
            'subtitle' => 'Showroom and sales compliance audit',
            'eyebrow' => 'Gateway sales operations compliance audit',
            'stylesheet' => 'css/DOS-des.css', 'body_class' => 'gateway-page-dos',
            'variant' => 'dos', 'icon' => 'fa-clipboard-check',
        ],
        'sales' => [
            'label' => 'Sales', 'title' => 'Sales Checklist',
            'subtitle' => 'Daily showroom and sales readiness',
            'eyebrow' => 'Gateway sales compliance checklist',
            'stylesheet' => 'css/5S-des.css', 'body_class' => 'gateway-page-5s',
            'variant' => 'standard', 'icon' => 'fa-car-side',
        ],
        'service' => [
            'label' => 'Service', 'title' => 'Service Checklist',
            'subtitle' => 'Daily reception and workshop readiness',
            'eyebrow' => 'Gateway service compliance checklist',
            'stylesheet' => 'css/5S-des.css', 'body_class' => 'gateway-page-5s',
            'variant' => 'standard', 'icon' => 'fa-screwdriver-wrench',
        ],
        'restroom' => [
            'label' => 'Restroom', 'title' => 'Restroom Checklist',
            'subtitle' => 'Daily restroom cleanliness monitoring',
            'eyebrow' => 'Gateway restroom compliance checklist',
            'stylesheet' => 'css/5S-des.css', 'body_class' => 'gateway-page-5s gateway-page-restroom',
            'variant' => 'restroom', 'icon' => 'fa-restroom',
        ],
        'dealer-operations-standards-subform' => [
            'label' => 'DOS Subform', 'title' => 'Dealer Operations Standards - Subform',
            'subtitle' => 'Facilities, Reception, Lounge, and MQS sub-requirements (39 standards)',
            'eyebrow' => 'Gateway dealer operations subform audit',
            'stylesheet' => 'css/DOS-des.css', 'body_class' => 'gateway-page-dos',
            'variant' => 'dos', 'icon' => 'fa-layer-group',
        ],
        'dealer-operations-standards-documentation' => [
            'label' => 'DOS Documentation', 'title' => 'Dealer Operations Standards - Documentation',
            'subtitle' => 'Repair order and service documentation audit (17 standards)',
            'eyebrow' => 'Gateway dealer operations documentation audit',
            'stylesheet' => 'css/DOS-des.css', 'body_class' => 'gateway-page-dos',
            'variant' => 'dos', 'icon' => 'fa-file-lines',
        ],
    ];

    public function index(Request $request): View
    {
        $availableWorkspace = collect(self::CHECKLIST_WORKSPACE)
            ->filter(fn (array $option, string $slug): bool => $request->user()->canAccessChecklist($slug));
        abort_if(
            $availableWorkspace->isEmpty(),
            403,
            'This PIC account does not have a checklist assignment.'
        );

        $selected = (string) $request->query('checklist', $availableWorkspace->keys()->first());
        $selected = match ($selected) {
            'dealer-operations', 'dos', 'dealer-operations-standards-aftersales', 'aftersales' => 'dealer-operations-standards',
            'gateway-5s', '5s' => 'sales',
            'utilities' => 'restroom',
            'dos-subform', 'subform' => 'dealer-operations-standards-subform',
            'dos-documentation', 'documentation' => 'dealer-operations-standards-documentation',
            default => $selected,
        };

        Validator::make(['checklist' => $selected], [
            'checklist' => ['required', Rule::in(array_keys(self::CHECKLIST_WORKSPACE))],
        ])->validate();
        abort_unless(
            $request->user()->canAccessChecklist($selected),
            403,
            'This checklist is not assigned to your PIC account.'
        );

        $preserved = Arr::only($request->query(), ['branch', 'date']);
        $workspace = $availableWorkspace->map(function (array $option, string $slug) use ($selected, $preserved): array {
            return $option + [
                'slug' => $slug,
                'selected' => $slug === $selected,
                'url' => route('checklists.index', array_merge($preserved, ['checklist' => $slug])),
            ];
        })->values()->all();

        return $this->renderPage($request, $selected, 'checklists.index', [
            'checklistPage' => self::CHECKLIST_WORKSPACE[$selected],
            'checklistWorkspace' => $workspace,
        ]);
    }

    public function fiveS(Request $request): RedirectResponse
    {
        return redirect()->route('checklists.index', $this->legacyRedirectParameters($request, 'sales'));
    }

    public function dealerOperations(Request $request): RedirectResponse
    {
        return redirect()->route('checklists.index', $this->legacyRedirectParameters($request, 'dealer-operations-standards'));
    }

    public function restroom(Request $request): RedirectResponse
    {
        return redirect()->route('checklists.index', $this->legacyRedirectParameters($request, 'restroom'));
    }

    public function subform(Request $request): RedirectResponse
    {
        return redirect()->route('checklists.index', $this->legacyRedirectParameters($request, 'dealer-operations-standards-subform'));
    }

    public function documentation(Request $request): RedirectResponse
    {
        return redirect()->route('checklists.index', $this->legacyRedirectParameters($request, 'dealer-operations-standards-documentation'));
    }

    public function load(Request $request, ChecklistTemplate $template): JsonResponse
    {
        abort_unless($template->is_active, 404);
        $this->authorizeChecklist($request, $template);

        $query = Validator::make([
            'date' => $request->query('date', $request->query('checklist_date', now()->toDateString())),
            'branch' => $request->query('branch', $request->query('branch_id')),
        ], [
            'date' => ['required', 'date_format:Y-m-d'],
            'branch' => ['nullable', 'string', 'max:255'],
        ])->validate();

        $branch = $this->resolveBranch($request, $query);
        $this->authorizeBranch($request, $branch);
        $this->loadTemplate($template, $request->user());
        $submission = $this->latestSubmission(
            $template,
            $query['date'],
            $this->scopeKey($branch),
            $request->user()?->id
        );

        return response()->json([
            'template' => $this->templateResource($template),
            'submission' => $submission ? $this->submissionResource($submission, $template) : null,
        ]);
    }

    public function saveDraft(Request $request, ChecklistTemplate $template): JsonResponse
    {
        abort_unless($template->is_active, 404);
        $this->authorizeChecklist($request, $template);

        $data = $this->validatedAuditPayload($request, $template);
        $branch = $this->resolveBranch($request, $data);
        $this->authorizeBranch($request, $branch);
        $this->loadTemplate($template, $request->user());

        $created = false;
        $submission = DB::transaction(function () use (
            $request,
            $template,
            $data,
            $branch,
            &$created
        ): ChecklistSubmission {
            $scopeKey = $this->scopeKey($branch);
            $submission = $this->draftQuery(
                $template,
                $data['date'],
                $scopeKey,
                $request->user()?->id
            )
                ->lockForUpdate()
                ->latest('id')
                ->first();

            if (! $submission) {
                $isHourly = ($template->settings['validation_mode'] ?? null) === 'time_slots'
                    || in_array($template->slug, ['restroom', 'utilities'], true);
                $isDocumentation = ($template->settings['validation_mode'] ?? null) === 'dos_documentation'
                    || in_array($template->slug, ['dealer-operations-standards-documentation', 'dos-documentation', 'documentation'], true);

                if ($isHourly || $isDocumentation) {
                    $existing = ChecklistSubmission::query()
                        ->where('checklist_template_id', $template->id)
                        ->whereDate('audit_date', $data['date'])
                        ->where('scope_key', $scopeKey)
                        ->where('user_id', $request->user()?->id)
                        ->lockForUpdate()
                        ->latest('id')
                        ->first();

                    if ($existing) {
                        $submission = $existing;
                    }
                }

                if (! $submission) {
                    $created = true;
                    $submission = new ChecklistSubmission;
                    $submission->checklist_template_id = $template->id;
                    $submission->status = 'draft';
                    $submission->scope_key = $scopeKey;
                    $submission->audit_date = $data['date'];
                }
            }

            $submission->fill([
                'user_id' => $request->user()?->id,
                'branch' => $branch,
                'template_version' => $template->version,
                'context' => $data['context'] ?? null,
                'template_snapshot' => $this->templateResource($template),
                'scores' => null,
                'submitted_by_user_id' => null,
                'submitted_by_name' => null,
                'submitted_by_email' => null,
                'submitted_by_user_type' => null,
                'submitted_at' => null,
            ]);
            $submission->save();

            // Draft requests may contain only the category currently open in
            // the mobile app. Merge those rows so saving one category cannot
            // delete answers already stored for another category.
            $responses = $this->syncResponses(
                $submission,
                $template,
                $data['responses'],
                replaceMissing: false
            );
            $submission->update([
                'scores' => $this->calculateScores($template, $responses),
            ]);

            // A merged draft can become empty when the mobile user undoes
            // the last saved answer. Check all rows, including other categories.
            if ($submission->status === 'draft'
                && ! $responses->contains(fn (ChecklistResponse $response): bool => $this->responseHasDraftContent($response))) {
                $submission->responses()->delete();
                $submission->delete();
                $submission->status = 'not_started';
                $submission->context = null;
                $submission->scores = $this->calculateScores($template, collect());
                $submission->setRelation('responses', collect());

                return $submission;
            }

            return $submission->fresh('responses');
        });

        return response()->json([
            'message' => $submission->exists ? 'Checklist draft saved.' : 'Checklist reset.',
            'submission' => $this->submissionResource($submission, $template),
        ], $created && $submission->exists ? 201 : 200);
    }

    private function responseHasDraftContent(ChecklistResponse $response): bool
    {
        $hasValue = static fn ($value): bool => is_string($value)
            && trim($value) !== '' && Str::lower(trim($value)) !== 'unanswered';
        if ($hasValue($response->status)) {
            return true;
        }
        foreach (['remark', 'finding', 'action_plan', 'commitment_date', 'escalation_target', 'attachment_path'] as $field) {
            if (filled($response->{$field})) {
                return true;
            }
        }
        $details = $response->details ?? [];
        foreach (['slots', 'subform_answers', 'submitted_slots'] as $field) {
            if (collect($details[$field] ?? [])->contains($hasValue)) {
                return true;
            }
        }
        if ($hasValue($details['eligibility'] ?? null)) {
            return true;
        }

        return collect($details['customers'] ?? [])->contains(fn ($customer): bool =>
            filled(data_get($customer, 'ro_number'))
            || filled(data_get($customer, 'mileage'))
            || collect(data_get($customer, 'answers', []))->contains($hasValue));
    }

    public function submit(
        Request $request,
        ChecklistTemplate $template,
        TaskCompletionNotifier $taskCompletionNotifier
    ): JsonResponse {
        abort_unless($template->is_active, 404);
        $this->authorizeChecklist($request, $template);

        $data = $this->validatedAuditPayload($request, $template);
        $branch = $this->resolveBranch($request, $data);
        $this->authorizeBranch($request, $branch);
        $this->loadTemplate($template, $request->user());

        [$submission, $report, $alreadySubmitted] = DB::transaction(function () use (
            $request,
            $template,
            $data,
            $branch,
            $taskCompletionNotifier
        ): array {
            $lockedTemplate = ChecklistTemplate::query()
                ->whereKey($template->id)
                ->lockForUpdate()
                ->firstOrFail();
            $this->loadTemplate($lockedTemplate, $request->user());

            $scopeKey = $this->scopeKey($branch);
            $submitter = $request->user();
            $submission = $this->draftQuery(
                $lockedTemplate,
                $data['date'],
                $scopeKey,
                $submitter?->id
            )
                ->lockForUpdate()
                ->latest('id')
                ->first();

            if (! $submission) {
                $existing = ChecklistSubmission::query()
                    ->where('checklist_template_id', $lockedTemplate->id)
                    ->whereDate('audit_date', $data['date'])
                    ->where('scope_key', $scopeKey)
                    ->where('user_id', $submitter?->id)
                    ->where('status', 'submitted')
                    ->with('responses')
                    ->latest('submitted_at')
                    ->latest('id')
                    ->first();

                if ($existing && $this->submissionMatchesPayload(
                    $existing,
                    $lockedTemplate,
                    $data['responses'],
                    $data['context'] ?? null
                )) {
                    $report = $existing->reports()
                        ->where('type', 'checklist_submission')
                        ->oldest('id')
                        ->first();

                    return [$existing, $report, true];
                }

                $isHourly = ($lockedTemplate->settings['validation_mode'] ?? null) === 'time_slots'
                    || in_array($lockedTemplate->slug, ['restroom', 'utilities'], true);
                $isDocumentation = ($lockedTemplate->settings['validation_mode'] ?? null) === 'dos_documentation'
                    || in_array($lockedTemplate->slug, ['dealer-operations-standards-documentation', 'dos-documentation', 'documentation'], true);

                if ($existing && ($isHourly || $isDocumentation)) {
                    $submission = $existing;
                } else {
                    $submission = new ChecklistSubmission([
                        'checklist_template_id' => $lockedTemplate->id,
                        'status' => 'draft',
                        'scope_key' => $scopeKey,
                        'audit_date' => $data['date'],
                    ]);
                }
            }

            $submission->fill([
                'user_id' => $request->user()?->id,
                'branch' => $branch,
                'template_version' => $lockedTemplate->version,
                'context' => $data['context'] ?? null,
                'template_snapshot' => $this->templateResource($lockedTemplate),
            ]);
            $submission->save();

            $responses = $this->syncResponses($submission, $lockedTemplate, $data['responses']);
            $clientTime = $request->header('X-Client-Time')
                ?? data_get($data, 'client_time')
                ?? data_get($data, 'context.client_time')
                ?? data_get($data, 'responses.0.details.client_time');
            $this->validateCompleteSubmission($lockedTemplate, $responses, $submission, $clientTime);
            $scores = $this->calculateScores($lockedTemplate, $responses);

            $submission->update([
                'status' => 'submitted',
                'scores' => $scores,
                'submitted_by_user_id' => $submitter?->id,
                'submitted_by_name' => $submitter?->name,
                'submitted_by_email' => $submitter?->email,
                'submitted_by_user_type' => $submitter?->roleCode(),
                'submitted_at' => now(),
            ]);
            $submission->load('responses');

            $snapshot = $this->submissionResource($submission, $lockedTemplate);
            $report = Report::updateOrCreate(
                [
                    'checklist_submission_id' => $submission->id,
                    'type' => 'checklist_submission',
                ],
                [
                    'checklist_template_id' => $lockedTemplate->id,
                    'generated_by_user_id' => $request->user()?->id,
                    'title' => Str::limit(implode(' - ', array_filter([
                        $lockedTemplate->name,
                        $branch,
                        $data['date'],
                    ])), 255, ''),
                    'status' => 'ready',
                    'filters' => [
                        'template' => $lockedTemplate->slug,
                        'branch' => $branch,
                        'date' => $data['date'],
                    ],
                    'data_snapshot' => [
                        'template' => $submission->template_snapshot,
                        'submission' => $snapshot,
                    ],
                    'generated_at' => now(),
                ]
            );

            if ($submitter !== null) {
                $taskCompletionNotifier->send($submission, $submitter);
            }

            return [$submission, $report, false];
        });

        return response()->json([
            'message' => $alreadySubmitted
                ? 'This checklist was already submitted.'
                : 'Checklist submitted.',
            'submission' => $this->submissionResource($submission, $template),
            'report_id' => $report?->id,
        ], $alreadySubmitted ? 200 : 201);
    }

    public function reset(Request $request, ChecklistTemplate $template): JsonResponse
    {
        abort_unless($template->is_active, 404);
        $this->authorizeChecklist($request, $template);

        $data = Validator::make([
            'date' => $request->input('date', $request->input('checklist_date')),
            'branch' => $request->input('branch', $request->input('branch_id')),
            'context' => $request->input('context'),
        ], [
            'date' => ['required', 'date_format:Y-m-d'],
            'branch' => ['nullable', 'string', 'max:255'],
            'context' => ['nullable', 'array'],
        ])->validate();

        $branch = $this->resolveBranch($request, $data);
        $this->authorizeBranch($request, $branch);
        $includeSubmitted = $request->boolean('include_submitted', false) || $request->boolean('reset_all', false);

        $deletedDrafts = DB::transaction(function () use ($request, $template, $data, $branch, $includeSubmitted): int {
            ChecklistTemplate::query()
                ->whereKey($template->id)
                ->lockForUpdate()
                ->firstOrFail();

            $scopeKey = $this->scopeKey($branch);

            if ($includeSubmitted) {
                $query = ChecklistSubmission::query()
                    ->where('checklist_template_id', $template->id)
                    ->whereDate('audit_date', $data['date'])
                    ->where('scope_key', $scopeKey);

                if (! $request->user()?->hasAdministrativeAccess()) {
                    $query->where('user_id', $request->user()?->id);
                }

                $submissions = $query->lockForUpdate()->get();
                $count = $submissions->count();

                foreach ($submissions as $submission) {
                    $submission->reports()->delete();
                    $submission->responses()->delete();
                    $submission->delete();
                }

                return $count;
            }

            $drafts = $this->draftQuery(
                $template,
                $data['date'],
                $scopeKey,
                $request->user()?->id
            )
                ->lockForUpdate()
                ->get();

            foreach ($drafts as $draft) {
                $draft->delete();
            }

            return $drafts->count();
        });

        return response()->json([
            'message' => $deletedDrafts
                ? 'Checklist draft deleted. Submitted history was retained.'
                : 'No checklist draft existed. Submitted history was retained.',
            'submission' => null,
            'deleted_drafts' => $deletedDrafts,
        ]);
    }

    public function debugResetAnswers(Request $request): JsonResponse
    {
        $validated = Validator::make($request->all(), [
            'template' => ['nullable', 'string'],
            'date' => ['nullable', 'string'],
            'branch' => ['nullable', 'string', 'max:255'],
            'scope' => ['nullable', 'string', Rule::in(['all', 'current', 'template_all'])],
            'target' => ['nullable', 'string', Rule::in(['all', 'drafts', 'submitted', 'notifications', 'subforms', 'documentation', 'subform_doc'])],
            'include_notifications' => ['nullable', 'boolean'],
        ])->validate();

        $templateInput = trim((string) ($validated['template'] ?? 'all'));
        if ($templateInput === '') {
            $templateInput = 'all';
        }

        $targetTemplates = collect();
        if ($templateInput !== 'all') {
            $matched = ChecklistTemplate::where('slug', $templateInput)->first();
            if (! $matched) {
                $alias = match ($templateInput) {
                    'dealer-operations', 'dos', 'dealer-operations-standards-aftersales', 'aftersales' => 'dealer-operations-standards',
                    'subform', 'dos-subform', 'aftersales-subform', 'subforms' => 'dealer-operations-standards-subform',
                    'documentation', 'doc', 'dos-documentation', 'dos-doc', 'aftersales-documentation' => 'dealer-operations-standards-documentation',
                    '5s' => 'sales',
                    'utilities' => 'restroom',
                    default => $templateInput,
                };
                $matched = ChecklistTemplate::where('slug', $alias)->first();
            }

            if (! $matched) {
                return response()->json([
                    'message' => "Checklist template '{$templateInput}' was not found.",
                ], 404);
            }

            if ($matched->slug === 'dealer-operations-standards') {
                $targetTemplates = ChecklistTemplate::whereIn('slug', [
                    'dealer-operations-standards',
                    'dealer-operations-standards-subform',
                    'dealer-operations-standards-documentation',
                ])->get();
            } else {
                $targetTemplates = collect([$matched]);
            }
        } else {
            $targetTemplates = ChecklistTemplate::all();
        }

        $date = trim((string) ($validated['date'] ?? ''));
        $branch = trim((string) ($validated['branch'] ?? ''));
        $scope = trim((string) ($validated['scope'] ?? 'all'));
        $target = trim((string) ($validated['target'] ?? 'all'));
        if (! in_array($target, ['all', 'drafts', 'submitted', 'notifications', 'subforms', 'documentation', 'subform_doc'], true)) {
            $target = 'all';
        }
        $includeNotifications = $request->has('include_notifications')
            ? $request->boolean('include_notifications')
            : true;

        $templateIds = $targetTemplates->pluck('id')->all();

        $stats = DB::transaction(function () use ($templateIds, $targetTemplates, $templateInput, $date, $branch, $scope, $target, $includeNotifications): array {
            $submissionQuery = ChecklistSubmission::query();

            if ($target === 'subforms') {
                $subformTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards-subform')->first();
                $subformTemplateId = $subformTemplate?->id;

                if ($subformTemplateId) {
                    $submissionQuery->where('checklist_template_id', $subformTemplateId);
                } else {
                    $submissionQuery->whereRaw('0 = 1');
                }
            } elseif ($target === 'documentation') {
                $docTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards-documentation')->first();
                $docTemplateId = $docTemplate?->id;

                if ($docTemplateId) {
                    $submissionQuery->where('checklist_template_id', $docTemplateId);
                } else {
                    $submissionQuery->whereRaw('0 = 1');
                }
            } elseif ($target === 'subform_doc') {
                $sdTemplates = ChecklistTemplate::whereIn('slug', [
                    'dealer-operations-standards-subform',
                    'dealer-operations-standards-documentation',
                ])->pluck('id')->all();

                if (! empty($sdTemplates)) {
                    $submissionQuery->whereIn('checklist_template_id', $sdTemplates);
                } else {
                    $submissionQuery->whereRaw('0 = 1');
                }
            } else {
                if ($templateInput !== 'all') {
                    $submissionQuery->whereIn('checklist_template_id', $templateIds);
                }

                if ($target === 'drafts') {
                    $submissionQuery->where('status', 'draft');
                } elseif ($target === 'submitted') {
                    $submissionQuery->where('status', 'submitted');
                }
            }

            if ($scope === 'current') {
                if ($date !== '' && $date !== 'all') {
                    $submissionQuery->whereDate('audit_date', $date);
                }
                if ($branch !== '' && $branch !== 'all') {
                    $scopeKey = hash('sha256', Str::lower($branch));
                    $submissionQuery->where(function ($q) use ($branch, $scopeKey) {
                        $q->where('branch', $branch)
                            ->orWhere('scope_key', $scopeKey);
                    });
                }
            } elseif ($date !== '' && $date !== 'all') {
                $submissionQuery->whereDate('audit_date', $date);
            }

            $submissions = $submissionQuery->lockForUpdate()->get();
            $submissionIds = $submissions->pluck('id')->all();

            $deletedDraftsCount = $target === 'notifications'
                ? 0
                : $submissions->where('status', 'draft')->count();
            $deletedSubmittedCount = $target === 'notifications'
                ? 0
                : $submissions->where('status', 'submitted')->count();
            $deletedResponsesCount = 0;
            $deletedSubmissionsCount = 0;
            $deletedReportsCount = 0;
            $deletedNotificationsCount = 0;
            $clearedSubformsCount = 0;
            $clearedDocsCount = 0;

            if (count($submissionIds) > 0) {
                if ($deletedDraftsCount > 0) {
                    try {
                        DB::table('notifications')
                            ->where('type', ChecklistDraftReminder::class)
                            ->whereIn('data->submission_id', $submissionIds)
                            ->delete();
                    } catch (\Throwable) {
                        // Safe fallback if notifications table does not support json path query or isn't present
                    }
                }

                if ($target !== 'notifications') {
                    $deletedResponsesCount = ChecklistResponse::query()
                        ->whereIn('checklist_submission_id', $submissionIds)
                        ->delete();

                    $deletedReportsCount = Report::query()
                        ->whereIn('checklist_submission_id', $submissionIds)
                        ->delete();

                    $deletedSubmissionsCount = ChecklistSubmission::query()
                        ->whereIn('id', $submissionIds)
                        ->delete();
                }
            }

            // Clear embedded subforms from DOS when targeting subforms, subform_doc, or subform template
            if (in_array($target, ['subforms', 'subform_doc'], true) || $templateInput === 'dealer-operations-standards-subform') {
                $clearedSubformsCount = $this->clearEmbeddedDosSubforms($branch, $date, $scope);
            }

            // Clear embedded documentation from DOS when targeting documentation, subform_doc, or documentation template
            if (in_array($target, ['documentation', 'subform_doc'], true) || $templateInput === 'dealer-operations-standards-documentation') {
                $clearedDocsCount = $this->clearEmbeddedDosDocumentation($branch, $date, $scope);
            }

            if ($includeNotifications || $target === 'notifications') {
                $notificationTypes = match ($target) {
                    'drafts' => [ChecklistDraftReminder::class],
                    'submitted' => [PicTaskCompleted::class, FindingFollowUpRequested::class],
                    default => [
                        PicTaskCompleted::class,
                        FindingFollowUpRequested::class,
                        ChecklistDraftReminder::class,
                    ],
                };

                try {
                    $allIdVariants = array_values(array_unique([
                        ...$submissionIds,
                        ...array_map('strval', $submissionIds),
                        ...array_map('intval', $submissionIds),
                    ]));

                    $targetSlugs = $targetTemplates->pluck('slug')->filter()->all();
                    $notifQuery = DB::table('notifications')->whereIn('type', $notificationTypes);

                    if ($templateInput === 'all' && $scope === 'all') {
                        $deletedNotificationsCount = $notifQuery->delete();
                    } elseif (! empty($allIdVariants)) {
                        $notifQuery->where(function ($q) use ($allIdVariants, $targetSlugs, $scope) {
                            $q->whereIn('data->submission_id', $allIdVariants);
                            if ($scope !== 'current' && ! empty($targetSlugs)) {
                                $q->orWhereIn('data->template_slug', $targetSlugs);
                            }
                        });
                        $deletedNotificationsCount = $notifQuery->delete();
                    } elseif ($scope !== 'current' && ! empty($targetSlugs)) {
                        $notifQuery->whereIn('data->template_slug', $targetSlugs);
                        $deletedNotificationsCount = $notifQuery->delete();
                    }
                } catch (\Throwable) {
                    // Safe fallback if notifications table does not support json queries
                }
            }

            $templatesCount = ChecklistTemplate::query()->count();
            $sectionsCount = ChecklistSection::query()->count();
            $itemsCount = ChecklistItem::query()->count();

            return [
                'deleted_submissions' => $deletedSubmissionsCount,
                'deleted_drafts' => $deletedDraftsCount,
                'deleted_submitted' => $deletedSubmittedCount,
                'deleted_responses' => $deletedResponsesCount,
                'deleted_reports' => $deletedReportsCount,
                'deleted_notifications' => $deletedNotificationsCount,
                'cleared_embedded_subforms' => $clearedSubformsCount,
                'cleared_embedded_documentation' => $clearedDocsCount,
                'templates_preserved' => true,
                'preserved_counts' => [
                    'templates' => $templatesCount,
                    'sections' => $sectionsCount,
                    'items' => $itemsCount,
                ],
            ];
        });

        $templateLabel = match (true) {
            $target === 'subforms' => 'Aftersales Subforms',
            $target === 'documentation' => 'Aftersales Documentation',
            $target === 'subform_doc' => 'Aftersales Subforms & Documentation',
            $templateInput === 'all' => 'All checklists',
            default => ($targetTemplates->first()?->name ?? $templateInput),
        };

        $typeLabel = match ($target) {
            'drafts' => 'drafts',
            'submitted' => 'submitted answers',
            'subforms' => 'subform submissions',
            'documentation' => 'documentation submissions',
            'subform_doc' => 'subform & documentation submissions',
            'notifications' => 'notification history',
            default => 'answers and notification history',
        };

        return response()->json([
            'message' => "Checklist {$typeLabel} for {$templateLabel} have been successfully reset. Master templates, sections, and items were safely preserved.",
            'template' => $templateInput,
            'target' => $target,
            'stats' => $stats,
        ]);
    }

    private function clearEmbeddedDosSubforms(?string $branch, ?string $date, string $scope): int
    {
        $dosTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards')->first();
        if (! $dosTemplate) {
            return 0;
        }

        $dosQuery = ChecklistSubmission::query()->where('checklist_template_id', $dosTemplate->id);
        if ($scope === 'current') {
            if ($date !== '' && $date !== null && $date !== 'all') {
                $dosQuery->whereDate('audit_date', $date);
            }
            if ($branch !== '' && $branch !== null && $branch !== 'all') {
                $scopeKey = hash('sha256', Str::lower($branch));
                $dosQuery->where(function ($q) use ($branch, $scopeKey) {
                    $q->where('branch', $branch)
                        ->orWhere('scope_key', $scopeKey);
                });
            }
        } elseif ($date !== '' && $date !== null && $date !== 'all') {
            $dosQuery->whereDate('audit_date', $date);
        }

        $dosSubmissions = $dosQuery->with(['responses.item'])->get();
        $cleared = 0;

        foreach ($dosSubmissions as $submission) {
            foreach ($submission->responses as $response) {
                $details = (array) ($response->details ?? []);
                $hasSubAnswers = array_key_exists('subform_answers', $details);
                $hasEligibility = array_key_exists('eligibility', $details);
                $itemNum = (string) ($response->item?->metadata['number'] ?? $response->item?->code ?? '');
                $isSubItem = in_array($itemNum, ['23', '27', '53', '54', '55'], true)
                    || in_array((string) $response->item_key, ['dos-as-23', 'dos-as-27', 'dos-as-53', 'dos-as-54', 'dos-as-55'], true);

                if ($hasSubAnswers || $hasEligibility || $isSubItem) {
                    unset($details['subform_answers'], $details['eligibility']);
                    $response->details = $details;
                    if ($isSubItem) {
                        $response->status = null;
                    }
                    $response->save();
                    $cleared++;
                }
            }
        }

        return $cleared;
    }

    private function clearEmbeddedDosDocumentation(?string $branch, ?string $date, string $scope): int
    {
        $dosTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards')->first();
        if (! $dosTemplate) {
            return 0;
        }

        $dosQuery = ChecklistSubmission::query()->where('checklist_template_id', $dosTemplate->id);
        if ($scope === 'current') {
            if ($date !== '' && $date !== null && $date !== 'all') {
                $dosQuery->whereDate('audit_date', $date);
            }
            if ($branch !== '' && $branch !== null && $branch !== 'all') {
                $scopeKey = hash('sha256', Str::lower($branch));
                $dosQuery->where(function ($q) use ($branch, $scopeKey) {
                    $q->where('branch', $branch)
                        ->orWhere('scope_key', $scopeKey);
                });
            }
        } elseif ($date !== '' && $date !== null && $date !== 'all') {
            $dosQuery->whereDate('audit_date', $date);
        }

        $dosSubmissions = $dosQuery->with(['responses.item'])->get();
        $cleared = 0;

        foreach ($dosSubmissions as $submission) {
            $context = (array) ($submission->context ?? []);
            if (! empty($context['documentation_samples'])) {
                unset($context['documentation_samples']);
                $submission->context = $context;
                $submission->save();
            }

            foreach ($submission->responses as $response) {
                $details = (array) ($response->details ?? []);
                $hasDocSamples = array_key_exists('documentation_samples', $details);
                $hasDocAnswers = array_key_exists('documentation_answers', $details);
                $itemNum = (string) ($response->item?->metadata['number'] ?? $response->item?->code ?? '');
                $isDocItem = $itemNum === '61'
                    || in_array((string) $response->item_key, ['dos-as-61', 'doc-61'], true)
                    || str_contains((string) $response->item_key, '61');

                if ($hasDocSamples || $hasDocAnswers || $isDocItem) {
                    unset($details['documentation_samples'], $details['documentation_answers']);
                    $response->details = $details;
                    if ($isDocItem) {
                        $response->status = null;
                    }
                    $response->save();
                    $cleared++;
                }
            }
        }

        return $cleared;
    }

    public function uploadAttachment(Request $request, ChecklistTemplate $template): JsonResponse
    {
        abort_unless($template->is_active, 404);
        $this->authorizeChecklist($request, $template);

        $request->validate([
            'photo' => ['required_without:attachment', 'nullable', 'image', 'mimes:jpeg,jpg,png,webp,heic', 'max:10240'],
            'attachment' => ['required_without:photo', 'nullable', 'image', 'mimes:jpeg,jpg,png,webp,heic', 'max:10240'],
        ]);

        $file = $request->file('photo') ?? $request->file('attachment');
        if (! $file || ! $file->isValid()) {
            return response()->json(['message' => 'A valid image file is required.'], 422);
        }

        $dateFolder = now()->format('Y-m-d');
        $path = $file->store("checklist-attachments/{$template->slug}/{$dateFolder}", 'public');

        return response()->json([
            'path' => $path,
            'url' => $this->attachmentUrl($path),
        ], 201);
    }

    public function updateTemplate(Request $request, ChecklistTemplate $template): JsonResponse
    {
        $this->ensureCanManageTemplates($request);
        $this->loadTemplate($template);
        $editorOptions = $this->templateEditorOptions($template);
        $input = $this->normalizeTemplateInput($request->all(), $template, $editorOptions);

        $validator = Validator::make($input, [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'settings' => ['sometimes', 'nullable', 'array'],
            'settings.instructions' => ['sometimes', 'nullable', 'string'],
            'settings.short_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'sections' => ['required', 'array', 'min:1'],
            'sections.*.id' => ['nullable', 'integer', Rule::exists('checklist_sections', 'id')->where('checklist_template_id', $template->id)],
            'sections.*.key' => ['required', 'string', 'max:100', 'distinct'],
            'sections.*.title' => ['required', 'string', 'max:255'],
            'sections.*.metadata' => ['nullable', 'array'],
            'sections.*.items' => ['required', 'array'],
            'sections.*.items.*.id' => ['nullable', 'integer', Rule::exists('checklist_items', 'id')->where('checklist_template_id', $template->id)],
            'sections.*.items.*.key' => ['required', 'string', 'max:100', 'distinct'],
            'sections.*.items.*.prompt' => ['required', 'string'],
            'sections.*.items.*.metadata' => ['nullable', 'array'],
            'sections.*.items.*.metadata.responsible_role' => ['required', 'string', Rule::in(array_column($editorOptions['responsible_roles'], 'value'))],
            'sections.*.items.*.metadata.level' => [$editorOptions['level_required'] ? 'required' : 'nullable', 'string', Rule::in(array_column($editorOptions['levels'], 'value'))],
            'sections.*.items.*.metadata.how_to_check' => ['sometimes', 'nullable', 'string'],
        ]);

        $validator->after(function ($validator) use ($input, $template): void {
            $sectionKeys = [];
            $itemKeys = [];
            $existingSections = $template->sections->keyBy('id');
            $existingItems = $template->sections->flatMap->items->keyBy('id');

            foreach (is_array($input['sections'] ?? null) ? $input['sections'] : [] as $sectionIndex => $section) {
                if (! is_array($section)) {
                    continue;
                }

                $existingSection = $existingSections->get($section['id'] ?? null);
                if ($existingSection && $existingSection->key !== ($section['key'] ?? null)) {
                    $validator->errors()->add("sections.$sectionIndex.key", 'An existing section key cannot be changed.');
                }

                $sectionKey = Str::lower(trim((string) ($section['key'] ?? '')));
                if ($sectionKey !== '') {
                    if (isset($sectionKeys[$sectionKey])) {
                        $validator->errors()->add(
                            "sections.$sectionIndex.key",
                            'Section keys must be unique regardless of letter case.'
                        );
                    }
                    $sectionKeys[$sectionKey] = true;
                }

                foreach (is_array($section['items'] ?? null) ? $section['items'] : [] as $itemIndex => $item) {
                    if (! is_array($item)) {
                        continue;
                    }

                    $existingItem = $existingItems->get($item['id'] ?? null);
                    if ($existingItem && $existingItem->key !== ($item['key'] ?? null)) {
                        $validator->errors()->add("sections.$sectionIndex.items.$itemIndex.key", 'An existing question key cannot be changed.');
                    }

                    $itemKey = Str::lower(trim((string) ($item['key'] ?? '')));
                    if ($itemKey === '') {
                        continue;
                    }
                    if (isset($itemKeys[$itemKey])) {
                        $validator->errors()->add(
                            "sections.$sectionIndex.items.$itemIndex.key",
                            'Item keys must be unique across the template regardless of letter case.'
                        );
                    }
                    $itemKeys[$itemKey] = true;
                }
            }
        });

        $validator->validate();
        // These JSON bags also contain checklist-specific fields (checker,
        // scoring, time slots, etc.) without individual validation rules.
        $data = Arr::only($input, ['name', 'description', 'settings', 'sections']);

        $template = DB::transaction(function () use ($template, $data): ChecklistTemplate {
            $template = ChecklistTemplate::query()->lockForUpdate()->findOrFail($template->id);
            $template->fill(Arr::only($data, ['name', 'description', 'settings']));
            $template->version++;
            $template->save();

            $keptSectionIds = [];
            $keptItemIds = [];
            $questionNumber = 0;

            foreach (array_values($data['sections']) as $sectionOrder => $sectionData) {
                $section = ChecklistSection::query()->updateOrCreate([
                    'checklist_template_id' => $template->id,
                    'key' => $sectionData['key'],
                ], [
                    'title' => trim($sectionData['title']),
                    'sort_order' => $sectionOrder,
                    'metadata' => $sectionData['metadata'] ?? null,
                    'is_active' => true,
                ]);
                $keptSectionIds[] = $section->id;

                foreach (array_values($sectionData['items']) as $itemOrder => $itemData) {
                    $questionNumber++;
                    $metadata = $itemData['metadata'] ?? [];
                    unset($metadata['deleted']);
                    $metadata['number'] = $questionNumber;
                    $metadata['code'] = (string) $questionNumber;
                    $isActive = array_key_exists('is_active', $itemData) ? (bool) $itemData['is_active'] : true;
                    $item = ChecklistItem::query()->updateOrCreate([
                        'checklist_template_id' => $template->id,
                        'key' => $itemData['key'],
                    ], [
                        'checklist_section_id' => $section->id,
                        'prompt' => trim($itemData['prompt']),
                        'sort_order' => $itemOrder,
                        'metadata' => $metadata,
                        'is_active' => $isActive,
                    ]);
                    $keptItemIds[] = $item->id;
                }
            }

            $template->items()->whereNotIn('id', $keptItemIds)->each(function (ChecklistItem $item): void {
                $metadata = $item->metadata ?? [];
                $metadata['deleted'] = true;
                $item->update([
                    'is_active' => false,
                    'metadata' => $metadata,
                ]);
            });
            $template->sections()->whereNotIn('id', $keptSectionIds)->update(['is_active' => false]);

            return $this->loadTemplate($template->fresh());
        });

        return response()->json([
            'message' => 'Checklist template updated.',
            'template' => $this->templateResource($template),
        ]);
    }

    public function toggleItem(Request $request, ChecklistTemplate $template): JsonResponse
    {
        $this->ensureCanManageTemplates($request);

        $validated = $request->validate([
            'key' => ['required', 'string'],
            'is_active' => ['required', 'boolean'],
            'slot' => ['nullable', 'string'],
        ]);

        $item = $template->items()
            ->where('key', $validated['key'])
            ->firstOrFail();

        $metadata = $item->metadata ?? [];
        unset($metadata['deleted']);

        $slot = $validated['slot'] ?? null;
        if ($slot !== null && $slot !== '') {
            $allSlots = $this->timeSlotKeys($template);
            $activeSlots = $metadata['active_slots'] ?? $allSlots;
            if (! is_array($activeSlots)) {
                $activeSlots = $allSlots;
            }

            if ($validated['is_active']) {
                if (! in_array($slot, $activeSlots, true)) {
                    $activeSlots[] = $slot;
                }
            } else {
                $activeSlots = array_values(array_filter($activeSlots, fn ($s) => $s !== $slot));
            }

            $metadata['active_slots'] = array_values($activeSlots);
            $itemActive = count($activeSlots) > 0;

            $item->update([
                'is_active' => $itemActive,
                'metadata' => $metadata,
            ]);

            return response()->json([
                'message' => $validated['is_active']
                    ? "Question enabled for {$slot}."
                    : "Question turned off for {$slot}.",
                'item' => [
                    'id' => $item->id,
                    'key' => $item->key,
                    'is_active' => (bool) $item->is_active,
                    'active_slots' => $metadata['active_slots'],
                ],
            ]);
        }

        $item->update([
            'is_active' => $validated['is_active'],
            'metadata' => $metadata,
        ]);

        return response()->json([
            'message' => $validated['is_active']
                ? 'Question is now included in the checklist.'
                : 'Question has been excluded from the checklist.',
            'item' => [
                'id' => $item->id,
                'key' => $item->key,
                'is_active' => (bool) $item->is_active,
                'active_slots' => $metadata['active_slots'] ?? null,
            ],
        ]);
    }

    public function storeTemplate(Request $request): JsonResponse
    {
        $this->ensureCanManageTemplates($request);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'slug' => ['required', 'string', 'max:100', 'unique:checklist_templates,slug'],
            'description' => ['nullable', 'string'],
            'variant' => ['nullable', 'string', Rule::in(['dos', 'standard', 'restroom'])],
            'clone_from_slug' => ['nullable', 'string', Rule::exists('checklist_templates', 'slug')],
            'instructions' => ['nullable', 'string'],
        ]);

        $baseTemplate = ! empty($validated['clone_from_slug'])
            ? ChecklistTemplate::where('slug', $validated['clone_from_slug'])->with(['sections.items'])->first()
            : null;

        $newTemplate = DB::transaction(function () use ($validated, $baseTemplate): ChecklistTemplate {
            $settings = $baseTemplate ? ($baseTemplate->settings ?? []) : [];
            if (! empty($validated['instructions'])) {
                $settings['instructions'] = $validated['instructions'];
            }
            if ($validated['variant'] ?? null) {
                $settings['validation_mode'] = match ($validated['variant']) {
                    'dos' => 'dos',
                    'restroom' => 'time_slots',
                    default => 'standard',
                };
            }

            $template = ChecklistTemplate::create([
                'name' => trim($validated['name']),
                'slug' => Str::slug($validated['slug']),
                'description' => $validated['description'] ?? ($baseTemplate?->description ?? ''),
                'version' => 1,
                'is_active' => true,
                'settings' => $settings,
            ]);

            if ($baseTemplate) {
                foreach ($baseTemplate->sections as $sec) {
                    $newSec = ChecklistSection::create([
                        'checklist_template_id' => $template->id,
                        'key' => Str::slug($sec->key . '-' . $template->id),
                        'title' => $sec->title,
                        'sort_order' => $sec->sort_order,
                        'metadata' => $sec->metadata,
                        'is_active' => true,
                    ]);
                    foreach ($sec->items as $item) {
                        ChecklistItem::create([
                            'checklist_template_id' => $template->id,
                            'checklist_section_id' => $newSec->id,
                            'key' => Str::slug($item->key . '-' . $template->id),
                            'prompt' => $item->prompt,
                            'sort_order' => $item->sort_order,
                            'metadata' => $item->metadata,
                            'is_active' => $item->is_active,
                        ]);
                    }
                }
            } else {
                $defaultSec = ChecklistSection::create([
                    'checklist_template_id' => $template->id,
                    'key' => 'general-section',
                    'title' => 'General Standards',
                    'sort_order' => 0,
                    'is_active' => true,
                ]);
                ChecklistItem::create([
                    'checklist_template_id' => $template->id,
                    'checklist_section_id' => $defaultSec->id,
                    'key' => 'item-1',
                    'prompt' => 'New checklist standard',
                    'sort_order' => 0,
                    'is_active' => true,
                    'metadata' => [
                        'code' => '1',
                        'number' => 1,
                        'responsible_role' => ($template->settings['validation_mode'] ?? '') === 'dos' ? 'ASM' : User::ROLE_PERSON_IN_CHARGE,
                        'level' => 'Standard',
                    ],
                ]);
            }

            return $template;
        });

        return response()->json([
            'message' => 'Checklist template created successfully.',
            'template' => $this->templateResource($this->loadTemplate($newTemplate)),
            'redirect_url' => route('checklists.index', ['checklist' => $newTemplate->slug]),
        ], 201);
    }

    private function renderPage(Request $request, string $slug, string $view, array $viewData = []): View
    {
        $template = ChecklistTemplate::query()
            ->where('slug', $slug)
            ->where('is_active', true)
            ->firstOrFail();
        $this->authorizeChecklist($request, $template);
        $this->loadTemplate($template, $request->user());

        $date = $request->query('date', now()->toDateString());
        Validator::make(['date' => $date], [
            'date' => ['required', 'date_format:Y-m-d'],
        ])->validate();
        $branch = $this->resolveBranch($request, [
            'branch' => $request->query('branch'),
        ]);
        $this->authorizeBranch($request, $branch);
        $submission = $this->latestSubmission(
            $template,
            $date,
            $this->scopeKey($branch),
            $request->user()?->id
        );

        $templateData = $this->templateResource($template);
        $submissionData = $submission ? $this->submissionResource($submission, $template) : null;
        $canManageTemplate = $this->hasAdministrativeAccess($request);
        $branches = ($canManageTemplate
            ? User::query()
                ->whereNotNull('branch')
                ->where('branch', '<>', '')
                ->distinct()
                ->orderBy('branch')
                ->pluck('branch')
                ->merge(config('gac.branches', []))
                ->push($branch)
            : collect([$branch]))
            ->filter(fn ($value) => is_string($value) && trim($value) !== '')
            ->unique(fn (string $value) => Str::lower(trim($value)))
            ->values()
            ->all();

        $subformTemplate = ChecklistTemplate::query()
            ->where('slug', 'dealer-operations-standards-subform')
            ->where('is_active', true)
            ->first();
        $subformTemplateData = $subformTemplate ? $this->templateResource($this->loadTemplate($subformTemplate)) : null;

        $documentationTemplate = ChecklistTemplate::query()
            ->where('slug', 'dealer-operations-standards-documentation')
            ->where('is_active', true)
            ->first();
        $documentationTemplateData = $documentationTemplate ? $this->templateResource($this->loadTemplate($documentationTemplate)) : null;

        $checklistSummary = $this->buildChecklistSummary($template, $subformTemplate);
        $userChecklistOverview = $checklistSummary;

        $availableBaseTemplates = ChecklistTemplate::query()
            ->where('is_active', true)
            ->get(['id', 'slug', 'name', 'description'])
            ->map(fn ($t) => [
                'slug' => $t->slug,
                'name' => $t->name,
                'description' => $t->description,
            ])
            ->values()
            ->all();

        $subformDocData = in_array($slug, ['dealer-operations-standards', 'dealer-operations-standards-aftersales'], true)
            ? app(AftersalesSubformDocService::class)->getSubformAndDocumentationResults(
                $branch,
                $date,
                $submission?->id,
                'user',
                $request->user()?->id
            )
            : null;

        return view($view, [
            'template' => $templateData,
            'subformTemplate' => $subformTemplateData,
            'documentationTemplate' => $documentationTemplateData,
            'subformDocData' => $subformDocData,
            'userChecklistOverview' => $checklistSummary,
            'checklistSummary' => $checklistSummary,
            'availableBaseTemplates' => $availableBaseTemplates,
            'submission' => $submissionData,
            'branches' => $branches,
            'canManageTemplate' => $canManageTemplate,
            'checklistBootstrap' => [
                'template' => $templateData,
                'subform_template' => $subformTemplateData,
                'documentation_template' => $documentationTemplateData,
                'subform_doc_data' => $subformDocData,
                'user_overview' => $checklistSummary,
                'checklist_summary' => $checklistSummary,
                'available_base_templates' => $availableBaseTemplates,
                'submission' => $submissionData,
                'date' => $date,
                'branch' => $branch,
                'branches' => $branches,
                'can_manage_template' => $canManageTemplate,
            ],
            ...$viewData,
        ]);
    }

    private function buildChecklistSummary(ChecklistTemplate $template, ?ChecklistTemplate $subformTemplate = null): array
    {
        $templates = ChecklistTemplate::query()
            ->where('is_active', true)
            ->with(['sections.items'])
            ->get()
            ->keyBy('slug');
        $slug = $template->slug;
        $itemsCount = $template->sections->flatMap->items->count();
        $sectionsCount = $template->sections->count();

        $dosAftersales = $templates->get('dealer-operations-standards');
        $dosSubform = $subformTemplate ?? $templates->get('dealer-operations-standards-subform');
        $dosDoc = $templates->get('dealer-operations-standards-documentation');
        $restroom = $templates->get('restroom');
        $sales5s = $templates->get('sales');
        $service5s = $templates->get('service');
        $dosSales = $templates->get('dealer-operations-standards-sales');
        $isDosAftersales = in_array($slug, ['dealer-operations-standards', 'dealer-operations-standards-aftersales'], true);

        $ceCore = $dosAftersales ? $dosAftersales->sections->flatMap->items->filter(fn ($i) => in_array(strtoupper(trim((string) ($i->metadata['checker'] ?? $i->metadata['responsible_role'] ?? ''))), ['CE SERVICE', 'CE'], true))->count() : 9;
        $ceSubform = 20; // 9 Service Reception + 11 Customer's Lounge
        $ceDoc = $dosDoc ? $dosDoc->sections->flatMap->items->count() : 17;
        $subformItems = $template->sections->flatMap->items->filter(function ($item) {
            $meta = (array) ($item->metadata ?? []);
            return ! empty($meta['has_subform'])
                || in_array((string) ($item->code ?? ''), ['23', '27', '53', '54', '55'], true)
                || ! empty($meta['subform_key']);
        });
        $hasSubform = $isDosAftersales || $subformItems->isNotEmpty() || $slug === 'dealer-operations-standards-subform';

        $wsCore = $dosAftersales ? $dosAftersales->sections->flatMap->items->filter(fn ($i) => in_array(strtoupper(trim((string) ($i->metadata['checker'] ?? $i->metadata['responsible_role'] ?? ''))), ['WORKSHOP SUP', 'WS SUP', 'WS', 'WORKSHOP SUPERVISOR'], true))->count() : 12;
        $wsSubform = 16; // 12 Employee Facilities + 4 Mitsubishi Quick Service
        $subformQuestionsCount = 0;
        $subformBreakdown = [];
        if ($hasSubform) {
            if ($subformTemplate) {
                $subformQuestionsCount = $subformTemplate->sections->flatMap->items->count();
                foreach ($subformTemplate->sections as $sec) {
                    $subformBreakdown[] = [
                        'name' => $sec->title,
                        'count' => $sec->items->count(),
                    ];
                }
            } elseif ($isDosAftersales) {
                $subformQuestionsCount = 39;
                $subformBreakdown = [
                    ['name' => 'Service Reception', 'count' => 9],
                    ['name' => "Customer's Lounge", 'count' => 11],
                    ['name' => 'Mitsubishi Quick Service', 'count' => 4],
                    ['name' => 'Employee Facilities', 'count' => 12],
                    ['name' => 'Meeting Room', 'count' => 3],
                ];
            } elseif ($slug === 'dealer-operations-standards-subform') {
                $subformQuestionsCount = $itemsCount;
                foreach ($template->sections as $sec) {
                    $subformBreakdown[] = [
                        'name' => $sec->title,
                        'count' => $sec->items->count(),
                    ];
                }
            }
        }

        $asmCore = $dosAftersales ? $dosAftersales->sections->flatMap->items->filter(fn ($i) => in_array(strtoupper(trim((string) ($i->metadata['checker'] ?? $i->metadata['responsible_role'] ?? ''))), ['ASM', 'AFTERSALES MANAGER'], true))->count() : 50;
        $asmSubform = 3; // 3 Meeting Room
        $docQuestionsCount = 0;
        if ($isDosAftersales) {
            $docTemplate = ChecklistTemplate::query()
                ->where('slug', 'dealer-operations-standards-documentation')
                ->where('is_active', true)
                ->first();
            $docQuestionsCount = $docTemplate ? $docTemplate->sections->flatMap->items->count() : 17;
        }

        $partsCore = $dosAftersales ? $dosAftersales->sections->flatMap->items->filter(fn ($i) => in_array(strtoupper(trim((string) ($i->metadata['checker'] ?? $i->metadata['responsible_role'] ?? ''))), ['PARTS', 'PARTS SUPERVISOR'], true))->count() : 3;
        $jcCore = $dosAftersales ? $dosAftersales->sections->flatMap->items->filter(fn ($i) => in_array(strtoupper(trim((string) ($i->metadata['checker'] ?? $i->metadata['responsible_role'] ?? ''))), ['JC', 'JOB CONTROLLER'], true))->count() : 1;
        $aftersalesTotalCore = $dosAftersales ? $dosAftersales->sections->flatMap->items->count() : 75;
        $subformTotal = $dosSubform ? $dosSubform->sections->flatMap->items->count() : 39;
        $rolesSummary = [];
        if ($isDosAftersales) {
            $ceCore = $template->sections->flatMap->items->filter(fn ($i) => in_array(strtoupper(trim((string) ($i->metadata['checker'] ?? $i->metadata['responsible_role'] ?? ''))), ['CE SERVICE', 'CE'], true))->count() ?: 9;
            $wsCore = $template->sections->flatMap->items->filter(fn ($i) => in_array(strtoupper(trim((string) ($i->metadata['checker'] ?? $i->metadata['responsible_role'] ?? ''))), ['WORKSHOP SUP', 'WS SUP', 'WS', 'WORKSHOP SUPERVISOR'], true))->count() ?: 12;
            $asmCore = $template->sections->flatMap->items->filter(fn ($i) => in_array(strtoupper(trim((string) ($i->metadata['checker'] ?? $i->metadata['responsible_role'] ?? ''))), ['ASM', 'AFTERSALES MANAGER'], true))->count() ?: 50;
            $partsCore = $template->sections->flatMap->items->filter(fn ($i) => in_array(strtoupper(trim((string) ($i->metadata['checker'] ?? $i->metadata['responsible_role'] ?? ''))), ['PARTS', 'PARTS SUPERVISOR'], true))->count() ?: 3;
            $jcCore = $template->sections->flatMap->items->filter(fn ($i) => in_array(strtoupper(trim((string) ($i->metadata['checker'] ?? $i->metadata['responsible_role'] ?? ''))), ['JC', 'JOB CONTROLLER'], true))->count() ?: 1;

            $rolesSummary = [
                ['code' => 'CE SERVICE', 'label' => 'CE Service', 'core' => $ceCore, 'subform' => 20, 'doc' => 17, 'total' => $ceCore + 20 + 17, 'role_id' => 'ce_service'],
                ['code' => 'WORKSHOP SUP', 'label' => 'Workshop Sup', 'core' => $wsCore, 'subform' => 16, 'doc' => 0, 'total' => $wsCore + 16, 'role_id' => 'workshop_sup'],
                ['code' => 'ASM', 'label' => 'ASM', 'core' => $asmCore, 'subform' => 3, 'doc' => 0, 'total' => $asmCore + 3, 'role_id' => 'aftersales_mgr', 'oversees' => 131],
                ['code' => 'PARTS', 'label' => 'Parts', 'core' => $partsCore, 'subform' => 0, 'doc' => 0, 'total' => $partsCore, 'role_id' => 'parts_sup'],
                ['code' => 'JC', 'label' => 'Job Controller', 'core' => $jcCore, 'subform' => 0, 'doc' => 0, 'total' => $jcCore, 'role_id' => 'job_controller'],
            ];
        }

        $users = [
            [
                'id' => 'ce_service',
                'checker_code' => 'CE SERVICE',
                'name' => 'Customer Experience Service',
                'short_title' => 'CE Service',
                'department' => 'DOS - Aftersales',
                'icon' => 'fa-user-tie',
                'color' => '#0ea5e9',
                'core_count' => $ceCore,
                'subform_count' => $ceSubform,
                'doc_count' => $ceDoc,
                'total_count' => $ceCore + $ceSubform + $ceDoc,
                'has_subform' => true,
                'has_documentation' => true,
                'subform_details' => 'Reception (9) + Lounge (11)',
                'doc_details' => 'Service Documents (17 across RO samples)',
                'scope' => 'reception_lounge_doc',
            ],
            [
                'id' => 'workshop_sup',
                'checker_code' => 'WORKSHOP SUP',
                'name' => 'Workshop Supervisor',
                'short_title' => 'Workshop Sup',
                'department' => 'DOS - Aftersales',
                'icon' => 'fa-wrench',
                'color' => '#8b5cf6',
                'core_count' => $wsCore,
                'subform_count' => $wsSubform,
                'doc_count' => 0,
                'total_count' => $wsCore + $wsSubform,
                'has_subform' => true,
                'has_documentation' => false,
                'subform_details' => 'Facilities (12) + MQS (4)',
                'doc_details' => null,
                'scope' => 'workshop_facilities',
            ],
            [
                'id' => 'aftersales_mgr',
                'checker_code' => 'ASM',
                'name' => 'Aftersales Manager',
                'short_title' => 'Aftersales Mgr',
                'department' => 'DOS - Aftersales',
                'icon' => 'fa-user-shield',
                'color' => '#e31c3d',
                'core_count' => $asmCore,
                'subform_count' => $asmSubform,
                'doc_count' => 0,
                'total_count' => $asmCore + $asmSubform,
                'oversees_total' => $aftersalesTotalCore + $subformTotal + $ceDoc,
                'has_subform' => true,
                'has_documentation' => true,
                'subform_details' => 'Meeting Room (3) & Oversees All Subforms (39)',
                'doc_details' => 'Oversees Documentation Audit (17)',
                'scope' => 'overall_management',
            ],
            [
                'id' => 'parts_sup',
                'checker_code' => 'PARTS SUPERVISOR',
                'name' => 'Parts Supervisor',
                'short_title' => 'Parts Sup',
                'department' => 'DOS - Aftersales',
                'icon' => 'fa-boxes-stacked',
                'color' => '#f59e0b',
                'core_count' => $partsCore,
                'subform_count' => 0,
                'doc_count' => 0,
                'total_count' => $partsCore,
                'has_subform' => false,
                'has_documentation' => false,
                'subform_details' => null,
                'doc_details' => null,
                'scope' => 'parts_inventory',
            ],
            [
                'id' => 'job_controller',
                'checker_code' => 'JC',
                'name' => 'Job Controller',
                'short_title' => 'Job Controller',
                'department' => 'DOS - Aftersales',
                'icon' => 'fa-clipboard-list',
                'color' => '#10b981',
                'core_count' => $jcCore,
                'subform_count' => 0,
                'doc_count' => 0,
                'total_count' => $jcCore,
                'has_subform' => false,
                'has_documentation' => false,
                'subform_details' => null,
                'doc_details' => null,
                'scope' => 'dispatch_control',
            ],
            [
                'id' => 'utilities_user',
                'checker_code' => '5S_UTILITIES',
                'name' => '5S Utilities PIC',
                'short_title' => '5S Utilities',
                'department' => '5S Systems',
                'icon' => 'fa-restroom',
                'color' => '#059669',
                'core_count' => $restroom ? $restroom->sections->flatMap->items->count() : 31,
                'subform_count' => 0,
                'doc_count' => 0,
                'total_count' => $restroom ? $restroom->sections->flatMap->items->count() : 31,
                'has_subform' => false,
                'has_documentation' => false,
                'subform_details' => null,
                'doc_details' => null,
                'scope' => 'restroom_hourly',
                'note' => '10 hourly inspections daily',
            ],
            [
                'id' => 'sales_5s_user',
                'checker_code' => '5S_SALES',
                'name' => '5S Sales PIC',
                'short_title' => '5S Sales',
                'department' => '5S Systems',
                'icon' => 'fa-car-side',
                'color' => '#2563eb',
                'core_count' => $sales5s ? $sales5s->sections->flatMap->items->count() : 44,
                'subform_count' => 0,
                'doc_count' => 0,
                'total_count' => $sales5s ? $sales5s->sections->flatMap->items->count() : 44,
                'has_subform' => false,
                'has_documentation' => false,
                'subform_details' => null,
                'doc_details' => null,
                'scope' => 'showroom_readiness',
            ],
            [
                'id' => 'service_5s_user',
                'checker_code' => '5S_SERVICE',
                'name' => '5S Service PIC',
                'short_title' => '5S Service',
                'department' => '5S Systems',
                'icon' => 'fa-screwdriver-wrench',
                'color' => '#7c3aed',
                'core_count' => $service5s ? $service5s->sections->flatMap->items->count() : 33,
                'subform_count' => 0,
                'doc_count' => 0,
                'total_count' => $service5s ? $service5s->sections->flatMap->items->count() : 33,
                'has_subform' => false,
                'has_documentation' => false,
                'subform_details' => null,
                'doc_details' => null,
                'scope' => 'workshop_readiness',
            ],
            [
                'id' => 'sales_manager',
                'checker_code' => 'SALES MANAGER',
                'name' => 'Sales Manager',
                'short_title' => 'Sales Mgr',
                'department' => 'DOS - Sales',
                'icon' => 'fa-briefcase',
                'color' => '#d97706',
                'core_count' => $dosSales ? $dosSales->sections->flatMap->items->count() : 90,
                'subform_count' => 0,
                'doc_count' => 0,
                'total_count' => $dosSales ? $dosSales->sections->flatMap->items->count() : 90,
                'has_subform' => false,
                'has_documentation' => false,
                'subform_details' => null,
                'doc_details' => null,
                'scope' => 'sales_standards',
            ],
        ];
        $assignedPic = '';
        $frequency = 'Daily';
        $title = $template->name;

        if ($slug === 'sales') {
            $title = '5S Sales Checklist';
            $assignedPic = '5S Sales PIC';
            $frequency = 'Daily Inspection';
            $guide = "Daily showroom and sales floor inspection across {$sectionsCount} sections.";
        } elseif ($slug === 'service') {
            $title = '5S Service Checklist';
            $assignedPic = '5S Service PIC';
            $frequency = 'Daily Inspection';
            $guide = "Daily service reception and workshop inspection across {$sectionsCount} sections.";
        } elseif ($slug === 'restroom') {
            $title = '5S Utilities - Restroom Checklist';
            $assignedPic = '5S Utilities PIC';
            $frequency = '10 Hourly Slots Daily (9:00 AM – 6:00 PM)';
            $guide = "Daily restroom sanitation tracked hourly across 10 inspection slots.";
        } elseif ($isDosAftersales) {
            $assignedPic = 'Aftersales Team (ASM, CE Service, Workshop Sup, Parts, JC)';
            $frequency = 'Monthly Compliance Audit';
            $guide = "Monthly compliance audit covering 75 core items, 5 subforms, and 17 documentation checks.";
        } elseif ($slug === 'dealer-operations-standards-sales') {
            $assignedPic = 'Sales Manager / Dealer Principal';
            $frequency = 'Monthly Compliance Audit';
            $guide = "Monthly showroom and sales process compliance audit across {$sectionsCount} sections.";
        } elseif ($slug === 'dealer-operations-standards-subform') {
            $assignedPic = 'Aftersales Auditors';
            $frequency = 'Monthly Compliance Audit';
            $guide = "Specialized facility subforms covering {$itemsCount} standards across {$sectionsCount} areas.";
        } elseif ($slug === 'dealer-operations-standards-documentation') {
            $assignedPic = 'CE Service / Warranty & Accounts';
            $frequency = 'Monthly Compliance Audit';
            $guide = "Documentation audit covering Rationalized Checksheets, Repair Orders, and Invoices.";
        } else {
            $assignedPic = $template->category ?? 'Operational Staff';
            $frequency = ucfirst((string) ($template->metadata['frequency'] ?? 'Periodic'));
            $guide = "Operational checklist covering {$itemsCount} items across {$sectionsCount} sections.";
        }

        return [
            'users' => $users,
            'active_slug' => $template->slug,
            'is_dos_aftersales' => $template->slug === 'dealer-operations-standards',
            'subform_total_items' => $subformTotal,
            'doc_total_items' => $ceDoc,
            'slug' => $slug,
            'title' => $title,
            'items_count' => $itemsCount,
            'sections_count' => $sectionsCount,
            'has_subform' => $hasSubform,
            'subform_count' => $subformQuestionsCount,
            'subform_breakdown' => $subformBreakdown,
            'has_documentation' => $docQuestionsCount > 0,
            'doc_count' => $docQuestionsCount,
            'total_audit_count' => $itemsCount + $subformQuestionsCount + $docQuestionsCount,
            'assigned_pic' => $assignedPic,
            'frequency' => $frequency,
            'guide' => $guide,
            'roles' => $rolesSummary,
        ];
    }

    private function legacyRedirectParameters(Request $request, string $checklist): array
    {
        return array_merge(
            Arr::only($request->query(), ['branch', 'date']),
            ['checklist' => $checklist]
        );
    }

    private function validatedAuditPayload(Request $request, ?ChecklistTemplate $template = null): array
    {
        $input = $request->all();
        $input['date'] ??= $input['checklist_date'] ?? null;
        $input['branch'] ??= $input['branch_id'] ?? null;

        $context = is_array($input['context'] ?? null) ? $input['context'] : [];
        foreach (['dealer', 'outlet', 'auditor', 'preset'] as $field) {
            if (array_key_exists($field, $input)) {
                $context[$field] = $input[$field];
            }
        }
        $input['context'] = $context ?: null;

        $responses = $input['responses'] ?? [];
        if (is_array($responses)) {
            foreach ($responses as $key => &$response) {
                if (! is_array($response)) {
                    continue;
                }
                if (! array_is_list($responses) && ! isset($response['item_key'], $response['item_id'])) {
                    $response['item_key'] = (string) $key;
                }
                $response['item_id'] ??= $response['itemId'] ?? null;
                $response['item_key'] ??= $response['itemKey'] ?? null;
                $response['remark'] ??= $response['remarks'] ?? null;
                $response['action_plan'] ??= $response['actionPlan'] ?? null;
                $response['commitment_date'] ??= $response['commitmentDate'] ?? null;
                $response['commitment_date'] = $this->normalizeCommitmentDateTime(
                    $response['commitment_date']
                );

                $details = $response['details'] ?? null;
                $escalation = $this->firstFilledValue([
                    $response['escalation_target'] ?? null,
                    $response['escalation'] ?? null,
                    is_array($details) ? ($details['escalation_target'] ?? null) : null,
                    is_array($details) ? ($details['escalation'] ?? null) : null,
                ]);
                $response['escalation_target'] = $this->normalizeEscalationTarget($escalation);
                if ($details === null || is_array($details)) {
                    $response['details'] = $this->normalizedResponseDetails(
                        is_array($details) ? $details : [],
                        $response['escalation_target']
                    );
                }
                $response['attachment_path'] ??= $response['attachmentPath'] ?? $response['photo_path'] ?? $response['photoPath'] ?? null;
                if (is_string($response['status'] ?? null)) {
                    $response['status'] = Str::lower(trim($response['status']));
                }
            }
            unset($response);
        }
        $input['responses'] = array_values($responses);

        $validator = Validator::make($input, [
            'date' => ['required', 'date_format:Y-m-d'],
            'branch' => ['nullable', 'string', 'max:255'],
            'context' => ['nullable', 'array'],
            'responses' => ['required', 'array'],
            'responses.*.item_id' => ['nullable', 'integer'],
            'responses.*.item_key' => ['nullable', 'string', 'max:100'],
            'responses.*.status' => ['nullable', 'string', Rule::in(['yes', 'no', 'na'])],
            'responses.*.remark' => ['nullable', 'string', 'max:10000'],
            'responses.*.finding' => ['nullable', 'string', 'max:10000'],
            'responses.*.action_plan' => ['nullable', 'string', 'max:10000'],
            'responses.*.escalation_target' => [
                'nullable',
                'string',
                Rule::in(self::ESCALATION_TARGETS),
            ],
            'responses.*.commitment_date' => ['nullable', 'date_format:Y-m-d H:i:s'],
            'responses.*.details' => ['nullable', 'array'],
            'responses.*.attachment_path' => ['nullable', 'string', 'max:500'],
        ]);

        $validator->after(function ($validator) use ($input, $template, $request): void {
            foreach ($input['responses'] ?? [] as $index => $response) {
                if (empty($response['item_id']) && blank($response['item_key'] ?? null)) {
                    $validator->errors()->add(
                        "responses.$index.item_key",
                        'Each response must identify an item by item_id or item_key.'
                    );
                }
            }

            if ($template && ($template->settings['validation_mode'] ?? null) === 'time_slots') {
                $date = (string) ($input['date'] ?? '');
                $clientTime = $request->header('X-Client-Time')
                    ?? data_get($input, 'client_time')
                    ?? data_get($input, 'context.client_time')
                    ?? data_get($input, 'responses.0.details.client_time');
                foreach ($input['responses'] ?? [] as $index => $response) {
                    $slots = $response['details']['slots'] ?? [];
                    if (is_array($slots)) {
                        foreach ($slots as $slotKey => $mark) {
                            if ($mark !== null && $mark !== '' && $this->isSlotInFuture($date, (string) $slotKey, $clientTime)) {
                                $validator->errors()->add(
                                    "responses.$index.details.slots.$slotKey",
                                    "Inspection for future time slot $slotKey cannot be recorded ahead of time."
                                );
                            }
                        }
                    }
                }
            }
        });

        return $validator->validate();
    }

    private function normalizeTemplateInput(array $input, ChecklistTemplate $template, array $editorOptions): array
    {
        $settings = is_array($input['settings'] ?? null)
            ? array_replace($template->settings ?? [], $input['settings'])
            : ($template->settings ?? []);
        foreach (['instructions', 'short_name'] as $field) {
            if (array_key_exists($field, $input)) {
                $settings[$field] = $input[$field];
            }
        }
        // Preserve scoring, schedules and other settings when only instructions
        // are edited or an older client omits the settings object.
        if (! array_key_exists('settings', $input) || is_array($input['settings']) || $input['settings'] === null) {
            $input['settings'] = $settings;
        }

        if (! is_array($input['sections'] ?? null)) {
            return $input;
        }

        $existingSections = $template->sections->keyBy(fn (ChecklistSection $section): string => Str::lower($section->key));
        $existingItems = $template->sections->flatMap->items->keyBy(fn (ChecklistItem $item): string => Str::lower($item->key));

        foreach ($input['sections'] as &$section) {
            if (! is_array($section)) {
                continue;
            }
            $section['key'] ??= is_string($section['id'] ?? null) ? $section['id'] : null;
            if (is_string($section['key'])) {
                $section['key'] = Str::lower(trim($section['key']));
            }
            $existingSection = is_string($section['key']) ? $existingSections->get($section['key']) : null;
            if ($existingSection) {
                $section['key'] = $existingSection->key;
            }
            if (! array_key_exists('metadata', $section) || is_array($section['metadata']) || $section['metadata'] === null) {
                $section['metadata'] = array_replace($existingSection?->metadata ?? [], $section['metadata'] ?? []) ?: null;
            }

            if (! is_array($section['items'] ?? null)) {
                continue;
            }

            foreach ($section['items'] as &$item) {
                if (! is_array($item)) {
                    continue;
                }
                $item['key'] ??= is_string($item['id'] ?? null) ? $item['id'] : null;
                if (is_string($item['key'])) {
                    $item['key'] = Str::lower(trim($item['key']));
                }
                $existingItem = is_string($item['key']) ? $existingItems->get($item['key']) : null;
                if ($existingItem) {
                    $item['key'] = $existingItem->key;
                }
                $item['prompt'] ??= $item['text'] ?? $item['checkItem'] ?? null;
                if (isset($item['metadata']) && ! is_array($item['metadata'])) {
                    continue;
                }
                $submittedMetadata = $item['metadata'] ?? [];
                $metadata = array_replace($existingItem?->metadata ?? [], $submittedMetadata);
                foreach ([
                    'number',
                    'code',
                    'label',
                    'description',
                    'level',
                    'category',
                    'coverage',
                    'subject',
                    'checker',
                    'pic',
                    'responsible_role',
                    'bom_task',
                    'escalation',
                    'how_to_check',
                    'response_type',
                ] as $field) {
                    if (array_key_exists($field, $item)) {
                        $metadata[$field] = $item[$field];
                    }
                }
                if ((array_key_exists('how_to_check', $item) || array_key_exists('how_to_check', $submittedMetadata))
                    && array_key_exists('howToCheck', $metadata)) {
                    $metadata['howToCheck'] = $metadata['how_to_check'];
                }

                $responsible = $metadata['responsible_role'] ?? $metadata['responsible'] ?? $metadata['pic'] ?? null;
                // Explicit blanks are validated as errors; omitted legacy
                // responsibility fields retain the old value or checklist default.
                foreach (['responsible_role', 'responsible', 'pic'] as $field) {
                    if (array_key_exists($field, $item)) {
                        $responsible = $item[$field];
                        break;
                    }
                    if (array_key_exists($field, $submittedMetadata)) {
                        $responsible = $submittedMetadata[$field];
                        break;
                    }
                }
                $hasSubmittedResponsible = count(array_intersect(['responsible_role', 'responsible', 'pic'], array_keys($item))) > 0
                    || count(array_intersect(['responsible_role', 'responsible', 'pic'], array_keys($submittedMetadata))) > 0;
                if (! $hasSubmittedResponsible && blank($responsible)) {
                    $responsible = $editorOptions['default_responsible_role'];
                }
                $metadata['responsible_role'] = $responsible;
                $metadata['pic'] = $responsible;
                if (array_key_exists('responsible', $metadata)) {
                    $metadata['responsible'] = $responsible;
                }

                $hasSubmittedLevel = array_key_exists('level', $item) || array_key_exists('level', $submittedMetadata);
                if (! $hasSubmittedLevel && blank($metadata['level'] ?? null) && $editorOptions['level_required']) {
                    $metadata['level'] = $metadata['category'] ?? 'Standard';
                }
                if (array_key_exists('level', $metadata)) {
                    $metadata['category'] = $metadata['level'];
                }
                $item['metadata'] = $metadata;
            }
            unset($item);
        }
        unset($section);

        return $input;
    }

    private function submissionMatchesPayload(
        ChecklistSubmission $submission,
        ChecklistTemplate $template,
        array $payloads,
        ?array $context
    ): bool {
        if ($submission->template_version !== $template->version) {
            return false;
        }

        $submission->loadMissing('responses');

        return $this->canonicalizeJson($submission->context) === $this->canonicalizeJson($context)
            && $this->storedResponseState($submission) === $this->payloadResponseState($template, $payloads);
    }

    private function payloadResponseState(ChecklistTemplate $template, array $payloads): array
    {
        $itemsById = $template->sections
            ->flatMap->items
            ->keyBy('id');
        $itemsByKey = $template->sections
            ->flatMap->items
            ->keyBy(fn (ChecklistItem $item): string => Str::lower(trim($item->key)));
        $state = [];

        foreach ($payloads as $index => $payload) {
            $item = ! empty($payload['item_id'])
                ? $itemsById->get((int) $payload['item_id'])
                : $itemsByKey->get(Str::lower(trim((string) ($payload['item_key'] ?? ''))));

            if (! $item) {
                throw ValidationException::withMessages([
                    "responses.$index.item_key" => 'The checklist item does not belong to this active template.',
                ]);
            }

            $status = $payload['status'] ?? null;
            if ($status === null && $template->slug === 'restroom') {
                $status = $this->statusFromSlots($payload['details']['slots'] ?? []);
            }

            $state[$item->key] = [
                'status' => $status,
                'remark' => $this->trimmedOrNull($payload['remark'] ?? null),
                'finding' => $this->trimmedOrNull($payload['finding'] ?? null),
                'action_plan' => $this->trimmedOrNull($payload['action_plan'] ?? null),
                'escalation_target' => $payload['escalation_target'] ?? null,
                'commitment_date' => $payload['commitment_date'] ?? null,
                'details' => $this->canonicalizeJson($this->normalizedResponseDetails(
                    $payload['details'] ?? [],
                    $payload['escalation_target'] ?? null
                )),
                'attachment_path' => $this->trimmedOrNull($payload['attachment_path'] ?? null),
            ];
        }

        ksort($state, SORT_STRING);

        return $state;
    }

    private function storedResponseState(ChecklistSubmission $submission): array
    {
        $state = [];

        foreach ($submission->responses as $response) {
            $state[$response->item_key] = [
                'status' => $response->status,
                'remark' => $response->remark,
                'finding' => $response->finding,
                'action_plan' => $response->action_plan,
                'escalation_target' => $this->responseEscalationTarget($response),
                'commitment_date' => $response->commitment_date?->format('Y-m-d H:i:s'),
                'details' => $this->canonicalizeJson($this->normalizedResponseDetails(
                    $response->details ?? [],
                    $this->responseEscalationTarget($response)
                )),
                'attachment_path' => $response->attachment_path,
            ];
        }

        ksort($state, SORT_STRING);

        return $state;
    }

    private function canonicalizeJson(mixed $value): mixed
    {
        if (! is_array($value)) {
            return $value;
        }

        if (array_is_list($value)) {
            return array_map(fn (mixed $item): mixed => $this->canonicalizeJson($item), $value);
        }

        $canonical = [];
        foreach ($value as $key => $item) {
            $canonical[$key] = $this->canonicalizeJson($item);
        }
        ksort($canonical, SORT_STRING);

        return $canonical;
    }

    private function syncResponses(
        ChecklistSubmission $submission,
        ChecklistTemplate $template,
        array $payloads,
        bool $replaceMissing = true
    ): EloquentCollection {
        $itemsById = $template->sections
            ->flatMap->items
            ->keyBy('id');
        $itemsByKey = $template->sections
            ->flatMap->items
            ->keyBy(fn (ChecklistItem $item): string => Str::lower(trim($item->key)));
        $existingResponses = $submission->exists
            ? $submission->responses()->get()->keyBy('item_key')
            : collect();
        $seen = [];

        $isDocumentation = ($template->settings['validation_mode'] ?? null) === 'dos_documentation'
            || in_array($template->slug, ['dealer-operations-standards-documentation', 'dos-documentation', 'documentation'], true);

        if ($isDocumentation) {
            $rawCustomers = null;
            foreach ($payloads as $p) {
                if (! empty($p['details']['customers']) && is_array($p['details']['customers'])) {
                    $rawCustomers = $p['details']['customers'];
                    break;
                }
            }

            if ($rawCustomers !== null) {
                $allItemKeys = $template->sections->flatMap->items->pluck('key')->all();
                $normalizedCustomers = [];

                foreach ($rawCustomers as $cust) {
                    if (! is_array($cust)) {
                        continue;
                    }
                    $answers = (array) ($cust['answers'] ?? []);
                    $hasNo = false;
                    foreach ($answers as $ans) {
                        if (is_string($ans) && Str::lower(trim($ans)) === 'no') {
                            $hasNo = true;
                            break;
                        }
                    }

                    if ($hasNo) {
                        foreach ($allItemKeys as $k) {
                            $answers[$k] = 'no';
                        }
                        foreach ($answers as $k => $v) {
                            $answers[$k] = 'no';
                        }
                    }

                    $cust['answers'] = $answers;
                    $normalizedCustomers[] = $cust;
                }

                foreach ($payloads as &$payload) {
                    $item = ! empty($payload['item_id'])
                        ? $itemsById->get((int) $payload['item_id'])
                        : $itemsByKey->get(Str::lower(trim((string) ($payload['item_key'] ?? ''))));
                    $itemKey = $item?->key ?? (string) ($payload['item_key'] ?? '');

                    $payload['details'] = is_array($payload['details'] ?? null) ? $payload['details'] : [];
                    $payload['details']['customers'] = $normalizedCustomers;

                    if ($itemKey !== '') {
                        $statuses = [];
                        foreach ($normalizedCustomers as $cust) {
                            $ans = $cust['answers'][$itemKey] ?? null;
                            if (is_string($ans) && trim($ans) !== '') {
                                $statuses[] = Str::lower(trim($ans));
                            }
                        }

                        if (in_array('no', $statuses, true)) {
                            $payload['status'] = 'no';
                        } elseif (count($statuses) === count($normalizedCustomers) && count($normalizedCustomers) > 0) {
                            $payload['status'] = in_array('na', $statuses, true) ? 'na' : 'yes';
                        }
                    }
                }
                unset($payload);
            } else {
                $hasAnyNo = false;
                foreach ($payloads as $p) {
                    if (is_string($p['status'] ?? null) && Str::lower(trim($p['status'])) === 'no') {
                        $hasAnyNo = true;
                        break;
                    }
                }
                if ($hasAnyNo) {
                    foreach ($payloads as &$payload) {
                        $payload['status'] = 'no';
                    }
                    unset($payload);
                }
            }
        }

        foreach ($payloads as $index => $payload) {
            $item = ! empty($payload['item_id'])
                ? $itemsById->get((int) $payload['item_id'])
                : $itemsByKey->get(Str::lower(trim((string) ($payload['item_key'] ?? ''))));

            if (! $item) {
                throw ValidationException::withMessages([
                    "responses.$index.item_key" => 'The checklist item does not belong to this active template.',
                ]);
            }

            $status = $payload['status'] ?? null;
            if ($status === null && $template->slug === 'restroom') {
                $status = $this->statusFromSlots($payload['details']['slots'] ?? []);
            }

            ChecklistResponse::query()->updateOrCreate([
                'checklist_submission_id' => $submission->id,
                'item_key' => $item->key,
            ], [
                'checklist_item_id' => $item->id,
                'status' => $status,
                'remark' => $this->trimmedOrNull($payload['remark'] ?? null),
                'finding' => $this->trimmedOrNull($payload['finding'] ?? null),
                'action_plan' => $this->trimmedOrNull($payload['action_plan'] ?? null),
                'escalation_target' => $payload['escalation_target'] ?? null,
                'commitment_date' => $payload['commitment_date'] ?? null,
                'details' => $this->normalizedResponseDetails(
                    $payload['details'] ?? [],
                    $payload['escalation_target'] ?? null
                ),
                'attachment_path' => $this->trimmedOrNull($payload['attachment_path'] ?? null),
                'item_snapshot' => $this->itemSnapshot($item),
            ]);
            $seen[] = $item->key;
        }

        if ($replaceMissing) {
            $stale = $submission->responses();
            if ($seen) {
                $stale->whereNotIn('item_key', $seen);
            }
            $stale->delete();
        }

        return $submission->responses()->get();
    }

    private function validateCompleteSubmission(
        ChecklistTemplate $template,
        Collection $responses,
        ?ChecklistSubmission $submission = null,
        ?string $clientTime = null
    ): void {
        $responses = $responses->keyBy('item_key');
        $errors = [];
        $mode = $template->settings['validation_mode'] ?? 'yes_no_na';
        $auditDateStr = $submission?->audit_date?->format('Y-m-d') ?? now()->format('Y-m-d');

        foreach ($template->sections->flatMap->items as $item) {
            /** @var ChecklistResponse|null $response */
            $response = $responses->get($item->key);
            $field = "responses.{$item->key}";

            if ($mode === 'time_slots') {
                $slots = is_array($response?->details['slots'] ?? null)
                    ? $response->details['slots']
                    : [];
                $activeSlots = $item->metadata['active_slots'] ?? null;
                foreach ($this->timeSlotKeys($template) as $slot) {
                    if (is_array($activeSlots) && ! in_array($slot, $activeSlots, true)) {
                        continue;
                    }
                    if ($this->isSlotInFuture($auditDateStr, $slot, $clientTime)) {
                        continue;
                    }
                    if (! array_key_exists($slot, $slots) || ! $this->isValidSlotMark($slots[$slot])) {
                        $errors["$field.details.slots.$slot"] = "A / or X mark is required for $slot.";
                    }
                }

                continue;
            }

            if (! $response || ! in_array($response->status, ['yes', 'no', 'na'], true)) {
                $errors["$field.status"] = 'A YES, NO, or N/A response is required.';

                continue;
            }

            if ($mode === 'dos' && $response->status === 'no') {
                if (blank($response->finding)) {
                    $errors["$field.finding"] = 'A finding is required for a NO response.';
                }
            } elseif ($mode === 'dos' && $response->status === 'na' && blank($response->finding)) {
                $errors["$field.finding"] = 'A reason is required for an N/A response.';
            } elseif (! in_array($mode, ['dos', 'dos_subform', 'dos_documentation'], true) && in_array($response->status, ['no', 'na'], true) && blank($response->remark)) {
                $errors["$field.remark"] = 'A remark is required for a NO or N/A response.';
            }
        }

        if ($errors) {
            throw ValidationException::withMessages($errors);
        }
    }

    private function calculateScores(ChecklistTemplate $template, Collection $responses): array
    {
        $responsesByKey = $responses->keyBy('item_key');
        $items = $template->sections->flatMap->items;
        $mode = $template->settings['validation_mode'] ?? 'yes_no_na';

        if ($mode === 'time_slots') {
            $good = 0;
            $bad = 0;
            $totalActiveSlots = 0;
            $slotKeys = $this->timeSlotKeys($template);
            $completedSlotsCount = 0;

            foreach ($slotKeys as $slot) {
                $slotActiveItemsCount = 0;
                $slotAnsweredItemsCount = 0;
                foreach ($items as $item) {
                    $slots = $responsesByKey->get($item->key)?->details['slots'] ?? [];
                    $activeSlots = $item->metadata['active_slots'] ?? null;
                    if (is_array($activeSlots) && ! in_array($slot, $activeSlots, true)) {
                        continue;
                    }
                    $slotActiveItemsCount++;
                    if (array_key_exists($slot, $slots) && $this->isValidSlotMark($slots[$slot])) {
                        $slotAnsweredItemsCount++;
                    }
                }
                if ($slotActiveItemsCount > 0 && $slotAnsweredItemsCount >= $slotActiveItemsCount) {
                    $completedSlotsCount++;
                }
            }

            foreach ($items as $item) {
                $slots = $responsesByKey->get($item->key)?->details['slots'] ?? [];
                $activeSlots = $item->metadata['active_slots'] ?? null;
                foreach ($slotKeys as $slot) {
                    if (is_array($activeSlots) && ! in_array($slot, $activeSlots, true)) {
                        continue;
                    }
                    $totalActiveSlots++;
                    if (! array_key_exists($slot, $slots) || ! $this->isValidSlotMark($slots[$slot])) {
                        continue;
                    }
                    $this->isGoodSlotMark($slots[$slot]) ? $good++ : $bad++;
                }
            }
            $slotTotal = $totalActiveSlots;
            $answered = $good + $bad;

            return [
                'total' => $slotTotal,
                'answered' => $answered,
                'yes' => $good,
                'no' => $bad,
                'na' => 0,
                'applicable' => $answered,
                'percentage' => $answered ? round(($good / $answered) * 100, 2) : 0,
                'item_total' => $items->count(),
                'items_answered' => $responsesByKey->count(),
                'slot_total' => $slotTotal,
                'slots_answered' => $answered,
                'completed_slots' => $completedSlotsCount,
                'good' => $good,
                'bad' => $bad,
                'completion_percentage' => $slotTotal ? round(($answered / $slotTotal) * 100, 2) : 0,
            ];
        }

        $overall = $this->metric($items, $responsesByKey);
        if ($mode !== 'dos') {
            return $overall;
        }

        $tiers = [];
        $requirements = ['basic' => 100, 'standard' => 80, 'beyond' => null];
        foreach ($requirements as $tier => $required) {
            $tierItems = $items->filter(
                fn (ChecklistItem $item) => Str::lower($item->metadata['level'] ?? '') === $tier
            );
            $metric = $this->metric($tierItems, $responsesByKey);
            $metric['required_percentage'] = $required;
            $metric['passes'] = $required === null
                ? null
                : $metric['answered'] === $metric['total'] && $metric['percentage'] >= $required;
            $tiers[$tier] = $metric;
        }

        $overall['tiers'] = $tiers;
        $overall['passes'] = $overall['answered'] === $overall['total']
            && $overall['percentage'] >= 80
            && ($tiers['basic']['passes'] ?? false)
            && ($tiers['standard']['passes'] ?? false);

        return $overall;
    }

    private function metric(Collection $items, Collection $responsesByKey): array
    {
        $statuses = $items
            ->map(fn (ChecklistItem $item) => $responsesByKey->get($item->key)?->status)
            ->filter(fn (?string $status) => in_array($status, ['yes', 'no', 'na'], true));
        $yes = $statuses->filter(fn (string $status) => $status === 'yes')->count();
        $no = $statuses->filter(fn (string $status) => $status === 'no')->count();
        $na = $statuses->filter(fn (string $status) => $status === 'na')->count();
        $applicable = $yes + $no;

        return [
            'total' => $items->count(),
            'answered' => $statuses->count(),
            'yes' => $yes,
            'no' => $no,
            'na' => $na,
            'applicable' => $applicable,
            'percentage' => $applicable ? round(($yes / $applicable) * 100, 2) : 0,
        ];
    }

    private function itemSnapshot(ChecklistItem $item): array
    {
        return [
            'id' => $item->id,
            'key' => $item->key,
            'prompt' => $item->prompt,
            'sort_order' => $item->sort_order,
            'metadata' => $item->metadata,
            'section' => [
                'id' => $item->section->id,
                'key' => $item->section->key,
                'title' => $item->section->title,
                'sort_order' => $item->section->sort_order,
                'metadata' => $item->section->metadata,
            ],
        ];
    }

    private function templateEditorOptions(ChecklistTemplate $template): array
    {
        $isDos = Str::startsWith((string) ($template->settings['validation_mode'] ?? ''), 'dos')
            || Str::startsWith($template->slug, 'dealer-operations-standards');
        $defaultRoles = match ($template->slug) {
            'sales' => [User::ROLE_5S_SALES, User::ROLE_PERSON_IN_CHARGE],
            'service' => [User::ROLE_5S_SERVICE, User::ROLE_PERSON_IN_CHARGE],
            'restroom', 'utilities' => [User::ROLE_5S_UTILITIES, User::ROLE_PERSON_IN_CHARGE],
            'gateway-5s' => [User::ROLE_5S_SALES, User::ROLE_5S_SERVICE, User::ROLE_PERSON_IN_CHARGE],
            'dealer-operations-standards-sales' => ['GM', 'SALES MANAGER'],
            default => $isDos ? ['GM', 'ASM', 'CE SERVICE', 'WORKSHOP SUP', 'JOB CONTROLLER', 'PARTS SUPERVISOR'] : [User::ROLE_PERSON_IN_CHARGE],
        };
        $metadata = $template->sections->flatMap->items->map(fn (ChecklistItem $item): array => $item->metadata ?? []);
        $responsibleRoles = collect($defaultRoles)
            ->merge($metadata->map(fn (array $item): mixed => $item['responsible_role'] ?? $item['responsible'] ?? $item['pic'] ?? $item['checker'] ?? null))
            ->filter(fn ($role): bool => is_string($role) && trim($role) !== '')
            ->unique()
            ->map(fn (string $role): array => [
                'value' => $role,
                'label' => match (strtoupper(trim($role))) {
                    'GM' => 'General Manager',
                    'ASM', 'AFTERSALES MANAGER' => 'Aftersales Manager (ASM)',
                    'CE SERVICE', 'CE' => 'Customer Experience Service (CE)',
                    'WORKSHOP SUP', 'WS SUP', 'WS' => 'Workshop Supervisor (WS SUP)',
                    'JOB CONTROLLER', 'JC' => 'Job Controller (JC)',
                    'PARTS SUPERVISOR', 'PARTS' => 'Parts Supervisor',
                    'SALES MANAGER', 'SM' => 'Sales Manager',
                    default => User::roleLabelFor($role),
                },
            ])->values()->all();
        $levels = collect($isDos ? ['Basic', 'Standard', 'Beyond'] : [])
            ->merge($metadata->map(fn (array $item): mixed => $item['level'] ?? $item['category'] ?? null))
            ->filter(fn ($level): bool => is_string($level) && trim($level) !== '')
            ->unique()
            ->map(fn (string $level): array => ['value' => $level, 'label' => $level])
            ->values()->all();

        return [
            'responsible_roles' => $responsibleRoles,
            'levels' => $levels,
            'responsible_required' => true,
            'level_required' => $isDos,
            'default_responsible_role' => $defaultRoles[0],
        ];
    }

    private function templateResource(ChecklistTemplate $template): array
    {
        $settings = is_array($template->settings) ? $template->settings : [];

        return [
            'id' => $template->id,
            'slug' => $template->slug,
            'name' => $template->name,
            'description' => $template->description,
            'version' => $template->version,
            'settings' => $settings,
            // Keep editor consumers independent of where these optional
            // template fields are stored. Older records keep them in the
            // JSON settings column, while newer records may expose them as
            // top-level resource fields.
            'short_name' => $settings['short_name'] ?? null,
            'instructions' => $settings['instructions'] ?? null,
            'time_slots' => $settings['time_slots'] ?? [],
            'editor_options' => $this->templateEditorOptions($template),
            'sections' => $template->sections->map(fn (ChecklistSection $section) => [
                'id' => $section->id,
                'key' => $section->key,
                'title' => $section->title,
                'sort_order' => $section->sort_order,
                'metadata' => $section->metadata,
                'items' => $section->items->map(fn (ChecklistItem $item) => [
                    'id' => $item->id,
                    'key' => $item->key,
                    'prompt' => $item->prompt,
                    'sort_order' => $item->sort_order,
                    'metadata' => $item->metadata,
                    'is_active' => (bool) $item->is_active,
                    'active_slots' => $item->metadata['active_slots'] ?? null,
                ])->values()->all(),
            ])->values()->all(),
        ];
    }

    private function submissionResource(
        ChecklistSubmission $submission,
        ?ChecklistTemplate $template = null
    ): array {
        $submission->loadMissing('responses');
        $responses = $submission->responses;

        if ($template !== null && $template->relationLoaded('sections')) {
            $accessibleItemKeys = $template->sections
                ->flatMap->items
                ->pluck('key')
                ->all();
            $responses = $responses
                ->whereIn('item_key', $accessibleItemKeys)
                ->values();
        }

        return [
            'id' => $submission->id,
            'template_id' => $submission->checklist_template_id,
            'status' => $submission->status,
            'branch' => $submission->branch,
            'audit_date' => $submission->audit_date->toDateString(),
            'template_version' => $submission->template_version,
            'context' => $submission->context,
            'scores' => $submission->scores,
            'submitted_by_user_id' => $submission->submitted_by_user_id,
            'submitted_by' => $submission->submitted_by_user_id || $submission->submitted_by_name
                ? [
                    'id' => $submission->submitted_by_user_id,
                    'name' => $submission->submitted_by_name,
                    'email' => $submission->submitted_by_email,
                    'user_type' => $submission->submitted_by_user_type,
                    'user_type_label' => User::roleLabelFor($submission->submitted_by_user_type),
                ]
                : null,
            'submitted_at' => $submission->submitted_at?->toISOString(),
            'updated_at' => $submission->updated_at?->toISOString(),
            'responses' => (object) $responses->mapWithKeys(fn (ChecklistResponse $response) => [
                $response->item_key => [
                    'id' => $response->id,
                    'item_id' => $response->checklist_item_id,
                    'item_key' => $response->item_key,
                    'status' => $response->status,
                    'remark' => $response->remark,
                    'finding' => $response->finding,
                    'action_plan' => $response->action_plan,
                    'escalation_target' => $this->responseEscalationTarget($response),
                    'escalation' => $this->responseEscalationTarget($response),
                    'commitment_date' => $response->commitment_date?->format('Y-m-d\TH:i:s'),
                    'details' => $this->normalizedResponseDetails(
                        $response->details ?? [],
                        $this->responseEscalationTarget($response)
                    ),
                    'attachment_path' => $response->attachment_path,
                    'attachment_url' => $this->attachmentUrl($response->attachment_path),
                    'item_snapshot' => $response->item_snapshot,
                ],
            ])->all(),
        ];
    }

    private function loadTemplate(
        ChecklistTemplate $template,
        ?User $user = null
    ): ChecklistTemplate {
        $isAdmin = $user?->hasAdministrativeAccess() === true
            || $user?->roleCode() === User::ROLE_BRANCH_OPERATIONS_MANAGER;

        $template->load([
            'sections' => fn ($query) => $query
                ->where('is_active', true)
                ->orderBy('sort_order'),
            'sections.items' => fn ($query) => $query
                ->when($isAdmin, fn ($q) => $q->where(fn ($sub) => $sub->whereNull('metadata->deleted')->orWhere('metadata->deleted', false)))
                ->when(! $isAdmin, fn ($q) => $q->where('is_active', true))
                ->orderBy('sort_order'),
        ]);

        if ($user !== null) {
            $template->retainAccessibleItemsFor($user);
        }

        return $template;
    }

    private function latestSubmission(
        ChecklistTemplate $template,
        string $date,
        string $scopeKey,
        ?int $userId
    ): ?ChecklistSubmission {
        $base = fn () => ChecklistSubmission::query()
            ->where('checklist_template_id', $template->id)
            ->whereDate('audit_date', $date)
            ->where('scope_key', $scopeKey)
            ->where('user_id', $userId)
            ->with('responses');

        return $base()->where('status', 'draft')->latest('updated_at')->first()
            ?? $base()->where('status', 'submitted')->latest('submitted_at')->first();
    }

    private function draftQuery(
        ChecklistTemplate $template,
        string $date,
        string $scopeKey,
        ?int $userId
    ) {
        return ChecklistSubmission::query()
            ->where('checklist_template_id', $template->id)
            ->whereDate('audit_date', $date)
            ->where('scope_key', $scopeKey)
            ->where('user_id', $userId)
            ->where('status', 'draft');
    }

    private function resolveBranch(Request $request, array $data): ?string
    {
        $branch = $data['branch']
            ?? data_get($data, 'context.outlet')
            ?? $request->user()?->branch;
        $branch = is_string($branch) ? trim($branch) : null;

        return $branch !== '' ? $branch : null;
    }

    private function scopeKey(?string $branch): string
    {
        return hash('sha256', Str::lower($branch ?? 'unassigned'));
    }

    private function authorizeBranch(Request $request, ?string $branch): void
    {
        $user = $request->user();
        if (! $user || $this->hasAdministrativeAccess($request)) {
            return;
        }

        abort_unless(
            Str::lower(trim((string) $user->branch)) === Str::lower(trim((string) $branch)),
            403,
            'You can only manage checklists for your assigned branch.'
        );
    }

    private function authorizeChecklist(Request $request, ChecklistTemplate $template): void
    {
        abort_unless(
            $request->user()?->canAccessChecklist($template->slug) === true,
            403,
            'This checklist is not assigned to your PIC account.'
        );
    }

    private function ensureCanManageTemplates(Request $request): void
    {
        abort_unless(
            $this->hasAdministrativeAccess($request),
            403,
            'Only a compliance administrator can update checklist templates.'
        );
    }

    private function hasAdministrativeAccess(Request $request): bool
    {
        $user = $request->user();
        if (! $user) {
            return false;
        }

        return $user->hasAdministrativeAccess() === true
            || $user->roleCode() === User::ROLE_BRANCH_OPERATIONS_MANAGER;
    }

    private function timeSlotKeys(ChecklistTemplate $template): array
    {
        return collect($template->settings['time_slots'] ?? [])
            ->map(fn ($slot) => is_array($slot) ? ($slot['key'] ?? null) : $slot)
            ->filter(fn ($slot) => is_string($slot) && $slot !== '')
            ->values()
            ->all();
    }

    private function statusFromSlots(array $slots): ?string
    {
        if (! $slots) {
            return null;
        }

        foreach ($slots as $mark) {
            if ($this->isValidSlotMark($mark) && ! $this->isGoodSlotMark($mark)) {
                return 'no';
            }
        }

        return collect($slots)->every(fn ($mark) => $this->isGoodSlotMark($mark)) ? 'yes' : null;
    }

    private function isValidSlotMark(mixed $mark): bool
    {
        return in_array(Str::lower(trim((string) $mark)), ['/', 'x', 'good', 'not_good', 'na'], true);
    }

    private function isGoodSlotMark(mixed $mark): bool
    {
        return in_array(Str::lower(trim((string) $mark)), ['/', 'good'], true);
    }

    private function trimmedOrNull(mixed $value): ?string
    {
        if (! is_string($value)) {
            return null;
        }

        $value = trim($value);

        return $value !== '' ? $value : null;
    }

    private function normalizeCommitmentDateTime(mixed $value): mixed
    {
        if ($value === null || (is_string($value) && trim($value) === '')) {
            return null;
        }

        if (! is_string($value)) {
            return $value;
        }

        $value = trim($value);
        $formats = [
            '!Y-m-d',
            '!Y-m-d H:i',
            '!Y-m-d H:i:s',
            '!Y-m-d\TH:i',
            '!Y-m-d\TH:i:s',
        ];

        foreach ($formats as $format) {
            try {
                $date = CarbonImmutable::createFromFormat($format, $value, config('app.timezone'));

                if ($date !== false && $date->format(ltrim($format, '!')) === $value) {
                    return $date->format('Y-m-d H:i:s');
                }
            } catch (\Throwable) {
                // Let validation return the field-specific error below.
            }
        }

        return $value;
    }

    private function normalizeEscalationTarget(mixed $value): mixed
    {
        return ChecklistResponse::normalizeEscalationTarget($value);
    }

    private function normalizedResponseDetails(mixed $details, mixed $escalationTarget): mixed
    {
        if (! is_array($details)) {
            return $details;
        }

        unset($details['escalation_target']);
        $target = $this->normalizeEscalationTarget($escalationTarget);

        if ($target === null) {
            unset($details['escalation']);
        } else {
            $details['escalation'] = $target;
        }

        return $details ?: null;
    }

    private function responseEscalationTarget(ChecklistResponse $response): mixed
    {
        return $this->normalizeEscalationTarget($this->firstFilledValue([
            $response->escalation_target,
            is_array($response->details) ? ($response->details['escalation_target'] ?? null) : null,
            is_array($response->details) ? ($response->details['escalation'] ?? null) : null,
        ]));
    }

    private function firstFilledValue(array $values): mixed
    {
        foreach ($values as $value) {
            if (! blank($value)) {
                return $value;
            }
        }

        return null;
    }

    private function attachmentUrl(?string $path): ?string
    {
        if (! $path) {
            return null;
        }

        return asset('storage/'.ltrim($path, '/'));
    }

    private function isSlotInFuture(string $date, string $slotKey, ?string $clientTime = null): bool
    {
        $timezone = env('GAC_REPORT_TIMEZONE', 'Asia/Manila');
        $now = now($timezone);
        $today = $now->format('Y-m-d');

        if ($clientTime) {
            try {
                $clientDt = CarbonImmutable::parse($clientTime, $timezone);
                if ($clientDt->format('Y-m-d') === $date) {
                    $now = $clientDt;
                    $today = $date;
                } elseif ($clientDt->isSameDay($now) && $clientDt->greaterThan($now)) {
                    $now = $clientDt;
                    $today = $now->format('Y-m-d');
                }
            } catch (\Throwable) {
                // Ignore parse errors
            }
        }

        if ($date < $today) {
            return false;
        }
        if ($date > $today) {
            return true;
        }

        $parts = explode(':', trim($slotKey));
        $slotHour = (int) ($parts[0] ?? 0);
        $slotMinute = (int) ($parts[1] ?? 0);
        $slotMinutes = $slotHour * 60 + $slotMinute;

        $nowMinutes = ((int) $now->format('H')) * 60 + (int) $now->format('i');

        // A time slot is in the future if its scheduled start time has not arrived yet.
        return $slotMinutes > $nowMinutes;
    }
}
