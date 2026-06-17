import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:ludo_club/theme/player_palette.dart';
import 'package:ludo_club/widgets/dice_panel.dart';
import 'package:ludo_club/widgets/ludo_board.dart';
import 'package:ludo_club/widgets/player_strip.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final state = controller.state;
    final isWide = MediaQuery.sizeOf(context).width >= 920;
    final pagePadding = isWide ? 16.0 : 12.0;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/club_table_v2.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0xDDF6F8FB), BlendMode.srcOver),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  playerCount: controller.playerCount,
                  onPlayerCountChanged: (count) =>
                      controller.newGame(playerCount: count),
                  onRestart: () => controller.newGame(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _BoardStage(state: state)),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 360,
                              child: SingleChildScrollView(
                                child: _SidePanel(
                                  state: state,
                                  onRoll: controller.rollDice,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _MobileGameLayout(
                              state: state,
                              onRoll: controller.rollDice,
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

class _BoardStage extends StatelessWidget {
  const _BoardStage({required this.state});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    return Center(child: _BoardArena(state: state));
  }
}

class _MobileGameLayout extends StatelessWidget {
  const _MobileGameLayout({required this.state, required this.onRoll});

  final LudoGameState state;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BoardArena(state: state),
        const SizedBox(height: 12),
        _MobileActionDock(state: state, onRoll: onRoll),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _BoardArena extends StatelessWidget {
  const _BoardArena({required this.state});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    const badgeHeight = 62.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final heightCap = constraints.maxHeight.isFinite
            ? math.max(260.0, constraints.maxHeight - badgeHeight)
            : constraints.maxWidth;
        final boardSize = math
            .min(constraints.maxWidth, heightCap)
            .clamp(280.0, 620.0)
            .toDouble();
        final badgeWidth = (boardSize * 0.43).clamp(136.0, 178.0).toDouble();
        final arenaHeight = boardSize + badgeHeight;
        final boardTop = badgeHeight * 0.56;

        return SizedBox(
          height: arenaHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: boardTop,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox.square(
                    dimension: boardSize,
                    child: const LudoBoard(),
                  ),
                ),
              ),
              _CornerPlayerBadge(
                player: _playerForColor(PlayerColor.yellow),
                isCurrent: _isCurrent(PlayerColor.yellow),
                width: badgeWidth,
                alignment: _CornerAlignment.topLeft,
              ),
              _CornerPlayerBadge(
                player: _playerForColor(PlayerColor.red),
                isCurrent: _isCurrent(PlayerColor.red),
                width: badgeWidth,
                alignment: _CornerAlignment.topRight,
              ),
              _CornerPlayerBadge(
                player: _playerForColor(PlayerColor.blue),
                isCurrent: _isCurrent(PlayerColor.blue),
                width: badgeWidth,
                alignment: _CornerAlignment.bottomLeft,
              ),
              _CornerPlayerBadge(
                player: _playerForColor(PlayerColor.green),
                isCurrent: _isCurrent(PlayerColor.green),
                width: badgeWidth,
                alignment: _CornerAlignment.bottomRight,
              ),
            ],
          ),
        );
      },
    );
  }

  LudoPlayer? _playerForColor(PlayerColor color) {
    for (final player in state.players) {
      if (player.color == color) {
        return player;
      }
    }
    return null;
  }

  bool _isCurrent(PlayerColor color) {
    return state.phase != TurnPhase.gameOver &&
        state.currentPlayer.color == color;
  }
}

enum _CornerAlignment { topLeft, topRight, bottomLeft, bottomRight }

class _CornerPlayerBadge extends StatelessWidget {
  const _CornerPlayerBadge({
    required this.player,
    required this.isCurrent,
    required this.width,
    required this.alignment,
  });

  final LudoPlayer? player;
  final bool isCurrent;
  final double width;
  final _CornerAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final player = this.player;
    if (player == null) {
      return const SizedBox.shrink();
    }

    final color = player.color.paint;
    final badge = AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: isCurrent ? 1.04 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isCurrent ? 0.97 : 0.88),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent ? color : Colors.white.withValues(alpha: 0.76),
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isCurrent ? 0.26 : 0.1),
              blurRadius: isCurrent ? 18 : 10,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                image: DecorationImage(
                  image: AssetImage(player.color.avatarAsset),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${player.color.colorLabel}  ${player.finishedCount}/4',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF64748B),
                          height: 1.05,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return switch (alignment) {
      _CornerAlignment.topLeft => Positioned(top: 0, left: 0, child: badge),
      _CornerAlignment.topRight => Positioned(top: 0, right: 0, child: badge),
      _CornerAlignment.bottomLeft =>
        Positioned(bottom: 0, left: 0, child: badge),
      _CornerAlignment.bottomRight =>
        Positioned(bottom: 0, right: 0, child: badge),
    };
  }
}

class _MobileActionDock extends StatelessWidget {
  const _MobileActionDock({required this.state, required this.onRoll});

  final LudoGameState state;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    final currentColor = state.winner ?? state.currentPlayer.color;
    final color = currentColor.paint;
    final canRoll = state.phase == TurnPhase.waitingForRoll;
    final title = state.phase == TurnPhase.gameOver
        ? '${currentColor.label} gewinnt'
        : '${state.currentPlayer.name} ist dran';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2.5),
                    image: DecorationImage(
                      image: AssetImage(currentColor.avatarAsset),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      Text(
                        state.turnMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 58,
                  height: 58,
                  child: FittedBox(child: DiceFace(value: state.diceValue)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: canRoll ? onRoll : null,
                icon: const Icon(Icons.casino_outlined),
                label: Text(
                  canRoll
                      ? '${state.currentPlayer.name} würfelt'
                      : 'Figur auswählen',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.playerCount,
    required this.onPlayerCountChanged,
    required this.onRestart,
  });

  final int playerCount;
  final ValueChanged<int> onPlayerCountChanged;
  final VoidCallback onRestart;

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
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/ludo_club_mark_v2.png',
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
                          color: const Color(0xFF64748B),
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
              onPressed: onRestart,
              icon: const Icon(Icons.refresh),
              label: const Text('Neu starten'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.state, required this.onRoll});

  final LudoGameState state;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusCard(state: state),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DicePanel(state: state, onRoll: onRoll),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PlayerStrip(state: state),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    final currentColor = state.winner ?? state.currentPlayer.color;
    final color = currentColor.paint;
    final title = state.phase == TurnPhase.gameOver
        ? '${currentColor.label} gewinnt'
        : '${state.currentPlayer.name} ist dran';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3),
                    image: DecorationImage(
                      image: AssetImage(currentColor.avatarAsset),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              state.turnMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF475569)),
            ),
            if (state.phase == TurnPhase.waitingForMove) ...[
              const SizedBox(height: 14),
              _MoveHint(state: state),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoveHint extends StatelessWidget {
  const _MoveHint({required this.state});

  final LudoGameState state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.touch_app_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Eine markierte Figur antippen.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
