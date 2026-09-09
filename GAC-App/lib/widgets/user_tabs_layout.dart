import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../platform/browser_history_stub.dart'
    if (dart.library.js_interop) '../platform/browser_history_web.dart';
import '../models/authenticated_user.dart';
import '../screens/user_checklist_detail_screen.dart';
import '../screens/user_checklists_screen.dart';
import '../screens/user_home_screen.dart';
import '../screens/user_notifications_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/user_settings_screen.dart';
import '../services/notification_service.dart';
import '../services/checklist_service.dart';
import '../services/local_notification_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';
import '../theme/gac_theme.dart';
import 'gac_surfaces.dart';
import 'user_floating_header.dart';

const _userRoutePaths = <String>[
  '/(user)/home',
  '/(user)/checklists',
  '/(user)/profile',
];

int? _userIndexForPath(String path) {
  return switch (path) {
    '/(user)/home' => 0,
    '/(user)/checklists' => 1,
    '/(user)/profile' => 2,
    _ => null,
  };
}

final _userTabRouteObserver = _UserTabRouteObserver();
bool _userTabRouteHandlingRegistered = false;

void registerUserTabRouteHandling() {
  if (!kIsWeb || _userTabRouteHandlingRegistered) return;
  WidgetsBinding.instance.addObserver(_userTabRouteObserver);
  _userTabRouteHandlingRegistered = true;
}

typedef _BrowserRouteHandler = bool Function(int index);

class _UserTabRouteObserver extends WidgetsBindingObserver {
  _BrowserRouteHandler? handler;

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final index = _userIndexForPath(routeInformation.uri.path);
    if (index == null) return false;
    return handler?.call(index) ?? false;
  }
}

class UserTabsLayout extends StatefulWidget {
  const UserTabsLayout({
    this.initialIndex = 0,
    this.profileRepository,
    this.checklistRepository,
    this.notificationController,
    this.initialChecklistSlug,
    this.initialChecklistSlotKey,
    this.initialChecklistAuditDate,
    super.key,
  }) : assert(initialIndex >= 0 && initialIndex <= 2);

  final int initialIndex;
  final ProfileRepository? profileRepository;
  final ChecklistRepository? checklistRepository;
  final UserNotificationController? notificationController;
  final String? initialChecklistSlug;
  final String? initialChecklistSlotKey;
  final String? initialChecklistAuditDate;

  @override
  State<UserTabsLayout> createState() => _UserTabsLayoutState();
}

class _UserTabsLayoutState extends State<UserTabsLayout> {
  late int _selectedIndex;
  late List<int> _navigationHistory;
  late final _BrowserRouteHandler _browserRouteHandler;
  late final ProfileRepository _profileRepository;
  late final UserNotificationController _notificationController;
  late final bool _ownsNotificationController;
  AuthenticatedUser _profile = AuthenticatedUser.fallback;

  @override
  void initState() {
    super.initState();
    _profileRepository = widget.profileRepository ?? ProfileApiService();
    _notificationController =
        widget.notificationController ?? UserNotificationController();
    _ownsNotificationController = widget.notificationController == null;
    _notificationController.addListener(_handleNotificationChange);
    unawaited(_loadCachedProfile());
    if (!_notificationController.initialized) {
      unawaited(_notificationController.load());
    }
    _browserRouteHandler = _handleBrowserRoute;
    _selectedIndex = widget.initialIndex;
    _navigationHistory = widget.initialIndex == 0
        ? <int>[0]
        : kIsWeb
        ? <int>[widget.initialIndex]
        : <int>[0, widget.initialIndex];

    if (kIsWeb && _userTabRouteHandlingRegistered) {
      _userTabRouteObserver.handler = _browserRouteHandler;
      SystemNavigator.selectMultiEntryHistory();
    }
  }

  @override
  void dispose() {
    _notificationController.removeListener(_handleNotificationChange);
    if (_ownsNotificationController) _notificationController.dispose();
    if (identical(_userTabRouteObserver.handler, _browserRouteHandler)) {
      _userTabRouteObserver.handler = null;
    }
    super.dispose();
  }

  Future<void> _loadCachedProfile() async {
    final profile = await _profileRepository.loadCachedProfile();
    if (profile == null) return;
    if (mounted) setState(() => _profile = profile);
    unawaited(_syncTaskReminders(profile, requestPermission: true));
  }

  Future<void> _syncTaskReminders(
    AuthenticatedUser profile, {
    bool requestPermission = false,
  }) async {
    try {
      final checklistRepo =
          widget.checklistRepository ?? ChecklistApiService();
      final checklists = await checklistRepo.fetchCatalog(
        date: _dateString(DateTime.now()),
      );
      await LocalNotificationService.instance.syncForUser(
        user: profile,
        checklists: checklists,
        requestPermission: requestPermission,
      );
    } catch (_) {
      // The checklist screens already surface API failures. Reminder refreshes
      // retry the next time the signed-in app is opened.
    }
  }

  String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _handleNotificationChange() {
    if (mounted) setState(() {});
  }

  void _handleProfileUpdated(AuthenticatedUser profile) {
    if (mounted) setState(() => _profile = profile);
    unawaited(_syncTaskReminders(profile));
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;

    if (index == 0) {
      _goHome();
      return;
    }

    setState(() {
      _navigationHistory.remove(index);
      _navigationHistory.add(index);
      _selectedIndex = index;
    });
    _syncBrowserRoute(index, replace: false);
  }

