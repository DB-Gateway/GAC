import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../data/admin_data.dart';
import '../main.dart';
import '../models/authenticated_user.dart';
import '../models/checklist_models.dart';
import '../services/checklist_service.dart';
import '../theme/gac_theme.dart';
import '../widgets/gac_surfaces.dart';
import 'dos_dashboard_screen.dart';

class UserChecklistDetailScreen extends StatefulWidget {
  const UserChecklistDetailScreen({
    required this.slug,
    required this.repository,
    this.categoryFilter,
    this.onCategoryFilterChanged,
    this.initialSectionIndex,
    this.initialQuestionIndex,
    this.auditDate,
    this.initialSlotKey,
    this.onBack,
    this.user,
    this.activeTrack,
    this.onTrackChanged,
    this.isCurrentTab = true,
    this.nowProvider,
    super.key,
  });

  final String slug;
  final ChecklistRepository repository;
  final String? categoryFilter;
  final ValueChanged<String?>? onCategoryFilterChanged;
  final int? initialSectionIndex;
  final int? initialQuestionIndex;
  final String? auditDate;
  final String? initialSlotKey;
  final VoidCallback? onBack;
  final AuthenticatedUser? user;
  final DosAuditTrack? activeTrack;
  final ValueChanged<DosAuditTrack>? onTrackChanged;
  final bool isCurrentTab;
  final DateTime Function()? nowProvider;

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
  String? _activeSlotKey;
  bool _stepByStepMode = true;
  int _fieldRevision = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _isDirty = false;
  String? _localSlugOverride;
  String? _localCategoryFilter;
  Timer? _slotWindowTimer;

  String get _currentSlug => _localSlugOverride ?? widget.slug;
  String? get _effectiveCategoryFilter =>
      _localCategoryFilter ?? widget.categoryFilter;
  DateTime get _now => widget.nowProvider?.call() ?? DateTime.now();
  String get _auditDate => widget.auditDate ?? _dateString(_now);
  ChecklistTemplateData? get _template => _record?.template;
  ChecklistSubmissionData? get _submission => _record?.submission;
  bool get _readOnly => _submission?.isSubmitted ?? false;

  bool get _isSubform =>
      _currentSlug == 'dealer-operations-standards-subform' ||
      _template?.validationMode == 'dos_subform';

