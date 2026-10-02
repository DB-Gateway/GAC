import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/config/api_config.dart';
import 'package:gac_flutter/services/security_service.dart';
import 'package:gac_flutter/services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SessionManager.instance.stopTracking();
    SessionManager.instance.resetTimeout();
    SessionManager.instance.onTimeout = null;
  });

  tearDown(() {
    SessionManager.instance.stopTracking();
    SessionManager.instance.resetTimeout();
    SessionManager.instance.onTimeout = null;
  });

  group('SessionManager Unit Tests', () {
    test('startTracking with isRemembered: false starts inactivity timer and tracks activity', () {
      SessionManager.instance.startTracking(
        isRemembered: false,
        customTimeout: const Duration(seconds: 10),
      );

      expect(SessionManager.instance.isTracking, isTrue);
      expect(SessionManager.instance.isRemembered, isFalse);
      expect(SessionManager.instance.lastActivityTime, isNotNull);
    });

    test('startTracking with isRemembered: true sets inactivity timer and tracks activity for strict timeout', () {
      SessionManager.instance.startTracking(
        isRemembered: true,
        customTimeout: const Duration(seconds: 10),
      );

      expect(SessionManager.instance.isTracking, isTrue);
      expect(SessionManager.instance.isRemembered, isTrue);
      expect(SessionManager.instance.lastActivityTime, isNotNull);
    });

    test('recordUserActivity updates lastActivityTime', () async {
      SessionManager.instance.startTracking(
        isRemembered: false,
        customTimeout: const Duration(seconds: 10),
      );

      final firstTime = SessionManager.instance.lastActivityTime;
      await Future<void>.delayed(const Duration(milliseconds: 10));

      SessionManager.instance.recordUserActivity();
      final updatedTime = SessionManager.instance.lastActivityTime;

      expect(updatedTime!.isAfter(firstTime!), isTrue);
    });

    test('handleSessionTimeout clears tokens and remember me, but preserves user type', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(gacAuthTokenKey, 'test-token');
      await prefs.setString(gacAuthUserKey, '{"name":"Tester"}');
      await prefs.setBool(gacRememberMeKey, true);
      await prefs.setString(gacPreviousUserTypeKey, 'PIC');

      bool timeoutTriggered = false;
      SessionManager.instance.onTimeout = () {
        timeoutTriggered = true;
      };

      await SessionManager.instance.handleSessionTimeout();

      expect(timeoutTriggered, isTrue);
      expect(prefs.getString(gacAuthTokenKey), isNull);
      expect(prefs.getString(gacAuthUserKey), isNull);
      expect(prefs.getBool(gacRememberMeKey), isFalse);
      // User type is preserved for notification scheduling
      expect(prefs.getString(gacPreviousUserTypeKey), 'PIC');
      expect(SessionManager.instance.isTracking, isFalse);
    });

    test('Timer expiry invokes handleSessionTimeout automatically', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(gacAuthTokenKey, 'test-token');

      final completer = Completer<void>();
      SessionManager.instance.onTimeout = () {
        completer.complete();
      };

      SessionManager.instance.startTracking(
        isRemembered: false,
        customTimeout: const Duration(milliseconds: 50),
      );

      await completer.future.timeout(const Duration(seconds: 1));

      expect(prefs.getString(gacAuthTokenKey), isNull);
      expect(SessionManager.instance.isTracking, isFalse);
    });

    test('App lifecycle background pause and resume with timeout elapsed triggers timeout', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(gacAuthTokenKey, 'test-token');

      bool timedOut = false;
      SessionManager.instance.onTimeout = () {
        timedOut = true;
      };

      SessionManager.instance.startTracking(
        isRemembered: false,
        customTimeout: const Duration(milliseconds: 50),
      );

      // Pause app
      SessionManager.instance.handleAppLifecycleState(AppLifecycleState.paused);

      // Wait longer than timeout
      await Future<void>.delayed(const Duration(milliseconds: 60));

      // Resume app
      SessionManager.instance.handleAppLifecycleState(AppLifecycleState.resumed);

      expect(timedOut, isTrue);
      expect(prefs.getString(gacAuthTokenKey), isNull);
    });
  });

  group('SecurityService Per-User PIN Checks', () {
    test('hasPin returns false for new user when global pin exists', () async {
      final prefs = await SharedPreferences.getInstance();
      // Simulate stale global pin from legacy test
      await prefs.setString(gacSecurityPinKey, '1234');

      // Check for a specific user who has never set a PIN
      final hasUserPin = await SecurityService.instance.hasPin(
        email: 'newuser@pic.gateway.local',
      );

      expect(hasUserPin, isFalse);
    });

    test('savePin saves for specific email and hasPin detects it', () async {
      await SecurityService.instance.savePin(
        '5678',
        email: 'makati.pic@gateway.local',
      );

      final hasMakatiPin = await SecurityService.instance.hasPin(
        email: 'makati.pic@gateway.local',
      );
      expect(hasMakatiPin, isTrue);

      final hasCebuPin = await SecurityService.instance.hasPin(
        email: 'cebu.pic@gateway.local',
      );
      expect(hasCebuPin, isFalse);

      final makatiValid = await SecurityService.instance.verifyPin(
        '5678',
        email: 'makati.pic@gateway.local',
      );
      expect(makatiValid, isTrue);

      final wrongPinValid = await SecurityService.instance.verifyPin(
        '0000',
        email: 'makati.pic@gateway.local',
      );
      expect(wrongPinValid, isFalse);
    });

    test('supports 6-digit PIN creation and validation', () async {
      final saved = await SecurityService.instance.savePin(
        '123456',
        email: 'user6@gateway.local',
      );
      expect(saved, isTrue);

      final hasPin = await SecurityService.instance.hasPin(
        email: 'user6@gateway.local',
      );
      expect(hasPin, isTrue);

      final stored = await SecurityService.instance.getStoredPin(
        email: 'user6@gateway.local',
      );
      expect(stored, '123456');

      final valid = await SecurityService.instance.verifyPin(
        '123456',
        email: 'user6@gateway.local',
      );
      expect(valid, isTrue);

      final invalid = await SecurityService.instance.verifyPin(
        '654321',
        email: 'user6@gateway.local',
      );
      expect(invalid, isFalse);
    });
  });

  group('Session 1-Hour Inactivity and isSessionActive', () {
    test('standard session timeout duration is 1 hour', () {
      expect(gacSessionTimeoutDuration, const Duration(hours: 1));
      expect(SessionManager.instance.timeoutDuration, const Duration(hours: 1));
    });

    test('isSessionActive returns true when within 1 hour for non-remembered user', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(gacAuthTokenKey, 'auth-token');
      await prefs.setString(gacAuthUserKey, '{"id":1,"name":"Alex"}');
      await prefs.setBool(gacRememberMeKey, false);
      // Last active 10 minutes ago
      final recent = DateTime.now().subtract(const Duration(minutes: 10));
      await prefs.setString(gacLastActivityTimeKey, recent.toIso8601String());

      final active = await SessionManager.instance.isSessionActive();
      expect(active, isTrue);
    });

    test('isSessionActive returns false when more than 1 hour has elapsed for non-remembered user', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(gacAuthTokenKey, 'auth-token');
      await prefs.setString(gacAuthUserKey, '{"id":1,"name":"Alex"}');
      await prefs.setBool(gacRememberMeKey, false);
      // Last active 65 minutes ago
      final past = DateTime.now().subtract(const Duration(minutes: 65));
      await prefs.setString(gacLastActivityTimeKey, past.toIso8601String());

      final active = await SessionManager.instance.isSessionActive();
      expect(active, isFalse);
    });

    test('isSessionActive returns false when more than 1 hour has elapsed even when Remember Me is enabled', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(gacAuthTokenKey, 'auth-token');
      await prefs.setString(gacAuthUserKey, '{"id":1,"name":"Alex"}');
      await prefs.setBool(gacRememberMeKey, true);
      // Last active 5 hours ago
      final past = DateTime.now().subtract(const Duration(hours: 5));
      await prefs.setString(gacLastActivityTimeKey, past.toIso8601String());

      final active = await SessionManager.instance.isSessionActive();
      expect(active, isFalse);
    });

    test('isSessionActive returns true when within 1 hour for Remember Me user', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(gacAuthTokenKey, 'auth-token');
      await prefs.setString(gacAuthUserKey, '{"id":1,"name":"Alex"}');
      await prefs.setBool(gacRememberMeKey, true);
      // Last active 20 minutes ago
      final recent = DateTime.now().subtract(const Duration(minutes: 20));
      await prefs.setString(gacLastActivityTimeKey, recent.toIso8601String());

      final active = await SessionManager.instance.isSessionActive();
      expect(active, isTrue);
    });

    test('recordUserActivity triggers handleSessionTimeout when inactivity duration has elapsed', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(gacAuthTokenKey, 'test-token');

      bool timedOut = false;
      SessionManager.instance.onTimeout = () {
        timedOut = true;
      };

      SessionManager.instance.startTracking(
        isRemembered: true,
        customTimeout: const Duration(milliseconds: 30),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      SessionManager.instance.recordUserActivity();

      expect(timedOut, isTrue);
      expect(prefs.getString(gacAuthTokenKey), isNull);
    });
  });
}
