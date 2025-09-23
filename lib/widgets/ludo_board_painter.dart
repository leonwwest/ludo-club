import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/utils/color_utils.dart';
import 'package:ludo_club/logic/ludo_path.dart';
import 'package:ludo_club/constants/game_constants.dart';

class LudoBoardPainter extends CustomPainter {
  // Reusable Paint objects for better performance
  static final Paint _backgroundPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint _gridPaint = Paint()
    ..color = Colors.grey.shade200
    ..strokeWidth = 0.5;

  static final Paint _homePaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 15;

    // Draw board background
    _drawBackground(canvas, size, cellSize);

    // Draw colored home areas
    _drawHomeAreas(canvas, cellSize);

    // Draw main path
    _drawMainPath(canvas, cellSize);

    // Draw home stretches (colored paths to center)
    _drawHomeStretches(canvas, cellSize);

    // Draw center triangle
    _drawCenter(canvas, cellSize);

    // Draw safe fields
    _drawSafeFields(canvas, cellSize);

    // Draw start positions
    _drawStartPositions(canvas, cellSize);
  }

  void _drawBackground(Canvas canvas, Size size, double cellSize) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), _backgroundPaint);

    // Draw subtle grid
    for (int i = 0; i <= 15; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        _gridPaint,
      );

      // Horizontal lines
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        _gridPaint,
      );
    }
  }

  void _drawHomeAreas(Canvas canvas, double cellSize) {
    // Red home (bottom-left)
    _homePaint.color = ColorUtils.getHomeAreaColor(PlayerColor.red);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cellSize * 9, cellSize * 6, cellSize * 6),
        const Radius.circular(8),
      ),
      _homePaint,
    );

    // Green home (top-left)
    _homePaint.color = ColorUtils.getHomeAreaColor(PlayerColor.green);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, cellSize * 6, cellSize * 6),
        const Radius.circular(8),
      ),
      _homePaint,
    );

    // Yellow home (top-right)
    _homePaint.color = ColorUtils.getHomeAreaColor(PlayerColor.yellow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cellSize * 9, 0, cellSize * 6, cellSize * 6),
        const Radius.circular(8),
      ),
      _homePaint,
    );

    // Blue home (bottom-right)
    _homePaint.color = ColorUtils.getHomeAreaColor(PlayerColor.blue);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cellSize * 9, cellSize * 9, cellSize * 6, cellSize * 6),
        const Radius.circular(8),
      ),
      _homePaint,
    );
  }

  void _drawMainPath(Canvas canvas, double cellSize) {
    final pathPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final seen = <String>{};
    for (final g in LudoPath.coords) {
      final key = '${g.dx.toInt()},${g.dy.toInt()}';
      if (!seen.add(key)) continue;
      final rect = Rect.fromLTWH(
        g.dx * cellSize,
        g.dy * cellSize,
        cellSize,
        cellSize,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, pathPaint);
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  void _drawHomeStretches(Canvas canvas, double cellSize) {
    final stretchPaint = Paint()..style = PaintingStyle.fill;

    // Red home stretch (vertical, bottom to center)
    stretchPaint.color =
        ColorUtils.getPrimaryColor(PlayerColor.red).withValues(alpha: 0.25);
    for (int i = 1; i <= 5; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cellSize * 7, cellSize * (8 + i), cellSize, cellSize),
          const Radius.circular(4),
        ),
        stretchPaint,
      );
    }

    // Green home stretch (horizontal, left to center)
    // Start tint from column 2..6 (leave col 1 white for start cell at index 13)
    stretchPaint.color =
        ColorUtils.getPrimaryColor(PlayerColor.green).withValues(alpha: 0.25);
    for (int i = 2; i <= 6; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cellSize * i, cellSize * 7, cellSize, cellSize),
          const Radius.circular(4),
        ),
        stretchPaint,
      );
    }

    // Yellow home stretch (vertical, top to center)
    stretchPaint.color =
        ColorUtils.getPrimaryColor(PlayerColor.yellow).withValues(alpha: 0.25);
    for (int i = 1; i <= 5; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cellSize * 7, cellSize * i, cellSize, cellSize),
          const Radius.circular(4),
        ),
        stretchPaint,
      );
    }

    // Blue home stretch (horizontal, right to center)
    stretchPaint.color =
        ColorUtils.getPrimaryColor(PlayerColor.blue).withValues(alpha: 0.25);
    for (int i = 1; i <= 5; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cellSize * (8 + i), cellSize * 7, cellSize, cellSize),
          const Radius.circular(4),
        ),
        stretchPaint,
      );
    }
  }

  void _drawCenter(Canvas canvas, double cellSize) {
    final centerPath = Path();
    centerPath.moveTo(cellSize * 7.5, cellSize * 6);
    centerPath.lineTo(cellSize * 6, cellSize * 7.5);
    centerPath.lineTo(cellSize * 7.5, cellSize * 9);
    centerPath.lineTo(cellSize * 9, cellSize * 7.5);
    centerPath.close();

    final centerPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.amber.shade200, Colors.amber.shade400],
      ).createShader(Rect.fromCenter(
        center: Offset(cellSize * 7.5, cellSize * 7.5),
        width: cellSize * 3,
        height: cellSize * 3,
      ));

    canvas.drawPath(centerPath, centerPaint);

    // Center border
    final borderPaint = Paint()
      ..color = Colors.amber.shade600
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(centerPath, borderPaint);
  }

  void _drawSafeFields(Canvas canvas, double cellSize) {
    final safePaint = Paint()
      ..color = Colors.green.shade400
      ..style = PaintingStyle.fill;

    for (final i in GameConstants.safeMainPathFields) {
      if (i < 0 || i >= LudoPath.coords.length) continue;
      final g = LudoPath.coords[i];
      final pos = Offset(cellSize * (g.dx + 0.5), cellSize * (g.dy + 0.5));
      // Draw star shape for safe fields
      _drawStar(canvas, pos, cellSize * 0.3, safePaint);
    }
  }

  void _drawStartPositions(Canvas canvas, double cellSize) {
    final startPaint = Paint()..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Red start
    startPaint.color = ColorUtils.getPrimaryColor(PlayerColor.red);
    canvas.drawCircle(
      Offset(cellSize * 0.5, cellSize * 13.5),
      cellSize * 0.4,
      startPaint,
    );
    canvas.drawCircle(
      Offset(cellSize * 0.5, cellSize * 13.5),
      cellSize * 0.4,
      borderPaint,
    );

    // Green start
    startPaint.color = ColorUtils.getPrimaryColor(PlayerColor.green);
    canvas.drawCircle(
      Offset(cellSize * 1.5, cellSize * 0.5),
      cellSize * 0.4,
      startPaint,
    );
    canvas.drawCircle(
      Offset(cellSize * 1.5, cellSize * 0.5),
      cellSize * 0.4,
      borderPaint,
    );

    // Yellow start
    startPaint.color = ColorUtils.getPrimaryColor(PlayerColor.yellow);
    canvas.drawCircle(
      Offset(cellSize * 13.5, cellSize * 1.5),
      cellSize * 0.4,
      startPaint,
    );
    canvas.drawCircle(
      Offset(cellSize * 13.5, cellSize * 1.5),
      cellSize * 0.4,
      borderPaint,
    );

    // Blue start
    startPaint.color = ColorUtils.getPrimaryColor(PlayerColor.blue);
    canvas.drawCircle(
      Offset(cellSize * 13.5, cellSize * 13.5),
      cellSize * 0.4,
      startPaint,
    );
    canvas.drawCircle(
      Offset(cellSize * 13.5, cellSize * 13.5),
      cellSize * 0.4,
      borderPaint,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const double starAngle = math.pi / 5;

    for (int i = 0; i < 10; i++) {
      double angle = i * starAngle;
      double currentRadius = i.isEven ? radius : radius * 0.5;
      double x = center.dx + currentRadius * math.cos(angle - math.pi / 2);
      double y = center.dy + currentRadius * math.sin(angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
