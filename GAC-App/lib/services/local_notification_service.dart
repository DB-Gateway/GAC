import 'dart:async';
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
import '../models/user_notification.dart';
import 'notification_service.dart';

const String gacPushNotificationsEnabledKey = 'gac_push_notifications_enabled';
const String gacDueRemindersEnabledKey = 'gac_due_reminders_enabled';

const String _scheduledReminderIdsKey = 'gac_scheduled_reminder_ids';
const String _scheduledReminderUserKey = 'gac_scheduled_reminder_user';
String _catalogCacheKey(String userId, String? branch) =>
    '$gacCachedChecklistCatalogKey:$userId:${Uri.encodeComponent((branch ?? '').trim().toLowerCase())}';
const String _reminderChannelId = 'gac_checklist_reminders_v3';
const String _inboxChannelId = 'gac_inbox_alerts_v1';
const String _bomGmChannelId = 'gac_manager_alerts_v1';
const String _scheduledBomGmReminderIdsKey =
    'gac_scheduled_bom_gm_reminder_ids';
const String _shownInboxNotificationIdsKey =
    'gac_shown_android_inbox_notification_ids';
const int _maxInboxAlertsPerSync = 3;
const int _testUtilitiesNotificationId = 699001;
const int _testShiftNotificationId = 699002;
const int _testAdminNotificationId = 699003;
const int _testDosMonthEndNotificationId = 699004;
const int _quickTestNotificationId = 699099;
const int _dosMonthEndNotificationId = 640000;
const int _dosMonthEndScheduleMonths = 24;
const int gacBomMiddayReminderId = 650690;
const int gacGmEodReminderId = 650990;

enum TaskReminderKind { utilities, shift, admin, dosMonthEnd, bomGmReminder }

@immutable
class TaskReminderPayload {
  const TaskReminderPayload({
    required this.event,
    this.templateSlug,
    this.slotKey,
    this.auditDate,
    this.notificationId,
    this.submissionId,
    this.itemKey,
    this.customerIndex,
    this.recipientUserId,
  });

  final String event;
  final String? templateSlug;
  final String? slotKey;
  final String? auditDate;
  final String? notificationId;
  final int? submissionId;
  final String? itemKey;
  final int? customerIndex;
  final String? recipientUserId;

  bool get targetsDosChecklist => const {
    'dealer-operations-standards',
    'dealer-operations-standards-sales',
  }.contains(templateSlug);

