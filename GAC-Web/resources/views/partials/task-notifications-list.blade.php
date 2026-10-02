@if ($activeTaskNotifications->isNotEmpty())
    <section class="notification-group" aria-labelledby="taskNotificationsTitle" data-task-notification-group>
        <div class="notification-group-heading">
            <h3 id="taskNotificationsTitle">Audit notifications</h3>
            <span>{{ $activeTaskNotifications->count() }} current</span>
        </div>

        @foreach ($activeTaskNotifications as $taskNotification)
            @php
                $taskData = is_array($taskNotification->data) ? $taskNotification->data : [];
                $taskSeen = $taskNotification->read_at !== null;
                $taskReportUrl = route('notifications.view-task', $taskNotification->id);
                $isFindingFollowUp = data_get($taskData, 'event') === 'finding_follow_up_requested';
            @endphp
            <article class="notify task-completion{{ $isFindingFollowUp ? ' finding-follow-up-request' : '' }}{{ $taskSeen ? ' is-viewed' : ' is-not-viewed' }}"
                     data-task-notification="{{ $taskNotification->id }}">
                <i class="fas {{ $isFindingFollowUp ? 'fa-bell' : 'fa-circle-check' }}" aria-hidden="true"></i>
                <div class="notification-copy">
                    <div class="notification-title-row">
                        <b>{{ data_get($taskData, 'title', 'Audit activity') }}</b>
                        <span class="notification-status {{ $taskSeen ? 'viewed' : 'not-viewed' }}"
                              data-notification-status>
                            {{ $taskSeen ? 'Seen' : 'New' }}
                        </span>
                    </div>
                    <p>{{ data_get($taskData, 'message', 'A checklist audit was updated.') }}</p>
                    @if (!empty($taskData['questions']))
                        <details class="notification-compiled-questions" style="margin: 6px 0 8px 0; font-size: 11px; background: rgba(15, 38, 66, 0.4); border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 8px; padding: 6px 10px;">
                            <summary style="cursor: pointer; font-weight: 700; color: var(--gateway-cyan, #00d2ff);">
                                <i class="fas fa-list-check" aria-hidden="true"></i> View compiled checklist ({{ count($taskData['questions']) }} questions)
                            </summary>
                            <ol style="margin: 8px 0 4px 18px; padding: 0; line-height: 1.5; color: #cbd5e1; max-height: 160px; overflow-y: auto;">
                                @foreach ($taskData['questions'] as $q)
                                    <li>
                                        <strong>{{ $q['area'] ?? '' }}:</strong> {{ $q['question'] ?? $q['item_key'] }}
                                        <span style="display: inline-block; padding: 1px 5px; font-size: 9px; font-weight: 800; border-radius: 4px; background: rgba(217, 45, 32, 0.2); color: #f87171; margin-left: 4px;">{{ $q['result'] ?? 'X' }}</span>
                                    </li>
                                @endforeach
                            </ol>
                        </details>
                    @endif
                    @include('partials.escalation-follow-up-photos', ['followUpData' => $taskData])
                    <div class="notification-meta">
                        <span><i class="far fa-clock" aria-hidden="true"></i>{{ $taskNotification->created_at?->diffForHumans() }}</span>
                        @if (data_get($taskData, 'audit_date'))
                            <span><i class="far fa-calendar" aria-hidden="true"></i>{{ data_get($taskData, 'audit_date') }}</span>
                        @endif
                        <a href="{{ $taskReportUrl }}"
                           class="{{ $isFindingFollowUp ? 'notification-escalate-link' : '' }}">
                            {{ $isFindingFollowUp ? 'Escalate' : 'View Task' }}
                            <i class="fas {{ $isFindingFollowUp ? 'fa-arrow-up-right-dots' : 'fa-arrow-right' }}" aria-hidden="true"></i>
                        </a>
                    </div>
                </div>
            </article>
        @endforeach
    </section>
@endif
