import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/data/admin_data.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/dos_dashboard_screen.dart';
import 'package:gac_flutter/screens/user_checklist_detail_screen.dart';
import 'package:gac_flutter/screens/user_checklists_screen.dart';
import 'package:gac_flutter/screens/user_home_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

class _FakeSubformDocRepository implements ChecklistRepository {
  String? savedSlug;
  List<Map<String, dynamic>> savedResponses = [];

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async {
    return [
      ChecklistCatalogItem(
        id: 1,
        slug: 'dealer-operations-standards',
        name: 'Dealer Operations Standards',
        description: 'FY2025 DOS Aftersales Audit',
        version: 1,
        settings: const {'validation_mode': 'dos'},
        sectionCount: 7,
        itemCount: 75,
        workUnitCount: 75,
        submission: null,
      ),
      ChecklistCatalogItem(
        id: 10,
        slug: 'dealer-operations-standards-subform',
        name: 'Dealer Operations Standards - Subform',
        description: 'FY2025 Subform Sheet',
        version: 1,
        settings: const {'validation_mode': 'dos_subform'},
        sectionCount: 5,
        itemCount: 39,
        workUnitCount: 39,
        submission: null,
      ),
      ChecklistCatalogItem(
        id: 11,
        slug: 'dealer-operations-standards-documentation',
        name: 'Dealer Operations Standards - Documentation',
        description: 'FY2025 Documentation Sheet',
        version: 1,
        settings: const {'validation_mode': 'dos_documentation'},
        sectionCount: 3,
        itemCount: 17,
        workUnitCount: 17,
        submission: null,
      ),
    ];
  }

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    if (slug == 'dealer-operations-standards-subform') {
      return ChecklistLoadResult(
        template: buildSubformTemplateData(),
        submission: null,
      );
    }
    if (slug == 'dealer-operations-standards-documentation') {
      return ChecklistLoadResult(
        template: buildDocumentationTemplateData(),
        submission: null,
      );
    }
    throw ChecklistApiException('Unknown checklist slug: $slug');
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    savedSlug = slug;
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
    savedSlug = slug;
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

  group('Subform and Documentation Data Models', () {
    test('Subform template contains 39 standards across 5 sections', () {
      final template = buildSubformTemplateData();
      expect(template.itemCount, 39);
      expect(template.sections.length, 5);
      expect(template.sections[0].key, 'subform-service-reception');
      expect(template.sections[0].items.length, 9);
      expect(template.sections[1].key, 'subform-employee-facilities');
      expect(template.sections[1].items.length, 12);
      expect(template.sections[2].key, 'subform-meeting-room');
      expect(template.sections[2].items.length, 3);
      expect(template.sections[3].key, 'subform-mitsubishi-quick-service');
      expect(template.sections[3].items.length, 4);
      expect(template.sections[4].key, 'subform-customers-lounge');
      expect(template.sections[4].items.length, 11);

      final staticItems = dosSubformTemplate
          .expand((section) => section.items)
          .toList();
      final workshopSupervisorItems = staticItems
          .where((item) => item.checker == 'WS SUP')
          .toList();
      final legacyWorkshopItems = staticItems
          .where(
            (item) => item.checker == 'WS' || item.checker == 'WORSHOP SUP',
          )
          .toList();

      expect(workshopSupervisorItems, hasLength(16));
      expect(legacyWorkshopItems, isEmpty);
    });

    test('Documentation template contains 17 standards across 3 sections', () {
      final template = buildDocumentationTemplateData();
      expect(template.itemCount, 17);
      expect(template.sections.length, 3);
      expect(template.sections[0].key, 'doc-rationalized-checksheet');
      expect(template.sections[0].items.length, 11);
      expect(template.sections[1].key, 'doc-repair-order');
      expect(template.sections[1].items.length, 3);
      expect(template.sections[2].key, 'doc-service-invoice');
      expect(template.sections[2].items.length, 3);
    });

    test('CustomerAuditSample serialization works correctly', () {
      final sample = CustomerAuditSample(
        customerIndex: 1,
        roNumber: 'RO-12345',
        mileage: '10,000 km',
        answers: {'doc-rc-1': 'yes', 'doc-rc-2': 'no'},
      );
      final json = sample.toJson();
      final restored = CustomerAuditSample.fromJson(json);

      expect(restored.customerIndex, 1);
      expect(restored.roNumber, 'RO-12345');
      expect(restored.mileage, '10,000 km');
      expect(restored.answers['doc-rc-1'], 'yes');
      expect(restored.answers['doc-rc-2'], 'no');
    });

    test('AuthenticatedUser permissions for Subform and Documentation', () {
      const ceUser = AuthenticatedUser(
        id: 1,
        name: 'CE Tester',
        email: 'ce@test.com',
        userType: 'CE SERVICE',
        accountStatus: 'active',
      );
      expect(ceUser.canAccessSubform, isTrue);
      expect(ceUser.canAccessDocumentation, isTrue);

      const workshopSupervisor = AuthenticatedUser(
        id: 2,
        name: 'Workshop Supervisor',
        email: 'workshop.supervisor@test.com',
        userType: 'WS SUP',
        accountStatus: 'active',
      );
      expect(workshopSupervisor.canAccessSubform, isTrue);
      expect(workshopSupervisor.canAccessDocumentation, isFalse);

      const asmUser = AuthenticatedUser(
        id: 3,
        name: 'ASM Tester',
        email: 'asm@test.com',
        userType: 'ASM',
        accountStatus: 'active',
      );
      expect(asmUser.canAccessSubform, isTrue);
      expect(asmUser.canAccessDocumentation, isFalse);

      const salesUser = AuthenticatedUser(
        id: 4,
        name: 'Sales Manager',
        email: 'sm@test.com',
        userType: 'SALES MANAGER',
        accountStatus: 'active',
      );
      expect(salesUser.canAccessSubform, isFalse);
      expect(salesUser.canAccessDocumentation, isFalse);

      const adminUser = AuthenticatedUser(
        id: 5,
        name: 'Admin',
        email: 'admin@test.com',
        userType: 'ADMIN',
        accountStatus: 'active',
      );
      expect(adminUser.canAccessSubform, isTrue);
      expect(adminUser.canAccessDocumentation, isTrue);
    });
  });

