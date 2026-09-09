import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/login.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/dos_dashboard_screen.dart';
import 'package:gac_flutter/screens/user_checklists_screen.dart';
import 'package:gac_flutter/screens/user_home_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

class _FakeCatalogRepository implements ChecklistRepository {
  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async =>
      const [
        ChecklistCatalogItem(
          id: 1,
          slug: 'restroom',
          name: 'Restroom Checklist',
          description: 'Hourly utilities checks',
          version: 1,
          settings: {'validation_mode': 'time_slots'},
          sectionCount: 1,
          itemCount: 11,
          workUnitCount: 99,
          submission: null,
        ),
        ChecklistCatalogItem(
          id: 2,
          slug: 'utilities',
          name: 'Utilities Checklist',
          description: 'Daily facilities inspection',
          version: 1,
          settings: {'validation_mode': 'time_slots'},
          sectionCount: 1,
          itemCount: 10,
          workUnitCount: 90,
          submission: null,
        ),
        ChecklistCatalogItem(
          id: 3,
          slug: 'sales',
          name: 'Sales Checklist',
          description: 'Showroom and customer lounge inspection',
          version: 4,
          settings: {'validation_mode': 'yes_no_na'},
          sectionCount: 1,
          itemCount: 41,
          workUnitCount: 41,
          submission: null,
        ),
        ChecklistCatalogItem(
          id: 4,
          slug: 'service',
          name: 'Service Checklist',
          description: 'Service reception and workshop 5S',
          version: 2,
          settings: {'validation_mode': 'yes_no_na'},
          sectionCount: 1,
          itemCount: 33,
          workUnitCount: 33,
          submission: null,
        ),
        ChecklistCatalogItem(
          id: 5,
          slug: 'dealer-operations-standards-sales',
          name: 'Dealer Operations Standards - Sales',
          description: 'DOS Sales Standards compliance audit',
          version: 1,
          settings: {'validation_mode': 'dos'},
          sectionCount: 3,
          itemCount: 90,
          workUnitCount: 90,
          submission: null,
        ),
        ChecklistCatalogItem(
          id: 6,
          slug: 'dealer-operations-standards',
          name: 'Dealer Operations Standards - Aftersales',
          description: 'DOS Aftersales compliance audit',
          version: 2,
          settings: {'validation_mode': 'dos'},
          sectionCount: 15,
          itemCount: 75,
          workUnitCount: 75,
          submission: null,
        ),
      ];

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    return ChecklistLoadResult(
      template: ChecklistTemplateData(
        id: 1,
        slug: slug,
        name: slug,
        description: 'Test template',
        version: 1,
        settings: const {'validation_mode': 'yes_no_na'},
        sections: const [],
      ),
      submission: null,
    );
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('AuthenticatedUser role detection', () {
    test('identifies 5S Utilities users accurately', () {
      const u1 = AuthenticatedUser(
        id: 1,
        name: 'Util User',
        email: 'util@gateway.com',
        userType: '5S_UTILITIES',
        accountStatus: 'active',
      );
      expect(u1.is5sUtilities, isTrue);
      expect(u1.isUtilities, isTrue);
      expect(u1.is5sSales, isFalse);
      expect(u1.is5sService, isFalse);
      expect(u1.isSalesService5s, isFalse);
      expect(u1.isDosAuditor, isFalse);

      const u2 = AuthenticatedUser(
        id: 2,
        name: 'Direct Util',
        email: 'u2@gateway.com',
        userType: 'UTILITIES',
        accountStatus: 'active',
      );
      expect(u2.is5sUtilities, isTrue);
      expect(u2.isUtilities, isTrue);
      expect(u2.is5sSales, isFalse);
      expect(u2.is5sService, isFalse);
    });

    test('identifies 5S Sales users accurately', () {
      const s1 = AuthenticatedUser(
        id: 3,
        name: 'Sales 5S',
        email: 'sales@gateway.com',
        userType: '5S_SALES',
        accountStatus: 'active',
      );
      expect(s1.is5sSales, isTrue);
      expect(s1.is5sService, isFalse);
      expect(s1.is5sUtilities, isFalse);
      expect(s1.isSalesService5s, isFalse);
      expect(s1.isDosAuditor, isFalse);
    });

    test('identifies 5S Service users accurately', () {
      const s2 = AuthenticatedUser(
        id: 4,
        name: 'Service 5S',
        email: 'service@gateway.com',
        userType: '5S_SERVICE',
        accountStatus: 'active',
      );
      expect(s2.is5sService, isTrue);
      expect(s2.is5sSales, isFalse);
      expect(s2.is5sUtilities, isFalse);
      expect(s2.isSalesService5s, isFalse);
      expect(s2.isDosAuditor, isFalse);
    });

    test('identifies DOS Sales and Aftersales strictly', () {
      const sm = AuthenticatedUser(
        id: 5,
        name: 'Sales Manager',
        email: 'sm@gateway.com',
        userType: 'SM',
        accountStatus: 'active',
      );
      expect(sm.isDosSales, isTrue);
      expect(sm.isDosAftersales, isFalse);
      expect(sm.canSwitchDosTracks, isFalse);

      const asm = AuthenticatedUser(
        id: 6,
        name: 'Aftersales Manager',
        email: 'asm@gateway.com',
        userType: 'ASM',
        accountStatus: 'active',
      );
      expect(asm.isDosAftersales, isTrue);
      expect(asm.isDosSales, isFalse);
      expect(asm.canSwitchDosTracks, isFalse);

      const ce = AuthenticatedUser(
        id: 7,
        name: 'CE Service',
        email: 'ce@gateway.com',
        userType: 'CE SERVICE',
        accountStatus: 'active',
      );
      expect(ce.isDosAftersales, isTrue);
      expect(ce.isDosSales, isFalse);
      expect(ce.canSwitchDosTracks, isFalse);

      const admin = AuthenticatedUser(
        id: 8,
        name: 'Compliance Admin',
        email: 'admin@gateway.com',
        userType: 'ADMIN',
        accountStatus: 'active',
      );
      expect(admin.canSwitchDosTracks, isTrue);
    });

    test('login routing maps all user types correctly', () {
      expect(destinationForUserType('5S_UTILITIES'), '/(user)/home');
      expect(destinationForUserType('5S_SERVICE'), '/(user)/home');
      expect(destinationForUserType('5S_SALES'), '/(user)/home');
      expect(destinationForUserType('UTILITIES'), '/(user)/home');
      expect(destinationForUserType('SALES_SERVICE'), '/(user)/home');
      expect(destinationForUserType('SM'), '/(dos)/dashboard');
      expect(destinationForUserType('ASM'), '/(dos)/dashboard');
      expect(destinationForUserType('DOS'), '/(dos)/dashboard');
    });
  });

