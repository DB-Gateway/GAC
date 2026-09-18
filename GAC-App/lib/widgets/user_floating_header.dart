import 'package:flutter/material.dart';

import '../models/authenticated_user.dart';
import '../theme/gac_theme.dart';
import 'gac_surfaces.dart';
import 'user_avatar.dart';

const _headerFontFamily = 'EurostileExtendedBlack';

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
        final logoWidth = sizeBetween(180, 130);
        final logoHeight = sizeBetween(22, 18);
        final subtitleSize = sizeBetween(8, 6.8);
        final notificationIconSize = sizeBetween(32, 24);
        final badgeSize = sizeBetween(18, 15);

        return SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          dimension: 48,
                          child: UserAvatar(
                            key: const ValueKey('user-home-profile-icon'),
                            size: profileIconSize,
                            user: user,
                            borderColor: GacColors.white,
                            borderWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _TransparentBrandButton(
                            onTap: onOpenHome,
                            logoWidth: logoWidth,
                            logoHeight: logoHeight,
                            subtitleSize: subtitleSize,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _TransparentIconButton(
                          key: const ValueKey('user-header-notifications'),
                          semanticsLabel: unreadNotifications > 0
                              ? 'Open notifications, $unreadNotifications unread'
                              : 'Open notifications',
                          onTap: onOpenNotifications,
                          dimension: 48,
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
        constraints: const BoxConstraints(maxWidth: 320),
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
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _GatewayBrandLogo(
                          width: logoWidth,
                          height: logoHeight,
                        ),
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
                          fontFamily: _headerFontFamily,
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

class _GatewayBrandLogo extends StatefulWidget {
  const _GatewayBrandLogo({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  State<_GatewayBrandLogo> createState() => _GatewayBrandLogoState();
}

class _GatewayBrandLogoState extends State<_GatewayBrandLogo> {
  static bool _evicted = false;
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_evicted) {
      _evicted = true;
      const AssetImage('assets/images/no-bg-gateway-logo.png').evict();
    }
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _GatewayBrandLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveImage();
  }

  void _resolveImage() {
    final provider = const AssetImage('assets/images/no-bg-gateway-logo.png');
    final newStream = provider.resolve(createLocalImageConfiguration(context));
    if (_imageStream?.key != newStream.key) {
      _imageStream?.removeListener(ImageStreamListener(_onImage));
      _imageStream = newStream;
      _imageStream!.addListener(ImageStreamListener(_onImage));
    }
  }

  void _onImage(ImageInfo info, bool synchronousCall) {
    if (mounted && _imageInfo?.image != info.image) {
      setState(() {
        _imageInfo = info;
      });
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener(_onImage));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If the image in memory is the uncropped asset (canvas height 114 with ~70% blank padding),
    // clip and scale so the visible center artwork fills the box.
    final isUncroppedAsset = _imageInfo != null && _imageInfo!.image.height > 60;

    final imageWidget = Image.asset(
      'assets/images/no-bg-gateway-logo.png',
      width: isUncroppedAsset ? widget.width / 0.89 : widget.width,
      height: isUncroppedAsset ? widget.height / 0.35 : widget.height,
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
              fontSize: 20,
              fontFamily: _headerFontFamily,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        );
      },
    );

    if (isUncroppedAsset) {
      return ClipRect(
        child: Align(
          alignment: const Alignment(0.11, 0.0),
          heightFactor: 0.35,
          widthFactor: 0.89,
          child: imageWidget,
        ),
      );
    }

    return imageWidget;
  }
}

class _TransparentIconButton extends StatelessWidget {
  const _TransparentIconButton({
    required this.semanticsLabel,
    required this.onTap,
    required this.child,
    this.dimension = 56,
    super.key,
  });

  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget child;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: onTap,
          radius: dimension / 2,
          child: SizedBox.square(dimension: dimension, child: Center(child: child)),
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
                    fontFamily: _headerFontFamily,
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

/// Glass, collapsible top bar used by checklist lists and detail screens.
class UserChecklistFloatingHeader extends StatelessWidget {
  const UserChecklistFloatingHeader({
    required this.expanded,
    required this.onOpenNotifications,
    this.title = 'Checklists',
    this.subtitle = 'Audit Compliance App',
    this.fontFamily = _headerFontFamily,
    this.user,
    this.onBack,
    this.onOpenProfile,
    this.backLabel = 'Back to home',
    this.onTapTitle,
    this.unreadNotifications = 0,
    super.key,
  });

  static const double extent = 76;

  final bool expanded;
  final String title;
  final String? subtitle;
  final String? fontFamily;
  final AuthenticatedUser? user;
  final VoidCallback? onBack;
  final VoidCallback? onOpenProfile;
  final String backLabel;
  final VoidCallback onOpenNotifications;
  final VoidCallback? onTapTitle;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('user-checklist-top-bar'),
      tween: Tween<double>(end: expanded ? 0 : 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, collapseProgress, child) {
        double sizeBetween(double expandedSize, double compactSize) {
          return expandedSize + (compactSize - expandedSize) * collapseProgress;
        }

        final profileIconSize = sizeBetween(44, 32);
        final titleSize = sizeBetween(18, 15);
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
                        if (onBack != null)
                          Tooltip(
                            message: backLabel,
                            child: _TransparentIconButton(
                              key: const ValueKey('checklist-back-button'),
                              semanticsLabel: backLabel,
                              onTap: onBack!,
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                size: 22,
                                color: GacColors.textPrimary,
                              ),
                            ),
                          )
                        else if (user != null)
                          _TransparentIconButton(
                            key: const ValueKey('user-header-profile'),
                            semanticsLabel: 'Open profile',
                            onTap: onOpenProfile ?? () {},
                            child: UserAvatar(
                              key: const ValueKey('user-checklist-profile-icon'),
                              size: profileIconSize,
                              user: user!,
                              borderColor: GacColors.white,
                              borderWidth: 2,
                            ),
                          )
                        else
                          const SizedBox.square(dimension: 56),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _TransparentTitleButton(
                            title: title,
                            subtitle: subtitle,
                            fontFamily: fontFamily,
                            onTap: onTapTitle,
                            titleSize: titleSize,
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

class _TransparentTitleButton extends StatelessWidget {
  const _TransparentTitleButton({
    required this.title,
    required this.titleSize,
    required this.subtitleSize,
    this.subtitle,
    this.onTap,
    this.fontFamily = _headerFontFamily,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double titleSize;
  final double subtitleSize;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Semantics(
          button: true,
          label: '$title${subtitle != null ? ', $subtitle' : ''}, return to top of checklists',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: const ValueKey('checklist-header-title'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: TextStyle(
                          color: GacColors.textPrimary,
                          fontSize: titleSize,
                          fontFamily: fontFamily,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          style: TextStyle(
                            color: GacColors.textSecondary,
                            fontSize: subtitleSize,
                            fontFamily: fontFamily,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.05,
                          ),
                        ),
                      ),
                    ],
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

/// Glass, collapsible top bar used by the user Profile screen.
class UserProfileFloatingHeader extends StatelessWidget {
  const UserProfileFloatingHeader({
    required this.expanded,
    required this.onOpenNotifications,
    this.title = 'Profile',
    this.subtitle = 'Audit Compliance App',
    this.user,
    this.onBack,
    this.onTapTitle,
    this.unreadNotifications = 0,
    super.key,
  });

  static const double extent = 76;

  final bool expanded;
  final String title;
  final String? subtitle;
  final AuthenticatedUser? user;
  final VoidCallback? onBack;
  final VoidCallback onOpenNotifications;
  final VoidCallback? onTapTitle;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('user-profile-top-bar'),
      tween: Tween<double>(end: expanded ? 0 : 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, collapseProgress, child) {
        double sizeBetween(double expandedSize, double compactSize) {
          return expandedSize + (compactSize - expandedSize) * collapseProgress;
        }

        final profileIconSize = sizeBetween(44, 32);
        final titleSize = sizeBetween(18, 15);
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
                        if (onBack != null)
                          _TransparentIconButton(
                            key: const ValueKey('profile-back-button'),
                            semanticsLabel: 'Back to home',
                            onTap: onBack!,
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 22,
                              color: GacColors.textPrimary,
                            ),
                          )
                        else if (user != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: UserAvatar(
                              key: const ValueKey('user-profile-header-icon'),
                              size: profileIconSize,
                              user: user!,
                              borderColor: GacColors.white,
                              borderWidth: 2,
                            ),
                          )
                        else
                          const SizedBox.square(dimension: 56),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _TransparentTitleButton(
                            title: title,
                            subtitle: subtitle,
                            onTap: onTapTitle,
                            titleSize: titleSize,
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
