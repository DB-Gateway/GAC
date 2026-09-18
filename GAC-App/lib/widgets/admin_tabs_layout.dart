import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../admin/admin_destination.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_dos_screen.dart';
import '../screens/admin_five_s_screen.dart';
import '../screens/admin_notifications_screen.dart';
import '../screens/admin_profile_screen.dart';
import '../screens/admin_reports_screen.dart';
import '../screens/admin_settings_screen.dart';
import '../screens/admin_users_screen.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../theme/gac_theme.dart';
import 'gac_surfaces.dart';

class AdminNotificationScope
    extends InheritedNotifier<UserNotificationController> {
  const AdminNotificationScope({
    required UserNotificationController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static UserNotificationController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdminNotificationScope>()
        ?.notifier;
  }
}

final _adminTabRouteObserver = _AdminTabRouteObserver();
bool _adminTabRouteHandlingRegistered = false;

void registerAdminTabRouteHandling() {
  if (!kIsWeb || _adminTabRouteHandlingRegistered) return;
  WidgetsBinding.instance.addObserver(_adminTabRouteObserver);
  _adminTabRouteHandlingRegistered = true;
}

typedef _AdminBrowserRouteHandler = bool Function(AdminDestination destination);

class _AdminTabRouteObserver extends WidgetsBindingObserver {
  _AdminBrowserRouteHandler? handler;

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final destination = AdminDestination.fromPath(routeInformation.uri.path);
    if (destination == null) return false;
    return handler?.call(destination) ?? false;
  }
}

class AdminTabsLayout extends StatefulWidget {
  const AdminTabsLayout({
    this.initialDestination = AdminDestination.dashboard,
    this.notificationController,
    super.key,
  });

  final AdminDestination initialDestination;
  final UserNotificationController? notificationController;

  @override
  State<AdminTabsLayout> createState() => _AdminTabsLayoutState();
}

class _AdminTabsLayoutState extends State<AdminTabsLayout> {
  late AdminDestination _selectedDestination;
  late List<AdminDestination> _navigationHistory;
  late final _AdminBrowserRouteHandler _browserRouteHandler;
  late final UserNotificationController _notificationController;
  late final bool _ownsNotificationController;

  @override
  void initState() {
    super.initState();
    _notificationController =
        widget.notificationController ?? UserNotificationController();
    _ownsNotificationController = widget.notificationController == null;
    if (!_notificationController.initialized) {
      unawaited(_notificationController.load());
    }
    _browserRouteHandler = _handleBrowserRoute;
    _selectedDestination = widget.initialDestination;
    _navigationHistory = widget.initialDestination == AdminDestination.dashboard
        ? <AdminDestination>[AdminDestination.dashboard]
        : kIsWeb
        ? <AdminDestination>[widget.initialDestination]
        : <AdminDestination>[
            AdminDestination.dashboard,
            widget.initialDestination,
          ];

    if (kIsWeb && _adminTabRouteHandlingRegistered) {
      _adminTabRouteObserver.handler = _browserRouteHandler;
      SystemNavigator.selectMultiEntryHistory();
    }
    unawaited(LocalNotificationService.instance.syncForPreviousUser());
  }

  @override
  void dispose() {
    if (_ownsNotificationController) {
      _notificationController.dispose();
    }
    if (identical(_adminTabRouteObserver.handler, _browserRouteHandler)) {
      _adminTabRouteObserver.handler = null;
    }
    super.dispose();
  }

  void _navigate(AdminDestination destination) {
    if (_selectedDestination == destination) return;
    if (destination == AdminDestination.dashboard) {
      _goToDashboard();
      return;
    }

    setState(() {
      _navigationHistory.remove(destination);
      _navigationHistory.add(destination);
      _selectedDestination = destination;
    });
    _syncBrowserRoute(destination, replace: false);
  }

  void _goToDashboard() {
    if (_selectedDestination == AdminDestination.dashboard &&
        _navigationHistory.length == 1) {
      return;
    }
    setState(() {
      _selectedDestination = AdminDestination.dashboard;
      _navigationHistory = <AdminDestination>[AdminDestination.dashboard];
    });
    _syncBrowserRoute(AdminDestination.dashboard, replace: true);
  }

