<!-- Shared Finding Detail Modal with Executive Summary & Corporate Layout -->
<div class="report-modal-backdrop" id="followUpHistoryDetailModal" role="dialog" aria-modal="true" aria-labelledby="historyDetailModalTitle">
    <div class="modal-card modal-card-xl follow-up-detail-modal-card">
        <div class="modal-heading">
            <div class="modal-title-wrap">
                <span class="modal-eyebrow"><i class="fas fa-file-shield" aria-hidden="true"></i> Quality Audit Record</span>
                <h3 id="historyDetailModalTitle">Checklist Finding Summary</h3>
            </div>
            <div class="modal-header-actions">
                <button type="button" class="button primary" id="printHistoryDetailBtn" title="Print official corporate finding document">
                    <i class="fas fa-print" aria-hidden="true"></i> Print Official Report
                </button>
                <button type="button" class="modal-close-btn" id="closeHistoryDetailModal" aria-label="Close dialog">&times;</button>
            </div>
        </div>

        <div class="modal-body follow-up-detail-body">
            <!-- ═════════════════════════════════════════════════════════
                 EXECUTIVE SUMMARIZED VIEW (Clean, Concise, Responsive)
                 ═════════════════════════════════════════════════════════ -->
            <div class="exec-summary-wrapper">
                <!-- 1. Executive Metric Ribbon (4 Key Pillars) -->
                <div class="exec-ribbon-grid">
                    <div class="exec-ribbon-card">
                        <span class="exec-ribbon-label"><i class="fas fa-building" aria-hidden="true"></i> Dealership Branch</span>
                        <strong class="exec-ribbon-val" id="execBranch">—</strong>
                        <div class="exec-ribbon-sub">
                            <span id="execAuditDate">—</span> &bull; <span id="execSubmissionId">—</span>
                        </div>
                    </div>

                    <div class="exec-ribbon-card">
                        <span class="exec-ribbon-label"><i class="fas fa-clipboard-list" aria-hidden="true"></i> Checklist &amp; Item</span>
                        <strong class="exec-ribbon-val" id="execTemplateName">—</strong>
                        <div class="exec-ribbon-sub">
                            <code class="exec-code" id="execItemCode">—</code> <span id="execArea">—</span>
                        </div>
                    </div>

                    <div class="exec-ribbon-card">
                        <span class="exec-ribbon-label"><i class="fas fa-circle-exclamation" aria-hidden="true"></i> Audit Status</span>
                        <div class="exec-status-row">
                            <span class="exec-status-badge" id="execStatusBadge">—</span>
                        </div>
                        <div class="exec-ribbon-sub">
                            Auditor: <strong id="execAuditor">—</strong> <span id="execAuditorRole"></span>
                        </div>
                    </div>

                    <div class="exec-ribbon-card">
                        <span class="exec-ribbon-label"><i class="fas fa-share-nodes" aria-hidden="true"></i> Escalation &amp; Due</span>
                        <strong class="exec-ribbon-val exec-accent-target" id="execEscalationTarget">—</strong>
                        <div class="exec-ribbon-sub">
                            Commitment: <strong id="execCommitmentDate">—</strong>
                            <span id="execDueBadge" class="exec-due-badge"></span>
                        </div>
                    </div>
                </div>

                <!-- 2. Two-Column Executive Detail Cards -->
                <div class="exec-cards-grid">
                    <!-- Left Column: Deficiency & Evidence -->
                    <div class="exec-col">
                        <!-- Requirement Card -->
                        <div class="exec-card">
                            <div class="exec-card-title">
                                <i class="fas fa-book-open" aria-hidden="true"></i> Checklist Requirement Standard
                            </div>
                            <div class="exec-prompt-box">
                                <p id="execItemPrompt">—</p>
                            </div>
                        </div>

                        <!-- Finding / Deficiency Callout -->
                        <div class="exec-card exec-card-danger">
                            <div class="exec-card-title text-danger">
                                <i class="fas fa-triangle-exclamation" aria-hidden="true"></i> Recorded Deficiency / Observation
                            </div>
                            <div class="exec-finding-box">
                                <p id="execFindingDetail">—</p>
                            </div>
                            <div id="execBomTaskWrap" class="exec-bom-task-box" style="display:none;">
                                <strong><i class="fas fa-tasks" aria-hidden="true"></i> Assigned BOM Task:</strong>
                                <span id="execBomTask">—</span>
                            </div>
                        </div>

                        <!-- Compiled Questions Card (for compiled utilities inspections) -->
                        <div class="exec-card" id="execCompiledQuestionsCard" style="display:none;">
                            <div class="exec-card-title text-primary">
                                <i class="fas fa-list-check" aria-hidden="true"></i> Compiled Checklist Questions (<span id="execCompiledQuestionsCount">0</span> Items)
                            </div>
                            <div id="execCompiledQuestionsContainer" style="max-height: 220px; overflow-y: auto; padding: 6px; font-size: 11px;"></div>
                        </div>

                        <!-- Evidence Photos -->
                        <div class="exec-card" id="execPhotosCard" style="display:none;">
                            <div class="exec-card-title">
                                <i class="fas fa-camera" aria-hidden="true"></i> Inspection Photo Evidence
                            </div>
                            <div id="execPhotosContainer" class="exec-photos-grid"></div>
                        </div>
                    </div>

                    <!-- Right Column: Action Plan & Escalation -->
                    <div class="exec-col">
                        <!-- Corrective Action Plan -->
                        <div class="exec-card exec-card-success">
                            <div class="exec-card-title text-success">
                                <i class="fas fa-wrench" aria-hidden="true"></i> Corrective Action Plan
                            </div>
                            <div class="exec-action-box">
                                <p id="execActionPlan">—</p>
                            </div>
                            <div id="execPrevUpdatesWrap" class="exec-prev-updates-box" style="display:none;">
                                <small class="text-muted"><i class="fas fa-history" aria-hidden="true"></i> <span id="execPrevUpdates">—</span></small>
                            </div>
                        </div>

                        <!-- Escalation & Accountable Details -->
                        <div class="exec-card">
                            <div class="exec-card-title">
                                <i class="fas fa-user-gear" aria-hidden="true"></i> Accountability &amp; Follow-up
                            </div>
                            <div class="exec-meta-list">
                                <div class="exec-meta-row">
                                    <span class="exec-meta-label">Escalation Recipient:</span>
                                    <strong id="execEscalationOwner">—</strong>
                                </div>
                                <div class="exec-meta-row">
                                    <span class="exec-meta-label">Checker / Verification:</span>
                                    <span id="execChecker">—</span>
                                </div>
                                <div class="exec-meta-row">
                                    <span class="exec-meta-label">Person Accountable:</span>
                                    <span id="execAccountable">—</span>
                                </div>
                                <div class="exec-meta-row">
                                    <span class="exec-meta-label">Resolution Commitment:</span>
                                    <span id="execCommitmentFull">—</span>
                                </div>
                            </div>
                        </div>

                        <!-- Follow-up Activity & Override Log (if exists) -->
                        <div class="exec-card" id="execTrailCard" style="display:none;">
                            <div class="exec-card-title">
                                <i class="fas fa-clock-rotate-left" aria-hidden="true"></i> Follow-up &amp; Override Trail
                            </div>
                            <div class="exec-trail-content">
                                <div id="execTrailActionWrap" class="exec-trail-item" style="display:none;">
                                    <span class="exec-trail-badge" id="execTrailActionType">Follow-up</span>
                                    <small class="exec-trail-time" id="execTrailTimestamp">—</small>
                                </div>
                                <p id="execTrailRemarks" class="exec-trail-remarks" style="display:none;">—</p>
                                <div id="execOverrideWrap" class="exec-override-callout" style="display:none;">
                                    <div class="override-callout-header">
                                        <strong><i class="fas fa-shield-check" aria-hidden="true"></i> Manager Override Record</strong>
                                        <span class="override-timestamp-badge" id="execOverrideTimestamp"><i class="fas fa-clock" aria-hidden="true"></i> —</span>
                                    </div>
                                    <div class="override-callout-meta" id="execOverrideMeta">—</div>
                                    <p id="execOverrideDetails" class="override-callout-details">—</p>
                                    <div id="execOverrideProofWrap" class="override-proof-callout-wrap" style="display:none;">
                                        <span class="proof-label"><i class="fas fa-paperclip" aria-hidden="true"></i> Attached Proof:</span>
                                        <a href="#" target="_blank" rel="noopener noreferrer" class="override-proof-link-card" id="execOverrideProofLink">
                                            <span id="execOverrideProofName">View attached proof document</span>
                                            <i class="fas fa-arrow-up-right-from-square" aria-hidden="true"></i>
                                        </a>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 3. Executive Sign-off Status Strip -->
                <div class="exec-signoff-strip">
                    <div class="exec-signoff-item is-complete">
                        <i class="fas fa-circle-check" aria-hidden="true"></i>
                        <div>
                            <strong>Lead Auditor Inspected</strong>
                            <small id="execSignAuditor">Inspected &amp; Logged</small>
                        </div>
                    </div>
                    <div class="exec-signoff-arrow"><i class="fas fa-chevron-right" aria-hidden="true"></i></div>
                    <div class="exec-signoff-item is-complete">
                        <i class="fas fa-circle-check" aria-hidden="true"></i>
                        <div>
                            <strong>BOM Action Plan Assigned</strong>
                            <small id="execSignBom">Escalated with Commitment Date</small>
                        </div>
                    </div>
                    <div class="exec-signoff-arrow"><i class="fas fa-chevron-right" aria-hidden="true"></i></div>
                    <div class="exec-signoff-item">
                        <i class="fas fa-circle-half-stroke" aria-hidden="true"></i>
                        <div>
                            <strong>General Manager Oversight</strong>
                            <small>Review &amp; Executive Sign-off</small>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Hidden container for print template reference -->
            <div id="corporateFindingDocSheet" style="display:none;" aria-hidden="true"></div>
        </div>

        <div class="modal-footer">
            <button type="button" class="button" id="cancelHistoryDetailBtn">Close</button>
            <button type="button" class="button primary" id="printHistoryDetailBtnBottom">
                <i class="fas fa-print" aria-hidden="true"></i> Print Official Report
            </button>
        </div>
    </div>