  String encode() => jsonEncode({
    'event': event,
    if (templateSlug != null) 'template_slug': templateSlug,
    if (slotKey != null) 'slot_key': slotKey,
    if (auditDate != null) 'audit_date': auditDate,
    if (notificationId != null) 'notification_id': notificationId,
    if (submissionId != null) 'submission_id': submissionId,
    if (itemKey != null) 'item_key': itemKey,
    if (customerIndex != null) 'customer_index': customerIndex,
    if (recipientUserId != null) 'recipient_user_id': recipientUserId,
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
        notificationId: optionalString('notification_id'),
        recipientUserId: data['recipient_user_id']?.toString(),
        submissionId: data['submission_id'] is num
            ? (data['submission_id'] as num).toInt()
            : null,
        itemKey: optionalString('item_key'),
        customerIndex: data['customer_index'] is num
            ? (data['customer_index'] as num).toInt()
            : null,
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
    '11:00',
    '14:00',
    '16:00',
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
    final normalized = normalizeUserType(userType)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return const {
      'SM',
      'SALES MANAGER',
      'SALES MGR',
      'ASM',
      'AFTERSALES MANAGER',
      'AS MGR',
      'CE',
      'CE SERVICE',
      'JC',
      'JOB CONTROLLER',
      'PARTS',
      'PARTS SUPERVISOR',
      'WS SUP',
      'DOS',
      'DOS SALES',
      'DOS AFTERSALES',
    }.contains(normalized);
  }

  static bool isUtilitiesRole(String? userType) {
    if (userType == null) return false;
    final normalized = normalizeUserType(userType)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return const {
      '5S UTILITIES',
      'UTILITIES',
      'UTILITY',
      'RESTROOM',
    }.contains(normalized);
  }

  static String? dosTemplateSlugForRole(String? userType) {
    if (userType == null) return null;
    final normalized = normalizeUserType(userType)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (const {
      'SM',
      'SALES MANAGER',
      'SALES MGR',
      'DOS SALES',
    }.contains(normalized)) {
      return 'dealer-operations-standards-sales';
    }
    if (const {
      'ASM',
      'AFTERSALES MANAGER',
      'AFTERSALES MGR',
      'AS MGR',
      'CE',
      'CE SERVICE',
      'JC',
      'JOB CONTROLLER',
      'PARTS',
      'PARTS SUPERVISOR',
      'WS SUP',
      'DOS AFTERSALES',
    }.contains(normalized)) {
      return 'dealer-operations-standards';
    }
    return null;
  }

  /// Returns the next [count] final-calendar-day occurrences after [now].
  ///
  /// These are scheduled individually because a recurring "last day of the
  /// month" calendar rule cannot represent 28-, 29-, 30-, and 31-day months.
  static List<DateTime> monthEndOccurrences(
    DateTime now, {
    int count = _dosMonthEndScheduleMonths,
    int hour = 8,
    int minute = 0,
  }) {
    if (count <= 0) return const [];
    final occurrences = <DateTime>[];
    var monthOffset = 0;
    while (occurrences.length < count) {
      final lastDay = DateTime(
        now.year,
        now.month + monthOffset + 1,
        0,
        hour,
        minute,
      );
      if (lastDay.isAfter(now)) occurrences.add(lastDay);
      monthOffset++;
    }
    return List.unmodifiable(occurrences);
  }

  static List<TaskReminderSpec> _dosMonthEndReminders(String userType) {
    final templateSlug = dosTemplateSlugForRole(userType);
    final trackLabel = templateSlug == 'dealer-operations-standards-sales'
        ? 'Sales DOS'
        : templateSlug == 'dealer-operations-standards'
        ? 'Aftersales DOS'
        : 'Sales/Aftersales DOS';
    return [
      TaskReminderSpec(
        id: _dosMonthEndNotificationId,
        kind: TaskReminderKind.dosMonthEnd,
        hour: 8,
        minute: 0,
        title: '$trackLabel checklist due today',
        body:
            'Complete and submit your $trackLabel checklist today. '
            'It must be finished by 11:59 PM.',
        payload: TaskReminderPayload(
          event: 'dos_month_end_due',
          templateSlug: templateSlug,
        ),
      ),
    ];
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
        body: 'Check scheduled utilities and restroom inspection logs for your branch.',
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

  /// Scheduled management check-ins from Branch Operations Manager.
  static List<TaskReminderSpec> bomGmReminders({
    String? userType,
    String? branch,
  }) {
    if (isUtilitiesRole(userType)) {
      return const [];
    }
    final branchName = branch?.trim();
    final branchSuffix = branchName != null && branchName.isNotEmpty
        ? ' for $branchName'
        : '';
    return [
      TaskReminderSpec(
        id: gacBomMiddayReminderId,
        kind: TaskReminderKind.bomGmReminder,
        hour: 11,
        minute: 30,
        title: 'BOM Checklist Reminder',
        body:
            'Branch Operations Manager reminder$branchSuffix: Review and complete your assigned inspection checklists.',
        payload: const TaskReminderPayload(event: 'bom_midday_checkin'),
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
    if (user.isDosAuditor) {
      return _dosMonthEndReminders(user.canonicalUserType);
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
      return _dosMonthEndReminders(userType);
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
    // The server checks live submissions before delivering Utilities reminders.
    // Daily device alarms would duplicate these and alert after submission on
    // another device. Existing scheduled alarms are cancelled during sync.
    return const [];
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

  static bool isUtilitiesAssignment(String value) {
    final lower = value.toLowerCase();
    return const {'utility', 'utilities', 'restroom'}.contains(lower) ||
        lower.startsWith('restroom');
  }

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
  Timer? _timedOutManagerPollTimer;
  bool _syncingInbox = false;

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
        description: 'Utilities, pre-shift, management, and month-end DOS checklist reminders.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _inboxChannelId,
        'Checklist updates',
        description:
            'New assignments, draft reminders, and checklist status updates.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _bomGmChannelId,
        'BOM & GM Alerts',
        description: 'Urgent alerts, reminders, and requests from Branch Operations Managers and General Managers.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    _exactAlarmsAvailable =
        await android?.canScheduleExactNotifications() ?? true;

    try {
      await _plugin.cancel(id: gacGmEodReminderId);
    } catch (_) {}

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

  /// Mirrors newly fetched unread Server notifications into Android's system
  /// notification tray. IDs are remembered locally so a 15-second inbox poll
  /// never alerts for the same server notification twice.
  Future<int> showUnreadInboxNotifications(
    Iterable<UserNotification> notifications, {
    bool isBomGm = false,
  }) async {
    if (!isSupported || !_initialized) return 0;

    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final recipientId = preferences.getString(gacPreviousUserIdKey);
    if (!(preferences.getBool(gacPushNotificationsEnabledKey) ?? true)) {
      return 0;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (!(await android?.areNotificationsEnabled() ?? true)) return 0;

    final shownIds = <String>{
      ...preferences.getStringList(_shownInboxNotificationIdsKey) ?? const [],
    };
    final unread = notifications
        .where(
          (notification) =>
              notification.unread &&
              (notification.data['recipient_user_id'] == null ||
                  notification.data['recipient_user_id'].toString() ==
                      recipientId),
        )
        .toList(growable: false);
    final newAlerts = unread
        .where((notification) => !shownIds.contains(notification.id))
        .take(_maxInboxAlertsPerSync)
        .toList(growable: false);

    var shownCount = 0;
    for (final notification in newAlerts) {
      await preferences.reload();
      if (preferences.getString(gacPreviousUserIdKey) != recipientId) {
        return shownCount;
      }
      final payload = _payloadForInboxNotification(notification);
      final effectiveBomGm = isBomGm || notification.isFromBomOrGm;
      await _plugin.show(
        id: _androidIdForInboxNotification(notification.id),
        title: notification.title,
        body: notification.message,
        notificationDetails: effectiveBomGm
            ? _bomGmDetails(notification.message)
            : _inboxDetails(notification.message),
        payload: payload.encode(),
      );
      shownIds.add(notification.id);
      shownCount++;
    }

    // Keep all delivered IDs. A capped history can repeatedly alert for old
    // unread findings, and marking an undisplayed batch would lose alerts.
    await preferences.reload();
    if (preferences.getString(gacPreviousUserIdKey) != recipientId) {
      return shownCount;
    }
    await preferences.setStringList(
      _shownInboxNotificationIdsKey,
      shownIds.toList(growable: false),
    );
    return shownCount;
  }

  TaskReminderPayload _payloadForInboxNotification(
    UserNotification notification,
  ) {
    String? stringValue(String key) {
      final value = notification.data[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    int? intValue(String key) {
      final value = notification.data[key];
      if (value is num) return value.toInt();
      return value is String ? int.tryParse(value) : null;
    }

    return TaskReminderPayload(
      event: notification.type.trim().isEmpty
          ? 'inbox_notification'
          : notification.type.trim(),
      templateSlug:
          stringValue('template_slug') ?? stringValue('checklist_slug'),
      slotKey: stringValue('slot_key'),
      auditDate: stringValue('audit_date'),
      notificationId: notification.id,
      submissionId: intValue('submission_id'),
      itemKey: stringValue('item_key'),
      customerIndex: intValue('customer_index'),
      recipientUserId: notification.data['recipient_user_id']?.toString(),
    );
  }

  int _androidIdForInboxNotification(String id) {
    // Stable FNV-1a hash, kept within Android's signed 32-bit integer range.
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return 700000 + (hash % 1000000000);
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
      await preferences.setString(
        _catalogCacheKey(user.id.toString(), user.branch),
        catalogJson,
      );
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
    final scheduledCount = await _schedulePlan(
      _lastPlan,
      preferences: preferences,
    );
    final isUtilities =
        user.is5sUtilities ||
        user.isUtilities ||
        TaskReminderPlanner.isUtilitiesRole(user.userType) ||
        TaskReminderPlanner.isUtilitiesAssignment(
          TaskReminderPlanner.normalizedAssignment(user),
        );
    final bomGmCount = isUtilities
        ? 0
        : await scheduleBomGmReminders(
            userType: user.canonicalUserType,
            branch: user.branch,
            preferences: preferences,
          );
    if (isUtilities) {
      await cancelBomGmReminders(preferences: preferences);
    }
    return scheduledCount + bomGmCount;
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
    final previousUserId = preferences.getString(gacPreviousUserIdKey);
    final previousBranch = preferences.getString(gacPreviousBranchKey);
    List<ChecklistCatalogItem>? checklists =
        _lastUser?.id.toString() == previousUserId &&
            (_lastUser?.branch ?? '').trim().toLowerCase() ==
                (previousBranch ?? '').trim().toLowerCase()
        ? _lastChecklists
        : null;
    if (checklists == null || checklists.isEmpty) {
      final cachedJson = previousUserId == null
          ? null
          : preferences.getString(
              _catalogCacheKey(previousUserId, previousBranch),
            );
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

    final scheduledCount = await _schedulePlan(
      _lastPlan,
      preferences: preferences,
    );
    final isUtilities =
        TaskReminderPlanner.isUtilitiesRole(previousUserType) ||
        TaskReminderPlanner.isUtilitiesAssignment(previousAssignment);
    final bomGmCount = isUtilities
        ? 0
        : await scheduleBomGmReminders(
            userType: previousUserType,
            preferences: preferences,
          );
    if (isUtilities) {
      await cancelBomGmReminders(preferences: preferences);
    }
    return scheduledCount + bomGmCount;
  }

  /// Cancels any scheduled recurring BOM/GM management reminders.
  Future<void> cancelBomGmReminders({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    if (isSupported && _initialized) {
      final oldIds =
          prefs.getStringList(_scheduledBomGmReminderIdsKey) ?? const [];
      for (final encoded in oldIds) {
        final id = int.tryParse(encoded);
        if (id != null) await _plugin.cancel(id: id);
      }
      await _plugin.cancel(id: gacBomMiddayReminderId);
      await _plugin.cancel(id: gacGmEodReminderId);
    }
    await prefs.remove(_scheduledBomGmReminderIdsKey);
  }

  /// Cancels any scheduled GM compliance wrap-up reminder.
  Future<void> cancelGmReminder() async {
    if (isSupported && _initialized) {
      await _plugin.cancel(id: gacGmEodReminderId);
    }
  }

  /// Schedules local recurring management reminders from the BOM (11:30 AM)
  /// for the user or previous user.
  Future<int> scheduleBomGmReminders({
    String? userType,
    String? branch,
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final effectiveUserType =
        userType ?? prefs.getString(gacPreviousUserTypeKey) ?? '';
    if (TaskReminderPlanner.isAdminRole(effectiveUserType) ||
        TaskReminderPlanner.isUtilitiesRole(effectiveUserType)) {
      await cancelBomGmReminders(preferences: prefs);
      return 0; // Admins, GMs, and BOMs already receive management oversight alerts; 5S Utilities do not receive BOM notices
    }

    if (!isSupported || !_initialized) return 0;
    final enabled =
        (prefs.getBool(gacPushNotificationsEnabledKey) ?? true) &&
        (prefs.getBool(gacDueRemindersEnabledKey) ?? true);
    if (!enabled) return 0;

    final effectiveBranch = branch ?? prefs.getString(gacPreviousBranchKey);
    final reminders = TaskReminderPlanner.bomGmReminders(
      userType: effectiveUserType,
      branch: effectiveBranch,
    );
    if (reminders.isEmpty) {
      await cancelBomGmReminders(preferences: prefs);
      return 0;
    }

    // Cancel previously scheduled BOM/GM reminders
    await cancelBomGmReminders(preferences: prefs);

    configureLocalTimezone();
    final now = tz.TZDateTime.now(tz.local);
    var count = 0;
    final scheduledIds = <String>[];
    for (final reminder in reminders) {
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: scheduledDate,
        notificationDetails: _bomGmDetails(reminder.body),
        androidScheduleMode: _exactAlarmsAvailable
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.payload.encode(),
        matchDateTimeComponents: DateTimeComponents.time,
      );
      scheduledIds.add(reminder.id.toString());
      count++;
    }
    await prefs.setStringList(_scheduledBomGmReminderIdsKey, scheduledIds);
    return count;
  }

  /// Polls the remembered inbox while the app process is running, including
  /// the login screen after timeout. Android WorkManager covers closed apps.
  void startTimedOutManagerNotificationPolling({
    NotificationRepository? repository,
    Duration interval = const Duration(seconds: 45),
  }) {
    _timedOutManagerPollTimer?.cancel();
    _timedOutManagerPollTimer = Timer.periodic(interval, (_) {
      unawaited(syncBomGmNotifications(repository: repository));
    });
  }

  /// Stops periodic background/timed-out polling for manager updates.
  void stopTimedOutManagerNotificationPolling() {
    _timedOutManagerPollTimer?.cancel();
    _timedOutManagerPollTimer = null;
  }

  /// Presents the last user's server alerts independently of Remember Me.
  Future<int> syncBomGmNotifications({
    NotificationRepository? repository,
  }) async {
    if (_syncingInbox) return 0;
    _syncingInbox = true;
    try {
      return await _syncRememberedInbox(repository: repository);
    } finally {
      _syncingInbox = false;
    }
  }

  Future<int> _syncRememberedInbox({NotificationRepository? repository}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final notificationsEnabled =
        preferences.getBool(gacPushNotificationsEnabledKey) ?? true;
    if (!notificationsEnabled) return 0;

    final token =
        preferences.getString(gacNotificationTokenKey) ??
        preferences.getString(gacAuthTokenKey) ??
        preferences.getString(gacPreviousAuthTokenKey);

    var count = 0;
    // Older servers use the previous API token until the next upgraded login.
    if (token != null && token.trim().isNotEmpty) {
      try {
        final repo =
            repository ??
            NotificationApiService(preferencesLoader: () async => preferences);
        final inbox = await repo.fetchNotifications();
        final bomGmAlerts = inbox.notifications
            .where((n) => n.unread)
            .toList(growable: false);

        if (bomGmAlerts.isNotEmpty) {
          if (isSupported && _initialized) {
            final shown = await showUnreadInboxNotifications(bomGmAlerts);
            if (shown > 0) return shown;
          }
          count = bomGmAlerts.length;
        }
      } catch (_) {
        // Network or offline: fall through to schedule local reminders
      }
    }

    // Ensure local scheduled BOM/GM reminders are scheduled
    if (isSupported && _initialized) {
      return await scheduleBomGmReminders(preferences: preferences);
    }
    return count;
  }

  /// Alias for [syncBomGmNotifications] matching the naming convention of
  /// [syncForPreviousUser].
  Future<int> syncBomGmNotificationsForPreviousUser({
    NotificationRepository? repository,
  }) => syncBomGmNotifications(repository: repository);

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
      if (reminder.kind == TaskReminderKind.dosMonthEnd) {
        final occurrences = TaskReminderPlanner.monthEndOccurrences(
          DateTime(now.year, now.month, now.day, now.hour, now.minute),
          count: _dosMonthEndScheduleMonths,
          hour: reminder.hour,
          minute: reminder.minute,
        );
        for (var index = 0; index < occurrences.length; index++) {
          final occurrence = occurrences[index];
          final scheduledDate = tz.TZDateTime(
            tz.local,
            occurrence.year,
            occurrence.month,
            occurrence.day,
            occurrence.hour,
            occurrence.minute,
          );
          final auditDate =
              '${occurrence.year.toString().padLeft(4, '0')}-'
              '${occurrence.month.toString().padLeft(2, '0')}-'
              '${occurrence.day.toString().padLeft(2, '0')}';
          final payload = TaskReminderPayload(
            event: reminder.payload.event,
            templateSlug: reminder.payload.templateSlug,
            slotKey: reminder.payload.slotKey,
            auditDate: auditDate,
          );
          final notificationId = reminder.id + index;
          await _plugin.zonedSchedule(
            id: notificationId,
            title: reminder.title,
            body: reminder.body,
            scheduledDate: scheduledDate,
            notificationDetails: _details(reminder.body),
            androidScheduleMode: _exactAlarmsAvailable
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload.encode(),
          );
          scheduledIds.add(notificationId.toString());
        }
        continue;
      }

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

    final bomGmIds =
        preferences.getStringList(_scheduledBomGmReminderIdsKey) ?? const [];
    for (final encoded in bomGmIds) {
      final id = int.tryParse(encoded);
      if (id != null) await _plugin.cancel(id: id);
    }
    await preferences.remove(_scheduledBomGmReminderIdsKey);
    if (isSupported && _initialized) {
      await _plugin.cancel(id: gacGmEodReminderId);
    }
  }

  Future<void> recordPreviousUser(
    AuthenticatedUser user, {
    String? token,
    bool? rememberMe,
    String? notificationToken,
    bool replaceNotificationAccount = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final previousId = preferences.getString(gacPreviousUserIdKey);
    final nextId = user.id.toString();
    if (previousId != nextId) {
      stopTimedOutManagerNotificationPolling();
      await preferences.remove(gacNotificationTokenKey);
      await preferences.remove(gacPreviousAuthTokenKey);
      await preferences.remove(gacPendingNotificationPayloadKey);
      await preferences.remove(_shownInboxNotificationIdsKey);
      if (isSupported && _initialized) await _plugin.cancelAll();
    }
    await preferences.setString(gacPreviousUserIdKey, nextId);
    if (replaceNotificationAccount) {
      if (notificationToken != null && notificationToken.isNotEmpty) {
        await preferences.setString(gacNotificationTokenKey, notificationToken);
      } else {
        await preferences.remove(gacNotificationTokenKey);
      }
    }
    final assignment = TaskReminderPlanner.normalizedAssignment(user);
    await preferences.setString(gacPreviousUserTypeKey, user.canonicalUserType);
    await preferences.setString(gacPreviousAssignmentKey, assignment);
    await preferences.setString(
      gacPreviousAssignmentLabelKey,
      user.assignmentLabel,
    );
    if (user.branch != null && user.branch!.trim().isNotEmpty) {
      await preferences.setString(gacPreviousBranchKey, user.branch!.trim());
    } else {
      await preferences.remove(gacPreviousBranchKey);
    }
    if (preferences.getString(gacNotificationTokenKey) != null) {
      await preferences.remove(gacPreviousAuthTokenKey);
    } else if (token != null && token.isNotEmpty) {
      await preferences.setString(gacPreviousAuthTokenKey, token);
    }
    if (rememberMe != null) {
      await preferences.setBool(gacPreviousRememberMeKey, rememberMe);
    }
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
      return showTestNotification(
        TaskReminderKind.admin,
        userType: effectiveUserType,
      );
    }
    if (TaskReminderPlanner.isDosRole(effectiveUserType)) {
      return showTestNotification(
        TaskReminderKind.dosMonthEnd,
        userType: effectiveUserType,
      );
    }
    final effectiveAssignment =
        assignment ?? await getPreviousAssignment() ?? '';
    final kind = TaskReminderPlanner.isUtilitiesAssignment(effectiveAssignment)
        ? TaskReminderKind.utilities
        : TaskReminderKind.shift;
    return showTestNotification(kind, userType: effectiveUserType);
  }

  Future<bool> showTestNotification(
    TaskReminderKind kind, {
    int? leadTimeMinutes,
    String? userType,
  }) async {
    if (!isSupported || !_initialized) return false;
    if (!await requestPermissions(requestExactAlarms: false)) return false;

    final preferences = await SharedPreferences.getInstance();
    final effectiveLeadTime =
        leadTimeMinutes ??
        preferences.getInt(gacReminderLeadTimeKey) ??
        gacDefaultReminderLeadTimeMinutes;
    final leadTimeText = TaskReminderPlanner.formatLeadTime(effectiveLeadTime);

    final title = switch (kind) {
      TaskReminderKind.utilities => 'Utilities check in $leadTimeText',
      TaskReminderKind.admin => 'Morning compliance review',
      TaskReminderKind.dosMonthEnd => 'DOS checklist due today',
      TaskReminderKind.shift => 'Pre-shift checklist is ready',
      TaskReminderKind.bomGmReminder => 'BOM Checklist Reminder',
    };
    final body = switch (kind) {
      TaskReminderKind.utilities =>
        'The 8:00 AM cleaning and equipment inspection is due in '
            '$leadTimeText. Tap to open your checklist.',
      TaskReminderKind.admin =>
        'Opening 5S and facility inspections have started. '
            'Tap to review compliance.',
      TaskReminderKind.dosMonthEnd =>
        'Complete and submit your Sales/Aftersales DOS checklist today. '
            'It must be finished by 11:59 PM.',
      TaskReminderKind.shift =>
        'Your 8:00 AM shift starts in $leadTimeText. Complete the Sales & '
            'Service checklists now.',
      TaskReminderKind.bomGmReminder => 'Branch Operations Manager reminder: Complete your assigned inspection checklists and submit pending findings.',
    };
    final payload = TaskReminderPayload(
      event: switch (kind) {
        TaskReminderKind.utilities => 'utilities_due_soon',
        TaskReminderKind.admin => 'admin_morning_oversight',
        TaskReminderKind.dosMonthEnd => 'dos_month_end_due',
        TaskReminderKind.shift => 'shift_checklist_due',
        TaskReminderKind.bomGmReminder => 'bom_midday_checkin',
      },
      templateSlug: kind == TaskReminderKind.utilities
          ? 'restroom'
          : kind == TaskReminderKind.dosMonthEnd
          ? TaskReminderPlanner.dosTemplateSlugForRole(userType)
          : null,
      slotKey: kind == TaskReminderKind.utilities ? '08:00' : null,
    );

    await _plugin.show(
      id: switch (kind) {
        TaskReminderKind.utilities => _testUtilitiesNotificationId,
        TaskReminderKind.admin => _testAdminNotificationId,
        TaskReminderKind.dosMonthEnd => _testDosMonthEndNotificationId,
        TaskReminderKind.shift => _testShiftNotificationId,
        TaskReminderKind.bomGmReminder => gacBomMiddayReminderId,
      },
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
      channelDescription: 'Utilities, pre-shift, management, and month-end DOS checklist reminders.',
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

  NotificationDetails _inboxDetails(String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      _inboxChannelId,
      'Checklist updates',
      channelDescription:
          'New assignments, draft reminders, and checklist status updates.',
      icon: 'ic_stat_gac',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(body),
      color: const Color(0xFF25B99A),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      channelShowBadge: true,
      ticker: 'Gateway checklist update',
      autoCancel: true,
    ),
  );

  NotificationDetails _bomGmDetails(String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      _bomGmChannelId,
      'BOM & GM Alerts',
      channelDescription: 'Urgent alerts, reminders, and requests from Branch Operations Managers and General Managers.',
      icon: 'ic_stat_gac',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(body),
      color: const Color(0xFFD32F2F),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      channelShowBadge: true,
      ticker: 'Urgent notice from Management',
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
