import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gac_flutter/config/api_config.dart';
import 'package:gac_flutter/models/user_notification.dart';
import 'package:gac_flutter/services/notification_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {
      gacAuthTokenKey: 'notification-token',
    });
  });

  test('loads the current user inbox with bearer authentication', () async {
    late http.Request captured;
    final service = NotificationApiService(
      apiUrl: 'https://gateway.test/api',
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'notifications': [
              {
                'id': 'notice-1',
                'type': 'task_assigned',
                'title': 'Checklist assigned',
                'message': 'Complete the restroom checklist.',
                'data': {'template_slug': 'restroom'},
                'unread': true,
                'read_at': null,
                'created_at': '2026-09-02T08:00:00+08:00',
              },
            ],
            'unread_count': 1,
          }),
          200,
        );
      }),
    );

    final inbox = await service.fetchNotifications();

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/notifications');
    expect(captured.headers['Authorization'], 'Bearer notification-token');
    expect(inbox.unreadCount, 1);
    expect(inbox.notifications.single.title, 'Checklist assigned');
    expect(inbox.notifications.single.data['template_slug'], 'restroom');
  });

  test(
    'controller keeps item state and the header count synchronized',
    () async {
      final repository = _InboxRepository();
      final controller = UserNotificationController(repository: repository);
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.unreadCount, 2);

      await controller.markRead('one');
      expect(controller.unreadCount, 1);
      expect(controller.notifications.first.unread, isFalse);

      await controller.markAllRead();
      expect(controller.unreadCount, 0);
      expect(controller.notifications.every((item) => !item.unread), isTrue);
    },
  );

  test(
    'controller presents newly loaded inbox items to Android bridge',
    () async {
      final repository = _InboxRepository();
      List<UserNotification>? presented;
      final controller = UserNotificationController(
        repository: repository,
        systemNotificationPresenter: (notifications) async {
          presented = notifications.toList(growable: false);
          return notifications.where((item) => item.unread).length;
        },
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(presented?.map((item) => item.id), ['one', 'two']);
      expect(controller.error, isNull);
    },
  );

  test('Android bridge errors do not hide a loaded in-app inbox', () async {
    final controller = UserNotificationController(
      repository: _InboxRepository(),
      systemNotificationPresenter: (_) =>
          Future<int>.error(StateError('Android notifications unavailable')),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.notifications, hasLength(2));
    expect(controller.unreadCount, 2);
    expect(controller.error, isNull);
  });
}

class _InboxRepository implements NotificationRepository {
  var unread = {'one', 'two'};

  UserNotification notice(String id) => UserNotification(
    id: id,
    type: 'task_assigned',
    title: 'Task $id',
    message: 'A checklist was assigned.',
    unread: unread.contains(id),
    data: const {},
    createdAt: DateTime(2026, 9, 2),
  );

  @override
  Future<NotificationInbox> fetchNotifications() async => NotificationInbox(
    notifications: [notice('one'), notice('two')],
    unreadCount: unread.length,
  );

  @override
  Future<NotificationInbox> markRead(String id) async {
    unread.remove(id);
    return NotificationInbox(
      notifications: [notice(id)],
      unreadCount: unread.length,
    );
  }

  @override
  Future<int> markAllRead() async {
    unread.clear();
    return 0;
  }
}
