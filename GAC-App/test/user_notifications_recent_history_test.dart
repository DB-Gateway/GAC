import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/user_notification.dart';
import 'package:gac_flutter/screens/user_notifications_screen.dart';
import 'package:gac_flutter/services/notification_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

class _FakeInboxRepo implements NotificationRepository {
  _FakeInboxRepo({List<UserNotification>? initial})
      : notifications = initial != null ? List.of(initial) : [];

  List<UserNotification> notifications;

  @override
  Future<NotificationInbox> fetchNotifications() async {
    return NotificationInbox(
      notifications: List.unmodifiable(notifications),
      unreadCount: notifications.where((n) => n.unread).length,
    );
  }

  @override
  Future<NotificationInbox> markRead(String id) async {
    notifications = [
      for (final n in notifications)
        if (n.id == id) n.markRead() else n,
    ];
    return fetchNotifications();
  }

  @override
  Future<int> markAllRead() async {
    notifications = notifications.map((n) => n.markRead()).toList();
    return 0;
  }
}

Widget _buildScreen(UserNotificationController controller) {
  return MaterialApp(
    theme: GacTheme.light,
    home: UserNotificationsScreen(
      onOpenProfile: () {},
      onGoHome: () {},
      onOpenSettings: () {},
      controller: controller,
      profile: const AuthenticatedUser(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        userType: '5S_SALES',
        accountStatus: 'active',
        branch: 'Pasong Tamo',
      ),
    ),
  );
}