  bool _handleBrowserRoute(AdminDestination destination) {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return false;
    if (_selectedDestination == destination) return true;

    setState(() {
      if (destination == AdminDestination.dashboard) {
        _navigationHistory = <AdminDestination>[AdminDestination.dashboard];
      } else {
        final previousPosition = _navigationHistory.lastIndexOf(destination);
        if (previousPosition >= 0) {
          _navigationHistory = _navigationHistory
              .take(previousPosition + 1)
              .toList();
        } else {
          _navigationHistory.add(destination);
        }
      }
      _selectedDestination = destination;
    });
    return true;
  }

  void _syncBrowserRoute(
    AdminDestination destination, {
    required bool replace,
  }) {
    if (!kIsWeb || !_adminTabRouteHandlingRegistered) return;
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(destination.route),
      replace: replace,
    );
  }

  void _signOut() {
    SessionManager.instance.stopTracking();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  int get _selectedIndex => _selectedDestination.index;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final canHandleBack =
        _selectedDestination != AdminDestination.dashboard ||
        _navigationHistory.length > 1;

    return AdminNotificationScope(
      controller: _notificationController,
      child: PopScope<void>(
        canPop: !canHandleBack,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _goToDashboard();
        },
        child: Scaffold(
          extendBody: true,
          backgroundColor: GacColors.canvas,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              AdminDashboardScreen(
                onNavigate: _navigate,
                controller: _notificationController,
              ),
              AdminDosScreen(onNavigate: _navigate),
              AdminFiveSScreen(onNavigate: _navigate),
              AdminReportsScreen(onNavigate: _navigate),
              AdminUsersScreen(onNavigate: _navigate),
              AdminNotificationsScreen(
                onNavigate: _navigate,
                controller: _notificationController,
              ),
              AdminProfileScreen(onNavigate: _navigate, onSignOut: _signOut),
              AdminSettingsScreen(onNavigate: _navigate),
            ],
          ),
          bottomNavigationBar: keyboardVisible
              ? null
              : _AdminBottomNavigationBar(
                  destination: _selectedDestination,
                  onSelected: _navigate,
                ),
        ),
      ),
    );
  }
}

class _AdminBottomNavigationBar extends StatelessWidget {
  const _AdminBottomNavigationBar({
    required this.destination,
    required this.onSelected,
  });

  final AdminDestination destination;
  final AdminNavigationCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final height = isIos ? 88.0 : 78.0;
    final bottomPadding = isIos ? 15.0 : 9.0;
    final checklistSelected =
        destination == AdminDestination.dos ||
        destination == AdminDestination.fiveS;
    final reportsSelected =
        destination == AdminDestination.reports ||
        destination == AdminDestination.users;

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SizedBox(
          height: height,
          child: GacGlassSurface(
            padding: EdgeInsets.fromLTRB(4, 9, 4, bottomPadding),
            borderRadius: 0,
            color: GacColors.glassSurfaceStrong,
            shadowOffset: const Offset(0, -8),
            child: Row(
              children: [
                Expanded(
                  child: _AdminNavigationItem(
                    label: 'Dashboard',
                    accessibilityLabel: 'Administrator dashboard',
                    selected: destination == AdminDestination.dashboard,
                    icon: Icons.grid_view_outlined,
                    selectedIcon: Icons.grid_view_rounded,
                    onTap: () => onSelected(AdminDestination.dashboard),
                  ),
                ),
                Expanded(
                  child: _AdminNavigationItem(
                    label: 'DOS & 5S',
                    accessibilityLabel: 'DOS and 5S checklist workspace',
                    selected: checklistSelected,
                    icon: Icons.assignment_outlined,
                    selectedIcon: Icons.assignment_rounded,
                    onTap: () => onSelected(AdminDestination.dos),
                  ),
                ),
                Expanded(
                  child: _AdminNavigationItem(
                    label: 'Reports & Users',
                    accessibilityLabel: 'Reports and user management',
                    selected: reportsSelected,
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart_rounded,
                    onTap: () => onSelected(AdminDestination.reports),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavigationItem extends StatelessWidget {
  const _AdminNavigationItem({
    required this.label,
    required this.accessibilityLabel,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  final String label;
  final String accessibilityLabel;
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GacColors.primary : GacColors.gray;
    return Semantics(
      button: true,
      selected: selected,
      label: accessibilityLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
