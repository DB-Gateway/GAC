import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_checklist_detail_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

class _FakeDosAftersalesRepository implements ChecklistRepository {
  ChecklistLoadResult? loadResult;
  List<Map<String, dynamic>> savedResponses = [];

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async => [];

  @override
  Future<ChecklistLoadResult> fetchChecklist(String slug, {String? date}) async {
    if (loadResult != null) return loadResult!;

    final section = ChecklistSectionData(
      id: 1,
      key: 'personalized-reception',
      title: 'Personalized Customer Reception',
      sortOrder: 1,
      metadata: const {},
      items: [
        ChecklistItemData(
          id: 23,
          key: 'dos-item-23',
          prompt: 'See sheet: "Subform"',
          sortOrder: 23,
          metadata: const {
            'number': 23,
            'level': 'Basic',
            'coverage': 'Personalized Customer Reception',
            'subject': 'Service Reception Area',
            'checker': 'ASM',
            'pic': 'BOM',
            'how_to_check':
                'All check items in the subform must be "YES" to count compliant.',
          },
        ),
      ],
    );

    return ChecklistLoadResult(
      template: ChecklistTemplateData(
        id: 2,
        slug: 'dealer-operations-standards',
        name: 'Dealer Operations Standards - Aftersales',
        description: 'FY2025 Aftersales Audit',
        version: 1,
        settings: const {
          'validation_mode': 'dos',
          'response_options': ['yes', 'no', 'na'],
        },
        sections: [section],
      ),
      submission: null,
    );
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
  }) async {
    savedResponses = responses;
    return ChecklistSubmissionData(
      id: 100,
      status: 'draft',
      auditDate: date,
      templateVersion: 1,
      scores: const {},
      responses: const {},
      answeredItems: responses.length,
      totalItems: responses.length,
      completionPercentage: 100,
      submittedAt: null,
      issueCount: 0,
    );
  }

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    savedResponses = responses;
    return ChecklistSubmissionData(
      id: 101,
      status: 'submitted',
      auditDate: date,
      templateVersion: 1,
      scores: const {},
      responses: const {},
      answeredItems: responses.length,
      totalItems: responses.length,
      completionPercentage: 100,
      submittedAt: DateTime.now(),
      issueCount: 0,
    );
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) async {
    return {'path': 'photos/$filename', 'url': 'https://example.com/$filename'};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DOS Aftersales Subform Eligibility & Question Dropbox Feature', () {
    const adminUser = AuthenticatedUser(
      id: 1,
      name: 'Admin Auditor',
      email: 'admin@gac.com',
      userType: 'ADMIN',
      accountStatus: 'active',
    );

    testWidgets('Displays eligibility prompt first for subform question', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeDosAftersalesRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards',
            repository: repo,
            user: adminUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ELIGIBILITY AUDIT'), findsOneWidget);
      expect(find.byKey(const ValueKey('subform-eligibility-show-subform')), findsOneWidget);
      expect(find.byKey(const ValueKey('subform-eligibility-na')), findsOneWidget);

      expect(find.byKey(const ValueKey('subform-dropdown-container')), findsNothing);
    });

    testWidgets('Tapping N/A sets item to N/A and reveals Reason for N/A field', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeDosAftersalesRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards',
            repository: repo,
            user: adminUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('subform-eligibility-na')));
      await tester.pumpAndSettle();

      expect(find.text('TAGGED N/A'), findsOneWidget);
      expect(find.byKey(const ValueKey('dos-finding-field')), findsOneWidget);
      expect(find.text('Reason for N/A (required)'), findsOneWidget);

      expect(find.byKey(const ValueKey('subform-dropdown-container')), findsNothing);
    });

    testWidgets('Tapping Show Subform reveals question dropdown and subform questions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeDosAftersalesRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards',
            repository: repo,
            user: adminUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('subform-eligibility-show-subform')));
      await tester.pumpAndSettle();

      expect(find.text('SUBFORM ACTIVE'), findsOneWidget);
      expect(find.byKey(const ValueKey('subform-dropdown-container')), findsOneWidget);

      final dropdownContainer = tester.widget<Container>(
        find.byKey(const ValueKey('subform-dropdown-container')),
      );
      expect(
        (dropdownContainer.decoration! as BoxDecoration).color,
        GacColors.offWhite,
      );

      final dropdown = tester.widget<DropdownButton<int>>(
        find.byKey(const ValueKey('dos-item-23-subform-dropbox')),
      );
      expect(dropdown.dropdownColor, GacColors.offWhite);

      final activeQuestionCard = tester.widget<Container>(
        find.byKey(const ValueKey('subform-active-question-card')),
      );
      expect(
        (activeQuestionCard.decoration! as BoxDecoration).color,
        GacColors.offWhite,
      );

      final activeQuestionPill = tester.widget<Container>(
        find.byKey(const ValueKey('subform-pill-surface-0')),
      );
      expect(
        (activeQuestionPill.decoration! as BoxDecoration).color,
        GacColors.primary,
      );
      for (var i = 1; i < 9; i++) {
        final inactiveQuestionPill = tester.widget<Container>(
          find.byKey(ValueKey('subform-pill-surface-$i')),
        );
        expect(
          (inactiveQuestionPill.decoration! as BoxDecoration).color,
          GacColors.offWhite,
        );
      }

      expect(find.text('QUESTION 1 OF 9'), findsOneWidget);
      expect(
        find.text(
          'Service Reception signage follows the standard design, and must be clearly displayed at the entrance',
        ),
        findsOneWidget,
      );

      expect(find.byKey(const ValueKey('subform-sr-1-yes')), findsOneWidget);
      expect(find.byKey(const ValueKey('subform-sr-1-no')), findsOneWidget);
      expect(find.byKey(const ValueKey('subform-sr-1-na')), findsOneWidget);
    });

    testWidgets('Answering subform questions updates compliance and derives overall status', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeDosAftersalesRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards',
            repository: repo,
            user: adminUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('subform-eligibility-show-subform')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('subform-sr-1-no')));
      await tester.pumpAndSettle();

      expect(find.textContaining('NON-COMPLIANT: Failure recorded (Overall: NO)'), findsOneWidget);
      expect(find.byKey(const ValueKey('dos-finding-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('dos-action-plan-field')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('subform-sr-1-yes')));
      await tester.pumpAndSettle();

      expect(find.textContaining('IN PROGRESS: 1 of 9 requirements answered'), findsOneWidget);
    });

    testWidgets('Next and previous buttons navigate subform questions', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeDosAftersalesRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards',
            repository: repo,
            user: adminUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('subform-eligibility-show-subform')));
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 1 OF 9'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('subform-next-btn')));
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 2 OF 9'), findsOneWidget);
      expect(
        find.text('Business hours clearly displayed at the entrance door'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('subform-prev-btn')));
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 1 OF 9'), findsOneWidget);
    });

    testWidgets('Tapping view mode toggle switches between dropdown view and list view', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeDosAftersalesRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards',
            repository: repo,
            user: adminUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('subform-eligibility-show-subform')));
      await tester.pumpAndSettle();

      // Initially in dropdown view
      expect(find.byKey(const ValueKey('subform-dropdown-container')), findsOneWidget);

      // Toggle to all questions view
      await tester.tap(find.byKey(const ValueKey('subform-toggle-view-mode')));
      await tester.pumpAndSettle();

      // Dropdown container is hidden in list view
      expect(find.byKey(const ValueKey('subform-dropdown-container')), findsNothing);
      // List items are present
      expect(find.byKey(const ValueKey('subform-sr-1-list-yes')), findsOneWidget);
      expect(find.byKey(const ValueKey('subform-sr-2-list-yes')), findsOneWidget);

      for (var i = 0; i < 9; i++) {
        final listQuestionCard = tester.widget<Container>(
          find.byKey(ValueKey('subform-list-question-card-$i')),
        );
        expect(
          (listQuestionCard.decoration! as BoxDecoration).color,
          GacColors.offWhite,
        );
      }

      // Toggle back to dropdown view
      await tester.tap(find.byKey(const ValueKey('subform-toggle-view-mode')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('subform-dropdown-container')), findsOneWidget);
    });

    testWidgets('All subform items YES derives COMPLIANT and submits with details', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeDosAftersalesRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards',
            repository: repo,
            user: adminUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('subform-eligibility-show-subform')));
      await tester.pumpAndSettle();

      // Answer all 9 items using list view for convenience
      await tester.tap(find.byKey(const ValueKey('subform-toggle-view-mode')));
      await tester.pumpAndSettle();

      for (var i = 1; i <= 9; i++) {
        final btn = find.byKey(ValueKey('subform-sr-$i-list-yes'));
        await tester.ensureVisible(btn);
        await tester.pumpAndSettle();
        await tester.tap(btn);
        await tester.pumpAndSettle();
      }

      // Check overall status banner
      expect(
        find.textContaining('COMPLIANT: All requirements passed (Overall: YES)'),
        findsOneWidget,
      );

      // Submit checklist
      await tester.tap(find.byKey(const ValueKey('checklist-header-submit-button')));
      await tester.pumpAndSettle();

      // Verify submitted payload has eligibility and subform answers
      expect(repo.savedResponses.isNotEmpty, isTrue);
      final details = repo.savedResponses.first['details'] as Map<String, dynamic>?;
      expect(details, isNotNull);
      expect(details!['eligibility'], 'show_subform');
      final subAnswers = details['subform_answers'] as Map<String, dynamic>?;
      expect(subAnswers, isNotNull);
      expect(subAnswers!.length, 9);
      expect(subAnswers['subform-sr-1'], 'yes');
      expect(subAnswers['subform-sr-9'], 'yes');
    });
  });
}
