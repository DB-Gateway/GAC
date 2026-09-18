import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_home_screen.dart';
import 'package:gac_flutter/screens/user_checklist_detail_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('attention ignores stale counts and notes on YES and unanswered responses', (tester) async {
    _setViewport(tester);
    final repository = _HomeRepository([
      _catalog(
        slug: 'service', name: 'Service Checklist', itemCount: 3,
        submission: _submission(status: 'draft', answered: 3, total: 3, issueCount: 3),
      ),
    ], {'service': _attentionRecord('service', ['yes', 'yes', null])});

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.text('Attention needed · 0'), findsOneWidget);
    expect(find.textContaining('checklist response(s) need review'), findsNothing);
    await tester.ensureVisible(find.text('Attention needed · 0'));
    await tester.tap(find.text('Attention needed · 0'));
    await tester.pumpAndSettle();
    expect(find.text('Service Checklist'), findsNothing);
  });

  testWidgets('attention detects NO even when summary reports zero issues', (tester) async {
    _setViewport(tester);
    final repository = _HomeRepository([
      _catalog(
        slug: 'service', name: 'Service Checklist', itemCount: 2,
        submission: _submission(status: 'draft', answered: 2, total: 2, issueCount: 0),
      ),
    ], {'service': _attentionRecord('service', ['yes', 'no'])});
    String? openedItem;
    await tester.pumpWidget(MaterialApp(
      theme: GacTheme.light,
      home: Scaffold(body: UserHomeScreen(
        isActive: true, repository: repository, now: () => DateTime(2026, 9, 2),
        onOpenChecklists: () {}, onOpenProfile: () {}, onOpenNotifications: () {},
        onOpenChecklistWithQuestion: (slug, date, slot, item) => openedItem = item,
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Attention needed · 1'), findsWidgets);
    final issueRow = find.widgetWithText(ListTile, 'Service Checklist');
    await tester.ensureVisible(issueRow);
    await tester.tap(issueRow);
    await tester.pumpAndSettle();
    expect(openedItem, isNull);
    final review = tester.widget<UserChecklistDetailScreen>(
      find.byType(UserChecklistDetailScreen),
    );
    expect(review.attentionOnly, isTrue);
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.text('Question 0'), findsNothing);
  });

  for (final failVerification in [false, true]) {
    testWidgets('attention does not navigate when recheck ${failVerification ? 'fails' : 'finds resolved answers'}', (tester) async {
      _setViewport(tester);
      final records = {'service': _attentionRecord('service', ['no', 'yes'])};
      final repository = _HomeRepository([
        _catalog(
          slug: 'service', name: 'Service Checklist', itemCount: 2,
          submission: _submission(status: 'draft', answered: 2, total: 2, issueCount: 1),
        ),
      ], records);
      var opened = false;
      await tester.pumpWidget(MaterialApp(
        theme: GacTheme.light,
        home: Scaffold(body: UserHomeScreen(
          isActive: true, repository: repository, now: () => DateTime(2026, 9, 2),
          onOpenChecklists: () {}, onOpenProfile: () {}, onOpenNotifications: () {},
          onOpenChecklistWithQuestion: (slug, date, slot, item) { opened = true; },
        )),
      ));
      await tester.pumpAndSettle();
      if (failVerification) {
        records.clear();
      } else {
        records['service'] = _attentionRecord('service', ['yes', 'yes']);
      }
      final issueRow = find.widgetWithText(ListTile, 'Service Checklist');
      await tester.ensureVisible(issueRow);
      await tester.tap(issueRow);
      await tester.pumpAndSettle();
      expect(opened, isFalse);
      expect(find.text(failVerification
          ? 'Unable to verify responses. Please try again.'
          : 'No responses currently need review.'), findsOneWidget);
      if (!failVerification) {
        expect(find.text('Attention needed · 0'), findsOneWidget);
      }
    });
  }

  testWidgets('home renders only the assigned Server tasks', (tester) async {
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
    ], {'service': _attentionRecord('service', ['no', 'no'])});

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

  testWidgets(
    'continuing from draft resumes the latest unfinished checklist in the list',
    (tester) async {
      _setViewport(tester);
      final repository = _HomeRepository([
        _catalog(
          slug: 'sales',
          name: 'Sales Checklist',
          itemCount: 41,
          submission: _submission(
            status: 'draft',
            answered: 8,
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
            answered: 12,
            total: 33,
            issueCount: 0,
          ),
        ),
      ]);

      String? openedSlug;
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
            onOpenChecklist: (slug, date) => openedSlug = slug,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sales Checklist'));
      await tester.pumpAndSettle();

      expect(openedSlug, 'service');
    },
  );

  testWidgets('continuing an hourly task opens the device-current slot', (
    tester,
  ) async {
    _setViewport(tester);
    final repository = _HomeRepository([
      _catalog(
        slug: 'utilities',
        name: 'Utilities Checklist',
        itemCount: 2,
        workUnitCount: 12,
        settings: const {
          'validation_mode': 'time_slots',
          'time_slots': [
            {'key': '08:00'},
            {'key': '13:00'},
            {'key': '14:00'},
            {'key': '15:00'},
          ],
        },
        submission: _submission(
          status: 'draft',
          answered: 2,
          total: 12,
          issueCount: 0,
        ),
      ),
    ]);
    String? openedSlot;

    await tester.pumpWidget(
      MaterialApp(
        theme: GacTheme.light,
        home: UserHomeScreen(
          isActive: true,
          repository: repository,
          now: () => DateTime(2026, 9, 2, 14, 37),
          onOpenChecklists: () {},
          onOpenProfile: () {},
          onOpenNotifications: () {},
          onOpenChecklistWithSlot: (slug, date, initialSlotKey) {
            openedSlot = initialSlotKey;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Utilities Checklist'));
    await tester.pumpAndSettle();

    expect(openedSlot, '14:00');
  });

  testWidgets(
    '5S utilities displays 9 total checklists on row and remains in To-do until all are finished',
    (tester) async {
      _setViewport(tester);
      final slots = const [
        {'key': '08:00', 'label': '8 AM'},
        {'key': '09:00', 'label': '9 AM'},
        {'key': '10:00', 'label': '10 AM'},
        {'key': '11:00', 'label': '11 AM'},
        {'key': '13:00', 'label': '1 PM'},
        {'key': '14:00', 'label': '2 PM'},
        {'key': '15:00', 'label': '3 PM'},
        {'key': '16:00', 'label': '4 PM'},
        {'key': '17:00', 'label': '5 PM'},
      ];

      // 1. Initial state (0 slots submitted)
      var repo = _HomeRepository([
        _catalog(
          slug: 'restroom',
          name: 'Restroom Checklist',
          itemCount: 11,
          workUnitCount: 99,
          settings: {
            'validation_mode': 'time_slots',
            'time_slots': slots,
          },
        ),
      ]);

      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      expect(find.text('0/9 '), findsOneWidget);
      expect(find.text('checklists submitted'), findsOneWidget);
      expect(find.text('To do · 1'), findsOneWidget);
      expect(find.text('Completed · 0'), findsOneWidget);
      expect(find.text('TO DO'), findsOneWidget);
      expect(find.text('START'), findsOneWidget);

      // 2. One slot submitted (11 of 99 checks completed, status = submitted)
      repo = _HomeRepository([
        _catalog(
          slug: 'restroom',
          name: 'Restroom Checklist',
          itemCount: 11,
          workUnitCount: 99,
          settings: {
            'validation_mode': 'time_slots',
            'time_slots': slots,
          },
          submission: _submission(
            status: 'submitted',
            answered: 11,
            total: 99,
            issueCount: 0,
          ),
        ),
      ]);

      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      expect(find.text('1/9 '), findsOneWidget);
      expect(find.text('checklists submitted'), findsOneWidget);
      expect(find.text('To do · 1'), findsOneWidget);
      expect(find.text('Completed · 0'), findsOneWidget);
      expect(find.text('TO DO'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      // Verify task still shows when filtering by To do
      await tester.tap(find.text('To do · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Restroom Checklist'), findsOneWidget);

      // 3. All 9 slots submitted (99 of 99 checks completed, status = submitted)
      repo = _HomeRepository([
        _catalog(
          slug: 'restroom',
          name: 'Restroom Checklist',
          itemCount: 11,
          workUnitCount: 99,
          settings: {
            'validation_mode': 'time_slots',
            'time_slots': slots,
          },
          submission: _submission(
            status: 'submitted',
            answered: 99,
            total: 99,
            issueCount: 0,
          ),
        ),
      ]);

      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      expect(find.text('9/9 '), findsOneWidget);
      expect(find.text('checklists submitted'), findsOneWidget);
      expect(find.text('To do · 0'), findsOneWidget);
      expect(find.text('Completed · 1'), findsOneWidget);

      await tester.tap(find.text('All · 1'));
      await tester.pumpAndSettle();

      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('VIEW'), findsOneWidget);
    },
  );

  testWidgets(
    'Attention needed tab displays count of checklists needing attention and filters them',
    (tester) async {
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
        _catalog(
          slug: 'restroom',
          name: 'Restroom Checklist',
          itemCount: 11,
          submission: _submission(
            status: 'draft',
            answered: 5,
            total: 11,
            issueCount: 1,
          ),
        ),
      ], {
        'service': _attentionRecord('service', ['no', 'no']),
        'restroom': _attentionRecord('restroom', ['not_good']),
      });

      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      // The tab chip displays the exact number of checklists that need attention (2)
      expect(find.text('Attention needed · 2'), findsWidgets);

      // Tap the Attention needed filter chip
      await tester.ensureVisible(find.text('Attention needed · 2').first);
      await tester.tap(find.text('Attention needed · 2').first);
      await tester.pumpAndSettle();

      // Only the two checklists that need attention are shown
      expect(find.text('Service Checklist'), findsWidgets);
      expect(find.text('Restroom Checklist'), findsWidgets);
      expect(find.text('Sales Checklist'), findsNothing);

      // Verify zero count and empty panel message
      final repoClean = _HomeRepository([
        _catalog(slug: 'sales', name: 'Sales Checklist', itemCount: 41),
      ]);
      await tester.pumpWidget(_app(repoClean));
      await tester.pumpAndSettle();

      expect(find.text('Attention needed · 0'), findsOneWidget);
      await tester.ensureVisible(find.text('Attention needed · 0'));
      await tester.tap(find.text('Attention needed · 0'));
      await tester.pumpAndSettle();

      expect(
        find.text('No checklists currently need attention.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Opening a checklist with attention needed redirects to the specific question',
    (tester) async {
      _setViewport(tester);
      final record = ChecklistLoadResult(
        template: ChecklistTemplateData(
          id: 1,
          slug: 'service',
          name: 'Service Checklist',
          description: 'Service Checklist Description',
          version: 1,
          settings: const {'validation_mode': 'yes_no_na'},
          sections: const [
            ChecklistSectionData(
              id: 1,
              key: 'sec-1',
              title: 'Section 1',
              sortOrder: 1,
              metadata: {},
              items: [
                ChecklistItemData(
                  id: 101,
                  key: 'service_q1',
                  prompt: 'Clean workspace',
                  sortOrder: 1,
                  metadata: {},
                ),
                ChecklistItemData(
                  id: 102,
                  key: 'service_q2',
                  prompt: 'Fire extinguisher inspected',
                  sortOrder: 2,
                  metadata: {},
                ),
              ],
            ),
          ],
        ),
        submission: const ChecklistSubmissionData(
          id: 1,
          status: 'draft',
          auditDate: '2026-09-02',
          templateVersion: 1,
          scores: {'no': 1},
          responses: {
            'service_q1': ChecklistResponseData(
              itemId: 101,
              itemKey: 'service_q1',
              status: 'yes',
              remark: '',
              finding: 'Previous finding',
              actionPlan: 'Previous action plan',
              commitmentDate: null,
              details: {
                'choice': 'no',
                'status': 'no',
                'escalation': 'general_manager',
                'has_issue': true,
                'subform_answers': {'old': 'no'},
              },
            ),
            'service_q2': ChecklistResponseData(
              itemId: 102,
              itemKey: 'service_q2',
              status: 'no',
              remark: 'Gauge in red',
              finding: 'Extinguisher depressurized',
              actionPlan: 'Recharge or replace',
              commitmentDate: '2026-09-05',
              details: {'choice': 'no'},
            ),
          },
          answeredItems: 2,
          totalItems: 2,
          completionPercentage: 100,
          submittedAt: null,
          issueCount: 1,
        ),
      );

      final repository = _HomeRepository(
        [
          _catalog(
            slug: 'service',
            name: 'Service Checklist',
            itemCount: 2,
            submission: _submission(
              status: 'draft',
              answered: 2,
              total: 2,
              issueCount: 1,
            ),
          ),
        ],
        {'service': record},
      );

      String? openedSlug;
      String? openedDate;
      String? openedSlot;
      String? openedItemKey;

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
            onOpenChecklistWithQuestion: (slug, date, slotKey, itemKey) {
              openedSlug = slug;
              openedDate = date;
              openedSlot = slotKey;
              openedItemKey = itemKey;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Service Checklist
      await tester.tap(find.text('Service Checklist').first);
      await tester.pumpAndSettle();

      expect(openedSlug, 'service');
      expect(openedDate, '2026-09-02');
      // Directly redirected into the question with the issue (service_q2)
      expect(openedItemKey, 'service_q2');
      expect(openedSlot, isNull);
    },
  );

  testWidgets(
    'Opening an hourly checklist with attention needed redirects to the question and slot',
    (tester) async {
      _setViewport(tester);
      final record = ChecklistLoadResult(
        template: ChecklistTemplateData(
          id: 2,
          slug: 'restroom',
          name: 'Restroom Checklist',
          description: 'Restroom Checklist Description',
          version: 1,
          settings: const {
            'validation_mode': 'time_slots',
            'time_slots': [
              {'key': '08:00', 'label': '8:00 AM'},
              {'key': '10:00', 'label': '10:00 AM'},
            ],
          },
          sections: const [
            ChecklistSectionData(
              id: 1,
              key: 'sec-restroom',
              title: 'Restroom Section',
              sortOrder: 1,
              metadata: {},
              items: [
                ChecklistItemData(
                  id: 201,
                  key: 'sink_cleanliness',
                  prompt: 'Sink is clean and dry',
                  sortOrder: 1,
                  metadata: {},
                ),
              ],
            ),
          ],
        ),
        submission: const ChecklistSubmissionData(
          id: 2,
          status: 'draft',
          auditDate: '2026-09-02',
          templateVersion: 1,
          scores: {'bad': 1},
          responses: {
            'sink_cleanliness': ChecklistResponseData(
              itemId: 201,
              itemKey: 'sink_cleanliness',
              status: null,
              remark: 'Water leak',
              finding: '',
              actionPlan: '',
              commitmentDate: null,
              details: {
                'slots': {
                  '08:00': 'good',
                  '10:00': 'not_good',
                },
              },
            ),
          },
          answeredItems: 2,
          totalItems: 2,
          completionPercentage: 100,
          submittedAt: null,
          issueCount: 1,
        ),
      );

      final repository = _HomeRepository(
        [
          _catalog(
            slug: 'restroom',
            name: 'Restroom Checklist',
            itemCount: 1,
            workUnitCount: 2,
            settings: const {
              'validation_mode': 'time_slots',
              'time_slots': [
                {'key': '08:00', 'label': '8:00 AM'},
                {'key': '10:00', 'label': '10:00 AM'},
              ],
            },
            submission: _submission(
              status: 'draft',
              answered: 2,
              total: 2,
              issueCount: 1,
            ),
          ),
        ],
        {'restroom': record},
      );

      String? openedSlug;
      String? openedSlot;
      String? openedItemKey;

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: UserHomeScreen(
            isActive: true,
            repository: repository,
            now: () => DateTime(2026, 9, 2, 8, 30),
            onOpenChecklists: () {},
            onOpenProfile: () {},
            onOpenNotifications: () {},
            onOpenChecklistWithQuestion: (slug, date, slotKey, itemKey) {
              openedSlug = slug;
              openedSlot = slotKey;
              openedItemKey = itemKey;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restroom Checklist').first);
      await tester.pumpAndSettle();

      expect(openedSlug, 'restroom');
      expect(openedItemKey, 'sink_cleanliness');
      expect(openedSlot, '10:00');
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
  _HomeRepository(this.tasks, [this.records = const {}]);

  final List<ChecklistCatalogItem> tasks;
  final Map<String, ChecklistLoadResult> records;
  final List<String?> requestedDates = [];

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async {
    requestedDates.add(date);
    return tasks;
  }

  @override
  Future<ChecklistLoadResult> fetchChecklist(String slug, {String? date}) async {
    final record = records[slug];
    if (record != null) return record;
    throw UnimplementedError('No record for $slug');
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
    Map<String, dynamic>? context,
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
    description: 'Assigned from Server.',
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

ChecklistLoadResult _attentionRecord(String slug, List<String?> statuses) {
  final hourly = slug == 'restroom';
  return ChecklistLoadResult(
    template: ChecklistTemplateData(
      id: 1,
      slug: slug,
      name: 'Test checklist',
      description: null,
      version: 1,
      settings: {
        'validation_mode': hourly ? 'time_slots' : 'yes_no_na',
        if (hourly) 'time_slots': [{'key': '08:00', 'label': '8 AM'}],
      },
      sections: [ChecklistSectionData(
        id: 1, key: 'section', title: 'Section', sortOrder: 1, metadata: const {},
        items: [for (var i = 0; i < statuses.length; i++) ChecklistItemData(
          id: i + 1, key: 'q$i', prompt: 'Question $i', sortOrder: i, metadata: const {},
        )],
      )],
    ),
    submission: ChecklistSubmissionData(
      id: 1, status: 'draft', auditDate: '2026-09-02', templateVersion: 1,
      scores: const {}, answeredItems: statuses.length, totalItems: statuses.length,
      completionPercentage: 100, submittedAt: null, issueCount: 99,
      responses: {for (var i = 0; i < statuses.length; i++) 'q$i': ChecklistResponseData(
        itemId: i + 1, itemKey: 'q$i', status: hourly ? null : statuses[i],
        remark: 'Old remark', finding: 'Old finding', actionPlan: 'Old plan',
        commitmentDate: null,
        details: hourly ? {'slots': {'08:00': statuses[i]}} : {'has_issue': true},
      )},
    ),
  );
}
