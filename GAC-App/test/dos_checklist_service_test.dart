import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:gac_flutter/services/dos_checklist_service.dart';

void main() {
  group('DosChecklistService catalog scope', () {
    const roleCases = <_RoleCase>[
      _RoleCase(
        userType: 'SALES_MANAGER',
        slug: DosChecklistService.salesSlug,
        itemCount: 90,
        checkerCode: 'SALES MANAGER',
      ),
      _RoleCase(
        userType: 'DOS_SALES',
        slug: DosChecklistService.salesSlug,
        itemCount: 90,
        checkerCode: 'SALES MANAGER',
      ),
      _RoleCase(
        userType: 'DOS_AFTERSALES',
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 75,
        checkerCode: 'ALL',
      ),
      _RoleCase(
        userType: 'ASM',
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 50,
        checkerCode: 'ASM',
      ),
      _RoleCase(
        userType: 'CE_SERVICE',
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 9,
        checkerCode: 'CE SERVICE',
      ),
      _RoleCase(
        userType: 'JC',
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 1,
        checkerCode: 'JC',
      ),
      _RoleCase(
        userType: 'PARTS',
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 3,
        checkerCode: 'PARTS',
      ),
      _RoleCase(
        userType: 'WS_SUP',
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 12,
        checkerCode: 'WS SUP',
      ),
    ];

    for (final roleCase in roleCases) {
      test('${roleCase.userType} sees one normalized DOS assignment', () async {
        final delegate = _RecordingChecklistRepository(
          catalog: [
            _catalog(
              slug: DosChecklistService.aftersalesSlug,
              itemCount: 75,
              submission: _submission(answered: 99, total: 75),
            ),
            _catalog(
              slug: DosChecklistService.salesSlug,
              itemCount: 90,
              submission: _submission(answered: 99, total: 90),
            ),
            _catalog(slug: 'restroom', itemCount: 99),
          ],
        );
        final service = DosChecklistService(
          user: _user(roleCase.userType),
          delegate: delegate,
        );

        final catalog = await service.fetchCatalog(date: '2026-09-07');

        expect(service.isAuthorized, isTrue);
        expect(service.assignedSlug, roleCase.slug);
        expect(service.assignedItemCount, roleCase.itemCount);
        expect(service.checkerCode, roleCase.checkerCode);
        expect(delegate.catalogDates, ['2026-09-07']);
        expect(catalog, hasLength(1));
        expect(catalog.single.slug, roleCase.slug);
        expect(catalog.single.itemCount, roleCase.itemCount);
        expect(catalog.single.workUnitCount, roleCase.itemCount);
        expect(catalog.single.totalWorkUnits, roleCase.itemCount);
        expect(catalog.single.submission!.totalItems, roleCase.itemCount);
        expect(catalog.single.submission!.answeredItems, roleCase.itemCount);
        expect(catalog.single.submission!.completionPercentage, 100);
        expect(catalog.single.submission!.scores['total'], roleCase.itemCount);
        expect(
          catalog.single.submission!.scores['answered'],
          roleCase.itemCount,
        );
      });
    }

    test(
      'combines Workshop Supervisor Aftersales and Subform assignments',
      () async {
        final delegate = _RecordingChecklistRepository(
          catalog: [
            _catalog(
              slug: DosChecklistService.aftersalesSlug,
              itemCount: 75,
              submission: _submission(answered: 75, total: 75),
            ),
            _catalog(
              slug: DosChecklistService.subformSlug,
              itemCount: 39,
              submission: _submission(answered: 39, total: 39),
            ),
            _catalog(
              slug: DosChecklistService.documentationSlug,
              itemCount: 17,
            ),
          ],
        );
        final service = DosChecklistService(
          user: _user('WS_SUP'),
          delegate: delegate,
        );

        final catalog = await service.fetchCatalog();
        final bySlug = {for (final item in catalog) item.slug: item};

        expect(service.checkerCode, 'WS SUP');
        expect(service.assignedItemCount, 12);
        expect(service.allowedSlugs, [
          DosChecklistService.aftersalesSlug,
          DosChecklistService.subformSlug,
        ]);
        expect(
          bySlug.keys,
          unorderedEquals([
            DosChecklistService.aftersalesSlug,
            DosChecklistService.subformSlug,
          ]),
        );
        expect(bySlug[DosChecklistService.aftersalesSlug]!.itemCount, 12);
        expect(bySlug[DosChecklistService.subformSlug]!.itemCount, 16);
        expect(
          bySlug[DosChecklistService.aftersalesSlug]!.submission!.totalItems,
          12,
        );
        expect(
          bySlug[DosChecklistService.subformSlug]!.submission!.totalItems,
          16,
        );
      },
    );

    test(
      'recalculates completion against the assigned checker total',
      () async {
        final delegate = _RecordingChecklistRepository(
          catalog: [
            _catalog(
              slug: DosChecklistService.aftersalesSlug,
              itemCount: 75,
              submission: _submission(answered: 4, total: 75, issueCount: 2),
            ),
          ],
        );
        final service = DosChecklistService(
          user: _user('CE Service'),
          delegate: delegate,
        );

        final item = (await service.fetchCatalog()).single;

        expect(item.submission!.answeredItems, 4);
        expect(item.submission!.totalItems, 9);
        expect(item.submission!.completionPercentage, closeTo(44.444, 0.001));
        expect(item.submission!.issues, 2);
      },
    );
  });

  group('DosChecklistService delegation', () {
    test(
      'replaces a stale Sales API template with all 90 workbook standards',
      () async {
        final delegate = _RecordingChecklistRepository(
          catalog: const [],
          loadResult: const ChecklistLoadResult(
            template: ChecklistTemplateData(
              id: 77,
              slug: DosChecklistService.salesSlug,
              name: 'Server Sales Template',
              description: 'Stale server copy',
              version: 4,
              settings: {'validation_mode': 'dos'},
              sections: [
                ChecklistSectionData(
                  id: 88,
                  key: 'stale-section',
                  title: 'Stale section',
                  sortOrder: 0,
                  metadata: {},
                  items: [
                    ChecklistItemData(
                      id: 999,
                      key: 'server-standard-1',
                      prompt: 'Outdated prompt',
                      sortOrder: 0,
                      metadata: {'number': 1, 'how_to_check': 'Outdated guide'},
                    ),
                  ],
                ),
              ],
            ),
            submission: null,
          ),
        );
        final service = DosChecklistService(
          user: _user('DOS_SALES'),
          delegate: delegate,
        );

        final loaded = await service.fetchChecklist(
          DosChecklistService.salesSlug,
        );
        final items = loaded.template.sections
            .expand((section) => section.items)
            .toList();

        expect(loaded.template.id, 77);
        expect(loaded.template.version, 4);
        expect(loaded.template.sections, hasLength(13));
        expect(items, hasLength(90));
        expect(items.first.id, 999);
        expect(items.first.key, 'server-standard-1');
        expect(
          items.first.prompt,
          'Fascia or badge sign and letterings are complete, undamaged, clean, no watermarks, no obstructions, no discoloration and stains',
        );
        expect(
          items.first.metadata['how_to_check'],
          contains('MMPC VI Standard Requirements'),
        );
      },
    );

    test(
      'delegates authorized load, save, submit, and upload unchanged',
      () async {
        final delegate = _RecordingChecklistRepository(
          catalog: const [],
          loadResult: ChecklistLoadResult(
            template: _aftersalesTemplate,
            submission: _sharedSubmission,
          ),
        );
        final service = DosChecklistService(
          user: _user('WS_SUP'),
          delegate: delegate,
        );
        final responses = <Map<String, dynamic>>[
          {'item_key': 'dos-a1', 'status': 'yes'},
        ];

        final loaded = await service.fetchChecklist(
          DosChecklistService.aftersalesSlug,
          date: '2026-09-07',
        );
        final drafted = await service.saveDraft(
          DosChecklistService.aftersalesSlug,
          date: '2026-09-07',
          responses: responses,
        );
        final submitted = await service.submit(
          DosChecklistService.aftersalesSlug,
          date: '2026-09-07',
          responses: responses,
        );
        final uploaded = await service.uploadAttachment(
          DosChecklistService.aftersalesSlug,
          bytes: const [1, 2, 3],
          filename: 'finding.jpg',
        );

        expect(delegate.loadedSlugs, [DosChecklistService.aftersalesSlug]);
        expect(delegate.loadedDates, ['2026-09-07']);
        expect(delegate.draftSlug, DosChecklistService.aftersalesSlug);
        expect(delegate.submitSlug, DosChecklistService.aftersalesSlug);
        expect(delegate.savedDate, '2026-09-07');
        expect(delegate.savedResponses, responses);
        expect(delegate.uploadSlug, DosChecklistService.aftersalesSlug);
        expect(delegate.uploadedBytes, [1, 2, 3]);
        expect(delegate.uploadedFilename, 'finding.jpg');
        expect(uploaded, {'path': 'finding.jpg'});
        expect(loaded.submission!.totalItems, 12);
        expect(drafted.totalItems, 12);
        expect(submitted.totalItems, 12);
      },
    );

    test(
      'rejects another checklist slug before calling the delegate',
      () async {
        final delegate = _RecordingChecklistRepository(catalog: const []);
        final service = DosChecklistService(
          user: _user('SM'),
          delegate: delegate,
        );
        final forbidden = isA<ChecklistApiException>().having(
          (error) => error.status,
          'status',
          403,
        );

        await expectLater(
          service.fetchChecklist(DosChecklistService.aftersalesSlug),
          throwsA(forbidden),
        );
        await expectLater(
          service.saveDraft(
            'restroom',
            date: '2026-09-07',
            responses: const [],
          ),
          throwsA(forbidden),
        );
        await expectLater(
          service.submit('gateway-5s', date: '2026-09-07', responses: const []),
          throwsA(forbidden),
        );
        expect(
          () => service.uploadAttachment(
            'service',
            bytes: const [],
            filename: 'x.jpg',
          ),
          throwsA(forbidden),
        );
        expect(delegate.totalOperationCalls, 0);
      },
    );

    test('fails closed if the server returns a different template', () async {
      final delegate = _RecordingChecklistRepository(
        catalog: const [],
        loadResult: const ChecklistLoadResult(
          template: _salesTemplate,
          submission: null,
        ),
      );
      final service = DosChecklistService(
        user: _user('ASM'),
        delegate: delegate,
      );

      await expectLater(
        service.fetchChecklist(DosChecklistService.aftersalesSlug),
        throwsA(
          isA<ChecklistApiException>().having(
            (error) => error.status,
            'status',
            403,
          ),
        ),
      );
    });
  });

  group('DosChecklistService fail-closed behavior', () {
    for (final role in const ['PIC', 'ADMIN', 'GENERAL MANAGER', '']) {
      test(
        'rejects non-DOS role "$role" without touching the delegate',
        () async {
          final delegate = _RecordingChecklistRepository(catalog: const []);
          final service = DosChecklistService(
            user: _user(role),
            delegate: delegate,
          );
          final forbidden = isA<ChecklistApiException>().having(
            (error) => error.status,
            'status',
            403,
          );

          expect(service.isAuthorized, isFalse);
          expect(service.assignedSlug, isNull);
          await expectLater(service.fetchCatalog(), throwsA(forbidden));
          await expectLater(
            service.fetchChecklist(DosChecklistService.aftersalesSlug),
            throwsA(forbidden),
          );
          expect(delegate.totalOperationCalls, 0);
        },
      );
    }
  });
}

