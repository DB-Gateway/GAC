import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/data/admin_data.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/dos_dashboard_screen.dart';
import 'package:gac_flutter/screens/user_checklist_detail_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/services/profile_service.dart';
import 'package:gac_flutter/models/user_notification.dart';
import 'package:gac_flutter/services/notification_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';
import 'package:gac_flutter/widgets/dos_tabs_layout.dart';
import 'package:gac_flutter/widgets/user_tabs_layout.dart';
import 'package:gac_flutter/widgets/user_floating_header.dart';

class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<NotificationInbox> fetchNotifications() async =>
      const NotificationInbox(notifications: [], unreadCount: 0);

  @override
  Future<NotificationInbox> markRead(String id) async =>
      const NotificationInbox(notifications: [], unreadCount: 0);

  @override
  Future<int> markAllRead() async => 0;
}

class _FakeChecklistRepository implements ChecklistRepository {
  _FakeChecklistRepository({
    this.workshopCheckerOverride,
    this.checklistResultOverride,
  });

  ChecklistSubmissionData? initialSubmission;
  final String? workshopCheckerOverride;
  final ChecklistLoadResult? checklistResultOverride;

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async =>
      const [
        ChecklistCatalogItem(
          id: 2,
          slug: 'dealer-operations-standards',
          name: 'Dealer Operations Standards - Aftersales',
          description: 'FY2025 Aftersales Standards Compliance Audit',
          version: 2,
          settings: {'validation_mode': 'dos'},
          sectionCount: 15,
          itemCount: 75,
          workUnitCount: 75,
          submission: null,
        ),
        ChecklistCatalogItem(
          id: 6,
          slug: 'dealer-operations-standards-sales',
          name: 'Dealer Operations Standards - Sales',
          description: 'FY2025 Sales Standards Compliance Audit',
          version: 1,
          settings: {'validation_mode': 'dos'},
          sectionCount: 13,
          itemCount: 90,
          workUnitCount: 90,
          submission: null,
        ),
        ChecklistCatalogItem(
          id: 3,
          slug: 'restroom',
          name: 'Restroom Checklist',
          description: 'Utilities work that DOS users must not see',
          version: 1,
          settings: {'validation_mode': 'time_slots'},
          sectionCount: 1,
          itemCount: 11,
          workUnitCount: 99,
          submission: null,
        ),
      ];

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    if (checklistResultOverride case final result?) return result;

