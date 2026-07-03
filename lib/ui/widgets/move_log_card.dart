import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/l10n/move_log_formatter.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/theme/player_palette.dart';

class MoveLogCard extends StatelessWidget {
  const MoveLogCard({required this.state, super.key});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.moveLog,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (state.moveLog.isEmpty)
              Text(
                l10n.noMovesYet,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.slate500,
                    ),
              )
            else
              for (final entry in state.moveLog) ...[
                MergeSemantics(
                  child: Row(
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
                          MoveLogFormatter.format(context, entry, state),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}
