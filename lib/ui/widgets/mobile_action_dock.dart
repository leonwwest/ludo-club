import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/theme/player_palette.dart';
import 'package:ludo_club/ui/widgets/board_arena.dart';
import 'package:ludo_club/ui/widgets/move_log_card.dart';
import 'package:ludo_club/ui/widgets/rule_options_card.dart';
import 'package:ludo_club/ui/widgets/setup_card.dart';
import 'package:ludo_club/widgets/dice_panel.dart';
import 'package:ludo_club/widgets/player_avatar.dart';

class MobileActionDock extends StatelessWidget {
  const MobileActionDock({
    required this.state,
    required this.onRoll,
    super.key,
  });

  final LudoGameState state;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    final currentColor = state.winner ?? state.currentPlayer.color;
    final color = currentColor.paint;
    final canRoll = state.phase == TurnPhase.waitingForRoll;
    final title = state.phase == TurnPhase.gameOver
        ? '${currentColor.label} gewinnt'
        : '${state.currentPlayer.name} ist dran';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PlayerAvatar(color: currentColor, size: 48, borderWidth: 2.5),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      Text(
                        state.turnMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.slate500,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 58,
                  height: 58,
                  child: FittedBox(child: DiceFace(value: state.diceValue)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: canRoll ? onRoll : null,
                icon: const Icon(Icons.casino_outlined),
                label: Text(
                  canRoll
                      ? '${state.currentPlayer.name} würfelt'
                      : 'Figur auswählen',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileGameLayout extends StatelessWidget {
  const MobileGameLayout({
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
        BoardArena(state: state),
        const SizedBox(height: AppDimensions.sectionSpacing),
        MobileActionDock(state: state, onRoll: onRoll),
        const SizedBox(height: AppDimensions.sectionSpacing),
        SetupCard(state: state, onPlayerNameChanged: onPlayerNameChanged),
        const SizedBox(height: AppDimensions.sectionSpacing),
        RuleOptionsCard(state: state, onRulesChanged: onRulesChanged),
        const SizedBox(height: AppDimensions.sectionSpacing),
        MoveLogCard(state: state),
        const SizedBox(height: AppDimensions.sectionSpacing),
      ],
    );
  }
}
