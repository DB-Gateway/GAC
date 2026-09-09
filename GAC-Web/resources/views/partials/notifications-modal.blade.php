<div class="modal-overlay"
     id="notificationsModal"
     aria-hidden="true"
     data-mark-viewed-url="{{ ($canReceiveTaskNotifications ?? false) ? route('notifications.mark-all-viewed') : '' }}"
     data-unread-task-count="{{ $unreadTaskNotificationCount ?? 0 }}">
    <div class="modal" role="dialog" aria-labelledby="notificationsModalTitle" aria-modal="true">
        <div class="modal-header">
            <div>
                <h2 id="notificationsModalTitle">Notifications</h2>
                <small>Audit activity and system alerts</small>
            </div>
            <button type="button" class="modal-close" id="notificationsModalClose" aria-label="Close notifications">
                <i class="fas fa-xmark" aria-hidden="true"></i>
            </button>
        </div>
        <div class="modal-body">
            @if ($canReceiveTaskNotifications ?? false)
                <section class="notification-group" aria-labelledby="taskNotificationsTitle">
                    <div class="notification-group-heading">
                        <h3 id="taskNotificationsTitle">Audit notifications</h3>
                        <span>{{ isset($taskNotifications) ? $taskNotifications->count() : 0 }} recent</span>
                    </div>

                    @forelse ($taskNotifications ?? [] as $taskNotification)
                        @php
                            $taskData = is_array($taskNotification->data) ? $taskNotification->data : [];
                            $taskViewed = $taskNotification->read_at !== null;
                            $taskReportUrl = route('notifications.view-task', $taskNotification->id);
                        @endphp
                        <article class="notify task-completion{{ $taskViewed ? ' is-viewed' : ' is-not-viewed' }}"
                                 data-task-notification="{{ $taskNotification->id }}">
                            <i class="fas fa-circle-check" aria-hidden="true"></i>
                            <div class="notification-copy">
                                <div class="notification-title-row">
                                    <b>{{ data_get($taskData, 'title', 'Audit activity') }}</b>
                                    <span class="notification-status {{ $taskViewed ? 'viewed' : 'not-viewed' }}"
                                          data-notification-status>
                                        {{ $taskViewed ? 'Viewed' : 'Not viewed' }}
                                    </span>
                                </div>
                                <p>{{ data_get($taskData, 'message', 'A checklist audit was updated.') }}</p>
                                <div class="notification-meta">
                                    <span><i class="far fa-clock" aria-hidden="true"></i>{{ $taskNotification->created_at?->diffForHumans() }}</span>
                                    @if (data_get($taskData, 'audit_date'))
                                        <span><i class="far fa-calendar" aria-hidden="true"></i>{{ data_get($taskData, 'audit_date') }}</span>
                                    @endif
                                    <a href="{{ $taskReportUrl }}">View Task <i class="fas fa-arrow-right" aria-hidden="true"></i></a>
                                </div>
                            </div>
                        </article>
                    @empty
                        <p class="dashboard-empty notification-empty">No audit notifications yet.</p>
                    @endforelse
                </section>
            @endif

            @if (isset($notifications) && $notifications->isNotEmpty())
                <section class="notification-group" aria-labelledby="systemNotificationsTitle">
                    <div class="notification-group-heading">
                        <h3 id="systemNotificationsTitle">System alerts</h3>
                        <span>{{ data_get($calendar ?? [], 'label', now()->format('F Y')) }}</span>
                    </div>
                    @foreach ($notifications as $notification)
                        @php
                            $notificationActionTarget = data_get($notification, 'action.target');
                            $notificationActionLabel = data_get($notification, 'action.label');
                            $notificationIsActionable = is_string($notificationActionTarget) && $notificationActionTarget !== '';
                        @endphp
                        @if ($notificationIsActionable)
                            <button type="button"
                                    class="notify {{ $notification['type'] }} notification-action"
                                    data-notification-action-target="{{ $notificationActionTarget }}"
                                    aria-controls="{{ $notificationActionTarget }}">
                        @else
                            <div class="notify {{ $notification['type'] }}">
                        @endif
                            <i class="fas {{ $notification['icon'] }}" aria-hidden="true"></i>
                            <div class="notification-copy">
                                <b>{{ $notification['title'] }}</b>
                                <p>{{ $notification['message'] }}</p>
                                @if ($notificationIsActionable)
                                    <span class="notification-action-hint">
                                        {{ $notificationActionLabel ?: 'View details' }}
                                        <i class="fas fa-arrow-right" aria-hidden="true"></i>
                                    </span>
                                @endif
                            </div>
                        @if ($notificationIsActionable)
                            </button>
                        @else
                            </div>
                        @endif
                    @endforeach
                </section>
            @else
                <p class="dashboard-empty">No active audit alerts for {{ data_get($calendar ?? [], 'label', now()->format('F Y')) }}.</p>
            @endif
        </div>
    </div>
