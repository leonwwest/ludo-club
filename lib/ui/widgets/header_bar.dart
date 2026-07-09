import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    required this.playerCount,
    required this.canUndo,
    required this.onPlayerCountChanged,
    required this.onRestart,
    required this.onUndo,
    required this.onClearSave,
    super.key,
  });

  final int playerCount;
  final bool canUndo;
  final ValueChanged<int> onPlayerCountChanged;
  final VoidCallback onRestart;
  final VoidCallback onUndo;
  final VoidCallback onClearSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final toolbarButtonStyle = OutlinedButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      foregroundColor: AppColors.paper,
      disabledForegroundColor: AppColors.paper.withValues(alpha: 0.38),
      side: const BorderSide(color: AppColors.brassHairline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.headerPanel,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: AppColors.brassHairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusSmall,
                      ),
                      border: Border.all(color: AppColors.brassHairline),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        AssetMapper.branding,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppColors.paper,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                      ),
                      Text(
                        l10n.appSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.paper.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<int>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.brass;
                      }
                      return Colors.white.withValues(alpha: 0.08);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.ink;
                      }
                      return AppColors.paper;
                    }),
                    side: WidgetStateProperty.all(
                      const BorderSide(color: AppColors.brassHairline),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                    ButtonSegment(value: 4, label: Text('4')),
                  ],
                  selected: {playerCount},
                  onSelectionChanged: (selection) =>
                      onPlayerCountChanged(selection.first),
                ),
                OutlinedButton.icon(
                  style: toolbarButtonStyle,
                  onPressed: canUndo ? onUndo : null,
                  icon: const Icon(Icons.undo),
                  label: Text(l10n.undo),
                ),
                OutlinedButton.icon(
                  style: toolbarButtonStyle,
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.newGame),
                ),
                IconButton.outlined(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    foregroundColor: AppColors.paper,
                    disabledForegroundColor:
                        AppColors.paper.withValues(alpha: 0.38),
                    side: const BorderSide(color: AppColors.brassHairline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusSmall,
                      ),
                    ),
                  ),
                  tooltip: l10n.clearSave,
                  onPressed: onClearSave,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
