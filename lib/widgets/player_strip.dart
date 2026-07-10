import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/app_durations.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/l10n/player_color_localizations.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/services/app_settings.dart';
import 'package:ludo_club/theme/player_palette.dart';
import 'package:ludo_club/widgets/player_avatar.dart';

class PlayerStrip extends StatelessWidget {
  const PlayerStrip({required this.state, super.key});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.players, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final player in state.players) ...[
          _PlayerProgressTile(
            player: player,
            isCurrent: player.color == state.currentPlayer.color &&
                state.phase != TurnPhase.gameOver,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PlayerProgressTile extends StatelessWidget {
  const _PlayerProgressTile({required this.player, required this.isCurrent});

  final LudoPlayer player;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = player.color.paint;
    return AnimatedContainer(
      duration: AppMotionSettings.duration(context, AppDurations.normal),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withValues(alpha: 0.12)
            : AppColors.paper.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(
          color: isCurrent ? color : AppColors.brassHairline,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlayerAvatar(
                color: player.color,
                avatarId: player.avatarId,
                size: 34,
                semanticLabel: player.name,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      localizedPlayerColor(l10n, player.color),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.slate500,
                          ),
                    ),
                  ],
                ),
              ),
              if (player.isBot) ...[
                const SizedBox(width: 8),
                Image.asset(
                  AssetMapper.botBadge,
                  width: 24,
                  height: 24,
                  filterQuality: FilterQuality.high,
                ),
              ],
              const SizedBox(width: 8),
              Text(l10n.finishedCount(player.finishedCount)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusLarge),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: player.finishedCount / LudoRules.piecesPerPlayer,
              color: color,
              backgroundColor: color.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}
