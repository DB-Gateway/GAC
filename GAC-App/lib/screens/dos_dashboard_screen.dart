import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/admin_data.dart';
import '../models/authenticated_user.dart';
import '../models/checklist_models.dart';
import '../services/checklist_service.dart';
import '../theme/gac_theme.dart';
import '../widgets/gac_surfaces.dart';
import '../widgets/user_avatar.dart';
import 'user_checklist_detail_screen.dart';

/// Available DOS Audit Tracks: Aftersales (75 standards) or Sales (90 standards).
enum DosAuditTrack { aftersales, sales }

class DosDashboardScreen extends StatefulWidget {
  const DosDashboardScreen({
    this.user = AuthenticatedUser.fallback,
    this.repository,
    this.initialTrack,
    this.onTrackChanged,
    this.onOpenAudit,
    this.onOpenAuditWithSlug,
    this.onOpen5S,
    this.onOpenProfile,
    this.onOpenNotifications,
    this.unreadNotifications = 0,
    super.key,
  });

  final AuthenticatedUser user;
  final ChecklistRepository? repository;
  final DosAuditTrack? initialTrack;
  final ValueChanged<DosAuditTrack>? onTrackChanged;
  final VoidCallback? onOpenAudit;
  final ValueChanged<String>? onOpenAuditWithSlug;
  final VoidCallback? onOpen5S;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotifications;
  final int unreadNotifications;

  @override
  State<DosDashboardScreen> createState() => _DosDashboardScreenState();
}

