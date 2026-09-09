import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../admin/admin_destination.dart';
import '../theme/gac_theme.dart';
import 'admin_tabs_layout.dart';
import 'gac_surfaces.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    required this.child,
    required this.onNavigate,
    this.controller,
    this.paddingTop = 21,
    this.paddingBottom = 124,
    super.key,
  });

  final Widget child;
  final AdminNavigationCallback onNavigate;
  final ScrollController? controller;
  final double paddingTop;
  final double paddingBottom;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 380 ? 14.0 : 18.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: GacColors.canvas,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: GacScreenBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AdminHeader(onNavigate: onNavigate),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: ListView(
                    controller: controller,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      paddingTop,
                      horizontalPadding,
                      paddingBottom,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: child,
                        ),
                      ),
                    ],
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

class AdminHeader extends StatelessWidget {
  const AdminHeader({required this.onNavigate, super.key});

  final AdminNavigationCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final unreadCount = AdminNotificationScope.of(context)?.unreadCount ?? 0;

    return GacGlassSurface(
      borderRadius: 0,
      color: GacColors.glassSurfaceStrong,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AdminHeaderButton(
                label: 'Open administrator profile',
                onTap: () => onNavigate(AdminDestination.profile),
                child: const Icon(
                  Icons.account_circle_outlined,
                  size: 27,
                  color: GacColors.black,
                ),
              ),
              Semantics(
                image: true,
                label: 'Gateway',
                child: Image.asset(
                  'assets/images/no-bg-gateway-logo.png',
                  width: 119,
                  height: 28,
                  fit: BoxFit.contain,
                  color: GacColors.black,
                  colorBlendMode: BlendMode.srcIn,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) => const Text(
                    'GATEWAY',
                    style: TextStyle(
                      color: GacColors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AdminHeaderButton(
                    label: unreadCount > 0
                        ? 'Open administrator notifications, $unreadCount unread'
                        : 'Open administrator notifications',
                    onTap: () => onNavigate(AdminDestination.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_rounded,
                          size: 21,
                          color: GacColors.black,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              width: 9,
                              height: 9,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: GacColors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const SizedBox.square(
                                dimension: 5,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: GacColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  _AdminHeaderButton(
                    label: 'Open administrator settings',
                    onTap: () => onNavigate(AdminDestination.settings),
                    child: const Icon(
                      Icons.settings_outlined,
                        size: 21,
                        color: GacColors.black,
                      ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHeaderButton extends StatefulWidget {
  const _AdminHeaderButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_AdminHeaderButton> createState() => _AdminHeaderButtonState();
}

class _AdminHeaderButtonState extends State<_AdminHeaderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) {
            if (_pressed == pressed) return;
            setState(() => _pressed = pressed);
          },
          customBorder: const CircleBorder(),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: AnimatedOpacity(
            opacity: _pressed ? 0.62 : 1,
            duration: const Duration(milliseconds: 90),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1,
              duration: const Duration(milliseconds: 90),
              child: SizedBox.square(
                dimension: 40,
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
