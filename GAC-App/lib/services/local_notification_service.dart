import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../config/api_config.dart';
import '../models/authenticated_user.dart';
import '../models/checklist_models.dart';

const String gacPushNotificationsEnabledKey = 'gac_push_notifications_enabled';
const String gacDueRemindersEnabledKey = 'gac_due_reminders_enabled';

const String _scheduledReminderIdsKey = 'gac_scheduled_reminder_ids';
const String _scheduledReminderUserKey = 'gac_scheduled_reminder_user';
const String _reminderChannelId = 'gac_checklist_reminders_v2';
const int _testUtilitiesNotificationId = 699001;
const int _testShiftNotificationId = 699002;
const int _testAdminNotificationId = 699003;
const int _quickTestNotificationId = 699099;

enum TaskReminderKind { utilities, shift, admin }

@immutable
class TaskReminderPayload {
  const TaskReminderPayload({
    required this.event,
    this.templateSlug,
    this.slotKey,
    this.auditDate,
  });

  final String event;
  final String? templateSlug;
  final String? slotKey;
  final String? auditDate;

  String encode() => jsonEncode({
    'event': event,
    if (templateSlug != null) 'template_slug': templateSlug,
    if (slotKey != null) 'slot_key': slotKey,
    if (auditDate != null) 'audit_date': auditDate,
  });

  static TaskReminderPayload? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      final data = <String, dynamic>{
        for (final entry in decoded.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
      final event = data['event'];
      if (event is! String || event.trim().isEmpty) return null;

      String? optionalString(String key) {
        final raw = data[key];
        if (raw is! String || raw.trim().isEmpty) return null;
        return raw.trim();
      }

      return TaskReminderPayload(
        event: event.trim(),
        templateSlug:
            optionalString('template_slug') ?? optionalString('checklist_slug'),
        slotKey: optionalString('slot_key'),
        auditDate: optionalString('audit_date'),
      );
    } catch (_) {
      return null;
    }
  }
}

