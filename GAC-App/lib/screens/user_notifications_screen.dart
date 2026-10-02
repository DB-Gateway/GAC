import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/authenticated_user.dart';
import '../models/user_notification.dart';
import '../services/notification_service.dart';
import '../services/checklist_service.dart';
import 'user_checklist_detail_screen.dart';
import '../theme/gac_theme.dart';
import '../widgets/gac_surfaces.dart';
import '../widgets/user_avatar.dart';
import '../widgets/escalation_details_dialog.dart';

enum NotificationTab { recent, history }

enum NotificationCategoryFilter { all, notices, followUps }

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({
    required this.onOpenProfile,
    required this.onGoHome,
    required this.onOpenSettings,
    this.profile = AuthenticatedUser.fallback,
    this.controller,
    this.onOpenNotification,
    this.checklistRepository,
    this.initialTab = NotificationTab.recent,
    super.key,
  });

  final VoidCallback onOpenProfile;
  final VoidCallback onGoHome;
  final VoidCallback onOpenSettings;
  final AuthenticatedUser profile;
  final UserNotificationController? controller;
  final ValueChanged<String>? onOpenNotification;
  final ChecklistRepository? checklistRepository;
  final NotificationTab initialTab;

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  late UserNotificationController _controller;
  late bool _ownsController;
  late NotificationTab _selectedTab;
  NotificationCategoryFilter _selectedFilter = NotificationCategoryFilter.all;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _controller = widget.controller ?? UserNotificationController();
    _ownsController = widget.controller == null;
    if (!_controller.initialized) unawaited(_controller.load());
    if (_ownsController) _controller.startPolling();
  }

  @override
  void didUpdateWidget(covariant UserNotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = widget.initialTab;
    }
    if (oldWidget.controller == widget.controller) return;
    if (_ownsController) _controller.dispose();
    _controller = widget.controller ?? UserNotificationController();
    _ownsController = widget.controller == null;
    if (!_controller.initialized) unawaited(_controller.load());
    if (_ownsController) _controller.startPolling();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      widget.onGoHome();
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _controller.markAllRead();
    } on NotificationApiException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  Future<void> _openNotification(UserNotification notification) async {
    if (notification.type == 'finding_escalated') {
      unawaited(
        _controller.markRead(notification.id).catchError((Object error) {
          if (mounted) {
            _showError('The notification could not be marked as read.');
          }
        }),
      );
      final canFollowUp =
          widget.profile.is5sUtilities || widget.profile.isUtilities;
      final followUp = await showEscalationDetailsDialog(
        context,
        notification,
        canFollowUp: canFollowUp,
        currentUser: widget.profile,
        onFollowUpSubmitted: (submitted) {
          _controller.updateNotificationData(notification.id, {
            'has_follow_up': true,
            'follow_up_submitted_at': DateTime.now().toIso8601String(),
            'follow_up_recipient_name': submitted.recipientName,
            'follow_up_action_taken': submitted.remarks,
          });
        },
      );
      if (followUp != null) {
        _controller.updateNotificationData(notification.id, {
          'has_follow_up': true,
          'follow_up_submitted_at': DateTime.now().toIso8601String(),
          'follow_up_recipient_name': followUp.recipientName,
          'follow_up_action_taken': followUp.remarks,
        });
      }
      return;
    }
    try {
      await _controller.markRead(notification.id);
    } on NotificationApiException catch (error) {
      if (mounted) _showError(error.message);
      return;
    }
    if (!mounted) return;
    final isDraftReminder = notification.type == 'checklist_draft_reminder';
    if (isDraftReminder || notification.isUtilitiesInspectionNotice) {
      final slug = notification.data['template_slug'];
      final date = notification.data['audit_date'];
      final draftId = notification.data['submission_id'];
      if (slug is! String ||
          slug.isEmpty ||
          date is! String ||
          DateTime.tryParse(date) == null ||
          (isDraftReminder && draftId is! num)) {
        _showError('This reminder does not contain a valid checklist.');
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => UserChecklistDetailScreen(
            slug: slug,
            repository: widget.checklistRepository ?? ChecklistApiService(),
            user: widget.profile.id > 0 ? widget.profile : null,
            auditDate: date,
            expectedDraftId: isDraftReminder ? (draftId as num).toInt() : null,
            onOpenNotifications: () => Navigator.of(context).pop(),
            unreadNotifications: _controller.unreadCount,
            initialItemKey: notification.data['item_key'] as String?,
            initialSlotKey: notification.data['slot_key'] as String?,
            initialCustomerIndex: (notification.data['customer_index'] as num?)
                ?.toInt(),
          ),
        ),
      );
      return;
    }
    widget.onOpenNotification?.call(notification.id);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: GacColors.navy950),
      );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 380 ? 16.0 : 20.0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: GacColors.canvas,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: GacScreenBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    0,
                  ),
                  child: _NotificationsHeader(
                    profile: widget.profile,
                    onBack: _goBack,
                    onOpenProfile: widget.onOpenProfile,
                  ),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => RefreshIndicator(
                      onRefresh: () => _controller.load(showSpinner: false),
                      child: ListView(
                        key: const PageStorageKey<String>(
                          'user-notifications-scroll',
                        ),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          24,
                          horizontalPadding,
                          40 + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: _InboxBody(
                                controller: _controller,
                                selectedTab: _selectedTab,
                                selectedFilter: _selectedFilter,
                                onTabChanged: (tab) =>
                                    setState(() => _selectedTab = tab),
                                onFilterChanged: (filter) =>
                                    setState(() => _selectedFilter = filter),
                                onRetry: _controller.load,
                                onMarkAllRead: _markAllRead,
                                onOpenNotification: _openNotification,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.profile,
    required this.onBack,
    required this.onOpenProfile,
  });

  final AuthenticatedUser profile;
  final VoidCallback onBack;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: GacGlassSurface(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        borderRadius: 22,
        shadowBlurRadius: 16,
        shadowOffset: const Offset(0, 4),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('notifications-back'),
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: GacColors.textPrimary,
              ),
            ),
            const Expanded(
              child: Text(
                'Notification center',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: GacColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkResponse(
                onTap: onOpenProfile,
                radius: 24,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: UserAvatar(
                      user: profile,
                      size: 34,
                      borderColor: GacColors.white,
                      borderWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InboxBody extends StatelessWidget {
  const _InboxBody({
    required this.controller,
    required this.selectedTab,
    required this.selectedFilter,
    required this.onTabChanged,
    required this.onFilterChanged,
    required this.onRetry,
    required this.onMarkAllRead,
    required this.onOpenNotification,
  });

  final UserNotificationController controller;
  final NotificationTab selectedTab;
  final NotificationCategoryFilter selectedFilter;
  final ValueChanged<NotificationTab> onTabChanged;
  final ValueChanged<NotificationCategoryFilter> onFilterChanged;
  final VoidCallback onRetry;
  final VoidCallback onMarkAllRead;
  final ValueChanged<UserNotification> onOpenNotification;

  @override
  Widget build(BuildContext context) {
    if (controller.loading && !controller.initialized) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TitleRow(unreadCount: 0, onMarkAllRead: onMarkAllRead),
          const _LoadingInbox(),
        ],
      );
    }
    if (controller.error != null && controller.notifications.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TitleRow(unreadCount: 0, onMarkAllRead: onMarkAllRead),
          const SizedBox(height: 18),
          _ErrorInbox(message: controller.error!, onRetry: onRetry),
        ],
      );
    }

    final recentNotifications = <UserNotification>[];
    final historyNotifications = <UserNotification>[];

    for (final notification in controller.notifications) {
      if (notification.unread) {
        recentNotifications.add(notification);
      } else {
        historyNotifications.add(notification);
      }
    }

    final tabNotifications = selectedTab == NotificationTab.recent
        ? recentNotifications
        : historyNotifications;

    final displayNotifications = tabNotifications.where((notification) {
      switch (selectedFilter) {
        case NotificationCategoryFilter.all:
          return true;
        case NotificationCategoryFilter.notices:
          return notification.isNotice;
        case NotificationCategoryFilter.followUps:
          return notification.isFollowUp;
      }
    }).toList(growable: false);

    final today = <UserNotification>[];
    final earlier = <UserNotification>[];
    final now = DateTime.now();
    for (final notification in displayNotifications) {
      if (notification.createdAt != null &&
          DateUtils.isSameDay(notification.createdAt, now)) {
        today.add(notification);
      } else {
        earlier.add(notification);
      }
    }

    final allCount = tabNotifications.length;
    final noticesCount = tabNotifications.where((n) => n.isNotice).length;
    final followUpsCount = tabNotifications.where((n) => n.isFollowUp).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TitleRow(
          unreadCount: selectedTab == NotificationTab.recent
              ? controller.unreadCount
              : 0,
          onMarkAllRead: onMarkAllRead,
        ),
        const SizedBox(height: 16),
        _NotificationTabSwitcher(
          selectedTab: selectedTab,
          onChanged: onTabChanged,
          recentCount: recentNotifications.length,
          historyCount: historyNotifications.length,
        ),
        const SizedBox(height: 12),
        _NotificationCategoryFilterBar(
          selectedFilter: selectedFilter,
          onFilterChanged: onFilterChanged,
          allCount: allCount,
          noticesCount: noticesCount,
          followUpsCount: followUpsCount,
        ),
        const SizedBox(height: 16),
        if (selectedTab == NotificationTab.recent) ...[
          _SummaryCard(
            unreadCount: recentNotifications.length,
            totalCount: controller.notifications.length,
          ),
          if (recentNotifications.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (displayNotifications.isEmpty)
              _EmptyFilteredNotifications(
                filter: selectedFilter,
                tab: NotificationTab.recent,
              )
            else ...[
              if (today.isNotEmpty) ...[
                const _SectionLabel('TODAY'),
                const SizedBox(height: 8),
                _NotificationGroup(
                  notifications: today,
                  onOpen: onOpenNotification,
                ),
              ],
              if (earlier.isNotEmpty) ...[
                if (today.isNotEmpty) const SizedBox(height: 18),
                const _SectionLabel('EARLIER'),
                const SizedBox(height: 8),
                _NotificationGroup(
                  notifications: earlier,
                  onOpen: onOpenNotification,
                ),
              ],
            ],
          ],
        ] else ...[
          if (historyNotifications.isEmpty)
            const _EmptyHistory()
          else if (displayNotifications.isEmpty)
            _EmptyFilteredNotifications(
              filter: selectedFilter,
              tab: NotificationTab.history,
            )
          else ...[
            if (today.isNotEmpty) ...[
              const _SectionLabel('TODAY'),
              const SizedBox(height: 8),
              _NotificationGroup(
                notifications: today,
                onOpen: onOpenNotification,
              ),
            ],
            if (earlier.isNotEmpty) ...[
              if (today.isNotEmpty) const SizedBox(height: 18),
              const _SectionLabel('EARLIER'),
              const SizedBox(height: 8),
              _NotificationGroup(
                notifications: earlier,
                onOpen: onOpenNotification,
              ),
            ],
          ],
        ],
      ],
    );
  }
}

