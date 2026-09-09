@php
    $bootstrapData = isset($checklistBootstrap)
        ? (is_array($checklistBootstrap) ? $checklistBootstrap : json_decode(json_encode($checklistBootstrap), true))
        : [];
    $templateSource = $template ?? data_get($bootstrapData, 'template', []);
    $submissionSource = $submission ?? data_get($bootstrapData, 'submission');
    $templateData = (is_array($templateSource) ? $templateSource : json_decode(json_encode($templateSource), true)) ?: [];
    $submissionData = $submissionSource
        ? (is_array($submissionSource) ? $submissionSource : json_decode(json_encode($submissionSource), true))
        : null;
    $branchSource = $branches ?? data_get($bootstrapData, 'branches', []);
    $branchData = (is_array($branchSource) ? $branchSource : json_decode(json_encode($branchSource), true)) ?: [];
    $templateSlug = (string) data_get($templateData, 'slug', '');
    $templateName = (string) data_get($templateData, 'name', $pageTitle);
    $templateDescription = (string) data_get($templateData, 'description', '');
    $templateInstructions = (string) data_get(
        $templateData,
        'instructions',
        data_get($templateData, 'settings.instructions', '')
    );
    $canManageTemplate = (bool) ($canManageTemplate
        ?? data_get(
            $bootstrapData,
            'can_manage_template',
            Auth::user()?->hasAdministrativeAccess() === true
        ));

    $resolveChecklistRoute = static function (array $names) use ($templateSlug): ?string {
        if ($templateSlug === '') {
            return null;
        }

        foreach ($names as $name) {
            if (\Illuminate\Support\Facades\Route::has($name)) {
                return route($name, [$templateSlug]);
            }
        }

        return null;
    };

    $loadUrl = $resolveChecklistRoute(['checklists.load', 'checklists.submission.show']);
    $draftUrl = $resolveChecklistRoute(['checklists.save-draft', 'checklists.draft', 'checklists.submission.store']);
    $submitUrl = $resolveChecklistRoute(['checklists.submit', 'checklists.submission.store']);
    $resetUrl = $resolveChecklistRoute(['checklists.reset', 'checklists.submission.destroy']);
    $templateUrl = $resolveChecklistRoute(['checklists.template.update', 'checklists.update-template']);
    $initialDate = (string) data_get(
        $submissionData,
        'audit_date',
        data_get($submissionData, 'date', data_get($bootstrapData, 'date', now()->toDateString()))
    );
    $initialBranch = (string) data_get(
        $submissionData,
        'branch',
        data_get($bootstrapData, 'branch', Auth::user()->branch ?? '')
    );
    $workspaceData = collect($checklistWorkspace ?? [])->map(
        fn ($option) => is_array($option) ? $option : json_decode(json_encode($option), true)
    )->all();
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#F5F6F8">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Gateway Audit Compliance | Checklists - {{ $pageTitle }}</title>
    <link rel="icon" type="image/png" href="{{ asset('images/G-logo-no-bg.png') }}">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css">
    <link rel="stylesheet" href="{{ asset($stylesheet) }}">
    <link rel="stylesheet" href="{{ asset('css/gateway-theme.css') }}">
    <style>
        .database-checklist .filters { grid-template-columns: minmax(190px, 1fr) minmax(170px, .7fr) minmax(220px, 1fr) auto; }
        .database-checklist .template-chip { min-height: 39px; display: flex; align-items: center; padding: 8px 10px; border: 1px solid var(--line-dark); border-radius: 6px; background: var(--fog-100); font-size: 11px; font-weight: 750; }
        .database-checklist .database-status { min-width: 122px; justify-self: end; text-align: right; color: var(--slate-600); font-size: 10px; font-weight: 800; }
        .database-checklist .item-copy { display: grid; gap: 7px; }
        .database-checklist .item-title-row { min-width: 0; display: flex; align-items: flex-start; gap: 8px; }
        .database-checklist .item-title-row .item-text { min-width: 0; flex: 1 1 auto; }
        .database-checklist .how-to-check-button { width: 24px; height: 24px; flex: 0 0 24px; display: inline-grid; place-items: center; padding: 0; border: 1px solid var(--line-dark); border-radius: 50%; color: var(--gateway-red-500); background: #fff; font: 800 12px/1 Georgia, serif; cursor: pointer; transition: border-color 150ms ease, background 150ms ease, color 150ms ease, box-shadow 150ms ease; }
        .database-checklist .how-to-check-button:hover { border-color: var(--gateway-red-500); color: #fff; background: var(--gateway-red-500); }
        .database-checklist .how-to-check-button:focus-visible { border-color: var(--gateway-red-500); outline: 0; box-shadow: 0 0 0 3px rgba(227, 28, 61, .16); }
        .database-checklist .item-description { margin: 0; color: var(--slate-600); font-size: 10px; line-height: 1.5; white-space: pre-line; }
        .database-checklist .response-fields { display: grid; gap: 7px; }
        .database-checklist .response-fields textarea { width: 100%; min-height: 48px; resize: vertical; }
        .database-checklist .response-fields label { display: grid; gap: 4px; color: var(--slate-600); font-size: 8px; font-weight: 850; letter-spacing: .05em; text-transform: uppercase; }
        .database-checklist .response-fields :is(input, select) { width: 100%; }
        .database-checklist .escalation-input { min-height: 39px; padding: 8px 10px; border: 1px solid var(--line-dark); border-radius: 6px; outline: 0; color: var(--graphite-900); background: #fff; font-size: 11px; }
        .database-checklist .escalation-input:focus { border-color: var(--gateway-red-500); box-shadow: 0 0 0 3px rgba(227, 28, 61, .12); }
        .database-checklist .response-fields .photo-attachment-label { display: inline-flex; align-items: center; gap: 5px; width: max-content; max-width: 100%; color: var(--gateway-red-500); font-size: 10px; font-weight: 750; letter-spacing: 0; text-transform: none; cursor: pointer; }
        .database-checklist .section-empty { padding: 24px; color: var(--slate-600); text-align: center; }
        .database-checklist .loading-mask { padding: 16px; color: var(--slate-600); text-align: center; }
        .database-checklist [hidden] { display: none !important; }
        .database-checklist .restroom-scroll { overflow-x: auto; }
        .database-checklist .restroom-table { width: 100%; min-width: 980px; border-collapse: collapse; background: #fff; }
        .database-checklist .restroom-table th,
        .database-checklist .restroom-table td { padding: 9px; border-right: 1px solid var(--line); border-bottom: 1px solid var(--line); vertical-align: middle; }
        .database-checklist .restroom-table th:first-child { min-width: 300px; text-align: left; }
        .database-checklist .restroom-table th:last-child { min-width: 210px; }
        .database-checklist .restroom-table .slot-cell { min-width: 82px; text-align: center; }
        .database-checklist .restroom-table tbody th .item-text { text-transform: lowercase; }
        .database-checklist .restroom-table tbody th .item-text::first-letter { text-transform: uppercase; }
        .database-checklist .checklist-workspace-header { min-width: 0; display: flex; align-items: center; gap: 14px; margin-bottom: 16px; }
        .database-checklist .checklist-workspace-switcher { min-width: 0; display: flex; align-items: stretch; flex: 1 1 auto; gap: 4px; margin: 0; padding: 4px; overflow-x: auto; overscroll-behavior-inline: contain; border: 1px solid #e7edf3; border-radius: 8px !important; background: #fff; box-shadow: none; scrollbar-width: thin; }
        .database-checklist .checklist-workspace-option { min-width: max-content; min-height: 36px; flex: 1 0 auto; display: inline-flex; align-items: center; justify-content: center; padding: 7px 11px; border: 1px solid transparent; border-radius: 6px !important; color: #526176; font-size: 10px; font-weight: 800; line-height: 1.35; text-align: center; text-decoration: none; white-space: nowrap; transition: background 150ms ease, color 150ms ease, border-color 150ms ease; }
        .database-checklist .checklist-workspace-option > i { display: none; }
        .database-checklist .checklist-workspace-option:hover,
        .database-checklist .checklist-workspace-option.is-active { border-color: rgba(232, 25, 63, .34); color: #122033; background: rgba(232, 25, 63, .1); box-shadow: none; }
        .database-checklist .checklist-page-heading { display: flex; align-items: center; justify-content: space-between; gap: 18px; margin-bottom: 15px; padding: 18px 20px; border: 1px solid rgba(138, 148, 166, .28); border-left: 4px solid var(--gateway-red-500); background: #fff; box-shadow: 0 2px 10px rgba(11, 15, 26, .055); }
        .database-checklist .checklist-editor-actions { width: auto; flex: 0 0 auto; margin: 0; }
        .database-checklist .slot-select { min-height: 34px; width: 100%; padding: 5px; border: 1px solid var(--line-dark); border-radius: 6px; background: #fff; font-size: 9px; font-weight: 800; }
        .database-checklist .slot-select.is-good { border-color: var(--success); color: var(--success); background: var(--success-soft); }
        .database-checklist .slot-select.is-not-good { border-color: var(--danger); color: var(--danger); background: var(--danger-soft); }
        .database-checklist .restroom-remark { width: 100%; min-height: 48px; resize: vertical; }
        .database-checklist .template-editor-dialog { width: min(1050px, calc(100vw - 32px)); max-height: 90vh; padding: 0; border: 0; border-radius: 12px; box-shadow: 0 24px 80px rgba(11, 15, 26, .28); }
        .database-checklist .template-editor-dialog::backdrop { background: rgba(11, 15, 26, .62); }
        .database-checklist .how-to-check-dialog { width: min(620px, calc(100vw - 32px)); max-height: min(82vh, 720px); padding: 0; overflow: hidden; border: 0; border-radius: 12px; color: var(--graphite-900); background: #fff; box-shadow: 0 24px 80px rgba(11, 15, 26, .28); }
        .database-checklist .how-to-check-dialog::backdrop { background: rgba(11, 15, 26, .62); }
        .database-checklist .how-to-check-shell { max-height: min(82vh, 720px); display: grid; grid-template-rows: auto minmax(0, 1fr) auto; }
        .database-checklist .how-to-check-header,
        .database-checklist .how-to-check-footer { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 14px 18px; border-bottom: 1px solid var(--line); }
        .database-checklist .how-to-check-header h3 { margin: 0; font-size: 16px; }
        .database-checklist .how-to-check-body { overflow: auto; padding: 18px; }
        .database-checklist .how-to-check-item { margin: 0 0 12px; color: var(--graphite-800); font-size: 12px; line-height: 1.5; white-space: pre-line; }
        .database-checklist .how-to-check-guidance { margin: 0; padding: 14px; border: 1px solid var(--line); border-left: 4px solid var(--gateway-red-500); border-radius: 8px; color: var(--slate-600); background: var(--fog-100); font-size: 12px; line-height: 1.65; white-space: pre-line; }
        .database-checklist .how-to-check-footer { justify-content: flex-end; border-top: 1px solid var(--line); border-bottom: 0; }
        .database-checklist .template-editor-shell { max-height: 90vh; display: grid; grid-template-rows: auto minmax(0, 1fr) auto; background: #fff; }
        .database-checklist .template-editor-header,
        .database-checklist .template-editor-footer { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 15px 18px; border-bottom: 1px solid var(--line); }
        .database-checklist .template-editor-footer { justify-content: flex-end; border-top: 1px solid var(--line); border-bottom: 0; }
        .database-checklist .template-editor-header h3 { margin: 0; font-size: 16px; }
        .database-checklist .template-editor-body { overflow: auto; padding: 18px; }
        .database-checklist .editor-template-fields { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; margin-bottom: 18px; }
        .database-checklist .editor-template-fields .wide { grid-column: 1 / -1; }
        .database-checklist .editor-section { margin-bottom: 14px; padding: 14px; border: 1px solid var(--line); border-radius: 9px; background: var(--fog-100); }
        .database-checklist .editor-section-head { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 9px; margin-bottom: 10px; }
        .database-checklist .editor-item { display: grid; grid-template-columns: 110px minmax(160px, .75fr) minmax(240px, 1.4fr) 110px 150px 150px auto; gap: 7px; align-items: start; margin-top: 8px; }
        .database-checklist .editor-item textarea { min-height: 62px; resize: vertical; }
        .database-checklist .editor-remove { min-width: 36px; padding-inline: 9px; }
        .database-checklist .editor-add-row { margin-top: 10px; }
        @media (max-width: 1100px) {
            .database-checklist .filters { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .database-checklist .editor-item { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }
        @media (max-width: 900px) {
            .database-checklist .checklist-workspace-header { align-items: stretch; flex-direction: column; }
            .database-checklist .checklist-workspace-switcher { width: 100%; }
        }
        @media (max-width: 680px) {
            .database-checklist .filters,
            .database-checklist .editor-template-fields,
            .database-checklist .editor-item { grid-template-columns: 1fr; }
            .database-checklist .database-status { justify-self: start; text-align: left; }
            .database-checklist .checklist-page-heading { align-items: stretch; flex-direction: column; padding: 15px; }
            .database-checklist .checklist-editor-actions { width: 100%; justify-content: stretch; }
            .database-checklist .checklist-editor-actions .button { flex: 1 1 auto; }
        }
        @media print {
            .database-checklist .checklist-editor-actions,
            .database-checklist .template-editor-dialog { display: none !important; }
            .database-checklist .restroom-table { min-width: 0; font-size: 7px; }
            .database-checklist .restroom-table th,
            .database-checklist .restroom-table td { padding: 3px; }
        }
    </style>
</head>
<body class="gateway-dashboard database-checklist {{ $bodyClass }}" data-checklist-variant="{{ $variant }}">
    @include('layouts.navigation')

    <div class="main-shell">
        @include('partials.app-topbar', [
            'topbarTitle' => $canManageTemplate ? 'Checklist Editor' : $pageTitle,
            'topbarSubtitle' => $pageSubtitle,
            'notificationId' => 'notificationsBtn',
            'notificationBadge' => (string) ($notificationBadgeCount ?? 0),
            'notificationBadgeId' => 'notificationsBadge',
        ])

        <main class="content">
            @if (! $canManageTemplate && $workspaceData !== [])
                <div class="checklist-workspace-header">
                    <nav class="checklist-workspace-switcher" aria-label="Select checklist" role="tablist">
                        @foreach ($workspaceData as $option)
                            <a href="{{ $option['url'] }}"
                               class="checklist-workspace-option{{ $option['selected'] ? ' is-active' : '' }}"
                               role="tab"
                               aria-selected="{{ $option['selected'] ? 'true' : 'false' }}"
                               @if ($option['selected']) aria-current="page" @endif>
                                <i class="fas {{ $option['icon'] }}" aria-hidden="true"></i>
                                <span>{{ $option['label'] }}</span>
                            </a>
                        @endforeach
                    </nav>
                </div>
            @endif

            <section class="page-heading checklist-page-heading">
                <div>
                    <span class="eyebrow"><span class="eyebrow-dot"></span>{{ $pageEyebrow }}</span>
                    <h2 id="pageChecklistName">{{ $templateName }}</h2>
                    @if ($templateDescription !== '')
                        <p id="pageChecklistDescription">{{ $templateDescription }}</p>
                    @endif
                </div>
                <div class="header-actions checklist-editor-actions">
                    <button class="button soft" id="printButton" type="button">
                        <i class="fas fa-print" aria-hidden="true"></i> Print
                    </button>
                    @if ($canManageTemplate)
                        <button class="button primary" id="editTemplateButton" type="button">
                            <i class="fas fa-pen-to-square" aria-hidden="true"></i> Edit Master Checklist
                        </button>
                    @endif
                </div>
            </section>

            <section class="stats-grid" aria-label="Checklist summary">
                <article class="stat-card">
                    <div class="stat-label">Compliance Score</div>
                    <div class="stat-value" id="scoreValue">0%</div>
                    <div class="stat-track"><span id="scoreBar"></span></div>
                    <div class="stat-meta"><span>Positive responses</span><strong id="scoreMeta">0 / 0</strong></div>
                </article>
                <article class="stat-card">
                    <div class="stat-label">Completion</div>
                    <div class="stat-value" id="completionValue">0%</div>
                    <div class="stat-track"><span id="completionBar"></span></div>
                    <div class="stat-meta"><span>Responses recorded</span><strong id="answeredCount">0 / 0</strong></div>
                </article>
                <article class="stat-card">
                    <div class="stat-label">Findings</div>
                    <div class="stat-value" id="findingsValue">0</div>
                    <div class="stat-track"><span id="findingsBar"></span></div>
                    <div class="stat-meta"><span>Items needing attention</span><strong id="findingsMeta">Clear</strong></div>
                </article>
                <article class="stat-card">
                    <div class="stat-label">Database Template</div>
                    <div class="stat-value" id="itemCountValue">0</div>
                    <div class="stat-track"><span style="width:100%"></span></div>
                    <div class="stat-meta"><span>Active items</span><strong id="sectionCountValue">0 sections</strong></div>
                </article>
            </section>

            <section class="panel filters" aria-label="Checklist details">
                <div class="field">
                    <label for="branchSelect">Branch</label>
                    <select id="branchSelect" autocomplete="organization">
                        @forelse ($branchData as $branch)
                            @php
                                $branchValue = is_scalar($branch)
                                    ? (string) $branch
                                    : (string) data_get($branch, 'name', data_get($branch, 'branch', data_get($branch, 'label', '')));
                            @endphp
                            @if ($branchValue !== '')
                                <option value="{{ $branchValue }}" @selected($branchValue === $initialBranch)>{{ $branchValue }}</option>
                            @endif
                        @empty
                            @if ($initialBranch !== '')
                                <option value="{{ $initialBranch }}">{{ $initialBranch }}</option>
                            @else
                                <option value="">No branch assigned</option>
                            @endif
                        @endforelse
                    </select>
                </div>
                <div class="field">
                    <label for="auditDate">Checklist Date</label>
                    <input id="auditDate" type="date" value="{{ $initialDate }}">
                </div>
                <div class="field">
                    <label>Checklist Template</label>
                    <div class="template-chip" id="templateChip">{{ $templateName }}</div>
                </div>
                <div class="database-status" id="recordStatus" role="status">Loading database record…</div>
            </section>

            @if ($templateInstructions !== '')
                <section class="notice" aria-label="Checklist instructions">
                    <div class="notice-icon"><i class="fas fa-info" aria-hidden="true"></i></div>
                    <div>
                        <strong>Checklist instructions</strong>
                        <p id="checklistInstructions">{{ $templateInstructions }}</p>
                    </div>
                </section>
            @endif

            <section class="panel {{ $variant === 'dos' ? 'audit-panel' : 'checklist-panel' }}" aria-labelledby="checklistHeading">
                <div class="{{ $variant === 'dos' ? 'audit-toolbar' : 'checklist-toolbar' }}">
                    <div class="{{ $variant === 'dos' ? 'audit-title' : 'checklist-title' }}">
                        <h3 id="checklistHeading">{{ $templateName }} <span class="mode-badge" id="modeBadge">Database form</span></h3>
                        <p>Checklist sections and items are loaded from the GAC database.</p>
                    </div>
                    <div class="toolbar-actions">
                        <button class="button soft" id="resetResponsesButton" type="button">Reset</button>
                        <button class="button" id="saveDraftButton" type="button">Save Draft</button>
                        <button class="button primary" id="submitButton" type="button">Submit</button>
                    </div>
                </div>

                <div class="audit-filters" id="auditFilters" @if ($variant === 'restroom') hidden @endif>
                    <input class="filter-control" id="searchInput" type="search" placeholder="Search checklist items…">
                    <select class="filter-control" id="sectionFilter"><option value="all">All sections</option></select>
                    <select class="filter-control" id="levelFilter"><option value="all">All levels</option></select>
                    <div class="showing-count" id="showingCount">Loading items…</div>
                </div>

                <div class="column-headings" aria-hidden="true" @if ($variant === 'restroom') hidden @endif>
                    <div>No.</div>
                    <div>Checklist Item</div>
                    <div>Response</div>
                    <div>Remarks / Corrective Action</div>
                    <div></div>
                </div>

                <div id="checklistContainer"><div class="loading-mask">Loading checklist…</div></div>

                <div class="{{ $variant === 'dos' ? 'audit-footer' : 'checklist-footer' }}">
                    <div class="footer-summary" id="footerSummary">Select a branch and date to load a database record.</div>
                    <div class="footer-actions">
                        <button class="button soft" id="scrollTopButton" type="button">Back to Top</button>
                        <button class="button primary" id="footerSubmitButton" type="button">Submit</button>
                    </div>
                </div>
            </section>
        </main>
    </div>

    @if ($variant === 'dos')
        <dialog class="how-to-check-dialog" id="howToCheckDialog" aria-labelledby="howToCheckTitle" aria-describedby="howToCheckGuidance">
            <div class="how-to-check-shell">
                <div class="how-to-check-header">
                    <h3 id="howToCheckTitle">How to Check</h3>
                    <button class="button soft" id="closeHowToCheck" type="button" aria-label="Close How to Check dialog">
                        <i class="fas fa-xmark" aria-hidden="true"></i>
                    </button>
                </div>
                <div class="how-to-check-body">
                    <p class="how-to-check-item" id="howToCheckItem"></p>
                    <p class="how-to-check-guidance" id="howToCheckGuidance"></p>
                </div>
                <div class="how-to-check-footer">
                    <button class="button primary" id="dismissHowToCheck" type="button">Close</button>
                </div>
            </div>
        </dialog>
    @endif

    @if ($canManageTemplate)
        <dialog class="template-editor-dialog" id="templateEditor" aria-labelledby="templateEditorTitle">
            <form class="template-editor-shell" id="templateEditorForm" method="dialog">
                <div class="template-editor-header">
                    <h3 id="templateEditorTitle">Edit Master Checklist</h3>
                    <button class="button soft" id="closeTemplateEditor" type="button" aria-label="Close editor"><i class="fas fa-xmark"></i></button>
                </div>
                <div class="template-editor-body">
                    <div class="editor-template-fields">
                        <div class="field"><label for="editorName">Template Name</label><input id="editorName" required></div>
                        <div class="field"><label for="editorShortName">Short Name</label><input id="editorShortName"></div>
                        <div class="field wide"><label for="editorDescription">Description</label><textarea id="editorDescription" rows="2"></textarea></div>
                        <div class="field wide"><label for="editorInstructions">Instructions</label><textarea id="editorInstructions" rows="3"></textarea></div>
                    </div>
                    <div id="editorSections"></div>
                    <button class="button" id="addEditorSection" type="button"><i class="fas fa-plus"></i> Add Section</button>
                </div>
                <div class="template-editor-footer">
                    <button class="button soft" id="cancelTemplateEditor" type="button">Cancel</button>
                    <button class="button primary" id="saveTemplateButton" type="button">Save Master Checklist</button>
                </div>
            </form>
        </dialog>
    @endif

    <div class="toast-region" id="toastRegion" aria-live="polite" aria-atomic="true"></div>

    <script>
        (() => {
            'use strict';

            const endpoints = Object.freeze({
                load: @json($loadUrl),
                draft: @json($draftUrl),
                submit: @json($submitUrl),
                reset: @json($resetUrl),
                template: @json($templateUrl),
            });
            const variant = @json($variant);
            const initialTemplate = {{ \Illuminate\Support\Js::from($templateData) }};
            const initialSubmission = {{ \Illuminate\Support\Js::from($submissionData) }};
            const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
            const container = document.getElementById('checklistContainer');
            const branchSelect = document.getElementById('branchSelect');
            const auditDate = document.getElementById('auditDate');
            const statusElement = document.getElementById('recordStatus');
            const toastRegion = document.getElementById('toastRegion');
            let template = normalizeTemplate(initialTemplate);
            let currentSubmission = initialSubmission;
            let loadController = null;
            let howToCheckReturnFocus = null;

            function asObject(value) {
                if (!value || typeof value !== 'object') return {};
                return value;
            }

            function parseObject(value) {
                if (value && typeof value === 'object') return value;
                if (typeof value !== 'string' || value.trim() === '') return {};
                try { return JSON.parse(value); } catch (_) { return {}; }
            }

            function escapeHTML(value) {
                return String(value ?? '')
                    .replaceAll('&', '&amp;')
                    .replaceAll('<', '&lt;')
                    .replaceAll('>', '&gt;')
                    .replaceAll('"', '&quot;')
                    .replaceAll("'", '&#039;');
            }

            function slug(value, fallback) {
                const normalized = String(value ?? '')
                    .toLowerCase()
                    .trim()
                    .replace(/[^a-z0-9]+/g, '-')
                    .replace(/^-|-$/g, '');
                return normalized || fallback;
            }

            function normalizeStatus(value) {
                const status = String(value ?? '').toLowerCase().replaceAll('/', '').replaceAll('_', '');
                if (['yes', 'good', 'pass', 'compliant'].includes(status)) return 'yes';
                if (['no', 'notgood', 'fail', 'noncompliant'].includes(status)) return 'no';
                if (['na', 'notapplicable'].includes(status)) return 'na';
                return '';
            }

            function normalizeEscalation(value) {
                const compact = String(value ?? '').trim().toLowerCase().replace(/[^a-z0-9]+/g, '');
                if (!compact) return '';
                if (compact === 'pm' || compact.includes('propertymanagement') || compact.includes('purchasingmanager')) return 'property_management';
                if (compact === 'gm' || compact.includes('generalmanager')) return 'general_manager';
                if (compact.includes('inventory')) return 'inventory';
                if (compact.includes('purchasing')) return 'purchasing';
                return '';
            }

            function normalizeDateTimeLocal(value) {
                const match = String(value ?? '').trim().match(/^(\d{4}-\d{2}-\d{2})(?:[T\s](\d{2}:\d{2}))?/);
                if (!match) return '';
                return `${match[1]}T${match[2] || '00:00'}`;
            }

            function normalizeTemplate(rawTemplate) {
                const raw = asObject(rawTemplate);
                const settings = asObject(raw.settings);
                const metadata = asObject(raw.metadata);
                const rawSlots = raw.time_slots ?? settings.time_slots ?? metadata.time_slots ?? [];
                const timeSlots = Array.isArray(rawSlots) ? rawSlots.map((slotValue, index) => {
                    const slotObject = asObject(slotValue);
                    const key = typeof slotValue === 'string'
                        ? slotValue
                        : String(slotObject.key ?? slotObject.value ?? slotObject.time ?? slotObject.label ?? index);
                    const label = typeof slotValue === 'string'
                        ? slotValue
                        : String(slotObject.label ?? slotObject.time ?? slotObject.value ?? key);
                    return { key, label };
                }).filter((slotValue) => slotValue.key !== '') : [];

                const sections = Array.isArray(raw.sections) ? raw.sections.map((sectionValue, sectionIndex) => {
                    const section = asObject(sectionValue);
                    const sectionMetadata = asObject(section.metadata);
                    const sectionKey = String(section.key ?? section.slug ?? section.id ?? `section-${sectionIndex + 1}`);
                    const items = Array.isArray(section.items) ? section.items.map((itemValue, itemIndex) => {
                        const item = asObject(itemValue);
                        const itemMetadata = asObject(item.metadata);
                        const itemKey = String(item.key ?? item.code ?? item.id ?? `${sectionKey}-item-${itemIndex + 1}`);
                        const prompt = String(item.prompt ?? item.label ?? item.description ?? '');
                        const label = String(item.label ?? itemMetadata.label ?? itemMetadata.subject ?? item.code ?? prompt);
                        const description = String(item.description ?? itemMetadata.description ?? (prompt !== label ? prompt : ''));
                        return {
                            id: item.id ?? null,
                            key: itemKey,
                            code: String(item.code ?? itemMetadata.code ?? itemMetadata.number ?? ''),
                            label,
                            description,
                            level: String(item.level ?? itemMetadata.level ?? ''),
                            responsible_role: String(item.responsible_role ?? itemMetadata.responsible_role ?? itemMetadata.responsible ?? itemMetadata.pic ?? ''),
                            escalation_to: String(item.escalation_to ?? itemMetadata.escalation_to ?? itemMetadata.escalation ?? ''),
                            how_to_check: String(item.how_to_check ?? item.howToCheck ?? itemMetadata.how_to_check ?? itemMetadata.howToCheck ?? ''),
                            metadata: itemMetadata,
                        };
                    }) : [];
                    return {
                        id: section.id ?? null,
                        key: sectionKey,
                        title: String(section.title ?? section.name ?? sectionMetadata.title ?? ''),
                        metadata: sectionMetadata,
                        items,
                    };
                }) : [];

                return {
                    id: raw.id ?? null,
                    slug: String(raw.slug ?? ''),
                    name: String(raw.name ?? ''),
                    short_name: String(raw.short_name ?? settings.short_name ?? ''),
                    description: String(raw.description ?? ''),
                    instructions: String(raw.instructions ?? settings.instructions ?? ''),
                    settings,
                    metadata,
                    time_slots: timeSlots,
                    sections,
                };
            }

            // Restroom templates can be either the legacy hourly time-slot
            // form or the newer once-per-audit yes/no form. The template
            // setting is the source of truth so an edited template keeps the
            // same response shape everywhere in the workspace.
            function usesRestroomTimeSlots() {
                return variant === 'restroom'
                    && template.settings?.validation_mode === 'time_slots'
                    && template.time_slots.length > 0;
            }

            function syncChecklistModeUI() {
                const hourly = usesRestroomTimeSlots();
                const filters = document.getElementById('auditFilters');
                const headings = document.querySelector('.column-headings');
                if (filters) filters.hidden = hourly;
                if (headings) headings.hidden = hourly;
            }

            function responseMap(submissionValue) {
                const source = asObject(submissionValue).responses ?? submissionValue ?? {};
                if (Array.isArray(source)) {
                    return source.reduce((map, response, index) => {
                        const entry = asObject(response);
                        const key = String(entry.item_key ?? entry.key ?? entry.item_id ?? entry.checklist_item_id ?? index);
                        map[key] = entry;
                        return map;
                    }, {});
                }
                return asObject(source);
            }

            function responseFor(item, responses) {
                const candidates = [item.key, item.id, item.code].filter((value) => value !== null && value !== undefined && value !== '');
                for (const candidate of candidates) {
                    if (Object.prototype.hasOwnProperty.call(responses, String(candidate))) return asObject(responses[String(candidate)]);
                }
                return {};
            }

            function itemMeta(item) {
                const badges = [];
                if (item.level) badges.push(`<span class="level-badge ${escapeHTML(item.level.toLowerCase())}">${escapeHTML(item.level)}</span>`);
                return badges.length ? `<div class="item-meta">${badges.join('')}</div>` : '';
            }

            function responsibilities(item) {
                const entries = [];
                if (item.responsible_role) entries.push(`<div class="responsibility"><span>Responsible</span><strong>${escapeHTML(item.responsible_role)}</strong></div>`);
                if (item.escalation_to) entries.push(`<div class="responsibility"><span>Escalation</span><strong>${escapeHTML(item.escalation_to)}</strong></div>`);
                return entries.length ? `<div class="responsibility-grid">${entries.join('')}</div>` : '';
            }

            function openHowToCheck(trigger) {
                const dialog = document.getElementById('howToCheckDialog');
                if (!dialog) return;
                const itemKey = trigger.dataset.itemKey || trigger.closest('[data-item-key]')?.dataset.itemKey;
                const item = template.sections.flatMap((section) => section.items).find((entry) => entry.key === itemKey);
                if (!item) return;

                const itemHeading = [item.code ? `Item ${item.code}` : '', item.label].filter(Boolean).join(' — ');
                document.getElementById('howToCheckItem').textContent = itemHeading || 'Checklist item';
                document.getElementById('howToCheckGuidance').textContent = item.how_to_check.trim()
                    || 'No How to Check guidance is available for this checklist item.';
                howToCheckReturnFocus = trigger;
                typeof dialog.showModal === 'function' ? dialog.showModal() : dialog.setAttribute('open', '');
                document.getElementById('closeHowToCheck')?.focus();
            }

            function closeHowToCheck() {
                const dialog = document.getElementById('howToCheckDialog');
                if (!dialog) return;
                if (typeof dialog.close === 'function' && dialog.open) {
                    dialog.close();
                    return;
                }
                dialog.removeAttribute('open');
                howToCheckReturnFocus?.focus();
                howToCheckReturnFocus = null;
            }

            function renderStandardItem(item, number, sectionKey) {
                const key = escapeHTML(item.key);
                const name = `status-${slug(item.key, String(number))}`;
                const displayNumber = item.code || number;
                return `<div class="item-row" data-item-key="${key}" data-section-key="${escapeHTML(sectionKey)}" data-level="${escapeHTML(item.level.toLowerCase())}" data-search="${escapeHTML([item.code, item.label, item.description, item.responsible_role, item.escalation_to].join(' ').toLowerCase())}">
                    <div class="item-number">${escapeHTML(displayNumber)}</div>
                    <div class="item-copy">
                        ${itemMeta(item)}
                        <div class="item-title-row">
                            <strong class="item-text">${escapeHTML(item.label)}</strong>
                            ${variant === 'dos' ? `<button type="button" class="how-to-check-button" data-action="show-how-to-check" data-item-key="${key}" aria-label="How to check ${escapeHTML(item.label)}" aria-haspopup="dialog" aria-controls="howToCheckDialog" title="How to Check"><span aria-hidden="true">i</span></button>` : ''}
                        </div>
                        ${item.description && item.description !== item.label ? `<p class="item-description">${escapeHTML(item.description)}</p>` : ''}
                        ${responsibilities(item)}
                    </div>
                    <div>
                        <div class="status-options" role="radiogroup" aria-label="Response for item ${number}">
                            <label class="status-option"><input type="radio" name="${escapeHTML(name)}" value="yes"><span>YES</span></label>
                            <label class="status-option"><input type="radio" name="${escapeHTML(name)}" value="no"><span>NO</span></label>
                            <label class="status-option"><input type="radio" name="${escapeHTML(name)}" value="na"><span>N/A</span></label>
                        </div>
                    </div>
                    <div class="response-fields">
                        ${variant === 'dos'
                            ? `<label>Finding / N/A reason<textarea class="audit-input" data-field="finding" placeholder="Describe the finding or reason"></textarea></label>
                               <label>Escalation<select class="escalation-input" data-field="escalation">
                                   <option value="">Select escalation recipient</option>
                                   <option value="general_manager">General Manager</option>
                                   <option value="purchasing">Purchasing</option>
                                   <option value="property_management">PM (Property Management)</option>
                                   <option value="inventory">Inventory</option>
                               </select></label>
                               <label>Action plan<textarea class="audit-input" data-field="action_plan" placeholder="Required for NO"></textarea></label>
                               <label>Commitment date and time<input class="commitment-input" data-field="commitment_date" type="datetime-local" step="60"></label>
                               <div class="standard-attachment-block dos-photo-attachment">
                                   <label class="photo-attachment-label">
                                       <i class="fas fa-camera" aria-hidden="true"></i> <span>Attach photo (optional for NO / N/A)</span>
                                       <input type="file" class="standard-photo-file" accept="image/*" hidden>
                                   </label>
                                   <div class="attachment-preview" style="margin-top:4px;"></div>
                               </div>`
                            : `<label>Remarks (Required for NO or N/A)<textarea class="remark-input" data-field="remark" placeholder="Enter remarks (required for NO or N/A)"></textarea></label>
                               <div class="standard-attachment-block" style="margin-top:6px;">
                                   <label class="photo-attachment-label">
                                       <i class="fas fa-camera" aria-hidden="true"></i> <span>Attach photo (optional)</span>
                                       <input type="file" class="standard-photo-file" accept="image/*" hidden>
                                   </label>
                                   <div class="attachment-preview" style="margin-top:4px;"></div>
                               </div>`}
                    </div>
                    <div class="row-spacer" aria-hidden="true"></div>
                </div>`;
            }

            function renderRestroomSection(section, sectionIndex, responses) {
                const slots = template.time_slots;
                const auditDateValue = auditDate ? auditDate.value : '';
                let todayStr = '';
                let curH = 0;
                let curM = 0;
                try {
                    todayStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Manila' }).format(new Date());
                    const manilaTimeParts = new Intl.DateTimeFormat('en-US', {
                        timeZone: 'Asia/Manila',
                        hour: 'numeric',
                        minute: 'numeric',
                        hour12: false,
                    }).formatToParts(new Date());
                    curH = parseInt(manilaTimeParts.find(p => p.type === 'hour')?.value || '0', 10);
                    curM = parseInt(manilaTimeParts.find(p => p.type === 'minute')?.value || '0', 10);
                } catch (e) {
                    const now = new Date();
                    todayStr = now.toISOString().slice(0, 10);
                    curH = now.getHours();
                    curM = now.getMinutes();
                }
                const isToday = !auditDateValue || auditDateValue === todayStr;
                const currentMinutes = curH * 60 + curM;

                const isFutureSlot = (slotKey) => {
                    if (!isToday) {
                        return auditDateValue > todayStr;
                    }
                    const parts = (slotKey || '').split(':');
                    const slotMinutes = (parseInt(parts[0], 10) || 0) * 60 + (parseInt(parts[1], 10) || 0);
                    return slotMinutes > currentMinutes;
                };

                const headings = slots.map((slotValue) => {
                    const locked = isFutureSlot(slotValue.key);
                    return `<th class="slot-cell${locked ? ' slot-locked-col' : ''}" scope="col">${escapeHTML(slotValue.label)}${locked ? ' <i class="fas fa-lock" title="Locked until ' + escapeHTML(slotValue.label) + '" style="font-size:10px;opacity:0.6;margin-left:3px;"></i>' : ''}</th>`;
                }).join('');

                const rows = section.items.map((item, itemIndex) => {
                    const response = responseFor(item, responses);
                    const details = parseObject(response.details);
                    const savedSlots = asObject(details.slots);
                    const slotCells = slots.map((slotValue) => {
                        const locked = isFutureSlot(slotValue.key);
                        if (locked) {
                            return `<td class="slot-cell slot-cell-locked"><span class="badge-slot-locked" title="Locked until ${escapeHTML(slotValue.label)}. Future inspections cannot be recorded ahead of time." style="display:inline-flex;align-items:center;gap:3px;padding:3px 6px;border-radius:4px;background:#f1f5f9;color:#94a3b8;font-size:10px;font-weight:700;cursor:not-allowed;"><i class="fas fa-lock" style="font-size:9px;"></i>Locked</span></td>`;
                        }
                        const storedValue = String(savedSlots[slotValue.key] ?? savedSlots[slotValue.label] ?? '').toLowerCase();
                        const value = ['good', '/', 'yes'].includes(storedValue)
                            ? 'good'
                            : (['not_good', 'not-good', 'x', 'no'].includes(storedValue) ? 'not_good' : '');
                        return `<td class="slot-cell"><select class="slot-select" data-slot="${escapeHTML(slotValue.key)}" aria-label="${escapeHTML(item.label)} at ${escapeHTML(slotValue.label)}">
                            <option value=""></option>
                            <option value="good"${value === 'good' ? ' selected' : ''}>Good</option>
                            <option value="not_good"${value === 'not_good' ? ' selected' : ''}>Not good</option>
                        </select></td>`;
                    }).join('');
                    const remark = response.remark ?? response.remarks ?? '';
                    const attachmentPath = response.attachment_path ?? '';
                    const attachmentUrl = response.attachment_url ?? (attachmentPath ? `/storage/${attachmentPath.replace(/^\/+/, '')}` : '');
                    return `<tr data-item-key="${escapeHTML(item.key)}" data-attachment-path="${escapeHTML(attachmentPath)}">
                        <th scope="row"><span class="item-number">${itemIndex + 1}.</span> <span class="item-text">${escapeHTML(item.label)}</span>${item.description && item.description !== item.label ? `<p class="item-description">${escapeHTML(item.description)}</p>` : ''}</th>
                        ${slotCells}
                        <td>
                            <textarea class="restroom-remark" data-field="remark" placeholder="Add remarks">${escapeHTML(remark)}</textarea>
                            ${attachmentUrl ? `<div class="attachment-preview" style="margin-top:6px;"><a href="${escapeHTML(attachmentUrl)}" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:5px;font-size:11px;font-weight:700;color:var(--gateway-red-500,#e8193f);text-decoration:none;"><i class="fas fa-image"></i> View photo</a></div>` : ''}
                        </td>
                    </tr>`;
                }).join('');
                return `<section class="checklist-section restroom-section" data-section-key="${escapeHTML(section.key)}">
                    <div class="section-header"><div class="section-heading-copy"><span class="section-index">${sectionIndex + 1}</span><div><h4>${escapeHTML(section.title)}</h4><span class="section-count">${section.items.length} item${section.items.length === 1 ? '' : 's'}</span></div></div></div>
                    ${slots.length ? `<div class="restroom-scroll"><table class="restroom-table"><thead><tr><th scope="col">Checklist Item</th>${headings}<th scope="col">Remarks</th></tr></thead><tbody>${rows}</tbody></table></div>` : '<div class="section-empty">No inspection time slots are configured for this template.</div>'}
                </section>`;
            }

            function renderChecklist(submissionValue = currentSubmission) {
                const responses = responseMap(submissionValue);
                let runningNumber = 0;
                if (!template.sections.length) {
                    container.innerHTML = '<div class="empty-state">This database template has no active sections.</div>';
                } else if (usesRestroomTimeSlots()) {
                    container.innerHTML = template.sections.map((section, sectionIndex) => renderRestroomSection(section, sectionIndex, responses)).join('');
                } else {
                    container.innerHTML = template.sections.map((section, sectionIndex) => {
                        const items = section.items.map((item) => renderStandardItem(item, ++runningNumber, section.key)).join('');
                        return `<section class="${variant === 'dos' ? 'coverage-section' : 'checklist-section'}" data-section-key="${escapeHTML(section.key)}">
                            <div class="section-header"><div class="section-heading-copy"><span class="section-index">${sectionIndex + 1}</span><div><h4>${escapeHTML(section.title)}</h4><span class="section-count">${section.items.length} item${section.items.length === 1 ? '' : 's'}</span></div></div></div>
                            ${items || '<div class="section-empty">No active items in this section.</div>'}
                        </section>`;
                    }).join('');
                    applyResponses(submissionValue);
                    populateFilters();
                }
                syncChecklistModeUI();
                paintSlotSelects();
                updateSummary();
            }

            function applyResponses(submissionValue) {
                const responses = responseMap(submissionValue);
                container.querySelectorAll('[data-item-key]').forEach((row) => {
                    const item = template.sections.flatMap((section) => section.items).find((entry) => entry.key === row.dataset.itemKey);
                    if (!item) return;
                    const response = responseFor(item, responses);
                    const details = parseObject(response.details);
                    const status = normalizeStatus(response.status);
                    const statusInput = Array.from(row.querySelectorAll('input[type="radio"]')).find((input) => input.value === status);
                    if (statusInput) statusInput.checked = true;
                    const attachmentPath = response.attachment_path ?? '';
                    const attachmentUrl = response.attachment_url ?? (attachmentPath ? `/storage/${attachmentPath.replace(/^\/+/, '')}` : '');
                    row.dataset.attachmentPath = attachmentPath;
                    const previewEl = row.querySelector('.attachment-preview');
                    if (previewEl) {
                        if (attachmentUrl) {
                            previewEl.innerHTML = `<div style="display:inline-flex;align-items:center;gap:8px;">
                                <a href="${escapeHTML(attachmentUrl)}" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:5px;font-size:11px;font-weight:700;color:var(--gateway-red-500,#e8193f);text-decoration:none;"><i class="fas fa-image"></i> View photo</a>
                                <button type="button" class="btn-remove-photo" style="background:none;border:none;color:#94a3b8;font-size:11px;cursor:pointer;padding:0;" title="Remove photo"><i class="fas fa-times"></i></button>
                            </div>`;
                            const removeBtn = previewEl.querySelector('.btn-remove-photo');
                            if (removeBtn) {
                                removeBtn.addEventListener('click', () => {
                                    row.dataset.attachmentPath = '';
                                    previewEl.innerHTML = '';
                                    const fileInput = row.querySelector('.standard-photo-file');
                                    if (fileInput) fileInput.value = '';
                                });
                            }
                        } else {
                            previewEl.innerHTML = '';
                        }
                    }
                    const photoInput = row.querySelector('.standard-photo-file');
                    if (photoInput && !photoInput.dataset.bound) {
                        photoInput.dataset.bound = 'true';
                        photoInput.addEventListener('change', async (e) => {
                            const file = e.target.files?.[0];
                            if (!file) return;
                            try {
                                if (previewEl) previewEl.innerHTML = '<span style="font-size:11px;color:#64748b;"><i class="fas fa-spinner fa-spin"></i> Uploading photo...</span>';
                                const res = await uploadPhoto(file);
                                row.dataset.attachmentPath = res.path;
                                if (previewEl) {
                                    previewEl.innerHTML = `<div style="display:inline-flex;align-items:center;gap:8px;">
                                        <a href="${escapeHTML(res.url)}" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:5px;font-size:11px;font-weight:700;color:var(--gateway-red-500,#e8193f);text-decoration:none;"><i class="fas fa-image"></i> View photo</a>
                                        <button type="button" class="btn-remove-photo" style="background:none;border:none;color:#94a3b8;font-size:11px;cursor:pointer;padding:0;" title="Remove photo"><i class="fas fa-times"></i></button>
                                    </div>`;
                                    previewEl.querySelector('.btn-remove-photo')?.addEventListener('click', () => {
                                        row.dataset.attachmentPath = '';
                                        previewEl.innerHTML = '';
                                        photoInput.value = '';
                                    });
                                }
                            } catch (err) {
                                alert(err.message || 'Photo upload failed.');
                                if (previewEl) previewEl.innerHTML = '';
                            }
                        });
                    }
                    row.querySelectorAll('[data-field]').forEach((input) => {
                        const field = input.dataset.field;
                        if (field === 'remark') {
                            input.value = String(response.remark ?? response.remarks ?? '');
                        } else if (field === 'escalation') {
                            input.value = normalizeEscalation(details.escalation ?? response.escalation);
                        } else if (field === 'commitment_date') {
                            input.value = normalizeDateTimeLocal(response.commitment_date ?? response.commitmentDate);
                        } else {
                            input.value = String(response[field] ?? '');
                        }
                    });
                });
            }

            async function uploadPhoto(file) {
                const formData = new FormData();
                formData.append('photo', file);
                const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
                const response = await fetch(`/checklists/${template.slug}/attachments`, {
                    method: 'POST',
                    headers: {
                        'X-CSRF-TOKEN': csrfToken,
                        'Accept': 'application/json',
                    },
                    body: formData,
                });
                if (!response.ok) {
                    const err = await response.json().catch(() => ({}));
                    throw new Error(err.message || 'Failed to upload photo.');
                }
                return await response.json();
            }

            function paintSlotSelects() {
                container.querySelectorAll('.slot-select').forEach((select) => {
                    select.classList.toggle('is-good', select.value === 'good');
                    select.classList.toggle('is-not-good', select.value === 'not_good');
                });
            }

            function populateFilters() {
                const sectionFilter = document.getElementById('sectionFilter');
                const levelFilter = document.getElementById('levelFilter');
                if (!sectionFilter || !levelFilter) return;
                const currentSection = sectionFilter.value;
                const currentLevel = levelFilter.value;
                sectionFilter.innerHTML = '<option value="all">All sections</option>' + template.sections
                    .map((section) => `<option value="${escapeHTML(section.key)}">${escapeHTML(section.title)}</option>`).join('');
                const levels = [...new Set(template.sections.flatMap((section) => section.items.map((item) => item.level)).filter(Boolean))];
                levelFilter.innerHTML = '<option value="all">All levels</option>' + levels
                    .map((level) => `<option value="${escapeHTML(level.toLowerCase())}">${escapeHTML(level)}</option>`).join('');
                if ([...sectionFilter.options].some((option) => option.value === currentSection)) sectionFilter.value = currentSection;
                if ([...levelFilter.options].some((option) => option.value === currentLevel)) levelFilter.value = currentLevel;
                filterItems();
            }

            function filterItems() {
                if (usesRestroomTimeSlots()) return;
                const query = document.getElementById('searchInput').value.trim().toLowerCase();
                const section = document.getElementById('sectionFilter').value;
                const level = document.getElementById('levelFilter').value;
                let visible = 0;
                container.querySelectorAll('.item-row').forEach((row) => {
                    const matches = (!query || row.dataset.search.includes(query))
                        && (section === 'all' || row.dataset.sectionKey === section)
                        && (level === 'all' || row.dataset.level === level);
                    row.hidden = !matches;
                    if (matches) visible += 1;
                });
                container.querySelectorAll('[data-section-key]').forEach((sectionElement) => {
                    const rows = sectionElement.querySelectorAll('.item-row');
                    if (rows.length) sectionElement.hidden = ![...rows].some((row) => !row.hidden);
                });
                document.getElementById('showingCount').textContent = `Showing ${visible} item${visible === 1 ? '' : 's'}`;
            }

            function collectResponses() {
                const itemLookup = new Map(template.sections.flatMap((section) => section.items).map((item) => [item.key, item]));
                if (usesRestroomTimeSlots()) {
                    return [...container.querySelectorAll('tbody tr[data-item-key]')].map((row) => {
                        const item = itemLookup.get(row.dataset.itemKey) || {};
                        const slots = {};
                        row.querySelectorAll('.slot-select').forEach((select) => { slots[select.dataset.slot] = select.value || null; });
                        const slotValues = Object.values(slots);
                        const status = slotValues.some((value) => value === 'not_good')
                            ? 'no'
                            : (slotValues.length && slotValues.every((value) => value === 'good') ? 'yes' : null);
                        const remark = row.querySelector('[data-field="remark"]')?.value.trim() || null;
                        return {
                            item_id: item.id,
                            item_key: item.key,
                            status,
                            remark,
                            remarks: remark,
                            finding: null,
                            action_plan: null,
                            commitment_date: null,
                            attachment_path: row.dataset.attachmentPath || null,
                            details: { slots },
                        };
                    });
                }
                return [...container.querySelectorAll('.item-row[data-item-key]')].map((row) => {
                    const item = itemLookup.get(row.dataset.itemKey) || {};
                    const value = (field) => row.querySelector(`[data-field="${field}"]`)?.value.trim() || null;
                    const remark = value('remark');
                    return {
                        item_id: item.id,
                        item_key: item.key,
                        status: row.querySelector('input[type="radio"]:checked')?.value || null,
                        remark,
                        remarks: remark,
                        finding: value('finding'),
                        action_plan: value('action_plan'),
                        commitment_date: value('commitment_date'),
                        attachment_path: row.dataset.attachmentPath || null,
                        details: variant === 'dos' ? { escalation: value('escalation') } : {},
                    };
                });
            }

            function updateSummary() {
                const responses = collectResponses();
                let total;
                let answered;
                let positive;
                let findings;
                if (usesRestroomTimeSlots()) {
                    const allSlots = responses.flatMap((response) => Object.values(response.details.slots));
                    total = allSlots.length;
                    answered = allSlots.filter(Boolean).length;
                    positive = allSlots.filter((value) => value === 'good').length;
                    findings = allSlots.filter((value) => value === 'not_good').length;
                } else {
                    total = responses.length;
                    answered = responses.filter((response) => response.status).length;
                    positive = responses.filter((response) => response.status === 'yes').length;
                    findings = responses.filter((response) => response.status === 'no').length;
                }
                const applicable = Math.max(0, answered - (usesRestroomTimeSlots() ? 0 : responses.filter((response) => response.status === 'na').length));
                const score = applicable ? Math.round((positive / applicable) * 100) : 0;
                const completion = total ? Math.round((answered / total) * 100) : 0;
                const itemCount = template.sections.reduce((sum, section) => sum + section.items.length, 0);
                document.getElementById('scoreValue').textContent = `${score}%`;
                document.getElementById('scoreBar').style.width = `${score}%`;
                document.getElementById('scoreMeta').textContent = `${positive} / ${applicable}`;
                document.getElementById('completionValue').textContent = `${completion}%`;
                document.getElementById('completionBar').style.width = `${completion}%`;
                document.getElementById('answeredCount').textContent = `${answered} / ${total}`;
                document.getElementById('findingsValue').textContent = findings;
                document.getElementById('findingsBar').style.width = total ? `${Math.round((findings / total) * 100)}%` : '0%';
                document.getElementById('findingsMeta').textContent = findings ? 'Review required' : 'Clear';
                document.getElementById('itemCountValue').textContent = itemCount;
                document.getElementById('sectionCountValue').textContent = `${template.sections.length} section${template.sections.length === 1 ? '' : 's'}`;
                document.getElementById('footerSummary').innerHTML = `<strong>${answered} of ${total}</strong> responses recorded · <strong>${score}%</strong> compliance · <strong>${findings}</strong> finding${findings === 1 ? '' : 's'}.`;
            }

            function validateForSubmit() {
                const responses = collectResponses();
                container.querySelectorAll('.validation-error').forEach((row) => row.classList.remove('validation-error'));
                let firstInvalid = null;
                if (usesRestroomTimeSlots()) {
                    container.querySelectorAll('tbody tr[data-item-key]').forEach((row, index) => {
                        if (Object.values(responses[index].details.slots).some((value) => !value)) {
                            row.classList.add('validation-error');
                            firstInvalid ??= row;
                        }
                    });
                } else {
                    container.querySelectorAll('.item-row[data-item-key]').forEach((row, index) => {
                        const response = responses[index];
                        const dosInvalid = variant === 'dos' && (
                            (response.status === 'no' && (!response.finding || !response.action_plan || !response.commitment_date))
                            || (response.status === 'na' && !response.finding)
                        );
                        const standardInvalid = variant !== 'dos'
                            && ['no', 'na'].includes(response.status)
                            && !response.remark;
                        if (!response.status || dosInvalid || standardInvalid) {
                            row.classList.add('validation-error');
                            firstInvalid ??= row;
                        }
                    });
                }
                if (firstInvalid) {
                    firstInvalid.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    const message = usesRestroomTimeSlots()
                        ? 'Record every hourly mark before submitting.'
                        : (variant === 'dos'
                            ? 'Complete every response and the required findings and corrective actions.'
                            : 'Complete every response and add remarks for NO or N/A items.');
                    showToast('Incomplete checklist', message, 'error');
                    return false;
                }
                return true;
            }

            function requestPayload(status) {
                return {
                    date: auditDate.value,
                    checklist_date: auditDate.value,
                    branch: branchSelect.value || null,
                    status,
                    context: { template_slug: template.slug, variant },
                    responses: collectResponses(),
                };
            }

            async function apiRequest(url, options = {}) {
                if (!url) throw new Error('The requested database endpoint is not configured.');
                const response = await fetch(url, {
                    credentials: 'same-origin',
                    ...options,
                    headers: {
                        Accept: 'application/json',
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': csrfToken,
                        ...(options.headers || {}),
                    },
                });
                const contentType = response.headers.get('content-type') || '';
                const data = response.status === 204
                    ? null
                    : (contentType.includes('application/json') ? await response.json() : null);
                if (!response.ok) {
                    const validation = data?.errors ? Object.values(data.errors).flat().join(' ') : '';
                    throw new Error(validation || data?.message || `Request failed (${response.status}).`);
                }
                return data;
            }

            function setBusy(button, busy, busyLabel) {
                if (!button) return;
                if (busy) {
                    button.dataset.label = button.innerHTML;
                    button.textContent = busyLabel;
                    button.disabled = true;
                } else {
                    button.innerHTML = button.dataset.label || button.innerHTML;
                    button.disabled = false;
                }
            }

            async function save(status, sourceButton) {
                if (!auditDate.value) {
                    showToast('Date required', 'Choose a checklist date before saving.', 'error');
                    return;
                }
                if (status === 'submitted' && !validateForSubmit()) return;
                const url = status === 'submitted' ? endpoints.submit : endpoints.draft;
                setBusy(sourceButton, true, status === 'submitted' ? 'Submitting…' : 'Saving…');
                try {
                    const data = await apiRequest(url, { method: 'POST', body: JSON.stringify(requestPayload(status)) });
                    currentSubmission = data?.submission ?? data ?? { status, responses: responseMapFromArray(collectResponses()) };
                    setRecordStatus(currentSubmission.status ?? status);
                    showToast(status === 'submitted' ? 'Checklist submitted' : 'Draft saved', 'The database record is up to date.', 'success');
                } catch (error) {
                    showToast('Unable to save', error.message, 'error');
                } finally {
                    setBusy(sourceButton, false);
                }
            }

            function responseMapFromArray(responses) {
                return responses.reduce((map, response) => {
                    map[String(response.item_key ?? response.item_id)] = response;
                    return map;
                }, {});
            }

            function setRecordStatus(status) {
                const normalized = String(status ?? '').toLowerCase();
                const labels = { draft: 'Draft in database', submitted: 'Submitted', complete: 'Submitted' };
                statusElement.textContent = labels[normalized] || 'No saved record';
            }

            async function loadSubmission({ quiet = false } = {}) {
                if (!endpoints.load || !auditDate.value) {
                    setRecordStatus(currentSubmission?.status);
                    return;
                }
                if (loadController) loadController.abort();
                loadController = new AbortController();
                statusElement.textContent = 'Loading database record…';
                const url = new URL(endpoints.load, window.location.origin);
                url.searchParams.set('date', auditDate.value);
                url.searchParams.set('checklist_date', auditDate.value);
                if (branchSelect.value) url.searchParams.set('branch', branchSelect.value);
                try {
                    const data = await apiRequest(url.toString(), { method: 'GET', signal: loadController.signal });
                    if (data?.template) {
                        template = normalizeTemplate(data.template);
                        syncTemplateHeadings();
                    }
                    currentSubmission = data?.submission ?? (data && Object.prototype.hasOwnProperty.call(data, 'responses') ? data : null);
                    renderChecklist(currentSubmission);
                    setRecordStatus(currentSubmission?.status);
                    if (!quiet) showToast('Checklist loaded', currentSubmission ? 'Saved responses were loaded from the database.' : 'No saved responses exist for this branch and date.');
                } catch (error) {
                    if (error.name === 'AbortError') return;
                    currentSubmission = null;
                    renderChecklist(null);
                    setRecordStatus(null);
                    if (!quiet) showToast('Unable to load', error.message, 'error');
                }
            }

            async function resetSubmission() {
                if (!confirm('Reset the responses for this branch and date? Saved draft responses will be cleared.')) return;
                const button = document.getElementById('resetResponsesButton');
                setBusy(button, true, 'Resetting…');
                const url = endpoints.reset ? new URL(endpoints.reset, window.location.origin) : null;
                if (url) {
                    url.searchParams.set('date', auditDate.value);
                    url.searchParams.set('checklist_date', auditDate.value);
                    if (branchSelect.value) url.searchParams.set('branch', branchSelect.value);
                }
                try {
                    await apiRequest(url?.toString(), {
                        method: 'DELETE',
                        body: JSON.stringify({ date: auditDate.value, checklist_date: auditDate.value, branch: branchSelect.value || null }),
                    });
                    currentSubmission = null;
                    renderChecklist(null);
                    setRecordStatus(null);
                    showToast('Responses reset', 'The saved draft responses were cleared.', 'success');
                } catch (error) {
                    showToast('Unable to reset', error.message, 'error');
                } finally {
                    setBusy(button, false);
                }
            }

            function syncTemplateHeadings() {
                document.getElementById('pageChecklistName').textContent = template.name;
                document.getElementById('checklistHeading').childNodes[0].nodeValue = `${template.name} `;
                document.getElementById('templateChip').textContent = template.name;
                const description = document.getElementById('pageChecklistDescription');
                if (description) description.textContent = template.description;
                const instructions = document.getElementById('checklistInstructions');
                if (instructions) instructions.textContent = template.instructions;
            }

            function showToast(title, message, type = '') {
                const toast = document.createElement('div');
                toast.className = `toast ${type}`;
                toast.innerHTML = `<span class="toast-mark">${type === 'error' ? '!' : '✓'}</span><div><strong></strong><span></span></div>`;
                toast.querySelector('strong').textContent = title;
                toast.querySelector('div span').textContent = message;
                toastRegion.appendChild(toast);
                window.setTimeout(() => toast.remove(), 4200);
            }

            function editorSectionMarkup(section = {}, sectionIndex = 0) {
                const items = Array.isArray(section.items) ? section.items : [];
                return `<section class="editor-section" data-id="${escapeHTML(section.id ?? '')}" data-key="${escapeHTML(section.key ?? `section-${Date.now()}-${sectionIndex}`)}">
                    <div class="editor-section-head">
                        <input class="section-name-input" data-editor-field="title" value="${escapeHTML(section.title ?? '')}" placeholder="Section title" required>
                        <button class="button danger editor-remove" type="button" data-editor-action="remove-section" aria-label="Remove section"><i class="fas fa-trash"></i></button>
                    </div>
                    <div data-editor-items>${items.map((item, itemIndex) => editorItemMarkup(item, itemIndex)).join('')}</div>
                    <div class="editor-add-row"><button class="button" type="button" data-editor-action="add-item"><i class="fas fa-plus"></i> Add Item</button></div>
                </section>`;
            }

            function editorItemMarkup(item = {}, itemIndex = 0) {
                return `<div class="editor-item" data-id="${escapeHTML(item.id ?? '')}" data-key="${escapeHTML(item.key ?? `item-${Date.now()}-${itemIndex}`)}">
                    <input class="edit-input" data-editor-field="code" value="${escapeHTML(item.code ?? '')}" placeholder="Code">
                    <textarea class="edit-textarea" data-editor-field="label" placeholder="Item label" required>${escapeHTML(item.label ?? '')}</textarea>
                    <textarea class="edit-textarea" data-editor-field="description" placeholder="Description">${escapeHTML(item.description ?? '')}</textarea>
                    <input class="edit-input" data-editor-field="level" value="${escapeHTML(item.level ?? '')}" placeholder="Level">
                    <input class="edit-input" data-editor-field="responsible_role" value="${escapeHTML(item.responsible_role ?? '')}" placeholder="Responsible role">
                    <input class="edit-input" data-editor-field="escalation_to" value="${escapeHTML(item.escalation_to ?? '')}" placeholder="Escalation">
                    <button class="button danger editor-remove" type="button" data-editor-action="remove-item" aria-label="Remove item"><i class="fas fa-trash"></i></button>
                </div>`;
            }

            function openTemplateEditor() {
                const dialog = document.getElementById('templateEditor');
                if (!dialog) return;
                document.getElementById('editorName').value = template.name;
                document.getElementById('editorShortName').value = template.short_name;
                document.getElementById('editorDescription').value = template.description;
                document.getElementById('editorInstructions').value = template.instructions;
                document.getElementById('editorSections').innerHTML = template.sections.map(editorSectionMarkup).join('');
                typeof dialog.showModal === 'function' ? dialog.showModal() : dialog.setAttribute('open', '');
            }

            function closeTemplateEditor() {
                const dialog = document.getElementById('templateEditor');
                if (!dialog) return;
                typeof dialog.close === 'function' ? dialog.close() : dialog.removeAttribute('open');
            }

            function collectTemplateEditor() {
                const sections = [...document.querySelectorAll('#editorSections .editor-section')].map((sectionElement, sectionIndex) => {
                    const existingSection = template.sections.find((section) => section.key === sectionElement.dataset.key);
                    const items = [...sectionElement.querySelectorAll(':scope > [data-editor-items] > .editor-item')].map((itemElement, itemIndex) => {
                        const field = (name) => itemElement.querySelector(`[data-editor-field="${name}"]`).value.trim();
                        const id = itemElement.dataset.id || null;
                        const key = itemElement.dataset.key || `item-${sectionIndex + 1}-${itemIndex + 1}`;
                        const existingItem = existingSection?.items.find((item) => item.key === key);
                        const label = field('label');
                        const description = field('description');
                        return {
                            id,
                            key,
                            code: field('code'),
                            label,
                            prompt: description || label,
                            description,
                            level: field('level'),
                            responsible_role: field('responsible_role'),
                            escalation_to: field('escalation_to'),
                            metadata: {
                                ...(existingItem?.metadata || {}),
                                code: field('code'),
                                number: field('code'),
                                label,
                                subject: label,
                                description,
                                level: field('level'),
                                responsible_role: field('responsible_role'),
                                pic: field('responsible_role'),
                                escalation_to: field('escalation_to'),
                                escalation: field('escalation_to'),
                            },
                        };
                    });
                    return {
                        id: sectionElement.dataset.id || null,
                        key: sectionElement.dataset.key || `section-${sectionIndex + 1}`,
                        title: sectionElement.querySelector('[data-editor-field="title"]').value.trim(),
                        metadata: { ...(existingSection?.metadata || {}) },
                        items,
                    };
                });
                return {
                    id: template.id,
                    slug: template.slug,
                    name: document.getElementById('editorName').value.trim(),
                    short_name: document.getElementById('editorShortName').value.trim(),
                    description: document.getElementById('editorDescription').value.trim(),
                    instructions: document.getElementById('editorInstructions').value.trim(),
                    time_slots: template.time_slots,
                    settings: {
                        ...template.settings,
                        short_name: document.getElementById('editorShortName').value.trim(),
                        instructions: document.getElementById('editorInstructions').value.trim(),
                        time_slots: template.time_slots,
                    },
                    sections,
                };
            }

            async function saveTemplate() {
                const form = document.getElementById('templateEditorForm');
                if (!form.reportValidity()) return;
                const payload = collectTemplateEditor();
                if (!payload.name || !payload.sections.length || payload.sections.some((section) => !section.title || section.items.some((item) => !item.label))) {
                    showToast('Template incomplete', 'Every section and checklist item needs a name.', 'error');
                    return;
                }
                const button = document.getElementById('saveTemplateButton');
                setBusy(button, true, 'Saving…');
                try {
                    const data = await apiRequest(endpoints.template, { method: 'PUT', body: JSON.stringify(payload) });
                    template = normalizeTemplate(data?.template ?? payload);
                    currentSubmission = null;
                    syncTemplateHeadings();
                    renderChecklist(null);
                    closeTemplateEditor();
                    setRecordStatus(null);
                    showToast('Master checklist saved', 'The database template has been updated.', 'success');
                } catch (error) {
                    showToast('Unable to save template', error.message, 'error');
                } finally {
                    setBusy(button, false);
                }
            }

            container.addEventListener('input', updateSummary);
            container.addEventListener('change', (event) => {
                if (event.target.matches('.slot-select')) paintSlotSelects();
                updateSummary();
            });
            container.addEventListener('click', (event) => {
                const trigger = event.target.closest('[data-action="show-how-to-check"]');
                if (trigger) openHowToCheck(trigger);
            });
            document.getElementById('closeHowToCheck')?.addEventListener('click', closeHowToCheck);
            document.getElementById('dismissHowToCheck')?.addEventListener('click', closeHowToCheck);
            document.getElementById('howToCheckDialog')?.addEventListener('close', () => {
                howToCheckReturnFocus?.focus();
                howToCheckReturnFocus = null;
            });
            document.getElementById('searchInput')?.addEventListener('input', filterItems);
            document.getElementById('sectionFilter')?.addEventListener('change', filterItems);
            document.getElementById('levelFilter')?.addEventListener('change', filterItems);
            branchSelect.addEventListener('change', () => loadSubmission());
            auditDate.addEventListener('change', () => loadSubmission());
            document.getElementById('saveDraftButton').addEventListener('click', (event) => save('draft', event.currentTarget));
            document.getElementById('submitButton').addEventListener('click', (event) => save('submitted', event.currentTarget));
            document.getElementById('footerSubmitButton').addEventListener('click', (event) => save('submitted', event.currentTarget));
            document.getElementById('resetResponsesButton').addEventListener('click', resetSubmission);
            document.getElementById('printButton').addEventListener('click', () => window.print());
            document.getElementById('scrollTopButton').addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));

            document.getElementById('editTemplateButton')?.addEventListener('click', openTemplateEditor);
            document.getElementById('closeTemplateEditor')?.addEventListener('click', closeTemplateEditor);
            document.getElementById('cancelTemplateEditor')?.addEventListener('click', closeTemplateEditor);
            document.getElementById('addEditorSection')?.addEventListener('click', () => {
                document.getElementById('editorSections').insertAdjacentHTML('beforeend', editorSectionMarkup({}, document.querySelectorAll('.editor-section').length));
            });
            document.getElementById('editorSections')?.addEventListener('click', (event) => {
                const action = event.target.closest('[data-editor-action]');
                if (!action) return;
                if (action.dataset.editorAction === 'remove-section') action.closest('.editor-section').remove();
                if (action.dataset.editorAction === 'remove-item') action.closest('.editor-item').remove();
                if (action.dataset.editorAction === 'add-item') {
                    const items = action.closest('.editor-section').querySelector('[data-editor-items]');
                    items.insertAdjacentHTML('beforeend', editorItemMarkup({}, items.children.length));
                }
            });
            document.getElementById('saveTemplateButton')?.addEventListener('click', saveTemplate);

            const sidebar = document.getElementById('sidebar');
            const mainShell = document.querySelector('.main-shell');
            const sidebarToggle = document.getElementById('sidebarToggle');
            const mobileMenuButton = document.getElementById('mobileMenuButton');
            const sidebarBackdrop = document.getElementById('sidebarBackdrop');
            sidebarToggle?.addEventListener('click', () => {
                const collapsed = !sidebar.classList.contains('desktop-collapsed');
                sidebar.classList.toggle('desktop-collapsed', collapsed);
                mainShell.classList.toggle('sidebar-collapsed', collapsed);
                sidebarToggle.setAttribute('aria-expanded', String(!collapsed));
            });
            const closeMobileSidebar = () => {
                sidebar?.classList.remove('open', 'mobile-open');
                sidebarBackdrop?.classList.remove('open');
            };
            mobileMenuButton?.addEventListener('click', () => {
                sidebar?.classList.add('open', 'mobile-open');
                sidebarBackdrop?.classList.add('open');
            });
            sidebarBackdrop?.addEventListener('click', closeMobileSidebar);

            renderChecklist(initialSubmission);
            setRecordStatus(initialSubmission?.status);
            if (endpoints.load) loadSubmission({ quiet: true });
            if (!endpoints.draft) document.getElementById('saveDraftButton').disabled = true;
            if (!endpoints.submit) {
                document.getElementById('submitButton').disabled = true;
                document.getElementById('footerSubmitButton').disabled = true;
            }
            if (!endpoints.reset) document.getElementById('resetResponsesButton').disabled = true;
            if (!endpoints.template) document.getElementById('editTemplateButton')?.setAttribute('disabled', 'disabled');
        })();
    </script>

    @include('partials.notifications-modal')
</body>
</html>