const _aftersalesTemplate = ChecklistTemplateData(
  id: 1,
  slug: DosChecklistService.aftersalesSlug,
  name: 'Dealer Operations Standards - Aftersales',
  description: null,
  version: 1,
  settings: {'validation_mode': 'dos'},
  sections: [],
);

const _salesTemplate = ChecklistTemplateData(
  id: 2,
  slug: DosChecklistService.salesSlug,
  name: 'Dealer Operations Standards - Sales',
  description: null,
  version: 1,
  settings: {'validation_mode': 'dos'},
  sections: [],
);

const _sharedSubmission = ChecklistSubmissionData(
  id: 4,
  status: 'draft',
  auditDate: '2026-09-07',
  templateVersion: 1,
  scores: {'total': 75, 'answered': 5},
  responses: {},
  answeredItems: 5,
  totalItems: 75,
  completionPercentage: 6.666,
  submittedAt: null,
  issueCount: 1,
);

AuthenticatedUser _user(String userType) => AuthenticatedUser(
  id: 10,
  name: 'DOS User',
  email: 'dos.user@gateway.com',
  userType: userType,
  accountStatus: 'active',
);

ChecklistCatalogItem _catalog({
  required String slug,
  required int itemCount,
  ChecklistSubmissionData? submission,
}) {
  return ChecklistCatalogItem(
    id: slug.hashCode,
    slug: slug,
    name: slug,
    description: 'Assigned checklist',
    version: 1,
    settings: const {'validation_mode': 'dos'},
    sectionCount: 1,
    itemCount: itemCount,
    workUnitCount: itemCount,
    submission: submission,
  );
}

