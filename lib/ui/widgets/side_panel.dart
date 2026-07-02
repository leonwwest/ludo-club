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
    required this.onRoll,
    required this.onPlayerNameChanged,
    required this.onRulesChanged,
    super.key,
  });

  final LudoGameState state;
  final VoidCallback onRoll;
  final void Function(PlayerColor color, String name) onPlayerNameChanged;
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
            child: DicePanel(state: state, onRoll: onRoll),
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
        SetupCard(state: state, onPlayerNameChanged: onPlayerNameChanged),
        const SizedBox(height: AppDimensions.sectionSpacing),
        RuleOptionsCard(state: state, onRulesChanged: onRulesChanged),
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