class _NotificationTabSwitcher extends StatelessWidget {
  const _NotificationTabSwitcher({
    required this.selectedTab,
    required this.onChanged,
    required this.recentCount,
    required this.historyCount,
  });

  final NotificationTab selectedTab;
  final ValueChanged<NotificationTab> onChanged;
  final int recentCount;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    return GacGlassSurface(
      height: 48,
      padding: const EdgeInsets.all(4),
      borderRadius: 16,
      color: GacColors.navy950.withValues(alpha: 0.94),
      borderColor: GacColors.navy700,
      shadowBlurRadius: 16,
      shadowOffset: const Offset(0, 4),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              key: const ValueKey('tab-recent'),
              title: 'Recent',
              icon: Icons.notifications_none_rounded,
              badgeCount: recentCount,
              isSelected: selectedTab == NotificationTab.recent,
              onTap: () => onChanged(NotificationTab.recent),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              key: const ValueKey('tab-history'),
              title: 'History',
              icon: Icons.history_rounded,
              badgeCount: historyCount,
              isSelected: selectedTab == NotificationTab.history,
              onTap: () => onChanged(NotificationTab.history),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCategoryFilterBar extends StatelessWidget {
  const _NotificationCategoryFilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.allCount,
    required this.noticesCount,
    required this.followUpsCount,
  });