    if (slug == 'dealer-operations-standards-sales') {
      final sections = dosTemplate
          .map(
            (sec) => ChecklistSectionData(
              id: 0,
              key: sec.id,
              title: sec.title,
              sortOrder: 0,
              metadata: const {},
              items: sec.items
                  .map((item) {
                    final itemNumber =
                        int.tryParse(
                          item.id.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;
                    return ChecklistItemData(
                      id: itemNumber,
                      key: item.id,
                      prompt: item.text,
                      sortOrder: itemNumber,
                      metadata: {
                        'number': itemNumber,
                        'level': item.level,
                        'category': item.level,
                        'coverage': item.coverage,
                        'subject': item.subject,
                        'checker': item.checker,
                        'pic': 'GM',
                        'bom_task': item.bomTask,
                        'escalation': item.escalation,
                        'how_to_check': item.howToCheck,
                      },
                    );
                  })
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);

      return ChecklistLoadResult(
        template: ChecklistTemplateData(
          id: 6,
          slug: 'dealer-operations-standards-sales',
          name: 'Dealer Operations Standards - Sales',
          description: 'FY25 Sales Standards Compliance Audit Sheet (REV02) (90 Standards)',
          version: 1,
          settings: const {
            'validation_mode': 'dos',
            'response_options': ['yes', 'no', 'na'],
          },
          sections: sections,
        ),
        submission:
            initialSubmission ??
            const ChecklistSubmissionData(
              id: 1,
              status: 'draft',
              auditDate: '2026-09-05',
              templateVersion: 1,
              scores: {'overall': 85},
              responses: {},
              answeredItems: 18,
              totalItems: 90,
              issueCount: 2,
              completionPercentage: 82,
              submittedAt: null,
            ),
      );
    } else {
      final sections = dosAftersalesTemplate
          .map(
            (sec) => ChecklistSectionData(
              id: 0,
              key: sec.id,
              title: sec.title,
              sortOrder: 0,
              metadata: const {},
              items: sec.items
                  .map((item) {
                    final itemNumber =
                        int.tryParse(
                          item.id.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;
                    return ChecklistItemData(
                      id: itemNumber,
                      key: item.id,
                      prompt: item.text,
                      sortOrder: itemNumber,
                      metadata: {
                        'number': itemNumber,
                        'level': item.level,
                        'category': item.level,
                        'coverage': item.coverage,
                        'subject': item.subject,
                        'checker': item.checker == 'WS SUP'
                            ? workshopCheckerOverride ?? item.checker
                            : item.checker,
                        'pic': 'GM',
                        'bom_task': item.bomTask,
                        'escalation': item.escalation,
                        'how_to_check': item.howToCheck,
                      },
                    );
                  })
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);

      return ChecklistLoadResult(
        template: ChecklistTemplateData(
          id: 2,
          slug: 'dealer-operations-standards',
          name: 'Dealer Operations Standards - Aftersales',
          description: 'FY2025 Aftersales Standards Compliance Audit Sheet (75 Standards)',
          version: 1,
          settings: const {
            'validation_mode': 'dos',
            'response_options': ['yes', 'no', 'na'],
          },
          sections: sections,
        ),
        submission:
            initialSubmission ??
            const ChecklistSubmissionData(
              id: 2,
              status: 'draft',
              auditDate: '2026-09-05',
              templateVersion: 1,
              scores: {'overall': 85},
              responses: {},
              answeredItems: 60,
              totalItems: 75,
              issueCount: 3,
              completionPercentage: 80,
              submittedAt: null,
            ),
      );
    }
  }

  String? savedSlug;
  List<Map<String, dynamic>>? savedResponses;
  int saveDraftCalls = 0;
  int submitCalls = 0;

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
  }) async {
    saveDraftCalls++;
    savedSlug = slug;
    savedResponses = responses;
    return const ChecklistSubmissionData(
      id: 1,
      status: 'draft',
      auditDate: '2026-09-05',
      templateVersion: 1,
      scores: {},
      responses: {},
      answeredItems: 0,
      totalItems: 0,
      issueCount: 0,
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
    submitCalls++;
    savedSlug = slug;
    savedResponses = responses;
    return const ChecklistSubmissionData(
      id: 1,
      status: 'submitted',
      auditDate: '2026-09-05',
      templateVersion: 1,
      scores: {},
      responses: {},
      answeredItems: 0,
      totalItems: 0,
      issueCount: 0,
      completionPercentage: 100,
      submittedAt: null,
    );
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) async => {'attachment_path': 'test.jpg'};
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<AuthenticatedUser?> loadCachedProfile() async =>
      const AuthenticatedUser(
        id: 10,
        name: 'Marcus Sales',
        email: 'sales.manager@gateway.com',
        userType: 'Sales Manager',
        accountStatus: 'active',
        branch: 'Gateway San Fernando',
      );

  @override
  Future<AuthenticatedUser> fetchProfile() async =>
      (await loadCachedProfile())!;

  @override
  Future<AuthenticatedUser> updateProfile({
    required String name,
    required String email,
  }) async => (await loadCachedProfile())!;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {}

  @override
  Future<AuthenticatedUser> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async => (await loadCachedProfile())!;

  @override
  Future<AuthenticatedUser> deleteAvatar() async =>
      (await loadCachedProfile())!;

  @override
  Future<void> logout() async {}
}

class _FakeAftersalesProfileRepository implements ProfileRepository {
  @override
  Future<AuthenticatedUser?> loadCachedProfile() async =>
      const AuthenticatedUser(
        id: 20,
        name: 'Carlo Mendoza',
        email: 'carlo.asm@gateway.com',
        userType: 'ASM',
        accountStatus: 'active',
        branch: 'Gateway Balintawak',
      );

  @override
  Future<AuthenticatedUser> fetchProfile() async =>
      (await loadCachedProfile())!;

  @override
  Future<AuthenticatedUser> updateProfile({
    required String name,
    required String email,
  }) async => (await loadCachedProfile())!;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {}

  @override
  Future<AuthenticatedUser> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async => (await loadCachedProfile())!;

  @override
  Future<AuthenticatedUser> deleteAvatar() async =>
      (await loadCachedProfile())!;

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DOS Role & Model Verification', () {
    test('AuthenticatedUser recognizes Sales Manager role variations', () {
      const user1 = AuthenticatedUser(
        id: 1,
        name: 'Alex',
        email: 'alex@gac.com',
        userType: 'Sales Manager',
        accountStatus: 'active',
      );
      expect(user1.isSalesManager, isTrue);

      const user2 = AuthenticatedUser(
        id: 2,
        name: 'Jordan',
        email: 'jordan@gac.com',
        userType: 'SM',
        accountStatus: 'active',
      );
      expect(user2.isSalesManager, isTrue);

      const user3 = AuthenticatedUser(
        id: 3,
        name: 'Taylor',
        email: 'taylor@gac.com',
        userType: 'SALES_MANAGER',
        accountStatus: 'active',
      );
      expect(user3.isSalesManager, isTrue);

      const regularUser = AuthenticatedUser(
        id: 4,
        name: 'Sam',
        email: 'sam@gac.com',
        userType: 'PIC',
        accountStatus: 'active',
      );
      expect(regularUser.isSalesManager, isFalse);
    });

    test('AuthenticatedUser recognizes all Aftersales checker roles', () {
      const asm = AuthenticatedUser(
        id: 11,
        name: 'Carlo',
        email: 'carlo@gateway.com',
        userType: 'ASM',
        accountStatus: 'active',
      );
      expect(asm.isAftersalesManager, isTrue);
      expect(asm.isAftersalesChecker, isTrue);
      expect(asm.isDosAuditor, isTrue);

      const ce = AuthenticatedUser(
        id: 12,
        name: 'Maria',
        email: 'maria@gateway.com',
        userType: 'CE Service',
        accountStatus: 'active',
      );
      expect(ce.isAftersalesManager, isFalse);
      expect(ce.isAftersalesChecker, isTrue);
      expect(ce.isDosAuditor, isTrue);

      const jc = AuthenticatedUser(
        id: 13,
        name: 'David',
        email: 'david@gateway.com',
        userType: 'Job Controller',
        accountStatus: 'active',
      );
      expect(jc.isAftersalesChecker, isTrue);
      expect(jc.isDosAuditor, isTrue);

      const parts = AuthenticatedUser(
        id: 14,
        name: 'Peter',
        email: 'peter@gateway.com',
        userType: 'Parts Supervisor',
        accountStatus: 'active',
      );
      expect(parts.isAftersalesChecker, isTrue);
      expect(parts.isDosAuditor, isTrue);

      const workshopSupervisor = AuthenticatedUser(
        id: 15,
        name: 'William',
        email: 'william@gateway.com',
        userType: 'WS SUP',
        accountStatus: 'active',
      );
      expect(workshopSupervisor.isAftersalesChecker, isTrue);
      expect(workshopSupervisor.isDosAuditor, isTrue);
    });

    test('ChecklistResponseData loads Property Management and legacy escalation values', () {
      final current = ChecklistResponseData.fromJson({
        'item_key': 'dos-1',
        'status': 'no',
        'commitment_date': '2026-09-15 14:35',
        'details': <String, dynamic>{},
        'escalation': 'Property Management (PM)',
      });
      final legacy = ChecklistResponseData.fromJson({
        'item_key': 'dos-1',
        'status': 'no',
        'details': <String, dynamic>{},
        'escalation': 'PM (Purchasing Manager)',
      });

      expect(current.escalation, 'Property Management (PM)');
      expect(current.commitmentDate, '2026-09-15 14:35');
      expect(legacy.escalation, 'PM (Purchasing Manager)');
    });

    test('dosAftersalesTemplate has all 75 Aftersales Standards across 15 coverages', () {
      final totalItems = dosAftersalesTemplate.fold<int>(
        0,
        (sum, sec) => sum + sec.items.length,
      );
      expect(totalItems, 75);
      expect(dosAftersalesTemplate.length, 15);

      final allItems = dosAftersalesTemplate.expand((s) => s.items).toList();
      expect(allItems.length, 75);

      // Categories verification: Basic (8), Standard (63), Beyond (4) = 75
      final basicItems = allItems.where((i) => i.level == 'Basic').toList();
      final standardItems = allItems
          .where((i) => i.level == 'Standard')
          .toList();
      final beyondItems = allItems.where((i) => i.level == 'Beyond').toList();

      expect(basicItems.length, 8);
      expect(standardItems.length, 63);
      expect(beyondItems.length, 4);

      // Checker distribution verification after Workshop Supervisor consolidation.
      final asmItems = allItems.where((i) => i.checker == 'ASM').toList();
      final ceItems = allItems.where((i) => i.checker == 'CE SERVICE').toList();
      final partsItems = allItems
          .where((i) => i.checker == 'Parts Supervisor')
          .toList();
      final jcItems = allItems.where((i) => i.checker == 'JC').toList();
      final workshopSupervisorItems = allItems
          .where((i) => i.checker == 'WS SUP')
          .toList();
      final legacyWorkshopItems = allItems
          .where((i) => i.checker == 'WS' || i.checker == 'WORSHOP SUP')
          .toList();

      expect(asmItems.length, 50);
      expect(ceItems.length, 9);
      expect(partsItems.length, 3);
      expect(jcItems.length, 1);
      expect(workshopSupervisorItems.length, 12);
      expect(legacyWorkshopItems, isEmpty);

      for (final item in allItems) {
        expect(item.howToCheck, isNotNull);
        expect(item.howToCheck!.isNotEmpty, isTrue);
        expect(item.bomTask, isNotNull);
        expect(item.bomTask!.isNotEmpty, isTrue);
      }

      // Verify embedded subform items have detailed checklist guidance
      final subformItems = allItems
          .where((i) => i.howToCheck!.contains('Subform'))
          .toList();
      expect(subformItems.isNotEmpty, isTrue);
    });

    test('dosTemplate has all 90 Sales Standards with HowToCheck guidance', () {
      final totalItems = dosTemplate.fold<int>(
        0,
        (sum, sec) => sum + sec.items.length,
      );
      expect(totalItems, 90);

      expect(dosTemplate, hasLength(13));

      final firstItem = dosTemplate.first.items.first;
      expect(firstItem.level, 'Basic');
      expect(firstItem.coverage, 'Facilities');
      expect(firstItem.subject, 'Facade');
      expect(firstItem.escalation, 'PM');
      expect(firstItem.bomTask, contains('Accomplish Inspection Request'));
      expect(firstItem.howToCheck, contains('MMPC VI Standard Requirements'));

      final allItems = dosTemplate.expand((s) => s.items).toList();
      expect(allItems.length, 90);

      final itemNumbers =
          allItems
              .map(
                (item) => int.parse(item.id.replaceAll(RegExp(r'[^0-9]'), '')),
              )
              .toList()
            ..sort();
      expect(itemNumbers, List<int>.generate(90, (index) => index + 1));
      expect(allItems.map((item) => item.id).toSet(), hasLength(90));

      final basicItems = allItems.where((i) => i.level == 'Basic').toList();
      final standardItems = allItems
          .where((i) => i.level == 'Standard')
          .toList();
      final beyondItems = allItems.where((i) => i.level == 'Beyond').toList();

      expect(basicItems, hasLength(14));
      expect(standardItems, hasLength(66));
      expect(beyondItems, hasLength(10));

      for (final item in allItems) {
        expect(item.checker, 'SALES MANAGER');
        expect(item.howToCheck, isNotNull);
        expect(item.howToCheck!.isNotEmpty, isTrue);
      }

      final itemsByNumber = {
        for (final item in allItems)
          int.parse(item.id.replaceAll(RegExp(r'[^0-9]'), '')): item,
      };
      expect(itemsByNumber[6]!.bomTask, isNull);
      expect(itemsByNumber[6]!.escalation, isNull);
      expect(
        itemsByNumber[6]!.howToCheck,
        '1. Check through observation if compliant',
      );
      expect(itemsByNumber[64]!.text, contains('Dealer’s copy'));
      expect(itemsByNumber[64]!.howToCheck, contains('choose (3) samples'));
      expect(
        itemsByNumber[90]!.howToCheck,
        '1. Check if PIC submitted monthly report',
      );
    });
  });

