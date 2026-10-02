import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';

import '../models/checklist_models.dart';
import '../models/authenticated_user.dart';
import '../services/checklist_service.dart';
import '../services/utilities_missed_checklist_service.dart';
import '../theme/gac_theme.dart';
import '../widgets/gac_surfaces.dart';
import '../widgets/user_floating_header.dart';
import '../utils/checklist_time_slot.dart';
import '../utils/checklist_attention.dart';
import 'dos_dashboard_screen.dart';
import 'user_checklist_detail_screen.dart';

enum _TaskFilter { all, inProgress, attention }

enum _TaskStatus { todo, inProgress, completed }

typedef UserChecklistOpenCallback = FutureOr<void> Function(
  String checklistSlug,
  String auditDate,
);

typedef UserChecklistOpenWithSlotCallback = FutureOr<void> Function(
  String checklistSlug,
  String auditDate,
  String? initialSlotKey,
);

typedef UserChecklistOpenWithQuestionCallback = FutureOr<void> Function(
  String checklistSlug,
  String auditDate,
  String? initialSlotKey,
  String? initialItemKey,
);

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    this.size = 78,
    this.strokeWidth = 6,
    super.key,
  });

  final int value;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value.clamp(0, 100);

    return Semantics(
      label: '$normalizedValue percent complete',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _ProgressRingPainter(
                value: normalizedValue / 100,
                strokeWidth: strokeWidth,
              ),
            ),
            Center(
              child: ExcludeSemantics(
                child: Text(
                  '$normalizedValue%',
                  style: const TextStyle(
                    color: GacColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daily task dashboard backed by the authenticated Laravel checklist catalog.
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({
    required this.isActive,
    required this.onOpenChecklists,
    required this.onOpenProfile,
    required this.onOpenNotifications,
    this.user = AuthenticatedUser.fallback,
    this.unreadNotifications = 0,
    this.repository,
    this.now,
    this.onOpenChecklist,
    this.onOpenChecklistWithSlot,
    this.onOpenChecklistWithQuestion,
    this.activeTrack,
    this.onTrackChanged,
    super.key,
  });

  final bool isActive;
  final VoidCallback onOpenChecklists;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;
  final AuthenticatedUser user;
  final int unreadNotifications;
  final ChecklistRepository? repository;
  final DateTime Function()? now;
  final UserChecklistOpenCallback? onOpenChecklist;
  final UserChecklistOpenWithSlotCallback? onOpenChecklistWithSlot;
  final UserChecklistOpenWithQuestionCallback? onOpenChecklistWithQuestion;
  final DosAuditTrack? activeTrack;
  final ValueChanged<DosAuditTrack>? onTrackChanged;

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  late ChecklistRepository _repository;
  late final ScrollController _scrollController;
  late DateTime _today;
  late DateTime _selectedDate;
  late DateTime _weekAnchor;

  List<ChecklistCatalogItem> _tasks = const [];
  bool _attentionUnavailable = false;
  _TaskFilter _selectedFilter = _TaskFilter.all;
  bool _loading = true;
  bool _topBarExpanded = true;
  String? _error;
  int _requestGeneration = 0;
  late final Timer _utilitiesDeadlineTimer;
  DosAuditTrack? _internalTrack;

  bool get _isDos {
    if (widget.user.is5sUtilities ||
        widget.user.is5sService ||
        widget.user.is5sSales ||
        widget.user.isUtilities ||
        widget.user.isSalesService5s) {
      return false;
    }
    return widget.activeTrack != null ||
        widget.user.isDosAuditor ||
        widget.user.isDosSales ||
        widget.user.isDosAftersales ||
        widget.user.userType.trim().toUpperCase() == 'DOS' ||
        _tasks.any(
          (task) =>
              task.slug == 'dealer-operations-standards' ||
              task.slug == 'dealer-operations-standards-sales',
        );
  }

  bool get _is5sChecklistUser {
    final user = widget.user;
    return user.is5sUtilities ||
        user.is5sService ||
        user.is5sSales ||
        user.isSalesService5s;
  }

  DosAuditTrack get _effectiveTrack {
    if (widget.activeTrack != null) return widget.activeTrack!;
    if (_internalTrack != null) return _internalTrack!;
    final user = widget.user;
    if (user.isSalesManager || user.isDosSales) return DosAuditTrack.sales;
    if (user.isAftersalesChecker || user.isDosAftersales) {
      return DosAuditTrack.aftersales;
    }
    return DosAuditTrack.aftersales;
  }

  bool get _canSwitchTrack {
    final user = widget.user;
    if (user.isAdmin) return true;
    if (user.isSalesManager ||
        user.isAftersalesChecker ||
        user.isDosSales ||
        user.isDosAftersales) {
      return false;
    }
    if (user.userType.trim().toUpperCase() == 'DOS') return true;
    return false;
  }

  List<ChecklistCatalogItem> get _trackFilteredTasks {
    final user = widget.user;
    if (user.is5sSales) {
      return _tasks.where((t) => t.slug == 'sales').toList(growable: false);
    }
    if (user.is5sService) {
      return _tasks.where((t) => t.slug == 'service').toList(growable: false);
    }
    if (user.is5sUtilities || user.isUtilities) {
      return _tasks
          .where(
            (t) =>
                t.slug == 'restroom' ||
                t.slug.startsWith('restroom') ||
                t.slug == 'utilities',
          )
          .toList(growable: false);
    }
    if (user.isSalesService5s) {
      return _tasks
          .where(
            (t) => const {'sales', 'service', 'gateway-5s'}.contains(t.slug),
          )
          .toList(growable: false);
    }
    if (user.isDosSales || user.isSalesManager) {
      return _tasks
          .where((t) => t.slug == 'dealer-operations-standards-sales')
          .toList(growable: false);
    }
    if (user.isDosAftersales || user.isAftersalesChecker) {
      return _tasks
          .where((t) {
            if (t.slug == 'dealer-operations-standards') return true;
            if (user.canAccessSubform &&
                t.slug == 'dealer-operations-standards-subform') {
              return true;
            }
            if (user.canAccessDocumentation &&
                t.slug == 'dealer-operations-standards-documentation') {
              return true;
            }
            return false;
          })
          .toList(growable: false);
    }
    if (!_isDos) return _tasks;
    final hasAftersales = _tasks.any(
      (t) => t.slug == 'dealer-operations-standards',
    );
    final hasSales = _tasks.any(
      (t) => t.slug == 'dealer-operations-standards-sales',
    );
    if (hasAftersales && hasSales) {
      if (_effectiveTrack == DosAuditTrack.aftersales) {
        return _tasks
            .where(
              (t) => const {
                'dealer-operations-standards',
                'dealer-operations-standards-subform',
                'dealer-operations-standards-documentation',
              }.contains(t.slug),
            )
            .toList(growable: false);
      }
      return _tasks
          .where((t) => t.slug == 'dealer-operations-standards-sales')
          .toList(growable: false);
    }
    return _tasks;
  }

  List<DateTime> get _overviewDays {
    final monday = _weekAnchor.subtract(
      Duration(days: _weekAnchor.weekday - 1),
    );
    return [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
  }

  List<ChecklistCatalogItem> get _visibleTasks {
    final tasks = _trackFilteredTasks;
    if (_selectedFilter == _TaskFilter.all) return tasks;

    return tasks
        .where((task) {
          final status = _statusFor(task);
          return switch (_selectedFilter) {
            _TaskFilter.inProgress => status == _TaskStatus.inProgress,
            _TaskFilter.attention => (task.submission?.issues ?? 0) > 0,
            _TaskFilter.all => true,
          };
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ChecklistApiService();
    _today = DateUtils.dateOnly((widget.now ?? DateTime.now)());
    _selectedDate = _today;
    _weekAnchor = _today;
    _scrollController = ScrollController()..addListener(_handleHomeScroll);
    _utilitiesDeadlineTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted &&
          widget.isActive &&
          widget.repository == null &&
          widget.now == null &&
          UtilitiesMissedChecklistService.isUtilitiesUser(widget.user)) {
        unawaited(_load(showSpinner: false));
      }
    });
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant UserHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.activeTrack != widget.activeTrack &&
        widget.activeTrack != null) {
      setState(() {
        _internalTrack = widget.activeTrack;
      });
    }

    if (oldWidget.repository != widget.repository) {
      _repository = widget.repository ?? ChecklistApiService();
      unawaited(_load());
    } else if (oldWidget.user.id != widget.user.id ||
        oldWidget.user.branch != widget.user.branch ||
        oldWidget.user.userType != widget.user.userType) {
      // Role-scoped dashboards may mount before the cached login profile has
      // finished loading. Refresh as soon as the authenticated role arrives.
      unawaited(_load());
    }

    if (!oldWidget.isActive && widget.isActive) {
      setState(() => _selectedFilter = _TaskFilter.all);
      unawaited(_load(showSpinner: false));
    }
  }

  @override
  void dispose() {
    _utilitiesDeadlineTimer.cancel();
    _requestGeneration++;
    _scrollController.removeListener(_handleHomeScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    final generation = ++_requestGeneration;
    final requestedDate = _dateParameter(_selectedDate);

    if (showSpinner && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      var tasks = await _repository.fetchCatalog(date: requestedDate);
      if (!mounted || generation != _requestGeneration) return;
      if (widget.repository == null &&
          widget.isActive &&
          widget.now == null &&
          UtilitiesMissedChecklistService.isUtilitiesUser(widget.user) &&
          requestedDate == _dateParameter(DateTime.now())) {
        final sync =
            await UtilitiesMissedChecklistService.syncMissedUtilitiesChecklist(
              repository: _repository,
              user: widget.user,
              catalog: tasks,
            );
        if (sync?.autoSubmitted == true) {
          tasks = await _repository.fetchCatalog(date: requestedDate);
        }
        if (!mounted || generation != _requestGeneration) return;
      }
      final catalog = tasks
          .where((t) => t.slug != 'dealer-operations-standards-subform')
          .toList(growable: false);
      final merged = List<ChecklistCatalogItem>.of(catalog);
      final user = widget.user;
      ChecklistSubmissionData? docSubmission;
      final records = <String, ChecklistLoadResult>{};
      if (user.canAccessDocumentation) {
        try {
          final docRecord = await _repository.fetchChecklist(
            'dealer-operations-standards-documentation',
            date: requestedDate,
          );
          docSubmission = docRecord.submission;
          records['dealer-operations-standards-documentation'] = docRecord;
        } catch (_) {
          // Fallback gracefully
        }
      }

      final docIndex = merged.indexWhere(
        (t) => t.slug == 'dealer-operations-standards-documentation',
      );
      if (user.canAccessDocumentation) {
        if (docIndex >= 0) {
          if (docSubmission != null) {
            merged[docIndex] = merged[docIndex].copyWith(
              submission: docSubmission,
            );
          }
        } else {
          merged.add(
            ChecklistCatalogItem(
              id: 11,
              slug: 'dealer-operations-standards-documentation',
              name: 'Dealer Operations Standards - Documentation',
              description: 'FY2025 Aftersales Standards Compliance Audit Documentation Sheet',
              version: 1,
              settings: const {'validation_mode': 'dos_documentation'},
              sectionCount: 3,
              itemCount: 17,
              workUnitCount: 17,
              submission: docSubmission,
            ),
          );
        }
      }
      var attentionUnavailable = false;
      final verified = await Future.wait(
        merged.map((task) async {
          if (task.submission == null) return task;
          try {
            final record =
                records[task.slug] ??
                await _repository.fetchChecklist(
                  task.slug,
                  date: requestedDate,
                );
            return _withAttentionCount(
              task,
              checklistAttentionTargets(record, user).length,
            );
          } catch (_) {
            // Unverified summary counts must never create attention links.
            attentionUnavailable = true;
            return _withAttentionCount(task, 0);
          }
        }),
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _tasks = verified;
        _attentionUnavailable = attentionUnavailable;
        _loading = false;
        _error = null;
      });
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
        _error = 'Your assigned tasks could not be loaded from Laravel.';
      });
    }
  }

  bool get _canNavigateMonthForward =>
      _selectedDate.year < _today.year ||
      (_selectedDate.year == _today.year && _selectedDate.month < _today.month);

  bool get _canNavigateWeekForward {
    final currentMonday = _today.subtract(Duration(days: _today.weekday - 1));
    final selectedMonday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    return selectedMonday.isBefore(currentMonday);
  }

  void _selectDate(DateTime date) {
    if (date.isAfter(_today)) return;
    if (DateUtils.isSameDay(date, _selectedDate)) return;
    setState(() {
      _selectedDate = date;
      _weekAnchor = date;
      _selectedFilter = _TaskFilter.all;
    });
    unawaited(_load());
  }

  DateTime _addMonths(DateTime date, int deltaMonths) {
    var year = date.year;
    var month = date.month + deltaMonths;
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    while (month > 12) {
      month -= 12;
      year += 1;
    }
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final day = date.day > daysInMonth ? daysInMonth : date.day;
    return DateTime(year, month, day);
  }

  void _navigateMonth(int delta) {
    if (delta > 0 && !_canNavigateMonthForward) return;
    var target = _addMonths(_selectedDate, delta);
    if (target.isAfter(_today)) {
      target = _today;
    }
    if (DateUtils.isSameDay(target, _selectedDate)) return;
    setState(() {
      _weekAnchor = target;
      _selectedDate = target;
      _selectedFilter = _TaskFilter.all;
    });
    unawaited(_load());
  }

  void _navigateWeek(int delta) {
    if (delta > 0 && !_canNavigateWeekForward) return;
    var target = _selectedDate.add(Duration(days: 7 * delta));
    if (target.isAfter(_today)) {
      target = _today;
    }
    if (DateUtils.isSameDay(target, _selectedDate)) return;
    setState(() {
      _weekAnchor = target;
      _selectedDate = target;
      _selectedFilter = _TaskFilter.all;
    });
    unawaited(_load());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(_today) ? _today : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: _today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: GacColors.cardSurface,
              onSurface: GacColors.textPrimary,
              primary: GacColors.primary,
              onPrimary: GacColors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: GacColors.cardSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      if (picked.isAfter(_today)) return;
      setState(() {
        _weekAnchor = picked;
        _selectedDate = picked;
        _selectedFilter = _TaskFilter.all;
      });
      unawaited(_load());
    }
  }

  void _goToToday() {
    if (DateUtils.isSameDay(_selectedDate, _today)) return;
    setState(() {
      _weekAnchor = _today;
      _selectedDate = _today;
      _selectedFilter = _TaskFilter.all;
    });
    unawaited(_load());
  }

  void _scrollHomeToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleHomeScroll() {
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

  @override
  Widget build(BuildContext context) {
    final bottomClearance = MediaQuery.viewPaddingOf(context).bottom;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 380
                  ? 12.0
                  : 16.0;

              return RefreshIndicator(
                onRefresh: () => _load(showSpinner: false),
                child: CustomScrollView(
                  key: const PageStorageKey<String>('user-home-scroll'),
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _HomeTopBarDelegate(
                        expanded: _topBarExpanded,
                        onOpenProfile: widget.onOpenProfile,
                        onOpenHome: _scrollHomeToTop,
                        onOpenNotifications: widget.onOpenNotifications,
                        user: widget.user,
                        unreadNotifications: widget.unreadNotifications,
                      ),
                    ),
                    if (_isDos || _is5sChecklistUser) _buildTrackHeader(),
                    SliverPadding(
                      key: const ValueKey('user-home-content-padding'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        UserFloatingHeader.extent + 28 + bottomClearance,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: _buildDashboard(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final isNotToday = !DateUtils.isSameDay(_selectedDate, _today);
    final isAttentionFilter = _selectedFilter == _TaskFilter.attention;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Select date',
              style: TextStyle(
                color: GacColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.25,
              ),
            ),
            const Spacer(),
            if (isNotToday) ...[
              _TodayChip(onTap: _goToToday),
              const SizedBox(width: 8),
            ],
            _CalendarButton(onTap: _pickDate),
          ],
        ),
        const SizedBox(height: 8),
        _DateNavigator(
          weekAnchor: _weekAnchor,
          onMonthBack: () => _navigateMonth(-1),
          onMonthForward: _canNavigateMonthForward
              ? () => _navigateMonth(1)
              : null,
          onWeekBack: () => _navigateWeek(-1),
          onWeekForward: _canNavigateWeekForward
              ? () => _navigateWeek(1)
              : null,
          onPickDate: _pickDate,
          canMonthForward: _canNavigateMonthForward,
          canWeekForward: _canNavigateWeekForward,
        ),
        const SizedBox(height: 8),
        _DatePickerRow(
          days: _overviewDays,
          selectedDate: _selectedDate,
          onChanged: _selectDate,
          maxDate: _today,
        ),
        const SizedBox(height: 12),
        GacGlassSurface(
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          blurSigma: 6,
          shadowBlurRadius: 16,
          shadowOffset: const Offset(0, 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FILTER STATUS',
                style: TextStyle(
                  color: GacColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in _TaskFilter.values) ...[
                      _FilterChip(
                        label: _filterLabel(filter),
                        count: _taskCount(filter),
                        selected: _selectedFilter == filter,
                        onTap: () => setState(() => _selectedFilter = filter),
                      ),
                      if (filter != _TaskFilter.values.last)
                        const SizedBox(width: 7),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                isAttentionFilter
                    ? 'Attention needed'
                    : DateUtils.isSameDay(_selectedDate, _today)
                    ? "Today's assigned tasks"
                    : 'Assigned tasks · ${_longDate(_selectedDate)}',
                style: const TextStyle(
                  color: GacColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (!_loading)
              IconButton(
                key: const ValueKey('user-home-refresh'),
                tooltip: 'Refresh assigned tasks',
                onPressed: () => _load(showSpinner: false),
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_loading)
          const _LoadingPanel()
        else if (_error != null)
          _ErrorPanel(message: _error!, onRetry: _load)
        else ...[
          _OverviewPanel(tasks: _trackFilteredTasks, user: widget.user),
          const SizedBox(height: 14),
          if (isAttentionFilter)
            if (_visibleTasks.isEmpty)
              _EmptyPanel(
                hasAssignments: _trackFilteredTasks.isNotEmpty,
                isAttentionFilter: true,
                attentionUnavailable: _attentionUnavailable,
              )
            else
              _IssueSummary(
                tasks: _visibleTasks,
                onOpen: (task) => _openTask(task, attentionOnly: true),
              )
          else if (_visibleTasks.isEmpty)
            _EmptyPanel(hasAssignments: _trackFilteredTasks.isNotEmpty)
          else
            for (var index = 0; index < _visibleTasks.length; index++) ...[
              _TaskCard(
                task: _visibleTasks[index],
                attentionMode:
                    _selectedFilter == _TaskFilter.all &&
                    (_visibleTasks[index].submission?.issues ?? 0) > 0,
                onOpen: () {
                  final task = _visibleTasks[index];
                  unawaited(_openTask(task));
                },
              ),
              if (index != _visibleTasks.length - 1) const SizedBox(height: 12),
            ],
          if (isAttentionFilter && _attentionUnavailable) ...[
            const SizedBox(height: 12),
            const Text(
              'Some responses could not be checked. Refresh to verify attention items.',
            ),
          ],
        ],
      ],
    );
  }

  int _taskCount(_TaskFilter filter) {
    final tasks = _trackFilteredTasks;
    if (filter == _TaskFilter.all) return tasks.length;
    if (filter == _TaskFilter.attention) {
      return tasks.fold<int>(
        0,
        (sum, task) => sum + (task.submission?.issues ?? 0),
      );
    }
    return tasks.where((task) {
      final status = _statusFor(task);
      return switch (filter) {
        _TaskFilter.inProgress => status == _TaskStatus.inProgress,
        _TaskFilter.attention => (task.submission?.issues ?? 0) > 0,
        _TaskFilter.all => true,
      };
    }).length;
  }

  ChecklistCatalogItem _withAttentionCount(
    ChecklistCatalogItem task,
    int count,
  ) {
    final submission = task.submission;
    if (submission == null) return task;
    return task.copyWith(
      submission: ChecklistSubmissionData(
        id: submission.id,
        status: submission.status,
        auditDate: submission.auditDate,
        templateVersion: submission.templateVersion,
        scores: submission.scores,
        responses: submission.responses,
        answeredItems: submission.answeredItems,
        totalItems: submission.totalItems,
        completionPercentage: submission.completionPercentage,
        submittedAt: submission.submittedAt,
        issueCount: count,
      ),
    );
  }

  ChecklistCatalogItem? _latestResumeTarget(List<ChecklistCatalogItem> tasks) {
    final candidates = tasks
        .where((task) {
          final submission = task.submission;
          if (submission == null) return false;
          if (submission.isSubmitted && !_isUtilitiesChecklist(task)) {
            return false;
          }
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

  Future<void> _openTask(
    ChecklistCatalogItem task, {
    bool attentionOnly = false,
    String? initialSlotKey,
  }) async {
    final submission = task.submission;
    final isUtilities = _isUtilitiesChecklist(task);
    final hasIssues = attentionOnly || (submission?.issues ?? 0) > 0;
    final resumeTarget =
        !hasIssues &&
            submission != null &&
            (!submission.isSubmitted || isUtilities) &&
            (submission.effectiveAnsweredItems > 0 ||
                (submission.completionPercentage ?? 0) > 0) &&
            !_isOptionalChecklist(task)
        ? _latestResumeTarget(
            _visibleTasks
                .where((t) => !_isOptionalChecklist(t))
                .toList(growable: false),
          )
        : null;
    final target = resumeTarget ?? task;
    final targetSubmission = target.submission;
    final isContinuing =
        targetSubmission != null &&
        (!targetSubmission.isSubmitted || _isUtilitiesChecklist(target)) &&
        targetSubmission.hasStarted;
    final localNow = (widget.now ?? DateTime.now)();
    final defaultSlotKey = isContinuing
        ? checklistSlotForLocalTime(target, localNow)
        : null;
    final auditDate = _dateParameter(_selectedDate);

    String? initialItemKey;
    int? initialCustomerIndex;
    String? resolvedInitialSlotKey = initialSlotKey ?? defaultSlotKey;

    if (hasIssues) {
      try {
        final record = await _repository.fetchChecklist(
          target.slug,
          date: auditDate,
        );
        if (!mounted || auditDate != _dateParameter(_selectedDate)) return;
        final targets = checklistAttentionTargets(record, widget.user);
        if (targets.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No responses currently need review.'),
            ),
          );
          await _load(showSpinner: false);
          return;
        }
        final attention = targets.first;
        initialItemKey = attention.itemKey;
        resolvedInitialSlotKey = attention.slotKey;
        initialCustomerIndex = attention.customerIndex;
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to verify responses. Please try again.'),
          ),
        );
        return;
      }
    }

    final questionCallback = widget.onOpenChecklistWithQuestion;
    final slotCallback = widget.onOpenChecklistWithSlot;
    final callback = widget.onOpenChecklist;
    if (questionCallback != null &&
        initialCustomerIndex == null &&
        !attentionOnly) {
      await questionCallback(
        target.slug,
        auditDate,
        resolvedInitialSlotKey,
        initialItemKey,
      );
    } else if (slotCallback != null && !hasIssues) {
      try {
        await (slotCallback as dynamic)(
          target.slug,
          auditDate,
          resolvedInitialSlotKey,
          initialItemKey,
        );
      } on NoSuchMethodError {
        await slotCallback(target.slug, auditDate, resolvedInitialSlotKey);
      }
    } else if (callback != null && !hasIssues) {
      try {
        await (callback as dynamic)(target.slug, auditDate, initialItemKey);
      } on NoSuchMethodError {
        await callback(target.slug, auditDate);
      }
    } else {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => UserChecklistDetailScreen(
            slug: target.slug,
            auditDate: auditDate,
            initialSlotKey: resolvedInitialSlotKey,
            initialItemKey: initialItemKey,
            initialCustomerIndex: initialCustomerIndex,
            attentionOnly: attentionOnly,
            repository: _repository,
            user: widget.user,
            nowProvider: widget.now,
            onOpenNotifications: widget.onOpenNotifications,
            unreadNotifications: widget.unreadNotifications,
          ),
        ),
      );
    }
    if (mounted) {
      await _load(showSpinner: false);
    }
  }

  Widget _buildTrackHeader() {
    if (_is5sChecklistUser) {
      final user = widget.user;
      final String title;
      final IconData icon;
      if (user.is5sUtilities) {
        title = '5S CHECKLIST — UTILITIES';
        icon = Icons.cleaning_services_rounded;
      } else if (user.is5sSales) {
        title = '5S CHECKLIST — SALES';
        icon = Icons.storefront_rounded;
      } else if (user.is5sService) {
        title = '5S CHECKLIST — SERVICE';
        icon = Icons.car_repair_rounded;
      } else {
        title = '5S CHECKLIST — SALES & SERVICE';
        icon = Icons.fact_check_rounded;
      }

      return SliverToBoxAdapter(
        child: _buildStaticTrackHeader(title: title, icon: icon),
      );
    }

    final Widget headerContent;
    if (_canSwitchTrack) {
      headerContent = Container(
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
    } else {
      final isAftersales = _effectiveTrack == DosAuditTrack.aftersales;
      final title = isAftersales
          ? 'DEALER OPERATIONS STANDARDS — AFTERSALES'
          : 'DEALER OPERATIONS STANDARDS — SALES';
      final icon = isAftersales
          ? Icons.car_repair_rounded
          : Icons.storefront_rounded;

      headerContent = _buildStaticTrackHeader(title: title, icon: icon);
    }

    return SliverToBoxAdapter(child: headerContent);
  }

  Widget _buildStaticTrackHeader({
    required String title,
    required IconData icon,
  }) {
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

  void _handleTrackSwitch(DosAuditTrack track) {
    if (track == _effectiveTrack) return;
    if (widget.onTrackChanged != null) {
      widget.onTrackChanged!(track);
    }
    setState(() {
      _internalTrack = track;
    });
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.tasks, this.user});

  final List<ChecklistCatalogItem> tasks;
  final AuthenticatedUser? user;

  @override
  Widget build(BuildContext context) {
    final primaryDos = tasks.where(
      (t) =>
          t.slug == 'dealer-operations-standards' ||
          t.slug == 'dealer-operations-standards-sales',
    );
    final mandatoryTasks = tasks.where((t) => !_isOptionalChecklist(t));
    final countTasks = primaryDos.isNotEmpty ? primaryDos : mandatoryTasks;
    final totalMandatoryCount = primaryDos.isNotEmpty
        ? primaryDos.length
        : mandatoryTasks.length;
    final total = countTasks.fold<int>(0, (sum, task) {
      final submittedTotal = task.submission?.totalItems;
      return sum +
          ((submittedTotal != null && submittedTotal > 0)
              ? submittedTotal
              : task.totalWorkUnits);
    });
    final answered = countTasks.fold<int>(
      0,
      (sum, task) => sum + (task.submission?.answeredItems ?? 0),
    );

    final isUtilities =
        (user != null && (user!.is5sUtilities || user!.isUtilities)) ||
        (tasks.isNotEmpty && tasks.every(_isUtilitiesChecklist));

    final int completed;
    final int totalCount;
    final String countLabel;

    if (isUtilities && tasks.isNotEmpty) {
      final totalSlots = tasks.fold<int>(
        0,
        (sum, task) => sum + _totalSlotsFor(task),
      );
      final completedSlots = tasks.fold<int>(
        0,
        (sum, task) => sum + _completedSlotsFor(task),
      );
      completed = completedSlots;
      totalCount = totalSlots > 0 ? totalSlots : 9;
      countLabel = 'checklists submitted';
    } else {
      completed = countTasks
          .where((task) => _statusFor(task) == _TaskStatus.completed)
          .length;
      totalCount = totalMandatoryCount;
      countLabel = 'tasks submitted';
    }

    final issues = countTasks.fold<int>(
      0,
      (sum, task) => sum + (task.submission?.issues ?? 0),
    );
    final progress = total == 0 ? 0 : ((answered / total) * 100).round();

    return GacContentPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      shadowBlurRadius: 18,
      shadowOffset: const Offset(0, 6),
      child: Row(
        children: [
          ProgressRing(value: progress),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$answered / $total checks completed',
                  style: const TextStyle(
                    color: GacColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                _MetricLine(
                  icon: Icons.task_alt_rounded,
                  value: '$completed/$totalCount',
                  label: countLabel,
                  color: GacColors.green600,
                ),
                const SizedBox(height: 5),
                _MetricLine(
                  icon: Icons.error_outline_rounded,
                  value: '$issues',
                  label: issues == 1 ? 'reported issue' : 'reported issues',
                  color: issues > 0 ? GacColors.warning : GacColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onOpen,
    this.attentionMode = false,
  });

  final ChecklistCatalogItem task;
  final VoidCallback onOpen;
  final bool attentionMode;

  @override
  Widget build(BuildContext context) {
    final isOptional = _isOptionalChecklist(task);
    final status = _statusFor(task);
    final isDone = status == _TaskStatus.completed;
    final cardColor = attentionMode
        ? GacColors.warning
        : isOptional && !isDone
        ? const Color(0xFF06B6D4)
        : _statusColor(status);
    final submission = task.submission;
    final total = (submission?.totalItems ?? 0) > 0
        ? submission!.totalItems!
        : task.totalWorkUnits;
    final answered = submission?.answeredItems ?? 0;
    final progress =
        submission?.completionPercentage?.round() ??
        (total == 0 ? 0 : ((answered / total) * 100).round());
    final issues = submission?.issues ?? 0;

    return GacContentPanel(
      borderRadius: 18,
      shadowBlurRadius: 18,
      shadowOffset: const Offset(0, 6),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        attentionMode
                            ? Icons.error_outline_rounded
                            : isOptional
                            ? Icons.description_rounded
                            : (task.slug == 'restroom' ||
                                      task.slug.startsWith('restroom')
                                  ? Icons.wc_rounded
                                  : Icons.fact_check_outlined),
                        color: cardColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: const TextStyle(
                              color: GacColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _scheduleLabel(task),
                            style: const TextStyle(
                              color: GacColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (attentionMode)
                      const _AttentionBadge()
                    else
                      _StatusBadge(status: status, isOptional: isOptional),
                  ],
                ),
                if (task.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 11),
                  Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GacColors.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 13),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 100) / 100,
                    minHeight: 7,
                    backgroundColor: const Color(0xFF153A56),
                    color: cardColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$answered of $total checks · $progress%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: GacColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (issues > 0)
                      Text(
                        '$issues ${issues == 1 ? 'issue' : 'issues'}',
                        style: const TextStyle(
                          color: GacColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      attentionMode ? 'REVIEW' : _actionLabel(status, task),
                      style: const TextStyle(
                        color: GacColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: GacColors.primary,
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IssueSummary extends StatelessWidget {
  const _IssueSummary({required this.tasks, required this.onOpen});

  final List<ChecklistCatalogItem> tasks;
  final ValueChanged<ChecklistCatalogItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final affected = tasks
        .where((task) => (task.submission?.issues ?? 0) > 0)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < affected.length; index++) ...[
          _TaskCard(
            task: affected[index],
            attentionMode: true,
            onOpen: () => onOpen(affected[index]),
          ),
          if (index != affected.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CalendarButton extends StatelessWidget {
  const _CalendarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open calendar to select date',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: GacColors.cardSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GacColors.cardBorder),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: GacColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.weekAnchor,
    required this.onMonthBack,
    required this.onMonthForward,
    required this.onWeekBack,
    required this.onWeekForward,
    required this.onPickDate,
    this.canMonthForward = true,
    this.canWeekForward = true,
  });

  final DateTime weekAnchor;
  final VoidCallback onMonthBack;
  final VoidCallback? onMonthForward;
  final VoidCallback onWeekBack;
  final VoidCallback? onWeekForward;
  final VoidCallback onPickDate;
  final bool canMonthForward;
  final bool canWeekForward;

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        '${_longMonths[weekAnchor.month - 1]} ${weekAnchor.year}';

    return Row(
      children: [
        _NavArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: onMonthBack,
          tooltip: 'Previous month',
        ),
        Flexible(
          child: GestureDetector(
            onTap: onPickDate,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      monthLabel,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: GacColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: GacColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        _NavArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: canMonthForward ? onMonthForward : null,
          tooltip: 'Next month',
          enabled: canMonthForward,
        ),
        const Spacer(),
        _NavArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: onWeekBack,
          tooltip: 'Previous week',
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'Week',
            style: TextStyle(
              color: GacColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _NavArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: canWeekForward ? onWeekForward : null,
          tooltip: 'Next week',
          enabled: canWeekForward,
        ),
      ],
    );
  }
}

class _NavArrowButton extends StatelessWidget {
  const _NavArrowButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? GacColors.textSecondary
        : GacColors.textMuted.withValues(alpha: 0.25);

    return Tooltip(
      message: enabled ? tooltip : '',
      child: Semantics(
        button: enabled,
        enabled: enabled,
        label: enabled ? tooltip : '$tooltip (disabled)',
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, color: effectiveColor, size: 20),
          ),
        ),
      ),
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Go to today',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: GacColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: const Text(
            'Today',
            style: TextStyle(
              color: GacColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.days,
    required this.selectedDate,
    required this.onChanged,
    required this.maxDate,
  });

  final List<DateTime> days;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;
  final DateTime maxDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < days.length; index++) ...[
          if (index > 0) const SizedBox(width: 5),
          Expanded(
            child: _DateButton(
              date: days[index],
              selected: DateUtils.isSameDay(days[index], selectedDate),
              disabled: days[index].isAfter(maxDate),
              onTap: days[index].isAfter(maxDate)
                  ? null
                  : () => onChanged(days[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.date,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final textColor = disabled
        ? GacColors.textMuted.withValues(alpha: 0.3)
        : (selected ? GacColors.white : GacColors.textPrimary);
    final secondary = disabled
        ? GacColors.textMuted.withValues(alpha: 0.2)
        : (selected ? const Color(0xCCFFFFFF) : GacColors.textSecondary);

    final backgroundColor = disabled
        ? GacColors.cardSurface.withValues(alpha: 0.35)
        : (selected ? GacColors.primary : GacColors.cardSurface);

    final borderColor = disabled
        ? GacColors.cardBorder.withValues(alpha: 0.25)
        : (selected ? GacColors.primary : GacColors.cardBorder);

    return Semantics(
      key: ValueKey<String>('home-date-${_dateParameter(date)}'),
      button: !disabled,
      enabled: !disabled,
      selected: selected,
      label: disabled ? '${_longDate(date)} (future date)' : _longDate(date),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onTap,
            child: SizedBox(
              height: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _shortMonths[date.month - 1],
                    style: TextStyle(
                      color: secondary,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _shortWeekdays[date.weekday - 1],
                    style: TextStyle(
                      color: secondary,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final countUnit = label == 'Attention needed'
        ? (count == 1 ? 'issue' : 'issues')
        : (count == 1 ? 'task' : 'tasks');
    return Semantics(
      button: true,
      selected: selected,
      label: 'Filter $label, $count $countUnit',
      child: Container(
        decoration: BoxDecoration(
          color: selected ? GacColors.primary : GacColors.cardSurface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? GacColors.primary : GacColors.cardBorder,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Text(
                '$label · $count',
                style: TextStyle(
                  color: selected ? GacColors.white : GacColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.isOptional = false});

  final _TaskStatus status;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    final showOptional = isOptional && status != _TaskStatus.completed;
    final color = showOptional ? const Color(0xFF06B6D4) : _statusColor(status);
    final label = showOptional
        ? 'OPTIONAL'
        : _statusLabel(status).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.45,
        ),
      ),
    );
  }
}

class _AttentionBadge extends StatelessWidget {
  const _AttentionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: GacColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'ATTENTION NEEDED',
        style: TextStyle(
          color: GacColors.warning,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.45,
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          '$value ',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: GacColors.steel,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const GacContentPanel(
      height: 170,
      borderRadius: 18,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Syncing your assigned tasks…',
            style: TextStyle(
              color: GacColors.steel,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function({bool showSpinner}) onRetry;

  @override
  Widget build(BuildContext context) {
    return GacContentPanel(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: GacColors.primary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GacColors.steel,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => onRetry(showSpinner: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.hasAssignments,
    this.isAttentionFilter = false,
    this.attentionUnavailable = false,
  });

  final bool hasAssignments;
  final bool isAttentionFilter;
  final bool attentionUnavailable;

  @override
  Widget build(BuildContext context) {
    final message = isAttentionFilter
        ? (attentionUnavailable
              ? 'Attention items could not be fully verified. Please refresh.'
              : 'No checklists currently need attention.')
        : (hasAssignments
              ? 'No tasks match this status.'
              : 'No tasks are assigned for this date.');
    final icon = isAttentionFilter
        ? (attentionUnavailable
              ? Icons.refresh_rounded
              : Icons.check_circle_outline_rounded)
        : (hasAssignments
              ? Icons.filter_alt_off_rounded
              : Icons.assignment_turned_in_outlined);

    return GacContentPanel(
      padding: const EdgeInsets.all(24),
      borderRadius: 18,
      child: Column(
        children: [
          Icon(
            icon,
            color: isAttentionFilter ? GacColors.green600 : GacColors.slate,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GacColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.value, required this.strokeWidth});

  final double value;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.max(
      0.0,
      (math.min(size.width, size.height) - strokeWidth) / 2,
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = const Color(0xFF153A56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final progress = Paint()
      ..color = GacColors.primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, track);
    if (value > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, progress);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.strokeWidth != strokeWidth;
}

class _HomeTopBarDelegate extends SliverPersistentHeaderDelegate {
  const _HomeTopBarDelegate({
    required this.expanded,
    required this.onOpenProfile,
    required this.onOpenHome,
    required this.onOpenNotifications,
    required this.user,
    required this.unreadNotifications,
  });

  final bool expanded;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenNotifications;
  final AuthenticatedUser user;
  final int unreadNotifications;

  @override
  double get maxExtent => UserFloatingHeader.extent;

  @override
  double get minExtent => UserFloatingHeader.extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return UserFloatingHeader(
      expanded: expanded,
      onOpenProfile: onOpenProfile,
      onOpenHome: onOpenHome,
      onOpenNotifications: onOpenNotifications,
      user: user,
      unreadNotifications: unreadNotifications,
    );
  }

  @override
  bool shouldRebuild(covariant _HomeTopBarDelegate oldDelegate) =>
      oldDelegate.expanded != expanded ||
      oldDelegate.user != user ||
      oldDelegate.unreadNotifications != unreadNotifications ||
      oldDelegate.onOpenProfile != onOpenProfile ||
      oldDelegate.onOpenHome != onOpenHome ||
      oldDelegate.onOpenNotifications != onOpenNotifications;
}

bool _isOptionalChecklist(ChecklistCatalogItem task) {
  return task.slug == 'dealer-operations-standards-documentation';
}

bool _isUtilitiesChecklist(ChecklistCatalogItem task) {
  return task.slug == 'restroom' ||
      task.slug.startsWith('restroom') ||
      task.slug == 'utilities' ||
      task.settings['validation_mode'] == 'time_slots' ||
      task.categoryLabel == 'UTILITIES';
}

int _totalSlotsFor(ChecklistCatalogItem task) {
  final rawSlots = task.settings['time_slots'];
  if (rawSlots is List && rawSlots.isNotEmpty) {
    return rawSlots.length;
  }
  return UtilitiesMissedChecklistService.defaultUtilitiesSlots.length;
}

int _completedSlotsFor(ChecklistCatalogItem task) {
  final submission = task.submission;
  if (submission == null) return 0;
  final totalSlots = _totalSlotsFor(task);

  final scores = submission.scores;
  if (scores['completed_slots'] is int) {
    return (scores['completed_slots'] as int).clamp(0, totalSlots);
  }
  final answered = submission.effectiveAnsweredItems;
  if (task.itemCount > 0 && answered > 0) {
    return (answered / task.itemCount).floor().clamp(0, totalSlots);
  }
  if (submission.isSubmitted) return totalSlots;
  return 0;
}

bool _isUtilitiesAllFinished(ChecklistCatalogItem task) {
  final totalSlots = _totalSlotsFor(task);
  final completedSlots = _completedSlotsFor(task);
  return completedSlots >= totalSlots && totalSlots > 0;
}

_TaskStatus _statusFor(ChecklistCatalogItem task) {
  final submission = task.submission;
  if (submission == null) {
    return _TaskStatus.todo;
  }

  // Each submitted Utilities time slot advances the single daily checklist.
  if (_isUtilitiesChecklist(task)) {
    if (_isUtilitiesAllFinished(task)) {
      return _TaskStatus.completed;
    }
    if (_completedSlotsFor(task) > 0 || submission.hasStarted) {
      return _TaskStatus.inProgress;
    }
    return _TaskStatus.todo;
  }

  final status = submission.status.trim().toLowerCase();
  if (submission.isSubmitted ||
      status == 'submitted' ||
      status == 'completed') {
    return _TaskStatus.completed;
  }
  if (submission.hasStarted) {
    return _TaskStatus.inProgress;
  }
  return _TaskStatus.todo;
}

String _filterLabel(_TaskFilter filter) => switch (filter) {
  _TaskFilter.all => 'All',
  _TaskFilter.inProgress => 'In progress',
  _TaskFilter.attention => 'Attention needed',
};

String _statusLabel(_TaskStatus status) => switch (status) {
  _TaskStatus.todo => 'To do',
  _TaskStatus.inProgress => 'In progress',
  _TaskStatus.completed => 'Completed',
};

String _actionLabel(_TaskStatus status, [ChecklistCatalogItem? task]) {
  if (task != null &&
      (task.submission?.hasStarted ?? false) &&
      status != _TaskStatus.completed) {
    return 'CONTINUE';
  }
  return switch (status) {
    _TaskStatus.todo => 'START',
    _TaskStatus.inProgress => 'CONTINUE',
    _TaskStatus.completed => 'VIEW',
  };
}

Color _statusColor(_TaskStatus status) => switch (status) {
  _TaskStatus.todo => GacColors.amber600,
  _TaskStatus.inProgress => GacColors.blue,
  _TaskStatus.completed => GacColors.green600,
};

String _scheduleLabel(ChecklistCatalogItem task) {
  if (_isOptionalChecklist(task)) {
    return 'Optional compliance checklist';
  }

  final schedule = task.settings['schedule'];
  if (schedule is Map) {
    final end = schedule['end'];
    if (end is String && RegExp(r'^\d{2}:\d{2}$').hasMatch(end)) {
      final parts = end.split(':');
      final hour = int.tryParse(parts[0]);
      if (hour != null) {
        final suffix = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour % 12 == 0 ? 12 : hour % 12;
        return 'Due by $displayHour:${parts[1]} $suffix';
      }
    }
  }

  return _isUtilitiesChecklist(task)
      ? 'Scheduled assigned inspection'
      : 'Daily assigned checklist';
}

String _dateParameter(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _longDate(DateTime date) =>
    '${_longMonths[date.month - 1]} ${date.day}, ${date.year}';

const _shortMonths = <String>[
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

const _longMonths = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _shortWeekdays = <String>[
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
  'SUN',
];
