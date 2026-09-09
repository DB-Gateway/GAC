@php
    $cards = $summarySheet['cards'];
    $isBelowTarget = $cards['is_below_target'];
    $overallScores = $summarySheet['overallScores'];
    $overallSummary = $summarySheet['overallSummaryRow'];
    $coverageRows = $summarySheet['coverageRows'];
    $coverageSummary = $summarySheet['coverageSummaryRow'];
    $activeForm = $summarySheet['activeForm'];
    $canManageFindings = $summarySheet['canManageFindings'];
    $nonCompliantFindings = $summarySheet['nonCompliantFindings'];
    $escalationOptions = $summarySheet['escalationOptions'];
    $summaryMode = $summarySheet['summaryMode'];
    $summaryScopeQuery = array_filter([
        'branch' => $summarySheet['selectedBranch'],
        'user_id' => $summarySheet['selectedUserId'],
        'user_type' => $summarySheet['selectedUserType'],
        'score_view' => $summaryMode,
    ], static fn ($value) => $value !== null && $value !== '');
    $perUserScoreUrl = route('dashboard', array_filter([
        'form' => $activeForm,
        'branch' => $summarySheet['selectedBranch'],
        'score_view' => 'user',
        'user_id' => $summarySheet['selectedUserId'],
        'user_type' => $summarySheet['selectedUserType'],
    ], static fn ($value) => $value !== null && $value !== ''));
    $overallScoreUrl = route('dashboard', array_filter([
        'form' => 'aftersales',
        'branch' => $summarySheet['selectedBranch'],
        'score_view' => 'overall',
    ], static fn ($value) => $value !== null && $value !== ''));
@endphp

