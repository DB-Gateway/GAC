@php
    $sdData = $subformDocData ?? [];
    $hasSubmissions = !empty($sdData['has_submissions']);
    $hasSubform = !empty($sdData['has_subform']);
    $hasDoc = !empty($sdData['has_documentation']);
    $subformInfo = $sdData['subform'] ?? [];
    $docInfo = $sdData['documentation'] ?? [];
    $subformSections = $subformInfo['sections'] ?? [];
    $docSamples = $docInfo['samples'] ?? [];
    $docMatrix = $docInfo['items_matrix'] ?? [];
    $docTotalSamples = count($docSamples);
@endphp

@if ($hasSubmissions)
<dialog id="subformDocModal" class="subform-doc-dialog" aria-labelledby="subformDocModalTitle">
    <div class="subform-doc-modal-container">
        {{-- MODAL HEADER --}}
        <header class="subform-doc-modal-header">
            <div class="modal-header-info">
                <span class="subform-doc-modal-badge">
                    <i class="fas fa-file-circle-check"></i> {{ $sdData['badge_label'] ?? 'SUBMISSION RESULTS' }}
                </span>
                <h2 id="subformDocModalTitle">Aftersales Subform &amp; Documentation Audit Results</h2>
                <div class="subform-doc-modal-meta">
                    <span><i class="fas fa-building"></i> <strong>Branch:</strong> {{ $sdData['branch'] ?: 'Assigned Outlet' }}</span>
                    <span><i class="fas fa-calendar-day"></i> <strong>Date:</strong> {{ $sdData['audit_date'] ? \Carbon\Carbon::parse($sdData['audit_date'])->format('F j, Y') : 'Active Period' }}</span>
                    <span><i class="fas fa-user-check"></i> <strong>Auditor:</strong> {{ $sdData['auditor'] ?: 'Operational Checkers' }}</span>
                </div>
            </div>
            <button type="button" class="subform-doc-modal-close" onclick="closeSubformDocModal()" aria-label="Close modal">
                <i class="fas fa-times"></i>
            </button>
        </header>

        {{-- TAB SWITCHER --}}
        <div class="subform-doc-modal-tabs" role="tablist">
            <button type="button" class="modal-tab-btn is-active" id="tabBtnSubform" role="tab" aria-selected="true" onclick="switchSubformDocModalTab('subform')">
                <i class="fas fa-layer-group"></i>
                <span>DOS Subform Standards ({{ $subformInfo['total_items'] ?? 39 }})</span>
                @if ($hasSubform)
                    <span class="tab-rating-pill {{ ($subformInfo['rating'] ?? '') === 'PASS' ? 'is-pass' : 'is-fail' }}">
                        {{ $subformInfo['score_percent'] ?? 0 }}% {{ $subformInfo['rating'] ?? '' }}
                    </span>
                @else
                    <span class="tab-rating-pill is-none">Not Recorded</span>
                @endif
            </button>
            <button type="button" class="modal-tab-btn" id="tabBtnDoc" role="tab" aria-selected="false" onclick="switchSubformDocModalTab('documentation')">
                <i class="fas fa-file-lines"></i>
                <span>DOS Documentation Standards {{ $hasDoc ? '(' . $docTotalSamples . ' ' . \Illuminate\Support\Str::plural('Sample', $docTotalSamples) . ')' : '(3 Samples)' }}</span>
                @if ($hasDoc)
                    <span class="tab-rating-pill {{ ($docInfo['rating'] ?? '') === 'PASS' ? 'is-pass' : 'is-fail' }}">
                        {{ $docInfo['score_percent'] ?? 0 }}% {{ $docInfo['rating'] ?? '' }}
                    </span>
                @else
                    <span class="tab-rating-pill is-none">Not Recorded</span>
                @endif
            </button>
        </div>

        {{-- TAB PANEL 1: SUBFORM RESULTS --}}
        <div class="subform-doc-modal-panel is-active" id="panelSubform" role="tabpanel">
            @if ($hasSubform)
                {{-- SUMMARY METRICS --}}
                <div class="modal-metrics-grid">
                    <div class="modal-metric-card">
                        <span class="metric-label">Total Standards</span>
                        <span class="metric-value">{{ $subformInfo['total_items'] ?? 0 }}</span>
                        <span class="metric-sub">Across {{ count($subformSections) }} Operational Areas</span>
                    </div>
                    <div class="modal-metric-card">
                        <span class="metric-label">Compliant (YES)</span>
                        <span class="metric-value text-success">{{ $subformInfo['yes_count'] ?? 0 }}</span>
                        <span class="metric-sub">Passed Standards</span>
                    </div>
                    <div class="modal-metric-card">
                        <span class="metric-label">Non-Compliant (NO)</span>
                        <span class="metric-value {{ ($subformInfo['no_count'] ?? 0) > 0 ? 'text-danger' : '' }}">{{ $subformInfo['no_count'] ?? 0 }}</span>
                        <span class="metric-sub">Requires Action Plan</span>
                    </div>
                    <div class="modal-metric-card">
                        <span class="metric-label">Not Applicable (N/A)</span>
                        <span class="metric-value text-muted">{{ $subformInfo['na_count'] ?? 0 }}</span>
                        <span class="metric-sub">Excluded from Score</span>
                    </div>
                    <div class="modal-metric-card score-highlight">
                        <span class="metric-label">Subform Score</span>
                        <span class="metric-value">{{ $subformInfo['score_percent'] ?? 0 }}%</span>
                        <span class="metric-badge {{ ($subformInfo['rating'] ?? '') === 'PASS' ? 'badge-pass' : 'badge-fail' }}">
                            {{ $subformInfo['rating'] ?? 'N/A' }}
                        </span>
                    </div>
                </div>

                {{-- 5 OPERATIONAL AREAS SUMMARY --}}
                <div class="modal-section-title">
                    <i class="fas fa-list-check"></i> Subform Performance by Operational Area
                </div>
                <div class="modal-table-responsive">
                    <table class="modal-data-table">
                        <thead>
                            <tr>
                                <th style="width: 50px;">No.</th>
                                <th>Operational Area / Section</th>
                                <th style="width: 90px; text-align: center;">Standards</th>
                                <th style="width: 80px; text-align: center;">YES</th>
                                <th style="width: 80px; text-align: center;">NO</th>
                                <th style="width: 80px; text-align: center;">N/A</th>
                                <th style="width: 100px; text-align: center;">% Score</th>
                                <th style="width: 100px; text-align: center;">Rating</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($subformSections as $sIndex => $sec)
                                <tr>
                                    <td>{{ $sIndex + 1 }}</td>
                                    <td><strong>{{ $sec['title'] }}</strong></td>
                                    <td style="text-align: center;">{{ $sec['total'] }}</td>
                                    <td style="text-align: center;" class="text-success font-bold">{{ $sec['yes'] }}</td>
                                    <td style="text-align: center;" class="{{ $sec['no'] > 0 ? 'text-danger font-bold' : '' }}">{{ $sec['no'] }}</td>
                                    <td style="text-align: center;" class="text-muted">{{ $sec['na'] }}</td>
                                    <td style="text-align: center; font-weight: 700;">
                                        @if ($sec['answered'] > 0)
                                            {{ $sec['score_percent'] }}%
                                        @else
                                            <span class="text-muted">—</span>
                                        @endif
                                    </td>
                                    <td style="text-align: center;">
                                        @if ($sec['answered'] > 0)
                                            <span class="modal-rating-chip {{ $sec['rating'] === 'PASS' ? 'is-pass' : 'is-fail' }}">
                                                {{ $sec['rating'] }}
                                            </span>
                                        @else
                                            <span class="status-pill is-unanswered">N/A</span>
                                        @endif
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="8" class="text-center text-muted">No subform sections available.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                {{-- ITEMIZED SUBFORM QUESTIONS --}}
                <div class="modal-section-title" style="margin-top: 24px;">
                    <i class="fas fa-clipboard-list"></i> Itemized Standards Evaluation ({{ $subformInfo['total_items'] ?? 39 }} Standards)
                </div>
                <div class="modal-table-responsive" style="max-height: 380px; overflow-y: auto;">
                    <table class="modal-data-table modal-itemized-table">
                        <thead>
                            <tr>
                                <th style="width: 45px;">#</th>
                                <th style="width: 160px;">Area</th>
                                <th>Standard Prompt</th>
                                <th style="width: 120px;">Checker</th>
                                <th style="width: 90px; text-align: center;">Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            @php $itemGlobalIndex = 1; @endphp
                            @foreach ($subformSections as $sec)
                                @foreach ($sec['items'] as $it)
                                    <tr>
                                        <td class="text-muted">{{ $itemGlobalIndex++ }}</td>
                                        <td><span class="area-chip">{{ $sec['title'] }}</span></td>
                                        <td>
                                            <div class="item-prompt-text">{{ $it['prompt'] }}</div>
                                            @if (!empty($it['remark']))
                                                <div class="item-remark-text"><i class="fas fa-comment-dots"></i> {{ $it['remark'] }}</div>
                                            @endif
                                        </td>
                                        <td><span class="checker-chip">{{ $it['checker'] ?: 'AUDITOR' }}</span></td>
                                        <td style="text-align: center;">
                                            @if ($it['status'] === 'yes')
                                                <span class="status-pill is-yes"><i class="fas fa-check"></i> YES</span>
                                            @elseif ($it['status'] === 'no')
                                                <span class="status-pill is-no"><i class="fas fa-times"></i> NO</span>
                                            @elseif ($it['status'] === 'na')
                                                <span class="status-pill is-na">N/A</span>
                                            @else
                                                <span class="status-pill is-unanswered">-</span>
                                            @endif
                                        </td>
                                    </tr>
                                @endforeach
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @else
                <div class="subform-doc-empty-state">
                    <div class="empty-icon"><i class="fas fa-folder-open"></i></div>
                    <h3>No Subform Audit Records</h3>
                    <p>Subform standards (Service Reception, Employee Facilities, Meeting Room, MQS, Customer Lounge) have not been evaluated for this period.</p>
                </div>
            @endif
        </div>

        {{-- TAB PANEL 2: DOCUMENTATION RESULTS --}}
        <div class="subform-doc-modal-panel" id="panelDoc" role="tabpanel" style="display: none;">
            @if ($hasDoc && $docTotalSamples > 0)
                {{-- SUMMARY METRICS --}}
                <div class="modal-metrics-grid">
                    <div class="modal-metric-card">
                        <span class="metric-label">Evaluated Samples</span>
                        <span class="metric-value">{{ $docTotalSamples }}</span>
                        <span class="metric-sub">Customer Repair Orders</span>
                    </div>
                    <div class="modal-metric-card">
                        <span class="metric-label">Total Checks</span>
                        <span class="metric-value">{{ $docInfo['total_checks'] ?? 0 }}</span>
                        <span class="metric-sub">Across {{ $docTotalSamples }} {{ \Illuminate\Support\Str::plural('Sample', $docTotalSamples) }}</span>
                    </div>
                    <div class="modal-metric-card">
                        <span class="metric-label">Compliant Checks</span>
                        <span class="metric-value text-success">{{ $docInfo['yes_count'] ?? 0 }}</span>
                        <span class="metric-sub">Audited &amp; Verified</span>
                    </div>
                    <div class="modal-metric-card">
                        <span class="metric-label">Non-Compliant Checks</span>
                        <span class="metric-value {{ ($docInfo['no_count'] ?? 0) > 0 ? 'text-danger' : '' }}">{{ $docInfo['no_count'] ?? 0 }}</span>
                        <span class="metric-sub">Deficiencies</span>
                    </div>
                    <div class="modal-metric-card score-highlight">
                        <span class="metric-label">Documentation Score</span>
                        <span class="metric-value">{{ $docInfo['score_percent'] ?? 0 }}%</span>
                        <span class="metric-badge {{ ($docInfo['rating'] ?? '') === 'PASS' ? 'badge-pass' : 'badge-fail' }}">
                            {{ $docInfo['rating'] ?? 'N/A' }}
                        </span>
                    </div>
                </div>

                {{-- SAMPLES OVERVIEW CARDS --}}
                <div class="modal-section-title">
                    <i class="fas fa-folder-open"></i> Sample Audit Details ({{ $docTotalSamples }} {{ \Illuminate\Support\Str::plural('Sample', $docTotalSamples) }})
                </div>
                <div class="modal-samples-cards-grid">
                    @foreach ($docSamples as $sample)
                        <div class="sample-detail-card">
                            <div class="sample-card-header">
                                <span class="sample-badge">Sample {{ $sample['index'] }}</span>
                                <span class="modal-rating-chip {{ $sample['rating'] === 'PASS' ? 'is-pass' : 'is-fail' }}">{{ $sample['rating'] }}</span>
                            </div>
                            <div class="sample-card-meta">
                                <div><strong>R.O. #:</strong> {{ $sample['ro_number'] ?: 'Not specified' }}</div>
                                <div><strong>Job / Mileage:</strong> {{ $sample['job_type'] ?: 'Not specified' }}</div>
                            </div>
                            <div class="sample-card-score">
                                <span>Score: <strong>{{ $sample['yes'] }} / {{ $sample['total'] }}</strong></span>
                                <span class="sample-pct font-bold">{{ $sample['score_percent'] }}%</span>
                            </div>
                        </div>
                    @endforeach
                </div>

                {{-- MULTI-SAMPLE EVALUATION MATRIX --}}
                <div class="modal-section-title" style="margin-top: 24px;">
                    <i class="fas fa-table-cells"></i> Multi-Sample Evaluation Matrix ({{ count($docMatrix) }} Standards)
                </div>
                <div class="modal-table-responsive" style="max-height: 380px; overflow-y: auto;">
                    <table class="modal-data-table modal-matrix-table">
                        <thead>
                            <tr>
                                <th style="width: 45px;">#</th>
                                <th style="width: 170px;">Section / Area</th>
                                <th>Documentation Standard</th>
                                @foreach ($docSamples as $sample)
                                    <th style="width: 120px; text-align: center;">
                                        <div>Sample {{ $sample['index'] }}</div>
                                        <div style="font-size: 10px; font-weight: normal; color: #64748b;">
                                            {{ $sample['ro_number'] ?: 'RO-'.$sample['index'] }}
                                        </div>
                                    </th>
                                @endforeach
                                <th style="width: 100px; text-align: center;">Overall</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($docMatrix as $mRow)
                                <tr>
                                    <td class="text-muted">{{ $mRow['number'] }}</td>
                                    <td><span class="area-chip">{{ $mRow['section'] }}</span></td>
                                    <td><div class="item-prompt-text">{{ $mRow['prompt'] }}</div></td>
                                    @foreach ($docSamples as $sIdx => $sample)
                                        @php
                                            $sVal = $mRow['samples'][$sIdx] ?? ($mRow['sample_'.($sIdx + 1)] ?? '-');
                                        @endphp
                                        <td style="text-align: center;">
                                            @if ($sVal === 'yes')
                                                <span class="status-pill is-yes"><i class="fas fa-check"></i> YES</span>
                                            @elseif ($sVal === 'no')
                                                <span class="status-pill is-no"><i class="fas fa-times"></i> NO</span>
                                            @elseif ($sVal === 'na')
                                                <span class="status-pill is-na">N/A</span>
                                            @else
                                                <span class="status-pill is-unanswered">-</span>
                                            @endif
                                        </td>
                                    @endforeach
                                    <td style="text-align: center;">
                                        @if ($mRow['overall_status'] === 'yes')
                                            <span class="modal-rating-chip is-pass">PASS</span>
                                        @elseif ($mRow['overall_status'] === 'no')
                                            <span class="modal-rating-chip is-fail">FAIL</span>
                                        @else
                                            <span class="status-pill is-unanswered">-</span>
                                        @endif
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="{{ 4 + $docTotalSamples }}" class="text-center text-muted">No documentation matrix available.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            @else
                <div class="subform-doc-empty-state">
                    <div class="empty-icon"><i class="fas fa-folder-open"></i></div>
                    <h3>No Documentation Audit Samples Recorded</h3>
                    <p>Documentation checks (Rationalized Checksheet, Repair Order, and Service Invoice samples) have not been submitted for this branch and period.</p>
                </div>
            @endif
        </div>

        {{-- MODAL FOOTER --}}
        <footer class="subform-doc-modal-footer">
            <button type="button" class="summary-btn" onclick="closeSubformDocModal()">
                <span>Close</span>
            </button>
            <button type="button" class="summary-btn btn-primary" onclick="printSubformDocDirectly()">
                <i class="fas fa-print"></i>
                <span>
                    @if ($hasSubform && $hasDoc)
                        Print Subform &amp; Documentation
                    @elseif ($hasSubform)
                        Print Subform Report
                    @else
                        Print Documentation Report
                    @endif
                </span>
            </button>
        </footer>
    </div>
