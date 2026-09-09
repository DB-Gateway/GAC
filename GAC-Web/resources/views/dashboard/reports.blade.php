@php
    $reportRecordCount = (int) ($reportSummary['audit_count'] ?? 0);
    $reportAnsweredCount = (int) ($reportSummary['answered'] ?? 0);
    $reportFindingRate = $reportAnsweredCount > 0
        ? min(100, ((int) ($reportSummary['findings_count'] ?? 0) / $reportAnsweredCount) * 100)
        : 0;
@endphp

<div class="panel-heading">
    <div>
        <span class="section-kicker">Historical intelligence</span>
        <h2>Reports &amp; Analytics</h2>
        <p>
            Analyze every reportable checklist record in your access scope.
            @if ($reportScope['type'] === 'assigned_branch')
                Results are limited to {{ $reportScope['branch'] ?: 'your assigned branch (not configured)' }}.
            @endif
        </p>
    </div>
    <div class="header-actions">
        <a class="button" href="{{ $reportsTabUrl }}"><i class="fas fa-rotate" aria-hidden="true"></i>Refresh</a>
        <a class="button" href="{{ route('reports.export', $reportQuery) }}"><i class="fas fa-file-csv" aria-hidden="true"></i>Export CSV</a>
        <button class="button primary" id="printDashboardReport" type="button"><i class="fas fa-print" aria-hidden="true"></i>Print</button>
    </div>
</div>

@if ($errors->any())
    <section class="workspace-notice danger" role="alert">
        <i class="fas fa-triangle-exclamation" aria-hidden="true"></i>
        <div><strong>The report filters could not be applied.</strong><p>{{ $errors->first() }}</p></div>
    </section>
@elseif ($reportRecordCount === 0)
    <section class="workspace-notice" aria-live="polite">
        <i class="fas fa-circle-info" aria-hidden="true"></i>
        <div><strong>No audit records match the current filters.</strong><p>Clear the filters or save a checklist submission to populate this report.</p></div>
    </section>
@endif

<form class="workspace-filter" method="GET" action="{{ route('dashboard') }}" aria-label="Report filters">
    <input type="hidden" name="tab" value="reports">
    <div class="workspace-field">
        <label for="dashboardReportBranch">Branch</label>
        <select id="dashboardReportBranch" name="branch">
            <option value="">{{ $reportScope['type'] === 'all_branches' ? 'All branches' : 'My assigned branch' }}</option>
            @foreach ($reportBranchOptions as $branch)
                <option value="{{ $branch }}" @selected($reportFilters['branch'] === $branch)>{{ $branch }}</option>
            @endforeach
        </select>
    </div>
    <div class="workspace-field">
        <label for="dashboardReportTemplate">Checklist</label>
        <select id="dashboardReportTemplate" name="template">
            <option value="">All checklists</option>
            @foreach ($reportTemplateOptions as $template)
                <option value="{{ $template['slug'] }}" @selected($reportFilters['template'] === $template['slug'])>
                    {{ $template['name'] }}{{ $template['is_archived'] ? ' (Archived)' : '' }}
                </option>
            @endforeach
        </select>
    </div>
    <div class="workspace-field">
        <label for="dashboardReportStatus">Status</label>
        <select id="dashboardReportStatus" name="status">
            <option value="">Submitted and draft</option>
            @foreach (['submitted', 'draft'] as $status)
                <option value="{{ $status }}" @selected($reportFilters['status'] === $status)>{{ ucfirst($status) }} only</option>
            @endforeach
        </select>
    </div>
    <div class="workspace-field">
        <label for="dashboardReportMonth">Audit Month</label>
        <input id="dashboardReportMonth" name="month" type="month" value="{{ $reportFilters['month'] }}" aria-label="Audit month">
    </div>
    <div class="workspace-filter-actions">
        <a class="button" href="{{ route('dashboard', ['tab' => 'reports']) }}"><i class="fas fa-filter-circle-xmark" aria-hidden="true"></i>Clear</a>
        <button class="button primary" type="submit"><i class="fas fa-filter" aria-hidden="true"></i>Apply</button>
    </div>
