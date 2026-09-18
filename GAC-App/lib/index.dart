import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String gatewayLogoHeroTag = 'gateway-splash-login-logo';
const String _gatewayCircleLogoAsset = 'assets/images/Gateway_logo_circle.png';

const Color _splashBlack = Color(0xFF050A15);
const Color _blushLight = Color(0xFF0A1628);

/// The launch splash shown before sign-in.
///
/// This preserves the existing login-route argument contract while replacing
/// the old interactive welcome page with the animated splash from the HTML
/// reference.
class GatewayWelcomeScreen extends StatefulWidget {
  final String loginRoute;

  /// Retained so existing construction sites do not break.
  @Deprecated('The launch splash now transitions directly to login.')
  final String registerRoute;

  const GatewayWelcomeScreen({
    super.key,
    this.loginRoute = '/login',
    this.registerRoute = '/register',
  });

  @override
  State<GatewayWelcomeScreen> createState() => _GatewayWelcomeScreenState();
}

class _GatewayWelcomeScreenState extends State<GatewayWelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(milliseconds: 1900);

  late final AnimationController _controller;
  late final Animation<double> _backgroundEntrance;
  late final Animation<double> _blobEntrance;
  late final Animation<double> _logoExpansion;
  late final Animation<double> _circleChromeEntrance;
  late final Animation<double> _taglineEntrance;

  bool _openingLogin = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final systemColor = Color.lerp(
          _splashBlack,
          _blushLight,
          _backgroundEntrance.value,
        )!;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: systemColor,
            systemNavigationBarColor: systemColor,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: _splashBlack,
            body: Stack(
              fit: StackFit.expand,
              children: [
                GatewayBlushBackdrop(
                  lightProgress: _backgroundEntrance.value,
                  blobProgress: _blobEntrance.value,
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final badgeSize = math.min(
                        300.0,
                        constraints.maxWidth * 0.84,
                      );

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: Hero(
                              tag: gatewayLogoHeroTag,
                              child: GatewayLogoBadge(
                                key: const ValueKey('gateway-splash-logo'),
                                size: badgeSize,
                                backgroundOpacity: 0.4,
                                imageScale: 0.82,
                                expansionProgress: _logoExpansion.value,
                                chromeOpacity: _circleChromeEntrance.value,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: math.max(52, constraints.maxHeight * 0.11),
                            child: Opacity(
                              opacity: _taglineEntrance.value,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  6 * (1 - _taglineEntrance.value),
                                ),
                                child: const Text(
                                  'Gateway Audit Compliance',
                                  key: ValueKey('gateway-splash-tagline'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF7A8FA6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prepare the transparent wordmark and the final circle during the hold.
    precacheImage(const _GatewayWordmarkImage(), context);
    precacheImage(const AssetImage(_gatewayCircleLogoAsset), context);
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _splashDuration)
      ..addStatusListener(_handleAnimationStatus);

    _backgroundEntrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        80 / 1900,
        1180 / 1900,
        curve: Cubic(0.22, 0.61, 0.36, 1),
      ),
    );
    _blobEntrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        80 / 1900,
        1680 / 1900,
        curve: Cubic(0.22, 0.61, 0.36, 1),
      ),
    );
    _logoExpansion = CurvedAnimation(
      parent: _controller,
      curve: const Interval(200 / 1900, 1200 / 1900),
    );
    _circleChromeEntrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        1100 / 1900,
        1550 / 1900,
        curve: Curves.easeInOutCubic,
      ),
    );
    _taglineEntrance = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: 800),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.ease)),
        weight: 550,
      ),
      TweenSequenceItem(tween: ConstantTween(1), weight: 400),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.ease)),
        weight: 150,
      ),
    ]).animate(_controller);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.top],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _openLogin();
      } else {
        _controller.forward();
      }
    });
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _openLogin();
  }

  void _openLogin() {
    if (!mounted || _openingLogin) return;
    _openingLogin = true;

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    Navigator.of(context).pushReplacementNamed<void, void>(
      widget.loginRoute,
      arguments: const <String, String>{'fromWelcome': '1'},
    );
  }
}

