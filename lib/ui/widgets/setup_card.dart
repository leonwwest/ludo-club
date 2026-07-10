import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/l10n/player_color_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/services/app_settings.dart';
import 'package:ludo_club/theme/player_palette.dart';
import 'package:ludo_club/widgets/player_avatar.dart';

class SetupCard extends StatelessWidget {
  const SetupCard({
    required this.state,
    required this.onPlayerNameChanged,
    required this.onPlayerKindChanged,
    required this.onPlayerAvatarChanged,
    required this.onBotDifficultyChanged,
    super.key,
  });

  final LudoGameState state;
  final void Function(PlayerColor color, String name) onPlayerNameChanged;
  final void Function(PlayerColor color, PlayerKind kind) onPlayerKindChanged;
  final void Function(PlayerColor color, PlayerAvatarId avatarId)
      onPlayerAvatarChanged;
  final void Function(PlayerColor color, BotDifficulty difficulty)
      onBotDifficultyChanged;

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
              l10n.playerSetup,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final player in state.players) ...[
              PlayerNameRow(
                player: player,
                onSubmitted: (name) => onPlayerNameChanged(player.color, name),
                onKindChanged: (kind) =>
                    onPlayerKindChanged(player.color, kind),
                onAvatarChanged: (avatarId) =>
                    onPlayerAvatarChanged(player.color, avatarId),
                onBotDifficultyChanged: (difficulty) =>
                    onBotDifficultyChanged(player.color, difficulty),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class PlayerNameRow extends StatefulWidget {
  const PlayerNameRow({
    required this.player,
    required this.onSubmitted,
    required this.onKindChanged,
    required this.onAvatarChanged,
    required this.onBotDifficultyChanged,
    super.key,
  });

  final LudoPlayer player;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<PlayerKind> onKindChanged;
  final ValueChanged<PlayerAvatarId> onAvatarChanged;
  final ValueChanged<BotDifficulty> onBotDifficultyChanged;

  @override
  State<PlayerNameRow> createState() => _PlayerNameRowState();
}

class _PlayerNameRowState extends State<PlayerNameRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.player.name);
  }

  @override
  void didUpdateWidget(covariant PlayerNameRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player.name != widget.player.name &&
        _controller.text != widget.player.name) {
      _controller.text = widget.player.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = widget.player.color.paint;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                PlayerAvatar(
                  color: widget.player.color,
                  avatarId: widget.player.avatarId,
                  size: 34,
                  semanticLabel: widget.player.name,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: localizedPlayerColor(
                        l10n,
                        widget.player.color,
                      ),
                    ),
                    onSubmitted: widget.onSubmitted,
                    onEditingComplete: () =>
                        widget.onSubmitted(_controller.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SegmentedButton<PlayerKind>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return color.withValues(alpha: 0.18);
                  }
                  return AppColors.paper.withValues(alpha: 0.72);
                }),
              ),
              segments: [
                ButtonSegment(
                  value: PlayerKind.human,
                  icon: const Icon(Icons.person_outline),
                  label: Text(l10n.human),
                ),
                ButtonSegment(
                  value: PlayerKind.bot,
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: Text(l10n.bot),
                ),
              ],
              selected: {widget.player.kind},
              onSelectionChanged: (selection) =>
                  widget.onKindChanged(selection.first),
            ),
            if (widget.player.isBot) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.botDifficulty,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: 6),
              SegmentedButton<BotDifficulty>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: BotDifficulty.easy,
                    label: Text(l10n.botDifficultyEasy),
                  ),
                  ButtonSegment(
                    value: BotDifficulty.normal,
                    label: Text(l10n.botDifficultyNormal),
                  ),
                  ButtonSegment(
                    value: BotDifficulty.hard,
                    label: Text(l10n.botDifficultyHard),
                  ),
                ],
                selected: {widget.player.botDifficulty},
                onSelectionChanged: (selection) =>
                    widget.onBotDifficultyChanged(selection.first),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final avatarId in PlayerAvatarId.values)
                  _AvatarChoice(
                    color: widget.player.color,
                    avatarId: avatarId,
                    selected: widget.player.avatarId == avatarId,
                    onSelected: () => widget.onAvatarChanged(avatarId),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.color,
    required this.avatarId,
    required this.selected,
    required this.onSelected,
  });

  final PlayerColor color;
  final PlayerAvatarId avatarId;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final paint = color.paint;
    return Tooltip(
      message: avatarId.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: avatarId.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onSelected,
            child: AnimatedContainer(
              duration: AppMotionSettings.duration(
                context,
                const Duration(milliseconds: 160),
              ),
              width: 42,
              height: 42,
              padding: EdgeInsets.all(selected ? 2 : 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? paint.withValues(alpha: 0.16)
                    : AppColors.paper.withValues(alpha: 0.72),
                border: Border.all(
                  color: selected
                      ? paint
                      : AppColors.slate300.withValues(alpha: 0.7),
                  width: selected ? 2 : 1,
                ),
              ),
              child: PlayerAvatar(
                color: color,
                avatarId: avatarId,
                size: selected ? 34 : 32,
                borderWidth: selected ? 2 : 1.2,
                semanticLabel: avatarId.label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
