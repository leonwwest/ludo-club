import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/theme/player_palette.dart';
import 'package:ludo_club/widgets/player_avatar.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({required this.state, super.key});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = state.stats;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.statistics,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in PlayerColor.values)
                  _WinTile(
                    color: color,
                    name: _playerName(color),
                    avatarId: _playerAvatar(color),
                    wins: stats.winsFor(color),
                  ),
              ],
            ),
            const Divider(height: 30),
            Text(
              l10n.currentMatch,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricPill(
                  icon: Icons.casino_outlined,
                  label: l10n.rolls,
                  value: stats.rolls,
                ),
                _MetricPill(
                  icon: Icons.touch_app_outlined,
                  label: l10n.moves,
                  value: stats.moves,
                ),
                _MetricPill(
                  icon: Icons.bolt_outlined,
                  label: l10n.captures,
                  value: stats.captures,
                ),
                _MetricPill(
                  icon: Icons.looks_6_outlined,
                  label: l10n.sixes,
                  value: stats.sixes,
                ),
                _DurationPill(duration: stats.duration),
              ],
            ),
            const Divider(height: 30),
            Text(
              l10n.matchHistory,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            if (stats.history.isEmpty)
              Text(
                l10n.noMatchHistory,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.slate500,
                    ),
              )
            else
              for (final entry in stats.history.take(8)) ...[
                _HistoryTile(
                  winnerName: _playerName(entry.winner),
                  winnerColor: entry.winner,
                  avatarId: _playerAvatar(entry.winner),
                  finishedAt: entry.finishedAt,
                  duration: entry.duration,
                  rolls: entry.rolls,
                  moves: entry.moves,
                  captures: entry.captures,
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }

  String _playerName(PlayerColor color) {
    for (final player in state.players) {
      if (player.color == color) return player.name;
    }
    return color.label;
  }

  PlayerAvatarId? _playerAvatar(PlayerColor color) {
    for (final player in state.players) {
      if (player.color == color) return player.avatarId;
    }
    return null;
  }
}

class _WinTile extends StatelessWidget {
  const _WinTile({
    required this.color,
    required this.name,
    required this.avatarId,
    required this.wins,
  });

  final PlayerColor color;
  final String name;
  final PlayerAvatarId? avatarId;
  final int wins;

  @override
  Widget build(BuildContext context) {
    final paint = color.paint;
    return Semantics(
      label: '$name, ${AppLocalizations.of(context)!.wins(wins)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paint.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          border: Border.all(color: paint.withValues(alpha: 0.24)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: PlayerAvatar(
                  color: color,
                  avatarId: avatarId,
                  size: 30,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    AppLocalizations.of(context)!.wins(wins),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.slate600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.boardCellAlt,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.brassHairline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: AppColors.brassDark),
              const SizedBox(width: 6),
              Text('$label $value'),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final label = _durationLabel(context, duration);
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.boardCellAlt,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.brassHairline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 17,
                color: AppColors.brassDark,
              ),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.winnerName,
    required this.winnerColor,
    required this.avatarId,
    required this.finishedAt,
    required this.duration,
    required this.rolls,
    required this.moves,
    required this.captures,
  });

  final String winnerName;
  final PlayerColor winnerColor;
  final PlayerAvatarId? avatarId;
  final DateTime finishedAt;
  final Duration duration;
  final int rolls;
  final int moves;
  final int captures;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localDate = finishedAt.toLocal();
    final materialL10n = MaterialLocalizations.of(context);
    final date = materialL10n.formatMediumDate(localDate);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: winnerColor.paint.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: AppColors.brassHairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            PlayerAvatar(
              color: winnerColor,
              avatarId: avatarId,
              size: 34,
              semanticLabel: winnerName,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.historyEntry(winnerName, date),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    '${_durationLabel(context, duration)} · ${l10n.rolls} $rolls · ${l10n.moves} $moves · ${l10n.captures} $captures',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.slate600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _durationLabel(BuildContext context, Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return AppLocalizations.of(context)!.matchDuration(minutes, seconds);
}
