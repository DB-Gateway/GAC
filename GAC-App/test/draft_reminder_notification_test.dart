import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/models/user_notification.dart';
import 'package:gac_flutter/screens/user_notifications_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/services/notification_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

void main() {
  testWidgets(
    'manager reminder opens the exact draft date and saved question',
    (tester) async {
      final inbox = _Inbox();
      final checklist = _Checklist();
      final controller = UserNotificationController(repository: inbox);
      addTearDown(controller.dispose);
      await _showInbox(tester, controller, checklist);

      await tester.tap(find.text('Finish your drafted checklist'));
      await tester.pumpAndSettle();

      expect(inbox.read, isTrue);
      expect(controller.unreadCount, 0);
      expect(checklist.loadedSlug, 'sales');
      expect(checklist.loadedDate, '2026-08-29');
      expect(find.text('Saved question two'), findsOneWidget);
      expect(find.text('First unanswered question'), findsNothing);
    },
  );

  testWidgets(
    'a submitted or removed reminder does not open a new editable checklist',
    (tester) async {
      final controller = UserNotificationController(repository: _Inbox());
      addTearDown(controller.dispose);
      final checklist = _Checklist()..submitted = true;
      await _showInbox(tester, controller, checklist);
      await tester.tap(find.text('Finish your drafted checklist'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('already been submitted or removed'),
        findsOneWidget,
      );
      expect(find.text('YES'), findsNothing);
    },
  );

  testWidgets(
    'periodic inbox refresh receives a new manager reminder and stops after disposal',
    (tester) async {
      final repository = _Inbox()..available = false;
      final controller = UserNotificationController(repository: repository);
      await controller.load();
      controller.startPolling();
      expect(controller.unreadCount, 0);
      repository.available = true;
      await tester.pump(const Duration(seconds: 15));
      expect(controller.unreadCount, 1);
      final loads = repository.loads;
      controller.dispose();
      await tester.pump(const Duration(seconds: 30));
      expect(repository.loads, loads);
    },
  );
}

Future<void> _showInbox(
  WidgetTester tester,
  UserNotificationController controller,
  ChecklistRepository repository,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: GacTheme.light,
      home: UserNotificationsScreen(
        onOpenProfile: () {},
        onGoHome: () {},
        onOpenSettings: () {},
        controller: controller,
        checklistRepository: repository,
        profile: const AuthenticatedUser(
          id: 12,
          name: 'Sales Auditor',
          email: 'sales@example.test',
          userType: '5S_SALES',
          accountStatus: 'active',
          branch: 'Pasong Tamo',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Inbox implements NotificationRepository {
  bool available = true;
  bool read = false;
  int loads = 0;
  UserNotification get notification => UserNotification(
    id: 'draft-reminder',
    type: 'checklist_draft_reminder',
    title: 'Finish your drafted checklist',
    message:
        'Your BOM asked you to finish Sales Checklist. Resume at question #2.',
    unread: !read,
    data: const {
      'template_slug': 'sales',
      'audit_date': '2026-08-29',
      'submission_id': 42,
      'item_key': 'item-2',
    },
  );
  @override
  Future<NotificationInbox> fetchNotifications() async {
    loads++;
    return NotificationInbox(
      notifications: available ? [notification] : [],
      unreadCount: available && !read ? 1 : 0,
    );
  }

  @override
  Future<NotificationInbox> markRead(String id) async {
    read = true;
    return NotificationInbox(notifications: [notification], unreadCount: 0);
  }

  @override
  Future<int> markAllRead() async {
    read = true;
    return 0;
  }
}

class _Checklist implements ChecklistRepository {
  String? loadedSlug;
  String? loadedDate;
  bool submitted = false;
  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    loadedSlug = slug;
    loadedDate = date;
    return ChecklistLoadResult(
      template: const ChecklistTemplateData(
        id: 1,
        slug: 'sales',
        name: 'Sales Checklist',
        description: null,
        version: 1,
        settings: {'validation_mode': 'standard'},
        sections: [
          ChecklistSectionData(
            id: 1,
            key: 'area',
            title: 'Sales Area',
            sortOrder: 0,
            metadata: {},
            items: [
              ChecklistItemData(
                id: 1,
                key: 'item-1',
                prompt: 'First unanswered question',
                sortOrder: 0,
                metadata: {'number': 1},
              ),
              ChecklistItemData(
                id: 2,
                key: 'item-2',
                prompt: 'Saved question two',
                sortOrder: 1,
                metadata: {'number': 2},
              ),
            ],
          ),
        ],
      ),
      submission: ChecklistSubmissionData(
        id: 42,
        status: submitted ? 'submitted' : 'draft',
        auditDate: date,
        templateVersion: 1,
        scores: {},
        responses: {},
        answeredItems: 0,
        totalItems: 2,
        completionPercentage: 0,
        submittedAt: null,
      ),
    );
  }

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async => [];
  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
  }) => throw UnimplementedError();
  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) => throw UnimplementedError();
}
