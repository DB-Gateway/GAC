import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../data/admin_data.dart';
import '../main.dart';
import '../models/authenticated_user.dart';
import '../models/checklist_models.dart';
import '../services/checklist_service.dart';
import '../theme/gac_theme.dart';
import '../utils/checklist_attention.dart';
import '../widgets/gac_surfaces.dart';
import '../widgets/user_floating_header.dart';
import 'dos_dashboard_screen.dart';
import 'user_notifications_screen.dart';

class UserChecklistDetailScreen extends StatefulWidget {
  const UserChecklistDetailScreen({
    required this.slug,
    required this.repository,
    this.categoryFilter,
    this.onCategoryFilterChanged,
    this.initialSectionIndex,
    this.initialQuestionIndex,
    this.initialItemKey,
    this.expectedDraftId,
    this.initialCustomerIndex,
    this.auditDate,
    this.initialSlotKey,
    this.onBack,
    this.onOpenNotifications,
    this.unreadNotifications = 0,
    this.user,
    this.activeTrack,
    this.onTrackChanged,
    this.isCurrentTab = true,
    this.nowProvider,
    this.attentionOnly = false,
    super.key,
  });

  final String slug;
  final ChecklistRepository repository;
  final String? categoryFilter;
  final ValueChanged<String?>? onCategoryFilterChanged;
  final int? initialSectionIndex;
  final int? initialQuestionIndex;
  final String? initialItemKey;
  final int? expectedDraftId;
  final int? initialCustomerIndex;
  final String? auditDate;
  final String? initialSlotKey;
  final VoidCallback? onBack;
  final VoidCallback? onOpenNotifications;
  final int unreadNotifications;
  final AuthenticatedUser? user;
  final DosAuditTrack? activeTrack;
  final ValueChanged<DosAuditTrack>? onTrackChanged;
  final bool isCurrentTab;
  final DateTime Function()? nowProvider;

  /// Opens a sequential review of saved No and N/A responses.
  final bool attentionOnly;

  @override
  State<UserChecklistDetailScreen> createState() =>
      _UserChecklistDetailScreenState();
}

