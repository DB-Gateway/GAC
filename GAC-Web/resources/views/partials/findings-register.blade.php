@php
    $isFollowUpWorkspace = $isFollowUpWorkspace ?? false;
    $showOverrideActions = $showOverrideActions ?? $canOverrideAny;
    $followUpNotificationEvent = (string) request()->query('follow_up_event', '');
@endphp

@if ($followUpResponseId)
    <div class="summary-follow-up-guidance">
        <i class="fas fa-location-dot" aria-hidden="true"></i>
        <span>
            {{ $followUpNotificationEvent === 'escalation_follow_up_submitted'
                ? 'A follow-up update was submitted for the highlighted finding. Review its latest details below.'
                : ($canManageEscalations
                    ? 'The GM requested follow-up on the highlighted finding. Complete its escalation details below.'
                    : 'The highlighted finding was opened from a follow-up update. Review its latest details below.') }}
        </span>
    </div>
@endif

<section class="findings-register-card" id="findingsRegisterCard" aria-label="{{ $registerAriaLabel ?? 'Checklist NO answers and escalations register' }}">
    <div class="card-heading register-header">
        <div>
            <div class="heading-badge-wrap">
                @if ($isFollowUpWorkspace)
                    <span class="authority-badge {{ $canViewFindings ? 'gm-review' : 'bom-escalation' }}">
                        <i class="fas {{ $canViewFindings ? 'fa-eye' : 'fa-arrow-up-right-dots' }}" aria-hidden="true"></i>
                        {{ $canViewFindings ? 'Finding Review' : 'Escalation Access' }}
                    </span>
                @elseif ($showOverrideActions)
                    <span class="authority-badge" title="You are authorized to override and edit checklist responses">
                        <i class="fas fa-shield-check" aria-hidden="true"></i> Override Active
                    </span>
                @else
                    <span class="authority-badge locked" title="Only authorized users may override NO responses">
                        <i class="fas fa-lock" aria-hidden="true"></i> View Only
                    </span>
                @endif
            </div>
            <h3>{{ $registerTitle ?? 'Checklist NO Answers & Escalations' }}</h3>
            <p>{{ $registerDescription ?? 'Comprehensive register of non-compliant checklist responses. Review tasks, action plans, photo evidence, and department escalations.' }}</p>
        </div>

        <div class="register-actions">
            <div class="register-filter-pills" role="tablist" aria-label="Filter NO answers">
                <button type="button" class="pill-btn active" data-filter-tab="all">{{ ($isOverrideWorkspace ?? false) ? 'NO Answers' : 'All' }} ({{ $reportFindings->count() }})</button>
                @if (! ($isOverrideWorkspace ?? false))
                <button type="button" class="pill-btn" data-filter-tab="no">NO Only ({{ $reportSummary['no_count'] ?? $reportFindings->filter(fn($f) => in_array($f['status'], ['no', 'x'], true))->count() }})</button>
                @endif
                <button type="button" class="pill-btn" data-filter-tab="overdue">Overdue ({{ $reportSummary['overdue_count'] ?? $reportFindings->where('is_overdue', true)->count() }})</button>
                <button type="button" class="pill-btn" data-filter-tab="escalated">Escalated ({{ $reportSummary['escalation_count'] ?? $reportFindings->filter(fn($f) => filled($f['escalation_target']))->count() }})</button>
                <button type="button" class="pill-btn" data-filter-tab="overridden">Overridden ({{ $reportSummary['overridden_count'] ?? $reportFindings->where('is_overridden', true)->count() }})</button>
            </div>
        </div>
    </div>

    <div class="table-wrap register-table-wrap">
        <table class="findings-table" id="dashboardFindingsTable">
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
                @forelse ($reportFindings as $finding)
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
                                @if (!empty($finding['is_compiled']) && !empty($finding['compiled_questions']))
                                    <details class="compiled-checklist-items-toggle" style="margin-top: 8px; font-size: 11px; background: rgba(15, 38, 66, 0.45); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 8px; padding: 6px 10px;">
                                        <summary style="cursor: pointer; font-weight: 700; color: #38bdf8;">
                                            <i class="fas fa-list-check" aria-hidden="true"></i> View all {{ $finding['compiled_count'] }} checklist questions
                                        </summary>
                                        <ol style="margin: 8px 0 4px 18px; padding: 0; line-height: 1.5; color: #cbd5e1; max-height: 160px; overflow-y: auto;">
                                            @foreach ($finding['compiled_questions'] as $cq)
                                                <li>
                                                    <strong>{{ $cq['area'] ?? '' }}:</strong> {{ $cq['question'] }}
                                                    <span style="display: inline-block; padding: 1px 5px; font-size: 9px; font-weight: 800; border-radius: 4px; background: rgba(217, 45, 32, 0.2); color: #f87171; margin-left: 4px;">{{ $cq['result'] ?? 'X' }}</span>
                                                </li>
                                            @endforeach
                                        </ol>
                                    </details>
                                @endif
                            </div>
                        </td>

                        <!-- Deficiency & Action Plan -->
                        <td class="deficiency-cell">
                            <div class="finding-remark">
                                <span class="detail-label">Finding:</span>
                                <p class="finding-detail-text">{{ $finding['detail'] }}</p>
                            </div>
                            @if (!empty($finding['bom_task']))
                                <div class="finding-bom-task">
                                    <span class="detail-label"><i class="fas fa-list-check" aria-hidden="true"></i> Task:</span>
                                    <p>{{ $finding['bom_task'] }}</p>
                                </div>
                            @endif
                            <div class="finding-action-plan" style="{{ empty($finding['action_plan']) ? 'display:none;' : '' }}">
                                <span class="detail-label"><i class="fas fa-wrench" aria-hidden="true"></i> Action Plan:</span>
                                <p class="action-plan-text">{{ $finding['action_plan'] }}</p>
                            </div>
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
                                <button type="button" class="button button-sm button-view-finding"
                                        data-view-finding
                                        data-finding="{{ json_encode($finding, JSON_HEX_APOS | JSON_HEX_QUOT) }}"
                                        title="View and print official corporate finding document">
                                    <i class="fas fa-eye" aria-hidden="true"></i> View
                                </button>

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

                                @if ($showOverrideActions && $finding['can_override'])
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
                                <strong>Zero Flagged NO Answers for Selected Filters</strong>
                                <p>All checklist responses recorded matching these filters are currently compliant, or no audits have been filed yet.</p>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</section>
