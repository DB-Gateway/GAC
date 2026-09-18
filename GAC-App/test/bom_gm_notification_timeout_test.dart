import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/config/api_config.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/user_notification.dart';
import 'package:gac_flutter/services/local_notification_service.dart';
import 'package:gac_flutter/services/notification_service.dart';
import 'package:gac_flutter/services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SessionManager.instance.stopTracking();
    SessionManager.instance.resetTimeout();
    SessionManager.instance.onTimeout = null;
    LocalNotificationService.instance.stopTimedOutManagerNotificationPolling();
  });

  tearDown(() {
    SessionManager.instance.stopTracking();
    SessionManager.instance.resetTimeout();
    SessionManager.instance.onTimeout = null;
    LocalNotificationService.instance.stopTimedOutManagerNotificationPolling();
  });

  group('UserNotification.isFromBomOrGm', () {
    test('identifies checklist_draft_reminder as a BOM/GM notification', () {
      const notification = UserNotification(
        id: 'note-1',
        type: 'checklist_draft_reminder',
        title: 'Finish your drafted checklist',
        message: 'Your BOM asked you to finish Sales Checklist. Resume at question #2.',
        unread: true,
        data: {'template_slug': 'sales', 'submission_id': 42},
      );

      expect(notification.isFromBomOrGm, isTrue);
    });

    test('detects BOM in title, message, or sender role', () {
      const noteTitle = UserNotification(
        id: 'note-2',
        type: 'general_announcement',
        title: 'BOM Morning Notice',
        message: 'Please complete all checklists on time.',
        unread: true,
        data: {},
      );
      expect(noteTitle.isFromBomOrGm, isTrue);

      const noteMsg = UserNotification(
        id: 'note-3',
        type: 'status_alert',
        title: 'Inspection Pending',
        message:
            'Roberto Garcia (Branch Operations Manager) requested an update.',
        unread: true,
        data: {},
      );
      expect(noteMsg.isFromBomOrGm, isTrue);

      const noteSender = UserNotification(
        id: 'note-4',
        type: 'audit_alert',
        title: 'Review findings',
        message: 'Action plan required for non-conformance item.',
        unread: true,
        data: {'sender_role': 'BOM'},
      );
      expect(noteSender.isFromBomOrGm, isTrue);
    });

    test('detects GM in title, message, or type', () {
      const noteGm = UserNotification(
        id: 'note-5',
        type: 'gm_compliance_notice',
        title: 'General Manager Review',
        message: 'Ensure monthly audit compliance records are complete.',
        unread: true,
        data: {},
      );
      expect(noteGm.isFromBomOrGm, isTrue);
    });

    test('returns false for generic notifications not from BOM or GM', () {
      const genericNote = UserNotification(
        id: 'note-6',
        type: 'system_sync',
        title: 'Catalog updated',
        message: 'New checklist templates are now available.',
        unread: true,
        data: {},
      );
      expect(genericNote.isFromBomOrGm, isFalse);
    });
  });

  group('TaskReminderPlanner.bomGmReminders', () {
    test('returns empty list for 5S_UTILITIES accounts', () {
      final reminders = TaskReminderPlanner.bomGmReminders(
        userType: '5S_UTILITIES',
        branch: 'Pasong Tamo',
      );

      expect(reminders, isEmpty);
    });

    test('returns midday BOM reminder and excludes GM wrap-up for non-utilities roles', () {
      final reminders = TaskReminderPlanner.bomGmReminders(
        userType: '5S_SERVICE',
        branch: 'Pasong Tamo',
      );

      expect(reminders, hasLength(1));

      final bom = reminders[0];
      expect(bom.id, gacBomMiddayReminderId);
      expect(bom.kind, TaskReminderKind.bomGmReminder);
      expect(bom.hour, 11);
      expect(bom.minute, 30);
      expect(bom.title, 'BOM Checklist Reminder');
      expect(bom.body, contains('Pasong Tamo'));
      expect(bom.payload.event, 'bom_midday_checkin');

      // GM notification should not be scheduled for other users
      expect(reminders.any((r) => r.id == gacGmEodReminderId), isFalse);
    });

    test('never includes GM notification for any other roles', () {
      for (final role in [
        '5S_SALES',
        '5S_SERVICE',
        'DOS_SALES',
        'DOS_AFTERSALES',
        'PIC',
      ]) {
        final reminders = TaskReminderPlanner.bomGmReminders(
          userType: role,
          branch: 'Pasong Tamo',
        );
        expect(
          reminders.any((r) => r.id == gacGmEodReminderId),
          isFalse,
          reason: 'GM notification should not be present for $role',
        );
      }
    });

    test('cancelGmReminder executes cleanly without throwing', () async {
      await expectLater(
        LocalNotificationService.instance.cancelGmReminder(),
        completes,
      );
    });
  });

  group('Session timeout preserves Remember-Me token for BOM/GM sync', () {
    test(
      'handleSessionTimeout preserves previous auth token & remember-me state',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(gacAuthTokenKey, 'active-session-token');
        await prefs.setString(gacAuthUserKey, '{"name":"Auditor"}');
        await prefs.setBool(gacRememberMeKey, true);
        await prefs.setString(gacPreviousUserTypeKey, '5S_SALES');

        bool timeoutCalled = false;
        SessionManager.instance.onTimeout = () {
          timeoutCalled = true;
        };

        await SessionManager.instance.handleSessionTimeout();

        expect(timeoutCalled, isTrue);
        // Active session tokens are cleared
        expect(prefs.getString(gacAuthTokenKey), isNull);
        expect(prefs.getString(gacAuthUserKey), isNull);
        expect(prefs.getBool(gacRememberMeKey), isFalse);

        // Previous user & remember-me token are preserved for BOM/GM notification continuity
        expect(
          prefs.getString(gacPreviousAuthTokenKey),
          'active-session-token',
        );
        expect(prefs.getBool(gacPreviousRememberMeKey), isTrue);
        expect(prefs.getString(gacPreviousUserTypeKey), '5S_SALES');
      },
    );

    test(
      'handleSessionTimeout cancels scheduled BOM reminders for 5S_UTILITIES',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(gacAuthTokenKey, 'utilities-session-token');
        await prefs.setString(gacAuthUserKey, '{"name":"Utility Cleaner"}');
        await prefs.setBool(gacRememberMeKey, true);
        await prefs.setString(gacPreviousUserTypeKey, '5S_UTILITIES');
        await prefs.setStringList('gac_scheduled_bom_gm_reminder_ids', [
          '650690',
        ]);

        bool timeoutCalled = false;
        SessionManager.instance.onTimeout = () {
          timeoutCalled = true;
        };

        await SessionManager.instance.handleSessionTimeout();

        expect(timeoutCalled, isTrue);
        expect(
          prefs.getStringList('gac_scheduled_bom_gm_reminder_ids'),
          isNull,
        );
      },
    );

    test('recordPreviousUser persists token, branch, and rememberMe', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LocalNotificationService.instance;
      const user = AuthenticatedUser(
        id: 7,
        name: 'Carlos Auditor',
        email: 'carlos@gateway.test',
        userType: '5S_SERVICE',
        accountStatus: 'active',
        branch: 'San Pablo',
      );

      await service.recordPreviousUser(
        user,
        token: 'remember-jwt-token-123',
        rememberMe: true,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(gacPreviousUserTypeKey), '5S_SERVICE');
      expect(prefs.getString(gacPreviousBranchKey), 'San Pablo');
      expect(
        prefs.getString(gacPreviousAuthTokenKey),
        'remember-jwt-token-123',
      );
      expect(prefs.getBool(gacPreviousRememberMeKey), isTrue);
    });
  });

  group('syncBomGmNotifications functionality', () {
    test('fetches unread BOM/GM notifications using remembered auth token when timed out', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        gacPreviousAuthTokenKey,
        'remembered-token-for-sync',
      );
      await prefs.setBool(gacPreviousRememberMeKey, true);
      await prefs.setString(gacPreviousUserTypeKey, '5S_SALES');

      final fakeRepo = _FakeNotificationRepo(
        notifications: [
          const UserNotification(
            id: 'draft-alert-99',
            type: 'checklist_draft_reminder',
            title: 'Finish your drafted checklist',
            message: 'Your BOM asked you to finish Sales Checklist. Resume at question #3.',
            unread: true,
            data: {
              'template_slug': 'sales',
              'submission_id': 50,
              'item_key': 'item-3',
            },
          ),
          const UserNotification(
            id: 'generic-alert-1',
            type: 'system',
            title: 'System update',
            message: 'Database maintenance scheduled tonight.',
            unread: true,
            data: {},
          ),
        ],
      );

      final service = LocalNotificationService.instance;
      final count = await service.syncBomGmNotifications(repository: fakeRepo);

      expect(fakeRepo.fetchCalled, isTrue);
      expect(count, greaterThanOrEqualTo(0));
    });

    test(
      'syncBomGmNotifications polls real server alerts for 5S_UTILITIES',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(gacPreviousAuthTokenKey, 'utilities-token');
        await prefs.setString(gacPreviousUserTypeKey, '5S_UTILITIES');
        await prefs.setString(gacPreviousAssignmentKey, 'utilities');

        final fakeRepo = _FakeNotificationRepo(
          notifications: [
            const UserNotification(
              id: 'draft-1',
              type: 'checklist_draft_reminder',
              title: 'Reminder',
              message: 'Finish your checklist',
              unread: true,
              data: {},
            ),
          ],
        );
        final service = LocalNotificationService.instance;
        final count = await service.syncBomGmNotifications(
          repository: fakeRepo,
        );

        expect(count, 1);
        expect(fakeRepo.fetchCalled, isTrue);
      },
    );

    test(
      'scheduleBomGmReminders returns 0 for 5S_UTILITIES and clears stored IDs',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('gac_scheduled_bom_gm_reminder_ids', [
          '650690',
          '650990',
        ]);

        final service = LocalNotificationService.instance;
        final count = await service.scheduleBomGmReminders(
          userType: '5S_UTILITIES',
          preferences: prefs,
        );

        expect(count, 0);
        expect(
          prefs.getStringList('gac_scheduled_bom_gm_reminder_ids'),
          isNull,
        );
      },
    );

    test(
      'syncBomGmNotificationsForPreviousUser alias functions identically',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(gacPreviousUserTypeKey, '5S_SERVICE');
        await prefs.setString(gacPreviousBranchKey, 'Cebu');

        final fakeRepo = _FakeNotificationRepo(notifications: []);
        final service = LocalNotificationService.instance;

        final count = await service.syncBomGmNotificationsForPreviousUser(
          repository: fakeRepo,
        );
        expect(count, greaterThanOrEqualTo(0));
      },
    );
  });
}

class _FakeNotificationRepo implements NotificationRepository {
  _FakeNotificationRepo({required this.notifications});

  final List<UserNotification> notifications;
  bool fetchCalled = false;

  @override
  Future<NotificationInbox> fetchNotifications() async {
    fetchCalled = true;
    final unread = notifications.where((n) => n.unread).length;
    return NotificationInbox(notifications: notifications, unreadCount: unread);
  }

  @override
  Future<NotificationInbox> markRead(String id) async {
    return NotificationInbox(notifications: notifications, unreadCount: 0);
  }

  @override
  Future<int> markAllRead() async => 0;
}
