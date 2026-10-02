import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_checklist_detail_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

class _FakeMissedChecklistRepo implements ChecklistRepository {
  _FakeMissedChecklistRepo({
    required this.template,
    required this.submission,
  });

  final ChecklistTemplateData template;
  final ChecklistSubmissionData? submission;

  @override
  Future<ChecklistLoadResult> fetchChecklist(String slug, {String? date}) async {
    return ChecklistLoadResult(template: template, submission: submission);
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedTime = DateTime(2026, 9, 11, 14, 30); // 2:30 PM (14:00 slot active)

  ChecklistTemplateData createTemplate() {
    return ChecklistTemplateData(
      id: 1,
      slug: 'restroom',
      name: 'Restroom Checklist',
      description: null,
      version: 1,
      settings: {
        'validation_mode': 'time_slots',
        'time_slots': [
          {'key': '08:00', 'label': '08:00 AM'},
          {'key': '11:00', 'label': '11:00 AM'},
          {'key': '14:00', 'label': '02:00 PM'},
          {'key': '16:00', 'label': '04:00 PM'},
        ],
      },
      sections: [
        ChecklistSectionData(
          id: 1,
          key: 'general',
          title: 'General Cleanliness',
          sortOrder: 1,
          metadata: const {},
          items: [
            ChecklistItemData.fromJson({
              'id': 1,
              'key': 'mirror-clean',
              'prompt': 'Is the mirror clean?',
              'sort_order': 1,
              'is_active': true,
              'active_slots': ['08:00', '11:00', '14:00', '16:00'],
              'metadata': {'number': '1'},
            }),
            ChecklistItemData.fromJson({
              'id': 2,
              'key': 'soap-dispenser',
              'prompt': 'Is the soap dispenser filled?',
              'sort_order': 2,
              'is_active': true,
              'active_slots': ['08:00', '11:00', '14:00', '16:00'],
              'metadata': {'number': '2'},
            }),
          ],
        ),
      ],
    );
  }

  // 08:00 slot was missed and auto-submitted as "NO" (not_good)
  ChecklistSubmissionData createMissedSubmission() {
    return ChecklistSubmissionData(
      id: 42,
      status: 'submitted',
      auditDate: '2026-09-11',
      templateVersion: 1,
      scores: const {},
      responses: {
        'mirror-clean': ChecklistResponseData.fromJson({
          'item_key': 'mirror-clean',
          'status': 'submitted',
          'details': {
            'slots': {'08:00': 'not_good'},
            'submitted_slots': ['08:00'],
          },
        }),
        'soap-dispenser': ChecklistResponseData.fromJson({
          'item_key': 'soap-dispenser',
          'status': 'submitted',
          'details': {
            'slots': {'08:00': 'not_good'},
            'submitted_slots': ['08:00'],
          },
        }),
      },
      answeredItems: 2,
      totalItems: 2,
      completionPercentage: 100,
      submittedAt: DateTime(2026, 9, 11, 9, 1),
    );
  }

  const user = AuthenticatedUser(
    id: 5,
    name: 'Utilities User',
    email: 'utilities@gac.test',
    userType: '5S_UTILITIES',
    accountStatus: 'active',
  );

  testWidgets(
    'when a slot was submitted due to being missed, submit button is disabled and shows scheduled hour modal on click',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final template = createTemplate();
      final submission = createMissedSubmission();
      final repo = _FakeMissedChecklistRepo(
        template: template,
        submission: submission,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'restroom',
            auditDate: '2026-09-11',
            user: user,
            repository: repo,
            nowProvider: () => fixedTime,
            initialSlotKey: '08:00',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify we are viewing the 08:00 slot
      expect(find.textContaining('08:00 AM'), findsWidgets);

      // 2. The header SUBMIT button is present with the submit key
      final headerSubmitButton = find.byKey(const ValueKey('checklist-header-submit-button'));
      expect(headerSubmitButton, findsOneWidget);

      // 3. Tapping the header SUBMIT button shows the modal
      await tester.tap(headerSubmitButton);
      await tester.pumpAndSettle();

      expect(find.text('SCHEDULED HOUR ONLY'), findsOneWidget);
      expect(find.text('Submission Locked'), findsOneWidget);
      expect(
        find.textContaining('This checklist can only be submitted during its scheduled hour'),
        findsOneWidget,
      );

      // 4. Dismiss modal with OK
      await tester.tap(find.byKey(const ValueKey('checklist-message-ok-button')));
      await tester.pumpAndSettle();
      expect(find.text('Submission Locked'), findsNothing);

      // 5. Since all items in this slot were answered/missed, it opened directly on the last question
      final bottomSubmit = find.widgetWithText(FilledButton, 'SUBMIT CHECKLIST');
      expect(bottomSubmit, findsOneWidget);

      // 6. Tapping the bottom SUBMIT CHECKLIST button also shows the modal
      await tester.tap(bottomSubmit);
      await tester.pumpAndSettle();

      expect(find.text('SCHEDULED HOUR ONLY'), findsOneWidget);
      expect(find.text('Submission Locked'), findsOneWidget);
      expect(
        find.textContaining('This checklist can only be submitted during its scheduled hour'),
        findsOneWidget,
      );

      // Dismiss modal
      await tester.tap(find.byKey(const ValueKey('checklist-message-ok-button')));
      await tester.pumpAndSettle();
      expect(find.text('Submission Locked'), findsNothing);

      // 7. Test PREVIOUS button to go back to question 1
      await tester.tap(find.text('PREVIOUS'));
      await tester.pumpAndSettle();
      expect(find.text('NEXT'), findsOneWidget);

      // Tap NEXT to return to question 2
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'SUBMIT CHECKLIST'), findsOneWidget);
    },
  );

  testWidgets(
    'in list view, disabled submit button shows scheduled hour modal on click for submitted/missed slot',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final template = createTemplate();
      final submission = createMissedSubmission();
      final repo = _FakeMissedChecklistRepo(
        template: template,
        submission: submission,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'restroom',
            auditDate: '2026-09-11',
            user: user,
            repository: repo,
            nowProvider: () => fixedTime,
            initialSlotKey: '08:00',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to List View via view toggle
      final viewToggle = find.byTooltip('Switch to list view');
      expect(viewToggle, findsOneWidget);
      await tester.tap(viewToggle);
      await tester.pumpAndSettle();

      // In List View, header SUBMIT button is present
      final headerSubmitButton = find.byKey(const ValueKey('checklist-header-submit-button'));
      expect(headerSubmitButton, findsOneWidget);

      // Tapping it triggers the modal
      await tester.tap(headerSubmitButton);
      await tester.pumpAndSettle();

      expect(find.text('SCHEDULED HOUR ONLY'), findsOneWidget);
      expect(find.text('Submission Locked'), findsOneWidget);
      expect(
        find.textContaining('This checklist can only be submitted during its scheduled hour'),
        findsOneWidget,
      );
    },
  );
}
