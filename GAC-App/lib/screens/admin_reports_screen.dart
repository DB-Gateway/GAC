import 'package:flutter/material.dart';

import '../admin/admin_destination.dart';
import '../data/admin_data.dart';
import '../services/share_service.dart';
import '../theme/gac_theme.dart';
import '../widgets/admin_page.dart';
import '../widgets/admin_segmented_switcher.dart';
import '../widgets/admin_ui.dart';

const _reportMessage =
    'Gateway Audit Compliance — August 2026\n'
    'Overall: 92%\n'
    'DOS: 91%\n'
    '5S: 94%\n'
    '28 audit records\n'
    '9 flagged findings';

const _dosTiers = <_DosTier>[
  _DosTier(label: 'Basic', value: 94, detail: 'Mandatory foundation standards'),
  _DosTier(label: 'Standard', value: 91, detail: 'Core operating standards'),
  _DosTier(label: 'Beyond', value: 86, detail: 'Enhanced experience standards'),
];

const _auditHistory = <_AuditRecord>[
  _AuditRecord(
    id: 'audit-1',
    date: 'Aug 10, 2026',
    module: 'DOS',
    branch: 'Pasong Tamo',
    status: 'Submitted',
    score: 92,
    completion: 100,
    counts: '69 YES · 6 NO · 0 N/A',
  ),
  _AuditRecord(
    id: 'audit-2',
    date: 'Aug 10, 2026',
    module: '5S',
    branch: 'Cavite',
    status: 'Submitted',
    score: 95,
    completion: 100,
    counts: '53 YES · 2 NO · 1 N/A',
  ),
  _AuditRecord(
    id: 'audit-3',
    date: 'Aug 9, 2026',
    module: '5S',
    branch: 'Gateway Branch 2',
    status: 'Draft',
    score: 88,
    completion: 79,
    counts: '39 YES · 5 NO · 0 N/A',
  ),
];

const _findings = <_Finding>[
  _Finding(
    id: 'finding-1',
    date: 'Aug 10',
    branch: 'Pasong Tamo',
    area: 'Customer Appointment',
    item: 'Appointment reconfirmation call',
    result: 'NO',
    action: 'Record calls in the booking system before the next review.',
  ),
  _Finding(
    id: 'finding-2',
    date: 'Aug 10',
    branch: 'Cavite',
    area: 'Showroom',
    item: 'Damaged floor tile',
    result: 'NO',
    action: 'Maintenance request submitted; commitment date is August 14.',
  ),
  _Finding(
    id: 'finding-3',
    date: 'Aug 9',
    branch: 'Gateway Branch 2',
    area: 'Customer Lounge',
    item: 'Public Wi-Fi availability',
    result: 'N/A',
    action: 'Temporary renovation; BOM provided supporting reason.',
  ),
];

enum _ModuleFilter { all, dos, fiveS }

