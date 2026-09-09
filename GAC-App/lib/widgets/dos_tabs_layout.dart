import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/authenticated_user.dart';
import '../screens/dos_dashboard_screen.dart';
import '../screens/user_checklist_detail_screen.dart';
import '../screens/user_checklists_screen.dart';
import '../screens/user_home_screen.dart';
import '../screens/user_notifications_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/user_settings_screen.dart';
import '../services/checklist_service.dart';
import '../services/dos_checklist_service.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';
import '../theme/gac_theme.dart';
import 'gac_surfaces.dart';

class DosTabsLayout extends StatefulWidget {
  const DosTabsLayout({
    this.initialIndex = 0,
    this.initialTrack,
    this.profileRepository,
    this.notificationController,
    this.checklistRepository,
    super.key,
  }) : assert(initialIndex >= 0 && initialIndex <= 2);

  final int initialIndex;
  final DosAuditTrack? initialTrack;
  final ProfileRepository? profileRepository;
  final UserNotificationController? notificationController;
  final ChecklistRepository? checklistRepository;

  @override
  State<DosTabsLayout> createState() => _DosTabsLayoutState();
}

class _DosTabsLayoutState extends State<DosTabsLayout> {
  late int _selectedIndex;
  late DosAuditTrack _activeTrack;
  String _activeAuditSlug = 'dealer-operations-standards';
  String? _activeAuditDate;
  String? _activeCategoryFilter;
  int? _activeSectionIndex;
  int? _activeQuestionIndex;
  late bool _isViewingAuditDetail;
  bool _hasExplicitlyNavigated = false;
  late final ProfileRepository _profileRepository;
  late final ChecklistRepository _baseChecklistRepository;
  late ChecklistRepository _checklistRepository;
  late final UserNotificationController _notificationController;
  late final bool _ownsNotificationController;
  AuthenticatedUser _profile = const AuthenticatedUser(
    id: 0,
    name: 'Gateway DOS User',
    email: '',
    userType: 'DOS',
    accountStatus: 'active',
  );