class _UserChecklistDetailScreenState extends State<UserChecklistDetailScreen>
    with WidgetsBindingObserver {
  ChecklistLoadResult? _record;
  ChecklistLoadResult? _rawRecord;
  final Map<String, _ChecklistAnswer> _answers = {};
  int _sectionIndex = 0;
  int _stepQuestionIndex = 0;
  List<ChecklistAttentionTarget> _attentionReviewTargets = const [];
  int _attentionReviewIndex = 0;
  bool _attentionReviewComplete = false;
  String? _activeSlotKey;
  String? _listViewSlotFilter;
  bool _stepByStepMode = true;
  int _fieldRevision = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _isDirty = false;
  String? _localSlugOverride;
  String? _localCategoryFilter;
  Timer? _slotWindowTimer;
  final ScrollController _listScrollController = ScrollController();
  bool _topBarExpanded = true;

  String get _currentSlug => _localSlugOverride ?? widget.slug;
  String? get _effectiveCategoryFilter =>
      widget.attentionOnly ? null : _localCategoryFilter ?? widget.categoryFilter;
  DateTime get _now => widget.nowProvider?.call() ?? DateTime.now();
  String get _auditDate => widget.auditDate ?? _dateString(_now);
  ChecklistTemplateData? get _template => _record?.template;
  ChecklistSubmissionData? get _submission => _record?.submission;
  bool get _isHourly =>
      _template?.validationMode == 'time_slots' ||
      _currentSlug == 'restroom' ||
      _currentSlug == 'utilities';

  bool get _readOnly {
    final status = _submission?.status.trim().toLowerCase();
    final isSub = (_submission?.isSubmitted == true) ||
        status == 'submitted' ||
        status == 'completed';
    if (!isSub) return false;
    if (_isHourly) {
      final template = _template;
      if (template == null || template.timeSlots.isEmpty) return true;
      final allItems = template.sections.expand((s) => s.items).toList();
      if (allItems.isEmpty) return true;

      final finalSlot = _lastChronologicalSlot(template.timeSlots);
      if (finalSlot != null &&
          allItems.every(
            (item) =>
                _answers[item.key]?.submittedSlots.contains(finalSlot.key) ??
                false,
          )) {
        return true;
      }

      final allSlotsSubmitted = template.timeSlots.every(
        (slot) => allItems.every(
          (item) =>
              _answers[item.key]?.submittedSlots.contains(slot.key) ?? false,
        ),
      );
      return allSlotsSubmitted;
    }
    if (_isDocumentation) {
      return !_hasNewDocumentationCustomer;
    }
    return true;
  }

  bool get _isSubform =>
      _currentSlug == 'dealer-operations-standards-subform' ||
      _template?.validationMode == 'dos_subform';

  bool get _isDocumentation =>
      _currentSlug == 'dealer-operations-standards-documentation' ||
      _template?.validationMode == 'dos_documentation';

  bool get _hasNewDocumentationCustomer =>
      _isDocumentation && _customers.length > _submittedCustomerCount;

  bool _isCustomerReadOnly(CustomerAuditSample customer) {
    if (!_isDocumentation) return _readOnly;
    final status = _submission?.status.trim().toLowerCase();
    final isSub = (_submission?.isSubmitted == true) ||
        status == 'submitted' ||
        status == 'completed';
    if (!isSub) return false;
    final customerPos = _customers.indexOf(customer);
    return customerPos >= 0 && customerPos < _submittedCustomerCount;
  }

  bool get _isCategoryView =>
      _effectiveCategoryFilter != null &&
      _effectiveCategoryFilter!.trim().isNotEmpty;

  List<String> get _availableCategories {
    final raw = _rawRecord?.template ?? _record?.template;
    if (raw == null) return const ['Basic', 'Standard', 'Beyond'];
    final currentUser = widget.user;
    final allUserItems = <ChecklistItemData>[];
    for (final section in raw.sections) {
      for (final item in section.items) {
        if (currentUser != null &&
            !currentUser.isAdmin &&
            (raw.validationMode == 'dos' ||
                raw.validationMode == 'dos_subform')) {
          if (!currentUser.matchesCheckerRole(item.checker)) {
            continue;
          }
        }
        allUserItems.add(item);
      }
    }
    const standardCategories = ['Basic', 'Standard', 'Beyond'];
    final present = standardCategories.where((cat) {
      return allUserItems.any((item) {
        final itemCat = (item.category ?? item.level ?? '')
            .trim()
            .toLowerCase();
        return itemCat == cat.toLowerCase();
      });
    }).toList();
    return present.isNotEmpty ? present : standardCategories;
  }

  String? _getNextCategory() {
    final current = _effectiveCategoryFilter;
    if (current == null) return null;
    final categories = _availableCategories;
    final currentIndex = categories.indexWhere(
      (c) => c.toLowerCase() == current.toLowerCase(),
    );
    if (currentIndex != -1 && currentIndex < categories.length - 1) {
      return categories[currentIndex + 1];
    }
    return null;
  }

  bool get _isLastCategory {
    if (!_isCategoryView) return true;
    return _getNextCategory() == null;
  }

  bool get _hasNextUnansweredCategory {
    final current = _effectiveCategoryFilter;
    if (current == null) return false;
    final categories = _availableCategories;
    final currentIndex = categories.indexWhere(
      (c) => c.toLowerCase() == current.toLowerCase(),
    );
    if (currentIndex == -1 || currentIndex >= categories.length - 1) {
      return false;
    }
    final raw = _rawRecord?.template ?? _record?.template;
    if (raw == null) return false;
    final currentUser = widget.user;

    for (var i = currentIndex + 1; i < categories.length; i++) {
      final cat = categories[i].toLowerCase();
      for (final section in raw.sections) {
        for (final item in section.items) {
          if (currentUser != null &&
              !currentUser.isAdmin &&
              (raw.validationMode == 'dos' ||
                  raw.validationMode == 'dos_subform')) {
            if (!currentUser.matchesCheckerRole(item.checker)) {
              continue;
            }
          }
          final itemCat = (item.metadata['level']?.toString() ??
                  item.metadata['category']?.toString() ??
                  item.level ??
                  item.category ??
                  '')
              .trim()
              .toLowerCase();
          if (itemCat == cat && !_isQuestionAnswered(item, raw)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool get _areAllItemsAnswered {
    final raw = _rawRecord?.template ?? _record?.template;
    if (raw == null) return false;
    final currentUser = widget.user;
    for (final section in raw.sections) {
      for (final item in section.items) {
        if (currentUser != null &&
            !currentUser.isAdmin &&
            (raw.validationMode == 'dos' ||
                raw.validationMode == 'dos_subform')) {
          if (!currentUser.matchesCheckerRole(item.checker)) {
            continue;
          }
        }
        if (!_isQuestionAnswered(item, raw)) {
          return false;
        }
      }
    }
    return true;
  }

  bool get _isReadyToSubmit =>
      !_isCategoryView ||
      _isLastCategory ||
      !_hasNextUnansweredCategory ||
      _areAllItemsAnswered;

  bool get _isDos =>
      _currentSlug == 'dealer-operations-standards' ||
      _currentSlug == 'dealer-operations-standards-sales' ||
      _isSubform ||
      _isDocumentation ||
      _template?.validationMode == 'dos' ||
      _template?.validationMode == 'dos_subform' ||
      _template?.validationMode == 'dos_documentation';

  static const Set<String> _dosInspectorEmails = {
    'sm@gateway.com',
    'asm@gateway.com',
    'ce@gateway.com',
    'parts@gateway.com',
    'jc@gateway.com',
    'ws.sup@gateway.com',
  };

  bool get _isDosInspectorUser {
    final user = widget.user;
    if (user != null) {
      final email = user.email.trim().toLowerCase();
      if (_dosInspectorEmails.contains(email)) return true;
      if (user.isAdmin) return false;
      return user.isDosSales ||
          user.isDosAftersales ||
          user.isSalesManager ||
          user.isAftersalesChecker;
    }
    return _isDos;
  }

  bool get _isDedicatedDosUser => _isDosInspectorUser;

  bool get _requiresDosEscalationAndCommitment => false;

  bool get _requiresDosActionPlan => false;

  bool get _showsDosBomTask => false;

  String get _dosInstructions =>
      'Judge every standard. NO requires a finding; N/A requires a reason.';

  int _selectedCustomerIndex = 1;
  int _submittedCustomerCount = 0;
  final List<CustomerAuditSample> _customers = [
    CustomerAuditSample(customerIndex: 1),
    CustomerAuditSample(customerIndex: 2),
    CustomerAuditSample(customerIndex: 3),
  ];

  DosAuditTrack get _effectiveTrack {
    if (widget.activeTrack != null) return widget.activeTrack!;
    return _currentSlug == 'dealer-operations-standards-sales'
        ? DosAuditTrack.sales
        : DosAuditTrack.aftersales;
  }

  bool get _canSwitchTrack {
    if (_isSubform || _isDocumentation) return false;
    final user = widget.user;
    if (user != null) {
      if (user.isAdmin) return true;
      return !user.isSalesManager &&
          !user.isAftersalesChecker &&
          !user.isDosSales &&
          !user.isDosAftersales;
    }
    return widget.onTrackChanged != null;
  }

  @override
  void initState() {
    super.initState();
    _activeSlotKey = widget.initialSlotKey;
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    _slotWindowTimer?.cancel();
    _listScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() {
          final template = _template;
          if (template != null) {
            _refreshHourlyWindow(template);
          }
        });
      }
      _scheduleSlotWindowRefresh();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (_isDirty && !_saving && !_readOnly) {
        unawaited(_autoSaveDraft());
      }
    }
  }

  @override
  void didUpdateWidget(UserChecklistDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCurrentTab && !widget.isCurrentTab) {
      if (_isDirty && !_saving && !_readOnly) {
        unawaited(_autoSaveDraft());
      }
    }
    if (widget.attentionOnly != oldWidget.attentionOnly ||
        widget.slug != oldWidget.slug ||
        widget.categoryFilter != oldWidget.categoryFilter ||
        widget.initialSectionIndex != oldWidget.initialSectionIndex ||
        widget.initialQuestionIndex != oldWidget.initialQuestionIndex) {
      _localSlugOverride = null;
      _localCategoryFilter = null;
      _sectionIndex = 0;
      _stepQuestionIndex = 0;
      _isDirty = false;
      _load();
    }
  }

  ChecklistLoadResult? _buildLocalFallback(String slug) {
    if (slug == 'dealer-operations-standards') {
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
                        'how_to_check': item.howToCheck,
                        'bom_task': item.bomTask,
                        'checker': item.checker,
                        'pic': 'GM',
                        'escalation': item.escalation,
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
          settings: {
            'validation_mode': 'dos',
            'response_options': const ['yes', 'no', 'na'],
            'instructions': _dosInstructions,
          },
          sections: sections,
        ),
        submission: null,
      );
    } else if (slug == 'dealer-operations-standards-sales') {
      final sections = _salesWorkbookSections();

      return ChecklistLoadResult(
        template: ChecklistTemplateData(
          id: 6,
          slug: 'dealer-operations-standards-sales',
          name: 'Dealer Operations Standards - Sales',
          description: 'FY25 Sales Standards Compliance Audit Sheet (REV02) (90 Standards)',
          version: 1,
          settings: {
            'validation_mode': 'dos',
            'response_options': const ['yes', 'no', 'na'],
            'instructions': _dosInstructions,
          },
          sections: sections,
        ),
        submission: null,
      );
    } else if (slug == 'dealer-operations-standards-subform') {
      return ChecklistLoadResult(
        template: buildSubformTemplateData(),
        submission: null,
      );
    } else if (slug == 'dealer-operations-standards-documentation') {
      return ChecklistLoadResult(
        template: buildDocumentationTemplateData(),
        submission: null,
      );
    }
    return null;
  }

  List<ChecklistSectionData> _salesWorkbookSections({
    ChecklistTemplateData? remoteTemplate,
  }) => buildDosSalesTemplateData(source: remoteTemplate).sections;

  ChecklistTemplateData _withSalesWorkbookContent(
    ChecklistTemplateData template,
  ) {
    if (_currentSlug != 'dealer-operations-standards-sales' &&
        template.slug != 'dealer-operations-standards-sales') {
      return template;
    }

    return buildDosSalesTemplateData(source: template);
  }

  ChecklistTemplateData _filterTemplateForUser(
    ChecklistTemplateData template, {
    bool filterCategory = true,
  }) {
    final currentUser = widget.user;
    final categoryFilter = filterCategory ? _effectiveCategoryFilter : null;
    if (_isDocumentation) {
      return template;
    }
    if ((currentUser == null || currentUser.isAdmin) &&
        categoryFilter == null) {
      return template;
    }
    if (template.validationMode != 'dos' &&
        template.validationMode != 'dos_subform' &&
        categoryFilter == null) {
      return template;
    }

    final filteredSections = <ChecklistSectionData>[];
    for (final section in template.sections) {
      final filteredItems = section.items
          .where((item) {
            if (currentUser != null &&
                !currentUser.isAdmin &&
                (template.validationMode == 'dos' ||
                    template.validationMode == 'dos_subform')) {
              if (!currentUser.matchesCheckerRole(item.checker)) {
                return false;
              }
            }
            if (categoryFilter != null) {
              final cat = (item.category ?? item.level ?? '')
                  .trim()
                  .toLowerCase();
              if (cat != categoryFilter.trim().toLowerCase()) {
                return false;
              }
            }
            return true;
          })
          .toList(growable: false);

      if (filteredItems.isNotEmpty) {
        filteredSections.add(
          ChecklistSectionData(
            id: section.id,
            key: section.key,
            title: section.title,
            sortOrder: section.sortOrder,
            metadata: section.metadata,
            items: filteredItems,
          ),
        );
      }
    }

    String templateName = template.name;
    if (categoryFilter != null) {
      templateName =
          '${template.name} — ${categoryFilter.toUpperCase()} STANDARDS';
    } else if (template.validationMode == 'dos_subform' &&
        currentUser != null &&
        !currentUser.isAdmin) {
      final roleSuffix = switch (currentUser.dosCheckerCode) {
        'CE SERVICE' => 'Service Reception & Lounge',
        'WS SUP' => 'Employee Facilities & Mitsubishi Quick Service',
        'ASM' => 'Meeting Room',
        _ => null,
      };
      if (roleSuffix != null) {
        templateName = 'Dealer Operations Standards - Subform ($roleSuffix)';
      }
    }

    return ChecklistTemplateData(
      id: template.id,
      slug: template.slug,
      name: templateName,
      description: template.description,
      version: template.version,
      settings: _isDedicatedDosUser && template.validationMode == 'dos'
          ? {...template.settings, 'instructions': _dosInstructions}
          : template.settings,
      sections: filteredSections,
    );
  }

  List<_ChecklistQuestionLocation> _getQuestionsForTemplate(
    ChecklistTemplateData template,
  ) {
    final questions = <_ChecklistQuestionLocation>[
      for (
        var sectionIndex = 0;
        sectionIndex < template.sections.length;
        sectionIndex++
      )
        for (final item in template.sections[sectionIndex].items)
          _ChecklistQuestionLocation(
            section: template.sections[sectionIndex],
            sectionIndex: sectionIndex,
            item: item,
          ),
    ];
    if (template.slug == 'dealer-operations-standards-sales') {
      questions.sort(
        (left, right) => left.item.sortOrder.compareTo(right.item.sortOrder),
      );
    }
    return questions;
  }

  bool _isQuestionAnswered(
    ChecklistItemData item,
    ChecklistTemplateData template,
  ) {
    final answer = _answers[item.key];
    if (answer == null) return false;
    final isTimeSlots =
        template.validationMode == 'time_slots' ||
        template.slug == 'restroom' ||
        template.slug == 'utilities';
    if (isTimeSlots) {
      final slotKey = _effectiveSlotKey(template);
      final slotVal = answer.slots[slotKey]?.trim().toLowerCase();
      return slotVal != null && slotVal.isNotEmpty && slotVal != 'unanswered';
    }
    final status = answer.status?.trim().toLowerCase();
    return status != null && status.isNotEmpty && status != 'unanswered';
  }

  void _applyRecord(ChecklistLoadResult record) {
    _rawRecord ??= record;
    final effectiveTemplate = _filterTemplateForUser(
      _withSalesWorkbookContent(record.template),
    );
    _record = ChecklistLoadResult(
      template: effectiveTemplate,
      submission: record.submission,
    );
    _answers
      ..clear()
      ..addEntries(
        effectiveTemplate.sections.expand((section) => section.items).map((
          item,
        ) {
          final response = record.submission?.responses[item.key];
          final answer = _ChecklistAnswer.fromResponse(response);
          if (_isHourly) {
            // Hourly status is derived by the server; only slot marks are
            // editable answers, including when the last mark is undone.
            answer.status = null;
          }
          if (_isDedicatedDosUser &&
              effectiveTemplate.validationMode == 'dos') {
            answer.commitmentDate = null;
            answer.escalationTarget = null;
            answer.actionPlan = '';
          }
          if (_isSubformReferenceItem(item, effectiveTemplate) &&
              effectiveTemplate.validationMode == 'dos' &&
              !_isSubform) {
            if (answer.eligibility == null) {
              if (answer.status == 'na') {
                answer.eligibility = 'na';
              } else if (answer.subformAnswers.isNotEmpty ||
                  answer.status == 'yes' ||
                  answer.status == 'no') {
                answer.eligibility = 'show_subform';
              }
            }
          }
          return MapEntry(item.key, answer);
        }),
      );
    final submissionStatus = record.submission?.status.trim().toLowerCase();
    final isSubmitted = (record.submission?.isSubmitted ?? false) ||
        submissionStatus == 'submitted' ||
        submissionStatus == 'completed';
    final questions = _getQuestionsForTemplate(effectiveTemplate);
    final isHourly = effectiveTemplate.validationMode == 'time_slots' ||
        effectiveTemplate.slug == 'restroom' ||
        effectiveTemplate.slug == 'utilities';

    final allQuestionsAnswered = questions.isNotEmpty &&
        questions.every((q) => _isQuestionAnswered(q.item, effectiveTemplate));

    final allHourlySlotsSubmitted = isHourly &&
        effectiveTemplate.timeSlots.isNotEmpty &&
        effectiveTemplate.timeSlots.every(
          (slot) => questions.every(
            (q) =>
                _answers[q.item.key]?.submittedSlots.contains(slot.key) ??
                false,
          ),
        );

    final isAlreadyDone = isSubmitted ||
        _readOnly ||
        (isHourly ? allHourlySlotsSubmitted : allQuestionsAnswered);

    if (isHourly && isAlreadyDone && widget.initialSlotKey == null) {
      final lastSlot = _lastChronologicalSlot(effectiveTemplate.timeSlots);
      if (lastSlot != null) {
        _activeSlotKey = lastSlot.key;
      }
    }

    if (!_readOnly && !isAlreadyDone) {
      _refreshHourlyWindow(effectiveTemplate, markDirty: false);
    }
    final maxSec = (effectiveTemplate.sections.length - 1).clamp(0, 1 << 20);
    final reminderQuestionIndex = questions.indexWhere(
      (question) => question.item.key == widget.initialItemKey,
    );

    if (reminderQuestionIndex >= 0) {
      _stepQuestionIndex = reminderQuestionIndex;
      _sectionIndex = questions[reminderQuestionIndex].sectionIndex;
    } else if (isAlreadyDone) {
      if (questions.isNotEmpty) {
        _stepQuestionIndex = questions.length - 1;
        _sectionIndex = questions[_stepQuestionIndex].sectionIndex;
      } else {
        _sectionIndex = 0;
        _stepQuestionIndex = 0;
      }
    } else if (widget.initialQuestionIndex != null && questions.isNotEmpty) {
      _stepQuestionIndex = widget.initialQuestionIndex!.clamp(
        0,
        questions.length - 1,
      );
      _sectionIndex = questions[_stepQuestionIndex].sectionIndex;
    } else if (widget.initialSectionIndex != null) {
      _sectionIndex = widget.initialSectionIndex!.clamp(0, maxSec);
      if (questions.isNotEmpty) {
        final firstUnansweredInSec = questions.indexWhere(
          (q) =>
              q.sectionIndex == _sectionIndex &&
              !_isQuestionAnswered(q.item, effectiveTemplate),
        );
        if (firstUnansweredInSec != -1) {
          _stepQuestionIndex = firstUnansweredInSec;
        } else {
          final lastInSec = questions.lastIndexWhere(
            (q) => q.sectionIndex == _sectionIndex,
          );
          _stepQuestionIndex =
              lastInSec != -1 ? lastInSec : questions.length - 1;
        }
      }
    } else {
      if (questions.isNotEmpty) {
        final firstUnanswered = questions.indexWhere(
          (q) => !_isQuestionAnswered(q.item, effectiveTemplate),
        );
        if (firstUnanswered != -1) {
          _stepQuestionIndex = firstUnanswered;
          _sectionIndex = questions[firstUnanswered].sectionIndex;
        } else {
          _stepQuestionIndex = questions.length - 1;
          _sectionIndex = questions[_stepQuestionIndex].sectionIndex;
        }
      } else {
        _sectionIndex = 0;
        _stepQuestionIndex = 0;
      }
    }
    if (_isDocumentation) {
      final firstResp = record.submission?.responses.values.firstOrNull;
      final rawCustomers = firstResp?.details['customers'];
      if (rawCustomers is List && rawCustomers.isNotEmpty) {
        _customers.clear();
        for (final item in rawCustomers) {
          if (item is Map) {
            _customers.add(
              CustomerAuditSample.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
      if (_customers.isEmpty) {
        _customers
          ..clear()
          ..addAll([
            CustomerAuditSample(customerIndex: 1),
            CustomerAuditSample(customerIndex: 2),
            CustomerAuditSample(customerIndex: 3),
          ]);
      }
      final documentationItems = effectiveTemplate.sections
          .expand((section) => section.items)
          .toList(growable: false);
      final allDocAnswered = _customers.isNotEmpty &&
          documentationItems.isNotEmpty &&
          _customers.every((customer) => documentationItems.every((item) {
                final status = customer.answers[item.key]?.trim();
                return status != null && status.isNotEmpty;
              }));
      final isDocAlreadyDone = isAlreadyDone || allDocAnswered;
      if (isDocAlreadyDone) {
        _submittedCustomerCount = _customers.length;
      } else {
        _submittedCustomerCount = 0;
      }

      if (widget.initialCustomerIndex != null &&
          _customers.any(
            (customer) => customer.customerIndex == widget.initialCustomerIndex,
          )) {
        _selectedCustomerIndex = widget.initialCustomerIndex!;
      } else if (isDocAlreadyDone && _customers.isNotEmpty) {
        _selectedCustomerIndex = _customers.last.customerIndex;
      }
      if (!_customers.any(
        (customer) => customer.customerIndex == _selectedCustomerIndex,
      )) {
        _selectedCustomerIndex = _customers.first.customerIndex;
      }
      if (isDocAlreadyDone &&
          reminderQuestionIndex < 0) {
        if (documentationItems.isNotEmpty) {
          _stepQuestionIndex = documentationItems.length - 1;
        }
      } else if (!isDocAlreadyDone &&
          widget.initialQuestionIndex == null &&
          reminderQuestionIndex < 0) {
        final activeCustomer = _customers.firstWhere(
          (customer) => customer.customerIndex == _selectedCustomerIndex,
        );
        final firstUnanswered = documentationItems.indexWhere((item) {
          final status = activeCustomer.answers[item.key]?.trim();
          return status == null || status.isEmpty;
        });
        _stepQuestionIndex = firstUnanswered < 0
            ? (documentationItems.length - 1).clamp(0, 1 << 20)
            : firstUnanswered;
      }
    }
    if (widget.attentionOnly) {
      _attentionReviewTargets = checklistAttentionTargets(
        _record!,
        widget.user ?? AuthenticatedUser.fallback,
      );
      _attentionReviewIndex = 0;
      _attentionReviewComplete = false;
    }
    _fieldRevision++;
    _loading = false;
    _error = null;
    _isDirty = false;
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final record = await widget.repository.fetchChecklist(
        _currentSlug,
        date: _auditDate,
      );
      if (widget.expectedDraftId != null &&
          (record.submission?.id != widget.expectedDraftId ||
              record.submission?.isSubmitted == true)) {
        throw const ChecklistApiException(
          'This draft has already been submitted or removed. Return to your checklists to view current work.',
        );
      }
      if (!mounted) return;
      setState(() {
        _rawRecord = record;
        _applyRecord(record);
      });
      _scheduleSlotWindowRefresh();
    } catch (error) {
      final fallback =
          gacEnableOfflineChecklistFallback && widget.expectedDraftId == null
          ? _buildLocalFallback(_currentSlug)
          : null;
      if (fallback != null) {
        if (!mounted) return;
        setState(() {
          _rawRecord = fallback;
          _applyRecord(fallback);
        });
        _scheduleSlotWindowRefresh();
        return;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is ChecklistApiException
            ? error.message
            : 'The checklist could not be loaded.';
      });
    }
  }

  Map<String, dynamic> _draftPosition(ChecklistTemplateData template) {
    final questions = _getQuestionsForTemplate(template);
    final item = questions.isEmpty
        ? null
        : questions[_stepQuestionIndex.clamp(0, questions.length - 1)].item;
    return {
      'draft_position': {
        if (item != null) 'item_key': item.key,
        if (template.timeSlots.isNotEmpty)
          'slot_key': _effectiveSlotKey(template),
        if (_isDocumentation) 'customer_index': _selectedCustomerIndex,
      },
    };
  }

  Future<void> _autoSaveDraft({bool showPopup = true}) async {
    final template = _template;
    if (template == null || _saving || _readOnly || !_isDirty) return;
    await _save(submit: false, isAutoSave: true, showPopup: showPopup);
  }

  bool get _hasDraftContent {
    if (_isDocumentation) {
      return _customers.any(
        (customer) =>
            customer.roNumber.trim().isNotEmpty ||
            customer.mileage.trim().isNotEmpty ||
            customer.answers.values.any(_ChecklistAnswer.hasValue),
      );
    }
    return _answers.values.any((answer) => !answer.isEmpty);
  }

  bool get _hasSavedResponsesInView =>
      _submission?.responses.keys.any(_answers.containsKey) ?? false;

  void _showChecklistSavedPopup() {
    final messenger =
        gacScaffoldMessengerKey.currentState ??
        (mounted ? ScaffoldMessenger.maybeOf(context) : null);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Checklist saved'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save({
    required bool submit,
    bool isAutoSave = false,
    bool showPopup = true,
  }) async {
    final template = _template;
    if (template == null || _saving || _readOnly) return;
    if (!submit && !_isDirty && !isAutoSave) return;

    final isHourlyChecklist =
        template.validationMode == 'time_slots' ||
        template.slug == 'restroom' ||
        template.slug == 'utilities';
    if (isHourlyChecklist && _moveFromExpiredHourlySlot(template)) {
      setState(() {
        _sectionIndex = 0;
        _stepQuestionIndex = 0;
        _listViewSlotFilter = null;
      });
    }
    final hasDraftContent = _hasDraftContent;
    if (!submit && !hasDraftContent && !_hasSavedResponsesInView) {
      // Undoing every new answer leaves nothing to persist or resume.
      setState(() {
        _isDirty = false;
        _sectionIndex = 0;
        _stepQuestionIndex = 0;
      });
      return;
    }
    final activeHourlySlot = isHourlyChecklist && template.timeSlots.isNotEmpty
        ? template.timeSlots.firstWhere(
            (slot) => slot.key == _effectiveSlotKey(template),
            orElse: () => template.timeSlots.first,
          )
        : null;
    final newlySubmittedHourlyAnswers = <_ChecklistAnswer>[];
    var hourlySubmissionSaved = false;

    if (submit) {
      final validation = _validateForSubmission(template);
      if (validation != null) {
        setState(() {
          _sectionIndex = validation.sectionIndex;
          if (validation.customerIndex != null) {
            _selectedCustomerIndex = validation.customerIndex!;
          }
          if (validation.questionIndex != null) {
            _stepQuestionIndex = validation.questionIndex!;
          }
        });
        await _showMessage('Checklist incomplete', validation.message);
        if (_listScrollController.hasClients) {
          _listScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
        return;
      }
    }

    // Basic, Standard, and Beyond are partial views of one DOS submission.
    // Completing one category updates the shared draft and advances to the next category.
    // The final category (Beyond, or Standard if Beyond doesn't exist) or Master Audit finalizes submission.
    // An hourly checklist stays editable for the rest of the day. Each hour
    // is saved independently, and only the final scheduled hour closes the
    // daily checklist and creates the final submission/report.
    final finalHourlySlot = isHourlyChecklist
        ? _lastChronologicalSlot(template.timeSlots)
        : null;
    final isFinalHourlySlot =
        !isHourlyChecklist || activeHourlySlot?.key == finalHourlySlot?.key;
    final shouldSubmit =
        submit && _isReadyToSubmit;

    setState(() => _saving = true);
    try {
      // Upload any local photos to Server first
      for (final answer in _answers.values) {
        if (answer.localAttachmentBytes != null &&
            answer.attachmentPath == null) {
          try {
            final uploadRes = await widget.repository.uploadAttachment(
              template.slug,
              bytes: answer.localAttachmentBytes!,
              filename: answer.localAttachmentName ?? 'defect_photo.jpg',
            );
            answer.attachmentPath = uploadRes['path'] as String?;
            answer.attachmentUrl = uploadRes['url'] as String?;
          } catch (uploadError) {
            if (!mounted) return;
            setState(() => _saving = false);
            final msg = uploadError is ChecklistApiException
                ? uploadError.message
                : 'Could not upload the attached photo to Server.';
            await _showMessage('Photo upload failed', msg);
            return;
          }
        }
      }

      // Hourly checklists are progressive. Send the completed active hour and
      // previously saved hours without inventing marks for future slots.
      if (submit && activeHourlySlot != null) {
        for (final section in template.sections) {
          for (final item in section.items) {
            if (!item.isSlotActive(activeHourlySlot.key)) continue;
            final answer = _answers[item.key];
            if (answer != null &&
                answer.submittedSlots.add(activeHourlySlot.key)) {
              newlySubmittedHourlyAnswers.add(answer);
            }
          }
        }
      }
      final responses = _payloads(
        template,
        includeEmpty: submit && !isHourlyChecklist,
        includeSavedCategories: shouldSubmit && _isCategoryView,
      );
      final submission = shouldSubmit
          ? await widget.repository.submit(
              template.slug,
              date: _auditDate,
              responses: responses,
            )
          : await widget.repository.saveDraft(
              template.slug,
              date: _auditDate,
              responses: responses,
              context: hasDraftContent ? _draftPosition(template) : null,
            );
      hourlySubmissionSaved = true;
      _isDirty = false;
      if (!mounted) {
        if (!submit && hasDraftContent && (_isDos || isAutoSave) && showPopup) {
          _showChecklistSavedPopup();
        }
        return;
      }
      setState(() {
        _record = ChecklistLoadResult(
          template: template,
          submission: submission,
        );
        _applyRecord(_record!);
        // The request is complete even while its result dialog remains open.
        _saving = false;
      });

      if (submit) {
        if (isHourlyChecklist && !isFinalHourlySlot) {
          final currentIndex = template.timeSlots.indexWhere(
            (slot) => slot.key == activeHourlySlot?.key,
          );
          final nextSlot =
              currentIndex >= 0 && currentIndex < template.timeSlots.length - 1
              ? template.timeSlots[currentIndex + 1]
              : null;
          await _showMessage(
            '${activeHourlySlot?.label ?? 'Hourly'} inspection submitted',
            nextSlot == null
                ? 'This hourly inspection was saved.'
                : 'This hour was saved. The next inspection will be available at ${nextSlot.label}.',
            isSuccess: true,
            statusLabel: 'HOUR COMPLETE',
          );
          if (mounted) {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            }
          }
        } else if (_isCategoryView && !_isReadyToSubmit) {
          final nextCategory = _getNextCategory()!;
          if (!mounted) return;
          widget.onCategoryFilterChanged?.call(nextCategory);
          setState(() {
            _localCategoryFilter = nextCategory;
            _isDirty = false;
            _applyRecord(
              ChecklistLoadResult(
                template: _rawRecord?.template ?? template,
                submission: submission,
              ),
            );
            _stepQuestionIndex = 0;
            _sectionIndex = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0F2642),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF12B76A), width: 1.2),
              ),
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF12B76A),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saved. Proceeding to $nextCategory standards...',
                      style: const TextStyle(
                        color: GacColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          final title = _isDocumentation ? 'Documentation audit submitted' : 'Checklist submitted';
          final message = _isDocumentation
              ? 'Your documentation audit was submitted to Server. The Branch Operations Manager (BOM) and General Manager (GM) have been notified.'
              : 'Responses saved and ready for review.';
          await _showMessage(
            title,
            message,
            isSuccess: true,
          );
          if (mounted) {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            }
          }
        }
      } else if (hasDraftContent) {
        if (_isDos || isAutoSave) {
          if (showPopup) {
            _showChecklistSavedPopup();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Draft saved to Server.')),
          );
        }
      }
    } on ChecklistApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      await _showMessage('Unable to save checklist', error.message);
    } finally {
      if (!hourlySubmissionSaved && activeHourlySlot != null) {
        for (final answer in newlySubmittedHourlyAnswers) {
          answer.submittedSlots.remove(activeHourlySlot.key);
        }
      }
      if (mounted) setState(() => _saving = false);
    }
  }

  _ChecklistValidation? _validateForSubmission(ChecklistTemplateData template) {
    if (!template.sections.any((section) => section.items.isNotEmpty)) {
      return const _ChecklistValidation(
        0,
        'This checklist has no inspection items. Please ask an administrator to review its template.',
      );
    }

    if (_isDocumentation) {
      if (_customers.isEmpty) {
        return const _ChecklistValidation(
          0,
          'Please add at least one customer sample.',
        );
      }
      for (final cust in _customers) {
        if (cust.roNumber.trim().isEmpty) {
          return _ChecklistValidation(
            0,
            'Please enter the R.O. Number for Customer ${cust.customerIndex}.',
            customerIndex: cust.customerIndex,
            questionIndex: 0,
          );
        }
        final items = template.sections.expand((s) => s.items).toList();
        for (var itemIndex = 0; itemIndex < items.length; itemIndex++) {
          final item = items[itemIndex];
          final ans = cust.answers[item.key];
          if (ans == null || ans.isEmpty) {
            return _ChecklistValidation(
              0,
              'Please answer all check items for Customer ${cust.customerIndex}.',
              customerIndex: cust.customerIndex,
              questionIndex: itemIndex,
            );
          }
        }
      }
      return null;
    }

    final restroom =
        template.validationMode == 'time_slots' ||
        template.slug == 'restroom' ||
        template.slug == 'utilities';
    if (restroom && template.timeSlots.isEmpty) {
      return const _ChecklistValidation(
        0,
        'This checklist has no inspection time slots. Please ask an administrator to review its template.',
      );
    }
    final activeRestroomSlot = restroom && template.timeSlots.isNotEmpty
        ? template.timeSlots.firstWhere(
            (slot) => slot.key == _effectiveSlotKey(template),
            orElse: () => template.timeSlots.first,
          )
        : null;
    if (activeRestroomSlot != null && _slotStart(activeRestroomSlot) == null) {
      return _ChecklistValidation(
        0,
        'The ${activeRestroomSlot.label} inspection has an invalid time-slot configuration.',
      );
    }
    if (activeRestroomSlot != null && _isSlotLocked(activeRestroomSlot)) {
      return _ChecklistValidation(
        0,
        'The ${activeRestroomSlot.label} inspection can only be submitted during its scheduled hour.',
      );
    }
    var questionIndex = 0;
    for (
      var sectionIndex = 0;
      sectionIndex < template.sections.length;
      sectionIndex++
    ) {
      final section = template.sections[sectionIndex];
      for (final item in section.items) {
        final currentQuestionIndex = questionIndex++;
        final answer = _answers[item.key]!;
        if (restroom) {
          final slot = activeRestroomSlot!;
          if (!item.isSlotActive(slot.key)) {
            continue;
          }
          final mark = answer.slots[slot.key];
          final normalizedMark = mark?.trim().toLowerCase();
          if (normalizedMark == null ||
              normalizedMark.isEmpty ||
              normalizedMark == 'unanswered') {
            return _ChecklistValidation(
              sectionIndex,
              'Select a condition for every item in the ${slot.label} inspection.',
              questionIndex: currentQuestionIndex,
            );
          }
          if (normalizedMark == 'na' && answer.remark.trim().isEmpty) {
            return _ChecklistValidation(
              sectionIndex,
              'Add a reason for N/A response on item ${item.displayNumber ?? item.key}.',
              questionIndex: currentQuestionIndex,
            );
          }
          if (normalizedMark == 'not_good' && answer.remark.trim().isEmpty) {
            return _ChecklistValidation(
              sectionIndex,
              'Add a remark for Not Good response on item ${item.displayNumber ?? item.key}.',
              questionIndex: currentQuestionIndex,
            );
          }
          continue;
        }

        if (template.validationMode == 'dos' &&
            !_isSubform &&
            _isSubformReferenceItem(item, template)) {
          if (answer.eligibility == null) {
            return _ChecklistValidation(
              sectionIndex,
              'Please select eligibility (Show Subform or N/A) for item ${item.displayNumber ?? item.key}.',
              questionIndex: currentQuestionIndex,
            );
          }
          if (answer.eligibility == 'show_subform') {
            final subformSec = _getSubformSection(item);
            if (subformSec != null) {
              final uncompleted = subformSec.items.any(
                (subItem) =>
                    !answer.subformAnswers.containsKey(subItem.id) ||
                    answer.subformAnswers[subItem.id] == null ||
                    answer.subformAnswers[subItem.id]!.isEmpty,
              );
              if (uncompleted) {
                return _ChecklistValidation(
                  sectionIndex,
                  'Please answer all subform questions for ${item.subject ?? item.displayNumber ?? item.key}.',
                  questionIndex: currentQuestionIndex,
                );
              }
            }
          }
        }

        if (answer.status == null) {
          return _ChecklistValidation(
            sectionIndex,
            'Answer every item in ${section.title}.',
            questionIndex: currentQuestionIndex,
          );
        }
        if (template.validationMode == 'dos') {
          if (answer.status == 'no' && answer.finding.trim().isEmpty) {
            return _ChecklistValidation(
              sectionIndex,
              'Add a finding for each NO response.',
              questionIndex: currentQuestionIndex,
            );
          }
          if (answer.status == 'na' && answer.finding.trim().isEmpty) {
            return _ChecklistValidation(
              sectionIndex,
              'Add a reason for each N/A response.',
              questionIndex: currentQuestionIndex,
            );
          }
        } else if ((answer.status == 'no' || answer.status == 'na') &&
            answer.remark.trim().isEmpty &&
            template.validationMode != 'dos_subform') {
          return _ChecklistValidation(
            sectionIndex,
            'Add a remark for each NO or N/A response.',
            questionIndex: currentQuestionIndex,
          );
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _payloads(
    ChecklistTemplateData template, {
    required bool includeEmpty,
    bool includeSavedCategories = false,
  }) {
    if (_isDocumentation) {
      // In documentation, every question is a prerequisite: if even one is NO,
      // all check items for that customer are strictly NO.
      final docItems = template.sections.expand((section) => section.items).toList(growable: false);
      for (final cust in _customers) {
        final hasNo = cust.answers.values.any((v) => v.trim().toLowerCase() == 'no');
        if (hasNo) {
          for (final item in docItems) {
            cust.answers[item.key] = 'no';
          }
        }
      }
      final customerMap = _customers.map((c) => c.toJson()).toList();
      final payloads = <Map<String, dynamic>>[];
      for (final item in docItems) {
        final statuses = _customers
            .map((customer) => customer.answers[item.key])
            .whereType<String>()
            .where((status) => status.trim().isNotEmpty)
            .map((status) => status.trim().toLowerCase())
            .toList(growable: false);
        final String? derivedStatus = statuses.contains('no')
            ? 'no'
            : statuses.length == _customers.length
            ? (statuses.contains('na') ? 'na' : 'yes')
            : null;

        payloads.add({
          'item_id': item.id,
          'item_key': item.key,
          'status': derivedStatus,
          'remark': null,
          'finding': null,
          'action_plan': null,
          'commitment_date': null,
          'attachment_path': null,
          'details': {'customers': customerMap},
        });
      }
      return payloads;
    }

    _markMissedHourlySlots(template);

    // The submit endpoint replaces all responses. Include the user's saved
    // answers from earlier categories when completing the final category.
    final payloadTemplate = includeSavedCategories
        ? _filterTemplateForUser(
            _withSalesWorkbookContent(_rawRecord?.template ?? template),
            filterCategory: false,
          )
        : template;
    final payloads = <Map<String, dynamic>>[];
    final items = payloadTemplate.sections.expand((section) => section.items);
    for (final item in items) {
      final answer =
          _answers[item.key] ??
          _ChecklistAnswer.fromResponse(_submission?.responses[item.key]);
      // Draft saves merge rows on the server. An empty previously saved row
      // must be sent explicitly so undo also clears the persisted answer.
      if (!includeEmpty &&
          answer.isEmpty &&
          !(_submission?.responses.containsKey(item.key) ?? false)) {
        continue;
      }
      final details = <String, dynamic>{};
      if (answer.slots.isNotEmpty) {
        // Locked slots are read-only, but their previously saved answers must
        // remain in the replacement payload when another hour is saved.
        details['slots'] = Map<String, String>.from(answer.slots);
      }
      if (answer.submittedSlots.isNotEmpty) {
        final submittedSlots = answer.submittedSlots.toList()..sort();
        details['submitted_slots'] = submittedSlots;
      }
      if (!_isDos) details['client_time'] = _now.toIso8601String();
      if (answer.eligibility != null) {
        details['eligibility'] = answer.eligibility;
      }
      if (answer.subformAnswers.isNotEmpty) {
        details['subform_answers'] = answer.subformAnswers;
      }
      payloads.add({
        'item_id': item.id,
        'item_key': item.key,
        'status': template.validationMode == 'time_slots'
            ? null
            : answer.status,
        'remark': _nullableText(answer.remark),
        'finding': _nullableText(answer.finding),
        'action_plan': null,
        'commitment_date': null,
        'attachment_path': answer.attachmentPath,
        'details': details.isEmpty ? null : details,
      });
    }
    return payloads;
  }

  Future<void> _showMessage(
    String title,
    String message, {
    bool? isSuccess,
    String? statusLabel,
  }) {
    final success =
        isSuccess ??
        (() {
          final t = title.toLowerCase();
          if (t.contains('incomplete') ||
              t.contains('fail') ||
              t.contains('error') ||
              t.contains('unable') ||
              t.contains('unavailable') ||
              t.contains('warning')) {
            return false;
          }
          if (t.contains('submit') ||
              t.contains('success') ||
              t.contains('saved') ||
              t.contains('complete') ||
              t.contains('done')) {
            return true;
          }
          return false;
        })();

    final accentColor = success
        ? const Color(0xFF12B76A) // GAC Success Green
        : const Color(0xFFD92D20); // GAC Error Red

    final statusIcon = success
        ? Icons.task_alt_rounded
        : Icons.error_outline_rounded;

    return showDialog<void>(
      context: context,
      barrierDismissible: !success,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F2642),
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.28),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.42),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(statusIcon, color: GacColors.white, size: 30),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel ??
                    (success ? 'CHECKLIST COMPLETE' : 'ACTION REQUIRED'),
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GacColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('checklist-message-ok-button'),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: GacColors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: Icon(
                success ? Icons.check_circle_rounded : Icons.close_rounded,
                size: 18,
              ),
              label: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmPrerequisiteNoSelection({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F2642),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GacColors.border),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD92D20),
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: GacColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: GacColors.gray,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel-prerequisite-warning'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: GacColors.gray,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FilledButton(
            key: const ValueKey('confirm-prerequisite-warning'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD92D20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'CONFIRM & MARK NO',
              style: TextStyle(
                color: GacColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmUndoChoice({String? choiceLabel}) =>
      _showUndoChoiceConfirmationDialog(context, choiceLabel: choiceLabel);

  Future<void> _handleStatusSelection({
    required ChecklistItemData item,
    required String? newStatus,
    ChecklistSectionData? section,
  }) async {
    if (_readOnly) return;
    final currentStatus = _answers[item.key]?.status;
    if (newStatus == currentStatus) {
      if (currentStatus != null) {
        final confirmed = await _confirmUndoChoice(choiceLabel: currentStatus);
        if (!confirmed || !mounted) return;
        _answers[item.key]?.status = null;
        _isDirty = true;
        _fieldRevision++;
        setState(() {});
      }
      return;
    }

    if (_isSubform && newStatus == 'no') {
      final effectiveSection =
          section ??
          _template?.sections.firstWhere(
            (s) => s.items.any((i) => i.key == item.key),
            orElse: () => ChecklistSectionData(
              id: 0,
              key: '',
              title: 'Subform Section',
              sortOrder: 0,
              metadata: const {},
              items: const [],
            ),
          );
      final sectionTitle = effectiveSection?.title ?? 'Subform Section';
      final confirmed = await _confirmPrerequisiteNoSelection(
        title: 'Prerequisite Warning',
        message:
            'Selecting "NO" will automatically set all questions in "$sectionTitle" to "NO".\n\nAre you sure you want to proceed?',
      );
      if (!confirmed) return;

      if (effectiveSection != null && effectiveSection.items.isNotEmpty) {
        for (final secItem in effectiveSection.items) {
          _answers[secItem.key]?.status = 'no';
        }
      } else {
        _answers[item.key]?.status = 'no';
      }
      _isDirty = true;
      _fieldRevision++;
      setState(() {});
      return;
    }

    _answers[item.key]?.status = newStatus;
    _isDirty = true;
    setState(() {});
  }

  // Temporary testing helper; remove together with the Randomize answers button.
  void _randomizeAnswers() {
    final template = _template;
    if (template == null || _loading || _saving || _readOnly) return;
    final random = math.Random();
    const statuses = ['yes', 'no', 'na'];
    String randomStatus() => statuses[random.nextInt(statuses.length)];

    setState(() {
      if (_isDocumentation) {
        for (final customer in _customers) {
          if (_isCustomerReadOnly(customer)) continue;
          final status = randomStatus();
          for (final item in template.sections.expand((s) => s.items)) {
            customer.answers[item.key] = status;
          }
        }
      } else {
        for (final section in template.sections) {
          final subformStatus = _isSubform ? randomStatus() : null;
          for (final item in section.items) {
            final answer = _answers.putIfAbsent(item.key, _ChecklistAnswer.new);
            if (_isHourly) {
              for (final slot in template.timeSlots) {
                if (slot.key != _effectiveSlotKey(template) ||
                    _isSlotLocked(slot) ||
                    !item.isSlotActive(slot.key) ||
                    answer.submittedSlots.contains(slot.key)) {
                  continue;
                }
                const marks = ['good', 'not_good', 'na'];
                answer.slots[slot.key] = marks[random.nextInt(marks.length)];
                if (answer.slots[slot.key] != 'good' &&
                    answer.remark.trim().isEmpty) {
                  answer.remark = 'Randomized test remark.';
                }
              }
              continue;
            }
            answer.status = subformStatus ?? randomStatus();
            if (!_isSubform && _isSubformReferenceItem(item, template)) {
              final subform = _getSubformSection(item);
              answer.subformAnswers.clear();
              answer.eligibility = answer.status == 'na' || subform == null
                  ? 'na'
                  : 'show_subform';
              if (answer.eligibility == 'na') {
                answer.status = 'na';
              } else {
                for (final subItem in subform!.items) {
                  answer.subformAnswers[subItem.id] = answer.status!;
                }
              }
            }
            if (answer.status == 'no' || answer.status == 'na') {
              if (template.validationMode == 'dos') {
                if (answer.finding.trim().isEmpty) {
                  answer.finding = 'Randomized test finding / N/A reason.';
                }
              } else if (answer.remark.trim().isEmpty) {
                answer.remark = 'Randomized test remark / N/A reason.';
              }
            }
          }
        }
      }
      _isDirty = true;
      _fieldRevision++;
    });
  }

  Future<void> _pickPhotoForItem(String itemKey) async {
    final takePhoto = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF0F2642),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'ATTACH DEFECT PHOTO',
                style: TextStyle(
                  color: GacColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0x262979FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: GacColors.primary,
                  ),
                ),
                title: const Text(
                  'Take Photo with Camera',
                  style: TextStyle(
                    color: GacColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          ),
        ),
      ),
    );

    if (takePhoto != true || !mounted) return;

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1440,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        final answer = _answers[itemKey]!;
        answer.localAttachmentBytes = bytes;
        answer.localAttachmentName = file.name;
        answer.attachmentPath = null;
        answer.attachmentUrl = null;
        _isDirty = true;
      });
    } catch (_) {
      if (mounted) {
        await _showMessage(
          'Photo unavailable',
          'Cannot access the camera on this device.',
        );
      }
    }
  }

  void _removePhotoForItem(String itemKey) {
    setState(() {
      final answer = _answers[itemKey]!;
      answer.localAttachmentBytes = null;
      answer.localAttachmentName = null;
      answer.attachmentPath = null;
      answer.attachmentUrl = null;
      _isDirty = true;
    });
  }

  DateTime? _slotStart(ChecklistTimeSlot slot) {
    final auditDate = DateTime.tryParse(_auditDate);
    if (auditDate == null) return null;
    final parts = slot.key.split(':');
    if (parts.isEmpty || parts.length > 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return DateTime(
      auditDate.year,
      auditDate.month,
      auditDate.day,
      hour,
      minute,
    );
  }

  bool _isSlotLocked(ChecklistTimeSlot slot, {DateTime? now}) {
    final slotStart = _slotStart(slot);
    if (slotStart == null) return true;
    final currentTime = now ?? _now;
    final slotEnd = slotStart.add(const Duration(hours: 1));
    return currentTime.isBefore(slotStart) || !currentTime.isBefore(slotEnd);
  }

  bool _isSlotExpired(ChecklistTimeSlot slot, {DateTime? now}) {
    final slotStart = _slotStart(slot);
    if (slotStart == null) return false;
    final currentTime = now ?? _now;
    return !currentTime.isBefore(slotStart.add(const Duration(hours: 1)));
  }

  bool _markMissedHourlySlots(ChecklistTemplateData template) {
    final isHourly =
        template.validationMode == 'time_slots' ||
        template.slug == 'restroom' ||
        template.slug == 'utilities';
    if (!isHourly || _readOnly) return false;

    final now = _now;
    var changed = false;
    for (final section in template.sections) {
      for (final item in section.items) {
        final answer = _answers[item.key];
        if (answer == null) continue;
        for (final slot in template.timeSlots) {
          if (!item.isSlotActive(slot.key)) continue;
          final existingMark = answer.slots[slot.key]?.trim().toLowerCase();
          final wasMissed =
              existingMark == null ||
              existingMark.isEmpty ||
              existingMark == 'unanswered';
          if (_isSlotExpired(slot, now: now) && wasMissed) {
            answer.slots[slot.key] = 'not_good';
            changed = true;
          }
        }
      }
    }
    return changed;
  }

  String _detectCurrentSlotKey(List<ChecklistTimeSlot> slots) {
    if (slots.isEmpty) return '08:00';
    final now = _now;
    final orderedSlots =
        slots
            .map((slot) => (slot: slot, start: _slotStart(slot)))
            .where((entry) => entry.start != null)
            .toList()
          ..sort((left, right) => left.start!.compareTo(right.start!));
    if (orderedSlots.isEmpty) return slots.first.key;

    for (final entry in orderedSlots) {
      final start = entry.start!;
      if (!now.isBefore(start) &&
          now.isBefore(start.add(const Duration(hours: 1)))) {
        return entry.slot.key;
      }
    }
    for (final entry in orderedSlots) {
      if (now.isBefore(entry.start!)) return entry.slot.key;
    }
    return orderedSlots.last.slot.key;
  }

  ChecklistTimeSlot? _lastChronologicalSlot(List<ChecklistTimeSlot> slots) {
    if (slots.isEmpty) return null;
    final orderedSlots =
        slots
            .map((slot) => (slot: slot, start: _slotStart(slot)))
            .where((entry) => entry.start != null)
            .toList()
          ..sort((left, right) => left.start!.compareTo(right.start!));
    return orderedSlots.isEmpty ? slots.last : orderedSlots.last.slot;
  }

  bool _moveFromExpiredHourlySlot(ChecklistTemplateData template) {
    final activeKey = _activeSlotKey;
    if (template.timeSlots.isEmpty) return false;
    final currentSlotKey = _detectCurrentSlotKey(template.timeSlots);
    if (activeKey == null) {
      _activeSlotKey = currentSlotKey;
      return true;
    }
    final activeSlot = template.timeSlots
        .where((slot) => slot.key == activeKey)
        .firstOrNull;
    if (activeSlot == null) {
      _activeSlotKey = currentSlotKey;
      return currentSlotKey != activeKey;
    }
    // Keep an explicitly linked response visible while reviewing its hour.
    if (widget.initialItemKey != null && widget.initialSlotKey == activeKey) {
      return false;
    }
    if (!_isSlotExpired(activeSlot)) return false;

    if (currentSlotKey == activeKey) return false;
    _activeSlotKey = currentSlotKey;
    return true;
  }

  bool _refreshHourlyWindow(
    ChecklistTemplateData template, {
    bool markDirty = true,
  }) {
    if (widget.attentionOnly) return false;
    final isHourly =
        template.validationMode == 'time_slots' ||
        template.slug == 'restroom' ||
        template.slug == 'utilities';
    if (!isHourly || _readOnly) return false;

    final answersChanged = _markMissedHourlySlots(template);
    final slotChanged = _moveFromExpiredHourlySlot(template);
    if (answersChanged && markDirty) _isDirty = true;
    if (slotChanged) {
      _sectionIndex = 0;
      _stepQuestionIndex = 0;
      _listViewSlotFilter = null;
    }
    return answersChanged || slotChanged;
  }

  String _effectiveSlotKey(ChecklistTemplateData template) {
    if (_listViewSlotFilter != null &&
        template.timeSlots.any((s) => s.key == _listViewSlotFilter)) {
      return _listViewSlotFilter!;
    }
    final current = _activeSlotKey;
    if (current != null && template.timeSlots.any((s) => s.key == current)) {
      // Keep an explicitly selected past or future slot visible so the user
      // sees its CLOSED/LOCKED explanation. Editing remains blocked by the
      // slot-state checks in the answer controls.
      return current;
    }
    return _detectCurrentSlotKey(template.timeSlots);
  }

  void _scheduleSlotWindowRefresh() {
    _slotWindowTimer?.cancel();
    if (widget.attentionOnly) return;
    final template = _template;
    if (widget.nowProvider != null ||
        template == null ||
        (template.validationMode != 'time_slots' &&
            template.slug != 'restroom' &&
            template.slug != 'utilities')) {
      return;
    }

    final now = _now;
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));
    _slotWindowTimer = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      setState(() {
        final currentTemplate = _template;
        if (currentTemplate != null) {
          _refreshHourlyWindow(currentTemplate);
        }
      });
      _scheduleSlotWindowRefresh();
    });
  }

  String get _headerTitle {
    if (_isDocumentation) return 'Documentation Audit';
    if (_isSubform) return 'Subform Audit';
    if (_isDos) {
      return _effectiveTrack == DosAuditTrack.sales
          ? 'Sales Audit'
          : 'Aftersales Audit';
    }
    return _template?.name ?? 'Checklist';
  }

  bool _handleHeaderScroll(UserScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.direction == ScrollDirection.idle &&
        notification.metrics.pixels > 8) {
      return false;
    }
    final shouldExpand =
        notification.metrics.pixels <= 8 ||
        notification.direction == ScrollDirection.forward;
    if (shouldExpand != _topBarExpanded) {
      setState(() => _topBarExpanded = shouldExpand);
    }
    return false;
  }

  void _scrollToTop() {
    for (final position in _listScrollController.positions.toList()) {
      position.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
    setState(() => _topBarExpanded = true);
  }

  Future<void> _handleBack() async {
    if (_isDirty && !_saving && !_readOnly) {
      await _autoSaveDraft();
    }
    if (!mounted) return;
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _handleOpenNotifications() {
    if (widget.onOpenNotifications != null) {
      widget.onOpenNotifications!();
      return;
    }
    final user = widget.user;
    if (user == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (notificationContext) => UserNotificationsScreen(
          profile: user,
          checklistRepository: widget.repository,
          onOpenProfile: () => Navigator.of(notificationContext).pop(),
          onGoHome: () => Navigator.of(notificationContext).pop(),
          onOpenSettings: () => Navigator.of(notificationContext).pop(),
        ),
      ),
    );
  }

  Widget _buildChecklistActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Temporary testing button, available to every user role.
              if (!widget.attentionOnly)
                Flexible(
                  child: TextButton(
                    onPressed:
                        _loading || _saving || _readOnly || _template == null
                        ? null
                        : _randomizeAnswers,
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Randomize answers'),
                  ),
                ),
              if (!_loading && !widget.attentionOnly)
                IconButton(
                  tooltip: _stepByStepMode
                      ? 'Switch to list view'
                      : 'Switch to step-by-step',
                  onPressed: () {
                    setState(() {
                      _stepByStepMode = !_stepByStepMode;
                      if (_stepByStepMode && _template != null) {
                        final questions = _getQuestionsForTemplate(_template!);
                        if (questions.isNotEmpty) {
                          final inSection = questions.indexWhere(
                            (q) => q.sectionIndex == _sectionIndex,
                          );
                          if (inSection != -1) {
                            _stepQuestionIndex = inSection;
                          }
                        }
                      }
                    });
                  },
                  icon: Icon(
                    _stepByStepMode
                        ? Icons.view_list_rounded
                        : Icons.view_carousel_rounded,
                  ),
                ),
              IconButton(
                tooltip: 'Refresh checklist from Server',
                onPressed: _loading || _saving ? null : () => _load(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (_isDirty && !_saving && !_readOnly) {
          unawaited(_autoSaveDraft());
        }
      },
      child: GacScreenBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: PrimaryScrollController(
              controller: _listScrollController,
              child: NotificationListener<UserScrollNotification>(
                onNotification: _handleHeaderScroll,
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: UserChecklistFloatingHeader.extent,
                      child: Column(
                        children: [
                          _buildChecklistActions(),
                          Expanded(child: _buildBody()),
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
                        title: _headerTitle,
                        subtitle: _effectiveCategoryFilter == null
                            ? 'Audit Compliance App'
                            : '${_effectiveCategoryFilter!} · Audit Compliance App',
                        backLabel: 'Back to checklists',
                        onBack: _handleBack,
                        onOpenNotifications: _handleOpenNotifications,
                        onTapTitle: _scrollToTop,
                        unreadNotifications: widget.unreadNotifications,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackSwitcher() {
    return _ChecklistDetailHeaderPanel(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildTrackPill(
              track: DosAuditTrack.aftersales,
              title: 'AFTERSALES (75)',
              icon: Icons.car_repair_rounded,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTrackPill(
              track: DosAuditTrack.sales,
              title: 'SALES (90)',
              icon: Icons.storefront_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackPill({
    required DosAuditTrack track,
    required String title,
    required IconData icon,
  }) {
    final active = _effectiveTrack == track;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _handleTrackSwitch(track),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0x2E2979FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? GacColors.primary : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: active ? GacColors.primary : GacColors.gray,
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    color: active ? GacColors.primary : GacColors.gray,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTrackSwitch(DosAuditTrack track) async {
    if (track == _effectiveTrack) return;
    if (_isDos && _isDirty && !_saving && !_readOnly) {
      await _autoSaveDraft();
    }
    if (widget.onTrackChanged != null) {
      widget.onTrackChanged!(track);
    } else {
      setState(() {
        _localSlugOverride = track == DosAuditTrack.aftersales
            ? 'dealer-operations-standards'
            : 'dealer-operations-standards-sales';
        _sectionIndex = 0;
        _stepQuestionIndex = 0;
        _isDirty = false;
      });
      _load();
    }
  }

  void _closeAttentionReview() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildAttentionReview(ChecklistTemplateData template) {
    final targets = _attentionReviewTargets;
    if (targets.isEmpty || _attentionReviewComplete) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                targets.isEmpty
                    ? 'No responses need review.'
                    : 'Review complete',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (targets.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('All No and N/A responses have been reviewed.'),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('attention-review-done'),
                onPressed: _closeAttentionReview,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }

    final target = targets[_attentionReviewIndex];
    final question = _getQuestionsForTemplate(template)
        .firstWhere((question) => question.item.key == target.itemKey);
    final customer = target.customerIndex == null
        ? null
        : _customers.firstWhere(
            (customer) => customer.customerIndex == target.customerIndex,
          );
    final slot = target.slotKey == null
        ? null
        : template.timeSlots.firstWhere((slot) => slot.key == target.slotKey);
    final last = _attentionReviewIndex == targets.length - 1;

    void showResponse(int index) {
      setState(() {
        _attentionReviewIndex = index;
        _fieldRevision++;
      });
    }

    return Column(
      key: const ValueKey('attention-review'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: GacColors.cardSurface,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GacColors.amber400.withValues(alpha: 0.10),
                      GacColors.cardSurface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: GacColors.amber400.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: GacColors.amber400,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Attention needed',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: GacColors.white,
                                  letterSpacing: -0.2,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.assignment_late_outlined,
                          size: 15,
                          color: GacColors.gray,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${_attentionReviewIndex + 1} of ${targets.length} responses · No / N/A',
                            key: const ValueKey('attention-review-position'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: GacColors.gray,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            primary: true,
            key: ValueKey(
              'attention-response-$_attentionReviewIndex-$_fieldRevision',
            ),
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(question.section.title),
                    if (slot != null) Text('Inspection: ${slot.label}'),
                    if (customer != null) ...[
                      Text('Customer ${customer.customerIndex}'),
                      if (customer.roNumber.isNotEmpty)
                        Text('R.O. ${customer.roNumber}'),
                      if (customer.mileage.isNotEmpty) Text(customer.mileage),
                    ],
                    const SizedBox(height: 12),
                    if (customer != null)
                      _buildDocQuestionCard(
                        item: question.item,
                        status: customer.answers[target.itemKey],
                        enabled: false,
                        onStatusSelected: (_) {},
                      )
                    else
                      _ChecklistQuestionCard(
                        item: question.item,
                        answer: _answers[target.itemKey]!,
                        template: template,
                        readOnly: true,
                        attentionOnly: true,
                        prominent: true,
                        visibleSlots: slot == null ? null : [slot],
                        isSlotLocked: _isSlotLocked,
                        onChanged: () {},
                        onPickCommitmentDate: () {},
                        onPickPhoto: () {},
                        onRemovePhoto: () {},
                        onShowHowToCheck: () =>
                            _showHowToCheckModal(context, question.item),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('attention-review-previous'),
                    onPressed: _attentionReviewIndex == 0
                        ? null
                        : () => showResponse(_attentionReviewIndex - 1),
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('attention-review-next'),
                    onPressed: last
                        ? () => setState(() => _attentionReviewComplete = true)
                        : () => showResponse(_attentionReviewIndex + 1),
                    child: Text(last ? 'Finish review' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ChecklistLoadError(message: _error!, onRetry: _load);
    }
    final template = _template!;
    if (template.sections.isEmpty) {
      return const _ChecklistLoadError(
        message: 'This checklist has no active sections yet.',
      );
    }

    if (widget.attentionOnly) return _buildAttentionReview(template);

    final isUtilities =
        template.validationMode == 'time_slots' ||
        template.slug == 'restroom' ||
        template.slug == 'utilities';

    if (isUtilities && _stepByStepMode) {
      final allItems = template.sections.expand((s) => s.items).toList();
      return _UtilitiesQuestionByQuestionView(
        template: template,
        items: allItems,
        questionIndex: _stepQuestionIndex.clamp(
          0,
          (allItems.length - 1).clamp(0, 1000),
        ),
        activeSlotKey: _effectiveSlotKey(template),
        answers: _answers,
        readOnly: _readOnly,
        saving: _saving,
        isSlotLocked: _isSlotLocked,
        isSlotExpired: _isSlotExpired,
        onSlotSelected: (slotKey) => setState(() {
          _activeSlotKey = slotKey;
          _sectionIndex = 0;
          _stepQuestionIndex = _readOnly
              ? (allItems.length - 1).clamp(0, 1000)
              : 0;
        }),
        onQuestionChanged: (index) =>
            setState(() => _stepQuestionIndex = index),
        onPickPhoto: _pickPhotoForItem,
        onRemovePhoto: _removePhotoForItem,
        onShowHowToCheck: (item) => _showHowToCheckModal(context, item),
        onSubmit: () => _save(submit: true),
        onChanged: () => setState(() => _isDirty = true),
      );
    }

    if (_isDocumentation) {
      return _buildDocumentationView(template);
    }

    if (_stepByStepMode) {
      return _buildQuestionFlow(template);
    }

    final section = template.sections[_sectionIndex];
    final progress = _progress(template);
    final sectionIncomplete = _sectionHasIncompleteItem(section);
    final activeSlotKey = _effectiveSlotKey(template);
    final selectedSlotKey = _listViewSlotFilter ?? activeSlotKey;
    final allItems = template.sections.expand((s) => s.items).toList();
    final isCurrentSlotSubmitted =
        isUtilities &&
        template.timeSlots.isNotEmpty &&
        allItems.isNotEmpty &&
        allItems.every(
          (item) =>
              _answers[item.key]?.submittedSlots.contains(selectedSlotKey) ??
              false,
        );

    return Column(
      children: [
        if (_isDos && _canSwitchTrack && _effectiveCategoryFilter == null)
          _buildTrackSwitcher(),
        _ChecklistDetailHeaderPanel(
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 17),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (template.sections.length > 1) ...[
                        IconButton(
                          tooltip: 'Previous section',
                          onPressed: _saving || _sectionIndex == 0
                              ? null
                              : () {
                                  setState(() => _sectionIndex--);
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (_listScrollController.hasClients) {
                                      _listScrollController.jumpTo(0);
                                    }
                                  });
                                },
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next section',
                          onPressed:
                              _saving ||
                                  _sectionIndex ==
                                      template.sections.length - 1 ||
                                  (!_readOnly && sectionIncomplete)
                              ? null
                              : () {
                                  setState(() => _sectionIndex++);
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (_listScrollController.hasClients) {
                                      _listScrollController.jumpTo(0);
                                    }
                                  });
                                },
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          isUtilities
                              ? (_listViewSlotFilter == null
                                    ? 'ALL TIME SLOTS  ·  VERSION ${template.version}'
                                    : 'INSPECTION TIME: ${template.timeSlots.firstWhere(
                                        (s) => s.key == _listViewSlotFilter,
                                        orElse: () => ChecklistTimeSlot(key: _listViewSlotFilter!, label: _listViewSlotFilter!),
                                      ).label.toUpperCase()}  ·  VERSION ${template.version}')
                              : 'SECTION ${_sectionIndex + 1} OF ${template.sections.length}  ·  VERSION ${template.version}',
                          style: const TextStyle(
                            color: GacColors.gray,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Text(
                        '${progress.round()}%',
                        style: const TextStyle(
                          color: GacColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!_readOnly && !isCurrentSlotSubmitted)
                        FilledButton(
                          key: const ValueKey('checklist-header-submit-button'),
                          onPressed: _saving ? null : () => _save(submit: true),
                          style: FilledButton.styleFrom(
                            backgroundColor: GacColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            minimumSize: const Size(72, 34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: GacColors.white,
                                  ),
                                )
                              : const Text(
                                  'SUBMIT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                        )
                      else
                        const _SubmittedPill(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 7,
                      backgroundColor: GacColors.lightGray,
                      valueColor: const AlwaysStoppedAnimation(
                        GacColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    section.title,
                    style: const TextStyle(
                      color: GacColors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (template.instructions case final instructions?) ...[
                    const SizedBox(height: 5),
                    Text(
                      instructions,
                      style: const TextStyle(
                        color: GacColors.gray,
                        fontSize: 10,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (isUtilities && template.timeSlots.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _ShowAllPill(
                            isSelected: _listViewSlotFilter == null,
                            onTap: () {
                              if (_listViewSlotFilter == null) return;
                              FocusScope.of(context).unfocus();
                              setState(() => _fieldRevision++);
                              Future.delayed(
                                const Duration(milliseconds: 80),
                                () {
                                  if (!mounted) return;
                                  setState(() {
                                    _listViewSlotFilter = null;
                                    _sectionIndex = 0;
                                    _stepQuestionIndex = 0;
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (_listScrollController.hasClients) {
                                      _listScrollController.jumpTo(0);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          for (final slot in template.timeSlots) ...[
                            _SlotPill(
                              slot: slot,
                              isSelected: _listViewSlotFilter == slot.key,
                              isAnswered:
                                  allItems.isNotEmpty &&
                                  allItems.every((i) {
                                    final mark = _answers[i.key]
                                        ?.slots[slot.key]
                                        ?.trim()
                                        .toLowerCase();
                                    return mark != null &&
                                        mark.isNotEmpty &&
                                        mark != 'unanswered';
                                  }),
                              hasDefect: allItems.any(
                                (i) =>
                                    _answers[i.key]?.slots[slot.key] ==
                                    'not_good',
                              ),
                              isLocked: _isSlotLocked(slot),
                              onTap: () {
                                if (_listViewSlotFilter == slot.key) return;
                                FocusScope.of(context).unfocus();
                                setState(() => _fieldRevision++);
                                Future.delayed(
                                  const Duration(milliseconds: 80),
                                  () {
                                    if (!mounted) return;
                                    setState(() {
                                      _listViewSlotFilter = slot.key;
                                      _activeSlotKey = slot.key;
                                      _sectionIndex = 0;
                                      _stepQuestionIndex = 0;
                                    });
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (_listScrollController
                                              .hasClients) {
                                            _listScrollController.jumpTo(0);
                                          }
                                        });
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (_readOnly) ...[
                    const SizedBox(height: 10),
                    const _SubmittedNotice(),
                  ],
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: _listScrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              _isDos
                  ? (96 + MediaQuery.viewPaddingOf(context).bottom)
                  : (isUtilities
                        ? (24 + MediaQuery.viewPaddingOf(context).bottom)
                        : 24),
            ),
            itemCount: section.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = section.items[index];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _ChecklistQuestionCard(
                    key: ValueKey(
                      '${item.key}-$_fieldRevision-${_listViewSlotFilter ?? "all"}',
                    ),
                    item: item,
                    answer: _answers[item.key]!,
                    template: template,
                    visibleSlots: _listViewSlotFilter == null
                        ? null
                        : [
                            template.timeSlots.firstWhere(
                              (s) => s.key == _listViewSlotFilter,
                              orElse: () => ChecklistTimeSlot(
                                key: _listViewSlotFilter!,
                                label: _listViewSlotFilter!,
                              ),
                            ),
                          ],
                    readOnly: _readOnly,
                    showDosEscalationAndCommitment:
                        _requiresDosEscalationAndCommitment,
                    showDosBomTask: _showsDosBomTask,
                    showDosActionPlan: _requiresDosActionPlan,
                    isSlotLocked: _isSlotLocked,
                    onChanged: () => setState(() => _isDirty = true),
                    onPickCommitmentDate: () => _pickCommitmentDate(item.key),
                    onPickPhoto: () => _pickPhotoForItem(item.key),
                    onRemovePhoto: () => _removePhotoForItem(item.key),
                    onShowHowToCheck: () => _showHowToCheckModal(context, item),
                    onSelectStatus: (status) => _handleStatusSelection(
                      item: item,
                      newStatus: status,
                      section: section,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _sectionHasIncompleteItem(ChecklistSectionData section) {
    return section.items.any((item) {
      final answer = _answers[item.key];
      final status = answer?.status?.trim().toLowerCase();
      if (status == null || status.isEmpty) return true;
      if (status == 'na' &&
          (answer?.remark.trim().isEmpty ?? true) &&
          (answer?.finding.trim().isEmpty ?? true)) {
        return true;
      }
      if (status == 'no') {
        final hasFinding = answer?.finding.trim().isNotEmpty ?? false;
        final hasRemark = answer?.remark.trim().isNotEmpty ?? false;
        if (!hasFinding && !hasRemark) return true;
      }
      return false;
    });
  }

  Widget _buildQuestionFlow(ChecklistTemplateData template) {
    final questions = _getQuestionsForTemplate(template);

    if (questions.isEmpty) {
      return _ChecklistLoadError(
        message: _isDos
            ? 'No DOS questions are assigned to this account.'
            : 'No checklist questions are available.',
      );
    }

    final questionIndex = _stepQuestionIndex.clamp(0, questions.length - 1);
    final question = questions[questionIndex];
    final item = question.item;
    final progress = _progress(template);
    final currentAnswer = _answers[item.key];
    final currentStatus = currentAnswer?.status?.trim().toLowerCase();
    final hasChosenChoice = currentStatus != null && currentStatus.isNotEmpty;
    final isDos = template.validationMode == 'dos';
    final isSubform = template.validationMode == 'dos_subform';

    final isFindingRequired = isDos && currentStatus == 'no';
    final hasFinding =
        currentAnswer != null && currentAnswer.finding.trim().isNotEmpty;

    final isNaReasonRequired = !isSubform && currentStatus == 'na';
    final hasNaReason =
        currentAnswer != null &&
        (isDos
            ? currentAnswer.finding.trim().isNotEmpty
            : (currentAnswer.remark.trim().isNotEmpty ||
                  currentAnswer.finding.trim().isNotEmpty));

    final isDefectRemarkRequired =
        !isDos && !isSubform && currentStatus == 'no';
    final hasDefectRemark =
        currentAnswer != null &&
        (currentAnswer.remark.trim().isNotEmpty ||
            currentAnswer.finding.trim().isNotEmpty);

    final isSubformRef =
        isDos && !isSubform && _isSubformReferenceItem(item, template);
    final subformSec = isSubformRef ? _getSubformSection(item) : null;
    final isSubformComplete =
        subformSec == null ||
        (currentAnswer?.eligibility == 'na') ||
        (currentAnswer?.eligibility == 'show_subform' &&
            subformSec.items.every(
              (si) =>
                  currentAnswer?.subformAnswers.containsKey(si.id) == true &&
                  currentAnswer?.subformAnswers[si.id] != null &&
                  currentAnswer!.subformAnswers[si.id]!.isNotEmpty,
            ));

    final canProceed =
        _readOnly ||
        (hasChosenChoice &&
            (!isSubformRef || isSubformComplete) &&
            (!isNaReasonRequired || hasNaReason) &&
            (!isFindingRequired || hasFinding) &&
            (!isDefectRemarkRequired || hasDefectRemark));

    void showQuestion(int index) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _stepQuestionIndex = index.clamp(0, questions.length - 1);
        _sectionIndex = questions[_stepQuestionIndex].sectionIndex;
      });
    }

    return Column(
      key: const ValueKey('dos-question-flow'),
      children: [
        if (_isDos && _canSwitchTrack && _effectiveCategoryFilter == null)
          _buildTrackSwitcher(),
        _ChecklistDetailHeaderPanel(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 15),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'QUESTION ${questionIndex + 1} OF ${questions.length}',
                          key: const ValueKey('dos-question-position'),
                          style: const TextStyle(
                            color: GacColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        '${progress.round()}%',
                        style: const TextStyle(
                          color: GacColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!_readOnly)
                        FilledButton(
                          key: const ValueKey('checklist-header-submit-button'),
                          onPressed: _saving ? null : () => _save(submit: true),
                          style: FilledButton.styleFrom(
                            backgroundColor: GacColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            minimumSize: const Size(72, 34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: GacColors.white,
                                  ),
                                )
                              : Text(
                                  _isCategoryView
                                      ? (_isReadyToSubmit ? 'SUBMIT' : 'SAVE')
                                      : 'SUBMIT',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                        )
                      else
                        const _SubmittedPill(),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 7,
                      backgroundColor: GacColors.lightGray,
                      valueColor: const AlwaysStoppedAnimation(
                        GacColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    question.section.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GacColors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'SECTION ${question.sectionIndex + 1} OF ${template.sections.length}  ·  VERSION ${template.version}',
                    style: const TextStyle(
                      color: GacColors.gray,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  if (_readOnly) ...[
                    const SizedBox(height: 9),
                    const _SubmittedNotice(),
                  ],
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            primary: true,
            key: ValueKey('dos-question-page-${item.key}'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              18,
              16,
              18,
              (!_isDos ? 24 : 102) + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  children: [
                    _ChecklistQuestionCard(
                      key: ValueKey('${item.key}-$_fieldRevision'),
                      item: item,
                      answer: _answers[item.key]!,
                      template: template,
                      readOnly: _readOnly,
                      showDosEscalationAndCommitment:
                          _requiresDosEscalationAndCommitment,
                      showDosBomTask: _showsDosBomTask,
                      showDosActionPlan: _requiresDosActionPlan,
                      prominent: true,
                      isSlotLocked: _isSlotLocked,
                      onChanged: () => setState(() => _isDirty = true),
                      onPickCommitmentDate: () => _pickCommitmentDate(item.key),
                      onPickPhoto: () => _pickPhotoForItem(item.key),
                      onRemovePhoto: () => _removePhotoForItem(item.key),
                      onShowHowToCheck: () =>
                          _showHowToCheckModal(context, item),
                      onSelectStatus: (status) => _handleStatusSelection(
                        item: item,
                        newStatus: status,
                        section: question.section,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('dos-previous-question'),
                            onPressed: _saving || questionIndex == 0
                                ? null
                                : () => showQuestion(questionIndex - 1),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'PREVIOUS',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey('dos-next-question'),
                            onPressed: _saving || !canProceed
                                ? null
                                : questionIndex < questions.length - 1
                                ? () => showQuestion(questionIndex + 1)
                                : _readOnly
                                ? null
                                : () => _save(submit: true),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 54),
                              backgroundColor: GacColors.primary,
                              disabledBackgroundColor: const Color(0xFF153A56),
                              disabledForegroundColor: GacColors.textMuted,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            icon: Icon(
                              questionIndex < questions.length - 1
                                  ? Icons.arrow_forward_rounded
                                  : (_isReadyToSubmit
                                        ? Icons.task_alt_rounded
                                        : Icons.arrow_forward_rounded),
                              size: 18,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                questionIndex < questions.length - 1
                                    ? 'NEXT QUESTION'
                                    : (_isReadyToSubmit
                                          ? 'SUBMIT CHECKLIST'
                                          : 'NEXT CATEGORY'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCommitmentDate(String itemKey) async {
    final answer = _answers[itemKey]!;
    final savedCommitment = answer.commitmentDate?.trim();
    final parsedCommitment = DateTime.tryParse(savedCommitment ?? '');
    final initial =
        parsedCommitment ?? DateTime.now().add(const Duration(days: 1));
    final hasSavedTime = _hasExplicitTime(savedCommitment);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: hasSavedTime ? initial.hour : 17,
        minute: hasSavedTime ? initial.minute : 0,
      ),
    );
    if (selectedTime == null || !mounted) return;

    final dateFormatted = _dateString(selectedDate);
    final timeFormatted =
        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
    setState(() {
      answer.commitmentDate = '$dateFormatted $timeFormatted';
      _isDirty = true;
    });
  }

  void _showHowToCheckModal(BuildContext context, ChecklistItemData item) {
    final guide = item.howToCheck?.trim();
    final hasGuide = guide != null && guide.isNotEmpty;
    final howToCheck = hasGuide
        ? guide
        : 'No detailed verification guide has been inputted for this checklist item yet.';
    final category = item.category ?? item.level;
    final subject = item.subject;
    final coverage = item.coverage;

    Color categoryColor = GacColors.cyan;
    if (category != null) {
      final norm = category.toLowerCase();
      if (norm.contains('beyond')) {
        categoryColor = GacColors.amber400;
      } else if (norm.contains('standard')) {
        categoryColor = GacColors.primary;
      }
    }

    final isUtilities = _isHourly ||
        _template?.slug == 'restroom' ||
        _template?.slug == 'utilities';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: GacColors.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.fromBorderSide(
              BorderSide(color: GacColors.primary, width: 1.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: GacColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x262979FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x662979FF)),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: GacColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HOW TO CHECK GUIDE',
                              style: TextStyle(
                                color: GacColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              item.displayNumber != null
                                  ? (isUtilities
                                      ? 'Question #${item.displayNumber}'
                                      : 'Standard #${item.displayNumber}')
                                  : 'Inspection Verification Criteria',
                              style: const TextStyle(
                                color: GacColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: GacColors.gray,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (category != null || coverage != null || subject != null) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (category != null)
                          _MetaBadge(label: category, color: categoryColor),
                        if (coverage != null) _MetaBadge(label: coverage),
                        if (subject != null) _MetaBadge(label: subject),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Divider(color: GacColors.cardBorder, height: 1),
                  const SizedBox(height: 14),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CHECKLIST ITEM',
                            style: TextStyle(
                              color: GacColors.gray,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: GacColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: GacColors.cardBorder),
                            ),
                            child: Text(
                              item.prompt,
                              style: const TextStyle(
                                color: GacColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'VERIFICATION INSTRUCTIONS',
                            style: TextStyle(
                              color: GacColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: hasGuide
                                  ? const Color(0x1F2979FF)
                                  : const Color(0x0F9E9E9E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasGuide
                                    ? const Color(0x402979FF)
                                    : const Color(0x269E9E9E),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!hasGuide) ...[
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: GacColors.textMuted,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Text(
                                    howToCheck,
                                    style: TextStyle(
                                      color: hasGuide
                                          ? GacColors.textPrimary
                                          : GacColors.textMuted,
                                      fontSize: 13,
                                      height: 1.55,
                                      fontWeight: hasGuide
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontStyle: hasGuide
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: GacColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text(
                        'GOT IT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentationView(ChecklistTemplateData template) {
    final progress = _progress(template);
    final activeCustomer = _customers.firstWhere(
      (c) => c.customerIndex == _selectedCustomerIndex,
      orElse: () => _customers.first,
    );

    return Column(
      key: const ValueKey('dos-documentation-view'),
      children: [
        _ChecklistDetailHeaderPanel(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 15),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            const Text(
                              'DOCUMENTATION AUDIT',
                              style: TextStyle(
                                color: GacColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF06B6D4)
                                      .withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'OPTIONAL',
                                style: TextStyle(
                                  color: Color(0xFF06B6D4),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${progress.round()}%',
                        style: const TextStyle(
                          color: GacColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!_readOnly)
                        FilledButton(
                          key: const ValueKey('checklist-header-submit-button'),
                          onPressed: _saving ? null : () => _save(submit: true),
                          style: FilledButton.styleFrom(
                            backgroundColor: GacColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            minimumSize: const Size(72, 34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: GacColors.white,
                                  ),
                                )
                              : const Text(
                                  'SUBMIT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                        )
                      else
                        const _SubmittedPill(),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 7,
                      backgroundColor: GacColors.lightGray,
                      valueColor: const AlwaysStoppedAnimation(
                        GacColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    template.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GacColors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'CE SERVICE DOCUMENT AUDIT  ·  ${_customers.length} CUSTOMER SAMPLES',
                    style: const TextStyle(
                      color: GacColors.gray,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  if (_readOnly) ...[
                    const SizedBox(height: 9),
                    const _SubmittedNotice(),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: _buildCustomerSelectorCard(activeCustomer),
            ),
          ),
        ),
        Expanded(
          child: _stepByStepMode
              ? _buildDocumentationStepView(template, activeCustomer)
              : ListView(
                  primary: true,
                  padding: EdgeInsets.fromLTRB(
                    18,
                    4,
                    18,
                    100 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCustomerFieldsCard(activeCustomer),
                            const SizedBox(height: 14),
                            ...template.sections.map((section) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 8,
                                      top: 10,
                                    ),
                                    child: Text(
                                      section.title.toUpperCase(),
                                      style: const TextStyle(
                                        color: GacColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  ...section.items.map((item) {
                                    final status =
                                        activeCustomer.answers[item.key];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _buildDocQuestionCard(
                                        item: item,
                                        status: status,
                                        enabled: !_isCustomerReadOnly(activeCustomer),
                                        onStatusSelected: (newStatus) =>
                                            _handleDocStatusSelected(
                                              customer: activeCustomer,
                                              item: item,
                                              newStatus: newStatus,
                                              template: template,
                                            ),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            }),
                            if (!_readOnly) ...[
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                key: const ValueKey('dos-documentation-list-submit-button'),
                                onPressed: _saving ? null : () => _save(submit: true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: GacColors.primary,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.task_alt_rounded, size: 18),
                                label: const Text(
                                  'SUBMIT DOCUMENTATION CHECKLIST',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDocumentationStepView(
    ChecklistTemplateData template,
    CustomerAuditSample activeCustomer,
  ) {
    final questions = _getQuestionsForTemplate(template);
    if (questions.isEmpty) {
      return const _ChecklistLoadError(
        message: 'No documentation questions are available.',
      );
    }

    final questionIndex = _stepQuestionIndex.clamp(0, questions.length - 1);
    final question = questions[questionIndex];
    final status = activeCustomer.answers[question.item.key];
    final customerPosition = _customers.indexWhere(
      (customer) => customer.customerIndex == activeCustomer.customerIndex,
    );
    final hasPrevious = questionIndex > 0 || customerPosition > 0;
    final hasNextCustomer = customerPosition < _customers.length - 1;
    final isLastQuestion = questionIndex >= questions.length - 1;
    final isCustomerLocked = _isCustomerReadOnly(activeCustomer);
    final canProceed =
        isCustomerLocked || (status != null && status.trim().isNotEmpty);

    void showQuestion(int index) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _stepQuestionIndex = index.clamp(0, questions.length - 1);
        _sectionIndex = questions[_stepQuestionIndex].sectionIndex;
      });
    }

    void showCustomer(int position, int targetQuestion) {
      FocusManager.instance.primaryFocus?.unfocus();
      final nextCustomer = _customers[position];
      setState(() {
        _selectedCustomerIndex = nextCustomer.customerIndex;
        _stepQuestionIndex = targetQuestion.clamp(0, questions.length - 1);
        _sectionIndex = questions[_stepQuestionIndex].sectionIndex;
        _fieldRevision++;
      });
    }

    void previous() {
      if (questionIndex > 0) {
        showQuestion(questionIndex - 1);
      } else if (customerPosition > 0) {
        showCustomer(customerPosition - 1, questions.length - 1);
      }
    }

    void next() {
      if (questionIndex < questions.length - 1) {
        showQuestion(questionIndex + 1);
      } else if (hasNextCustomer) {
        showCustomer(customerPosition + 1, 0);
      } else if (!_readOnly) {
        unawaited(_save(submit: true));
      }
    }

    final nextLabel = !isLastQuestion
        ? 'NEXT QUESTION'
        : hasNextCustomer
        ? 'NEXT CUSTOMER'
        : _readOnly
        ? 'CHECKLIST SUBMITTED'
        : 'SUBMIT CHECKLIST';

    return Column(
      key: const ValueKey('dos-documentation-step-view'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            primary: true,
            key: ValueKey(
              'documentation-question-${activeCustomer.customerIndex}-${question.item.key}',
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GacContentPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      borderRadius: 14,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CUSTOMER ${activeCustomer.customerIndex}  ·  QUESTION ${questionIndex + 1} OF ${questions.length}',
                                  key: const ValueKey(
                                    'dos-documentation-question-position',
                                  ),
                                  style: const TextStyle(
                                    color: GacColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.65,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  question.section.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: GacColors.gray,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _MetaBadge(
                            label:
                                '${customerPosition + 1}/${_customers.length} SAMPLES',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCustomerFieldsCard(activeCustomer),
                    const SizedBox(height: 12),
                    _buildDocQuestionCard(
                      item: question.item,
                      status: status,
                      enabled: !_isCustomerReadOnly(activeCustomer),
                      onStatusSelected: (newStatus) => _handleDocStatusSelected(
                        customer: activeCustomer,
                        item: question.item,
                        newStatus: newStatus,
                        template: template,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: GacContentPanel(
                  key: const ValueKey('documentation-step-controls'),
                  padding: const EdgeInsets.all(10),
                  borderRadius: 16,
                  color: GacColors.glassSurfaceStrong,
                  shadowBlurRadius: 18,
                  shadowOffset: const Offset(0, -4),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('dos-previous-question'),
                          onPressed: _saving || !hasPrevious ? null : previous,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 17),
                          label: const FittedBox(
                            child: Text(
                              'PREVIOUS',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('dos-next-question'),
                          onPressed: _saving ||
                                  !canProceed ||
                                  (_readOnly &&
                                      isLastQuestion &&
                                      !hasNextCustomer)
                              ? null
                              : next,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            backgroundColor: GacColors.primary,
                            disabledBackgroundColor: const Color(0xFF153A56),
                            disabledForegroundColor: GacColors.textMuted,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            isLastQuestion && !hasNextCustomer
                                ? Icons.task_alt_rounded
                                : Icons.arrow_forward_rounded,
                            size: 17,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              nextLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSelectorCard(CustomerAuditSample activeCustomer) {
    return GacContentPanel(
      key: const ValueKey('documentation-customer-selector'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          final customerPicker = Row(
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_alt_rounded,
                color: GacColors.primary,
                size: 20,
              ),
              const SizedBox(width: 9),
              const Text(
                'CUSTOMER:',
                style: TextStyle(
                  color: GacColors.gray,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    key: const ValueKey('customer-dropdown'),
                    value: activeCustomer.customerIndex,
                    isExpanded: compact,
                    dropdownColor: const Color(0xFF0F2642),
                    style: const TextStyle(
                      color: GacColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    items: _customers.map((cust) {
                      return DropdownMenuItem<int>(
                        value: cust.customerIndex,
                        child: Text(
                          'Customer ${cust.customerIndex}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (newIdx) {
                      if (newIdx != null && newIdx != _selectedCustomerIndex) {
                        setState(() {
                          _selectedCustomerIndex = newIdx;
                          final documentationItems = _template?.sections
                              .expand((section) => section.items)
                              .toList(growable: false) ?? [];
                          _stepQuestionIndex = (_readOnly && documentationItems.isNotEmpty)
                              ? documentationItems.length - 1
                              : 0;
                          _sectionIndex = 0;
                          _fieldRevision++;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          );

          final addButton = FilledButton.icon(
            key: const ValueKey('add-customer-button'),
            style: FilledButton.styleFrom(
              backgroundColor: GacColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              minimumSize: const Size(0, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const FittedBox(
              child: Text(
                'ADD CUSTOMER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            onPressed: !_saving ? _addDocumentationCustomer : null,
          );
          final isSubmittedCust = _isCustomerReadOnly(activeCustomer);
          final canDelete = !isSubmittedCust && _customers.length > 1 && !_saving;
          final deleteButton = IconButton.outlined(
            key: ValueKey('remove-customer-${activeCustomer.customerIndex}'),
            tooltip: 'Delete Customer ${activeCustomer.customerIndex}',
            onPressed: canDelete
                ? () => unawaited(_removeDocumentationCustomer(activeCustomer))
                : null,
            style: IconButton.styleFrom(
              minimumSize: const Size(42, 42),
              side: BorderSide(
                color: canDelete
                    ? const Color(0x66EF4444)
                    : GacColors.border.withValues(alpha: 0.3),
              ),
            ),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: canDelete ? Colors.redAccent : GacColors.textMuted,
              size: 20,
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                customerPicker,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: addButton),
                    const SizedBox(width: 8),
                    deleteButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: customerPicker),
              const SizedBox(width: 10),
              addButton,
              const SizedBox(width: 8),
              deleteButton,
            ],
          );
        },
      ),
    );
  }

  void _addDocumentationCustomer() {
    final nextIndex = _customers.isEmpty
        ? 1
        : _customers
                  .map((customer) => customer.customerIndex)
                  .reduce(math.max) +
              1;
    setState(() {
      _customers.add(CustomerAuditSample(customerIndex: nextIndex));
      _selectedCustomerIndex = nextIndex;
      _stepQuestionIndex = 0;
      _sectionIndex = 0;
      _isDirty = true;
      _fieldRevision++;
    });
  }

  Future<void> _removeDocumentationCustomer(
    CustomerAuditSample customer,
  ) async {
    if (_isCustomerReadOnly(customer) || _saving || _customers.length <= 1) return;
    final removedPosition = _customers.indexWhere(
      (entry) => entry.customerIndex == customer.customerIndex,
    );
    if (removedPosition < 0) return;

    setState(() {
      _customers.removeAt(removedPosition);
      final nextPosition = removedPosition.clamp(0, _customers.length - 1);
      _selectedCustomerIndex = _customers[nextPosition].customerIndex;
      _stepQuestionIndex = 0;
      _sectionIndex = 0;
      _isDirty = true;
      _fieldRevision++;
    });

    // Persist the removal immediately so a refresh cannot restore the deleted
    // sample. The normal draft error UI handles a failed server save.
    await _autoSaveDraft(showPopup: false);
  }

  Widget _buildCustomerFieldsCard(CustomerAuditSample activeCustomer) {
    return GacContentPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MetaBadge(
                label: 'CUSTOMER ${activeCustomer.customerIndex}',
                primary: true,
              ),
              if (_isCustomerReadOnly(activeCustomer)) ...[
                const SizedBox(width: 8),
                const _MetaBadge(
                  label: 'SUBMITTED',
                  primary: false,
                ),
              ] else if (_hasNewDocumentationCustomer) ...[
                const SizedBox(width: 8),
                const _MetaBadge(
                  label: 'NEW SAMPLE',
                  primary: true,
                ),
              ],
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'REPAIR ORDER & JOB DETAILS',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: GacColors.gray,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: ValueKey('doc-ro-number-${activeCustomer.customerIndex}'),
            initialValue: activeCustomer.roNumber,
            enabled: !_isCustomerReadOnly(activeCustomer),
            style: const TextStyle(color: GacColors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Repair Order (R.O.) Number',
              hintText: 'e.g. RO-104928',
              labelStyle: const TextStyle(color: GacColors.gray, fontSize: 12),
              hintStyle: TextStyle(
                color: GacColors.gray.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              prefixIcon: const Icon(
                Icons.receipt_long_rounded,
                color: GacColors.primary,
                size: 18,
              ),
              filled: true,
              fillColor: const Color(0xFF0D2137),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GacColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GacColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GacColors.primary),
              ),
            ),
            onChanged: (val) {
              activeCustomer.roNumber = val;
              _isDirty = true;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('doc-mileage-${activeCustomer.customerIndex}'),
            initialValue: activeCustomer.mileage,
            enabled: !_isCustomerReadOnly(activeCustomer),
            style: const TextStyle(color: GacColors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Type of Job (mileage) - Exempt from No cascade',
              hintText: 'e.g. 5,000 km PMS / 10,000 km Maintenance',
              labelStyle: const TextStyle(color: GacColors.gray, fontSize: 12),
              hintStyle: TextStyle(
                color: GacColors.gray.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              prefixIcon: const Icon(
                Icons.speed_rounded,
                color: Color(0xFF06B6D4),
                size: 18,
              ),
              helperText: 'Typed-in value, exempt from turning NO on prerequisite failure',
              helperStyle: const TextStyle(color: GacColors.gray, fontSize: 10),
              filled: true,
              fillColor: const Color(0xFF0D2137),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GacColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GacColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GacColors.primary),
              ),
            ),
            onChanged: (val) {
              activeCustomer.mileage = val;
              _isDirty = true;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocQuestionCard({
    required ChecklistItemData item,
    required String? status,
    required ValueChanged<String?> onStatusSelected,
    bool enabled = true,
  }) {
    final itemNumber = item.metadata['number'] ?? item.id;
    return GacContentPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaBadge(label: '#$itemNumber', primary: true),
              if (item.coverage case final cov?) _MetaBadge(label: cov),
              const _MetaBadge(
                label: 'CHECKER: CE SERVICE',
                color: GacColors.green400,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.prompt,
            style: const TextStyle(
              color: GacColors.black,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ResponseChoiceButton(
                  key: ValueKey('doc-item-${item.key}-yes'),
                  label: 'YES',
                  icon: Icons.check_circle_rounded,
                  activeColor: const Color(0xFF16865B),
                  selected: status == 'yes',
                  enabled: enabled,
                  onTap: () => onStatusSelected('yes'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResponseChoiceButton(
                  key: ValueKey('doc-item-${item.key}-no'),
                  label: 'NO',
                  icon: Icons.cancel_rounded,
                  activeColor: const Color(0xFFD92D20),
                  selected: status == 'no',
                  enabled: enabled,
                  onTap: () => onStatusSelected('no'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResponseChoiceButton(
                  key: ValueKey('doc-item-${item.key}-na'),
                  label: 'N/A',
                  icon: Icons.block_rounded,
                  activeColor: const Color(0xFFD97706),
                  selected: status == 'na',
                  enabled: enabled,
                  onTap: () => onStatusSelected('na'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDocStatusSelected({
    required CustomerAuditSample customer,
    required ChecklistItemData item,
    required String? newStatus,
    required ChecklistTemplateData template,
  }) async {
    if (_isCustomerReadOnly(customer)) return;
    final currentStatus = customer.answers[item.key];
    if (newStatus == currentStatus) {
      if (currentStatus != null) {
        final confirmed = await _confirmUndoChoice(choiceLabel: currentStatus);
        if (!confirmed || !mounted) return;
        customer.answers.remove(item.key);
        _isDirty = true;
        _fieldRevision++;
        setState(() {});
      }
      return;
    }

    if (newStatus == 'no') {
      final confirmed = await _confirmPrerequisiteNoSelection(
        title: 'Prerequisite Warning',
        message:
            'Selecting "NO" will automatically set all prerequisite check items for Customer ${customer.customerIndex} to "NO".\n\n(Note: Type of Job mileage and R.O. number are exempt)\n\nAre you sure you want to proceed?',
      );
      if (!confirmed) return;

      for (final checkItem in template.sections.expand((s) => s.items)) {
        customer.answers[checkItem.key] = 'no';
      }
      _isDirty = true;
      _fieldRevision++;
      setState(() {});
      return;
    }

    final hasNoAnswer = customer.answers.values.any((v) => v.trim().toLowerCase() == 'no');
    if (hasNoAnswer && (newStatus == 'yes' || newStatus == 'na')) {
      final confirmed = await _confirmPrerequisiteNoSelection(
        title: 'Reset Customer Evaluation',
        message:
            'Customer ${customer.customerIndex} currently has questions set to "NO" under the prerequisite rule.\n\nSetting this question to "${newStatus!.toUpperCase()}" will reset all questions for Customer ${customer.customerIndex} so you can re-evaluate.\n\nAre you sure you want to proceed?',
      );
      if (!confirmed) return;

      for (final checkItem in template.sections.expand((s) => s.items)) {
        customer.answers[checkItem.key] = newStatus;
      }
      _isDirty = true;
      _fieldRevision++;
      setState(() {});
      return;
    }

    if (newStatus != null) {
      customer.answers[item.key] = newStatus;
    } else {
      customer.answers.remove(item.key);
    }
    _isDirty = true;
    setState(() {});
  }

  double _progress(ChecklistTemplateData template) {
    if (_isDocumentation) {
      if (_readOnly) return 100;
      if (_customers.isEmpty || template.itemCount == 0) return 0;
      final totalExpected = template.itemCount * _customers.length;
      var totalAnswered = 0;
      for (final cust in _customers) {
        totalAnswered += cust.answers.length;
      }
      return ((totalAnswered / totalExpected).clamp(0.0, 1.0)) * 100;
    }
    if (template.validationMode == 'time_slots') {
      var total = 0;
      var answered = 0;
      for (final section in template.sections) {
        for (final item in section.items) {
          final ans = _answers[item.key];
          for (final slot in template.timeSlots) {
            if (item.isSlotActive(slot.key)) {
              total++;
              final mark = ans?.slots[slot.key]?.trim().toLowerCase();
              if (mark != null && mark.isNotEmpty && mark != 'unanswered') {
                answered++;
              }
            }
          }
        }
      }
      return total == 0 ? 0 : (answered / total) * 100;
    }
    final answered = _answers.values
        .where((answer) => answer.status != null)
        .length;
    return template.itemCount == 0 ? 0 : (answered / template.itemCount) * 100;
  }
}

/// Matches the inset glass treatment of the shared floating checklist bar.
class _ChecklistDetailHeaderPanel extends StatelessWidget {
  const _ChecklistDetailHeaderPanel({
    required this.padding,
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: GacGlassSurface(
            width: double.infinity,
            padding: padding,
            borderRadius: 22,
            blurSigma: 5,
            shadowBlurRadius: 16,
            shadowOffset: const Offset(0, 4),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _UtilitiesQuestionByQuestionView extends StatelessWidget {
  const _UtilitiesQuestionByQuestionView({
    required this.template,
    required this.items,
    required this.questionIndex,
    required this.activeSlotKey,
    required this.answers,
    required this.readOnly,
    required this.saving,
    required this.isSlotLocked,
    required this.isSlotExpired,
    required this.onSlotSelected,
    required this.onQuestionChanged,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onSubmit,
    required this.onChanged,
    this.onShowHowToCheck,
  });

  final ChecklistTemplateData template;
  final List<ChecklistItemData> items;
  final int questionIndex;
  final String activeSlotKey;
  final Map<String, _ChecklistAnswer> answers;
  final bool readOnly;
  final bool saving;
  final bool Function(ChecklistTimeSlot) isSlotLocked;
  final bool Function(ChecklistTimeSlot) isSlotExpired;
  final ValueChanged<String> onSlotSelected;
  final ValueChanged<int> onQuestionChanged;
  final ValueChanged<String> onPickPhoto;
  final ValueChanged<String> onRemovePhoto;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;
  final void Function(ChecklistItemData item)? onShowHowToCheck;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No checklist questions available.',
          style: TextStyle(color: GacColors.white),
        ),
      );
    }

    final item = items[questionIndex];
    final answer = answers[item.key]!;
    final isSlotActive = item.isSlotActive(activeSlotKey);
    final isTurnedOff = !isSlotActive;
    final currentMark = answer.slots[activeSlotKey];
    final activeSlot = template.timeSlots.firstWhere(
      (s) => s.key == activeSlotKey,
      orElse: () => ChecklistTimeSlot(key: activeSlotKey, label: activeSlotKey),
    );
    final isCurrentSlotSubmitted =
        items.isNotEmpty &&
        items.every(
          (item) =>
              !item.isSlotActive(activeSlotKey) ||
              (answers[item.key]?.submittedSlots.contains(activeSlotKey) ??
                  false),
        );
    final isCurrentSlotLocked = isSlotLocked(activeSlot);
    final isCurrentSlotExpired = isSlotExpired(activeSlot);
    final hasChosenChoice = currentMark != null && currentMark.isNotEmpty;
    final isNaReasonRequired = currentMark == 'na';
    final hasNaReason = answer.remark.trim().isNotEmpty;
    final isNotGoodRemarkRequired = currentMark == 'not_good';
    final hasNotGoodRemark = answer.remark.trim().isNotEmpty;
    final canProceed =
        readOnly ||
        isTurnedOff ||
        isCurrentSlotLocked ||
        isCurrentSlotSubmitted ||
        (hasChosenChoice &&
            (!isNaReasonRequired || hasNaReason) &&
            (!isNotGoodRemarkRequired || hasNotGoodRemark));

    final activeItemsInSlot =
        items.where((i) => i.isSlotActive(activeSlotKey)).toList();
    final answeredInSlot = activeItemsInSlot.where((i) {
      final mark = answers[i.key]?.slots[activeSlotKey]?.trim().toLowerCase();
      return mark != null && mark.isNotEmpty && mark != 'unanswered';
    }).length;

    return Column(
      children: [
        _ChecklistDetailHeaderPanel(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'INSPECTION TIME: ${activeSlot.label.toUpperCase()}  ·  $answeredInSlot OF ${activeItemsInSlot.length} ANSWERED',
                          style: const TextStyle(
                            color: GacColors.gray,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'QUESTION ${questionIndex + 1} / ${items.length}',
                        style: const TextStyle(
                          color: GacColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (!readOnly && !isCurrentSlotSubmitted) ...[
                        const SizedBox(width: 10),
                        FilledButton(
                          key: const ValueKey('checklist-header-submit-button'),
                          onPressed: saving ? null : onSubmit,
                          style: FilledButton.styleFrom(
                            backgroundColor: GacColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            minimumSize: const Size(72, 34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: saving
                              ? const SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: GacColors.white,
                                  ),
                                )
                              : const Text(
                                  'SUBMIT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                        ),
                      ] else if (isCurrentSlotSubmitted) ...[
                        const SizedBox(width: 10),
                        const _SubmittedPill(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (final slot in template.timeSlots) ...[
                          _SlotPill(
                            slot: slot,
                            isSelected: slot.key == activeSlotKey,
                            isAnswered: () {
                              final activeInSlot = items
                                  .where((i) => i.isSlotActive(slot.key))
                                  .toList();
                              if (activeInSlot.isEmpty) return true;
                              return activeInSlot.every((i) {
                                final mark = answers[i.key]?.slots[slot.key]
                                    ?.trim()
                                    .toLowerCase();
                                return mark != null &&
                                    mark.isNotEmpty &&
                                    mark != 'unanswered';
                              });
                            }(),
                            hasDefect: items
                                .where((i) => i.isSlotActive(slot.key))
                                .any(
                                  (i) =>
                                      answers[i.key]?.slots[slot.key] ==
                                      'not_good',
                                ),
                            isLocked: isSlotLocked(slot),
                            onTap: () => onSlotSelected(slot.key),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            primary: true,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              18,
              16,
              18,
              24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GacContentPanel(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      shadowBlurRadius: 18,
                      shadowOffset: const Offset(0, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _MetaBadge(
                                      label:
                                          'QUESTION #${item.displayNumber ?? (questionIndex + 1)}',
                                      primary: true,
                                    ),
                                    if (item.subject case final subject?)
                                      _MetaBadge(label: subject),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isTurnedOff
                                      ? const Color(0x2664748B)
                                      : (currentMark == 'good'
                                          ? const Color(0x261B8A5A)
                                          : (currentMark == 'not_good'
                                                ? const Color(0x26D92D20)
                                                : (currentMark == 'na'
                                                      ? const Color(0x26D97706)
                                                      : Colors.white10))),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isTurnedOff
                                        ? const Color(0xFF64748B)
                                        : (currentMark == 'good'
                                            ? const Color(0xFF1B8A5A)
                                            : (currentMark == 'not_good'
                                                  ? const Color(0xFFD92D20)
                                                  : (currentMark == 'na'
                                                        ? const Color(0xFFD97706)
                                                        : Colors.white24))),
                                  ),
                                ),
                                child: Text(
                                  isTurnedOff
                                      ? 'TURNED OFF'
                                      : (currentMark == 'good'
                                          ? 'MARKED YES'
                                          : (currentMark == 'not_good'
                                                ? 'MARKED NO'
                                                : (currentMark == 'na'
                                                      ? 'MARKED N/A'
                                                      : 'UNANSWERED'))),
                                  style: TextStyle(
                                    color: isTurnedOff
                                        ? const Color(0xFF94A3B8)
                                        : (currentMark == 'good'
                                            ? const Color(0xFF1B8A5A)
                                            : (currentMark == 'not_good'
                                                  ? const Color(0xFFD92D20)
                                                  : (currentMark == 'na'
                                                        ? const Color(0xFFD97706)
                                                        : GacColors.gray))),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ),
                              if (onShowHowToCheck != null) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'How to check',
                                  child: InkWell(
                                    key: ValueKey('${item.key}-how-to-check'),
                                    onTap: () => onShowHowToCheck!(item),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0x262979FF),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0x662979FF),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.info_outline_rounded,
                                          color: GacColors.primary,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.prompt,
                            style: const TextStyle(
                              color: GacColors.black,
                              fontSize: 16,
                              height: 1.45,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (item.description case final desc?)
                            if (desc.isNotEmpty && desc != item.prompt) ...[
                              const SizedBox(height: 6),
                              Text(
                                desc,
                                style: const TextStyle(
                                  color: GacColors.gray,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          if (isTurnedOff) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0x1A64748B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0x4064748B),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.power_settings_new_rounded,
                                    size: 20,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TURNED OFF FOR ${activeSlot.label.toUpperCase()}',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: .5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'This question has been turned off by the administrator for this inspection hour and does not require an answer.',
                                          style: TextStyle(
                                            color: GacColors.black,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ] else if (isCurrentSlotSubmitted) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0x1A12B76A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0x5912B76A),
                                ),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 20,
                                    color: Color(0xFF12B76A),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ALREADY SUBMITTED',
                                          style: TextStyle(
                                            color: Color(0xFF12B76A),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: .5,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'This hourly inspection has already been submitted and can no longer be changed.',
                                          style: TextStyle(
                                            color: GacColors.black,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ] else if (isCurrentSlotLocked) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0x1AF59E0B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0x40F59E0B),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.lock_clock_rounded,
                                    size: 20,
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isCurrentSlotExpired
                                              ? 'TIME WINDOW CLOSED FOR ${activeSlot.label.toUpperCase()}'
                                              : 'LOCKED UNTIL ${activeSlot.label.toUpperCase()}',
                                          style: const TextStyle(
                                            color: Color(0xFFD97706),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: .5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isCurrentSlotExpired
                                              ? 'This hourly inspection has expired. It was only editable during ${_slotWindowLabel(context, activeSlot)} and can no longer be recorded or changed.'
                                              : 'This inspection is not open yet. It will be editable only during ${_slotWindowLabel(context, activeSlot)}.',
                                          style: const TextStyle(
                                            color: GacColors.black,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ] else ...[
                            const SizedBox(height: 20),
                          ],
                          Text(
                            isTurnedOff
                                ? 'QUESTION IS TURNED OFF FOR ${activeSlot.label.toUpperCase()}'
                                : isCurrentSlotSubmitted
                                ? 'INSPECTION FOR ${activeSlot.label.toUpperCase()} IS ALREADY SUBMITTED'
                                : isCurrentSlotLocked
                                ? 'INSPECTION FOR ${activeSlot.label.toUpperCase()} IS LOCKED'
                                : 'SELECT CONDITION FOR ${activeSlot.label.toUpperCase()}:',
                            style: const TextStyle(
                              color: GacColors.gray,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _BigActionButton(
                                  label: 'YES',
                                  icon: Icons.check_circle_rounded,
                                  activeColor: const Color(0xFF1B8A5A),
                                  selected: currentMark == 'good',
                                  enabled:
                                      !readOnly &&
                                      !isTurnedOff &&
                                      !isCurrentSlotLocked &&
                                      !isCurrentSlotSubmitted,
                                  onTap: () async {
                                    if (currentMark == 'good') {
                                      final confirmed =
                                          await _showUndoChoiceConfirmationDialog(
                                        context,
                                        choiceLabel: 'YES',
                                      );
                                      if (!confirmed) return;
                                      answer.slots.remove(activeSlotKey);
                                      onChanged();
                                      return;
                                    }
                                    answer.slots[activeSlotKey] = 'good';
                                    onChanged();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _BigActionButton(
                                  label: 'NO',
                                  icon: Icons.cancel_rounded,
                                  activeColor: const Color(0xFFD92D20),
                                  selected: currentMark == 'not_good',
                                  enabled:
                                      !readOnly &&
                                      !isTurnedOff &&
                                      !isCurrentSlotLocked &&
                                      !isCurrentSlotSubmitted,
                                  onTap: () async {
                                    if (currentMark == 'not_good') {
                                      final confirmed =
                                          await _showUndoChoiceConfirmationDialog(
                                        context,
                                        choiceLabel: 'NO',
                                      );
                                      if (!confirmed) return;
                                      answer.slots.remove(activeSlotKey);
                                      onChanged();
                                      return;
                                    }
                                    answer.slots[activeSlotKey] = 'not_good';
                                    onChanged();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _BigActionButton(
                                  label: 'N/A',
                                  icon: Icons.block_rounded,
                                  activeColor: const Color(0xFFD97706),
                                  selected: currentMark == 'na',
                                  enabled:
                                      !readOnly &&
                                      !isTurnedOff &&
                                      !isCurrentSlotLocked &&
                                      !isCurrentSlotSubmitted,
                                  onTap: () async {
                                    if (currentMark == 'na') {
                                      final confirmed =
                                          await _showUndoChoiceConfirmationDialog(
                                        context,
                                        choiceLabel: 'N/A',
                                      );
                                      if (!confirmed) return;
                                      answer.slots.remove(activeSlotKey);
                                      onChanged();
                                      return;
                                    }
                                    answer.slots[activeSlotKey] = 'na';
                                    onChanged();
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (!isTurnedOff &&
                              !isCurrentSlotLocked &&
                              !isCurrentSlotSubmitted &&
                              (currentMark == 'not_good' ||
                                  currentMark == 'na')) ...[
                            const SizedBox(height: 18),
                            _RemarksAndPhotoCard(
                              answer: answer,
                              readOnly: readOnly,
                              title: currentMark == 'na'
                                  ? 'REASON FOR N/A (REQUIRED) & PHOTO (OPTIONAL)'
                                  : 'REMARKS & DEFECT DETAILS',
                              hintText: currentMark == 'na'
                                  ? 'Enter reason why this item is not applicable (required)...'
                                  : 'Describe the issue (e.g. leaking sink, no hand soap, broken latch)...',
                              accentColor: currentMark == 'na'
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFFD92D20),
                              onPickPhoto: () => onPickPhoto(item.key),
                              onRemovePhoto: () => onRemovePhoto(item.key),
                              onChanged: onChanged,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              foregroundColor: GacColors.white,
                              side: const BorderSide(color: GacColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: questionIndex > 0
                                ? () => onQuestionChanged(questionIndex - 1)
                                : null,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'PREVIOUS',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: GacColors.primary,
                              disabledBackgroundColor: const Color(0xFF153A56),
                              disabledForegroundColor: GacColors.textMuted,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: saving
                                ? null
                                : questionIndex < items.length - 1
                                ? (canProceed
                                    ? () => onQuestionChanged(questionIndex + 1)
                                    : null)
                                : (readOnly || isCurrentSlotSubmitted || isCurrentSlotLocked)
                                ? null
                                : (canProceed ? onSubmit : null),
                            icon: Icon(
                              questionIndex < items.length - 1
                                  ? Icons.arrow_forward_rounded
                                  : Icons.task_alt_rounded,
                              size: 18,
                            ),
                            label: Text(
                              questionIndex < items.length - 1
                                  ? 'NEXT'
                                  : 'SUBMIT CHECKLIST',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            _QuestionJumperDot(
                              number: i + 1,
                              isCurrent: i == questionIndex,
                              isTurnedOff:
                                  !items[i].isSlotActive(activeSlotKey),
                              status:
                                  answers[items[i].key]?.slots[activeSlotKey],
                              onTap: () => onQuestionChanged(i),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BigActionButton extends StatelessWidget {
  const _BigActionButton({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color activeColor;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? activeColor : const Color(0xFF0D2137),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? activeColor : GacColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? GacColors.white : GacColors.gray,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? GacColors.white : GacColors.gray,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RemarksAndPhotoCard extends StatefulWidget {
  const _RemarksAndPhotoCard({
    required this.answer,
    required this.readOnly,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onChanged,
    this.title = 'REMARKS & DEFECT DETAILS',
    this.hintText =
        'Describe the issue (e.g. leaking sink, no hand soap, broken latch)...',
    this.accentColor = const Color(0xFFD92D20),
  });

  final _ChecklistAnswer answer;
  final bool readOnly;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onChanged;
  final String title;
  final String hintText;
  final Color accentColor;

  @override
  State<_RemarksAndPhotoCard> createState() => _RemarksAndPhotoCardState();
}

class _RemarksAndPhotoCardState extends State<_RemarksAndPhotoCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.answer.remark);
  }

  @override
  void didUpdateWidget(covariant _RemarksAndPhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answer != widget.answer ||
        _controller.text != widget.answer.remark) {
      _controller.text = widget.answer.remark;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final answer = widget.answer;
    final hasPhoto =
        answer.localAttachmentBytes != null ||
        (answer.attachmentUrl != null && answer.attachmentUrl!.isNotEmpty);
    final accent = widget.accentColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            enabled: !widget.readOnly,
            maxLines: 3,
            style: const TextStyle(
              color: GacColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                color: GacColors.textMuted,
                fontSize: 12,
              ),
              filled: true,
              fillColor: GacColors.offWhite,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: GacColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: GacColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: GacColors.cyan, width: 1.5),
              ),
            ),
            onChanged: (text) {
              answer.remark = text;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 12),
          if (hasPhoto) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                    child: answer.localAttachmentBytes != null
                        ? Image.memory(
                            Uint8List.fromList(answer.localAttachmentBytes!),
                            height: 160,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            resolveGacAssetUrl(answer.attachmentUrl)!,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 100,
                              color: Colors.black12,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: GacColors.gray,
                              ),
                            ),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF1B8A5A),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            answer.localAttachmentName ?? 'Photo attached',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: GacColors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!widget.readOnly) ...[
                          TextButton(
                            onPressed: widget.onPickPhoto,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text(
                              'Change',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onRemovePhoto,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text(
                              'Remove',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: widget.readOnly ? null : widget.onPickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text(
                'ATTACH PHOTO (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShowAllPill extends StatelessWidget {
  const _ShowAllPill({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? GacColors.primary : const Color(0xFF0D2137),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? GacColors.primary : GacColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 12,
                color: isSelected ? GacColors.white : GacColors.gray,
              ),
              const SizedBox(width: 4),
              Text(
                'SHOW ALL',
                style: TextStyle(
                  color: GacColors.white,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                  letterSpacing: .3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotPill extends StatelessWidget {
  const _SlotPill({
    required this.slot,
    required this.isSelected,
    required this.isAnswered,
    required this.hasDefect,
    required this.isLocked,
    required this.onTap,
  });

  final ChecklistTimeSlot slot;
  final bool isSelected;
  final bool isAnswered;
  final bool hasDefect;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isLocked
        ? (isSelected ? const Color(0xFF1E293B) : const Color(0x330F172A))
        : (isSelected
              ? GacColors.primary
              : (hasDefect
                    ? const Color(0x33D92D20)
                    : (isAnswered
                          ? const Color(0x331B8A5A)
                          : const Color(0xFF0D2137))));
    final borderColor = isLocked
        ? (isSelected ? const Color(0xFF64748B) : const Color(0x2664748B))
        : (isSelected
              ? GacColors.primary
              : (hasDefect
                    ? const Color(0xFFD92D20)
                    : (isAnswered
                          ? const Color(0xFF1B8A5A)
                          : GacColors.border)));

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLocked) ...[
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
              ] else if (hasDefect) ...[
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 12,
                  color: Color(0xFFFF6B6B),
                ),
                const SizedBox(width: 4),
              ] else if (isAnswered) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: Color(0xFF4EBA86),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                slot.label,
                style: TextStyle(
                  color: isLocked
                      ? const Color(0xFF64748B)
                      : (isSelected
                            ? GacColors.white
                            : (hasDefect
                                  ? const Color(0xFFFF8B8B)
                                  : (isAnswered
                                        ? const Color(0xFF4EBA86)
                                        : GacColors.white))),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                  letterSpacing: .3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionJumperDot extends StatelessWidget {
  const _QuestionJumperDot({
    required this.number,
    required this.isCurrent,
    this.isTurnedOff = false,
    required this.status,
    required this.onTap,
  });

  final int number;
  final bool isCurrent;
  final bool isTurnedOff;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFF0D2137);
    Color border = GacColors.border;
    Color text = GacColors.gray;

    if (isTurnedOff) {
      bg = const Color(0x1A64748B);
      border = const Color(0x3364748B);
      text = const Color(0xFF64748B);
    } else if (status == 'good') {
      bg = const Color(0x331B8A5A);
      border = const Color(0xFF1B8A5A);
      text = const Color(0xFF4EBA86);
    } else if (status == 'not_good') {
      bg = const Color(0x33D92D20);
      border = const Color(0xFFD92D20);
      text = const Color(0xFFFF6B6B);
    } else if (status == 'na') {
      bg = const Color(0x33D97706);
      border = const Color(0xFFD97706);
      text = const Color(0xFFFBBF24);
    }

    if (isCurrent) {
      border = GacColors.white;
      text = GacColors.white;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: border, width: isCurrent ? 2 : 1),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

bool _isSubformReferenceItem(
  ChecklistItemData item,
  ChecklistTemplateData template,
) {
  // Inline subforms belong only to the Aftersales main form. Sales uses the
  // same row numbers (including 23, 27, and 53-55) for ordinary standards.
  if (template.slug != 'dealer-operations-standards') return false;

  final prompt = item.prompt.toLowerCase();
  final howToCheck = (item.howToCheck ?? '').toLowerCase();
  final subject = (item.subject ?? '').toLowerCase();
  final number = item.metadata['number'] ?? item.id;

  if (prompt.contains('see sheet: "subform"') ||
      prompt.contains('see sheet: subform') ||
      prompt.contains('subform')) {
    return true;
  }
  if (howToCheck.contains('subform')) {
    return true;
  }
  if (number == 23 ||
      number == 27 ||
      number == 53 ||
      number == 54 ||
      number == 55) {
    return true;
  }
  if (subject.contains('service reception area') ||
      subject.contains('customers\' lounge') ||
      subject.contains('customers lounge') ||
      subject.contains('employee facilities') ||
      subject.contains('meeting room') ||
      subject.contains('mitsubishi quick service')) {
    return true;
  }
  return false;
}

ChecklistSection? _getSubformSection(ChecklistItemData item) {
  final subject = (item.subject ?? '').toLowerCase();
  final number = item.metadata['number'] ?? item.id;

  if (number == 23 || subject.contains('service reception')) {
    return dosSubformTemplate.firstWhere(
      (s) => s.id == 'subform-service-reception',
      orElse: () => dosSubformTemplate.first,
    );
  } else if (number == 27 || subject.contains('lounge')) {
    return dosSubformTemplate.firstWhere(
      (s) => s.id == 'subform-customers-lounge',
      orElse: () => dosSubformTemplate.last,
    );
  } else if (number == 53 ||
      subject.contains('quick service') ||
      subject.contains('mqs')) {
    return dosSubformTemplate.firstWhere(
      (s) => s.id == 'subform-mitsubishi-quick-service',
      orElse: () => dosSubformTemplate[3],
    );
  } else if (number == 54 || subject.contains('employee facilities')) {
    return dosSubformTemplate.firstWhere(
      (s) => s.id == 'subform-employee-facilities',
      orElse: () => dosSubformTemplate[1],
    );
  } else if (number == 55 || subject.contains('meeting room')) {
    return dosSubformTemplate.firstWhere(
      (s) => s.id == 'subform-meeting-room',
      orElse: () => dosSubformTemplate[2],
    );
  }
  return null;
}

String? _deriveSubformOverallStatus(
  ChecklistSection subformSection,
  Map<String, String> subformAnswers,
) {
  if (subformAnswers.isEmpty) return null;
  final anyNo = subformSection.items.any(
    (item) => subformAnswers[item.id] == 'no',
  );
  if (anyNo) return 'no';

  final allAnswered = subformSection.items.every(
    (item) =>
        subformAnswers.containsKey(item.id) &&
        subformAnswers[item.id] != null &&
        subformAnswers[item.id]!.isNotEmpty,
  );
  if (!allAnswered) {
    return null;
  }

  final allNa = subformSection.items.every(
    (item) => subformAnswers[item.id] == 'na',
  );
  if (allNa) return 'na';

  return 'yes';
}

String _dosCheckerLabel(String? checker, {String fallback = ''}) {
  final raw = checker?.trim() ?? '';
  if (raw.isEmpty) return fallback;
  return canonicalDosChecker(raw) == 'WS SUP' ? 'WS SUP' : raw;
}

class _ChecklistQuestionCard extends StatelessWidget {
  const _ChecklistQuestionCard({
    required this.item,
    required this.answer,
    required this.template,
    required this.readOnly,
    this.attentionOnly = false,
    this.showDosEscalationAndCommitment = false,
    this.showDosBomTask = false,
    this.showDosActionPlan = false,
    this.prominent = false,
    this.isSlotLocked,
    this.visibleSlots,
    required this.onChanged,
    required this.onPickCommitmentDate,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    this.onShowHowToCheck,
    this.onSelectStatus,
    super.key,
  });

  final ChecklistItemData item;
  final _ChecklistAnswer answer;
  final ChecklistTemplateData template;
  final bool readOnly;
  final bool attentionOnly;
  final bool showDosEscalationAndCommitment;
  final bool showDosBomTask;
  final bool showDosActionPlan;
  final bool prominent;
  final bool Function(ChecklistTimeSlot)? isSlotLocked;
  final List<ChecklistTimeSlot>? visibleSlots;
  final VoidCallback onChanged;
  final VoidCallback onPickCommitmentDate;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback? onShowHowToCheck;
  final ValueChanged<String?>? onSelectStatus;

  @override
  Widget build(BuildContext context) {
    final isDos = template.validationMode == 'dos';
    final isRestroom = template.validationMode == 'time_slots';
    final isSubform = template.validationMode == 'dos_subform';
    final isSubformRef =
        isDos && !isSubform && _isSubformReferenceItem(item, template);
    final subformSection = isSubformRef ? _getSubformSection(item) : null;
    final checkerLabel = _dosCheckerLabel(
      item.checker,
      fallback: 'Sales Manager',
    );

    Color? categoryColor;
    if (item.category != null) {
      final norm = item.category!.toLowerCase();
      if (norm.contains('basic')) {
        categoryColor = const Color(0xFF06B6D4);
      } else if (norm.contains('beyond')) {
        categoryColor = const Color(0xFFF59E0B);
      } else if (norm.contains('standard')) {
        categoryColor = const Color(0xFF8B5CF6);
      }
    }

    return GacContentPanel(
      padding: EdgeInsets.all(prominent ? 20 : 17),
      borderRadius: 20,
      shadowBlurRadius: 18,
      shadowOffset: const Offset(0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (item.displayNumber case final number?)
                      _MetaBadge(label: '#$number', primary: true),
                    if (item.level case final level?)
                      _MetaBadge(
                        label: level.toUpperCase(),
                        color: categoryColor,
                      ),
                    if (item.coverage case final coverage?)
                      _MetaBadge(label: coverage),
                    if (item.subject case final subject?)
                      _MetaBadge(label: subject),
                    if (isDos &&
                        item.checker != null &&
                        item.checker!.isNotEmpty)
                      _MetaBadge(
                        label: 'CHECKER: $checkerLabel',
                        color: GacColors.green400,
                      ),
                  ],
                ),
              ),
              if (onShowHowToCheck != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  key: ValueKey('${item.key}-how-to-check'),
                  onTap: onShowHowToCheck,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0x262979FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x662979FF)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: GacColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSubformRef && item.prompt.toLowerCase().contains('see sheet')
                ? '${item.subject ?? subformSection?.title ?? 'Subform Standard'} (See sheet: "Subform")'
                : item.prompt,
            style: TextStyle(
              color: GacColors.black,
              fontSize: prominent ? 16 : 13,
              height: prominent ? 1.5 : 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (item.pic != null || isDos) ...[
            const SizedBox(height: 8),
            Text(
              isDos
                  ? 'Checker: $checkerLabel${!showDosEscalationAndCommitment || item.escalation == null ? '' : '  ·  Escalate: ${item.escalation}'}'
                  : 'PIC: ${item.pic}${item.escalation == null ? '' : '  ·  Escalate: ${item.escalation}'}',
              style: const TextStyle(
                color: GacColors.gray,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (isRestroom) ...[
            _TimeSlotAnswers(
              slots: visibleSlots ?? template.timeSlots,
              answer: answer,
              readOnly: readOnly,
              isSlotLocked: isSlotLocked,
              isSlotTurnedOff: (slot) => !item.isSlotActive(slot.key),
              onChanged: onChanged,
            ),
            Builder(
              builder: (context) {
                final currentSlotMark =
                    (visibleSlots != null && visibleSlots!.length == 1)
                    ? answer.slots[visibleSlots!.first.key]
                    : null;
                final shouldShowRemarks =
                    visibleSlots != null && visibleSlots!.length == 1
                    ? (currentSlotMark == 'not_good' ||
                          currentSlotMark == 'na' ||
                          answer.attachmentPath != null ||
                          answer.localAttachmentBytes != null)
                    : (answer.slots.values.any(
                            (m) => m == 'not_good' || m == 'na',
                          ) ||
                          answer.attachmentPath != null ||
                          answer.localAttachmentBytes != null);
                final isNaOnly =
                    visibleSlots != null && visibleSlots!.length == 1
                    ? (currentSlotMark == 'na')
                    : (answer.slots.values.any((m) => m == 'na') &&
                          !answer.slots.values.any((m) => m == 'not_good'));

                if (!shouldShowRemarks) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _RemarksAndPhotoCard(
                    answer: answer,
                    readOnly: readOnly,
                    title: isNaOnly
                        ? 'REASON FOR N/A (REQUIRED) & PHOTO (OPTIONAL)'
                        : 'REMARKS & DEFECT DETAILS',
                    hintText: isNaOnly
                        ? 'Enter reason why this item is not applicable (required)...'
                        : 'Describe the issue (e.g. leaking sink, no hand soap, broken latch)...',
                    accentColor: isNaOnly
                        ? const Color(0xFFD97706)
                        : const Color(0xFFD92D20),
                    onPickPhoto: onPickPhoto,
                    onRemovePhoto: onRemovePhoto,
                    onChanged: onChanged,
                  ),
                );
              },
            ),
          ] else ...[
            if (isSubformRef && subformSection != null) ...[
              _SubformEligibilitySelector(
                eligibility: answer.eligibility,
                enabled: !readOnly,
                onChanged: (newEligibility) async {
                  if (answer.eligibility == newEligibility) {
                    final confirmed = await _showUndoChoiceConfirmationDialog(
                      context,
                      choiceLabel:
                          newEligibility == 'na' ? 'N/A' : 'SHOW SUBFORM',
                    );
                    if (!confirmed) return;
                    answer.eligibility = null;
                    answer.status = null;
                    onChanged();
                    return;
                  }
                  answer.eligibility = newEligibility;
                  if (newEligibility == 'na') {
                    answer.status = 'na';
                  } else if (newEligibility == 'show_subform') {
                    answer.status = _deriveSubformOverallStatus(
                      subformSection,
                      answer.subformAnswers,
                    );
                  } else {
                    answer.status = null;
                  }
                  onChanged();
                },
              ),
              if (answer.eligibility == 'show_subform') ...[
                const SizedBox(height: 14),
                _SubformQuestionDropboxView(
                  item: item,
                  subformSection: subformSection,
                  answer: answer,
                  readOnly: readOnly,
                  attentionOnly: attentionOnly,
                  onChanged: () {
                    answer.status = _deriveSubformOverallStatus(
                      subformSection,
                      answer.subformAnswers,
                    );
                    onChanged();
                  },
                ),
              ],
            ] else ...[
              _ResponseButtons(
                itemKey: item.key,
                value: answer.status,
                enabled: !readOnly,
                onChanged: (value) async {
                  if (onSelectStatus != null) {
                    onSelectStatus!(value);
                  } else {
                    if (answer.status == value) {
                      final confirmed = await _showUndoChoiceConfirmationDialog(
                        context,
                        choiceLabel: value,
                      );
                      if (!confirmed) return;
                      answer.status = null;
                      onChanged();
                      return;
                    }
                    answer.status = value;
                    onChanged();
                  }
                },
              ),
            ],
            if (!isDos && (answer.status == 'no' || answer.status == 'na')) ...[
              const SizedBox(height: 14),
              _RemarksAndPhotoCard(
                answer: answer,
                title: answer.status == 'na'
                    ? 'REASON FOR N/A (REQUIRED) & PHOTO (OPTIONAL)'
                    : 'REMARKS (REQUIRED) & PHOTO (OPTIONAL)',
                hintText: answer.status == 'na'
                    ? 'Enter reason why this item is not applicable (required)...'
                    : 'Enter remarks and defect details for NO (required)...',
                accentColor: answer.status == 'na'
                    ? const Color(0xFFD97706)
                    : const Color(0xFFD92D20),
                readOnly: readOnly,
                onPickPhoto: onPickPhoto,
                onRemovePhoto: onRemovePhoto,
                onChanged: onChanged,
              ),
            ],
            if (isDos && (answer.status == 'no' || answer.status == 'na')) ...[
              const SizedBox(height: 13),
              _AnswerField(
                key: const ValueKey('dos-finding-field'),
                label: answer.status == 'na'
                    ? 'Reason for N/A (required)'
                    : 'Remarks (required)',
                initialValue: answer.finding,
                enabled: !readOnly,
                onChanged: (value) {
                  answer.finding = value;
                  onChanged();
                },
              ),
              const SizedBox(height: 10),
              _DosPhotoAttachmentRow(
                answer: answer,
                readOnly: readOnly,
                onPickPhoto: onPickPhoto,
                onRemovePhoto: onRemovePhoto,
              ),
            ],
            if (isDos && answer.status == 'no') ...[
              if (showDosBomTask &&
                  item.bomTask != null &&
                  item.bomTask!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _BomTaskGuideCard(bomTask: item.bomTask!),
              ],
              if (showDosEscalationAndCommitment) ...[
                const SizedBox(height: 12),
                _EscalationSelector(
                  selected: _resolvedDosEscalation(
                    answer.escalationTarget ?? item.escalation,
                  ),
                  enabled: !readOnly,
                  onChanged: (val) {
                    answer.escalationTarget = val;
                    onChanged();
                  },
                ),
              ],
              if (showDosActionPlan) ...[
                const SizedBox(height: 12),
                _AnswerField(
                  key: const ValueKey('dos-action-plan-field'),
                  label: 'Action plan (required)',
                  initialValue: answer.actionPlan,
                  enabled: !readOnly,
                  onChanged: (value) {
                    answer.actionPlan = value;
                    onChanged();
                  },
                ),
              ],
              if (showDosEscalationAndCommitment) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const ValueKey('dos-commitment-date-time'),
                  onPressed: readOnly ? null : onPickCommitmentDate,
                  icon: const Icon(Icons.event_outlined, size: 17),
                  label: Text(
                    answer.commitmentDate == null
                        ? 'Choose commitment date & time'
                        : 'Commitment: ${answer.commitmentDate}',
                  ),
                ),
                if (!_hasCommitmentDateAndTime(answer.commitmentDate)) ...[
                  const SizedBox(height: 5),
                  const Text(
                    'Commitment date and time are required.',
                    style: TextStyle(
                      color: Color(0xFFD92D20),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _BomTaskGuideCard extends StatelessWidget {
  const _BomTaskGuideCard({required this.bomTask});

  final String bomTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.assignment_late_outlined,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'BOM TASKS (MEASURES IF NOT CONDUCTED)',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bomTask,
            style: const TextStyle(
              color: GacColors.textSecondary,
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EscalationSelector extends StatelessWidget {
  const _EscalationSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final String? selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  static const List<Map<String, String>> options = [
    {
      'code': 'GM',
      'value': 'general_manager',
      'label': 'General Manager',
      'sub': 'Person',
    },
    {
      'code': 'PURCHASING',
      'value': 'purchasing',
      'label': 'Purchasing',
      'sub': 'Team',
    },
    {
      'code': 'PM',
      'value': 'property_management',
      'label': 'PM (Property Management)',
      'sub': 'Team',
    },
    {
      'code': 'INVENTORY',
      'value': 'inventory',
      'label': 'Inventory',
      'sub': 'Team',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ESCALATION (RESPONSIBLE RECIPIENT)',
          style: TextStyle(
            color: GacColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final opt in options) ...[
              Builder(
                builder: (context) {
                  final isSelected =
                      _normalizeDosEscalation(selected) == opt['value'];
                  return InkWell(
                    key: ValueKey(
                      'dos-escalation-${opt['code']!.toLowerCase()}',
                    ),
                    onTap: enabled ? () => onChanged(opt['value']!) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0x33EF4444)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF334155),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 13,
                            color: isSelected
                                ? const Color(0xFFEF4444)
                                : GacColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            opt['label']!,
                            style: TextStyle(
                              color: isSelected
                                  ? GacColors.textPrimary
                                  : GacColors.textSecondary,
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DosPhotoAttachmentRow extends StatelessWidget {
  const _DosPhotoAttachmentRow({
    required this.answer,
    required this.readOnly,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final _ChecklistAnswer answer;
  final bool readOnly;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        answer.attachmentPath != null ||
        answer.localAttachmentBytes != null ||
        (answer.attachmentUrl != null && answer.attachmentUrl!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Icon(
            hasPhoto ? Icons.photo_outlined : Icons.add_a_photo_outlined,
            size: 16,
            color: hasPhoto ? const Color(0xFF10B981) : GacColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasPhoto ? 'Defect photo attached' : 'Defect photo (optional)',
              style: TextStyle(
                color: hasPhoto ? const Color(0xFF10B981) : GacColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (hasPhoto && !readOnly) ...[
            TextButton(
              onPressed: onRemovePhoto,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'REMOVE',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ] else if (!readOnly) ...[
            OutlinedButton.icon(
              onPressed: onPickPhoto,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: const Size(60, 30),
                side: const BorderSide(color: Color(0xFF475569)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 14),
              label: const Text(
                'ADD PHOTO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeSlotAnswers extends StatelessWidget {
  const _TimeSlotAnswers({
    required this.slots,
    required this.answer,
    required this.readOnly,
    this.isSlotLocked,
    this.isSlotTurnedOff,
    required this.onChanged,
  });

  final List<ChecklistTimeSlot> slots;
  final _ChecklistAnswer answer;
  final bool readOnly;
  final bool Function(ChecklistTimeSlot)? isSlotLocked;
  final bool Function(ChecklistTimeSlot)? isSlotTurnedOff;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < slots.length; index++) ...[
          Builder(
            builder: (context) {
              final slot = slots[index];
              final isTurnedOff = isSlotTurnedOff?.call(slot) ?? false;
              final locked = isSlotLocked?.call(slot) ?? false;
              final isSlotSubmitted = answer.submittedSlots.contains(slot.key);
              return Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Row(
                      children: [
                        if (locked) ...[
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 11,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                        ],
                        Expanded(
                          child: Text(
                            slot.label,
                            style: TextStyle(
                              color: (isTurnedOff || locked)
                                  ? const Color(0xFF64748B)
                                  : GacColors.gray,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isTurnedOff) ...[
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x1A64748B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x3364748B)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '— TURNED OFF —',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: _SlotButton(
                        label: 'YES',
                        icon: Icons.check_circle_rounded,
                        activeColor: const Color(0xFF1B8A5A),
                        selected: answer.slots[slot.key] == 'good',
                        enabled: !readOnly && !locked && !isSlotSubmitted,
                        onTap: () async {
                          if (answer.slots[slot.key] == 'good') {
                            final confirmed =
                                await _showUndoChoiceConfirmationDialog(
                              context,
                              choiceLabel: 'YES',
                            );
                            if (!confirmed) return;
                            answer.slots.remove(slot.key);
                            onChanged();
                            return;
                          }
                          answer.slots[slot.key] = 'good';
                          onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _SlotButton(
                        label: 'NO',
                        icon: Icons.cancel_rounded,
                        activeColor: const Color(0xFFD92D20),
                        selected: answer.slots[slot.key] == 'not_good',
                        enabled: !readOnly && !locked && !isSlotSubmitted,
                        onTap: () async {
                          if (answer.slots[slot.key] == 'not_good') {
                            final confirmed =
                                await _showUndoChoiceConfirmationDialog(
                              context,
                              choiceLabel: 'NO',
                            );
                            if (!confirmed) return;
                            answer.slots.remove(slot.key);
                            onChanged();
                            return;
                          }
                          answer.slots[slot.key] = 'not_good';
                          onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _SlotButton(
                        label: 'N/A',
                        icon: Icons.block_rounded,
                        activeColor: const Color(0xFFD97706),
                        selected: answer.slots[slot.key] == 'na',
                        enabled: !readOnly && !locked && !isSlotSubmitted,
                        onTap: () async {
                          if (answer.slots[slot.key] == 'na') {
                            final confirmed =
                                await _showUndoChoiceConfirmationDialog(
                              context,
                              choiceLabel: 'N/A',
                            );
                            if (!confirmed) return;
                            answer.slots.remove(slot.key);
                            onChanged();
                            return;
                          }
                          answer.slots[slot.key] = 'na';
                          onChanged();
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          if (index != slots.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.activeColor,
    this.icon,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Color? activeColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = activeColor ?? GacColors.primary;
    return Material(
      color: selected ? effectiveColor : const Color(0xFF0D2137),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? effectiveColor
                  : (enabled ? GacColors.border : const Color(0x3364748B)),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: selected
                      ? GacColors.white
                      : (enabled ? GacColors.gray : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? GacColors.white
                      : (enabled ? GacColors.gray : const Color(0xFF64748B)),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponseButtons extends StatelessWidget {
  const _ResponseButtons({
    required this.itemKey,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String itemKey;
  final String? value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in const [
          ('yes', 'YES', Icons.check_circle_rounded, Color(0xFF16865B)),
          ('no', 'NO', Icons.cancel_rounded, Color(0xFFD92D20)),
          ('na', 'N/A', Icons.block_rounded, Color(0xFFD97706)),
        ]) ...[
          Expanded(
            child: _ResponseChoiceButton(
              key: ValueKey('$itemKey-response-${option.$1}'),
              label: option.$2,
              icon: option.$3,
              activeColor: option.$4,
              selected: value == option.$1,
              enabled: enabled,
              onTap: () => onChanged(option.$1),
            ),
          ),
          if (option.$1 != 'na') const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ResponseChoiceButton extends StatelessWidget {
  const _ResponseChoiceButton({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color activeColor;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? GacColors.white : GacColors.gray;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '$label response',
      child: Material(
        color: selected ? activeColor : const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? activeColor : GacColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: foreground, size: 22),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
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

class _SubformEligibilitySelector extends StatelessWidget {
  const _SubformEligibilitySelector({
    required this.eligibility,
    required this.enabled,
    required this.onChanged,
  });

  final String? eligibility;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0A2979FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: eligibility != null
              ? const Color(0x332979FF)
              : const Color(0x1F2979FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rule_rounded,
                size: 16,
                color: GacColors.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'ELIGIBILITY AUDIT',
                style: TextStyle(
                  color: GacColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (eligibility != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: eligibility == 'show_subform'
                        ? const Color(0x1F16865B)
                        : const Color(0x1FD97706),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    eligibility == 'show_subform'
                        ? 'SUBFORM ACTIVE'
                        : 'TAGGED N/A',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: eligibility == 'show_subform'
                          ? const Color(0xFF16865B)
                          : const Color(0xFFD97706),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Is this facility or service applicable for this audit? Choose "Show subform" to evaluate all requirements, or "N/A" if not applicable.',
            style: TextStyle(
              color: GacColors.gray,
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ResponseChoiceButton(
                  key: const ValueKey('subform-eligibility-show-subform'),
                  label: 'SHOW SUBFORM',
                  icon: Icons.checklist_rounded,
                  activeColor: GacColors.primary,
                  selected: eligibility == 'show_subform',
                  enabled: enabled,
                  onTap: () => onChanged('show_subform'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResponseChoiceButton(
                  key: const ValueKey('subform-eligibility-na'),
                  label: 'N/A',
                  icon: Icons.block_rounded,
                  activeColor: const Color(0xFFD97706),
                  selected: eligibility == 'na',
                  enabled: enabled,
                  onTap: () => onChanged('na'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubformQuestionDropboxView extends StatefulWidget {
  const _SubformQuestionDropboxView({
    required this.item,
    required this.subformSection,
    required this.answer,
    required this.readOnly,
    required this.onChanged,
    this.attentionOnly = false,
  });

  final ChecklistItemData item;
  final ChecklistSection subformSection;
  final _ChecklistAnswer answer;
  final bool readOnly;
  final VoidCallback onChanged;
  final bool attentionOnly;

  @override
  State<_SubformQuestionDropboxView> createState() =>
      _SubformQuestionDropboxViewState();
}

class _SubformQuestionDropboxViewState
    extends State<_SubformQuestionDropboxView> {
  int _selectedIndex = 0;
  bool _showAllQuestions = false;

  Future<void> _selectStatus(String subItemId, String status) async {
    if (widget.readOnly) return;
    final currentStatus = widget.answer.subformAnswers[subItemId];
    if (currentStatus == status) {
      final confirmed = await _showUndoChoiceConfirmationDialog(
        context,
        choiceLabel: status,
      );
      if (!confirmed || !mounted) return;
      setState(() {
        widget.answer.subformAnswers.remove(subItemId);
      });
      widget.onChanged();
      return;
    }
    setState(() {
      widget.answer.subformAnswers[subItemId] = status;
    });
    widget.onChanged();
  }

  Widget _buildStatusPill(String? status) {
    if (status == 'yes') {
      return const Icon(
        Icons.check_circle_rounded,
        size: 16,
        color: Color(0xFF16865B),
      );
    } else if (status == 'no') {
      return const Icon(
        Icons.cancel_rounded,
        size: 16,
        color: Color(0xFFD92D20),
      );
    } else if (status == 'na') {
      return const Icon(
        Icons.block_rounded,
        size: 16,
        color: Color(0xFFD97706),
      );
    }
    return const Icon(
      Icons.radio_button_unchecked_rounded,
      size: 16,
      color: GacColors.gray,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.attentionOnly
        ? widget.subformSection.items
              .where((item) => checklistResponseNeedsAttention(
                    widget.answer.subformAnswers[item.id],
                  ))
              .toList()
        : widget.subformSection.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final activeIndex = _selectedIndex.clamp(0, items.length - 1);
    final activeItem = items[activeIndex];
    final activeStatus = widget.answer.subformAnswers[activeItem.id];
    final activeChecker = _dosCheckerLabel(activeItem.checker);
    final activeHowToCheck = activeItem.howToCheck?.trim() ?? '';

    final answeredCount = items
        .where((i) => widget.answer.subformAnswers.containsKey(i.id))
        .length;
    final noCount = items
        .where((i) => widget.answer.subformAnswers[i.id] == 'no')
        .length;

    final overallDerived = _deriveSubformOverallStatus(
      widget.subformSection,
      widget.answer.subformAnswers,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x052979FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1F2979FF)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUBFORM: ${widget.subformSection.title.toUpperCase()}',
                      style: const TextStyle(
                        color: GacColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$answeredCount of ${items.length} answered'
                      '${noCount > 0 ? '  ·  $noCount non-compliant' : ''}',
                      style: TextStyle(
                        color: noCount > 0
                            ? const Color(0xFFD92D20)
                            : GacColors.gray,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('subform-toggle-view-mode'),
                tooltip: _showAllQuestions
                    ? 'Switch to Dropdown View'
                    : 'View All Questions',
                icon: Icon(
                  _showAllQuestions
                      ? Icons.view_day_outlined
                      : Icons.list_alt_rounded,
                  color: GacColors.primary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _showAllQuestions = !_showAllQuestions),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_showAllQuestions) ...[
            Container(
              key: const ValueKey('subform-dropdown-container'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: GacColors.offWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x332979FF)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  key: ValueKey('${widget.item.key}-subform-dropbox'),
                  isExpanded: true,
                  value: activeIndex,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: GacColors.primary,
                    size: 26,
                  ),
                  dropdownColor: GacColors.offWhite,
                  items: [
                    for (var i = 0; i < items.length; i++)
                      DropdownMenuItem<int>(
                        value: i,
                        child: Row(
                          children: [
                            _buildStatusPill(
                              widget.answer.subformAnswers[items[i].id],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Q${i + 1}: ${items[i].text}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: GacColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (newIdx) {
                    if (newIdx != null) {
                      setState(() => _selectedIndex = newIdx);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              key: const ValueKey('subform-active-question-card'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GacColors.offWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x1F2979FF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MetaBadge(
                        label: 'QUESTION ${activeIndex + 1} OF ${items.length}',
                        primary: true,
                      ),
                      const SizedBox(width: 6),
                      if (activeChecker.isNotEmpty)
                        _MetaBadge(
                          label: 'CHECKER: $activeChecker',
                          color: GacColors.green400,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    activeItem.text,
                    style: const TextStyle(
                      color: GacColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                  if (activeHowToCheck.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x082979FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: GacColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              activeHowToCheck,
                              style: const TextStyle(
                                fontSize: 11,
                                color: GacColors.gray,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ResponseChoiceButton(
                          key: ValueKey('${activeItem.id}-yes'),
                          label: 'YES',
                          icon: Icons.check_circle_rounded,
                          activeColor: const Color(0xFF16865B),
                          selected: activeStatus == 'yes',
                          enabled: !widget.readOnly,
                          onTap: () => _selectStatus(activeItem.id, 'yes'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ResponseChoiceButton(
                          key: ValueKey('${activeItem.id}-no'),
                          label: 'NO',
                          icon: Icons.cancel_rounded,
                          activeColor: const Color(0xFFD92D20),
                          selected: activeStatus == 'no',
                          enabled: !widget.readOnly,
                          onTap: () => _selectStatus(activeItem.id, 'no'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ResponseChoiceButton(
                          key: ValueKey('${activeItem.id}-na'),
                          label: 'N/A',
                          icon: Icons.block_rounded,
                          activeColor: const Color(0xFFD97706),
                          selected: activeStatus == 'na',
                          enabled: !widget.readOnly,
                          onTap: () => _selectStatus(activeItem.id, 'na'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('subform-prev-btn'),
                        onPressed: activeIndex > 0
                            ? () => setState(
                                () => _selectedIndex = activeIndex - 1,
                              )
                            : null,
                        icon: const Icon(Icons.arrow_back, size: 14),
                        label: const Text(
                          'PREVIOUS',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('subform-next-btn'),
                        onPressed: activeIndex < items.length - 1
                            ? () => setState(
                                () => _selectedIndex = activeIndex + 1,
                              )
                            : null,
                        icon: const Icon(Icons.arrow_forward, size: 14),
                        label: const Text(
                          'NEXT',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    InkWell(
                      key: ValueKey('subform-pill-$i'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _selectedIndex = i),
                      child: Container(
                        key: ValueKey('subform-pill-surface-$i'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: i == activeIndex
                              ? GacColors.primary
                              : GacColors.offWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: i == activeIndex
                                ? GacColors.primary
                                : const Color(0x292979FF),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Q${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: i == activeIndex
                                    ? GacColors.white
                                    : GacColors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _buildStatusPill(
                              widget.answer.subformAnswers[items[i].id],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Container(
                    key: ValueKey('subform-list-question-card-$i'),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GacColors.offWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x1F2979FF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _MetaBadge(label: '#${i + 1}', primary: true),
                            const SizedBox(width: 6),
                            if (_dosCheckerLabel(items[i].checker).isNotEmpty)
                              _MetaBadge(
                                label:
                                    'CHECKER: ${_dosCheckerLabel(items[i].checker)}',
                                color: GacColors.green400,
                              ),
                            const Spacer(),
                            _buildStatusPill(
                              widget.answer.subformAnswers[items[i].id],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          items[i].text,
                          style: const TextStyle(
                            color: GacColors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ResponseChoiceButton(
                                key: ValueKey('${items[i].id}-list-yes'),
                                label: 'YES',
                                icon: Icons.check_circle_rounded,
                                activeColor: const Color(0xFF16865B),
                                selected:
                                    widget.answer.subformAnswers[items[i].id] ==
                                    'yes',
                                enabled: !widget.readOnly,
                                onTap: () => _selectStatus(items[i].id, 'yes'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ResponseChoiceButton(
                                key: ValueKey('${items[i].id}-list-no'),
                                label: 'NO',
                                icon: Icons.cancel_rounded,
                                activeColor: const Color(0xFFD92D20),
                                selected:
                                    widget.answer.subformAnswers[items[i].id] ==
                                    'no',
                                enabled: !widget.readOnly,
                                onTap: () => _selectStatus(items[i].id, 'no'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ResponseChoiceButton(
                                key: ValueKey('${items[i].id}-list-na'),
                                label: 'N/A',
                                icon: Icons.block_rounded,
                                activeColor: const Color(0xFFD97706),
                                selected:
                                    widget.answer.subformAnswers[items[i].id] ==
                                    'na',
                                enabled: !widget.readOnly,
                                onTap: () => _selectStatus(items[i].id, 'na'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: overallDerived == 'yes'
                  ? const Color(0x1F16865B)
                  : overallDerived == 'no'
                  ? const Color(0x1FD92D20)
                  : const Color(0x1F2979FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: overallDerived == 'yes'
                    ? const Color(0xFF16865B)
                    : overallDerived == 'no'
                    ? const Color(0xFFD92D20)
                    : const Color(0x332979FF),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  overallDerived == 'yes'
                      ? Icons.check_circle_rounded
                      : overallDerived == 'no'
                      ? Icons.cancel_rounded
                      : Icons.hourglass_top_rounded,
                  size: 18,
                  color: overallDerived == 'yes'
                      ? const Color(0xFF16865B)
                      : overallDerived == 'no'
                      ? const Color(0xFFD92D20)
                      : GacColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    overallDerived == 'yes'
                        ? 'COMPLIANT: All requirements passed (Overall: YES)'
                        : overallDerived == 'no'
                        ? 'NON-COMPLIANT: Failure recorded (Overall: NO)'
                        : 'IN PROGRESS: $answeredCount of ${items.length} requirements answered',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: overallDerived == 'yes'
                          ? const Color(0xFF16865B)
                          : overallDerived == 'no'
                          ? const Color(0xFFD92D20)
                          : GacColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerField extends StatelessWidget {
  const _AnswerField({
    required this.label,
    required this.initialValue,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String initialValue;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      minLines: 2,
      maxLines: 4,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label, this.primary = false, this.color});

  final String label;
  final bool primary;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color != null
        ? color!.withValues(alpha: 0.15)
        : (primary ? GacColors.primary : GacColors.canvas);
    final border = color != null
        ? color!.withValues(alpha: 0.5)
        : (primary ? GacColors.primary : GacColors.border);
    final text = color ?? (primary ? GacColors.white : GacColors.gray);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: text, fontSize: 7, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SubmittedNotice extends StatelessWidget {
  const _SubmittedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x26249D6B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x40249D6B)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: GacColors.success, size: 17),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'This checklist was submitted and is read-only.',
              style: TextStyle(
                color: GacColors.success,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedPill extends StatelessWidget {
  const _SubmittedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x26249D6B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x40249D6B)),
      ),
      child: const Text(
        'SUBMITTED',
        style: TextStyle(
          color: GacColors.success,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ChecklistLoadError extends StatelessWidget {
  const _ChecklistLoadError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 38,
              color: GacColors.gray,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('TRY AGAIN'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChecklistAnswer {
  _ChecklistAnswer({
    this.status,
    this.remark = '',
    this.finding = '',
    this.actionPlan = '',
    this.commitmentDate,
    this.escalationTarget,
    this.attachmentPath,
    this.attachmentUrl,
    this.eligibility,
    Map<String, String>? slots,
    Set<String>? submittedSlots,
    Map<String, String>? subformAnswers,
  }) : slots = slots ?? {},
       submittedSlots = submittedSlots ?? {},
       subformAnswers = subformAnswers ?? {};

  factory _ChecklistAnswer.fromResponse(ChecklistResponseData? response) {
    final rawSlots = response?.details['slots'];
    final rawSubmittedSlots = response?.details['submitted_slots'];
    final rawEscalation =
        response?.escalation ??
        (response?.details['escalation'] is String
            ? response?.details['escalation'] as String
            : null);
    final rawEligibility = response?.details['eligibility'] as String?;
    final rawSubformAnswers = response?.details['subform_answers'];
    return _ChecklistAnswer(
      status: response?.status,
      remark: response?.remark ?? '',
      finding: response?.finding ?? '',
      actionPlan: response?.actionPlan ?? '',
      commitmentDate: response?.commitmentDate,
      escalationTarget: rawEscalation,
      attachmentPath: response?.attachmentPath,
      attachmentUrl: response?.attachmentUrl,
      eligibility: rawEligibility,
      slots: rawSlots is Map
          ? {
              for (final entry in rawSlots.entries)
                if (entry.key is String && entry.value is String)
                  entry.key as String: entry.value as String,
            }
          : null,
      submittedSlots: rawSubmittedSlots is Iterable
          ? rawSubmittedSlots
                .whereType<String>()
                .where((slot) => slot.trim().isNotEmpty)
                .toSet()
          : null,
      subformAnswers: rawSubformAnswers is Map
          ? {
              for (final entry in rawSubformAnswers.entries)
                if (entry.key is String && entry.value is String)
                  entry.key as String: entry.value as String,
            }
          : null,
    );
  }

  String? status;
  String remark;
  String finding;
  String actionPlan;
  String? commitmentDate;
  String? escalationTarget;
  String? attachmentPath;
  String? attachmentUrl;
  List<int>? localAttachmentBytes;
  String? localAttachmentName;
  String? eligibility;
  final Map<String, String> slots;
  final Set<String> submittedSlots;
  final Map<String, String> subformAnswers;

  static bool hasValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized != null &&
        normalized.isNotEmpty &&
        normalized != 'unanswered';
  }

  bool get isEmpty =>
      !hasValue(status) &&
      remark.trim().isEmpty &&
      finding.trim().isEmpty &&
      actionPlan.trim().isEmpty &&
      commitmentDate == null &&
      escalationTarget == null &&
      attachmentPath == null &&
      localAttachmentBytes == null &&
      !slots.values.any(hasValue) &&
      submittedSlots.isEmpty &&
      eligibility == null &&
      !subformAnswers.values.any(hasValue);
}

class _ChecklistQuestionLocation {
  const _ChecklistQuestionLocation({
    required this.section,
    required this.sectionIndex,
    required this.item,
  });

  final ChecklistSectionData section;
  final int sectionIndex;
  final ChecklistItemData item;
}

class _ChecklistValidation {
  const _ChecklistValidation(
    this.sectionIndex,
    this.message, {
    this.questionIndex,
    this.customerIndex,
  });

  final int sectionIndex;
  final String message;
  final int? questionIndex;
  final int? customerIndex;
}

String _dateString(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String _slotWindowLabel(BuildContext context, ChecklistTimeSlot slot) {
  final parts = slot.key.split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) : 0;
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return slot.label;
  }

  final start = DateTime(2000, 1, 1, hour, minute);
  final lastMinute = start.add(const Duration(minutes: 59));
  final localizations = MaterialLocalizations.of(context);
  final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);
  final startLabel = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(start),
    alwaysUse24HourFormat: use24HourFormat,
  );
  final endLabel = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(lastMinute),
    alwaysUse24HourFormat: use24HourFormat,
  );
  return '$startLabel–$endLabel';
}

bool _hasCommitmentDateAndTime(String? value) {
  final normalized = value?.trim();
  return normalized != null &&
      DateTime.tryParse(normalized) != null &&
      _hasExplicitTime(normalized);
}

bool _hasExplicitTime(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return false;
  return RegExp(r'(?:T|\s)\d{1,2}:\d{2}').hasMatch(normalized);
}

String _resolvedDosEscalation(String? value) {
  return _normalizeDosEscalation(value) ?? 'general_manager';
}

String? _normalizeDosEscalation(String? value) {
  final normalized = value
      ?.trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (normalized == null || normalized.isEmpty) return null;
  final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  if (const {
    'pm',
    'propertymanagement',
    'propertymanagementpm',
    'pmpropertymanagement',
    'propertymgmt',
    'purchasingmanager',
    'purchasingmanagerpm',
    'pmpurchasingmanager',
  }.contains(compact)) {
    // Old app/database labels remain readable but are always rewritten using
    // the corrected canonical terminology.
    return 'property_management';
  }
  if (normalized == 'purchasing' || normalized.startsWith('purchasing team')) {
    return 'purchasing';
  }
  if (normalized == 'inventory' || normalized.startsWith('inventory team')) {
    return 'inventory';
  }
  if (normalized == 'gm' ||
      normalized == 'general manager' ||
      normalized.startsWith('general manager ')) {
    return 'general_manager';
  }
  return null;
}

String? _nullableText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Future<bool> _showUndoChoiceConfirmationDialog(
  BuildContext context, {
  String? choiceLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF0F2642),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GacColors.border),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.help_outline_rounded,
            color: GacColors.primary,
            size: 26,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Undo Choice',
              style: TextStyle(
                color: GacColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to undo your choice?',
        style: TextStyle(
          color: GacColors.gray,
          fontSize: 13,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('cancel-undo-choice'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: GacColors.gray,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        FilledButton(
          key: const ValueKey('confirm-undo-choice'),
          style: FilledButton.styleFrom(
            backgroundColor: GacColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(
            'UNDO',
            style: TextStyle(
              color: GacColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
