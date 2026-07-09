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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.headerPanel,
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusSmall),
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
            padding: EdgeInsets.all(isCompact ? 10 : 12),
            child: isCompact
                ? _CompactHeaderContent(
                    canUndo: canUndo,
                    onRestart: onRestart,
                    onUndo: onUndo,
                    onClearSave: onClearSave,
                  )
                : _WideHeaderContent(
                    playerCount: playerCount,
                    canUndo: canUndo,
                    onPlayerCountChanged: onPlayerCountChanged,
                    onRestart: onRestart,
                    onUndo: onUndo,
                    onClearSave: onClearSave,
                  ),
          ),
        );
      },
    );
  }
}

class _WideHeaderContent extends StatelessWidget {
  const _WideHeaderContent({
    required this.playerCount,
    required this.canUndo,
    required this.onPlayerCountChanged,
    required this.onRestart,
    required this.onUndo,
    required this.onClearSave,
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
    final toolbarButtonStyle = _toolbarButtonStyle();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        const _HeaderBrand(showSubtitle: true),
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
            _HeaderIconButton(
              tooltip: l10n.clearSave,
              icon: Icons.delete_outline,
              onPressed: onClearSave,
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactHeaderContent extends StatelessWidget {
  const _CompactHeaderContent({
    required this.canUndo,
    required this.onRestart,
    required this.onUndo,
    required this.onClearSave,
  });

  final bool canUndo;
  final VoidCallback onRestart;
  final VoidCallback onUndo;
  final VoidCallback onClearSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        const Expanded(child: _HeaderBrand(showSubtitle: false)),
        const SizedBox(width: 8),
        _HeaderIconButton(
          tooltip: l10n.undo,
          icon: Icons.undo,
          onPressed: canUndo ? onUndo : null,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          tooltip: l10n.newGame,
          icon: Icons.refresh,
          onPressed: onRestart,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          tooltip: l10n.clearSave,
          icon: Icons.delete_outline,
          onPressed: onClearSave,
        ),
      ],
    );
  }
}

class _HeaderBrand extends StatelessWidget {
  const _HeaderBrand({required this.showSubtitle});

  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (showSubtitle
                  ? Theme.of(context).textTheme.headlineMedium
                  : Theme.of(context).textTheme.titleLarge)
              ?.copyWith(
            color: AppColors.paper,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        if (showSubtitle)
          Text(
            l10n.appSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.paper.withValues(alpha: 0.7),
                ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedWidth = constraints.maxWidth.isFinite;
        final logoSize = showSubtitle ? 48.0 : 34.0;
        final textChild = hasBoundedWidth
            ? Expanded(child: title)
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: showSubtitle ? 280 : 170),
                child: title,
              );
        return Row(
          mainAxisSize: hasBoundedWidth ? MainAxisSize.max : MainAxisSize.min,
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
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(width: showSubtitle ? 12 : 8),
            textChild,
          ],
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        foregroundColor: AppColors.paper,
        disabledForegroundColor: AppColors.paper.withValues(alpha: 0.38),
        side: const BorderSide(color: AppColors.brassHairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        ),
      ),
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

ButtonStyle _toolbarButtonStyle() {
  return OutlinedButton.styleFrom(
    backgroundColor: Colors.white.withValues(alpha: 0.06),
    foregroundColor: AppColors.paper,
    disabledForegroundColor: AppColors.paper.withValues(alpha: 0.38),
    side: const BorderSide(color: AppColors.brassHairline),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
    ),
  );
}
