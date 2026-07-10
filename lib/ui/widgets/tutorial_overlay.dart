import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';

class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    required this.step,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  final int step;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  static const stepCount = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = switch (step) {
      0 => (
          icon: Icons.casino_outlined,
          title: l10n.tutorialRollTitle,
          body: l10n.tutorialRollBody,
        ),
      1 => (
          icon: Icons.touch_app_outlined,
          title: l10n.tutorialMoveTitle,
          body: l10n.tutorialMoveBody,
        ),
      _ => (
          icon: Icons.health_and_safety_outlined,
          title: l10n.tutorialSafeTitle,
          body: l10n.tutorialSafeBody,
        ),
    };
    final isLast = step == stepCount - 1;

    return Positioned.fill(
      child: BlockSemantics(
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: l10n.tutorialTitle,
          explicitChildNodes: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.feltDeep.withValues(alpha: 0.88),
              image: DecorationImage(
                image: const AssetImage(AssetMapper.tableSkinNight),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  AppColors.feltDeep.withValues(alpha: 0.78),
                  BlendMode.srcOver,
                ),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.tutorialTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            TextButton(
                              onPressed: onSkip,
                              child: Text(l10n.tutorialSkip),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.teal.withValues(alpha: 0.12),
                              border: Border.all(
                                color: AppColors.brassHairline,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Icon(
                                content.icon,
                                size: 52,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          content.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          content.body,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.slate600,
                                    height: 1.4,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var index = 0; index < stepCount; index++) ...[
                              Semantics(
                                selected: index == step,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: index == step ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: index == step
                                        ? AppColors.brass
                                        : AppColors.slate300,
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.borderRadiusLarge,
                                    ),
                                  ),
                                ),
                              ),
                              if (index != stepCount - 1)
                                const SizedBox(width: 6),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            if (onBack != null) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: onBack,
                                  child: Text(l10n.tutorialBack),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: onNext,
                                icon: Icon(
                                  isLast
                                      ? Icons.play_arrow_rounded
                                      : Icons.arrow_forward_rounded,
                                ),
                                label: Text(
                                  isLast
                                      ? l10n.tutorialDone
                                      : l10n.tutorialNext,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