void main() {
  testWidgets(
    'shows You are all caught up when Recent has no notifications, and History shows previous notifications',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final readNotification = UserNotification(
        id: 'notif-1',
        type: 'checklist_draft_reminder',
        title: 'Finish your drafted checklist',
        message: 'Resume at question #1',
        unread: false,
        data: const {},
        createdAt: DateTime.now(),
      );

      final repo = _FakeInboxRepo(initial: [readNotification]);
      final controller = UserNotificationController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      await tester.pumpWidget(_buildScreen(controller));
      await tester.pumpAndSettle();

      // Recent tab is selected by default.
      // Since unread count is 0, Recent shows 'You’re all caught up'.
      expect(find.text('You’re all caught up'), findsOneWidget);
      // And the read notification is NOT in Recent!
      expect(find.text('Finish your drafted checklist'), findsNothing);

      // Switch to History tab.
      await tester.tap(find.byKey(const ValueKey('tab-history')));
      await tester.pumpAndSettle();

      // In History: the previous notification IS visible!
      expect(find.text('Finish your drafted checklist'), findsOneWidget);
      // And in History: 'You’re all caught up' is NOT shown!
      expect(find.text('You’re all caught up'), findsNothing);
    },
  );

  testWidgets(
    'incoming unread notification shows in Recent, marks all read, moves to History',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final unreadNotification = UserNotification(
        id: 'notif-2',
        type: 'task_assigned',
        title: 'New assignment',
        message: 'You have a new checklist.',
        unread: true,
        data: const {},
        createdAt: DateTime.now(),
      );

      final repo = _FakeInboxRepo(initial: [unreadNotification]);
      final controller = UserNotificationController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      await tester.pumpWidget(_buildScreen(controller));
      await tester.pumpAndSettle();

      // Recent shows unread notification and '1 unread update'
      expect(find.text('New assignment'), findsOneWidget);
      expect(find.text('1 unread update'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
      // 'You’re all caught up' is NOT shown!
      expect(find.text('You’re all caught up'), findsNothing);

      // Tap Mark all read
      await tester.tap(find.byKey(const ValueKey('mark-all-notifications-read')));
      await tester.pumpAndSettle();

      // Now Recent is caught up!
      expect(find.text('You’re all caught up'), findsOneWidget);
      expect(find.text('New assignment'), findsNothing);

      // Switch to History tab: the notification is now in History!
      await tester.tap(find.byKey(const ValueKey('tab-history')));
      await tester.pumpAndSettle();

      expect(find.text('New assignment'), findsOneWidget);
      expect(find.text('You’re all caught up'), findsNothing);
    },
  );

  testWidgets('empty state when user has zero notifications', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeInboxRepo(initial: []);
    final controller = UserNotificationController(repository: repo);
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(_buildScreen(controller));
    await tester.pumpAndSettle();

    expect(find.text('You’re all caught up'), findsOneWidget);
    expect(find.text('Task and review updates will appear here.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-history')));
    await tester.pumpAndSettle();

    expect(find.text('No notification history'), findsOneWidget);
    expect(
      find.text('Previously viewed updates will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'filters notifications by category (all, notices, follow-ups) and shows follow-up status badges',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notice = UserNotification(
        id: 'notif-notice',
        type: 'checklist_draft_reminder',
        title: 'Resume drafted checklist',
        message: 'Draft at item 1',
        unread: true,
        data: const {},
        createdAt: DateTime.now(),
      );
      final followUpPending = UserNotification(
        id: 'notif-follow-up-1',
        type: 'finding_escalated',
        title: 'BOM escalated finding',
        message: 'Showroom signage damaged',
        unread: true,
        data: const {
          'question': 'Is signage ok?',
          'sender_name': 'Brenda BOM',
        },
        createdAt: DateTime.now(),
      );
      final followUpDone = UserNotification(
        id: 'notif-follow-up-2',
        type: 'finding_escalated',
        title: 'Completed escalation finding',
        message: 'Cleanliness finding',
        unread: true,
        data: const {
          'question': 'Is lobby clean?',
          'has_follow_up': true,
          'follow_up_recipient_name': 'Brenda BOM',
        },
        createdAt: DateTime.now(),
      );

      final repo = _FakeInboxRepo(
        initial: [notice, followUpPending, followUpDone],
      );
      final controller = UserNotificationController(repository: repo);
      addTearDown(controller.dispose);
      await controller.load();

      await tester.pumpWidget(_buildScreen(controller));
      await tester.pumpAndSettle();

      // Default is 'All' filter: all 3 items visible
      expect(find.text('Resume drafted checklist'), findsOneWidget);
      expect(find.text('BOM escalated finding'), findsOneWidget);
      expect(find.text('Completed escalation finding'), findsOneWidget);
      expect(find.text('Follow-up required →'), findsOneWidget);
      expect(find.text('Follow-up submitted'), findsOneWidget);

      // Filter chips show correct labels and counts
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('filter-all')),
          matching: find.text('All'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('filter-all')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('filter-notices')),
          matching: find.text('Notices'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('filter-notices')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('filter-follow-ups')),
          matching: find.text('Follow-ups'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('filter-follow-ups')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      // Filter by Notices
      await tester.tap(find.byKey(const ValueKey('filter-notices')));
      await tester.pumpAndSettle();

      expect(find.text('Resume drafted checklist'), findsOneWidget);
      expect(find.text('BOM escalated finding'), findsNothing);
      expect(find.text('Completed escalation finding'), findsNothing);

      // Filter by Follow-ups
      await tester.ensureVisible(find.byKey(const ValueKey('filter-follow-ups')));
      await tester.tap(find.byKey(const ValueKey('filter-follow-ups')));
      await tester.pumpAndSettle();

      expect(find.text('Resume drafted checklist'), findsNothing);
      expect(find.text('BOM escalated finding'), findsOneWidget);
      expect(find.text('Completed escalation finding'), findsOneWidget);

      // Switch back to All
      await tester.ensureVisible(find.byKey(const ValueKey('filter-all')));
      await tester.tap(find.byKey(const ValueKey('filter-all')));
      await tester.pumpAndSettle();

      expect(find.text('Resume drafted checklist'), findsOneWidget);
      expect(find.text('BOM escalated finding'), findsOneWidget);
      expect(find.text('Completed escalation finding'), findsOneWidget);
    },
  );
}
