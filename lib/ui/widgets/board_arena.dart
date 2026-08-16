import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/app_durations.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/l10n/player_color_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/services/app_settings.dart';
import 'package:ludo_club/theme/player_palette.dart';
import 'package:ludo_club/widgets/ludo_board.dart';
import 'package:ludo_club/widgets/player_avatar.dart';

class BoardArena extends StatelessWidget {
  const BoardArena({required this.state, super.key});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    const badgeHeight = AppDimensions.cornerBadgeHeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final heightCap = constraints.maxHeight.isFinite
            ? math.max(220.0, constraints.maxHeight - badgeHeight)
            : constraints.maxWidth;
        final rawBoardSize = math.min(constraints.maxWidth, heightCap);
        final boardSize = rawBoardSize
            .clamp(
              math.min(AppDimensions.boardSizeMin, rawBoardSize),
              AppDimensions.boardSizeMax,
            )
            .toDouble();
        final badgeWidth = (boardSize * 0.43)
            .clamp(
              AppDimensions.badgeWidthMin,
              AppDimensions.badgeWidthMax,
            )
            .toDouble();
        final arenaHeight = boardSize + badgeHeight;
        final boardTop = badgeHeight * AppDimensions.cornerBoardTopFactor;

        final corners = _cornerPlacements(state);

        return SizedBox(
          width: boardSize,
          height: arenaHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: boardTop,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox.square(
                    dimension: boardSize,
                    child: const LudoBoard(),
                  ),
                ),
              ),
              for (final corner in corners)
                _CornerPlayerBadge(
                  player: corner.player,
                  isCurrent: corner.isCurrent,
                  width: badgeWidth,
                  alignment: corner.alignment,
                ),
            ],
          ),
        );
      },
    );
  }

  List<_CornerPlacement> _cornerPlacements(LudoGameState state) {
    final byColor = {
      for (final player in state.players) player.color: player,
    };
    final isGameOver = state.phase == TurnPhase.gameOver;
    return [
      _CornerPlacement(
        player: byColor[PlayerColor.yellow],
        isCurrent:
            !isGameOver && state.currentPlayer.color == PlayerColor.yellow,
        alignment: _CornerAlignment.topLeft,
      ),
      _CornerPlacement(
        player: byColor[PlayerColor.red],
        isCurrent: !isGameOver && state.currentPlayer.color == PlayerColor.red,
        alignment: _CornerAlignment.topRight,
      ),
      _CornerPlacement(
        player: byColor[PlayerColor.blue],
        isCurrent: !isGameOver && state.currentPlayer.color == PlayerColor.blue,
        alignment: _CornerAlignment.bottomLeft,
      ),
      _CornerPlacement(
        player: byColor[PlayerColor.green],
        isCurrent:
            !isGameOver && state.currentPlayer.color == PlayerColor.green,
        alignment: _CornerAlignment.bottomRight,
      ),
    ];
  }
}

enum _CornerAlignment { topLeft, topRight, bottomLeft, bottomRight }

class _CornerPlacement {
  const _CornerPlacement({
    required this.player,
    required this.isCurrent,
    required this.alignment,
  });

  final LudoPlayer? player;
  final bool isCurrent;
  final _CornerAlignment alignment;
}

class _CornerPlayerBadge extends StatelessWidget {
  const _CornerPlayerBadge({
    required this.player,
    required this.isCurrent,
    required this.width,
    required this.alignment,
  });

  final LudoPlayer? player;
  final bool isCurrent;
  final double width;
  final _CornerAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final player = this.player;
    if (player == null) {
      return const SizedBox.shrink();
    }

    final color = player.color.paint;
    final content = AnimatedContainer(
      duration: AppMotionSettings.duration(context, AppDurations.normal),
      width: width,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.cardSurface
            : AppColors.cardSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(
          color: isCurrent ? color : AppColors.brassHairline,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isCurrent ? 0.26 : 0.1),
            blurRadius: isCurrent ? 18 : 10,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          PlayerAvatar(
            color: player.color,
            avatarId: player.avatarId,
            semanticLabel: player.name,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${localizedPlayerColor(AppLocalizations.of(context)!, player.color)}  ${AppLocalizations.of(context)!.finishedCount(player.finishedCount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.slate500,
                        height: 1.05,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final badge = AnimatedScale(
      duration: AppMotionSettings.duration(context, AppDurations.normal),
      scale: isCurrent ? 1.04 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          if (isCurrent)
            Positioned(
              top: -15,
              right: -12,
              child: Image.asset(
                AssetMapper.currentTurnBadge,
                width: 42,
                height: 42,
                filterQuality: FilterQuality.high,
              ),
            ),
          if (player.isBot)
            Positioned(
              right: -8,
              bottom: -9,
              child: Image.asset(
                AssetMapper.botBadge,
                width: 30,
                height: 30,
                filterQuality: FilterQuality.high,
              ),
            ),
        ],
      ),
    );

    return switch (alignment) {
      _CornerAlignment.topLeft => Positioned(top: 0, left: 0, child: badge),
      _CornerAlignment.topRight => Positioned(top: 0, right: 0, child: badge),
      _CornerAlignment.bottomLeft =>
        Positioned(bottom: 0, left: 0, child: badge),
      _CornerAlignment.bottomRight =>
        Positioned(bottom: 0, right: 0, child: badge),
    };
  }
}
