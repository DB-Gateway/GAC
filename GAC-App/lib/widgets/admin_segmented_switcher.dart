import 'dart:async';

import 'package:flutter/material.dart';

import '../admin/admin_destination.dart';
import '../theme/gac_theme.dart';

class AdminSegmentOption<T> {
  const AdminSegmentOption({
    required this.value,
    required this.label,
    required this.accessibilityLabel,
    required this.icon,
    required this.activeIcon,
  });

  final T value;
  final String label;
  final String accessibilityLabel;
  final IconData icon;
  final IconData activeIcon;
}

class AdminSegmentedSwitcher<T> extends StatefulWidget {
  const AdminSegmentedSwitcher({
    required this.activeValue,
    required this.eyebrow,
    required this.options,
    required this.onChanged,
    super.key,
  }) : assert(options.length == 2);

  final T activeValue;
  final String eyebrow;
  final List<AdminSegmentOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  State<AdminSegmentedSwitcher<T>> createState() =>
      _AdminSegmentedSwitcherState<T>();
}

class _AdminSegmentedSwitcherState<T> extends State<AdminSegmentedSwitcher<T>> {
  static const _animationDuration = Duration(milliseconds: 220);

  Timer? _highlightTimer;
  Timer? _navigationTimer;
  late int _activeIndex;
  late int _indicatorIndex;
  late int _highlightedIndex;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _resetToActiveValue();
  }

  @override
  void didUpdateWidget(covariant AdminSegmentedSwitcher<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeValue != widget.activeValue) _resetToActiveValue();
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _resetToActiveValue() {
    _highlightTimer?.cancel();
    _navigationTimer?.cancel();
    _activeIndex = widget.options.indexWhere(
      (option) => option.value == widget.activeValue,
    );
    if (_activeIndex < 0) _activeIndex = 0;
    _indicatorIndex = _activeIndex;
    _highlightedIndex = _activeIndex;
    _pending = false;
  }

  void _select(int index) {
    if (index == _activeIndex || _pending) return;

    setState(() {
      _pending = true;
      _indicatorIndex = index;
    });

    _highlightTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() => _highlightedIndex = index);
    });

    _navigationTimer = Timer(_animationDuration, () {
      if (!mounted) return;
      widget.onChanged(widget.options[index].value);
      if (!mounted) return;
      setState(_resetToActiveValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.eyebrow,
            style: const TextStyle(
              color: GacColors.gray,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: GacColors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: GacColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedAlign(
                    duration: _animationDuration,
                    curve: Curves.easeOutCubic,
                    alignment: _indicatorIndex == 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: GacColors.black,
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var index = 0; index < widget.options.length; index++)
                      Expanded(child: _buildOption(index)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int index) {
    final option = widget.options[index];
    final highlighted = _highlightedIndex == index;
    return Semantics(
      button: true,
      selected: _activeIndex == index,
      enabled: !_pending,
      label: option.accessibilityLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: _pending ? null : () => _select(index),
          borderRadius: BorderRadius.circular(13),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  highlighted ? option.activeIcon : option.icon,
                  size: 18,
                  color: highlighted ? GacColors.white : GacColors.gray,
                ),
                const SizedBox(width: 7),
                Text(
                  option.label,
                  style: TextStyle(
                    color: highlighted ? GacColors.white : GacColors.gray,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
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

class AdminChecklistSwitcher extends StatelessWidget {
  const AdminChecklistSwitcher({
    required this.activeModule,
    required this.onChanged,
    super.key,
  });

  final AdminDestination activeModule;
  final AdminNavigationCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AdminSegmentedSwitcher<AdminDestination>(
      activeValue: activeModule,
      eyebrow: 'CHECKLIST TYPE',
      onChanged: onChanged,
      options: const [
        AdminSegmentOption(
          value: AdminDestination.dos,
          label: 'DOS',
          accessibilityLabel: 'Dealer Operations Standards',
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
        ),
        AdminSegmentOption(
          value: AdminDestination.fiveS,
          label: '5S',
          accessibilityLabel: '5S checklist',
          icon: Icons.list_alt_outlined,
          activeIcon: Icons.list_alt_rounded,
        ),
      ],
    );
  }
}

class AdminReportsUsersSwitcher extends StatelessWidget {
  const AdminReportsUsersSwitcher({
    required this.activeView,
    required this.onChanged,
    super.key,
  });

  final AdminDestination activeView;
  final AdminNavigationCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AdminSegmentedSwitcher<AdminDestination>(
      activeValue: activeView,
      eyebrow: 'ADMIN VIEW',
      onChanged: onChanged,
      options: const [
        AdminSegmentOption(
          value: AdminDestination.reports,
          label: 'REPORTS',
          accessibilityLabel: 'Reports and analytics',
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
        ),
        AdminSegmentOption(
          value: AdminDestination.users,
          label: 'USERS',
          accessibilityLabel: 'User management',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
        ),
      ],
    );
  }
}
