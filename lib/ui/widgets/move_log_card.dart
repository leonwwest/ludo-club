import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/theme/player_palette.dart';

class MoveLogCard extends StatelessWidget {
  const MoveLogCard({required this.state, super.key});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Zugprotokoll',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (state.moveLog.isEmpty)
              Text(
                'Noch keine Züge.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.slate500,
                    ),
              )
            else
              for (final entry in state.moveLog) ...[
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entry.color.paint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}
