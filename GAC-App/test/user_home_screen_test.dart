import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_home_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home renders only the assigned Laravel tasks', (tester) async {
    _setViewport(tester);
    final repository = _HomeRepository([
      _catalog(
        slug: 'restroom',
        name: 'Restroom Checklist',
        itemCount: 11,
        workUnitCount: 99,
        settings: const {
          'validation_mode': 'time_slots',
          'time_slots': [
            {'key': '08:00'},
            {'key': '09:00'},
            {'key': '10:00'},
            {'key': '11:00'},
            {'key': '13:00'},
            {'key': '14:00'},
            {'key': '15:00'},
            {'key': '16:00'},
            {'key': '17:00'},
          ],
        },
      ),
    ]);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(repository.requestedDates, ['2026-09-02']);
    expect(find.text('Restroom Checklist'), findsOneWidget);
    expect(find.text('0 / 99 checks completed'), findsOneWidget);
    expect(find.text('Sales Checklist'), findsNothing);
    expect(find.text('Sales materials outdated'), findsNothing);
  });

  testWidgets('date and status filters request and show database state', (
    tester,
  ) async {
    _setViewport(tester);
    final repository = _HomeRepository([
      _catalog(slug: 'sales', name: 'Sales Checklist', itemCount: 41),
      _catalog(
        slug: 'service',
        name: 'Service Checklist',
        itemCount: 33,
        submission: _submission(
          status: 'draft',
          answered: 10,
          total: 33,
          issueCount: 2,
        ),
      ),
    ]);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('In progress · 1'));
    await tester.pump();
    expect(find.text('Service Checklist'), findsWidgets);
    expect(find.text('Sales Checklist'), findsNothing);
    expect(find.text('Attention needed · 2'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('home-date-2026-09-01')),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedDates.last, '2026-09-01');
    expect(find.text('All · 2'), findsOneWidget);
    expect(find.text('Sales Checklist'), findsOneWidget);
  });

  testWidgets(
    'To-do filter works properly when tasks have empty drafts or no submissions',
    (tester) async {
      _setViewport(tester);
      final repository = _HomeRepository([
        _catalog(
          slug: 'sales',
          name: 'Sales Checklist',
          itemCount: 41,
          submission: _submission(
            status: 'draft',
            answered: 0,
            total: 41,
            issueCount: 0,
          ),
        ),
        _catalog(
          slug: 'service',
          name: 'Service Checklist',
          itemCount: 33,
          submission: _submission(
            status: 'draft',
            answered: 10,
            total: 33,
            issueCount: 0,
          ),
        ),
        _catalog(
          slug: 'gateway-5s',
          name: '5S Completed Audit',
          itemCount: 20,
          submission: _submission(
            status: 'submitted',
            answered: 20,
            total: 20,
            issueCount: 0,
          ),
        ),
      ]);

      String? openedSlug;
      String? openedDate;

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserHomeScreen(
            isActive: true,
            repository: repository,
            now: () => DateTime(2026, 9, 2),
            onOpenChecklists: () {},
            onOpenProfile: () {},
            onOpenNotifications: () {},
            onOpenChecklist: (slug, date) {
              openedSlug = slug;
              openedDate = date;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify filter chip counts
      expect(find.text('All · 3'), findsOneWidget);
      expect(find.text('To do · 1'), findsOneWidget);
      expect(find.text('In progress · 1'), findsOneWidget);
      expect(find.text('Completed · 1'), findsOneWidget);

      // Filter by To do
      await tester.tap(find.text('To do · 1'));
      await tester.pumpAndSettle();

      // Only the unstarted Sales Checklist should be visible
      expect(find.text('Sales Checklist'), findsOneWidget);
      expect(find.text('Service Checklist'), findsNothing);
      expect(find.text('5S Completed Audit'), findsNothing);

      // Badge and action label on To do task
      expect(find.text('TO DO'), findsOneWidget);
      expect(find.text('START'), findsOneWidget);

      // Tapping the To do task opens it
      await tester.tap(find.text('Sales Checklist'));
      await tester.pumpAndSettle();
      expect(openedSlug, 'sales');
      expect(openedDate, '2026-09-02');

      // Filter by In progress
      await tester.tap(find.text('In progress · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Service Checklist'), findsOneWidget);
      expect(find.text('Sales Checklist'), findsNothing);
      expect(find.text('IN PROGRESS'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      // Filter by Completed
      await tester.ensureVisible(find.text('Completed · 1'));
      await tester.tap(find.text('Completed · 1'));
      await tester.pumpAndSettle();
      expect(find.text('5S Completed Audit'), findsOneWidget);
      expect(find.text('Sales Checklist'), findsNothing);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('VIEW'), findsOneWidget);
    },
  );
}

Widget _app(ChecklistRepository repository) {
  return MaterialApp(
    theme: GacTheme.light,
    home: UserHomeScreen(
      isActive: true,
      repository: repository,
      now: () => DateTime(2026, 9, 2),
      onOpenChecklists: () {},
      onOpenProfile: () {},
      onOpenNotifications: () {},
    ),
  );
}

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _HomeRepository implements ChecklistRepository {
  _HomeRepository(this.tasks);

  final List<ChecklistCatalogItem> tasks;
  final List<String?> requestedDates = [];

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async {
    requestedDates.add(date);
    return tasks;
  }

  @override
  Future<ChecklistLoadResult> fetchChecklist(String slug, {String? date}) {
    throw UnimplementedError();
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) {
    throw UnimplementedError();
  }
}

ChecklistCatalogItem _catalog({
  required String slug,
  required String name,
  required int itemCount,
  int? workUnitCount,
  Map<String, dynamic> settings = const {'validation_mode': 'yes_no_na'},
  ChecklistSubmissionData? submission,
}) {
  return ChecklistCatalogItem(
    id: name.hashCode,
    slug: slug,
    name: name,
    description: 'Assigned from Laravel.',
    version: 1,
    settings: settings,
    sectionCount: 1,
    itemCount: itemCount,
    workUnitCount: workUnitCount,
    submission: submission,
  );
}

ChecklistSubmissionData _submission({
  required String status,
  required int answered,
  required int total,
  required int issueCount,
}) {
  return ChecklistSubmissionData(
    id: 1,
    status: status,
    auditDate: '2026-09-02',
    templateVersion: 1,
    scores: {'answered': answered, 'total': total, 'no': issueCount},
    responses: const {},
    answeredItems: answered,
    totalItems: total,
    completionPercentage: answered / total * 100,
    submittedAt: null,
    issueCount: issueCount,
  );
}