ChecklistSubmissionData _submission({
  required int answered,
  required int total,
  int issueCount = 0,
}) {
  return ChecklistSubmissionData(
    id: 1,
    status: 'draft',
    auditDate: '2026-09-07',
    templateVersion: 1,
    scores: {'total': total, 'answered': answered, 'no': issueCount},
    responses: const {},
    answeredItems: answered,
    totalItems: total,
    completionPercentage: total == 0 ? 0 : (answered / total) * 100,
    submittedAt: null,
    issueCount: issueCount,
  );
}

class _RoleCase {
  const _RoleCase({
    required this.userType,
    required this.slug,
    required this.itemCount,
    required this.checkerCode,
  });

  final String userType;
  final String slug;
  final int itemCount;
  final String checkerCode;
}

class _RecordingChecklistRepository implements ChecklistRepository {
  _RecordingChecklistRepository({
    required this.catalog,
    this.loadResult = const ChecklistLoadResult(
      template: _aftersalesTemplate,
      submission: _sharedSubmission,
    ),
  });

  final List<ChecklistCatalogItem> catalog;
  final ChecklistLoadResult loadResult;

  final List<String?> catalogDates = [];
  final List<String> loadedSlugs = [];
  final List<String?> loadedDates = [];
  String? draftSlug;
  String? submitSlug;
  String? savedDate;
  List<Map<String, dynamic>>? savedResponses;
  String? uploadSlug;
  List<int>? uploadedBytes;
  String? uploadedFilename;

  int get totalOperationCalls =>
      catalogDates.length +
      loadedSlugs.length +
      (draftSlug == null ? 0 : 1) +
      (submitSlug == null ? 0 : 1) +
      (uploadSlug == null ? 0 : 1);

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async {
    catalogDates.add(date);
    return catalog;
  }

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    loadedSlugs.add(slug);
    loadedDates.add(date);
    return loadResult;
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    draftSlug = slug;
    savedDate = date;
    savedResponses = responses;
    return _sharedSubmission;
  }

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    submitSlug = slug;
    savedDate = date;
    savedResponses = responses;
    return _sharedSubmission;
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) async {
    uploadSlug = slug;
    uploadedBytes = bytes;
    uploadedFilename = filename;
    return {'path': filename};
  }
}