</dialog>

<script>
    function openSubformDocModal() {
        const dialog = document.getElementById('subformDocModal');
        if (!dialog) return;
        if (typeof dialog.showModal === 'function') {
            dialog.showModal();
        } else {
            dialog.setAttribute('open', '');
        }
    }

    function closeSubformDocModal() {
        const dialog = document.getElementById('subformDocModal');
        if (!dialog) return;
        if (typeof dialog.close === 'function' && dialog.open) {
            dialog.close();
        } else {
            dialog.removeAttribute('open');
        }
    }

    function switchSubformDocModalTab(tab) {
        const tabBtnSubform = document.getElementById('tabBtnSubform');
        const tabBtnDoc = document.getElementById('tabBtnDoc');
        const panelSubform = document.getElementById('panelSubform');
        const panelDoc = document.getElementById('panelDoc');

        if (tab === 'subform') {
            tabBtnSubform?.classList.add('is-active');
            tabBtnSubform?.setAttribute('aria-selected', 'true');
            tabBtnDoc?.classList.remove('is-active');
            tabBtnDoc?.setAttribute('aria-selected', 'false');

            if (panelSubform) panelSubform.style.display = 'block';
            if (panelDoc) panelDoc.style.display = 'none';
        } else {
            tabBtnDoc?.classList.add('is-active');
            tabBtnDoc?.setAttribute('aria-selected', 'true');
            tabBtnSubform?.classList.remove('is-active');
            tabBtnSubform?.setAttribute('aria-selected', 'false');

            if (panelDoc) panelDoc.style.display = 'block';
            if (panelSubform) panelSubform.style.display = 'none';
        }
    }

    function printSubformDocDirectly() {
        closeSubformDocModal();
        if (typeof triggerAdminPrint === 'function') {
            triggerAdminPrint('subform_doc_only');
        } else {
            document.body.classList.remove('print-scope-aftersales', 'print-scope-both');
            document.body.classList.add('print-scope-subform-doc');
            window.print();
        }
    }
</script>
@endif