class _DosDashboardScreenState extends State<DosDashboardScreen> {
  late DosAuditTrack _activeTrack;
  String _selectedChecker = 'ALL';
  late final ChecklistRepository _repository;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  String? _error;
  ChecklistLoadResult? _dosRecord;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ChecklistApiService();
    if (widget.user.isDosSales) {
      _activeTrack = DosAuditTrack.sales;
      _selectedChecker = 'SALES MANAGER';
    } else if (widget.user.isDosAftersales) {
      _activeTrack = DosAuditTrack.aftersales;
      _selectedChecker = widget.user.dosCheckerCode ?? 'ALL';
    } else if (widget.initialTrack != null) {
      _activeTrack = widget.initialTrack!;
      _selectedChecker = 'ALL';
    } else {
      _activeTrack = DosAuditTrack.aftersales;
      _selectedChecker = 'ALL';
    }
    _load();
  }

  @override
  void didUpdateWidget(DosDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.userType != oldWidget.user.userType) {
      if (widget.user.isDosAftersales) {
        _activeTrack = DosAuditTrack.aftersales;
        _selectedChecker = widget.user.dosCheckerCode ?? 'ALL';
        _load();
      } else if (widget.user.isDosSales) {
        _activeTrack = DosAuditTrack.sales;
        _selectedChecker = 'SALES MANAGER';
        _load();
      }
    } else if (widget.initialTrack != null &&
        widget.initialTrack != oldWidget.initialTrack) {
      _activeTrack = widget.initialTrack!;
      _load();
    }
  }

  bool get _isAftersales => _activeTrack == DosAuditTrack.aftersales;

  String get _currentAuditSlug => _isAftersales
      ? 'dealer-operations-standards'
      : 'dealer-operations-standards-sales';

  List<ChecklistSection> get _activeTemplate =>
      _isAftersales ? dosAftersalesTemplate : dosTemplate;

  bool _matchesChecker(String? itemChecker, String filter) {
    if (filter == 'ALL') return true;
    return canonicalDosChecker(itemChecker) == canonicalDosChecker(filter);
  }

  List<String> get _checkerFilters {
    if (widget.user.isAdmin) {
      if (!_isAftersales) {
        return const ['ALL', 'SALES MANAGER'];
      }
      return const ['ALL', 'ASM', 'CE SERVICE', 'PARTS', 'JC', 'WS SUP'];
    }

    if (widget.user.isDosSales) {
      return const ['SALES MANAGER'];
    }

    final code = widget.user.dosCheckerCode;
    if (code != null) {
      if (widget.user.isAftersalesManager) {
        return const ['ASM', 'ALL'];
      }
      return [code];
    }

    return const ['ALL'];
  }

  String _checkerFilterLabel(String filter) {
    if (!_isAftersales) {
      return filter == 'ALL' ? 'ALL (90)' : 'SALES MANAGER (90)';
    }
    return switch (filter) {
      'ALL' => 'ALL (75)',
      'ASM' => 'ASM (50)',
      'CE SERVICE' => 'CE SERVICE (9)',
      'PARTS' => 'PARTS (3)',
      'JC' => 'JC (1)',
      'WS SUP' => 'WS SUP (12)',
      _ => filter,
    };
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final dateStr =
          '${_selectedDate.year.toString().padLeft(4, '0')}-'
          '${_selectedDate.month.toString().padLeft(2, '0')}-'
          '${_selectedDate.day.toString().padLeft(2, '0')}';

      final record = await _repository.fetchChecklist(
        _currentAuditSlug,
        date: dateStr,
      );
      if (!mounted) return;
      setState(() {
        _dosRecord = record;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to refresh DOS audit standards.';
      });
    }
  }

  void _switchTrack(DosAuditTrack track) {
    if (!widget.user.isAdmin) {
      if (widget.user.isDosSales && track != DosAuditTrack.sales) return;
      if (widget.user.isDosAftersales && track != DosAuditTrack.aftersales) {
        return;
      }
    }
    if (track == _activeTrack) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeTrack = track;
      _selectedChecker = widget.user.dosCheckerCode ?? 'ALL';
    });
    widget.onTrackChanged?.call(track);
    _load();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _load();
    }
  }

  void _openAuditSheet([String? slugOverride]) {
    final slug = slugOverride ?? _currentAuditSlug;
    if (widget.onOpenAuditWithSlug != null) {
      widget.onOpenAuditWithSlug!(slug);
      return;
    }
    if (slugOverride == null && widget.onOpenAudit != null) {
      widget.onOpenAudit!();
      return;
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => UserChecklistDetailScreen(
              slug: slug,
              repository: _repository,
              user: widget.user,
              onOpenNotifications: widget.onOpenNotifications,
              unreadNotifications: widget.unreadNotifications,
              auditDate:
                  '${_selectedDate.year.toString().padLeft(4, '0')}-'
                  '${_selectedDate.month.toString().padLeft(2, '0')}-'
                  '${_selectedDate.day.toString().padLeft(2, '0')}',
            ),
          ),
        )
        .then((_) => _load(showSpinner: false));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: GacColors.canvas,
        systemNavigationBarColor: GacColors.canvas,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GacScreenBackground(
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () => _load(showSpinner: false),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 16),
                              _buildComplianceTypeSwitcher(),
                              const SizedBox(height: 12),
                              _buildDosTrackSelector(),
                              const SizedBox(height: 14),
                              _buildCheckerFilterBar(),
                              const SizedBox(height: 16),
                              if (_loading && _dosRecord == null) ...[
                                const SizedBox(height: 60),
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: GacColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 60),
                              ] else ...[
                                if (_error != null && _dosRecord == null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: GacColors.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: GacColors.error.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: GacColors.error,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              color: GacColors.textPrimary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                _buildAuditBanner(),
                                const SizedBox(height: 16),
                                _buildOverallComplianceCard(),
                                const SizedBox(height: 16),
                                _buildCategoryBreakdown(),
                                const SizedBox(height: 20),
                                _buildSectionHeader(
                                  'COVERAGE & SUBJECT BREAKDOWN',
                                ),
                                const SizedBox(height: 10),
                                _buildCoverageCards(),
                                if (!widget.user.isDosSales &&
                                    !widget.user.isDosAftersales) ...[
                                  const SizedBox(height: 20),
                                  _buildSectionHeader(
                                    'ESCALATION & ACTION CENTER',
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEscalationCenter(),
                                ],
                                const SizedBox(height: 24),
                                _buildLaunchAuditButton(),
                              ],
                            ],
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
    );
  }

  Widget _buildHeader() {
    final roleBadge = widget.user.isAftersalesManager
        ? 'AFTERSALES MANAGER'
        : widget.user.isAftersalesChecker
        ? widget.user.roleLabel.toUpperCase()
        : widget.user.isDosSales
        ? 'SALES MANAGER'
        : widget.user.userType.toUpperCase();

    final userName = widget.user.name.isEmpty
        ? (_isAftersales ? 'Aftersales Manager' : 'Sales Manager')
        : widget.user.name;

    return Row(
      children: [
        GestureDetector(
          onTap: widget.onOpenProfile,
          child: UserAvatar(
            user: widget.user,
            size: 46,
            borderColor: GacColors.white,
            borderWidth: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        color: GacColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: GacColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x662979FF)),
                    ),
                    child: Text(
                      roleBadge,
                      style: const TextStyle(
                        color: GacColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${widget.user.branch ?? 'Gateway Dealership'} · DOS Auditor',
                style: const TextStyle(
                  color: GacColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (widget.onOpenNotifications != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: widget.onOpenNotifications,
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: GacColors.textPrimary,
                  size: 22,
                ),
              ),
              if (widget.unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: GacColors.brandRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildComplianceTypeSwitcher() {
    return GacGlassSurface(
      padding: const EdgeInsets.all(4),
      borderRadius: 14,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: GacColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x402979FF),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        color: Colors.white,
                        size: 15,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'DOS COMPLIANCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.onOpen5S,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          color: GacColors.textMuted,
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '5S COMPLIANCE',
                          style: TextStyle(
                            color: GacColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
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
      ),
    );
  }

  Widget _buildDosTrackSelector() {
    if (!widget.user.isAdmin &&
        (widget.user.isDosSales || widget.user.isDosAftersales)) {
      final title = _isAftersales
          ? 'DEALER OPERATIONS STANDARDS — AFTERSALES'
          : 'DEALER OPERATIONS STANDARDS — SALES';
      final icon = _isAftersales
          ? Icons.car_repair_rounded
          : Icons.storefront_rounded;
      return GacGlassSurface(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 14,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: GacColors.primary, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: GacColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return GacGlassSurface(
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
    );
  }

  Widget _buildTrackPill({
    required DosAuditTrack track,
    required String title,
    required IconData icon,
  }) {
    final active = _activeTrack == track;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _switchTrack(track),
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
                  color: active ? GacColors.primary : GacColors.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: active ? GacColors.primary : GacColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckerFilterBar() {
    final filters = _checkerFilters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'FILTER BY CHECKER ROLE',
              style: TextStyle(
                color: GacColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            if (_selectedChecker != 'ALL')
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedChecker = 'ALL');
                },
                child: const Text(
                  'Reset to All',
                  style: TextStyle(
                    color: GacColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final filter in filters) ...[
                _buildCheckerChip(filter),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckerChip(String filter) {
    final active = _selectedChecker == filter;
    final label = _checkerFilterLabel(filter);

    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedChecker = filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? GacColors.primary : GacColors.cardSurface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? GacColors.primary : GacColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? GacColors.white : GacColors.textSecondary,
            fontSize: 10,
            fontWeight: active ? FontWeight.w900 : FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildAuditBanner() {
    final title = _isAftersales
        ? 'Aftersales Standards Compliance Audit (FY25)'
        : 'Sales Standards Compliance Audit (REV02)';
    final subtitle = _isAftersales
        ? '75 Standards · 15 Coverages · 5 Checker Roles'
        : 'Checker: Sales Manager · 90 Standards';
    final icon = _isAftersales
        ? Icons.car_repair_rounded
        : Icons.assignment_turned_in_outlined;

    return GacContentPanel(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x242979FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x402979FF)),
            ),
            child: Icon(icon, color: GacColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEALER OPERATION STANDARDS',
                  style: TextStyle(
                    color: GacColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: GacColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: GacColors.textMuted.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x1F249D6B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x40249D6B)),
              ),
              child: const Text(
                'ACTIVE',
                style: TextStyle(
                  color: GacColors.green400,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallComplianceCard() {
    final submission = _dosRecord?.submission;

    final int totalStandards;
    if (_selectedChecker == 'ALL') {
      totalStandards = _isAftersales ? 75 : 90;
    } else {
      final filtered = _activeTemplate
          .expand((s) => s.items)
          .where((i) => _matchesChecker(i.checker, _selectedChecker))
          .length;
      totalStandards = filtered > 0 ? filtered : (_isAftersales ? 75 : 90);
    }

    final int answered;
    final int issues;
    if (_selectedChecker == 'ALL' && submission != null) {
      answered = (submission.answeredItems ?? (_isAftersales ? 71 : 87)).clamp(
        0,
        totalStandards,
      );
      issues = submission.issues.clamp(0, answered);
    } else {
      final defaultAnswered = _isAftersales
          ? (_selectedChecker == 'ALL' ? 71 : (totalStandards * 0.95).round())
          : 87;
      answered = defaultAnswered.clamp(0, totalStandards);
      issues = (_isAftersales ? 4 : 2).clamp(0, answered);
    }

    final compliantYes = (answered - issues).clamp(0, totalStandards);
    final completionPct = totalStandards == 0
        ? 0
        : ((answered / totalStandards) * 100).round();
    final compliancePct = answered == 0
        ? 0
        : (((compliantYes) / answered) * 100).round();

    return GacContentPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      shadowBlurRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selectedChecker == 'ALL'
                      ? 'COMPLIANCE SCORECARD'
                      : 'SCORECARD · ${_selectedChecker.toUpperCase()}',
                  style: const TextStyle(
                    color: GacColors.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: compliancePct >= 80
                      ? const Color(0x1F249D6B)
                      : const Color(0x1FE71D48),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: compliancePct >= 80
                        ? const Color(0x40249D6B)
                        : const Color(0x40E71D48),
                  ),
                ),
                child: Text(
                  compliancePct >= 80 ? 'PASSING (≥80%)' : 'ACTION REQUIRED',
                  style: TextStyle(
                    color: compliancePct >= 80
                        ? GacColors.green400
                        : GacColors.brandRed,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 86,
                height: 86,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: compliancePct / 100,
                      strokeWidth: 8,
                      backgroundColor: GacColors.cardBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        compliancePct >= 80
                            ? GacColors.green400
                            : GacColors.brandRed,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$compliancePct%',
                            style: const TextStyle(
                              color: GacColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'SCORE',
                            style: TextStyle(
                              color: GacColors.textMuted,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildJudgementRow(
                      'YES (Compliant)',
                      '$compliantYes',
                      GacColors.green400,
                    ),
                    const SizedBox(height: 6),
                    _buildJudgementRow(
                      'NO (Findings / Defect)',
                      '$issues',
                      GacColors.brandRed,
                    ),
                    const SizedBox(height: 6),
                    _buildJudgementRow(
                      'N/A (Not Applicable)',
                      '${(totalStandards - answered).clamp(0, totalStandards)}',
                      GacColors.amber400,
                    ),
                    const SizedBox(height: 6),
                    _buildJudgementRow(
                      'Audit Completion',
                      '$completionPct%',
                      GacColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJudgementRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: GacColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    final int basicTotal = _isAftersales ? 8 : 14;
    final int basicCompliant = _isAftersales ? 8 : 13;
    final int standardTotal = _isAftersales ? 63 : 66;
    final int standardCompliant = _isAftersales ? 56 : 65;
    final int beyondTotal = _isAftersales ? 4 : 10;
    final int beyondCompliant = _isAftersales ? 4 : 10;

    return GacGlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'STANDARDS CATEGORY COMPLIANCE',
                  style: TextStyle(
                    color: GacColors.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'TARGETS',
                style: TextStyle(
                  color: GacColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCategoryMeter(
            title: 'BASIC',
            target: '100% Required',
            total: basicTotal,
            compliant: basicCompliant,
            accentColor: GacColors.cyan,
          ),
          const SizedBox(height: 12),
          _buildCategoryMeter(
            title: 'STANDARD',
            target: '80% Required',
            total: standardTotal,
            compliant: standardCompliant,
            accentColor: GacColors.primary,
          ),
          const SizedBox(height: 12),
          _buildCategoryMeter(
            title: 'BEYOND',
            target: 'Bonus Excellence',
            total: beyondTotal,
            compliant: beyondCompliant,
            accentColor: GacColors.amber400,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryMeter({
    required String title,
    required String target,
    required int total,
    required int compliant,
    required Color accentColor,
  }) {
    final pct = total == 0 ? 0.0 : (compliant / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$compliant / $total compliant',
                      style: const TextStyle(
                        color: GacColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              target,
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: GacColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: GacColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildCoverageCards() {
    if (!_isAftersales) {
      final items = _activeTemplate
          .expand((section) => section.items)
          .where((item) => _matchesChecker(item.checker, _selectedChecker));
      final itemsByCoverage = <String, List<ChecklistItem>>{};
      for (final item in items) {
        final coverage = item.coverage?.trim();
        if (coverage == null || coverage.isEmpty) continue;
        itemsByCoverage.putIfAbsent(coverage, () => []).add(item);
      }

      final coverages = itemsByCoverage.entries.toList(growable: false);
      return Column(
        children: [
          for (final (index, entry) in coverages.indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            _buildCoverageCard(
              coverage: entry.key.toUpperCase(),
              subjects: _salesSubjects(entry.value),
              icon: _salesCoverageIcon(entry.key),
              color: _salesCoverageColor(index),
            ),
          ],
        ],
      );
    }

    // 15 Aftersales Coverages
    final cards = <_CoverageDefinition>[
      const _CoverageDefinition(
        coverage: 'Facilities',
        icon: Icons.storefront_outlined,
        color: GacColors.primary,
        checkers: {'JC', 'PARTS', 'WS SUP', 'ASM'},
        subjects: [
          _SubjectMeta('Dedicated Appointment and Walk-In Bay', 1, 'JC check'),
          _SubjectMeta('Parts 5S', 1, 'Parts Supervisor check'),
          _SubjectMeta('Workshop Maintenance', 1, 'Workshop Supervisor check'),
          _SubjectMeta(
            'Storage & Workshop Rooms (7)',
            7,
            'WS SUP inspections: tools, oil, scrap',
          ),
          _SubjectMeta('Employee Facilities & Meeting', 1, 'WS SUP check'),
          _SubjectMeta('5S Checklists Accomplished', 1, 'ASM verification'),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Personalized Customer Reception',
        icon: Icons.handshake_outlined,
        color: Color(0xFF8B5CF6),
        checkers: {'ASM'},
        subjects: [
          _SubjectMeta('Queuing system', 1, 'ASM audit'),
          _SubjectMeta('Peak hours', 1, 'ASM audit'),
          _SubjectMeta(
            'Walk Around Inspection',
            1,
            'SA walk-around tablet checklist',
          ),
          _SubjectMeta(
            'Protective Covers',
            1,
            'Steering, seat, shift, handbrake, mat',
          ),
          _SubjectMeta('Vehicle Status Tag & Direct Reception', 2, 'ASM audit'),
          _SubjectMeta(
            'Workshop Driveway & Service Reception Area',
            2,
            'Entrance clearance & subform',
          ),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Customer Care and Communication',
        icon: Icons.support_agent_rounded,
        color: Color(0xFFEC4899),
        checkers: {'ASM'},
        subjects: [
          _SubjectMeta(
            "Customers' Lounge & Amenities",
            2,
            'Subform checklist & lounge comfort',
          ),
          _SubjectMeta(
            'CRM Requirements & Status Monitor',
            1,
            'Vehicle status monitor display',
          ),
          _SubjectMeta(
            'Shuttle Service & Sales Contact',
            2,
            'Shuttle offer & salesperson duty',
          ),
          _SubjectMeta(
            'Service Advisor & Customer Information Sheet',
            2,
            'Care protocol & CIS update',
          ),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Customer Appointment',
        icon: Icons.calendar_month_rounded,
        color: Color(0xFFF59E0B),
        checkers: {'CE SERVICE'},
        subjects: [
          _SubjectMeta(
            'Blocking of SA for Walk-In customer',
            1,
            'CE Service audit',
          ),
          _SubjectMeta('SA assignment', 1, 'CE Service audit'),
          _SubjectMeta('Reconfirmation Call', 1, 'Pre-day confirmation check'),
          _SubjectMeta(
            'Appointment Welcome Board',
            1,
            'Complete 6-point details',
          ),
          _SubjectMeta(
            'Pre-sharing Appointment List',
            1,
            'Shared 1 day before appointment',
          ),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Workshop Scheduling',
        icon: Icons.schedule_rounded,
        color: Color(0xFF10B981),
        checkers: {'ASM', 'WS SUP'},
        subjects: [
          _SubjectMeta(
            'Job Progress Monitoring',
            2,
            'JPM board & promise time check',
          ),
          _SubjectMeta('Carwash Control Board', 1, 'Queue and wash tracking'),
          _SubjectMeta(
            'Technicians Clock-In',
            1,
            'Time recording & SIU pacing',
          ),
          _SubjectMeta('Repair Scheduling', 1, 'Lead time adherence'),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Manpower',
        icon: Icons.groups_rounded,
        color: Color(0xFF06B6D4),
        checkers: {'ASM'},
        subjects: [
          _SubjectMeta('Manpower Count', 1, 'NTD latest submission check'),
          _SubjectMeta(
            'Training Requirements',
            2,
            'Training PIC & CRD accreditation',
          ),
          _SubjectMeta(
            'Customer Relations Department',
            1,
            'Count based on MMPC standard',
          ),
          _SubjectMeta(
            "Employees' Uniform",
            1,
            'Neat dress & prescribed uniform',
          ),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Customer Information and Car Return',
        icon: Icons.assignment_return_outlined,
        color: Color(0xFF6366F1),
        checkers: {'ASM', 'WS SUP'},
        subjects: [
          _SubjectMeta('Actual Cost', 1, 'Agreed RO & quoted price check'),
          _SubjectMeta('Replaced Parts', 1, 'Shown to customer on delivery'),
          _SubjectMeta('QVOC Reminder', 1, 'SA reminder to customer'),
          _SubjectMeta(
            'Removal of Protective Cover',
            1,
            'Removed in customer presence',
          ),
          _SubjectMeta(
            'Follow-Up Call Notice',
            1,
            'Notice of 3-day CRO follow-up',
          ),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Concern Prevention and Resolution',
        icon: Icons.report_problem_outlined,
        color: Color(0xFFEF4444),
        checkers: {'ASM'},
        subjects: [
          _SubjectMeta(
            'Weekly Meeting (MAM)',
            4,
            'Actions, boards, suggestions, 19 KPIs',
          ),
          _SubjectMeta(
            'Daily Meeting (MOM)',
            1,
            'Daily workshop alignment meeting',
          ),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Repair Order Processing and Quality of Work',
        icon: Icons.build_circle_outlined,
        color: Color(0xFF14B8A6),
        checkers: {'WS SUP', 'ASM'},
        subjects: [
          _SubjectMeta('Vehicle Status Tag', 1, 'WS SUP check'),
          _SubjectMeta('Unapproved Job Protocol', 1, 'ASM check'),
          _SubjectMeta('Repair Execution & Quality', 1, 'WS SUP check'),
          _SubjectMeta('Mitsubishi Quick Service', 1, 'WS SUP audit'),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Systems',
        icon: Icons.devices_rounded,
        color: Color(0xFF3B82F6),
        checkers: {'ASM'},
        subjects: [
          _SubjectMeta(
            'Otoleap Booking Management',
            1,
            'No pending bookings >24h',
          ),
          _SubjectMeta(
            'CRM Tablets & High-Speed WiFi',
            2,
            '1 tablet per SA & Ookla speed',
          ),
          _SubjectMeta(
            'Service Documents Management',
            1,
            'Digital & physical files',
          ),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Repair Order Completion and Invoicing',
        icon: Icons.receipt_long_outlined,
        color: Color(0xFFA855F7),
        checkers: {'ASM'},
        subjects: [
          _SubjectMeta(
            'Vehicle Status Tag Completion',
            1,
            'Updated upon repair finish',
          ),
          _SubjectMeta(
            'On-Time Delivery Verification',
            1,
            'Actual vs promised time',
          ),
          _SubjectMeta(
            'Car Return Cleanliness Check',
            1,
            'Check for clean handover',
          ),
          _SubjectMeta(
            'Repair Invoicing Accuracy',
            1,
            'Match with estimate & parts',
          ),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Customer After Service Contact',
        icon: Icons.phone_callback_rounded,
        color: Color(0xFFF97316),
        checkers: {'ASM', 'CE SERVICE'},
        subjects: [
          _SubjectMeta('3-Day Follow-Up Call', 1, 'ASM audit'),
          _SubjectMeta(
            'Complaint Monitoring Tracking Report',
            2,
            'CE Service & ASM review',
          ),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Pro-active Customer Contact',
        icon: Icons.contact_phone_outlined,
        color: Color(0xFFEAB308),
        checkers: {'CE SERVICE'},
        subjects: [
          _SubjectMeta('Appointment balance (80/20)', 1, 'CE Service audit'),
          _SubjectMeta(
            'Reason of Rejection Log',
            1,
            'Countermeasures recorded',
          ),
          _SubjectMeta(
            'Contact Details / QR Hotline',
            1,
            'Visible hotline printed QR code',
          ),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Menu Pricing / Commitment of Price and Time Delivery',
        icon: Icons.price_check_rounded,
        color: Color(0xFF22C55E),
        checkers: {'ASM'},
        subjects: [
          _SubjectMeta(
            'Promised Delivery Time',
            1,
            'Technician availability check',
          ),
          _SubjectMeta(
            'Cost Estimate Attachment',
            1,
            'Attached to Repair Order',
          ),
          _SubjectMeta('SA Individual Note', 1, 'Promised time tracking'),
        ],
      ),
      const _CoverageDefinition(
        coverage: 'Advance Info to Parts Store',
        icon: Icons.inventory_2_outlined,
        color: Color(0xFFE11D48),
        checkers: {'PARTS'},
        subjects: [
          _SubjectMeta(
            'Advance Pick-List Preparation',
            1,
            'Parts pre-picking before service',
          ),
          _SubjectMeta(
            'Emergency Parts Ordering',
            1,
            'Expedited parts availability',
          ),
        ],
      ),
    ];

    final filteredCards = cards.where((card) {
      if (_selectedChecker == 'ALL') return true;
      return card.checkers.any((c) => _matchesChecker(c, _selectedChecker));
    }).toList();

    final isWorkshopSupervisorFilter =
        canonicalDosChecker(_selectedChecker) == 'WS SUP';
    final filteredItemsByCoverage = <String, List<ChecklistItem>>{};
    if (isWorkshopSupervisorFilter) {
      for (final item in _activeTemplate.expand((section) => section.items)) {
        if (!_matchesChecker(item.checker, _selectedChecker)) continue;
        final coverage = item.coverage;
        if (coverage == null || coverage.trim().isEmpty) continue;
        filteredItemsByCoverage
            .putIfAbsent(_coverageKey(coverage), () => [])
            .add(item);
      }
    }

    return Column(
      children: [
        for (int i = 0; i < filteredCards.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildCoverageCard(
            coverage: filteredCards[i].coverage.toUpperCase(),
            subjects: isWorkshopSupervisorFilter
                ? _salesSubjects(
                    filteredItemsByCoverage[_coverageKey(
                          filteredCards[i].coverage,
                        )] ??
                        const <ChecklistItem>[],
                  )
                : filteredCards[i].subjects,
            icon: filteredCards[i].icon,
            color: filteredCards[i].color,
          ),
        ],
      ],
    );
  }

  List<_SubjectMeta> _salesSubjects(List<ChecklistItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final subject = item.subject?.trim();
      if (subject == null || subject.isEmpty) continue;
      counts.update(subject, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts.entries
        .map(
          (entry) => _SubjectMeta(
            entry.key,
            entry.value,
            '${entry.value} Main Form standard${entry.value == 1 ? '' : 's'}',
          ),
        )
        .toList(growable: false);
  }

  String _coverageKey(String coverage) =>
      coverage.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  IconData _salesCoverageIcon(String coverage) {
    return switch (coverage.toLowerCase()) {
      'facilities' => Icons.storefront_outlined,
      'product presentation and test drive' => Icons.directions_car_outlined,
      'customer engagement and showroom operations' => Icons.handshake_outlined,
      'sales operation management' => Icons.manage_accounts_outlined,
      'lead generation and management' => Icons.campaign_outlined,
      'manpower' => Icons.groups_rounded,
      'needs analysis' => Icons.fact_check_outlined,
      'deal and closing management' => Icons.price_check_outlined,
      'application process support' => Icons.description_outlined,
      'vehicle release management' => Icons.car_rental_outlined,
      'post-release customer management' => Icons.support_agent_outlined,
      'systems' => Icons.devices_rounded,
      'mandatory reports' => Icons.assessment_outlined,
      _ => Icons.checklist_rounded,
    };
  }

  Color _salesCoverageColor(int index) {
    const colors = [
      GacColors.primary,
      GacColors.green400,
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
      Color(0xFF6366F1),
      Color(0xFFA855F7),
      Color(0xFFF97316),
      Color(0xFF22C55E),
      Color(0xFF3B82F6),
      Color(0xFFE11D48),
    ];
    return colors[index % colors.length];
  }

  Widget _buildCoverageCard({
    required String coverage,
    required List<_SubjectMeta> subjects,
    required IconData icon,
    required Color color,
  }) {
    final totalItems = subjects.fold<int>(0, (sum, s) => sum + s.itemCount);

    return GacContentPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coverage,
                      style: const TextStyle(
                        color: GacColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.1,
                      ),
                    ),
                    Text(
                      '$totalItems audit standards',
                      style: const TextStyle(
                        color: GacColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _openAuditSheet,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: const Size(60, 32),
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'AUDIT',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: GacColors.cardBorder),
          const SizedBox(height: 10),
          for (final s in subjects) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 2,
                    child: Text(
                      s.title,
                      style: const TextStyle(
                        color: GacColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${s.itemCount})',
                    style: const TextStyle(
                      color: GacColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      s.detail,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: GacColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEscalationCenter() {
    return GacGlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ESCALATION & NOTIFICATION TARGETS',
                  style: TextStyle(
                    color: GacColors.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.forward_to_inbox_rounded,
                color: GacColors.primary,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isAftersales
                ? 'Non-compliant Aftersales items flagged by inspectors automatically escalate to responsible accounts with required Action Plans and Commitment Dates:'
                : 'Non-compliant items flagged by Sales Manager automatically escalate to responsible accounts with required Action Plans and Commitment Dates:',
            style: const TextStyle(
              color: GacColors.textSecondary,
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          _buildEscalationRow(
            'General Manager (Person)',
            'Executive accountable for dealership policy & operational compliance',
            'GM',
            GacColors.brandRed,
          ),
          const SizedBox(height: 10),
          _buildEscalationRow(
            'Purchasing (Team)',
            'Team notification for parts replenishment, consumables & reception equipment',
            'TEAM',
            GacColors.amber400,
          ),
          const SizedBox(height: 10),
          _buildEscalationRow(
            'PM - Property Management (Team)',
            'Property Management team accountable for facility cladding, tools, oil dispensers & lift maintenance',
            'PM',
            GacColors.primary,
          ),
          const SizedBox(height: 10),
          _buildEscalationRow(
            'Inventory (Team)',
            'Team notification for fast-moving parts stock, pre-picking & warranty items',
            'TEAM',
            GacColors.green400,
          ),
          if (_isAftersales) ...[
            const SizedBox(height: 10),
            _buildEscalationRow(
              'AS Brand Head / CE Central',
              'Person accountable for customer experience, CSI scores & complaint resolution',
              'BRAND',
              GacColors.cyan,
            ),
            const SizedBox(height: 10),
            _buildEscalationRow(
              'Network Training Department / MMPC',
              'Accreditation body for technical training certifications and CRD level status',
              'MMPC',
              GacColors.blue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEscalationRow(
    String title,
    String desc,
    String badge,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: GacColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: GacColors.textMuted,
                  fontSize: 9.5,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLaunchAuditButton() {
    final label = _isAftersales
        ? 'LAUNCH AFTERSALES STANDARDS AUDIT'
        : 'LAUNCH SALES STANDARDS AUDIT';

    final showSubform =
        _isAftersales && (widget.user.isAdmin || widget.user.canAccessSubform);
    final showDoc =
        _isAftersales &&
        (widget.user.isAdmin || widget.user.canAccessDocumentation);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: () => _openAuditSheet(),
          style: FilledButton.styleFrom(
            backgroundColor: GacColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
            shadowColor: const Color(0x402979FF),
          ),
          icon: const Icon(Icons.rate_review_outlined, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (showSubform || showDoc) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (showSubform)
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('dos-launch-subform-button'),
                    onPressed: () =>
                        _openAuditSheet('dealer-operations-standards-subform'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: GacColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.checklist_rounded,
                      size: 16,
                      color: GacColors.primary,
                    ),
                    label: const Text(
                      'SUBFORM SHEET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: GacColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              if (showSubform && showDoc) const SizedBox(width: 8),
              if (showDoc)
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('dos-launch-doc-button'),
                    onPressed: () => _openAuditSheet(
                      'dealer-operations-standards-documentation',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF06B6D4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.description_rounded,
                      size: 16,
                      color: Color(0xFF06B6D4),
                    ),
                    label: const Text(
                      'DOCUMENTATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF06B6D4),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SubjectMeta {
  const _SubjectMeta(this.title, this.itemCount, this.detail);
  final String title;
  final int itemCount;
  final String detail;
}

class _CoverageDefinition {
  const _CoverageDefinition({
    required this.coverage,
    required this.icon,
    required this.color,
    required this.checkers,
    required this.subjects,
  });

  final String coverage;
  final IconData icon;
  final Color color;
  final Set<String> checkers;
  final List<_SubjectMeta> subjects;
}
