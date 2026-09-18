import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/models/user_notification.dart';
import 'package:gac_flutter/screens/user_home_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/services/notification_service.dart';
import 'package:gac_flutter/services/profile_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';
import 'package:gac_flutter/widgets/user_tabs_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final openFromHome in [true, false]) {
    for (final action in ['submit', 'draft', 'undo']) {
      final submit = action == 'submit';
      final undo = action == 'undo';
      testWidgets(
        '${submit
            ? 'Submitting'
            : undo
            ? 'Undoing the last saved answer'
            : 'Saving a draft'} from '
        '${openFromHome ? 'Home' : 'Checklist'} updates both tabs without refresh',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final repository = _ProgressRepository();
          final notifications = UserNotificationController(
            repository: _NotificationsRepository(),
          );
          await notifications.load();
          addTearDown(notifications.dispose);

          await tester.pumpWidget(
            MaterialApp(
              theme: GacTheme.light,
              home: UserTabsLayout(
                checklistRepository: repository,
                profileRepository: _ProfileRepository(),
                notificationController: notifications,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('0 / 2 checks completed'), findsOneWidget);

          if (!openFromHome) {
            await tester.tap(find.text('Checklist'));
            await tester.pumpAndSettle();
            expect(find.text('0/2 · 0%'), findsNWidgets(2));
            await tester.tap(find.text('Sales Checklist'));
          } else {
            await tester.tap(find.text('Sales Checklist'));
          }
          await tester.pumpAndSettle();
          await tester.tap(find.text('YES'));
          await tester.pumpAndSettle();

          if (submit) {
            await tester.ensureVisible(
              find.byKey(const ValueKey('dos-next-question')),
            );
            await tester.tap(find.byKey(const ValueKey('dos-next-question')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('YES'));
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('checklist-header-submit-button')),
            );
            await tester.pumpAndSettle();
            expect(find.text('Checklist submitted'), findsOneWidget);
            await tester.tap(
              find.byKey(const ValueKey('checklist-message-ok-button')),
            );
          } else if (undo) {
            await tester.tap(find.byTooltip('Back to checklists'));
            await tester.pumpAndSettle();
            await tester.pump(const Duration(seconds: 3));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Sales Checklist'));
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('dos-previous-question')),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.text('YES'));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('confirm-undo-choice')));
            await tester.pumpAndSettle();
            await tester.tap(find.byTooltip('Back to checklists'));
          } else {
            await tester.tap(find.byTooltip('Back to checklists'));
          }
          await tester.pumpAndSettle();

          final answered = submit
              ? 2
              : undo
              ? 0
              : 1;
          final percentage = submit
              ? 100
              : undo
              ? 0
              : 50;
          expect(repository.submission?.status, submit ? 'submitted' : 'draft');
          if (undo) {
            expect(repository.submission!.hasStarted, isFalse);
            expect(find.text('Checklist saved'), findsNothing);
          }

          if (!openFromHome) {
            expect(find.text('$answered/2 · $percentage%'), findsNWidgets(2));
            await tester.tap(
              find.byKey(const ValueKey('checklist-back-button')),
            );
            await tester.pumpAndSettle();
          }
          expect(find.text('$answered / 2 checks completed'), findsOneWidget);
          expect(
            tester.widget<ProgressRing>(find.byType(ProgressRing)).value,
            percentage,
          );

          // The other tab was already mounted before the answers were saved.
          await tester.tap(find.text('Checklist'));
          await tester.pumpAndSettle();
          expect(find.text('$answered/2 · $percentage%'), findsNWidgets(2));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _ProgressRepository implements ChecklistRepository {
  ChecklistSubmissionData? submission;

  static const template = ChecklistTemplateData(
    id: 1,
    slug: 'sales',
    name: 'Sales Checklist',
    description: 'Daily sales checks',
    version: 1,
    settings: {'validation_mode': 'yes_no_na'},
    sections: [
      ChecklistSectionData(
        id: 1,
        key: 'sales-area',
        title: 'Sales Area',
        sortOrder: 0,
        metadata: {},
        items: [
          ChecklistItemData(
            id: 1,
            key: 'item-1',
            prompt: 'Is the sales area clean?',
            sortOrder: 0,
            metadata: {'number': 1},
          ),
          ChecklistItemData(
            id: 2,
            key: 'item-2',
            prompt: 'Are the displays tidy?',
            sortOrder: 1,
            metadata: {'number': 2},
          ),
        ],
      ),
    ],
  );

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async => [
    ChecklistCatalogItem(
      id: 1,
      slug: template.slug,
      name: template.name,
      description: template.description,
      version: template.version,
      settings: template.settings,
      sectionCount: 1,
      itemCount: 2,
      workUnitCount: 2,
      submission: submission,
    ),
  ];

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    if (slug != template.slug) {
      throw const ChecklistApiException('Checklist unavailable');
    }
    return ChecklistLoadResult(template: template, submission: submission);
  }

  ChecklistSubmissionData _save(
    String status,
    String date,
    List<Map<String, dynamic>> responses,
  ) {
    final answered = responses
        .where((response) => response['status'] != null)
        .length;
    return submission = ChecklistSubmissionData(
      id: 1,
      status: status,
      auditDate: date,
      templateVersion: 1,
      scores: {'answered': answered, 'total': 2},
      responses: {
        for (final response in responses)
          response['item_key'] as String: ChecklistResponseData.fromJson(
            response,
          ),
      },
      answeredItems: answered,
      totalItems: 2,
      completionPercentage: answered / 2 * 100,
      submittedAt: status == 'submitted' ? DateTime.now() : null,
    );
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
  }) async => _save('draft', date, responses);

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async => _save('submitted', date, responses);

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) => throw UnimplementedError();
}

class _ProfileRepository implements ProfileRepository {
  @override
  Future<AuthenticatedUser?> loadCachedProfile() async =>
      const AuthenticatedUser(
        id: 1,
        name: 'Sales Inspector',
        email: 'sales@example.test',
        userType: '5S_SALES',
        accountStatus: 'active',
      );

  @override
  Future<AuthenticatedUser> fetchProfile() async =>
      (await loadCachedProfile())!;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NotificationsRepository implements NotificationRepository {
  @override
  Future<NotificationInbox> fetchNotifications() async =>
      const NotificationInbox(notifications: [], unreadCount: 0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
