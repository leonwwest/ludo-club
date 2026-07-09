import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/app_durations.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';

class DicePanel extends StatelessWidget {
  const DicePanel({
    required this.state,
    required this.onRoll,
    required this.isBotTurn,
    super.key,
  });

  final LudoGameState state;
  final VoidCallback onRoll;
  final bool isBotTurn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canRoll = state.phase == TurnPhase.waitingForRoll && !isBotTurn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                state.phase == TurnPhase.gameOver ? l10n.gameOver : l10n.dice,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            AnimatedDiceFace(value: state.diceValue),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: canRoll ? onRoll : null,
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              AssetMapper.diceIdle,
              width: 22,
              height: 22,
              fit: BoxFit.cover,
            ),
          ),
          label: Text(
            canRoll
                ? l10n.playerRolls(state.currentPlayer.name)
                : isBotTurn
                    ? '${state.currentPlayer.name} denkt ...'
                    : l10n.selectMove,
          ),
        ),
      ],
    );
  }
}

class AnimatedDiceFace extends StatelessWidget {
  const AnimatedDiceFace({required this.value, super.key});

  final int? value;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.normal,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return RotationTransition(
          turns: Tween<double>(begin: -0.16, end: 0).animate(curved),
          child: ScaleTransition(scale: curved, child: child),
        );
      },
      child: DiceFace(
        key: ValueKey(value ?? 0),
        value: value,
      ),
    );
  }
}

class DiceFace extends StatelessWidget {
  const DiceFace({required this.value, super.key});

  final int? value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null) {
      return const ExcludeSemantics(
        child: _DiceAsset(path: AssetMapper.diceIdle),
      );
    }

    return Semantics(
      label: l10n.dice,
      child: _DiceAsset(path: AssetMapper.diceFace(value!)),
    );
  }
}

class _DiceAsset extends StatelessWidget {
  const _DiceAsset({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: AppColors.brass.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        child: Image.asset(
          path,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
