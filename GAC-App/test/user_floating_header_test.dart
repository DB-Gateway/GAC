import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/theme/gac_theme.dart';
import 'package:gac_flutter/widgets/user_floating_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUser = AuthenticatedUser(
    id: 1,
    name: 'Test User',
    email: 'test@gateway.com',
    userType: '5S Service',
    accountStatus: 'active',
    branch: 'Gateway Manila',
  );

  group('UserFloatingHeader widget tests', () {
    testWidgets('renders brand logo, subtitle, profile, and notification button without overflow across various screen widths', (
      tester,
    ) async {
      final screenWidths = [320.0, 360.0, 390.0, 412.0, 600.0];

      for (final width in screenWidths) {
        for (final expanded in [true, false]) {
          var homeTapped = false;
          var profileTapped = false;
          var notificationsTapped = false;

          await tester.binding.setSurfaceSize(Size(width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MaterialApp(
              theme: GacTheme.light,
              home: Scaffold(
                body: SizedBox(
                  height: UserFloatingHeader.extent,
                  child: UserFloatingHeader(
                    expanded: expanded,
                    user: testUser,
                    unreadNotifications: 3,
                    onOpenHome: () => homeTapped = true,
                    onOpenProfile: () => profileTapped = true,
                    onOpenNotifications: () => notificationsTapped = true,
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify no RenderFlex overflow
          expect(tester.takeException(), isNull, reason: 'No overflow at width $width (expanded: $expanded)');

          // Verify brand button and subtitle
          expect(find.byKey(const ValueKey('user-header-home')), findsOneWidget);
          expect(find.text('Audit Compliance App'), findsOneWidget);
          expect(find.byType(Image), findsOneWidget);

          // Verify profile and notification buttons
          expect(find.byKey(const ValueKey('user-header-profile')), findsOneWidget);
          expect(find.byKey(const ValueKey('user-header-notifications')), findsOneWidget);

          // Test tap on home
          await tester.tap(find.byKey(const ValueKey('user-header-home')));
          expect(homeTapped, isTrue);

          // Test tap on profile
          await tester.tap(find.byKey(const ValueKey('user-header-profile')));
          expect(profileTapped, isTrue);

          // Test tap on notifications
          await tester.tap(find.byKey(const ValueKey('user-header-notifications')));
          expect(notificationsTapped, isTrue);
        }
      }
    });
  });
}
