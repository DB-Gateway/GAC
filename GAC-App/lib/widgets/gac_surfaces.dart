import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/gac_theme.dart';

/// The authenticated-app version of the splash/login dark navy background.
class GacBlushBackdrop extends StatelessWidget {
  const GacBlushBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0, -1),
                  end: Alignment(0, 1),
                  colors: [
                    Color(0xFF060E1E),
                    Color(0xFF0A1628),
                    Color(0xFF0E1E35),
                  ],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            CustomPaint(
              painter: _SurfaceDarkWavePainter(),
              size: Size.infinite,
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceDarkWavePainter extends CustomPainter {
  const _SurfaceDarkWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF0B1D33)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.38)
      ..cubicTo(
        size.width * 0.20, size.height * 0.30,
        size.width * 0.45, size.height * 0.42,
        size.width * 0.65, size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.80, size.height * 0.32,
        size.width * 0.95, size.height * 0.38,
        size.width, size.height * 0.34,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFF0E2240)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height * 0.52)
      ..cubicTo(
        size.width * 0.25, size.height * 0.44,
        size.width * 0.50, size.height * 0.56,
        size.width * 0.70, size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.85, size.height * 0.43,
        size.width * 0.95, size.height * 0.50,
        size.width, size.height * 0.46,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, paint2);

    final paint3 = Paint()
      ..color = const Color(0xFF102847)
      ..style = PaintingStyle.fill;

    final path3 = Path()
      ..moveTo(0, size.height * 0.64)
      ..cubicTo(
        size.width * 0.30, size.height * 0.57,
        size.width * 0.55, size.height * 0.66,
        size.width * 0.75, size.height * 0.60,
      )
      ..cubicTo(
        size.width * 0.90, size.height * 0.56,
        size.width * 0.97, size.height * 0.62,
        size.width, size.height * 0.58,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Places a screen over the same blush composition used by login.
class GacScreenBackground extends StatelessWidget {
  const GacScreenBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [const GacBlushBackdrop(), child],
    );
  }
}

/// True glass, based on the splash logo badge's blur/fill/border/shadow recipe.
///
/// Use this selectively for fixed chrome, floating controls, and hero panels.
/// Repeated scrolling cards should normally use [GacContentPanel] instead.
class GacGlassSurface extends StatelessWidget {
  const GacGlassSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.borderRadius = 24,
    this.blurSigma = 18,
    this.color = GacColors.glassSurface,
    this.borderColor = GacColors.glassBorder,
    this.shadowColor = GacColors.glassShadow,
    this.shadowBlurRadius = 24,
    this.shadowOffset = const Offset(0, 8),
    this.width,
    this.height,
    this.constraints,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: shadowBlurRadius,
            offset: shadowOffset,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: radius,
              border: Border.all(color: borderColor),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// The solid content-panel treatment established by the login form card.
class GacContentPanel extends StatelessWidget {
  const GacContentPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.borderRadius = 24,
    this.color = GacColors.cardSurface,
    this.borderColor = GacColors.panelBorder,
    this.shadowColor = GacColors.panelShadow,
    this.shadowBlurRadius = 28,
    this.shadowOffset = const Offset(0, 14),
    this.clipBehavior = Clip.none,
    this.width,
    this.height,
    this.constraints,
    this.alignment,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final Clip clipBehavior;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: constraints,
      alignment: alignment,
      margin: margin,
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: shadowBlurRadius,
            offset: shadowOffset,
          ),
        ],
      ),
      child: child,
    );
  }
}
