@php
    $formatPercent = static fn ($value) => $value === null ? '—' : number_format((float) $value, 1).'%';
    $barWidth = static fn ($value) => min(100, max(0, (float) ($value ?? 0)));
    $filterQuery = array_filter($filters, static fn ($value) => $value !== null && $value !== '');
    $recordCount = (int) ($summary['audit_count'] ?? 0);
    $answeredCount = (int) ($summary['answered'] ?? 0);
    $findingRate = $answeredCount > 0
        ? min(100, ((int) ($summary['findings_count'] ?? 0) / $answeredCount) * 100)
        : 0;
    $noCount = (int) ($summary['no_count'] ?? 0);
    $escalationCount = (int) ($summary['escalation_count'] ?? 0);
    $overdueCount = (int) ($summary['overdue_count'] ?? 0);
    $overriddenCount = (int) ($summary['overridden_count'] ?? 0);
    $canViewFindings = $canViewFindings ?? false;
    $canManageEscalations = $canManageEscalations ?? false;
    $canOverrideAny = $canOverrideAny ?? false;
    $showOverrideActions = $showOverrideActions ?? $canOverrideAny;
    $followUpResponseId = (int) ($followUpResponseId ?? 0);
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    @include('partials.browser-push-head')
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta name="theme-color" content="#F5F6F8">
    <title>Gateway Audit Compliance | Reports & Analytics</title>
    <link rel="icon" type="image/png" href="{{ asset('images/G-logo-no-bg.png') }}">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css">
    <link rel="stylesheet" href="{{ asset('css/reports-des.css') }}">
    <link rel="stylesheet" href="{{ asset('css/gateway-theme.css') }}">
