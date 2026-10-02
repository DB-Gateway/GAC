@php($showOverrideActions = $showOverrideActions ?? $canOverrideAny)

<!-- BOM & GM EXCLUSIVE OVERRIDE MODAL -->
@if ($showOverrideActions)
<div class="report-modal-backdrop" id="overrideModal" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
    <div class="modal-card modal-card-lg">
        <div class="modal-heading">
            <div class="modal-title-wrap">
                <span class="modal-eyebrow"><i class="fas fa-shield-halved" aria-hidden="true"></i> Authorized Manager Action</span>
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

            <!-- Current Action Timestamp Notice -->
            <div class="modal-callout override-audit-notice">
                <i class="fas fa-clock-rotate-left" aria-hidden="true"></i>
                <div class="audit-notice-content">
                    <strong>Official Manager Override Log:</strong>
                    <span>Applying this override will record your manager credentials and stamp the exact action date &amp; time (<span id="modalCurrentTimestampIndicator">—</span>).</span>
                </div>
            </div>

            <!-- Previous Override Information (if already overridden) -->
            <div class="modal-callout override-history-callout" id="modalPreviousOverrideWrap" style="display:none;">
                <i class="fas fa-shield-check text-success" aria-hidden="true"></i>
                <div class="history-callout-content">
                    <strong>Previously Overridden finding:</strong>
                    <div class="history-callout-meta" id="modalPreviousOverrideMeta">—</div>
                    <div class="history-callout-reason" id="modalPreviousOverrideReason"></div>
                    <div class="history-callout-proof" id="modalPreviousOverrideProof" style="display:none;">
                        <a href="#" target="_blank" rel="noopener noreferrer" class="override-proof-chip" id="modalPreviousOverrideProofLink">
                            <i class="fas fa-paperclip" aria-hidden="true"></i>
                            <span id="modalPreviousOverrideProofName">View Current Attached Proof</span>
                        </a>
                    </div>
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
                                <span class="radio-title text-danger"><i class="fas fa-times-circle" aria-hidden="true"></i> Keep as NO</span>
                                <small>Maintain non-compliant finding</small>
                            </div>
                        </label>
                        <label class="status-radio-card">
                            <input type="radio" name="override_status" value="yes" id="radioStatusYes">
                            <div class="radio-card-content">
                                <span class="radio-title text-success"><i class="fas fa-check-circle" aria-hidden="true"></i> Override to YES</span>
                                <small>Mark resolved / compliant</small>
                            </div>
                        </label>
                        <label class="status-radio-card">
                            <input type="radio" name="override_status" value="na" id="radioStatusNa">
                            <div class="radio-card-content">
                                <span class="radio-title text-muted"><i class="fas fa-ban" aria-hidden="true"></i> Override to N/A</span>
                                <small>Mark not applicable / exempt</small>
                            </div>
                        </label>
                    </div>
                </div>

                <!-- BOM Escalation Target -->
                <div class="form-group span-half">
                    <label for="modalEscalation" class="form-label">
                        <i class="fas fa-share-nodes" aria-hidden="true"></i> BOM Suggested Escalation To
                    </label>
                    <select id="modalEscalation" name="escalation_target" class="form-select">
                        <option value="">No Escalation Required</option>
                        @foreach ($escalationOptions as $escKey => $escLabel)
                            <option value="{{ $escKey }}">{{ $escLabel }}</option>
                        @endforeach
                    </select>
                    <span class="field-hint">Identify who the BOM recommends this deficiency be escalated to.</span>
                </div>

                <!-- Commitment Date and Time -->
                <div class="form-group span-half">
                    <label for="modalCommitmentDate" class="form-label">
                        <i class="fas fa-calendar-check" aria-hidden="true"></i> Commitment Date &amp; Time
                    </label>
                    <input type="datetime-local" id="modalCommitmentDate" name="commitment_date" class="form-input" step="60">
                    <span class="field-hint">Target resolution date and exact commitment time.</span>
                </div>

                <!-- Action Plan -->
                <div class="form-group span-full">
                    <label for="modalActionPlan" class="form-label">
                        <i class="fas fa-wrench" aria-hidden="true"></i> Action Plan
                    </label>
                    <textarea id="modalActionPlan" name="action_plan" class="form-textarea" rows="2" placeholder="Corrective action plan to remedy this deficiency"></textarea>
                </div>

                <!-- Finding / Remarks -->
                <div class="form-group span-full">
                    <label for="modalFinding" class="form-label">
                        <i class="fas fa-file-lines" aria-hidden="true"></i> Finding / Remarks
                    </label>
                    <textarea id="modalFinding" name="finding" class="form-textarea" rows="2" placeholder="Deficiency details or resolution remarks"></textarea>
                </div>

                <!-- Override Reason / Notes -->
                <div class="form-group span-full">
                    <label for="modalOverrideReason" class="form-label">
                        <i class="fas fa-comment-dots" aria-hidden="true"></i> Manager Override Justification / Reason <span class="required-asterisk">*</span>
                    </label>
                    <textarea id="modalOverrideReason" name="override_reason" class="form-textarea" rows="2" maxlength="1000" required placeholder="Specify why this response is being overridden or edited (e.g., Verified rectified on-site, Approved warranty replacement, Exemption granted)"></textarea>
                </div>

                <!-- Attachment of Proof -->
                <div class="form-group span-full">
                    <label for="modalOverrideProof" class="form-label">
                        <i class="fas fa-paperclip" aria-hidden="true"></i> Attachment of Proof / Supporting Document
                    </label>
                    <div class="attachment-upload-zone" id="overrideProofDropzone">
                        <input type="file" id="modalOverrideProof" name="proof" class="attachment-file-input" accept="image/jpeg,image/png,image/jpg,image/webp,image/heic,application/pdf">
                        <div class="attachment-prompt" id="overrideProofPrompt">
                            <i class="fas fa-cloud-arrow-up" aria-hidden="true"></i>
                            <div class="prompt-text">
                                <strong>Choose a proof file or drag and drop here</strong>
                                <small>Photo evidence, repair verification, job order, receipt, or PDF exemption (Max 15MB)</small>
                            </div>
                            <span class="button button-sm button-browse" type="button">Browse File</span>
                        </div>
                        <div class="attachment-preview-card" id="overrideProofPreview" style="display:none;">
                            <div class="preview-thumb-wrap" id="overridePreviewThumbWrap">
                                <img id="overridePreviewImg" src="" alt="Proof preview" style="display:none;">
                                <i id="overridePreviewPdfIcon" class="fas fa-file-pdf text-danger" style="display:none;" aria-hidden="true"></i>
                            </div>
                            <div class="preview-file-details">
                                <strong class="preview-name" id="overridePreviewName">—</strong>
                                <small class="preview-size" id="overridePreviewSize">—</small>
                            </div>
                            <button type="button" class="button-remove-file" id="removeOverrideProofBtn" title="Remove selected proof file">
                                <i class="fas fa-times" aria-hidden="true"></i>
                            </button>
                        </div>
                    </div>
                    <span class="field-hint">Upload evidence verifying rectification or justification for this override.</span>
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
@endif

