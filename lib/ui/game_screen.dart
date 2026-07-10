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
import 'package:ludo_club/services/app_settings.dart';
import 'package:ludo_club/services/game_feedback.dart';
import 'package:ludo_club/theme/player_palette.dart';
import 'package:ludo_club/ui/widgets/header_bar.dart';
import 'package:ludo_club/ui/widgets/mobile_action_dock.dart';
import 'package:ludo_club/ui/widgets/move_log_card.dart';
import 'package:ludo_club/ui/widgets/online_room_sheet.dart';
import 'package:ludo_club/ui/widgets/rule_options_card.dart';
import 'package:ludo_club/ui/widgets/side_panel.dart';
import 'package:ludo_club/ui/widgets/setup_card.dart';
import 'package:ludo_club/ui/widgets/settings_card.dart';
import 'package:ludo_club/ui/widgets/stats_card.dart';
import 'package:ludo_club/ui/widgets/tutorial_overlay.dart';
import 'package:ludo_club/widgets/player_avatar.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  bool? _showLaunchPanel;
  int? _tutorialStep;
  bool _tutorialScheduled = false;
  PlayerColor? _announcedWinner;
  int? _lastDiceValue;
  MoveSummary? _lastMoveSummary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(context.read<GameController>().flushStorage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final settings = context.watch<AppSettingsController>();
    final state = controller.state;
    _showLaunchPanel ??= !controller.hasMoveLog &&
        state.diceValue == null &&
        state.phase == TurnPhase.waitingForRoll;
    final botAutomationActive =
        _showLaunchPanel != true && _tutorialStep == null;
    final isVisibleBotTurn = botAutomationActive && controller.isBotTurn;
    final isVisibleRemoteTurn = botAutomationActive && controller.isRemoteTurn;
    final isWaitingForOnlinePlayers =
        botAutomationActive && controller.isWaitingForOnlinePlayers;
    controller.setBotAutomationEnabled(botAutomationActive);
    _handleFeedback(state);
    _scheduleTutorialForResumedGame(settings, state);

    final isWide =
        MediaQuery.sizeOf(context).width >= AppDimensions.responsiveBreakpoint;
    final pagePadding = isWide
        ? AppDimensions.pagePaddingWide
        : AppDimensions.pagePaddingNarrow;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: isWide ||
              _showLaunchPanel == true ||
              _tutorialStep != null ||
              state.phase == TurnPhase.gameOver
          ? null
          : _buildMobileDock(
              controller,
              state,
              isVisibleBotTurn,
              isVisibleRemoteTurn,
              isWaitingForOnlinePlayers,
            ),
      body: DecoratedBox(
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
                  onNewGame: () => unawaited(_requestNewGameSetup(controller)),
                  onUndo: () => unawaited(
                    _runAction(
                      controller.undoLastAction,
                      FeedbackCue.tap,
                    ),
                  ),
                  onClearSave: () =>
                      unawaited(_confirmClearSavedGame(controller)),
                  onOpenSettings: _showSettingsSheet,
                  onOpenStats: _showStatsSheet,
                ),
                if (controller.isOnlineMatch) ...[
                  const SizedBox(height: 8),
                  OnlineRoomStatusBar(
                    snapshot: controller.onlineRoomSnapshot,
                    status: controller.onlineRoomStatus,
                    errorMessage: controller.onlineRoomError,
                    onLeave: () => unawaited(
                      _leaveOnlineRoom(controller, showSetup: true),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: Stack(
                    children: [
                      ExcludeSemantics(
                        excluding: _showLaunchPanel == true ||
                            state.phase == TurnPhase.gameOver ||
                            _tutorialStep != null,
                        child: isWide
                            ? Row(
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
                                        isRemoteTurn: isVisibleRemoteTurn,
                                        isWaitingForPlayers:
                                            isWaitingForOnlinePlayers,
                                        isOnlineMatch: controller.isOnlineMatch,
                                        canEditRules: controller.canEditRules,
                                        onRoll: () => unawaited(
                                          _rollForHuman(controller),
                                        ),
                                        onPlayerNameChanged: (color, name) =>
                                            unawaited(
                                          controller.updatePlayerName(
                                            color,
                                            name,
                                          ),
                                        ),
                                        onPlayerKindChanged: (color, kind) =>
                                            unawaited(
                                          controller.updatePlayerKind(
                                            color,
                                            kind,
                                          ),
                                        ),
                                        onPlayerAvatarChanged:
                                            (color, avatarId) => unawaited(
                                          controller.updatePlayerAvatar(
                                            color,
                                            avatarId,
                                          ),
                                        ),
                                        onBotDifficultyChanged:
                                            (color, difficulty) => unawaited(
                                          controller.updateBotDifficulty(
                                            color,
                                            difficulty,
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
                            : MobileGameLayout(state: state),
                      ),
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
                          onPlayerNameChanged: (color, name) => unawaited(
                            controller.updatePlayerName(color, name),
                          ),
                          onPlayerAvatarChanged: (color, avatarId) => unawaited(
                            controller.updatePlayerAvatar(color, avatarId),
                          ),
                          onBotDifficultyChanged: (color, difficulty) =>
                              unawaited(
                            controller.updateBotDifficulty(
                              color,
                              difficulty,
                            ),
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
                          onCustomRules: _showRulesSheet,
                          onOnlineRoom: () => _showOnlineRoomSheet(controller),
                          onStart: () {
                            _playFeedback(FeedbackCue.start);
                            setState(() {
                              _showLaunchPanel = false;
                              _tutorialScheduled = true;
                              if (!settings.tutorialCompleted) {
                                _tutorialStep = 0;
                              }
                            });
                            controller.setBotAutomationEnabled(true);
                          },
                        ),
                      if (_tutorialStep case final int step)
                        TutorialOverlay(
                          step: step,
                          onBack: step == 0
                              ? null
                              : () => setState(
                                    () => _tutorialStep = step - 1,
                                  ),
                          onNext: () => _advanceTutorial(settings, step),
                          onSkip: () => _finishTutorial(settings),
                        ),
                      if (state.phase == TurnPhase.gameOver)
                        WinnerOverlay(
                          state: state,
                          canRematch: !controller.isOnlineMatch ||
                              controller.canRestartOnlineMatch,
                          reduceMotion: AppMotionSettings.shouldReduce(context),
                          onRematch: () => unawaited(
                            _runAction(
                              controller.newGame,
                              FeedbackCue.start,
                            ),
                          ),
                          onSetup: () => unawaited(
                            controller.isOnlineMatch
                                ? _leaveOnlineRoom(
                                    controller,
                                    showSetup: true,
                                  )
                                : _openSetupForNewGame(controller),
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
    );
  }

  Future<void> _requestNewGameSetup(GameController controller) async {
    final l10n = AppLocalizations.of(context)!;
    final hasActiveGame = !controller.canEditRules ||
        controller.hasMoveLog ||
        controller.state.diceValue != null;
    if (hasActiveGame) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.newGameConfirmTitle),
          content: Text(l10n.newGameConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.continueAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    if (controller.isOnlineMatch) {
      await controller.leaveOnlineRoom();
      if (!mounted) return;
    }
    await _openSetupForNewGame(controller);
  }

  void _showOnlineRoomSheet(GameController controller) {
    _playFeedback(FeedbackCue.tap);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        useSafeArea: true,
        backgroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.borderRadiusSmall),
          ),
        ),
        builder: (sheetContext) => OnlineRoomSheet(
          initialState: controller.state,
          onAttached: controller.attachOnlineRoom,
          onOpenGame: () {
            if (mounted) {
              setState(() {
                _showLaunchPanel = false;
                _tutorialStep = null;
              });
            }
          },
          onLeave: controller.leaveOnlineRoom,
        ),
      ),
    );
  }

  Future<void> _leaveOnlineRoom(
    GameController controller, {
    required bool showSetup,
  }) async {
    await controller.leaveOnlineRoom();
    if (mounted && showSetup) {
      setState(() {
        _showLaunchPanel = true;
        _tutorialStep = null;
      });
    }
  }

  Future<void> _openSetupForNewGame(GameController controller) async {
    await _runAction(controller.newGame, FeedbackCue.start);
    if (mounted) {
      setState(() {
        _showLaunchPanel = true;
        _tutorialStep = null;
      });
    }
  }

  Future<void> _confirmClearSavedGame(GameController controller) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearSaveConfirmTitle),
        content: Text(l10n.clearSaveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runAction(controller.clearSavedGame, FeedbackCue.tap);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.savedGameCleared)));
  }

  void _scheduleTutorialForResumedGame(
    AppSettingsController settings,
    LudoGameState state,
  ) {
    if (_tutorialScheduled ||
        settings.tutorialCompleted ||
        _showLaunchPanel == true ||
        state.phase == TurnPhase.gameOver) {
      return;
    }
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !settings.tutorialCompleted) {
        setState(() => _tutorialStep = 0);
      }
    });
  }

  void _advanceTutorial(AppSettingsController settings, int step) {
    if (step >= TutorialOverlay.stepCount - 1) {
      _finishTutorial(settings);
      return;
    }
    setState(() => _tutorialStep = step + 1);
  }

  void _finishTutorial(AppSettingsController settings) {
    unawaited(settings.completeTutorial());
    setState(() => _tutorialStep = null);
  }

  Widget _buildMobileDock(
    GameController controller,
    LudoGameState state,
    bool isVisibleBotTurn,
    bool isVisibleRemoteTurn,
    bool isWaitingForOnlinePlayers,
  ) {
    return SafeArea(
      top: false,
      child: MobileActionDock(
        state: state,
        isBotTurn: isVisibleBotTurn,
        isRemoteTurn: isVisibleRemoteTurn,
        isWaitingForPlayers: isWaitingForOnlinePlayers,
        onRoll: () => unawaited(_rollForHuman(controller)),
        onOpenSetup: controller.isOnlineMatch ? null : _showSetupSheet,
        onOpenRules: _showRulesSheet,
        onOpenMoveLog: () => _showMoveLogSheet(),
        onOpenStats: _showStatsSheet,
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
            onBotDifficultyChanged: (color, difficulty) => unawaited(
              controller.updateBotDifficulty(color, difficulty),
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
            enabled: controller.canEditRules,
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

  void _showStatsSheet() {
    _playFeedback(FeedbackCue.tap);
    _showMobileToolSheet(
      title: AppLocalizations.of(context)!.statistics,
      builder: (sheetContext) => Consumer<GameController>(
        builder: (context, controller, _) {
          return StatsCard(state: controller.state);
        },
      ),
    );
  }

  void _showSettingsSheet() {
    _playFeedback(FeedbackCue.tap);
    _showMobileToolSheet(
      title: AppLocalizations.of(context)!.settings,
      builder: (sheetContext) => Consumer<AppSettingsController>(
        builder: (context, settings, _) {
          return SettingsCard(
            settings: settings,
            onReplayTutorial: () {
              Navigator.of(sheetContext).pop();
              unawaited(settings.resetTutorial());
              setState(() {
                _showLaunchPanel = false;
                _tutorialScheduled = true;
                _tutorialStep = 0;
              });
            },
          );
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
    required this.onPlayerNameChanged,
    required this.onPlayerKindChanged,
    required this.onPlayerAvatarChanged,
    required this.onBotDifficultyChanged,
    required this.onClassicPreset,
    required this.onClubPreset,
    required this.onCustomRules,
    required this.onOnlineRoom,
    required this.onStart,
    super.key,
  });

  final LudoGameState state;
  final ValueChanged<int> onPlayerCountChanged;
  final void Function(PlayerColor color, String name) onPlayerNameChanged;
  final void Function(PlayerColor color, PlayerKind kind) onPlayerKindChanged;
  final void Function(PlayerColor color, PlayerAvatarId avatarId)
      onPlayerAvatarChanged;
  final void Function(PlayerColor color, BotDifficulty difficulty)
      onBotDifficultyChanged;
  final VoidCallback onClassicPreset;
  final VoidCallback onClubPreset;
  final VoidCallback onCustomRules;
  final VoidCallback onOnlineRoom;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                            segments: [
                              ButtonSegment(
                                value: 2,
                                label: Text(l10n.playerCountLabel(2)),
                              ),
                              ButtonSegment(
                                value: 3,
                                label: Text(l10n.playerCountLabel(3)),
                              ),
                              ButtonSegment(
                                value: 4,
                                label: Text(l10n.playerCountLabel(4)),
                              ),
                            ],
                            selected: {state.players.length},
                            onSelectionChanged: (selection) =>
                                onPlayerCountChanged(selection.first),
                          ),
                          const SizedBox(height: 16),
                          SetupCard(
                            state: state,
                            onPlayerNameChanged: onPlayerNameChanged,
                            onPlayerKindChanged: onPlayerKindChanged,
                            onPlayerAvatarChanged: onPlayerAvatarChanged,
                            onBotDifficultyChanged: onBotDifficultyChanged,
                          ),
                          const SizedBox(height: 16),
                          _PresetChoice(
                            icon: Icons.table_bar_outlined,
                            title: l10n.classicPreset,
                            description: l10n.classicPresetDescription,
                            selected: _usesClassicPreset(state.rules),
                            onTap: onClassicPreset,
                          ),
                          const SizedBox(height: 10),
                          _PresetChoice(
                            icon: Icons.auto_awesome_outlined,
                            title: l10n.clubPreset,
                            description: l10n.clubPresetDescription,
                            selected: _usesClubPreset(state.rules),
                            onTap: onClubPreset,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: onCustomRules,
                            icon: const Icon(Icons.tune),
                            label: Text(l10n.customRules),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: onOnlineRoom,
                            icon: const Icon(Icons.public),
                            label: Text(l10n.onlineRoom),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: onStart,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(l10n.startGame),
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
    final l10n = AppLocalizations.of(context)!;
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
                          l10n.setupTitle,
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
                          l10n.setupSubtitle,
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

bool _usesClassicPreset(RuleOptions rules) {
  return rules.openRollRule == OpenRollRule.oneRoll &&
      !rules.extraTurnOnFinish &&
      !rules.threeSixesEndTurn &&
      rules.extraTurnOnCapture &&
      rules.extraTurnOnSixNoMove &&
      !rules.doublePieceBlockades;
}

bool _usesClubPreset(RuleOptions rules) {
  return rules.openRollRule == OpenRollRule.threeRolls &&
      rules.extraTurnOnFinish &&
      rules.threeSixesEndTurn;
}

class _PresetChoice extends StatelessWidget {
  const _PresetChoice({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = selected ? AppColors.brass : AppColors.slate500;
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$title, ${l10n.selectedLabel}' : title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotionSettings.duration(
              context,
              const Duration(milliseconds: 180),
            ),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.brass.withValues(alpha: 0.13)
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusSmall,
              ),
              border: Border.all(
                color: selected ? AppColors.brass : AppColors.brassHairline,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_circle, color: accent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.slate600,
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
    );
  }
}

class WinnerOverlay extends StatelessWidget {
  const WinnerOverlay({
    required this.state,
    required this.onRematch,
    required this.onSetup,
    required this.canRematch,
    required this.reduceMotion,
    super.key,
  });

  final LudoGameState state;
  final VoidCallback onRematch;
  final VoidCallback onSetup;
  final bool canRematch;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            Positioned.fill(
              child: WinCelebration(
                color: winner.color.paint,
                reduceMotion: reduceMotion,
              ),
            ),
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
                                onPressed: canRematch ? onRematch : null,
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.rematch),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onSetup,
                                icon: const Icon(Icons.tune),
                                label: Text(l10n.setup),
                              ),
                            ),
                          ],
                        ),
                        if (!canRematch) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.onlineHostRestartOnly,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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
                          AppLocalizations.of(context)!.playerWins(winner.name),
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
                          AppLocalizations.of(context)!
                              .winnerActionCount(actionCount),
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
            Text(
              '${player.name}: ${AppLocalizations.of(context)!.finishedCount(player.finishedCount)}',
            ),
          ],
        ),
      ),
    );
  }
}

class WinCelebration extends StatefulWidget {
  const WinCelebration({
    required this.color,
    required this.reduceMotion,
    super.key,
  });

  final Color color;
  final bool reduceMotion;

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
    );
    if (!widget.reduceMotion) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WinCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion == widget.reduceMotion) {
      return;
    }
    if (widget.reduceMotion) {
      _controller.stop(canceled: false);
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return IgnorePointer(
        child: CustomPaint(
          painter: _WinCelebrationPainter(
            progress: 0.4,
            color: widget.color,
          ),
        ),
      );
    }
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
