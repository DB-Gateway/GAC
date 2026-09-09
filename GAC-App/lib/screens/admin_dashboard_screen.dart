import 'package:flutter/material.dart';

import '../admin/admin_destination.dart';
import '../data/admin_data.dart';
import '../models/user_notification.dart';
import '../services/notification_service.dart';
import '../theme/gac_theme.dart';
import '../widgets/admin_page.dart';
import '../widgets/admin_tabs_layout.dart';
import '../widgets/admin_ui.dart';

const _calendarDays = <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const _calendarCells = <int?>[
  null,
  null,
  null,
  null,
  null,
  null,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
  23,
  24,
  25,
  26,
  27,
  28,
  29,
  30,
  31,
  null,
  null,
  null,
  null,
  null,
];

const _quickActions = <_QuickAction>[
  _QuickAction(
    label: 'DOS Master Form',
    detail: 'Audit or edit 75 standards',
    icon: Icons.assignment_outlined,
    destination: AdminDestination.dos,
  ),
  _QuickAction(
    label: 'Daily 5S',
    detail: 'Audit or edit 56 items',
    icon: Icons.list_alt_outlined,
    destination: AdminDestination.fiveS,
  ),
  _QuickAction(
    label: 'Generate Report',
    detail: 'Review and share analytics',
    icon: Icons.description_outlined,
    destination: AdminDestination.reports,
  ),
  _QuickAction(
    label: 'User Management',
    detail: 'Manage 5S and BOM usage',
    icon: Icons.people_outline_rounded,
    destination: AdminDestination.users,
  ),
];

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    required this.onNavigate,
    this.controller,
    super.key,
  });

  final AdminNavigationCallback onNavigate;
  final UserNotificationController? controller;

  @override
  Widget build(BuildContext context) {
    final compactGrid = MediaQuery.sizeOf(context).width < 540;
    final notifController = controller ?? AdminNotificationScope.of(context);
    final unreadCount = notifController?.unreadCount ?? 0;
    final liveNotifications = notifController?.notifications ?? const [];

    return AdminPage(
      onNavigate: onNavigate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminPageHeading(
            eyebrow: 'General Manager workspace',
            title: 'Administrator Dashboard',
            description:
                'Monitor DOS and 5S compliance, review branch performance, '
                'manage findings, and oversee branch 5S and BOM operations from one '
                'mobile workspace.',
            action: AdminStatusPill(
              label: 'All systems active',
              tone: AdminStatusTone.dark,
            ),
          ),
          _MetricGrid(compact: compactGrid),
          if (unreadCount > 0) ...[
            const SizedBox(height: 12),
            _UnreadAlertsBanner(
              unreadCount: unreadCount,
              onReview: () => onNavigate(AdminDestination.notifications),
            ),
          ],
          const SizedBox(height: 16),
          _WelcomeCard(
            onOpenReports: () => onNavigate(AdminDestination.reports),
          ),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Analytics',
            title: 'Monthly Compliance Trend',
            detail: 'Dealer Operations Standards · March to August',
            action: AdminStatusPill(
              label: '92% current',
              tone: AdminStatusTone.dark,
            ),
          ),
          const AdminSurfaceCard(child: _MonthlyComplianceChart()),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'DOS Coverage',
            title: 'Compliance by Category',
            detail: 'The strongest and weakest operational areas this month',
          ),
          AdminSurfaceCard(child: _CategoryProgressList(items: dosCategories)),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Latest Updates',
            title: 'Recent Activities',
            detail: 'Submissions, approvals, and findings requiring oversight',
          ),
          _ActivityList(notifications: liveNotifications),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Current Month',
            title: 'Branch Compliance Ranking',
            detail: 'Combined DOS and 5S scores',
          ),
          const AdminSurfaceCard(child: _BranchRanking()),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Shortcuts',
            title: 'Quick Actions',
            detail: 'Open the administrator tools used most often',
          ),
          _QuickActionGrid(compact: compactGrid, onNavigate: onNavigate),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'August 2026',
            title: 'Audit Calendar',
            detail: 'The 10th is the current audit date',
          ),
          const AdminSurfaceCard(child: _AuditCalendar()),
          const SizedBox(height: 30),
          const Text(
            'Gateway Audit Compliance System · Administrator Mobile',
            textAlign: TextAlign.center,
            style: TextStyle(color: GacColors.muted, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * (compact ? 0.48 : 0.235);
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 10,
          spacing: 10,
          children: [
            SizedBox(
              width: width,
              child: const AdminMetricCard(
                label: 'Overall Compliance',
                value: '92%',
                detail: 'Current monthly performance',
                progress: 92,
                icon: Icons.speed_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: const AdminMetricCard(
                label: 'DOS Audits Completed',
                value: '28',
                detail: 'Completed this month',
                progress: 85,
                icon: Icons.done_all_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: const AdminMetricCard(
                label: 'Pending Audits',
                value: '4',
                detail: 'Waiting for 5S submission',
                progress: 30,
                icon: Icons.schedule_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: const AdminMetricCard(
                label: 'Critical Findings',
                value: '9',
                detail: 'Items marked NO or N/A',
                progress: 40,
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onOpenReports});

  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(18),
      color: GacColors.black,
      borderColor: GacColors.black,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GATEWAY AUDIT COMPLIANCE',
                  style: TextStyle(
                    color: GacColors.muted,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Compliance oversight, built for action.',
                  style: TextStyle(
                    color: GacColors.white,
                    fontSize: 19,
                    height: 23 / 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Review monthly audits, edit master checklists, monitor daily '
                  '5S completion, and track branch activity from your phone.',
                  style: TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 9,
                    height: 14 / 9,
                  ),
                ),
                const SizedBox(height: 13),
                _PressableScale(
                  onTap: onOpenReports,
                  semanticsLabel: 'Open reports',
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: GacColors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'OPEN REPORTS',
                          style: TextStyle(
                            color: GacColors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 17,
                          color: GacColors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GacColors.charcoal,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF343434)),
            ),
            child: Image.asset(
              'assets/images/G-logo-no-bg.png',
              width: 54,
              height: 54,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                'G',
                style: TextStyle(
                  color: GacColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyComplianceChart extends StatelessWidget {
  const _MonthlyComplianceChart();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Monthly overall compliance: March 81, April 84, May 87, June 89, '
          'July 91, August 92 percent.',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 172,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var index = 0; index < monthlyCompliance.length; index++)
                    SizedBox(
                      width: constraints.maxWidth * 0.14,
                      height: 172,
                      child: _ChartColumn(
                        month: monthlyCompliance[index],
                        current: index == monthlyCompliance.length - 1,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChartColumn extends StatelessWidget {
  const _ChartColumn({required this.month, required this.current});

  final ComplianceMonth month;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${month.overall}%',
          style: const TextStyle(
            color: GacColors.gray,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 27,
            height: 125,
            child: ColoredBox(
              color: GacColors.lightGray,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: month.overall / 100,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: current
                          ? GacColors.primary
                          : const Color(0xFFCAD8ED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          month.month,
          style: TextStyle(
            color: current ? GacColors.primary : GacColors.muted,
            fontSize: 9,
            fontWeight: current ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _CategoryProgressList extends StatelessWidget {
  const _CategoryProgressList({required this.items});

  final List<ProgressMetric> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: index == 0
                ? null
                : const BoxDecoration(
                    border: Border(top: BorderSide(color: GacColors.lightGray)),
                  ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[index].label,
                            style: const TextStyle(
                              color: GacColors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (items[index].detail != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              items[index].detail!,
                              style: const TextStyle(
                                color: GacColors.gray,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${items[index].value}%',
                      style: const TextStyle(
                        color: GacColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                AdminProgressBar(
                  value: items[index].value.toDouble(),
                  fillColor: GacColors.success,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({this.notifications = const []});

  final List<UserNotification> notifications;

  @override
  Widget build(BuildContext context) {
    if (notifications.isNotEmpty) {
      final items = notifications.take(4).toList(growable: false);
      return Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const SizedBox(height: 9),
            _buildNotificationCard(items[index]),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (var index = 0; index < recentActivities.length; index++) ...[
          if (index > 0) const SizedBox(height: 9),
          AdminSurfaceCard(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 11),
                  decoration: BoxDecoration(
                    color: GacColors.black,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _activityIcon(recentActivities[index].status),
                    size: 19,
                    color: GacColors.white,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recentActivities[index].user,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: GacColors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AdminStatusPill(
                            label: recentActivities[index].status,
                            tone: _activityTone(recentActivities[index].status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recentActivities[index].action,
                        style: const TextStyle(
                          color: GacColors.gray,
                          fontSize: 9,
                          height: 14 / 9,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recentActivities[index].time,
                        style: const TextStyle(
                          color: GacColors.muted,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationCard(UserNotification notification) {
    final data = notification.data;
    final userName = data['completed_by_name'] as String? ??
        (data['user_name'] as String? ?? 'Audit Staff');
    final findingCount = (data['finding_count'] as num?)?.toInt() ?? 0;
    final status = findingCount > 0
        ? 'Flagged'
        : (notification.type.contains('pending') ? 'Pending' : 'Completed');
    final timeStr = _formatTimestamp(notification.createdAt);

    return AdminSurfaceCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 11),
            decoration: BoxDecoration(
              color: GacColors.black,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _activityIcon(status),
              size: 19,
              color: GacColors.white,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: GacColors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AdminStatusPill(
                      label: status,
                      tone: _activityTone(status),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message.isNotEmpty
                      ? notification.message
                      : notification.title,
                  style: const TextStyle(
                    color: GacColors.gray,
                    fontSize: 9,
                    height: 14 / 9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: GacColors.muted,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static AdminStatusTone _activityTone(String status) {
    if (status == 'Completed' || status == 'Approved') {
      return AdminStatusTone.success;
    }
    if (status == 'Pending') return AdminStatusTone.warning;
    return AdminStatusTone.danger;
  }

  static IconData _activityIcon(String status) {
    if (status == 'Flagged') return Icons.warning_amber_rounded;
    if (status == 'Pending') return Icons.schedule_rounded;
    return Icons.check_rounded;
  }
}

class _UnreadAlertsBanner extends StatelessWidget {
  const _UnreadAlertsBanner({
    required this.unreadCount,
    required this.onReview,
  });

  final int unreadCount;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: const Color(0xFF161F2E),
      borderColor: GacColors.primary,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GacColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 18,
              color: GacColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unreadCount New Audit Alert${unreadCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: GacColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Recent 5S and BOM submissions require oversight.',
                  style: TextStyle(
                    color: GacColors.muted,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PressableScale(
            onTap: onReview,
            semanticsLabel: 'Review administrator alerts',
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: GacColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'REVIEW',
                style: TextStyle(
                  color: GacColors.black,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
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
    'Dec'
  ];
  return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
}

class _BranchRanking extends StatelessWidget {
  const _BranchRanking();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < branches.length; index++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: index == 0
                ? null
                : const BoxDecoration(
                    border: Border(top: BorderSide(color: GacColors.lightGray)),
                  ),
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 11),
                  decoration: BoxDecoration(
                    color: GacColors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${branches[index].rank}',
                    style: const TextStyle(
                      color: GacColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branches[index].branch,
                          style: const TextStyle(
                            color: GacColors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'DOS ${branches[index].dos}% · '
                          '5S ${branches[index].fiveS}%',
                          style: const TextStyle(
                            color: GacColors.gray,
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(height: 7),
                        AdminProgressBar(
                          value: branches[index].compliance.toDouble(),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${branches[index].compliance}%',
                      style: const TextStyle(
                        color: GacColors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      branches[index].status.toUpperCase(),
                      style: const TextStyle(
                        color: GacColors.gray,
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.compact, required this.onNavigate});

  final bool compact;
  final AdminNavigationCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * (compact ? 0.48 : 0.235);
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 10,
          spacing: 10,
          children: [
            for (final action in _quickActions)
              SizedBox(
                width: width,
                child: _PressableScale(
                  onTap: () => onNavigate(action.destination),
                  semanticsLabel: action.label,
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 154),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: GacColors.white,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: GacColors.lightGray),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: GacColors.black,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            action.icon,
                            size: 21,
                            color: GacColors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          action.label,
                          style: const TextStyle(
                            color: GacColors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action.detail,
                          style: const TextStyle(
                            color: GacColors.gray,
                            fontSize: 8,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 17,
                          color: GacColors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AuditCalendar extends StatelessWidget {
  const _AuditCalendar();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'August 2026 audit calendar. August 10 is the current audit date.',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / 7;
            return Wrap(
              children: [
                for (final day in _calendarDays)
                  SizedBox(
                    width: cellWidth,
                    height: 39,
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: GacColors.gray,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                for (final date in _calendarCells)
                  SizedBox(
                    width: cellWidth,
                    height: 39,
                    child: date == null
                        ? null
                        : Center(
                            child: Container(
                              width: 31,
                              height: 31,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: date == 10
                                    ? GacColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$date',
                                style: TextStyle(
                                  color: date == 10
                                      ? GacColors.white
                                      : GacColors.black,
                                  fontSize: 10,
                                  fontWeight: date == 10
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.detail,
    required this.icon,
    required this.destination,
  });

  final String label;
  final String detail;
  final IconData icon;
  final AdminDestination destination;
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.onTap,
    required this.semanticsLabel,
    required this.borderRadius,
    required this.child,
  });

  final VoidCallback onTap;
  final String semanticsLabel;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) {
            if (_pressed == pressed) return;
            setState(() => _pressed = pressed);
          },
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: AnimatedOpacity(
            opacity: _pressed ? 0.8 : 1,
            duration: const Duration(milliseconds: 90),
            child: AnimatedScale(
              scale: _pressed ? 0.99 : 1,
              duration: const Duration(milliseconds: 90),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