<!-- BOM EXCLUSIVE ESCALATION / ACTION PLAN MODAL -->
@if ($canManageEscalations)
<div class="report-modal-backdrop" id="escalateModal" role="dialog" aria-modal="true" aria-labelledby="escalateModalTitle">
    <div class="modal-card modal-card-lg">
        <div class="modal-heading">
            <div class="modal-title-wrap">
                <span class="modal-eyebrow"><i class="fas fa-arrow-up-right-dots" aria-hidden="true"></i> BOM Action</span>
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

            <div class="modal-callout">
                <i class="fas fa-shield-halved" aria-hidden="true"></i>
                <span>Set the recipient, Action Plan, and Commitment Date Planned. Saving these details does not change the original <strong>NO</strong> result.</span>
            </div>

            <div class="modal-fields-grid">
                <!-- Finding Detail (Read-only reference) -->
                <div class="form-group span-full">
                    <label class="form-label"><i class="fas fa-triangle-exclamation" aria-hidden="true"></i> Recorded Finding</label>
                    <div class="finding-static-box" id="escalateFindingDetail"></div>
                </div>

                <div class="form-group span-full" id="escalateBomTaskGroup" style="display:none;">
                    <label class="form-label"><i class="fas fa-list-check" aria-hidden="true"></i> BOM Task</label>
                    <div class="finding-static-box bom-task-box" id="escalateBomTask"></div>
                </div>

                <!-- Escalation Recipient -->
                <div class="form-group span-half">
                    <label for="escalateSelectTarget" class="form-label">
                        <i class="fas fa-share-nodes" aria-hidden="true"></i> Escalate To
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
                        <i class="fas fa-calendar-day" aria-hidden="true"></i> Commitment Date Planned
                    </label>
                    <input type="date" id="escalateCommitmentDate" name="commitment_date" class="form-input" required>
                    <span class="field-hint">Target planned resolution date.</span>
                </div>

                <!-- Action Plan -->
                <div class="form-group span-full">
                    <label for="escalateActionPlan" class="form-label">
                        <i class="fas fa-wrench" aria-hidden="true"></i> Action Plan
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