<div class="summary-sheet-wrapper">
    {{-- TOP 4 STAT CARDS --}}
    <section class="summary-cards-grid" aria-label="Audit summary metrics">
        {{-- Card 1: Audit Completion (Total Answered Questions) --}}
        <article class="summary-card {{ $isBelowTarget ? 'card-caution' : 'card-success' }}" id="auditCompletionCard">
            <div class="summary-card-top">
                <div>
                    <span class="summary-card-label">Audit Completion</span>
                    <span class="summary-card-kicker">Answered Questions</span>
                </div>
                <div class="summary-card-icon" aria-hidden="true">
                    @if ($isBelowTarget)
                        <i class="fas fa-triangle-exclamation"></i>
                    @else
                        <i class="fas fa-circle-check"></i>
                    @endif
                </div>
            </div>
            <div class="summary-card-body">
                <div class="summary-card-value">{{ number_format($cards['completion_rate'], 1) }}%</div>
                @if ($isBelowTarget)
                    <div class="summary-card-badge badge-danger">
                        <i class="fas fa-triangle-exclamation"></i> Below 90% Threshold
                    </div>
                @else
                    <div class="summary-card-badge badge-success">
                        <i class="fas fa-circle-check"></i> Target Met (&ge;90%)
                    </div>
                @endif
                <div class="summary-card-progress {{ $isBelowTarget ? 'progress-danger' : 'progress-success' }}" role="progressbar" aria-valuenow="{{ $cards['completion_rate'] }}" aria-valuemin="0" aria-valuemax="100">
                    <span style="width: {{ min(100, max(0, $cards['completion_rate'])) }}%"></span>
                </div>
            </div>
            <div class="summary-card-footer">
                <span><strong>{{ $cards['answered'] }}</strong> of {{ $cards['total_questions'] }} items answered</span>
            </div>
        </article>

        {{-- Card 2: Count of YES --}}
        <article class="summary-card card-yes" id="countYesCard">
            <div class="summary-card-top">
                <div>
                    <span class="summary-card-label">Compliant (Yes)</span>
                    <span class="summary-card-kicker">Passed Standards</span>
                </div>
                <div class="summary-card-icon" aria-hidden="true">
                    <i class="fas fa-circle-check"></i>
                </div>
            </div>
            <div class="summary-card-body">
                <div class="summary-card-value">{{ $cards['count_yes'] }}</div>
                <div class="summary-card-badge badge-success">
                    <i class="fas fa-check"></i> {{ $cards['answered'] > 0 ? round(($cards['count_yes'] / $cards['answered']) * 100, 1) : 0 }}% of Answered
                </div>
                <div class="summary-card-progress progress-success">
                    <span style="width: {{ $cards['answered'] > 0 ? round(($cards['count_yes'] / $cards['answered']) * 100, 1) : 0 }}%"></span>
                </div>
            </div>
            <div class="summary-card-footer">
                <span>Evaluated as compliant</span>
            </div>
        </article>

        {{-- Card 3: Count of NO --}}
        <article class="summary-card card-no" id="countNoCard">
            <div class="summary-card-top">
                <div>
                    <span class="summary-card-label">Non-Compliant (No)</span>
                    <span class="summary-card-kicker">Action Required</span>
                </div>
                <div class="summary-card-icon" aria-hidden="true">
                    <i class="fas fa-circle-xmark"></i>
                </div>
            </div>
            <div class="summary-card-body">
                <div class="summary-card-value">{{ $cards['count_no'] }}</div>
                <div class="summary-card-badge badge-danger">
                    <i class="fas fa-triangle-exclamation"></i> Findings Recorded
                </div>
                <div class="summary-card-progress progress-danger">
                    <span style="width: {{ $cards['answered'] > 0 ? round(($cards['count_no'] / $cards['answered']) * 100, 1) : 0 }}%"></span>
                </div>
            </div>
            @if ($summaryMode === 'overall')
                <div class="summary-card-footer">
                    <span>Combined from each user's latest Aftersales audit</span>
                </div>
            @elseif ($canManageFindings)
                <div class="summary-card-footer summary-card-footer-actions">
                    <button type="button"
                            class="summary-card-action summary-card-action-secondary"
                            data-summary-modal-target="summaryFindingsModal"
                            {{ $nonCompliantFindings->isEmpty() ? 'disabled' : '' }}>
                        <i class="fas fa-magnifying-glass" aria-hidden="true"></i>
                        View Findings
                    </button>
                    <button type="button"
                            class="summary-card-action summary-card-action-danger"
                            data-summary-modal-target="summaryEscalationModal"
                            {{ $nonCompliantFindings->isEmpty() ? 'disabled' : '' }}>
                        <i class="fas fa-arrow-up-right-dots" aria-hidden="true"></i>
                        Escalation
                    </button>
                </div>
            @else
                <div class="summary-card-footer">
                    <span>Requires action plan &amp; escalation</span>
                </div>
            @endif
        </article>

        {{-- Card 4: Count of N/A --}}
        <article class="summary-card card-na" id="countNaCard">
            <div class="summary-card-top">
                <div>
                    <span class="summary-card-label">Not Applicable (N/A)</span>
                    <span class="summary-card-kicker">Excluded Items</span>
                </div>
                <div class="summary-card-icon" aria-hidden="true">
                    <i class="fas fa-circle-minus"></i>
                </div>
            </div>
            <div class="summary-card-body">
                <div class="summary-card-value">{{ $cards['count_na'] }}</div>
                <div class="summary-card-badge" style="background:#f1f5f9; color:#475569; border: 1px solid #cbd5e1;">
                    <i class="fas fa-minus"></i> Excluded Baseline
                </div>
                <div class="summary-card-progress" style="background:#e2e8f0;">
                    <span style="width: {{ $cards['answered'] > 0 ? round(($cards['count_na'] / $cards['answered']) * 100, 1) : 0 }}%; background: #64748b;"></span>
                </div>
            </div>
            <div class="summary-card-footer">
                <span>Excluded from scoring denominator</span>
            </div>
        </article>
    </section>

    {{-- CONTROLS & SWITCHER BAR --}}
    <section class="summary-control-bar" aria-label="Summary sheet navigation and controls">
        {{-- Form Switcher Pills: Sales vs Aftersales --}}
        <div class="summary-pills-switcher" role="tablist">
            <a href="{{ route('dashboard', array_merge($summaryScopeQuery, ['form' => 'sales'])) }}"
               class="summary-pill-btn {{ $activeForm === 'sales' ? 'active' : '' }}"
               role="tab"
               aria-selected="{{ $activeForm === 'sales' ? 'true' : 'false' }}">
                <i class="fas fa-car" aria-hidden="true"></i>
                <span>Sales Standards (FY25)</span>
            </a>
            <a href="{{ route('dashboard', array_merge($summaryScopeQuery, ['form' => 'aftersales'])) }}"
               class="summary-pill-btn {{ $activeForm === 'aftersales' ? 'active' : '' }}"
               role="tab"
               aria-selected="{{ $activeForm === 'aftersales' ? 'true' : 'false' }}">
                <i class="fas fa-screwdriver-wrench" aria-hidden="true"></i>
                <span>Aftersales Standards (FY25)</span>
            </a>
        </div>

        @if ($summarySheet['canSwitchSummaryMode'])
            <div class="summary-score-switcher" role="group" aria-label="Aftersales score view">
                <a href="{{ $perUserScoreUrl }}"
                   class="summary-score-switch {{ $summaryMode === 'user' ? 'active' : '' }}"
                   aria-pressed="{{ $summaryMode === 'user' ? 'true' : 'false' }}">
                    <i class="fas fa-user" aria-hidden="true"></i>
                    Per User
                </a>
                <a href="{{ $overallScoreUrl }}"
                   class="summary-score-switch {{ $summaryMode === 'overall' ? 'active' : '' }}"
                   aria-pressed="{{ $summaryMode === 'overall' ? 'true' : 'false' }}">
                    <i class="fas fa-users" aria-hidden="true"></i>
                    Overall Aftersales
                </a>
            </div>
        @endif

        {{-- Filter dropdowns: Branch & Submission --}}
        <form action="{{ route('dashboard') }}" method="GET" class="summary-filters-form" id="summaryFilterForm">
            <input type="hidden" name="form" value="{{ $activeForm }}">
            <input type="hidden" name="score_view" value="{{ $summaryMode }}">
            <input type="hidden" name="user_type" id="summaryUserType" value="{{ $summarySheet['selectedUserType'] }}">

            @if ($isAdministrator)
                <div class="summary-filter-group">
                    <label for="summaryBranchSelect"><i class="fas fa-location-dot"></i> Outlet:</label>
                    <select name="branch" id="summaryBranchSelect" class="summary-select" onchange="this.form.submit()">
                        @foreach ($summarySheet['availableBranches'] as $b)
                            <option value="{{ $b }}" {{ strcasecmp($b, $summarySheet['selectedBranch']) === 0 ? 'selected' : '' }}>
                                {{ $b }}
                            </option>
                        @endforeach
                    </select>
                </div>
            @endif

            @if ($summarySheet['canSelectUser'] && $summaryMode === 'user')
                <div class="summary-filter-group">
                    <label for="summaryUserSelect"><i class="fas fa-user"></i> User:</label>
                    <select name="user_id"
                            id="summaryUserSelect"
                            class="summary-select"
                            onchange="document.getElementById('summaryUserType').value = this.selectedOptions[0]?.dataset.userType || ''; this.form.submit()">
                        <option value="" data-user-type="" disabled>Select a user</option>
                        @foreach ($summarySheet['availableUsers'] as $summaryUser)
                            <option value="{{ $summaryUser->id }}"
                                    data-user-type="{{ $summaryUser->roleCode() }}"
                                    @selected((int) $summaryUser->id === (int) $summarySheet['selectedUserId'])>
                                {{ $summaryUser->name }} &mdash; {{ $summaryUser->roleLabel() }} &mdash; {{ trim((string) $summaryUser->branch) ?: 'Unassigned branch' }}
                            </option>
                        @endforeach
                    </select>
                </div>
            @endif

            @if ($summaryMode === 'user')
                <div class="summary-filter-group">
                    <label for="summarySubSelect"><i class="fas fa-clock-rotate-left"></i> Audit Date:</label>
                    <select name="submission_id" id="summarySubSelect" class="summary-select" onchange="this.form.submit()">
                        @forelse ($summarySheet['availableSubmissions'] as $sub)
                            <option value="{{ $sub->id }}" {{ $sub->id === $summarySheet['selectedSubmissionId'] ? 'selected' : '' }}>
                                {{ $sub->period_label ?? 'September to October' }} &mdash; {{ ucfirst($sub->status) }}
                            </option>
                        @empty
                            <option value="">No recorded audit</option>
                        @endforelse
                    </select>
                </div>
            @else
                <div class="summary-aggregate-scope" aria-label="Overall Aftersales scope">
                    <i class="fas fa-layer-group" aria-hidden="true"></i>
                    <span><strong>{{ $summarySheet['aggregateUserCount'] }}</strong> latest user {{ Str::plural('audit', $summarySheet['aggregateUserCount']) }}</span>
                </div>
            @endif

            <div class="summary-filter-actions">
                <a href="{{ $summarySheet['checklistRoute'] }}" class="summary-btn btn-primary" title="Open and edit audit form">
                    <i class="fas fa-pen-to-square"></i>
                    <span>Open Audit Form</span>
                </a>
                <button type="button" class="summary-btn" onclick="window.print()" title="Print summary sheet">
                    <i class="fas fa-print"></i>
                    <span>Print</span>
                </button>
            </div>
        </form>
    </section>

    {{-- DEALERSHIP & AUDIT META CARD --}}
    <section class="summary-meta-card" aria-label="Dealership and audit information">
        <div class="meta-header">
            <div>
                <h1>{{ $summarySheet['activeFormTitle'] }}</h1>
                <div class="meta-subtitle">
                    <span>Standards Compliance Audit Summary Sheet &bull; FY2025</span>
                    <span class="scope-chip"><i class="fas fa-clipboard-check"></i> {{ $summarySheet['activeForm'] === 'aftersales' ? 'Aftersales Standards' : 'Sales Standards' }}</span>
                </div>
            </div>
            <div>
                @if ($summarySheet['status'] === 'submitted')
                    <span class="badge-rating badge-pass"><i class="fas fa-circle-check"></i> SUBMITTED</span>
                @elseif ($summarySheet['status'] === 'draft')
                    <span class="badge-rating badge-fail" style="background:#fef3c7; color:#b45309; border-color:#fde68a;"><i class="fas fa-clock"></i> DRAFT / IN PROGRESS</span>
                @elseif ($summarySheet['status'] === 'aggregate')
                    <span class="badge-rating badge-pass"><i class="fas fa-users"></i> OVERALL USERS</span>
                @else
                    <span class="badge-rating badge-neutral"><i class="fas fa-circle-info"></i> NO RECORDED AUDIT</span>
                @endif
            </div>
        </div>

        <div class="summary-meta-grid">
            <div class="summary-meta-item">
                <div class="meta-label">Dealer</div>
                <div class="meta-value">{{ $summarySheet['dealer'] }}</div>
            </div>
            <div class="summary-meta-item">
                <div class="meta-label">Outlet / Branch</div>
                <div class="meta-value">{{ $summarySheet['outlet'] }}</div>
            </div>
            <div class="summary-meta-item">
                <div class="meta-label">{{ $summaryMode === 'overall' ? 'Audit Scope' : 'Audit Date' }}</div>
                <div class="meta-value">{{ $summarySheet['date'] }}</div>
            </div>
            <div class="summary-meta-item">
                <div class="meta-label">{{ $summaryMode === 'overall' ? 'Users Included' : 'Auditor' }}</div>
                <div class="meta-value">{{ $summarySheet['auditor'] }}</div>
            </div>
        </div>
    </section>

    {{-- SECTION 1: OVERALL AUDIT SCORE (Table 1) --}}
    <section class="summary-table-card" aria-label="Overall audit score table">
        <div class="summary-section-header">
            <div>
                <h2>{{ $summaryMode === 'overall' ? 'Overall Aftersales Score per Criteria' : 'User Audit Score per Criteria' }}</h2>
                <p>
                    @if ($summaryMode === 'overall')
                        Combined score from the latest visible audit of {{ $summarySheet['aggregateUserCount'] }} Aftersales {{ Str::plural('user', $summarySheet['aggregateUserCount']) }}. Basic requires 100% and Standard requires &ge;80%.
                    @else
                        {{ $summarySheet['scoreContextLabel'] }}@if ($summarySheet['scoreContextRole']) ({{ $summarySheet['scoreContextRole'] }})@endif &mdash; scores use only criteria assigned to this user's checker role.
                    @endif
                </p>
            </div>
        </div>

        <div class="summary-table-wrap">
            <table class="summary-table">
                <thead>
                    <tr>
                        <th style="width: 60px;">No.</th>
                        <th>Criteria</th>
                        <th style="width: 120px; text-align: center;">Total</th>
                        <th style="width: 120px; text-align: center;">Score</th>
                        <th style="width: 220px;">% Score</th>
                        <th style="width: 130px; text-align: center;">Rating</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($overallScores as $row)
                        <tr>
                            <td>{{ $row['no'] }}</td>
                            <td>
                                <strong>{{ $row['category'] }}</strong>
                                @if ($row['target'] !== null)
                                    <span class="table-benchmark-tag">Target: {{ $row['target'] }}%</span>
                                @else
                                    <span class="table-benchmark-tag">Bonus / Discretionary</span>
                                @endif
                            </td>
                            <td style="text-align: center;"><strong>{{ $row['total'] }}</strong></td>
                            <td style="text-align: center;"><strong>{{ $row['score'] }}</strong></td>
                            <td>
                                <div class="cell-pct-bar">
                                    <span class="pct-val">{{ number_format($row['percent'], 1) }}%</span>
                                    <div class="table-progress {{ $row['percent'] >= ($row['target'] ?? 80) ? '' : ($row['percent'] >= 60 ? 'progress-amber' : 'progress-red') }}">
                                        <span style="width: {{ min(100, max(0, $row['percent'])) }}%"></span>
                                    </div>
                                </div>
                            </td>
                            <td style="text-align: center;">
                                @if ($row['rating'] === 'PASS')
                                    <span class="badge-rating badge-pass"><i class="fas fa-check"></i> PASS</span>
                                @elseif ($row['rating'] === 'FAIL')
                                    <span class="badge-rating badge-fail"><i class="fas fa-xmark"></i> FAIL</span>
                                @else
                                    <span class="badge-rating badge-neutral">&mdash;</span>
                                @endif
                            </td>
                        </tr>
                    @endforeach
                    <tr class="total-row">
                        <td colspan="2" style="text-transform: uppercase;">TOTAL:</td>
                        <td style="text-align: center;">{{ $overallSummary['total'] }}</td>
                        <td style="text-align: center;">{{ $overallSummary['score'] }}</td>
                        <td>
                            <div class="cell-pct-bar">
                                <span class="pct-val">{{ number_format($overallSummary['percent'], 1) }}%</span>
                                <div class="table-progress {{ $overallSummary['percent'] >= 80 ? '' : ($overallSummary['percent'] >= 60 ? 'progress-amber' : 'progress-red') }}">
                                    <span style="width: {{ min(100, max(0, $overallSummary['percent'])) }}%"></span>
                                </div>
                            </div>
                        </td>
                        <td style="text-align: center;">
                            @if ($overallSummary['rating'] === 'PASS')
                                <span class="badge-rating badge-pass"><i class="fas fa-check"></i> PASS</span>
                            @else
                                <span class="badge-rating badge-fail"><i class="fas fa-xmark"></i> FAIL</span>
                            @endif
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </section>

    {{-- SECTION 2: COMPLIANCE PER CATEGORY (Table 2 - Coverage Breakdown) --}}
    <section class="summary-table-card" aria-label="Compliance per category coverage breakdown">
        <div class="summary-section-header">
            <div>
                <h2>{{ $summaryMode === 'overall' ? 'Overall Aftersales Score per Category' : 'User Audit Score per Category' }}</h2>
                <p>
                    @if ($summaryMode === 'overall')
                        Combined coverage across all {{ count($coverageRows) }} Aftersales operational categories.
                    @else
                        Category breakdown for {{ $summarySheet['scoreContextLabel'] }}, limited to this user's assigned checklist items.
                    @endif
                </p>
            </div>
        </div>

        <div class="summary-table-wrap">
            <table class="summary-table">
                <thead>
                    <tr>
                        <th style="width: 60px;">No.</th>
                        <th>Coverage</th>
                        <th style="width: 140px; text-align: center;">Total</th>
                        <th style="width: 140px; text-align: center;">Score</th>
                        <th style="width: 260px;">% Score</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($coverageRows as $cov)
                        <tr>
                            <td>{{ $cov['no'] }}</td>
                            <td><strong>{{ $cov['coverage'] }}</strong></td>
                            <td style="text-align: center;">{{ $cov['total'] }}</td>
                            <td style="text-align: center;"><strong>{{ $cov['score'] }}</strong></td>
                            <td>
                                <div class="cell-pct-bar">
                                    <span class="pct-val">{{ number_format($cov['percent'], 1) }}%</span>
                                    <div class="table-progress {{ $cov['percent'] >= 80 ? '' : ($cov['percent'] >= 60 ? 'progress-amber' : 'progress-red') }}">
                                        <span style="width: {{ min(100, max(0, $cov['percent'])) }}%"></span>
                                    </div>
                                </div>
                            </td>
                        </tr>
                    @endforeach
                    <tr class="total-row">
                        <td colspan="2" style="text-transform: uppercase;">Total:</td>
                        <td style="text-align: center;">{{ $coverageSummary['total'] }}</td>
                        <td style="text-align: center;">{{ $coverageSummary['score'] }}</td>
                        <td>
                            <div class="cell-pct-bar">
                                <span class="pct-val">{{ number_format($coverageSummary['percent'], 1) }}%</span>
                                <div class="table-progress {{ $coverageSummary['percent'] >= 80 ? '' : ($coverageSummary['percent'] >= 60 ? 'progress-amber' : 'progress-red') }}">
                                    <span style="width: {{ min(100, max(0, $coverageSummary['percent'])) }}%"></span>
                                </div>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </section>
