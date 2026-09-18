import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_checklist_detail_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('leaving an untouched checklist does not save a draft', (
    tester,
  ) async {
    final repository = _UndoTestRepository(_standardTemplate('sales'));
    var wentBack = false;
    await _open(
      tester,
      repository,
      _user('PIC'),
      onBack: () => wentBack = true,
    );

    await tester.tap(find.byTooltip('Back to checklists'));
    await tester.pumpAndSettle();

    expect(wentBack, isTrue);
    expect(repository.saveCount, 0);
    expect(find.text('Checklist saved'), findsNothing);
  });

  for (final choice in ['yes', 'no', 'na']) {
    testWidgets('undoing the only new $choice answer exits without a draft', (
      tester,
    ) async {
      final repository = _UndoTestRepository(_standardTemplate('sales'));
      var wentBack = false;
      await _open(
        tester,
        repository,
        _user('PIC'),
        onBack: () => wentBack = true,
      );
      final button = find.byKey(ValueKey('item-0-response-$choice'));
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-undo-choice')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back to checklists'));
      await tester.pumpAndSettle();

      expect(wentBack, isTrue);
      expect(repository.saveCount, 0);
      expect(repository.responses, isEmpty);
      expect(find.text('Checklist saved'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final keepAnotherAnswer in [false, true]) {
    testWidgets(
      'undo clears a saved answer ${keepAnotherAnswer ? 'and preserves another answer' : 'and resets progress to zero'}',
      (tester) async {
        final repository = _UndoTestRepository(_standardTemplate('sales'));
        repository.responses['item-0'] = ChecklistResponseData.fromJson({
          'item_key': 'item-0',
          'status': 'yes',
        });
        if (keepAnotherAnswer) {
          repository.responses['item-1'] = ChecklistResponseData.fromJson({
            'item_key': 'item-1',
            'status': 'yes',
          });
        }
        var wentBack = false;
        await _open(
          tester,
          repository,
          _user('PIC'),
          onBack: () => wentBack = true,
        );
        if (keepAnotherAnswer) {
          await tester.tap(find.byKey(const ValueKey('dos-previous-question')));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey('item-0-response-yes')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirm-undo-choice')));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Back to checklists'));
        await tester.pumpAndSettle();

        expect(wentBack, isTrue);
        expect(repository.saveCount, 1);
        expect(repository.responses['item-0']?.status, isNull);
        final reloaded = await repository.fetchChecklist('sales');
        expect(reloaded.submission!.hasStarted, keepAnotherAnswer);
        expect(reloaded.submission!.answeredItems, keepAnotherAnswer ? 1 : 0);
        expect(
          reloaded.submission!.completionPercentage,
          keepAnotherAnswer ? 50 : 0,
        );
        if (keepAnotherAnswer) {
          expect(repository.responses['item-1']?.status, 'yes');
          expect(find.text('Checklist saved'), findsOneWidget);
        } else {
          expect(repository.savedContext, isNull);
          expect(find.text('Checklist saved'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final saved in [false, true]) {
    testWidgets(
      'undoing the only ${saved ? 'saved' : 'new'} hourly mark leaves no draft progress',
      (tester) async {
        final repository = _UndoTestRepository(_hourlyTemplate('restroom'));
        if (saved) {
          repository.responses['util-0'] = ChecklistResponseData.fromJson({
            'item_key': 'util-0',
            'status': 'yes',
            'details': {
              'slots': {'08:00': 'good'},
            },
          });
        }
        await _open(tester, repository, _user('PIC'), slug: 'restroom');
        if (!saved) {
          await tester.tap(find.text('YES').first);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('YES').first);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirm-undo-choice')));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Back to checklists'));
        await tester.pumpAndSettle();

        expect(repository.saveCount, saved ? 1 : 0);
        expect(repository.responses['util-0']?.status, isNull);
        expect(repository.responses['util-0']?.details['slots'], isNull);
        expect(
          (await repository.fetchChecklist('restroom')).submission!.hasStarted,
          isFalse,
        );
        expect(find.text('Checklist saved'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  group('Checklist undo / uncheck choice tests for all users', () {
    testWidgets(
      'PIC user: clicking chosen choice prompts for confirmation, CANCEL keeps choice, UNDO unchecks it',
      (tester) async {
        final user = _user('PIC');
        final repository = _UndoTestRepository(_standardTemplate('sales'));
        await _open(tester, repository, user);

        // 1. Initial state: neither is chosen
        final yesButton = find.byKey(const ValueKey('item-0-response-yes'));
        final noButton = find.byKey(const ValueKey('item-0-response-no'));
        final nextButton = find.byKey(const ValueKey('dos-next-question'));

        expect(yesButton, findsOneWidget);
        expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);

        // 2. Select YES
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        // NEXT button is now enabled
        expect(tester.widget<FilledButton>(nextButton).onPressed, isNotNull);

        // 3. Click YES again (the already chosen choice)
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        // Verify confirmation prompt is displayed
        expect(find.text('Undo Choice'), findsOneWidget);
        expect(
          find.text('Are you sure you want to undo your choice?'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('cancel-undo-choice')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('confirm-undo-choice')),
          findsOneWidget,
        );

        // 4. Tap CANCEL
        await tester.tap(find.byKey(const ValueKey('cancel-undo-choice')));
        await tester.pumpAndSettle();

        // Prompt dismissed, YES remains selected
        expect(find.text('Undo Choice'), findsNothing);
        expect(tester.widget<FilledButton>(nextButton).onPressed, isNotNull);

        // 5. Click YES again and confirm UNDO
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('confirm-undo-choice')));
        await tester.pumpAndSettle();

        // Prompt dismissed, YES is unchecked (choice is undone)
        expect(find.text('Undo Choice'), findsNothing);
        // NEXT button is disabled again because question is unanswered
        expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);

        // 6. Select NO
        await tester.tap(noButton);
        await tester.pumpAndSettle();

        // Click NO again
        await tester.tap(noButton);
        await tester.pumpAndSettle();

        expect(find.text('Undo Choice'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('confirm-undo-choice')));
        await tester.pumpAndSettle();

        expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);
      },
    );

    testWidgets(
      'DOS Inspector user: clicking chosen choice prompts for confirmation and UNDO unchecks it',
      (tester) async {
        final user = _user('SM');
        final repository = _UndoTestRepository(_dosTemplate(user));
        await _open(tester, repository, user);

        final yesButton = find.byKey(const ValueKey('dos-0-response-yes'));
        expect(yesButton, findsOneWidget);

        // Select YES
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        // Click YES again
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        expect(find.text('Undo Choice'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('confirm-undo-choice')));
        await tester.pumpAndSettle();

        expect(find.text('Undo Choice'), findsNothing);
      },
    );

    testWidgets(
      'Admin user: clicking chosen choice prompts for confirmation and UNDO unchecks it',
      (tester) async {
        final user = _user('ADMIN');
        final repository = _UndoTestRepository(_standardTemplate('daily'));
        await _open(tester, repository, user);

        final naButton = find.byKey(const ValueKey('item-0-response-na'));
        expect(naButton, findsOneWidget);

        // Select N/A
        await tester.tap(naButton);
        await tester.pumpAndSettle();

        // Click N/A again
        await tester.tap(naButton);
        await tester.pumpAndSettle();

        expect(find.text('Undo Choice'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('confirm-undo-choice')));
        await tester.pumpAndSettle();

        expect(find.text('Undo Choice'), findsNothing);
      },
    );

    testWidgets(
      'Hourly / Time slots checklist: clicking chosen slot mark prompts for confirmation and UNDO unchecks it',
      (tester) async {
        final user = _user('PIC');
        final template = _hourlyTemplate('utilities');
        final repository = _UndoTestRepository(template);

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'utilities',
              repository: repository,
              user: user,
              initialSlotKey: '08:00',
              nowProvider: () => DateTime(2026, 9, 8, 8, 15),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The question view for utilities shows condition buttons (YES, NO, N/A)
        final yesButton = find.text('YES').first;
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        // Tapping YES again on the active hour slot prompts undo confirmation
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        expect(find.text('Undo Choice'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('confirm-undo-choice')));
        await tester.pumpAndSettle();

        expect(find.text('Undo Choice'), findsNothing);
      },
    );
  });
}

AuthenticatedUser _user(String role) => AuthenticatedUser(
  id: 1,
  name: 'Test user',
  email: 'test@gateway.com',
  userType: role,
  accountStatus: 'active',
);

Future<void> _open(
  WidgetTester tester,
  ChecklistRepository repository,
  AuthenticatedUser user, {
  VoidCallback? onBack,
  String slug = 'sales',
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: GacTheme.light,
      home: UserChecklistDetailScreen(
        slug: slug,
        repository: repository,
        user: user,
        auditDate: '2026-09-08',
        initialQuestionIndex: 0,
        nowProvider: () => DateTime(2026, 9, 8, 8, 15),
        onBack: onBack,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ChecklistTemplateData _standardTemplate(String slug) {
  return ChecklistTemplateData(
    id: 1,
    slug: slug,
    name: 'Standard Checklist',
    description: 'Test fixture',
    version: 1,
    settings: {'validation_mode': 'yes_no_na'},
    sections: [
      ChecklistSectionData(
        id: 1,
        key: 'sec-1',
        title: 'Section 1',
        sortOrder: 0,
        metadata: const {},
        items: [
          ChecklistItemData(
            id: 1,
            key: 'item-0',
            prompt: 'Is this item clean and organized?',
            sortOrder: 0,
            metadata: const {'number': 1},
          ),
          ChecklistItemData(
            id: 2,
            key: 'item-1',
            prompt: 'Is this second item checked?',
            sortOrder: 1,
            metadata: const {'number': 2},
          ),
        ],
      ),
    ],
  );
}

ChecklistTemplateData _dosTemplate(AuthenticatedUser user) {
  return ChecklistTemplateData(
    id: 2,
    slug: 'dealer-operations-standards',
    name: 'DOS Checklist',
    description: 'DOS fixture',
    version: 1,
    settings: {'validation_mode': 'dos'},
    sections: [
      ChecklistSectionData(
        id: 1,
        key: 'sec-dos',
        title: 'DOS Section',
        sortOrder: 0,
        metadata: const {},
        items: [
          ChecklistItemData(
            id: 10,
            key: 'dos-0',
            prompt: 'Is standard #1 met?',
            sortOrder: 0,
            metadata: {
              'number': 1,
              'category': 'Basic',
              'checker': user.dosCheckerCode,
            },
          ),
        ],
      ),
    ],
  );
}

ChecklistTemplateData _hourlyTemplate(String slug) {
  return ChecklistTemplateData(
    id: 3,
    slug: slug,
    name: 'Utilities Checklist',
    description: 'Hourly fixture',
    version: 1,
    settings: {
      'validation_mode': 'time_slots',
      'time_slots': [
        {'key': '08:00', 'label': '8:00 AM', 'window_minutes': 60},
        {'key': '09:00', 'label': '9:00 AM', 'window_minutes': 60},
      ],
    },
    sections: [
      ChecklistSectionData(
        id: 1,
        key: 'sec-util',
        title: 'Utilities Section',
        sortOrder: 0,
        metadata: const {},
        items: [
          ChecklistItemData(
            id: 20,
            key: 'util-0',
            prompt: 'Check electrical panels',
            sortOrder: 0,
            metadata: const {'number': 1},
          ),
        ],
      ),
    ],
  );
}

class _UndoTestRepository implements ChecklistRepository {
  _UndoTestRepository(this.template);

  final ChecklistTemplateData template;
  final Map<String, ChecklistResponseData> responses = {};
  int saveCount = 0;
  Map<String, dynamic>? savedContext;

  int get answeredItems => responses.values.where((response) {
    final slots = response.details['slots'];
    return response.status != null || (slots is Map && slots.isNotEmpty);
  }).length;

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    return ChecklistLoadResult(
      template: template,
      submission: ChecklistSubmissionData(
        id: 1,
        status: 'draft',
        auditDate: '2026-09-08',
        templateVersion: 1,
        scores: const {},
        submittedAt: null,
        responses: Map.of(responses),
        answeredItems: answeredItems,
        totalItems: template.itemCount,
        completionPercentage: answeredItems / template.itemCount * 100,
      ),
    );
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
  }) async {
    saveCount++;
    savedContext = context;
    for (final r in responses) {
      this.responses[r['item_key'] as String] = ChecklistResponseData.fromJson(
        r,
      );
    }
    return ChecklistSubmissionData(
      id: 1,
      status: 'draft',
      auditDate: date,
      templateVersion: 1,
      scores: const {},
      submittedAt: null,
      responses: Map.of(this.responses),
      answeredItems: answeredItems,
      totalItems: template.itemCount,
      completionPercentage: answeredItems / template.itemCount * 100,
    );
  }

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    return saveDraft(slug, date: date, responses: responses);
  }

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async => [];

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) async => {'path': 'dummy/path', 'url': 'http://dummy.url'};
}