</div>

<script>
    (() => {
        if (window.__gatewayNotificationsInitialized) return;
        window.__gatewayNotificationsInitialized = true;

        const notificationsButton = document.getElementById('notificationsBtn');
        const notificationsModal = document.getElementById('notificationsModal');
        const notificationsClose = document.getElementById('notificationsModalClose');
        const notificationsBadge = document.getElementById('notificationsBadge');
        let markingNotifications = false;

        const setNotificationBadge = (count) => {
            if (!notificationsBadge) return;

            const unreadCount = Math.max(0, Number(count) || 0);
            notificationsBadge.textContent = unreadCount > 0 ? String(unreadCount) : '';
            notificationsBadge.style.display = unreadCount > 0 ? '' : 'none';
            notificationsBadge.setAttribute('aria-hidden', unreadCount > 0 ? 'false' : 'true');
            notificationsButton?.setAttribute(
                'aria-label',
                unreadCount > 0 ? `Open notifications (${unreadCount} unread)` : 'Open notifications'
            );
        };

        const markTaskNotificationsViewed = async () => {
            if (!notificationsModal || markingNotifications) return;

            const url = notificationsModal.dataset.markViewedUrl;
            const unreadCount = Number(notificationsModal.dataset.unreadTaskCount || 0);
            if (!url || unreadCount < 1) return;

            markingNotifications = true;
            setNotificationBadge(0);

            try {
                const response = await fetch(url, {
                    method: 'PATCH',
                    headers: {
                        Accept: 'application/json',
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || '',
                    },
                    credentials: 'same-origin',
                    body: JSON.stringify({}),
                });

                if (!response.ok) throw new Error('Unable to update notification status.');

                const result = await response.json();
                (result.ids || []).forEach((id) => {
                    const notification = document.querySelector(`[data-task-notification="${id}"]`);
                    const status = notification?.querySelector('[data-notification-status]');

                    notification?.classList.remove('is-not-viewed');
                    notification?.classList.add('is-viewed');
                    status?.classList.remove('not-viewed');
                    status?.classList.add('viewed');
                    if (status) status.textContent = 'Viewed';
                });

                notificationsModal.dataset.unreadTaskCount = '0';
            } catch (error) {
                setNotificationBadge(unreadCount);
            } finally {
                markingNotifications = false;
            }
        };

        const setNotificationsOpen = (open) => {
            if (!notificationsModal) return;

            notificationsModal.classList.toggle('is-open', open);
            notificationsModal.setAttribute('aria-hidden', open ? 'false' : 'true');
            notificationsButton?.setAttribute('aria-expanded', open ? 'true' : 'false');
            document.body.style.overflow = open ? 'hidden' : '';
            if (open) notificationsClose?.focus();
            else notificationsButton?.focus();
        };

        notificationsButton?.addEventListener('click', () => {
            setNotificationsOpen(true);
            void markTaskNotificationsViewed();
        });
        notificationsClose?.addEventListener('click', () => setNotificationsOpen(false));
        notificationsModal?.addEventListener('click', (event) => {
            const action = event.target.closest('[data-notification-action-target]');
            if (action) {
                const target = action.dataset.notificationActionTarget;
                const summaryAction = [...document.querySelectorAll('.summary-card-action-secondary[data-summary-modal-target]')]
                    .find((button) => button.dataset.summaryModalTarget === target);

                if (summaryAction && !summaryAction.disabled) {
                    setNotificationsOpen(false);
                    window.requestAnimationFrame(() => summaryAction.click());
                }

                return;
            }

            if (event.target === notificationsModal) setNotificationsOpen(false);
        });

        document.addEventListener('keydown', (event) => {
            if (event.key !== 'Escape') return;
            if (notificationsModal?.classList.contains('is-open')) setNotificationsOpen(false);
        });
    })();
</script>