  final NotificationCategoryFilter selectedFilter;
  final ValueChanged<NotificationCategoryFilter> onFilterChanged;
  final int allCount;
  final int noticesCount;
  final int followUpsCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _NotificationFilterChip(
            key: const ValueKey('filter-all'),
            label: 'All',
            count: allCount,
            icon: Icons.all_inbox_rounded,
            selected: selectedFilter == NotificationCategoryFilter.all,
            onTap: () => onFilterChanged(NotificationCategoryFilter.all),
          ),
          const SizedBox(width: 8),
          _NotificationFilterChip(
            key: const ValueKey('filter-notices'),
            label: 'Notices',
            count: noticesCount,
            icon: Icons.notifications_none_rounded,
            selected: selectedFilter == NotificationCategoryFilter.notices,
            onTap: () => onFilterChanged(NotificationCategoryFilter.notices),
          ),
          const SizedBox(width: 8),
          _NotificationFilterChip(
            key: const ValueKey('filter-follow-ups'),
            label: 'Follow-ups',
            count: followUpsCount,
            icon: Icons.reply_rounded,
            selected: selectedFilter == NotificationCategoryFilter.followUps,
            onTap: () => onFilterChanged(NotificationCategoryFilter.followUps),
          ),
        ],
      ),
    );
  }
}

