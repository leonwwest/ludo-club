import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/ui/widgets/board_arena.dart';
import 'package:ludo_club/ui/widgets/move_log_card.dart';
import 'package:ludo_club/ui/widgets/rule_options_card.dart';
import 'package:ludo_club/ui/widgets/setup_card.dart';
import 'package:ludo_club/ui/widgets/status_card.dart';
import 'package:ludo_club/widgets/dice_panel.dart';
import 'package:ludo_club/widgets/player_strip.dart';

class SidePanel extends StatelessWidget {
  const SidePanel({
    required this.state,
    required this.isBotTurn,
    required this.isRemoteTurn,
    required this.isWaitingForPlayers,
    required this.isOnlineMatch,
    required this.canEditRules,
    required this.onRoll,
    required this.onPlayerNameChanged,
    required this.onPlayerKindChanged,
    required this.onPlayerAvatarChanged,
    required this.onBotDifficultyChanged,
    required this.onRulesChanged,
    super.key,
  });

  final LudoGameState state;
  final bool isBotTurn;
  final bool isRemoteTurn;
  final bool isWaitingForPlayers;
  final bool isOnlineMatch;
  final bool canEditRules;
  final VoidCallback onRoll;
  final void Function(PlayerColor color, String name) onPlayerNameChanged;
  final void Function(PlayerColor color, PlayerKind kind) onPlayerKindChanged;
  final void Function(PlayerColor color, PlayerAvatarId avatarId)
      onPlayerAvatarChanged;
  final void Function(PlayerColor color, BotDifficulty difficulty)
      onBotDifficultyChanged;
  final ValueChanged<RuleOptions> onRulesChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusCard(state: state),
        const SizedBox(height: AppDimensions.sectionSpacing),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DicePanel(
              state: state,
              isBotTurn: isBotTurn,
              isRemoteTurn: isRemoteTurn,
              isWaitingForPlayers: isWaitingForPlayers,
              onRoll: onRoll,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.sectionSpacing),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PlayerStrip(state: state),
          ),
        ),
        const SizedBox(height: AppDimensions.sectionSpacing),
        if (!isOnlineMatch) ...[
          SetupCard(
            state: state,
            onPlayerNameChanged: onPlayerNameChanged,
            onPlayerKindChanged: onPlayerKindChanged,
            onPlayerAvatarChanged: onPlayerAvatarChanged,
            onBotDifficultyChanged: onBotDifficultyChanged,
          ),
          const SizedBox(height: AppDimensions.sectionSpacing),
        ],
        RuleOptionsCard(
          state: state,
          onRulesChanged: onRulesChanged,
          enabled: canEditRules,
        ),
        const SizedBox(height: AppDimensions.sectionSpacing),
        MoveLogCard(state: state),
      ],
    );
  }
}

class BoardStage extends StatelessWidget {
  const BoardStage({required this.state, super.key});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    return Center(child: BoardArena(state: state));
  }
}
