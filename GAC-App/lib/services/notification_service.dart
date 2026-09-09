import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_notification.dart';

abstract interface class NotificationRepository {
  Future<NotificationInbox> fetchNotifications();

  Future<NotificationInbox> markRead(String id);

  Future<int> markAllRead();
}

class NotificationApiService implements NotificationRepository {
  NotificationApiService({
    http.Client? client,
    this.apiUrl = gacApiUrl,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _client = client ?? http.Client(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final http.Client _client;
  final String apiUrl;
  final Future<SharedPreferences> Function() _preferencesLoader;

  @override
  Future<NotificationInbox> fetchNotifications() async {
    final data = await _request('GET', '/notifications');
    final items = data['notifications'];
    if (items is! List || data['unread_count'] is! num) {
      throw const NotificationApiException(
        'Laravel returned an invalid notification inbox.',
      );
    }
    try {
      return NotificationInbox(
        notifications: items
            .map(UserNotification.fromJson)
            .toList(growable: false),
        unreadCount: (data['unread_count'] as num).toInt(),
      );
    } on FormatException catch (error) {
      throw NotificationApiException(error.message);
    }
  }

  @override
  Future<NotificationInbox> markRead(String id) async {
    final data = await _request(
      'PATCH',
      '/notifications/${Uri.encodeComponent(id)}/read',
    );
    if (data['unread_count'] is! num) {
      throw const NotificationApiException(
        'Laravel returned an invalid notification update.',
      );
    }
    try {
      return NotificationInbox(
        notifications: [UserNotification.fromJson(data['notification'])],
        unreadCount: (data['unread_count'] as num).toInt(),
      );
    } on FormatException catch (error) {
      throw NotificationApiException(error.message);
    }
  }

  @override
  Future<int> markAllRead() async {
    final data = await _request('PATCH', '/notifications/read-all');
    final count = data['unread_count'];
    if (count is! num) {
      throw const NotificationApiException(
        'Laravel returned an invalid notification update.',
      );
    }
    return count.toInt();
  }

  Future<Map<String, dynamic>> _request(String method, String endpoint) async {
    final preferences = await _preferencesLoader();
    final token = preferences.getString(gacAuthTokenKey);
    if (token == null || token.isEmpty) {
      throw const NotificationApiException(
        'Your session has expired. Sign in again.',
        status: 401,
      );
    }

    final base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final request = http.Request(method, Uri.parse('$base$endpoint'))
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      );
    } catch (_) {
      throw NotificationApiException(
        'Cannot reach Laravel at $base. Check your connection.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final data = decoded is Map
        ? {
            for (final entry in decoded.entries)
              if (entry.key is String) entry.key as String: entry.value,
          }
        : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationApiException(
        data['message'] is String
            ? data['message'] as String
            : 'The notification request failed.',
        status: response.statusCode,
      );
    }
    return data;
  }
}

class UserNotificationController extends ChangeNotifier {
  UserNotificationController({NotificationRepository? repository})
    : _repository = repository ?? NotificationApiService();

  final NotificationRepository _repository;
  List<UserNotification> _notifications = const [];
  int _unreadCount = 0;
  bool _loading = false;
  bool _requesting = false;
  bool _initialized = false;
  String? _error;

  List<UserNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  bool get initialized => _initialized;
  String? get error => _error;

  Future<void> load({bool showSpinner = true}) async {
    if (_requesting) return;
    _requesting = true;
    _loading = showSpinner;
    _error = null;
    notifyListeners();
    try {
      final inbox = await _repository.fetchNotifications();
      _notifications = inbox.notifications;
      _unreadCount = inbox.unreadCount;
      _initialized = true;
    } on NotificationApiException catch (error) {
      _error = error.message;
      _initialized = true;
    } catch (_) {
      _error = 'Your notifications could not be loaded from Laravel.';
      _initialized = true;
    } finally {
      _requesting = false;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || !_notifications[index].unread) return;
    final result = await _repository.markRead(id);
    final updated = result.notifications.single;
    _notifications = [
      for (final item in _notifications)
        if (item.id == id) updated else item,
    ];
    _unreadCount = result.unreadCount;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (_unreadCount == 0) return;
    _unreadCount = await _repository.markAllRead();
    _notifications = _notifications
        .map((item) => item.unread ? item.markRead() : item)
        .toList(growable: false);
    notifyListeners();
  }
}

class NotificationApiException implements Exception {
  const NotificationApiException(this.message, {this.status = 0});

  final String message;
  final int status;

  @override
  String toString() => message;
}
