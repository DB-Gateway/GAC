import 'package:flutter/material.dart';

import '../theme/gac_theme.dart';
import 'gac_surfaces.dart';

class AdminPageHeading extends StatelessWidget {
  const AdminPageHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.action,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: GacColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        eyebrow.toUpperCase(),
                        style: const TextStyle(
                          color: GacColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 28,
                    height: 32 / 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: const TextStyle(
                    color: GacColors.gray,
                    fontSize: 11,
                    height: 17 / 11,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

class AdminSectionHeading extends StatelessWidget {
  const AdminSectionHeading({
    required this.title,
    this.eyebrow,
    this.detail,
    this.action,
    super.key,
  });

  final String? eyebrow;
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: const TextStyle(
                      color: GacColors.gray,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail!,
                    style: const TextStyle(
                      color: GacColors.gray,
                      fontSize: 9,
                      height: 14 / 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 14), action!],
        ],
      ),
    );
  }
}

class AdminSurfaceCard extends StatelessWidget {
  const AdminSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(17),
    this.margin,
    this.color = GacColors.white,
    this.borderColor = GacColors.lightGray,
    this.borderRadius = 21,
    this.clipBehavior = Clip.none,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final Color borderColor;
  final double borderRadius;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final usesDefaultTreatment =
        color == GacColors.white && borderColor == GacColors.lightGray;

    if (usesDefaultTreatment) {
      return GacContentPanel(
        margin: margin,
        padding: padding,
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: child,
      );
    }

    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    this.progress,
    super.key,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 146),
      child: GacContentPanel(
        padding: const EdgeInsets.all(14),
        borderRadius: 19,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 31),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GacColors.gray,
                      fontSize: 9,
                      height: 13 / 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 29,
                height: 29,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GacColors.iconTile,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: GacColors.navy950),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: GacColors.black,
              fontSize: 26,
              height: 31 / 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 7),
            AdminProgressBar(value: progress!),
          ],
          const SizedBox(height: 8),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GacColors.gray,
              fontSize: 8,
              height: 1.5,
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class AdminProgressBar extends StatelessWidget {
  const AdminProgressBar({
    required this.value,
    this.light = false,
    this.height = 6,
    this.fillColor,
    this.trackColor,
    super.key,
  });

  final double value;
  final bool light;
  final double height;
  final Color? fillColor;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0, 100).toDouble();
    return Semantics(
      value: '${safeValue.round()} percent',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: height,
            child: ColoredBox(
              color:
                  trackColor ??
                  (light ? const Color(0xFF3A3A3A) : GacColors.lightGray),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: safeValue / 100,
                  heightFactor: 1,
                  child: ColoredBox(
                    color:
                        fillColor ??
                        (light ? GacColors.white : GacColors.primary),
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

enum AdminActionButtonVariant { primary, secondary, danger }

class AdminActionButton extends StatelessWidget {
  const AdminActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AdminActionButtonVariant.secondary,
    this.compact = false,
    this.disabled = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final AdminActionButtonVariant variant;
  final bool compact;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isSecondary = variant == AdminActionButtonVariant.secondary;
    final backgroundColor = switch (variant) {
      AdminActionButtonVariant.primary => GacColors.primary,
      AdminActionButtonVariant.secondary => GacColors.white,
      AdminActionButtonVariant.danger => GacColors.error,
    };
    final borderColor = switch (variant) {
      AdminActionButtonVariant.primary => GacColors.primary,
      AdminActionButtonVariant.secondary => GacColors.border,
      AdminActionButtonVariant.danger => GacColors.error,
    };
    final foregroundColor = isSecondary ? GacColors.black : GacColors.white;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Material(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 11 : 13),
            side: BorderSide(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: compact ? 36 : 44),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 15),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: compact ? 15 : 17,
                        color: foregroundColor,
                      ),
                      const SizedBox(width: 7),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: compact ? 9 : 10,
                          fontWeight: FontWeight.w900,
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
    );
  }
}

enum AdminStatusTone { dark, neutral, success, warning, danger }

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({
    required this.label,
    this.tone = AdminStatusTone.neutral,
    super.key,
  });

  final String label;
  final AdminStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, border, foreground) = switch (tone) {
      AdminStatusTone.dark => (
        GacColors.black,
        GacColors.black,
        GacColors.white,
      ),
      AdminStatusTone.neutral => (
        GacColors.offWhite,
        GacColors.border,
        GacColors.gray,
      ),
      AdminStatusTone.success => (
        const Color(0xFFEDF8F2),
        const Color(0xFFB7D8C8),
        GacColors.gray,
      ),
      AdminStatusTone.warning => (
        const Color(0xFFFFF8E6),
        const Color(0xFFE6D19B),
        GacColors.gray,
      ),
      AdminStatusTone.danger => (
        const Color(0xFFFFF1EF),
        const Color(0xFFE4B6B1),
        GacColors.error,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
