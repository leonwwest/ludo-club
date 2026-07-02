import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/constants/app_durations.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:ludo_club/theme/player_palette.dart';
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
          final cell = size.shortestSide / GameConstants.gridSize;
          final pieceSize = (cell * 1.08).clamp(28.0, 56.0).toDouble();
          final pieces =
              state.players.expand((player) => player.pieces).toList();
          final stackCounts = _stackCountsFor(pieces);
          final stackIndexes = <String, int>{};
          final moveTargets = {
            for (final piece in pieces)
              if (controller.legalTargetStepsFor(piece) case final int target)
                '${piece.color.name}:${piece.id}': target,
          };

          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowBoard,
                  blurRadius: 26,
                  offset: Offset(0, 16),
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
                    child: CustomPaint(painter: _BoardPainter()),
                  ),
                  for (final piece in pieces)
                    if (moveTargets['${piece.color.name}:${piece.id}']
                        case final int target)
                      _TargetHalo(
                        offset: _BoardGeometry.positionFor(
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
  ) {
    final key = _positionKey(piece);
    final stackCount = stackCounts[key] ?? 1;
    final stackIndex = stackIndexes.update(
      key,
      (value) => value + 1,
      ifAbsent: () => 0,
    );
    final baseOffset = _BoardGeometry.positionFor(piece, size);
    final jitter = piece.isInBase
        ? Offset.zero
        : _BoardGeometry.stackJitter(stackIndex, stackCount, pieceSize);
    final offset = baseOffset + jitter;
    final isMovable = controller.isMovable(piece);
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
                    piece.color.pinAsset,
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

class _BoardPainter extends CustomPainter {
  const _BoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final board = Offset.zero & size;
    final cell = size.shortestSide / _BoardGeometry.gridSize;

    canvas.drawRect(board, Paint()..color = Colors.white);
    _drawPlayerQuadrants(canvas, cell);
    _drawTrack(canvas, cell);
    _drawHomeLanes(canvas, cell);
    _drawCenter(canvas, cell);
    _drawGridBorders(canvas, size, cell);
  }

  void _drawPlayerQuadrants(Canvas canvas, double cell) {
    _drawHomeQuadrant(
      canvas,
      PlayerColor.yellow,
      Rect.fromLTWH(0, 0, cell * 6, cell * 6),
      cell,
    );
    _drawHomeQuadrant(
      canvas,
      PlayerColor.red,
      Rect.fromLTWH(cell * 9, 0, cell * 6, cell * 6),
      cell,
    );
    _drawHomeQuadrant(
      canvas,
      PlayerColor.blue,
      Rect.fromLTWH(0, cell * 9, cell * 6, cell * 6),
      cell,
    );
    _drawHomeQuadrant(
      canvas,
      PlayerColor.green,
      Rect.fromLTWH(cell * 9, cell * 9, cell * 6, cell * 6),
      cell,
    );
  }

  void _drawHomeQuadrant(
    Canvas canvas,
    PlayerColor color,
    Rect rect,
    double cell,
  ) {
    final paint = Paint()..color = color.paint;
    canvas.drawRect(rect, paint);

    final inset = cell * 0.85;
    final homeRect = rect.deflate(inset);
    final homeRRect = RRect.fromRectAndRadius(
      homeRect,
      Radius.circular(cell * 0.34),
    );
    canvas.drawRRect(
      homeRRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      homeRRect,
      Paint()
        ..color = AppColors.slate800.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05,
    );

    final slotOffsets = [
      Offset(
        homeRect.left + homeRect.width * 0.32,
        homeRect.top + homeRect.height * 0.32,
      ),
      Offset(
        homeRect.left + homeRect.width * 0.68,
        homeRect.top + homeRect.height * 0.32,
      ),
      Offset(
        homeRect.left + homeRect.width * 0.32,
        homeRect.top + homeRect.height * 0.68,
      ),
      Offset(
        homeRect.left + homeRect.width * 0.68,
        homeRect.top + homeRect.height * 0.68,
      ),
    ];
    for (final offset in slotOffsets) {
      canvas.drawCircle(
        offset,
        cell * 0.38,
        Paint()..color = AppColors.gray200,
      );
    }
  }

  void _drawTrack(Canvas canvas, double cell) {
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.035
      ..color = AppColors.slate600.withValues(alpha: 0.55);

    for (var index = 0; index < LudoRules.trackLength; index++) {
      final point = _BoardGeometry.trackCell(index);
      final rect = _cellRect(point.row, point.col, cell);
      final startColor = _BoardGeometry.startColorFor(index);
      final isSafe = LudoRules.safeFields.contains(index);
      final fill = startColor?.paint ??
          (isSafe ? AppColors.slate50 : const Color(0xFFFFFFFF));
      canvas.drawRect(rect, Paint()..color = fill);
      canvas.drawRect(rect, border);

      if (isSafe) {
        _drawStar(
          canvas,
          rect.center,
          cell * 0.28,
          startColor?.paint ?? AppColors.slate300,
        );
      }
    }
  }

  void _drawHomeLanes(Canvas canvas, double cell) {
    for (final color in PlayerColor.values) {
      for (var lane = 0; lane < 5; lane++) {
        final point = _BoardGeometry.homeLaneCell(color, lane);
        final rect = _cellRect(point.row, point.col, cell);
        canvas.drawRect(
          rect,
          Paint()
            ..color = color.paint.withValues(alpha: lane == 4 ? 0.95 : 0.86),
        );
        canvas.drawRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.035
            ..color = AppColors.slate600.withValues(alpha: 0.45),
        );
      }
    }
  }

  void _drawCenter(Canvas canvas, double cell) {
    final centerRect = Rect.fromLTWH(cell * 6, cell * 6, cell * 3, cell * 3);
    final center = centerRect.center;
    final triangles = <(PlayerColor, Offset, Offset)>[
      (
        PlayerColor.red,
        Offset(centerRect.left, centerRect.top),
        Offset(centerRect.right, centerRect.top),
      ),
      (
        PlayerColor.green,
        Offset(centerRect.right, centerRect.top),
        Offset(centerRect.right, centerRect.bottom),
      ),
      (
        PlayerColor.blue,
        Offset(centerRect.left, centerRect.bottom),
        Offset(centerRect.right, centerRect.bottom),
      ),
      (
        PlayerColor.yellow,
        Offset(centerRect.left, centerRect.top),
        Offset(centerRect.left, centerRect.bottom),
      ),
    ];

    for (final (color, a, b) in triangles) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = color.paint);
    }

    canvas.drawRect(
      centerRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05
        ..color = AppColors.ink.withValues(alpha: 0.62),
    );
  }

  void _drawGridBorders(Canvas canvas, Size size, double cell) {
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.06
      ..color = AppColors.ink.withValues(alpha: 0.75);
    canvas.drawRect(Offset.zero & size, border);
  }

  Rect _cellRect(int row, int col, double cell) {
    return Rect.fromLTWH(col * cell, row * cell, cell, cell);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var point = 0; point < 10; point++) {
      final angle = -math.pi / 2 + point * math.pi / 5;
      final pointRadius = point.isEven ? radius : radius * 0.44;
      final offset =
          center + Offset(math.cos(angle), math.sin(angle)) * pointRadius;
      if (point == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.9));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.08
        ..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => false;
}

