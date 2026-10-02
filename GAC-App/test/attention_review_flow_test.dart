import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_checklist_detail_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

void main() {
  testWidgets(
    'Next and Previous review only NO across categories, excluding N/A, then finish',
    (tester) async {
      final repository = _ReviewRepository(
        _record(['yes', 'no', 'yes', 'na', 'no', 'yes'], mode: 'dos'),
      );
      await _openReview(tester, repository, category: 'Basic');
      expect(find.text('1 of 2 responses · No'), findsOneWidget);
      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('Question 0'), findsNothing);
      expect(find.text('Question 3'), findsNothing);
      expect(find.byTooltip('Switch to list view'), findsNothing);
      expect(find.text('Randomize answers'), findsNothing);

      await _next(tester);
      expect(find.text('Question 4'), findsOneWidget);
      expect(find.text('Question 2'), findsNothing);
      expect(find.text('Question 3'), findsNothing);
      expect(find.text('2 of 2 responses · No'), findsOneWidget);
      expect(find.text('Finish review'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('attention-review-previous')));
      await tester.pumpAndSettle();
      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('1 of 2 responses · No'), findsOneWidget);

      await _next(tester);
      expect(find.text('Question 4'), findsOneWidget);
      await _next(tester);
      expect(find.text('Review complete'), findsOneWidget);
      expect(find.text('All No responses have been reviewed.'), findsOneWidget);
      expect(find.text('Question 5'), findsNothing);
      expect(repository.saveCalls, 0);
      expect(repository.submitCalls, 0);
    },
  );

  testWidgets(
    'hourly review skips good and na slots and visits only affected item and slot pairs',
    (tester) async {
      final repository = _ReviewRepository(
        _record(
          ['yes', 'no', 'yes'],
          mode: 'time_slots',
          details: [
            {
              'slots': {'08:00': 'good', '09:00': 'na'},
            },
            {
              'slots': {'08:00': 'not_good', '09:00': 'good'},
            },
            {
              'slots': {'08:00': 'good', '09:00': 'good'},
            },
          ],
        ),
      );
      await _openReview(tester, repository);
      expect(find.text('1 of 1 responses · No'), findsOneWidget);
      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('Inspection: 8 AM'), findsOneWidget);
      expect(find.text('9 AM'), findsNothing);
      expect(find.text('Question 0'), findsNothing);
      await _next(tester);
      expect(find.text('Review complete'), findsOneWidget);
      expect(find.text('All No responses have been reviewed.'), findsOneWidget);
      expect(repository.saveCalls, 0);
    },
  );

  testWidgets('documentation review skips YES and N/A for each customer sample', (
    tester,
  ) async {
    final repository = _ReviewRepository(
      _record(
        ['yes', 'no', 'no'],
        mode: 'dos_documentation',
        details: [
          {
            'customers': [
              {
                'customer_index': 1,
                'ro_number': 'RO-1',
                'answers': {'q0': 'yes', 'q1': 'na', 'q2': 'yes'},
              },
              {
                'customer_index': 2,
                'ro_number': 'RO-2',
                'answers': {'q0': 'yes', 'q1': 'yes', 'q2': 'no'},
              },
            ],
          },
          {},
          {},
        ],
      ),
    );
    await _openReview(tester, repository);
    expect(find.text('1 of 1 responses · No'), findsOneWidget);
    expect(find.text('Customer 2'), findsOneWidget);
    expect(find.text('Question 2'), findsOneWidget);
    expect(find.text('Customer 1'), findsNothing);
    await _next(tester);
    expect(find.text('Review complete'), findsOneWidget);
    expect(find.text('All No responses have been reviewed.'), findsOneWidget);
    expect(repository.submitCalls, 0);
  });

  testWidgets('all-YES review has a clear end without opening a category', (
    tester,
  ) async {
    await _openReview(tester, _ReviewRepository(_record(['yes', 'yes'])));
    expect(find.text('No responses need review.'), findsOneWidget);
    expect(find.text('Question 0'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    expect(find.byKey(const ValueKey('attention-review-next')), findsNothing);
  });

  testWidgets('all-N/A review has a clear end without opening any question', (
    tester,
  ) async {
    await _openReview(tester, _ReviewRepository(_record(['na', 'na'])));
    expect(find.text('No responses need review.'), findsOneWidget);
    expect(find.text('Question 0'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    expect(find.byKey(const ValueKey('attention-review-next')), findsNothing);
  });
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('attention-review-next')));
  await tester.pumpAndSettle();
}

Future<void> _openReview(
  WidgetTester tester,
  _ReviewRepository repository, {
  String? category,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: GacTheme.light,
      home: UserChecklistDetailScreen(
        slug: repository.record.template.slug,
        repository: repository,
        attentionOnly: true,
        categoryFilter: category,
        auditDate: '2026-09-02',
        nowProvider: () => DateTime(2026, 9, 2, 10, 30),
        user: const AuthenticatedUser(
          id: 1,
          name: 'Admin',
          email: 'admin@example.com',
          userType: 'ADMIN',
          accountStatus: 'active',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ChecklistLoadResult _record(
  List<String> statuses, {
  String mode = 'yes_no_na',
  List<Map<String, dynamic>>? details,
}) => ChecklistLoadResult(
  template: ChecklistTemplateData(
    id: 1,
    slug: 'review-test',
    name: 'Review test',
    description: null,
    version: 1,
    settings: {
      'validation_mode': mode,
      'time_slots': [
        {'key': '08:00', 'label': '8 AM'},
        {'key': '09:00', 'label': '9 AM'},
      ],
    },
    sections: [
      for (var i = 0; i < statuses.length; i++)
        ChecklistSectionData(
          id: i,
          key: 'section$i',
          title: 'Section $i',
          sortOrder: i,
          metadata: const {},
          items: [
            ChecklistItemData(
              id: i + 100,
              key: 'q$i',
              prompt: 'Question $i',
              sortOrder: i,
              metadata: {'category': i < 3 ? 'Basic' : 'Beyond'},
            ),
          ],
        ),
    ],
  ),
  submission: ChecklistSubmissionData(
    id: 1,
    status: 'draft',
    auditDate: '2026-09-02',
    templateVersion: 1,
    scores: const {},
    answeredItems: statuses.length,
    totalItems: statuses.length,
    completionPercentage: 100,
    submittedAt: null,
    responses: {
      for (var i = 0; i < statuses.length; i++)
        'q$i': ChecklistResponseData(
          itemId: i + 100,
          itemKey: 'q$i',
          status: statuses[i],
          remark: 'Review note',
          finding: 'Review finding',
          actionPlan: null,
          commitmentDate: null,
          details: details?[i] ?? const {},
        ),
    },
  ),
);

class _ReviewRepository implements ChecklistRepository {
  _ReviewRepository(this.record);
  final ChecklistLoadResult record;
  int saveCalls = 0;
  int submitCalls = 0;

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async => record;
  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async => [];
  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
  }) async {
    saveCalls++;
    return record.submission!;
  }

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    submitCalls++;
    return record.submission!;
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) => throw UnimplementedError();
}
