import 'dart:async';

import 'package:flutter/material.dart';

import '../admin/admin_destination.dart';
import '../models/user_notification.dart';
import '../services/notification_service.dart';
import '../theme/gac_theme.dart';
import '../widgets/admin_page.dart';
import '../widgets/admin_ui.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({
    required this.onNavigate,
    this.controller,
    super.key,
  });

  final AdminNavigationCallback onNavigate;
  final UserNotificationController? controller;

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late UserNotificationController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? UserNotificationController();
    _ownsController = widget.controller == null;
    if (!_controller.initialized) {
      unawaited(_controller.load());
    }
  }

  @override
  void didUpdateWidget(covariant AdminNotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    if (_ownsController) _controller.dispose();
    _controller = widget.controller ?? UserNotificationController();
    _ownsController = widget.controller == null;
    if (!_controller.initialized) {
      unawaited(_controller.load());
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _markAllRead() async {
    try {
      await _controller.markAllRead();
    } on NotificationApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Could not mark all notifications as read.');
    }
  }

  Future<void> _handleAlertTap(UserNotification notification) async {
    if (notification.unread) {
      try {
        await _controller.markRead(notification.id);
      } on NotificationApiException catch (error) {
        if (mounted) _showError(error.message);
      } catch (_) {
        // Continue navigation even if marking read hits network issue
      }
    }

    final data = notification.data;
    final slug = (data['template_slug'] as String? ?? '').toLowerCase();
    if (slug.contains('dos') || slug.contains('dealer-operations')) {
      widget.onNavigate(AdminDestination.dos);
    } else if (slug.contains('5s') ||
        slug.contains('restroom') ||
        slug.contains('sales') ||
        slug.contains('service')) {
      widget.onNavigate(AdminDestination.fiveS);
    } else if (data.containsKey('submission_id')) {
      widget.onNavigate(AdminDestination.reports);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: GacColors.black),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final notifications = _controller.notifications;
        final unreadCount = _controller.unreadCount;

        return AdminPage(
          onNavigate: widget.onNavigate,
          child: RefreshIndicator(
            color: GacColors.primary,
            onRefresh: () => _controller.load(showSpinner: false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminPageHeading(
                  eyebrow: 'Administrator oversight',
                  title: 'Notifications',
                  description:
                      'Overdue audits, missing 5S work, critical findings, '
                      'and checklist decisions that need General Manager attention.',
                  action: unreadCount > 0
                      ? Semantics(
                          button: true,
                          label: 'Mark all administrator alerts read',
                          child: InkWell(
                            onTap: _markAllRead,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'MARK ALL READ',
                                style: TextStyle(
                                  color: GacColors.black,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                AdminSurfaceCard(
                  margin: const EdgeInsets.only(bottom: 13),
                  color: GacColors.black,
                  borderColor: GacColors.black,
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: GacColors.darkGray,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          size: 22,
                          color: GacColors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$unreadCount unread ${unreadCount == 1 ? 'alert' : 'alerts'}',
                              style: const TextStyle(
                                color: GacColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              unreadCount > 0
                                  ? 'Administrator actions are waiting for review.'
                                  : 'All administrator alerts have been reviewed.',
                              style: const TextStyle(
                                color: GacColors.muted,
                                fontSize: 9,
                                height: 13 / 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_controller.loading && !_controller.initialized) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: GacColors.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ] else if (_controller.error != null &&
                    notifications.isEmpty) ...[
                  AdminSurfaceCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 32,
                          color: GacColors.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _controller.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: GacColors.gray,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _controller.load(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ] else if (notifications.isEmpty) ...[
                  const AdminSurfaceCard(
                    padding: EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 36,
                          color: GacColors.muted,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No alerts right now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: GacColors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Checklist completions, DOS audits, and critical findings will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, color: GacColors.gray),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  for (
                    var index = 0;
                    index < notifications.length;
                    index++
                  ) ...[
                    _AlertCard(
                      notification: notifications[index],
                      unread: notifications[index].unread,
                      onTap: () => _handleAlertTap(notifications[index]),
                    ),
                    if (index != notifications.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.notification,
    required this.unread,
    required this.onTap,
  });

  final UserNotification notification;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = notification.data;
    final findingCount = (data['finding_count'] as num?)?.toInt() ?? 0;
    final typeLower = notification.type.toLowerCase();

    final String typeLabel;
    final AdminStatusTone tone;
    final IconData icon;

    if (findingCount > 0 || typeLower.contains('finding')) {
      typeLabel = findingCount > 0
          ? '$findingCount Finding${findingCount > 1 ? 's' : ''}'
          : 'Finding';
      tone = AdminStatusTone.danger;
      icon = Icons.warning_amber_rounded;
    } else if (typeLower.contains('dos') || typeLower.contains('audit')) {
      typeLabel = 'DOS Audit';
      tone = AdminStatusTone.dark;
      icon = Icons.assignment_turned_in_outlined;
    } else if (typeLower.contains('completed')) {
      typeLabel = 'Completed';
      tone = AdminStatusTone.success;
      icon = Icons.check_circle_outline_rounded;
    } else if (typeLower.contains('approval')) {
      typeLabel = 'Approval';
      tone = AdminStatusTone.warning;
      icon = Icons.description_outlined;
    } else {
      typeLabel = 'Alert';
      tone = AdminStatusTone.dark;
      icon = Icons.access_time_rounded;
    }

    final formattedTime = _formatTimestamp(notification.createdAt);

    return Semantics(
      button: true,
      label:
          '${notification.title}. ${unread ? 'Unread.' : 'Read.'} ${notification.message}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Ink(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: GacColors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: unread ? GacColors.primary : GacColors.lightGray,
                width: unread ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: GacColors.black,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, size: 20, color: GacColors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    notification.title,
                                    style: const TextStyle(
                                      color: GacColors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (unread) ...[
                                  const SizedBox(width: 7),
                                  const SizedBox.square(
                                    dimension: 7,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: GacColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                color: GacColors.muted,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AdminStatusPill(label: typeLabel, tone: tone),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.message,
                  style: const TextStyle(
                    color: GacColors.gray,
                    fontSize: 9,
                    height: 14 / 9,
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
