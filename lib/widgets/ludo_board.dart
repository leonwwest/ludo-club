import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/app_durations.dart';
import 'package:ludo_club/constants/assets.dart';
import 'package:ludo_club/logic/ludo_board_geometry.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/providers/game_controller.dart';
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
          final pieces =
              state.players.expand((player) => player.pieces).toList();
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
                  for (final piece in pieces)
                    if (moveTargets['${piece.color.name}:${piece.id}']
                        case final int target)
                      _TargetHalo(
                        offset: BoardGeometry.positionFor(
                          piece.copyWith(steps: target),
                          size,
                        ),
                        size: pieceSize,
                        color: piece.color.paint,
                      ),
                  for (final piece in pieces)
                    _buildPiece(
                      controller,
                      piece,
                      size,
                      pieceSize,
                      stackCounts,
                      stackIndexes,
                      canInteract,
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
    GameController controller,
    LudoPiece piece,
    Size size,
    double pieceSize,
    Map<String, int> stackCounts,
    Map<String, int> stackIndexes,
    bool canInteract,
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
    final moveHint = controller.moveHintFor(piece);

    return AnimatedPositioned(
      duration: AppDurations.slow,
      curve: Curves.easeOutCubic,
      left: offset.dx - pieceSize / 2,
      top: offset.dy - pieceSize / 2,
      width: pieceSize,
      height: pieceSize,
      child: _PieceChip(
        piece: piece,
        isMovable: isMovable,
        moveHint: moveHint,
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

class _TargetHalo extends StatelessWidget {
  const _TargetHalo({
    required this.offset,
    required this.size,
    required this.color,
  });

  final Offset offset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx - size * 0.45,
      top: offset.dy - size * 0.45,
      width: size * 0.9,
      height: size * 0.9,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color, width: 2),
          ),
        ),
      ),
    );
  }
}

class _PieceChip extends StatelessWidget {
  const _PieceChip({
    required this.piece,
    required this.isMovable,
    required this.moveHint,
    required this.onTap,
  });

  final LudoPiece piece;
  final bool isMovable;
  final String? moveHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = piece.color.paint;
    final semanticLabel = moveHint == null
        ? '${piece.color.label} Figur ${piece.id + 1}'
        : '${piece.color.label}: $moveHint';
    final chip = Semantics(
      button: isMovable,
      enabled: isMovable,
      label: semanticLabel,
      child: AnimatedScale(
        duration: AppDurations.fast,
        scale: isMovable ? 1.14 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
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
                Positioned.fill(
                  child: Image.asset(
                    AssetMapper.pinFor(piece.color),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                if (isMovable)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
              ],
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
