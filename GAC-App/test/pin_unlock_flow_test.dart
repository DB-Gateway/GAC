import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/config/api_config.dart';
import 'package:gac_flutter/login.dart';
import 'package:gac_flutter/widgets/pin_dialogs.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PIN Keypad and Indicator Widgets', () {
    testWidgets('PinDots renders correct number of filled and empty circles', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Scaffold(body: Center(child: PinDots(length: 2, total: 4))),
        ),
      );

      // Verify PinDots renders 4 dot containers
      final dotsFinder = find.byType(AnimatedContainer);
      expect(dotsFinder, findsNWidgets(4));
    });

    testWidgets(
      'PinDots can animate from filled to empty without an exception',
      (tester) async {
        var length = 1;
        late StateSetter updateState;

        await tester.pumpWidget(
          _wrap(
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  updateState = setState;
                  return Center(child: PinDots(length: length));
                },
              ),
            ),
          ),
        );

        updateState(() => length = 0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('PinKeypad responds to digit taps and backspace', (
      tester,
    ) async {
      String entered = '';
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Center(
              child: PinKeypad(
                onDigit: (digit) => entered += digit,
                onBackspace: () {
                  if (entered.isNotEmpty) {
                    entered = entered.substring(0, entered.length - 1);
                  }
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('9'));
      await tester.pump();
      expect(entered, '159');

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(entered, '15');
    });
  });

  group('Login Remember Me Checkbox and Quick Unlock Presentation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'login screen shows Remember me checkbox and Forgot password link',
      (tester) async {
        await tester.pumpWidget(
          _wrap(GatewayLoginScreen(storedSessionValidator: (_) async => true)),
        );
        await tester.pump();

        expect(find.text('Remember me'), findsOneWidget);
        expect(find.text('Forgot password?'), findsOneWidget);
        expect(find.text('USERNAME'), findsOneWidget);
        expect(find.text('PASSWORD'), findsOneWidget);
      },
    );

    testWidgets(
      'returns in quick unlock mode when PIN is set and Remember Me was enabled',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          gacRememberMeKey: true,
          gacRememberEmailKey: 'alex@gateway.local',
          gacAuthTokenKey: 'valid-test-token',
          gacAuthUserKey:
              '{"id":1,"name":"Alex Reyes","email":"alex@gateway.local",'
              '"branch":"Pasong Tamo","user_type":"PIC",'
              '"pic_assignment_type":"utilities",'
              '"pic_assignment_label":"Utilities","account_status":"active"}',
          gacSecurityPinKey: '1234',
          '${gacSecurityPinKey}_alex@gateway.local': '1234',
        });

        await tester.pumpWidget(
          _wrap(GatewayLoginScreen(storedSessionValidator: (_) async => true)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1500));

        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.text('Alex Reyes'), findsOneWidget);
        expect(find.text('Enter your 4-digit PIN to continue'), findsOneWidget);
        expect(find.text('Sign in with password instead'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Sign in with password exits quick unlock back to standard form',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          gacRememberMeKey: true,
          gacRememberEmailKey: 'alex@gateway.local',
          gacAuthTokenKey: 'valid-test-token',
          gacAuthUserKey:
              '{"id":1,"name":"Alex Reyes","email":"alex@gateway.local",'
              '"branch":"Pasong Tamo","user_type":"PIC",'
              '"pic_assignment_type":"utilities",'
              '"pic_assignment_label":"Utilities","account_status":"active"}',
          gacSecurityPinKey: '1234',
          '${gacSecurityPinKey}_alex@gateway.local': '1234',
        });

        await tester.pumpWidget(
          _wrap(GatewayLoginScreen(storedSessionValidator: (_) async => true)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1500));

        expect(find.text('Welcome Back'), findsOneWidget);

        await tester.ensureVisible(find.text('Sign in with password instead'));
        await tester.tap(find.text('Sign in with password instead'));
        await tester.pumpAndSettle();

        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Remember me'), findsOneWidget);
      },
    );

    testWidgets('server-rejected remembered session cannot enter quick unlock', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        gacRememberMeKey: true,
        gacRememberEmailKey: 'blocked@gateway.local',
        gacAuthTokenKey: 'revoked-test-token',
        gacAuthUserKey:
            '{"id":3,"name":"Blocked Utility","email":"blocked@gateway.local",'
            '"branch":"Pasong Tamo","user_type":"5S_UTILITIES",'
            '"account_status":"active"}',
        gacSecurityPinKey: '1234',
        '${gacSecurityPinKey}_blocked@gateway.local': '1234',
      });

      await tester.pumpWidget(
        _wrap(GatewayLoginScreen(storedSessionValidator: (_) async => false)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('Welcome Back'), findsNothing);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets(
      'returns in quick unlock mode with 6-digit PIN when 6-digit PIN is stored',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          gacRememberMeKey: true,
          gacRememberEmailKey: 'maria@gateway.local',
          gacAuthTokenKey: 'valid-test-token-6',
          gacAuthUserKey:
              '{"id":2,"name":"Maria Santos","email":"maria@gateway.local",'
              '"branch":"Cebu","user_type":"PIC",'
              '"pic_assignment_type":"utilities",'
              '"pic_assignment_label":"Utilities","account_status":"active"}',
          gacSecurityPinKey: '123456',
          '${gacSecurityPinKey}_maria@gateway.local': '123456',
        });

        await tester.pumpWidget(
          _wrap(GatewayLoginScreen(storedSessionValidator: (_) async => true)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1500));

        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.text('Maria Santos'), findsOneWidget);
        expect(find.text('Enter your 6-digit PIN to continue'), findsOneWidget);
      },
    );

    testWidgets(
      'shows persistent session timed out notice banner when arrived from timeout',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const GatewayLoginScreen(fromTimeout: true)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1600));

        expect(find.text('Session Timed Out'), findsOneWidget);
        expect(
          find.text('You were logged out after 1 hour of inactivity.'),
          findsOneWidget,
        );
        expect(find.text('Guide'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Guide on timeout notice opens the Stay Signed In Guide sheet',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const GatewayLoginScreen(fromTimeout: true)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1600));

        await tester.ensureVisible(find.text('Guide'));
        await tester.tap(find.text('Guide'));
        await tester.pumpAndSettle();

        expect(find.text('Stay Signed In Guide'), findsOneWidget);
        expect(find.text('1. Check "Remember me" at Sign In'), findsOneWidget);
        expect(find.text('2. Set Up a 6-Digit PIN'), findsOneWidget);
        expect(find.text('GOT IT'), findsOneWidget);

        // Scroll to and tap GOT IT to dismiss
        await tester.ensureVisible(find.text('GOT IT'));
        await tester.tap(find.text('GOT IT'));
        await tester.pumpAndSettle();

        expect(find.text('Stay Signed In Guide'), findsNothing);
      },
    );

    testWidgets(
      'tapping (i) icon next to Remember me opens the Stay Signed In Guide sheet',
      (tester) async {
        await tester.pumpWidget(_wrap(const GatewayLoginScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1600));

        final infoIconFinder = find.byIcon(Icons.info_outline_rounded);
        expect(infoIconFinder, findsOneWidget);

        await tester.tap(infoIconFinder);
        await tester.pumpAndSettle();

        expect(find.text('Stay Signed In Guide'), findsOneWidget);
        expect(find.text('1. Check "Remember me" at Sign In'), findsOneWidget);
      },
    );
  });
}
