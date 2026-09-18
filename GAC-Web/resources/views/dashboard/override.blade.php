@php
    $isOverrideWorkspace = true;
    $overrideLabel = $overrideChecklists->firstWhere('slug', $selectedOverrideChecklist)['label'];
    $overrideQuery = array_filter([
        'tab' => 'override',
        'checklist' => $selectedOverrideChecklist,
        'branch' => $reportFilters['branch'],
        'month' => $reportFilters['month'],
        'status' => $reportFilters['status'],
    ], static fn ($value) => $value !== null && $value !== '');
    $registerTitle = $overrideLabel.' NO Answers';
    $registerDescription = 'Review non-compliant responses, photo evidence, action plans, and escalations. Use Override / Edit to update a finding.';
    $reportSummary = [
        'no_count' => $reportFindings->count(),
        'overdue_count' => $reportFindings->where('is_overdue', true)->count(),
        'escalation_count' => $reportFindings->filter(fn ($finding) => filled($finding['escalation_target']))->count(),
        'overridden_count' => $reportFindings->where('is_overridden', true)->count(),
    ];
@endphp

<div class="checklist-workspace-header">
    <nav class="checklist-workspace-switcher" aria-label="Select checklist for override" role="tablist">
        @foreach ($overrideChecklists as $option)
            @php($isSelected = $option['slug'] === $selectedOverrideChecklist)
            <a href="{{ route('dashboard', [...$overrideQuery, 'checklist' => $option['slug']]) }}"
               class="checklist-workspace-option{{ $isSelected ? ' is-active' : '' }}"
               role="tab"
               aria-selected="{{ $isSelected ? 'true' : 'false' }}"
               data-override-checklist="{{ $option['slug'] }}"
               @if ($isSelected) aria-current="page" @endif>
                @if (!empty($option['icon']))
                    <i class="fas {{ $option['icon'] }}" aria-hidden="true"></i>
                @endif
                <span>{{ $option['label'] }}</span>
                @if (isset($option['no_count']))
                    <span class="checklist-workspace-count{{ $option['no_count'] > 0 ? ' has-issues' : '' }}">{{ $option['no_count'] }}</span>
                @endif
            </a>
        @endforeach
    </nav>
</div>

<div class="panel-heading checklist-page-heading">
    <div>
        <span class="section-kicker">Checklist Override</span>
        <h2>{{ $overrideLabel }}</h2>
        <p>
            Manage NO answers for this checklist in the selected audit month.
            @if ($reportScope['type'] === 'assigned_branch')
                Results are limited to {{ $reportScope['branch'] ?: 'your assigned branch (not configured)' }}.
            @endif
        </p>
    </div>
    <div class="header-actions">
        <a class="button" href="{{ route('dashboard', $overrideQuery) }}"><i class="fas fa-rotate" aria-hidden="true"></i>Refresh</a>
        <button class="button" id="printDashboardReport" type="button"><i class="fas fa-print" aria-hidden="true"></i>Print</button>
    </div>
</div>

@if ($errors->any())
    <section class="workspace-notice danger" role="alert">
        <i class="fas fa-triangle-exclamation" aria-hidden="true"></i>
        <div><strong>The filters could not be applied.</strong><p>{{ $errors->first() }}</p></div>
    </section>
@endif

<form class="workspace-filter" method="GET" action="{{ route('dashboard') }}" aria-label="Override filters">
    <input type="hidden" name="tab" value="override">
    <input type="hidden" name="checklist" value="{{ $selectedOverrideChecklist }}">
    <div class="workspace-field">
        <label for="overrideBranch">Branch</label>
        <select id="overrideBranch" name="branch">
            <option value="">{{ $reportScope['type'] === 'all_branches' ? 'All branches' : 'My assigned branch' }}</option>
            @foreach ($reportBranchOptions as $branch)
                <option value="{{ $branch }}" @selected($reportFilters['branch'] === $branch)>{{ $branch }}</option>
            @endforeach
        </select>
    </div>
    <div class="workspace-field">
        <label for="overrideStatus">Audit Status</label>
        <select id="overrideStatus" name="status">
            <option value="">Submitted and draft</option>
            @foreach (['submitted', 'draft'] as $status)
                <option value="{{ $status }}" @selected($reportFilters['status'] === $status)>{{ ucfirst($status) }} only</option>
            @endforeach
        </select>
    </div>
    <div class="workspace-field">
        <label for="overrideMonth">Audit Month</label>
        <input id="overrideMonth" name="month" type="month" value="{{ $reportFilters['month'] }}">
    </div>
    <div class="workspace-filter-actions">
        <a class="button" href="{{ route('dashboard', ['tab' => 'override', 'checklist' => $selectedOverrideChecklist]) }}"><i class="fas fa-filter-circle-xmark" aria-hidden="true"></i>Clear</a>
        <button class="button primary" type="submit"><i class="fas fa-filter" aria-hidden="true"></i>Apply</button>
    </div>
</form>

@include('partials.findings-register')
@include('partials.findings-actions')
