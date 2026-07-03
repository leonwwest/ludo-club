import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:ludo_club/ui/widgets/header_bar.dart';
import 'package:ludo_club/ui/widgets/mobile_action_dock.dart';
import 'package:ludo_club/ui/widgets/side_panel.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final state = controller.state;
    final isWide =
        MediaQuery.sizeOf(context).width >= AppDimensions.responsiveBreakpoint;
    final pagePadding = isWide
        ? AppDimensions.pagePaddingWide
        : AppDimensions.pagePaddingNarrow;

    return Scaffold(
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
                      controller.newGame(playerCount: count),
                    ),
                    onRestart: () => unawaited(controller.newGame()),
                    onUndo: () => unawaited(controller.undoLastAction()),
                    onClearSave: () => unawaited(controller.clearSavedGame()),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
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
                                    onRoll: () =>
                                        unawaited(controller.rollDice()),
                                    onPlayerNameChanged: (color, name) =>
                                        unawaited(
                                      controller.updatePlayerName(color, name),
                                    ),
                                    onRulesChanged: (rules) => unawaited(
                                      controller.updateRules(rules),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              MobileGameLayout(
                                state: state,
                                onRoll: () => unawaited(controller.rollDice()),
                                onPlayerNameChanged: (color, name) => unawaited(
                                  controller.updatePlayerName(color, name),
                                ),
                                onRulesChanged: (rules) =>
                                    unawaited(controller.updateRules(rules)),
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
}
