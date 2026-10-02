import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/screens/user_checklists_screen.dart';
import 'package:gac_flutter/services/checklist_service.dart';

class _MockChecklistRepository extends Fake implements ChecklistRepository {
  _MockChecklistRepository(this.items);

  final List<ChecklistCatalogItem> items;

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async => items;
}

void main() {
  testWidgets('Checklist at 100% but not submitted displays IN PROGRESS and CONTINUE CHECKLIST', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final task100NotSubmitted = ChecklistCatalogItem(
      id: 1,
      slug: 'sales',
      name: 'Sales 5S Inspection',
      description: 'Daily showroom checks',
      version: 1,
      settings: const {'validation_mode': 'yes_no_na'},
      itemCount: 10,
      sectionCount: 1,
      workUnitCount: 10,
      submission: const ChecklistSubmissionData(
        id: 101,
        templateVersion: 1,
        status: 'in_progress', // NOT submitted
        auditDate: '2026-09-19',
        totalItems: 10,
        answeredItems: 10, // 100% completed
        completionPercentage: 100.0,
        scores: {'answered': 10, 'total': 10},
        responses: {},
        submittedAt: null,
      ),
    );

    final repo = _MockChecklistRepository([task100NotSubmitted]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserChecklistsScreen(
            repository: repo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 100% answered on both individual and master card
    expect(find.text('10/10 · 100%'), findsNWidgets(2));

    // Status badge must be IN PROGRESS, NOT SUBMITTED
    expect(find.text('IN PROGRESS'), findsNWidgets(2));
    expect(find.text('SUBMITTED'), findsNothing);

    // Button must be CONTINUE CHECKLIST, NOT VIEW SUBMISSION
    expect(find.text('CONTINUE CHECKLIST'), findsNWidgets(2));
    expect(find.text('VIEW SUBMISSION'), findsNothing);
  });

  testWidgets('Checklist that is submitted displays SUBMITTED and VIEW SUBMISSION', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final taskSubmitted = ChecklistCatalogItem(
      id: 2,
      slug: 'sales',
      name: 'Sales 5S Inspection',
      description: 'Daily showroom checks',
      version: 1,
      settings: const {'validation_mode': 'yes_no_na'},
      itemCount: 10,
      sectionCount: 1,
      workUnitCount: 10,
      submission: ChecklistSubmissionData(
        id: 102,
        templateVersion: 1,
        status: 'submitted', // IS submitted
        auditDate: '2026-09-19',
        totalItems: 10,
        answeredItems: 10,
        completionPercentage: 100.0,
        scores: const {'answered': 10, 'total': 10},
        responses: const {},
        submittedAt: DateTime(2026, 9, 19, 12, 0),
      ),
    );

    final repo = _MockChecklistRepository([taskSubmitted]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserChecklistsScreen(
            repository: repo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Status badge must be SUBMITTED
    expect(find.text('SUBMITTED'), findsNWidgets(2));

    // Button must be VIEW SUBMISSION
    expect(find.text('VIEW SUBMISSION'), findsNWidgets(2));
  });
}
