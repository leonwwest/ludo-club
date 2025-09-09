import 'package:flutter/material.dart';

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
            BoxShadow(blurRadius: 16, offset: Offset(0, 8), color: Color(0x33000000)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest.shortestSide;
            // Build using a 3x3 layout that matches the HTML structure:
            // [ Base(6x6) | VertTrack(3x6) | Base(6x6) ]
            // [ HorTrack(6x3) | Center(3x3) | HorTrack(6x3) ]
            // [ Base(6x6) | VertTrack(3x6) | Base(6x6) ]
            return SizedBox(
              width: size,
              height: size,
              child: Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: Row(
                      children: const [
                        // Top-left should be GREEN
                        Expanded(flex: 6, child: _Base(color: Color(0xFF22C55E), tokenColor: Color(0xFF16A34A))),
                        // Top vertical track (toward center) belongs to BLUE
                        Expanded(flex: 3, child: _TrackVertical(color: Color(0xFF3B82F6))),
                        // Top-right should be BLUE
                        Expanded(flex: 6, child: _Base(color: Color(0xFF3B82F6), tokenColor: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: const [
                        // Left horizontal track (toward center) belongs to GREEN
                        Expanded(flex: 6, child: _TrackHorizontal(color: Color(0xFF22C55E))),
                        Expanded(flex: 3, child: _CenterSquare()),
                        // Right horizontal track belongs to YELLOW
                        Expanded(flex: 6, child: _TrackHorizontal(color: Color(0xFFF59E0B))),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Row(
                      children: const [
                        // Bottom-left should be RED
                        Expanded(flex: 6, child: _Base(color: Color(0xFFEF4444), tokenColor: Color(0xFFDC2626))),
                        // Bottom vertical track belongs to RED
                        Expanded(flex: 3, child: _TrackVertical(color: Color(0xFFEF4444))),
                        // Bottom-right should be YELLOW
                        Expanded(flex: 6, child: _Base(color: Color(0xFFF59E0B), tokenColor: Color(0xFFD97706))),
                      ],
                    ),
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
    final light = Color.alphaBlend(Colors.white.withOpacity(.35), color);
    return Container(
      color: color,
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 6, crossAxisSpacing: 6,
        ),
        itemCount: 4,
        itemBuilder: (context, _) => Container(
          decoration: BoxDecoration(
            color: light,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: tokenColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(blurRadius: 3, offset: Offset(0, 1), color: Color(0x33000000))],
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: 18,
      itemBuilder: (context, index) => _Box(color: index % 3 == 1 ? color.withOpacity(0.25) : null),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
      itemCount: 18,
      itemBuilder: (context, index) => _Box(color: index ~/ 6 == 1 ? color.withOpacity(0.25) : null),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({this.child, this.color});
  final Widget? child;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.transparent,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child == null ? null : Center(child: child),
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

    final p1 = Path()..moveTo(0, 0)..lineTo(w, 0)..lineTo(0, h)..close();
    final p2 = Path()..moveTo(0, 0)..lineTo(w, 0)..lineTo(w, h)..close();
    final p3 = Path()..moveTo(0, h)..lineTo(w, h)..lineTo(0, 0)..close();
    final p4 = Path()..moveTo(w, 0)..lineTo(w, h)..lineTo(0, h)..close();

    // Top-left GREEN, top-right BLUE, bottom-left RED, bottom-right YELLOW
    canvas.drawPath(p1, green);
    canvas.drawPath(p2, blue);
    canvas.drawPath(p3, red);
    canvas.drawPath(p4, yellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


