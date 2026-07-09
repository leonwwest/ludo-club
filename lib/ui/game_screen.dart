import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/app_durations.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:ludo_club/services/game_feedback.dart';
import 'package:ludo_club/theme/player_palette.dart';
import 'package:ludo_club/ui/widgets/header_bar.dart';
import 'package:ludo_club/ui/widgets/mobile_action_dock.dart';
import 'package:ludo_club/ui/widgets/move_log_card.dart';
import 'package:ludo_club/ui/widgets/rule_options_card.dart';
import 'package:ludo_club/ui/widgets/side_panel.dart';
import 'package:ludo_club/ui/widgets/setup_card.dart';
import 'package:ludo_club/widgets/player_avatar.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool? _showLaunchPanel;
  PlayerColor? _announcedWinner;
  int? _lastDiceValue;
  MoveSummary? _lastMoveSummary;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final state = controller.state;
    _showLaunchPanel ??= !controller.hasMoveLog &&
        state.diceValue == null &&
        state.phase == TurnPhase.waitingForRoll;
    final botAutomationActive = _showLaunchPanel != true;
    final isVisibleBotTurn = botAutomationActive && controller.isBotTurn;
    controller.setBotAutomationEnabled(botAutomationActive);
    _handleFeedback(state);

    final isWide =
        MediaQuery.sizeOf(context).width >= AppDimensions.responsiveBreakpoint;
    final pagePadding = isWide
        ? AppDimensions.pagePaddingWide
        : AppDimensions.pagePaddingNarrow;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: isWide ||
              _showLaunchPanel == true ||
              state.phase == TurnPhase.gameOver
          ? null
          : _buildMobileDock(controller, state, isVisibleBotTurn),
      body: ExcludeSemantics(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AssetMapper.background),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                AppColors.backgroundOverlay,
                BlendMode.srcOver,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeaderBar(
                    playerCount: controller.playerCount,
                    canUndo: controller.canUndo,
                    onPlayerCountChanged: (count) => unawaited(
                      _runAction(
                        () => controller.newGame(playerCount: count),
                        FeedbackCue.tap,
                      ),
                    ),
                    onRestart: () => unawaited(_restartFromHeader(controller)),
                    onUndo: () => unawaited(
                      _runAction(
                        controller.undoLastAction,
                        FeedbackCue.tap,
                      ),
                    ),
                    onClearSave: () => unawaited(
                      _runAction(
                        controller.clearSavedGame,
                        FeedbackCue.tap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Stack(
                      children: [
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: BoardStage(state: state)),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: AppDimensions.sidePanelWidth,
                                child: SingleChildScrollView(
                                  child: SidePanel(
                                    state: state,
                                    isBotTurn: isVisibleBotTurn,
                                    onRoll: () => unawaited(
                                      _rollForHuman(controller),
                                    ),
                                    onPlayerNameChanged: (color, name) =>
                                        unawaited(
                                      controller.updatePlayerName(color, name),
                                    ),
                                    onPlayerKindChanged: (color, kind) =>
                                        unawaited(
                                      controller.updatePlayerKind(color, kind),
                                    ),
                                    onPlayerAvatarChanged: (color, avatarId) =>
                                        unawaited(
                                      controller.updatePlayerAvatar(
                                        color,
                                        avatarId,
                                      ),
                                    ),
                                    onRulesChanged: (rules) => unawaited(
                                      controller.updateRules(rules),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          MobileGameLayout(state: state),
                        if (_showLaunchPanel == true)
                          LaunchSetupOverlay(
                            state: state,
                            onPlayerCountChanged: (count) => unawaited(
                              _runAction(
                                () => controller.newGame(playerCount: count),
                                FeedbackCue.tap,
                              ),
                            ),
                            onPlayerKindChanged: (color, kind) => unawaited(
                              controller.updatePlayerKind(color, kind),
                            ),
                            onPlayerAvatarChanged: (color, avatarId) =>
                                unawaited(
                              controller.updatePlayerAvatar(color, avatarId),
                            ),
                            onClassicPreset: () => unawaited(
                              _runAction(
                                () => controller.updateRules(
                                  const RuleOptions(),
                                ),
                                FeedbackCue.tap,
                              ),
                            ),
                            onClubPreset: () => unawaited(
                              _runAction(
                                () => controller.updateRules(
                                  const RuleOptions(
                                    openRollRule: OpenRollRule.threeRolls,
                                    extraTurnOnFinish: true,
                                    threeSixesEndTurn: true,
                                  ),
                                ),
                                FeedbackCue.tap,
                              ),
                            ),
                            onStart: () {
                              _playFeedback(FeedbackCue.start);
                              setState(() => _showLaunchPanel = false);
                              controller.setBotAutomationEnabled(true);
                            },
                          ),
                        if (state.phase == TurnPhase.gameOver)
                          WinnerOverlay(
                            state: state,
                            onRematch: () => unawaited(
                              _runAction(
                                controller.newGame,
                                FeedbackCue.start,
                              ),
                            ),
                            onSetup: () => unawaited(
                              _openSetupForNewGame(controller),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _restartFromHeader(GameController controller) async {
    await _runAction(controller.newGame, FeedbackCue.start);
    if (mounted) {
      setState(() => _showLaunchPanel = false);
    }
  }

  Future<void> _openSetupForNewGame(GameController controller) async {
    await _runAction(controller.newGame, FeedbackCue.start);
    if (mounted) {
      setState(() => _showLaunchPanel = true);
    }
  }

  Widget _buildMobileDock(
    GameController controller,
    LudoGameState state,
    bool isVisibleBotTurn,
  ) {
    return SafeArea(
      top: false,
      child: MobileActionDock(
        state: state,
        isBotTurn: isVisibleBotTurn,
        onRoll: () => unawaited(_rollForHuman(controller)),
        onOpenSetup: _showSetupSheet,
        onOpenRules: _showRulesSheet,
        onOpenMoveLog: () => _showMoveLogSheet(),
      ),
    );
  }

  Future<void> _rollForHuman(GameController controller) async {
    await controller.rollDice();
    if (!mounted) {
      return;
    }
    await Future<void>.delayed(AppDurations.slow);
    if (!mounted || controller.isBotTurn) {
      return;
    }
    await controller.performOnlyLegalMoveIfAvailable();
  }

  void _showSetupSheet() {
    _playFeedback(FeedbackCue.tap);
    _showMobileToolSheet(
      title: AppLocalizations.of(context)!.playerSetup,
      builder: (sheetContext) => Consumer<GameController>(
        builder: (context, controller, _) {
          return SetupCard(
            state: controller.state,
            onPlayerNameChanged: (color, name) => unawaited(
              controller.updatePlayerName(color, name),
            ),
            onPlayerKindChanged: (color, kind) => unawaited(
              controller.updatePlayerKind(color, kind),
            ),
            onPlayerAvatarChanged: (color, avatarId) => unawaited(
              controller.updatePlayerAvatar(color, avatarId),
            ),
          );
        },
      ),
    );
  }

  void _showRulesSheet() {
    _playFeedback(FeedbackCue.tap);
    _showMobileToolSheet(
      title: AppLocalizations.of(context)!.rules,
      builder: (sheetContext) => Consumer<GameController>(
        builder: (context, controller, _) {
          return RuleOptionsCard(
            state: controller.state,
            onRulesChanged: (rules) => unawaited(controller.updateRules(rules)),
          );
        },
      ),
    );
  }

  void _showMoveLogSheet() {
    _playFeedback(FeedbackCue.tap);
    _showMobileToolSheet(
      title: AppLocalizations.of(context)!.moveLog,
      builder: (sheetContext) => Consumer<GameController>(
        builder: (context, controller, _) {
          return MoveLogCard(state: controller.state);
        },
      ),
    );
  }

  void _showMobileToolSheet({
    required String title,
    required WidgetBuilder builder,
  }) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.borderRadiusSmall),
          ),
        ),
        builder: (sheetContext) {
          return Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 10,
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 12,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.86,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(sheetContext)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: builder(sheetContext),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    FeedbackCue cue,
  ) async {
    _playFeedback(cue);
    await action();
  }

  void _handleFeedback(LudoGameState state) {
    if (_lastDiceValue != state.diceValue && state.diceValue != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _playFeedback(FeedbackCue.roll);
        }
      });
    }
    if (_lastMoveSummary != state.moveSummary && state.moveSummary != null) {
      final cue = state.moveSummary!.didCapture
          ? FeedbackCue.capture
          : state.moveSummary!.finished
              ? FeedbackCue.finish
              : FeedbackCue.move;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _playFeedback(cue);
        }
      });
    }
    if (_announcedWinner != state.winner && state.winner != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _playFeedback(FeedbackCue.win);
        }
      });
    }
    _lastDiceValue = state.diceValue;
    _lastMoveSummary = state.moveSummary;
    _announcedWinner = state.winner;
  }

  void _playFeedback(FeedbackCue cue) {
    unawaited(GameFeedback.play(cue));
  }
}

