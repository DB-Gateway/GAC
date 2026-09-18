import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/config/api_config.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_settings_screen.dart';
import 'package:gac_flutter/services/local_notification_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TaskReminderPlanner', () {
    test('plans each utilities slot five minutes before it is due', () {
      final reminders = TaskReminderPlanner.forUser(
        user: _user(assignment: 'utilities'),
        checklists: [
          _catalog(
            slug: 'restroom',
            settings: const {
              'validation_mode': 'time_slots',
              'time_slots': [
                {'key': '08:00', 'label': '8 AM'},
                {'key': '09:00', 'label': '9 AM'},
                {'key': '13:00', 'label': '1 PM'},
              ],
            },
          ),
        ],
      );

      expect(
        reminders
            .map((reminder) => '${reminder.hour}:${reminder.minute}')
            .toList(),
        ['7:55', '8:55', '12:55'],
      );
      expect(reminders.first.title, 'Utilities check in 5 minutes');
      expect(reminders.first.body, contains('8:00 AM'));
      expect(reminders.first.payload.templateSlug, 'restroom');
      expect(reminders.first.payload.slotKey, '08:00');
    });

    test('handles a utilities slot just after midnight', () {
      final reminders = TaskReminderPlanner.forUser(
        user: _user(assignment: 'restroom'),
        checklists: [
          _catalog(
            slug: 'utilities',
            settings: const {
              'validation_mode': 'time_slots',
              'time_slots': ['00:03'],
            },
          ),
        ],
      );

      expect(reminders.single.hour, 23);
      expect(reminders.single.minute, 58);
    });

    test('groups the Sales and Service window into one reminder', () {
      final reminders = TaskReminderPlanner.forUser(
        user: _user(assignment: 'sales_service'),
        checklists: [
          _catalog(
            slug: 'sales',
            settings: const {
              'schedule': {'start': '08:00', 'end': '08:30'},
            },
          ),
          _catalog(
            slug: 'service',
            settings: const {
              'schedule': {'start': '08:00', 'end': '08:30'},
            },
          ),
        ],
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.hour, 7);
      expect(reminders.single.minute, 30);
      expect(reminders.single.body, contains('8:00 AM shift'));
      expect(reminders.single.body, contains('Sales & Service checklists'));
      expect(reminders.single.payload.templateSlug, isNull);
    });

    test('prefers an explicit shift start and alerts 30 minutes before', () {
      final reminders = TaskReminderPlanner.forUser(
        user: _user(assignment: 'sales'),
        checklists: [
          _catalog(
            slug: 'sales',
            settings: const {
              'shift_start': '08:00',
              'schedule': {'start': '07:30', 'end': '08:00'},
            },
          ),
        ],
      );

      expect(reminders.single.hour, 7);
      expect(reminders.single.minute, 30);
      expect(reminders.single.payload.templateSlug, 'sales');
    });

    test('does not schedule reminders for inactive or unrelated users', () {
      expect(
        TaskReminderPlanner.forUser(
          user: _user(assignment: 'utilities', accountStatus: 'pending'),
          checklists: const [],
        ),
        isEmpty,
      );
      expect(
        TaskReminderPlanner.forUser(
          user: _user(assignment: 'other'),
          checklists: const [],
        ),
        isEmpty,
      );
    });

    test(
      'plans a same-day month-end reminder for DOS Sales and Aftersales',
      () {
        const roles = <String, String>{
          'DOS_SALES': 'dealer-operations-standards-sales',
          'SALES MANAGER': 'dealer-operations-standards-sales',
          'DOS_AFTERSALES': 'dealer-operations-standards',
          'ASM': 'dealer-operations-standards',
          'CE SERVICE': 'dealer-operations-standards',
          'JC': 'dealer-operations-standards',
          'PARTS': 'dealer-operations-standards',
          'WS SUP': 'dealer-operations-standards',
        };

        for (final entry in roles.entries) {
          final reminders = TaskReminderPlanner.forUser(
            user: AuthenticatedUser(
              id: entry.key.hashCode,
              name: entry.key,
              email: 'dos@gateway.test',
              userType: entry.key,
              accountStatus: 'active',
            ),
            checklists: const [],
          );

          expect(reminders, hasLength(1), reason: entry.key);
          expect(
            reminders.single.kind,
            TaskReminderKind.dosMonthEnd,
            reason: entry.key,
          );
          expect(reminders.single.hour, 8, reason: entry.key);
          expect(reminders.single.minute, 0, reason: entry.key);
          expect(reminders.single.body, contains('today'), reason: entry.key);
          expect(
            reminders.single.body,
            contains('11:59 PM'),
            reason: entry.key,
          );
          expect(
            reminders.single.payload.templateSlug,
            entry.value,
            reason: entry.key,
          );
          expect(
            reminders.single.payload.event,
            'dos_month_end_due',
            reason: entry.key,
          );
        }
      },
    );

    test('calculates real month ends including leap years', () {
      final occurrences = TaskReminderPlanner.monthEndOccurrences(
        DateTime(2028, 1, 15, 9),
        count: 4,
      );

      expect(occurrences, [
        DateTime(2028, 1, 31, 8),
        DateTime(2028, 2, 29, 8),
        DateTime(2028, 3, 31, 8),
        DateTime(2028, 4, 30, 8),
      ]);
    });

    test('moves to next month once the current month-end alarm has passed', () {
      final occurrences = TaskReminderPlanner.monthEndOccurrences(
        DateTime(2026, 9, 30, 8),
        count: 2,
      );

      expect(occurrences, [
        DateTime(2026, 10, 31, 8),
        DateTime(2026, 11, 30, 8),
      ]);
    });
  });

  group('TaskReminderPayload', () {
    test('round-trips the checklist deep-link fields', () {
      const original = TaskReminderPayload(
        event: 'checklist_draft_reminder',
        templateSlug: 'dealer-operations-standards',
        slotKey: '09:00',
        auditDate: '2026-09-03',
        notificationId: 'notice-42',
        submissionId: 42,
        itemKey: 'documentation-2',
        customerIndex: 1,
      );

      final parsed = TaskReminderPayload.tryParse(original.encode());

      expect(parsed?.event, original.event);
      expect(parsed?.templateSlug, original.templateSlug);
      expect(parsed?.slotKey, original.slotKey);
      expect(parsed?.auditDate, original.auditDate);
      expect(parsed?.notificationId, original.notificationId);
      expect(parsed?.submissionId, original.submissionId);
      expect(parsed?.itemKey, original.itemKey);
      expect(parsed?.customerIndex, original.customerIndex);
      expect(parsed?.targetsDosChecklist, isTrue);
    });

    test('accepts checklist_slug alias and rejects malformed payloads', () {
      final parsed = TaskReminderPayload.tryParse(
        '{"event":"shift_checklist_due","checklist_slug":"sales"}',
      );

      expect(parsed?.templateSlug, 'sales');
      expect(TaskReminderPayload.tryParse('not json'), isNull);
      expect(TaskReminderPayload.tryParse('{"template_slug":"sales"}'), isNull);
    });
  });

  group('UserType and Assignment isolation', () {
    test('identifies utilities and sales/service assignments accurately', () {
      expect(TaskReminderPlanner.isUtilitiesAssignment('utilities'), isTrue);
      expect(TaskReminderPlanner.isUtilitiesAssignment('utility'), isTrue);
      expect(TaskReminderPlanner.isUtilitiesAssignment('restroom'), isTrue);
      expect(
        TaskReminderPlanner.isUtilitiesAssignment('sales_service'),
        isFalse,
      );

      expect(
        TaskReminderPlanner.isSalesServiceAssignment('sales_service'),
        isTrue,
      );
      expect(TaskReminderPlanner.isSalesServiceAssignment('sales'), isTrue);
      expect(TaskReminderPlanner.isSalesServiceAssignment('service'), isTrue);
      expect(
        TaskReminderPlanner.isSalesServiceAssignment('utilities'),
        isFalse,
      );
    });

    test('normalizes user assignment from picAssignmentType and label', () {
      final utilitiesUser = _user(assignment: 'Utilities');
      expect(
        TaskReminderPlanner.normalizedAssignment(utilitiesUser),
        'utilities',
      );

      final salesServiceUser = _user(assignment: 'Sales & Service');
      expect(
        TaskReminderPlanner.normalizedAssignment(salesServiceUser),
        'sales_service',
      );

      const util5s = AuthenticatedUser(
        id: 11,
        name: '5S Utilities',
        email: 'util@gateway.test',
        userType: '5S_UTILITIES',
        accountStatus: 'active',
      );
      expect(TaskReminderPlanner.normalizedAssignment(util5s), 'utilities');

      const sales5s = AuthenticatedUser(
        id: 12,
        name: '5S Sales',
        email: 'sales@gateway.test',
        userType: '5S_SALES',
        accountStatus: 'active',
      );
      expect(TaskReminderPlanner.normalizedAssignment(sales5s), 'sales');

      const service5s = AuthenticatedUser(
        id: 13,
        name: '5S Service',
        email: 'service@gateway.test',
        userType: '5S_SERVICE',
        accountStatus: 'active',
      );
      expect(TaskReminderPlanner.normalizedAssignment(service5s), 'service');
    });

    test(
      'persists previous user type and assignment across logout/exit',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = LocalNotificationService.instance;
        final user = _user(assignment: 'utilities');

        await service.recordPreviousUser(user);

        expect(await service.getPreviousUserType(), 'PIC');
        expect(await service.getPreviousAssignment(), 'utilities');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(gacPreviousUserTypeKey), 'PIC');
        expect(prefs.getString(gacPreviousAssignmentKey), 'utilities');
      },
    );

    test(
      'saves and consumes pending notification payload for manual login',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = LocalNotificationService.instance;
        const payload = TaskReminderPayload(
          event: 'utilities_due_soon',
          templateSlug: 'restroom',
          slotKey: '09:00',
        );

        await service.setPendingPayload(payload);

        final consumed = await service.consumePendingPayload();
        expect(consumed?.event, 'utilities_due_soon');
        expect(consumed?.templateSlug, 'restroom');
        expect(consumed?.slotKey, '09:00');

        // Subsequent consumption returns null
        expect(await service.consumePendingPayload(), isNull);
      },
    );
  });

  group('Lead Time Preferences and Planning', () {
    test('plans utilities reminders according to custom leadTimeMinutes', () {
      final catalog = [
        _catalog(
          slug: 'restroom',
          settings: const {
            'validation_mode': 'time_slots',
            'time_slots': [
              {'key': '09:00', 'label': '9 AM'},
            ],
          },
        ),
      ];

      // 5 minutes (default preset)
      final reminders5 = TaskReminderPlanner.forUser(
        user: _user(assignment: 'utilities'),
        checklists: catalog,
        leadTimeMinutes: 5,
      );
      expect(reminders5.single.hour, 8);
      expect(reminders5.single.minute, 55);
      expect(reminders5.single.title, 'Utilities check in 5 minutes');
      expect(reminders5.single.body, contains('is due in 5 minutes'));

      // 10 minutes
      final reminders10 = TaskReminderPlanner.forUser(
        user: _user(assignment: 'utilities'),
        checklists: catalog,
        leadTimeMinutes: 10,
      );
      expect(reminders10.single.hour, 8);
      expect(reminders10.single.minute, 50);
      expect(reminders10.single.title, 'Utilities check in 10 minutes');

      // 15 minutes
      final reminders15 = TaskReminderPlanner.forUser(
        user: _user(assignment: 'utilities'),
        checklists: catalog,
        leadTimeMinutes: 15,
      );
      expect(reminders15.single.hour, 8);
      expect(reminders15.single.minute, 45);
      expect(reminders15.single.title, 'Utilities check in 15 minutes');

      // 30 minutes
      final reminders30 = TaskReminderPlanner.forUser(
        user: _user(assignment: 'utilities'),
        checklists: catalog,
        leadTimeMinutes: 30,
      );
      expect(reminders30.single.hour, 8);
      expect(reminders30.single.minute, 30);
      expect(reminders30.single.title, 'Utilities check in 30 minutes');

      // 1 hour (60 minutes)
      final reminders60 = TaskReminderPlanner.forUser(
        user: _user(assignment: 'utilities'),
        checklists: catalog,
        leadTimeMinutes: 60,
      );
      expect(reminders60.single.hour, 8);
      expect(reminders60.single.minute, 0);
      expect(reminders60.single.title, 'Utilities check in 1 hour');
      expect(reminders60.single.body, contains('is due in 1 hour'));
    });

    test('formatLeadTime formats minutes and hours cleanly', () {
      expect(TaskReminderPlanner.formatLeadTime(5), '5 minutes');
      expect(TaskReminderPlanner.formatLeadTime(10), '10 minutes');
      expect(TaskReminderPlanner.formatLeadTime(15), '15 minutes');
      expect(TaskReminderPlanner.formatLeadTime(30), '30 minutes');
      expect(TaskReminderPlanner.formatLeadTime(60), '1 hour');
      expect(TaskReminderPlanner.formatLeadTime(120), '2 hours');
    });

    test(
      'loads default leadTimeMinutes (5) and persists custom choice',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = LocalNotificationService.instance;

        // Default is 5 minutes
        final initialPrefs = await service.loadPreferences();
        expect(initialPrefs.leadTimeMinutes, 5);

        // Save 15 minutes
        await service.saveLeadTimeMinutes(15);
        final updatedPrefs = await service.loadPreferences();
        expect(updatedPrefs.leadTimeMinutes, 15);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(gacReminderLeadTimeKey), 15);
      },
    );

    testWidgets(
      'UserSettingsScreen displays preset 5 minutes lead time and EDIT button',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
        });

        await tester.pumpWidget(
          MaterialApp(theme: GacTheme.light, home: const UserSettingsScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Due-time reminders'), findsOneWidget);
        expect(find.text('5 minutes before task'), findsOneWidget);
        expect(find.text('EDIT'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping EDIT opens modal with options and persists chosen lead time',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
        });

        await tester.pumpWidget(
          MaterialApp(theme: GacTheme.light, home: const UserSettingsScreen()),
        );
        await tester.pumpAndSettle();

        // Tap EDIT
        await tester.tap(find.text('EDIT'));
        await tester.pumpAndSettle();

        // Verify modal and options
        expect(find.text('Due-Time Reminder'), findsOneWidget);
        expect(find.text('5 minutes before task'), findsWidgets);
        expect(find.text('PRESET (DEFAULT)'), findsOneWidget);
        expect(find.text('10 minutes before task'), findsOneWidget);
        expect(find.text('15 minutes before task'), findsOneWidget);
        expect(find.text('30 minutes before task'), findsOneWidget);
        expect(find.text('1 hour before task'), findsOneWidget);
        expect(find.text('SAVE PREFERENCE'), findsOneWidget);

        // Select 15 minutes before task
        await tester.tap(find.text('15 minutes before task'));
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.text('SAVE PREFERENCE'));
        await tester.pumpAndSettle();

        // Modal closed and UI updated
        expect(find.text('Due-Time Reminder'), findsNothing);
        expect(find.text('15 minutes before task'), findsOneWidget);

        // Preference persisted
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(gacReminderLeadTimeKey), 15);
      },
    );

    testWidgets(
      'Push notifications and Due-time reminders toggles update preferences',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
        });

        await tester.pumpWidget(
          MaterialApp(theme: GacTheme.light, home: const UserSettingsScreen()),
        );
        await tester.pumpAndSettle();

        // Tap Due-time reminders row to toggle it off
        await tester.tap(find.text('Due-time reminders'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(gacDueRemindersEnabledKey), isFalse);

        // When reminders disabled, edit pill is hidden
        expect(find.text('EDIT'), findsNothing);
      },
    );

    testWidgets('DOS settings offer only the DOS month-end reminder test', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: const UserSettingsScreen(
            profile: AuthenticatedUser(
              id: 112,
              name: 'Workshop Supervisor',
              email: 'workshop.supervisor@gateway.com',
              userType: 'WS SUP',
              accountStatus: 'active',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('test-utilities-notification')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('test-shift-notification')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('test-dos-month-end-notification')),
        findsOneWidget,
      );
      expect(find.text('Month-end DOS reminder'), findsOneWidget);
      expect(find.textContaining('finish by 11:59 PM'), findsOneWidget);
      expect(find.text('EDIT'), findsNothing);
      expect(
        find.byKey(const ValueKey('test-background-alert')),
        findsOneWidget,
      );
      expect(find.textContaining('final calendar day'), findsWidgets);
    });
  });

  group('Offline and Role-Based Planning (Timed-Out Users)', () {
    test('schedules only the month-end checklist reminder for DOS roles', () {
      for (final role in const [
        'SALES_MANAGER',
        'ASM',
        'CE SERVICE',
        'JOB CONTROLLER',
        'PARTS SUPERVISOR',
        'WS SUP',
      ]) {
        expect(TaskReminderPlanner.isDosRole(role), isTrue, reason: role);
        final plan = TaskReminderPlanner.forRole(
          userType: role,
          assignment: role,
          checklists: const [],
        );
        expect(plan, hasLength(1), reason: role);
        expect(plan.single.kind, TaskReminderKind.dosMonthEnd, reason: role);
        expect(plan.single.body, contains('11:59 PM'), reason: role);
      }
    });

    test('legacy standalone workshop aliases remain DOS-only inputs', () {
      for (final legacyRole in const ['WS', 'WORKSHOP']) {
        expect(
          TaskReminderPlanner.isDosRole(legacyRole),
          isTrue,
          reason: legacyRole,
        );
        final plan = TaskReminderPlanner.forRole(
          userType: legacyRole,
          assignment: legacyRole,
          checklists: const [],
        );
        expect(plan, hasLength(1), reason: legacyRole);
        expect(
          plan.single.kind,
          TaskReminderKind.dosMonthEnd,
          reason: legacyRole,
        );
        expect(
          plan.single.payload.templateSlug,
          'dealer-operations-standards',
          reason: legacyRole,
        );
      }
    });

    test('identifies admin and GM roles correctly', () {
      expect(TaskReminderPlanner.isAdminRole('ADMIN'), isTrue);
      expect(TaskReminderPlanner.isAdminRole('GM'), isTrue);
      expect(TaskReminderPlanner.isAdminRole('General Manager'), isTrue);
      expect(TaskReminderPlanner.isAdminRole('BOM'), isTrue);
      expect(
        TaskReminderPlanner.isAdminRole('Branch Operations Manager'),
        isTrue,
      );
      expect(TaskReminderPlanner.isAdminRole('PIC'), isFalse);
      expect(TaskReminderPlanner.isAdminRole('5S_UTILITIES'), isFalse);
      expect(TaskReminderPlanner.isAdminRole('5S_SERVICE'), isFalse);
      expect(TaskReminderPlanner.isAdminRole('5S_SALES'), isFalse);
      expect(TaskReminderPlanner.isAdminRole(null), isFalse);
    });

    test('plans management compliance alerts for Admin and GM roles', () {
      final adminPlan = TaskReminderPlanner.forRole(userType: 'ADMIN');
      expect(adminPlan, hasLength(3));
      expect(adminPlan[0].hour, 8);
      expect(adminPlan[0].minute, 30);
      expect(adminPlan[0].title, contains('Morning'));
      expect(adminPlan[1].hour, 12);
      expect(adminPlan[1].minute, 0);
      expect(adminPlan[1].title, contains('Midday'));
      expect(adminPlan[2].hour, 17);
      expect(adminPlan[2].minute, 0);
      expect(adminPlan[2].title, contains('Daily'));
    });

    test('plans fallback 9 utilities slots for 5S Utilities when checklists is empty (offline/timed-out)', () {
      final plan = TaskReminderPlanner.forRole(
        userType: '5S_UTILITIES',
        assignment: 'utilities',
        checklists: const [],
        leadTimeMinutes: 5,
      );

      expect(plan, hasLength(9));
      expect(plan.first.hour, 7);
      expect(plan.first.minute, 55);
      expect(plan.first.payload.templateSlug, 'restroom');
      expect(plan.last.hour, 16);
      expect(plan.last.minute, 55);
    });

    test('plans fallback shift reminder for 5S Sales when checklists is empty (offline/timed-out)', () {
      final plan = TaskReminderPlanner.forRole(
        userType: '5S_SALES',
        assignment: 'sales',
        checklists: const [],
        leadTimeMinutes: 30,
      );

      expect(plan, hasLength(1));
      expect(plan.single.hour, 7);
      expect(plan.single.minute, 30);
      expect(plan.single.body, contains('8:00 AM shift'));
      expect(plan.single.payload.templateSlug, 'sales');
    });

    test('plans fallback shift reminder for 5S Service when checklists is empty (offline/timed-out)', () {
      final plan = TaskReminderPlanner.forRole(
        userType: '5S_SERVICE',
        assignment: 'service',
        checklists: const [],
        leadTimeMinutes: 30,
      );

      expect(plan, hasLength(1));
      expect(plan.single.hour, 7);
      expect(plan.single.minute, 30);
      expect(plan.single.body, contains('8:00 AM shift'));
      expect(plan.single.payload.templateSlug, 'service');
    });

    test('recordPreviousRole persists userType and assignment for timeout recovery', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LocalNotificationService.instance;

      await service.recordPreviousRole(
        userType: 'GM',
        assignment: 'management',
        assignmentLabel: 'General Manager',
      );

      expect(await service.getPreviousUserType(), 'GM');
      expect(await service.getPreviousAssignment(), 'management');
    });
  });
}

AuthenticatedUser _user({
  required String assignment,
  String accountStatus = 'active',
}) => AuthenticatedUser(
  id: 7,
  name: 'Gateway PIC',
  email: 'pic@gateway.test',
  userType: 'PIC',
  picAssignmentType: assignment,
  picAssignmentLabel: assignment,
  accountStatus: accountStatus,
);

ChecklistCatalogItem _catalog({
  required String slug,
  required Map<String, dynamic> settings,
}) => ChecklistCatalogItem(
  id: slug.hashCode,
  slug: slug,
  name: '$slug checklist',
  description: null,
  version: 1,
  settings: settings,
  sectionCount: 1,
  itemCount: 1,
  submission: null,
);
