import 'package:flutter/material.dart';

import '../models/authenticated_user.dart';
import '../theme/gac_theme.dart';
import 'gac_surfaces.dart';
import 'user_avatar.dart';

/// Glass, collapsible top bar used only by the user Home screen.
class UserFloatingHeader extends StatelessWidget {
  const UserFloatingHeader({
    required this.expanded,
    required this.onOpenProfile,
    required this.onOpenHome,
    required this.onOpenNotifications,
    required this.user,
    this.unreadNotifications = 0,
    super.key,
  });

  static const double extent = 76;

  final bool expanded;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenNotifications;
  final AuthenticatedUser user;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('user-home-top-bar'),
      tween: Tween<double>(end: expanded ? 0 : 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, collapseProgress, child) {
        double sizeBetween(double expandedSize, double compactSize) {
          return expandedSize + (compactSize - expandedSize) * collapseProgress;
        }

        final profileIconSize = sizeBetween(44, 32);
        final logoWidth = sizeBetween(162, 126);
        final logoHeight = sizeBetween(31, 24);
        final subtitleSize = sizeBetween(8, 6.8);
        final notificationIconSize = sizeBetween(32, 24);
        final badgeSize = sizeBetween(18, 15);

        return SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: GacGlassSurface(
                    borderRadius: 22,
                    blurSigma: 5,
                    shadowBlurRadius: 16,
                    shadowOffset: const Offset(0, 4),
                    child: Row(
                      children: [
                        _TransparentIconButton(
                          key: const ValueKey('user-header-profile'),
                          semanticsLabel: 'Open profile',
                          onTap: onOpenProfile,
                          child: UserAvatar(
                            key: const ValueKey('user-home-profile-icon'),
                            size: profileIconSize,
                            user: user,
                            borderColor: GacColors.white,
                            borderWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _TransparentBrandButton(
                            onTap: onOpenHome,
                            logoWidth: logoWidth,
                            logoHeight: logoHeight,
                            subtitleSize: subtitleSize,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _TransparentIconButton(
                          key: const ValueKey('user-header-notifications'),
                          semanticsLabel: unreadNotifications > 0
                              ? 'Open notifications, $unreadNotifications unread'
                              : 'Open notifications',
                          onTap: onOpenNotifications,
                          child: _NotificationIcon(
                            unreadNotifications: unreadNotifications,
                            iconSize: notificationIconSize,
                            badgeSize: badgeSize,
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
      },
    );
  }
}

class _TransparentBrandButton extends StatelessWidget {
  const _TransparentBrandButton({
    required this.onTap,
    required this.logoWidth,
    required this.logoHeight,
    required this.subtitleSize,
  });

  final VoidCallback onTap;
  final double logoWidth;
  final double logoHeight;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Semantics(
          button: true,
          label: 'GATEWAY Audit Compliance App, return to the top of Home',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: const ValueKey('user-header-home'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: logoHeight,
                      child: Image.asset(
                        'assets/images/no-bg-gateway-logo.png',
                        width: logoWidth,
                        fit: BoxFit.contain,
                        color: GacColors.textPrimary,
                        colorBlendMode: BlendMode.srcIn,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stackTrace) {
                          return const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'GATEWAY',
                              style: TextStyle(
                                color: GacColors.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Audit Compliance App',
                        maxLines: 1,
                        style: TextStyle(
                          color: GacColors.textSecondary,
                          fontSize: subtitleSize,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.05,
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

class _TransparentIconButton extends StatelessWidget {
  const _TransparentIconButton({
    required this.semanticsLabel,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: SizedBox.square(dimension: 56, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({
    required this.unreadNotifications,
    required this.iconSize,
    required this.badgeSize,
  });

  final int unreadNotifications;
  final double iconSize;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Icon(
              Icons.notifications_none_rounded,
              size: iconSize,
              color: GacColors.textPrimary,
            ),
          ),
          if (unreadNotifications > 0)
            Positioned(
              top: 1,
              right: 0,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: badgeSize,
                  minHeight: badgeSize,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: GacColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: GacColors.canvas, width: 1.5),
                ),
                child: Text(
                  unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                  style: TextStyle(
                    color: GacColors.white,
                    fontSize: _badgeFontSize(badgeSize),
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _badgeFontSize(double size) => size >= 17 ? 8 : 7;
}
