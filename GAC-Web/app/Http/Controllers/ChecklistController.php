<?php

namespace App\Http\Controllers;

use App\Models\ChecklistItem;
use App\Models\ChecklistResponse;
use App\Models\ChecklistSection;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\Report;
use App\Models\User;
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
            'dealer-operations', 'dos' => 'dealer-operations-standards',
            'gateway-5s', '5s' => 'sales',
            'utilities' => 'restroom',
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
                $created = true;
                $submission = new ChecklistSubmission;
                $submission->checklist_template_id = $template->id;
                $submission->status = 'draft';
                $submission->scope_key = $scopeKey;
                $submission->audit_date = $data['date'];
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

            return $submission->fresh('responses');
        });

        return response()->json([
            'message' => 'Checklist draft saved.',
            'submission' => $this->submissionResource($submission, $template),
        ], $created ? 201 : 200);
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

                $submission = new ChecklistSubmission([
                    'checklist_template_id' => $lockedTemplate->id,
                    'status' => 'draft',
                    'scope_key' => $scopeKey,
                    'audit_date' => $data['date'],
                ]);
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
            $this->validateCompleteSubmission($lockedTemplate, $responses, $submission);
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
            $report = Report::create([
                'checklist_submission_id' => $submission->id,
                'checklist_template_id' => $lockedTemplate->id,
                'generated_by_user_id' => $request->user()?->id,
                'type' => 'checklist_submission',
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
            ]);

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
                    'dealer-operations', 'dos' => 'dealer-operations-standards',
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

            $targetTemplates = collect([$matched]);
        } else {
            $targetTemplates = ChecklistTemplate::all();
        }

        $date = trim((string) ($validated['date'] ?? ''));
        $branch = trim((string) ($validated['branch'] ?? ''));
        $scope = trim((string) ($validated['scope'] ?? 'all'));

        $templateIds = $targetTemplates->pluck('id')->all();

        $stats = DB::transaction(function () use ($templateIds, $templateInput, $date, $branch, $scope): array {
            $submissionQuery = ChecklistSubmission::query();

            if ($templateInput !== 'all') {
                $submissionQuery->whereIn('checklist_template_id', $templateIds);
            }

            if ($scope === 'current') {
                if ($date !== '' && $date !== 'all') {
                    $submissionQuery->whereDate('audit_date', $date);
                }
                if ($branch !== '' && $branch !== 'all') {
                    $submissionQuery->where('branch', $branch);
                }
            } elseif ($date !== '' && $date !== 'all') {
                $submissionQuery->whereDate('audit_date', $date);
            }

            $submissions = $submissionQuery->lockForUpdate()->get();
            $submissionIds = $submissions->pluck('id')->all();

            $deletedResponsesCount = 0;
            $deletedSubmissionsCount = count($submissionIds);
            $deletedReportsCount = 0;

            if ($deletedSubmissionsCount > 0) {
                $deletedResponsesCount = ChecklistResponse::query()
                    ->whereIn('checklist_submission_id', $submissionIds)
                    ->delete();

                $deletedReportsCount = Report::query()
                    ->whereIn('checklist_submission_id', $submissionIds)
                    ->delete();

                ChecklistSubmission::query()
                    ->whereIn('id', $submissionIds)
                    ->delete();
            }

            $templatesCount = ChecklistTemplate::query()->count();
            $sectionsCount = ChecklistSection::query()->count();
            $itemsCount = ChecklistItem::query()->count();

            return [
                'deleted_submissions' => $deletedSubmissionsCount,
                'deleted_responses' => $deletedResponsesCount,
                'deleted_reports' => $deletedReportsCount,
                'templates_preserved' => true,
                'preserved_counts' => [
                    'templates' => $templatesCount,
                    'sections' => $sectionsCount,
                    'items' => $itemsCount,
                ],
            ];
        });

        $templateLabel = $templateInput === 'all'
            ? 'All checklists'
            : ($targetTemplates->first()?->name ?? $templateInput);

        return response()->json([
            'message' => "Checklist answers for {$templateLabel} have been successfully reset. Master templates, sections, and items were safely preserved.",
            'template' => $templateInput,
            'stats' => $stats,
        ]);
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
        $input = $this->normalizeTemplateInput($request->all());

        $validator = Validator::make($input, [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'settings' => ['sometimes', 'nullable', 'array'],
            'sections' => ['required', 'array', 'min:1'],
            'sections.*.key' => ['required', 'string', 'max:100', 'distinct'],
            'sections.*.title' => ['required', 'string', 'max:255'],
            'sections.*.metadata' => ['nullable', 'array'],
            'sections.*.items' => ['required', 'array'],
            'sections.*.items.*.key' => ['required', 'string', 'max:100', 'distinct'],
            'sections.*.items.*.prompt' => ['required', 'string'],
            'sections.*.items.*.metadata' => ['nullable', 'array'],
        ]);

        $validator->after(function ($validator) use ($input): void {
            $sectionKeys = [];
            $itemKeys = [];

            foreach ($input['sections'] ?? [] as $sectionIndex => $section) {
                if (! is_array($section)) {
                    continue;
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

                foreach ($section['items'] ?? [] as $itemIndex => $item) {
                    if (! is_array($item)) {
                        continue;
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

        $data = $validator->validate();

        $template = DB::transaction(function () use ($template, $data): ChecklistTemplate {
            $template = ChecklistTemplate::query()->lockForUpdate()->findOrFail($template->id);
            $template->fill(Arr::only($data, ['name', 'description', 'settings']));
            $template->version++;
            $template->save();

            $keptSectionIds = [];
            $keptItemIds = [];

            foreach ($data['sections'] as $sectionOrder => $sectionData) {
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

                foreach ($sectionData['items'] as $itemOrder => $itemData) {
                    $item = ChecklistItem::query()->updateOrCreate([
                        'checklist_template_id' => $template->id,
                        'key' => $itemData['key'],
                    ], [
                        'checklist_section_id' => $section->id,
                        'prompt' => trim($itemData['prompt']),
                        'sort_order' => $itemOrder,
                        'metadata' => $itemData['metadata'] ?? null,
                        'is_active' => true,
                    ]);
                    $keptItemIds[] = $item->id;
                }
            }

            $template->items()->whereNotIn('id', $keptItemIds)->update(['is_active' => false]);
            $template->sections()->whereNotIn('id', $keptSectionIds)->update(['is_active' => false]);

            return $this->loadTemplate($template->fresh());
        });

        return response()->json([
            'message' => 'Checklist template updated.',
            'template' => $this->templateResource($template),
        ]);
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

        return view($view, [
            'template' => $templateData,
            'submission' => $submissionData,
            'branches' => $branches,
            'canManageTemplate' => $canManageTemplate,
            'checklistBootstrap' => [
                'template' => $templateData,
                'submission' => $submissionData,
                'date' => $date,
                'branch' => $branch,
                'branches' => $branches,
                'can_manage_template' => $canManageTemplate,
            ],
            ...$viewData,
        ]);
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

        $validator->after(function ($validator) use ($input, $template): void {
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
                foreach ($input['responses'] ?? [] as $index => $response) {
                    $slots = $response['details']['slots'] ?? [];
                    if (is_array($slots)) {
                        foreach ($slots as $slotKey => $mark) {
                            if ($mark !== null && $mark !== '' && $this->isSlotInFuture($date, (string) $slotKey)) {
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

    private function normalizeTemplateInput(array $input): array
    {
        foreach ($input['sections'] ?? [] as &$section) {
            if (! is_array($section)) {
                continue;
            }
            $section['key'] ??= is_string($section['id'] ?? null) ? $section['id'] : null;
            if (is_string($section['key'])) {
                $section['key'] = Str::lower(trim($section['key']));
            }
            $section['metadata'] ??= null;

            foreach ($section['items'] ?? [] as &$item) {
                if (! is_array($item)) {
                    continue;
                }
                $item['key'] ??= is_string($item['id'] ?? null) ? $item['id'] : null;
                if (is_string($item['key'])) {
                    $item['key'] = Str::lower(trim($item['key']));
                }
                $item['prompt'] ??= $item['text'] ?? $item['checkItem'] ?? null;
                $metadata = is_array($item['metadata'] ?? null) ? $item['metadata'] : [];
                foreach ([
                    'number',
                    'level',
                    'category',
                    'coverage',
                    'subject',
                    'checker',
                    'pic',
                    'bom_task',
                    'escalation',
                    'how_to_check',
                    'response_type',
                ] as $field) {
                    if (array_key_exists($field, $item)) {
                        $metadata[$field] = $item[$field];
                    }
                }
                $item['metadata'] = $metadata ?: null;
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
        ?ChecklistSubmission $submission = null
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
                foreach ($this->timeSlotKeys($template) as $slot) {
                    if ($this->isSlotInFuture($auditDateStr, $slot)) {
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
            foreach ($items as $item) {
                $slots = $responsesByKey->get($item->key)?->details['slots'] ?? [];
                foreach ($this->timeSlotKeys($template) as $slot) {
                    if (! array_key_exists($slot, $slots) || ! $this->isValidSlotMark($slots[$slot])) {
                        continue;
                    }
                    $this->isGoodSlotMark($slots[$slot]) ? $good++ : $bad++;
                }
            }
            $slotTotal = $items->count() * count($this->timeSlotKeys($template));
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
            'responses' => $responses->mapWithKeys(fn (ChecklistResponse $response) => [
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
        $template->load([
            'sections' => fn ($query) => $query
                ->where('is_active', true)
                ->orderBy('sort_order'),
            'sections.items' => fn ($query) => $query
                ->where('is_active', true)
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
        return $request->user()?->hasAdministrativeAccess() === true;
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
        return in_array(Str::lower(trim((string) $mark)), ['/', 'x', 'good', 'not_good'], true);
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

    private function isSlotInFuture(string $date, string $slotKey): bool
    {
        $timezone = env('GAC_REPORT_TIMEZONE', 'Asia/Manila');
        $now = now($timezone);
        $today = $now->format('Y-m-d');
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

        return $slotMinutes > $nowMinutes;
    }
}
