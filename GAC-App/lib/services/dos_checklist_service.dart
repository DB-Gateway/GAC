import 'dart:math' as math;

import '../data/admin_data.dart';
import '../models/authenticated_user.dart';
import '../models/checklist_models.dart';
import 'checklist_service.dart';

/// Restricts checklist access to the DOS assignment owned by [user].
///
/// This decorator is intentionally role-based rather than email-based. The
/// server remains the source of truth for the authenticated user's role, while
/// this client-side boundary prevents a DOS workspace from accidentally
/// listing or opening another checklist type.
class DosChecklistService implements ChecklistRepository {
  DosChecklistService({
    required AuthenticatedUser user,
    ChecklistRepository? delegate,
  }) : _delegate = delegate ?? ChecklistApiService(),
       _scope = _DosChecklistScope.forUser(user);

  static const salesSlug = 'dealer-operations-standards-sales';
  static const aftersalesSlug = 'dealer-operations-standards';
  static const subformSlug = 'dealer-operations-standards-subform';
  static const documentationSlug = 'dealer-operations-standards-documentation';

  final ChecklistRepository _delegate;
  final _DosChecklistScope? _scope;

  bool get isAssigned => _scope != null;
  bool get isAuthorized => isAssigned;
  String? get assignedSlug => _scope?.slug;
  int? get assignedItemCount => _scope?.itemCount;
  String? get checkerCode => _scope?.checkerCode;
  List<String> get allowedSlugs => _scope?.allowedSlugs ?? const [];

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async {
    final scope = _requireScope();
    final catalog = await _delegate.fetchCatalog(date: date);

    return catalog
        .where((item) => scope.allows(item.slug))
        .map(
          (item) => _normalizeCatalogItem(item, scope.itemCountFor(item.slug)),
        )
        .toList();
  }

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    final scope = _authorizeSlug(slug);
    try {
      final result = await _delegate.fetchChecklist(slug, date: date);
      if (!scope.allows(result.template.slug)) {
        throw const ChecklistApiException(
          'The checklist returned by the server is not assigned to this account.',
          status: 403,
        );
      }

      final count = scope.itemCountFor(slug);
      return ChecklistLoadResult(
        template: slug == DosChecklistService.salesSlug
            ? buildDosSalesTemplateData(source: result.template)
            : result.template,
        submission: _normalizeSubmission(result.submission, count),
      );
    } catch (e) {
      if (slug == DosChecklistService.subformSlug) {
        return ChecklistLoadResult(
          template: buildSubformTemplateData(),
          submission: null,
        );
      }
      if (slug == DosChecklistService.documentationSlug) {
        return ChecklistLoadResult(
          template: buildDocumentationTemplateData(),
          submission: null,
        );
      }
      rethrow;
    }
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    final scope = _authorizeSlug(slug);
    final submission = await _delegate.saveDraft(
      slug,
      date: date,
      responses: responses,
    );
    return _normalizeSubmission(submission, scope.itemCountFor(slug))!;
  }

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    final scope = _authorizeSlug(slug);
    final submission = await _delegate.submit(
      slug,
      date: date,
      responses: responses,
    );
    return _normalizeSubmission(submission, scope.itemCountFor(slug))!;
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) {
    _authorizeSlug(slug);
    return _delegate.uploadAttachment(slug, bytes: bytes, filename: filename);
  }

  _DosChecklistScope _requireScope() {
    final scope = _scope;
    if (scope != null) return scope;
    throw const ChecklistApiException(
      'This account is not assigned to a DOS checklist.',
      status: 403,
    );
  }

  _DosChecklistScope _authorizeSlug(String slug) {
    final scope = _requireScope();
    if (!scope.allows(slug.trim())) {
      throw const ChecklistApiException(
        'This checklist is not assigned to your DOS role.',
        status: 403,
      );
    }
    return scope;
  }

  ChecklistCatalogItem _normalizeCatalogItem(
    ChecklistCatalogItem item,
    int assignedItemCount,
  ) {
    return ChecklistCatalogItem(
      id: item.id,
      slug: item.slug,
      name: item.name,
      description: item.description,
      version: item.version,
      settings: item.settings,
      sectionCount: item.sectionCount,
      itemCount: assignedItemCount,
      workUnitCount: assignedItemCount,
      submission: _normalizeSubmission(item.submission, assignedItemCount),
    );
  }

  ChecklistSubmissionData? _normalizeSubmission(
    ChecklistSubmissionData? submission,
    int assignedItemCount,
  ) {
    if (submission == null) return null;

    final rawAnswered = submission.answeredItems ?? submission.responses.length;
    final answered = rawAnswered.clamp(0, assignedItemCount).toInt();
    final issueCount = math.min(submission.issues, answered);
    final scores = Map<String, dynamic>.of(submission.scores)
      ..['total'] = assignedItemCount
      ..['answered'] = answered;

    return ChecklistSubmissionData(
      id: submission.id,
      status: submission.status,
      auditDate: submission.auditDate,
      templateVersion: submission.templateVersion,
      scores: scores,
      responses: submission.responses,
      answeredItems: answered,
      totalItems: assignedItemCount,
      completionPercentage: assignedItemCount == 0
          ? 0
          : (answered / assignedItemCount) * 100,
      submittedAt: submission.submittedAt,
      issueCount: issueCount,
    );
  }
}