class LaunchSetupOverlay extends StatelessWidget {
  const LaunchSetupOverlay({
    required this.state,
    required this.onPlayerCountChanged,
    required this.onPlayerKindChanged,
    required this.onPlayerAvatarChanged,
    required this.onClassicPreset,
    required this.onClubPreset,
    required this.onStart,
    super.key,
  });

  final LudoGameState state;
  final ValueChanged<int> onPlayerCountChanged;
  final void Function(PlayerColor color, PlayerKind kind) onPlayerKindChanged;
  final void Function(PlayerColor color, PlayerAvatarId avatarId)
      onPlayerAvatarChanged;
  final VoidCallback onClassicPreset;
  final VoidCallback onClubPreset;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.feltDeep.withValues(alpha: 0.78),
          image: DecorationImage(
            image: const AssetImage(AssetMapper.tableSkinNight),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              AppColors.feltDeep.withValues(alpha: 0.62),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 560,
                  maxHeight: constraints.maxHeight - 24,
                ),
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SetupHeroHeader(),
                          const SizedBox(height: 18),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 2, label: Text('2 Spieler')),
                              ButtonSegment(value: 3, label: Text('3 Spieler')),
                              ButtonSegment(value: 4, label: Text('4 Spieler')),
                            ],
                            selected: {state.players.length},
                            onSelectionChanged: (selection) =>
                                onPlayerCountChanged(selection.first),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final player in state.players)
                                _SetupPlayerChip(
                                  player: player,
                                  onToggleKind: () => onPlayerKindChanged(
                                    player.color,
                                    player.isBot
                                        ? PlayerKind.human
                                        : PlayerKind.bot,
                                  ),
                                  onCycleAvatar: () => onPlayerAvatarChanged(
                                    player.color,
                                    _nextAvatar(player.avatarId),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: onClassicPreset,
                                icon: const Icon(Icons.table_bar_outlined),
                                label: const Text('Klassisch'),
                              ),
                              OutlinedButton.icon(
                                onPressed: onClubPreset,
                                icon: const Icon(Icons.auto_awesome_outlined),
                                label: const Text('Club-Preset'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: onStart,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Partie starten'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SetupHeroHeader extends StatelessWidget {
  const _SetupHeroHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      child: SizedBox(
        height: 178,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AssetMapper.setupHero,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.ink.withValues(alpha: 0.08),
                    AppColors.ink.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusSmall,
                      ),
                      border: Border.all(color: AppColors.brassHairline),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        AssetMapper.branding,
                        width: 46,
                        height: 46,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partie einrichten',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppColors.paper,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                        ),
                        Text(
                          'Spieler, Bots und Regeln festlegen.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.paper.withValues(
                                      alpha: 0.76,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupPlayerChip extends StatelessWidget {
  const _SetupPlayerChip({
    required this.player,
    required this.onToggleKind,
    required this.onCycleAvatar,
  });

  final LudoPlayer player;
  final VoidCallback onToggleKind;
  final VoidCallback onCycleAvatar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        onTap: onToggleKind,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: player.color.paint.withValues(alpha: 0.08),
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusLarge),
            border: Border.all(
              color: player.color.paint.withValues(alpha: 0.28),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Avatar wechseln',
                  child: InkResponse(
                    radius: 24,
                    customBorder: const CircleBorder(),
                    onTap: onCycleAvatar,
                    child: PlayerAvatar(
                      color: player.color,
                      avatarId: player.avatarId,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(player.name),
                const SizedBox(width: 8),
                if (player.isBot)
                  Image.asset(
                    AssetMapper.botBadge,
                    width: 22,
                    height: 22,
                    filterQuality: FilterQuality.high,
                  )
                else
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: player.color.paint,
                  ),
                const SizedBox(width: 4),
                Text(
                  player.isBot ? 'Bot' : 'Mensch',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.slate600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

PlayerAvatarId _nextAvatar(PlayerAvatarId current) {
  final values = PlayerAvatarId.values;
  final nextIndex = (values.indexOf(current) + 1) % values.length;
  return values[nextIndex];
}

class WinnerOverlay extends StatelessWidget {
  const WinnerOverlay({
    required this.state,
    required this.onRematch,
    required this.onSetup,
    super.key,
  });

  final LudoGameState state;
  final VoidCallback onRematch;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final winner = state.players.firstWhere(
      (player) => player.color == state.winner,
      orElse: () => state.currentPlayer,
    );
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.feltDeep.withValues(alpha: 0.52),
          image: DecorationImage(
            image: const AssetImage(AssetMapper.tableSkinClassic),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              AppColors.feltDeep.withValues(alpha: 0.7),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: WinCelebration(color: winner.color.paint)),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.42,
                  child: Image.asset(
                    AssetMapper.winnerConfetti,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WinnerHeroHeader(
                          winner: winner,
                          actionCount: state.moveLog.length,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final player in state.players)
                              _WinnerStat(player: player),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: onRematch,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Revanche'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onSetup,
                                icon: const Icon(Icons.tune),
                                label: const Text('Setup'),
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
          ],
        ),
      ),
    );
  }
}

class _WinnerHeroHeader extends StatelessWidget {
  const _WinnerHeroHeader({
    required this.winner,
    required this.actionCount,
  });

  final LudoPlayer winner;
  final int actionCount;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      child: SizedBox(
        height: 112,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AssetMapper.winnerRibbon,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PlayerAvatar(
                        color: winner.color,
                        avatarId: winner.avatarId,
                        size: 72,
                        borderWidth: 3,
                      ),
                      Positioned(
                        right: -11,
                        bottom: -9,
                        child: Image.asset(
                          AssetMapper.winnerTrophyBadge,
                          width: 42,
                          height: 42,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${winner.name} gewinnt',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                        ),
                        Text(
                          '$actionCount protokollierte Aktionen',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.brassDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinnerStat extends StatelessWidget {
  const _WinnerStat({required this.player});

  final LudoPlayer player;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: player.color.paint.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: player.color.paint.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerAvatar(
              color: player.color,
              avatarId: player.avatarId,
              size: 30,
            ),
            const SizedBox(width: 8),
            Text('${player.name}: ${player.finishedCount}/4'),
          ],
        ),
      ),
    );
  }
}

class WinCelebration extends StatefulWidget {
  const WinCelebration({required this.color, super.key});

  final Color color;

  @override
  State<WinCelebration> createState() => _WinCelebrationState();
}

class _WinCelebrationState extends State<WinCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WinCelebrationPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _WinCelebrationPainter extends CustomPainter {
  const _WinCelebrationPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 22; index++) {
      final phase = (progress + index / 22) % 1.0;
      final angle = index * math.pi * 0.618 + phase * math.pi * 0.8;
      final radius = phase * size.shortestSide * 0.52;
      final offset = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final sparkleColor = index.isEven ? AppColors.brass : color;
      paint.color = sparkleColor.withValues(alpha: (1 - phase).clamp(0, 1));
      canvas.drawCircle(offset, 3.5 + (index % 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WinCelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
