import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/l10n/turn_status_formatter.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/theme/player_palette.dart';
import 'package:ludo_club/ui/widgets/board_arena.dart';
import 'package:ludo_club/widgets/dice_panel.dart';
import 'package:ludo_club/widgets/player_avatar.dart';

class MobileActionDock extends StatelessWidget {
  const MobileActionDock({
    required this.state,
    required this.onRoll,
    required this.isBotTurn,
    required this.isRemoteTurn,
    required this.isWaitingForPlayers,
    required this.onOpenSetup,
    required this.onOpenRules,
    required this.onOpenMoveLog,
    required this.onOpenStats,
    super.key,
  });

  final LudoGameState state;
  final VoidCallback onRoll;
  final bool isBotTurn;
  final bool isRemoteTurn;
  final bool isWaitingForPlayers;
  final VoidCallback? onOpenSetup;
  final VoidCallback onOpenRules;
  final VoidCallback onOpenMoveLog;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentColor = state.winner ?? state.currentPlayer.color;
    final currentPlayer = state.players.firstWhere(
      (player) => player.color == currentColor,
      orElse: () => state.currentPlayer,
    );
    final color = currentColor.paint;
    final canRoll =
        state.phase == TurnPhase.waitingForRoll && !isBotTurn && !isRemoteTurn;
    final title = state.phase == TurnPhase.gameOver
        ? l10n.playerWins(currentPlayer.name)
        : l10n.playerTurn(state.currentPlayer.name);
    final actionLabel = canRoll
        ? l10n.playerRolls(state.currentPlayer.name)
        : isRemoteTurn
            ? isWaitingForPlayers
                ? l10n.waitingForRoomPlayers
                : l10n.waitingForRemotePlayer(state.currentPlayer.name)
            : isBotTurn
                ? l10n.botThinking(state.currentPlayer.name)
                : l10n.tapHighlightedPiece;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.headerPanel,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusSmall),
        ),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PlayerAvatar(
                      color: currentColor,
                      avatarId: currentPlayer.avatarId,
                      size: 48,
                      borderWidth: 2.5,
                      semanticLabel: currentPlayer.name,
                    ),
                    Positioned(
                      right: -7,
                      bottom: -6,
                      child: Image.asset(
                        state.phase == TurnPhase.gameOver
                            ? AssetMapper.winnerTrophyBadge
                            : AssetMapper.currentTurnBadge,
                        width: 26,
                        height: 26,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.paper,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      Text(
                        TurnStatusFormatter.format(context, state),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.paper.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 58,
                  height: 58,
                  child: FittedBox(
                    child: AnimatedDiceFace(value: state.diceValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: AppDimensions.minTouchTarget,
              child: canRoll
                  ? FilledButton.icon(
                      onPressed: canRoll ? onRoll : null,
                      icon: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          AssetMapper.diceIdle,
                          width: 22,
                          height: 22,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      label: Text(
                        actionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : Semantics(
                      liveRegion: true,
                      label: actionLabel,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadiusSmall,
                          ),
                          border: Border.all(
                            color: color.withValues(alpha: 0.34),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isRemoteTurn
                                    ? Icons.public
                                    : isBotTurn
                                        ? Icons.smart_toy_outlined
                                        : Icons.touch_app_outlined,
                                color: AppColors.paper,
                              ),
                              const SizedBox(width: 9),
                              Flexible(
                                child: Text(
                                  actionLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: AppColors.paper,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _DockToolButton(
                        label: l10n.players,
                        icon: Icons.group_outlined,
                        onPressed: onOpenSetup,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _DockToolButton(
                        label: l10n.statistics,
                        icon: Icons.bar_chart_outlined,
                        onPressed: onOpenStats,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _DockToolButton(
                        label: l10n.rules,
                        icon: Icons.tune,
                        onPressed: onOpenRules,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _DockToolButton(
                        label: l10n.moveLog,
                        icon: Icons.format_list_bulleted,
                        onPressed: onOpenMoveLog,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DockToolButton extends StatelessWidget {
  const _DockToolButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.minTouchTarget,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          foregroundColor: AppColors.paper,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: const BorderSide(color: AppColors.brassHairline),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusSmall),
          ),
        ),
        icon: Icon(icon, size: 19),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class MobileGameLayout extends StatelessWidget {
  const MobileGameLayout({
    required this.state,
    super.key,
  });

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    return Center(child: BoardArena(state: state));
  }
}
