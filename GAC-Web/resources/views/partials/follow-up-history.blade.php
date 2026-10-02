@php
    $historyRecords = $followUpHistory ?? collect();
@endphp

<!-- Follow-up & Escalation History Section -->
<section class="follow-up-history-card" id="followUpHistoryCard" aria-label="Follow-up and escalation history">
    <div class="card-heading register-header">
        <div>
            <div class="heading-badge-wrap">
                <span class="authority-badge">
                    <i class="fas fa-clock-rotate-left" aria-hidden="true"></i> Activity Log
                </span>
            </div>
            <h3>Follow-up &amp; Escalation History</h3>
            <p>Complete log of follow-up requests, escalation updates, and escalation follow-ups recorded in the system.</p>
        </div>
        <div class="register-actions">
            <div class="history-toolbar">
                <button type="button" class="button" id="exportFollowUpExcel" title="Export history to Excel (.xlsx)">
                    <i class="fas fa-file-excel" aria-hidden="true"></i> Export Excel
                </button>
                <button type="button" class="button" id="printFollowUpHistory" title="Print history table">
                    <i class="fas fa-print" aria-hidden="true"></i> Print History
                </button>
            </div>
        </div>
    </div>

    <div class="table-wrap register-table-wrap">
        <table class="findings-table follow-up-history-table" id="followUpHistoryTable">
            <thead>
                <tr>
                    <th>Date &amp; Time</th>
                    <th>Action Type</th>
                    <th>Performed By</th>
                    <th>Branch</th>
                    <th>Checklist &amp; Item</th>
                    <th>Escalation Target</th>
                    <th class="actions-col">Action</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($historyRecords as $record)
                    <tr class="history-row"
                        data-history-record="{{ json_encode($record, JSON_HEX_APOS | JSON_HEX_QUOT) }}">
                        <td class="meta-cell">
                            <div class="audit-date-badge">
                                <strong>{{ $record['generated_at'] ?? '—' }}</strong>
                            </div>
                            <small class="history-diff-time">{{ $record['generated_at_diff'] ?? '' }}</small>
                        </td>
                        <td>
                            <span class="history-action-badge {{ $record['type'] }}">
                                <i class="fas {{ $record['action_icon'] }}" aria-hidden="true"></i>
                                {{ $record['action_type'] }}
                            </span>
                        </td>
                        <td class="meta-cell">
                            <strong>{{ $record['performed_by'] }}</strong>
                            <small class="role-pill-micro">{{ $record['performed_by_role'] }}</small>
                        </td>
                        <td><span class="branch-tag"><i class="fas fa-building" aria-hidden="true"></i> {{ $record['branch'] }}</span></td>
                        <td class="item-cell">
                            <span class="template-chip-sm">{{ $record['template_name'] }}</span>
                            @if ($record['item_key'] && $record['item_key'] !== '—')
                                <code class="item-code">{{ $record['item_key'] }}</code>
                            @endif
                        </td>
                        <td>
                            @if ($record['escalation_target'])
                                <div class="escalation-badge {{ strtolower(str_replace('_', '-', $record['escalation_target'])) }}">
                                    <i class="fas fa-share-nodes" aria-hidden="true"></i>
                                    <span>{{ $record['escalation_label'] }}</span>
                                </div>
                            @else
                                <span class="no-escalation-text"><i class="fas fa-minus" aria-hidden="true"></i> —</span>
                            @endif
                        </td>
                        <td class="actions-cell">
                            <button type="button" class="button button-sm button-view-finding" data-view-history-detail title="View and print official corporate document">
                                <i class="fas fa-eye" aria-hidden="true"></i> View
                            </button>
                        </td>
                    </tr>
                @empty
                    <tr class="empty-row">
                        <td colspan="7">
                            <div class="empty-findings-box">
                                <i class="fas fa-folder-open" aria-hidden="true"></i>
                                <strong>No Follow-up or Escalation Activity Yet</strong>
                                <p>Follow-up requests, escalation updates, and escalation follow-ups will appear here once they are recorded.</p>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</section>

<!-- SheetJS for Excel export -->
<script src="https://cdn.sheetjs.com/xlsx-0.20.3/package/dist/xlsx.full.min.js"></script>

<script>
(() => {
    // ─── Print history table ────────────────────────────────────────
    document.getElementById('printFollowUpHistory')?.addEventListener('click', () => {
        document.body.classList.add('follow-up-history-print-ready');
        window.print();
        setTimeout(() => document.body.classList.remove('follow-up-history-print-ready'), 1000);
    });

    // ─── Excel export via SheetJS ───────────────────────────────────
    document.getElementById('exportFollowUpExcel')?.addEventListener('click', () => {
        if (typeof XLSX === 'undefined') {
            alert('Excel export library is still loading. Please try again in a moment.');
            return;
        }

        const rows = document.querySelectorAll('#followUpHistoryTable .history-row');
        if (!rows.length) {
            alert('No history records to export.');
            return;
        }

        const data = [
            ['Date & Time', 'Action Type', 'Performed By', 'Role', 'Branch', 'Checklist', 'Item Code', 'Escalation Target', 'Action Plan', 'Commitment Date', 'Finding', 'Remarks']
        ];

        rows.forEach(row => {
            let record;
            try { record = JSON.parse(row.dataset.historyRecord); } catch { return; }
            data.push([
                record.generated_at || '',
                record.action_type || '',
                record.performed_by || '',
                record.performed_by_role || '',
                record.branch || '',
                record.template_name || '',
                record.item_key || '',
                record.escalation_label || '',
                record.action_plan || '',
                record.commitment_date || '',
                record.finding || '',
                record.remarks || '',
            ]);
        });

        const wb = XLSX.utils.book_new();
        const ws = XLSX.utils.aoa_to_sheet(data);

        // Auto-width columns
        ws['!cols'] = data[0].map((_, i) => ({
            wch: Math.max(...data.map(r => String(r[i] || '').length), 12)
        }));

        XLSX.utils.book_append_sheet(wb, ws, 'Follow-up History');
        XLSX.writeFile(wb, 'gateway-follow-up-history-' + new Date().toISOString().slice(0, 10) + '.xlsx');
    });
})();
</script>