  group('UserChecklistsScreen role-based scoping', () {
    testWidgets('5S Utilities user ONLY sees utilities checklists', (
      tester,
    ) async {
      setViewport(tester);
      const utilUser = AuthenticatedUser(
        id: 1,
        name: 'Utilities 5S',
        email: 'util@gateway.com',
        userType: '5S_UTILITIES',
        accountStatus: 'active',
      );

      final repo = _FakeCatalogRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserChecklistsScreen(user: utilUser, repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Utilities checklists are present alongside the Master Checklist
      expect(find.text('Restroom Checklist'), findsOneWidget);
      expect(find.text('Utilities Checklist'), findsOneWidget);
      expect(find.text('Complete Utilities Master Checklist'), findsOneWidget);
      expect(find.text('BY CATEGORY'), findsOneWidget);
      expect(find.text('COMPLETE AUDIT'), findsOneWidget);

      // Switching to Complete Audit shows only the Master Checklist
      await tester.ensureVisible(find.text('COMPLETE AUDIT'));
      await tester.tap(find.text('COMPLETE AUDIT'));
      await tester.pumpAndSettle();
      expect(find.text('Complete Utilities Master Checklist'), findsOneWidget);
      expect(find.text('Restroom Checklist'), findsNothing);
      expect(find.text('Utilities Checklist'), findsNothing);

      // Switch back to By Category
      await tester.ensureVisible(find.text('BY CATEGORY'));
      await tester.tap(find.text('BY CATEGORY'));
      await tester.pumpAndSettle();
      expect(find.text('Restroom Checklist'), findsOneWidget);
      expect(find.text('Utilities Checklist'), findsOneWidget);
      expect(find.text('Complete Utilities Master Checklist'), findsOneWidget);

      // Non-utilities checklists must NEVER appear
      expect(find.text('Sales Checklist'), findsNothing);
      expect(find.text('Service Checklist'), findsNothing);
      expect(find.text('Dealer Operations Standards - Sales'), findsNothing);
      expect(
        find.text('Dealer Operations Standards - Aftersales'),
        findsNothing,
      );

      // Filter chips for other categories must not be rendered
      expect(find.text('DOS'), findsNothing);
      expect(find.text('SALES & SERVICE'), findsNothing);
    });

    testWidgets(
      '5S Sales user ONLY sees Sales checklist (separate from Service)',
      (tester) async {
        setViewport(tester);
        const salesUser = AuthenticatedUser(
          id: 2,
          name: 'Sales 5S',
          email: 'sales@gateway.com',
          userType: '5S_SALES',
          accountStatus: 'active',
        );

        final repo = _FakeCatalogRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(user: salesUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        // Sales checklist is present alongside the Master Checklist
        expect(find.text('Sales Checklist'), findsOneWidget);
        expect(find.text('Complete 5S Sales Audit'), findsOneWidget);
        expect(find.text('BY CATEGORY'), findsOneWidget);
        expect(find.text('COMPLETE AUDIT'), findsOneWidget);

        // Switching to Complete Audit shows only the Master Checklist
        await tester.ensureVisible(find.text('COMPLETE AUDIT'));
        await tester.tap(find.text('COMPLETE AUDIT'));
        await tester.pumpAndSettle();
        expect(find.text('Complete 5S Sales Audit'), findsOneWidget);
        expect(find.text('Sales Checklist'), findsNothing);

        // Switch back to By Category
        await tester.ensureVisible(find.text('BY CATEGORY'));
        await tester.tap(find.text('BY CATEGORY'));
        await tester.pumpAndSettle();
        expect(find.text('Sales Checklist'), findsOneWidget);
        expect(find.text('Complete 5S Sales Audit'), findsOneWidget);

        // Service, Utilities and DOS must NEVER appear
        expect(find.text('Service Checklist'), findsNothing);
        expect(find.text('Restroom Checklist'), findsNothing);
        expect(find.text('Utilities Checklist'), findsNothing);
        expect(find.text('Dealer Operations Standards - Sales'), findsNothing);
        expect(
          find.text('Dealer Operations Standards - Aftersales'),
          findsNothing,
        );

        // Filter chips for other categories must not be rendered
        expect(find.text('DOS'), findsNothing);
        expect(find.text('SERVICE'), findsNothing);
        expect(find.text('UTILITIES'), findsNothing);
      },
    );

    testWidgets(
      '5S Service user ONLY sees Service checklist (separate from Sales)',
      (tester) async {
        setViewport(tester);
        const serviceUser = AuthenticatedUser(
          id: 3,
          name: 'Service 5S',
          email: 'service@gateway.com',
          userType: '5S_SERVICE',
          accountStatus: 'active',
        );

        final repo = _FakeCatalogRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(user: serviceUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        // Service checklist is present alongside the Master Checklist
        expect(find.text('Service Checklist'), findsOneWidget);
        expect(find.text('Complete 5S Service Audit'), findsOneWidget);
        expect(find.text('BY CATEGORY'), findsOneWidget);
        expect(find.text('COMPLETE AUDIT'), findsOneWidget);

        // Switching to Complete Audit shows only the Master Checklist
        await tester.ensureVisible(find.text('COMPLETE AUDIT'));
        await tester.tap(find.text('COMPLETE AUDIT'));
        await tester.pumpAndSettle();
        expect(find.text('Complete 5S Service Audit'), findsOneWidget);
        expect(find.text('Service Checklist'), findsNothing);

        // Switch back to By Category
        await tester.ensureVisible(find.text('BY CATEGORY'));
        await tester.tap(find.text('BY CATEGORY'));
        await tester.pumpAndSettle();
        expect(find.text('Service Checklist'), findsOneWidget);
        expect(find.text('Complete 5S Service Audit'), findsOneWidget);

        // Sales, Utilities and DOS must NEVER appear
        expect(find.text('Sales Checklist'), findsNothing);
        expect(find.text('Restroom Checklist'), findsNothing);
        expect(find.text('Utilities Checklist'), findsNothing);
        expect(find.text('Dealer Operations Standards - Sales'), findsNothing);
        expect(
          find.text('Dealer Operations Standards - Aftersales'),
          findsNothing,
        );

        // Filter chips for other categories must not be rendered
        expect(find.text('DOS'), findsNothing);
        expect(find.text('SALES'), findsNothing);
        expect(find.text('UTILITIES'), findsNothing);
      },
    );

    testWidgets(
      'DOS Sales Manager sees ONLY Sales categorized and NO track switcher',
      (tester) async {
        setViewport(tester);
        const smUser = AuthenticatedUser(
          id: 3,
          name: 'Sales Manager',
          email: 'sm@gateway.com',
          userType: 'SM',
          accountStatus: 'active',
        );

        final repo = _FakeCatalogRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(user: smUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        // Categorized cards for Sales are visible including Master Audit
        expect(find.text('BY CATEGORY'), findsOneWidget);
        expect(find.text('Basic Standards Checklist'), findsOneWidget);
        expect(find.text('Standard Standards Checklist'), findsOneWidget);
        expect(find.text('Beyond Standards Checklist'), findsOneWidget);
        expect(
          find.text('Dealer Operations Standards — Sales'),
          findsOneWidget,
        );

        // Track switcher must NOT appear for Sales Manager
        expect(find.text('AFTERSALES'), findsNothing);
        expect(find.text('SALES (90)'), findsNothing);
        expect(find.text('AFTERSALES (75)'), findsNothing);
      },
    );

    testWidgets(
      'DOS Aftersales Checker sees ONLY Aftersales categorized and NO track switcher',
      (tester) async {
        setViewport(tester);
        const ceUser = AuthenticatedUser(
          id: 4,
          name: 'CE Service Checker',
          email: 'ce@gateway.com',
          userType: 'CE SERVICE',
          accountStatus: 'active',
        );

        final repo = _FakeCatalogRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(user: ceUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        // Categorized cards are visible including Master Audit
        expect(find.text('BY CATEGORY'), findsOneWidget);
        expect(find.text('Standard Standards Checklist'), findsOneWidget);
        expect(find.text('Beyond Standards Checklist'), findsOneWidget);
        expect(find.text('Basic Standards Checklist'), findsNothing);
        expect(
          find.text('Dealer Operations Standards — Aftersales'),
          findsOneWidget,
        );

        // Track switcher must NOT appear for Aftersales Checker
        expect(find.text('SALES'), findsNothing);
        expect(find.text('SALES (90)'), findsNothing);
        expect(find.text('AFTERSALES (75)'), findsNothing);
      },
    );

    testWidgets(
      'Workshop Supervisor does NOT see Beyond category card when has no beyond standards',
      (tester) async {
        setViewport(tester);
        const wsUser = AuthenticatedUser(
          id: 6,
          name: 'Workshop Supervisor',
          email: 'ws@gateway.com',
          userType: 'WS SUP',
          accountStatus: 'active',
        );

        final repo = _FakeCatalogRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(user: wsUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('BY CATEGORY'), findsOneWidget);
        expect(find.text('Basic Standards Checklist'), findsOneWidget);
        expect(find.text('Standard Standards Checklist'), findsOneWidget);
        expect(find.text('Beyond Standards Checklist'), findsNothing);
        expect(
          find.text('Dealer Operations Standards — Aftersales'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Parts Supervisor does NOT see Basic or Beyond category cards when has only standard standards',
      (tester) async {
        setViewport(tester);
        const partsUser = AuthenticatedUser(
          id: 7,
          name: 'Parts Supervisor',
          email: 'parts@gateway.com',
          userType: 'PARTS SUPERVISOR',
          accountStatus: 'active',
        );

        final repo = _FakeCatalogRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(user: partsUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('BY CATEGORY'), findsOneWidget);
        expect(find.text('Standard Standards Checklist'), findsOneWidget);
        expect(find.text('Basic Standards Checklist'), findsNothing);
        expect(find.text('Beyond Standards Checklist'), findsNothing);
        expect(
          find.text('Dealer Operations Standards — Aftersales'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Job Controller does NOT see Basic or Beyond category cards when has only standard standards',
      (tester) async {
        setViewport(tester);
        const jcUser = AuthenticatedUser(
          id: 8,
          name: 'Job Controller',
          email: 'jc@gateway.com',
          userType: 'JC',
          accountStatus: 'active',
        );

        final repo = _FakeCatalogRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(user: jcUser, repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('BY CATEGORY'), findsOneWidget);
        expect(find.text('Standard Standards Checklist'), findsOneWidget);
        expect(find.text('Basic Standards Checklist'), findsNothing);
        expect(find.text('Beyond Standards Checklist'), findsNothing);
        expect(
          find.text('Dealer Operations Standards — Aftersales'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Track switcher pills are removed and Master Checklist is present on checklists tab',
      (tester) async {
        setViewport(tester);
        const adminUser = AuthenticatedUser(
          id: 5,
          name: 'Admin',
          email: 'admin@gateway.com',
          userType: 'ADMIN',
          accountStatus: 'active',
        );

        final repo = _FakeCatalogRepository();
        await tester.pumpWidget(
          MaterialApp(
            theme: GacTheme.light,
            home: UserChecklistsScreen(
              user: adminUser,
              repository: repo,
              activeTrack: DosAuditTrack.sales,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Track switcher buttons must NOT appear
        expect(find.text('SALES (90)'), findsNothing);
        expect(find.text('AFTERSALES (75)'), findsNothing);

        // Master Checklist card is present
        expect(
          find.text('Dealer Operations Standards — Sales'),
          findsOneWidget,
        );
      },
    );
  });

  group('UserHomeScreen task filtering by role', () {
    testWidgets('5S Utilities user on home screen sees only utilities tasks', (
      tester,
    ) async {
      setViewport(tester);
      const utilUser = AuthenticatedUser(
        id: 1,
        name: 'Utilities 5S',
        email: 'util@gateway.com',
        userType: '5S_UTILITIES',
        accountStatus: 'active',
      );

      final repo = _FakeCatalogRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserHomeScreen(
            isActive: true,
            user: utilUser,
            repository: repo,
            onOpenChecklists: () {},
            onOpenProfile: () {},
            onOpenNotifications: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restroom Checklist'), findsOneWidget);
      expect(find.text('Utilities Checklist'), findsOneWidget);
      expect(find.text('Sales Checklist'), findsNothing);
      expect(find.text('Service Checklist'), findsNothing);
    });

    testWidgets('5S Sales user on home screen sees only sales tasks', (
      tester,
    ) async {
      setViewport(tester);
      const salesUser = AuthenticatedUser(
        id: 2,
        name: 'Sales 5S',
        email: 'sales@gateway.com',
        userType: '5S_SALES',
        accountStatus: 'active',
      );

      final repo = _FakeCatalogRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserHomeScreen(
            isActive: true,
            user: salesUser,
            repository: repo,
            onOpenChecklists: () {},
            onOpenProfile: () {},
            onOpenNotifications: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sales Checklist'), findsOneWidget);
      expect(find.text('Service Checklist'), findsNothing);
      expect(find.text('Restroom Checklist'), findsNothing);
      expect(find.text('Utilities Checklist'), findsNothing);
    });

    testWidgets('5S Service user on home screen sees only service tasks', (
      tester,
    ) async {
      setViewport(tester);
      const serviceUser = AuthenticatedUser(
        id: 3,
        name: 'Service 5S',
        email: 'service@gateway.com',
        userType: '5S_SERVICE',
        accountStatus: 'active',
      );

      final repo = _FakeCatalogRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserHomeScreen(
            isActive: true,
            user: serviceUser,
            repository: repo,
            onOpenChecklists: () {},
            onOpenProfile: () {},
            onOpenNotifications: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Service Checklist'), findsOneWidget);
      expect(find.text('Sales Checklist'), findsNothing);
      expect(find.text('Restroom Checklist'), findsNothing);
      expect(find.text('Utilities Checklist'), findsNothing);
    });
  });
}
