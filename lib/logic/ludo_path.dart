import 'dart:ui';

/// Canonical 52 main-path grid coordinates (col,row) on a 15x15 board.
/// Indices: 0/13/26/39 are the colored start tiles; 12/25/38/51 are the
/// corresponding home-entry tiles that lead into each goal lane.
class LudoPath {
  const LudoPath._();

  static const List<Offset> coords = [
    // Bottom edge heading left towards the green quarter
    Offset(6, 13), // 0  Red start / entry
    Offset(6, 12), // 1
    Offset(6, 11), // 2
    Offset(6, 10), // 3
    Offset(6, 9), // 4
    Offset(5, 8), // 5
    Offset(4, 8), // 6
    Offset(3, 8), // 7
    Offset(2, 8), // 8
    Offset(1, 8), // 9
    Offset(0, 8), // 10
    Offset(0, 7), // 11
    Offset(0, 6), // 12 Green home entry
    // Left edge running upward into the green quarter
    Offset(1, 6), // 13 Green start / entry
    Offset(2, 6), // 14
    Offset(3, 6), // 15
    Offset(4, 6), // 16
    Offset(5, 6), // 17
    Offset(6, 5), // 18
    Offset(6, 4), // 19
    Offset(6, 3), // 20
    Offset(6, 2), // 21
    Offset(6, 1), // 22
    Offset(6, 0), // 23
    Offset(7, 0), // 24
    Offset(8, 0), // 25 Yellow home entry
    // Top edge wrapping towards the yellow quarter
    Offset(8, 1), // 26 Yellow start / entry
    Offset(8, 2), // 27
    Offset(8, 3), // 28
    Offset(8, 4), // 29
    Offset(8, 5), // 30
    Offset(9, 6), // 31
    Offset(10, 6), // 32
    Offset(11, 6), // 33
    Offset(12, 6), // 34
    Offset(13, 6), // 35
    Offset(14, 6), // 36 Blue home entry
    Offset(14, 7), // 37
    Offset(14, 8), // 38
    Offset(13, 8), // 39 Blue start / entry
    // Right edge descending into the red quarter
    Offset(12, 8), // 40
    Offset(11, 8), // 41
    Offset(10, 8), // 42
    Offset(9, 8), // 43
    Offset(8, 9), // 44
    Offset(8, 10), // 45
    Offset(8, 11), // 46
    Offset(8, 12), // 47
    Offset(8, 13), // 48
    Offset(8, 14), // 49
    Offset(7, 14), // 50
    Offset(6, 14), // 51 Red home entry
  ];
}
