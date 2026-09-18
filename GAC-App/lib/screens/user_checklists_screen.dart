import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../data/admin_data.dart';
import '../models/authenticated_user.dart';
import '../models/checklist_models.dart';
import '../services/checklist_service.dart';
import '../theme/gac_theme.dart';
import '../utils/checklist_time_slot.dart';
import '../widgets/gac_surfaces.dart';
import '../widgets/user_floating_header.dart';
import 'dos_dashboard_screen.dart';
import 'user_checklist_detail_screen.dart';
import 'user_notifications_screen.dart';

enum _ChecklistFilter { all, sales, service, restroom, dos }

enum _DosViewMode { byCategory, byCoverage, completeAudit }

class UserChecklistsScreen extends StatefulWidget {
  const UserChecklistsScreen({
    this.isActive = true,
    this.onOpenChecklist,
    this.onOpenCategoryChecklist,
    this.repository,
    this.initialSlug,
    this.initialSlotKey,
    this.initialAuditDate,
    this.initialSubmissionId,
    this.initialItemKey,
    this.initialCustomerIndex,
    this.onBack,
    this.user,
    this.activeTrack,
    this.onTrackChanged,
    this.now,
    this.onOpenNotifications,
    this.onOpenProfile,
    this.unreadNotifications = 0,
    this.title,
    this.subtitle,
    super.key,
  });

  final bool isActive;
  final ValueChanged<String>? onOpenChecklist;
  final void Function(
    String slug, {
    String? categoryFilter,
    int? sectionIndex,
    int? initialQuestionIndex,
  })?
  onOpenCategoryChecklist;
  final ChecklistRepository? repository;
  final String? initialSlug;
  final String? initialSlotKey;
  final String? initialAuditDate;
  final int? initialSubmissionId;
  final String? initialItemKey;
  final int? initialCustomerIndex;
  final VoidCallback? onBack;
  final AuthenticatedUser? user;
  final DosAuditTrack? activeTrack;
  final ValueChanged<DosAuditTrack>? onTrackChanged;
  final DateTime Function()? now;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;
  final int unreadNotifications;
  final String? title;
  final String? subtitle;

  @override
  State<UserChecklistsScreen> createState() => _UserChecklistsScreenState();
}

