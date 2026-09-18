import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_checklist_detail_screen.dart';
import 'package:gac_flutter/screens/user_checklists_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hourly attention link keeps the affected question and expired slot visible', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: GacTheme.light,
      home: UserChecklistDetailScreen(
        slug: 'utilities', repository: _FakeChecklistRepository(),
        auditDate: '2026-09-08', initialSlotKey: '13:00',
        initialItemKey: 'sink-clean',
        nowProvider: () => DateTime(2026, 9, 8, 16, 15),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('QUESTION 2 / 2'), findsOneWidget);
    expect(find.text('TIME WINDOW CLOSED FOR 1:00 PM'), findsOneWidget);
    expect(find.text('SELECT CONDITION FOR 4:00 PM:'), findsNothing);
  });

  testWidgets('PIC catalog renders Server templates and opens section page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeChecklistRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: GacTheme.light,
        home: UserChecklistsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sales Checklist'), findsOneWidget);
    expect(find.text('Service Checklist'), findsOneWidget);
    expect(find.text('Restroom Checklist'), findsNothing);

    await tester.tap(find.text('START CHECKLIST').first);
    await tester.pumpAndSettle();

    expect(find.text('Parking Area'), findsOneWidget);
    expect(
      find.text('Is the parking area clean and clearly marked?'),
      findsOneWidget,
    );
    expect(find.text('SECTION 1 OF 1  ·  VERSION 4'), findsOneWidget);
  });

  testWidgets('a PIC answer is auto-saved to Server when leaving', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeChecklistRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: GacTheme.light,
        home: UserChecklistsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('START CHECKLIST').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('YES'));
    expect(find.text('SAVE DRAFT'), findsNothing);
    expect(
      find.byKey(const ValueKey('checklist-header-submit-button')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Back to checklists'));
    await tester.pumpAndSettle();

    expect(repository.savedSlug, 'sales');
    expect(repository.savedResponses, hasLength(1));
    expect(repository.savedResponses.single['item_key'], 'item-1');
    expect(repository.savedResponses.single['status'], 'yes');
    expect(repository.savedContext?['draft_position'], {'item_key': 'item-1'});
  });

  testWidgets('notification deep link opens its assigned checklist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeChecklistRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: GacTheme.light,
        home: UserChecklistsScreen(
          repository: repository,
          initialSlug: 'utilities',
          initialSlotKey: '08:00',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Utilities Checklist'), findsWidgets);
    expect(find.text('QUESTION 1 / 2'), findsOneWidget);
    expect(find.text('8:00 AM'), findsWidgets);
  });

  testWidgets(
    'utilities checklist opens in mobile-friendly question-by-question mode with big good/not good buttons',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            auditDate: '2026-09-08',
            nowProvider: () => DateTime(2026, 9, 8, 8, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify question-by-question view elements
      expect(find.text('QUESTION 1 / 2'), findsOneWidget);
      expect(find.text('Are mirrors clean and spotless?'), findsOneWidget);
      expect(find.text('YES'), findsOneWidget);
      expect(find.text('NO'), findsOneWidget);

      // Select 8:00 AM slot
      await tester.tap(find.text('8:00 AM'));
      await tester.pumpAndSettle();

      // Tap NOT GOOD to reveal remarks and photo attachment
      await tester.tap(find.text('NO'));
      await tester.pumpAndSettle();

      expect(find.text('MARKED NO'), findsOneWidget);
      expect(find.text('REMARKS & DEFECT DETAILS'), findsOneWidget);
      expect(find.text('ATTACH PHOTO (OPTIONAL)'), findsOneWidget);

      // Enter remark
      await tester.enterText(
        find.byType(TextField).first,
        'Mirror glass has water spots',
      );
      await tester.pumpAndSettle();

      // Complete this hourly inspection. Intermediate hours are persisted by
      // the draft endpoint so the next scheduled hour remains available.
      await tester.tap(find.widgetWithText(FilledButton, 'NEXT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUBMIT'));
      await tester.pumpAndSettle();

      expect(repository.submittedSlug, 'utilities');
      expect(repository.submittedResponses, hasLength(2));
      final mirrorResponse = repository.submittedResponses.firstWhere(
        (response) => response['item_key'] == 'mirror-clean',
      );
      expect(mirrorResponse['remark'], 'Mirror glass has water spots');
      expect(mirrorResponse['details']['slots']['08:00'], 'not_good');
      expect(find.text('HOUR COMPLETE'), findsOneWidget);
    },
  );

  testWidgets(
    'utilities checklist NEXT button is disabled until condition is chosen for active slot',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            auditDate: '2026-09-08',
            nowProvider: () => DateTime(2026, 9, 8, 8, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nextButtonFinder = find.widgetWithText(FilledButton, 'NEXT');
      expect(nextButtonFinder, findsOneWidget);

      // Initially 8:00 AM slot is unlocked, but condition is unselected: NEXT button is disabled
      FilledButton nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNull);

      // Tap GOOD: NEXT button becomes enabled
      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();

      nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNotNull);

      // Tap NEXT to advance to Question 2
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 2 / 2'), findsOneWidget);
      expect(
        find.text('Is the sink clean and working properly?'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'utilities checklist renders database draft with attachment photo preview',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      repository.initialSubmission = const ChecklistSubmissionData(
        id: 99,
        status: 'draft',
        auditDate: '2026-09-03',
        templateVersion: 1,
        scores: {'total': 2, 'answered': 1},
        responses: {
          'mirror-clean': ChecklistResponseData(
            itemId: 101,
            itemKey: 'mirror-clean',
            status: 'no',
            remark: 'Cracked glass on left side',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            attachmentPath:
                'checklist-attachments/utilities/2026-09-03/broken_mirror.jpg',
            attachmentUrl: 'http://localhost/storage/checklist-attachments/utilities/2026-09-03/broken_mirror.jpg',
            details: {
              'slots': {'08:00': 'not_good'},
            },
          ),
        },
        answeredItems: 1,
        totalItems: 2,
        completionPercentage: 50,
        submittedAt: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            initialQuestionIndex: 0,
            auditDate: '2026-09-08',
            nowProvider: () => DateTime(2026, 9, 8, 8, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('8:00 AM'));
      await tester.pumpAndSettle();

      expect(find.text('MARKED NO'), findsOneWidget);
      expect(find.text('Cracked glass on left side'), findsOneWidget);
      expect(find.text('Photo attached'), findsOneWidget);
    },
  );

  testWidgets('utilities checklist only allows the current hourly time slot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeChecklistRepository();
    var currentTime = DateTime(2026, 9, 8, 8, 59, 59);
    await tester.pumpWidget(
      MaterialApp(
        theme: GacTheme.light,
        home: UserChecklistDetailScreen(
          slug: 'utilities',
          repository: repository,
          auditDate: '2026-09-08',
          nowProvider: () => currentTime,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The 8:00 AM task remains editable through the final second of 8:59 AM.
    expect(find.text('SELECT CONDITION FOR 8:00 AM:'), findsOneWidget);

    // At exactly 9:00 AM, the 8:00 AM task expires permanently.
    currentTime = DateTime(2026, 9, 8, 9);
    await tester.tap(find.text('8:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('TIME WINDOW CLOSED FOR 8:00 AM'), findsOneWidget);
    expect(find.text('INSPECTION FOR 8:00 AM IS LOCKED'), findsOneWidget);

    // Tapping YES cannot change an expired hour.
    await tester.tap(find.text('YES'));
    await tester.pumpAndSettle();

    // Tap on the future 10:00 AM slot.
    await tester.tap(find.text('10:00 AM'));
    await tester.pumpAndSettle();

    // Verify lock warning banner appears and condition buttons are disabled
    expect(find.text('LOCKED UNTIL 10:00 AM'), findsOneWidget);
    expect(find.text('INSPECTION FOR 10:00 AM IS LOCKED'), findsOneWidget);

    // Attempting to tap YES on locked slot does not mark it
    await tester.tap(find.text('YES'));
    await tester.pumpAndSettle();

    // The 9:00 AM task becomes editable immediately at 9:00 AM.
    await tester.tap(find.text('9:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('TIME WINDOW CLOSED FOR 8:00 AM'), findsNothing);
    expect(find.text('SELECT CONDITION FOR 9:00 AM:'), findsOneWidget);

    await tester.tap(find.text('YES'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'NEXT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YES'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    expect(repository.submittedSlug, 'utilities');
    expect(repository.submittedResponses, hasLength(2));
    final mirrorResponse = repository.submittedResponses.firstWhere(
      (response) => response['item_key'] == 'mirror-clean',
    );
    final sinkResponse = repository.submittedResponses.firstWhere(
      (response) => response['item_key'] == 'sink-clean',
    );
    expect(mirrorResponse['details']['slots']['09:00'], 'good');
    // Every unanswered question in the expired hour is recorded as Not Good.
    expect(mirrorResponse['details']['slots']['08:00'], 'not_good');
    expect(sinkResponse['details']['slots']['08:00'], 'not_good');
    expect(sinkResponse['details']['slots']['09:00'], 'good');
    // Future hours are never added early.
    expect(mirrorResponse['details']['slots']['23:00'], isNull);
    expect(sinkResponse['details']['slots']['23:00'], isNull);
  });

  testWidgets(
    'utilities submits the complete 8 AM inspection without requiring 9 AM',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      var returnedToChecklistList = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            auditDate: '2026-09-08',
            nowProvider: () => DateTime(2026, 9, 8, 8, 52),
            onBack: () => returnedToChecklistList = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'NEXT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUBMIT'));
      await tester.pumpAndSettle();

      // Intermediate hours submit to Server so compliance administrators receive notifications
      // while subsequent hours remain open.
      expect(repository.submittedSlug, 'utilities');
      expect(repository.submittedResponses, hasLength(2));
      for (final response in repository.submittedResponses) {
        final slots = response['details']['slots'] as Map<String, String>;
        expect(slots['08:00'], 'good');
        expect(slots['09:00'], isNull);
        expect(response['details']['submitted_slots'], contains('08:00'));
      }
      expect(find.text('HOUR COMPLETE'), findsOneWidget);
      expect(find.text('8:00 AM inspection submitted'), findsOneWidget);
      expect(
        find.text(
          'This hour was saved. The next inspection will be available at 9:00 AM.',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('checklist-message-ok-button')),
      );
      await tester.pumpAndSettle();
      expect(returnedToChecklistList, isTrue);
    },
  );

  testWidgets(
    'utilities shows a green already-submitted state and disables submission for a completed hour',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      repository.initialSubmission = const ChecklistSubmissionData(
        id: 101,
        status: 'draft',
        auditDate: '2026-09-08',
        templateVersion: 1,
        scores: {'total': 2, 'answered': 2},
        responses: {
          'mirror-clean': ChecklistResponseData(
            itemId: 101,
            itemKey: 'mirror-clean',
            status: 'yes',
            remark: null,
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {
              'slots': {'08:00': 'good'},
              'submitted_slots': ['08:00'],
            },
          ),
          'sink-clean': ChecklistResponseData(
            itemId: 102,
            itemKey: 'sink-clean',
            status: 'yes',
            remark: null,
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {
              'slots': {'08:00': 'good'},
              'submitted_slots': ['08:00'],
            },
          ),
        },
        answeredItems: 2,
        totalItems: 2,
        completionPercentage: 20,
        submittedAt: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            auditDate: '2026-09-08',
            nowProvider: () => DateTime(2026, 9, 8, 8, 55),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ALREADY SUBMITTED'), findsOneWidget);
      expect(
        find.text('INSPECTION FOR 8:00 AM IS ALREADY SUBMITTED'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'SUBMIT'), findsNothing);
    },
  );

  testWidgets(
    'utilities can submit the current hour when the previous hour was missed',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      repository.initialSubmission = const ChecklistSubmissionData(
        id: 100,
        status: 'draft',
        auditDate: '2026-09-08',
        templateVersion: 1,
        scores: {'total': 2, 'answered': 2},
        responses: {
          'mirror-clean': ChecklistResponseData(
            itemId: 101,
            itemKey: 'mirror-clean',
            status: null,
            remark: null,
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {
              'slots': {'08:00': 'good'},
            },
          ),
          'sink-clean': ChecklistResponseData(
            itemId: 102,
            itemKey: 'sink-clean',
            status: null,
            remark: null,
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {
              'slots': {'08:00': 'good'},
            },
          ),
        },
        answeredItems: 2,
        totalItems: 2,
        completionPercentage: 25,
        submittedAt: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            auditDate: '2026-09-08',
            nowProvider: () => DateTime(2026, 9, 8, 10, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SELECT CONDITION FOR 10:00 AM:'), findsOneWidget);
      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'NEXT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUBMIT'));
      await tester.pumpAndSettle();

      expect(repository.submittedSlug, 'utilities');
      expect(repository.submittedResponses, hasLength(2));
      for (final response in repository.submittedResponses) {
        final slots = response['details']['slots'] as Map<String, String>;
        expect(slots['08:00'], 'good');
        expect(slots['09:00'], 'not_good');
        expect(slots['10:00'], 'good');
        expect(slots['23:00'], isNull);
      }
      expect(find.text('10:00 AM inspection submitted'), findsOneWidget);
    },
  );

  testWidgets(
    'utilities moves a stale 1 PM selection to the active 4 PM inspection',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            auditDate: '2026-09-08',
            initialSlotKey: '13:00',
            nowProvider: () => DateTime(2026, 9, 8, 16, 15),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SELECT CONDITION FOR 4:00 PM:'), findsOneWidget);
      expect(find.text('TIME WINDOW CLOSED FOR 1:00 PM'), findsNothing);

      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'NEXT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUBMIT'));
      await tester.pumpAndSettle();

      expect(repository.submittedSlug, 'utilities');
      for (final response in repository.submittedResponses) {
        final slots = response['details']['slots'] as Map<String, String>;
        expect(slots['13:00'], 'not_good');
        expect(slots['16:00'], 'good');
      }
    },
  );

  testWidgets(
    '5S utilities displays information icon and opens how to check guide or empty fallback',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            auditDate: '2026-09-08',
            nowProvider: () => DateTime(2026, 9, 8, 10, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First question ('mirror-clean') has no inputted guide
      final infoButton1 = find.byKey(
        const ValueKey('mirror-clean-how-to-check'),
      );
      expect(infoButton1, findsOneWidget);

      await tester.tap(infoButton1);
      await tester.pumpAndSettle();

      expect(find.text('HOW TO CHECK GUIDE'), findsOneWidget);
      expect(find.text('Question #1'), findsOneWidget);
      expect(find.text('Are mirrors clean and spotless?'), findsNWidgets(2));
      expect(
        find.text(
          'No detailed verification guide has been inputted for this checklist item yet.',
        ),
        findsOneWidget,
      );

      // Close modal
      await tester.tap(find.text('GOT IT'));
      await tester.pumpAndSettle();

      // Answer and proceed to second question ('sink-clean')
      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'NEXT'));
      await tester.pumpAndSettle();

      // Second question has an existing guide
      final infoButton2 = find.byKey(
        const ValueKey('sink-clean-how-to-check'),
      );
      expect(infoButton2, findsOneWidget);

      await tester.tap(infoButton2);
      await tester.pumpAndSettle();

      expect(find.text('HOW TO CHECK GUIDE'), findsOneWidget);
      expect(find.text('Question #2'), findsOneWidget);
      expect(
        find.text('Is the sink clean and working properly?'),
        findsNWidgets(2),
      );
      expect(
        find.text('Check sink for clogs, water flow, and soap residue.'),
        findsOneWidget,
      );

      await tester.tap(find.text('GOT IT'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'utilities reports an empty time-slot template without crashing',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _EmptyHourlyChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            auditDate: '2026-09-08',
            nowProvider: () => DateTime(2026, 9, 8, 16, 15),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUBMIT'));
      await tester.pumpAndSettle();

      expect(repository.savedSlug, isNull);
      expect(find.text('Checklist incomplete'), findsOneWidget);
      expect(
        find.text(
          'This checklist has no inspection time slots. Please ask an administrator to review its template.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'utilities blocks hourly submission until every item in the active slot is answered',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            auditDate: '2026-09-08',
            nowProvider: () => DateTime(2026, 9, 8, 13, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mark only the first question at 1 PM. The second question remains
      // unanswered, so the hour must remain incomplete.
      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUBMIT'));
      await tester.pumpAndSettle();

      expect(repository.savedSlug, isNull);
      expect(repository.submittedSlug, isNull);
      expect(find.text('Checklist incomplete'), findsOneWidget);
      expect(
        find.text(
          'Select a condition for every item in the 1:00 PM inspection.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('utilities final scheduled hour closes the daily checklist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeChecklistRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: GacTheme.light,
        home: UserChecklistDetailScreen(
          slug: 'utilities',
          repository: repository,
          auditDate: '2026-09-08',
          nowProvider: () => DateTime(2026, 9, 8, 23, 30),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('YES'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'NEXT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YES'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    expect(repository.savedSlug, isNull);
    expect(repository.submittedSlug, 'utilities');
    expect(repository.submittedResponses, hasLength(2));
    for (final response in repository.submittedResponses) {
      final slots = response['details']['slots'] as Map<String, String>;
      expect(slots['23:00'], 'good');
    }
    expect(find.text('Checklist submitted'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('checklist-message-ok-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Checklist submitted'), findsNothing);
  });

  testWidgets('failed submission stops loading and can be retried', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeChecklistRepository()
      ..submitError = const ChecklistApiException('Server unavailable.');
    await tester.pumpWidget(
      MaterialApp(
        theme: GacTheme.light,
        home: UserChecklistDetailScreen(
          slug: 'sales',
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('YES'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to save checklist'), findsOneWidget);
    expect(find.text('Server unavailable.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('checklist-message-ok-button')),
    );
    await tester.pumpAndSettle();

    repository.submitError = null;
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();
    expect(find.text('Checklist submitted'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repository.submittedResponses.single['status'], 'yes');
  });

  testWidgets(
    'sales and service checklist requires remark on NO or N/A and supports optional photo attachment',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'sales',
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially NO/NA card is not visible
      expect(find.text('REMARKS (REQUIRED) & PHOTO (OPTIONAL)'), findsNothing);

      // Tap NO
      await tester.tap(find.text('NO'));
      await tester.pumpAndSettle();

      // Remarks (Required) & photo button appear
      expect(
        find.text('REMARKS (REQUIRED) & PHOTO (OPTIONAL)'),
        findsOneWidget,
      );
      expect(find.text('ATTACH PHOTO (OPTIONAL)'), findsOneWidget);

      // Attempt submit without remark
      await tester.tap(find.text('SUBMIT'));
      await tester.pumpAndSettle();

      // Validation dialog blocks submission
      expect(find.text('Checklist incomplete'), findsOneWidget);
      expect(
        find.text('Add a remark for each NO or N/A response.'),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Enter required remark
      await tester.enterText(
        find.byType(TextField).first,
        'Missing promotional vehicle tags',
      );
      await tester.pumpAndSettle();

      // Tap N/A to verify label switch
      await tester.tap(find.text('N/A'));
      await tester.pumpAndSettle();
      expect(
        find.text('REASON FOR N/A (REQUIRED) & PHOTO (OPTIONAL)'),
        findsOneWidget,
      );

      // Tap back to NO
      await tester.tap(find.text('NO'));
      await tester.pumpAndSettle();

      // Leaving the checklist auto-saves the current response as a draft.
      expect(find.text('SAVE DRAFT'), findsNothing);
      expect(
        find.byKey(const ValueKey('checklist-header-submit-button')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Back to checklists'));
      await tester.pumpAndSettle();

      expect(repository.savedSlug, 'sales');
      expect(repository.savedResponses, hasLength(1));
      expect(repository.savedResponses.first['status'], 'no');
      expect(
        repository.savedResponses.first['remark'],
        'Missing promotional vehicle tags',
      );
    },
  );

  testWidgets(
    'sales and aftersales 5S checklist NEXT button is disabled until choice is selected, and N/A requires reasoning',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _MultiItemChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'sales',
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SAVE DRAFT'), findsNothing);
      expect(
        find.byKey(const ValueKey('checklist-header-submit-button')),
        findsOneWidget,
      );

      final nextButtonFinder = find.byKey(const ValueKey('dos-next-question'));
      expect(nextButtonFinder, findsOneWidget);

      // 1. Initially no choice chosen: NEXT QUESTION is disabled
      FilledButton nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNull);

      // 2. Tap YES: NEXT QUESTION becomes enabled
      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();

      nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNotNull);

      // 3. Tap N/A: NEXT QUESTION becomes disabled because reasoning is empty
      await tester.tap(find.text('N/A'));
      await tester.pumpAndSettle();

      nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNull);
      expect(
        find.text('REASON FOR N/A (REQUIRED) & PHOTO (OPTIONAL)'),
        findsOneWidget,
      );

      // 4. Type reason for N/A: NEXT QUESTION becomes enabled
      await tester.enterText(
        find.byType(TextField).first,
        'No vehicle display area at this location',
      );
      await tester.pumpAndSettle();

      nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNotNull);

      // 5. Clear reason: NEXT QUESTION becomes disabled again
      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.pumpAndSettle();

      nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNull);

      // 6. Enter valid reason and advance to Question 2
      await tester.enterText(
        find.byType(TextField).first,
        'No vehicle display area at this location',
      );
      await tester.pumpAndSettle();

      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 2 OF 2'), findsOneWidget);
      expect(
        find.text('Are customer lounge seats clean and properly arranged?'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'sales and aftersales 5S checklist NEXT button requires defect remark when NO is selected',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _MultiItemChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'service',
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SAVE DRAFT'), findsNothing);
      expect(
        find.byKey(const ValueKey('checklist-header-submit-button')),
        findsOneWidget,
      );

      final nextButtonFinder = find.byKey(const ValueKey('dos-next-question'));
      expect(nextButtonFinder, findsOneWidget);

      // Tap NO: NEXT QUESTION is disabled because remarks are empty
      await tester.tap(find.text('NO'));
      await tester.pumpAndSettle();

      expect(
        find.text('REMARKS (REQUIRED) & PHOTO (OPTIONAL)'),
        findsOneWidget,
      );
      FilledButton nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNull);

      // Type defect remark: NEXT QUESTION becomes enabled
      await tester.enterText(
        find.byType(TextField).first,
        'Service bay floor has oil stain',
      );
      await tester.pumpAndSettle();

      nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'utilities checklist supports N/A condition and disables NEXT button until reasoning is typed',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            auditDate: '2026-09-08',
            nowProvider: () => DateTime(2026, 9, 8, 8, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nextButtonFinder = find.widgetWithText(FilledButton, 'NEXT');
      expect(nextButtonFinder, findsOneWidget);

      // Unlock 8:00 AM slot
      await tester.tap(find.text('8:00 AM'));
      await tester.pumpAndSettle();

      // N/A button is present alongside GOOD and NOT GOOD
      expect(find.text('N/A'), findsOneWidget);

      // Tap N/A: NEXT button is disabled because reasoning is blank
      await tester.tap(find.text('N/A'));
      await tester.pumpAndSettle();

      expect(find.text('MARKED N/A'), findsOneWidget);
      expect(
        find.text('REASON FOR N/A (REQUIRED) & PHOTO (OPTIONAL)'),
        findsOneWidget,
      );

      FilledButton nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNull);

      // Enter N/A reason: NEXT button becomes enabled
      await tester.enterText(
        find.byType(TextField).first,
        'Facility under renovation, mirrors temporarily removed',
      );
      await tester.pumpAndSettle();

      nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNotNull);

      // Advance to Question 2
      await tester.ensureVisible(nextButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 2 / 2'), findsOneWidget);
      expect(
        find.text('Is the sink clean and working properly?'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'utilities checklist disables NEXT button when NOT GOOD is selected until remark is typed',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            auditDate: '2026-09-08',
            nowProvider: () => DateTime(2026, 9, 8, 8, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nextButtonFinder = find.widgetWithText(FilledButton, 'NEXT');
      expect(nextButtonFinder, findsOneWidget);

      await tester.tap(find.text('8:00 AM'));
      await tester.pumpAndSettle();

      // Tap NOT GOOD: NEXT is disabled until defect remark is provided
      await tester.tap(find.text('NO'));
      await tester.pumpAndSettle();

      FilledButton nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNull);

      // Enter remark: NEXT is enabled
      await tester.enterText(
        find.byType(TextField).first,
        'Cracked sink faucet leaking water',
      );
      await tester.pumpAndSettle();

      nextButton = tester.widget<FilledButton>(nextButtonFinder);
      expect(nextButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'partially completed checklist resumes at the first unanswered question',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _MultiItemChecklistRepository();
      repository.initialSubmission = ChecklistSubmissionData(
        id: 1,
        status: 'draft',
        auditDate: '2026-08-29',
        templateVersion: 4,
        scores: const {'total': 2, 'answered': 1},
        responses: const {
          'item-1': ChecklistResponseData(
            itemId: 1,
            itemKey: 'item-1',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
        },
        answeredItems: 1,
        totalItems: 2,
        completionPercentage: 50,
        submittedAt: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'service',
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen automatically resumes on Question 2 (first unanswered question)
      expect(find.text('QUESTION 2 OF 2'), findsOneWidget);
      expect(
        find.text('Are customer lounge seats clean and properly arranged?'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tapping CONTINUE on user checklists screen opens the checklist at the left-off question',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _MultiItemChecklistRepository();
      repository.initialSubmission = ChecklistSubmissionData(
        id: 1,
        status: 'draft',
        auditDate: '2026-08-29',
        templateVersion: 4,
        scores: const {'total': 2, 'answered': 1},
        responses: const {
          'item-1': ChecklistResponseData(
            itemId: 1,
            itemKey: 'item-1',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
        },
        answeredItems: 1,
        totalItems: 2,
        completionPercentage: 50,
        submittedAt: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistsScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Look for the CONTINUE CHECKLIST button
      final continueBtn = find.text('CONTINUE CHECKLIST');
      expect(continueBtn, findsWidgets);

      await tester.tap(continueBtn.first);
      await tester.pumpAndSettle();

      // Opens directly at Question 2 (left off)
      expect(find.text('QUESTION 2 OF 2'), findsOneWidget);
      expect(
        find.text('Are customer lounge seats clean and properly arranged?'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'utilities checklist resumes on the first unanswered question for active slot',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      repository.initialSubmission = ChecklistSubmissionData(
        id: 1,
        status: 'draft',
        auditDate: '2026-08-29',
        templateVersion: 1,
        scores: const {'total': 2, 'answered': 1},
        responses: const {
          'mirror-clean': ChecklistResponseData(
            itemId: 101,
            itemKey: 'mirror-clean',
            status: 'good',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {
              'slots': {'08:00': 'good'},
            },
          ),
        },
        answeredItems: 1,
        totalItems: 2,
        completionPercentage: 50,
        submittedAt: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            initialSlotKey: '08:00',
            repository: repository,
            auditDate: '2026-08-29',
            nowProvider: () => DateTime(2026, 8, 29, 8, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mirror-clean is already answered in slot 08:00, so it resumes at Question 2
      expect(find.text('QUESTION 2 / 2'), findsOneWidget);
      expect(
        find.text('Is the sink clean and working properly?'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'completed checklist in submitted mode opens at the last question',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _MultiItemChecklistRepository();
      repository.initialSubmission = ChecklistSubmissionData(
        id: 1,
        status: 'submitted',
        auditDate: '2026-08-29',
        templateVersion: 4,
        scores: const {'total': 2, 'answered': 2},
        responses: const {
          'item-1': ChecklistResponseData(
            itemId: 1,
            itemKey: 'item-1',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
          'item-2': ChecklistResponseData(
            itemId: 2,
            itemKey: 'item-2',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
        },
        answeredItems: 2,
        totalItems: 2,
        completionPercentage: 100,
        submittedAt: DateTime(2026, 8, 29),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'service',
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Read-only view starts at the last question
      expect(find.text('QUESTION 2 OF 2'), findsOneWidget);
    },
  );

  testWidgets(
    'completed checklist opens at last question for Admin user as well',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _MultiItemChecklistRepository();
      repository.initialSubmission = ChecklistSubmissionData(
        id: 1,
        status: 'submitted',
        auditDate: '2026-08-29',
        templateVersion: 4,
        scores: const {'total': 2, 'answered': 2},
        responses: const {
          'item-1': ChecklistResponseData(
            itemId: 1,
            itemKey: 'item-1',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
          'item-2': ChecklistResponseData(
            itemId: 2,
            itemKey: 'item-2',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
        },
        answeredItems: 2,
        totalItems: 2,
        completionPercentage: 100,
        submittedAt: DateTime(2026, 8, 29),
      );

      const adminUser = AuthenticatedUser(
        id: 99,
        name: 'Admin User',
        email: 'admin@gateway.com',
        userType: 'ADMIN',
        accountStatus: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'service',
            repository: repository,
            user: adminUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 2 OF 2'), findsOneWidget);
    },
  );

  testWidgets(
    'completed checklist opens at last question for Checker user as well',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _MultiItemChecklistRepository();
      repository.initialSubmission = ChecklistSubmissionData(
        id: 1,
        status: 'submitted',
        auditDate: '2026-08-29',
        templateVersion: 4,
        scores: const {'total': 2, 'answered': 2},
        responses: const {
          'item-1': ChecklistResponseData(
            itemId: 1,
            itemKey: 'item-1',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
          'item-2': ChecklistResponseData(
            itemId: 2,
            itemKey: 'item-2',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
        },
        answeredItems: 2,
        totalItems: 2,
        completionPercentage: 100,
        submittedAt: DateTime(2026, 8, 29),
      );

      const checkerUser = AuthenticatedUser(
        id: 10,
        name: 'WS Supervisor',
        email: 'ws.sup@gateway.com',
        userType: 'WS SUP',
        accountStatus: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'service',
            repository: repository,
            user: checkerUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 2 OF 2'), findsOneWidget);
    },
  );

  testWidgets(
    'completed checklist opens at last question even when initialSectionIndex is passed',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _MultiItemChecklistRepository();
      repository.initialSubmission = ChecklistSubmissionData(
        id: 1,
        status: 'submitted',
        auditDate: '2026-08-29',
        templateVersion: 4,
        scores: const {'total': 2, 'answered': 2},
        responses: const {
          'item-1': ChecklistResponseData(
            itemId: 1,
            itemKey: 'item-1',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
          'item-2': ChecklistResponseData(
            itemId: 2,
            itemKey: 'item-2',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
        },
        answeredItems: 2,
        totalItems: 2,
        completionPercentage: 100,
        submittedAt: DateTime(2026, 8, 29),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'service',
            repository: repository,
            initialSectionIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 2 OF 2'), findsOneWidget);
    },
  );

  testWidgets(
    'checklist with all questions answered opens at last question',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _MultiItemChecklistRepository();
      repository.initialSubmission = ChecklistSubmissionData(
        id: 1,
        status: 'draft',
        auditDate: '2026-08-29',
        templateVersion: 4,
        scores: const {'total': 2, 'answered': 2},
        responses: const {
          'item-1': ChecklistResponseData(
            itemId: 1,
            itemKey: 'item-1',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
          'item-2': ChecklistResponseData(
            itemId: 2,
            itemKey: 'item-2',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
        },
        answeredItems: 2,
        totalItems: 2,
        completionPercentage: 100,
        submittedAt: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'service',
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 2 OF 2'), findsOneWidget);
    },
  );

  testWidgets(
    'utilities checklist NEXT button turns into SUBMIT CHECKLIST on final question and submits',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeChecklistRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'utilities',
            repository: repository,
            nowProvider: () => DateTime(2026, 8, 29, 8, 15),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Question 1: Next button is NEXT
      expect(find.text('QUESTION #1'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);

      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Question 2 (final question): Next button turns into SUBMIT CHECKLIST
      expect(find.text('QUESTION #2'), findsOneWidget);
      expect(find.text('SUBMIT CHECKLIST'), findsOneWidget);

      await tester.tap(find.text('YES'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUBMIT CHECKLIST'));
      await tester.pumpAndSettle();

      expect(repository.submittedSlug, 'utilities');
      expect(repository.submittedResponses, isNotEmpty);
    },
  );

  testWidgets(
    'view toggle between step-by-step and list view is available for both editable and read-only / submitted checklists',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _MultiItemChecklistRepository();
      // Case 1: Active editable checklist
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            key: const ValueKey('active-checklist'),
            slug: 'service',
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step-by-step view is active by default
      expect(find.byTooltip('Switch to list view'), findsOneWidget);
      expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);

      // Tap to switch to list view
      await tester.tap(find.byTooltip('Switch to list view'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Switch to step-by-step'), findsOneWidget);
      expect(find.byIcon(Icons.view_carousel_rounded), findsOneWidget);

      // Case 2: Read-only / submitted checklist
      final submittedRepo = _MultiItemChecklistRepository();
      submittedRepo.initialSubmission = ChecklistSubmissionData(
        id: 99,
        status: 'submitted',
        auditDate: '2026-08-29',
        templateVersion: 4,
        scores: const {},
        responses: {
          'item-1': ChecklistResponseData(
            itemId: 1,
            itemKey: 'item-1',
            status: 'yes',
            remark: '',
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {'choice': 'yes'},
          ),
        },
        answeredItems: 1,
        totalItems: 2,
        completionPercentage: 50,
        submittedAt: DateTime(2026, 8, 29, 10, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            key: const ValueKey('submitted-checklist'),
            slug: 'service',
            repository: submittedRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Read-only user MUST have access to toggle view
      expect(find.byTooltip('Switch to list view'), findsOneWidget);
      expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);

      // Can switch to list view even when read-only
      await tester.tap(find.byTooltip('Switch to list view'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Switch to step-by-step'), findsOneWidget);
      expect(find.byIcon(Icons.view_carousel_rounded), findsOneWidget);
    },
  );
}

class _MultiItemChecklistRepository extends _FakeChecklistRepository {
  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async {
    return [
      ChecklistCatalogItem(
        id: 2,
        slug: 'service',
        name: 'Service Checklist',
        description: 'Database-backed checklist.',
        version: 4,
        settings: const {'validation_mode': 'yes_no_na'},
        sectionCount: 1,
        itemCount: 2,
        submission: initialSubmission,
      ),
    ];
  }

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    return ChecklistLoadResult(
      template: ChecklistTemplateData(
        id: slug == 'service' ? 2 : 1,
        slug: slug,
        name: slug == 'service' ? 'Service Checklist' : 'Sales Checklist',
        description: 'Database-backed checklist.',
        version: 4,
        settings: const {
          'validation_mode': 'yes_no_na',
          'instructions': 'Answer every item.',
        },
        sections: const [
          ChecklistSectionData(
            id: 1,
            key: 'general-area',
            title: 'General Area',
            sortOrder: 0,
            metadata: {},
            items: [
              ChecklistItemData(
                id: 1,
                key: 'item-1',
                prompt: 'Is the parking area clean and clearly marked?',
                sortOrder: 0,
                metadata: {'number': 1},
              ),
              ChecklistItemData(
                id: 2,
                key: 'item-2',
                prompt:
                    'Are customer lounge seats clean and properly arranged?',
                sortOrder: 1,
                metadata: {'number': 2},
              ),
            ],
          ),
        ],
      ),
      submission: initialSubmission,
    );
  }
}

class _EmptyHourlyChecklistRepository extends _FakeChecklistRepository {
  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    final template = _template(slug);
    return ChecklistLoadResult(
      template: ChecklistTemplateData(
        id: template.id,
        slug: template.slug,
        name: template.name,
        description: template.description,
        version: template.version,
        settings: const {
          'validation_mode': 'time_slots',
          'time_slots': <Map<String, String>>[],
        },
        sections: template.sections,
      ),
      submission: initialSubmission,
    );
  }
}

class _FakeChecklistRepository implements ChecklistRepository {
  String? savedSlug;
  Map<String, dynamic>? savedContext;
  List<Map<String, dynamic>> savedResponses = const [];
  String? submittedSlug;
  List<Map<String, dynamic>> submittedResponses = const [];
  String? uploadedSlug;
  List<int>? uploadedBytes;
  String? uploadedFilename;
  ChecklistSubmissionData? initialSubmission;
  ChecklistApiException? submitError;

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async {
    return [
      _catalog('sales', 'Sales Checklist', 4),
      _catalog('service', 'Service Checklist', 2),
      _catalog('utilities', 'Utilities Checklist', 1),
    ];
  }

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    return ChecklistLoadResult(
      template: _template(slug),
      submission: initialSubmission,
    );
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
  }) async {
    savedSlug = slug;
    savedContext = context;
    savedResponses = responses;
    return _submission(status: 'draft');
  }

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    submittedSlug = slug;
    submittedResponses = responses;
    if (submitError case final error?) throw error;
    return _submission(status: 'submitted');
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) async {
    uploadedSlug = slug;
    uploadedBytes = bytes;
    uploadedFilename = filename;
    return {
      'path': 'checklist-attachments/$slug/mock-$filename',
      'url':
          'http://localhost/storage/checklist-attachments/$slug/mock-$filename',
    };
  }
}

ChecklistCatalogItem _catalog(String slug, String name, int version) {
  final isUtilities = slug == 'utilities' || slug == 'restroom';
  return ChecklistCatalogItem(
    id: version,
    slug: slug,
    name: name,
    description: 'Database-backed checklist.',
    version: version,
    settings: {'validation_mode': isUtilities ? 'time_slots' : 'yes_no_na'},
    sectionCount: 1,
    itemCount: isUtilities ? 2 : 1,
    submission: null,
  );
}

ChecklistTemplateData _template(String slug) {
  if (slug == 'utilities' || slug == 'restroom') {
    return const ChecklistTemplateData(
      id: 3,
      slug: 'utilities',
      name: 'Utilities Checklist',
      description: 'Hourly utilities and restroom inspection checklist.',
      version: 1,
      settings: {
        'validation_mode': 'time_slots',
        'instructions': 'Inspect each time slot.',
        'time_slots': [
          {'key': '08:00', 'label': '8:00 AM'},
          {'key': '09:00', 'label': '9:00 AM'},
          {'key': '10:00', 'label': '10:00 AM'},
          {'key': '13:00', 'label': '1:00 PM'},
          {'key': '16:00', 'label': '4:00 PM'},
          {'key': '23:00', 'label': '11:00 PM'},
        ],
      },
      sections: [
        ChecklistSectionData(
          id: 10,
          key: 'restroom-items',
          title: 'Restroom and Utilities',
          sortOrder: 0,
          metadata: {},
          items: [
            ChecklistItemData(
              id: 101,
              key: 'mirror-clean',
              prompt: 'Are mirrors clean and spotless?',
              sortOrder: 0,
              metadata: {'number': 1},
            ),
            ChecklistItemData(
              id: 102,
              key: 'sink-clean',
              prompt: 'Is the sink clean and working properly?',
              sortOrder: 1,
              metadata: {
                'number': 2,
                'how_to_check':
                    'Check sink for clogs, water flow, and soap residue.',
              },
            ),
          ],
        ),
      ],
    );
  }

  return ChecklistTemplateData(
    id: 1,
    slug: slug,
    name: slug == 'service' ? 'Service Checklist' : 'Sales Checklist',
    description: 'Database-backed checklist.',
    version: 4,
    settings: const {
      'validation_mode': 'yes_no_na',
      'instructions': 'Answer every item.',
    },
    sections: const [
      ChecklistSectionData(
        id: 1,
        key: 'parking-area',
        title: 'Parking Area',
        sortOrder: 0,
        metadata: {},
        items: [
          ChecklistItemData(
            id: 1,
            key: 'item-1',
            prompt: 'Is the parking area clean and clearly marked?',
            sortOrder: 0,
            metadata: {'number': 1},
          ),
        ],
      ),
    ],
  );
}

ChecklistSubmissionData _submission({required String status}) {
  return ChecklistSubmissionData(
    id: 9,
    status: status,
    auditDate: '2026-08-29',
    templateVersion: 4,
    scores: const {'total': 1, 'answered': 1},
    responses: const {},
    answeredItems: 1,
    totalItems: 1,
    completionPercentage: 100,
    submittedAt: status == 'submitted' ? DateTime(2026, 8, 29) : null,
  );
}
