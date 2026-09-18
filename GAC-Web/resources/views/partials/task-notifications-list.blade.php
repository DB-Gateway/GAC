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
