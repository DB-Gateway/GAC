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

    test('startTracking with isRemembered: true does not set inactivity timer', () {
      SessionManager.instance.startTracking(
        isRemembered: true,
      );

      expect(SessionManager.instance.isTracking, isTrue);
      expect(SessionManager.instance.isRemembered, isTrue);
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
  });
}