enum _ReportPeriod { threeMonths, sixMonths }

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({required this.onNavigate, this.onShare, super.key});

  final AdminNavigationCallback onNavigate;
  final ShareTextCallback? onShare;

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  _ModuleFilter _moduleFilter = _ModuleFilter.all;
  _ReportPeriod _period = _ReportPeriod.sixMonths;

  List<ComplianceMonth> get _visibleMonths =>
      _period == _ReportPeriod.threeMonths
      ? monthlyCompliance.sublist(monthlyCompliance.length - 3)
      : monthlyCompliance;

  Future<void> _shareReport() async {
    final callback = widget.onShare;
    if (callback != null) {
      await callback(_reportMessage);
      return;
    }
    await shareText(context, _reportMessage);
  }

  @override
  Widget build(BuildContext context) {
    final compactGrid = MediaQuery.sizeOf(context).width < 540;
    final months = _visibleMonths;

    return AdminPage(
      onNavigate: widget.onNavigate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminReportsUsersSwitcher(
            activeView: AdminDestination.reports,
            onChanged: widget.onNavigate,
          ),
          AdminPageHeading(
            eyebrow: 'Consolidated GM reporting',
            title: 'Reports & Analytics',
            description:
                'Compare DOS and 5S performance, review branch results, and '
                'inspect every flagged finding in a mobile-friendly report.',
            action: AdminActionButton(
              label: 'Share Report',
              icon: Icons.share_outlined,
              onPressed: _shareReport,
              variant: AdminActionButtonVariant.primary,
              compact: true,
            ),
          ),
          AdminSurfaceCard(child: _buildFilters()),
          const SizedBox(height: 15),
          _ReportMetricGrid(compact: compactGrid),
          const SizedBox(height: 28),
          AdminSectionHeading(
            eyebrow: 'Weighted YES score',
            title: 'Monthly Compliance Trend',
            detail:
                '${_moduleFilter == _ModuleFilter.all
                    ? 'DOS and 5S'
                    : _moduleFilter == _ModuleFilter.dos
                    ? 'DOS'
                    : '5S'} '
                '· N/A excluded from the score',
            action: AdminStatusPill(
              label: _period == _ReportPeriod.threeMonths ? '3M' : '6M',
              tone: AdminStatusTone.dark,
            ),
          ),
          AdminSurfaceCard(
            child: _GroupedComplianceChart(
              months: months,
              moduleFilter: _moduleFilter,
            ),
          ),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Response mix',
            title: 'Judgment Distribution',
            detail: 'Share of YES, NO, and N/A judgments',
          ),
          const AdminSurfaceCard(child: _JudgmentDistribution()),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Record volume',
            title: 'Audits by Month',
            detail: 'Submitted and draft DOS and 5S records',
          ),
          AdminSurfaceCard(child: _AuditVolumeList(months: months)),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'All branches',
            title: 'Branch Performance',
            detail: 'Weighted DOS and 5S compliance',
          ),
          const _BranchPerformanceList(),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'DOS Main Form',
            title: 'Performance by Coverage',
            detail: 'Representative coverage areas from the 75-standard master form',
          ),
          AdminSurfaceCard(child: _PerformanceList(items: dosCategories)),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Gateway 5S',
            title: 'Performance by Section',
            detail: 'Representative areas from the 56-item daily checklist',
          ),
          AdminSurfaceCard(child: _PerformanceList(items: fiveSSections)),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Basic · Standard · Beyond',
            title: 'DOS Category Performance',
            detail: 'Weighted score for every standards tier',
          ),
          const _DosTierList(),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'NO + N/A',
            title: 'Monthly Findings Trend',
            detail: 'Judgments requiring review or a supporting reason',
          ),
          AdminSurfaceCard(child: _FindingTrendList(months: months)),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Records',
            title: 'Audit History',
            detail: 'Recent records matching the current mobile filters',
            action: AdminStatusPill(label: '3 records'),
          ),
          const _AuditHistoryList(),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Corrective action',
            title: 'Findings Register',
            detail: 'Items marked NO or N/A with the proposed response',
            action: AdminStatusPill(
              label: '9 total',
              tone: AdminStatusTone.danger,
            ),
          ),
          const _FindingsList(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel('MODULE'),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _FilterChip(
              label: 'DOS + 5S',
              selected: _moduleFilter == _ModuleFilter.all,
              onPressed: () =>
                  setState(() => _moduleFilter = _ModuleFilter.all),
            ),
            _FilterChip(
              label: 'DOS',
              selected: _moduleFilter == _ModuleFilter.dos,
              onPressed: () =>
                  setState(() => _moduleFilter = _ModuleFilter.dos),
            ),
            _FilterChip(
              label: '5S',
              selected: _moduleFilter == _ModuleFilter.fiveS,
              onPressed: () =>
                  setState(() => _moduleFilter = _ModuleFilter.fiveS),
            ),
          ],
        ),
        const SizedBox(height: 13),
        const _FilterLabel('PERIOD'),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _FilterChip(
              label: 'Last 3 months',
              selected: _period == _ReportPeriod.threeMonths,
              onPressed: () =>
                  setState(() => _period = _ReportPeriod.threeMonths),
            ),
            _FilterChip(
              label: 'Last 6 months',
              selected: _period == _ReportPeriod.sixMonths,
              onPressed: () =>
                  setState(() => _period = _ReportPeriod.sixMonths),
            ),
          ],
        ),
        const SizedBox(height: 13),
        const Divider(height: 1, thickness: 1, color: GacColors.lightGray),
        const SizedBox(height: 13),
        const Row(
          children: [
            Icon(Icons.business_outlined, size: 15, color: GacColors.gray),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'All branches · Submitted and draft records',
                style: TextStyle(color: GacColors.gray, fontSize: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: GacColors.gray,
        fontSize: 7,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      excludeSemantics: true,
      child: Material(
        color: widget.selected ? GacColors.black : GacColors.offWhite,
        shape: StadiumBorder(
          side: BorderSide(
            color: widget.selected ? GacColors.black : GacColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (pressed) {
            if (_pressed == pressed) return;
            setState(() => _pressed = pressed);
          },
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: AnimatedOpacity(
            opacity: _pressed ? 0.8 : 1,
            duration: const Duration(milliseconds: 90),
            child: AnimatedScale(
              scale: _pressed ? 0.99 : 1,
              duration: const Duration(milliseconds: 90),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 36),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.selected
                            ? GacColors.white
                            : GacColors.gray,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportMetricGrid extends StatelessWidget {
  const _ReportMetricGrid({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    const metrics = <_ReportMetric>[
      _ReportMetric(
        label: 'Overall Compliance',
        value: '92%',
        detail: 'Weighted applicable responses',
        icon: Icons.speed_rounded,
        progress: 92,
      ),
      _ReportMetric(
        label: 'DOS Compliance',
        value: '91%',
        detail: '28 DOS records',
        icon: Icons.assignment_outlined,
        progress: 91,
      ),
      _ReportMetric(
        label: '5S Compliance',
        value: '94%',
        detail: 'Daily branch checklists',
        icon: Icons.list_alt_outlined,
        progress: 94,
      ),
      _ReportMetric(
        label: 'Audit Records',
        value: '28',
        detail: 'Submitted and draft',
        icon: Icons.file_copy_outlined,
      ),
      _ReportMetric(
        label: 'Completion',
        value: '89%',
        detail: 'Standards and items judged',
        icon: Icons.check_circle_outline_rounded,
        progress: 89,
      ),
      _ReportMetric(
        label: 'Flagged Findings',
        value: '9',
        detail: 'NO and N/A judgments',
        icon: Icons.warning_amber_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * (compact ? 0.48 : 0.318);
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: AdminMetricCard(
                  label: metric.label,
                  value: metric.value,
                  detail: metric.detail,
                  icon: metric.icon,
                  progress: metric.progress,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GroupedComplianceChart extends StatelessWidget {
  const _GroupedComplianceChart({
    required this.months,
    required this.moduleFilter,
  });

  final List<ComplianceMonth> months;
  final _ModuleFilter moduleFilter;

  @override
  Widget build(BuildContext context) {
    final moduleLabel = switch (moduleFilter) {
      _ModuleFilter.all => 'DOS and 5S',
      _ModuleFilter.dos => 'DOS',
      _ModuleFilter.fiveS => '5S',
    };
    final values = months
        .map((month) => '${month.month}: DOS ${month.dos}, 5S ${month.fiveS}')
        .join('; ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _LegendItem(label: 'DOS', color: GacColors.black),
            SizedBox(width: 16),
            _LegendItem(label: '5S', color: Color(0xFF989898)),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          label: '$moduleLabel monthly compliance. $values percent.',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 177,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final month in months)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 144,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (moduleFilter != _ModuleFilter.fiveS)
                                  _VerticalTrack(
                                    value: month.dos,
                                    color: GacColors.black,
                                  ),
                                if (moduleFilter == _ModuleFilter.all)
                                  const SizedBox(width: 3),
                                if (moduleFilter != _ModuleFilter.dos)
                                  _VerticalTrack(
                                    value: month.fiveS,
                                    color: const Color(0xFF989898),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            month.month,
                            style: const TextStyle(
                              color: GacColors.gray,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: GacColors.gray,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _VerticalTrack extends StatelessWidget {
  const _VerticalTrack({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        width: 13,
        height: 138,
        child: ColoredBox(
          color: GacColors.lightGray,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: value / 100,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JudgmentDistribution extends StatelessWidget {
  const _JudgmentDistribution();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '1,482 recorded responses. YES 1,215, 82 percent. NO 163, 11 '
          'percent. N/A 104, 7 percent.',
      child: ExcludeSemantics(
        child: Column(
          children: [
            const Text(
              '1,482',
              style: TextStyle(
                color: GacColors.black,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'recorded responses',
              style: TextStyle(color: GacColors.gray, fontSize: 9),
            ),
            const SizedBox(height: 17),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                height: 22,
                child: Row(
                  children: [
                    Expanded(
                      flex: 82,
                      child: ColoredBox(color: GacColors.black),
                    ),
                    Expanded(
                      flex: 11,
                      child: ColoredBox(color: Color(0xFF777777)),
                    ),
                    Expanded(
                      flex: 7,
                      child: ColoredBox(color: Color(0xFFC8C8C8)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: _DistributionLegend('YES', '1,215 · 82%')),
                SizedBox(width: 8),
                Expanded(child: _DistributionLegend('NO', '163 · 11%')),
                SizedBox(width: 8),
                Expanded(child: _DistributionLegend('N/A', '104 · 7%')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionLegend extends StatelessWidget {
  const _DistributionLegend(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GacColors.gray,
            fontSize: 7,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: GacColors.black,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AuditVolumeList extends StatelessWidget {
  const _AuditVolumeList({required this.months});

  final List<ComplianceMonth> months;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < months.length; index++)
          _HorizontalDataRow(
            label: months[index].month,
            value: months[index].audits,
            fraction: months[index].audits / 30,
            showBorder: index > 0,
          ),
      ],
    );
  }
}

class _HorizontalDataRow extends StatelessWidget {
  const _HorizontalDataRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.showBorder,
    this.fillColor = GacColors.black,
    this.valueColor = GacColors.black,
  });

  final String label;
  final int value;
  final double fraction;
  final bool showBorder;
  final Color fillColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final percent = (fraction * 100).round();
    return Semantics(
      label: '$label, $value',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 49),
          decoration: showBorder
              ? const BoxDecoration(
                  border: Border(top: BorderSide(color: GacColors.lightGray)),
                )
              : null,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 9,
                    child: ColoredBox(
                      color: GacColors.lightGray,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: percent.clamp(0, 100) / 100,
                          heightFactor: 1,
                          child: ColoredBox(color: fillColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 25,
                child: Text(
                  '$value',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchPerformanceList extends StatelessWidget {
  const _BranchPerformanceList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < branches.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          AdminSurfaceCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 37,
                      height: 37,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: GacColors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${branches[index].rank}',
                        style: const TextStyle(
                          color: GacColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branches[index].branch,
                            style: const TextStyle(
                              color: GacColors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            branches[index].status,
                            style: const TextStyle(
                              color: GacColors.gray,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${branches[index].compliance}%',
                      style: const TextStyle(
                        color: GacColors.black,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _BranchMetricRow(
                  label: 'DOS',
                  value: branches[index].dos,
                  color: GacColors.black,
                ),
                _BranchMetricRow(
                  label: '5S',
                  value: branches[index].fiveS,
                  color: const Color(0xFF8D8D8D),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BranchMetricRow extends StatelessWidget {
  const _BranchMetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value percent',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 30),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: GacColors.gray,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AdminProgressBar(
                  value: value.toDouble(),
                  height: 7,
                  fillColor: color,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  '$value%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformanceList extends StatelessWidget {
  const _PerformanceList({required this.items});

  final List<ProgressMetric> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: index == 0
                ? null
                : const BoxDecoration(
                    border: Border(top: BorderSide(color: GacColors.lightGray)),
                  ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[index].label,
                            style: const TextStyle(
                              color: GacColors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (items[index].detail != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              items[index].detail!,
                              style: const TextStyle(
                                color: GacColors.gray,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${items[index].value}%',
                      style: const TextStyle(
                        color: GacColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                AdminProgressBar(value: items[index].value.toDouble()),
              ],
            ),
          ),
      ],
    );
  }
}

class _DosTierList extends StatelessWidget {
  const _DosTierList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < _dosTiers.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          AdminSurfaceCard(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 11),
                  decoration: BoxDecoration(
                    color: GacColors.black,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.layers_outlined,
                    size: 19,
                    color: GacColors.white,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dosTiers[index].label,
                        style: const TextStyle(
                          color: GacColors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _dosTiers[index].detail,
                        style: const TextStyle(
                          color: GacColors.gray,
                          fontSize: 8,
                        ),
                      ),
                      const SizedBox(height: 7),
                      AdminProgressBar(
                        value: _dosTiers[index].value.toDouble(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_dosTiers[index].value}%',
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FindingTrendList extends StatelessWidget {
  const _FindingTrendList({required this.months});

  final List<ComplianceMonth> months;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < months.length; index++)
          _HorizontalDataRow(
            label: months[index].month,
            value: months[index].findings,
            fraction: months[index].findings / 16,
            fillColor: GacColors.error,
            valueColor: GacColors.error,
            showBorder: index > 0,
          ),
      ],
    );
  }
}

class _AuditHistoryList extends StatelessWidget {
  const _AuditHistoryList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < _auditHistory.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          AdminSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: GacColors.black,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        _auditHistory[index].module,
                        style: const TextStyle(
                          color: GacColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _auditHistory[index].branch,
                            style: const TextStyle(
                              color: GacColors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _auditHistory[index].date,
                            style: const TextStyle(
                              color: GacColors.gray,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AdminStatusPill(
                      label: _auditHistory[index].status,
                      tone: _auditHistory[index].status == 'Submitted'
                          ? AdminStatusTone.success
                          : AdminStatusTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HistoryMetric(
                        label: 'SCORE',
                        value: '${_auditHistory[index].score}%',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _HistoryMetric(
                        label: 'COMPLETION',
                        value: '${_auditHistory[index].completion}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Text(
                  _auditHistory[index].counts,
                  style: const TextStyle(color: GacColors.gray, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: GacColors.offWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: GacColors.gray,
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: GacColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FindingsList extends StatelessWidget {
  const _FindingsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < _findings.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          AdminSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: GacColors.error,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        _findings[index].result,
                        style: const TextStyle(
                          color: GacColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _findings[index].area,
                            style: const TextStyle(
                              color: GacColors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_findings[index].branch} · '
                            '${_findings[index].date}',
                            style: const TextStyle(
                              color: GacColors.gray,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  _findings[index].item,
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 10,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: GacColors.offWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.construction_outlined,
                        size: 16,
                        color: GacColors.black,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _findings[index].action,
                          style: const TextStyle(
                            color: GacColors.gray,
                            fontSize: 8,
                            height: 13 / 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ReportMetric {
  const _ReportMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    this.progress,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final double? progress;
}

class _DosTier {
  const _DosTier({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final int value;
  final String detail;
}

class _AuditRecord {
  const _AuditRecord({
    required this.id,
    required this.date,
    required this.module,
    required this.branch,
    required this.status,
    required this.score,
    required this.completion,
    required this.counts,
  });

  final String id;
  final String date;
  final String module;
  final String branch;
  final String status;
  final int score;
  final int completion;
  final String counts;
}

class _Finding {
  const _Finding({
    required this.id,
    required this.date,
    required this.branch,
    required this.area,
    required this.item,
    required this.result,
    required this.action,
  });

  final String id;
  final String date;
  final String branch;
  final String area;
  final String item;
  final String result;
  final String action;
}
