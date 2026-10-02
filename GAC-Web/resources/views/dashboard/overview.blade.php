@php
    $cards = $summarySheet['cards'];
    $isBelowTarget = $cards['is_below_target'];
    $overallScores = $summarySheet['overallScores'];
    $overallSummary = $summarySheet['overallSummaryRow'];
    $coverageRows = $summarySheet['coverageRows'];
    $coverageSummary = $summarySheet['coverageSummaryRow'];
    $activeForm = $summarySheet['activeForm'];
    $subformDocData = $summarySheet['subformDocData'] ?? [];
    $canManageFindings = $summarySheet['canManageFindings'];
    $canViewFindings = $summarySheet['canViewFindings'];
    $canManageEscalations = $summarySheet['canManageEscalations'];
    $followUpResponseId = $summarySheet['followUpResponseId'];
    $nonCompliantFindings = $summarySheet['nonCompliantFindings'];
    $escalationOptions = $summarySheet['escalationOptions'];
    $summaryMode = $summarySheet['summaryMode'];
    $summaryScopeQuery = array_filter([
        'branch' => $summarySheet['selectedBranch'],
        'user_id' => $summarySheet['selectedUserId'],
        'user_type' => $summarySheet['selectedUserType'],
        'score_view' => $summaryMode,
        'audit_date' => $summaryMode === 'overall'
            ? $summarySheet['selectedOverallAuditDate']
            : ($summarySheet['isFiveSDailyChecklist'] ? $summarySheet['selectedFiveSDate'] : null),
        'five_s_area' => $activeForm === 'five_s' ? $summarySheet['fiveSArea'] : null,
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
        'audit_date' => $summarySheet['selectedOverallAuditDate'],
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
                    <span class="summary-card-kicker">{{ $summarySheet['isTimeSlotChecklist'] ? 'Completed Inspection Slots' : 'Answered Questions' }}</span>
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
                        <i class="fas fa-circle-check"></i> Target Met
                    </div>
                @endif
                <div class="summary-card-progress {{ $isBelowTarget ? 'progress-danger' : 'progress-success' }}" role="progressbar" aria-valuenow="{{ $cards['completion_rate'] }}" aria-valuemin="0" aria-valuemax="100">
                    <span style="width: {{ min(100, max(0, $cards['completion_rate'])) }}%"></span>
                </div>
            </div>
            <div class="summary-card-footer">
                <span>
                    <strong>{{ $cards['answered'] }}</strong> of {{ $cards['total_questions'] }}
                    {{ $summarySheet['isTimeSlotChecklist'] ? 'hourly checks completed' : 'items answered' }}
                </span>
            </div>
        </article>

        {{-- Card 2: Count of YES --}}
        <article class="summary-card card-yes" id="countYesCard">
            <div class="summary-card-top">
                <div>
                    <span class="summary-card-label">Yes</span>
                    <span class="summary-card-kicker">{{ $summarySheet['isTimeSlotChecklist'] ? 'Yes Answers' : 'Compliant' }}</span>
                </div>
                <div class="summary-card-icon" aria-hidden="true">
                    <i class="fas fa-circle-check"></i>
                </div>
            </div>
            <div class="summary-card-body">
                <div class="summary-card-value">{{ $cards['count_yes'] }}</div>
                <div class="summary-card-badge badge-success">
                    <i class="fas fa-check"></i> {{ $cards['answered'] > 0 ? round(($cards['count_yes'] / $cards['answered']) * 100, 1) : 0 }}% of {{ $summarySheet['isTimeSlotChecklist'] ? 'Checks' : 'Answered' }}
                </div>
                <div class="summary-card-progress progress-success">
                    <span style="width: {{ $cards['answered'] > 0 ? round(($cards['count_yes'] / $cards['answered']) * 100, 1) : 0 }}%"></span>
                </div>
            </div>
            <div class="summary-card-footer">
                <span>
                    <strong>{{ $cards['count_yes'] }}</strong> of {{ $cards['answered'] }} {{ $summarySheet['isTimeSlotChecklist'] ? 'checks' : 'answered' }}
                </span>
            </div>
        </article>

        {{-- Card 3: Count of NO --}}
        <article class="summary-card card-no" id="countNoCard">
            <div class="summary-card-top">
                <div>
                    <span class="summary-card-label">No</span>
                    <span class="summary-card-kicker">{{ $summarySheet['isTimeSlotChecklist'] ? 'No Answers' : 'Non-Compliant' }}</span>
                </div>
                <div class="summary-card-icon" aria-hidden="true">
                    <i class="fas fa-circle-xmark"></i>
                </div>
            </div>
            <div class="summary-card-body">
                <div class="summary-card-value">{{ $cards['count_no'] }}</div>
                <div class="summary-card-badge-row">
                    <div class="summary-card-badge badge-danger">
                        <i class="fas fa-triangle-exclamation"></i> {{ $cards['answered'] > 0 ? round(($cards['count_no'] / $cards['answered']) * 100, 1) : 0 }}% of {{ $summarySheet['isTimeSlotChecklist'] ? 'Checks' : 'Answered' }}
                    </div>
                    @if ($canManageFindings)
                        <span class="summary-card-badge-meta">
                            <strong>{{ $cards['count_no'] }}</strong> of {{ $cards['total_questions'] }} {{ $summarySheet['isTimeSlotChecklist'] ? 'checks' : 'answered' }}
                        </span>
                    @endif
                </div>
                <div class="summary-card-progress progress-danger">
                    <span style="width: {{ $cards['answered'] > 0 ? round(($cards['count_no'] / $cards['answered']) * 100, 1) : 0 }}%"></span>
                </div>
            </div>
            @if ($canManageFindings)
                <div class="summary-card-footer summary-card-footer-actions">
                    @if ($canViewFindings)
                        <button type="button"
                                class="summary-card-action summary-card-action-secondary"
                                data-summary-modal-target="summaryFindingsModal"
                                {{ $nonCompliantFindings->isEmpty() ? 'disabled' : '' }}>
                            <i class="fas fa-magnifying-glass" aria-hidden="true"></i>
                            View Findings
                        </button>
                    @endif
                    @if ($canManageEscalations)
                        <button type="button"
                                class="summary-card-action summary-card-action-danger"
                                data-summary-modal-target="summaryEscalationModal"
                                {{ $nonCompliantFindings->isEmpty() ? 'disabled' : '' }}>
                            <i class="fas fa-arrow-up-right-dots" aria-hidden="true"></i>
                            Escalation
                        </button>
                    @endif
                </div>
            @elseif ($summaryMode === 'overall')
                <div class="summary-card-footer">
                    <span>
                        <strong>{{ $cards['count_no'] }}</strong> of {{ $cards['answered'] }} answered &middot; {{ $summarySheet['aggregateUserCount'] }} {{ Str::plural('user', $summarySheet['aggregateUserCount']) }}
                    </span>
                </div>
            @else
                <div class="summary-card-footer">
                    <span>
                        <strong>{{ $cards['count_no'] }}</strong> of {{ $cards['answered'] }} {{ $summarySheet['isTimeSlotChecklist'] ? 'checks' : 'answered' }}
                    </span>
                </div>
            @endif
        </article>

        {{-- Card 4: Count of N/A or hourly restroom checklist scope --}}
        <article class="summary-card card-na" id="countNaCard">
            <div class="summary-card-top">
                <div>
                    <span class="summary-card-label">{{ $summarySheet['isTimeSlotChecklist'] ? 'Checklist Items' : 'Not Applicable (N/A)' }}</span>
                    <span class="summary-card-kicker">{{ $summarySheet['isTimeSlotChecklist'] ? 'Restroom Standards' : 'Not Applicable' }}</span>
                </div>
                <div class="summary-card-icon" aria-hidden="true">
                    <i class="fas {{ $summarySheet['isTimeSlotChecklist'] ? 'fa-restroom' : 'fa-circle-minus' }}"></i>
                </div>
            </div>
            <div class="summary-card-body">
                <div class="summary-card-value">{{ $summarySheet['isTimeSlotChecklist'] ? $cards['item_total'] : $cards['count_na'] }}</div>
                <div class="summary-card-badge" style="background:#f1f5f9; color:#475569; border: 1px solid #cbd5e1;">
                    @if ($summarySheet['isTimeSlotChecklist'])
                        <i class="fas fa-list-check"></i> {{ $cards['coverage_count'] }} Inspection Areas
                    @else
                        <i class="fas fa-minus"></i> N/A Items
                    @endif
                </div>
                <div class="summary-card-progress" style="background:#e2e8f0;">
                    <span style="width: {{ $summarySheet['isTimeSlotChecklist'] ? 100 : ($cards['answered'] > 0 ? round(($cards['count_na'] / $cards['answered']) * 100, 1) : 0) }}%; background: #64748b;"></span>
                </div>
            </div>
            <div class="summary-card-footer">
                <span>
                    @if ($summarySheet['isTimeSlotChecklist'])
                        <strong>{{ $cards['coverage_count'] }}</strong> {{ Str::plural('area', $cards['coverage_count']) }} &middot; {{ $summarySheet['selectedUtilityTime'] ? $summarySheet['selectedUtilityTimeLabel'].' check per item' : $summarySheet['timeSlotCount'].' scheduled checks per item' }}
                    @else
                        <strong>{{ $cards['count_na'] }}</strong> of {{ $cards['total_questions'] }} items counted in total
                    @endif
                </span>
            </div>
        </article>
    </section>

    {{-- CONTROLS & SWITCHER BAR --}}
    <section class="summary-control-bar" aria-label="Summary sheet navigation and controls">
        {{-- Form Switcher Pills: Sales DOS, Aftersales DOS, and 5S --}}
        @php
            $salesTabQuery = array_merge($summaryScopeQuery, ['form' => 'sales']);
            unset($salesTabQuery['score_view'], $salesTabQuery['five_s_area'], $salesTabQuery['audit_date']);

            $aftersalesTabQuery = array_merge($summaryScopeQuery, ['form' => 'aftersales']);
            unset($aftersalesTabQuery['score_view'], $aftersalesTabQuery['five_s_area'], $aftersalesTabQuery['user_id'], $aftersalesTabQuery['user_type'], $aftersalesTabQuery['audit_date']);

            $fiveSTabQuery = array_merge($summaryScopeQuery, ['form' => 'five_s', 'five_s_area' => $summarySheet['fiveSArea']]);
            unset($fiveSTabQuery['score_view']);
        @endphp
        <div class="summary-pills-switcher" role="tablist" aria-label="Audit summary type">
            @if ($summarySheet['summaryFormOptions']->has('sales'))
            <a href="{{ route('dashboard', $salesTabQuery) }}"
               class="summary-pill-btn {{ $activeForm === 'sales' ? 'active' : '' }}"
               role="tab"
               aria-selected="{{ $activeForm === 'sales' ? 'true' : 'false' }}">
                <i class="fas fa-car" aria-hidden="true"></i>
                <span>Sales Standards (FY25)</span>
            </a>
            @endif
            @if ($summarySheet['summaryFormOptions']->has('aftersales'))
            <a href="{{ route('dashboard', $aftersalesTabQuery) }}"
               class="summary-pill-btn {{ $activeForm === 'aftersales' ? 'active' : '' }}"
               role="tab"
               aria-selected="{{ $activeForm === 'aftersales' ? 'true' : 'false' }}">
                <i class="fas fa-screwdriver-wrench" aria-hidden="true"></i>
                <span>Aftersales Standards (FY25)</span>
            </a>
            @endif
            @if ($summarySheet['summaryFormOptions']->has('five_s'))
            <a href="{{ route('dashboard', $fiveSTabQuery) }}"
               class="summary-pill-btn {{ $activeForm === 'five_s' ? 'active' : '' }}"
               role="tab"
               aria-selected="{{ $activeForm === 'five_s' ? 'true' : 'false' }}">
                <i class="fas fa-broom-ball" aria-hidden="true"></i>
                <span>5S Checklist</span>
            </a>
            @endif
            @if ($summarySheet['summaryFormOptions']->isEmpty())
                <span class="summary-pill-btn" aria-disabled="true">
                    <i class="fas fa-ban" aria-hidden="true"></i>
                    <span>No checklists available for this branch</span>
                </span>
            @endif
        </div>

        @if ($activeForm === 'five_s' && $summarySheet['fiveSAreaOptions']->count() > 1)
            <div class="summary-score-switcher" role="group" aria-label="5S checklist area">
                @foreach ($summarySheet['fiveSAreaOptions'] as $fiveSArea => $fiveSAreaLabel)
                    <a href="{{ route('dashboard', array_merge($summaryScopeQuery, ['form' => 'five_s', 'five_s_area' => $fiveSArea])) }}"
                       class="summary-score-switch {{ $summarySheet['fiveSArea'] === $fiveSArea ? 'active' : '' }}"
                       aria-pressed="{{ $summarySheet['fiveSArea'] === $fiveSArea ? 'true' : 'false' }}">
                        <i class="fas {{ match ($fiveSArea) {
                            'service' => 'fa-screwdriver-wrench',
                            'restroom' => 'fa-restroom',
                            default => 'fa-car-side',
                        } }}" aria-hidden="true"></i>
                        {{ $fiveSAreaLabel }}
                    </a>
                @endforeach
            </div>
        @elseif ($summarySheet['canSwitchSummaryMode'])
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
            @if ($activeForm === 'five_s')
                <input type="hidden" name="five_s_area" value="{{ $summarySheet['fiveSArea'] }}">
            @endif

            @if ($isAdministrator)
                <div class="summary-filter-group">
                    <label for="summaryBranchSelect"><i class="fas fa-location-dot"></i> Outlet:</label>
                    <select name="branch" id="summaryBranchSelect" class="summary-select" onchange="['summaryUserSelect','summaryRestroomArea','summaryRestroomId','summaryRestroomGender','summaryUtilityMonth','summaryUtilityDay'].forEach(id => { const el = document.getElementById(id); if (el) el.value = ''; }); this.form.submit()">
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
                                {{ $summaryUser->nameWithRole() }}
                            </option>
                        @endforeach
                    </select>
                </div>
            @endif

            @if ($summaryMode === 'user')
                @if ($summarySheet['isUtilityChecklist'])
                    <div class="summary-filter-group">
                        <label for="summaryRestroomArea"><i class="fas fa-restroom"></i> Area:</label>
                        <select name="restroom_area"
                                id="summaryRestroomArea"
                                class="summary-select"
                                onchange="const restroom = document.getElementById('summaryRestroomId'); if (restroom) restroom.value = ''; document.getElementById('summaryRestroomGender').value = ''; this.form.submit()">
                            @foreach ($summarySheet['availableRestroomAreas'] as $areaVal => $areaLabel)
                                <option value="{{ $areaVal }}" @selected($areaVal === ($summarySheet['selectedRestroomArea'] ?? ''))>
                                    {{ $areaLabel }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    @if ($summarySheet['branchRestrooms']->count() > 1)
                        <div class="summary-filter-group">
                            <label for="summaryRestroomId"><i class="fas fa-door-open"></i> Restroom:</label>
                            <select name="restroom_id"
                                    id="summaryRestroomId"
                                    class="summary-select"
                                    onchange="const areaEl = document.getElementById('summaryRestroomArea'); if (areaEl) areaEl.value = this.selectedOptions[0]?.dataset.areaType || ''; document.getElementById('summaryRestroomGender').value = ''; this.form.submit()">
                                <option value="" data-area-type="">All Restrooms</option>
                                @foreach ($summarySheet['branchRestrooms'] as $rItem)
                                    @if (empty($summarySheet['selectedRestroomArea']) || $rItem->area_type === $summarySheet['selectedRestroomArea'])
                                        <option value="{{ $rItem->id }}"
                                                data-area-type="{{ $rItem->area_type }}"
                                                @selected($rItem->id === ($summarySheet['selectedRestroomId'] ?? null))>
                                            {{ $rItem->name }} ({{ $rItem->isCustomerArea() ? 'Customer' : 'Office' }})
                                        </option>
                                    @endif
                                @endforeach
                            </select>
                        </div>
                    @endif

                    <div class="summary-filter-group">
                        <label for="summaryRestroomGender"><i class="fas fa-venus-mars"></i> Type:</label>
                        <select name="restroom_gender"
                                id="summaryRestroomGender"
                                class="summary-select"
                                onchange="this.form.submit()">
                            @foreach ($summarySheet['availableGenders'] as $genderVal => $genderLabel)
                                <option value="{{ $genderVal }}" @selected($genderVal === ($summarySheet['selectedRestroomGender'] ?? ''))>
                                    {{ $genderLabel }}
                                </option>
                            @endforeach
                        </select>
                    </div>
                    <div class="summary-filter-group">
                        <label for="summaryUtilityMonth"><i class="fas fa-calendar"></i> Month and Year:</label>
                        <select name="utility_month"
                                id="summaryUtilityMonth"
                                class="summary-select"
                                onchange="document.getElementById('summaryUtilityDay').value = ''; this.form.submit()">
                            @forelse ($summarySheet['utilityAuditMonths'] as $monthOption)
                                <option value="{{ $monthOption['value'] }}"
                                        @selected($monthOption['value'] === $summarySheet['selectedUtilityMonth'])>
                                    {{ $monthOption['label'] }}
                                </option>
                            @empty
                                <option value="">No recorded month</option>
                            @endforelse
                        </select>
                    </div>

                    <div class="summary-filter-group">
                        <label for="summaryUtilityDay"><i class="fas fa-calendar-day"></i> Day:</label>
                        <select name="utility_day"
                                id="summaryUtilityDay"
                                class="summary-select"
                                onchange="this.form.submit()">
                            @forelse ($summarySheet['utilityAuditDays'] as $dayOption)
                                <option value="{{ $dayOption['value'] }}"
                                        @selected($dayOption['value'] === $summarySheet['selectedUtilityDay'])>
                                    {{ $dayOption['label'] }}
                                </option>
                            @empty
                                <option value="">No recorded day</option>
                            @endforelse
                        </select>
                    </div>

                    <div class="summary-filter-group">
                        <label for="summaryUtilityTime"><i class="fas fa-clock"></i> Time:</label>
                        <select name="utility_time"
                                id="summaryUtilityTime"
                                class="summary-select"
                                onchange="this.form.submit()">
                            <option value="">All Times</option>
                            @foreach ($summarySheet['utilityTimeOptions'] as $timeOption)
                                <option value="{{ $timeOption['value'] }}"
                                        @selected($timeOption['value'] === $summarySheet['selectedUtilityTime'])>
                                    {{ $timeOption['label'] }}
                                </option>
                            @endforeach
                        </select>
                    </div>
                @endif

                @if ($summarySheet['isStandardsChecklist'])
                    <div class="summary-filter-group">
                        <label for="summarySubSelect"><i class="fas fa-calendar"></i> Audit Month:</label>
                        <select name="submission_id" id="summarySubSelect" class="summary-select" onchange="this.form.submit()">
                            @forelse ($summarySheet['availableSubmissions'] as $sub)
                                <option value="{{ $sub->id }}" {{ $sub->id === $summarySheet['selectedSubmissionId'] ? 'selected' : '' }}>
                                    {{ $sub->audit_month ?? 'September' }}
                                </option>
                            @empty
                                <option value="">No recorded audit</option>
                            @endforelse
                        </select>
                    </div>
                @elseif (! $summarySheet['isUtilityChecklist'])
                    <div class="summary-filter-group">
                        <label for="summaryFiveSMonth"><i class="fas fa-calendar"></i> Month and Year:</label>
                        <select name="five_s_month"
                                id="summaryFiveSMonth"
                                class="summary-select"
                                onchange="document.getElementById('summaryFiveSDay').value = ''; this.form.submit()">
                            @forelse ($summarySheet['fiveSAuditMonths'] as $monthOption)
                                <option value="{{ $monthOption['value'] }}"
                                        @selected($monthOption['value'] === $summarySheet['selectedFiveSMonth'])>
                                    {{ $monthOption['label'] }}
                                </option>
                            @empty
                                <option value="">No recorded month</option>
                            @endforelse
                        </select>
                    </div>

                    <div class="summary-filter-group">
                        <label for="summaryFiveSDay"><i class="fas fa-calendar-day"></i> Day:</label>
                        <select name="audit_date"
                                id="summaryFiveSDay"
                                class="summary-select"
                                onchange="this.form.submit()">
                            @forelse ($summarySheet['fiveSAuditDays'] as $dayOption)
                                <option value="{{ $dayOption['value'] }}"
                                        @selected($dayOption['value'] === $summarySheet['selectedFiveSDate'])>
                                    {{ $dayOption['label'] }}
                                </option>
                            @empty
                                <option value="">No recorded day</option>
                            @endforelse
                        </select>
                    </div>
                @endif
            @else
                <div class="summary-filter-group">
                    <label for="summaryOverallAuditDate"><i class="fas fa-calendar"></i> {{ $summarySheet['isStandardsChecklist'] ? 'Audit Month:' : 'Audit Date:' }}</label>
                    <select name="audit_date"
                            id="summaryOverallAuditDate"
                            class="summary-select"
                            onchange="this.form.submit()">
                        <option value="">Latest audit per user</option>
                        @foreach ($summarySheet['availableOverallAuditDates'] as $auditDateOption)
                            <option value="{{ $auditDateOption['value'] }}"
                                    @selected($auditDateOption['value'] === $summarySheet['selectedOverallAuditDate'])>
                                {{ $auditDateOption['label'] }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="summary-aggregate-scope" aria-label="Overall Aftersales scope">
                    <i class="fas fa-layer-group" aria-hidden="true"></i>
                    @if ($summarySheet['selectedOverallAuditDate'])
                        <span><strong>{{ $summarySheet['aggregateUserCount'] }}</strong> user {{ Str::plural('audit', $summarySheet['aggregateUserCount']) }} on {{ $summarySheet['date'] }}</span>
                    @else
                        <span><strong>{{ $summarySheet['aggregateUserCount'] }}</strong> latest user {{ Str::plural('audit', $summarySheet['aggregateUserCount']) }}</span>
                    @endif
                </div>
            @endif

            <div class="summary-filter-actions">
                @if ($activeForm === 'aftersales' && !empty($subformDocData['has_submissions']))
                    <button type="button" class="summary-btn btn-subform-doc" id="btnOpenSubformDocModal" onclick="openSubformDocModal()" title="View existing Subform & Documentation submissions">
                        <i class="fas fa-file-circle-check"></i>
                        <span>{{ $subformDocData['button_label'] }}</span>
                    </button>
                @endif
                <a href="{{ $summarySheet['checklistRoute'] }}" class="summary-btn btn-primary" title="Open and edit audit form">
                    <i class="fas fa-pen-to-square"></i>
                    <span>Open Audit Form</span>
                </a>
                <button type="button" class="summary-btn" onclick="handleSummaryPrint()" title="Print summary sheet">
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
                    <span class="scope-chip"><i class="fas fa-clipboard-check"></i> {{ $summarySheet['activeFormLabel'] }}</span>
                </div>
            </div>
            <div class="meta-header-badges" style="display:flex; gap:8px; align-items:center; flex-wrap:wrap; justify-content:flex-end;">
                @if ($summarySheet['status'] === 'submitted')
                    <span class="badge-rating badge-pass"><i class="fas fa-circle-check"></i> SUBMITTED</span>
                @elseif ($summarySheet['status'] === 'draft')
                    <span class="badge-rating badge-fail" style="background:#fef3c7; color:#b45309; border-color:#fde68a;"><i class="fas fa-clock"></i> DRAFT / IN PROGRESS</span>
                @elseif ($summarySheet['status'] === 'aggregate')
                    <span class="badge-rating badge-pass"><i class="fas fa-users"></i> OVERALL USERS</span>
                @else
                    <span class="badge-rating badge-neutral"><i class="fas fa-circle-info"></i> NO RECORDED AUDIT</span>
                @endif

                @if ($activeForm === 'aftersales' && !empty($subformDocData['has_submissions']))
                    <button type="button" class="badge-rating badge-subform-doc" onclick="openSubformDocModal()" title="Click to view Subform & Documentation results">
                        <i class="fas fa-file-circle-check"></i> {{ $subformDocData['badge_label'] }}
                    </button>
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
                <div class="meta-label">{{ $summarySheet['isStandardsChecklist'] ? 'Audit Month' : ($summaryMode === 'overall' ? 'Audit Scope' : 'Audit Date') }}</div>
                <div class="meta-value">{{ $summarySheet['date'] }}</div>
            </div>
            <div class="summary-meta-item">
                <div class="meta-label">{{ $summaryMode === 'overall' ? 'Users Included' : 'Auditor' }}</div>
                <div class="meta-value">{{ $summarySheet['auditor'] }}</div>
            </div>
            <div class="summary-meta-item">
                @if ($summarySheet['isUtilityChecklist'])
                    <div class="meta-label">Audit Completion Month</div>
                    <div class="meta-value" title="{{ $summarySheet['completion_tooltip'] ?? '' }}">{{ $summarySheet['completion_month'] }}</div>
                @else
                    <div class="meta-label">Completion Date and Time</div>
                    <div class="meta-value">{{ $summarySheet['completion_date_time'] }}</div>
                @endif
            </div>
        </div>
    </section>

    {{-- SECTION 1: OVERALL AUDIT SCORE (Table 1) --}}
    <section class="summary-table-card" aria-label="Overall audit score table">
        <div class="summary-section-header">
            <div>
                <h2>
                    @if ($activeForm === 'five_s')
                        {{ $summarySheet['fiveSAreaLabel'] }} 5S Checklist Score
                    @else
                        {{ $summaryMode === 'overall' ? 'Overall Aftersales Score per Criteria' : 'User Audit Score per Criteria' }}
                    @endif
                </h2>
                <p>
                    @if ($activeForm === 'five_s')
                        @if ($summarySheet['isTimeSlotChecklist'])
                            <strong>{{ $summarySheet['selectedRestroomScopeLabel'] ?? 'All Restrooms · All Genders' }}</strong>
                            ({{ $cards['restroom_type_count'] }} {{ Str::plural('restroom type', $cards['restroom_type_count']) }}) &mdash;
                            @if ($summarySheet['selectedUtilityTime'])
                                Showing the {{ $summarySheet['selectedUtilityTimeLabel'] }} inspection for each restroom item. Yes and No answers determine the score.
                            @else
                                Each restroom item is checked across the {{ $summarySheet['timeSlotCount'] }} hourly slots from 8 AM to 5 PM. Yes and No answers determine the score.
                            @endif
                        @else
                            Total includes all checklist items. N/A items do not count as score.
                        @endif
                    @elseif ($summaryMode === 'overall')
                        {{ $summarySheet['aggregateUserCount'] }} {{ Str::plural('user', $summarySheet['aggregateUserCount']) }} combined. Base score from Basic + Standard; Beyond bonus applied when base &lt; 80%.
                    @else
                        {{ $summarySheet['scoreContextLabel'] }}@if ($summarySheet['scoreContextRole']) ({{ $summarySheet['scoreContextRole'] }})@endif &mdash; role-assigned criteria only.
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
                        <th style="width: 110px; text-align: center;">{{ $summarySheet['isTimeSlotChecklist'] ? 'Slots' : 'Total' }}</th>
                        <th style="width: 110px; text-align: center;">{{ $summarySheet['isTimeSlotChecklist'] ? 'Yes' : 'Score' }}</th>
                        <th style="width: 80px; text-align: center;">N/A</th>
                        <th style="width: 200px;">% Score</th>
                        <th style="width: 120px; text-align: center;">Rating</th>
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
                                @elseif ($activeForm === 'five_s')
                                    <span class="table-benchmark-tag table-benchmark-bonus">
                                        {{ $summarySheet['isTimeSlotChecklist']
                                            ? (($summarySheet['selectedRestroomScopeLabel'] ?? 'All Restrooms').' · '.$summarySheet['selectedUtilityTimeLabel'].' score · / good · X not good')
                                            : 'Checklist score · N/A in total' }}
                                    </span>
                                @else
                                    <span class="table-benchmark-tag table-benchmark-bonus">No rating &middot; Bonus credit</span>
                                @endif
                            </td>
                            <td style="text-align: center;"><strong>{{ $row['total'] }}</strong></td>
                            <td style="text-align: center;"><strong>{{ $row['score'] }}</strong></td>
                            <td style="text-align: center;">{{ $row['na'] ?? 0 }}</td>
                            <td>
                                <div class="cell-pct-bar">
                                    <span class="pct-val">{{ number_format($row['percent'], 1) }}%</span>
                                    <div class="table-progress {{ $row['target'] === null ? 'progress-bonus' : ($row['percent'] >= $row['target'] ? '' : ($row['percent'] >= 60 ? 'progress-amber' : 'progress-red')) }}">
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
                        <td colspan="2" style="text-transform: uppercase;">
                            TOTAL:
                            @if ($overallSummary['uses_beyond_bonus'])
                                <span class="table-benchmark-tag table-benchmark-bonus">
                                    Base {{ number_format($overallSummary['base_percent'], 1) }}%
                                    + {{ number_format($overallSummary['beyond_bonus_percentage_points'], 1) }}% Beyond bonus
                                </span>
                            @endif
                        </td>
                        <td style="text-align: center;">{{ $overallSummary['total'] }}</td>
                        <td style="text-align: center;">{{ $overallSummary['score'] }}</td>
                        <td style="text-align: center;">{{ $overallSummary['na'] ?? 0 }}</td>
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
                            @elseif ($overallSummary['rating'] === 'FAIL')
                                <span class="badge-rating badge-fail"><i class="fas fa-xmark"></i> FAIL</span>
                            @else
                                <span class="badge-rating badge-neutral">&mdash;</span>
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
                <h2>
                    @if ($activeForm === 'five_s')
                        Compliance per 5S Area
                    @else
                        {{ $summaryMode === 'overall' ? 'Overall Aftersales Score per Category' : 'User Audit Score per Category' }}
                    @endif
                </h2>
                <p>
                    @if ($activeForm === 'five_s')
                        @if ($summarySheet['isUtilityChecklist'])
                            Restroom - Utility worksheet breakdown &mdash; <strong>{{ $summarySheet['selectedRestroomScopeLabel'] ?? 'All Restrooms · All Genders' }}</strong> &middot; {{ $summarySheet['selectedUtilityTimeLabel'] }}.
                        @else
                            {{ $summarySheet['fiveSAreaLabel'] }} worksheet breakdown.
                        @endif
                    @elseif ($summaryMode === 'overall')
                        {{ count($coverageRows) }} operational categories combined.
                    @else
                        {{ $summarySheet['scoreContextLabel'] }} &mdash; role-assigned items only.
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
                        <th style="width: 110px; text-align: center;">{{ $summarySheet['isTimeSlotChecklist'] ? 'Slots' : 'Total' }}</th>
                        <th style="width: 110px; text-align: center;">{{ $summarySheet['isTimeSlotChecklist'] ? 'Yes' : 'Score' }}</th>
                        <th style="width: 80px; text-align: center;">N/A</th>
                        <th style="width: 240px;">% Score</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($coverageRows as $cov)
                        <tr>
                            <td>{{ $cov['no'] }}</td>
                            <td><strong>{{ $cov['coverage'] }}</strong></td>
                            <td style="text-align: center;">{{ $cov['total'] }}</td>
                            <td style="text-align: center;"><strong>{{ $cov['score'] }}</strong></td>
                            <td style="text-align: center;">{{ $cov['na'] ?? 0 }}</td>
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
                        <td style="text-align: center;">{{ $coverageSummary['na'] ?? 0 }}</td>
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

    @include('dashboard.summary-print')

    @if ($activeForm === 'aftersales' && !empty($subformDocData['has_submissions']))
        @include('dashboard.subform-doc-print')
    @endif
</div>

@if ($canManageFindings)
    @if ($canViewFindings)
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
                        <span>Select another {{ $summarySheet['isStandardsChecklist'] ? 'audit month' : 'audit date' }} to review its findings.</span>
                    </div>
                @else
                    <div class="summary-modal-callout">
                        <i class="fas fa-circle-info" aria-hidden="true"></i>
                        <span><strong>{{ $nonCompliantFindings->count() }}</strong> {{ !empty($isUtilityChecklist) ? Str::plural('inspection slot', $nonCompliantFindings->count()) : Str::plural('item', $nonCompliantFindings->count()) }} marked <strong>NO</strong> with checker details and evidence.</span>
                    </div>
                    <div class="summary-findings-table-wrap">
                        <table class="summary-findings-table">
                            <thead>
                                <tr>
                                    <th>Question</th>
                                    <th>Checked By</th>
                                    <th>Finding / Reason</th>
                                    <th>Photo Attached</th>
                                    <th>Follow-up</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach ($nonCompliantFindings as $finding)
                                    <tr>
                                        <td class="summary-question-cell">
                                            <div class="summary-table-tags">
                                                @if (!empty($finding['is_compiled']))
                                                    <span class="summary-table-tag tag-danger">FAILED ({{ $finding['compiled_count'] ?? 30 }} ITEMS)</span>
                                                @else
                                                    <span class="summary-table-tag tag-danger">NO</span>
                                                @endif
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
                                            @if (!empty($finding['is_compiled']) && !empty($finding['compiled_questions']))
                                                <details class="compiled-checklist-items-toggle" style="margin-top: 8px; font-size: 11px; background: rgba(15, 38, 66, 0.05); border: 1px solid #cbd5e1; border-radius: 8px; padding: 6px 10px;">
                                                    <summary style="cursor: pointer; font-weight: 700; color: #0284c7;">
                                                        <i class="fas fa-list-check" aria-hidden="true"></i> View all {{ $finding['compiled_count'] }} checklist questions
                                                    </summary>
                                                    <ol style="margin: 8px 0 4px 18px; padding: 0; line-height: 1.5; color: #334155; max-height: 180px; overflow-y: auto;">
                                                        @foreach ($finding['compiled_questions'] as $cq)
                                                            <li>
                                                                <strong>{{ $cq['area'] ?? '' }}:</strong> {{ $cq['question'] }}
                                                                <span style="display: inline-block; padding: 1px 5px; font-size: 9px; font-weight: 800; border-radius: 4px; background: #fee2e2; color: #dc2626; margin-left: 4px;">{{ $cq['result'] ?? 'NO' }}</span>
                                                            </li>
                                                        @endforeach
                                                    </ol>
                                                </details>
                                            @endif
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
                                                <small><b>Task:</b> {{ $finding['bom_task'] }}</small>
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
                                        <td class="summary-follow-up-cell">
                                            <button type="button"
                                                    class="summary-follow-up-btn"
                                                    data-request-finding-follow-up
                                                    data-endpoint="{{ route('reports.responses.follow-up', $finding['response_id']) }}">
                                                <i class="fas fa-bell" aria-hidden="true"></i>
                                                <span>Follow-up</span>
                                            </button>
                                            <small class="summary-follow-up-status" role="status" aria-live="polite"></small>
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
    @endif

    @if ($canManageEscalations)
    <div class="modal-overlay summary-modal-overlay" id="summaryEscalationModal" aria-hidden="true">
        <section class="modal summary-modal summary-modal-wide"
                 role="dialog"
                 aria-modal="true"
                 aria-labelledby="summaryEscalationTitle"
                 tabindex="-1">
            <header class="modal-header summary-modal-header">
                <div>
                    <span class="summary-modal-eyebrow"><i class="fas fa-arrow-up-right-dots" aria-hidden="true"></i> Action Plan</span>
                    <h2 id="summaryEscalationTitle">Escalate non-compliant findings</h2>
                    <small>{{ $summarySheet['activeFormTitle'] }} &middot; {{ $summarySheet['outlet'] }} &middot; {{ $summarySheet['date_with_year'] }}</small>
                </div>
                <button type="button" class="modal-close" data-close-summary-modal aria-label="Close escalation dialog">
                    <i class="fas fa-xmark" aria-hidden="true"></i>
                </button>
            </header>

            <div class="modal-body summary-modal-body summary-escalation-body">
                @if ($nonCompliantFindings->isEmpty())
                    <div class="summary-modal-empty">
                        <i class="fas fa-circle-check" aria-hidden="true"></i>
                        <strong>No findings require escalation.</strong>
                    </div>
                @else
                    @if ($followUpResponseId)
                        <div class="summary-follow-up-guidance">
                            <i class="fas fa-location-dot" aria-hidden="true"></i>
                            <span>Follow-up requested on the highlighted finding. Select <strong>Escalate</strong> to complete.</span>
                        </div>
                    @endif
                    <div class="summary-modal-callout">
                        <i class="fas fa-shield-halved" aria-hidden="true"></i>
                        <span>Select <strong>Escalate</strong> to assign a recipient, action plan, and commitment date.</span>
                    </div>
                    <div class="summary-escalation-status" id="summaryEscalationListStatus" role="status" aria-live="polite"></div>
                    <div class="summary-findings-table-wrap">
                        <table class="summary-findings-table summary-escalation-table">
                            <thead>
                                <tr>
                                    <th>Question &amp; Area</th>
                                    <th>Checker / Accountable</th>
                                    <th>Finding</th>
                                    <th>Photo Attached</th>
                                    <th>Escalation</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach ($nonCompliantFindings as $finding)
                                    <tr id="summaryEscalationFinding{{ $finding['response_id'] }}"
                                        class="{{ (int) $followUpResponseId === (int) $finding['response_id'] ? 'is-follow-up-highlight' : '' }}"
                                        data-summary-escalation-row
                                        data-response-id="{{ $finding['response_id'] }}"
                                        @if (!empty($finding['is_compiled']) && !empty($finding['response_ids']))
                                            data-response-ids="{{ implode(',', $finding['response_ids']) }}"
                                        @endif
                                        data-is-compiled="{{ !empty($finding['is_compiled']) ? '1' : '0' }}"
                                        data-template-slug="{{ $finding['template_slug'] ?? $activeSlug ?? '' }}"
                                        data-auditor-role="{{ $finding['checked_by_role'] ?? '' }}"
                                        data-checker-role="{{ $finding['checker_role'] ?? '' }}"
                                        data-is-restroom="{{ !empty($isUtilityChecklist) || !empty($finding['is_restroom']) || ($activeSlug ?? '') === 'restroom' ? '1' : '0' }}"
                                        @if ((int) $followUpResponseId === (int) $finding['response_id'])
                                            data-follow-up-highlight
                                            tabindex="-1"
                                        @endif>
                                        <td class="summary-question-cell">
                                            <div class="summary-table-tags">
                                                @if (!empty($finding['is_compiled']))
                                                    <span class="summary-table-tag tag-danger">FAILED ({{ $finding['compiled_count'] ?? 30 }} ITEMS)</span>
                                                @else
                                                    <span class="summary-table-tag tag-danger">NO</span>
                                                @endif
                                                @if ($finding['category'])
                                                    <span class="summary-table-tag">{{ $finding['category'] }}</span>
                                                @endif
                                            </div>
                                            <strong data-summary-escalation-question>
                                                @if ($finding['question_number'])
                                                    {{ $finding['question_number'] }}.
                                                @endif
                                                {{ $finding['question'] }}
                                            </strong>
                                            @if ($finding['subject'])
                                                <small>{{ $finding['subject'] }}</small>
                                            @endif
                                            <small>{{ $finding['area'] }} &middot; <span data-summary-escalation-item-key>{{ $finding['item_key'] }}</span></small>
                                            @if (!empty($finding['is_compiled']) && !empty($finding['compiled_questions']))
                                                <details class="compiled-checklist-items-toggle" style="margin-top: 8px; font-size: 11px; background: rgba(15, 38, 66, 0.05); border: 1px solid #cbd5e1; border-radius: 8px; padding: 6px 10px;">
                                                    <summary style="cursor: pointer; font-weight: 700; color: #0284c7;">
                                                        <i class="fas fa-list-check" aria-hidden="true"></i> View all {{ $finding['compiled_count'] }} checklist questions
                                                    </summary>
                                                    <ol style="margin: 8px 0 4px 18px; padding: 0; line-height: 1.5; color: #334155; max-height: 180px; overflow-y: auto;">
                                                        @foreach ($finding['compiled_questions'] as $cq)
                                                            <li>
                                                                <strong>{{ $cq['area'] ?? '' }}:</strong> {{ $cq['question'] }}
                                                                <span style="display: inline-block; padding: 1px 5px; font-size: 9px; font-weight: 800; border-radius: 4px; background: #fee2e2; color: #dc2626; margin-left: 4px;">{{ $cq['result'] ?? 'NO' }}</span>
                                                            </li>
                                                        @endforeach
                                                    </ol>
                                                </details>
                                            @endif
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
                                            <strong data-summary-escalation-finding>{{ $finding['finding'] }}</strong>
                                            @if ($finding['bom_task'])
                                                <small><b>Task:</b> {{ $finding['bom_task'] }}</small>
                                            @endif
                                        </td>
                                        <td class="summary-escalation-photo-cell">
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
                                        <td class="summary-escalation-action-cell">
                                            <input type="hidden"
                                                   value="{{ $finding['escalation_target'] }}"
                                                   data-summary-escalation-value="escalation_target"
                                                   data-escalation-label="{{ $finding['escalation_target_label'] }}">
                                            <textarea hidden data-summary-escalation-value="action_plan">{{ $finding['action_plan'] }}</textarea>
                                            <input type="hidden"
                                                   value="{{ $finding['commitment_date_input'] }}"
                                                   data-summary-escalation-value="commitment_date">
                                            <div class="summary-escalation-current">
                                                <strong data-summary-current-escalation>
                                                    {{ $finding['escalation_target_label'] ?: 'Not assigned' }}
                                                </strong>
                                                <small data-summary-current-plan>
                                                    {{ $finding['action_plan'] ? 'Action plan added' : 'No action plan yet' }}
                                                </small>
                                                <small data-summary-current-commitment>
                                                    {{ $finding['commitment_date'] ? 'Commitment: '.$finding['commitment_date'] : 'No commitment date' }}
                                                </small>
                                            </div>
                                            <button type="button"
                                                    class="summary-escalate-btn"
                                                    data-open-summary-escalation-editor
                                                    aria-controls="summaryEscalationEditorModal">
                                                <i class="fas fa-arrow-up-right-dots" aria-hidden="true"></i>
                                                <span>Escalate</span>
                                            </button>
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

    <div class="modal-overlay summary-modal-overlay summary-escalation-editor-overlay" id="summaryEscalationEditorModal" aria-hidden="true">
        <section class="modal summary-modal summary-escalation-editor-modal"
                 role="dialog"
                 aria-modal="true"
                 aria-labelledby="summaryEscalationEditorTitle"
                 tabindex="-1">
            <header class="modal-header summary-modal-header">
                <div>
                    <span class="summary-modal-eyebrow"><i class="fas fa-arrow-up-right-dots" aria-hidden="true"></i> Action Plan</span>
                    <h2 id="summaryEscalationEditorTitle">Escalate finding</h2>
                    <small id="summaryEscalationEditorItem">Select a finding to continue.</small>
                </div>
                <button type="button" class="modal-close" data-close-summary-modal aria-label="Close escalation form">
                    <i class="fas fa-xmark" aria-hidden="true"></i>
                </button>
            </header>

            <form id="summaryEscalationForm" data-endpoint="{{ route('reports.responses.escalations') }}">
                <input type="hidden" id="summaryEscalationResponseId" value="">
                <div class="modal-body summary-modal-body summary-escalation-editor-body">
                    <div class="summary-escalation-context">
                        <span class="summary-table-tag tag-danger">NO</span>
                        <strong id="summaryEscalationEditorQuestion"></strong>
                        <p id="summaryEscalationEditorFinding"></p>
                    </div>

                    <div class="summary-escalation-fields">
                        <div class="summary-escalation-field-group">
                            <label for="summaryEscalationTarget">Escalate To</label>
                            <select id="summaryEscalationTarget"
                                    required
                                    class="summary-escalation-select"
                                    data-summary-escalation-field="escalation_target">
                                <option value="">No escalation selected</option>
                                @foreach ($escalationOptions as $targetValue => $targetLabel)
                                    <option value="{{ $targetValue }}">{{ $targetLabel }}</option>
                                @endforeach
                            </select>
                        </div>

                        <div class="summary-escalation-field-group">
                            <label for="summaryActionPlan">Action Plan</label>
                            <textarea id="summaryActionPlan"
                                      required
                                      class="summary-action-plan-input"
                                      data-summary-escalation-field="action_plan"
                                      rows="5"
                                      maxlength="10000"
                                      placeholder="Write the Action Plan here"></textarea>
                        </div>

                        <div class="summary-escalation-field-group">
                            <label for="summaryCommitmentDate">Commitment Date Planned</label>
                            <input id="summaryCommitmentDate"
                                   required
                                   class="summary-commitment-date-input"
                                   data-summary-escalation-field="commitment_date"
                                   type="date">
                        </div>
                    </div>
                </div>

                <footer class="summary-modal-footer">
                    <div class="summary-escalation-status" id="summaryEscalationStatus" role="status" aria-live="polite"></div>
                    <div class="summary-modal-actions">
                        <button type="button" class="summary-modal-btn" data-close-summary-modal>Cancel</button>
                        <button type="submit" class="summary-modal-btn summary-modal-btn-primary" id="saveSummaryEscalations">
                            <i class="fas fa-floppy-disk" aria-hidden="true"></i>
                            <span>Save Escalation</span>
                        </button>
                    </div>
                </footer>
            </form>
        </section>
    </div>
    @endif

    <script>
        (() => {
            const modalTriggers = document.querySelectorAll('[data-summary-modal-target]');
            const modals = document.querySelectorAll('.summary-modal-overlay');
            const modalTriggerMap = new WeakMap();

            const closeModal = (modal, { reset = true } = {}) => {
                if (!modal) return;
                const escalationForm = modal.querySelector('#summaryEscalationForm');
                if (escalationForm?.dataset.saving === 'true') return;

                if (reset) {
                    escalationForm?.querySelectorAll('[data-summary-escalation-field]').forEach((field) => {
                        field.value = field.dataset.originalValue || '';
                    });
                }
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
                const trigger = modalTriggerMap.get(modal);
                modalTriggerMap.delete(modal);
                trigger?.focus();
            };

            const openModal = (modal, trigger) => {
                if (!modal || trigger?.disabled) return;
                if (trigger) modalTriggerMap.set(modal, trigger);
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

            const escalationEditorModal = document.getElementById('summaryEscalationEditorModal');
            const escalationForm = document.getElementById('summaryEscalationForm');
            const escalationResponseId = document.getElementById('summaryEscalationResponseId');
            const escalationFields = [...(escalationForm?.querySelectorAll('[data-summary-escalation-field]') || [])];

            const rowValueField = (row, fieldName) => row?.querySelector(
                `[data-summary-escalation-value="${fieldName}"]`
            );

            const cleanText = (element) => (element?.textContent || '').replace(/\s+/g, ' ').trim();

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

            const openEscalationEditor = (button) => {
                const row = button?.closest('[data-summary-escalation-row]');
                if (!row || !escalationForm || !escalationEditorModal) return;

                const targetSelect = escalationForm.querySelector('[data-summary-escalation-field="escalation_target"]');
                const rowOptions = resolveEscalationOptions(row.dataset);
                const currentTargetVal = rowValueField(row, 'escalation_target')?.value || '';
                populateEscalationSelect(targetSelect, rowOptions, currentTargetVal, 'No escalation selected');

                escalationResponseId.value = row.dataset.responseId || '';
                escalationFields.forEach((field) => {
                    const source = rowValueField(row, field.dataset.summaryEscalationField);
                    const value = source?.value || '';

                    if (field === targetSelect && value && ![...field.options].some((option) => option.value === value)) {
                        const option = document.createElement('option');
                        option.value = value;
                        option.textContent = source?.dataset.escalationLabel || value;
                        option.dataset.temporaryEscalationOption = 'true';
                        field.append(option);
                    }

                    field.value = value;
                    field.dataset.originalValue = value;
                });

                const itemKey = cleanText(row.querySelector('[data-summary-escalation-item-key]'));
                const editorItem = document.getElementById('summaryEscalationEditorItem');
                const editorQuestion = document.getElementById('summaryEscalationEditorQuestion');
                const editorFinding = document.getElementById('summaryEscalationEditorFinding');
                const editorStatus = document.getElementById('summaryEscalationStatus');

                if (editorItem) editorItem.textContent = itemKey ? `Item ${itemKey}` : 'Selected non-compliant finding';
                if (editorQuestion) editorQuestion.textContent = cleanText(row.querySelector('[data-summary-escalation-question]'));
                if (editorFinding) editorFinding.textContent = cleanText(row.querySelector('[data-summary-escalation-finding]'));
                if (editorStatus) {
                    editorStatus.className = 'summary-escalation-status';
                    editorStatus.textContent = '';
                }

                openModal(escalationEditorModal, button);
                window.requestAnimationFrame(() => targetSelect?.focus());
            };

            document.querySelectorAll('[data-open-summary-escalation-editor]').forEach((button) => {
                button.addEventListener('click', () => openEscalationEditor(button));
            });

            @if ($canViewFindings)
            document.querySelectorAll('[data-request-finding-follow-up]').forEach((button) => {
                button.addEventListener('click', async () => {
                    if (button.disabled) return;

                    const status = button.closest('.summary-follow-up-cell')?.querySelector('.summary-follow-up-status');
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
                                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || '',
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
                const open = [...modals].reverse().find((modal) => modal.classList.contains('is-open'));
                if (open) closeModal(open);
            });

            escalationForm?.addEventListener('submit', async (event) => {
                event.preventDefault();
                if (escalationForm.dataset.saving === 'true') return;

                const status = document.getElementById('summaryEscalationStatus');
                const saveButton = document.getElementById('saveSummaryEscalations');
                const responseId = Number(escalationResponseId?.value);
                const row = [...document.querySelectorAll('[data-summary-escalation-row]')]
                    .find((candidate) => Number(candidate.dataset.responseId) === responseId);
                const hasChanges = escalationFields.some(
                    (field) => field.value !== (field.dataset.originalValue || '')
                );

                status.className = 'summary-escalation-status';
                if (!row || !responseId) {
                    status.classList.add('is-error');
                    status.textContent = 'Select a finding before saving.';
                    return;
                }
                if (!hasChanges) {
                    status.textContent = 'No changes to save.';
                    return;
                }

                const update = { id: responseId };
                escalationFields.forEach((field) => {
                    update[field.dataset.summaryEscalationField] = field.value || null;
                });

                saveButton.disabled = true;
                saveButton.classList.add('is-loading');
                escalationForm.dataset.saving = 'true';
                escalationForm.setAttribute('aria-busy', 'true');
                escalationFields.forEach((field) => {
                    field.disabled = true;
                });
                status.textContent = 'Saving escalation...';
                let savedSuccessfully = false;

                try {
                    const response = await fetch(escalationForm.dataset.endpoint, {
                        method: 'PATCH',
                        headers: {
                            'Accept': 'application/json',
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || '',
                        },
                        body: JSON.stringify({ responses: [update] }),
                    });
                    const data = await response.json().catch(() => ({}));

                    if (!response.ok) {
                        throw new Error(data.message || 'The finding follow-up details could not be saved.');
                    }

                    const saved = (data.responses || []).find((item) => Number(item.id) === responseId) || {
                        id: responseId,
                        escalation_target: update.escalation_target,
                        escalation_target_label: escalationForm
                            .querySelector('[data-summary-escalation-field="escalation_target"]')
                            ?.selectedOptions[0]?.textContent,
                        action_plan: typeof update.action_plan === 'string' ? update.action_plan.trim() : null,
                        commitment_date: update.commitment_date,
                    };

                    escalationFields.forEach((field) => {
                        const fieldName = field.dataset.summaryEscalationField;
                        const value = Object.prototype.hasOwnProperty.call(saved, fieldName)
                            ? (saved[fieldName] || '')
                            : field.value;
                        const source = rowValueField(row, fieldName);

                        field.value = value;
                        field.dataset.originalValue = value;
                        if (source) source.value = value;
                    });

                    const targetSource = rowValueField(row, 'escalation_target');
                    const targetLabel = saved.escalation_target
                        ? (saved.escalation_target_label || saved.escalation_target)
                        : 'Not assigned';
                    if (targetSource) targetSource.dataset.escalationLabel = targetLabel;

                    const currentEscalation = row.querySelector('[data-summary-current-escalation]');
                    const currentPlan = row.querySelector('[data-summary-current-plan]');
                    const currentCommitment = row.querySelector('[data-summary-current-commitment]');
                    if (currentEscalation) currentEscalation.textContent = targetLabel;
                    if (currentPlan) currentPlan.textContent = saved.action_plan ? 'Action plan added' : 'No action plan yet';
                    if (currentCommitment) {
                        currentCommitment.textContent = saved.commitment_date
                            ? `Commitment: ${saved.commitment_date}`
                            : 'No commitment date';
                    }

                    const listStatus = document.getElementById('summaryEscalationListStatus');
                    if (listStatus) {
                        listStatus.className = 'summary-escalation-status is-success';
                        listStatus.textContent = data.message || 'Escalation saved.';
                    }
                    savedSuccessfully = true;
                } catch (error) {
                    status.classList.add('is-error');
                    status.textContent = error.message || 'The finding follow-up details could not be saved.';
                } finally {
                    saveButton.disabled = false;
                    saveButton.classList.remove('is-loading');
                    escalationForm.dataset.saving = 'false';
                    escalationForm.removeAttribute('aria-busy');
                    escalationFields.forEach((field) => {
                        field.disabled = false;
                    });
                }

                if (savedSuccessfully) closeModal(escalationEditorModal, { reset: false });
            });

            const highlightedFollowUp = document.querySelector('[data-follow-up-highlight]');
            if (highlightedFollowUp) {
                const escalationModal = document.getElementById('summaryEscalationModal');
                openModal(escalationModal, null);
                window.requestAnimationFrame(() => {
                    highlightedFollowUp.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'center' });
                    const escalateButton = highlightedFollowUp.querySelector('[data-open-summary-escalation-editor]');
                    if (escalateButton) openEscalationEditor(escalateButton);
                    else highlightedFollowUp.focus({ preventScroll: true });
                });
            }
        })();
    </script>
@endif

@if ($activeForm === 'aftersales' && !empty($subformDocData['has_submissions']))
    @include('dashboard.subform-doc-modal')

    <dialog id="printOptionsModal" class="subform-doc-dialog print-options-dialog" aria-labelledby="printOptionsModalTitle">
        <div class="subform-doc-modal-container" style="max-width: 550px;">
            <header class="subform-doc-modal-header">
                <div class="modal-header-info">
                    <span class="subform-doc-modal-badge"><i class="fas fa-print"></i> PRINT REPORT OPTIONS</span>
                    <h2 id="printOptionsModalTitle">Select Audit Sheets to Print</h2>
                    <p style="margin: 4px 0 0; font-size: 12px; color: #64748b;">Choose which aftersales documents to include in your printed report.</p>
                </div>
                <button type="button" class="subform-doc-modal-close" onclick="closePrintOptionsModal()" aria-label="Close dialog">
                    <i class="fas fa-times"></i>
                </button>
            </header>
            <div class="print-options-body">
                <label class="print-option-card">
                    <input type="radio" name="printScopeChoice" value="both" checked>
                    <div class="option-content">
                        <div class="option-title-row">
                            <i class="fas fa-copy option-icon"></i>
                            <span class="option-name">Both (Aftersales Results + Subform &amp; Documentation)</span>
                            <span class="option-recommended-tag">Recommended</span>
                        </div>
                        <p class="option-desc">Complete multi-sheet aftersales audit package (Main form summary + 39 Subform items + 3 RO Documentation samples).</p>
                    </div>
                </label>

                <label class="print-option-card">
                    <input type="radio" name="printScopeChoice" value="aftersales_only">
                    <div class="option-content">
                        <div class="option-title-row">
                            <i class="fas fa-file-invoice option-icon"></i>
                            <span class="option-name">Aftersales Results Only</span>
                        </div>
                        <p class="option-desc">Only the standard FY25 Aftersales Compliance Audit Summary Sheet (Overall Scores, Category Compliance, Radar &amp; Bar Charts, Signatures).</p>
                    </div>
                </label>

                <label class="print-option-card">
                    <input type="radio" name="printScopeChoice" value="subform_doc_only">
                    <div class="option-content">
                        <div class="option-title-row">
                            <i class="fas fa-layer-group option-icon"></i>
                            <span class="option-name">Subform &amp; Documentation Only</span>
                        </div>
                        <p class="option-desc">Only the Subform compliance summary across 5 areas and the 17-standard multi-sample documentation matrix.</p>
                    </div>
                </label>
            </div>
            <footer class="subform-doc-modal-footer">
                <button type="button" class="summary-btn" onclick="closePrintOptionsModal()">
                    <span>Cancel</span>
                </button>
                <button type="button" class="summary-btn btn-primary" onclick="confirmPrintOptions()">
                    <i class="fas fa-print"></i>
                    <span>Print Document</span>
                </button>
            </footer>
        </div>
    </dialog>

    <script>
        function openPrintOptionsModal() {
            const dialog = document.getElementById('printOptionsModal');
            if (!dialog) return;
            if (typeof dialog.showModal === 'function') {
                dialog.showModal();
            } else {
                dialog.setAttribute('open', '');
            }
        }

        function closePrintOptionsModal() {
            const dialog = document.getElementById('printOptionsModal');
            if (!dialog) return;
            if (typeof dialog.close === 'function' && dialog.open) {
                dialog.close();
            } else {
                dialog.removeAttribute('open');
            }
        }

        function triggerAdminPrint(scope) {
            document.body.classList.remove('print-scope-aftersales', 'print-scope-subform-doc', 'print-scope-both');
            if (scope === 'aftersales_only') {
                document.body.classList.add('print-scope-aftersales');
            } else if (scope === 'subform_doc_only') {
                document.body.classList.add('print-scope-subform-doc');
            } else {
                document.body.classList.add('print-scope-both');
            }

            window.print();
        }

        function confirmPrintOptions() {
            const selected = document.querySelector('input[name="printScopeChoice"]:checked')?.value || 'both';
            closePrintOptionsModal();
            triggerAdminPrint(selected);
        }

        window.addEventListener('afterprint', () => {
            document.body.classList.remove('print-scope-aftersales', 'print-scope-subform-doc', 'print-scope-both');
        });
    </script>
@endif

<script>
    function handleSummaryPrint() {
        @if ($activeForm === 'aftersales' && !empty($subformDocData['has_submissions']))
            openPrintOptionsModal();
        @else
            window.print();
        @endif
    }
</script>
