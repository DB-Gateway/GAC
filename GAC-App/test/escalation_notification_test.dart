import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/config/api_config.dart';
import 'package:gac_flutter/main.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/user_notification.dart';
import 'package:gac_flutter/screens/user_notifications_screen.dart';
import 'package:gac_flutter/services/background_notification_service.dart';
import 'package:gac_flutter/services/local_notification_service.dart';
import 'package:gac_flutter/services/notification_service.dart';
import 'package:gac_flutter/services/session_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _notice = UserNotification(
  id: 'escalation-12',
  type: 'finding_escalated',
  title: 'BOM escalated a checklist finding',
  message: 'Review your escalation.',
  unread: true,
  data: {
    'recipient_user_id': 7,
    'template_slug': 'dealer-operations-standards-sales',
    'template_name': 'Dealer Operations Standards - Sales',
    'branch': 'Pasong Tamo',
    'audit_date': '2026-09-14',
    'item_key': 'sales-2',
    'question': 'Is the signage in good condition?',
    'finding': 'The showroom sign is damaged.',
    'escalation_target_label': 'MARKETING / PURCHASING',
    'commitment_date': '2026-09-30',
    'action_plan': 'Replace the sign and verify installation.',
    'sender_name': 'Brenda BOM',
  },
);
const _payload = TaskReminderPayload(
  event: 'finding_escalated',
  notificationId: 'escalation-12',
  recipientUserId: '7',
  templateSlug: 'dealer-operations-standards-sales',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({gacPreviousUserIdKey: '7'});
  });
  tearDown(() {
    SessionManager.instance.stopTracking();
    LocalNotificationService.instance.stopTimedOutManagerNotificationPolling();
  });

  testWidgets(
    'inbox escalation opens a scrollable details modal and marks it read',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Inbox();
      final controller = UserNotificationController(
        repository: repository,
        systemNotificationPresenter: (_) async => 0,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserNotificationsScreen(
            onOpenProfile: () {},
            onGoHome: () {},
            onOpenSettings: () {},
            controller: controller,
            onOpenNotification: (_) =>
                fail('An escalation should open its modal.'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_notice.title));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('escalation-details-dialog')),
        findsOneWidget,
      );
      for (final value in [
        'Dealer Operations Standards - Sales',
        'MARKETING / PURCHASING',
        '2026-09-30',
        'Replace the sign and verify installation.',
        'Brenda BOM',
      ]) {
        expect(find.text(value), findsOneWidget);
      }
      expect(repository.read, isTrue);
      expect(controller.unreadCount, 0);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('escalation-details-dialog')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'system escalation tap opens the modal after session timeout without opening a checklist',
    (tester) async {
      final repository = _Inbox();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: gacNavigatorKey,
          home: const Scaffold(body: Text('Sign in')),
        ),
      );
      unawaited(
        openNotificationPayload(
          _payload.encode(),
          notificationRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('escalation-details-dialog')),
        findsOneWidget,
      );
      expect(repository.read, isTrue);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);
    },
  );

  testWidgets(
    'an alert for a previous account is ignored after account switching',
    (tester) async {
      SharedPreferences.setMockInitialValues({gacPreviousUserIdKey: '8'});
      final repository = _Inbox();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: gacNavigatorKey,
          home: const Scaffold(body: Text('Current user')),
        ),
      );
      await openNotificationPayload(
        _payload.encode(),
        notificationRepository: repository,
      );
      await tester.pumpAndSettle();
      expect(repository.fetches, 0);
      expect(
        find.byKey(const ValueKey('escalation-details-dialog')),
        findsNothing,
      );
    },
  );

  test(
    'notification API uses its device credential after interactive timeout',
    () async {
      SharedPreferences.setMockInitialValues({
        gacNotificationTokenKey: 'device-secret',
        gacPreviousUserIdKey: '7',
        gacAuthTokenKey: 'expired-login-secret',
        gacRememberMeKey: false,
      });
      final service = NotificationApiService(
        apiUrl: 'https://gateway.test/api',
        client: MockClient((request) async {
          expect(request.url.path, '/api/device-notifications');
          expect(request.headers['Authorization'], 'Bearer device-secret');
          return http.Response(
            jsonEncode({'notifications': [], 'unread_count': 0}),
            200,
          );
        }),
      );
      await service.fetchNotifications();
    },
  );

  test(
    'a response arriving after an account switch cannot enter the inbox',
    () async {
      SharedPreferences.setMockInitialValues({
        gacNotificationTokenKey: 'first-user',
      });
      final service = NotificationApiService(
        client: MockClient((request) async {
          final preferences = await SharedPreferences.getInstance();
          await preferences.setString(gacNotificationTokenKey, 'second-user');
          return http.Response(
            jsonEncode({'notifications': [], 'unread_count': 0}),
            200,
          );
        }),
      );
      await expectLater(
        service.fetchNotifications(),
        throwsA(isA<NotificationApiException>()),
      );
    },
  );

  test('remembered recipient and device access survive timeout with Remember Me off', () async {
    SharedPreferences.setMockInitialValues({
      gacPreviousUserIdKey: '7',
      gacNotificationTokenKey: 'device-secret',
      gacAuthTokenKey: 'login-secret',
      gacAuthUserKey: '{}',
      gacRememberMeKey: false,
      gacPushNotificationsEnabledKey: false,
    });
    await SessionManager.instance.handleSessionTimeout();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(gacPreviousUserIdKey), '7');
    expect(preferences.getString(gacNotificationTokenKey), 'device-secret');
    expect(preferences.getString(gacAuthTokenKey), isNull);
    expect(preferences.getString(gacPreviousAuthTokenKey), isNull);
  });

  test(
    'successful account replacement clears old pending alerts and credentials',
    () async {
      SharedPreferences.setMockInitialValues({
        gacPreviousUserIdKey: '7',
        gacNotificationTokenKey: 'old-secret',
        gacPreviousAuthTokenKey: 'old-login',
        gacPreviousBranchKey: 'Old branch',
        gacPendingNotificationPayloadKey: _payload.encode(),
      });
      await LocalNotificationService.instance.recordPreviousUser(
        const AuthenticatedUser(
          id: 8,
          name: 'New user',
          email: 'new@test.test',
          userType: '5S_UTILITIES',
          accountStatus: 'active',
        ),
        notificationToken: 'new-secret',
        replaceNotificationAccount: true,
        rememberMe: false,
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(gacPreviousUserIdKey), '8');
      expect(preferences.getString(gacNotificationTokenKey), 'new-secret');
      expect(preferences.getString(gacPreviousAuthTokenKey), isNull);
      expect(preferences.getString(gacPreviousBranchKey), isNull);
      expect(preferences.getString(gacPendingNotificationPayloadKey), isNull);
    },
  );

  test('device identity is stable across restarts and notification payload preserves recipient', () async {
    final first = await notificationDeviceId();
    expect(await notificationDeviceId(), first);
    expect(
      first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(
      TaskReminderPayload.tryParse(_payload.encode())?.recipientUserId,
      '7',
    );
  });
}

class _Inbox implements NotificationRepository {
  bool read = false;
  int fetches = 0;
  NotificationInbox get inbox => NotificationInbox(
    notifications: [read ? _notice.markRead() : _notice],
    unreadCount: read ? 0 : 1,
  );
  @override
  Future<NotificationInbox> fetchNotifications() async {
    fetches++;
    return inbox;
  }

  @override
  Future<NotificationInbox> markRead(String id) async {
    read = true;
    return inbox;
  }

  @override
  Future<int> markAllRead() async {
    read = true;
    return 0;
  }
}