  static String _slugForTrack(DosAuditTrack track) =>
      track == DosAuditTrack.aftersales
      ? 'dealer-operations-standards'
      : 'dealer-operations-standards-sales';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _isViewingAuditDetail = widget.initialIndex == 1;
    _activeTrack = widget.initialTrack ?? DosAuditTrack.sales;
    _activeAuditSlug = _slugForTrack(_activeTrack);
    _profileRepository = widget.profileRepository ?? ProfileApiService();
    _baseChecklistRepository =
        widget.checklistRepository ?? ChecklistApiService();
    _checklistRepository = DosChecklistService(
      user: _profile,
      delegate: _baseChecklistRepository,
    );
    _notificationController =
        widget.notificationController ?? UserNotificationController();
    _ownsNotificationController = widget.notificationController == null;
    _notificationController.addListener(_handleNotificationChange);
    unawaited(_loadProfile());
    if (!_notificationController.initialized) {
      unawaited(_notificationController.load());
    }
  }

  @override
  void dispose() {
    _notificationController.removeListener(_handleNotificationChange);
    if (_ownsNotificationController) {
      _notificationController.dispose();
    }
    super.dispose();
  }

  void _handleNotificationChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    try {
      final cached = await _profileRepository.loadCachedProfile();
      if (cached != null) _applyProfile(cached);
    } catch (_) {
      // A missing or stale cache is harmless; the API remains authoritative.
    }

    try {
      final profile = await _profileRepository.fetchProfile();
      _applyProfile(profile);
    } catch (_) {
      // Continue with the authenticated profile cached at login when offline.
    }
  }

  void _applyProfile(AuthenticatedUser profile) {
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _checklistRepository = DosChecklistService(
        user: profile,
        delegate: _baseChecklistRepository,
      );
      if (profile.isDosAftersales) {
        _activeTrack = DosAuditTrack.aftersales;
      } else if (profile.isDosSales) {
        _activeTrack = DosAuditTrack.sales;
      } else if (widget.initialTrack != null) {
        _activeTrack = widget.initialTrack!;
      }
      _activeAuditSlug = _slugForTrack(_activeTrack);
    });
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (index == 1) {
        _activeAuditSlug = _slugForTrack(_activeTrack);
        _isViewingAuditDetail = false;
        _activeCategoryFilter = null;
        _activeSectionIndex = null;
      }
      _selectedIndex = index;
    });
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => UserNotificationsScreen(
          onOpenProfile: () {
            Navigator.of(context).pop();
            setState(() => _selectedIndex = 2);
          },
          onGoHome: () {
            Navigator.of(context).pop();
            setState(() => _selectedIndex = 0);
          },
          onOpenSettings: () {
            Navigator.of(context).pop();
            _openSettings();
          },
          profile: _profile,
          controller: _notificationController,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UserSettingsScreen(profile: _profile),
      ),
    );
  }

  Future<void> _signOut() async {
    SessionManager.instance.stopTracking();
    await LocalNotificationService.instance.recordPreviousUser(_profile);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(gacRememberMeKey, false);
    await _profileRepository.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _openAssignedAudit(String slug, String auditDate) {
    final track = slug == 'dealer-operations-standards-sales'
        ? DosAuditTrack.sales
        : DosAuditTrack.aftersales;
    setState(() {
      _activeTrack = track;
      _activeAuditSlug = slug;
      _activeAuditDate = auditDate;
      _activeCategoryFilter = null;
      _activeSectionIndex = null;
      _isViewingAuditDetail = true;
      _hasExplicitlyNavigated = true;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canHandleBack = _selectedIndex != 0 || _isViewingAuditDetail;

    return PopScope<void>(
      canPop: !canHandleBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            if (_isViewingAuditDetail) {
              if (widget.initialIndex == 1 && !_hasExplicitlyNavigated) {
                _selectedIndex = 0;
              }
              _isViewingAuditDetail = false;
              _activeCategoryFilter = null;
              _activeSectionIndex = null;
            } else {
              _selectedIndex = 0;
            }
          });
        }
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
                user: _profile,
                repository: _checklistRepository,
                unreadNotifications: _notificationController.unreadCount,
                onOpenChecklists: () => setState(() {
                  _selectedIndex = 1;
                  _isViewingAuditDetail = false;
                  _activeCategoryFilter = null;
                  _activeSectionIndex = null;
                }),
                onOpenChecklist: _openAssignedAudit,
                onOpenProfile: () => setState(() => _selectedIndex = 2),
                onOpenNotifications: _openNotifications,
                activeTrack: _activeTrack,
                onTrackChanged: (track) {
                  setState(() {
                    _activeTrack = track;
                    _activeAuditSlug = _slugForTrack(track);
                  });
                },
              ),
              _isViewingAuditDetail
                  ? UserChecklistDetailScreen(
                      key: ValueKey(
                        '${_activeAuditSlug}_${_activeAuditDate}_${_activeCategoryFilter}_${_activeSectionIndex}_${_profile.userType}',
                      ),
                      slug: _activeAuditSlug,
                      categoryFilter: _activeCategoryFilter,
                      onCategoryFilterChanged: (newCategory) {
                        setState(() {
                          _activeCategoryFilter = newCategory;
                          _activeSectionIndex = null;
                          _activeQuestionIndex = null;
                        });
                      },
                      initialSectionIndex: _activeSectionIndex,
                      initialQuestionIndex: _activeQuestionIndex,
                      repository: _checklistRepository,
                      auditDate: _activeAuditDate,
                      onBack: () {
                        setState(() {
                          if (widget.initialIndex == 1 &&
                              !_hasExplicitlyNavigated) {
                            _selectedIndex = 0;
                          }
                          _isViewingAuditDetail = false;
                          _activeCategoryFilter = null;
                          _activeSectionIndex = null;
                          _activeQuestionIndex = null;
                        });
                      },
                      user: _profile,
                      activeTrack: _activeTrack,
                      onTrackChanged: (track) {
                        setState(() {
                          _activeTrack = track;
                          _activeAuditSlug = _slugForTrack(track);
                        });
                      },
                      isCurrentTab: _selectedIndex == 1,
                    )
                  : UserChecklistsScreen(
                      key: ValueKey(
                        'dos_checklists_${_activeTrack}_${_activeAuditSlug}_${_profile.userType}',
                      ),
                      user: _profile,
                      repository: _checklistRepository,
                      activeTrack: _activeTrack,
                      onTrackChanged: (track) {
                        setState(() {
                          _activeTrack = track;
                          _activeAuditSlug = _slugForTrack(track);
                        });
                      },
                      onOpenChecklist: (slug) {
                        setState(() {
                          _activeAuditSlug = slug;
                          _activeTrack =
                              slug == 'dealer-operations-standards-sales'
                              ? DosAuditTrack.sales
                              : DosAuditTrack.aftersales;
                          _isViewingAuditDetail = true;
                          _activeCategoryFilter = null;
                          _activeSectionIndex = null;
                          _activeQuestionIndex = null;
                        });
                      },
                      onOpenCategoryChecklist:
                          (slug, {categoryFilter, sectionIndex, initialQuestionIndex}) {
                            setState(() {
                              _activeAuditSlug = slug;
                              _activeTrack =
                                  slug == 'dealer-operations-standards-sales'
                                  ? DosAuditTrack.sales
                                  : DosAuditTrack.aftersales;
                              _isViewingAuditDetail = true;
                              _activeCategoryFilter = categoryFilter;
                              _activeSectionIndex = sectionIndex;
                              _activeQuestionIndex = initialQuestionIndex;
                            });
                          },
                      onBack: () => setState(() => _selectedIndex = 0),
                    ),
              UserProfileScreen(
                initialProfile: _profile,
                repository: _profileRepository,
                onProfileUpdated: _applyProfile,
                onOpenSettings: _openSettings,
                onSignOut: () => unawaited(_signOut()),
                onBack: () => setState(() => _selectedIndex = 0),
              ),
            ],
          ),
          bottomNavigationBar: _selectedIndex == 0
              ? _DosBottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onSelected: _onTabTapped,
                )
              : null,
        ),
      ),
    );
  }
}