class _BoardGeometry {
  const _BoardGeometry._();

  static const int gridSize = GameConstants.gridSize;

  static const List<_GridCell> _track = [
    _GridCell(6, 1),
    _GridCell(6, 2),
    _GridCell(6, 3),
    _GridCell(6, 4),
    _GridCell(6, 5),
    _GridCell(5, 6),
    _GridCell(4, 6),
    _GridCell(3, 6),
    _GridCell(2, 6),
    _GridCell(1, 6),
    _GridCell(0, 6),
    _GridCell(0, 7),
    _GridCell(0, 8),
    _GridCell(1, 8),
    _GridCell(2, 8),
    _GridCell(3, 8),
    _GridCell(4, 8),
    _GridCell(5, 8),
    _GridCell(6, 9),
    _GridCell(6, 10),
    _GridCell(6, 11),
    _GridCell(6, 12),
    _GridCell(6, 13),
    _GridCell(6, 14),
    _GridCell(7, 14),
    _GridCell(8, 14),
    _GridCell(8, 13),
    _GridCell(8, 12),
    _GridCell(8, 11),
    _GridCell(8, 10),
    _GridCell(8, 9),
    _GridCell(9, 8),
    _GridCell(10, 8),
    _GridCell(11, 8),
    _GridCell(12, 8),
    _GridCell(13, 8),
    _GridCell(14, 8),
    _GridCell(14, 7),
    _GridCell(14, 6),
    _GridCell(13, 6),
    _GridCell(12, 6),
    _GridCell(11, 6),
    _GridCell(10, 6),
    _GridCell(9, 6),
    _GridCell(8, 5),
    _GridCell(8, 4),
    _GridCell(8, 3),
    _GridCell(8, 2),
    _GridCell(8, 1),
    _GridCell(8, 0),
    _GridCell(7, 0),
    _GridCell(6, 0),
  ];