  group('DosDashboardScreen Widget Tests', () {
    testWidgets(
      'renders Sales Manager dashboard and reacts to navigation triggers',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool auditOpened = false;
        bool fiveSOpened = false;

        final user = const AuthenticatedUser(
          id: 101,
          name: 'Roberto Gomez',
          email: 'roberto@gateway.com',
          userType: 'Sales Manager',
          accountStatus: 'active',
          branch: 'Gateway Balintawak',
        );

        final repo = _FakeChecklistRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: DosDashboardScreen(
              user: user,
              repository: repo,
              onOpenAudit: () => auditOpened = true,
              onOpen5S: () => fiveSOpened = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Roberto Gomez'), findsOneWidget);
        expect(find.text('SALES MANAGER'), findsOneWidget);
        expect(find.text('DOS COMPLIANCE'), findsOneWidget);
        expect(find.text('5S COMPLIANCE'), findsOneWidget);
        expect(find.text('DEALER OPERATION STANDARDS'), findsOneWidget);
        expect(
          find.text('Sales Standards Compliance Audit (REV02)'),
          findsOneWidget,
        );
        expect(find.text('SCORECARD · SALES MANAGER'), findsOneWidget);
        expect(find.text('ESCALATION & ACTION CENTER'), findsNothing);
        final launchButtonFinder = find.text('LAUNCH SALES STANDARDS AUDIT');
        await tester.ensureVisible(launchButtonFinder);
        expect(launchButtonFinder, findsOneWidget);

        await tester.tap(find.text('5S COMPLIANCE'));
        await tester.pump();
        expect(fiveSOpened, isTrue);

        await tester.tap(launchButtonFinder);
        await tester.pump();
        expect(auditOpened, isTrue);
      },
    );

    testWidgets(
      'renders Aftersales Manager dashboard with 75 standards and checker filtering',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool auditOpened = false;
        String? auditSlugOpened;

        const user = AuthenticatedUser(
          id: 201,
          name: 'Carlo Mendoza',
          email: 'carlo.asm@gateway.com',
          userType: 'ASM',
          accountStatus: 'active',
          branch: 'Gateway Balintawak',
        );

        final repo = _FakeChecklistRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: DosDashboardScreen(
              user: user,
              repository: repo,
              onOpenAuditWithSlug: (slug) {
                auditOpened = true;
                auditSlugOpened = slug;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Header verification for ASM
        expect(find.text('Carlo Mendoza'), findsOneWidget);
        expect(find.text('AFTERSALES MANAGER'), findsOneWidget);

        // Dedicated track banner for non-admin Aftersales user
        expect(
          find.text('DEALER OPERATIONS STANDARDS — AFTERSALES'),
          findsOneWidget,
        );

        // Banner verification for Aftersales
        expect(
          find.text('Aftersales Standards Compliance Audit (FY25)'),
          findsOneWidget,
        );
        expect(
          find.text('75 Standards · 15 Coverages · 5 Checker Roles'),
          findsOneWidget,
        );

        // Category breakdown
        expect(find.text('BASIC'), findsOneWidget);
        expect(find.text('STANDARD'), findsOneWidget);
        expect(find.text('BEYOND'), findsOneWidget);

        // ASM user sees their scoped filter chips
        expect(find.text('ASM (50)'), findsOneWidget);
        expect(find.text('ALL (75)'), findsOneWidget);

        // Scorecard initially filters to ASM
        expect(find.text('SCORECARD · ASM'), findsOneWidget);
        expect(find.text('ESCALATION & ACTION CENTER'), findsNothing);

        // Reset filter via ALL (75)
        await tester.tap(find.text('ALL (75)'));
        await tester.pumpAndSettle();
        expect(find.text('COMPLIANCE SCORECARD'), findsOneWidget);

        // Filter back to ASM (50)
        await tester.tap(find.text('ASM (50)'));
        await tester.pumpAndSettle();
        expect(find.text('SCORECARD · ASM'), findsOneWidget);

        // Launch button for Aftersales
        final launchButtonFinder = find.text(
          'LAUNCH AFTERSALES STANDARDS AUDIT',
        );
        await tester.scrollUntilVisible(
          launchButtonFinder,
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(launchButtonFinder, findsOneWidget);

        await tester.tap(launchButtonFinder);
        await tester.pump();
        expect(auditOpened, isTrue);
        expect(auditSlugOpened, 'dealer-operations-standards');
      },
    );

    testWidgets(
      'renders Admin dashboard with full track switcher between Sales and Aftersales',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const adminUser = AuthenticatedUser(
          id: 999,
          name: 'Super Admin',
          email: 'admin@gateway.com',
          userType: 'ADMIN',
          accountStatus: 'active',
        );

        final repo = _FakeChecklistRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: DosDashboardScreen(user: adminUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        // Track switcher pills available for Admin
        expect(find.text('AFTERSALES (75)'), findsOneWidget);
        expect(find.text('SALES (90)'), findsOneWidget);

        // Admin has access to all checker filters for Aftersales
        expect(find.text('ALL (75)'), findsOneWidget);
        expect(find.text('ASM (50)'), findsOneWidget);
        expect(find.text('CE SERVICE (9)'), findsOneWidget);
        expect(find.text('PARTS (3)'), findsOneWidget);
        expect(find.text('JC (1)'), findsOneWidget);
        expect(find.text('WS SUP (12)'), findsOneWidget);
        expect(find.text('WS (11)'), findsNothing);

        // Filter by Workshop Supervisor.
        final workshopSupervisorFilter = find.text('WS SUP (12)');
        await tester.ensureVisible(workshopSupervisorFilter);
        await tester.tap(workshopSupervisorFilter);
        await tester.pumpAndSettle();
        expect(find.text('SCORECARD · WS SUP'), findsOneWidget);
        expect(find.text('6 audit standards'), findsOneWidget);
        expect(find.text('2 audit standards'), findsOneWidget);
        expect(find.text('1 audit standards'), findsOneWidget);
        expect(find.text('3 audit standards'), findsOneWidget);

        // Switch to Sales (90)
        final salesTrack = find.text('SALES (90)');
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
        await tester.pumpAndSettle();
        await tester.tap(salesTrack);
        await tester.pumpAndSettle();
        expect(
          find.text('Sales Standards Compliance Audit (REV02)'),
          findsOneWidget,
        );

        // Switch back to Aftersales (75)
        await tester.tap(find.text('AFTERSALES (75)'));
        await tester.pumpAndSettle();
        expect(
          find.text('Aftersales Standards Compliance Audit (FY25)'),
          findsOneWidget,
        );
      },
    );
  });

  group('DosTabsLayout Navigation Tests', () {
    testWidgets(
      'renders the user task dashboard first with exactly 3 bottom nav items',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final profileRepo = _FakeProfileRepository();
        final checklistRepo = _FakeChecklistRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: DosTabsLayout(
              profileRepository: profileRepo,
              checklistRepository: checklistRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Exactly 3 bottom navigation icons: Home, Checklist, Profile
        final navigationBar = find.byKey(
          const ValueKey('dos-bottom-navigation-bar'),
        );
        expect(
          find.descendant(
            of: navigationBar,
            matching: find.byIcon(Icons.home_rounded),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: navigationBar,
            matching: find.byIcon(Icons.fact_check_outlined),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: navigationBar,
            matching: find.byIcon(Icons.person_outline_rounded),
          ),
          findsOneWidget,
        );

        // DOS login lands on the same assigned-task dashboard as Utilities.
        expect(find.text('Select date'), findsOneWidget);
        expect(find.text("Today's assigned tasks"), findsOneWidget);
        expect(
          find.text('Dealer Operations Standards - Sales'),
          findsOneWidget,
        );
        expect(find.text('0 / 90 checks completed'), findsOneWidget);
        expect(find.text('Restroom Checklist'), findsNothing);
        expect(find.text('5S COMPLIANCE'), findsNothing);

        // Tap on Profile tab (index 2)
        await tester.tap(find.byIcon(Icons.person_outline_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Profile'), findsWidgets);

        // Bottom navigation bar is hidden outside the Home tab.
        expect(
          find.byKey(const ValueKey('dos-bottom-navigation-bar')),
          findsNothing,
        );

        // Header back button on Profile navigates back to Home.
        await tester.tap(find.byKey(const ValueKey('profile-back-button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('dos-bottom-navigation-bar')),
          findsOneWidget,
        );

        // Open Checklist tab (index 1)
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('dos-bottom-navigation-bar')),
            matching: find.byIcon(Icons.fact_check_outlined),
          ),
        );
        await tester.pumpAndSettle();

        // Bottom navigation bar is hidden on Checklist tab as well.
        expect(
          find.byKey(const ValueKey('dos-bottom-navigation-bar')),
          findsNothing,
        );

        // Shows the distributed DOS category checklists.
        expect(find.text('BY CATEGORY'), findsOneWidget);
        expect(find.text('Basic Standards Checklist'), findsOneWidget);
        expect(find.text('Standard Standards Checklist'), findsOneWidget);
        expect(find.text('Beyond Standards Checklist'), findsOneWidget);
        expect(find.text('Dealer Operations Standards — Sales'), findsWidgets);

        // Header back button on Checklist screen returns to Home.
        await tester.tap(find.byKey(const ValueKey('checklist-back-button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('dos-bottom-navigation-bar')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders Aftersales Audit for Aftersales user and navigates between tabs',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final profileRepo = _FakeAftersalesProfileRepository();
        final checklistRepo = _FakeChecklistRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: DosTabsLayout(
              profileRepository: profileRepo,
              checklistRepository: checklistRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The Aftersales account lands on its role-scoped dashboard assignment.
        expect(
          find.text('Dealer Operations Standards - Aftersales'),
          findsOneWidget,
        );
        expect(find.text('0 / 50 checks completed'), findsOneWidget);
        expect(find.text('Dealer Operations Standards - Sales'), findsNothing);
        expect(find.text('Restroom Checklist'), findsNothing);

        // The checklist tab opens the Aftersales category checklists.
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('dos-bottom-navigation-bar')),
            matching: find.byIcon(Icons.fact_check_outlined),
          ),
        );
        await tester.pumpAndSettle();

        // Bottom nav bar is hidden outside the Home tab.
        expect(
          find.byKey(const ValueKey('dos-bottom-navigation-bar')),
          findsNothing,
        );

        // Shows distributed category checklists for Aftersales.
        expect(find.text('BY CATEGORY'), findsOneWidget);
        expect(find.text('Basic Standards Checklist'), findsOneWidget);
        expect(find.text('Standard Standards Checklist'), findsOneWidget);
        expect(
          find.text('Dealer Operations Standards — Aftersales'),
          findsWidgets,
        );

        // Tapping the Basic standards card opens the Aftersales audit view scoped to Basic.
        await tester.tap(find.text('Basic Standards Checklist'));
        await tester.pumpAndSettle();
        expect(
          find.text('DEALER OPERATIONS STANDARDS — AFTERSALES — BASIC'),
          findsNothing,
        );
        expect(find.text('Aftersales Audit'), findsOneWidget);
        expect(find.text('Basic · Audit Compliance App'), findsOneWidget);
        expect(find.byKey(const ValueKey('user-checklist-top-bar')), findsOneWidget);
      },
    );

    testWidgets(
      'Audit view leading back button cleanly navigates back to Home (DOS Dashboard) without black screen',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final profileRepo = _FakeAftersalesProfileRepository();
        final checklistRepo = _FakeChecklistRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: DosTabsLayout(
              initialIndex: 1,
              profileRepository: profileRepo,
              checklistRepository: checklistRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Explicit audit routes still open Checklist (Tab 1).
        final backButton = find.byTooltip('Back to checklists');
        expect(backButton, findsOneWidget);

        // Tap the back button
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Cleanly navigates back to the assigned-work Home dashboard.
        expect(find.text('Select date'), findsOneWidget);
        expect(
          find.text('Dealer Operations Standards - Aftersales'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'UserChecklistDetailScreen filters sections and items strictly based on checker role',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const ceUser = AuthenticatedUser(
          id: 301,
          name: 'CE Officer',
          email: 'ce@gateway.com',
          userType: 'CE Service',
          accountStatus: 'active',
        );

        final repo = _FakeChecklistRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: Scaffold(
              body: UserChecklistDetailScreen(
                slug: 'dealer-operations-standards',
                repository: repo,
                user: ceUser,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // CE Service items should be visible (there are 9 CE Service items)
        // Items assigned exclusively to other checkers should be omitted.
        expect(
          find.textContaining('CE SERVICE', findRichText: true),
          findsWidgets,
        );
      },
    );

    testWidgets('legacy workshop checker labels render only as WS SUP', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const workshopSupervisor = AuthenticatedUser(
        id: 302,
        name: 'Workshop Supervisor',
        email: 'workshop.supervisor@gateway.com',
        userType: 'WS SUP',
        accountStatus: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards',
            repository: _FakeChecklistRepository(workshopCheckerOverride: 'WS'),
            user: workshopSupervisor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 1 OF 12'), findsOneWidget);
      expect(find.text('CHECKER: WS SUP'), findsOneWidget);
      expect(find.text('Checker: WS SUP'), findsOneWidget);
      expect(find.text('CHECKER: WS'), findsNothing);
      expect(find.text('Checker: WS'), findsNothing);
    });

    testWidgets(
      'DOS checklist shows one question at a time and moves to the next question',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const smUser = AuthenticatedUser(
          id: 101,
          name: 'Sales Manager',
          email: 'sm@gateway.com',
          userType: 'SALES_MANAGER',
          accountStatus: 'active',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-sales',
              repository: _FakeChecklistRepository(),
              user: smUser,
            ),
          ),
        );
        await tester.pumpAndSettle();

        const firstPrompt =
            'Fascia or badge sign and letterings are complete, undamaged, clean, no watermarks, no obstructions, no discoloration and stains';
        const secondPrompt =
            'Pylon (Single/Two-Post / Tower / Wall Projecting) sign/s and letterings are complete, undamaged, clean, no watermarks, no obstructions, no discoloration and stains';

        expect(find.byKey(const ValueKey('dos-question-flow')), findsOneWidget);
        expect(find.text('QUESTION 1 OF 90'), findsOneWidget);
        expect(find.text(firstPrompt), findsOneWidget);
        expect(find.text(secondPrompt), findsNothing);

        await tester.tap(find.byKey(const ValueKey('dos-1-response-yes')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('dos-next-question')));
        await tester.pumpAndSettle();

        expect(find.text('QUESTION 2 OF 90'), findsOneWidget);
        expect(find.text(firstPrompt), findsNothing);
        expect(find.text(secondPrompt), findsOneWidget);
        expect(
          find.byKey(const ValueKey('dos-2-response-yes')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dos-previous-question')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Sales standards that share Aftersales subform row numbers stay normal questions',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const smUser = AuthenticatedUser(
          id: 101,
          name: 'Sales Manager',
          email: 'sm@gateway.com',
          userType: 'SALES_MANAGER',
          accountStatus: 'active',
        );
        final orderedItems =
            dosTemplate.expand((section) => section.items).toList()
              ..sort((left, right) {
                final leftNumber = int.parse(
                  left.id.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                final rightNumber = int.parse(
                  right.id.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                return leftNumber.compareTo(rightNumber);
              });

        for (final rowNumber in const [23, 27, 53, 54, 55]) {
          final questionIndex = orderedItems.indexWhere(
            (item) => item.id == 'dos-$rowNumber',
          );
          expect(questionIndex, isNonNegative);

          await tester.pumpWidget(
            MaterialApp(
              theme: GacTheme.light,
              home: UserChecklistDetailScreen(
                key: ValueKey('sales-standard-$rowNumber'),
                slug: 'dealer-operations-standards-sales',
                repository: _FakeChecklistRepository(),
                user: smUser,
                initialQuestionIndex: questionIndex,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('ELIGIBILITY AUDIT'), findsNothing);
          expect(
            find.byKey(ValueKey('dos-$rowNumber-response-yes')),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets('DOS question navigation continues across a section boundary', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const smUser = AuthenticatedUser(
        id: 101,
        name: 'Sales Manager',
        email: 'sm@gateway.com',
        userType: 'SALES_MANAGER',
        accountStatus: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards-sales',
            repository: _FakeChecklistRepository(),
            user: smUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var question = 1; question < 7; question++) {
        await tester.tap(find.byKey(ValueKey('dos-$question-response-yes')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('dos-next-question')));
        await tester.pumpAndSettle();
      }

      expect(find.text('QUESTION 7 OF 90'), findsOneWidget);
      expect(
        find.text(
          'PWD parking slot and ramp with railings should be unobstructed and painted with standard PWD Logo.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Test drive vehicle are maintained clean, fully functional and is readily available for use.',
        ),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('dos-7-response-yes')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dos-next-question')));
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 8 OF 90'), findsOneWidget);
      expect(
        find.text(
          'PWD parking slot and ramp with railings should be unobstructed and painted with standard PWD Logo.',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Test drive vehicle are maintained clean, fully functional and is readily available for use.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'DOS Sales item exposes its workbook guide without escalation or commitment controls',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const smUser = AuthenticatedUser(
          id: 101,
          name: 'Sales Manager',
          email: 'sm@gateway.com',
          userType: 'SALES_MANAGER',
          accountStatus: 'active',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-sales',
              repository: _FakeChecklistRepository(),
              user: smUser,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('dos-1-how-to-check')));
        await tester.pumpAndSettle();

        expect(find.text('HOW TO CHECK GUIDE'), findsOneWidget);
        expect(find.text('VERIFICATION INSTRUCTIONS'), findsOneWidget);
        expect(
          find.textContaining('MMPC VI Standard Requirements'),
          findsOneWidget,
        );

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('dos-1-response-no')));
        await tester.pumpAndSettle();

        expect(find.text('Defect photo (optional)'), findsOneWidget);
        expect(
          find.text('BOM TASKS (MEASURES IF NOT CONDUCTED)'),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('dos-action-plan-field')),
          findsNothing,
        );
        expect(find.textContaining('Escalate:'), findsNothing);
        expect(find.byKey(const ValueKey('dos-escalation-pm')), findsNothing);
        expect(
          find.byKey(const ValueKey('dos-commitment-date-time')),
          findsNothing,
        );

        await tester.tap(find.byKey(const ValueKey('dos-1-response-na')));
        await tester.pumpAndSettle();

        expect(find.text('Reason for N/A (required)'), findsOneWidget);
        expect(find.text('Defect photo (optional)'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('dos-action-plan-field')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'UserChecklistDetailScreen removes action plan, commitment date, and escalation for admin user',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const adminUser = AuthenticatedUser(
          id: 999,
          name: 'Compliance Admin',
          email: 'admin@gateway.com',
          userType: 'ADMIN',
          accountStatus: 'active',
        );
        final repo = _FakeChecklistRepository()
          ..initialSubmission = const ChecklistSubmissionData(
            id: 45,
            status: 'draft',
            auditDate: '2026-09-15',
            templateVersion: 1,
            scores: {},
            responses: {
              'dos-1': ChecklistResponseData(
                itemId: 1,
                itemKey: 'dos-1',
                status: 'no',
                remark: null,
                finding: 'Damaged fascia lettering',
                actionPlan: null,
                commitmentDate: null,
                details: {},
                attachmentPath: null,
                attachmentUrl: null,
              ),
            },
            answeredItems: 1,
            totalItems: 90,
            issueCount: 1,
            completionPercentage: 1,
            submittedAt: null,
          );

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-sales',
              repository: repo,
              user: adminUser,
              initialQuestionIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('dos-finding-field')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('dos-action-plan-field')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('dos-commitment-date-time')),
          findsNothing,
        );
        expect(
          find.text('BOM TASKS (MEASURES IF NOT CONDUCTED)'),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('dos-escalation-pm')), findsNothing);

        await tester.enterText(
          find.byKey(const ValueKey('dos-finding-field')),
          'Updated finding explanation',
        );
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pumpAndSettle();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        final payload = repo.savedResponses!.single;
        expect(payload['finding'], 'Updated finding explanation');
        expect(payload['action_plan'], isNull);
        expect(payload['commitment_date'], isNull);
      },
    );

    testWidgets(
      'DOS Aftersales item omits escalation and commitment controls',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const asmUser = AuthenticatedUser(
          id: 201,
          name: 'Aftersales Manager',
          email: 'asm@gateway.com',
          userType: 'ASM',
          accountStatus: 'active',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards',
              repository: _FakeChecklistRepository(),
              user: asmUser,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('dos-as-1-response-no')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('dos-action-plan-field')),
          findsNothing,
        );
        expect(
          find.text('BOM TASKS (MEASURES IF NOT CONDUCTED)'),
          findsNothing,
        );
        expect(find.textContaining('Escalate:'), findsNothing);
        expect(
          find.byKey(const ValueKey('dos-escalation-as-brand-head')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('dos-commitment-date-time')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'DOS next question requires only a NO finding without action plan or commitment date for Sales Manager',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const smUser = AuthenticatedUser(
          id: 101,
          name: 'Sales Manager',
          email: 'sm@gateway.com',
          userType: 'SALES_MANAGER',
          accountStatus: 'active',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-sales',
              repository: _FakeChecklistRepository(),
              user: smUser,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final nextButtonFinder = find.byKey(
          const ValueKey('dos-next-question'),
        );
        expect(nextButtonFinder, findsOneWidget);

        // Initially no choice has been selected: NEXT QUESTION button is disabled (onPressed == null)
        FilledButton nextButton = tester.widget<FilledButton>(nextButtonFinder);
        expect(nextButton.onPressed, isNull);

        // Select YES: NEXT QUESTION button becomes enabled
        await tester.tap(find.byKey(const ValueKey('dos-1-response-yes')));
        await tester.pumpAndSettle();

        nextButton = tester.widget<FilledButton>(nextButtonFinder);
        expect(nextButton.onPressed, isNotNull);

        // Select N/A: NEXT QUESTION button is disabled because reason for N/A is blank
        await tester.tap(find.byKey(const ValueKey('dos-1-response-na')));
        await tester.pumpAndSettle();

        nextButton = tester.widget<FilledButton>(nextButtonFinder);
        expect(nextButton.onPressed, isNull);

        // Fill reason for N/A: NEXT QUESTION button becomes enabled
        final naReasonFinder = find.byKey(const ValueKey('dos-finding-field'));
        expect(naReasonFinder, findsOneWidget);
        await tester.enterText(
          naReasonFinder,
          'Branch does not have a pylon sign',
        );
        await tester.pumpAndSettle();

        nextButton = tester.widget<FilledButton>(nextButtonFinder);
        expect(nextButton.onPressed, isNotNull);

        // Clearing reason for N/A disables the next button again
        await tester.enterText(naReasonFinder, '   ');
        await tester.pumpAndSettle();

        nextButton = tester.widget<FilledButton>(nextButtonFinder);
        expect(nextButton.onPressed, isNull);

        // Select NO: NEXT QUESTION button is disabled because Finding is blank
        await tester.tap(find.byKey(const ValueKey('dos-1-response-no')));
        await tester.pumpAndSettle();

        nextButton = tester.widget<FilledButton>(nextButtonFinder);
        expect(nextButton.onPressed, isNull);

        // Action plan and commitment date fields are completely omitted for Sales Manager
        expect(
          find.byKey(const ValueKey('dos-action-plan-field')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('dos-commitment-date-time')),
          findsNothing,
        );
        expect(
          find.text('BOM TASKS (MEASURES IF NOT CONDUCTED)'),
          findsNothing,
        );

        // Entering finding alone enables the next button
        final findingFieldFinder = find.byKey(
          const ValueKey('dos-finding-field'),
        );
        expect(findingFieldFinder, findsOneWidget);
        await tester.enterText(findingFieldFinder, 'Defective sign lettering');
        await tester.pumpAndSettle();

        nextButton = tester.widget<FilledButton>(nextButtonFinder);
        expect(nextButton.onPressed, isNotNull);

        // Clearing finding disables the next button again
        await tester.enterText(findingFieldFinder, '   ');
        await tester.pumpAndSettle();

        nextButton = tester.widget<FilledButton>(nextButtonFinder);
        expect(nextButton.onPressed, isNull);

        // Restoring finding re-enables the next button and allows advancing
        await tester.enterText(findingFieldFinder, 'Defective sign lettering');
        await tester.pumpAndSettle();

        nextButton = tester.widget<FilledButton>(nextButtonFinder);
        expect(nextButton.onPressed, isNotNull);

        await tester.ensureVisible(nextButtonFinder);
        await tester.pumpAndSettle();
        await tester.tap(nextButtonFinder);
        await tester.pumpAndSettle();

        expect(find.text('QUESTION 2 OF 90'), findsOneWidget);

        // Question 2 is unanswered, so NEXT QUESTION is disabled again
        nextButton = tester.widget<FilledButton>(nextButtonFinder);
        expect(nextButton.onPressed, isNull);
      },
    );

    testWidgets(
      'DOS YES NO and N/A response buttons are at least 60 pixels tall on a compact phone',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const smUser = AuthenticatedUser(
          id: 101,
          name: 'Sales Manager',
          email: 'sm@gateway.com',
          userType: 'SALES_MANAGER',
          accountStatus: 'active',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-sales',
              repository: _FakeChecklistRepository(),
              user: smUser,
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (final response in const ['yes', 'no', 'na']) {
          final button = find.byKey(ValueKey('dos-1-response-$response'));
          expect(button, findsOneWidget);
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          expect(tester.getSize(button).height, greaterThanOrEqualTo(60));
        }

        final questionScroll = find.descendant(
          of: find.byKey(const ValueKey('dos-question-flow')),
          matching: find.byType(Scrollable),
        ).first;
        await tester.drag(questionScroll, const Offset(0, -180));
        await tester.pumpAndSettle();
        expect(
          tester.widget<UserChecklistFloatingHeader>(
            find.byType(UserChecklistFloatingHeader),
          ).expanded,
          isFalse,
        );
        await tester.tap(find.byKey(const ValueKey('checklist-header-title')));
        await tester.pumpAndSettle();
        expect(tester.state<ScrollableState>(questionScroll).position.pixels, 0);
        expect(
          tester.widget<UserChecklistFloatingHeader>(
            find.byType(UserChecklistFloatingHeader),
          ).expanded,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'UserChecklistDetailScreen removes SAVE DRAFT button and places SUBMIT button at top',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const smUser = AuthenticatedUser(
          id: 101,
          name: 'Sales Manager',
          email: 'sm@gateway.com',
          userType: 'SALES_MANAGER',
          accountStatus: 'active',
        );

        final repo = _FakeChecklistRepository();
        var notificationsOpened = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-sales',
              repository: repo,
              user: smUser,
              onOpenNotifications: () => notificationsOpened = true,
              unreadNotifications: 3,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // SAVE DRAFT button is completely removed on Sales and Aftersales tabs
        expect(find.text('SAVE DRAFT'), findsNothing);

        // SUBMIT button is located at the top header card
        expect(
          find.byKey(const ValueKey('checklist-header-submit-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('checklist-appbar-submit-button')),
          findsNothing,
        );

        // The shared floating header replaces the redundant track banner.
        expect(
          find.text('DEALER OPERATIONS STANDARDS — SALES'),
          findsNothing,
        );
        expect(find.text('Sales Audit'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('user-header-notifications')));
        expect(notificationsOpened, isTrue);
        expect(find.byKey(const ValueKey('user-checklist-top-bar')), findsOneWidget);
      },
    );

    testWidgets(
      'UserChecklistDetailScreen automatically saves draft on app exit and shows popup below',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const smUser = AuthenticatedUser(
          id: 101,
          name: 'Sales Manager',
          email: 'sm@gateway.com',
          userType: 'SALES_MANAGER',
          accountStatus: 'active',
        );

        final repo = _FakeChecklistRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-sales',
              repository: repo,
              user: smUser,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap YES on the first item to make changes
        final yesButton = find.text('YES').first;
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        // Simulate the user exiting/backgrounding the application
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        // Auto-save was triggered automatically
        expect(repo.savedSlug, 'dealer-operations-standards-sales');
        expect(repo.savedResponses, isNotNull);

        // Popup below confirms the checklist is saved
        expect(find.text('Checklist saved'), findsOneWidget);
      },
    );

    testWidgets(
      'dedicated DOS users discard legacy escalation and commitment draft data',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const smUser = AuthenticatedUser(
          id: 101,
          name: 'Sales Manager',
          email: 'sm@gateway.com',
          userType: 'SALES_MANAGER',
          accountStatus: 'active',
        );
        final repo = _FakeChecklistRepository()
          ..initialSubmission = const ChecklistSubmissionData(
            id: 44,
            status: 'draft',
            auditDate: '2026-09-15',
            templateVersion: 1,
            scores: {},
            responses: {
              'dos-1': ChecklistResponseData(
                itemId: 1,
                itemKey: 'dos-1',
                status: 'no',
                remark: null,
                finding: 'Damaged fascia lettering',
                actionPlan: 'Replace the damaged lettering',
                commitmentDate: '2026-09-15 14:35',
                details: {'escalation': 'Inventory'},
                attachmentPath: null,
                attachmentUrl: null,
              ),
            },
            answeredItems: 1,
            totalItems: 90,
            issueCount: 1,
            completionPercentage: 5,
            submittedAt: null,
          );

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-sales',
              repository: repo,
              user: smUser,
              initialQuestionIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Commitment: 2026-09-15 14:35'), findsNothing);
        expect(
          find.byKey(const ValueKey('dos-commitment-date-time')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('dos-escalation-inventory')),
          findsNothing,
        );

        expect(
          find.byKey(const ValueKey('dos-action-plan-field')),
          findsNothing,
        );

        await tester.enterText(
          find.byKey(const ValueKey('dos-finding-field')),
          'Replace the damaged lettering and verify installation',
        );
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pumpAndSettle();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        final payload = repo.savedResponses!.single;
        expect(payload['commitment_date'], isNull);
        expect(payload['action_plan'], isNull);
        expect(payload['details'], isNull);
        expect(payload.containsKey('escalation'), isFalse);
      },
    );

    testWidgets(
      'UserChecklistDetailScreen automatically saves draft when navigating back',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const smUser = AuthenticatedUser(
          id: 101,
          name: 'Sales Manager',
          email: 'sm@gateway.com',
          userType: 'SALES_MANAGER',
          accountStatus: 'active',
        );

        final repo = _FakeChecklistRepository();
        bool backCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-sales',
              repository: repo,
              user: smUser,
              onBack: () => backCalled = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap YES on the first item
        final yesButton = find.text('YES').first;
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        // Tap back button
        final backButton = find.byTooltip('Back to checklists');
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(backCalled, isTrue);
        expect(repo.savedSlug, 'dealer-operations-standards-sales');
        expect(find.text('Checklist saved'), findsOneWidget);
      },
    );

    testWidgets(
      'UserChecklistDetailScreen track tabs allow switching between Sales and Aftersales and auto-save',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const adminUser = AuthenticatedUser(
          id: 999,
          name: 'Admin',
          email: 'admin@gateway.com',
          userType: 'ADMIN',
          accountStatus: 'active',
        );

        final repo = _FakeChecklistRepository();

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

        // Track tabs rendered for Admin
        expect(find.text('AFTERSALES (75)'), findsOneWidget);
        expect(find.text('SALES (90)'), findsOneWidget);

        // Tap YES on an item
        await tester.tap(find.text('YES').first);
        await tester.pumpAndSettle();

        // Switch to SALES track tab
        await tester.tap(find.text('SALES (90)'));
        await tester.pumpAndSettle();

        // Verify the previous track draft was auto-saved
        expect(repo.savedSlug, 'dealer-operations-standards');
        expect(find.text('Checklist saved'), findsOneWidget);

        // Verify Sales track is now active
        expect(
          find.text('Sales Audit'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Tapping a DOS category card opens category-scoped checklist detail and returns',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final profileRepo = _FakeProfileRepository();
        final checklistRepo = _FakeChecklistRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: DosTabsLayout(
              profileRepository: profileRepo,
              checklistRepository: checklistRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Checklist tab
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('dos-bottom-navigation-bar')),
            matching: find.byIcon(Icons.fact_check_outlined),
          ),
        );
        await tester.pumpAndSettle();

        // Check category cards are displayed
        expect(find.text('BY CATEGORY'), findsOneWidget);
        expect(find.text('Basic Standards Checklist'), findsOneWidget);

        // Tap on Basic Standards Checklist card
        await tester.tap(find.text('Basic Standards Checklist'));
        await tester.pumpAndSettle();

        // Detail screen opens scoped to Basic category
        expect(
          find.text('DEALER OPERATIONS STANDARDS — SALES — BASIC'),
          findsNothing,
        );
        expect(find.text('Sales Audit'), findsOneWidget);
        expect(find.text('Basic · Audit Compliance App'), findsOneWidget);

        // Leading back button in detail view returns to the category distribution list
        final backButton = find.byTooltip('Back to checklists');
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Confirms back on category list
        expect(find.text('BY CATEGORY'), findsOneWidget);
        expect(find.text('Basic Standards Checklist'), findsOneWidget);
        expect(find.text('Standard Standards Checklist'), findsOneWidget);
      },
    );

    testWidgets(
      'completing a DOS category saves its rows as a draft without submitting the master audit',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repository = _FakeChecklistRepository(
          checklistResultOverride: const ChecklistLoadResult(
            template: ChecklistTemplateData(
              id: 2,
              slug: 'dealer-operations-standards',
              name: 'Dealer Operations Standards - Aftersales',
              description: 'Category persistence fixture',
              version: 2,
              settings: {'validation_mode': 'dos'},
              sections: [
                ChecklistSectionData(
                  id: 1,
                  key: 'facilities',
                  title: 'Facilities',
                  sortOrder: 1,
                  metadata: {},
                  items: [
                    ChecklistItemData(
                      id: 101,
                      key: 'basic-1',
                      prompt: 'First basic standard',
                      sortOrder: 1,
                      metadata: {'category': 'Basic', 'number': 1},
                    ),
                    ChecklistItemData(
                      id: 102,
                      key: 'basic-2',
                      prompt: 'Second basic standard',
                      sortOrder: 2,
                      metadata: {'category': 'Basic', 'number': 2},
                    ),
                    ChecklistItemData(
                      id: 103,
                      key: 'standard-1',
                      prompt: 'A standard category item',
                      sortOrder: 3,
                      metadata: {'category': 'Standard', 'number': 3},
                    ),
                  ],
                ),
              ],
            ),
            submission: null,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards',
              categoryFilter: 'Basic',
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('QUESTION 1 OF 2'), findsOneWidget);
        expect(find.text('SAVE'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('basic-1-response-yes')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('dos-next-question')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('basic-2-response-yes')));
        await tester.pump();

        expect(find.text('NEXT CATEGORY'), findsWidgets);
        await tester.tap(find.byKey(const ValueKey('dos-next-question')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(repository.saveDraftCalls, 1);
        expect(repository.submitCalls, 0);
        expect(repository.savedResponses, hasLength(2));
        expect(
          repository.savedResponses!.map((response) => response['item_key']),
          containsAll(<String>['basic-1', 'basic-2']),
        );
        expect(
          repository.savedResponses!.any(
            (response) => response['item_key'] == 'standard-1',
          ),
          isFalse,
        );
        expect(find.text('Category saved'), findsNothing);
        expect(
          find.textContaining('then use Master Audit to submit the full audit'),
          findsNothing,
        );
        expect(
          find.textContaining('Proceeding to Standard standards'),
          findsOneWidget,
        );
        await tester.pumpAndSettle();

        // Standard category is now active, starting at Question 1 of Standard
        expect(find.text('QUESTION 1 OF 1'), findsOneWidget);
        expect(find.text('A standard category item'), findsOneWidget);
        // Since Beyond does not exist in this fixture, Standard is the last category -> button is SUBMIT CHECKLIST
        expect(find.text('SUBMIT CHECKLIST'), findsOneWidget);
      },
    );

    testWidgets(
      'completing all DOS categories turns the final question button into SUBMIT CHECKLIST and submits the full audit',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repository = _FakeChecklistRepository(
          checklistResultOverride: const ChecklistLoadResult(
            template: ChecklistTemplateData(
              id: 2,
              slug: 'dealer-operations-standards',
              name: 'Dealer Operations Standards - Aftersales',
              description: 'Category persistence fixture',
              version: 2,
              settings: {'validation_mode': 'dos'},
              sections: [
                ChecklistSectionData(
                  id: 1,
                  key: 'facilities',
                  title: 'Facilities',
                  sortOrder: 1,
                  metadata: {},
                  items: [
                    ChecklistItemData(
                      id: 101,
                      key: 'basic-1',
                      prompt: 'First basic standard',
                      sortOrder: 1,
                      metadata: {'category': 'Basic', 'number': 1},
                    ),
                    ChecklistItemData(
                      id: 102,
                      key: 'basic-2',
                      prompt: 'Second basic standard',
                      sortOrder: 2,
                      metadata: {'category': 'Basic', 'number': 2},
                    ),
                    ChecklistItemData(
                      id: 103,
                      key: 'standard-1',
                      prompt: 'A standard category item',
                      sortOrder: 3,
                      metadata: {'category': 'Standard', 'number': 3},
                    ),
                  ],
                ),
              ],
            ),
            submission: null,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards',
              categoryFilter: 'Basic',
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Answer Basic questions
        await tester.tap(find.byKey(const ValueKey('basic-1-response-yes')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('dos-next-question')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('basic-2-response-yes')));
        await tester.pump();

        // Advance to Standard
        await tester.tap(find.byKey(const ValueKey('dos-next-question')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Standard is active and is the final category
        expect(find.text('QUESTION 1 OF 1'), findsOneWidget);
        expect(find.text('SUBMIT CHECKLIST'), findsOneWidget);

        // Answer Standard
        await tester.tap(find.byKey(const ValueKey('standard-1-response-yes')));
        await tester.pump();

        // Tap SUBMIT CHECKLIST
        await tester.tap(find.byKey(const ValueKey('dos-next-question')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Audit is submitted!
        expect(repository.submitCalls, 1);
        expect(find.text('Checklist submitted'), findsOneWidget);
      },
    );

    testWidgets(
      'UserTabsLayout shows bottom navigation bar on Home tab and hides it on Checklist and Profile tabs',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final profileRepo = _FakeProfileRepository();
        final checklistRepo = _FakeChecklistRepository();
        final notifications = UserNotificationController(
          repository: _FakeNotificationRepository(),
        );
        await notifications.load();
        addTearDown(notifications.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserTabsLayout(
              profileRepository: profileRepo,
              checklistRepository: checklistRepo,
              notificationController: notifications,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // On Home tab, bottom navigation bar is visible
        expect(
          find.byKey(const ValueKey('user-bottom-navigation-bar')),
          findsOneWidget,
        );

        // Navigate to Checklist tab
        await tester.tap(find.text('Checklist'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Bottom navigation bar is hidden on Checklist tab
        expect(
          find.byKey(const ValueKey('user-bottom-navigation-bar')),
          findsNothing,
        );

        // Tap back button on Checklist screen
        await tester.tap(find.byKey(const ValueKey('checklist-back-button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Returns to Home tab, bottom bar is visible again
        expect(
          find.byKey(const ValueKey('user-bottom-navigation-bar')),
          findsOneWidget,
        );

        // Navigate to Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Bottom navigation bar is hidden on Profile tab
        expect(
          find.byKey(const ValueKey('user-bottom-navigation-bar')),
          findsNothing,
        );

        // Tap back button on Profile screen
        await tester.tap(find.byKey(const ValueKey('profile-back-button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Returns to Home tab, bottom bar is visible again
        expect(
          find.byKey(const ValueKey('user-bottom-navigation-bar')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'UserChecklistDetailScreen removes commitment date, BOM task, and action plan on NO for sm@gateway.com and submits null values for database',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const smUser = AuthenticatedUser(
          id: 107,
          name: 'Marcus Sales',
          email: 'sm@gateway.com',
          userType: 'SALES_MANAGER',
          accountStatus: 'active',
        );

        final initialResponses = <String, ChecklistResponseData>{
          for (var i = 2; i <= 90; i++)
            'dos-$i': ChecklistResponseData(
              itemId: i,
              itemKey: 'dos-$i',
              status: 'yes',
              remark: null,
              finding: null,
              actionPlan: null,
              commitmentDate: null,
              details: const {'eligibility': 'na'},
            ),
        };
        final repo = _FakeChecklistRepository()
          ..initialSubmission = ChecklistSubmissionData(
            id: 1,
            status: 'draft',
            auditDate: '2026-09-05',
            templateVersion: 1,
            scores: const {'overall': 85},
            responses: initialResponses,
            answeredItems: 89,
            totalItems: 90,
            issueCount: 0,
            completionPercentage: 99,
            submittedAt: null,
          );

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-sales',
              repository: repo,
              user: smUser,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select NO on the question
        await tester.tap(find.byKey(const ValueKey('dos-1-response-no')));
        await tester.pumpAndSettle();

        // Finding field is shown
        expect(find.byKey(const ValueKey('dos-finding-field')), findsOneWidget);

        // BOM tasks, Action plan, and Commitment date are all REMOVED
        expect(
          find.text('BOM TASKS (MEASURES IF NOT CONDUCTED)'),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('dos-action-plan-field')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('dos-commitment-date-time')),
          findsNothing,
        );

        // Enter required finding
        await tester.enterText(
          find.byKey(const ValueKey('dos-finding-field')),
          'Signage lettering is missing',
        );
        await tester.pumpAndSettle();

        // Tap submit button in header
        final submitButton = find.byKey(
          const ValueKey('checklist-header-submit-button'),
        );
        expect(submitButton, findsOneWidget);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();
        expect(find.text('Checklist submitted'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(repo.submitCalls, 1);
        final firstResponse = repo.savedResponses!.first;
        expect(firstResponse['status'], 'no');
        expect(firstResponse['finding'], 'Signage lettering is missing');
        expect(firstResponse['action_plan'], isNull);
        expect(firstResponse['commitment_date'], isNull);
      },
    );

    testWidgets(
      'UserChecklistDetailScreen removes commitment date, BOM task, and action plan for all Aftersales accounts (asm, ws, ce, parts, jc, ws.sup)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const aftersalesUsers = [
          AuthenticatedUser(
            id: 108,
            name: 'Carlo Mendoza',
            email: 'asm@gateway.com',
            userType: 'ASM',
            accountStatus: 'active',
          ),
          AuthenticatedUser(
            id: 109,
            name: 'Maria Santos',
            email: 'ce@gateway.com',
            userType: 'CE SERVICE',
            accountStatus: 'active',
          ),
          AuthenticatedUser(
            id: 110,
            name: 'David Cruz',
            email: 'jc@gateway.com',
            userType: 'JOB CONTROLLER',
            accountStatus: 'active',
          ),
          AuthenticatedUser(
            id: 111,
            name: 'Peter Reyes',
            email: 'parts@gateway.com',
            userType: 'PARTS SUPERVISOR',
            accountStatus: 'active',
          ),
          AuthenticatedUser(
            id: 112,
            name: 'William Bautista',
            email: 'ws.sup@gateway.com',
            userType: 'WORKSHOP SUP',
            accountStatus: 'active',
          ),
        ];

        for (final user in aftersalesUsers) {
          final repo = _FakeChecklistRepository();

          await tester.pumpWidget(
            MaterialApp(
              theme: GacTheme.light,
              home: UserChecklistDetailScreen(
                key: ValueKey('test-${user.email}'),
                slug: 'dealer-operations-standards',
                repository: repo,
                user: user,
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Tap NO on first question
          final noButton = find.byKey(const ValueKey('dos-as-1-response-no'));
          if (noButton.evaluate().isNotEmpty) {
            await tester.tap(noButton);
            await tester.pumpAndSettle();

            // Finding is present
            expect(
              find.byKey(const ValueKey('dos-finding-field')),
              findsOneWidget,
              reason: 'Finding field should be present for ${user.email}',
            );

            // BOM Task, Action Plan, and Commitment are ALL removed
            expect(
              find.text('BOM TASKS (MEASURES IF NOT CONDUCTED)'),
              findsNothing,
              reason: 'BOM task should be removed for ${user.email}',
            );
            expect(
              find.byKey(const ValueKey('dos-action-plan-field')),
              findsNothing,
              reason: 'Action plan should be removed for ${user.email}',
            );
            expect(
              find.byKey(const ValueKey('dos-commitment-date-time')),
              findsNothing,
              reason: 'Commitment date should be removed for ${user.email}',
            );
          }
        }
      },
    );
  });
}
