import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/app_durations.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/logic/ludo_board_geometry.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/l10n/move_hint_formatter.dart';
import 'package:ludo_club/l10n/player_color_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:ludo_club/services/app_settings.dart';
import 'package:ludo_club/theme/player_palette.dart';
import 'package:ludo_club/widgets/ludo_board_painter.dart';
import 'package:provider/provider.dart';

class LudoBoard extends StatelessWidget {
  const LudoBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final state = controller.state;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final cell = size.shortestSide / BoardGeometry.gridSize;
          final pieceSize = (cell * 1.08).clamp(28.0, 56.0).toDouble();
          final pieceHitSize = math.max(
            pieceSize,
            AppDimensions.minTouchTarget,
          );
          final pieces =
              state.players.expand((player) => player.pieces).toList();
          final playerNames = {
            for (final player in state.players) player.color: player.name,
          };
          final canInteract = !controller.isBotTurn;
          final stackCounts = _stackCountsFor(pieces);
          final stackIndexes = <String, int>{};
          final moveTargets = {
            for (final piece in pieces)
              if (controller.legalTargetStepsFor(piece) case final int target)
                '${piece.color.name}:${piece.id}': target,
          };

          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.feltDeep,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              border: Border.all(color: AppColors.brass, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowBoard,
                  blurRadius: 32,
                  offset: Offset(0, 18),
                ),
                BoxShadow(
                  color: Color(0x331F1202),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: BoardPainter()),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.18,
                        child: Image.asset(
                          AssetMapper.boardTexture,
                          fit: BoxFit.cover,
                          repeat: ImageRepeat.repeat,
                          filterQuality: FilterQuality.low,
                        ),
                      ),
                    ),
                  ),
                  for (final safeField in LudoRules.safeFields)
                    _BoardImageMarker(
                      offset: BoardGeometry.trackOffset(safeField, size),
                      size: cell * 0.82,
                      assetPath: AssetMapper.safeFieldStar,
                      opacity: 0.82,
                    ),
                  _BoardImageMarker(
                    offset: BoardGeometry.cellCenter(7, 7, cell),
                    size: cell * 2.86,
                    assetPath: AssetMapper.centerMedallion,
                    opacity: 0.94,
                  ),
                  for (final piece in pieces)
                    if (moveTargets['${piece.color.name}:${piece.id}']
                        case final int target)
                      _TargetHalo(
                        key: ValueKey('target-${piece.color.name}-${piece.id}'),
                        offset: BoardGeometry.positionFor(
                          piece.copyWith(steps: target),
                          size,
                        ),
                        size: pieceSize,
                        color: piece.color.paint,
                        hint: MoveHintFormatter.format(context, state, piece),
                        onTap: canInteract
                            ? () => controller.movePiece(piece)
                            : null,
                      ),
                  for (final piece in pieces)
                    _buildPiece(
                      context,
                      controller,
                      piece,
                      size,
                      pieceSize,
                      pieceHitSize,
                      stackCounts,
                      stackIndexes,
                      canInteract,
                      state.moveSummary,
                      playerNames[piece.color] ??
                          localizedPlayerColor(
                            AppLocalizations.of(context)!,
                            piece.color,
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

  Widget _buildPiece(
    BuildContext context,
    GameController controller,
    LudoPiece piece,
    Size size,
    double pieceSize,
    double pieceHitSize,
    Map<String, int> stackCounts,
    Map<String, int> stackIndexes,
    bool canInteract,
    MoveSummary? moveSummary,
    String playerName,
  ) {
    final key = _positionKey(piece);
    final stackCount = stackCounts[key] ?? 1;
    final stackIndex = stackIndexes.update(
      key,
      (value) => value + 1,
      ifAbsent: () => 0,
    );
    final baseOffset = BoardGeometry.positionFor(piece, size);
    final jitter = piece.isInBase
        ? Offset.zero
        : BoardGeometry.stackJitter(stackIndex, stackCount, pieceSize);
    final offset = baseOffset + jitter;
    final isMovable = canInteract && controller.isMovable(piece);
    final moveHint = MoveHintFormatter.format(context, controller.state, piece);
    final isRecentMove = moveSummary?.mover == piece.color &&
        moveSummary?.pieceId == piece.id &&
        moveSummary?.toSteps == piece.steps;

    return AnimatedPositioned(
      duration: AppMotionSettings.duration(context, AppDurations.slow),
      curve: Curves.easeOutCubic,
      left: offset.dx - pieceHitSize / 2,
      top: offset.dy - pieceHitSize / 2,
      width: pieceHitSize,
      height: pieceHitSize,
      child: _PieceChip(
        key: ValueKey('piece-${piece.color.name}-${piece.id}'),
        piece: piece,
        visualSize: pieceSize,
        isMovable: isMovable,
        isRecentMove: isRecentMove,
        isRecentCapture: isRecentMove && moveSummary?.didCapture == true,
        isRecentFinish: isRecentMove && moveSummary?.finished == true,
        moveHint: moveHint,
        playerName: playerName,
        onTap: isMovable ? () => controller.movePiece(piece) : null,
      ),
    );
  }

  Map<String, int> _stackCountsFor(List<LudoPiece> pieces) {
    final counts = <String, int>{};
    for (final piece in pieces) {
      final key = _positionKey(piece);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  String _positionKey(LudoPiece piece) {
    if (piece.isInBase) {
      return 'base:${piece.color.name}:${piece.id}';
    }
    if (piece.isFinished) {
      return 'finish:${piece.color.name}';
    }
    if (piece.isInHomeLane) {
      return 'home:${piece.color.name}:${LudoRules.homeLaneIndexOf(piece)}';
    }
    return 'track:${LudoRules.globalIndexOf(piece)}';
  }
}

class _BoardImageMarker extends StatelessWidget {
  const _BoardImageMarker({
    required this.offset,
    required this.size,
    required this.assetPath,
    required this.opacity,
  });

  final Offset offset;
  final double size;
  final String assetPath;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _TargetHalo extends StatelessWidget {
  const _TargetHalo({
    super.key,
    required this.offset,
    required this.size,
    required this.color,
    required this.hint,
    required this.onTap,
  });

  final Offset offset;
  final double size;
  final Color color;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hitSize = math.max(size, AppDimensions.minTouchTarget);
    final haloSize = size * 0.9;
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(
          child: SizedBox.square(
            dimension: haloSize,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.14),
                  ),
                ),
                Image.asset(
                  AssetMapper.moveTargetRing,
                  fit: BoxFit.contain,
                  color: color.withValues(alpha: 0.92),
                  colorBlendMode: BlendMode.srcIn,
                  filterQuality: FilterQuality.high,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Positioned(
      left: offset.dx - hitSize / 2,
      top: offset.dy - hitSize / 2,
      width: hitSize,
      height: hitSize,
      child: Semantics(
        button: onTap != null,
        enabled: onTap != null,
        label: hint,
        child: Tooltip(
          message: hint ?? '',
          child: child,
        ),
      ),
    );
  }
}

class _PieceChip extends StatelessWidget {
  const _PieceChip({
    super.key,
    required this.piece,
    required this.visualSize,
    required this.isMovable,
    required this.isRecentMove,
    required this.isRecentCapture,
    required this.isRecentFinish,
    required this.moveHint,
    required this.playerName,
    required this.onTap,
  });

  final LudoPiece piece;
  final double visualSize;
  final bool isMovable;
  final bool isRecentMove;
  final bool isRecentCapture;
  final bool isRecentFinish;
  final String? moveHint;
  final String playerName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = piece.color.paint;
    final semanticLabel = moveHint == null
        ? l10n.playerPiece(playerName, piece.id + 1)
        : '$playerName: $moveHint';
    final effectSize = isRecentCapture
        ? visualSize + 26
        : isRecentFinish
            ? visualSize + 18
            : isMovable
                ? visualSize + 14
                : visualSize;
    final chip = Semantics(
      button: isMovable,
      enabled: isMovable,
      label: semanticLabel,
      child: AnimatedScale(
        duration: AppMotionSettings.duration(context, AppDurations.fast),
        scale: isMovable
            ? 1.14
            : isRecentMove
                ? 1.08
                : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: OverflowBox(
                maxWidth: effectSize,
                maxHeight: effectSize,
                child: SizedBox.square(
                  dimension: effectSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      SizedBox.square(
                        dimension: visualSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(
                                  alpha: isMovable ? 0.58 : 0.32,
                                ),
                                blurRadius: isMovable ? 18 : 10,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isMovable)
                        SizedBox.square(
                          dimension: visualSize + 14,
                          child: Image.asset(
                            AssetMapper.moveTargetRing,
                            fit: BoxFit.contain,
                            color: color.withValues(alpha: 0.9),
                            colorBlendMode: BlendMode.srcIn,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      if (isRecentCapture || isRecentFinish)
                        SizedBox.square(
                          dimension: visualSize + (isRecentCapture ? 26 : 18),
                          child: Image.asset(
                            isRecentCapture
                                ? AssetMapper.captureBurst
                                : AssetMapper.finishWreath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      SizedBox.square(
                        dimension: visualSize,
                        child: Image.asset(
                          AssetMapper.pinFor(piece.color),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (moveHint == null) {
      return chip;
    }
    return Tooltip(message: moveHint!, child: chip);
  }
}
