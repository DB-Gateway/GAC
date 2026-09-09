import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/authenticated_user.dart';
import '../theme/gac_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.user,
    required this.size,
    this.borderColor,
    this.borderWidth = 0,
    this.backgroundColor = GacColors.navy950,
    this.foregroundColor = GacColors.white,
    super.key,
  });

  final AuthenticatedUser user;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveGacAssetUrl(user.avatarUrl);
    final innerSize = (size - borderWidth * 2).clamp(0.0, size);

    return Semantics(
      image: true,
      label: '${user.name} profile photo',
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          color: borderColor ?? backgroundColor,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: SizedBox.square(
            dimension: innerSize,
            child: imageUrl == null
                ? _Initials(
                    initials: user.initials,
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                    fontSize: size * 0.31,
                  )
                : Image.network(
                    imageUrl,
                    key: ValueKey<String>('user-avatar-$imageUrl'),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => _Initials(
                      initials: user.initials,
                      backgroundColor: backgroundColor,
                      foregroundColor: foregroundColor,
                      fontSize: size * 0.31,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.initials,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.fontSize,
  });

  final String initials;
  final Color backgroundColor;
  final Color foregroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: Text(
          initials,
          maxLines: 1,
          style: TextStyle(
            color: foregroundColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
