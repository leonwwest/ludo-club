import 'package:flutter/material.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/theme/player_palette.dart';

class PlayerStrip extends StatelessWidget {
  const PlayerStrip({required this.state, super.key});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Spieler', style: Theme.of(context).textTheme.titleMedium),
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
    final color = player.color.paint;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isCurrent ? color.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? color : const Color(0xFFE2E8F0),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                  image: DecorationImage(
                    image: AssetImage(player.color.avatarAsset),
                    fit: BoxFit.cover,
                  ),
                ),
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
                      player.color.colorLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
              ),
              Text('${player.finishedCount}/4'),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
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
