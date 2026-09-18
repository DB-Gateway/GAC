@if ($historicalTaskNotifications->isNotEmpty())
    <div class="notification-history-layout">
        <div class="notification-history-list" role="listbox" aria-label="Notification history previews">
            @foreach ($historicalTaskNotifications as $historyNotification)
                @php
                    $historyData = is_array($historyNotification->data) ? $historyNotification->data : [];
                @endphp
                <button type="button"
                        class="notification-history-preview{{ $loop->first ? ' active' : '' }}"
                        id="notificationHistoryPreview{{ $historyNotification->id }}"
                        role="option"
                        aria-selected="{{ $loop->first ? 'true' : 'false' }}"
                        aria-controls="notificationHistoryDetail{{ $historyNotification->id }}"
                        data-notification-history-target="notificationHistoryDetail{{ $historyNotification->id }}">
                    <span class="notification-history-preview-icon"><i class="fas fa-check" aria-hidden="true"></i></span>
                    <span class="notification-history-preview-copy">
                        <strong>{{ data_get($historyData, 'title', 'Audit activity') }}</strong>
                        <span>{{ Str::limit(data_get($historyData, 'message', 'A checklist audit was updated.'), 82) }}</span>
                        <small>{{ $historyNotification->updated_at?->diffForHumans() }}</small>
                    </span>
                </button>
            @endforeach
        </div>

        <div class="notification-history-details" aria-live="polite">
            @foreach ($historicalTaskNotifications as $historyNotification)
                @php
                    $historyData = is_array($historyNotification->data) ? $historyNotification->data : [];
                    $historyIsFollowUp = data_get($historyData, 'event') === 'finding_follow_up_requested';
                    $historyRoleValue = $historyIsFollowUp
                        ? data_get($historyData, 'requested_by_role')
                        : data_get($historyData, 'completed_by_role');
                    $historyRole = filled($historyRoleValue)
                        ? \App\Models\User::roleLabelFor($historyRoleValue)
                        : 'Not recorded';
                    $historyStandards = match (data_get($historyData, 'standards_type')) {
                        'sales' => 'Sales Standards',
                        'aftersales' => 'Aftersales Standards',
                        'five_s' => match (data_get($historyData, 'five_s_area')) {
                            'sales' => 'Sales 5S Checklist',
                            'service' => 'Service 5S Checklist',
                            'restroom' => 'Utilities 5S Checklist',
                            default => 'Gateway 5S Checklist',
                        },
                        default => data_get($historyData, 'template_name', 'Checklist task'),
                    };
                @endphp
                <article class="notification-history-detail{{ $loop->first ? ' active' : '' }}"
                         id="notificationHistoryDetail{{ $historyNotification->id }}"
                         role="region"
                         aria-labelledby="notificationHistoryPreview{{ $historyNotification->id }}"
                         data-notification-history-detail
                         @if (! $loop->first) hidden @endif>
                    <div class="notification-history-detail-heading">
                        <span class="notification-history-detail-icon"><i class="fas {{ $historyIsFollowUp ? 'fa-bell' : 'fa-clipboard-check' }}" aria-hidden="true"></i></span>
                        <div>
                            <span class="notification-history-eyebrow">{{ $historyIsFollowUp ? 'BOM follow-up' : 'Seen notification' }}</span>
                            <h3>{{ data_get($historyData, 'title', 'Audit activity') }}</h3>
                        </div>
                    </div>
                    <p>{{ data_get($historyData, 'message', 'A checklist audit was updated.') }}</p>
                    @include('partials.escalation-follow-up-photos', ['followUpData' => $historyData])

                    <dl class="notification-history-facts">
                        <div><dt>{{ $historyIsFollowUp ? 'Requested by' : 'User' }}</dt><dd>{{ $historyIsFollowUp ? data_get($historyData, 'requested_by_name', 'Not recorded') : data_get($historyData, 'completed_by_name', 'Not recorded') }}</dd></div>
                        <div><dt>User type</dt><dd>{{ $historyRole }}</dd></div>
                        <div><dt>Branch</dt><dd>{{ $historyIsFollowUp ? data_get($historyData, 'branch', 'Not recorded') : data_get($historyData, 'completed_by_branch', data_get($historyData, 'branch', 'Not recorded')) }}</dd></div>
                        <div><dt>Standards</dt><dd>{{ $historyStandards }}</dd></div>
                        <div><dt>Audit date</dt><dd>{{ data_get($historyData, 'audit_date', 'Not recorded') }}</dd></div>
                        <div><dt>{{ $historyIsFollowUp ? 'Finding' : 'Findings' }}</dt><dd>{{ $historyIsFollowUp ? data_get($historyData, 'item_key', 'Not recorded') : data_get($historyData, 'finding_count', 0) }}</dd></div>
                    </dl>

                    <div class="notification-history-footer">
                        <span><i class="far fa-clock" aria-hidden="true"></i> Moved to history {{ $historyNotification->updated_at?->diffForHumans() }}</span>
                        <a href="{{ route('notifications.view-task', $historyNotification->id) }}">
                            {{ $historyIsFollowUp ? 'Open Follow-up Again' : 'Open Task Again' }} <i class="fas fa-arrow-up-right-from-square" aria-hidden="true"></i>
                        </a>
                    </div>
                </article>
            @endforeach
        </div>
    </div>
@else
    <div class="notification-empty-state">
        <i class="fas fa-clock-rotate-left" aria-hidden="true"></i>
        <strong>No notification history yet</strong>
        <span>Notifications move here automatically after you see them.</span>
    </div>
@endif