<script>
    (() => {
        // Findings Table Filter Pills
        const filterPills = document.querySelectorAll('.register-filter-pills [data-filter-tab]');
        const findingRows = document.querySelectorAll('#dashboardFindingsTable .finding-row');

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
        document.querySelectorAll('[data-request-finding-follow-up]').forEach(button => {
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
                            'Accept': 'application/json',
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': csrfToken,
                        },
                        credentials: 'same-origin',
                        body: JSON.stringify({}),
                    });
                    const data = await response.json().catch(() => ({}));

                    if (!response.ok) {
                        throw new Error(data.message || 'The BOM follow-up notification could not be sent.');
                    }

                    button.classList.remove('is-loading');
                    button.classList.add('is-sent');
                    if (label) label.textContent = 'Follow-up Sent';
                    if (status) {
                        status.classList.add('is-success');
                        status.textContent = data.message || 'Follow-up sent to the BOM user.';
                    }
                } catch (error) {
                    button.disabled = false;
                    button.classList.remove('is-loading');
                    if (label) label.textContent = 'Follow-up';
                    if (status) {
                        status.classList.add('is-error');
                        status.textContent = error.message || 'The BOM follow-up notification could not be sent.';
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

            escalateModal?.classList.add('is-open');
        }

        function closeEscalateModalDialog() {
            escalateModal?.classList.remove('is-open');
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
        escalateModal?.addEventListener('click', (e) => {
            if (e.target === escalateModal) closeEscalateModalDialog();
        });

        escalateForm?.addEventListener('submit', async (e) => {
            e.preventDefault();
            const responseId = Number(document.getElementById('escalateResponseId').value);
            const escalationTarget = document.getElementById('escalateSelectTarget').value || null;
            const commitmentDate = document.getElementById('escalateCommitmentDate').value || null;
            const actionPlan = document.getElementById('escalateActionPlan').value.trim() || null;

            saveEscalateBtn.disabled = true;
            saveEscalateBtn.innerHTML = '<i class="fas fa-spinner fa-spin" aria-hidden="true"></i> Saving...';
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

        // Override Modal
        @if ($showOverrideActions)
        const overrideModal = document.getElementById('overrideModal');
        const closeOverrideBtn = document.getElementById('closeOverrideModal');
        const cancelOverrideBtn = document.getElementById('cancelOverrideBtn');
        const overrideForm = document.getElementById('overrideForm');
        const modalOverrideProof = document.getElementById('modalOverrideProof');
        const overrideProofPrompt = document.getElementById('overrideProofPrompt');
        const overrideProofPreview = document.getElementById('overrideProofPreview');
        const overridePreviewImg = document.getElementById('overridePreviewImg');
        const overridePreviewPdfIcon = document.getElementById('overridePreviewPdfIcon');
        const overridePreviewName = document.getElementById('overridePreviewName');
        const overridePreviewSize = document.getElementById('overridePreviewSize');
        const removeOverrideProofBtn = document.getElementById('removeOverrideProofBtn');
        const overrideProofDropzone = document.getElementById('overrideProofDropzone');

        function formatCurrentDateTime() {
            const now = new Date();
            return now.toLocaleString('en-US', {
                day: '2-digit',
                month: 'short',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: true
            });
        }

        function resetOverrideProofInput() {
            if (modalOverrideProof) modalOverrideProof.value = '';
            if (overridePreviewImg) {
                overridePreviewImg.src = '';
                overridePreviewImg.style.display = 'none';
            }
            if (overridePreviewPdfIcon) overridePreviewPdfIcon.style.display = 'none';
            if (overrideProofPreview) overrideProofPreview.style.display = 'none';
            if (overrideProofPrompt) overrideProofPrompt.style.display = '';
        }

        function handleProofFileSelect(file) {
            if (!file) {
                resetOverrideProofInput();
                return;
            }

            overridePreviewName.textContent = file.name;
            const sizeKb = file.size / 1024;
            overridePreviewSize.textContent = sizeKb > 1024
                ? (sizeKb / 1024).toFixed(2) + ' MB'
                : Math.round(sizeKb) + ' KB';

            if (file.type.startsWith('image/')) {
                overridePreviewImg.src = URL.createObjectURL(file);
                overridePreviewImg.style.display = 'block';
                overridePreviewPdfIcon.style.display = 'none';
            } else if (file.type === 'application/pdf') {
                overridePreviewImg.style.display = 'none';
                overridePreviewPdfIcon.style.display = 'block';
            } else {
                overridePreviewImg.style.display = 'none';
                overridePreviewPdfIcon.style.display = 'none';
            }

            overrideProofPrompt.style.display = 'none';
            overrideProofPreview.style.display = 'flex';
        }

        if (modalOverrideProof) {
            modalOverrideProof.addEventListener('change', () => {
                const file = modalOverrideProof.files?.[0];
                handleProofFileSelect(file);
            });
        }

        if (removeOverrideProofBtn) {
            removeOverrideProofBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                resetOverrideProofInput();
            });
        }

        if (overrideProofDropzone) {
            ['dragenter', 'dragover'].forEach(eventName => {
                overrideProofDropzone.addEventListener(eventName, (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    overrideProofDropzone.classList.add('is-dragover');
                });
            });
            ['dragleave', 'drop'].forEach(eventName => {
                overrideProofDropzone.addEventListener(eventName, (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    overrideProofDropzone.classList.remove('is-dragover');
                });
            });
            overrideProofDropzone.addEventListener('drop', (e) => {
                const dt = e.dataTransfer;
                const file = dt?.files?.[0];
                if (file && modalOverrideProof) {
                    modalOverrideProof.files = dt.files;
                    handleProofFileSelect(file);
                }
            });
        }

        function openOverrideModal(data) {
            overrideForm.dataset.endpoint = data.endpoint;
            document.getElementById('overrideResponseId').value = data.responseId || '';
            document.getElementById('modalTemplateName').textContent = data.template || 'Checklist';
            document.getElementById('modalBranchName').textContent = data.branch || 'Branch';
            document.getElementById('modalItemKey').textContent = data.itemKey || 'ITEM';
            document.getElementById('modalItemPrompt').textContent = data.itemPrompt || '';

            // Update live action timestamp indicator
            const currentTsElem = document.getElementById('modalCurrentTimestampIndicator');
            if (currentTsElem) currentTsElem.textContent = formatCurrentDateTime();

            // Populate previous override history if already overridden
            const prevWrap = document.getElementById('modalPreviousOverrideWrap');
            const prevMeta = document.getElementById('modalPreviousOverrideMeta');
            const prevReason = document.getElementById('modalPreviousOverrideReason');
            const prevProofWrap = document.getElementById('modalPreviousOverrideProof');
            const prevProofLink = document.getElementById('modalPreviousOverrideProofLink');
            const prevProofName = document.getElementById('modalPreviousOverrideProofName');

            const isOverridden = data.isOverridden || !!data.overriddenAt;
            if (isOverridden && prevWrap) {
                prevWrap.style.display = '';
                const timeStr = data.overriddenAtFormatted || data.overriddenAt || 'Recorded';
                const byStr = data.overriddenByName || 'Authorized Manager';
                const roleStr = data.overriddenRole || 'BOM';
                if (prevMeta) prevMeta.textContent = `Overridden on ${timeStr} by ${byStr} (${roleStr})`;
                if (prevReason) prevReason.textContent = data.overrideReason ? `“${data.overrideReason}”` : 'No justification specified.';

                if (data.overrideAttachmentUrl && prevProofWrap && prevProofLink) {
                    prevProofWrap.style.display = '';
                    prevProofLink.href = data.overrideAttachmentUrl;
                    if (prevProofName) {
                        prevProofName.textContent = data.overrideAttachmentName
                            ? `View Current Attached Proof (${data.overrideAttachmentName})`
                            : 'View Current Attached Proof';
                    }
                } else if (prevProofWrap) {
                    prevProofWrap.style.display = 'none';
                }
            } else if (prevWrap) {
                prevWrap.style.display = 'none';
            }

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
            document.getElementById('modalOverrideReason').value = data.overrideReason || '';

            // Reset file upload
            resetOverrideProofInput();

            overrideModal?.classList.add('is-open');
        }

        function closeOverrideModalDialog() {
            overrideModal?.classList.remove('is-open');
            resetOverrideProofInput();
        }

        document.querySelectorAll('[data-action="open-override"]').forEach(btn => {
            btn.addEventListener('click', () => {
                openOverrideModal({
                    endpoint: btn.dataset.endpoint,
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
                    isOverridden: btn.dataset.isOverridden === '1' || btn.dataset.isOverridden === 'true',
                    overriddenAt: btn.dataset.overriddenAt || '',
                    overriddenAtFormatted: btn.dataset.overriddenAtFormatted || '',
                    overriddenByName: btn.dataset.overriddenBy || '',
                    overriddenRole: btn.dataset.overriddenRole || '',
                    overrideReason: btn.dataset.overrideReason || '',
                    overrideAttachmentUrl: btn.dataset.overrideAttachmentUrl || '',
                    overrideAttachmentName: btn.dataset.overrideAttachmentName || '',
                });
            });
        });

        closeOverrideBtn?.addEventListener('click', closeOverrideModalDialog);
        cancelOverrideBtn?.addEventListener('click', closeOverrideModalDialog);
        overrideModal?.addEventListener('click', (e) => {
            if (e.target === overrideModal) closeOverrideModalDialog();
        });

        overrideForm?.addEventListener('submit', async (e) => {
            e.preventDefault();
            const saveBtn = document.getElementById('saveOverrideBtn');
            if (saveBtn.disabled) return;
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
            saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin" aria-hidden="true"></i> Saving Override...';

            try {
                const formData = new FormData();
                formData.append('_method', 'PATCH');
                formData.append('status', status);
                if (escalationTarget) formData.append('escalation_target', escalationTarget);
                if (commitmentDate) formData.append('commitment_date', commitmentDate);
                if (actionPlan) formData.append('action_plan', actionPlan);
                if (finding) formData.append('finding', finding);
                formData.append('override_reason', overrideReason);

                const file = modalOverrideProof?.files?.[0];
                if (file) {
                    formData.append('proof', file);
                }

                const res = await fetch(overrideForm.dataset.endpoint, {
                    method: 'POST',
                    headers: {
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': csrfToken,
                    },
                    body: formData,
                });

                const data = await res.json().catch(() => ({}));
                if (!res.ok) {
                    const validationMsg = data.errors ? Object.values(data.errors).flat().join('\n') : '';
                    throw new Error(validationMsg || data.message || 'Failed to save override.');
                }

                closeOverrideModalDialog();
                window.location.reload();
            } catch (err) {
                alert(err.message || 'An error occurred while saving the override.');
            } finally {
                saveBtn.disabled = false;
                saveBtn.innerHTML = '<i class="fas fa-save" aria-hidden="true"></i> Save &amp; Apply Override';
            }
        });
        @endif

        // ESC key to close open modals
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                @if ($showOverrideActions)
                if (overrideModal?.classList.contains('is-open')) {
                    closeOverrideModalDialog();
                }
                @endif
                @if ($canManageEscalations)
                if (escalateModal?.classList.contains('is-open')) {
                    closeEscalateModalDialog();
                }
                @endif
            }
        });

        // Auto-scroll and focus to highlighted finding if follow_up_response_id is passed
        const highlightedFollowUp = document.querySelector('[data-follow-up-highlight]');
        if (highlightedFollowUp) {
            window.requestAnimationFrame(() => {
                highlightedFollowUp.scrollIntoView({ behavior: 'smooth', block: 'center' });
                @if ($canManageEscalations)
                const escalationButton = highlightedFollowUp.querySelector('[data-action="open-escalate"]');
                if (escalationButton) {
                    escalationButton.click();
                } else {
                    highlightedFollowUp.focus({ preventScroll: true });
                }
                @else
                highlightedFollowUp.focus({ preventScroll: true });
                @endif
            });
        }
    })();
</script>