  void _goHome() {
    if (_selectedIndex == 0 && _navigationHistory.length == 1) return;
    setState(() {
      _selectedIndex = 0;
      _navigationHistory = <int>[0];
    });
    _syncBrowserRoute(0, replace: true);
  }

  void _goBack() {
    if (_navigationHistory.length > 1) {
      if (kIsWeb && _userTabRouteHandlingRegistered) {
        browserHistoryBack();
        return;
      }

      setState(() {
        _navigationHistory.removeLast();
        _selectedIndex = _navigationHistory.last;
      });
      return;
    }

    if (_selectedIndex != 0) _goHome();
  }

  void _openNotifications() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/(user)/notifications'),
        builder: (_) => UserNotificationsScreen(
          onOpenProfile: () => _closeSubpageAndSelect(2),
          onGoHome: () => _closeSubpageAndSelect(0),
          onOpenSettings: _replaceSubpageWithSettings,
          profile: _profile,
          controller: _notificationController,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/(user)/settings'),
        builder: (_) => UserSettingsScreen(profile: _profile),
      ),
    );
  }

  void _closeSubpageAndSelect(int index) {
    Navigator.of(context).pop();
    _selectTab(index);
  }

  void _replaceSubpageWithSettings() {
    Navigator.of(context).pop();
    _openSettings();
  }

  Future<void> _openChecklistFromHome(String slug, String auditDate) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UserChecklistDetailScreen(
          slug: slug,
          repository: widget.checklistRepository ?? ChecklistApiService(),
          auditDate: auditDate,
          user: _profile,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    SessionManager.instance.stopTracking();
    final currentProfile = _profile;
    await LocalNotificationService.instance.recordPreviousUser(currentProfile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(gacRememberMeKey, false);
    await _profileRepository.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  bool _handleBrowserRoute(int index) {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return false;
    if (_selectedIndex == index) return true;

    setState(() {
      if (index == 0) {
        _navigationHistory = <int>[0];
      } else {
        final previousPosition = _navigationHistory.lastIndexOf(index);
        if (previousPosition >= 0) {
          _navigationHistory = _navigationHistory
              .take(previousPosition + 1)
              .toList();
        } else {
          _navigationHistory.add(index);
        }
      }
      _selectedIndex = index;
    });
    return true;
  }

  void _syncBrowserRoute(int index, {required bool replace}) {
    if (!kIsWeb || !_userTabRouteHandlingRegistered) return;
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(_userRoutePaths[index]),
      replace: replace,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canHandleBack = _selectedIndex != 0 || _navigationHistory.length > 1;

    return PopScope<void>(
      canPop: !canHandleBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: GacScreenBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              UserHomeScreen(
                isActive: _selectedIndex == 0,
                onOpenChecklists: () => _selectTab(1),
                onOpenChecklist: _openChecklistFromHome,
                onOpenProfile: () => _selectTab(2),
                onOpenNotifications: _openNotifications,
                user: _profile,
                repository: widget.checklistRepository,
                unreadNotifications: _notificationController.unreadCount,
              ),
              UserChecklistsScreen(
                key: ValueKey(
                  'user_checklists_${_profile.userType}_${_profile.picAssignmentType}',
                ),
                user: _profile,
                repository: widget.checklistRepository,
                onBack: _goHome,
                initialSlug: widget.initialChecklistSlug,
                initialSlotKey: widget.initialChecklistSlotKey,
                initialAuditDate: widget.initialChecklistAuditDate,
              ),
              UserProfileScreen(
                initialProfile: _profile,
                repository: _profileRepository,
                onProfileUpdated: _handleProfileUpdated,
                onOpenSettings: _openSettings,
                onSignOut: () => unawaited(_signOut()),
                onBack: _goHome,
              ),
            ],
          ),
          bottomNavigationBar: _selectedIndex == 0
              ? _UserBottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onSelected: _selectTab,
                )
              : null,
        ),
      ),
    );
  }
}

class _UserBottomNavigationBar extends StatelessWidget {
  const _UserBottomNavigationBar({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barHeight = UserFloatingHeader.extent + bottomInset;

    return SizedBox(
      key: const ValueKey('user-bottom-navigation-bar'),
      height: barHeight,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: GacGlassSurface(
                  key: const ValueKey('user-bottom-navigation-glass'),
                  borderRadius: 22,
                  blurSigma: 5,
                  color: GacColors.glassSurfaceStrong,
                  borderColor: GacColors.glassBorder,
                  shadowBlurRadius: 25,
                  shadowOffset: const Offset(0, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SideNavigationItem(
                          label: 'Home',
                          semanticsLabel: 'Open home dashboard',
                          selected: currentIndex == 0,
                          selectedIcon: Icons.home_rounded,
                          unselectedIcon: Icons.home_outlined,
                          onTap: () => onSelected(0),
                        ),
                      ),
                      Expanded(
                        child: _SideNavigationItem(
                          label: 'Checklist',
                          semanticsLabel: 'Open checklists',
                          selected: currentIndex == 1,
                          selectedIcon: Icons.assignment_rounded,
                          unselectedIcon: Icons.assignment_outlined,
                          onTap: () => onSelected(1),
                        ),
                      ),
                      Expanded(
                        child: _SideNavigationItem(
                          label: 'Profile',
                          semanticsLabel: 'Open profile',
                          selected: currentIndex == 2,
                          selectedIcon: Icons.person_rounded,
                          unselectedIcon: Icons.person_outline_rounded,
                          onTap: () => onSelected(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideNavigationItem extends StatelessWidget {
  const _SideNavigationItem({
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GacColors.primary : GacColors.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : unselectedIcon,
                size: 22,
                color: color,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