</div>

<script>
(() => {
    const detailModal = document.getElementById('followUpHistoryDetailModal');
    const closeDetailBtn = document.getElementById('closeHistoryDetailModal');
    const cancelDetailBtn = document.getElementById('cancelHistoryDetailBtn');
    const printDetailBtn = document.getElementById('printHistoryDetailBtn');
    const printDetailBtnBottom = document.getElementById('printHistoryDetailBtnBottom');
    let activeFindingRecord = null;

    function closeDetailModal() {
        detailModal?.classList.remove('is-open');
        document.body.classList.remove('modal-finding-open');
        activeFindingRecord = null;
    }

    closeDetailBtn?.addEventListener('click', closeDetailModal);
    cancelDetailBtn?.addEventListener('click', closeDetailModal);
    detailModal?.addEventListener('click', (e) => {
        if (e.target === detailModal) closeDetailModal();
    });
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && detailModal?.classList.contains('is-open')) closeDetailModal();
    });

    function setText(id, text) {
        const el = document.getElementById(id);
        if (el) el.textContent = text || '—';
    }

    function showIf(id, condition) {
        const el = document.getElementById(id);
        if (el) el.style.display = condition ? '' : 'none';
    }

    // Populate modal from finding data
    window.openFindingDetailModal = function(data) {
        if (!data) return;
        activeFindingRecord = data;

        const responseId = data.response_id || data.id || 'N/A';
        const submissionId = data.submission_id ? '#' + data.submission_id : '—';
        const auditDate = data.audit_date || '—';
        const branch = data.branch || '—';
        const templateName = data.template_name || 'Checklist Audit';
        const itemKey = data.item_key || '—';
        const itemPrompt = data.item || data.question || 'No requirement prompt recorded.';
        const auditor = data.auditor || data.performed_by || 'Not recorded';
        const auditorRole = data.auditor_role || data.performed_by_role || '';
        const findingText = data.detail || data.finding || 'No deficiency details recorded.';
        const bomTask = data.bom_task || '';
        const actionPlan = data.action_plan || 'Pending corrective action plan by branch operations manager.';
        const escalationTarget = data.escalation_target_label || data.escalation_label || (data.escalation_target ? data.escalation_target.replace(/_/g, ' ').toUpperCase() : 'Not Assigned');
        const commitmentDate = data.commitment_date_formatted || data.commitment_date || 'Not Set';
        const dueStatus = data.due_status || (data.is_overdue ? 'Overdue' : '');

        // 1. Ribbon
        setText('execBranch', branch);
        setText('execAuditDate', auditDate);
        setText('execSubmissionId', submissionId);
        setText('execTemplateName', templateName);
        setText('execItemCode', itemKey);
        setText('execArea', data.area ? '(' + data.area + ')' : '');

        // Status Badge
        const statusBadge = document.getElementById('execStatusBadge');
        if (statusBadge) {
            const isNo = data.status === 'no' || data.status === 'x' || !data.status;
            statusBadge.textContent = data.result || (isNo ? 'DEFICIENT (NO)' : 'COMPLIANT');
            statusBadge.className = 'exec-status-badge ' + (isNo ? 'is-danger' : 'is-success');
        }

        setText('execAuditor', auditor);
        setText('execAuditorRole', auditorRole ? '(' + auditorRole + ')' : '');

        setText('execEscalationTarget', escalationTarget);
        setText('execCommitmentDate', commitmentDate);

        const dueBadge = document.getElementById('execDueBadge');
        if (dueBadge) {
            if (dueStatus) {
                dueBadge.textContent = dueStatus;
                dueBadge.className = 'exec-due-badge ' + (data.is_overdue ? 'is-overdue' : 'is-upcoming');
                dueBadge.style.display = '';
            } else {
                dueBadge.style.display = 'none';
            }
        }

        // 2. Left Column Cards
        setText('execItemPrompt', itemPrompt);
        setText('execFindingDetail', findingText);

        const hasBomTask = !!(bomTask && bomTask.trim());
        showIf('execBomTaskWrap', hasBomTask);
        setText('execBomTask', bomTask);

        // Photos
        const photosContainer = document.getElementById('execPhotosContainer');
        const photos = [];
        if (data.attachment_url) photos.push({ url: data.attachment_url, alt: 'Primary audit inspection photo' });
        if (data.override_details?.attachment_url && data.override_details.is_image !== false) {
            photos.push({ url: data.override_details.attachment_url, alt: 'Manager override proof photo' });
        }
        if (Array.isArray(data.photos)) {
            data.photos.forEach(p => {
                const u = typeof p === 'string' ? p : (p.url || '');
                if (u && !photos.some(existing => existing.url === u)) {
                    photos.push({ url: u, alt: 'Follow-up evidence photo' });
                }
            });
        }

        if (photos.length > 0 && photosContainer) {
            photosContainer.innerHTML = '';
            photos.forEach(photo => {
                const link = document.createElement('a');
                link.href = photo.url;
                link.target = '_blank';
                link.rel = 'noopener noreferrer';
                link.className = 'exec-photo-card';
                link.title = 'Click to view full photo';
                const img = document.createElement('img');
                img.src = photo.url;
                img.alt = photo.alt;
                img.loading = 'lazy';
                link.appendChild(img);
                photosContainer.appendChild(link);
            });
            showIf('execPhotosCard', true);
        } else {
            showIf('execPhotosCard', false);
        }

        // Compiled questions for utilities checklist
        const compiledContainer = document.getElementById('execCompiledQuestionsContainer');
        const compiledCountSpan = document.getElementById('execCompiledQuestionsCount');
        const compiledQuestions = Array.isArray(data.compiled_questions) ? data.compiled_questions : (Array.isArray(data.questions) ? data.questions : []);

        if (compiledQuestions.length > 0 && compiledContainer) {
            compiledContainer.innerHTML = '';
            if (compiledCountSpan) compiledCountSpan.textContent = compiledQuestions.length;
            const ol = document.createElement('ol');
            ol.style.margin = '0 0 0 16px';
            ol.style.padding = '0';
            ol.style.lineHeight = '1.6';
            compiledQuestions.forEach(q => {
                const li = document.createElement('li');
                li.style.marginBottom = '4px';
                li.innerHTML = `<strong>${q.area || ''}:</strong> ${q.question || q.item_key} <span style="display:inline-block;padding:1px 5px;font-size:9px;font-weight:800;border-radius:4px;background:rgba(217,45,32,0.2);color:#f87171;margin-left:4px;">${q.result || 'X'}</span>`;
                ol.appendChild(li);
            });
            compiledContainer.appendChild(ol);
            showIf('execCompiledQuestionsCard', true);
        } else {
            showIf('execCompiledQuestionsCard', false);
        }

        // 3. Right Column Cards
        setText('execActionPlan', actionPlan);

        const prevUpdates = [];
        if (data.previous_escalation_target && data.previous_escalation_target !== data.escalation_target) {
            prevUpdates.push('Prev Target: ' + data.previous_escalation_target.replace(/_/g, ' '));
        }
        if (data.previous_commitment_date && data.previous_commitment_date !== data.commitment_date) {
            prevUpdates.push('Prev Commitment: ' + data.previous_commitment_date);
        }
        showIf('execPrevUpdatesWrap', prevUpdates.length > 0);
        setText('execPrevUpdates', prevUpdates.join(' | '));

        setText('execEscalationOwner', escalationTarget);
        setText('execChecker', data.checker_role || 'General Manager / Auditor');
        setText('execAccountable', data.person_accountable || 'Branch Operations');
        setText('execCommitmentFull', commitmentDate + (dueStatus ? ' (' + dueStatus + ')' : ''));

        // Trail & Override
        let hasTrail = false;
        if (data.action_type || data.generated_at) {
            setText('execTrailActionType', data.action_type || 'Update Logged');
            setText('execTrailTimestamp', data.generated_at || '—');
            showIf('execTrailActionWrap', true);
            hasTrail = true;
        } else {
            showIf('execTrailActionWrap', false);
        }

        const hasRemarks = !!(data.remarks && data.remarks.trim());
        showIf('execTrailRemarks', hasRemarks);
        if (hasRemarks) {
            setText('execTrailRemarks', data.remarks);
            hasTrail = true;
        }

        const override = data.override_details;
        const isOverridden = data.is_overridden || !!override;
        showIf('execOverrideWrap', isOverridden);
        if (isOverridden) {
            const reason = override ? (override.reason || override.override_reason || 'Manager Override') : 'Status overridden';
            const by = override ? (override.overridden_by_name || 'Manager') : '';
            const role = override ? (override.overridden_by_role || '') : '';
            const time = override ? (override.overridden_at_formatted || override.overridden_at || '') : '';

            setText('execOverrideDetails', reason);
            setText('execOverrideTimestamp', time ? time : 'Logged');
            setText('execOverrideMeta', by ? ('Authorized by ' + by + (role ? ' (' + role + ')' : '')) : 'Authorized Manager Override');

            if (override && override.attachment_url) {
                showIf('execOverrideProofWrap', true);
                const proofLink = document.getElementById('execOverrideProofLink');
                if (proofLink) proofLink.href = override.attachment_url;
                setText('execOverrideProofName', override.attachment_name ? 'View ' + override.attachment_name : 'View attached proof file');
            } else {
                showIf('execOverrideProofWrap', false);
            }

            hasTrail = true;
        }
        showIf('execTrailCard', hasTrail);

        // Sign-offs
        setText('execSignAuditor', auditor !== 'Not recorded' ? auditor + ' (Verified)' : 'Inspection Logged');
        setText('execSignBom', (data.performed_by && data.performed_by !== auditor) ? data.performed_by + ' (BOM)' : 'Action Plan Recorded');

        detailModal?.classList.add('is-open');
        document.body.classList.add('modal-finding-open');
    };

    // Click handler for Findings table rows
    document.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-view-finding]');
        if (!btn) return;
        try {
            const raw = btn.getAttribute('data-finding') || btn.getAttribute('data-finding-json');
            if (raw) {
                const data = JSON.parse(raw);
                window.openFindingDetailModal(data);
            }
        } catch (err) {
            console.error('Failed to parse finding data', err);
        }
    });

    // Click handler for History table rows
    document.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-view-history-detail]');
        if (!btn) return;
        const row = btn.closest('.history-row');
        if (!row) return;
        try {
            const data = JSON.parse(row.dataset.historyRecord);
            window.openFindingDetailModal(data);
        } catch (err) {
            console.error('Failed to parse history data', err);
        }
    });

    // ─── ISOLATED CORPORATE PRINT ENGINE ─────────────────────────
    // Prints the full official corporate document with Gateway Logo at top-left
    function printIsolatedFindingDocument(data) {
        if (!data) return;

        let iframe = document.getElementById('isolatedFindingPrintFrame');
        if (iframe) iframe.remove();

        iframe = document.createElement('iframe');
        iframe.id = 'isolatedFindingPrintFrame';
        iframe.style.position = 'fixed';
        iframe.style.right = '0';
        iframe.style.bottom = '0';
        iframe.style.width = '0';
        iframe.style.height = '0';
        iframe.style.border = '0';
        document.body.appendChild(iframe);

        const circleLogoUrl = "{{ asset('images/Gateway_logo_circle.png') }}";
        const gatewayWordmarkUrl = "{{ asset('images/no-bg-gateway-logo.png') }}";
        const responseId = data.response_id || data.id || 'N/A';
        const submissionId = data.submission_id ? '#' + data.submission_id : '—';
        const auditDate = data.audit_date || '—';
        const branch = data.branch || '—';
        const templateName = data.template_name || 'Checklist Audit';
        const itemKey = data.item_key || '—';
        const itemPrompt = data.item || data.question || 'No requirement prompt recorded.';
        const auditor = data.auditor || data.performed_by || 'Not recorded';
        const auditorRole = data.auditor_role || data.performed_by_role || '';
        const findingText = data.detail || data.finding || 'No deficiency details recorded.';
        const bomTask = data.bom_task || '';
        const actionPlan = data.action_plan || 'Pending corrective action plan.';
        const escalationTarget = data.escalation_target_label || data.escalation_label || (data.escalation_target ? data.escalation_target.replace(/_/g, ' ').toUpperCase() : 'None assigned');
        const commitmentDate = data.commitment_date_formatted || data.commitment_date || 'Not set';
        const isNo = data.status === 'no' || data.status === 'x' || !data.status;
        const resultLabel = data.result || (isNo ? 'DEFICIENT (NO)' : 'COMPLIANT');
        const dueStatus = data.due_status || (data.is_overdue ? 'Overdue' : '');

        const photos = [];
        if (data.attachment_url) photos.push(data.attachment_url);
        if (Array.isArray(data.photos)) {
            data.photos.forEach(p => {
                const u = typeof p === 'string' ? p : (p.url || '');
                if (u && !photos.includes(u)) photos.push(u);
            });
        }

        const iframeDoc = iframe.contentWindow.document;
        iframeDoc.open();
        iframeDoc.write(`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>GATEWAY AUDIT RECORD - ${itemKey}</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        @page { size: A4 portrait; margin: 12mm 14mm; }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            color: #0f172a;
            background: #ffffff;
            font-size: 9.5pt;
            line-height: 1.45;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }
        .corp-header-banner {
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #0f172a !important;
            color: #ffffff !important;
            padding: 14px 18px;
            border-radius: 6px;
            margin-bottom: 12px;
            gap: 16px;
        }
        .corp-header-left {
            display: flex;
            align-items: center;
            gap: 14px;
        }
        .corp-header-logo-box {
            display: flex;
            align-items: center;
            justify-content: center;
            background: rgba(255, 255, 255, 0.08);
            width: 48px;
            height: 48px;
            padding: 3px;
            border-radius: 4px;
            border: 1px solid rgba(255, 255, 255, 0.15);
            overflow: hidden;
            flex: 0 0 48px;
        }
        .corp-header-logo {
            width: 100%;
            height: 100%;
            object-fit: contain;
            display: block;
        }
        .corp-title {
            display: flex;
            align-items: center;
            gap: 7px;
            color: #ffffff !important;
            line-height: 1.2;
        }
        .corp-title-wordmark-frame {
            position: relative;
            display: block;
            flex: 0 0 152px;
            width: 152px;
            height: 15px;
            overflow: hidden;
        }
        .corp-title-wordmark {
            position: absolute;
            top: -15.5px;
            left: -19px;
            display: block;
            width: 170px;
            height: auto;
            max-width: none;
        }
        .corp-title-company-name {
            font-family: 'Eurostile', 'Eurostile Extended', 'Eurostile LT', 'Eurostile LT Std', Arial, sans-serif;
            font-size: 13pt;
            font-weight: 700;
            letter-spacing: 0.8px;
            white-space: nowrap;
        }
        .corp-subtitle {
            font-size: 7.5pt;
            letter-spacing: 1px;
            font-weight: 600;
            color: #94a3b8 !important;
            text-transform: uppercase;
        }
        .corp-doc-type {
            font-size: 8.5pt;
            font-weight: 700;
            color: #f87171 !important;
            margin-top: 2px;
            letter-spacing: 0.5px;
        }
        .corp-header-right {
            text-align: right;
            display: flex;
            flex-direction: column;
            align-items: flex-end;
            gap: 2px;
        }
        .corp-confidential-pill {
            background: #dc2626 !important;
            color: #ffffff !important;
            font-size: 7.5pt;
            font-weight: 800;
            padding: 2px 7px;
            border-radius: 3px;
            letter-spacing: 0.5px;
            margin-bottom: 2px;
        }
        .corp-meta-line {
            font-size: 8pt;
            color: #cbd5e1 !important;
        }
        .corp-meta-line strong { color: #94a3b8 !important; }
        .corp-section {
            margin-bottom: 11px;
            border: 1px solid #cbd5e1;
            border-radius: 5px;
            overflow: hidden;
            page-break-inside: avoid;
            break-inside: avoid;
        }
        .corp-section-header {
            background: #f1f5f9 !important;
            color: #1e293b !important;
            font-size: 8.5pt;
            font-weight: 800;
            letter-spacing: 0.4px;
            padding: 5px 10px;
            border-bottom: 1px solid #cbd5e1;
            display: flex;
            align-items: center;
            gap: 6px;
            text-transform: uppercase;
        }
        .corp-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 8.5pt;
        }
        .corp-table th, .corp-table td {
            padding: 5px 9px;
            border: 1px solid #e2e8f0;
            vertical-align: top;
            text-align: left;
        }
        .corp-table th {
            background: #f8fafc !important;
            color: #475569 !important;
            font-weight: 700;
            font-size: 8pt;
            text-transform: uppercase;
        }
        .corp-item-code {
            display: inline-block;
            background: #0f172a;
            color: #ffffff !important;
            padding: 1px 6px;
            border-radius: 3px;
            font-weight: 700;
        }
        .corp-finding-cell {
            background: #fff5f5 !important;
            color: #991b1b !important;
            font-weight: 600;
            line-height: 1.5;
            white-space: pre-wrap;
        }
        .corp-action-cell {
            background: #f0fdf4 !important;
            color: #166534 !important;
            font-weight: 600;
            line-height: 1.5;
            white-space: pre-wrap;
        }
        .corp-photos-wrap {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            padding: 4px 0;
        }
        .corp-photo-item {
            display: block;
            width: 140px;
            height: 105px;
            border: 1px solid #cbd5e1;
            border-radius: 4px;
            overflow: hidden;
        }
        .corp-photo-item img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        .corp-sign-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 10px;
            padding: 10px;
            background: #ffffff;
        }
        .corp-sign-box {
            border: 1px solid #cbd5e1;
            border-radius: 4px;
            padding: 8px 10px;
            display: flex;
            flex-direction: column;
            text-align: center;
        }
        .corp-sign-role {
            font-size: 7.5pt;
            font-weight: 800;
            letter-spacing: 0.4px;
            color: #475569;
            margin-bottom: 24px;
            text-transform: uppercase;
        }
        .corp-sign-line {
            border-bottom: 1px solid #0f172a;
            margin-bottom: 4px;
        }
        .corp-sign-name {
            font-size: 8.5pt;
            font-weight: 700;
            color: #0f172a;
        }
        .corp-sign-sub { font-size: 7.5pt; color: #64748b; margin-bottom: 6px; }
        .corp-sign-date { font-size: 7.5pt; color: #64748b; }
        .corp-footer-notice {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 7pt;
            color: #94a3b8;
            margin-top: 8px;
            padding-top: 4px;
            border-top: 1px solid #e2e8f0;
        }
    </style>
</head>
<body>
    <div class="corp-header-banner">
        <div class="corp-header-left">
            <div class="corp-header-logo-box">
                <img src="${circleLogoUrl}" alt="Gateway logo" class="corp-header-logo">
            </div>
            <div>
                <h2 class="corp-title"><span class="corp-title-wordmark-frame"><img src="${gatewayWordmarkUrl}" alt="GATEWAY" class="corp-title-wordmark"></span><span class="corp-title-company-name">MOTORS GROUP</span></h2>
                <div class="corp-subtitle">QUALITY ASSURANCE &amp; AUDIT COMPLIANCE SYSTEM</div>
                <div class="corp-doc-type">OFFICIAL CHECKLIST FINDING &amp; ESCALATION RECORD</div>
            </div>
        </div>
        <div class="corp-header-right">
            <span class="corp-confidential-pill">CONFIDENTIAL</span>
            <div class="corp-meta-line"><strong>REF:</strong> GAC-ESC-${responseId}</div>
            <div class="corp-meta-line"><strong>DATE:</strong> ${auditDate}</div>
            <div class="corp-meta-line"><strong>STATUS:</strong> ${resultLabel}</div>
        </div>
    </div>

    <div class="corp-section">
        <div class="corp-section-header"><i class="fas fa-building"></i> 1. AUDIT &amp; FACILITY INFORMATION</div>
        <table class="corp-table">
            <tr>
                <th style="width: 18%;">Branch</th>
                <td style="width: 32%;">${branch}</td>
                <th style="width: 18%;">Audit Date</th>
                <td style="width: 32%;">${auditDate}</td>
            </tr>
            <tr>
                <th>Checklist</th>
                <td>${templateName}</td>
                <th>Submission ID</th>
                <td>${submissionId}</td>
            </tr>
            <tr>
                <th>Lead Auditor</th>
                <td><strong>${auditor}</strong> ${auditorRole ? '(' + auditorRole + ')' : ''}</td>
                <th>Checker / PIC</th>
                <td>${data.checker_role || 'Not specified'} ${data.person_accountable ? ' · ' + data.person_accountable : ''}</td>
            </tr>
        </table>
    </div>

    <div class="corp-section">
        <div class="corp-section-header"><i class="fas fa-triangle-exclamation"></i> 2. NON-COMPLIANCE &amp; DEFICIENCY DETAILS</div>
        <table class="corp-table">
            <tr>
                <th style="width: 18%;">Area / Coverage</th>
                <td style="width: 32%;">${data.area || 'General'}</td>
                <th style="width: 18%;">Item Code</th>
                <td style="width: 32%;"><code class="corp-item-code">${itemKey}</code></td>
            </tr>
            <tr>
                <th>Requirement Prompt</th>
                <td colspan="3"><strong>${itemPrompt}</strong></td>
            </tr>
            <tr>
                <th>Recorded Deficiency</th>
                <td colspan="3" class="corp-finding-cell">${findingText}</td>
            </tr>
            ${bomTask ? `<tr><th>Assigned BOM Task</th><td colspan="3">${bomTask}</td></tr>` : ''}
            ${photos.length > 0 ? `<tr><th>Photo Evidence</th><td colspan="3"><div class="corp-photos-wrap">${photos.map(p => `<div class="corp-photo-item"><img src="${p}" alt="Photo"></div>`).join('')}</div></td></tr>` : ''}
        </table>
    </div>

    <div class="corp-section">
        <div class="corp-section-header"><i class="fas fa-arrow-up-right-dots"></i> 3. ESCALATION &amp; CORRECTIVE ACTION PLAN</div>
        <table class="corp-table">
            <tr>
                <th style="width: 18%;">Escalation Target</th>
                <td style="width: 32%;"><strong>${escalationTarget}</strong></td>
                <th style="width: 18%;">Commitment Date</th>
                <td style="width: 32%;"><strong>${commitmentDate}</strong> ${dueStatus ? `(${dueStatus})` : ''}</td>
            </tr>
            <tr>
                <th>Corrective Action Plan</th>
                <td colspan="3" class="corp-action-cell">${actionPlan}</td>
            </tr>
        </table>
    </div>

    ${data.remarks || data.is_overridden ? `
    <div class="corp-section">
        <div class="corp-section-header"><i class="fas fa-clock-rotate-left"></i> 4. FOLLOW-UP ACTIVITY &amp; VERIFICATION LOG</div>
        <table class="corp-table">
            ${data.remarks ? `<tr><th style="width: 18%;">Follow-up Remarks</th><td colspan="3">${data.remarks}</td></tr>` : ''}
            ${data.is_overridden ? `<tr><th style="width: 18%;">Override Record</th><td colspan="3"><strong>Authorized by:</strong> ${data.override_details?.overridden_by_name || 'Manager'} (${data.override_details?.overridden_by_role || 'BOM'})${data.override_details?.overridden_at_formatted ? ` on <strong>${data.override_details.overridden_at_formatted}</strong>` : ''}<br><strong>Justification:</strong> ${data.override_details?.reason || 'Manager Override'}${data.override_details?.attachment_url ? `<br><strong>Proof Attachment:</strong> <a href="${data.override_details.attachment_url}" target="_blank">View attached proof document (${data.override_details.attachment_name || 'Proof file'})</a>` : ''}</td></tr>` : ''}
        </table>
    </div>` : ''}

    <div class="corp-section">
        <div class="corp-section-header"><i class="fas fa-signature"></i> 5. AUDIT REVIEW &amp; AUTHORIZATION SIGN-OFF</div>
        <div class="corp-sign-grid">
            <div class="corp-sign-box">
                <span class="corp-sign-role">INSPECTED &amp; PREPARED BY</span>
                <div class="corp-sign-line"></div>
                <strong class="corp-sign-name">${auditor}</strong>
                <small class="corp-sign-sub">Checklist Lead Inspector</small>
                <div class="corp-sign-date">Date: ____________________</div>
            </div>
            <div class="corp-sign-box">
                <span class="corp-sign-role">ACTION PLANNED &amp; ESCALATED BY</span>
                <div class="corp-sign-line"></div>
                <strong class="corp-sign-name">${(data.performed_by && data.performed_by !== auditor) ? data.performed_by : 'Branch Operations Manager'}</strong>
                <small class="corp-sign-sub">Operations Management</small>
                <div class="corp-sign-date">Date: ____________________</div>
            </div>
            <div class="corp-sign-box">
                <span class="corp-sign-role">REVIEWED &amp; APPROVED BY</span>
                <div class="corp-sign-line"></div>
                <strong class="corp-sign-name">General Manager</strong>
                <small class="corp-sign-sub">Executive Compliance Oversight</small>
                <div class="corp-sign-date">Date: ____________________</div>
            </div>
        </div>
    </div>

    <div class="corp-footer-notice">
        <span>GATEWAY AUDIT COMPLIANCE SYSTEM &bull; CONFIDENTIAL QUALITY AUDIT DOCUMENT &bull; ALL RIGHTS RESERVED</span>
        <span>Generated on ${new Date().toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}</span>
    </div>
</body>
</html>`);
        iframeDoc.close();

        setTimeout(async () => {
            const imageLoads = Array.from(iframeDoc.images).map((image) => {
                if (image.complete) return Promise.resolve();
                return new Promise((resolve) => {
                    image.addEventListener('load', resolve, { once: true });
                    image.addEventListener('error', resolve, { once: true });
                });
            });

            await Promise.all(imageLoads);
            if (iframeDoc.fonts?.ready) await iframeDoc.fonts.ready;

            iframe.contentWindow.focus();
            iframe.contentWindow.print();
            setTimeout(() => {
                if (iframe && iframe.parentNode) iframe.parentNode.removeChild(iframe);
            }, 2000);
        }, 100);
    }

    // Connect both Print buttons to the isolated print engine
    printDetailBtn?.addEventListener('click', () => {
        printIsolatedFindingDocument(activeFindingRecord);
    });
    printDetailBtnBottom?.addEventListener('click', () => {
        printIsolatedFindingDocument(activeFindingRecord);
    });
})();
</script>