/// The shared backdrop used on both sides of the splash-to-login handoff.
class GatewayBlushBackdrop extends StatelessWidget {
  final double lightProgress;
  final double blobProgress;

  const GatewayBlushBackdrop({
    super.key,
    this.lightProgress = 1,
    this.blobProgress = 1,
  });

  @override
  Widget build(BuildContext context) {
    final light = lightProgress.clamp(0.0, 1.0);
    final blobs = blobProgress.clamp(0.0, 1.0);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _splashBlack),
          Opacity(
            opacity: light,
            child: const DecoratedBox(
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
          ),
          Opacity(
            opacity: blobs,
            child: CustomPaint(
              painter: _DarkWavePainter(progress: blobs),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkWavePainter extends CustomPainter {
  final double progress;
  const _DarkWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Wave 1 — deepest, in the back
    final paint1 = Paint()
      ..color = const Color(0xFF0B1D33)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.38)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.30,
        size.width * 0.45,
        size.height * 0.42,
        size.width * 0.65,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.80,
        size.height * 0.32,
        size.width * 0.95,
        size.height * 0.38,
        size.width,
        size.height * 0.34,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, paint1);

    // Wave 2 — mid layer
    final paint2 = Paint()
      ..color = const Color(0xFF0E2240)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height * 0.52)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.44,
        size.width * 0.50,
        size.height * 0.56,
        size.width * 0.70,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.43,
        size.width * 0.95,
        size.height * 0.50,
        size.width,
        size.height * 0.46,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, paint2);

    // Wave 3 — front layer, lightest dark blue
    final paint3 = Paint()
      ..color = const Color(0xFF102847)
      ..style = PaintingStyle.fill;