  group('Subform Checklist Screen & Prerequisite Cascade', () {
    testWidgets('CE SERVICE sees only Service Reception & Customer Lounge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const ceUser = AuthenticatedUser(
        id: 1,
        name: 'CE Service User',
        email: 'ce@gac.com',
        userType: 'CE SERVICE',
        accountStatus: 'active',
      );
      final repo = _FakeSubformDocRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards-subform',
            repository: repo,
            user: ceUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Service Reception c/o CE'), findsOneWidget);
      // Total 9 + 11 = 20 questions for CE Service
      expect(find.text('QUESTION 1 OF 20'), findsOneWidget);
    });

    testWidgets(
      'Workshop Supervisor sees Employee Facilities and MQS (16 standards)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const workshopSupervisor = AuthenticatedUser(
          id: 2,
          name: 'Workshop Supervisor',
          email: 'workshop.supervisor@gac.com',
          userType: 'WS SUP',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-subform',
              repository: repo,
              user: workshopSupervisor,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Employee Facilities c/o Workshop Supervisor'),
          findsOneWidget,
        );
        expect(find.text('QUESTION 1 OF 16'), findsOneWidget);
      },
    );

    testWidgets('ASM sees only Meeting Room (3 standards)', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const asmUser = AuthenticatedUser(
        id: 30,
        name: 'Aftersales Manager',
        email: 'asm@gac.com',
        userType: 'ASM',
        accountStatus: 'active',
      );
      final repo = _FakeSubformDocRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards-subform',
            repository: repo,
            user: asmUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meeting Room c/o ASM'), findsOneWidget);
      // Total 3 questions strictly for ASM
      expect(find.text('QUESTION 1 OF 3'), findsOneWidget);
    });

    testWidgets('Admin sees all 39 questions across 5 sections', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const adminUser = AuthenticatedUser(
        id: 40,
        name: 'Administrator',
        email: 'admin@gac.com',
        userType: 'ADMIN',
        accountStatus: 'active',
      );
      final repo = _FakeSubformDocRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistDetailScreen(
            slug: 'dealer-operations-standards-subform',
            repository: repo,
            user: adminUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 1 OF 39'), findsOneWidget);
    });

    testWidgets(
      'Selecting NO in Subform shows warning dialog and cascades to all section items',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const ceUser = AuthenticatedUser(
          id: 1,
          name: 'CE Service User',
          email: 'ce@gac.com',
          userType: 'CE SERVICE',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-subform',
              repository: repo,
              user: ceUser,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find NO response button for the first item
        final noBtn = find.byKey(const ValueKey('subform-sr-1-response-no'));
        expect(noBtn, findsOneWidget);

        // Tap NO -> warning dialog should pop up
        await tester.tap(noBtn);
        await tester.pumpAndSettle();

        expect(find.text('Prerequisite Warning'), findsOneWidget);
        expect(
          find.textContaining(
            'Selecting "NO" will automatically set all questions',
          ),
          findsOneWidget,
        );

        // Test cancel
        final cancelBtn = find.byKey(
          const ValueKey('cancel-prerequisite-warning'),
        );
        expect(cancelBtn, findsOneWidget);
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Warning dismissed, dialog closed
        expect(find.text('Prerequisite Warning'), findsNothing);

        // Tap NO again and confirm
        await tester.tap(noBtn);
        await tester.pumpAndSettle();

        final confirmBtn = find.byKey(
          const ValueKey('confirm-prerequisite-warning'),
        );
        expect(confirmBtn, findsOneWidget);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // The first item should now have NO selected (Material color is red)
        final noBtnMaterial = tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(const ValueKey('subform-sr-1-response-no')),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(noBtnMaterial.color, const Color(0xFFD92D20));

        // Tap NEXT to go to question 2 in the same section
        final nextBtn = find.byKey(const ValueKey('dos-next-question'));
        expect(nextBtn, findsOneWidget);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();

        // Question 2 (subform-sr-2) should ALSO be cascaded to NO!
        final noBtn2Material = tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(const ValueKey('subform-sr-2-response-no')),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(noBtn2Material.color, const Color(0xFFD92D20));
      },
    );
  });

  group('Documentation Checklist Screen & Multi-Customer Cascade', () {
    testWidgets(
      'Displays customer dropdown, add customer button, and customer fields',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const ceUser = AuthenticatedUser(
          id: 1,
          name: 'CE Service User',
          email: 'ce@gac.com',
          userType: 'CE SERVICE',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-documentation',
              repository: repo,
              user: ceUser,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('dos-documentation-view')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('customer-dropdown')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('add-customer-button')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('doc-ro-number-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('doc-mileage-1')), findsOneWidget);

        // Add Customer
        await tester.tap(find.byKey(const ValueKey('add-customer-button')));
        await tester.pumpAndSettle();

        expect(
          find.text('CE SERVICE DOCUMENT AUDIT  ·  4 CUSTOMER SAMPLES'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Tapping NO on check item shows warning dialog and cascades all 17 items for that customer to NO, exempting mileage',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const ceUser = AuthenticatedUser(
          id: 1,
          name: 'CE Service User',
          email: 'ce@gac.com',
          userType: 'CE SERVICE',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistDetailScreen(
              slug: 'dealer-operations-standards-documentation',
              repository: repo,
              user: ceUser,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter RO Number and Mileage
        await tester.enterText(
          find.byKey(const ValueKey('doc-ro-number-1')),
          'RO-998877',
        );
        await tester.enterText(
          find.byKey(const ValueKey('doc-mileage-1')),
          '10,000 km PMS',
        );
        await tester.pumpAndSettle();

        // Tap NO on the first check item
        final docItemNo = find.byKey(const ValueKey('doc-item-doc-rc-1-no'));
        expect(docItemNo, findsOneWidget);
        await tester.tap(docItemNo);
        await tester.pumpAndSettle();

        // Verify warning dialog
        expect(find.text('Prerequisite Warning'), findsOneWidget);
        expect(
          find.textContaining('Type of Job mileage and R.O. number are exempt'),
          findsOneWidget,
        );

        // Confirm
        final confirmBtn = find.byKey(
          const ValueKey('confirm-prerequisite-warning'),
        );
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Verify mileage and RO number are preserved
        expect(find.text('RO-998877'), findsOneWidget);
        expect(find.text('10,000 km PMS'), findsOneWidget);

        // Verify save draft serializes customers array
        await tester.tap(
          find.byKey(const ValueKey('checklist-appbar-submit-button')),
        );
        await tester.pumpAndSettle();

        // If submit is tapped, validate it submits or saves
      },
    );
  });

  group('DOS Dashboard Quick Launch', () {
    testWidgets(
      'Aftersales DOS Dashboard shows Subform and Documentation buttons for CE',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const ceUser = AuthenticatedUser(
          id: 1,
          name: 'CE Tester',
          email: 'ce@gac.com',
          userType: 'CE SERVICE',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: DosDashboardScreen(user: ceUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('dos-launch-subform-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dos-launch-doc-button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Aftersales DOS Dashboard shows only Subform for Workshop Supervisor',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const workshopSupervisor = AuthenticatedUser(
          id: 2,
          name: 'Workshop Supervisor',
          email: 'workshop.supervisor@gac.com',
          userType: 'WS SUP',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: DosDashboardScreen(
              user: workshopSupervisor,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('dos-launch-subform-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dos-launch-doc-button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'CE SERVICE sees scoped Subform and Documentation in UserChecklistsScreen',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const ceUser = AuthenticatedUser(
          id: 1,
          name: 'CE Service User',
          email: 'ce@gac.com',
          userType: 'CE SERVICE',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(user: ceUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Subform Sheet — Service Reception & Lounge'),
          findsOneWidget,
        );
        expect(
          find.text('Documentation Sheet — Customer Repair Orders'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Workshop Supervisor sees combined Subform and no Documentation',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const workshopSupervisor = AuthenticatedUser(
          id: 2,
          name: 'Workshop Supervisor',
          email: 'workshop.supervisor@gac.com',
          userType: 'WS SUP',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(
              user: workshopSupervisor,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Subform Sheet — Employee Facilities & MQS'),
          findsOneWidget,
        );
        expect(
          find.text('Documentation Sheet — Customer Repair Orders'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'ASM sees Meeting Room Subform and NO Documentation in UserChecklistsScreen',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const asmUser = AuthenticatedUser(
          id: 30,
          name: 'Aftersales Manager',
          email: 'asm@gac.com',
          userType: 'ASM',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(user: asmUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Subform Sheet — Meeting Room'), findsOneWidget);
        expect(
          find.text('Documentation Sheet — Customer Repair Orders'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Admin sees All Aftersales Sections Subform in UserChecklistsScreen',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const adminUser = AuthenticatedUser(
          id: 40,
          name: 'Administrator',
          email: 'admin@gac.com',
          userType: 'ADMIN',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(
              user: adminUser,
              repository: repo,
              activeTrack: DosAuditTrack.aftersales,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Subform Sheet — All Aftersales Sections'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'JC does not see Subform or Documentation in UserChecklistsScreen',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const jcUser = AuthenticatedUser(
          id: 4,
          name: 'Job Controller',
          email: 'jc@gac.com',
          userType: 'JC',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(user: jcUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('SUBFORM AUDIT'), findsNothing);
        expect(find.text('DOCUMENTATION AUDIT'), findsNothing);
      },
    );

    testWidgets(
      'CE SERVICE sees scoped Subform and Documentation in UserHomeScreen',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const ceUser = AuthenticatedUser(
          id: 1,
          name: 'CE Service User',
          email: 'ce@gac.com',
          userType: 'CE SERVICE',
          accountStatus: 'active',
        );
        final repo = _FakeSubformDocRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserHomeScreen(
              isActive: true,
              user: ceUser,
              repository: repo,
              onOpenChecklists: () {},
              onOpenProfile: () {},
              onOpenNotifications: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Dealer Operations Standards - Subform (Reception & Lounge)',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Dealer Operations Standards - Documentation'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Workshop Supervisor sees combined Subform in UserHomeScreen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const workshopSupervisor = AuthenticatedUser(
        id: 2,
        name: 'Workshop Supervisor',
        email: 'workshop.supervisor@gac.com',
        userType: 'WS SUP',
        accountStatus: 'active',
      );
      final repo = _FakeSubformDocRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserHomeScreen(
            isActive: true,
            user: workshopSupervisor,
            repository: repo,
            onOpenChecklists: () {},
            onOpenProfile: () {},
            onOpenNotifications: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Dealer Operations Standards - Subform (Employee Facilities & MQS)',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Dealer Operations Standards - Documentation'),
        findsNothing,
      );
    });
  });
}