  static _GridCell trackCell(int globalIndex) {
    return _track[globalIndex % LudoRules.trackLength];
  }

  static PlayerColor? startColorFor(int globalIndex) {
    for (final color in PlayerColor.values) {
      if (color.startIndex == globalIndex) {
        return color;
      }
    }
    return null;
  }

  static _GridCell homeLaneCell(PlayerColor color, int laneIndex) {
    return switch (color) {
      PlayerColor.yellow => _GridCell(7, laneIndex + 1),
      PlayerColor.red => _GridCell(laneIndex + 1, 7),
      PlayerColor.green => _GridCell(7, 13 - laneIndex),
      PlayerColor.blue => _GridCell(13 - laneIndex, 7),
    };
  }

  static Offset positionFor(LudoPiece piece, Size size) {
    if (piece.isInBase) {
      return baseOffset(piece.color, piece.id, size);
    }
    if (piece.isFinished) {
      return finishedOffset(piece.color, piece.id, size);
    }
    if (piece.isInHomeLane) {
      return homeOffset(piece.color, piece.steps - LudoRules.trackLength, size);
    }
    return trackOffset(LudoRules.globalIndexOf(piece)!, size);
  }

  static Offset trackOffset(int globalIndex, Size size) {
    final cell = size.shortestSide / gridSize;
    final point = trackCell(globalIndex);
    return _cellCenter(point.row, point.col, cell);
  }

  static Offset homeOffset(PlayerColor color, int laneIndex, Size size) {
    final cell = size.shortestSide / gridSize;
    if (laneIndex >= 5) {
      return _cellCenter(7, 7, cell);
    }
    final point = homeLaneCell(color, laneIndex);
    return _cellCenter(point.row, point.col, cell);
  }

  static Offset baseOffset(PlayerColor color, int id, Size size) {
    final cell = size.shortestSide / gridSize;
    final slots = switch (color) {
      PlayerColor.yellow => const [
          Offset(2.1, 2.1),
          Offset(3.9, 2.1),
          Offset(2.1, 3.9),
          Offset(3.9, 3.9),
        ],
      PlayerColor.red => const [
          Offset(11.1, 2.1),
          Offset(12.9, 2.1),
          Offset(11.1, 3.9),
          Offset(12.9, 3.9),
        ],
      PlayerColor.blue => const [
          Offset(2.1, 11.1),
          Offset(3.9, 11.1),
          Offset(2.1, 12.9),
          Offset(3.9, 12.9),
        ],
      PlayerColor.green => const [
          Offset(11.1, 11.1),
          Offset(12.9, 11.1),
          Offset(11.1, 12.9),
          Offset(12.9, 12.9),
        ],
    };
    final slot = slots[id % slots.length];
    return Offset(slot.dx * cell, slot.dy * cell);
  }

  static Offset finishedOffset(PlayerColor color, int id, Size size) {
    final cell = size.shortestSide / gridSize;
    final angle = -math.pi / 2 + color.index * math.pi / 2 + (id - 1.5) * 0.22;
    return _cellCenter(7, 7, cell) +
        Offset(math.cos(angle), math.sin(angle)) * cell * 0.34;
  }

  static Offset stackJitter(int index, int count, double pieceSize) {
    if (count <= 1) {
      return Offset.zero;
    }
    final angle = 2 * math.pi * index / count;
    final radius = pieceSize * 0.16;
    return Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  static Offset _cellCenter(int row, int col, double cell) {
    return Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }
}

class _GridCell {
  const _GridCell(this.row, this.col);

  final int row;
  final int col;
}
