import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/widgets/player_avatar.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({required this.state, super.key});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentColor = state.winner ?? state.currentPlayer.color;
    final currentPlayer = state.players.firstWhere(
      (player) => player.color == currentColor,
      orElse: () => state.currentPlayer,
    );
    final title = state.phase == TurnPhase.gameOver
        ? l10n.playerWins(currentColor.label)
        : l10n.playerTurn(state.currentPlayer.name);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlayerAvatar(
                  color: currentColor,
                  avatarId: currentPlayer.avatarId,
                  size: 52,
                  borderWidth: 3,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              state.turnMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.slate600),
            ),
            if (state.phase == TurnPhase.waitingForMove) ...[
              const SizedBox(height: 14),
              MoveHint(state: state),
            ],
          ],
        ),
      ),
    );
  }
}

class MoveHint extends StatelessWidget {
  const MoveHint({required this.state, super.key});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.boardCellAlt.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: AppColors.brassHairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.touch_app_outlined,
              color: AppColors.brassDark,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.tapToMove,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
