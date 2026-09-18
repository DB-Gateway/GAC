import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/admin_destination.dart';
import 'config/api_config.dart';
import 'index.dart';
import 'login.dart';
import 'models/authenticated_user.dart';
import 'screens/dos_dashboard_screen.dart';
import 'screens/force_password_change_screen.dart';
import 'screens/user_notifications_screen.dart';
import 'screens/user_settings_screen.dart';
import 'services/local_notification_service.dart';
import 'services/battery_optimization_service.dart';
import 'services/session_service.dart';
import 'services/background_notification_service.dart';
import 'services/notification_service.dart';
import 'widgets/escalation_details_dialog.dart';
import 'theme/gac_theme.dart';
import 'widgets/admin_tabs_layout.dart';
import 'widgets/dos_tabs_layout.dart';
import 'widgets/user_tabs_layout.dart';

final GlobalKey<NavigatorState> gacNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> gacScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _disableDebugPaintOverlays();
  registerAdminTabRouteHandling();
  registerUserTabRouteHandling();
  String? launchPayload;
  try {
    launchPayload = await LocalNotificationService.instance.initialize(
      onNotificationTap: openNotificationPayload,
    );
    // Ensure scheduled notifications matching the last logged-in user type are active
    // even before sign-in, after app restart, or when an account has timed out.
    await LocalNotificationService.instance.syncForPreviousUser();
    // Check for incoming BOM or GM notifications, especially if remember me was on
    unawaited(LocalNotificationService.instance.syncBomGmNotifications());
    LocalNotificationService.instance.startTimedOutManagerNotificationPolling();
    await startBackgroundNotificationPolling();
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
      (_) => openNotificationPayload(pendingPayload),
    );
  }
}

void _disableDebugPaintOverlays() {
  assert(() {
    // These can be left enabled by Flutter Inspector between debug runs. They
    // draw the yellow/green lines beneath every text baseline and are not part
    // of the application's visual design.
    debugPaintBaselinesEnabled = false;
    debugPaintTextLayoutBoxes = false;
    debugPaintSizeEnabled = false;
    debugPaintLayerBordersEnabled = false;
    debugPaintPointersEnabled = false;
    debugRepaintRainbowEnabled = false;
    debugRepaintTextRainbowEnabled = false;
    return true;
  }());
}

Future<void> openNotificationPayload(
  String encodedPayload, {
  NotificationRepository? notificationRepository,
}) async {
  final payload = TaskReminderPayload.tryParse(encodedPayload);
  if (payload == null) return;

  final preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  if (payload.recipientUserId != null &&
      payload.recipientUserId != preferences.getString(gacPreviousUserIdKey)) {
    return;
  }
  if (payload.event == 'finding_escalated' && payload.notificationId != null) {
    try {
      final repository = notificationRepository ?? NotificationApiService();
      final inbox = await repository.fetchNotifications();
      final notification = inbox.notifications
          .where(
            (item) =>
                item.id == payload.notificationId &&
                item.type == 'finding_escalated',
          )
          .firstOrNull;
      if (notification == null) return;
      final context = gacNavigatorKey.currentState?.overlay?.context;
      if (context == null || !context.mounted) return;
      unawaited(
        repository
            .markRead(notification.id)
            .catchError((Object error) => inbox),
      );
      await showEscalationDetailsDialog(context, notification);
    } catch (_) {
      gacScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not load this escalation. Check your connection and try again.',
          ),
        ),
      );
    }
    return;
  }
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
      final defaultDestination =
          (user.is5sUtilities ||
              user.is5sService ||
              user.is5sSales ||
              user.isUtilities ||
              user.isSalesService5s ||
              userType == 'PIC' ||
              userType == 'PERSON IN CHARGE')
          ? '/(user)/checklists'
          : (user.isDosAuditor ? '/(dos)/dashboard' : '/(admin)/dashboard');
      destination =
          user.isDosAuditor &&
              (payload.event == 'dos_month_end_due' ||
                  payload.targetsDosChecklist)
          ? '/(dos)/audit'
          : defaultDestination;
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
      arguments:
          destination == '/(user)/checklists' || destination == '/(dos)/audit'
          ? {
              'template_slug': payload.templateSlug,
              'slot_key': payload.slotKey,
              'audit_date': payload.auditDate,
              'submission_id': payload.submissionId,
              'item_key': payload.itemKey,
              'customer_index': payload.customerIndex,
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
      builder: (context, child) =>
          SessionActivityListener(child: child ?? const SizedBox.shrink()),
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
          pageBuilder: (_, animation, secondaryAnimation) => GatewayLoginScreen(
            arrivedFromWelcome: arrivedFromWelcome,
            fromTimeout: fromTimeout,
          ),
          transitionsBuilder: (_, animation, secondaryAnimation, child) =>
              child,
        );
      case '/force-password-change':
        final arguments = settings.arguments;
        final data = arguments is Map ? arguments : const {};
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ForcePasswordChangeScreen(
            currentPassword: data['currentPassword'] as String?,
            destination: (data['destination'] as String?) ?? '/login',
            destinationArguments: data['destinationArguments'],
            rememberMe: data['rememberMe'] == true,
          ),
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
            initialChecklistSubmissionId: data['submission_id'] is num
                ? (data['submission_id'] as num).toInt()
                : null,
            initialChecklistItemKey: data['item_key'] is String
                ? data['item_key'] as String
                : null,
            initialChecklistCustomerIndex: data['customer_index'] is num
                ? (data['customer_index'] as num).toInt()
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
        final arguments = settings.arguments;
        final data = arguments is Map ? arguments : const {};
        final templateSlug = data['template_slug'];
        final initialTrack = templateSlug == 'dealer-operations-standards-sales'
            ? DosAuditTrack.sales
            : templateSlug == 'dealer-operations-standards'
            ? DosAuditTrack.aftersales
            : null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => DosTabsLayout(
            initialIndex: 1,
            initialTrack: initialTrack,
            initialAuditDate: data['audit_date'] is String
                ? data['audit_date'] as String
                : null,
            initialSubmissionId: data['submission_id'] is num
                ? (data['submission_id'] as num).toInt()
                : null,
            initialItemKey: data['item_key'] is String
                ? data['item_key'] as String
                : null,
            initialCustomerIndex: data['customer_index'] is num
                ? (data['customer_index'] as num).toInt()
                : null,
          ),
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
