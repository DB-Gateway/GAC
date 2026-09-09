import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/authenticated_user.dart';
import '../models/user_notification.dart';
import '../services/notification_service.dart';
import '../theme/gac_theme.dart';
import '../widgets/gac_surfaces.dart';
import '../widgets/user_avatar.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({
    required this.onOpenProfile,
    required this.onGoHome,
    required this.onOpenSettings,
    this.profile = AuthenticatedUser.fallback,
    this.controller,
    this.onOpenNotification,
    super.key,
  });

  final VoidCallback onOpenProfile;
  final VoidCallback onGoHome;
  final VoidCallback onOpenSettings;
  final AuthenticatedUser profile;
  final UserNotificationController? controller;
  final ValueChanged<String>? onOpenNotification;

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  late UserNotificationController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? UserNotificationController();
    _ownsController = widget.controller == null;
    if (!_controller.initialized) unawaited(_controller.load());
  }

  @override
  void didUpdateWidget(covariant UserNotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    if (_ownsController) _controller.dispose();
    _controller = widget.controller ?? UserNotificationController();
    _ownsController = widget.controller == null;
    if (!_controller.initialized) unawaited(_controller.load());
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
    try {
      await _controller.markRead(notification.id);
    } on NotificationApiException catch (error) {
      if (mounted) _showError(error.message);
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
        child: SafeArea(
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
    required this.onRetry,
    required this.onMarkAllRead,
    required this.onOpenNotification,
  });

  final UserNotificationController controller;
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

    final today = <UserNotification>[];
    final earlier = <UserNotification>[];
    final now = DateTime.now();
    for (final notification in controller.notifications) {
      if (notification.createdAt != null &&
          DateUtils.isSameDay(notification.createdAt, now)) {
        today.add(notification);
      } else {
        earlier.add(notification);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TitleRow(
          unreadCount: controller.unreadCount,
          onMarkAllRead: onMarkAllRead,
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          unreadCount: controller.unreadCount,
          totalCount: controller.notifications.length,
        ),
        const SizedBox(height: 16),
        if (controller.notifications.isEmpty)
          const _EmptyInbox()
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
    color: notification.unread ? const Color(0xFF0E223D) : const Color(0xFF0A1628),
    borderColor: notification.unread ? const Color(0xFF1A3A5C) : const Color(0xFF122238),
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

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) => GacContentPanel(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
    borderRadius: 20,
    child: const Column(
      children: [
        Icon(
          Icons.notifications_off_outlined,
          size: 36,
          color: GacColors.slate,
        ),
        SizedBox(height: 12),
        Text(
          'No notifications yet',
          style: TextStyle(
            color: GacColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Updates about your Gateway tasks will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: GacColors.slate, fontSize: 10, height: 1.4),
        ),
      ],
    ),
  );
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
  if (value.contains('warning') || value.contains('finding')) {
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
