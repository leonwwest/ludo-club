import 'package:flutter/material.dart';
import 'dart:math' as math;

class LudoBoardPainter extends CustomPainter {
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
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    
    // Draw subtle grid
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;
    
    for (int i = 0; i <= 15; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
      
      // Horizontal lines
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }
  }

  void _drawHomeAreas(Canvas canvas, double cellSize) {
    final homePaint = Paint()..style = PaintingStyle.fill;
    
    // Red home (bottom-left)
    homePaint.color = Colors.red.shade100;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cellSize * 9, cellSize * 6, cellSize * 6),
        const Radius.circular(8),
      ),
      homePaint,
    );
    
    // Green home (top-left)
    homePaint.color = Colors.green.shade100;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, cellSize * 6, cellSize * 6),
        const Radius.circular(8),
      ),
      homePaint,
    );
    
    // Blue home (top-right)
    homePaint.color = Colors.blue.shade100;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cellSize * 9, 0, cellSize * 6, cellSize * 6),
        const Radius.circular(8),
      ),
      homePaint,
    );
    
    // Yellow home (bottom-right)
    homePaint.color = Colors.yellow.shade100;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cellSize * 9, cellSize * 9, cellSize * 6, cellSize * 6),
        const Radius.circular(8),
      ),
      homePaint,
    );
  }

  void _drawMainPath(Canvas canvas, double cellSize) {
    final pathPaint = Paint()
      ..color = Colors.grey.shade50
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Main path cells
    final pathCells = [
      // Bottom row (left to right)
      for (int i = 0; i < 6; i++) Rect.fromLTWH(i * cellSize, cellSize * 13, cellSize, cellSize),
      for (int i = 0; i < 6; i++) Rect.fromLTWH(i * cellSize, cellSize * 12, cellSize, cellSize),
      // Left column (bottom to top)
      for (int i = 11; i >= 6; i--) Rect.fromLTWH(cellSize * 0, i * cellSize, cellSize, cellSize),
      for (int i = 11; i >= 6; i--) Rect.fromLTWH(cellSize * 1, i * cellSize, cellSize, cellSize),
      // Top row (left to right)
      for (int i = 0; i < 6; i++) Rect.fromLTWH(i * cellSize, cellSize * 1, cellSize, cellSize),
      for (int i = 0; i < 6; i++) Rect.fromLTWH(i * cellSize, cellSize * 0, cellSize, cellSize),
      // Right column (top to bottom)
      for (int i = 2; i < 8; i++) Rect.fromLTWH(cellSize * 14, i * cellSize, cellSize, cellSize),
      for (int i = 2; i < 8; i++) Rect.fromLTWH(cellSize * 13, i * cellSize, cellSize, cellSize),
    ];
    
    for (final cell in pathCells) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(cell, const Radius.circular(4)),
        pathPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(cell, const Radius.circular(4)),
        borderPaint,
      );
    }
  }

  void _drawHomeStretches(Canvas canvas, double cellSize) {
    final stretchPaint = Paint()..style = PaintingStyle.fill;
    
    // Red home stretch (vertical, bottom to center)
    stretchPaint.color = Colors.red.shade200;
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
    stretchPaint.color = Colors.green.shade200;
    for (int i = 1; i <= 5; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cellSize * i, cellSize * 7, cellSize, cellSize),
          const Radius.circular(4),
        ),
        stretchPaint,
      );
    }
    
    // Blue home stretch (vertical, top to center)
    stretchPaint.color = Colors.blue.shade200;
    for (int i = 1; i <= 5; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cellSize * 7, cellSize * i, cellSize, cellSize),
          const Radius.circular(4),
        ),
        stretchPaint,
      );
    }
    
    // Yellow home stretch (horizontal, right to center)
    stretchPaint.color = Colors.yellow.shade200;
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
    
    final safePositions = [
      Offset(cellSize * 0.5, cellSize * 13.5),  // Red start (position 0)
      Offset(cellSize * 2.5, cellSize * 8.5),   // Safe field 1 (position 8)
      Offset(cellSize * 1.5, cellSize * 0.5),   // Green start (position 13)
      Offset(cellSize * 8.5, cellSize * 2.5),   // Safe field 2 (position 21)
      Offset(cellSize * 13.5, cellSize * 1.5),  // Blue start (position 26)
      Offset(cellSize * 12.5, cellSize * 8.5),  // Safe field 3 (position 34)
      Offset(cellSize * 13.5, cellSize * 13.5), // Yellow start (position 39)
      Offset(cellSize * 6.5, cellSize * 12.5),  // Safe field 4 (position 47)
    ];
    
    for (final pos in safePositions) {
      // Draw star shape for safe fields
      _drawStar(canvas, pos, cellSize * 0.3, safePaint);
    }
  }

  void _drawStartPositions(Canvas canvas, double cellSize) {
    final startPaint = Paint()
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    // Red start
    startPaint.color = Colors.red.shade600;
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
    startPaint.color = Colors.green.shade600;
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
    
    // Blue start
    startPaint.color = Colors.blue.shade600;
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
    
    // Yellow start
    startPaint.color = Colors.yellow.shade600;
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