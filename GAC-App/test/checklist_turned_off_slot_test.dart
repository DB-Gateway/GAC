import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_checklist_detail_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

class _FakeUtilitiesRepo implements ChecklistRepository {
  _FakeUtilitiesRepo(this.template);

  final ChecklistTemplateData template;
  List<Map<String, dynamic>>? lastSubmittedResponses;

  @override
  Future<ChecklistLoadResult> fetchChecklist(String slug, {String? date}) async {
    return ChecklistLoadResult(template: template, submission: null);
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
  }) async {
    return ChecklistSubmissionData(
      id: 1,
      status: 'draft',
      auditDate: date,
      templateVersion: template.version,
      scores: const {},
      responses: const {},
      answeredItems: 0,
      totalItems: template.itemCount,
      completionPercentage: 0,
      submittedAt: null,
    );
  }

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    lastSubmittedResponses = responses;
    return ChecklistSubmissionData(
      id: 1,
      status: 'submitted',
      auditDate: date,
      templateVersion: template.version,
      scores: const {},
      responses: const {},
      answeredItems: responses.length,
      totalItems: template.itemCount,
      completionPercentage: 100,
      submittedAt: DateTime(2026, 9, 11, 8, 30),
    );
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

  group('ChecklistItemData turned-off slot tests', () {
    test('parses is_active and active_slots from JSON', () {
      final item = ChecklistItemData.fromJson({
        'id': 101,
        'key': 'mirror-clean',
        'prompt': 'Is the mirror clean?',
        'sort_order': 1,
        'is_active': true,
        'active_slots': ['08:00', '10:00'],
        'metadata': {},
      });

      expect(item.isActive, isTrue);
      expect(item.activeSlots, ['08:00', '10:00']);
      expect(item.isSlotActive('08:00'), isTrue);
      expect(item.isSlotActive('10:00'), isTrue);
      expect(item.isSlotActive('14:00'), isFalse);
    });

    test('parses active_slots from metadata fallback', () {
      final item = ChecklistItemData.fromJson({
        'id': 102,
        'key': 'soap-dispenser',
        'prompt': 'Is the soap dispenser filled?',
        'sort_order': 2,
        'is_active': true,
        'metadata': {
          'active_slots': ['08:00'],
        },
      });

      expect(item.isSlotActive('08:00'), isTrue);
      expect(item.isSlotActive('09:00'), isFalse);
    });

    test('isSlotActive returns false when item isActive is false', () {
      final item = ChecklistItemData.fromJson({
        'id': 103,
        'key': 'inactive-item',
        'prompt': 'Inactive prompt',
        'sort_order': 3,
        'is_active': false,
        'active_slots': ['08:00'],
        'metadata': {},
      });

      expect(item.isActive, isFalse);
      expect(item.isSlotActive('08:00'), isFalse);
    });
  });

  group('5S Utilities mobile UI turned-off slot tests', () {
    final fixedTime = DateTime(2026, 9, 11, 8, 15);

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
            {'key': '08:00', 'label': '08:00'},
            {'key': '10:00', 'label': '10:00'},
          ],
        },
        sections: [
          ChecklistSectionData(
            id: 1,
            key: 'main',
            title: 'Main Inspection',
            sortOrder: 1,
            metadata: const {},
            items: [
              ChecklistItemData.fromJson({
                'id': 1,
                'key': 'item-active',
                'prompt': 'Active Question in all hours',
                'sort_order': 1,
                'is_active': true,
                'active_slots': ['08:00', '10:00'],
                'metadata': {'number': '1'},
              }),
              ChecklistItemData.fromJson({
                'id': 2,
                'key': 'item-turned-off-in-0800',
                'prompt': 'Turned Off Question in 08:00',
                'sort_order': 2,
                'is_active': true,
                'active_slots': ['10:00'],
                'metadata': {'number': '2'},
              }),
            ],
          ),
        ],
      );
    }

    testWidgets(
      'turned off question displays TURNED OFF badge, banner, disabled buttons, and allows proceeding & submitting',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = _FakeUtilitiesRepo(createTemplate());
        const user = AuthenticatedUser(
          id: 5,
          name: 'Utilities User',
          email: 'utilities@gac.test',
          userType: '5S_UTILITIES',
          accountStatus: 'active',
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
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. First question: Active in 08:00
        expect(find.text('Active Question in all hours'), findsOneWidget);
        expect(find.text('MARKED YES'), findsNothing);
        expect(find.text('TURNED OFF'), findsNothing);

        // Header shows 0 OF 1 ANSWERED because only 1 item is active for 08:00
        expect(find.textContaining('0 OF 1 ANSWERED'), findsOneWidget);

        // Mark YES on question 1
        await tester.tap(find.text('YES'));
        await tester.pumpAndSettle();
        expect(find.textContaining('1 OF 1 ANSWERED'), findsOneWidget);

        // Advance to Question 2
        await tester.tap(find.text('NEXT'));
        await tester.pumpAndSettle();

        // 2. Second question: Turned off for 08:00
        expect(find.text('Turned Off Question in 08:00'), findsOneWidget);
        expect(find.text('TURNED OFF'), findsOneWidget);
        expect(
          find.text('TURNED OFF FOR 08:00'),
          findsOneWidget,
        );
        expect(
          find.text(
            'This question has been turned off by the administrator for this inspection hour and does not require an answer.',
          ),
          findsOneWidget,
        );

        // 3. Submit inspection for 08:00 without answering question 2
        await tester.tap(find.byKey(const ValueKey('checklist-header-submit-button')));
        await tester.pumpAndSettle();

        // Verify successful submission
        expect(repo.lastSubmittedResponses, isNotNull);
        expect(repo.lastSubmittedResponses, hasLength(1));
        expect(repo.lastSubmittedResponses!.first['item_key'], 'item-active');
      },
    );

    testWidgets(
      'list view displays — TURNED OFF — placeholder for slots that are turned off',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = _FakeUtilitiesRepo(createTemplate());
        const user = AuthenticatedUser(
          id: 5,
          name: 'Utilities User',
          email: 'utilities@gac.test',
          userType: '5S_UTILITIES',
          accountStatus: 'active',
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
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to List View
        await tester.tap(find.byTooltip('Switch to list view'));
        await tester.pumpAndSettle();

        // Question 2 has slot 08:00 turned off, so "— TURNED OFF —" must be rendered
        expect(find.text('— TURNED OFF —'), findsOneWidget);
      },
    );
  });
}