class _DosChecklistScope {
  const _DosChecklistScope({
    required this.slug,
    required this.itemCount,
    required this.checkerCode,
    this.allowedSlugs = const [],
    this.itemCounts = const {},
  });

  final String slug;
  final int itemCount;
  final String checkerCode;
  final List<String> allowedSlugs;
  final Map<String, int> itemCounts;

  bool allows(String s) => s == slug || allowedSlugs.contains(s);

  int itemCountFor(String s) => itemCounts[s] ?? (s == slug ? itemCount : 0);

  static _DosChecklistScope? forUser(AuthenticatedUser user) {
    final role = normalizeUserType(user.userType)
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .trim();

    return switch (role) {
      'SM' ||
      'SALES MANAGER' ||
      'SALES MGR' ||
      'DOS SALES' => const _DosChecklistScope(
        slug: DosChecklistService.salesSlug,
        itemCount: 90,
        checkerCode: 'SALES MANAGER',
        allowedSlugs: [DosChecklistService.salesSlug],
        itemCounts: {DosChecklistService.salesSlug: 90},
      ),
      'DOS AFTERSALES' => const _DosChecklistScope(
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 75,
        checkerCode: 'ALL',
        allowedSlugs: [DosChecklistService.aftersalesSlug],
        itemCounts: {DosChecklistService.aftersalesSlug: 75},
      ),
      'ASM' ||
      'AFTERSALES MANAGER' ||
      'AFTERSALES MGR' ||
      'AS MGR' => const _DosChecklistScope(
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 50,
        checkerCode: 'ASM',
        allowedSlugs: [
          DosChecklistService.aftersalesSlug,
          DosChecklistService.subformSlug,
        ],
        itemCounts: {
          DosChecklistService.aftersalesSlug: 50,
          DosChecklistService.subformSlug: 3,
        },
      ),
      'CE' ||
      'CE SERVICE' ||
      'CUSTOMER EXPERIENCE' ||
      'CUSTOMER EXPERIENCE SERVICE' => const _DosChecklistScope(
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 9,
        checkerCode: 'CE SERVICE',
        allowedSlugs: [
          DosChecklistService.aftersalesSlug,
          DosChecklistService.subformSlug,
          DosChecklistService.documentationSlug,
        ],
        itemCounts: {
          DosChecklistService.aftersalesSlug: 9,
          DosChecklistService.subformSlug: 20,
          DosChecklistService.documentationSlug: 17,
        },
      ),
      'JC' || 'JOB CONTROLLER' => const _DosChecklistScope(
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 1,
        checkerCode: 'JC',
        allowedSlugs: [DosChecklistService.aftersalesSlug],
        itemCounts: {DosChecklistService.aftersalesSlug: 1},
      ),
      'PARTS' || 'PARTS SUPERVISOR' => const _DosChecklistScope(
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 3,
        checkerCode: 'PARTS',
        allowedSlugs: [DosChecklistService.aftersalesSlug],
        itemCounts: {DosChecklistService.aftersalesSlug: 3},
      ),
      'WS SUP' => const _DosChecklistScope(
        slug: DosChecklistService.aftersalesSlug,
        itemCount: 12,
        checkerCode: 'WS SUP',
        allowedSlugs: [
          DosChecklistService.aftersalesSlug,
          DosChecklistService.subformSlug,
        ],
        itemCounts: {
          DosChecklistService.aftersalesSlug: 12,
          DosChecklistService.subformSlug: 16,
        },
      ),
      _ => null,
    };
  }
}