  bool get _isDocumentation =>
      _currentSlug == 'dealer-operations-standards-documentation' ||
      _template?.validationMode == 'dos_documentation';

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
    'ws@gateway.com',
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() {});
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
    if (widget.slug != oldWidget.slug ||
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
    final maxSec = (effectiveTemplate.sections.length - 1).clamp(0, 1 << 20);
    final questions = _getQuestionsForTemplate(effectiveTemplate);
    final isSubmitted = record.submission?.isSubmitted ?? false;

    if (widget.initialQuestionIndex != null && questions.isNotEmpty) {
      _stepQuestionIndex = widget.initialQuestionIndex!.clamp(
        0,
        questions.length - 1,
      );
      _sectionIndex = questions[_stepQuestionIndex].sectionIndex;
    } else if (isSubmitted) {
      _sectionIndex = widget.initialSectionIndex != null
          ? widget.initialSectionIndex!.clamp(0, maxSec)
          : 0;
      if (widget.initialSectionIndex != null && questions.isNotEmpty) {
        final firstInSec = questions.indexWhere(
          (q) => q.sectionIndex == _sectionIndex,
        );
        _stepQuestionIndex = firstInSec != -1 ? firstInSec : 0;
      } else {
        _stepQuestionIndex = 0;
      }
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
          final firstInSec = questions.indexWhere(
            (q) => q.sectionIndex == _sectionIndex,
          );
          _stepQuestionIndex = firstInSec != -1 ? firstInSec : 0;
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
    }
    if (!isSubmitted) {
      _markMissedHourlySlots(effectiveTemplate);
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
      if (!mounted) return;
      setState(() {
        _rawRecord = record;
        _applyRecord(record);
      });
      _scheduleSlotWindowRefresh();
    } catch (error) {
      final fallback = gacEnableOfflineChecklistFallback
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

  Future<void> _autoSaveDraft({bool showPopup = true}) async {
    final template = _template;
    if (template == null || _saving || _readOnly || !_isDirty) return;
    await _save(submit: false, isAutoSave: true, showPopup: showPopup);
  }

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

    if (submit) {
      final validation = _validateForSubmission(template);
      if (validation != null) {
        setState(() {
          _sectionIndex = validation.sectionIndex;
          if (validation.questionIndex != null) {
            _stepQuestionIndex = validation.questionIndex!;
          }
        });
        await _showMessage('Checklist incomplete', validation.message);
        return;
      }
    }

    // Basic, Standard, and Beyond are partial views of one DOS submission.
    // Completing one category updates the shared draft and advances to the next category.
    // The final category (Beyond, or Standard if Beyond doesn't exist) or Master Audit finalizes submission.
    final finalizeSubmission = submit && (!_isCategoryView || _isLastCategory);

    setState(() => _saving = true);
    try {
      // Upload any local photos to Laravel first
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
                : 'Could not upload the attached photo to Laravel.';
            await _showMessage('Photo upload failed', msg);
            return;
          }
        }
      }

      // Hourly checklists are progressive: a PIC can submit the inspections
      // that were completed without inventing a mark for the current or a
      // later time slot.  Sending blank rows would make an API that validates
      // every received row treat those blanks as missing A/X marks.
      final isHourlyChecklist =
          template.validationMode == 'time_slots' ||
          template.slug == 'restroom' ||
          template.slug == 'utilities';
      final responses = _payloads(
        template,
        includeEmpty: submit && !isHourlyChecklist,
        includeSavedCategories: finalizeSubmission && _isCategoryView,
      );
      final submission = finalizeSubmission
          ? await widget.repository.submit(
              template.slug,
              date: _auditDate,
              responses: responses,
            )
          : await widget.repository.saveDraft(
              template.slug,
              date: _auditDate,
              responses: responses,
            );
      _isDirty = false;
      if (!mounted) {
        if (!submit && (_isDos || isAutoSave) && showPopup) {
          _showChecklistSavedPopup();
        }
        return;
      }
      setState(() {
        _record = ChecklistLoadResult(
          template: template,
          submission: submission,
        );
      });

      if (submit) {
        if (_isCategoryView && !_isLastCategory) {
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
          await _showMessage(
            'Checklist submitted',
            'Your responses were saved to Laravel and are now available to the compliance administrator.',
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
      } else {
        if (_isDos || isAutoSave) {
          if (showPopup) {
            _showChecklistSavedPopup();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Draft saved to Laravel.')),
          );
        }
      }
    } on ChecklistApiException catch (error) {
      if (!mounted) return;
      await _showMessage('Unable to save checklist', error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  _ChecklistValidation? _validateForSubmission(ChecklistTemplateData template) {
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
          );
        }
        for (final item in template.sections.expand((s) => s.items)) {
          final ans = cust.answers[item.key];
          if (ans == null || ans.isEmpty) {
            return _ChecklistValidation(
              0,
              'Please answer all check items for Customer ${cust.customerIndex}.',
            );
          }
        }
      }
      return null;
    }

    final restroom = template.validationMode == 'time_slots';
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
          for (final slot in template.timeSlots) {
            if (_isSlotLocked(slot)) continue;
            final mark = answer.slots[slot.key];
            final normalizedMark = mark?.trim().toLowerCase();
            if (normalizedMark == null ||
                normalizedMark.isEmpty ||
                normalizedMark == 'unanswered') {
              // An hourly checklist is intentionally progressive.  A missing
              // mark means that this item was not inspected in this hour; it
              // must not prevent saving or submitting the work already done.
              continue;
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
      final customerMap = _customers.map((c) => c.toJson()).toList();
      final payloads = <Map<String, dynamic>>[];
      for (final item in template.sections.expand((section) => section.items)) {
        final firstCustomerStatus = _customers.isNotEmpty
            ? _customers.first.answers[item.key]
            : null;
        final anyNo = _customers.any((c) => c.answers[item.key] == 'no');
        final derivedStatus = anyNo ? 'no' : (firstCustomerStatus ?? 'yes');

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
      if (!includeEmpty && answer.isEmpty) continue;
      final details = <String, dynamic>{};
      if (answer.slots.isNotEmpty) {
        // Locked slots are read-only, but their previously saved answers must
        // remain in the replacement payload when another hour is saved.
        details['slots'] = Map<String, String>.from(answer.slots);
      }
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

  Future<void> _showMessage(String title, String message, {bool? isSuccess}) {
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
                success ? 'CHECKLIST COMPLETE' : 'ACTION REQUIRED',
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

  Future<void> _handleStatusSelection({
    required ChecklistItemData item,
    required String? newStatus,
    ChecklistSectionData? section,
  }) async {
    if (_readOnly) return;
    final currentStatus = _answers[item.key]?.status;
    if (newStatus == currentStatus) return;

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

  Future<void> _pickPhotoForItem(String itemKey) async {
    final source = await showModalBottomSheet<ImageSource>(
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
                onTap: () =>
                    Navigator.of(dialogContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0x262979FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: GacColors.primary,
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: GacColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () =>
                    Navigator.of(dialogContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1440,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
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
          'Cannot access photos on this device.',
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
    for (final answer in _answers.values) {
      for (final slot in template.timeSlots) {
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
    return changed;
  }

  String _detectCurrentSlotKey(List<ChecklistTimeSlot> slots) {
    if (slots.isEmpty) return '08:00';
    final now = _now;
    for (final slot in slots) {
      if (!_isSlotLocked(slot, now: now)) return slot.key;
    }
    for (final slot in slots) {
      final start = _slotStart(slot);
      if (start != null && now.isBefore(start)) return slot.key;
    }
    return slots.last.key;
  }

  String _effectiveSlotKey(ChecklistTemplateData template) {
    final current = _activeSlotKey;
    if (current != null && template.timeSlots.any((s) => s.key == current)) {
      return current;
    }
    return _detectCurrentSlotKey(template.timeSlots);
  }

  void _scheduleSlotWindowRefresh() {
    _slotWindowTimer?.cancel();
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
        if (currentTemplate != null &&
            _markMissedHourlySlots(currentTemplate)) {
          _isDirty = true;
        }
      });
      _scheduleSlotWindowRefresh();
    });
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: const GacGlassSurface(
              borderRadius: 0,
              color: GacColors.glassSurfaceStrong,
              shadowBlurRadius: 16,
              shadowOffset: Offset(0, 5),
              child: SizedBox.expand(),
            ),
            leading: IconButton(
              tooltip: 'Back to checklists',
              onPressed: () async {
                if (_isDirty && !_saving && !_readOnly) {
                  await _autoSaveDraft();
                }
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (context.mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(
              _template?.name ?? 'Checklist',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            actions: [
              if (_isDos && !_loading && !_readOnly)
                IconButton(
                  key: const ValueKey('checklist-appbar-submit-button'),
                  tooltip: _isCategoryView
                      ? 'Save category'
                      : 'Submit checklist',
                  onPressed: _saving ? null : () => _save(submit: true),
                  icon: Icon(
                    _isCategoryView
                        ? Icons.save_rounded
                        : Icons.task_alt_rounded,
                  ),
                ),
              if (_template?.validationMode == 'time_slots')
                IconButton(
                  tooltip: _stepByStepMode
                      ? 'Switch to list view'
                      : 'Switch to step-by-step',
                  onPressed: () =>
                      setState(() => _stepByStepMode = !_stepByStepMode),
                  icon: Icon(
                    _stepByStepMode
                        ? Icons.view_list_rounded
                        : Icons.view_carousel_rounded,
                  ),
                ),
              IconButton(
                tooltip: 'Refresh checklist from Laravel',
                onPressed: _loading || _saving ? null : () => _load(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildTrackHeader() {
    if (_canSwitchTrack && _effectiveCategoryFilter == null) {
      return Container(
        color: GacColors.canvas,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: GacGlassSurface(
              padding: const EdgeInsets.all(4),
              borderRadius: 14,
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
            ),
          ),
        ),
      );
    }

    final isAftersales = _effectiveTrack == DosAuditTrack.aftersales;
    final baseTitle = isAftersales
        ? 'DEALER OPERATIONS STANDARDS — AFTERSALES'
        : 'DEALER OPERATIONS STANDARDS — SALES';
    final title = _effectiveCategoryFilter != null
        ? '$baseTitle — ${_effectiveCategoryFilter!.toUpperCase()}'
        : baseTitle;
    final icon = isAftersales
        ? Icons.car_repair_rounded
        : Icons.storefront_rounded;

    return Container(
      color: GacColors.canvas,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: GacGlassSurface(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            borderRadius: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: GacColors.primary, size: 15),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: GacColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
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
        onSlotSelected: (slotKey) => setState(() => _activeSlotKey = slotKey),
        onQuestionChanged: (index) =>
            setState(() => _stepQuestionIndex = index),
        onPickPhoto: _pickPhotoForItem,
        onRemovePhoto: _removePhotoForItem,
        onSaveDraft: () => _save(submit: false),
        onSubmit: () => _save(submit: true),
        onChanged: () => setState(() => _isDirty = true),
      );
    }

    if (_isDocumentation) {
      return _buildDocumentationView(template);
    }

    if (_isDos || _stepByStepMode) {
      return _buildQuestionFlow(template);
    }

    final section = template.sections[_sectionIndex];
    final progress = _progress(template);
    final sectionIncomplete = _sectionHasIncompleteItem(section);

    return Column(
      children: [
        if (_isDos) _buildTrackHeader(),
        GacGlassSurface(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 17),
          borderRadius: 0,
          color: GacColors.glassSurfaceStrong,
          shadowBlurRadius: 16,
          shadowOffset: const Offset(0, 5),
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
                              : () => setState(() => _sectionIndex--),
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
                                  sectionIncomplete
                              ? null
                              : () => setState(() => _sectionIndex++),
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
                          'SECTION ${_sectionIndex + 1} OF ${template.sections.length}  ·  VERSION ${template.version}',
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
                      if (_isDos) ...[
                        const SizedBox(width: 12),
                        if (!_readOnly)
                          FilledButton(
                            key: const ValueKey(
                              'checklist-header-submit-button',
                            ),
                            onPressed: _saving
                                ? null
                                : () => _save(submit: true),
                            style: FilledButton.styleFrom(
                              backgroundColor: GacColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 0,
                              ),
                              minimumSize: const Size(72, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x26249D6B),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: GacColors.success.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'SUBMITTED',
                              style: TextStyle(
                                color: GacColors.success,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              _isDos ? (96 + MediaQuery.viewPaddingOf(context).bottom) : 24,
            ),
            itemCount: section.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = section.items[index];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _ChecklistQuestionCard(
                    key: ValueKey('${item.key}-$_fieldRevision'),
                    item: item,
                    answer: _answers[item.key]!,
                    template: template,
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
        if (!_isDos)
          _DetailActions(
            sectionIndex: _sectionIndex,
            sectionCount: template.sections.length,
            saving: _saving,
            readOnly: _readOnly,
            onPrevious: _sectionIndex == 0
                ? null
                : () => setState(() => _sectionIndex--),
            onNext:
                _sectionIndex == template.sections.length - 1 ||
                    sectionIncomplete
                ? null
                : () => setState(() => _sectionIndex++),
            onSaveDraft: () => _save(submit: false),
            onSubmit: () => _save(submit: true),
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
        if (_isDos) _buildTrackHeader(),
        GacGlassSurface(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 15),
          borderRadius: 0,
          color: GacColors.glassSurfaceStrong,
          shadowBlurRadius: 16,
          shadowOffset: const Offset(0, 5),
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
                      if (_isDos) ...[
                        const SizedBox(width: 10),
                        if (!_readOnly)
                          FilledButton(
                            key: const ValueKey(
                              'checklist-header-submit-button',
                            ),
                            onPressed: _saving
                                ? null
                                : () => _save(submit: true),
                            style: FilledButton.styleFrom(
                              backgroundColor: GacColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                              ),
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
                                        ? (_isLastCategory ? 'SUBMIT' : 'SAVE')
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
                      ] else if (_readOnly) ...[
                        const SizedBox(width: 10),
                        const _SubmittedPill(),
                      ],
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
                                  : _isCategoryView
                                  ? (_isLastCategory
                                        ? Icons.task_alt_rounded
                                        : Icons.arrow_forward_rounded)
                                  : Icons.task_alt_rounded,
                              size: 18,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                questionIndex < questions.length - 1
                                    ? 'NEXT QUESTION'
                                    : _isCategoryView
                                    ? (_isLastCategory
                                          ? 'SUBMIT CHECKLIST'
                                          : 'NEXT CATEGORY')
                                    : 'SUBMIT CHECKLIST',
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
        if (!_isDos)
          _DetailActions(
            sectionIndex: question.sectionIndex,
            sectionCount: template.sections.length,
            saving: _saving,
            readOnly: _readOnly,
            onPrevious: questionIndex == 0
                ? null
                : () => showQuestion(questionIndex - 1),
            onNext: (questionIndex == questions.length - 1 || !canProceed)
                ? null
                : () => showQuestion(questionIndex + 1),
            onSaveDraft: () => _save(submit: false),
            onSubmit: () => _save(submit: true),
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
    final howToCheck =
        item.howToCheck ??
        'No detailed verification guide is available for this standard.';
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
                                  ? 'Standard #${item.displayNumber}'
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
                              color: const Color(0x1F2979FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0x402979FF),
                              ),
                            ),
                            child: Text(
                              howToCheck,
                              style: const TextStyle(
                                color: GacColors.textPrimary,
                                fontSize: 13,
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                              ),
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
        GacGlassSurface(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 15),
          borderRadius: 0,
          color: GacColors.glassSurfaceStrong,
          shadowBlurRadius: 16,
          shadowOffset: const Offset(0, 5),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'DOCUMENTATION AUDIT',
                          style: TextStyle(
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
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              18,
              16,
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
                      _buildCustomerSelectorCard(activeCustomer),
                      const SizedBox(height: 14),
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
                              final status = activeCustomer.answers[item.key];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildDocQuestionCard(
                                  item: item,
                                  status: status,
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

  Widget _buildCustomerSelectorCard(CustomerAuditSample activeCustomer) {
    return GacContentPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          const Icon(
            Icons.people_alt_rounded,
            color: GacColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
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
          DropdownButton<int>(
            key: const ValueKey('customer-dropdown'),
            value: activeCustomer.customerIndex,
            dropdownColor: const Color(0xFF0F2642),
            style: const TextStyle(
              color: GacColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            underline: const SizedBox.shrink(),
            items: _customers.map((cust) {
              return DropdownMenuItem<int>(
                value: cust.customerIndex,
                child: Text('Customer ${cust.customerIndex}'),
              );
            }).toList(),
            onChanged: (newIdx) {
              if (newIdx != null && newIdx != _selectedCustomerIndex) {
                setState(() {
                  _selectedCustomerIndex = newIdx;
                  _fieldRevision++;
                });
              }
            },
          ),
          const Spacer(),
          if (!_readOnly) ...[
            FilledButton.icon(
              key: const ValueKey('add-customer-button'),
              style: FilledButton.styleFrom(
                backgroundColor: GacColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'ADD CUSTOMER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () {
                final nextIdx = _customers.isEmpty
                    ? 1
                    : (_customers.map((c) => c.customerIndex).reduce(math.max) +
                          1);
                setState(() {
                  _customers.add(CustomerAuditSample(customerIndex: nextIdx));
                  _selectedCustomerIndex = nextIdx;
                  _isDirty = true;
                  _fieldRevision++;
                });
              },
            ),
            if (_customers.length > 1) ...[
              const SizedBox(width: 8),
              IconButton(
                key: ValueKey(
                  'remove-customer-${activeCustomer.customerIndex}',
                ),
                tooltip: 'Remove Customer ${activeCustomer.customerIndex}',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _customers.removeWhere(
                      (c) => c.customerIndex == activeCustomer.customerIndex,
                    );
                    _selectedCustomerIndex = _customers.first.customerIndex;
                    _isDirty = true;
                    _fieldRevision++;
                  });
                },
              ),
            ],
          ],
        ],
      ),
    );
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
              const SizedBox(width: 8),
              const Text(
                'REPAIR ORDER & JOB DETAILS',
                style: TextStyle(
                  color: GacColors.gray,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: ValueKey('doc-ro-number-${activeCustomer.customerIndex}'),
            initialValue: activeCustomer.roNumber,
            enabled: !_readOnly,
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
            enabled: !_readOnly,
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
  }) {
    final itemNumber = item.metadata['number'] ?? item.id;
    return GacContentPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetaBadge(label: '#$itemNumber', primary: true),
              const SizedBox(width: 6),
              if (item.coverage case final cov?) ...[
                _MetaBadge(label: cov),
                const SizedBox(width: 6),
              ],
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
                  enabled: !_readOnly,
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
                  enabled: !_readOnly,
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
                  enabled: !_readOnly,
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
    if (_readOnly) return;
    final currentStatus = customer.answers[item.key];
    if (newStatus == currentStatus) return;

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
      if (_customers.isEmpty || template.itemCount == 0) return 0;
      final totalExpected = template.itemCount * _customers.length;
      var totalAnswered = 0;
      for (final cust in _customers) {
        totalAnswered += cust.answers.length;
      }
      return ((totalAnswered / totalExpected).clamp(0.0, 1.0)) * 100;
    }
    if (template.validationMode == 'time_slots') {
      final total = template.itemCount * template.timeSlots.length;
      final answered = _answers.values.fold(
        0,
        (sum, answer) => sum + answer.slots.length,
      );
      return total == 0 ? 0 : (answered / total) * 100;
    }
    final answered = _answers.values
        .where((answer) => answer.status != null)
        .length;
    return template.itemCount == 0 ? 0 : (answered / template.itemCount) * 100;
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
    required this.onSaveDraft,
    required this.onSubmit,
    required this.onChanged,
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
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;

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
    final currentMark = answer.slots[activeSlotKey];
    final activeSlot = template.timeSlots.firstWhere(
      (s) => s.key == activeSlotKey,
      orElse: () => ChecklistTimeSlot(key: activeSlotKey, label: activeSlotKey),
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
        isCurrentSlotLocked ||
        (hasChosenChoice &&
            (!isNaReasonRequired || hasNaReason) &&
            (!isNotGoodRemarkRequired || hasNotGoodRemark));

    final answeredInSlot = items
        .where((i) => answers[i.key]?.slots.containsKey(activeSlotKey) ?? false)
        .length;

    return Column(
      children: [
        GacGlassSurface(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          borderRadius: 0,
          color: GacColors.glassSurfaceStrong,
          shadowBlurRadius: 16,
          shadowOffset: const Offset(0, 5),
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
                          'INSPECTION TIME: ${activeSlot.label.toUpperCase()}  ·  $answeredInSlot OF ${items.length} ANSWERED',
                          style: const TextStyle(
                            color: GacColors.gray,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Text(
                        'QUESTION ${questionIndex + 1} / ${items.length}',
                        style: const TextStyle(
                          color: GacColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
                            isAnswered: items.every(
                              (i) =>
                                  answers[i.key]?.slots.containsKey(slot.key) ??
                                  false,
                            ),
                            hasDefect: items.any(
                              (i) =>
                                  answers[i.key]?.slots[slot.key] == 'not_good',
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _MetaBadge(
                                label:
                                    'QUESTION #${item.displayNumber ?? (questionIndex + 1)}',
                                primary: true,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: currentMark == 'good'
                                      ? const Color(0x261B8A5A)
                                      : (currentMark == 'not_good'
                                            ? const Color(0x26D92D20)
                                            : (currentMark == 'na'
                                                  ? const Color(0x26D97706)
                                                  : Colors.white10)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: currentMark == 'good'
                                        ? const Color(0xFF1B8A5A)
                                        : (currentMark == 'not_good'
                                              ? const Color(0xFFD92D20)
                                              : (currentMark == 'na'
                                                    ? const Color(0xFFD97706)
                                                    : Colors.white24)),
                                  ),
                                ),
                                child: Text(
                                  currentMark == 'good'
                                      ? 'MARKED GOOD'
                                      : (currentMark == 'not_good'
                                            ? 'MARKED NOT GOOD'
                                            : (currentMark == 'na'
                                                  ? 'MARKED N/A'
                                                  : 'UNANSWERED')),
                                  style: TextStyle(
                                    color: currentMark == 'good'
                                        ? const Color(0xFF1B8A5A)
                                        : (currentMark == 'not_good'
                                              ? const Color(0xFFD92D20)
                                              : (currentMark == 'na'
                                                    ? const Color(0xFFD97706)
                                                    : GacColors.gray)),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ),
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
                          if (isCurrentSlotLocked) ...[
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
                            isCurrentSlotLocked
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
                                  enabled: !readOnly && !isCurrentSlotLocked,
                                  onTap: () {
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
                                  enabled: !readOnly && !isCurrentSlotLocked,
                                  onTap: () {
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
                                  enabled: !readOnly && !isCurrentSlotLocked,
                                  onTap: () {
                                    answer.slots[activeSlotKey] = 'na';
                                    onChanged();
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (!isCurrentSlotLocked &&
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
                            onPressed:
                                (questionIndex < items.length - 1 && canProceed)
                                ? () => onQuestionChanged(questionIndex + 1)
                                : null,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: Text(
                              questionIndex < items.length - 1
                                  ? 'NEXT'
                                  : 'END OF LIST',
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
        _DetailActions(
          sectionIndex: 0,
          sectionCount: 1,
          saving: saving,
          readOnly: readOnly,
          onPrevious: null,
          onNext: null,
          onSaveDraft: onSaveDraft,
          onSubmit: onSubmit,
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
    required this.status,
    required this.onTap,
  });

  final int number;
  final bool isCurrent;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFF0D2137);
    Color border = GacColors.border;
    Color text = GacColors.gray;

    if (status == 'good') {
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
    this.showDosEscalationAndCommitment = false,
    this.showDosBomTask = false,
    this.showDosActionPlan = false,
    this.prominent = false,
    this.isSlotLocked,
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
  final bool showDosEscalationAndCommitment;
  final bool showDosBomTask;
  final bool showDosActionPlan;
  final bool prominent;
  final bool Function(ChecklistTimeSlot)? isSlotLocked;
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
              slots: template.timeSlots,
              answer: answer,
              readOnly: readOnly,
              isSlotLocked: isSlotLocked,
              onChanged: onChanged,
            ),
            if (answer.slots.values.any((m) => m == 'not_good') ||
                answer.attachmentPath != null ||
                answer.localAttachmentBytes != null) ...[
              const SizedBox(height: 14),
              _RemarksAndPhotoCard(
                answer: answer,
                readOnly: readOnly,
                onPickPhoto: onPickPhoto,
                onRemovePhoto: onRemovePhoto,
                onChanged: onChanged,
              ),
            ],
          ] else ...[
            if (isSubformRef && subformSection != null) ...[
              _SubformEligibilitySelector(
                eligibility: answer.eligibility,
                enabled: !readOnly,
                onChanged: (newEligibility) {
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
                onChanged: (value) {
                  if (onSelectStatus != null) {
                    onSelectStatus!(value);
                  } else {
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
    required this.onChanged,
  });

  final List<ChecklistTimeSlot> slots;
  final _ChecklistAnswer answer;
  final bool readOnly;
  final bool Function(ChecklistTimeSlot)? isSlotLocked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < slots.length; index++) ...[
          Builder(
            builder: (context) {
              final slot = slots[index];
              final locked = isSlotLocked?.call(slot) ?? false;
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
                              color: locked
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
                  Expanded(
                    child: _SlotButton(
                      label: locked ? 'LOCKED' : 'GOOD  /',
                      selected: answer.slots[slot.key] == 'good',
                      enabled: !readOnly && !locked,
                      onTap: () {
                        answer.slots[slot.key] = 'good';
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SlotButton(
                      label: locked ? 'LOCKED' : 'NOT GOOD  X',
                      selected: answer.slots[slot.key] == 'not_good',
                      enabled: !readOnly && !locked,
                      onTap: () {
                        answer.slots[slot.key] = 'not_good';
                        onChanged();
                      },
                    ),
                  ),
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
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? GacColors.primary : const Color(0xFF0D2137),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 36),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? GacColors.primary : GacColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? GacColors.white : GacColors.gray,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
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
  });

  final ChecklistItemData item;
  final ChecklistSection subformSection;
  final _ChecklistAnswer answer;
  final bool readOnly;
  final VoidCallback onChanged;

  @override
  State<_SubformQuestionDropboxView> createState() =>
      _SubformQuestionDropboxViewState();
}

class _SubformQuestionDropboxViewState
    extends State<_SubformQuestionDropboxView> {
  int _selectedIndex = 0;
  bool _showAllQuestions = false;

  void _selectStatus(String subItemId, String status) {
    if (widget.readOnly) return;
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
    final items = widget.subformSection.items;
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

class _DetailActions extends StatelessWidget {
  const _DetailActions({
    required this.sectionIndex,
    required this.sectionCount,
    required this.saving,
    required this.readOnly,
    required this.onPrevious,
    required this.onNext,
    required this.onSaveDraft,
    required this.onSubmit,
  });

  final int sectionIndex;
  final int sectionCount;
  final bool saving;
  final bool readOnly;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GacGlassSurface(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        borderRadius: 0,
        color: GacColors.glassSurfaceStrong,
        shadowBlurRadius: 16,
        shadowOffset: const Offset(0, -5),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous section',
                  onPressed: saving ? null : onPrevious,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  tooltip: 'Next section',
                  onPressed: saving ? null : onNext,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                const SizedBox(width: 6),
                if (!readOnly) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : onSaveDraft,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const FittedBox(child: Text('SAVE DRAFT')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: saving ? null : onSubmit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: saving
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: GacColors.white,
                              ),
                            )
                          : const Text('SUBMIT'),
                    ),
                  ),
                ] else ...[
                  const Spacer(),
                  const Text(
                    'SUBMITTED',
                    style: TextStyle(
                      color: GacColors.gray,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
    Map<String, String>? subformAnswers,
  }) : slots = slots ?? {},
       subformAnswers = subformAnswers ?? {};

  factory _ChecklistAnswer.fromResponse(ChecklistResponseData? response) {
    final rawSlots = response?.details['slots'];
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
  final Map<String, String> subformAnswers;

  bool get isEmpty =>
      status == null &&
      remark.trim().isEmpty &&
      finding.trim().isEmpty &&
      actionPlan.trim().isEmpty &&
      commitmentDate == null &&
      escalationTarget == null &&
      attachmentPath == null &&
      localAttachmentBytes == null &&
      slots.isEmpty &&
      eligibility == null &&
      subformAnswers.isEmpty;
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
  });

  final int sectionIndex;
  final String message;
  final int? questionIndex;
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