class _DosBottomNavigationBar extends StatelessWidget {
  const _DosBottomNavigationBar({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const barHeight = 76.0;

    return SizedBox(
      key: const ValueKey('dos-bottom-navigation-bar'),
      height: barHeight + bottomInset,
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
                  key: const ValueKey('dos-bottom-navigation-glass'),
                  borderRadius: 22,
                  blurSigma: 5,
                  color: GacColors.glassSurfaceStrong,
                  borderColor: GacColors.glassBorder,
                  shadowBlurRadius: 25,
                  shadowOffset: const Offset(0, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DosNavigationItem(
                          label: 'Home',
                          semanticsLabel: 'Open DOS dashboard',
                          selected: currentIndex == 0,
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home_rounded,
                          onTap: () => onSelected(0),
                        ),
                      ),
                      Expanded(
                        child: _DosNavigationItem(
                          label: 'Checklist',
                          semanticsLabel: 'Open checklist audit',
                          selected: currentIndex == 1,
                          icon: Icons.fact_check_outlined,
                          selectedIcon: Icons.fact_check_outlined,
                          onTap: () => onSelected(1),
                        ),
                      ),
                      Expanded(
                        child: _DosNavigationItem(
                          label: 'Profile',
                          semanticsLabel: 'Open profile',
                          selected: currentIndex == 2,
                          icon: Icons.person_outline_rounded,
                          selectedIcon: Icons.person_outline_rounded,
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

class _DosNavigationItem extends StatelessWidget {
  const _DosNavigationItem({
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
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
              Icon(selected ? selectedIcon : icon, size: 22, color: color),
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