    final path3 = Path()
      ..moveTo(0, size.height * 0.64)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.57,
        size.width * 0.55,
        size.height * 0.66,
        size.width * 0.75,
        size.height * 0.60,
      )
      ..cubicTo(
        size.width * 0.90,
        size.height * 0.56,
        size.width * 0.97,
        size.height * 0.62,
        size.width,
        size.height * 0.58,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant _DarkWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A cached, padded alpha image made from the circle's exact wordmark pixels.
/// Background removal happens once, before scaling or GPU texture filtering.
class _GatewayWordmarkImage extends ImageProvider<_GatewayWordmarkImage> {
  const _GatewayWordmarkImage();

  static const sourceSize = 720;
  static const cropLeft = 124;
  static const cropTop = 335;
  static const cropWidth = 472;
  static const cropHeight = 50;
  static const padding = 2;
  static const imageWidth = cropWidth + 2 * padding;
  static const imageHeight = cropHeight + 2 * padding;

  @override
  Future<_GatewayWordmarkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _GatewayWordmarkImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_loadMask());

  Future<ImageInfo> _loadMask() async {
    final asset = await rootBundle.load(_gatewayCircleLogoAsset);
    final source = await ui.instantiateImageCodec(
      asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
    );
    final pixels = Uint8List(imageWidth * imageHeight * 4);
    try {
      final frame = await source.getNextFrame();
      try {
        final rgba = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        if (rgba == null) {
          throw StateError('Could not read Gateway wordmark pixels.');
        }
        for (var y = 0; y < cropHeight; y++) {
          for (var x = 0; x < cropWidth; x++) {
            final src = ((cropTop + y) * frame.image.width + cropLeft + x) * 4;
            final dst = ((y + padding) * imageWidth + x + padding) * 4;
            final alpha =
                ((255 - rgba.getUint8(src)) * rgba.getUint8(src + 3) / 255)
                    .round();
            // ImageDescriptor.raw expects premultiplied RGBA. White edge
            // pixels must be (alpha, alpha, alpha, alpha), including zeros
            // in the transparent padding, so no dark matte is interpolated.
            pixels[dst] = alpha;
            pixels[dst + 1] = alpha;
            pixels[dst + 2] = alpha;
            pixels[dst + 3] = alpha;
          }
        }
      } finally {
        frame.image.dispose();
      }
    } finally {
      source.dispose();
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: imageWidth,
      height: imageHeight,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    try {
      final codec = await descriptor.instantiateCodec();
      try {
        final frame = await codec.getNextFrame();
        return ImageInfo(
          image: frame.image,
          debugLabel: 'Gateway transparent wordmark',
        );
      } finally {
        codec.dispose();
      }
    } finally {
      descriptor.dispose();
      buffer.dispose();
    }
  }
}

class _GatewayWordmarkClipper extends CustomClipper<Rect> {
  const _GatewayWordmarkClipper({required this.showG});

  final bool showG;

  @override
  Rect getClip(Size size) {
    // Split in the transparent gap after the G, including image padding.
    final split = size.width * 67 / _GatewayWordmarkImage.imageWidth;
    return Rect.fromLTRB(
      showG ? 0 : split,
      0,
      showG ? split : size.width,
      size.height,
    );
  }

  @override
  bool shouldReclip(_GatewayWordmarkClipper oldClipper) =>
      oldClipper.showG != showG;
}

/// The animated wordmark expanding from "G" into "GATEWAY" as seen in Gateway-Loading.mp4.
class GatewayExpandingWordmark extends StatelessWidget {
  // Pixel coordinates in Gateway_logo_circle.png (720 x 720). The crop is
  // centered on the circle and includes the trademark. Using the final logo
  // itself keeps the glyphs and their positions identical during the handoff.
  static const _sourceSize = _GatewayWordmarkImage.sourceSize;
  static const _wordmarkWidth = _GatewayWordmarkImage.cropWidth;
  static const _wordmarkHeight = _GatewayWordmarkImage.cropHeight;
  static const _gCenterX = 34.5; // Source x=158.5, relative to crop x=124.

  final double width;
  final double progress;
  final Color? color;

  const GatewayExpandingWordmark({
    super.key,
    required this.width,
    required this.progress,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final phase = progress.clamp(0.0, 1.0);
    final travel = const Interval(
      0,
      0.72,
      curve: Curves.easeInOutCubic,
    ).transform(phase);
    final reveal = const Interval(
      0.72,
      1,
      curve: Curves.easeOut,
    ).transform(phase);
    final sourceScale = width / _wordmarkWidth;
    final targetHeight = _wordmarkHeight * sourceScale;
    final imageWidth = _GatewayWordmarkImage.imageWidth * sourceScale;
    final imageHeight = _GatewayWordmarkImage.imageHeight * sourceScale;
    final gCenter = (_gCenterX + _GatewayWordmarkImage.padding) * sourceScale;
    final shift = (imageWidth / 2 - gCenter) * (1 - travel);
    final scale = ui.lerpDouble(4.5, 1, travel)!;
    final wordmark = Image(
      image: const _GatewayWordmarkImage(),
      width: imageWidth,
      height: imageHeight,
      color: color,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );

    return Semantics(
      label: 'Gateway',
      image: true,
      child: SizedBox(
        width: width,
        height: targetHeight * 4.5,
        child: OverflowBox(
          minWidth: imageWidth,
          maxWidth: imageWidth,
          minHeight: imageHeight,
          maxHeight: imageHeight,
          child: Transform.translate(
            offset: Offset(shift, 0),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment(2 * gCenter / imageWidth - 1, 0),
              child: Stack(
                children: [
                  ClipRect(
                    clipper: const _GatewayWordmarkClipper(showG: true),
                    child: wordmark,
                  ),
                  if (reveal > 0)
                    Opacity(
                      opacity: reveal,
                      child: ClipRect(
                        clipper: const _GatewayWordmarkClipper(showG: false),
                        child: wordmark,
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

/// The persistent glass logo badge shared by the splash and login screens.
class GatewayLogoBadge extends StatelessWidget {
  final double size;
  final double backgroundOpacity;
  final double imageScale;
  final double imageOpacity;
  final double imageOffsetY;
  final double expansionProgress;
  final double chromeOpacity;

  const GatewayLogoBadge({
    super.key,
    required this.size,
    this.backgroundOpacity = 0.85,
    this.imageScale = 0.66,
    this.imageOpacity = 1,
    this.imageOffsetY = 0,
    this.expansionProgress = 1.0,
    this.chromeOpacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final imageAreaSize = size * imageScale;
    final clampedChrome = chromeOpacity.clamp(0.0, 1.0);
    final clampedExpansion = expansionProgress.clamp(0.0, 1.0);
    final circleReveal =
        clampedChrome *
        const Interval(
          0.9,
          1,
          curve: Curves.easeInOut,
        ).transform(clampedExpansion);

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: clampedChrome > 0.01
              ? [
                  BoxShadow(
                    color: const Color(0x4000BCD4)
                        .withValues(alpha: 0.25 * clampedChrome),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 18 * clampedChrome,
              sigmaY: 18 * clampedChrome,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    Color.fromRGBO(
                      15,
                      30,
                      55,
                      (backgroundOpacity * clampedChrome).clamp(0.0, 1.0),
                    ),
                    Color.fromRGBO(
                      8,
                      18,
                      38,
                      (backgroundOpacity * clampedChrome).clamp(0.0, 1.0),
                    ),
                  ],
                ),
                border: Border.all(
                  color: const Color(
                    0xAA00BCD4,
                  ).withValues(alpha: (0.67 * clampedChrome).clamp(0.0, 1.0)),
                  width: 1.8,
                ),
              ),
              child: Center(
                child: Opacity(
                  opacity: imageOpacity.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, imageOffsetY),
                    child: SizedBox.square(
                      dimension: imageAreaSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (circleReveal > 0)
                            Opacity(
                              key: const ValueKey('gateway-circle-reveal'),
                              opacity: circleReveal,
                              child: Image.asset(
                                _gatewayCircleLogoAsset,
                                width: imageAreaSize,
                                height: imageAreaSize,
                                // Reveal only the white disc while the one
                                // wordmark above it changes color. Blending
                                // two antialiased copies leaves dark contours.
                                color: circleReveal < 1 ? Colors.white : null,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                semanticLabel: 'Gateway',
                              ),
                            ),
                          if (circleReveal < 1)
                            KeyedSubtree(
                              key: const ValueKey('gateway-wordmark-reveal'),
                              child: GatewayExpandingWordmark(
                                width:
                                    imageAreaSize *
                                    GatewayExpandingWordmark._wordmarkWidth /
                                    GatewayExpandingWordmark._sourceSize,
                                progress: clampedExpansion,
                                color: Color.lerp(
                                  Colors.white,
                                  Colors.black,
                                  circleReveal,
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
          ),
        ),
      ),
    );
  }
}

/// Three animated pulsing/bouncing dots for splash and loading indicators.
class GatewayLoadingDots extends StatefulWidget {
  final Color color;
  final double size;
  final double spacing;
  final Animation<double>? animation;

  const GatewayLoadingDots({
    super.key,
    this.color = Colors.white,
    this.size = 7.0,
    this.spacing = 8.0,
    this.animation,
  });

  @override
  State<GatewayLoadingDots> createState() => _GatewayLoadingDotsState();
}

class _GatewayLoadingDotsState extends State<GatewayLoadingDots>
    with SingleTickerProviderStateMixin {
  AnimationController? _internalController;

  Animation<double> get _activeAnimation =>
      widget.animation ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.animation == null) {
      _internalController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      );
      if (!WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations) {
        _internalController!.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(covariant GatewayLoadingDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != null && _internalController != null) {
      _internalController!.dispose();
      _internalController = null;
    } else if (widget.animation == null && _internalController == null) {
      _internalController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      );
      if (!WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations) {
        _internalController!.repeat();
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _activeAnimation,
      builder: (context, _) {
        final animValue = _activeAnimation.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final offset = index * 0.18;
            final raw =
                (animValue * (widget.animation != null ? 2.5 : 1.0)) - offset;
            final progress = (raw % 1.0 + 1.0) % 1.0;
            final curve = math.sin(progress * math.pi).clamp(0.0, 1.0);
            final bounceY = -5.0 * curve;
            final scale = 0.8 + (0.35 * curve);
            final opacity = (0.35 + (0.65 * curve)).clamp(0.0, 1.0);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: Transform.translate(
                offset: Offset(0, bounceY),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.35 * curve),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