</form>

<section class="workspace-stats" aria-label="Report summary">
    <article class="workspace-stat">
        <div class="workspace-stat-top"><span>Overall Compliance</span><i class="fas fa-gauge-high" aria-hidden="true"></i></div>
        <strong>{{ $formatPercent($reportSummary['score']) }}</strong>
        <div class="workspace-meter"><span style="width:{{ $barWidth($reportSummary['score']) }}%"></span></div>
        <p>{{ number_format($reportSummary['yes']) }} passing of {{ number_format($reportSummary['applicable']) }} applicable judgments</p>
    </article>
    <article class="workspace-stat">
        <div class="workspace-stat-top"><span>Completion</span><i class="fas fa-circle-check" aria-hidden="true"></i></div>
        <strong>{{ $formatPercent($reportSummary['completion']) }}</strong>
        <div class="workspace-meter"><span style="width:{{ $barWidth($reportSummary['completion']) }}%"></span></div>
        <p>{{ number_format($reportSummary['answered']) }} of {{ number_format($reportSummary['total']) }} expected judgments</p>
    </article>
    <article class="workspace-stat">
        <div class="workspace-stat-top"><span>Audit Records</span><i class="fas fa-file-lines" aria-hidden="true"></i></div>
        <strong>{{ number_format($reportRecordCount) }}</strong>
        <div class="workspace-meter"><span style="width:{{ $reportRecordCount > 0 ? 100 : 0 }}%"></span></div>
        <p>{{ number_format($reportSummary['submitted_count']) }} submitted · {{ number_format($reportSummary['draft_count']) }} draft</p>
    </article>
    <article class="workspace-stat">
        <div class="workspace-stat-top"><span>Flagged Findings</span><i class="fas fa-triangle-exclamation" aria-hidden="true"></i></div>
        <strong>{{ number_format($reportSummary['findings_count']) }}</strong>
        <div class="workspace-meter"><span style="width:{{ $barWidth($reportFindingRate) }}%"></span></div>
        <p>NO, N/A, and failed Restroom time-slot results</p>
    </article>
</section>

