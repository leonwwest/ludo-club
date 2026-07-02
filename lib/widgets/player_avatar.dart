import 'package:flutter/material.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/theme/player_palette.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    required this.color,
    this.size = 36,
    this.borderWidth = 2,
    super.key,
  });

  final PlayerColor color;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final paint = color.paint;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: paint, width: borderWidth),
        image: DecorationImage(
          image: AssetImage(AssetMapper.avatarFor(color)),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
