@php
    $activeTaskNotifications = $taskNotifications ?? collect();
    $historicalTaskNotifications = $taskNotificationHistory ?? collect();
    $systemNotifications = $notifications ?? collect();
    $showTaskNotificationTabs = $canReceiveTaskNotifications ?? false;
@endphp

<div class="modal-overlay"
     id="notificationsModal"
     aria-hidden="true"
     data-status-url="{{ ($canReceiveTaskNotifications ?? false) ? route('notifications.status') : '' }}"
     data-mark-viewed-url="{{ ($canReceiveTaskNotifications ?? false) ? route('notifications.mark-all-viewed') : '' }}"
     data-unread-task-count="{{ $unreadTaskNotificationCount ?? 0 }}">
    <div class="modal notifications-modal" role="dialog" aria-labelledby="notificationsModalTitle" aria-modal="true">
        <div class="modal-header">
            <div>
                <h2 id="notificationsModalTitle">Notifications</h2>
                <small>Audit activity and system alerts</small>
            </div>
            <button type="button" class="modal-close" id="notificationsModalClose" aria-label="Close notifications">
                <i class="fas fa-xmark" aria-hidden="true"></i>
            </button>
        </div>
        <div class="modal-body notifications-modal-body">
            <section class="browser-push-settings" aria-label="Device notifications">
                <strong>Notifications on this device</strong>
                <p data-push-status role="status" aria-live="polite">Checking notification settings...</p>
                <button type="button" data-push-enable hidden>Enable notifications</button>
                <button type="button" data-push-disable hidden>Turn off on this device</button>
            </section>
            @if ($showTaskNotificationTabs)
                <div class="notification-tabs" role="tablist" aria-label="Notification views">
                    <button type="button"
                            class="notification-tab active"
                            id="currentNotificationsTab"
                            role="tab"
                            aria-selected="true"
                            aria-controls="currentNotificationsPanel"
                            data-notification-tab="current">
                        Current
                        <span data-current-notification-count>{{ $activeTaskNotifications->count() }}</span>
                    </button>
                    <button type="button"
                            class="notification-tab"
                            id="notificationHistoryTab"
                            role="tab"
                            aria-selected="false"
                            aria-controls="notificationHistoryPanel"
                            data-notification-tab="history">
                        History
                        <span data-history-notification-count>{{ $historicalTaskNotifications->count() }}</span>
                    </button>
                </div>
            @endif

            <section class="notification-tab-panel active"
                     id="currentNotificationsPanel"
                     @if ($showTaskNotificationTabs)
                         role="tabpanel"
                         aria-labelledby="currentNotificationsTab"
                     @else
                         role="region"
                         aria-label="Current notifications"
                     @endif
                     data-notification-panel="current">
                @if ($showTaskNotificationTabs)
                    @include('partials.task-notifications-list', ['activeTaskNotifications' => $activeTaskNotifications])
                @endif

                @if ($systemNotifications->isNotEmpty())
                    <section class="notification-group" aria-labelledby="systemNotificationsTitle">
                        <div class="notification-group-heading">
                            <h3 id="systemNotificationsTitle">System alerts</h3>
                            <span>{{ data_get($calendar ?? [], 'label', now()->format('F Y')) }}</span>
                        </div>
                        @foreach ($systemNotifications as $notification)
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
                @endif

                @if ((! $showTaskNotificationTabs || $activeTaskNotifications->isEmpty()) && $systemNotifications->isEmpty())
                    <div class="notification-empty-state" data-current-notification-empty>
                        <i class="far fa-bell-slash" aria-hidden="true"></i>
                        <strong>No notifications currently</strong>
                        <span>Seen notifications are saved automatically in History.</span>
                    </div>
                @endif
            </section>

            @if ($showTaskNotificationTabs)
                <section class="notification-tab-panel"
                         id="notificationHistoryPanel"
                         role="tabpanel"
                         aria-labelledby="notificationHistoryTab"
                         data-notification-panel="history"
                         hidden>
                    @include('partials.task-notification-history')
                </section>
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
        let notificationsBadge = document.getElementById('notificationsBadge');
        const notificationTabs = [...document.querySelectorAll('[data-notification-tab]')];
        const notificationPanels = [...document.querySelectorAll('[data-notification-panel]')];
        const baseDocumentTitle = document.title.replace(/^\(\d+\)\s*/, '');
        let markingNotifications = false;
        let notificationRefreshPromise = null;
        let latestNotificationFeed = null;
        let seenTimer = null;

        const isReadingCurrent = () => notificationsModal?.classList.contains('is-open')
            && !document.getElementById('currentNotificationsPanel')?.hidden;

        const scheduleSeenNotifications = () => {
            window.clearTimeout(seenTimer);
            if (isReadingCurrent() && document.visibilityState === 'visible') {
                seenTimer = window.setTimeout(() => void markTaskNotificationsViewed(), 800);
            }
        };

        const ensureNotificationBadge = () => {
            if (notificationsBadge || !notificationsButton) return notificationsBadge;

            notificationsBadge = document.createElement('span');
            notificationsBadge.id = 'notificationsBadge';
            notificationsBadge.className = 'notifications-badge';
            notificationsButton.append(notificationsBadge);

            return notificationsBadge;
        };

        const setNotificationBadge = (count) => {
            const unreadCount = Math.max(0, Number(count) || 0);
            const badge = unreadCount > 0 ? ensureNotificationBadge() : notificationsBadge;

            if (badge) {
                badge.textContent = unreadCount > 0 ? String(unreadCount) : '';
                badge.style.display = unreadCount > 0 ? '' : 'none';
                badge.setAttribute('aria-hidden', unreadCount > 0 ? 'false' : 'true');
            }

            notificationsButton?.setAttribute(
                'aria-label',
                unreadCount > 0 ? `Open notifications (${unreadCount} unread)` : 'Open notifications'
            );
            document.title = unreadCount > 0 ? `(${unreadCount}) ${baseDocumentTitle}` : baseDocumentTitle;
        };

        const createCurrentEmptyState = () => {
            const emptyState = document.createElement('div');
            emptyState.className = 'notification-empty-state';
            emptyState.dataset.currentNotificationEmpty = '';
            emptyState.innerHTML = [
                '<i class="far fa-bell-slash" aria-hidden="true"></i>',
                '<strong>No notifications currently</strong>',
                '<span>Seen notifications are saved automatically in History.</span>',
            ].join('');

            return emptyState;
        };

        const renderTaskNotifications = (html, currentCount) => {
            const currentPanel = document.getElementById('currentNotificationsPanel');
            if (!currentPanel) return;

            const template = document.createElement('template');
            template.innerHTML = typeof html === 'string' ? html.trim() : '';

            const currentGroup = currentPanel.querySelector('[data-task-notification-group]');
            const nextGroup = template.content.querySelector('[data-task-notification-group]');

            if (currentGroup && nextGroup) {
                currentGroup.replaceWith(nextGroup);
            } else if (currentGroup) {
                currentGroup.remove();
            } else if (nextGroup) {
                currentPanel.insertBefore(nextGroup, currentPanel.firstElementChild);
            }

            const count = Math.max(0, Number(currentCount) || 0);
            const countLabel = document.querySelector('[data-current-notification-count]');
            if (countLabel) countLabel.textContent = String(count);

            const hasNotificationGroup = Boolean(currentPanel.querySelector('.notification-group'));
            const emptyState = currentPanel.querySelector('[data-current-notification-empty]');

            if (hasNotificationGroup) {
                emptyState?.remove();
            } else if (!emptyState) {
                currentPanel.append(createCurrentEmptyState());
            }
        };

        const refreshTaskNotifications = () => {
            const url = notificationsModal?.dataset.statusUrl;
            if (!url || markingNotifications) return Promise.resolve();
            if (notificationRefreshPromise) return notificationRefreshPromise;

            notificationRefreshPromise = (async () => {
                try {
                    const response = await fetch(url, {
                        headers: { Accept: 'application/json' },
                        credentials: 'same-origin',
                        cache: 'no-store',
                    });

                    if (!response.ok) return;

                    const result = await response.json();
                    if (markingNotifications) return;

                    const unreadCount = Math.max(0, Number(result.unread_count) || 0);
                    notificationsModal.dataset.unreadTaskCount = String(unreadCount);
                    setNotificationBadge(unreadCount);
                    latestNotificationFeed = result;
                    // Keep the current reading session in place. Seen items are
                    // already in History and leave Current when switching or closing.
                    if (!isReadingCurrent()) renderTaskNotifications(result.html, result.current_count);
                    const historyPanel = document.getElementById('notificationHistoryPanel');
                    const selectedDetail = historyPanel?.querySelector('[data-notification-history-detail].active')?.id;
                    if (historyPanel && typeof result.history_html === 'string') {
                        historyPanel.innerHTML = result.history_html;
                        if (selectedDetail && document.getElementById(selectedDetail)) selectHistoryNotification(selectedDetail);
                    }
                    const historyCount = document.querySelector('[data-history-notification-count]');
                    if (historyCount) historyCount.textContent = String(result.history_count || 0);
                } catch {
                    // Keep the last known count when the connection is temporarily unavailable.
                } finally {
                    notificationRefreshPromise = null;
                }
            })();

            return notificationRefreshPromise;
        };

        const markTaskNotificationsViewed = async () => {
            if (notificationRefreshPromise) await notificationRefreshPromise;
            if (!notificationsModal || markingNotifications || !isReadingCurrent() || document.visibilityState !== 'visible'
                || document.querySelector('dialog[open]')) return;

            const url = notificationsModal.dataset.markViewedUrl;
            const viewport = notificationsModal.querySelector('.notifications-modal-body').getBoundingClientRect();
            const ids = [...notificationsModal.querySelectorAll('[data-task-notification].is-not-viewed')]
                .filter((notification) => {
                    const bounds = notification.getBoundingClientRect();
                    const visibleHeight = Math.min(bounds.bottom, viewport.bottom) - Math.max(bounds.top, viewport.top);
                    return visibleHeight >= Math.min(bounds.height, viewport.height) * 0.6;
                })
                .map((notification) => notification.dataset.taskNotification);
            if (!url || !ids.length) return;

            markingNotifications = true;

            try {
                const response = await fetch(url, {
                    method: 'PATCH',
                    headers: {
                        Accept: 'application/json',
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || '',
                    },
                    credentials: 'same-origin',
                    body: JSON.stringify({ ids }),
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
                    if (status) status.textContent = 'Seen';
                });

            } catch {
                // Retain unread status when saving fails; retry on the next refresh.
            } finally {
                markingNotifications = false;
            }
            await refreshTaskNotifications();
        };

        const selectNotificationTab = (tabName) => {
            if (latestNotificationFeed) renderTaskNotifications(latestNotificationFeed.html, latestNotificationFeed.current_count);
            notificationTabs.forEach((tab) => {
                const selected = tab.dataset.notificationTab === tabName;
                tab.classList.toggle('active', selected);
                tab.setAttribute('aria-selected', selected ? 'true' : 'false');
            });
            notificationPanels.forEach((panel) => {
                const selected = panel.dataset.notificationPanel === tabName;
                panel.classList.toggle('active', selected);
                panel.hidden = !selected;
            });
            scheduleSeenNotifications();
        };

        const selectHistoryNotification = (detailId) => {
            document.querySelectorAll('[data-notification-history-target]').forEach((preview) => {
                const selected = preview.dataset.notificationHistoryTarget === detailId;
                preview.classList.toggle('active', selected);
                preview.setAttribute('aria-selected', selected ? 'true' : 'false');
            });
            document.querySelectorAll('[data-notification-history-detail]').forEach((detail) => {
                const selected = detail.id === detailId;
                detail.classList.toggle('active', selected);
                detail.hidden = !selected;
            });
        };

        const setNotificationsOpen = (open) => {
            if (!notificationsModal) return;

            notificationsModal.classList.toggle('is-open', open);
            notificationsModal.setAttribute('aria-hidden', open ? 'false' : 'true');
            notificationsButton?.setAttribute('aria-expanded', open ? 'true' : 'false');
            document.body.style.overflow = open ? 'hidden' : '';
            if (open) notificationsClose?.focus();
            else {
                window.clearTimeout(seenTimer);
                if (latestNotificationFeed) renderTaskNotifications(latestNotificationFeed.html, latestNotificationFeed.current_count);
                notificationsButton?.focus();
            }
        };

        notificationsButton?.addEventListener('click', async () => {
            setNotificationsOpen(true);
            await refreshTaskNotifications();
            if (latestNotificationFeed) renderTaskNotifications(latestNotificationFeed.html, latestNotificationFeed.current_count);
            scheduleSeenNotifications();
        });
        notificationTabs.forEach((tab) => {
            tab.addEventListener('click', () => selectNotificationTab(tab.dataset.notificationTab));
        });
        notificationsModal?.querySelector('.notifications-modal-body')?.addEventListener('scroll', scheduleSeenNotifications);
        notificationsClose?.addEventListener('click', () => setNotificationsOpen(false));
        notificationsModal?.addEventListener('click', (event) => {
            const preview = event.target.closest('[data-notification-history-target]');
            if (preview) selectHistoryNotification(preview.dataset.notificationHistoryTarget);
            const action = event.target.closest('[data-notification-action-target]');
            if (action) {
                const target = action.dataset.notificationActionTarget;
                if (target === 'draftReminderModal') {
                    setNotificationsOpen(false);
                    window.dispatchEvent(new CustomEvent('gateway:open-draft-follow-up', { detail: { trigger: notificationsButton } }));
                    return;
                }
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
            if (document.querySelector('dialog[open]')) return;
            if (notificationsModal?.classList.contains('is-open')) setNotificationsOpen(false);
        });

        setNotificationBadge(notificationsModal?.dataset.unreadTaskCount || 0);

        if (notificationsModal?.dataset.statusUrl) {
            void refreshTaskNotifications();
            window.setInterval(async () => {
                await refreshTaskNotifications();
                scheduleSeenNotifications();
            }, 15000);

            document.addEventListener('visibilitychange', () => {
                if (document.visibilityState === 'visible') {
                    void refreshTaskNotifications();
                    scheduleSeenNotifications();
                }
            });
            window.addEventListener('focus', () => void refreshTaskNotifications());
            window.addEventListener('gateway:push-received', () => void refreshTaskNotifications());
        }
    })();
</script>

@include('partials.draft-reminder')
@include('partials.browser-push')