</head>
<body class="gateway-dashboard gateway-page-reports">
    @include('layouts.navigation')

    <div class="main-shell" id="mainShell">
        @include('partials.app-topbar', [
            'topbarTitle' => 'Reports & Analytics',
            'topbarSubtitle' => 'Database-backed compliance performance, NO answers register, and escalation management',
            'notificationId' => 'notificationsBtn',
        ])

        <main class="content">
            <!-- Top Page Heading & Monthly Navigation -->
            <section class="page-heading">
                <div>
                    <span class="eyebrow"><span class="eyebrow-dot"></span> Monthly compliance intelligence</span>
                    <h2>Reports &amp; Analytics</h2>
                    <p>
                        Performance tracking for Dealer Operations Standards, 5S, and dedicated Restroom audits.
                        @if ($reportScope['type'] === 'assigned_branch')
                            Scattered data is restricted to <strong>{{ $reportScope['branch'] ?: 'your assigned branch' }}</strong>.
                        @else
                            Showing enterprise records across <strong>all dealership branches</strong>.
                        @endif
                    </p>
                </div>
                <div class="header-actions">
                    <a class="button" href="{{ route('reports.index', $filterQuery) }}"><i class="fas fa-rotate" aria-hidden="true"></i>Refresh</a>
                    <a class="button" href="{{ route('reports.export', array_merge($filterQuery, ['export_type' => 'submissions'])) }}"><i class="fas fa-file-csv" aria-hidden="true"></i>Export Submissions</a>
                    <a class="button" href="{{ route('reports.export', array_merge($filterQuery, ['export_type' => 'findings'])) }}" title="Export NO Answers & Escalations"><i class="fas fa-file-excel" aria-hidden="true"></i>Export NO Answers</a>
                    <button class="button primary" id="printButton" type="button"><i class="fas fa-print" aria-hidden="true"></i>Print Report</button>
                </div>
            </section>

            <!-- Month Scoping Navigator (Preset to current month) -->
            <section class="panel month-navigator-panel" aria-label="Monthly reporting timeframe">
                <div class="month-nav-left">
                    <span class="month-nav-label"><i class="fas fa-calendar-days" aria-hidden="true"></i> Reporting Month:</span>
                    <strong class="month-nav-current">{{ $selectedMonthLabel }}</strong>
                    @if ($selectedMonth === $currentMonth)
                        <span class="badge-current-month"><i class="fas fa-bolt" aria-hidden="true"></i> Current Month</span>
                    @else
                        <a class="button button-xs" href="{{ route('reports.index', array_merge(\Illuminate\Support\Arr::except($filterQuery, ['month']), ['month' => $currentMonth])) }}">
                            <i class="fas fa-calendar-check" aria-hidden="true"></i> Jump to Current Month
                        </a>
                    @endif
                </div>
                <div class="month-nav-controls">
                    <a class="button button-sm" href="{{ route('reports.index', array_merge($filterQuery, ['month' => $prevMonth])) }}" title="Previous Month">
                        <i class="fas fa-chevron-left" aria-hidden="true"></i> Prev Month
                    </a>
                    <form method="GET" action="{{ route('reports.index') }}" class="month-select-form">
                        @foreach ($filters as $fKey => $fVal)
                            @if ($fKey !== 'month' && filled($fVal))
                                <input type="hidden" name="{{ $fKey }}" value="{{ $fVal }}">
                            @endif
                        @endforeach
                        <label for="monthQuickPicker" class="sr-only">Change Month</label>
                        <input type="month" id="monthQuickPicker" name="month" value="{{ $selectedMonth }}" onchange="this.form.submit()" title="Choose specific month">
                    </form>
                    <a class="button button-sm" href="{{ route('reports.index', array_merge($filterQuery, ['month' => $nextMonth])) }}" title="Next Month">
                        Next Month <i class="fas fa-chevron-right" aria-hidden="true"></i>
                    </a>
                </div>
            </section>

            @if ($errors->any())
                <section class="notice visible alert-notice" role="alert">
                    <span class="notice-icon"><i class="fas fa-triangle-exclamation" aria-hidden="true"></i></span>
                    <div>
                        <strong>Unable to apply requested report filter.</strong>
                        <p>{{ $errors->first() }}</p>
                    </div>
                </section>
            @elseif ($recordCount === 0)
                <section class="notice visible empty-notice" aria-live="polite">
                    <span class="notice-icon"><i class="fas fa-circle-info" aria-hidden="true"></i></span>
                    <div>
                        <strong>No checklist audits found for {{ $selectedMonthLabel }}.</strong>
                        <p>No audit submissions match the active filters for this month. Switch months or clear filters to view historical audit logs.</p>
                    </div>
                </section>
            @endif

            <!-- Filter Controls Panel -->
            <form class="panel filter-panel" method="GET" action="{{ route('reports.index') }}" aria-label="Report filters">
                <input type="hidden" name="month" value="{{ $selectedMonth }}">

                <div class="field">
                    <label for="branchFilter">Branch</label>
                    <select id="branchFilter" name="branch">
                        <option value="">{{ $reportScope['type'] === 'all_branches' ? 'All Dealership Branches' : 'My Assigned Branch' }}</option>
                        @foreach ($branchOptions as $branch)
                            <option value="{{ $branch }}" @selected($filters['branch'] === $branch)>{{ $branch }}</option>
                        @endforeach
                    </select>
                </div>

                <div class="field">
                    <label for="templateFilter">Audit Module</label>
                    <select id="templateFilter" name="template">
                        <option value="">All Checklist Modules</option>
                        @foreach ($templateOptions as $template)
                            <option value="{{ $template['slug'] }}" @selected($filters['template'] === $template['slug'])>
                                {{ $template['name'] }}{{ $template['slug'] === 'restroom' ? ' (Dedicated)' : '' }}{{ $template['is_archived'] ? ' (Archived)' : '' }}
                            </option>
                        @endforeach
                    </select>
                </div>

                <div class="field">
                    <label for="statusFilter">Record Status</label>
                    <select id="statusFilter" name="status">
                        <option value="">Submitted and draft</option>
                        @foreach ($statusOptions as $status)
                            <option value="{{ $status }}" @selected($filters['status'] === $status)>{{ ucfirst($status) }} only</option>
                        @endforeach
                    </select>
                </div>

                <div class="field">
                    <label for="userTypeFilter">User Type</label>
                    <select id="userTypeFilter" name="user_type">
                        <option value="">All Employee Roles</option>
                        @foreach ($roleOptions as $roleCode => $roleLabel)
                            <option value="{{ $roleCode }}" @selected($filters['user_type'] === $roleCode)>{{ $roleLabel }}</option>
                        @endforeach
                    </select>
                </div>

                <div class="field">
                    <label for="recencyFilter">Submission Recency</label>
                    <select id="recencyFilter" name="recency">
                        <option value="">All dates this month</option>
                        @foreach ($recencyOptions as $recency => $recencyLabel)
                            <option value="{{ $recency }}" @selected($filters['recency'] === $recency)>{{ $recencyLabel }}</option>
                        @endforeach
                    </select>
                </div>

                <div class="field">
                    <label for="findingsFilter">Findings View</label>
                    <select id="findingsFilter" name="findings_filter">
                        <option value="all" @selected(($filters['findings_filter'] ?? 'all') === 'all')>All Flagged Findings</option>
                        <option value="no" @selected(($filters['findings_filter'] ?? '') === 'no')>NO Answers Only</option>
                        <option value="overdue" @selected(($filters['findings_filter'] ?? '') === 'overdue')>Overdue Commitments</option>
                        <option value="escalated" @selected(($filters['findings_filter'] ?? '') === 'escalated')>With Escalation</option>
                        <option value="overridden" @selected(($filters['findings_filter'] ?? '') === 'overridden')>Overridden / Resolved</option>
                    </select>
                </div>

                <div class="filter-actions">
                    <a class="button" href="{{ route('reports.index', ['month' => $selectedMonth]) }}"><i class="fas fa-filter-circle-xmark" aria-hidden="true"></i>Reset Filters</a>
                    <button class="button primary" type="submit"><i class="fas fa-filter" aria-hidden="true"></i>Apply Filters</button>
                </div>
            </form>

            <!-- KPI Executive Summary Cards -->
            <section class="stats-grid" aria-label="Executive compliance summary">
                <article class="stat-card">
                    <div class="stat-top"><span class="stat-label">Overall Compliance</span><span class="stat-icon"><i class="fas fa-gauge-high" aria-hidden="true"></i></span></div>
                    <div class="stat-value" id="statScore">{{ $formatPercent($summary['score']) }}</div>
                    <div class="stat-track"><span style="width:{{ $barWidth($summary['score']) }}%"></span></div>
                    <div class="stat-meta">{{ number_format($summary['yes']) }} passing of {{ number_format($summary['applicable']) }} applicable judgments</div>
                </article>

                <article class="stat-card">
                    <div class="stat-top"><span class="stat-label">Completion Rate</span><span class="stat-icon"><i class="fas fa-circle-check" aria-hidden="true"></i></span></div>
                    <div class="stat-value">{{ $formatPercent($summary['completion']) }}</div>
                    <div class="stat-track"><span style="width:{{ $barWidth($summary['completion']) }}%"></span></div>
                    <div class="stat-meta">{{ number_format($summary['answered']) }} of {{ number_format($summary['total']) }} audit items answered</div>
                </article>

                <article class="stat-card">
                    <div class="stat-top"><span class="stat-label">Audits Completed</span><span class="stat-icon"><i class="fas fa-file-signature" aria-hidden="true"></i></span></div>
                    <div class="stat-value">{{ number_format($recordCount) }}</div>
                    <div class="stat-track"><span style="width:{{ $recordCount > 0 ? 100 : 0 }}%"></span></div>
                    <div class="stat-meta">{{ number_format($summary['submitted_count']) }} submitted · {{ number_format($summary['draft_count']) }} in progress</div>
                </article>

                <article class="stat-card stat-alert">
                    <div class="stat-top"><span class="stat-label">NO Answers / Deficiencies</span><span class="stat-icon"><i class="fas fa-triangle-exclamation" aria-hidden="true"></i></span></div>
                    <div class="stat-value text-danger" id="statNoCount">{{ number_format($noCount) }}</div>
                    <div class="stat-track"><span class="track-danger" style="width:{{ $findingRate }}%"></span></div>
                    <div class="stat-meta">Items marked non-compliant or failed time slots</div>
                </article>

                <article class="stat-card">
                    <div class="stat-top"><span class="stat-label">Escalations</span><span class="stat-icon"><i class="fas fa-share-nodes" aria-hidden="true"></i></span></div>
                    <div class="stat-value text-purple" id="statEscalationCount">{{ number_format($escalationCount) }}</div>
                    <div class="stat-track"><span class="track-purple" style="width:{{ $noCount > 0 ? min(100, ($escalationCount / $noCount) * 100) : 0 }}%"></span></div>
                    <div class="stat-meta">Assigned to management, purchasing, inventory, or property</div>
                </article>

                <article class="stat-card {{ $overdueCount > 0 ? 'stat-overdue' : '' }}">
                    <div class="stat-top"><span class="stat-label">Overdue Commitments</span><span class="stat-icon"><i class="fas fa-clock-rotate-left" aria-hidden="true"></i></span></div>
                    <div class="stat-value {{ $overdueCount > 0 ? 'text-danger' : 'text-success' }}" id="statOverdueCount">{{ number_format($overdueCount) }}</div>
                    <div class="stat-track"><span class="track-danger" style="width:{{ $noCount > 0 ? min(100, ($overdueCount / $noCount) * 100) : 0 }}%"></span></div>
                    <div class="stat-meta">{{ $overdueCount > 0 ? 'Commitment date/time passed without resolution' : 'All action commitments are on schedule' }}</div>
                </article>
            </section>

            <!-- DEDICATED NO ANSWERS & ESCALATIONS REGISTER -->
            <section class="panel no-answers-register-panel" id="noAnswersSection" aria-label="NO Answers and Action Plan Register">
                <div class="register-header">
                    <div class="register-title">
                        <div class="register-badge-row">
                            <span class="section-tag"><i class="fas fa-clipboard-list" aria-hidden="true"></i> Action Item Register</span>
                            @if ($canOverrideAny)
                                <span class="authority-badge" title="You are authorized to override and edit checklist responses">
                                    <i class="fas fa-shield-check" aria-hidden="true"></i> Override Active
                                </span>
                            @else
                                <span class="authority-badge locked" title="Only authorized users may override NO responses">
                                    <i class="fas fa-lock" aria-hidden="true"></i> View Only
                                </span>
                            @endif
                        </div>
                        <h3>Checklist NO Answers &amp; Escalations</h3>
                        <p>Comprehensive register of non-compliant checklist responses. Review corrective actions, commitment dates, and exercise authorized overrides.</p>
                    </div>

                    <div class="register-actions">
                        <div class="register-filter-pills" role="tablist" aria-label="Filter NO answers">
                            <button type="button" class="pill-btn active" data-filter-tab="all">All ({{ $findings->count() }})</button>
                            <button type="button" class="pill-btn" data-filter-tab="no">NO Only ({{ $noCount }})</button>
                            <button type="button" class="pill-btn" data-filter-tab="overdue">Overdue ({{ $overdueCount }})</button>
                            <button type="button" class="pill-btn" data-filter-tab="escalated">Escalated ({{ $escalationCount }})</button>
                            <button type="button" class="pill-btn" data-filter-tab="overridden">Overridden ({{ $overriddenCount }})</button>
                        </div>
                    </div>
                </div>

                @if ($followUpResponseId)
                    <div class="summary-follow-up-guidance">
                        <i class="fas fa-location-dot" aria-hidden="true"></i>
                        <span>Follow-up requested on the highlighted finding. Complete its escalation details below.</span>
                    </div>
                @endif

                <div class="table-wrap register-table-wrap">
                    <table class="findings-table" id="findingsTable">
                        <thead>
                            <tr>
                                <th>Date &amp; Branch</th>
                                <th>Checklist &amp; Item</th>
                                <th>Deficiency &amp; Action Plan</th>
                                <th>Suggested Escalation</th>
                                <th>Commitment Date &amp; Time</th>
                                <th>Status / Resolution</th>
                                <th class="actions-col">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($findings as $finding)
                                @php
                                    $isNo = in_array($finding['status'], ['no', 'x'], true);
                                    $rowClasses = [
                                        'finding-row',
                                        $isNo ? 'is-no-row' : 'is-na-row',
                                        $finding['is_overdue'] ? 'is-overdue-row' : '',
                                        $finding['escalation_target'] ? 'is-escalated-row' : '',
                                        $finding['is_overridden'] ? 'is-overridden-row' : '',
                                        (int) $followUpResponseId === (int) $finding['response_id'] ? 'is-follow-up-highlight' : '',
                                    ];
                                @endphp
                                <tr id="findingRow{{ $finding['response_id'] }}"
                                    class="{{ implode(' ', array_filter($rowClasses)) }}"
                                    data-finding-id="{{ $finding['response_id'] }}"
                                    data-is-no="{{ $isNo ? 'true' : 'false' }}"
                                    data-is-overdue="{{ $finding['is_overdue'] ? 'true' : 'false' }}"
                                    data-is-escalated="{{ $finding['escalation_target'] ? 'true' : 'false' }}"
                                    data-is-overridden="{{ $finding['is_overridden'] ? 'true' : 'false' }}"
                                    @if ((int) $followUpResponseId === (int) $finding['response_id'])
                                        data-follow-up-highlight
                                        tabindex="-1"
                                    @endif>

                                    <!-- Date & Branch -->
                                    <td class="meta-cell">
                                        <div class="audit-date-badge">
                                            <strong>{{ $finding['audit_date'] ? \Illuminate\Support\Carbon::parse($finding['audit_date'])->format('d M Y') : '—' }}</strong>
                                        </div>
                                        <div class="branch-tag"><i class="fas fa-building" aria-hidden="true"></i> {{ $finding['branch'] }}</div>
                                        <div class="auditor-info" title="Auditor: {{ $finding['auditor'] }}">
                                            <i class="fas fa-user-check" aria-hidden="true"></i> <span>{{ $finding['auditor'] }}</span>
                                            <small class="role-pill-micro {{ strtolower($finding['auditor_role']) }}">{{ $finding['auditor_role'] }}</small>
                                        </div>
                                        @if (!empty($finding['checker_role']))
                                            <div class="meta-subtext"><small><i class="fas fa-clipboard-user" aria-hidden="true"></i> Checker: {{ $finding['checker_role'] }}</small></div>
                                        @endif
                                        @if (!empty($finding['person_accountable']))
                                            <div class="meta-subtext"><small><i class="fas fa-user-gear" aria-hidden="true"></i> Accountable: {{ $finding['person_accountable'] }}</small></div>
                                        @endif
                                    </td>

                                    <!-- Checklist & Item Details -->
                                    <td class="item-cell">
                                        <div class="item-tags-row">
                                            <span class="template-chip-sm">{{ $finding['template_name'] }}</span>
                                            @if (!empty($finding['category']))
                                                <span class="category-chip">{{ $finding['category'] }}</span>
                                            @endif
                                            @if ($finding['is_restroom'] && $finding['slot'])
                                                <span class="slot-badge"><i class="fas fa-clock" aria-hidden="true"></i> Slot {{ $finding['slot'] }}</span>
                                            @endif
                                        </div>
                                        <div class="item-area-label">{{ $finding['area'] }}</div>
                                        <div class="item-prompt-text">
                                            @if (!empty($finding['question_number']))
                                                <span class="question-number">{{ $finding['question_number'] }}.</span>
                                            @endif
                                            <strong>{{ $finding['item'] }}</strong>
                                            @if (!empty($finding['subject']))
                                                <small class="item-subject">{{ $finding['subject'] }}</small>
                                            @endif
                                            @if ($finding['item_key'])
                                                <code class="item-code">{{ $finding['item_key'] }}</code>
                                            @endif
                                        </div>
                                    </td>

                                    <!-- Deficiency & Action Plan -->
                                    <td class="deficiency-cell">
                                        <div class="finding-remark">
                                            <span class="detail-label">Finding:</span>
                                            <p>{{ $finding['detail'] }}</p>
                                        </div>
                                        @if (!empty($finding['bom_task']))
                                            <div class="finding-bom-task">
                                                <span class="detail-label"><i class="fas fa-list-check" aria-hidden="true"></i> Task:</span>
                                                <p>{{ $finding['bom_task'] }}</p>
                                            </div>
                                        @endif
                                        @if ($finding['action_plan'])
                                            <div class="finding-action-plan">
                                                <span class="detail-label"><i class="fas fa-wrench" aria-hidden="true"></i> Action Plan:</span>
                                                <p>{{ $finding['action_plan'] }}</p>
                                            </div>
                                        @endif
                                        @if ($finding['attachment_url'])
                                            <div class="finding-attachment-wrap">
                                                <a href="{{ $finding['attachment_url'] }}"
                                                   target="_blank"
                                                   rel="noopener noreferrer"
                                                   class="summary-photo-link">
                                                    <img src="{{ $finding['attachment_url'] }}"
                                                         alt="Photo evidence for {{ $finding['item_key'] }}"
                                                         loading="lazy">
                                                    <span><i class="fas fa-up-right-from-square" aria-hidden="true"></i> View full photo</span>
                                                </a>
                                            </div>
                                        @else
                                            <span class="summary-no-photo"><i class="fas fa-image" aria-hidden="true"></i> No photo attached</span>
                                        @endif
                                        @if (!empty($finding['override_details']['attachment_url']))
                                            <div class="finding-override-proof-box">
                                                <span class="detail-label"><i class="fas fa-shield-check text-success" aria-hidden="true"></i> Override Proof:</span>
                                                <a href="{{ $finding['override_details']['attachment_url'] }}"
                                                   target="_blank"
                                                   rel="noopener noreferrer"
                                                   class="summary-photo-link summary-proof-link"
                                                   title="View override proof attachment">
                                                    @if ($finding['override_details']['is_image'] ?? true)
                                                        <img src="{{ $finding['override_details']['attachment_url'] }}"
                                                             alt="Override proof for {{ $finding['item_key'] }}"
                                                             loading="lazy">
                                                    @else
                                                        <span class="proof-pdf-icon"><i class="fas fa-file-pdf text-danger" aria-hidden="true"></i> PDF Proof</span>
                                                    @endif
                                                    <span><i class="fas fa-up-right-from-square" aria-hidden="true"></i> View proof</span>
                                                </a>
                                            </div>
                                        @endif
                                    </td>

                                    <!-- Suggested Escalation -->
                                    <td class="escalation-cell">
                                        @if (!empty($finding['recommended_escalation']))
                                            <div class="workbook-target-label" title="Workbook recommended recipient">
                                                <small>Workbook target:</small>
                                                <span class="summary-workbook-target">{{ $finding['recommended_escalation'] }}</span>
                                            </div>
                                        @endif
                                        <div class="escalation-badge-wrap">
                                            @if ($finding['escalation_target'])
                                                <div class="escalation-badge {{ strtolower(str_replace('_', '-', $finding['escalation_target'])) }}">
                                                    <i class="fas {{ match ($finding['escalation_target']) {
                                                        'general_manager', 'general_manager_ce_central' => 'fa-shield-halved',
                                                        'purchasing', 'marketing_purchasing' => 'fa-cart-shopping',
                                                        'property_management', 'marketing_property_management' => 'fa-user-tie',
                                                        'inventory' => 'fa-boxes-stacked',
                                                        'bom' => 'fa-user-gear',
                                                        'ce_central' => 'fa-building-shield',
                                                        'central_admin' => 'fa-landmark',
                                                        'dnd' => 'fa-compass',
                                                        'as_brand_head', 'brand_head' => 'fa-user-tie',
                                                        'as_head' => 'fa-wrench',
                                                        'it' => 'fa-laptop-code',
                                                        'marketing' => 'fa-bullhorn',
                                                        'logistic' => 'fa-truck',
                                                        'mmpc_cs_team', 'mmpc_training_team' => 'fa-users',
                                                        default => 'fa-arrow-up-right-from-square',
                                                    } }}" aria-hidden="true"></i>
                                                    <span>{{ $finding['escalation_target_label'] }}</span>
                                                </div>
                                                <small class="bom-escalated-note">Target</small>
                                            @else
                                                <span class="no-escalation-text"><i class="fas fa-minus" aria-hidden="true"></i> None specified</span>
                                            @endif
                                        </div>
                                    </td>

                                    <!-- Commitment Date & Time -->
                                    <td class="commitment-cell">
                                        <div class="commitment-badge-wrap">
                                            @if ($finding['commitment_date'])
                                                <div class="commitment-datetime-badge">
                                                    <i class="fas fa-calendar-check" aria-hidden="true"></i>
                                                    <strong class="commitment-date-text">{{ $finding['commitment_date_formatted'] }}</strong>
                                                </div>
                                                @if ($finding['due_status'])
                                                    <div class="urgency-tag {{ $finding['is_overdue'] ? 'tag-overdue' : 'tag-upcoming' }}">
                                                        <i class="fas {{ $finding['is_overdue'] ? 'fa-triangle-exclamation' : 'fa-hourglass-half' }}" aria-hidden="true"></i>
                                                        {{ $finding['due_status'] }}
                                                    </div>
                                                @endif
                                            @else
                                                <span class="no-commitment-text"><i class="fas fa-clock" aria-hidden="true"></i> No date &amp; time committed</span>
                                            @endif
                                        </div>
                                    </td>

                                    <!-- Status / Resolution -->
                                    <td class="status-cell">
                                        <div class="status-indicator-block">
                                            @if ($finding['is_overridden'])
                                                <span class="status-pill overridden" title="Response overridden by {{ $finding['override_details']['overridden_by_name'] ?? 'BOM/GM' }}">
                                                    <i class="fas fa-check-double" aria-hidden="true"></i> {{ $finding['result'] }}
                                                </span>
                                                <div class="override-meta-note">
                                                    <span class="override-meta-actor">By {{ $finding['override_details']['overridden_by_name'] ?? 'Manager' }} ({{ $finding['override_details']['overridden_by_role'] ?? 'BOM' }})</span>
                                                    @if (!empty($finding['override_details']['overridden_at_formatted']))
                                                        <span class="override-meta-timestamp" title="Date and time when override was submitted">
                                                            <i class="fas fa-clock" aria-hidden="true"></i> {{ $finding['override_details']['overridden_at_formatted'] }}
                                                        </span>
                                                    @endif
                                                    @if (!empty($finding['override_details']['reason']))
                                                        <small title="{{ $finding['override_details']['reason'] }}">“{{ Str::limit($finding['override_details']['reason'], 35) }}”</small>
                                                    @endif
                                                    @if (!empty($finding['override_details']['attachment_url']))
                                                        <a href="{{ $finding['override_details']['attachment_url'] }}"
                                                           target="_blank"
                                                           rel="noopener noreferrer"
                                                           class="override-proof-chip"
                                                           title="View attached proof document">
                                                            <i class="fas fa-paperclip" aria-hidden="true"></i> Proof Attached
                                                        </a>
                                                    @endif
                                                </div>
                                            @else
                                                <span class="status-pill {{ $finding['status'] === 'x' ? 'no' : $finding['status'] }}">
                                                    {{ $finding['result'] }}
                                                </span>
                                                <span class="substatus-note">{{ $isNo ? 'Unresolved Defect' : 'Audit Finding' }}</span>
                                            @endif
                                        </div>
                                    </td>

                                    <!-- Follow-up & Override Actions -->
                                    <td class="actions-cell">
                                        <div class="actions-stack">
                                            @if ($canViewFindings && $isNo)
                                                <div class="follow-up-action-wrap">
                                                    <button type="button"
                                                            class="button button-sm summary-follow-up-btn"
                                                            data-request-finding-follow-up
                                                            data-endpoint="{{ route('reports.responses.follow-up', $finding['response_id']) }}"
                                                            title="Request follow-up on this finding">
                                                        <i class="fas fa-bell" aria-hidden="true"></i>
                                                        <span>Follow-up</span>
                                                    </button>
                                                    <small class="summary-follow-up-status" role="status" aria-live="polite"></small>
                                                </div>
                                            @endif

                                            @if ($canManageEscalations && $isNo)
                                                <button type="button" class="button button-sm button-escalate"
                                                        data-action="open-escalate"
                                                        data-response-id="{{ $finding['response_id'] }}"
                                                        data-template="{{ $finding['template_name'] }}"
                                                        data-template-slug="{{ $finding['template_slug'] ?? '' }}"
                                                        data-auditor-role="{{ $finding['auditor_role'] ?? '' }}"
                                                        data-checker-role="{{ $finding['checker_role'] ?? '' }}"
                                                        data-is-restroom="{{ !empty($finding['is_restroom']) ? '1' : '0' }}"
                                                        data-branch="{{ $finding['branch'] }}"
                                                        data-item-key="{{ $finding['item_key'] }}"
                                                        data-item-prompt="{{ $finding['item'] }}"
                                                        data-finding="{{ $finding['detail'] }}"
                                                        data-bom-task="{{ $finding['bom_task'] ?? '' }}"
                                                        data-escalation="{{ $finding['escalation_target'] }}"
                                                        data-action-plan="{{ $finding['action_plan'] }}"
                                                        data-commitment="{{ $finding['commitment_date_input'] ?? '' }}"
                                                        title="Update escalation target, action plan, and commitment date planned">
                                                    <i class="fas fa-arrow-up-right-dots" aria-hidden="true"></i> Escalate / Action Plan
                                                </button>
                                            @endif

                                            @if ($finding['can_override'])
                                                <button type="button" class="button button-sm button-override"
                                                        data-action="open-override"
                                                        data-endpoint="{{ route('reports.responses.override', $finding['response_id']) }}"
                                                        data-response-id="{{ $finding['response_id'] }}"
                                                        data-template="{{ $finding['template_name'] }}"
                                                        data-template-slug="{{ $finding['template_slug'] ?? '' }}"
                                                        data-auditor-role="{{ $finding['auditor_role'] ?? '' }}"
                                                        data-checker-role="{{ $finding['checker_role'] ?? '' }}"
                                                        data-is-restroom="{{ !empty($finding['is_restroom']) ? '1' : '0' }}"
                                                        data-branch="{{ $finding['branch'] }}"
                                                        data-item-key="{{ $finding['item_key'] }}"
                                                        data-item-prompt="{{ $finding['item'] }}"
                                                        data-status="{{ $finding['status'] }}"
                                                        data-escalation="{{ $finding['escalation_target'] }}"
                                                        data-commitment="{{ $finding['commitment_date_local'] }}"
                                                        data-action-plan="{{ $finding['action_plan'] }}"
                                                        data-finding="{{ $finding['detail'] }}"
                                                        data-is-overridden="{{ $finding['is_overridden'] ? '1' : '0' }}"
                                                        data-overridden-at="{{ $finding['override_details']['overridden_at'] ?? '' }}"
                                                        data-overridden-at-formatted="{{ $finding['override_details']['overridden_at_formatted'] ?? '' }}"
                                                        data-overridden-by="{{ $finding['override_details']['overridden_by_name'] ?? '' }}"
                                                        data-overridden-role="{{ $finding['override_details']['overridden_by_role'] ?? '' }}"
                                                        data-override-reason="{{ $finding['override_details']['reason'] ?? '' }}"
                                                        data-override-attachment-url="{{ $finding['override_details']['attachment_url'] ?? '' }}"
                                                        data-override-attachment-name="{{ $finding['override_details']['attachment_name'] ?? '' }}"
                                                        title="Override checklist finding status with justification">
                                                    <i class="fas fa-pen-to-square" aria-hidden="true"></i> Override / Edit
                                                </button>
                                            @elseif (! $canViewFindings && ! $canManageEscalations)
                                                <span class="locked-badge" title="Only authorized users may manage or override NO answers in the checklist">
                                                    <i class="fas fa-lock" aria-hidden="true"></i> View Only
                                                </span>
                                            @endif
                                        </div>
                                    </td>
                                </tr>
                            @empty
                                <tr class="empty-row">
                                    <td colspan="7">
                                        <div class="empty-findings-box">
                                            <i class="fas fa-circle-check text-success" aria-hidden="true"></i>
                                            <strong>Zero Flagged NO Answers for {{ $selectedMonthLabel }}</strong>
                                            <p>All checklist responses recorded this month are currently compliant, or no audits have been filed yet.</p>
                                        </div>
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </section>

            <!-- Visual Charts & Analytics Section -->
            <section class="charts-grid" aria-label="Visual compliance breakdowns">
                <article class="chart-card span-8">
                    <div class="card-heading">
                        <div>
                            <h3>Compliance by Checklist</h3>
                            <p>Weighted compliance performance across active templates for {{ $selectedMonthLabel }}.</p>
                        </div>
                        <span class="card-badge">{{ $moduleSummaries->count() }} checklists</span>
                    </div>
                    <div class="chart-body">
                        @if ($moduleSummaries->isEmpty())
                            <div class="empty-chart">Checklist performance will appear once audit responses are recorded this month.</div>
                        @else
                            <div class="horizontal-bars">
                                @foreach ($moduleSummaries as $module)
                                    <div class="hbar-row">
                                        <div class="hbar-label" title="{{ $module['label'] }}">
                                            {{ $module['label'] }}{{ ($module['is_restroom_hourly'] ?? false) ? ' · Hourly' : '' }}
                                        </div>
                                        <div class="hbar-track" aria-label="{{ $module['label'] }} compliance {{ $formatPercent($module['score']) }}">
                                            <span class="hbar-fill" style="width:{{ $barWidth($module['score']) }}%"></span>
                                        </div>
                                        <div class="hbar-value">{{ $formatPercent($module['score']) }}</div>
                                    </div>
                                    <div class="stat-meta">{{ $module['count'] }} {{ Str::plural('audit', $module['count']) }} · {{ $module['findings_count'] }} {{ Str::plural('finding', $module['findings_count']) }} · {{ $formatPercent($module['completion']) }} complete</div>
                                @endforeach
                            </div>
                        @endif
                    </div>
                </article>

                <article class="chart-card span-4">
                    <div class="card-heading">
                        <div>
                            <h3>Response Distribution</h3>
                            <p>Proportion of compliant, non-compliant, and N/A judgments.</p>
                        </div>
                        <span class="card-badge">{{ number_format($summary['answered']) }} total</span>
                    </div>
                    <div class="chart-body">
                        @if ($summary['answered'] === 0)
                            <div class="empty-chart">Response distribution will populate after checklist judgments are saved.</div>
                        @else
                            <div class="horizontal-bars">
                                @foreach ([
                                    ['label' => 'YES / Passing', 'value' => $summary['yes'], 'color' => 'var(--success-green, #10b981)'],
                                    ['label' => 'NO / Deficient', 'value' => $summary['no'], 'color' => 'var(--gateway-red-500, #e31c3d)'],
                                    ['label' => 'N/A / Exempt', 'value' => $summary['na'], 'color' => 'var(--muted-slate, #64748b)'],
                                ] as $judgment)
                                    @php($judgmentPercent = $summary['answered'] > 0 ? ($judgment['value'] / $summary['answered']) * 100 : 0)
                                    <div class="hbar-row">
                                        <div class="hbar-label">{{ $judgment['label'] }}</div>
                                        <div class="hbar-track"><span class="hbar-fill" style="width:{{ $barWidth($judgmentPercent) }}%; background-color: {{ $judgment['color'] }};"></span></div>
                                        <div class="hbar-value">{{ number_format($judgment['value']) }}</div>
                                    </div>
                                @endforeach
                            </div>
                        @endif
                    </div>
                </article>

                <article class="chart-card span-6">
                    <div class="card-heading">
                        <div>
                            <h3>Branch Compliance Comparison</h3>
                            <p>Weighted pass rate and deficiency count by dealership facility.</p>
                        </div>
                        <span class="card-badge">{{ $branchSummaries->count() }} branches</span>
                    </div>
                    <div class="chart-body">
                        @if ($branchSummaries->isEmpty())
                            <div class="empty-chart">Branch comparisons will appear after audit records are submitted this month.</div>
                        @else
                            <div class="horizontal-bars">
                                @foreach ($branchSummaries as $branch)
                                    <div class="hbar-row">
                                        <div class="hbar-label" title="{{ $branch['label'] }}">{{ $branch['label'] }}</div>
                                        <div class="hbar-track"><span class="hbar-fill" style="width:{{ $barWidth($branch['score']) }}%"></span></div>
                                        <div class="hbar-value">{{ $formatPercent($branch['score']) }}</div>
                                    </div>
                                    <div class="stat-meta">{{ $branch['count'] }} {{ Str::plural('audit', $branch['count']) }} · {{ $branch['findings_count'] }} {{ Str::plural('finding', $branch['findings_count']) }}</div>
                                @endforeach
                            </div>
                        @endif
                    </div>
                </article>

                <article class="chart-card span-6">
                    <div class="card-heading">
                        <div>
                            <h3>Monthly Trend &amp; History</h3>
                            <p>Audit volumes, compliance trajectory, and findings over time.</p>
                        </div>
                        <span class="card-badge">{{ $monthlySummaries->count() }} historical months</span>
                    </div>
                    <div class="table-wrap">
                        <table>
                            <thead><tr><th>Month</th><th>Audits</th><th>Compliance</th><th>Completion</th><th>Findings</th></tr></thead>
                            <tbody>
                                @forelse ($monthlySummaries as $month)
                                    <tr class="{{ $month['label'] === $selectedMonthLabel ? 'active-month-row' : '' }}">
                                        <td>
                                            <strong>{{ $month['label'] }}</strong>
                                            @if ($month['label'] === $selectedMonthLabel)
                                                <span class="current-tag">Viewing</span>
                                            @endif
                                        </td>
                                        <td>{{ number_format($month['count']) }}</td>
                                        <td class="score-cell">{{ $formatPercent($month['score']) }}</td>
                                        <td>{{ $formatPercent($month['completion']) }}</td>
                                        <td>{{ number_format($month['findings_count']) }}</td>
                                    </tr>
                                @empty
                                    <tr class="empty-row"><td colspan="5">Historical monthly audit records will populate as submissions are archived.</td></tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </article>
            </section>

            <!-- Employee Checklist Activity Audit Log -->
            <section class="tables-grid" style="grid-template-columns:1fr" aria-label="Detailed audit submission records">
                <article class="table-card">
                    <div class="card-heading">
                        <div>
                            <h3>Employee Checklist Activity</h3>
                            <p>Audit trail recording submission timestamps, employee name, role, score, and findings count.</p>
                        </div>
                        <span class="card-badge">{{ number_format($history->count()) }} records</span>
                    </div>
                    <div class="table-wrap">
                        <table class="activity-table">
                            <thead>
                                <tr><th>Submitted At</th><th>Employee</th><th>Role</th><th>Checklist Module</th><th>Branch</th><th>Status</th><th>Score</th><th>Completion</th><th>Defects</th></tr>
                            </thead>
                            <tbody>
                                @forelse ($history as $record)
                                    <tr>
                                        <td class="submission-time">
                                            @if ($record['submitted_at'])
                                                @php($submittedAt = \Illuminate\Support\Carbon::parse($record['submitted_at'])->timezone($reportTimezone))
                                                <time datetime="{{ $record['submitted_at'] }}" title="{{ $submittedAt->format('d M Y, h:i:s A') }} {{ $reportTimezone }}">
                                                    <strong>{{ $submittedAt->format('d M Y') }}</strong>
                                                    <span>{{ $submittedAt->format('h:i A') }} · {{ $submittedAt->diffForHumans() }}</span>
                                                </time>
                                            @else
                                                <span class="muted-copy">In-progress Draft</span>
                                            @endif
                                        </td>
                                        <td class="employee-cell">
                                            <strong>{{ $record['submitter_name'] }}</strong>
                                            <span>{{ $record['submitter_email'] ?: 'No email recorded' }}</span>
                                        </td>
                                        <td>
                                            <span class="role-pill {{ strtolower($record['submitter_role_code']) }}">{{ $record['submitter_role_label'] }}</span>
                                        </td>
                                        <td>
                                            <strong>{{ $record['template_name'] }}</strong>
                                            <span class="activity-meta">Audit date {{ $record['audit_date'] ? \Illuminate\Support\Carbon::parse($record['audit_date'])->format('d M Y') : '—' }} · #{{ $record['id'] }}</span>
                                            @if ($record['is_restroom'])
                                                <br><span class="status-pill na">Dedicated Restroom{{ ($record['is_restroom_hourly'] ?? false) ? ' · Hourly' : '' }}</span>
                                            @endif
                                        </td>
                                        <td><strong>{{ $record['branch'] }}</strong></td>
                                        <td><span class="status-pill {{ $record['status'] }}">{{ ucfirst($record['status']) }}</span></td>
                                        <td class="score-cell">{{ $formatPercent($record['score']) }}</td>
                                        <td>{{ $formatPercent($record['completion']) }}<br><small>{{ $record['answered'] }}/{{ $record['total'] }}</small></td>
                                        <td>
                                            @if ($record['findings_count'] > 0)
                                                <span class="finding-count-badge">{{ $record['findings_count'] }}</span>
                                            @else
                                                <span class="text-success"><i class="fas fa-check"></i> 0</span>
                                            @endif
                                        </td>
                                    </tr>
                                @empty
                                    <tr class="empty-row"><td colspan="9">No employee checklist activity recorded for {{ $selectedMonthLabel }}.</td></tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </article>
            </section>

            <!-- Legal & Compliance Footnote -->
            <section class="panel source-note">
                <strong>Compliance basis:</strong> All analytics and findings are queried from verified MariaDB audit records. Reports are scoped strictly per calendar month (preset to current month {{ $selectedMonthLabel }}). NO answers and bad time slots are subject to authorized override by designated managers. Every override action is permanently recorded in the system audit log.
            </section>
        </main>
    </div>

    <!-- AUTHORIZED OVERRIDE MODAL -->
    <div class="override-modal-backdrop" id="overrideModalBackdrop" aria-hidden="true">
        <div class="override-modal" id="overrideModal" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
            <div class="modal-header">
                <div class="modal-title-wrap">
                    <span class="modal-eyebrow"><i class="fas fa-shield-halved"></i> Authorized Manager Action</span>
                    <h3 id="modalTitle">Override &amp; Edit Checklist Finding</h3>
                </div>
                <button type="button" class="modal-close-btn" id="closeOverrideModal" aria-label="Close dialog">&times;</button>
            </div>

            <form id="overrideForm" class="modal-form">
                <input type="hidden" id="overrideResponseId" name="response_id">

                <div class="modal-item-summary">
                    <div class="summary-line">
                        <strong id="modalTemplateName">Checklist</strong> &middot;
                        <span id="modalBranchName">Branch</span>
                    </div>
                    <div class="summary-prompt">
                        <code id="modalItemKey">CODE</code>
                        <strong id="modalItemPrompt">Item text</strong>
                    </div>
                </div>

                <div class="modal-fields-grid">
                    <!-- Status Override Choice -->
                    <div class="form-group span-full">
                        <label class="form-label">Resolution / Status Override <span class="required-asterisk">*</span></label>
                        <div class="status-radio-group">
                            <label class="status-radio-card">
                                <input type="radio" name="override_status" value="no" id="radioStatusNo">
                                <div class="radio-card-content">
                                    <span class="radio-title text-danger"><i class="fas fa-times-circle"></i> Keep as NO</span>
                                    <small>Maintain non-compliant finding</small>
                                </div>
                            </label>
                            <label class="status-radio-card">
                                <input type="radio" name="override_status" value="yes" id="radioStatusYes">
                                <div class="radio-card-content">
                                    <span class="radio-title text-success"><i class="fas fa-check-circle"></i> Override to YES</span>
                                    <small>Mark resolved / compliant</small>
                                </div>
                            </label>
                            <label class="status-radio-card">
                                <input type="radio" name="override_status" value="na" id="radioStatusNa">
                                <div class="radio-card-content">
                                    <span class="radio-title text-muted"><i class="fas fa-ban"></i> Override to N/A</span>
                                    <small>Mark not applicable / exempt</small>
                                </div>
                            </label>
                        </div>
                    </div>

                    <!-- Escalation Target -->
                    <div class="form-group span-half">
                        <label for="modalEscalation" class="form-label">
                            <i class="fas fa-share-nodes"></i> Suggested Escalation To
                        </label>
                        <select id="modalEscalation" name="escalation_target" class="form-select">
                            <option value="">No Escalation Required</option>
                            @foreach ($escalationOptions as $escKey => $escLabel)
                                <option value="{{ $escKey }}">{{ $escLabel }}</option>
                            @endforeach
                        </select>
                        <span class="field-hint">Identify who this deficiency should be escalated to.</span>
                    </div>

                    <!-- Commitment Date and Time -->
                    <div class="form-group span-half">
                        <label for="modalCommitmentDate" class="form-label">
                            <i class="fas fa-calendar-clock"></i> Commitment Date &amp; Time
                        </label>
                        <input type="datetime-local" id="modalCommitmentDate" name="commitment_date" class="form-input" step="60">
                        <span class="field-hint">Target resolution date and exact commitment time.</span>
                    </div>

                    <!-- Action Plan -->
                    <div class="form-group span-full">
                        <label for="modalActionPlan" class="form-label">
                            <i class="fas fa-wrench"></i> Action Plan
                        </label>
                        <textarea id="modalActionPlan" name="action_plan" class="form-textarea" rows="2" placeholder="Corrective action plan to remedy this deficiency"></textarea>
                    </div>

                    <!-- Finding / Remarks -->
                    <div class="form-group span-full">
                        <label for="modalFinding" class="form-label">
                            <i class="fas fa-file-lines"></i> Finding / Remarks
                        </label>
                        <textarea id="modalFinding" name="finding" class="form-textarea" rows="2" placeholder="Deficiency details or resolution remarks"></textarea>
                    </div>

                    <!-- Override Reason / Notes -->
                    <div class="form-group span-full">
                        <label for="modalOverrideReason" class="form-label">
                            <i class="fas fa-comment-dots"></i> Manager Override Justification / Reason <span class="required-asterisk">*</span>
                        </label>
                        <textarea id="modalOverrideReason" name="override_reason" class="form-textarea" rows="2" placeholder="Specify why this response is being overridden or edited (e.g., Verified rectified on-site, Approved warranty replacement, Exemption granted)"></textarea>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button" class="button" id="cancelOverrideBtn">Cancel</button>
                    <button type="submit" class="button primary" id="saveOverrideBtn">
                        <i class="fas fa-save" aria-hidden="true"></i> Save &amp; Apply Override
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- ESCALATION / ACTION PLAN MODAL -->
    @if ($canManageEscalations)
    <div class="override-modal-backdrop" id="escalateModalBackdrop" aria-hidden="true">
        <div class="override-modal" id="escalateModal" role="dialog" aria-modal="true" aria-labelledby="escalateModalTitle">
            <div class="modal-header">
                <div class="modal-title-wrap">
                    <span class="modal-eyebrow"><i class="fas fa-arrow-up-right-dots"></i> Action Plan</span>
                    <h3 id="escalateModalTitle">Escalate Finding &amp; Set Action Plan</h3>
                </div>
                <button type="button" class="modal-close-btn" id="closeEscalateModal" aria-label="Close dialog">&times;</button>
            </div>

            <form id="escalateForm" class="modal-form" data-endpoint="{{ route('reports.responses.escalations') }}">
                <input type="hidden" id="escalateResponseId" name="response_id">

                <div class="modal-item-summary">
                    <div class="summary-line">
                        <strong id="escalateTemplateName">Checklist</strong> &middot;
                        <span id="escalateBranchName">Branch</span>
                    </div>
                    <div class="summary-prompt">
                        <code id="escalateItemKey">CODE</code>
                        <strong id="escalateItemPrompt">Item text</strong>
                    </div>
                </div>

                <div class="summary-modal-callout">
                    <i class="fas fa-shield-halved" aria-hidden="true"></i>
                    <span>Set the recipient, Action Plan, and Commitment Date Planned. Saving these details does not change the original <strong>NO</strong> result.</span>
                </div>

                <div class="modal-fields-grid">
                    <!-- Finding Detail (Read-only reference) -->
                    <div class="form-group span-full">
                        <label class="form-label"><i class="fas fa-triangle-exclamation"></i> Recorded Finding</label>
                        <div class="finding-static-box" id="escalateFindingDetail"></div>
                    </div>

                    <div class="form-group span-full" id="escalateBomTaskGroup" style="display:none;">
                        <label class="form-label"><i class="fas fa-list-check"></i> Task</label>
                        <div class="finding-static-box bom-task-box" id="escalateBomTask"></div>
                    </div>

                    <!-- Escalation Recipient -->
                    <div class="form-group span-half">
                        <label for="escalateSelectTarget" class="form-label">
                            <i class="fas fa-share-nodes"></i> Escalate To
                        </label>
                        <select id="escalateSelectTarget" name="escalation_target" class="form-select" required>
                            <option value="">Select a recipient</option>
                            @foreach ($escalationOptions as $escKey => $escLabel)
                                <option value="{{ $escKey }}">{{ $escLabel }}</option>
                            @endforeach
                        </select>
                        <span class="field-hint">Department or manager responsible for addressing this finding.</span>
                    </div>

                    <!-- Commitment Date Planned -->
                    <div class="form-group span-half">
                        <label for="escalateCommitmentDate" class="form-label">
                            <i class="fas fa-calendar-day"></i> Commitment Date Planned
                        </label>
                        <input type="date" id="escalateCommitmentDate" name="commitment_date" class="form-input" required>
                        <span class="field-hint">Target planned resolution date.</span>
                    </div>

                    <!-- Action Plan -->
                    <div class="form-group span-full">
                        <label for="escalateActionPlan" class="form-label">
                            <i class="fas fa-wrench"></i> Action Plan
                        </label>
                        <textarea id="escalateActionPlan" name="action_plan" class="form-textarea" rows="4" maxlength="10000" placeholder="Write the corrective action plan here..." required></textarea>
                    </div>
                </div>

                <div class="modal-footer">
                    <div class="summary-escalation-status" id="escalateStatus" role="status" aria-live="polite"></div>
                    <button type="button" class="button" id="cancelEscalateBtn">Cancel</button>
                    <button type="submit" class="button primary" id="saveEscalateBtn">
                        <i class="fas fa-floppy-disk" aria-hidden="true"></i> Save Changes
                    </button>
                </div>
            </form>
        </div>
    </div>
    @endif

    <!-- Scripts -->
    <script>
        (() => {
            const sidebar = document.getElementById('sidebar');
            const mainShell = document.getElementById('mainShell');
            const sidebarBackdrop = document.getElementById('sidebarBackdrop');
            const sidebarToggle = document.getElementById('sidebarToggle');
            const mobileMenuButton = document.getElementById('mobileMenuButton');
            const printButton = document.getElementById('printButton');

            const setDesktopSidebarCollapsed = (collapsed) => {
                if (!sidebar || !mainShell || !sidebarToggle) return;

                sidebar.classList.toggle('desktop-collapsed', collapsed);
                mainShell.classList.toggle('sidebar-collapsed', collapsed);
                sidebarToggle.classList.toggle('is-active', collapsed);
                sidebarToggle.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
                sidebarToggle.setAttribute('aria-label', collapsed ? 'Expand navigation' : 'Collapse navigation');
                const icon = sidebarToggle.querySelector('i');
                if (icon) icon.className = collapsed ? 'fas fa-angles-right' : 'fas fa-angles-left';
                localStorage.setItem('gatewaySidebarCollapsed', collapsed ? '1' : '0');
            };

            sidebarToggle?.addEventListener('click', () => {
                setDesktopSidebarCollapsed(!sidebar?.classList.contains('desktop-collapsed'));
            });

            mobileMenuButton?.addEventListener('click', () => {
                sidebar?.classList.add('mobile-open');
                sidebarBackdrop?.classList.add('visible');
            });

            sidebarBackdrop?.addEventListener('click', () => {
                sidebar?.classList.remove('mobile-open');
                sidebarBackdrop.classList.remove('visible');
            });

            if (localStorage.getItem('gatewaySidebarCollapsed') === '1' && window.innerWidth > 900) {
                setDesktopSidebarCollapsed(true);
            }

            printButton?.addEventListener('click', () => window.print());

            // Findings Table Filter Pills
            const filterPills = document.querySelectorAll('[data-filter-tab]');
            const findingRows = document.querySelectorAll('.finding-row');

            filterPills.forEach(pill => {
                pill.addEventListener('click', () => {
                    filterPills.forEach(p => p.classList.remove('active'));
                    pill.classList.add('active');
                    const tab = pill.dataset.filterTab;

                    findingRows.forEach(row => {
                        let show = true;
                        if (tab === 'no') {
                            show = row.dataset.isNo === 'true';
                        } else if (tab === 'overdue') {
                            show = row.dataset.isOverdue === 'true';
                        } else if (tab === 'escalated') {
                            show = row.dataset.isEscalated === 'true';
                        } else if (tab === 'overridden') {
                            show = row.dataset.isOverridden === 'true';
                        }
                        row.style.display = show ? '' : 'none';
                    });
                });
            });

            const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';

            // GM Finding Follow-up
            @if ($canViewFindings)
            document.querySelectorAll('[data-request-finding-follow-up]').forEach((button) => {
                button.addEventListener('click', async () => {
                    if (button.disabled) return;

                    const status = button.closest('.follow-up-action-wrap')?.querySelector('.summary-follow-up-status')
                        || button.parentElement?.querySelector('.summary-follow-up-status');
                    const label = button.querySelector('span');
                    button.disabled = true;
                    button.classList.add('is-loading');
                    if (label) label.textContent = 'Sending...';
                    if (status) {
                        status.className = 'summary-follow-up-status';
                        status.textContent = '';
                    }

                    try {
                        const response = await fetch(button.dataset.endpoint, {
                            method: 'POST',
                            headers: {
                                Accept: 'application/json',
                                'Content-Type': 'application/json',
                                'X-CSRF-TOKEN': csrfToken,
                            },
                            credentials: 'same-origin',
                            body: JSON.stringify({}),
                        });
                        const data = await response.json().catch(() => ({}));

                        if (!response.ok) {
                            throw new Error(data.message || 'Follow-up notification could not be sent.');
                        }

                        button.classList.remove('is-loading');
                        button.classList.add('is-sent');
                        if (label) label.textContent = 'Follow-up Sent';
                        if (status) {
                            status.classList.add('is-success');
                            status.textContent = data.message || 'Follow-up sent successfully.';
                        }
                    } catch (error) {
                        button.disabled = false;
                        button.classList.remove('is-loading');
                        if (label) label.textContent = 'Follow-up';
                        if (status) {
                            status.classList.add('is-error');
                            status.textContent = error.message || 'Follow-up notification could not be sent.';
                        }
                    }
                });
            });
            @endif

            @if ($canManageEscalations || $showOverrideActions)
            const escalationOptionsMap = @json($escalationOptionsMap ?? \App\Models\ChecklistResponse::contextualEscalationOptionsMap());

            function resolveEscalationOptions(data) {
                const templateSlug = (data.templateSlug || '').toLowerCase();
                const auditorRole = (data.auditorRole || '').toLowerCase();
                const checkerRole = (data.checkerRole || '').toLowerCase();
                const isRestroom = data.isRestroom === '1' || templateSlug === 'restroom' || templateSlug === 'utilities';

                if (isRestroom || auditorRole.includes('utility') || checkerRole.includes('utility')) {
                    return escalationOptionsMap.utility || { property_management: 'Property Management (PM)', general_manager: 'General Manager (GM)' };
                }

                if (templateSlug.includes('sales') && templateSlug.includes('dealer-operations')) {
                    return escalationOptionsMap.sales || escalationOptionsMap.default;
                }
                if (auditorRole.includes('sales manager') || checkerRole.includes('sales manager')) {
                    return escalationOptionsMap.sales || escalationOptionsMap.default;
                }

                const isAftersales = templateSlug.includes('dealer-operations') ||
                    auditorRole.includes('aftersales') || auditorRole.includes('ce') ||
                    auditorRole.includes('job controller') || auditorRole.includes('parts') ||
                    auditorRole.includes('workshop');

                if (isAftersales) {
                    if (checkerRole.includes('jc') || checkerRole.includes('job controller') ||
                        checkerRole.includes('parts') || checkerRole.includes('workshop') ||
                        auditorRole.includes('job controller') || auditorRole.includes('parts') ||
                        auditorRole.includes('workshop')) {
                        return escalationOptionsMap.aftersales_single_gm || { general_manager: 'General Manager (GM)' };
                    }
                    if (checkerRole.includes('asm') || auditorRole.includes('aftersales manager')) {
                        return escalationOptionsMap.aftersales_asm || escalationOptionsMap.aftersales;
                    }
                    if (checkerRole.includes('ce') || auditorRole.includes('ce service')) {
                        return escalationOptionsMap.aftersales_ce || escalationOptionsMap.aftersales;
                    }
                    return escalationOptionsMap.aftersales || escalationOptionsMap.default;
                }

                if (templateSlug === 'sales' || templateSlug === 'service' || templateSlug === '5s') {
                    return escalationOptionsMap.five_s || escalationOptionsMap.default;
                }

                return escalationOptionsMap.default;
            }

            function populateEscalationSelect(selectElem, options, selectedValue, defaultLabel) {
                if (!selectElem) return;
                selectElem.innerHTML = '';
                const defaultOpt = document.createElement('option');
                defaultOpt.value = '';
                defaultOpt.textContent = defaultLabel;
                selectElem.appendChild(defaultOpt);

                let hasSelected = false;
                for (const [val, label] of Object.entries(options || {})) {
                    const opt = document.createElement('option');
                    opt.value = val;
                    opt.textContent = label;
                    if (selectedValue && val === selectedValue) {
                        opt.selected = true;
                        hasSelected = true;
                    }
                    selectElem.appendChild(opt);
                }

                if (selectedValue && !hasSelected) {
                    const opt = document.createElement('option');
                    opt.value = selectedValue;
                    opt.textContent = selectedValue.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
                    opt.selected = true;
                    selectElem.appendChild(opt);
                }
            }
            @endif

            // BOM Escalation & Action Plan Modal
            @if ($canManageEscalations)
            const escalateModal = document.getElementById('escalateModal');
            const escalateBackdrop = document.getElementById('escalateModalBackdrop');
            const closeEscalateBtn = document.getElementById('closeEscalateModal');
            const cancelEscalateBtn = document.getElementById('cancelEscalateBtn');
            const escalateForm = document.getElementById('escalateForm');
            const escalateStatus = document.getElementById('escalateStatus');
            const saveEscalateBtn = document.getElementById('saveEscalateBtn');

            function openEscalateModal(data) {
                document.getElementById('escalateResponseId').value = data.responseId || '';
                document.getElementById('escalateTemplateName').textContent = data.template || 'Checklist';
                document.getElementById('escalateBranchName').textContent = data.branch || 'Branch';
                document.getElementById('escalateItemKey').textContent = data.itemKey || 'ITEM';
                document.getElementById('escalateItemPrompt').textContent = data.itemPrompt || '';
                document.getElementById('escalateFindingDetail').textContent = data.finding || 'No finding recorded.';

                const bomTaskGroup = document.getElementById('escalateBomTaskGroup');
                const bomTaskBox = document.getElementById('escalateBomTask');
                if (data.bomTask && data.bomTask.trim()) {
                    bomTaskBox.textContent = data.bomTask;
                    bomTaskGroup.style.display = '';
                } else {
                    bomTaskGroup.style.display = 'none';
                }

                const options = resolveEscalationOptions(data);
                populateEscalationSelect(document.getElementById('escalateSelectTarget'), options, data.escalation || '', 'Select a recipient');
                document.getElementById('escalateCommitmentDate').value = data.commitment || '';
                document.getElementById('escalateActionPlan').value = data.actionPlan || '';

                if (escalateStatus) {
                    escalateStatus.className = 'summary-escalation-status';
                    escalateStatus.textContent = '';
                }

                escalateBackdrop?.classList.add('visible');
                escalateModal?.classList.add('visible');
            }

            function closeEscalateModalDialog() {
                escalateBackdrop?.classList.remove('visible');
                escalateModal?.classList.remove('visible');
            }

            document.querySelectorAll('[data-action="open-escalate"]').forEach(btn => {
                btn.addEventListener('click', () => {
                    openEscalateModal({
                        responseId: btn.dataset.responseId,
                        template: btn.dataset.template,
                        templateSlug: btn.dataset.templateSlug,
                        auditorRole: btn.dataset.auditorRole,
                        checkerRole: btn.dataset.checkerRole,
                        isRestroom: btn.dataset.isRestroom,
                        branch: btn.dataset.branch,
                        itemKey: btn.dataset.itemKey,
                        itemPrompt: btn.dataset.itemPrompt,
                        finding: btn.dataset.finding,
                        bomTask: btn.dataset.bomTask,
                        escalation: btn.dataset.escalation,
                        actionPlan: btn.dataset.actionPlan,
                        commitment: btn.dataset.commitment,
                    });
                });
            });

            closeEscalateBtn?.addEventListener('click', closeEscalateModalDialog);
            cancelEscalateBtn?.addEventListener('click', closeEscalateModalDialog);
            escalateBackdrop?.addEventListener('click', (e) => {
                if (e.target === escalateBackdrop) closeEscalateModalDialog();
            });

            escalateForm?.addEventListener('submit', async (e) => {
                e.preventDefault();
                const responseId = Number(document.getElementById('escalateResponseId').value);
                const escalationTarget = document.getElementById('escalateSelectTarget').value || null;
                const commitmentDate = document.getElementById('escalateCommitmentDate').value || null;
                const actionPlan = document.getElementById('escalateActionPlan').value.trim() || null;

                saveEscalateBtn.disabled = true;
                saveEscalateBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
                if (escalateStatus) {
                    escalateStatus.className = 'summary-escalation-status';
                    escalateStatus.textContent = 'Saving finding follow-up details...';
                }

                try {
                    const res = await fetch(escalateForm.dataset.endpoint, {
                        method: 'PATCH',
                        headers: {
                            'Accept': 'application/json',
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': csrfToken,
                        },
                        body: JSON.stringify({
                            responses: [
                                {
                                    id: responseId,
                                    escalation_target: escalationTarget,
                                    action_plan: actionPlan,
                                    commitment_date: commitmentDate,
                                }
                            ]
                        }),
                    });

                    const data = await res.json().catch(() => ({}));
                    if (!res.ok) {
                        throw new Error(data.message || 'The finding follow-up details could not be saved.');
                    }

                    if (escalateStatus) {
                        escalateStatus.classList.add('is-success');
                        escalateStatus.textContent = data.message || 'Finding follow-up details saved.';
                    }

                    window.location.reload();
                } catch (err) {
                    if (escalateStatus) {
                        escalateStatus.classList.add('is-error');
                        escalateStatus.textContent = err.message || 'Failed to save finding details.';
                    }
                } finally {
                    saveEscalateBtn.disabled = false;
                    saveEscalateBtn.innerHTML = '<i class="fas fa-floppy-disk" aria-hidden="true"></i> Save Changes';
                }
            });
            @endif

            // Override Modal Handling
            const overrideModal = document.getElementById('overrideModal');
            const modalBackdrop = document.getElementById('overrideModalBackdrop');
            const closeBtn = document.getElementById('closeOverrideModal');
            const cancelBtn = document.getElementById('cancelOverrideBtn');
            const overrideForm = document.getElementById('overrideForm');

            function openModal(data) {
                document.getElementById('overrideResponseId').value = data.responseId || '';
                document.getElementById('modalTemplateName').textContent = data.template || 'Checklist';
                document.getElementById('modalBranchName').textContent = data.branch || 'Branch';
                document.getElementById('modalItemKey').textContent = data.itemKey || 'ITEM';
                document.getElementById('modalItemPrompt').textContent = data.itemPrompt || '';

                const status = (data.status || 'no').toLowerCase();
                if (status === 'yes') {
                    document.getElementById('radioStatusYes').checked = true;
                } else if (status === 'na') {
                    document.getElementById('radioStatusNa').checked = true;
                } else {
                    document.getElementById('radioStatusNo').checked = true;
                }

                const options = resolveEscalationOptions(data);
                populateEscalationSelect(document.getElementById('modalEscalation'), options, data.escalation || '', 'No Escalation Required');
                document.getElementById('modalCommitmentDate').value = data.commitment || '';
                document.getElementById('modalActionPlan').value = data.actionPlan || '';
                document.getElementById('modalFinding').value = data.finding || '';
                document.getElementById('modalOverrideReason').value = '';

                modalBackdrop.classList.add('visible');
                overrideModal.classList.add('visible');
            }

            function closeModal() {
                modalBackdrop.classList.remove('visible');
                overrideModal.classList.remove('visible');
            }

            document.querySelectorAll('[data-action="open-override"]').forEach(btn => {
                btn.addEventListener('click', () => {
                    openModal({
                        responseId: btn.dataset.responseId,
                        template: btn.dataset.template,
                        templateSlug: btn.dataset.templateSlug,
                        auditorRole: btn.dataset.auditorRole,
                        checkerRole: btn.dataset.checkerRole,
                        isRestroom: btn.dataset.isRestroom,
                        branch: btn.dataset.branch,
                        itemKey: btn.dataset.itemKey,
                        itemPrompt: btn.dataset.itemPrompt,
                        status: btn.dataset.status,
                        escalation: btn.dataset.escalation,
                        commitment: btn.dataset.commitment,
                        actionPlan: btn.dataset.actionPlan,
                        finding: btn.dataset.finding,
                    });
                });
            });

            closeBtn?.addEventListener('click', closeModal);
            cancelBtn?.addEventListener('click', closeModal);
            modalBackdrop?.addEventListener('click', (e) => {
                if (e.target === modalBackdrop) closeModal();
            });

            document.addEventListener('keydown', (e) => {
                if (e.key === 'Escape') {
                    if (modalBackdrop?.classList.contains('visible')) {
                        closeModal();
                    }
                    @if ($canManageEscalations)
                    if (escalateBackdrop?.classList.contains('visible')) {
                        closeEscalateModalDialog();
                    }
                    @endif
                }
            });

            // Form Submit via AJAX
            overrideForm?.addEventListener('submit', async (e) => {
                e.preventDefault();
                const saveBtn = document.getElementById('saveOverrideBtn');
                const responseId = document.getElementById('overrideResponseId').value;
                const status = overrideForm.querySelector('input[name="override_status"]:checked')?.value || 'no';
                const escalationTarget = document.getElementById('modalEscalation').value;
                const commitmentDate = document.getElementById('modalCommitmentDate').value;
                const actionPlan = document.getElementById('modalActionPlan').value;
                const finding = document.getElementById('modalFinding').value;
                const overrideReason = document.getElementById('modalOverrideReason').value;

                if (!overrideReason.trim()) {
                    alert('Please provide an override justification/reason.');
                    document.getElementById('modalOverrideReason').focus();
                    return;
                }

                saveBtn.disabled = true;
                saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';

                try {
                    const res = await fetch(`/reports/responses/${responseId}/override`, {
                        method: 'PATCH',
                        headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                            'X-CSRF-TOKEN': csrfToken,
                        },
                        body: JSON.stringify({
                            status: status,
                            escalation_target: escalationTarget || null,
                            commitment_date: commitmentDate || null,
                            action_plan: actionPlan || null,
                            finding: finding || null,
                            override_reason: overrideReason,
                        }),
                    });

                    const data = await res.json();
                    if (!res.ok) {
                        throw new Error(data.message || 'Failed to save override.');
                    }

                    // Success - refresh the table row or reload
                    closeModal();

                    // Reload page to reflect updated scores and charts
                    window.location.reload();
                } catch (err) {
                    alert(err.message || 'An error occurred while saving the override.');
                } finally {
                    saveBtn.disabled = false;
                    saveBtn.innerHTML = '<i class="fas fa-save"></i> Save &amp; Apply Override';
                }
            });

            // Auto-scroll and focus to highlighted finding if follow_up_response_id is passed
            const highlightedFollowUp = document.querySelector('[data-follow-up-highlight]');
            if (highlightedFollowUp) {
                window.requestAnimationFrame(() => {
                    highlightedFollowUp.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    highlightedFollowUp.focus({ preventScroll: true });
                });
            }
        })();
    </script>

    @include('partials.notifications-modal')
</body>
</html>
