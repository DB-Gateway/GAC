import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/admin_destination.dart';
import 'config/api_config.dart';
import 'index.dart';
import 'login.dart';
import 'models/authenticated_user.dart';
import 'screens/user_notifications_screen.dart';
import 'screens/user_settings_screen.dart';
import 'services/local_notification_service.dart';
import 'services/battery_optimization_service.dart';
import 'services/session_service.dart';
import 'theme/gac_theme.dart';
import 'widgets/admin_tabs_layout.dart';
import 'widgets/dos_tabs_layout.dart';
import 'widgets/user_tabs_layout.dart';

final GlobalKey<NavigatorState> gacNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> gacScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerAdminTabRouteHandling();
  registerUserTabRouteHandling();
  String? launchPayload;
  try {
    launchPayload = await LocalNotificationService.instance.initialize(
      onNotificationTap: _openNotificationPayload,
    );
    // Ensure scheduled notifications matching the last logged-in user type are active
    // even before sign-in, after app restart, or when an account has timed out.
    await LocalNotificationService.instance.syncForPreviousUser();
  } catch (_) {
    // Notification setup must never prevent the audit app from opening.
  }
  // Request battery-optimization exemption so notifications and background
  // work survive Doze mode.  The system dialog is only shown when the app
  // is not yet exempt.
  try {
    await BatteryOptimizationService.instance.ensureExempt();
  } catch (_) {
    // Must never block the app from opening.
  }
  runApp(const GacApp());
  if (launchPayload != null && launchPayload.isNotEmpty) {
    final pendingPayload = launchPayload;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openNotificationPayload(pendingPayload),
    );
  }
}
Future<void> _openNotificationPayload(String encodedPayload) async {
  final payload = TaskReminderPayload.tryParse(encodedPayload);
  if (payload == null) return;

  final preferences = await SharedPreferences.getInstance();
  final rememberMe = preferences.getBool(gacRememberMeKey) ?? false;
  final token = preferences.getString(gacAuthTokenKey);
  final encodedUser = preferences.getString(gacAuthUserKey);

  final canDirectEnter =
      rememberMe &&
      token != null &&
      token.trim().isNotEmpty &&
      encodedUser != null;

  String destination = '/login';
  if (canDirectEnter) {
    try {
      final user = AuthenticatedUser.fromJson(jsonDecode(encodedUser));
      final userType = user.userType.trim().toUpperCase();
      destination = (user.is5sUtilities ||
              user.is5sService ||
              user.is5sSales ||
              user.isUtilities ||
              user.isSalesService5s ||
              userType == 'PIC' ||
              userType == 'PERSON IN CHARGE')
          ? '/(user)/checklists'
          : (user.isDosAuditor
              ? '/(dos)/dashboard'
              : '/(admin)/dashboard');
    } catch (_) {
      destination = '/login';
    }
  } else {
    await LocalNotificationService.instance.setPendingPayload(payload);
  }

  void navigate() {
    final navigator = gacNavigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
      return;
    }
    navigator.pushNamedAndRemoveUntil(
      destination,
      (route) => false,
      arguments: destination == '/(user)/checklists'
          ? {
              'template_slug': payload.templateSlug,
              'slot_key': payload.slotKey,
              'audit_date': payload.auditDate,
            }
          : null,
    );
  }

  navigate();
}

class GacApp extends StatelessWidget {
  const GacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: gacNavigatorKey,
      scaffoldMessengerKey: gacScaffoldMessengerKey,
      title: 'Gateway Audit Compliance',
      debugShowCheckedModeBanner: false,
      theme: GacTheme.light,
      onGenerateRoute: _routeFor,
      builder: (context, child) => SessionActivityListener(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  bool _arrivedFromWelcome(Object? arguments) {
    if (arguments is! Map) return false;
    final value = arguments['fromWelcome'];
    return value == '1' || (value is Iterable && value.contains('1'));
  }

  bool _fromTimeout(Object? arguments) {
    if (arguments is! Map) return false;
    final value = arguments['fromTimeout'];
    return value == '1' || (value is Iterable && value.contains('1'));
  }

  Route<dynamic>? _routeFor(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GatewayWelcomeScreen(),
        );
      case '/login':
        final arrivedFromWelcome = _arrivedFromWelcome(settings.arguments);
        final fromTimeout = _fromTimeout(settings.arguments);
        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: arrivedFromWelcome
              ? const Duration(milliseconds: 1050)
              : Duration.zero,
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, animation, secondaryAnimation) =>
              GatewayLoginScreen(
                arrivedFromWelcome: arrivedFromWelcome,
                fromTimeout: fromTimeout,
              ),
          transitionsBuilder: (_, animation, secondaryAnimation, child) =>
              child,
        );
      case '/(user)/home':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const UserTabsLayout(),
        );
      case '/(user)/checklists':
        final arguments = settings.arguments;
        final data = arguments is Map ? arguments : const {};
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => UserTabsLayout(
            initialIndex: 1,
            initialChecklistSlug: data['template_slug'] is String
                ? data['template_slug'] as String
                : null,
            initialChecklistSlotKey: data['slot_key'] is String
                ? data['slot_key'] as String
                : null,
            initialChecklistAuditDate: data['audit_date'] is String
                ? data['audit_date'] as String
                : null,
          ),
        );
      case '/(user)/profile':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const UserTabsLayout(initialIndex: 2),
        );
      case '/(user)/notifications':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => UserNotificationsScreen(
            onOpenProfile: () =>
                Navigator.of(context).pushReplacementNamed('/(user)/profile'),
            onGoHome: () =>
                Navigator.of(context).pushReplacementNamed('/(user)/home'),
            onOpenSettings: () =>
                Navigator.of(context).pushReplacementNamed('/(user)/settings'),
          ),
        );
      case '/(user)/settings':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const UserSettingsScreen(),
        );
      case '/(dos)/dashboard':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const DosTabsLayout(),
        );
      case '/(dos)/audit':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const DosTabsLayout(initialIndex: 1),
        );
      case '/(admin)/dashboard':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminTabsLayout(),
        );
      case '/(admin)/dos':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              const AdminTabsLayout(initialDestination: AdminDestination.dos),
        );
      case '/(admin)/five-s':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              const AdminTabsLayout(initialDestination: AdminDestination.fiveS),
        );
      case '/(admin)/reports':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminTabsLayout(
            initialDestination: AdminDestination.reports,
          ),
        );
      case '/(admin)/users':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              const AdminTabsLayout(initialDestination: AdminDestination.users),
        );
      case '/(admin)/notifications':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminTabsLayout(
            initialDestination: AdminDestination.notifications,
          ),
        );
      case '/(admin)/profile':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminTabsLayout(
            initialDestination: AdminDestination.profile,
          ),
        );
      case '/(admin)/settings':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AdminTabsLayout(
            initialDestination: AdminDestination.settings,
          ),
        );
    }

    return null;
  }
}

/// Listens for user gestures (touch/pointer events) and app lifecycle state
/// changes across all screens to keep active sessions alive or trigger timeouts.
class SessionActivityListener extends StatefulWidget {
  final Widget child;
  const SessionActivityListener({required this.child, super.key});

  @override
  State<SessionActivityListener> createState() =>
      _SessionActivityListenerState();
}

class _SessionActivityListenerState extends State<SessionActivityListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SessionManager.instance.handleAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SessionManager.instance.recordUserActivity(),
      onPointerMove: (_) => SessionManager.instance.recordUserActivity(),
      child: widget.child,
    );
  }
}