class _NotificationFilterChip extends StatelessWidget {
  const _NotificationFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Filter $label, $count notifications',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? GacColors.primary.withValues(alpha: 0.22)
                  : GacColors.navy950.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? GacColors.primary : GacColors.navy700,
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 13,
                    color: selected ? GacColors.cyan : GacColors.slate,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? GacColors.white : GacColors.textSecondary,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? GacColors.primary : GacColors.navy800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: TextStyle(
                      color: selected ? GacColors.white : GacColors.mist,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
    super.key,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? GacColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x402979FF),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? GacColors.white : GacColors.slate,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? GacColors.white : GacColors.slate,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? GacColors.white.withValues(alpha: 0.25)
                        : GacColors.navy800,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: TextStyle(
                      color: isSelected ? GacColors.white : GacColors.mist,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.unreadCount, required this.onMarkAllRead});

  final int unreadCount;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UPDATES',
              style: TextStyle(
                color: GacColors.cyan,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.7,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Notifications',
              style: TextStyle(
                color: GacColors.textPrimary,
                fontSize: 29,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
          ],
        ),
      ),
      if (unreadCount > 0)
        TextButton(
          key: const ValueKey('mark-all-notifications-read'),
          onPressed: onMarkAllRead,
          child: const Text('Mark all read'),
        ),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.unreadCount, required this.totalCount});

  final int unreadCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final title = unreadCount == 0
        ? 'You’re all caught up'
        : '$unreadCount unread ${unreadCount == 1 ? 'update' : 'updates'}';
    final message = totalCount == 0
        ? 'Task and review updates will appear here.'
        : unreadCount == 0
        ? 'You have reviewed every notification.'
        : 'Open an update to mark it as read.';
    return GacGlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      color: GacColors.navy950.withValues(alpha: 0.94),
      borderColor: GacColors.navy700,
      shadowBlurRadius: 24,
      shadowOffset: const Offset(0, 10),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unreadCount > 0 ? GacColors.primary : GacColors.green600,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              unreadCount > 0
                  ? Icons.notifications_rounded
                  : Icons.done_all_rounded,
              size: 20,
              color: GacColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: GacColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: GacColors.mist, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: GacColors.slate,
      fontSize: 8,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.25,
    ),
  );
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({required this.notifications, required this.onOpen});

  final List<UserNotification> notifications;
  final ValueChanged<UserNotification> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < notifications.length; index++) ...[
        _NotificationCard(
          notification: notifications[index],
          onTap: () => onOpen(notifications[index]),
        ),
        if (index != notifications.length - 1) const SizedBox(height: 9),
      ],
    ],
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final UserNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GacContentPanel(
    color: notification.unread
        ? const Color(0xFF0E223D)
        : const Color(0xFF0A1628),
    borderColor: notification.unread
        ? const Color(0xFF1A3A5C)
        : const Color(0xFF122238),
    borderRadius: 19,
    shadowBlurRadius: notification.unread ? 16 : 9,
    shadowOffset: const Offset(0, 5),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            if (notification.unread)
              const Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: SizedBox(
                  width: 4,
                  child: ColoredBox(color: GacColors.primary),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                notification.unread ? 19 : 15,
                15,
                15,
                15,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _toneFor(notification.type),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _iconFor(notification.type),
                      size: 20,
                      color: GacColors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: const TextStyle(
                                  color: GacColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (notification.unread)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: SizedBox.square(
                                  dimension: 7,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: GacColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (notification.message.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            notification.message,
                            style: const TextStyle(
                              color: GacColors.textSecondary,
                              fontSize: 10,
                              height: 1.45,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (notification.isUtilitiesInspectionNotice) ...[
                          const Text(
                            'Open Utilities inspection',
                            style: TextStyle(
                              color: GacColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (notification.type ==
                            'checklist_draft_reminder') ...[
                          const Text(
                            'Resume drafted checklist →',
                            style: TextStyle(
                              color: GacColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (notification.type == 'finding_escalated') ...[
                          if (notification.isFollowedUp) ...[
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: GacColors.green200,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Follow-up submitted',
                                  style: TextStyle(
                                    color: GacColors.green200,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ] else ...[
                            const Row(
                              children: [
                                Icon(
                                  Icons.reply_rounded,
                                  size: 13,
                                  color: GacColors.amber200,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Follow-up required →',
                                  style: TextStyle(
                                    color: GacColors.amber200,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                        Text(
                          _formatTimestamp(notification.createdAt),
                          style: const TextStyle(
                            color: GacColors.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => GacContentPanel(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
    borderRadius: 20,
    child: const Column(
      children: [
        Icon(Icons.history_rounded, size: 36, color: GacColors.slate),
        SizedBox(height: 12),
        Text(
          'No notification history',
          style: TextStyle(
            color: GacColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Previously viewed updates will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: GacColors.slate, fontSize: 10, height: 1.4),
        ),
      ],
    ),
  );
}

class _EmptyFilteredNotifications extends StatelessWidget {
  const _EmptyFilteredNotifications({
    required this.filter,
    required this.tab,
  });

  final NotificationCategoryFilter filter;
  final NotificationTab tab;

  @override
  Widget build(BuildContext context) {
    final isFollowUps = filter == NotificationCategoryFilter.followUps;
    final isRecent = tab == NotificationTab.recent;
    final title = isFollowUps
        ? (isRecent ? 'No unread follow-ups' : 'No follow-up history')
        : (isRecent ? 'No unread notices' : 'No notice history');
    final message = isFollowUps
        ? (isRecent
            ? 'When a manager escalates a checklist finding, it will appear here.'
            : 'Previously reviewed follow-ups and escalations will appear here.')
        : (isRecent
            ? 'Draft reminders and general notifications will appear here.'
            : 'Previously viewed notices will appear here.');
    final icon = isFollowUps
        ? Icons.reply_rounded
        : Icons.notifications_none_rounded;

    return GacContentPanel(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      borderRadius: 20,
      child: Column(
        children: [
          Icon(icon, size: 36, color: GacColors.slate),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: GacColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GacColors.slate,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingInbox extends StatelessWidget {
  const _LoadingInbox();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 80),
    child: Column(
      children: [
        Icon(Icons.sync_rounded, size: 32, color: GacColors.slate),
        SizedBox(height: 10),
        Text(
          'Loading updates…',
          style: TextStyle(color: GacColors.slate, fontSize: 10),
        ),
      ],
    ),
  );
}

class _ErrorInbox extends StatelessWidget {
  const _ErrorInbox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => GacContentPanel(
    padding: const EdgeInsets.all(24),
    borderRadius: 20,
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, size: 34, color: GacColors.primary),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: GacColors.steel, fontSize: 11),
        ),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

IconData _iconFor(String type) {
  final value = type.toLowerCase();
  if (value.contains('completed') || value.contains('accepted')) {
    return Icons.task_alt_rounded;
  }
  if (value.contains('assigned')) return Icons.assignment_rounded;
  if (value.contains('missed')) return Icons.warning_amber_rounded;
  if (value.contains('warning') || value.contains('finding')) {
    return Icons.error_outline_rounded;
  }
  if (value.contains('reminder') || value.contains('due')) {
    return Icons.schedule_rounded;
  }
  return Icons.notifications_none_rounded;
}

Color _toneFor(String type) {
  final value = type.toLowerCase();
  if (value.contains('completed') || value.contains('accepted')) {
    return GacColors.green600;
  }
  if (value.contains('warning') || value.contains('finding') ||
      value.contains('missed')) {
    return GacColors.brandRed;
  }
  return GacColors.navy800;
}

String _formatTimestamp(DateTime? timestamp) {
  if (timestamp == null) return 'Recently';
  final now = DateTime.now();
  final difference = now.difference(timestamp);
  if (!difference.isNegative && difference.inMinutes < 1) return 'Just now';
  if (!difference.isNegative && difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }
  if (!difference.isNegative && difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }
  if (DateUtils.isSameDay(timestamp, now.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
}
