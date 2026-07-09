import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
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
    required this.onOpenSetup,
    required this.onOpenRules,
    required this.onOpenMoveLog,
    super.key,
  });

  final LudoGameState state;
  final VoidCallback onRoll;
  final bool isBotTurn;
  final VoidCallback onOpenSetup;
  final VoidCallback onOpenRules;
  final VoidCallback onOpenMoveLog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentColor = state.winner ?? state.currentPlayer.color;
    final currentPlayer = state.players.firstWhere(
      (player) => player.color == currentColor,
      orElse: () => state.currentPlayer,
    );
    final color = currentColor.paint;
    final canRoll = state.phase == TurnPhase.waitingForRoll && !isBotTurn;
    final title = state.phase == TurnPhase.gameOver
        ? l10n.playerWins(currentColor.label)
        : l10n.playerTurn(state.currentPlayer.name);
    final actionLabel = canRoll
        ? l10n.playerRolls(state.currentPlayer.name)
        : isBotTurn
            ? '${state.currentPlayer.name} denkt ...'
            : l10n.selectPiece;

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
                        state.turnMessage,
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
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppDimensions.minTouchTarget,
                    child: FilledButton.icon(
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
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _DockIconButton(
                  tooltip: l10n.playerSetup,
                  icon: Icons.group_outlined,
                  onPressed: onOpenSetup,
                ),
                const SizedBox(width: 8),
                _DockIconButton(
                  tooltip: l10n.rules,
                  icon: Icons.tune,
                  onPressed: onOpenRules,
                ),
                const SizedBox(width: 8),
                _DockIconButton(
                  tooltip: l10n.moveLog,
                  icon: Icons.format_list_bulleted,
                  onPressed: onOpenMoveLog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  const _DockIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppDimensions.minTouchTarget,
      child: IconButton.outlined(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          foregroundColor: AppColors.paper,
          side: const BorderSide(color: AppColors.brassHairline),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusSmall),
          ),
        ),
        icon: Icon(icon),
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
