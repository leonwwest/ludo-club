import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:ludo_club/logic/ludo_path.dart';
import 'package:ludo_club/constants/game_constants.dart';

/// A tiled, grid-based Ludo board background composed of bases and tracks.
/// Designed to align with a 15x15 logical grid, without margins/padding, so
/// that game pins and dice can be positioned on top using grid coordinates.
class LudoBoardTiled extends StatelessWidget {
  const LudoBoardTiled({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
                blurRadius: 16, offset: Offset(0, 8), color: Color(0x33000000)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest.shortestSide;
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Tiled background layout
                  const Column(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Row(
                          children: [
                            Expanded(
                                flex: 6,
                                child: _Base(
                                    color: Color(0xFF22C55E),
                                    tokenColor: Color(0xFF16A34A))),
                            Expanded(
                                flex: 3,
                                child:
                                    _TrackVertical(color: Color(0xFF3B82F6))),
                            Expanded(
                                flex: 6,
                                child: _Base(
                                    color: Color(0xFF3B82F6),
                                    tokenColor: Color(0xFF2563EB))),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                                flex: 6,
                                child:
                                    _TrackHorizontal(color: Color(0xFF22C55E))),
                            Expanded(flex: 3, child: _CenterSquare()),
                            Expanded(
                                flex: 6,
                                child:
                                    _TrackHorizontal(color: Color(0xFFF59E0B))),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Row(
                          children: [
                            Expanded(
                                flex: 6,
                                child: _Base(
                                    color: Color(0xFFEF4444),
                                    tokenColor: Color(0xFFDC2626))),
                            Expanded(
                                flex: 3,
                                child:
                                    _TrackVertical(color: Color(0xFFEF4444))),
                            Expanded(
                                flex: 6,
                                child: _Base(
                                    color: Color(0xFFF59E0B),
                                    tokenColor: Color(0xFFD97706))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Grid-accurate markers so pins align perfectly with circles
                  CustomPaint(
                    painter: const _MarkersPainter(),
                    size: Size.square(size),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Base extends StatelessWidget {
  const _Base({required this.color, required this.tokenColor});
  final Color color;
  final Color tokenColor;

  @override
  Widget build(BuildContext context) {
    final light = Color.alphaBlend(Colors.white.withValues(alpha: .35), color);
    return Container(
      color: color,
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: 4,
        itemBuilder: (context, _) => Container(
          decoration: BoxDecoration(
            color: light,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: tokenColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 3,
                      offset: Offset(0, 1),
                      color: Color(0x33000000))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackVertical extends StatelessWidget {
  const _TrackVertical({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: 18,
      itemBuilder: (context, index) =>
          _Box(color: index % 3 == 1 ? color.withValues(alpha: 0.25) : null),
    );
  }
}

class _TrackHorizontal extends StatelessWidget {
  const _TrackHorizontal({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
      itemCount: 18,
      itemBuilder: (context, index) =>
          _Box(color: index ~/ 6 == 1 ? color.withValues(alpha: 0.25) : null),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({this.color});
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.transparent,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
    );
  }
}

class _CenterSquare extends StatelessWidget {
  const _CenterSquare();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CenterPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _CenterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()..color = const Color(0xFF22C55E);
    final blue = Paint()..color = const Color(0xFF3B82F6);
    final red = Paint()..color = const Color(0xFFEF4444);
    final yellow = Paint()..color = const Color(0xFFF59E0B);

    final w = size.width, h = size.height;

    final p1 = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(0, h)
      ..close();
    final p2 = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..close();
    final p3 = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(0, 0)
      ..close();
    final p4 = Path()
      ..moveTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    // Top-left GREEN, top-right BLUE, bottom-left RED, bottom-right YELLOW
    canvas.drawPath(p1, green);
    canvas.drawPath(p2, blue);
    canvas.drawPath(p3, red);
    canvas.drawPath(p4, yellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draw grid-aligned circles at exact centers where pins should be in bases
/// and subtle home-stretch lanes matching the logic grid (15x15).
class _MarkersPainter extends CustomPainter {
  const _MarkersPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 15.0;

    // Helper to draw ring circle
    void ring(int col, int row,
        {Color fill = Colors.white, Color stroke = Colors.white}) {
      final center = Offset(cell * (col + 0.5), cell * (row + 0.5));
      final r = cell * 0.35;
      final paintFill = Paint()..color = fill;
      final paintStroke = Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.08;
      canvas.drawCircle(center, r, paintFill);
      canvas.drawCircle(center, r, paintStroke);
    }

    // Base circles (match BoardWidget starting coords)
    // Red (bottom-left) at (1,11) (3,11) (1,13) (3,13)
    final redFill = const Color(0xFFEF4444).withValues(alpha: 0.25);
    for (final p in const [
      (1, 11),
      (3, 11),
      (1, 13),
      (3, 13),
    ]) {
      ring(p.$1, p.$2, fill: redFill);
    }

    // Green (top-left) at (1,1) (3,1) (1,3) (3,3)
    final greenFill = const Color(0xFF22C55E).withValues(alpha: 0.25);
    for (final p in const [
      (1, 1),
      (3, 1),
      (1, 3),
      (3, 3),
    ]) {
      ring(p.$1, p.$2, fill: greenFill);
    }

    // Blue (top-right) at (11,1) (13,1) (11,3) (13,3)
    final blueFill = const Color(0xFF3B82F6).withValues(alpha: 0.25);
    for (final p in const [
      (11, 1),
      (13, 1),
      (11, 3),
      (13, 3),
    ]) {
      ring(p.$1, p.$2, fill: blueFill);
    }

    // Yellow (bottom-right) at (11,11) (13,11) (11,13) (13,13)
    final yellowFill = const Color(0xFFF59E0B).withValues(alpha: 0.25);
    for (final p in const [
      (11, 11),
      (13, 11),
      (11, 13),
      (13, 13),
    ]) {
      ring(p.$1, p.$2, fill: yellowFill);
    }

    // Home stretches (subtle tinted lanes) exactly on logic lanes
    final stretchPaint = Paint()..style = PaintingStyle.fill;

    // Red vertical from rows 9..13 at column 7
    stretchPaint.color = const Color(0xFFEF4444).withValues(alpha: 0.18);
    canvas.drawRect(
        Rect.fromLTWH(cell * 7, cell * 9, cell, cell * 5), stretchPaint);

    // Green horizontal just above the shifted main path (cols 2..6) at row 7
    stretchPaint.color = const Color(0xFF22C55E).withValues(alpha: 0.18);
    canvas.drawRect(
        Rect.fromLTWH(cell * 2, cell * 7, cell * 5, cell), stretchPaint);

    // Blue vertical goal lane from rows 1..5 at column 7
    stretchPaint.color = const Color(0xFF3B82F6).withValues(alpha: 0.18);
    canvas.drawRect(
        Rect.fromLTWH(cell * 7, cell * 1, cell, cell * 5), stretchPaint);

    // Yellow horizontal goal lane from cols 9..13 at row 7
    stretchPaint.color = const Color(0xFFF59E0B).withValues(alpha: 0.18);
    canvas.drawRect(
        Rect.fromLTWH(cell * 9, cell * 7, cell * 5, cell), stretchPaint);

    // Main path neutral cells following the shared geometry definition
    final neutral = Paint()..color = const Color(0xFFEFF2F7);
    final seen = <String>{};
    for (final g in LudoPath.coords) {
      final key = '${g.dx.toInt()},${g.dy.toInt()}';
      if (!seen.add(key)) continue;
      canvas.drawRect(
        Rect.fromLTWH(cell * g.dx, cell * g.dy, cell, cell),
        neutral,
      );
    }

    // Draw safe-field stars at canonical indices using path mapping
    void starAtIndex(int index, {Color color = const Color(0xFF16A34A)}) {
      if (index < 0 || index >= LudoPath.coords.length) return;
      final g = LudoPath.coords[index];
      final center = Offset(cell * (g.dx + 0.5), cell * (g.dy + 0.5));
      _drawStar(canvas, center, cell * 0.28,
          Paint()..color = color.withValues(alpha: 0.9));
    }

    // Safe indices (start tiles + stars): 0,8,13,21,26,34,39,47
    for (final idx in GameConstants.safeMainPathFields) {
      starAtIndex(idx);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const double starAngle = math.pi / 5;

    for (int i = 0; i < 10; i++) {
      final angle = i * starAngle;
      final r = i.isEven ? radius : radius * 0.5;
      final x = center.dx + r * math.cos(angle - math.pi / 2);
      final y = center.dy + r * math.sin(angle - math.pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
