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
      final point = BoardGeometry.trackCell(index);
      final rect = _cellRect(point.row, point.col, cell);
      final startColor = BoardGeometry.startColorFor(index);
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
        final point = BoardGeometry.homeLaneCell(color, lane);
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
  bool shouldRepaint(covariant BoardPainter oldDelegate) => false;
}
