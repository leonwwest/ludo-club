import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    required this.playerCount,
    required this.canUndo,
    required this.onNewGame,
    required this.onUndo,
    required this.onClearSave,
    required this.onOpenSettings,
    required this.onOpenStats,
    super.key,
  });

  final int playerCount;
  final bool canUndo;
  final VoidCallback onNewGame;
  final VoidCallback onUndo;
  final VoidCallback onClearSave;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 980;
        return Semantics(
          container: true,
          header: true,
          child: DecoratedBox(
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
                      onNewGame: onNewGame,
                      onUndo: onUndo,
                      onClearSave: onClearSave,
                      onOpenSettings: onOpenSettings,
                      onOpenStats: onOpenStats,
                    )
                  : _WideHeaderContent(
                      playerCount: playerCount,
                      canUndo: canUndo,
                      onNewGame: onNewGame,
                      onUndo: onUndo,
                      onClearSave: onClearSave,
                      onOpenSettings: onOpenSettings,
                      onOpenStats: onOpenStats,
                    ),
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
    required this.onNewGame,
    required this.onUndo,
    required this.onClearSave,
    required this.onOpenSettings,
    required this.onOpenStats,
  });

  final int playerCount;
  final bool canUndo;
  final VoidCallback onNewGame;
  final VoidCallback onUndo;
  final VoidCallback onClearSave;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final toolbarButtonStyle = _toolbarButtonStyle();

    return Row(
      children: [
        const Expanded(child: _HeaderBrand(showSubtitle: true)),
        const SizedBox(width: 18),
        Flexible(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.end,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brass.withValues(alpha: 0.16),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusSmall),
                  border: Border.all(color: AppColors.brassHairline),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    l10n.playerCountLabel(playerCount),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.paper,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              OutlinedButton.icon(
                style: toolbarButtonStyle,
                onPressed: canUndo ? onUndo : null,
                icon: const Icon(Icons.undo),
                label: Text(l10n.undo),
              ),
              OutlinedButton.icon(
                style: toolbarButtonStyle,
                onPressed: onNewGame,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(l10n.newGameSetup),
              ),
              _HeaderIconButton(
                tooltip: l10n.statistics,
                icon: Icons.bar_chart_outlined,
                onPressed: onOpenStats,
              ),
              _HeaderIconButton(
                tooltip: l10n.settings,
                icon: Icons.settings_outlined,
                onPressed: onOpenSettings,
              ),
              _HeaderMenuButton(
                onClearSave: onClearSave,
                onOpenSettings: onOpenSettings,
                includeSettings: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactHeaderContent extends StatelessWidget {
  const _CompactHeaderContent({
    required this.canUndo,
    required this.onNewGame,
    required this.onUndo,
    required this.onClearSave,
    required this.onOpenSettings,
    required this.onOpenStats,
  });

  final bool canUndo;
  final VoidCallback onNewGame;
  final VoidCallback onUndo;
  final VoidCallback onClearSave;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenStats;

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
          icon: Icons.add_circle_outline,
          onPressed: onNewGame,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          tooltip: l10n.statistics,
          icon: Icons.bar_chart_outlined,
          onPressed: onOpenStats,
        ),
        const SizedBox(width: 6),
        _HeaderMenuButton(
          onClearSave: onClearSave,
          onOpenSettings: onOpenSettings,
          includeSettings: true,
        ),
      ],
    );
  }
}

class _HeaderMenuButton extends StatelessWidget {
  const _HeaderMenuButton({
    required this.onClearSave,
    required this.onOpenSettings,
    required this.includeSettings,
  });

  final VoidCallback onClearSave;
  final VoidCallback onOpenSettings;
  final bool includeSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_HeaderMenuAction>(
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      color: AppColors.paper,
      onSelected: (action) {
        switch (action) {
          case _HeaderMenuAction.settings:
            onOpenSettings();
          case _HeaderMenuAction.clearSave:
            onClearSave();
        }
      },
      itemBuilder: (context) => [
        if (includeSettings)
          PopupMenuItem<_HeaderMenuAction>(
            value: _HeaderMenuAction.settings,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.settings),
            ),
          ),
        PopupMenuItem<_HeaderMenuAction>(
          value: _HeaderMenuAction.clearSave,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.clearSave),
          ),
        ),
      ],
      icon: const Icon(Icons.more_horiz),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        foregroundColor: AppColors.paper,
        side: const BorderSide(color: AppColors.brassHairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        ),
      ),
    );
  }
}

enum _HeaderMenuAction { settings, clearSave }

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
