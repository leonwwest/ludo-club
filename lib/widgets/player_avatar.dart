import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/theme/player_palette.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    required this.color,
    this.avatarId,
    this.size = 36,
    this.borderWidth = 2,
    this.semanticLabel,
    super.key,
  });

  final PlayerColor color;
  final PlayerAvatarId? avatarId;
  final double size;
  final double borderWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final paint = color.paint;
    return Semantics(
      label: semanticLabel ?? color.label,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.paper,
          border: Border.all(color: paint, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: paint.withValues(alpha: 0.24),
              blurRadius: size * 0.24,
              offset: Offset(0, size * 0.08),
            ),
            const BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          image: DecorationImage(
            image: AssetImage(
              avatarId == null
                  ? AssetMapper.avatarFor(color)
                  : AssetMapper.avatarForId(avatarId!),
            ),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
