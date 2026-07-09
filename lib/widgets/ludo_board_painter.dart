import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/logic/ludo_board_geometry.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/theme/player_palette.dart';

class BoardPainter extends CustomPainter {
  const BoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final board = Offset.zero & size;
    final cell = size.shortestSide / BoardGeometry.gridSize;

    _drawBoardBase(canvas, board);
    _drawPlayerQuadrants(canvas, cell);
    _drawTrack(canvas, cell);
    _drawHomeLanes(canvas, cell);
    _drawCenter(canvas, cell);
    _drawGridBorders(canvas, size, cell);
  }

  void _drawBoardBase(Canvas canvas, Rect board) {
    canvas.drawRect(
      board,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.boardCell,
            AppColors.boardCellAlt,
          ],
        ).createShader(board),
    );
    canvas.drawRect(
      board,
      Paint()
        ..color = AppColors.felt.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
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
    final quadrantRect = rect.deflate(cell * 0.06);
    final quadrant = RRect.fromRectAndRadius(
      quadrantRect,
      Radius.circular(cell * 0.2),
    );
    final highlight = Color.lerp(color.paint, Colors.white, 0.08)!;
    final shade = Color.lerp(color.paint, AppColors.ink, 0.18)!;
    canvas.drawRRect(
      quadrant,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlight, color.paint, shade],
        ).createShader(quadrantRect),
    );
    canvas.drawRRect(
      quadrant,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.055
        ..color = AppColors.brass.withValues(alpha: 0.5),
    );

    final inset = cell * 0.85;
    final homeRect = rect.deflate(inset);
    final homeRRect = RRect.fromRectAndRadius(
      homeRect,
      Radius.circular(cell * 0.34),
    );
    canvas.drawRRect(
      homeRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.paper,
            AppColors.boardCellAlt,
          ],
        ).createShader(homeRect),
    );
    canvas.drawRRect(
      homeRRect,
      Paint()
        ..color = AppColors.brassDark.withValues(alpha: 0.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.055,
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
        offset + Offset(0, cell * 0.05),
        cell * 0.41,
        Paint()..color = AppColors.ink.withValues(alpha: 0.12),
      );
      canvas.drawCircle(
        offset,
        cell * 0.39,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.lerp(color.paint, AppColors.paper, 0.84)!,
              Color.lerp(color.paint, AppColors.paper, 0.62)!,
            ],
          ).createShader(
            Rect.fromCircle(center: offset, radius: cell * 0.39),
          ),
      );
      canvas.drawCircle(
        offset,
        cell * 0.39,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.035
          ..color = color.paint.withValues(alpha: 0.42),
      );
    }
  }

  void _drawTrack(Canvas canvas, double cell) {
    for (var index = 0; index < LudoRules.trackLength; index++) {
      final point = BoardGeometry.trackCell(index);
      final rect = _cellRect(point.row, point.col, cell);
      final startColor = BoardGeometry.startColorFor(index);
      final isSafe = LudoRules.safeFields.contains(index);
      final fill = _trackFill(startColor, isSafe);
      _drawTile(canvas, rect, fill, cell);

      if (isSafe) {
        _drawStar(
          canvas,
          rect.center,
          cell * 0.28,
          startColor?.paint ?? AppColors.brass,
        );
      }
    }
  }

  void _drawHomeLanes(Canvas canvas, double cell) {
    for (final color in PlayerColor.values) {
      for (var lane = 0; lane < 5; lane++) {
        final point = BoardGeometry.homeLaneCell(color, lane);
        final rect = _cellRect(point.row, point.col, cell);
        final fill = Color.lerp(
          color.paint,
          AppColors.boardCell,
          lane == 4 ? 0.12 : 0.24,
        )!;
        _drawTile(
          canvas,
          rect,
          fill,
          cell,
          borderColor: color.paint.withValues(alpha: 0.52),
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

    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, Radius.circular(cell * 0.14)),
      Paint()..color = AppColors.ink.withValues(alpha: 0.12),
    );

    for (final (color, a, b) in triangles) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color.paint, AppColors.paper, 0.1)!,
              Color.lerp(color.paint, AppColors.ink, 0.12)!,
            ],
          ).createShader(centerRect),
      );
    }

    canvas.drawCircle(
      center,
      cell * 0.42,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.paper,
            AppColors.brass.withValues(alpha: 0.88),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: cell * 0.42)),
    );
    _drawStar(canvas, center, cell * 0.24, AppColors.brassDark);

    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, Radius.circular(cell * 0.14)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.055
        ..color = AppColors.brassDark.withValues(alpha: 0.62),
    );
  }

  void _drawGridBorders(Canvas canvas, Size size, double cell) {
    final outerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.085
      ..color = AppColors.ink.withValues(alpha: 0.72);
    final innerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.035
      ..color = AppColors.brass.withValues(alpha: 0.78);
    canvas.drawRect(Offset.zero & size, outerBorder);
    canvas.drawRect((Offset.zero & size).deflate(cell * 0.06), innerBorder);
  }

  Rect _cellRect(int row, int col, double cell) {
    return Rect.fromLTWH(col * cell, row * cell, cell, cell);
  }

  void _drawTile(
    Canvas canvas,
    Rect rect,
    Color fill,
    double cell, {
    Color? borderColor,
  }) {
    final tile = rect.deflate(cell * 0.026);
    final rrect = RRect.fromRectAndRadius(
      tile,
      Radius.circular(cell * 0.085),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(fill, Colors.white, 0.12)!,
            fill,
            Color.lerp(fill, AppColors.ink, 0.06)!,
          ],
        ).createShader(tile),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.026
        ..color = borderColor ?? AppColors.brassDark.withValues(alpha: 0.28),
    );
  }

  Color _trackFill(PlayerColor? startColor, bool isSafe) {
    if (startColor != null) {
      return Color.lerp(startColor.paint, AppColors.boardCell, 0.28)!;
    }
    return isSafe ? AppColors.safeCell : AppColors.boardCell;
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
  bool shouldRepaint(covariant BoardPainter oldDelegate) => false;
}
