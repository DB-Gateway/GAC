import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/api_config.dart';
import '../models/authenticated_user.dart';
import '../services/battery_optimization_service.dart';
import '../services/local_notification_service.dart';
import '../services/profile_service.dart';
import '../services/security_service.dart';
import '../theme/gac_theme.dart';
import '../widgets/gac_surfaces.dart';
import '../widgets/pin_dialogs.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({this.onBack, this.profile, super.key});

  final VoidCallback? onBack;
  final AuthenticatedUser? profile;

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen>
    with WidgetsBindingObserver {
  bool _notificationsEnabled = true;
  bool _remindersEnabled = true;
  int _leadTimeMinutes = gacDefaultReminderLeadTimeMinutes;
  bool _batteryOptimizationIgnored = false;
  bool _compactMode = false;
  bool _loadingPreferences = true;
  String? _assignment;
  TaskReminderKind? _sendingTest;
  bool _schedulingTest = false;
  String? _manufacturer;

  bool _hasPin = false;
  bool _biometricsSupported = false;
  bool _biometricsEnabled = false;
  String _detectedDeviceTime = '';
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadPreferences());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkBatteryOptimization());
    }
  }

  Future<void> _checkBatteryOptimization() async {
    final ignored = await BatteryOptimizationService.instance
        .isIgnoringBatteryOptimizations();
    if (mounted && ignored != _batteryOptimizationIgnored) {
      setState(() => _batteryOptimizationIgnored = ignored);
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await LocalNotificationService.instance
          .loadPreferences();
      String? assignment = widget.profile != null
          ? TaskReminderPlanner.normalizedAssignment(widget.profile!)
          : null;
      String? userEmail = widget.profile?.email;
      if (assignment == null || userEmail == null) {
        final cached = await ProfileApiService().loadCachedProfile();
        if (cached != null) {
          assignment ??= TaskReminderPlanner.normalizedAssignment(cached);
          userEmail ??= cached.email;
        } else {
          assignment ??= await LocalNotificationService.instance
              .getPreviousAssignment();
        }
      }
      _userEmail = userEmail;

      final hasPin = await SecurityService.instance.hasPin(email: userEmail);
      final biometricsSupported = await SecurityService.instance
          .isBiometricsSupported();
      final biometricsEnabled = await SecurityService.instance
          .isBiometricsEnabled();
      final detectedTime = LocalNotificationService.instance
          .getDetectedTimeString();
      final batteryIgnored = await BatteryOptimizationService.instance
          .isIgnoringBatteryOptimizations();
      final manufacturer = await BatteryOptimizationService.instance
          .getManufacturer();

      if (!mounted) return;
      setState(() {
        _notificationsEnabled = preferences.notificationsEnabled;
        _remindersEnabled = preferences.dueRemindersEnabled;
        _leadTimeMinutes = preferences.leadTimeMinutes;
        _batteryOptimizationIgnored = batteryIgnored;
        _manufacturer = manufacturer;
        _assignment = assignment;
        _hasPin = hasPin;
        _biometricsSupported = biometricsSupported;
        _biometricsEnabled = biometricsEnabled;
        _detectedDeviceTime = detectedTime;
        _loadingPreferences = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPreferences = false);
    }
  }

  Future<void> _handleBatteryOptimizationToggle(bool targetValue) async {
    if (targetValue) {
      await BatteryOptimizationService.instance
          .requestIgnoreBatteryOptimizations();
    } else {
      await BatteryOptimizationService.instance
          .openBatteryOptimizationSettings();
    }
    await _checkBatteryOptimization();
  }

  Future<void> _openAutoStartSettings() async {
    final opened = await BatteryOptimizationService.instance
        .openAutoStartSettings();
    if (!opened && mounted) {
      _showMessage(
        'Please check device Settings -> Apps to enable Auto-Start / Background Activity.',
      );
    }
  }

  Future<void> _scheduleBackgroundTest() async {
    if (_schedulingTest) return;
    setState(() => _schedulingTest = true);
    try {
      final scheduled = await LocalNotificationService.instance
          .scheduleQuickTestReminder(delaySeconds: 10);
      if (!mounted) return;
      _showMessage(
        scheduled
            ? 'Test scheduled for 10 seconds! Lock your device or swipe away the app now to test.'
            : 'Allow exact alarms and notifications for Gateway Audit Compliance, then try again.',
      );
    } catch (_) {
      if (mounted) {
        _showMessage(
          'The background test notification could not be scheduled.',
        );
      }
    } finally {
      if (mounted) setState(() => _schedulingTest = false);
    }
  }

  Future<void> _handlePinSetupOrChange() async {
    final changed = await showPinSetupDialog(
      context,
      isChanging: _hasPin,
      email: _userEmail,
    );
    if (!mounted) return;
    if (changed) {
      final hasPin = await SecurityService.instance.hasPin(email: _userEmail);
      final biometricsEnabled = await SecurityService.instance
          .isBiometricsEnabled();
      setState(() {
        _hasPin = hasPin;
        _biometricsEnabled = biometricsEnabled;
      });
      _showMessage(
        _hasPin
            ? '6-Digit PIN updated successfully.'
            : '6-Digit PIN configured.',
      );
    }
  }

  Future<void> _handleToggleBiometrics(bool value) async {
    if (value) {
      final result = await SecurityService.instance
          .authenticateWithBiometricsDetailed(
            reason: 'Authenticate to enable fingerprint unlock',
          );
      if (!mounted) return;
      if (result.success) {
        await SecurityService.instance.setBiometricsEnabled(true);
        setState(() => _biometricsEnabled = true);
        _showMessage('Fingerprint unlock enabled.');
      } else {
        _showMessage(result.message);
      }
    } else {
      await SecurityService.instance.setBiometricsEnabled(false);
      setState(() => _biometricsEnabled = false);
      _showMessage('Fingerprint unlock disabled.');
    }
  }

  Future<void> _updateReminderPreferences({
    bool? notificationsEnabled,
    bool? remindersEnabled,
  }) async {
    final nextNotifications = notificationsEnabled ?? _notificationsEnabled;
    final nextReminders = remindersEnabled ?? _remindersEnabled;
    setState(() {
      _notificationsEnabled = nextNotifications;
      _remindersEnabled = nextReminders;
    });

    try {
      if (nextNotifications && nextReminders) {
        await LocalNotificationService.instance.requestPermissions();
      }
      await LocalNotificationService.instance.savePreferences(
        notificationsEnabled: nextNotifications,
        dueRemindersEnabled: nextReminders,
        leadTimeMinutes: _leadTimeMinutes,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'The notification setting could not be updated. Please try again.',
      );
    }
  }

  Future<void> _showReminderLeadTimeModal() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) =>
          _ReminderLeadTimeSheet(initialMinutes: _leadTimeMinutes),
    );

    if (selected != null && selected != _leadTimeMinutes) {
      setState(() => _leadTimeMinutes = selected);
      try {
        await LocalNotificationService.instance.saveLeadTimeMinutes(selected);
        if (!mounted) return;
        final label = TaskReminderPlanner.formatLeadTime(selected);
        _showMessage('Due-time reminder set to $label before task.');
      } catch (_) {
        if (!mounted) return;
        _showMessage('Could not update due-time reminder preference.');
      }
    }
  }

  Future<void> _sendTestNotification(TaskReminderKind kind) async {
    if (_sendingTest != null) return;
    setState(() => _sendingTest = kind);
    try {
      final shown = await LocalNotificationService.instance
          .showTestNotification(
            kind,
            leadTimeMinutes: _leadTimeMinutes,
            userType: widget.profile?.userType,
          );
      if (!mounted) return;
      _showMessage(
        shown
            ? 'Test sent. Press Home or lock the device, then tap the notification to reopen the checklist.'
            : 'Allow Android notifications for Gateway Audit Compliance, then try again.',
      );
    } catch (_) {
      if (mounted) {
        _showMessage('The Android test notification could not be sent.');
      }
    } finally {
      if (mounted) setState(() => _sendingTest = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goBack() {
    final callback = widget.onBack;
    if (callback != null) {
      callback();
      return;
    }

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 380 ? 16.0 : 20.0;
    final isDosProfile = TaskReminderPlanner.isDosRole(
      widget.profile?.userType,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: GacColors.canvas,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: GacScreenBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _SubpageHeader(title: 'Settings', onBack: _goBack),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      59,
                      horizontalPadding,
                      36,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PREFERENCES',
                              style: TextStyle(
                                color: GacColors.slate,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.7,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Workspace settings',
                              style: TextStyle(
                                color: GacColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.65,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Choose how the app reminds you about assigned '
                              'compliance work.',
                              style: TextStyle(
                                color: GacColors.textSecondary,
                                fontSize: 11,
                                height: 17 / 11,
                              ),
                            ),
                            const SizedBox(height: 20),
                            GacContentPanel(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              borderRadius: 21,
                              shadowBlurRadius: 22,
                              shadowOffset: const Offset(0, 9),
                              child: Column(
                                children: [
                                  _SettingRow(
                                    icon: Icons.notifications_none_rounded,
                                    title: 'Push notifications',
                                    description: 'Receive task assignments and manager updates.',
                                    value: _notificationsEnabled,
                                    enabled: !_loadingPreferences,
                                    onValueChanged: (value) => unawaited(
                                      _updateReminderPreferences(
                                        notificationsEnabled: value,
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: GacColors.cardBorder,
                                  ),
                                  _SettingRow(
                                    icon: Icons.alarm_outlined,
                                    title: isDosProfile
                                        ? 'Month-end DOS reminder'
                                        : 'Due-time reminders',
                                    description: isDosProfile
                                        ? 'Alert at 8:00 AM on the final calendar day; finish by 11:59 PM.'
                                        : 'Get reminded before a checklist becomes overdue.',
                                    value: _remindersEnabled,
                                    enabled: !_loadingPreferences,
                                    action: _remindersEnabled && !isDosProfile
                                        ? InkWell(
                                            onTap: _showReminderLeadTimeModal,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                top: 3,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 9,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0x2200BCD4),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color(
                                                    0x4400BCD4,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.access_time_rounded,
                                                      size: 12,
                                                      color: GacColors.cyan,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      '${TaskReminderPlanner.formatLeadTime(_leadTimeMinutes)} before task',
                                                      style: const TextStyle(
                                                        color: GacColors.cyan,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: GacColors.cyan
                                                            .withValues(
                                                              alpha: 0.25,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.edit_rounded,
                                                            size: 9,
                                                            color: Colors.white,
                                                          ),
                                                          SizedBox(width: 3),
                                                          Text(
                                                            'EDIT',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 8.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              letterSpacing:
                                                                  0.4,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        : null,
                                    onValueChanged: (value) => unawaited(
                                      _updateReminderPreferences(
                                        remindersEnabled: value,
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: GacColors.cardBorder,
                                  ),
                                  _SettingRow(
                                    icon: Icons.battery_charging_full_rounded,
                                    title: 'Run in background',
                                    description: 'Turn off battery optimization to allow continuous background tasks.',
                                    value: _batteryOptimizationIgnored,
                                    enabled: !_loadingPreferences,
                                    action: InkWell(
                                      onTap: _openAutoStartSettings,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0x2200BCD4),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0x4400BCD4),
                                            width: 1,
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.launch_rounded,
                                                size: 10,
                                                color: GacColors.cyan,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _manufacturer != null &&
                                                        _manufacturer!
                                                            .isNotEmpty
                                                    ? 'AUTO-START (${_manufacturer!.toUpperCase()})'
                                                    : 'AUTO-START / OEM SETTINGS',
                                                style: const TextStyle(
                                                  color: GacColors.cyan,
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    onValueChanged: (value) => unawaited(
                                      _handleBatteryOptimizationToggle(value),
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: GacColors.cardBorder,
                                  ),
                                  _SettingRow(
                                    icon: Icons.phone_android_outlined,
                                    title: 'Compact dashboard',
                                    description: 'Show denser cards and shorter task summaries.',
                                    value: _compactMode,
                                    onValueChanged: (value) =>
                                        setState(() => _compactMode = value),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'SECURITY & QUICK ACCESS',
                              style: TextStyle(
                                color: GacColors.slate,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.7,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'App lock & authentication',
                              style: TextStyle(
                                color: GacColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Manage your 6-digit PIN and biometric unlock preferences.',
                              style: TextStyle(
                                color: GacColors.textSecondary,
                                fontSize: 11,
                                height: 16 / 11,
                              ),
                            ),
                            const SizedBox(height: 14),
                            GacContentPanel(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              borderRadius: 21,
                              shadowBlurRadius: 22,
                              shadowOffset: const Offset(0, 9),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0x2200BCD4),
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.pin_outlined,
                                            size: 20,
                                            color: GacColors.cyan,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Quick Access PIN',
                                                style: TextStyle(
                                                  color: GacColors.textPrimary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                _hasPin
                                                    ? '6-Digit PIN is active'
                                                    : 'Not configured yet',
                                                style: TextStyle(
                                                  color: _hasPin
                                                      ? const Color(0xFF4CAF50)
                                                      : GacColors.textSecondary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: _handlePinSetupOrChange,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _hasPin
                                                ? const Color(0xFF1E293B)
                                                : GacColors.brandBlue,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            side: _hasPin
                                                ? const BorderSide(
                                                    color: Color(0xFF334155),
                                                  )
                                                : null,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            _hasPin ? 'CHANGE' : 'SET UP',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_biometricsSupported) ...[
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: GacColors.cardBorder,
                                    ),
                                    _SettingRow(
                                      icon: Icons.fingerprint_rounded,
                                      title: 'Fingerprint scanner',
                                      description: 'Unlock Gateway Audit Compliance using fingerprint.',
                                      value: _biometricsEnabled,
                                      enabled: !_loadingPreferences,
                                      onValueChanged: (val) => unawaited(
                                        _handleToggleBiometrics(val),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            GacGlassSurface(
                              padding: const EdgeInsets.all(16),
                              borderRadius: 21,
                              blurSigma: 14,
                              shadowBlurRadius: 14,
                              shadowOffset: const Offset(0, 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.notification_add_outlined,
                                        size: 20,
                                        color: GacColors.cyan,
                                      ),
                                      SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          'TEST ANDROID NOTIFICATION',
                                          style: TextStyle(
                                            color: GacColors.textPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (_detectedDeviceTime.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x1A00BCD4),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0x3300BCD4),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 15,
                                            color: GacColors.cyan,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Device Clock: $_detectedDeviceTime',
                                              style: const TextStyle(
                                                color: GacColors.cyan,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  Builder(
                                    builder: (context) {
                                      final assignment = _assignment ?? '';
                                      final isUtilities =
                                          TaskReminderPlanner.isUtilitiesAssignment(
                                            assignment,
                                          );
                                      final isSalesService =
                                          TaskReminderPlanner.isSalesServiceAssignment(
                                            assignment,
                                          );
                                      final isDos =
                                          TaskReminderPlanner.isDosRole(
                                            widget.profile?.userType ??
                                                assignment,
                                          );
                                      final showAll =
                                          !isUtilities &&
                                          !isSalesService &&
                                          !isDos;

                                      final hint = isUtilities
                                          ? 'Send the Utilities cleaning & inspection reminder now to preview it on the Home or lock screen.'
                                          : isSalesService
                                          ? 'Send the pre-shift Sales & Service reminder now to preview it on the Home or lock screen.'
                                          : isDos
                                          ? 'Send the month-end DOS reminder now. The live reminder arrives at 8:00 AM on the final calendar day and is due that same day.'
                                          : 'Send the real high-priority reminder now to preview it on the Home or lock screen.';

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hint,
                                            style: const TextStyle(
                                              color: GacColors.textSecondary,
                                              fontSize: 9,
                                              height: 14 / 9,
                                            ),
                                          ),
                                          const SizedBox(height: 13),
                                          Wrap(
                                            spacing: 9,
                                            runSpacing: 9,
                                            children: [
                                              if (isUtilities || showAll)
                                                _TestNotificationButton(
                                                  key: const ValueKey(
                                                    'test-utilities-notification',
                                                  ),
                                                  label: 'UTILITIES TEST',
                                                  loading:
                                                      _sendingTest ==
                                                      TaskReminderKind
                                                          .utilities,
                                                  enabled: _sendingTest == null,
                                                  onPressed: () => unawaited(
                                                    _sendTestNotification(
                                                      TaskReminderKind
                                                          .utilities,
                                                    ),
                                                  ),
                                                ),
                                              if (isSalesService || showAll)
                                                _TestNotificationButton(
                                                  key: const ValueKey(
                                                    'test-shift-notification',
                                                  ),
                                                  label: 'SALES / SERVICE TEST',
                                                  loading:
                                                      _sendingTest ==
                                                      TaskReminderKind.shift,
                                                  enabled: _sendingTest == null,
                                                  onPressed: () => unawaited(
                                                    _sendTestNotification(
                                                      TaskReminderKind.shift,
                                                    ),
                                                  ),
                                                ),
                                              if (isDos)
                                                _TestNotificationButton(
                                                  key: const ValueKey(
                                                    'test-dos-month-end-notification',
                                                  ),
                                                  label: 'DOS MONTH-END TEST',
                                                  loading:
                                                      _sendingTest ==
                                                      TaskReminderKind
                                                          .dosMonthEnd,
                                                  enabled: _sendingTest == null,
                                                  onPressed: () => unawaited(
                                                    _sendTestNotification(
                                                      TaskReminderKind
                                                          .dosMonthEnd,
                                                    ),
                                                  ),
                                                ),
                                              _TestNotificationButton(
                                                key: const ValueKey(
                                                  'test-background-alert',
                                                ),
                                                label: 'TEST BACKGROUND (10s)',
                                                loading: _schedulingTest,
                                                enabled:
                                                    !_schedulingTest &&
                                                    _sendingTest == null,
                                                onPressed: () => unawaited(
                                                  _scheduleBackgroundTest(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const GacGlassSurface(
                              padding: EdgeInsets.all(15),
                              borderRadius: 17,
                              blurSigma: 14,
                              shadowBlurRadius: 14,
                              shadowOffset: Offset(0, 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 20,
                                    color: GacColors.primary,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Reminder choices are saved on this device. '
                                      'Android keeps scheduled alerts active while '
                                      'the app is closed and restores them after a restart.',
                                      style: TextStyle(
                                        color: GacColors.steel,
                                        fontSize: 9,
                                        height: 14 / 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _SubpageHeader extends StatelessWidget {
  const _SubpageHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: GacGlassSurface(
                borderRadius: 22,
                blurSigma: 16,
                shadowBlurRadius: 16,
                shadowOffset: const Offset(0, 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Semantics(
                        button: true,
                        label: 'Go back',
                        child: Material(
                          type: MaterialType.transparency,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: onBack,
                            customBorder: const CircleBorder(),
                            child: const SizedBox.square(
                              dimension: 42,
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 21,
                                color: GacColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          color: GacColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox.square(dimension: 42),
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

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onValueChanged,
    this.enabled = true,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onValueChanged;
  final bool enabled;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onValueChanged(!value) : null,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 84),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 41,
                height: 41,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0x242979FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 19, color: GacColors.cyan),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: GacColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: GacColors.textSecondary,
                          fontSize: 9,
                          height: 14 / 9,
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(height: 6),
                        action!,
                      ],
                    ],
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.82,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: value,
                  onChanged: enabled ? onValueChanged : null,
                  activeTrackColor: GacColors.primary,
                  activeThumbColor: GacColors.white,
                  inactiveTrackColor: const Color(0xFF153A56),
                  inactiveThumbColor: GacColors.white,
                  trackOutlineColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestNotificationButton extends StatelessWidget {
  const _TestNotificationButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: enabled ? onPressed : null,
    icon: loading
        ? const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.send_to_mobile_rounded, size: 17),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: GacColors.cyan,
      side: const BorderSide(color: GacColors.cardBorder),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      textStyle: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.35,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
  );
}

class _ReminderLeadTimeSheet extends StatefulWidget {
  const _ReminderLeadTimeSheet({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_ReminderLeadTimeSheet> createState() => _ReminderLeadTimeSheetState();
}

class _ReminderLeadTimeSheetState extends State<_ReminderLeadTimeSheet> {
  late int _selectedMinutes;

  static const List<({int minutes, String label, String? badge})> _options = [
    (minutes: 5, label: '5 minutes before task', badge: 'PRESET (DEFAULT)'),
    (minutes: 10, label: '10 minutes before task', badge: null),
    (minutes: 15, label: '15 minutes before task', badge: null),
    (minutes: 30, label: '30 minutes before task', badge: null),
    (minutes: 60, label: '1 hour before task', badge: null),
  ];

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x2200BCD4),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0x4400BCD4)),
                ),
                child: const Icon(
                  Icons.alarm_outlined,
                  size: 22,
                  color: GacColors.cyan,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Due-Time Reminder',
                      style: TextStyle(
                        color: GacColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Choose how early to be notified before task due time.',
                      style: TextStyle(
                        color: GacColors.textSecondary.withValues(alpha: 0.85),
                        fontSize: 11,
                        height: 15 / 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Options list
          ...List.generate(_options.length, (index) {
            final option = _options[index];
            final isSelected = _selectedMinutes == option.minutes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedMinutes = option.minutes);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0x1F00BCD4)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? GacColors.cyan
                            : const Color(0xFF334155),
                        width: isSelected ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? GacColors.cyan
                                  : const Color(0xFF64748B),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: GacColors.cyan,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 13),

                        // Label
                        Expanded(
                          child: Text(
                            option.label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : GacColors.textPrimary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),

                        // Optional badge (e.g. Preset / Default)
                        if (option.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? GacColors.cyan.withValues(alpha: 0.25)
                                  : const Color(0x22334155),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? GacColors.cyan
                                    : const Color(0xFF475569),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              option.badge!,
                              style: TextStyle(
                                color: isSelected
                                    ? GacColors.cyan
                                    : const Color(0xFF94A3B8),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GacColors.textSecondary,
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(_selectedMinutes);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GacColors.brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SAVE PREFERENCE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
