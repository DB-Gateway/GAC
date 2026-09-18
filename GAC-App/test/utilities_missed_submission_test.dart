import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_home_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/services/utilities_missed_checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

class _FakeChecklistRepo implements ChecklistRepository {
  String? submittedSlug;
  String? submittedDate;
  List<Map<String, dynamic>> submittedResponses = const [];
  ChecklistSubmissionData? currentSubmission;

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async {
    return [
      ChecklistCatalogItem(
        id: 1,
        slug: 'restroom',
        name: '5S Utilities Checklist',
        description: 'Hourly Restroom Inspection',
        version: 1,
        settings: const {
          'validation_mode': 'time_slots',
          'time_slots': [
            {'key': '08:00', 'label': '8 AM'},
            {'key': '09:00', 'label': '9 AM'},
            {'key': '10:00', 'label': '10 AM'},
            {'key': '11:00', 'label': '11 AM'},
            {'key': '13:00', 'label': '1 PM'},
            {'key': '14:00', 'label': '2 PM'},
            {'key': '15:00', 'label': '3 PM'},
            {'key': '16:00', 'label': '4 PM'},
            {'key': '17:00', 'label': '5 PM'},
          ],
        },
        sectionCount: 1,
        itemCount: 2,
        workUnitCount: 18,
        submission: currentSubmission,
      ),
    ];
  }

  @override
  Future<ChecklistLoadResult> fetchChecklist(String slug, {String? date}) async {
    return ChecklistLoadResult(
      template: ChecklistTemplateData(
        id: 1,
        slug: slug,
        name: '5S Utilities Checklist',
        description: 'Hourly Restroom Inspection',
        version: 1,
        settings: const {
          'validation_mode': 'time_slots',
          'time_slots': [
            {'key': '08:00', 'label': '8 AM'},
            {'key': '09:00', 'label': '9 AM'},
            {'key': '10:00', 'label': '10 AM'},
            {'key': '11:00', 'label': '11 AM'},
            {'key': '13:00', 'label': '1 PM'},
            {'key': '14:00', 'label': '2 PM'},
            {'key': '15:00', 'label': '3 PM'},
            {'key': '16:00', 'label': '4 PM'},
            {'key': '17:00', 'label': '5 PM'},
          ],
        },
        sections: const [
          ChecklistSectionData(
            id: 10,
            key: 'restroom-hygiene',
            title: 'Restroom Hygiene',
            sortOrder: 1,
            metadata: {},
            items: [
              ChecklistItemData(
                id: 101,
                key: 'mirror-clean',
                prompt: 'Are mirrors clean?',
                sortOrder: 1,
                metadata: {},
              ),
              ChecklistItemData(
                id: 102,
                key: 'sink-clean',
                prompt: 'Are sinks clean?',
                sortOrder: 2,
                metadata: {},
              ),
            ],
          ),
        ],
      ),
      submission: currentSubmission,
    );
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
  }) async {
    return _createSubmission(status: 'draft', date: date, responses: responses);
  }

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    submittedSlug = slug;
    submittedDate = date;
    submittedResponses = responses;
    final sub = _createSubmission(
      status: 'submitted',
      date: date,
      responses: responses,
    );
    currentSubmission = sub;
    return sub;
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) async {
    return {'path': 'attachments/$filename', 'url': 'http://localhost/$filename'};
  }

  ChecklistSubmissionData _createSubmission({
    required String status,
    required String date,
    required List<Map<String, dynamic>> responses,
  }) {
    final responseMap = <String, ChecklistResponseData>{};
    for (final r in responses) {
      final key = r['item_key'] as String;
      responseMap[key] = ChecklistResponseData(
        itemId: r['item_id'] as int? ?? 0,
        itemKey: key,
        status: r['status'] as String?,
        remark: r['remark'] as String?,
        finding: null,
        actionPlan: null,
        commitmentDate: null,
        details: Map<String, dynamic>.from(r['details'] as Map? ?? {}),
      );
    }
    return ChecklistSubmissionData(
      id: 99,
      status: status,
      auditDate: date,
      templateVersion: 1,
      scores: {'completed_slots': 1},
      responses: responseMap,
      answeredItems: responses.length,
      totalItems: 2,
      completionPercentage: 50,
      submittedAt: DateTime.now(),
    );
  }
}