@immutable
class TaskReminderSpec {
  const TaskReminderSpec({
    required this.id,
    required this.kind,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final TaskReminderKind kind;
  final int hour;
  final int minute;
  final String title;
  final String body;
  final TaskReminderPayload payload;

  int get minuteOfDay => (hour * 60) + minute;
}

/// Converts a signed-in user's live checklist settings into daily reminders.
abstract final class TaskReminderPlanner {
  static String formatLeadTime(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remaining = minutes % 60;
      if (remaining == 0) {
        return hours == 1 ? '1 hour' : '$hours hours';
      }
      return '$hours hr $remaining min';
    }
    return '$minutes minutes';
  }

  static const List<String> defaultUtilitiesSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  static bool isAdminRole(String? userType) {
    if (userType == null) return false;
    final normalized = userType.trim().toUpperCase();
    return normalized == 'ADMIN' ||
        normalized == 'GM' ||
        normalized == 'GENERAL MANAGER' ||
        normalized == 'BOM' ||
        normalized == 'BRANCH OPERATIONS MANAGER' ||
        normalized == 'BRANCH OPERATION MANAGER';
  }

  static bool isDosRole(String? userType) {
    if (userType == null) return false;
    final normalized = normalizeUserType(userType).toUpperCase();
    return const {
      'SM',
      'SALES MANAGER',
      'SALES_MANAGER',
      'SALES MGR',
      'ASM',
      'AFTERSALES MANAGER',
      'AFTERSALES_MANAGER',
      'AS MGR',
      'CE',
      'CE SERVICE',
      'CE_SERVICE',
      'JC',
      'JOB CONTROLLER',
      'JOB_CONTROLLER',
      'PARTS',
      'PARTS SUPERVISOR',
      'PARTS_SUPERVISOR',
      'WS SUP',
    }.contains(normalized);
  }

  static List<TaskReminderSpec> _adminReminders() {
    return const [
      TaskReminderSpec(
        id: 630510,
        kind: TaskReminderKind.admin,
        hour: 8,
        minute: 30,
        title: 'Morning compliance review',
        body: 'Opening 5S and facility inspections have started. Review active checklist progress.',
        payload: TaskReminderPayload(event: 'admin_morning_oversight'),
      ),
      TaskReminderSpec(
        id: 630720,
        kind: TaskReminderKind.admin,
        hour: 12,
        minute: 0,
        title: 'Midday audit oversight',
        body: 'Check hourly utilities and restroom inspection logs for your branch.',
        payload: TaskReminderPayload(event: 'admin_midday_oversight'),
      ),
      TaskReminderSpec(
        id: 631020,
        kind: TaskReminderKind.admin,
        hour: 17,
        minute: 0,
        title: 'Daily compliance wrap-up',
        body: 'Verify that all daily checklists are submitted and any critical findings are noted.',
        payload: TaskReminderPayload(event: 'admin_eod_oversight'),
      ),
    ];
  }

  static List<TaskReminderSpec> forUser({
    required AuthenticatedUser user,
    required List<ChecklistCatalogItem> checklists,
    int? leadTimeMinutes,
  }) {
    if (user.accountStatus.trim().toLowerCase() != 'active') return const [];
    if (isAdminRole(user.userType)) {
      return _adminReminders();
    }

    final assignment = normalizedAssignment(user);
    if (isUtilitiesAssignment(assignment)) {
      return _utilitiesReminders(
        checklists,
        leadTimeMinutes: leadTimeMinutes ?? gacDefaultReminderLeadTimeMinutes,
      );
    }
    if (isSalesServiceAssignment(assignment)) {
      return _shiftReminders(
        assignment,
        checklists,
        leadTimeMinutes: leadTimeMinutes ?? 30,
      );
    }
    return const [];
  }

  /// Plans reminders according to a user role and assignment string.
  /// Used for offline, timed-out, or remembered previous logins.
  static List<TaskReminderSpec> forRole({
    required String userType,
    String? assignment,
    List<ChecklistCatalogItem>? checklists,
    int? leadTimeMinutes,
  }) {
    if (isAdminRole(userType)) {
      return _adminReminders();
    }
    if (isDosRole(userType)) {
      // DOS does not currently define a time window. Avoid falling back to
      // hourly Utilities alerts for these dedicated Sales/Aftersales roles.
      return const [];
    }

    final effectiveAssignment = (assignment ?? 'utilities')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    if (isUtilitiesAssignment(effectiveAssignment)) {
      return _utilitiesReminders(
        checklists ?? const [],
        leadTimeMinutes: leadTimeMinutes ?? gacDefaultReminderLeadTimeMinutes,
      );
    }
    if (isSalesServiceAssignment(effectiveAssignment)) {
      return _shiftReminders(
        effectiveAssignment,
        checklists ?? const [],
        leadTimeMinutes: leadTimeMinutes ?? 30,
      );
    }
    return _utilitiesReminders(
      checklists ?? const [],
      leadTimeMinutes: leadTimeMinutes ?? gacDefaultReminderLeadTimeMinutes,
    );
  }

  static List<TaskReminderSpec> _utilitiesReminders(
    List<ChecklistCatalogItem> checklists, {
    int leadTimeMinutes = gacDefaultReminderLeadTimeMinutes,
  }) {
    ChecklistCatalogItem? target;
    for (final checklist in checklists) {
      if (checklist.slug == 'restroom' || checklist.slug == 'utilities') {
        target = checklist;
        break;
      }
      if (target == null &&
          checklist.settings['validation_mode'] == 'time_slots') {
        target = checklist;
      }
    }

    final rawSlots = (target != null && target.settings['time_slots'] is List)
        ? target.settings['time_slots'] as List
        : (checklists.isEmpty ? defaultUtilitiesSlots : null);
    if (rawSlots == null) return const [];

    final reminders = <TaskReminderSpec>[];
    final seenDueMinutes = <int>{};
    final leadTimeText = formatLeadTime(leadTimeMinutes);

    for (final rawSlot in rawSlots) {
      final slotKey = switch (rawSlot) {
        String value => value,
        Map value when value['key'] is String => value['key'] as String,
        _ => null,
      };
      final due = _parseClock(slotKey);
      if (slotKey == null || due == null || !seenDueMinutes.add(due)) continue;

      final reminderMinute = (due - leadTimeMinutes + 1440) % 1440;
      final dueLabel = _formatClock(due);
      reminders.add(
        TaskReminderSpec(
          id: 610000 + due,
          kind: TaskReminderKind.utilities,
          hour: reminderMinute ~/ 60,
          minute: reminderMinute % 60,
          title: 'Utilities check in $leadTimeText',
          body:
              'The $dueLabel cleaning and equipment inspection is due in $leadTimeText. '
              'Tap to open your checklist.',
          payload: TaskReminderPayload(
            event: 'utilities_due_soon',
            templateSlug: target?.slug ?? 'restroom',
            slotKey: slotKey,
          ),
        ),
      );
    }

    reminders.sort(
      (left, right) => left.minuteOfDay.compareTo(right.minuteOfDay),
    );
    return List.unmodifiable(reminders);
  }

  static List<TaskReminderSpec> _shiftReminders(
    String assignment,
    List<ChecklistCatalogItem> checklists, {
    int leadTimeMinutes = gacDefaultReminderLeadTimeMinutes,
  }) {
    final preferredSlugs = switch (assignment) {
      'sales' => const {'sales'},
      'service' => const {'service'},
      _ => const {'sales', 'service', 'gateway-5s'},
    };
    final candidates = checklists
        .where((checklist) => preferredSlugs.contains(checklist.slug))
        .toList(growable: false);

    // Sales & Service users own their respective templates. Grouping
    // by reminder time prevents duplicate Android alerts at shift opening.
    final shiftsByReminderMinute = <int, _ShiftWindow>{};
    for (final checklist in candidates) {
      final window = _shiftWindow(checklist, leadTimeMinutes: leadTimeMinutes);
      if (window == null) continue;
      shiftsByReminderMinute.putIfAbsent(window.reminderMinute, () => window);
    }

    // Fallback if no catalog items exist (e.g. offline / timed out)
    if (shiftsByReminderMinute.isEmpty && checklists.isEmpty) {
      const defaultShiftMinute = 8 * 60; // 08:00 AM
      final reminderMinute =
          (defaultShiftMinute - leadTimeMinutes + 1440) % 1440;
      final defaultSlug = switch (assignment) {
        'sales' => 'sales',
        'service' => 'service',
        _ => 'gateway-5s',
      };
      shiftsByReminderMinute[reminderMinute] = _ShiftWindow(
        templateSlug: defaultSlug,
        shiftMinute: defaultShiftMinute,
        reminderMinute: reminderMinute,
      );
    }

    if (shiftsByReminderMinute.isEmpty) return const [];

    final isCombined = assignment != 'sales' && assignment != 'service';
    final assignmentLabel = switch (assignment) {
      'sales' => 'Sales',
      'service' => 'Service',
      _ => 'Sales & Service',
    };
    final reminders = <TaskReminderSpec>[];
    final leadTimeText = formatLeadTime(leadTimeMinutes);

    for (final window in shiftsByReminderMinute.values) {
      reminders.add(
        TaskReminderSpec(
          id: 620000 + window.reminderMinute,
          kind: TaskReminderKind.shift,
          hour: window.reminderMinute ~/ 60,
          minute: window.reminderMinute % 60,
          title: 'Pre-shift checklist is ready',
          body:
              'Your ${_formatClock(window.shiftMinute)} shift starts in '
              '$leadTimeText. Complete the $assignmentLabel '
              '${isCombined ? 'checklists' : 'checklist'} now.',
          payload: TaskReminderPayload(
            event: 'shift_checklist_due',
            templateSlug: isCombined ? null : window.templateSlug,
          ),
        ),
      );
    }

    reminders.sort(
      (left, right) => left.minuteOfDay.compareTo(right.minuteOfDay),
    );
    return List.unmodifiable(reminders);
  }

  static _ShiftWindow? _shiftWindow(
    ChecklistCatalogItem checklist, {
    int leadTimeMinutes = gacDefaultReminderLeadTimeMinutes,
  }) {
    final settings = checklist.settings;
    final schedule = settings['schedule'];
    final scheduleMap = schedule is Map ? schedule : const <String, dynamic>{};

    final explicitShift = _parseClock(
      _stringValue(settings['shift_start']) ??
          _stringValue(scheduleMap['shift_start']),
    );
    if (explicitShift != null) {
      return _ShiftWindow(
        templateSlug: checklist.slug,
        shiftMinute: explicitShift,
        reminderMinute: (explicitShift - leadTimeMinutes + 1440) % 1440,
      );
    }

    // Until the API exposes a per-user shift_start, the checklist schedule's
    // start is the shared shift boundary used by the current templates.
    final windowStart = _parseClock(_stringValue(scheduleMap['start']));
    if (windowStart == null) return null;

    return _ShiftWindow(
      templateSlug: checklist.slug,
      shiftMinute: windowStart,
      reminderMinute: (windowStart - leadTimeMinutes + 1440) % 1440,
    );
  }

  static String normalizedAssignment(AuthenticatedUser user) {
    if (user.is5sSales) return 'sales';
    if (user.is5sService) return 'service';
    if (user.is5sUtilities) return 'utilities';
    final raw = user.picAssignmentType?.trim().toLowerCase();
    if (raw != null && raw.isNotEmpty) {
      return raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    }
    return user.assignmentLabel.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
  }

  static bool isUtilitiesAssignment(String value) =>
      const {'utility', 'utilities', 'restroom'}.contains(value.toLowerCase());

  static bool isSalesServiceAssignment(String value) {
    final normalized = value.toLowerCase();
    return normalized == 'sales' ||
        normalized == 'service' ||
        normalized == 'sales_service' ||
        normalized == 'sales__service' ||
        normalized == 'sales_and_service';
  }

  static int? _parseClock(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return (hour * 60) + minute;
  }

  static String _formatClock(int minuteOfDay) {
    final hour24 = (minuteOfDay ~/ 60) % 24;
    final minute = minuteOfDay % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  static String? _stringValue(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}

@immutable
class ReminderPreferences {
  const ReminderPreferences({
    required this.notificationsEnabled,
    required this.dueRemindersEnabled,
    required this.leadTimeMinutes,
  });

  final bool notificationsEnabled;
  final bool dueRemindersEnabled;
  final int leadTimeMinutes;
}

/// Android notification gateway used for lock-screen and launcher reminders.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  ValueChanged<String>? _onNotificationTap;
  List<TaskReminderSpec> _lastPlan = const [];
  AuthenticatedUser? _lastUser;
  List<ChecklistCatalogItem>? _lastChecklists;
  bool _initialized = false;
  bool _exactAlarmsAvailable = false;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<String?> initialize({ValueChanged<String>? onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;
    if (!isSupported) return null;

    configureLocalTimezone();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_gac'),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _onNotificationTap?.call(payload);
        }
      },
    );
    _initialized = true;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        'Checklist reminders',
        description:
            'Hourly Utilities checks and pre-shift Sales & Service reminders.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    _exactAlarmsAvailable =
        await android?.canScheduleExactNotifications() ?? true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp != true) return null;
    return launchDetails?.notificationResponse?.payload;
  }

  Future<ReminderPreferences> loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    return ReminderPreferences(
      notificationsEnabled:
          preferences.getBool(gacPushNotificationsEnabledKey) ?? true,
      dueRemindersEnabled:
          preferences.getBool(gacDueRemindersEnabledKey) ?? true,
      leadTimeMinutes:
          preferences.getInt(gacReminderLeadTimeKey) ??
          gacDefaultReminderLeadTimeMinutes,
    );
  }

  Future<void> savePreferences({
    required bool notificationsEnabled,
    required bool dueRemindersEnabled,
    int? leadTimeMinutes,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      gacPushNotificationsEnabledKey,
      notificationsEnabled,
    );
    await preferences.setBool(gacDueRemindersEnabledKey, dueRemindersEnabled);
    if (leadTimeMinutes != null) {
      await preferences.setInt(gacReminderLeadTimeKey, leadTimeMinutes);
    }

    if (!notificationsEnabled || !dueRemindersEnabled) {
      await _cancelScheduledReminders(clearPlan: false);
    } else {
      final leadTime =
          leadTimeMinutes ??
          preferences.getInt(gacReminderLeadTimeKey) ??
          gacDefaultReminderLeadTimeMinutes;
      if (_lastUser != null && _lastChecklists != null) {
        _lastPlan = TaskReminderPlanner.forUser(
          user: _lastUser!,
          checklists: _lastChecklists!,
          leadTimeMinutes: leadTime,
        );
      }
      await _schedulePlan(_lastPlan, preferences: preferences);
    }
  }

  /// Persists only the lead-time value and reschedules existing reminders.
  Future<void> saveLeadTimeMinutes(int minutes) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(gacReminderLeadTimeKey, minutes);
    if (_lastUser != null && _lastChecklists != null) {
      _lastPlan = TaskReminderPlanner.forUser(
        user: _lastUser!,
        checklists: _lastChecklists!,
        leadTimeMinutes: minutes,
      );
    }
    // Reschedule with updated lead time
    final enabled =
        (preferences.getBool(gacPushNotificationsEnabledKey) ?? true) &&
        (preferences.getBool(gacDueRemindersEnabledKey) ?? true);
    if (enabled && _lastPlan.isNotEmpty) {
      await _schedulePlan(_lastPlan, preferences: preferences);
    }
  }

  Future<bool> requestPermissions({bool requestExactAlarms = true}) async {
    if (!isSupported || !_initialized) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notificationPermission = await android
        ?.requestNotificationsPermission();
    final notificationsEnabled =
        await android?.areNotificationsEnabled() ??
        notificationPermission ??
        true;
    if (!notificationsEnabled) return false;

    _exactAlarmsAvailable =
        await android?.canScheduleExactNotifications() ?? true;
    if (requestExactAlarms && !_exactAlarmsAvailable) {
      _exactAlarmsAvailable =
          await android?.requestExactAlarmsPermission() ?? false;
    }
    return true;
  }

  Future<int> syncForUser({
    required AuthenticatedUser user,
    required List<ChecklistCatalogItem> checklists,
    bool requestPermission = false,
  }) async {
    _lastUser = user;
    _lastChecklists = checklists;
    final preferences = await SharedPreferences.getInstance();

    // Cache catalog for offline or timed-out reminder planning
    try {
      final catalogJson = jsonEncode(
        checklists.map((c) => c.toJson()).toList(),
      );
      await preferences.setString(gacCachedChecklistCatalogKey, catalogJson);
    } catch (_) {}

    final leadTime =
        preferences.getInt(gacReminderLeadTimeKey) ??
        gacDefaultReminderLeadTimeMinutes;
    _lastPlan = TaskReminderPlanner.forUser(
      user: user,
      checklists: checklists,
      leadTimeMinutes: leadTime,
    );
    if (!isSupported || !_initialized) return 0;

    final enabled =
        (preferences.getBool(gacPushNotificationsEnabledKey) ?? true) &&
        (preferences.getBool(gacDueRemindersEnabledKey) ?? true);
    if (!enabled) {
      await _cancelScheduledReminders(clearPlan: false);
      return 0;
    }
    if (requestPermission && !await requestPermissions()) {
      await _cancelScheduledReminders(clearPlan: false);
      return 0;
    }

    await preferences.setInt(_scheduledReminderUserKey, user.id);
    await recordPreviousUser(user);
    return _schedulePlan(_lastPlan, preferences: preferences);
  }

  /// Ensures reminders are actively scheduled based on the previous login's user type
  /// and assignment, even when the user is logged out, timed out, or offline.
  Future<int> syncForPreviousUser({bool requestPermission = false}) async {
    if (!isSupported || !_initialized) return 0;

    final preferences = await SharedPreferences.getInstance();
    final enabled =
        (preferences.getBool(gacPushNotificationsEnabledKey) ?? true) &&
        (preferences.getBool(gacDueRemindersEnabledKey) ?? true);
    if (!enabled) {
      await _cancelScheduledReminders(clearPlan: false);
      return 0;
    }

    final storedUserType =
        preferences.getString(gacPreviousUserTypeKey) ?? '5S_UTILITIES';
    final previousUserType = normalizeUserType(storedUserType);
    if (previousUserType != storedUserType) {
      await preferences.setString(gacPreviousUserTypeKey, previousUserType);
    }
    final previousAssignment =
        preferences.getString(gacPreviousAssignmentKey) ?? 'utilities';
    final leadTime =
        preferences.getInt(gacReminderLeadTimeKey) ??
        gacDefaultReminderLeadTimeMinutes;

    // Load cached checklists if in-memory list is absent
    List<ChecklistCatalogItem>? checklists = _lastChecklists;
    if (checklists == null || checklists.isEmpty) {
      final cachedJson = preferences.getString(gacCachedChecklistCatalogKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List) {
            checklists = decoded
                .whereType<Map>()
                .map(
                  (m) => ChecklistCatalogItem.fromJson(
                    Map<String, dynamic>.from(m),
                  ),
                )
                .toList(growable: false);
            _lastChecklists = checklists;
          }
        } catch (_) {}
      }
    }

    _lastPlan = TaskReminderPlanner.forRole(
      userType: previousUserType,
      assignment: previousAssignment,
      checklists: checklists,
      leadTimeMinutes: leadTime,
    );

    if (requestPermission && !await requestPermissions()) {
      await _cancelScheduledReminders(clearPlan: false);
      return 0;
    }

    return _schedulePlan(_lastPlan, preferences: preferences);
  }

  Future<int> _schedulePlan(
    List<TaskReminderSpec> plan, {
    SharedPreferences? preferences,
  }) async {
    if (!isSupported || !_initialized) return 0;
    final storage = preferences ?? await SharedPreferences.getInstance();
    await _cancelStoredIds(storage);
    if (plan.isEmpty) return 0;

    configureLocalTimezone();
    final now = tz.TZDateTime.now(tz.local);
    final scheduledIds = <String>[];
    for (final reminder in plan) {
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );
      if (!scheduledDate.isAfter(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: scheduledDate,
        notificationDetails: _details(reminder.body),
        androidScheduleMode: _exactAlarmsAvailable
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: reminder.payload.encode(),
      );
      scheduledIds.add(reminder.id.toString());
    }
    await storage.setStringList(_scheduledReminderIdsKey, scheduledIds);
    return scheduledIds.length;
  }

  Future<void> cancelScheduledReminders() =>
      _cancelScheduledReminders(clearPlan: true);

  Future<void> _cancelScheduledReminders({required bool clearPlan}) async {
    if (!isSupported || !_initialized) return;
    final preferences = await SharedPreferences.getInstance();
    await _cancelStoredIds(preferences);
    await preferences.remove(_scheduledReminderUserKey);
    if (clearPlan) _lastPlan = const [];
  }

  Future<void> _cancelStoredIds(SharedPreferences preferences) async {
    final ids = preferences.getStringList(_scheduledReminderIdsKey) ?? const [];
    for (final encoded in ids) {
      final id = int.tryParse(encoded);
      if (id != null) await _plugin.cancel(id: id);
    }
    await preferences.remove(_scheduledReminderIdsKey);
  }

  Future<void> recordPreviousUser(AuthenticatedUser user) async {
    final preferences = await SharedPreferences.getInstance();
    final assignment = TaskReminderPlanner.normalizedAssignment(user);
    await preferences.setString(gacPreviousUserTypeKey, user.canonicalUserType);
    await preferences.setString(gacPreviousAssignmentKey, assignment);
    await preferences.setString(
      gacPreviousAssignmentLabelKey,
      user.assignmentLabel,
    );
  }

  Future<void> recordPreviousRole({
    required String userType,
    String? assignment,
    String? assignmentLabel,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      gacPreviousUserTypeKey,
      normalizeUserType(userType),
    );
    if (assignment != null) {
      await preferences.setString(gacPreviousAssignmentKey, assignment);
    }
    if (assignmentLabel != null) {
      await preferences.setString(
        gacPreviousAssignmentLabelKey,
        assignmentLabel,
      );
    }
  }

  Future<String?> getPreviousAssignment() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(gacPreviousAssignmentKey);
  }

  Future<String?> getPreviousUserType() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(gacPreviousUserTypeKey);
  }

  Future<void> setPendingPayload(TaskReminderPayload payload) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      gacPendingNotificationPayloadKey,
      payload.encode(),
    );
  }

  Future<TaskReminderPayload?> consumePendingPayload() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(gacPendingNotificationPayloadKey);
    if (encoded == null || encoded.isEmpty) return null;
    await preferences.remove(gacPendingNotificationPayloadKey);
    return TaskReminderPayload.tryParse(encoded);
  }

  /// Schedules an immediate test reminder [delaySeconds] into the future to verify that
  /// notifications successfully wake up the device and notify when the app is
  /// closed or running in the background.
  Future<bool> scheduleQuickTestReminder({int delaySeconds = 10}) async {
    if (!isSupported || !_initialized) return false;
    if (!await requestPermissions(requestExactAlarms: true)) return false;

    configureLocalTimezone();
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(seconds: delaySeconds));

    await _plugin.zonedSchedule(
      id: _quickTestNotificationId,
      title: 'Background alert test',
      body: 'Notifications are working while the app is closed or running in the background!',
      scheduledDate: scheduledDate,
      notificationDetails: _details(
        'Notifications are working while the app is closed or running in the background!',
      ),
      androidScheduleMode: _exactAlarmsAvailable
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: const TaskReminderPayload(event: 'test_background_notification')
          .encode(),
    );
    return true;
  }

  Future<bool> showRelevantTestNotification({
    String? assignment,
    String? userType,
  }) async {
    final effectiveUserType =
        userType ?? await getPreviousUserType() ?? '5S_UTILITIES';
    if (TaskReminderPlanner.isAdminRole(effectiveUserType)) {
      return showTestNotification(TaskReminderKind.admin);
    }
    final effectiveAssignment =
        assignment ?? await getPreviousAssignment() ?? '';
    final kind = TaskReminderPlanner.isUtilitiesAssignment(effectiveAssignment)
        ? TaskReminderKind.utilities
        : TaskReminderKind.shift;
    return showTestNotification(kind);
  }

  Future<bool> showTestNotification(
    TaskReminderKind kind, {
    int? leadTimeMinutes,
  }) async {
    if (!isSupported || !_initialized) return false;
    if (!await requestPermissions(requestExactAlarms: false)) return false;

    final preferences = await SharedPreferences.getInstance();
    final effectiveLeadTime =
        leadTimeMinutes ??
        preferences.getInt(gacReminderLeadTimeKey) ??
        gacDefaultReminderLeadTimeMinutes;
    final leadTimeText = TaskReminderPlanner.formatLeadTime(effectiveLeadTime);

    final label = kind == TaskReminderKind.utilities
        ? '9:00 AM'
        : kind == TaskReminderKind.admin
        ? '8:30 AM'
        : '8:00 AM';
    final title = kind == TaskReminderKind.utilities
        ? 'Utilities check in $leadTimeText'
        : kind == TaskReminderKind.admin
        ? 'Morning compliance review'
        : 'Pre-shift checklist is ready';
    final body = kind == TaskReminderKind.utilities
        ? 'The $label cleaning and equipment inspection is due in $leadTimeText. '
              'Tap to open your checklist.'
        : kind == TaskReminderKind.admin
        ? 'Opening 5S and facility inspections have started. Tap to review compliance.'
        : 'Your $label shift starts in $leadTimeText. Complete the Sales & '
              'Service checklists now.';
    final payload = TaskReminderPayload(
      event: kind == TaskReminderKind.utilities
          ? 'utilities_due_soon'
          : kind == TaskReminderKind.admin
          ? 'admin_morning_oversight'
          : 'shift_checklist_due',
      templateSlug: kind == TaskReminderKind.utilities ? 'restroom' : null,
      slotKey: kind == TaskReminderKind.utilities ? '09:00' : null,
    );

    await _plugin.show(
      id: kind == TaskReminderKind.utilities
          ? _testUtilitiesNotificationId
          : kind == TaskReminderKind.admin
          ? _testAdminNotificationId
          : _testShiftNotificationId,
      title: title,
      body: body,
      notificationDetails: _details(body),
      payload: payload.encode(),
    );
    return true;
  }

  NotificationDetails _details(String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      _reminderChannelId,
      'Checklist reminders',
      channelDescription: 'Hourly Utilities checks, pre-shift reminders, and audit compliance alerts.',
      icon: 'ic_stat_gac',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(body),
      color: const Color(0xFF2979FF),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      channelShowBadge: true,
      ticker: 'Gateway checklist reminder',
      autoCancel: true,
    ),
  );

  /// Dynamically aligns [tz.local] with the device's actual clock and timezone offset.
  void configureLocalTimezone() {
    tz_data.initializeTimeZones();
    final deviceNow = DateTime.now();
    final offset = deviceNow.timeZoneOffset;
    final timeZoneName = deviceNow.timeZoneName;

    // 1. Direct match by device timezone name if present in tz database
    if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      return;
    }

    // 2. Match any timezone location whose current offset equals the device's offset
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.now(loc).timeZoneOffset == offset) {
        tz.setLocalLocation(loc);
        return;
      }
    }

    // 3. Fallback to business timezone or UTC
    try {
      tz.setLocalLocation(tz.getLocation(gacBusinessTimezone));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Manila'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  /// Returns a human-readable string of the device's current date, time, and UTC offset
  /// to make debugging system clock adjustments simple and transparent.
  String getDetectedTimeString() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final offsetStr = 'UTC$sign$hours:$minutes';

    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final minStr = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour12:$minStr $period';
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return '$dateStr $timeStr ($offsetStr)';
  }
}

@immutable
class _ShiftWindow {
  const _ShiftWindow({
    required this.templateSlug,
    required this.shiftMinute,
    required this.reminderMinute,
  });

  final String templateSlug;
  final int shiftMinute;
  final int reminderMinute;
}
