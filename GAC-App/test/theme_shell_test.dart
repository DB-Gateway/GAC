import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gac_flutter/admin/admin_destination.dart';
import 'package:gac_flutter/config/api_config.dart';
import 'package:gac_flutter/index.dart';
import 'package:gac_flutter/login.dart';
import 'package:gac_flutter/main.dart' as app;
import 'package:gac_flutter/models/user_notification.dart';
import 'package:gac_flutter/screens/user_notifications_screen.dart';
import 'package:gac_flutter/screens/user_settings_screen.dart';
import 'package:gac_flutter/services/notification_service.dart';
import 'package:gac_flutter/services/session_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';
import 'package:gac_flutter/widgets/admin_tabs_layout.dart';
import 'package:gac_flutter/widgets/gac_surfaces.dart';
import 'package:gac_flutter/widgets/user_tabs_layout.dart';

void setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Widget themed(Widget child) {
  return MaterialApp(theme: GacTheme.light, home: child);
}

Future<UserNotificationController> loadedNotificationController({
  int unreadCount = 0,
}) async {
  final controller = UserNotificationController(
    repository: _FakeNotificationRepository(unreadCount: unreadCount),
  );
  await controller.load();
  return controller;
}

void main() {
  test('theme carries the blush glass palette and rounded mobile shapes', () {
    final theme = GacTheme.light;
    final enabledBorder = theme.inputDecorationTheme.enabledBorder;

    expect(theme.colorScheme.primary, GacColors.primary);
    expect(theme.colorScheme.secondary, GacColors.blue);
    expect(theme.scaffoldBackgroundColor, GacColors.canvas);
    expect(
      theme.navigationBarTheme.backgroundColor,
      GacColors.glassSurfaceStrong,
    );
    expect(enabledBorder, isA<OutlineInputBorder>());
    expect(
      (enabledBorder! as OutlineInputBorder).borderRadius,
      BorderRadius.circular(15),
    );
  });

  testWidgets('launch screen presents the animated Gateway splash', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(themed(const GatewayWelcomeScreen()));
    await tester.pump();

    expect(find.byKey(const ValueKey('gateway-splash-logo')), findsOneWidget);
    expect(
      tester
          .widget<GatewayLogoBadge>(
            find.byKey(const ValueKey('gateway-splash-logo')),
          )
          .size,
      300,
    );
    expect(find.text('Gateway Audit Compliance'), findsOneWidget);
    expect(find.text('Continue to sign in'), findsNothing);
    expect(find.text('CORPORATE CHECKLIST'), findsNothing);
    expect(find.text('Welcome to\nGateway.'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(320, 568), Size(1200, 800)]) {
    testWidgets('splash remains usable at ${size.width}x${size.height}', (
      tester,
    ) async {
      setViewport(tester, size);

      await tester.pumpWidget(themed(const GatewayWelcomeScreen()));
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.byKey(const ValueKey('gateway-splash-logo')), findsOneWidget);
      expect(find.text('Continue to sign in'), findsNothing);
      expect(find.text('Welcome to\nGateway.'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('splash automatically hands off to the animated login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(const app.GacApp());
    await tester.pump();

    expect(find.byType(GatewayWelcomeScreen), findsOneWidget);
    expect(find.byType(GatewayLoginScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();

    expect(find.byType(GatewayLoginScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.byType(GatewayWelcomeScreen), findsNothing);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Audit Compliance App'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Welcome to\nGateway.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'remembered session finishes the logo Hero before opening the user shell',
    (tester) async {
      SharedPreferences.setMockInitialValues(const {
        'gac_remember_me': true,
        gacAuthTokenKey: 'remembered-token',
        gacAuthUserKey:
            '{"id":1,"name":"Alex Reyes","email":"alex@gateway.local",'
            '"branch":"Pasong Tamo","user_type":"PIC"}',
      });
      addTearDown(SessionManager.instance.stopTracking);
      setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        app.GacApp(storedSessionValidator: (_) async => true),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump();

      expect(find.byType(GatewayLoginScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GatewayLoginScreen), findsOneWidget);
      expect(find.byType(UserTabsLayout), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(UserTabsLayout), findsOneWidget);
      expect(find.byType(GatewayLoginScreen), findsNothing);
      expect(find.byType(GatewayLogoBadge), findsNothing);
      expect(find.byKey(const ValueKey('gateway-login-logo')), findsNothing);
      expect(tester.takeException(), isNull);
      SessionManager.instance.stopTracking();
    },
  );

  testWidgets('login presents the simple light sign-in composition', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(themed(const GatewayLoginScreen()));
    await tester.pump();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Audit Compliance App'), findsOneWidget);
    expect(find.text('USERNAME'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('BOM.MitsubishiSucat'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.byType(Image), findsAtLeastNWidgets(1));
    final logoAssets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((image) => image.assetName)
        .toSet();
    expect(logoAssets, contains('assets/images/Gateway_logo_circle.png'));
    expect(
      tester
          .widget<GatewayLogoBadge>(
            find.byKey(const ValueKey('gateway-login-logo')),
          )
          .size,
      180,
    );
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields, hasLength(2));
    for (final field in fields) {
      expect(field.decoration?.filled, isFalse);
      expect(field.decoration?.fillColor, Colors.transparent);
      expect(field.style?.color, GacColors.textPrimary);
    }
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(320, 568), Size(1200, 800)]) {
    testWidgets('login remains usable at ${size.width}x${size.height}', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(const {});
      setViewport(tester, size);

      await tester.pumpWidget(themed(const GatewayLoginScreen()));
      await tester.pump();

      expect(find.text('BOM.MitsubishiSucat'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('user shell uses home, checklist, and profile tabs', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(themed(const UserTabsLayout()));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Checklist'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.text('Audit Compliance App'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('user-header-notifications')),
      findsOneWidget,
    );
    expect(find.byType(GacScreenBackground), findsWidgets);
    expect(find.byType(GacGlassSurface), findsWidgets);
    expect(find.byType(GacContentPanel), findsWidgets);
    expect(find.text('USER WORKSPACE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation uses floating glass with live backdrop blur', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(themed(const UserTabsLayout()));
    await tester.pump();

    final topBarSize = tester.getSize(
      find.byKey(const ValueKey('user-home-top-bar')),
    );
    final bottomBarSize = tester.getSize(
      find.byKey(const ValueKey('user-bottom-navigation-bar')),
    );
    final bottomGlassFinder = find.byKey(
      const ValueKey('user-bottom-navigation-glass'),
    );
    final bottomGlassSize = tester.getSize(bottomGlassFinder);
    final bottomGlass = tester.widget<GacGlassSurface>(bottomGlassFinder);
    final shellScaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final homeScrollFinder = find.byKey(
      const PageStorageKey<String>('user-home-scroll'),
    );
    final homeContentPadding = tester.widget<SliverPadding>(
      find.byKey(const ValueKey('user-home-content-padding')),
    );

    expect(shellScaffold.extendBody, isTrue);
    expect(bottomBarSize.height, topBarSize.height);
    expect(bottomGlassSize, const Size(362, 64));
    expect(bottomGlass.borderRadius, 22);
    expect(bottomGlass.blurSigma, greaterThan(0));
    expect(bottomGlass.color.a, lessThan(1));
    expect(bottomGlass.shadowBlurRadius, greaterThan(0));
    expect(bottomGlass.shadowOffset, const Offset(0, 4));
    expect(
      find.descendant(
        of: bottomGlassFinder,
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
    expect(
      tester.getBottomLeft(homeScrollFinder).dy,
      greaterThan(tester.getTopLeft(bottomGlassFinder).dy),
    );
    expect(
      MediaQuery.of(tester.element(homeScrollFinder)).padding.bottom,
      bottomBarSize.height,
    );
    expect(
      homeContentPadding.padding.resolve(TextDirection.ltr).bottom,
      28 + bottomBarSize.height,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('user destinations and profile settings stay connected', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {
      gacAuthTokenKey: 'profile-token',
      gacAuthUserKey:
          '{"id":1,"name":"Alex Reyes","email":"alex@gateway.local",'
          '"branch":"Pasong Tamo","user_type":"PIC",'
          '"pic_assignment_type":"utilities",'
          '"pic_assignment_label":"Utilities","account_status":"active"}',
    });
    setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(themed(const UserTabsLayout()));
    await tester.pump();

    await tester.tap(find.text('Checklist'));
    await tester.pump();
    expect(find.text('My checklists'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('user-bottom-navigation-bar')),
      findsNothing,
    );
    expect(
      tester
          .widget<ListView>(
            find.byKey(const PageStorageKey<String>('user-checklist-scroll')),
          )
          .padding!
          .resolve(TextDirection.ltr)
          .bottom,
      24,
    );
    expect(find.byKey(const ValueKey('user-home-top-bar')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('checklist-back-button')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('user-bottom-navigation-bar')),
      findsOneWidget,
    );

    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('user-bottom-navigation-bar')),
      findsNothing,
    );
    expect(find.text('Alex Reyes'), findsOneWidget);
    expect(find.text('Workspace settings'), findsOneWidget);
    expect(
      tester
          .widget<ListView>(
            find.byKey(const PageStorageKey<String>('user-profile-scroll')),
          )
          .padding!
          .resolve(TextDirection.ltr)
          .bottom,
      24,
    );
    expect(find.byType(GacGlassSurface), findsWidgets);
    expect(find.byType(GacContentPanel), findsWidgets);
    expect(find.byKey(const ValueKey('user-home-top-bar')), findsNothing);

    await tester.drag(
      find.byKey(const PageStorageKey<String>('user-profile-scroll')),
      const Offset(0, -420),
    );
    await tester.pump();
    await tester.tap(find.text('Workspace settings'));
    await tester.pumpAndSettle();
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.byType(GacScreenBackground), findsWidgets);
    expect(find.byType(GacGlassSurface), findsWidgets);
    expect(find.byType(GacContentPanel), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating notification control opens the notification center', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844));
    final notifications = await loadedNotificationController(unreadCount: 3);
    addTearDown(notifications.dispose);

    await tester.pumpWidget(
      themed(UserTabsLayout(notificationController: notifications)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('user-header-notifications')));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('3 unread updates'), findsOneWidget);
    expect(find.byType(GacScreenBackground), findsWidgets);
    expect(find.byType(GacGlassSurface), findsWidgets);
    expect(find.byType(GacContentPanel), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(320, 568), Size(1200, 800)]) {
    testWidgets('user notification and settings glass layouts fit '
        '${size.width}x${size.height}', (tester) async {
      setViewport(tester, size);
      final notifications = await loadedNotificationController();
      addTearDown(notifications.dispose);

      await tester.pumpWidget(
        themed(
          UserNotificationsScreen(
            onOpenProfile: () {},
            onGoHome: () {},
            onOpenSettings: () {},
            controller: notifications,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byType(GacGlassSurface), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(themed(const UserSettingsScreen()));
      await tester.pump();

      expect(find.text('Workspace settings'), findsOneWidget);
      expect(find.byType(GacGlassSurface), findsWidgets);
      expect(find.byType(GacContentPanel), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Home top bar compacts down and expands while scrolling up', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(themed(const UserTabsLayout()));
    await tester.pump();

    double profileIconSize() => tester
        .getSize(find.byKey(const ValueKey('user-home-profile-icon')))
        .width;

    expect(profileIconSize(), 44);

    await tester.drag(
      find.byKey(const PageStorageKey<String>('user-home-scroll')),
      const Offset(0, -320),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(profileIconSize(), 32);
    expect(find.byKey(const ValueKey('user-home-top-bar')), findsOneWidget);

    await tester.drag(
      find.byKey(const PageStorageKey<String>('user-home-scroll')),
      const Offset(0, 80),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(profileIconSize(), 44);

    await tester.drag(
      find.byKey(const PageStorageKey<String>('user-home-scroll')),
      const Offset(0, -80),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(profileIconSize(), 32);

    await tester.drag(
      find.byKey(const PageStorageKey<String>('user-home-scroll')),
      const Offset(0, 1200),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(profileIconSize(), 44);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide user viewport still uses the Android tab structure', (
    tester,
  ) async {
    setViewport(tester, const Size(1200, 800));

    await tester.pumpWidget(themed(const UserTabsLayout()));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Checklist'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.text('USER WORKSPACE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final destination in AdminDestination.values) {
    testWidgets('admin ${destination.name} keeps the mobile shell', (
      tester,
    ) async {
      setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        themed(AdminTabsLayout(initialDestination: destination)),
      );
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('DOS & 5S'), findsOneWidget);
      expect(find.text('Reports & Users'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('wide admin viewport does not introduce a website sidebar', (
    tester,
  ) async {
    setViewport(tester, const Size(1200, 800));

    await tester.pumpWidget(themed(const AdminTabsLayout()));
    await tester.pump();

    expect(find.text('Administrator Dashboard'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Audit Compliance Command Center'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({required int unreadCount})
    : _notifications = [
        for (var index = 0; index < unreadCount; index++)
          UserNotification(
            id: 'notification-$index',
            type: 'task_assigned',
            title: 'Task update ${index + 1}',
            message: 'A Gateway checklist has an update.',
            unread: true,
            data: const {},
            createdAt: DateTime.now(),
          ),
      ];

  List<UserNotification> _notifications;

  @override
  Future<NotificationInbox> fetchNotifications() async => NotificationInbox(
    notifications: List.unmodifiable(_notifications),
    unreadCount: _notifications.where((item) => item.unread).length,
  );

  @override
  Future<NotificationInbox> markRead(String id) async {
    _notifications = [
      for (final item in _notifications)
        if (item.id == id) item.markRead() else item,
    ];
    return NotificationInbox(
      notifications: [_notifications.firstWhere((item) => item.id == id)],
      unreadCount: _notifications.where((item) => item.unread).length,
    );
  }

  @override
  Future<int> markAllRead() async {
    _notifications = _notifications.map((item) => item.markRead()).toList();
    return 0;
  }
}