</div>

@if ($canManageFindings)
    <div class="modal-overlay summary-modal-overlay" id="summaryFindingsModal" aria-hidden="true">
        <section class="modal summary-modal summary-modal-wide"
                 role="dialog"
                 aria-modal="true"
                 aria-labelledby="summaryFindingsTitle"
                 tabindex="-1">
            <header class="modal-header summary-modal-header">
                <div>
                    <span class="summary-modal-eyebrow"><i class="fas fa-circle-xmark" aria-hidden="true"></i> Non-Compliant Register</span>
                    <h2 id="summaryFindingsTitle">Recorded findings</h2>
                    <small>{{ $summarySheet['activeFormTitle'] }} &middot; {{ $summarySheet['outlet'] }} &middot; {{ $summarySheet['date_with_year'] }}</small>
                </div>
                <button type="button" class="modal-close" data-close-summary-modal aria-label="Close findings dialog">
                    <i class="fas fa-xmark" aria-hidden="true"></i>
                </button>
            </header>

            <div class="modal-body summary-modal-body">
                @if ($nonCompliantFindings->isEmpty())
                    <div class="summary-modal-empty">
                        <i class="fas fa-circle-check" aria-hidden="true"></i>
                        <strong>No NO findings in this audit.</strong>
                        <span>Select another audit date to review its findings.</span>
                    </div>
                @else
                    <div class="summary-modal-callout">
                        <i class="fas fa-circle-info" aria-hidden="true"></i>
                        <span>Showing {{ $nonCompliantFindings->count() }} specific {{ Str::plural('question', $nonCompliantFindings->count()) }} marked <strong>NO</strong>, including the recorded checker, reason, and photo evidence.</span>
                    </div>
                    <div class="summary-findings-table-wrap">
                        <table class="summary-findings-table">
                            <thead>
                                <tr>
                                    <th>Question</th>
                                    <th>Checked By</th>
                                    <th>Finding / Reason</th>
                                    <th>Photo Attached</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach ($nonCompliantFindings as $finding)
                                    <tr>
                                        <td class="summary-question-cell">
                                            <div class="summary-table-tags">
                                                <span class="summary-table-tag tag-danger">NO</span>
                                                @if ($finding['category'])
                                                    <span class="summary-table-tag">{{ $finding['category'] }}</span>
                                                @endif
                                                <span class="summary-table-tag">{{ $finding['area'] }}</span>
                                            </div>
                                            <strong>
                                                @if ($finding['question_number'])
                                                    {{ $finding['question_number'] }}.
                                                @endif
                                                {{ $finding['question'] }}
                                            </strong>
                                            @if ($finding['subject'])
                                                <small>{{ $finding['subject'] }}</small>
                                            @endif
                                            <small>Item: {{ $finding['item_key'] }}</small>
                                        </td>
                                        <td>
                                            <strong>{{ $finding['checked_by_name'] }}</strong>
                                            <span>{{ $finding['checked_by_role'] }}</span>
                                            @if ($finding['checker_role'])
                                                <small>Workbook checker: {{ $finding['checker_role'] }}</small>
                                            @endif
                                            @if ($finding['checked_at'])
                                                <small>{{ $finding['checked_at'] }}</small>
                                            @endif
                                        </td>
                                        <td class="summary-finding-cell">
                                            <strong>{{ $finding['finding'] }}</strong>
                                            @if ($finding['bom_task'])
                                                <small><b>BOM task:</b> {{ $finding['bom_task'] }}</small>
                                            @endif
                                            @if ($finding['action_plan'])
                                                <small><b>Action plan:</b> {{ $finding['action_plan'] }}</small>
                                            @endif
                                            @if ($finding['commitment_date'])
                                                <small><b>Commitment:</b> {{ $finding['commitment_date'] }}</small>
                                            @endif
                                        </td>
                                        <td>
                                            @if ($finding['attachment_url'])
                                                <a href="{{ $finding['attachment_url'] }}"
                                                   target="_blank"
                                                   rel="noopener noreferrer"
                                                   class="summary-photo-link">
                                                    <img src="{{ $finding['attachment_url'] }}"
                                                         alt="Photo evidence for {{ $finding['item_key'] }}"
                                                         loading="lazy">
                                                    <span><i class="fas fa-up-right-from-square" aria-hidden="true"></i> View full photo</span>
                                                </a>
                                            @else
                                                <span class="summary-no-photo"><i class="fas fa-image" aria-hidden="true"></i> No photo attached</span>
                                            @endif
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                @endif
            </div>
        </section>
    </div>

    <div class="modal-overlay summary-modal-overlay" id="summaryEscalationModal" aria-hidden="true">
        <section class="modal summary-modal summary-modal-extra-wide"
                 role="dialog"
                 aria-modal="true"
                 aria-labelledby="summaryEscalationTitle"
                 tabindex="-1">
            <header class="modal-header summary-modal-header">
                <div>
                    <span class="summary-modal-eyebrow"><i class="fas fa-arrow-up-right-dots" aria-hidden="true"></i> GM / BOM Action</span>
                    <h2 id="summaryEscalationTitle">Escalate non-compliant findings</h2>
                    <small>{{ $summarySheet['activeFormTitle'] }} &middot; {{ $summarySheet['outlet'] }} &middot; {{ $summarySheet['date_with_year'] }}</small>
                </div>
                <button type="button" class="modal-close" data-close-summary-modal aria-label="Close escalation dialog">
                    <i class="fas fa-xmark" aria-hidden="true"></i>
                </button>
            </header>

            <form id="summaryEscalationForm" data-endpoint="{{ route('reports.responses.escalations') }}">
                <div class="modal-body summary-modal-body summary-escalation-body">
                    @if ($nonCompliantFindings->isEmpty())
                        <div class="summary-modal-empty">
                            <i class="fas fa-circle-check" aria-hidden="true"></i>
                            <strong>No findings require escalation.</strong>
                        </div>
                    @else
                        <div class="summary-modal-callout">
                            <i class="fas fa-shield-halved" aria-hidden="true"></i>
                            <span>Choose a recipient only for the rows you need to update. Saving an escalation does not change the original <strong>NO</strong> result.</span>
                        </div>
                        <div class="summary-findings-table-wrap">
                            <table class="summary-findings-table summary-escalation-table">
                                <thead>
                                    <tr>
                                        <th>Question &amp; Area</th>
                                        <th>Checker / Accountable</th>
                                        <th>Finding &amp; Evidence</th>
                                        <th>Workbook Escalation</th>
                                        <th>Escalate To</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach ($nonCompliantFindings as $finding)
                                        <tr>
                                            <td class="summary-question-cell">
                                                <div class="summary-table-tags">
                                                    <span class="summary-table-tag tag-danger">NO</span>
                                                    @if ($finding['category'])
                                                        <span class="summary-table-tag">{{ $finding['category'] }}</span>
                                                    @endif
                                                </div>
                                                <strong>
                                                    @if ($finding['question_number'])
                                                        {{ $finding['question_number'] }}.
                                                    @endif
                                                    {{ $finding['question'] }}
                                                </strong>
                                                @if ($finding['subject'])
                                                    <small>{{ $finding['subject'] }}</small>
                                                @endif
                                                <small>{{ $finding['area'] }} &middot; {{ $finding['item_key'] }}</small>
                                            </td>
                                            <td>
                                                <strong>{{ $finding['checked_by_name'] }}</strong>
                                                <span>{{ $finding['checked_by_role'] }}</span>
                                                <small>Checker: {{ $finding['checker_role'] ?: 'Not specified' }}</small>
                                                @if ($finding['person_accountable'])
                                                    <small>Accountable: {{ $finding['person_accountable'] }}</small>
                                                @endif
                                            </td>
                                            <td class="summary-finding-cell">
                                                <strong>{{ $finding['finding'] }}</strong>
                                                @if ($finding['bom_task'])
                                                    <small><b>BOM task:</b> {{ $finding['bom_task'] }}</small>
                                                @endif
                                                @if ($finding['action_plan'])
                                                    <small><b>Action plan:</b> {{ $finding['action_plan'] }}</small>
                                                @endif
                                                @if ($finding['commitment_date'])
                                                    <small><b>Commitment:</b> {{ $finding['commitment_date'] }}</small>
                                                @endif
                                                @if ($finding['attachment_url'])
                                                    <a href="{{ $finding['attachment_url'] }}" target="_blank" rel="noopener noreferrer" class="summary-inline-photo-link">
                                                        <i class="fas fa-image" aria-hidden="true"></i> View attached photo
                                                    </a>
                                                @else
                                                    <small>No photo attached</small>
                                                @endif
                                            </td>
                                            <td>
                                                @if ($finding['recommended_escalation'])
                                                    <span class="summary-workbook-target">{{ $finding['recommended_escalation'] }}</span>
                                                @else
                                                    <span class="summary-muted-value">Not specified</span>
                                                @endif
                                            </td>
                                            <td class="summary-escalation-select-cell">
                                                <label class="sr-only" for="summaryEscalation{{ $finding['response_id'] }}">Escalation recipient for {{ $finding['item_key'] }}</label>
                                                <select id="summaryEscalation{{ $finding['response_id'] }}"
                                                        class="summary-escalation-select"
                                                        data-response-id="{{ $finding['response_id'] }}"
                                                        data-original-value="{{ $finding['escalation_target'] }}">
                                                    <option value="">No escalation selected</option>
                                                    @if ($finding['escalation_target'] && ! array_key_exists($finding['escalation_target'], $escalationOptions))
                                                        <option value="{{ $finding['escalation_target'] }}" selected>{{ $finding['escalation_target_label'] }}</option>
                                                    @endif
                                                    @foreach ($escalationOptions as $targetValue => $targetLabel)
                                                        <option value="{{ $targetValue }}" {{ $finding['escalation_target'] === $targetValue ? 'selected' : '' }}>{{ $targetLabel }}</option>
                                                    @endforeach
                                                </select>
                                                @if ($finding['escalation_target_label'])
                                                    <small class="summary-current-escalation">Current: {{ $finding['escalation_target_label'] }}</small>
                                                @else
                                                    <small class="summary-current-escalation">Not assigned</small>
                                                @endif
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    @endif
                </div>

                <footer class="summary-modal-footer">
                    <div class="summary-escalation-status" id="summaryEscalationStatus" role="status" aria-live="polite"></div>
                    <div class="summary-modal-actions">
                        <button type="button" class="summary-modal-btn" data-close-summary-modal>Cancel</button>
                        <button type="submit" class="summary-modal-btn summary-modal-btn-primary" id="saveSummaryEscalations" {{ $nonCompliantFindings->isEmpty() ? 'disabled' : '' }}>
                            <i class="fas fa-floppy-disk" aria-hidden="true"></i>
                            <span>Save Escalations</span>
                        </button>
                    </div>
                </footer>
            </form>
        </section>
    </div>

    <script>
        (() => {
            const modalTriggers = document.querySelectorAll('[data-summary-modal-target]');
            const modals = document.querySelectorAll('.summary-modal-overlay');
            let lastTrigger = null;

            const closeModal = (modal) => {
                if (!modal) return;
                const escalationForm = modal.querySelector('#summaryEscalationForm');
                if (escalationForm?.dataset.saving === 'true') return;

                escalationForm?.querySelectorAll('.summary-escalation-select').forEach((select) => {
                    select.value = select.dataset.originalValue || '';
                });
                const escalationStatus = escalationForm?.querySelector('#summaryEscalationStatus');
                if (escalationStatus) {
                    escalationStatus.className = 'summary-escalation-status';
                    escalationStatus.textContent = '';
                }

                modal.classList.remove('is-open');
                modal.setAttribute('aria-hidden', 'true');
                if (![...modals].some((item) => item.classList.contains('is-open'))) {
                    document.body.classList.remove('summary-modal-open');
                }
                lastTrigger?.focus();
            };

            const openModal = (modal, trigger) => {
                if (!modal || trigger?.disabled) return;
                lastTrigger = trigger || null;
                modal.classList.add('is-open');
                modal.setAttribute('aria-hidden', 'false');
                document.body.classList.add('summary-modal-open');
                window.requestAnimationFrame(() => modal.querySelector('.summary-modal')?.focus());
            };

            modalTriggers.forEach((trigger) => {
                trigger.addEventListener('click', () => {
                    openModal(document.getElementById(trigger.dataset.summaryModalTarget), trigger);
                });
            });

            document.querySelectorAll('[data-close-summary-modal]').forEach((button) => {
                button.addEventListener('click', () => closeModal(button.closest('.summary-modal-overlay')));
            });

            modals.forEach((modal) => {
                modal.addEventListener('click', (event) => {
                    if (event.target === modal) closeModal(modal);
                });
            });

            document.addEventListener('keydown', (event) => {
                if (event.key !== 'Escape') return;
                const open = [...modals].find((modal) => modal.classList.contains('is-open'));
                if (open) closeModal(open);
            });

            const escalationForm = document.getElementById('summaryEscalationForm');
            escalationForm?.addEventListener('submit', async (event) => {
                event.preventDefault();
                if (escalationForm.dataset.saving === 'true') return;

                const status = document.getElementById('summaryEscalationStatus');
                const saveButton = document.getElementById('saveSummaryEscalations');
                const selects = [...escalationForm.querySelectorAll('.summary-escalation-select')];
                const updates = selects
                    .filter((select) => select.value !== select.dataset.originalValue)
                    .map((select) => ({
                        id: Number(select.dataset.responseId),
                        escalation_target: select.value || null,
                    }));

                status.className = 'summary-escalation-status';
                if (updates.length === 0) {
                    status.textContent = 'No escalation changes to save.';
                    return;
                }

                saveButton.disabled = true;
                saveButton.classList.add('is-loading');
                escalationForm.dataset.saving = 'true';
                escalationForm.setAttribute('aria-busy', 'true');
                selects.forEach((select) => {
                    select.disabled = true;
                });
                status.textContent = 'Saving escalation assignments...';

                try {
                    const response = await fetch(escalationForm.dataset.endpoint, {
                        method: 'PATCH',
                        headers: {
                            'Accept': 'application/json',
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || '',
                        },
                        body: JSON.stringify({ responses: updates }),
                    });
                    const data = await response.json().catch(() => ({}));

                    if (!response.ok) {
                        throw new Error(data.message || 'The escalation assignments could not be saved.');
                    }

                    selects.forEach((select) => {
                        select.dataset.originalValue = select.value;
                        const currentLabel = select.closest('.summary-escalation-select-cell')?.querySelector('.summary-current-escalation');
                        if (currentLabel) {
                            currentLabel.textContent = select.value
                                ? `Current: ${select.selectedOptions[0]?.textContent || select.value}`
                                : 'Not assigned';
                        }
                    });
                    status.classList.add('is-success');
                    status.textContent = data.message || 'Escalation assignments saved.';
                } catch (error) {
                    status.classList.add('is-error');
                    status.textContent = error.message || 'The escalation assignments could not be saved.';
                } finally {
                    saveButton.disabled = false;
                    saveButton.classList.remove('is-loading');
                    escalationForm.dataset.saving = 'false';
                    escalationForm.removeAttribute('aria-busy');
                    selects.forEach((select) => {
                        select.disabled = false;
                    });
                }
            });
        })();
    </script>
@endif
