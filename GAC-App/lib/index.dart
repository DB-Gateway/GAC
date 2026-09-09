import 'dart:math' as math;
import 'dart:ui' as ui;

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
  late final Animation<double> _badgeOpacity;
  late final Animation<double> _badgeScale;
  late final Animation<double> _logoEntrance;
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
        final useDarkIcons = _backgroundEntrance.value > 0.55;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value:
              (useDarkIcons
                      ? SystemUiOverlayStyle.dark
                      : SystemUiOverlayStyle.light)
                  .copyWith(
                    statusBarColor: systemColor,
                    systemNavigationBarColor: systemColor,
                    statusBarIconBrightness: useDarkIcons
                        ? Brightness.dark
                        : Brightness.light,
                    systemNavigationBarIconBrightness: useDarkIcons
                        ? Brightness.dark
                        : Brightness.light,
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
                            child: Opacity(
                              opacity: _badgeOpacity.value,
                              child: Transform.scale(
                                scale: _badgeScale.value,
                                child: Hero(
                                  tag: gatewayLogoHeroTag,
                                  child: GatewayLogoBadge(
                                    key: const ValueKey('gateway-splash-logo'),
                                    size: badgeSize,
                                    backgroundOpacity: 0.4,
                                    imageScale: 0.82,
                                    imageOpacity: _logoEntrance.value,
                                    imageOffsetY: 4 * (1 - _logoEntrance.value),
                                  ),
                                ),
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
    _badgeOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        380 / 1900,
        1180 / 1900,
        curve: Cubic(0.22, 0.61, 0.36, 1),
      ),
    );
    _badgeScale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          380 / 1900,
          1430 / 1900,
          curve: Cubic(0.65, 0, 0.35, 1),
        ),
      ),
    );
    _logoEntrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        670 / 1900,
        1370 / 1900,
        curve: Cubic(0.22, 0.61, 0.36, 1),
      ),
    );
    _taglineEntrance = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: 700),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.ease)),
        weight: 600,
      ),
      TweenSequenceItem(tween: ConstantTween(1), weight: 450),
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

    // Wave 2 — mid layer
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

    // Wave 3 — front layer, lightest dark blue
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
  bool shouldRepaint(covariant _DarkWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// The persistent glass logo badge shared by the splash and login screens.
class GatewayLogoBadge extends StatelessWidget {
  final double size;
  final double backgroundOpacity;
  final double imageScale;
  final double imageOpacity;
  final double imageOffsetY;

  const GatewayLogoBadge({
    super.key,
    required this.size,
    this.backgroundOpacity = 0.85,
    this.imageScale = 0.66,
    this.imageOpacity = 1,
    this.imageOffsetY = 0,
  });

  @override
  Widget build(BuildContext context) {
    final imageAreaSize = size * imageScale;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0x4000BCD4),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    Color.fromRGBO(15, 30, 55, backgroundOpacity.clamp(0.0, 1.0)),
                    Color.fromRGBO(8, 18, 38, backgroundOpacity.clamp(0.0, 1.0)),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xAA00BCD4),
                  width: 1.8,
                ),
              ),
              child: Center(
                child: Opacity(
                  opacity: imageOpacity.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, imageOffsetY),
                    child: Image.asset(
                          _gatewayCircleLogoAsset,
                          width: imageAreaSize,
                          height: imageAreaSize,
                          fit: BoxFit.contain,
                          semanticLabel: 'Gateway',
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
