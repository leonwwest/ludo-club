import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/app_durations.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';

class DicePanel extends StatelessWidget {
  const DicePanel({required this.state, required this.onRoll, super.key});

  final LudoGameState state;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canRoll = state.phase == TurnPhase.waitingForRoll;
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
            AnimatedSwitcher(
              duration: AppDurations.normal,
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: DiceFace(
                key: ValueKey(state.diceValue ?? 0),
                value: state.diceValue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: canRoll ? onRoll : null,
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              AssetMapper.dice,
              width: 22,
              height: 22,
              fit: BoxFit.cover,
            ),
          ),
          label: Text(
            canRoll
                ? l10n.playerRolls(state.currentPlayer.name)
                : l10n.selectMove,
          ),
        ),
      ],
    );
  }
}

class DiceFace extends StatelessWidget {
  const DiceFace({required this.value, super.key});

  final int? value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (value == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        child: Image.asset(
          AssetMapper.dice,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DicePainter(
          value: value,
          pipColor: colorScheme.onSurface,
          idleColor: colorScheme.outline,
        ),
      ),
    );
  }
}

class _DicePainter extends CustomPainter {
  const _DicePainter({
    required this.value,
    required this.pipColor,
    required this.idleColor,
  });

  final int? value;
  final Color pipColor;
  final Color idleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = value == null ? idleColor : pipColor;
    final radius = size.shortestSide * 0.055;
    final center = Offset(size.width / 2, size.height / 2);
    final left = Offset(size.width * 0.3, size.height * 0.3);
    final right = Offset(size.width * 0.7, size.height * 0.7);
    final topRight = Offset(size.width * 0.7, size.height * 0.3);
    final bottomLeft = Offset(size.width * 0.3, size.height * 0.7);
    final middleLeft = Offset(size.width * 0.3, size.height * 0.5);
    final middleRight = Offset(size.width * 0.7, size.height * 0.5);

    final pips = switch (value) {
      1 => [center],
      2 => [left, right],
      3 => [left, center, right],
      4 => [left, topRight, bottomLeft, right],
      5 => [left, topRight, center, bottomLeft, right],
      6 => [left, middleLeft, bottomLeft, topRight, middleRight, right],
      _ => [center],
    };

    for (final pip in pips) {
      canvas.drawCircle(pip, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DicePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.pipColor != pipColor ||
        oldDelegate.idleColor != idleColor;
  }
}
