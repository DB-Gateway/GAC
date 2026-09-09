import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../main.dart';
import 'local_notification_service.dart';

/// Manages active user session inactivity timeouts and auto-logout.
///
/// When a user logs in WITHOUT "Remember Me", an inactivity timer is started.
/// If no interaction occurs within [gacSessionTimeoutDuration], the user is
/// automatically logged out and redirected to the login screen.
///
/// If "Remember Me" is enabled, sessions remain persistent across inactivity.
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
    if (_isTracking && !_isRemembered) {
      _resetTimer();
    }
  }

  /// Reset to standard timeout duration.
  void resetTimeout() {
    _timeoutDuration = gacSessionTimeoutDuration;
    if (_isTracking && !_isRemembered) {
      _resetTimer();
    }
  }

  /// Starts tracking session activity.
  ///
  /// If [isRemembered] is true, session inactivity auto-logout is disabled.
  void startTracking({
    required bool isRemembered,
    Duration? customTimeout,
  }) {
    if (customTimeout != null) {
      _timeoutDuration = customTimeout;
    }
    _isRemembered = isRemembered;
    _isTracking = true;
    _lastActivityTime = DateTime.now();
    _backgroundedTime = null;

    if (_isRemembered) {
      _inactivityTimer?.cancel();
      _inactivityTimer = null;
      return;
    }

    _resetTimer();
  }

  /// Records user touch/interaction event and resets the inactivity timer.
  void recordUserActivity() {
    if (!_isTracking || _isRemembered) return;
    _lastActivityTime = DateTime.now();
    _resetTimer();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, () {
      unawaited(handleSessionTimeout());
    });
  }

  /// Handles app lifecycle state transitions.
  void handleAppLifecycleState(AppLifecycleState state) {
    if (!_isTracking || _isRemembered) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedTime = DateTime.now();
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
      await prefs.remove(gacAuthTokenKey);
      await prefs.remove(gacAuthUserKey);
      await prefs.setBool(gacRememberMeKey, false);
      // NOTE: Scheduled local notifications matching the user's role continue uninterrupted
      // based on the previous login's account user type.
      await LocalNotificationService.instance.syncForPreviousUser();
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
