@php
    $isFollowUpWorkspace = true;
    $showOverrideActions = false;
    $followUpQuery = array_filter([
        'tab' => 'follow-up',
        'branch' => $reportFilters['branch'],
        'template' => $reportFilters['template'],
        'status' => $reportFilters['status'],
        'month' => $reportFilters['month'],
    ], static fn ($value) => $value !== null && $value !== '');

    $openFindings = $reportFindings->filter(
        static fn (array $finding): bool => in_array($finding['status'], ['no', 'x'], true)
            && ! $finding['is_overridden']
    );
    $awaitingEscalation = $openFindings->filter(
        static fn (array $finding): bool => blank($finding['escalation_target'])
    );
    $escalatedFindings = $reportFindings->filter(
        static fn (array $finding): bool => filled($finding['escalation_target'])
    );
    $overdueFindings = $openFindings->where('is_overdue', true);
    $findingTotal = max(1, $reportFindings->count());

    $registerTitle = $canViewFindings ? 'Findings Review' : 'Escalation Queue';
    $registerDescription = $canViewFindings
        ? 'Review non-compliant checklist results, supporting evidence, action plans, and escalation status. Use Follow-up to request action.'
        : 'Review open findings for your branch, then set the escalation recipient, corrective action plan, and commitment date.';
    $registerAriaLabel = $canViewFindings
        ? 'Findings available for review and follow-up'
        : 'Findings available for escalation';
@endphp

@php
    $followUpView = request()->query('view', 'findings');
    if (! in_array($followUpView, ['findings', 'history'], true)) {
        $followUpView = 'findings';
    }
    $historyCount = ($followUpHistory ?? collect())->count();
    $findingsCount = $reportFindings->count();
@endphp

<div class="checklist-workspace-header">
    <nav class="checklist-workspace-switcher" aria-label="Select checklist findings view" role="tablist">
        <a href="{{ route('dashboard', array_merge($followUpQuery, ['view' => 'findings'])) }}"
           class="checklist-workspace-option{{ $followUpView === 'findings' ? ' is-active' : '' }}"
           role="tab"
           data-followup-switch="findings"
           aria-selected="{{ $followUpView === 'findings' ? 'true' : 'false' }}"
           @if ($followUpView === 'findings') aria-current="page" @endif>
            <i class="fas fa-list-check" aria-hidden="true"></i>
            <span>Findings</span>
            <span class="checklist-workspace-count{{ $findingsCount > 0 ? ' has-issues' : '' }}">{{ $findingsCount }}</span>
        </a>
        <a href="{{ route('dashboard', array_merge($followUpQuery, ['view' => 'history'])) }}"
           class="checklist-workspace-option{{ $followUpView === 'history' ? ' is-active' : '' }}"
           role="tab"
           data-followup-switch="history"
           aria-selected="{{ $followUpView === 'history' ? 'true' : 'false' }}"
           @if ($followUpView === 'history') aria-current="page" @endif>
            <i class="fas fa-clock-rotate-left" aria-hidden="true"></i>
            <span>History</span>
            <span class="checklist-workspace-count">{{ $historyCount }}</span>
        </a>
    </nav>
</div>

<div class="panel-heading follow-up-heading">
    <div>
        <span class="section-kicker">Management workflow</span>
        <h2>Checklist Findings</h2>
        <p>
            {{ $canViewFindings
                ? 'Review audit findings and request the next action from the responsible branch.'
                : 'Turn non-compliant results into assigned, time-bound corrective actions.' }}
            @if ($reportScope['type'] === 'assigned_branch')
                Results are limited to {{ $reportScope['branch'] ?: 'your assigned branch (not configured)' }}.
            @endif
        </p>
    </div>
    <div class="header-actions">
        <a class="button" href="{{ route('dashboard', array_merge($followUpQuery, ['view' => $followUpView])) }}">
            <i class="fas fa-rotate" aria-hidden="true"></i>Refresh
        </a>
    </div>
</div>

@if ($errors->any())
    <section class="workspace-notice danger" role="alert">
        <i class="fas fa-triangle-exclamation" aria-hidden="true"></i>
        <div><strong>The follow-up filters could not be applied.</strong><p>{{ $errors->first() }}</p></div>
    </section>
@endif

<form class="workspace-filter follow-up-filter" method="GET" action="{{ route('dashboard') }}" aria-label="Follow-up filters">
    <input type="hidden" name="tab" value="follow-up">
    <input type="hidden" name="view" id="followUpViewInput" value="{{ $followUpView }}">
    <div class="workspace-field">
        <label for="followUpBranch">Branch</label>
        <select id="followUpBranch" name="branch">
            <option value="">{{ $reportScope['type'] === 'all_branches' ? 'All branches' : 'My assigned branch' }}</option>
            @foreach ($reportBranchOptions as $branch)
                <option value="{{ $branch }}" @selected($reportFilters['branch'] === $branch)>{{ $branch }}</option>
            @endforeach
        </select>
    </div>
    <div class="workspace-field">
        <label for="followUpTemplate">Checklist</label>
        <select id="followUpTemplate" name="template">
            <option value="">All checklists</option>
            @foreach ($reportTemplateOptions as $template)
                <option value="{{ $template['slug'] }}" @selected($reportFilters['template'] === $template['slug'])>
                    {{ $template['name'] }}{{ $template['is_archived'] ? ' (Archived)' : '' }}
                </option>
            @endforeach
        </select>
    </div>
    <div class="workspace-field">
        <label for="followUpStatus">Audit Status</label>
        <select id="followUpStatus" name="status">
            <option value="">Submitted and draft</option>
            @foreach (['submitted', 'draft'] as $status)
                <option value="{{ $status }}" @selected($reportFilters['status'] === $status)>{{ ucfirst($status) }} only</option>
            @endforeach
        </select>
    </div>
    <div class="workspace-field">
        <label for="followUpMonth">Audit Month</label>
        <input id="followUpMonth" name="month" type="month" value="{{ $reportFilters['month'] }}">
    </div>
    <div class="workspace-filter-actions">
        <a class="button" href="{{ route('dashboard', ['tab' => 'follow-up', 'view' => $followUpView]) }}">
            <i class="fas fa-filter-circle-xmark" aria-hidden="true"></i>Clear
        </a>
        <button class="button primary" type="submit">
            <i class="fas fa-filter" aria-hidden="true"></i>Apply
        </button>
    </div>