<section class="insight-grid" aria-label="Report breakdowns">
    <article class="insight-card span-7">
        <div class="insight-heading">
            <div><h3>Compliance by Checklist</h3><p>Weighted performance for each saved checklist type.</p></div>
            <span>{{ $reportModuleSummaries->count() }} types</span>
        </div>
        <div class="insight-body">
            @forelse ($reportModuleSummaries as $module)
                <div class="metric-row">
                    <div class="metric-label" title="{{ $module['label'] }}">{{ $module['label'] }}</div>
                    <div class="metric-track"><span style="width:{{ $barWidth($module['score']) }}%"></span></div>
                    <strong>{{ $formatPercent($module['score']) }}</strong>
                </div>
                <p class="metric-meta">{{ $module['count'] }} {{ Str::plural('audit', $module['count']) }} · {{ $module['findings_count'] }} {{ Str::plural('finding', $module['findings_count']) }} · {{ $formatPercent($module['completion']) }} complete</p>
            @empty
                <p class="dashboard-empty">Checklist performance will appear after an audit is saved.</p>
            @endforelse
        </div>
    </article>

    <article class="insight-card span-5">
        <div class="insight-heading">
            <div><h3>Judgment Distribution</h3><p>Good and bad Restroom slots are included.</p></div>
            <span>{{ number_format($reportSummary['answered']) }} answered</span>
        </div>
        <div class="insight-body">
            @forelse ([
                ['label' => 'YES / Good', 'value' => $reportSummary['yes']],
                ['label' => 'NO / Bad', 'value' => $reportSummary['no']],
                ['label' => 'N/A', 'value' => $reportSummary['na']],
            ] as $judgment)
                @php($judgmentWidth = $reportSummary['answered'] > 0 ? ($judgment['value'] / $reportSummary['answered']) * 100 : 0)
                <div class="metric-row compact">
                    <div class="metric-label">{{ $judgment['label'] }}</div>
                    <div class="metric-track"><span style="width:{{ $barWidth($judgmentWidth) }}%"></span></div>
                    <strong>{{ number_format($judgment['value']) }}</strong>
                </div>
            @empty
                <p class="dashboard-empty">Response distribution is not available yet.</p>
            @endforelse
        </div>
    </article>

    <article class="insight-card span-6">
        <div class="insight-heading">
            <div><h3>Branch Performance</h3><p>Weighted compliance inside the current access scope.</p></div>
            <span>{{ $reportBranchSummaries->count() }} branches</span>
        </div>
        <div class="insight-body scrollable-insight">
            @forelse ($reportBranchSummaries as $branch)
                <div class="metric-row">
                    <div class="metric-label" title="{{ $branch['label'] }}">{{ $branch['label'] }}</div>
                    <div class="metric-track"><span style="width:{{ $barWidth($branch['score']) }}%"></span></div>
                    <strong>{{ $formatPercent($branch['score']) }}</strong>
                </div>
                <p class="metric-meta">{{ $branch['count'] }} {{ Str::plural('audit', $branch['count']) }} · {{ $branch['findings_count'] }} {{ Str::plural('finding', $branch['findings_count']) }}</p>
            @empty
                <p class="dashboard-empty">Branch comparisons will appear after audits are saved.</p>
            @endforelse
        </div>
    </article>

    <article class="insight-card span-6">
        <div class="insight-heading">
            <div><h3>Monthly Audit History</h3><p>The latest 12 months matching your filters.</p></div>
            <span>{{ $reportMonthlySummaries->count() }} months</span>
        </div>
        <div class="table-wrap compact-table">
            <table>
                <thead><tr><th>Month</th><th>Audits</th><th>Compliance</th><th>Findings</th></tr></thead>
                <tbody>
                    @forelse ($reportMonthlySummaries as $month)
                        <tr>
                            <td><strong>{{ $month['label'] }}</strong></td>
                            <td>{{ number_format($month['count']) }}</td>
                            <td>{{ $formatPercent($month['score']) }}</td>
                            <td>{{ number_format($month['findings_count']) }}</td>
                        </tr>
                    @empty
                        <tr><td class="dashboard-empty" colspan="4">Monthly history is not available yet.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </article>
</section>

<section class="workspace-table-card" aria-label="Audit history">
    <div class="insight-heading">
        <div><h3>Recent Audit History</h3><p>The 25 latest records matching the active report filters.</p></div>
        <span>{{ number_format($reportHistory->count()) }} shown</span>
    </div>
    <div class="table-wrap">
        <table>
            <thead>
                <tr><th>Date</th><th>Checklist</th><th>Branch</th><th>Auditor</th><th>Status</th><th>Score</th><th>Completion</th><th>Findings</th></tr>
            </thead>
            <tbody>
                @forelse ($reportHistory as $record)
                    <tr>
                        <td><strong>{{ $record['audit_date'] ? \Illuminate\Support\Carbon::parse($record['audit_date'])->format('d M Y') : '—' }}</strong><small class="table-subtext">#{{ $record['id'] }}</small></td>
                        <td>{{ $record['template_name'] }}</td>
                        <td>{{ $record['branch'] }}</td>
                        <td>{{ $record['auditor'] }}</td>
                        <td><span class="status-pill {{ $record['status'] }}">{{ ucfirst($record['status']) }}</span></td>
                        <td><strong>{{ $formatPercent($record['score']) }}</strong></td>
                        <td>{{ $formatPercent($record['completion']) }}<small class="table-subtext">{{ $record['answered'] }}/{{ $record['total'] }}</small></td>
                        <td>{{ number_format($record['findings_count']) }}</td>
                    </tr>
                @empty
                    <tr><td class="dashboard-empty" colspan="8">No audit records match the current report filters.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</section>
