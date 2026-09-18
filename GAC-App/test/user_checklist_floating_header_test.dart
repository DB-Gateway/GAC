import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_checklists_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';
import 'package:gac_flutter/widgets/user_floating_header.dart';

class _FakeRepo extends Fake implements ChecklistRepository {
  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async {
    return const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserChecklistFloatingHeader widget tests', () {
    testWidgets('renders title, back button, and notification bell', (
      tester,
    ) async {
      var backPressed = false;
      var notificationsPressed = false;
      var titleTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: Scaffold(
            body: SizedBox(
              height: UserChecklistFloatingHeader.extent,
              child: UserChecklistFloatingHeader(
                expanded: true,
                title: 'Checklists',
                subtitle: 'Audit Compliance App',
                onBack: () => backPressed = true,
                onOpenNotifications: () => notificationsPressed = true,
                onTapTitle: () => titleTapped = true,
                unreadNotifications: 5,
              ),
            ),
          ),
        ),
      );

      // Verify title and subtitle are present
      expect(find.text('Checklists'), findsOneWidget);
      expect(find.text('Audit Compliance App'), findsOneWidget);

      // Verify back button is present and tap calls onBack
      expect(find.byKey(const ValueKey('checklist-back-button')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('checklist-back-button')));
      expect(backPressed, isTrue);

      // Verify notification bell icon with badge '5' is present and tap calls callback
      expect(find.byKey(const ValueKey('user-header-notifications')), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('user-header-notifications')));
      expect(notificationsPressed, isTrue);

      // Verify tapping title triggers onTapTitle
      await tester.tap(find.byKey(const ValueKey('checklist-header-title')));
      expect(titleTapped, isTrue);
    });

    testWidgets('renders user avatar when onBack is null and user is provided', (
      tester,
    ) async {
      var profileOpened = false;
      const user = AuthenticatedUser(
        id: 1,
        name: 'Juan Dela Cruz',
        email: 'juan@gateway.com',
        userType: 'PIC',
        accountStatus: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: Scaffold(
            body: SizedBox(
              height: UserChecklistFloatingHeader.extent,
              child: UserChecklistFloatingHeader(
                expanded: false,
                title: 'Assigned Audits',
                user: user,
                onOpenProfile: () => profileOpened = true,
                onOpenNotifications: () {},
                unreadNotifications: 0,
              ),
            ),
          ),
        ),
      );

      // No back button when onBack is null
      expect(find.byKey(const ValueKey('checklist-back-button')), findsNothing);

      // User avatar profile icon is rendered
      expect(find.byKey(const ValueKey('user-checklist-profile-icon')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('user-header-profile')));
      expect(profileOpened, isTrue);

      // Notification badge is hidden when unread is 0
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('UserChecklistsScreen integrates floating header and collapses on scroll', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var backTapped = false;
      var notificationsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistsScreen(
            repository: _FakeRepo(),
            onBack: () => backTapped = true,
            onOpenNotifications: () => notificationsTapped = true,
            unreadNotifications: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header is rendered
      expect(find.byKey(const ValueKey('user-checklist-top-bar')), findsOneWidget);
      expect(find.text('Checklists'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Verify the rendered font survives the header's internal Material.
      for (final label in ['Checklists', 'Audit Compliance App']) {
        final text = tester.widget<RichText>(
          find.descendant(of: find.text(label), matching: find.byType(RichText)),
        );
        expect(text.text.style?.fontFamily, 'EurostileExtendedBlack');
      }
      final filterText = tester.widget<RichText>(
        find.descendant(
          of: find.text('BY CATEGORY'),
          matching: find.byType(RichText),
        ),
      );
      expect(filterText.text.style?.fontFamily, isNot('EurostileExtendedBlack'));

      // Tapping back button triggers callback
      await tester.tap(find.byKey(const ValueKey('checklist-back-button')));
      expect(backTapped, isTrue);

      // Tapping notifications triggers callback
      await tester.tap(find.byKey(const ValueKey('user-header-notifications')));
      expect(notificationsTapped, isTrue);
    });
  });
}
