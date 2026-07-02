import 'package:flutter/material.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/widgets/player_avatar.dart';

class SetupCard extends StatelessWidget {
  const SetupCard({
    required this.state,
    required this.onPlayerNameChanged,
    super.key,
  });

  final LudoGameState state;
  final void Function(PlayerColor color, String name) onPlayerNameChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Spieler-Setup',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final player in state.players) ...[
              PlayerNameRow(
                player: player,
                onSubmitted: (name) => onPlayerNameChanged(player.color, name),
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
    super.key,
  });

  final LudoPlayer player;
  final ValueChanged<String> onSubmitted;

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
    return Row(
      children: [
        PlayerAvatar(color: widget.player.color, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              isDense: true,
              labelText: widget.player.color.colorLabel,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: widget.onSubmitted,
            onEditingComplete: () => widget.onSubmitted(_controller.text),
          ),
        ),
      ],
    );
  }
}
