import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/assets.dart';

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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              child: Image.asset(
                AssetMapper.branding,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ludo Club',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                  ),
                  Text(
                    'Schlankes lokales Brettspiel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.slate500,
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
              onPressed: canUndo ? onUndo : null,
              icon: const Icon(Icons.undo),
              label: const Text('Zurück'),
            ),
            OutlinedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh),
              label: const Text('Neu starten'),
            ),
            IconButton.outlined(
              tooltip: 'Speicherstand löschen',
              onPressed: onClearSave,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    );
  }
}