class _UserChecklistsScreenState extends State<UserChecklistsScreen>
    with WidgetsBindingObserver {
  ChecklistRepository get _repository =>
      widget.repository ?? ChecklistApiService();
  List<ChecklistCatalogItem> _checklists = const [];
  ChecklistLoadResult? _dosRecord;
  ChecklistLoadResult? _docRecord;
  _ChecklistFilter _filter = _ChecklistFilter.all;
  _DosViewMode _dosViewMode = _DosViewMode.byCategory;
  late final ScrollController _scrollController;
  bool _topBarExpanded = true;
  DosAuditTrack? _internalTrack;
  bool _loading = true;
  bool _openedInitialChecklist = false;
  int _requestGeneration = 0;
  String? _error;

  bool get _isDosWorkspace {
    if (widget.activeTrack != null) return true;
    final user = widget.user;
    if (user != null) {
      if (user.is5sUtilities ||
          user.is5sService ||
          user.is5sSales ||
          user.isUtilities ||
          user.isSalesService5s) {
        return false;
      }
      if (user.isDosAuditor ||
          user.isSalesManager ||
          user.isAftersalesChecker ||
          user.isDosSales ||
          user.isDosAftersales ||
          user.userType.trim().toUpperCase() == 'DOS') {
        return true;
      }
    }
    return false;
  }

  bool get _isDosViewActive =>
      _isDosWorkspace || _filter == _ChecklistFilter.dos;

  DosAuditTrack get _effectiveTrack {
    final user = widget.user;
    if (user != null) {
      if (user.isDosSales || user.isSalesManager) return DosAuditTrack.sales;
      if (user.isDosAftersales || user.isAftersalesChecker) {
        return DosAuditTrack.aftersales;
      }
    }
    if (_internalTrack != null) return _internalTrack!;
    if (widget.activeTrack != null) return widget.activeTrack!;
    return DosAuditTrack.sales;
  }

  String get _activeDosSlug => _effectiveTrack == DosAuditTrack.sales
      ? 'dealer-operations-standards-sales'
      : 'dealer-operations-standards';

  List<_ChecklistFilter> get _availableFilters {
    final user = widget.user;
    if (user != null) {
      if (user.is5sSales) {
        return const [_ChecklistFilter.sales];
      }
      if (user.is5sService) {
        return const [_ChecklistFilter.service];
      }
      if (user.is5sUtilities || user.isUtilities) {
        return const [_ChecklistFilter.restroom];
      }
      if (user.isSalesService5s) {
        return const [_ChecklistFilter.sales, _ChecklistFilter.service];
      }
      if (user.isDosSales || user.isDosAftersales) {
        return const [_ChecklistFilter.dos];
      }
    }
    return _ChecklistFilter.values;
  }

  List<ChecklistCatalogItem> get _visibleChecklists {
    final user = widget.user;
    var base = _checklists
        .where((item) => item.slug != 'dealer-operations-standards-subform')
        .toList(growable: false);
    if (user != null) {
      if (user.is5sSales) {
        base = base
            .where((item) => item.slug == 'sales')
            .toList(growable: false);
      } else if (user.is5sService) {
        base = base
            .where((item) => item.slug == 'service')
            .toList(growable: false);
      } else if (user.is5sUtilities || user.isUtilities) {
        base = base
            .where(
              (item) => item.slug == 'restroom' || item.slug == 'utilities',
            )
            .toList(growable: false);
      } else if (user.isSalesService5s) {
        base = base
            .where(
              (item) =>
                  const {'sales', 'service', 'gateway-5s'}.contains(item.slug),
            )
            .toList(growable: false);
      } else if (user.isDosSales) {
        base = base
            .where((item) => item.slug == 'dealer-operations-standards-sales')
            .toList(growable: false);
      } else if (user.isDosAftersales) {
        base = base
            .where(
              (item) =>
                  item.slug == 'dealer-operations-standards' ||
                  (user.canAccessDocumentation &&
                      item.slug == 'dealer-operations-standards-documentation'),
            )
            .toList(growable: false);
      }
    }

    return switch (_filter) {
      _ChecklistFilter.all => base,
      _ChecklistFilter.sales =>
        base.where((item) => item.slug == 'sales').toList(growable: false),
      _ChecklistFilter.service =>
        base.where((item) => item.slug == 'service').toList(growable: false),
      _ChecklistFilter.dos =>
        base
            .where(
              (item) => const {
                'dealer-operations-standards',
                'dealer-operations-standards-sales',
                'dealer-operations-standards-documentation',
              }.contains(item.slug),
            )
            .toList(growable: false),
      _ChecklistFilter.restroom =>
        base
            .where(
              (item) => item.slug == 'restroom' || item.slug == 'utilities',
            )
            .toList(growable: false),
    };
  }

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    if (_isDosWorkspace) {
      _filter = _ChecklistFilter.dos;
    } else if (user != null && user.is5sSales) {
      _filter = _ChecklistFilter.sales;
    } else if (user != null && user.is5sService) {
      _filter = _ChecklistFilter.service;
    } else if (user != null && (user.is5sUtilities || user.isUtilities)) {
      _filter = _ChecklistFilter.restroom;
    } else if (user != null && user.isSalesService5s) {
      _filter = _ChecklistFilter.sales;
    }
    _scrollController = ScrollController()..addListener(_handleScroll);
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didUpdateWidget(covariant UserChecklistsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trackChanged =
        oldWidget.activeTrack != widget.activeTrack &&
        widget.activeTrack != null;
    final userChanged = oldWidget.user != widget.user;
    final repoChanged = oldWidget.repository != widget.repository;

    if (trackChanged || userChanged || repoChanged) {
      if (trackChanged) {
        _internalTrack = widget.activeTrack;
      }
      if (userChanged) {
        final user = widget.user;
        if (_isDosWorkspace) {
          _filter = _ChecklistFilter.dos;
        } else if (user != null && user.is5sSales) {
          _filter = _ChecklistFilter.sales;
        } else if (user != null && user.is5sService) {
          _filter = _ChecklistFilter.service;
        } else if (user != null && (user.is5sUtilities || user.isUtilities)) {
          _filter = _ChecklistFilter.restroom;
        } else if (user != null && user.isSalesService5s) {
          _filter = _ChecklistFilter.sales;
        }
      }
      _dosRecord = null;
      _error = null;
    }

    if (trackChanged ||
        userChanged ||
        repoChanged ||
        (!oldWidget.isActive && widget.isActive)) {
      _load(showSpinner: false);
    }
  }

  @override
  void dispose() {
    _requestGeneration++;
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(showSpinner: false);
  }

  Future<void> _load({bool showSpinner = true}) async {
    final generation = ++_requestGeneration;
    if (showSpinner && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final dateStr = _dateString((widget.now ?? DateTime.now)());
      final checklists = await _repository.fetchCatalog(date: dateStr);
      if (!mounted || generation != _requestGeneration) return;
      final catalog = checklists
          .where((e) => e.slug != 'dealer-operations-standards-subform')
          .toList(growable: false);
      final updatedChecklists = List<ChecklistCatalogItem>.of(catalog);
      final user = widget.user;
      ChecklistLoadResult? docRecord;
      if (user != null && user.canAccessDocumentation) {
        try {
          docRecord = await _repository.fetchChecklist(
            'dealer-operations-standards-documentation',
            date: dateStr,
          );
        } catch (_) {
          // Fallback gracefully to template
        }
      }

      final docIndex = updatedChecklists.indexWhere(
        (e) => e.slug == 'dealer-operations-standards-documentation',
      );
      if (user != null && user.canAccessDocumentation) {
        if (docIndex >= 0) {
          if (docRecord?.submission != null) {
            updatedChecklists[docIndex] = updatedChecklists[docIndex].copyWith(
              submission: docRecord!.submission,
            );
          }
        } else {
          updatedChecklists.add(
            ChecklistCatalogItem(
              id: 11,
              slug: 'dealer-operations-standards-documentation',
              name: 'Dealer Operations Standards - Documentation',
              description:
                  'FY2025 Aftersales Standards Compliance Audit Documentation Sheet',
              version: 1,
              settings: const {'validation_mode': 'dos_documentation'},
              sectionCount: 3,
              itemCount: 17,
              workUnitCount: 17,
              submission: docRecord?.submission,
            ),
          );
        }
      }
      ChecklistLoadResult? dosRecord;
      try {
        dosRecord = await _repository.fetchChecklist(
          _activeDosSlug,
          date: dateStr,
        );
      } catch (_) {
        // Fallback gracefully to template
      }
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _checklists = updatedChecklists;
        _dosRecord = dosRecord;
        _docRecord = docRecord;
        _loading = false;
        _error = null;
      });
      _openInitialChecklist(updatedChecklists);
    } on ChecklistApiException catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loading = false;
        _error = 'The checklists could not be loaded from Laravel.';
      });
    }
  }

  void _openInitialChecklist(List<ChecklistCatalogItem> checklists) {
    final slug = widget.initialSlug;
    if (_openedInitialChecklist || slug == null || slug.trim().isEmpty) return;
    _openedInitialChecklist = true;

    final authorizedChecklists = _visibleChecklists;
    ChecklistCatalogItem? target;
    for (final checklist in authorizedChecklists) {
      if (checklist.slug == slug) {
        target = checklist;
        break;
      }
    }
    if (target == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openChecklist(
          target!,
          initialSlotKey: widget.initialSlotKey,
          auditDate: widget.initialAuditDate,
          expectedDraftId: widget.initialSubmissionId,
          initialItemKey: widget.initialItemKey,
          initialCustomerIndex: widget.initialCustomerIndex,
        );
      }
    });
  }

  Future<void> _openChecklist(
    ChecklistCatalogItem checklist, {
    String? initialSlotKey,
    String? auditDate,
    int? initialQuestionIndex,
    int? expectedDraftId,
    String? initialItemKey,
    int? initialCustomerIndex,
  }) async {
    final submission = checklist.submission;
    final target =
        submission != null &&
            !submission.isSubmitted &&
            (submission.effectiveAnsweredItems > 0 ||
                (submission.completionPercentage ?? 0) > 0)
        ? _latestResumeTarget(_visibleChecklists)
        : null;
    final resolvedChecklist = target ?? checklist;
    final resolvedSubmission = resolvedChecklist.submission;
    final isContinuing =
        resolvedSubmission != null &&
        !resolvedSubmission.isSubmitted &&
        resolvedSubmission.hasStarted;
    final resolvedSlotKey =
        initialSlotKey ??
        (isContinuing
            ? checklistSlotForLocalTime(
                resolvedChecklist,
                (widget.now ?? DateTime.now)(),
              )
            : null);

    final callback = widget.onOpenChecklist;
    if (callback != null) {
      callback(resolvedChecklist.slug);
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UserChecklistDetailScreen(
          slug: resolvedChecklist.slug,
          repository: _repository,
          initialSlotKey: resolvedSlotKey,
          initialQuestionIndex: initialQuestionIndex,
          expectedDraftId: expectedDraftId,
          initialItemKey: initialItemKey,
          initialCustomerIndex: initialCustomerIndex,
          auditDate: auditDate,
          user: widget.user,
          nowProvider: widget.now,
          onOpenNotifications: widget.onOpenNotifications,
          unreadNotifications: widget.unreadNotifications,
        ),
      ),
    );
    if (mounted) await _load(showSpinner: false);
  }

  Future<void> _openCategoryChecklist(
    String slug, {
    String? categoryFilter,
    int? sectionIndex,
    int? initialQuestionIndex,
  }) async {
    final callback = widget.onOpenCategoryChecklist;
    if (callback != null) {
      callback(
        slug,
        categoryFilter: categoryFilter,
        sectionIndex: sectionIndex,
        initialQuestionIndex: initialQuestionIndex,
      );
      return;
    }

    final generalCallback = widget.onOpenChecklist;
    if (generalCallback != null &&
        categoryFilter == null &&
        sectionIndex == null &&
        initialQuestionIndex == null) {
      generalCallback(slug);
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UserChecklistDetailScreen(
          slug: slug,
          categoryFilter: categoryFilter,
          initialSectionIndex: sectionIndex,
          initialQuestionIndex: initialQuestionIndex,
          repository: _repository,
          auditDate: widget.initialAuditDate,
          user: widget.user,
          activeTrack: _effectiveTrack,
          onOpenNotifications: widget.onOpenNotifications,
          unreadNotifications: widget.unreadNotifications,
        ),
      ),
    );
    if (mounted) await _load(showSpinner: false);
  }

  List<ChecklistItemData> _getEffectiveDosItems() {
    final record = _dosRecord;
    List<ChecklistItemData> items;
    if (record != null && record.template.sections.isNotEmpty) {
      items = record.template.sections
          .expand((sec) => sec.items)
          .toList(growable: false);
    } else if (_effectiveTrack == DosAuditTrack.sales) {
      items = dosTemplate
          .expand((sec) => sec.items)
          .map((item) {
            final num =
                int.tryParse(item.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return ChecklistItemData(
              id: num,
              key: item.id,
              prompt: item.text,
              sortOrder: num,
              metadata: {
                'number': num,
                'level': item.level,
                'category': item.level,
                'coverage': item.coverage,
                'subject': item.subject,
                'checker': item.checker,
              },
            );
          })
          .toList(growable: false);
    } else {
      items = dosAftersalesTemplate
          .expand((sec) => sec.items)
          .map((item) {
            final num =
                int.tryParse(item.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return ChecklistItemData(
              id: num,
              key: item.id,
              prompt: item.text,
              sortOrder: num,
              metadata: {
                'number': num,
                'level': item.level,
                'category': item.level,
                'coverage': item.coverage,
                'subject': item.subject,
                'checker': item.checker,
              },
            );
          })
          .toList(growable: false);
    }

    final user = widget.user;
    if (user != null && !user.isAdmin && !user.canSwitchDosTracks) {
      final hasCheckerData = items.any((it) => it.checker != null);
      if (hasCheckerData) {
        items = items
            .where((it) => user.matchesCheckerRole(it.checker))
            .toList(growable: false);
      }
    }
    return items;
  }

  List<ChecklistSectionData> _getEffectiveDosSections() {
    final record = _dosRecord;
    final List<ChecklistSectionData> rawSections;
    if (record != null && record.template.sections.isNotEmpty) {
      rawSections = record.template.sections;
    } else if (_effectiveTrack == DosAuditTrack.sales) {
      rawSections = dosTemplate
          .map(
            (sec) => ChecklistSectionData(
              id: 0,
              key: sec.id,
              title: sec.title,
              sortOrder: 0,
              metadata: const {},
              items: sec.items
                  .map((item) {
                    final num =
                        int.tryParse(
                          item.id.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;
                    return ChecklistItemData(
                      id: num,
                      key: item.id,
                      prompt: item.text,
                      sortOrder: num,
                      metadata: {
                        'number': num,
                        'level': item.level,
                        'category': item.level,
                        'coverage': item.coverage,
                        'subject': item.subject,
                        'checker': item.checker,
                      },
                    );
                  })
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);
    } else {
      rawSections = dosAftersalesTemplate
          .map(
            (sec) => ChecklistSectionData(
              id: 0,
              key: sec.id,
              title: sec.title,
              sortOrder: 0,
              metadata: const {},
              items: sec.items
                  .map((item) {
                    final num =
                        int.tryParse(
                          item.id.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;
                    return ChecklistItemData(
                      id: num,
                      key: item.id,
                      prompt: item.text,
                      sortOrder: num,
                      metadata: {
                        'number': num,
                        'level': item.level,
                        'category': item.level,
                        'coverage': item.coverage,
                        'subject': item.subject,
                        'checker': item.checker,
                      },
                    );
                  })
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);
    }

    final user = widget.user;
    if (user != null && !user.isAdmin && !user.canSwitchDosTracks) {
      final hasCheckerData = rawSections.any(
        (sec) => sec.items.any((it) => it.checker != null),
      );
      if (hasCheckerData) {
        final filtered = <ChecklistSectionData>[];
        for (final sec in rawSections) {
          final matchingItems = sec.items
              .where((it) => user.matchesCheckerRole(it.checker))
              .toList(growable: false);
          if (matchingItems.isNotEmpty) {
            filtered.add(
              ChecklistSectionData(
                id: sec.id,
                key: sec.key,
                title: sec.title,
                sortOrder: sec.sortOrder,
                metadata: sec.metadata,
                items: matchingItems,
              ),
            );
          }
        }
        return filtered;
      }
    }

    return rawSections;
  }

  bool _isItemAnswered(ChecklistItemData item) {
    final record = _dosRecord;
    if (record == null) return false;
    final responses = record.submission?.responses;
    if (responses == null) return false;
    final answer = responses[item.key];
    if (answer == null) return false;
    final status = answer.status?.trim().toLowerCase();
    if (status != null && status != 'unanswered' && status.isNotEmpty) {
      return true;
    }
    final choice = answer.details['choice']?.toString().trim().toLowerCase();
    if (choice != null && choice != 'unanswered' && choice.isNotEmpty) {
      return true;
    }
    return false;
  }

  _DosCategoryStats _computeCategoryStats({
    required String category,
    required String title,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    final allItems = _getEffectiveDosItems();
    final items = allItems
        .where(
          (it) =>
              (it.category ?? it.level ?? '').trim().toLowerCase() ==
              category.toLowerCase(),
        )
        .toList(growable: false);

    final total = items.length;
    final answered = items.where(_isItemAnswered).length;
    return _DosCategoryStats(
      category: category,
      title: title,
      subtitle: subtitle,
      total: total,
      answered: answered,
      accentColor: accentColor,
      icon: icon,
      completedLabel: _dosRecord?.submission?.isSubmitted ?? false
          ? 'Submitted'
          : 'Completed',
    );
  }

  _DosCategoryStats _computeMasterStats() {
    final allItems = _getEffectiveDosItems();
    final total = allItems.length;
    final answered = allItems.where(_isItemAnswered).length;
    final isAftersales = _effectiveTrack == DosAuditTrack.aftersales;
    final sectionsCount = _getEffectiveDosSections().length;

    return _DosCategoryStats(
      category: 'MASTER AUDIT',
      title: isAftersales
          ? 'Dealer Operations Standards — Aftersales'
          : 'Dealer Operations Standards — Sales',
      subtitle: isAftersales
          ? 'Complete FY2025 Aftersales Standards Compliance Audit ($total standards across $sectionsCount ${sectionsCount == 1 ? 'area' : 'areas'}).'
          : 'Complete FY2025 Sales Standards Compliance Audit ($total standards across $sectionsCount ${sectionsCount == 1 ? 'area' : 'areas'}).',
      total: total,
      answered: answered,
      accentColor: GacColors.primary,
      icon: Icons.assignment_rounded,
      completedLabel: _dosRecord?.submission?.isSubmitted ?? false
          ? 'Submitted'
          : 'Completed',
    );
  }

  List<_DosSectionStats> _computeSectionStats() {
    final sections = _getEffectiveDosSections();
    final stats = <_DosSectionStats>[];
    for (var i = 0; i < sections.length; i++) {
      final sec = sections[i];
      final total = sec.items.length;
      final answered = sec.items.where(_isItemAnswered).length;
      stats.add(
        _DosSectionStats(
          index: i,
          title: sec.title,
          total: total,
          answered: answered,
        ),
      );
    }
    return stats;
  }

  int _count(_ChecklistFilter filter) {
    final user = widget.user;
    var base = _checklists
        .where((item) => item.slug != 'dealer-operations-standards-subform')
        .toList(growable: false);
    if (user != null) {
      if (user.is5sSales) {
        base = base
            .where((item) => item.slug == 'sales')
            .toList(growable: false);
      } else if (user.is5sService) {
        base = base
            .where((item) => item.slug == 'service')
            .toList(growable: false);
      } else if (user.is5sUtilities || user.isUtilities) {
        base = base
            .where(
              (item) => item.slug == 'restroom' || item.slug == 'utilities',
            )
            .toList(growable: false);
      } else if (user.isSalesService5s) {
        base = base
            .where(
              (item) =>
                  const {'sales', 'service', 'gateway-5s'}.contains(item.slug),
            )
            .toList(growable: false);
      } else if (user.isDosSales) {
        base = base
            .where((item) => item.slug == 'dealer-operations-standards-sales')
            .toList(growable: false);
      } else if (user.isDosAftersales) {
        base = base
            .where(
              (item) =>
                  item.slug == 'dealer-operations-standards' ||
                  (user.canAccessDocumentation &&
                      item.slug == 'dealer-operations-standards-documentation'),
            )
            .toList(growable: false);
      }
    }

    return switch (filter) {
      _ChecklistFilter.all => base.length,
      _ChecklistFilter.sales =>
        base.where((item) => item.slug == 'sales').length,
      _ChecklistFilter.service =>
        base.where((item) => item.slug == 'service').length,
      _ChecklistFilter.dos =>
        base
            .where(
              (item) => const {
                'dealer-operations-standards',
                'dealer-operations-standards-sales',
                'dealer-operations-standards-documentation',
              }.contains(item.slug),
            )
            .length,
      _ChecklistFilter.restroom =>
        base
            .where(
              (item) => item.slug == 'restroom' || item.slug == 'utilities',
            )
            .length,
    };
  }

  ChecklistCatalogItem? _latestResumeTarget(List<ChecklistCatalogItem> tasks) {
    final candidates = tasks
        .where((task) {
          final submission = task.submission;
          if (submission == null || submission.isSubmitted) return false;
          final total = (submission.totalItems ?? 0) > 0
              ? submission.totalItems!
              : task.totalWorkUnits;
          final answered = submission.effectiveAnsweredItems;
          return (answered > 0 || (submission.completionPercentage ?? 0) > 0) &&
              (total == 0 || answered < total);
        })
        .toList(growable: false);

    if (candidates.isEmpty) return null;

    candidates.sort((left, right) {
      final leftAnswered = left.submission!.effectiveAnsweredItems;
      final rightAnswered = right.submission!.effectiveAnsweredItems;
      final leftTotal = (left.submission!.totalItems ?? 0) > 0
          ? left.submission!.totalItems!
          : left.totalWorkUnits;
      final rightTotal = (right.submission!.totalItems ?? 0) > 0
          ? right.submission!.totalItems!
          : right.totalWorkUnits;
      final leftProgress = leftTotal == 0
          ? left.submission!.completionPercentage ?? 0
          : (leftAnswered / leftTotal) * 100;
      final rightProgress = rightTotal == 0
          ? right.submission!.completionPercentage ?? 0
          : (rightAnswered / rightTotal) * 100;

      final progressDelta = rightProgress.compareTo(leftProgress);
      if (progressDelta != 0) return progressDelta;
      return rightAnswered.compareTo(leftAnswered);
    });

    return candidates.first;
  }

  void _handleScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.userScrollDirection == ScrollDirection.idle &&
        position.pixels > 8) {
      return;
    }

    final shouldExpand =
        position.pixels <= 8 ||
        position.userScrollDirection == ScrollDirection.forward;
    if (shouldExpand == _topBarExpanded) return;
    setState(() => _topBarExpanded = shouldExpand);
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleOpenNotifications() {
    if (widget.onOpenNotifications != null) {
      widget.onOpenNotifications!();
      return;
    }
    if (widget.user != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => UserNotificationsScreen(
            profile: widget.user!,
            onOpenProfile: widget.onOpenProfile ?? () {},
            onGoHome: () => Navigator.of(context).pop(),
            onOpenSettings: () {},
          ),
        ),
      );
    }
  }

  String get _headerTitle {
    if (widget.title != null) return widget.title!;
    if (_isDosWorkspace) {
      return _effectiveTrack == DosAuditTrack.sales
          ? 'Sales Audit'
          : 'Aftersales Audit';
    }
    return 'Checklists';
  }

  String? get _headerSubtitle {
    if (widget.subtitle != null) return widget.subtitle;
    return 'Audit Compliance App';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 380 ? 16.0 : 20.0;
    final bottomClearance = MediaQuery.viewPaddingOf(context).bottom;
    final isHomeTabOnly = widget.onBack != null || _isDosWorkspace;
    final bottomPadding = isHomeTabOnly
        ? (24 + bottomClearance)
        : (78 + 28 + bottomClearance);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: GacColors.canvas,
        systemNavigationBarColor: GacColors.canvas,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GacScreenBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              RefreshIndicator(
                edgeOffset: UserChecklistFloatingHeader.extent,
                onRefresh: () => _load(showSpinner: false),
                child: ListView(
                  key: const PageStorageKey<String>('user-checklist-scroll'),
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    UserChecklistFloatingHeader.extent + 12,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _ChecklistIntro(),
                            const SizedBox(height: 19),
                            _buildFilters(),
                            const SizedBox(height: 15),
                            _buildContent(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: UserChecklistFloatingHeader.extent,
                child: UserChecklistFloatingHeader(
                  expanded: _topBarExpanded,
                  user: widget.user,
                  title: _headerTitle,
                  subtitle: _headerSubtitle,
                  fontFamily: 'EurostileExtendedBlack',
                  onBack: widget.onBack,
                  onOpenProfile: widget.onOpenProfile,
                  onOpenNotifications: _handleOpenNotifications,
                  onTapTitle: _scrollToTop,
                  unreadNotifications: widget.unreadNotifications,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final available = _availableFilters;
    final showCategoryFilter = !_isDosWorkspace && available.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCategoryFilter) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in available) ...[
                  _FilterChip(
                    label: '${_filterLabel(filter)} · ${_count(filter)}',
                    selected: _filter == filter,
                    onTap: () => setState(() => _filter = filter),
                  ),
                  if (filter != available.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'BY CATEGORY',
                selected: _dosViewMode == _DosViewMode.byCategory,
                onTap: () =>
                    setState(() => _dosViewMode = _DosViewMode.byCategory),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'BY COVERAGE',
                selected: _dosViewMode == _DosViewMode.byCoverage,
                onTap: () =>
                    setState(() => _dosViewMode = _DosViewMode.byCoverage),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'COMPLETE AUDIT',
                selected: _dosViewMode == _DosViewMode.completeAudit,
                onTap: () =>
                    setState(() => _dosViewMode = _DosViewMode.completeAudit),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _ChecklistError(message: _error!, onRetry: _load);
    }

    if (_isDosViewActive) {
      return _buildDosCategoryContent();
    }

    return _buildGeneralCategoryContent();
  }

  Widget _buildGeneralCategoryContent() {
    final visible = _visibleChecklists;
    if (visible.isEmpty) {
      return const _ChecklistEmpty();
    }

    final masterStats = _computeGeneralMasterStats(visible);

    if (_dosViewMode == _DosViewMode.completeAudit) {
      if (masterStats.total == 0) {
        return const _ChecklistEmpty();
      }
      return _DosCategoryCard(
        stats: masterStats,
        onPressed: _openMasterChecklist,
      );
    }

    if (_dosViewMode == _DosViewMode.byCoverage) {
      final validItems = visible
          .where((item) {
            final total = item.submission?.totalItems ?? item.itemCount;
            return total > 0;
          })
          .toList(growable: false);

      if (validItems.isEmpty) {
        return const _ChecklistEmpty();
      }

      return Column(
        children: [
          for (var i = 0; i < validItems.length; i++) ...[
            _DosSectionCard(
              stats: _DosSectionStats(
                index: i,
                title: '${validItems[i].name} · ${validItems[i].categoryLabel}',
                total:
                    validItems[i].submission?.totalItems ??
                    validItems[i].itemCount,
                answered: validItems[i].submission?.answeredItems ?? 0,
              ),
              onPressed: () => _openChecklist(validItems[i]),
            ),
            if (i != validItems.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    // Default: By Category (Individual categorized checklists + Master Checklist)
    final itemsWithoutMaster = visible
        .where((item) => item.slug != 'gateway-5s')
        .toList(growable: false);

    final cards = <Widget>[];
    for (final item in itemsWithoutMaster) {
      final stats = _computeItemCategoryStats(item);
      if (stats.total > 0) {
        cards.add(
          _DosCategoryCard(stats: stats, onPressed: () => _openChecklist(item)),
        );
      }
    }
    if (masterStats.total > 0) {
      cards.add(
        _DosCategoryCard(stats: masterStats, onPressed: _openMasterChecklist),
      );
    }

    if (cards.isEmpty) {
      return const _ChecklistEmpty();
    }

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i != cards.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _openMasterChecklist() {
    final visible = _visibleChecklists;
    if (visible.isEmpty) return;

    for (final item in visible) {
      if (item.slug == 'gateway-5s') {
        _openChecklist(item);
        return;
      }
    }

    final incomplete = visible.firstWhere(
      (item) => !(item.submission?.isSubmitted ?? false),
      orElse: () => visible.first,
    );
    _openChecklist(incomplete);
  }

  _DosCategoryStats _computeItemCategoryStats(ChecklistCatalogItem item) {
    final (
      String category,
      Color accentColor,
      IconData icon,
      String subtitle,
    ) = switch (item.slug) {
      'sales' => (
        'SALES 5S',
        const Color(0xFF06B6D4),
        Icons.storefront_rounded,
        item.description ?? 'Showroom, customer lounge, sales desks, and vehicle display inspection.',
      ),
      'service' => (
        'SERVICE 5S',
        const Color(0xFF8B5CF6),
        Icons.car_repair_rounded,
        item.description ?? 'Service reception, customer waiting lounge, and workshop 5S inspection.',
      ),
      'restroom' => (
        'SANITATION',
        const Color(0xFF06B6D4),
        Icons.cleaning_services_rounded,
        item.description ?? 'Hourly restroom condition, cleanliness, and orderliness inspection.',
      ),
      'utilities' => (
        'FACILITIES',
        const Color(0xFF10B981),
        Icons.lightbulb_rounded,
        item.description ?? 'Daily facilities, lighting, power, and utility equipment inspection.',
      ),
      _ => (
        item.categoryLabel.toUpperCase(),
        GacColors.primary,
        _categoryIcon(item.slug),
        item.description ?? 'Compliance checklist inspection.',
      ),
    };

    final total = item.submission?.totalItems ?? item.itemCount;
    final answered = item.submission?.answeredItems ?? 0;

    return _DosCategoryStats(
      category: category,
      title: item.name,
      subtitle: subtitle,
      total: total,
      answered: answered,
      accentColor: accentColor,
      icon: icon,
    );
  }

  _DosCategoryStats _computeGeneralMasterStats(
    List<ChecklistCatalogItem> items,
  ) {
    final user = widget.user;
    final isSales =
        (user != null && user.is5sSales) || _filter == _ChecklistFilter.sales;
    final isService =
        (user != null && user.is5sService) ||
        _filter == _ChecklistFilter.service;
    final isUtil =
        (user != null && (user.is5sUtilities || user.isUtilities)) ||
        _filter == _ChecklistFilter.restroom;
    final is5s = (user != null && user.isSalesService5s);

    ChecklistCatalogItem? gatewayItem;
    for (final it in items) {
      if (it.slug == 'gateway-5s') {
        gatewayItem = it;
        break;
      }
    }

    if (gatewayItem != null) {
      final total = gatewayItem.submission?.totalItems ?? gatewayItem.itemCount;
      final answered = gatewayItem.submission?.answeredItems ?? 0;
      return _DosCategoryStats(
        category: 'MASTER CHECKLIST',
        title: gatewayItem.name.isNotEmpty
            ? gatewayItem.name
            : 'Complete 5S Master Audit',
        subtitle: gatewayItem.description ?? 'Complete daily pre-business-hours 5S audit across both Sales and Service areas.',
        total: total,
        answered: answered,
        accentColor: GacColors.primary,
        icon: Icons.assignment_turned_in_rounded,
      );
    }

    final total = items.fold<int>(
      0,
      (sum, it) => sum + (it.submission?.totalItems ?? it.itemCount),
    );
    final answered = items.fold<int>(
      0,
      (sum, it) => sum + (it.submission?.answeredItems ?? 0),
    );

    final String title;
    final String subtitle;
    if (isSales) {
      title = 'Complete 5S Sales Audit';
      subtitle =
          'Complete daily pre-business-hours 5S audit for Sales showroom and negotiation areas ($total standards).';
    } else if (isService) {
      title = 'Complete 5S Service Audit';
      subtitle =
          'Complete daily pre-business-hours 5S audit for Service reception and workshop areas ($total standards).';
    } else if (isUtil) {
      title = 'Complete Utilities Master Checklist';
      subtitle =
          'Complete full daily facilities & sanitation inspection across all utility areas ($total inspection points).';
    } else if (is5s) {
      title = 'Complete 5S Master Audit';
      subtitle =
          'Complete daily pre-business-hours 5S audit across both Sales and Service areas ($total standards).';
    } else {
      title = 'Complete Compliance Master Checklist';
      subtitle =
          'Complete all assigned operational standards and daily compliance items ($total items).';
    }

    return _DosCategoryStats(
      category: 'MASTER CHECKLIST',
      title: title,
      subtitle: subtitle,
      total: total,
      answered: answered,
      accentColor: GacColors.primary,
      icon: Icons.assignment_turned_in_rounded,
    );
  }

  _DosCategoryStats _computeDocumentationStats() {
    final submission = _docRecord?.submission ??
        _checklists
            .where((e) => e.slug == 'dealer-operations-standards-documentation')
            .firstOrNull
            ?.submission;
    final isSubmitted = submission?.isSubmitted ?? false;
    final total = _docRecord?.template.sections
            .fold<int>(0, (sum, sec) => sum + sec.items.length) ??
        17;
    final answered =
        isSubmitted ? total : (submission?.effectiveAnsweredItems ?? 0);

    return _DosCategoryStats(
      category: 'DOCUMENTATION AUDIT (OPTIONAL)',
      title: 'Documentation Sheet — Customer Repair Orders',
      subtitle:
          'Multi-customer audit: Rationalized Checksheet (11), Repair Order (3), and Service Invoice (3). Optional audit.',
      total: total,
      answered: answered,
      accentColor: const Color(0xFF06B6D4),
      icon: Icons.description_rounded,
      completedLabel: 'Submitted',
    );
  }

  Widget _buildDosCategoryContent() {
    final user = widget.user;
    final isAftersales = _effectiveTrack == DosAuditTrack.aftersales;
    final canDoc = isAftersales && (user?.canAccessDocumentation ?? false);

    final docStats = canDoc ? _computeDocumentationStats() : null;

    if (_dosViewMode == _DosViewMode.completeAudit) {
      final masterStats = _computeMasterStats();
      final cards = <Widget>[];
      if (masterStats.total > 0) {
        cards.add(
          _DosCategoryCard(
            stats: masterStats,
            onPressed: () => _openCategoryChecklist(_activeDosSlug),
          ),
        );
      }
      if (docStats != null && docStats.total > 0) {
        cards.add(
          _DosCategoryCard(
            stats: docStats,
            onPressed: () => _openCategoryChecklist(
              'dealer-operations-standards-documentation',
            ),
          ),
        );
      }
      if (cards.isEmpty) {
        return const _ChecklistEmpty();
      }
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    if (_dosViewMode == _DosViewMode.byCoverage) {
      final sectionStats = _computeSectionStats();
      final cards = <Widget>[];
      for (final secStat in sectionStats) {
        if (secStat.total > 0) {
          cards.add(
            _DosSectionCard(
              stats: secStat,
              onPressed: () => _openCategoryChecklist(
                _activeDosSlug,
                sectionIndex: secStat.index,
              ),
            ),
          );
        }
      }
      if (docStats != null && docStats.total > 0) {
        cards.add(
          _DosCategoryCard(
            stats: docStats,
            onPressed: () => _openCategoryChecklist(
              'dealer-operations-standards-documentation',
            ),
          ),
        );
      }
      if (cards.isEmpty) {
        return const _ChecklistEmpty();
      }
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    // Default: By Category (Basic, Standard, Beyond, Master Audit)
    final basicStats = _computeCategoryStats(
      category: 'BASIC',
      title: 'Basic Standards Checklist',
      subtitle: 'Mandatory baseline standards required for full operational compliance (100% required).',
      accentColor: const Color(0xFF06B6D4),
      icon: Icons.verified_user_rounded,
    );

    final standardStats = _computeCategoryStats(
      category: 'STANDARD',
      title: 'Standard Standards Checklist',
      subtitle: 'Core operational benchmarks and day-to-day dealership process standards (80% target).',
      accentColor: const Color(0xFF8B5CF6),
      icon: Icons.fact_check_rounded,
    );

    final beyondStats = _computeCategoryStats(
      category: 'BEYOND',
      title: 'Beyond Standards Checklist',
      subtitle: 'Bonus excellence standards showcasing premium customer care and top performance.',
      accentColor: const Color(0xFFF59E0B),
      icon: Icons.military_tech_rounded,
    );

    final masterStats = _computeMasterStats();

    final categoryCards = <Widget>[];

    if (basicStats.total > 0) {
      categoryCards.add(
        _DosCategoryCard(
          stats: basicStats,
          onPressed: () =>
              _openCategoryChecklist(_activeDosSlug, categoryFilter: 'Basic'),
        ),
      );
    }

    if (standardStats.total > 0) {
      categoryCards.add(
        _DosCategoryCard(
          stats: standardStats,
          onPressed: () => _openCategoryChecklist(
            _activeDosSlug,
            categoryFilter: 'Standard',
          ),
        ),
      );
    }

    if (beyondStats.total > 0) {
      categoryCards.add(
        _DosCategoryCard(
          stats: beyondStats,
          onPressed: () =>
              _openCategoryChecklist(_activeDosSlug, categoryFilter: 'Beyond'),
        ),
      );
    }

    if (masterStats.total > 0) {
      categoryCards.add(
        _DosCategoryCard(
          stats: masterStats,
          onPressed: () => _openCategoryChecklist(_activeDosSlug),
        ),
      );
    }

    if (docStats != null && docStats.total > 0) {
      categoryCards.add(
        _DosCategoryCard(
          stats: docStats,
          onPressed: () => _openCategoryChecklist(
            'dealer-operations-standards-documentation',
          ),
        ),
      );
    }

    if (categoryCards.isEmpty) {
      return const _ChecklistEmpty();
    }

    return Column(
      children: [
        for (var i = 0; i < categoryCards.length; i++) ...[
          categoryCards[i],
          if (i != categoryCards.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _DosCategoryStats {
  const _DosCategoryStats({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.total,
    required this.answered,
    required this.accentColor,
    required this.icon,
    this.completedLabel = 'Submitted',
  });

  final String category;
  final String title;
  final String subtitle;
  final int total;
  final int answered;
  final Color accentColor;
  final IconData icon;
  final String completedLabel;

  int get progress =>
      total == 0 ? 0 : ((answered / total) * 100).round().clamp(0, 100);
  bool get isCompleted => total > 0 && answered >= total;
  String get status =>
      isCompleted ? completedLabel : (answered > 0 ? 'Continue' : 'Start');
}

class _DosSectionStats {
  const _DosSectionStats({
    required this.index,
    required this.title,
    required this.total,
    required this.answered,
  });

  final int index;
  final String title;
  final int total;
  final int answered;

  int get progress =>
      total == 0 ? 0 : ((answered / total) * 100).round().clamp(0, 100);
  bool get isCompleted => total > 0 && answered >= total;
  String get status =>
      isCompleted ? 'Submitted' : (answered > 0 ? 'Continue' : 'Start');
}

class _DosCategoryCard extends StatelessWidget {
  const _DosCategoryCard({required this.stats, required this.onPressed});

  final _DosCategoryStats stats;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final submitted = stats.isCompleted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: onPressed,
        child: GacContentPanel(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          borderRadius: 21,
          shadowBlurRadius: 20,
          shadowOffset: const Offset(0, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: stats.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: stats.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(stats.icon, size: 21, color: stats.accentColor),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.category.toUpperCase(),
                          style: TextStyle(
                            color: stats.accentColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stats.title,
                          style: const TextStyle(
                            color: GacColors.black,
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: stats.status, submitted: submitted),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                stats.subtitle,
                style: const TextStyle(
                  color: GacColors.gray,
                  fontSize: 10,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    size: 14,
                    color: GacColors.gray,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${stats.total} standards in this category',
                      style: const TextStyle(
                        color: GacColors.gray,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Completion',
                    style: TextStyle(
                      color: GacColors.gray,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${stats.answered}/${stats.total} · ${stats.progress}%',
                    style: const TextStyle(
                      color: GacColors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: stats.total == 0 ? 0 : stats.progress / 100,
                  minHeight: 7,
                  backgroundColor: GacColors.lightGray,
                  valueColor: AlwaysStoppedAnimation(stats.accentColor),
                ),
              ),
              const SizedBox(height: 17),
              _ChecklistActionButton(
                label: submitted
                    ? 'VIEW SUBMISSION'
                    : '${stats.status.toUpperCase()} CHECKLIST',
                accentColor: stats.accentColor,
                isSubmitted: submitted,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DosSectionCard extends StatelessWidget {
  const _DosSectionCard({required this.stats, required this.onPressed});

  final _DosSectionStats stats;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final submitted = stats.isCompleted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: onPressed,
        child: GacContentPanel(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          borderRadius: 21,
          shadowBlurRadius: 20,
          shadowOffset: const Offset(0, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF102847),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0x3300BCD4)),
                    ),
                    child: const Icon(
                      Icons.view_agenda_outlined,
                      size: 21,
                      color: Color(0xFF00BCD4),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SECTION ${stats.index + 1}',
                          style: const TextStyle(
                            color: GacColors.gray,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stats.title,
                          style: const TextStyle(
                            color: GacColors.black,
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: stats.status, submitted: submitted),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    size: 14,
                    color: GacColors.gray,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${stats.total} standards in this section',
                      style: const TextStyle(
                        color: GacColors.gray,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Completion',
                    style: TextStyle(
                      color: GacColors.gray,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${stats.answered}/${stats.total} · ${stats.progress}%',
                    style: const TextStyle(
                      color: GacColors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: stats.total == 0 ? 0 : stats.progress / 100,
                  minHeight: 7,
                  backgroundColor: GacColors.lightGray,
                  valueColor: const AlwaysStoppedAnimation(GacColors.primary),
                ),
              ),
              const SizedBox(height: 17),
              _ChecklistActionButton(
                label: submitted
                    ? 'VIEW SECTION'
                    : '${stats.status.toUpperCase()} SECTION AUDIT',
                accentColor: GacColors.primary,
                isSubmitted: submitted,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistIntro extends StatelessWidget {
  const _ChecklistIntro() : onBack = null;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ASSIGNED WORK',
          style: TextStyle(
            color: GacColors.gray,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.7,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'My checklists',
          style: TextStyle(
            color: GacColors.black,
            fontSize: 29,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'These checklists are loaded live from the compliance database. Pull down to fetch administrator updates.',
          style: TextStyle(color: GacColors.gray, fontSize: 11, height: 1.55),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '$label checklist filter',
      child: Material(
        color: selected ? GacColors.primary : GacColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? GacColors.primary : GacColors.glassBorder,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? GacColors.white : GacColors.gray,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Retained as the compact-card presentation used by the alternate checklist
// layout; the current grouped DOS/5S layout does not instantiate it directly.
// ignore: unused_element
class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.checklist, required this.onPressed});

  final ChecklistCatalogItem checklist;
  final VoidCallback onPressed;

  String get _status {
    final submission = checklist.submission;
    if (submission == null) return 'Start';
    if (submission.isSubmitted) return 'Submitted';
    if (submission.hasStarted) return 'Continue';
    return 'Start';
  }

  int get _completed => checklist.submission?.answeredItems ?? 0;
  int get _total => checklist.submission?.totalItems ?? checklist.itemCount;
  int get _progress =>
      (checklist.submission?.completionPercentage ?? 0).round().clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    final submitted = checklist.submission?.isSubmitted ?? false;
    return GacContentPanel(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      borderRadius: 21,
      shadowBlurRadius: 20,
      shadowOffset: const Offset(0, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF102847),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0x3300BCD4)),
                ),
                child: Icon(
                  _categoryIcon(checklist.slug),
                  size: 21,
                  color: const Color(0xFF00BCD4),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${checklist.categoryLabel} · V${checklist.version}',
                      style: const TextStyle(
                        color: GacColors.gray,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      checklist.name,
                      style: const TextStyle(
                        color: GacColors.black,
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: _status, submitted: submitted),
            ],
          ),
          if (checklist.description case final description?) ...[
            const SizedBox(height: 13),
            Text(
              description,
              style: const TextStyle(
                color: GacColors.gray,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.view_agenda_outlined,
                size: 14,
                color: GacColors.gray,
              ),
              const SizedBox(width: 6),
              Text(
                '${checklist.sectionCount} sections · ${checklist.itemCount} items',
                style: const TextStyle(color: GacColors.gray, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Completion',
                style: TextStyle(
                  color: GacColors.gray,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$_completed/$_total · $_progress%',
                style: const TextStyle(
                  color: GacColors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 7,
              backgroundColor: GacColors.lightGray,
              valueColor: const AlwaysStoppedAnimation(GacColors.primary),
            ),
          ),
          const SizedBox(height: 17),
          _ChecklistActionButton(
            checklist: checklist,
            status: _status,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.submitted});

  final String status;
  final bool submitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: submitted ? GacColors.successContainer : GacColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: submitted ? GacColors.success : GacColors.white,
          fontSize: 7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ChecklistActionButton extends StatelessWidget {
  const _ChecklistActionButton({
    this.checklist,
    this.status,
    this.label,
    this.accentColor,
    this.isSubmitted,
    required this.onPressed,
  });

  final ChecklistCatalogItem? checklist;
  final String? status;
  final String? label;
  final Color? accentColor;
  final bool? isSubmitted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final submitted =
        isSubmitted ?? (checklist?.submission?.isSubmitted ?? false);
    final effectiveLabel =
        label ??
        (submitted
            ? 'VIEW SUBMISSION'
            : '${(status ?? "START").toUpperCase()} CHECKLIST');
    final buttonColor = submitted
        ? const Color(0xFF153A56)
        : (accentColor ?? GacColors.primary);

    return Semantics(
      button: true,
      label:
          '$effectiveLabel${checklist != null ? ': ${checklist!.name}' : ''}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: submitted
              ? null
              : [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 45),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    effectiveLabel,
                    style: const TextStyle(
                      color: GacColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Icon(
                    submitted ? Icons.visibility_outlined : Icons.arrow_forward,
                    size: 18,
                    color: GacColors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistError extends StatelessWidget {
  const _ChecklistError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GacContentPanel(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      borderRadius: 20,
      shadowBlurRadius: 20,
      shadowOffset: const Offset(0, 7),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: GacColors.gray, size: 34),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 13),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }
}

class _ChecklistEmpty extends StatelessWidget {
  const _ChecklistEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'No active checklists are assigned to this filter.',
          textAlign: TextAlign.center,
          style: TextStyle(color: GacColors.gray),
        ),
      ),
    );
  }
}

String _filterLabel(_ChecklistFilter filter) => switch (filter) {
  _ChecklistFilter.all => 'ALL',
  _ChecklistFilter.sales => '5S SALES',
  _ChecklistFilter.service => '5S SERVICE',
  _ChecklistFilter.dos => 'DOS',
  _ChecklistFilter.restroom => '5S UTILITIES',
};

IconData _categoryIcon(String slug) => switch (slug) {
  'gateway-5s' => Icons.auto_awesome_outlined,
  'dealer-operations-standards' ||
  'dealer-operations-standards-sales' => Icons.assignment_outlined,
  'dealer-operations-standards-documentation' => Icons.description_rounded,
  'restroom' || 'utilities' => Icons.cleaning_services_rounded,
  _ => Icons.checklist_rounded,
};

String _dateString(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
