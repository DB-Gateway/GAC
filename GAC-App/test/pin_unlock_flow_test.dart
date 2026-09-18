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
        await tester.pumpWidget(_wrap(const GatewayLoginScreen()));
        await tester.pump();

        expect(find.text('Remember me'), findsOneWidget);
        expect(find.text('Forgot password?'), findsOneWidget);
        expect(find.text('EMAIL ADDRESS'), findsOneWidget);
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

        await tester.pumpWidget(_wrap(const GatewayLoginScreen()));
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

        await tester.pumpWidget(_wrap(const GatewayLoginScreen()));
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
  });
}
