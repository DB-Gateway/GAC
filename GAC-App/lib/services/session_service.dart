import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../main.dart';
import 'local_notification_service.dart';

/// Manages active user session inactivity timeouts and auto-logout.
///
/// When a user logs in, an inactivity timer is started.
/// If no interaction occurs within [gacSessionTimeoutDuration], the user is
/// automatically logged out and redirected to the login screen.
///
/// If "Remember Me" is enabled, credential preferences are preserved to allow
/// Quick PIN / Biometric unlock, but active sessions strictly time out after
/// [gacSessionTimeoutDuration] of inactivity for all users.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  Timer? _inactivityTimer;
  Duration _timeoutDuration = gacSessionTimeoutDuration;
  bool _isTracking = false;
  bool _isRemembered = false;
  DateTime? _lastActivityTime;
  DateTime? _backgroundedTime;
  VoidCallback? onTimeout;

  Duration get timeoutDuration => _timeoutDuration;
  bool get isTracking => _isTracking;
  bool get isRemembered => _isRemembered;
  DateTime? get lastActivityTime => _lastActivityTime;

  /// Configure custom timeout duration (useful for tests).
  void setCustomTimeout(Duration duration) {
    _timeoutDuration = duration;
    if (_isTracking) {
      _resetTimer();
    }
  }

  /// Reset to standard timeout duration.
  void resetTimeout() {
    _timeoutDuration = gacSessionTimeoutDuration;
    if (_isTracking) {
      _resetTimer();
    }
  }

  /// Starts tracking session activity for all authenticated users.
  void startTracking({required bool isRemembered, Duration? customTimeout}) {
    if (customTimeout != null) {
      _timeoutDuration = customTimeout;
    }
    _isRemembered = isRemembered;
    _isTracking = true;
    _lastActivityTime = DateTime.now();
    _backgroundedTime = null;
    unawaited(_persistLastActivity(_lastActivityTime!));

    _resetTimer();
  }

  /// Records user touch/interaction event and resets the inactivity timer.
  /// If inactivity has already exceeded [_timeoutDuration], immediately handles timeout.
  void recordUserActivity() {
    if (!_isTracking) return;
    final now = DateTime.now();
    if (_lastActivityTime != null &&
        now.difference(_lastActivityTime!) >= _timeoutDuration) {
      unawaited(handleSessionTimeout());
      return;
    }
    _lastActivityTime = now;
    unawaited(_persistLastActivity(_lastActivityTime!));
    _resetTimer();
  }

  Future<void> _persistLastActivity(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(gacLastActivityTimeKey, time.toIso8601String());
    } catch (_) {}
  }

  /// Checks if an existing stored session is still within the 1-hour timeout window.
  Future<bool> isSessionActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final token = prefs.getString(gacAuthTokenKey);
      final user = prefs.getString(gacAuthUserKey);
      if (token == null || token.trim().isEmpty || user == null) return false;

      final lastActivityStr = prefs.getString(gacLastActivityTimeKey);
      if (lastActivityStr == null) {
        // If lastActivityTime in memory exists, check that
        if (_lastActivityTime != null) {
          return DateTime.now().difference(_lastActivityTime!) < _timeoutDuration;
        }
        return true;
      }
      final lastActivity = DateTime.tryParse(lastActivityStr);
      if (lastActivity == null) return false;

      return DateTime.now().difference(lastActivity) < _timeoutDuration;
    } catch (_) {
      return false;
    }
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, () {
      unawaited(handleSessionTimeout());
    });
  }

  /// Handles app lifecycle state transitions.
  void handleAppLifecycleState(AppLifecycleState state) {
    if (!_isTracking) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedTime = DateTime.now();
      unawaited(_persistLastActivity(_backgroundedTime!));
    } else if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final reference = _backgroundedTime ?? _lastActivityTime;
      if (reference != null && now.difference(reference) >= _timeoutDuration) {
        unawaited(handleSessionTimeout());
        return;
      }
      _backgroundedTime = null;
      recordUserActivity();
    }
  }

  /// Triggers session timeout: clears auth tokens and redirects to login.
  Future<void> handleSessionTimeout() async {
    stopTracking();

    try {
      final prefs = await SharedPreferences.getInstance();
      // Ensure previous auth token and remember-me preference are preserved for background BOM/GM sync
      final wasRemembered = prefs.getBool(gacRememberMeKey) ?? false;
      final token = prefs.getString(gacAuthTokenKey);
      if (prefs.getString(gacNotificationTokenKey) != null) {
        await prefs.remove(gacPreviousAuthTokenKey);
      } else if (token != null && token.isNotEmpty) {
        await prefs.setString(gacPreviousAuthTokenKey, token);
      }
      if (wasRemembered) {
        await prefs.setBool(gacPreviousRememberMeKey, true);
      }

      await prefs.remove(gacAuthTokenKey);
      await prefs.remove(gacAuthUserKey);
      await prefs.remove(gacLastActivityTimeKey);
      await prefs.setBool(gacRememberMeKey, false);
      // NOTE: Scheduled local notifications matching the user's role continue uninterrupted
      // based on the previous login's account user type.
      await LocalNotificationService.instance.syncForPreviousUser();
      if (TaskReminderPlanner.isUtilitiesRole(
            prefs.getString(gacPreviousUserTypeKey),
          ) ||
          TaskReminderPlanner.isUtilitiesAssignment(
            prefs.getString(gacPreviousAssignmentKey) ?? '',
          )) {
        await LocalNotificationService.instance.cancelBomGmReminders();
      }

      // Notification delivery is independent of Remember Me and assignment.
      // Do not hold the login redirect open while waiting for the network.
      unawaited(LocalNotificationService.instance.syncBomGmNotifications());
      LocalNotificationService.instance
          .startTimedOutManagerNotificationPolling();
    } catch (_) {}

    onTimeout?.call();

    final navigator = gacNavigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
        arguments: const {'fromTimeout': '1'},
      );
    }
  }

  /// Stops tracking user inactivity.
  void stopTracking() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _isTracking = false;
    _lastActivityTime = null;
    _backgroundedTime = null;
  }
}