void main() {
  const utilitiesUser = AuthenticatedUser(
    id: 10,
    name: 'Utilities Personnel',
    email: 'utilities@gateway.com',
    userType: '5S_UTILITIES',
    accountStatus: 'active',
    branch: 'Cebu',
    picAssignmentType: 'utilities',
  );

  const salesUser = AuthenticatedUser(
    id: 20,
    name: 'Sales Personnel',
    email: 'sales@gateway.com',
    userType: '5S_SALES',
    accountStatus: 'active',
    branch: 'Cebu',
    picAssignmentType: 'sales',
  );

  group('UtilitiesMissedChecklistService unit tests', () {
    test('non-utilities user is ignored', () async {
      final repo = _FakeChecklistRepo();
      final result = await UtilitiesMissedChecklistService.syncMissedUtilitiesChecklist(
        repository: repo,
        user: salesUser,
        now: DateTime(2026, 9, 17, 9, 30),
      );
      expect(result, isNull);
      expect(repo.submittedSlug, isNull);
    });

    test('user logging in at 8:15 AM does not auto-submit and detects active 8 AM due slot', () async {
      final repo = _FakeChecklistRepo();
      final result = await UtilitiesMissedChecklistService.syncMissedUtilitiesChecklist(
        repository: repo,
        user: utilitiesUser,
        now: DateTime(2026, 9, 17, 8, 15),
        date: '2026-09-17',
      );

      expect(result, isNotNull);
      expect(result!.autoSubmitted, isFalse);
      expect(result.missedSlots, isEmpty);
      expect(result.activeDueSlot, '08:00');
      expect(repo.submittedSlug, isNull);
    });

    test('user logging in at 9:30 AM auto-submits missed 8:00 AM slot as NO (not_good)', () async {
      final repo = _FakeChecklistRepo();
      final result = await UtilitiesMissedChecklistService.syncMissedUtilitiesChecklist(
        repository: repo,
        user: utilitiesUser,
        now: DateTime(2026, 9, 17, 9, 30),
        date: '2026-09-17',
      );

      expect(result, isNotNull);
      expect(result!.autoSubmitted, isTrue);
      expect(result.missedSlots, ['08:00']);
      expect(result.formattedMissedSlots, '8:00 AM');
      expect(result.activeDueSlot, '09:00');

      expect(repo.submittedSlug, 'restroom');
      expect(repo.submittedDate, '2026-09-17');
      expect(repo.submittedResponses, hasLength(2));

      for (final r in repo.submittedResponses) {
        final details = r['details'] as Map<String, dynamic>;
        final slots = details['slots'] as Map<String, dynamic>;
        final submittedSlots = details['submitted_slots'] as List;

        expect(slots['08:00'], 'not_good');
        expect(submittedSlots, contains('08:00'));
      }
    });

    test('user logging in at 11:30 AM auto-submits all missed slots (8, 9, 10 AM) as NO', () async {
      final repo = _FakeChecklistRepo();
      final result = await UtilitiesMissedChecklistService.syncMissedUtilitiesChecklist(
        repository: repo,
        user: utilitiesUser,
        now: DateTime(2026, 9, 17, 11, 30),
        date: '2026-09-17',
      );

      expect(result, isNotNull);
      expect(result!.autoSubmitted, isTrue);
      expect(result.missedSlots, ['08:00', '09:00', '10:00']);
      expect(result.formattedMissedSlots, '8:00 AM, 9:00 AM, 10:00 AM');
      expect(result.activeDueSlot, '11:00');

      for (final r in repo.submittedResponses) {
        final details = r['details'] as Map<String, dynamic>;
        final slots = details['slots'] as Map<String, dynamic>;
        final submittedSlots = details['submitted_slots'] as List;

        expect(slots['08:00'], 'not_good');
        expect(slots['09:00'], 'not_good');
        expect(slots['10:00'], 'not_good');
        expect(submittedSlots, containsAll(['08:00', '09:00', '10:00']));
      }
    });

    test('preserves already submitted slots when subsequent missed slots are auto-submitted', () async {
      final repo = _FakeChecklistRepo();
      // Suppose 8:00 AM was submitted as 'good' earlier in the day
      repo.currentSubmission = ChecklistSubmissionData(
        id: 50,
        status: 'draft',
        auditDate: '2026-09-17',
        templateVersion: 1,
        scores: {'completed_slots': 1},
        responses: {
          'mirror-clean': const ChecklistResponseData(
            itemId: 101,
            itemKey: 'mirror-clean',
            status: null,
            remark: null,
            finding: null,
            actionPlan: null,
            commitmentDate: null,
            details: {
              'slots': {'08:00': 'good'},
              'submitted_slots': ['08:00'],
            },
          ),
          'sink-clean': const ChecklistResponseData(
            itemId: 102,
            itemKey: 'sink-clean',
            status: null,
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

      final result = await UtilitiesMissedChecklistService.syncMissedUtilitiesChecklist(
        repository: repo,
        user: utilitiesUser,
        now: DateTime(2026, 9, 17, 10, 30),
        date: '2026-09-17',
      );

      expect(result, isNotNull);
      expect(result!.autoSubmitted, isTrue);
      // Only 9:00 AM was missed, because 8:00 was already submitted
      expect(result.missedSlots, ['09:00']);

      for (final r in repo.submittedResponses) {
        final details = r['details'] as Map<String, dynamic>;
        final slots = details['slots'] as Map<String, dynamic>;
        final submittedSlots = details['submitted_slots'] as List;

        expect(slots['08:00'], 'good'); // preserved
        expect(slots['09:00'], 'not_good'); // auto-submitted as NO
        expect(submittedSlots, containsAll(['08:00', '09:00']));
      }
    });
  });

  group('UserHomeScreen widget tests for 5S Utilities missed and due submissions', () {
    testWidgets('at 9:30 AM, auto-submits missed 8:00 AM and shows SnackBar', (tester) async {
      final repo = _FakeChecklistRepo();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: Scaffold(
            body: UserHomeScreen(
              isActive: true,
              user: utilitiesUser,
              repository: repo,
              now: () => DateTime(2026, 9, 17, 9, 30),
              onOpenChecklists: () {},
              onOpenProfile: () {},
              onOpenNotifications: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.submittedSlug, 'restroom');
      expect(
        find.text('Missed 8:00 AM Utilities inspection was automatically submitted as NO.'),
        findsOneWidget,
      );
    });

    testWidgets('at 8:15 AM, does not auto-submit and displays 8:00 AM INSPECTION DUE banner', (tester) async {
      final repo = _FakeChecklistRepo();
      String? openedSlug;
      String? openedSlot;

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: Scaffold(
            body: UserHomeScreen(
              isActive: true,
              user: utilitiesUser,
              repository: repo,
              now: () => DateTime(2026, 9, 17, 8, 15),
              onOpenChecklists: () {},
              onOpenProfile: () {},
              onOpenNotifications: () {},
              onOpenChecklistWithSlot: (slug, date, slot, [itemKey]) {
                openedSlug = slug;
                openedSlot = slot;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Not auto-submitted
      expect(repo.submittedSlug, isNull);

      // Banner is shown
      expect(find.byKey(const ValueKey('utilities-active-slot-banner')), findsOneWidget);
      expect(find.text('8:00 AM INSPECTION DUE'), findsOneWidget);
      expect(
        find.text('Please complete and submit your 5S Utilities inspection.'),
        findsOneWidget,
      );

      // Tap the SUBMIT button in the banner
      await tester.tap(find.byKey(const ValueKey('submit-active-slot-button')));
      await tester.pumpAndSettle();

      expect(openedSlug, 'restroom');
      expect(openedSlot, '08:00');
    });
  });
}