</form>

<!-- Findings Pane -->
<div id="paneFindings" class="follow-up-pane" style="{{ $followUpView === 'findings' ? '' : 'display: none;' }}">
    <section class="follow-up-role-card {{ $canViewFindings ? 'is-gm' : 'is-bom' }}" aria-labelledby="followUpRoleActionTitle">
        <div class="follow-up-role-icon" aria-hidden="true">
            <i class="fas {{ $canViewFindings ? 'fa-magnifying-glass-chart' : 'fa-arrow-up-right-dots' }}"></i>
        </div>
        <div class="follow-up-role-copy">
            <span class="follow-up-role-kicker">
                <i class="fas {{ $canViewFindings ? 'fa-user-shield' : 'fa-user-gear' }}" aria-hidden="true"></i>
                {{ $canViewFindings ? 'GM workspace' : 'BOM workspace' }}
            </span>
            <h2 id="followUpRoleActionTitle">{{ $canViewFindings ? 'View Findings' : 'Escalation' }}</h2>
            <p>
                {{ $canViewFindings
                    ? 'Inspect each recorded deficiency and send a focused follow-up request to the assigned branch.'
                    : 'Open a finding to assign the escalation owner, document the action plan, and commit to a resolution date.' }}
            </p>
        </div>
        <a class="button primary follow-up-role-action" href="#findingsRegisterCard">
            <i class="fas {{ $canViewFindings ? 'fa-eye' : 'fa-arrow-up-right-from-square' }}" aria-hidden="true"></i>
            {{ $canViewFindings ? 'View Findings' : 'Open Escalation Queue' }}
        </a>
    </section>

    <section class="workspace-stats follow-up-stats" aria-label="Follow-up summary">
        <article class="workspace-stat follow-up-stat is-open">
            <div class="workspace-stat-top"><span>Open Findings</span><i class="fas fa-circle-exclamation" aria-hidden="true"></i></div>
            <strong>{{ number_format($openFindings->count()) }}</strong>
            <div class="workspace-meter"><span style="width:{{ $barWidth(($openFindings->count() / $findingTotal) * 100) }}%"></span></div>
            <p>Unresolved NO and failed time-slot results.</p>
        </article>
        <article class="workspace-stat follow-up-stat is-awaiting">
            <div class="workspace-stat-top"><span>Awaiting Escalation</span><i class="fas fa-hourglass-half" aria-hidden="true"></i></div>
            <strong>{{ number_format($awaitingEscalation->count()) }}</strong>
            <div class="workspace-meter"><span style="width:{{ $barWidth(($awaitingEscalation->count() / $findingTotal) * 100) }}%"></span></div>
            <p>Open findings without an assigned escalation target.</p>
        </article>
        <article class="workspace-stat follow-up-stat is-escalated">
            <div class="workspace-stat-top"><span>Escalated</span><i class="fas fa-share-nodes" aria-hidden="true"></i></div>
            <strong>{{ number_format($escalatedFindings->count()) }}</strong>
            <div class="workspace-meter"><span style="width:{{ $barWidth(($escalatedFindings->count() / $findingTotal) * 100) }}%"></span></div>
            <p>Findings with a responsible escalation target.</p>
        </article>
        <article class="workspace-stat follow-up-stat is-overdue">
            <div class="workspace-stat-top"><span>Overdue</span><i class="fas fa-calendar-xmark" aria-hidden="true"></i></div>
            <strong>{{ number_format($overdueFindings->count()) }}</strong>
            <div class="workspace-meter"><span style="width:{{ $barWidth(($overdueFindings->count() / $findingTotal) * 100) }}%"></span></div>
            <p>Open findings past their commitment date.</p>
        </article>
    </section>

    @include('partials.findings-register')
</div>

<!-- History Pane -->
<div id="paneHistory" class="follow-up-pane" style="{{ $followUpView === 'history' ? '' : 'display: none;' }}">
    @include('partials.follow-up-history')
</div>

@include('partials.findings-actions')
@include('partials.finding-detail-modal')

<script>
(() => {
    const switchBtns = document.querySelectorAll('[data-followup-switch]');
    const paneFindings = document.getElementById('paneFindings');
    const paneHistory = document.getElementById('paneHistory');
    const viewInput = document.getElementById('followUpViewInput');

    switchBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            if (e.metaKey || e.ctrlKey || e.shiftKey) return;
            e.preventDefault();

            const target = btn.dataset.followupSwitch;
            switchBtns.forEach(b => {
                const isActive = b.dataset.followupSwitch === target;
                b.classList.toggle('is-active', isActive);
                b.setAttribute('aria-selected', isActive ? 'true' : 'false');
                if (isActive) {
                    b.setAttribute('aria-current', 'page');
                } else {
                    b.removeAttribute('aria-current');
                }
            });

            if (paneFindings) paneFindings.style.display = target === 'findings' ? '' : 'none';
            if (paneHistory) paneHistory.style.display = target === 'history' ? '' : 'none';
            if (viewInput) viewInput.value = target;

            const url = new URL(btn.href, window.location.origin);
            window.history.replaceState({}, '', url.toString());
        });
    });
})();
</script>
