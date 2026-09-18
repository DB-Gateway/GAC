import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/data/admin_data.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_checklist_detail_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

void main() {
  for (final role in [
    'ASM',
    'CE SERVICE',
    'JC',
    'PARTS',
    'WS SUP',
    'ADMIN',
    'BOM',
  ]) {
    for (final categories in [2, 3]) {
      testWidgets('$role submits all Yes across $categories DOS categories', (
        tester,
      ) async {
        final user = _user(role);
        final repository = _SubmissionRepository(
          _template(
            'dealer-operations-standards',
            user,
            categories: categories,
          ),
          user,
        );
        await _open(tester, repository, category: 'Basic');

        for (var index = 0; index < categories; index++) {
          await tester.tap(find.byKey(ValueKey('item-$index-response-yes')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const ValueKey('dos-next-question')),
          );
          await tester.tap(find.byKey(const ValueKey('dos-next-question')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }

        expect(repository.submittedResponses, hasLength(categories));
        expect(find.text('Checklist submitted'), findsOneWidget);
        for (final response in repository.submittedResponses!) {
          expect(response['status'], 'yes');
          expect(response['remark'], isNull);
          expect(response['finding'], isNull);
        }
        expect(repository.draftCalls, categories - 1);
      });
    }
  }

  for (final role in ['5S_SALES', '5S_SERVICE', 'PIC']) {
    testWidgets('$role submits all Yes without remarks or findings', (
      tester,
    ) async {
      final user = _user(role);
      final repository = _SubmissionRepository(
        _template(role == '5S_SERVICE' ? 'service' : 'sales', user),
        user,
      );
      await _open(tester, repository);
      for (var index = 0; index < 3; index++) {
        await tester.tap(find.byKey(ValueKey('item-$index-response-yes')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('dos-next-question')),
        );
        await tester.tap(find.byKey(const ValueKey('dos-next-question')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Checklist submitted'), findsOneWidget);
      expect(repository.submittedResponses, hasLength(3));
      expect(
        repository.submittedResponses!.map((r) => r['status']),
        everyElement('yes'),
      );
    });
  }

  testWidgets(
    'Sales Manager submits all Yes from the final saved DOS category',
    (tester) async {
      final repository = _SubmissionRepository(
        buildDosSalesTemplateData(),
        _user('SM'),
      );
      repository.answers.addEntries(
        repository.items.map((item) => MapEntry(item.key, _yesResponse(item))),
      );
      await _open(tester, repository, category: 'Beyond');
      await tester.tap(
        find.byKey(const ValueKey('checklist-header-submit-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repository.submittedResponses, hasLength(repository.items.length));
      expect(find.text('Checklist submitted'), findsOneWidget);
      expect(
        repository.submittedResponses!.map((r) => r['status']),
        everyElement('yes'),
      );
    },
  );
}

AuthenticatedUser _user(String role) => AuthenticatedUser(
  id: 1,
  name: 'Checklist user',
  email: 'checklist@example.test',
  userType: role,
  accountStatus: 'active',
);

Future<void> _open(
  WidgetTester tester,
  _SubmissionRepository repository, {
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
        slug: repository.template.slug,
        repository: repository,
        user: repository.user,
        categoryFilter: category,
        auditDate: '2026-09-08',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ChecklistTemplateData _template(
  String slug,
  AuthenticatedUser user, {
  int categories = 3,
}) {
  final isDos = slug == 'dealer-operations-standards';
  return ChecklistTemplateData(
    id: 1,
    slug: slug,
    name: 'Checklist',
    description: 'Submission fixture',
    version: 1,
    settings: {'validation_mode': isDos ? 'dos' : 'yes_no_na'},
    sections: [
      ChecklistSectionData(
        id: 1,
        key: 'standards',
        title: 'Standards',
        sortOrder: 0,
        metadata: const {},
        items: [
          for (var index = 0; index < categories; index++)
            ChecklistItemData(
              id: index + 1,
              key: 'item-$index',
              prompt: 'Is standard ${index + 1} compliant?',
              sortOrder: index,
              metadata: {
                'number': index + 1,
                'category': ['Basic', 'Standard', 'Beyond'][index],
                'checker': user.dosCheckerCode,
              },
            ),
          if (isDos && !user.isAdmin)
            const ChecklistItemData(
              id: 99,
              key: 'another-checker',
              prompt: 'A standard assigned to another checker',
              sortOrder: 99,
              metadata: {'category': 'Beyond', 'checker': 'SM'},
            ),
        ],
      ),
    ],
  );
}

Map<String, dynamic> _yesResponse(ChecklistItemData item) => {
  'item_id': item.id,
  'item_key': item.key,
  'status': 'yes',
};

class _SubmissionRepository implements ChecklistRepository {
  _SubmissionRepository(this.template, this.user);

  final ChecklistTemplateData template;
  final AuthenticatedUser user;
  final Map<String, Map<String, dynamic>> answers = {};
  List<Map<String, dynamic>>? submittedResponses;
  int draftCalls = 0;

  List<ChecklistItemData> get items => template.sections
      .expand((s) => s.items)
      .where(
        (item) =>
            template.validationMode != 'dos' ||
            user.isAdmin ||
            user.matchesCheckerRole(item.checker),
      )
      .toList();

  ChecklistSubmissionData _submission(String status) => ChecklistSubmissionData(
    id: 1,
    status: status,
    auditDate: '2026-09-08',
    templateVersion: 1,
    scores: const {},
    responses: answers.map(
      (key, value) => MapEntry(key, ChecklistResponseData.fromJson(value)),
    ),
    answeredItems: answers.length,
    totalItems: items.length,
    completionPercentage: 100.0 * answers.length / items.length,
    submittedAt: status == 'submitted' ? DateTime(2026, 9, 8) : null,
  );

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async =>
      ChecklistLoadResult(template: template, submission: _submission('draft'));

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
  }) async {
    draftCalls++;
    for (final response in responses) {
      answers[response['item_key'] as String] = response;
    }
    return _submission('draft');
  }

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    submittedResponses = responses;
    // The API replaces the submission's answers with the final request body.
    final submittedKeys = responses.map((r) => r['item_key']).toSet();
    if (items.any((item) => !submittedKeys.contains(item.key))) {
      throw const ChecklistApiException(
        'A YES, NO, or N/A response is required.',
      );
    }
    return _submission('submitted');
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
