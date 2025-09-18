import 'dart:ui';

/// Canonical 52 main-path grid coordinates (col,row) on a 15x15 board.
/// Indices: 0/13/26/39 are start tiles; 12/25/38/51 are home-entry tiles.
class LudoPath {
  const LudoPath._();

  static const List<Offset> coords = [
    // Bottom vertical up (left of red goal lane)
    Offset(6, 13), // 0  Red start
    Offset(6, 12), // 1
    Offset(6, 11), // 2
    Offset(6, 10), // 3
    Offset(6, 9), // 4
    Offset(6, 8), // 5
    // Bottom horizontal left
    Offset(5, 8), // 6
    Offset(4, 8), // 7
    Offset(3, 8), // 8
    Offset(2, 8), // 9
    Offset(1, 8), // 10
    Offset(0, 8), // 11
    // Left middle (green entry)
    Offset(0, 7), // 12 Green home entry
    // Above green lane (row 6)
    Offset(1, 6), // 13 Green start
    Offset(2, 6), // 14
    Offset(3, 6), // 15
    Offset(4, 6), // 16
    Offset(5, 6), // 17
    Offset(6, 6), // 18
    // Up towards top edge (col 6)
    Offset(6, 5), // 19
    Offset(6, 4), // 20
    Offset(6, 3), // 21
    Offset(6, 2), // 22
    Offset(6, 1), // 23
    Offset(6, 0), // 24 (top edge)
    // Corner across top gap away from blue lane
    Offset(7, 0), // 25 Blue home entry
    Offset(8, 0), // 26 Blue start
    // Down alongside blue lane (col 8)
    Offset(8, 1), // 27
    Offset(8, 2), // 28
    Offset(8, 3), // 29
    Offset(8, 4), // 30
    Offset(8, 5), // 31
    Offset(8, 6), // 32
    // Right along row 6
    Offset(9, 6), // 33
    Offset(10, 6), // 34
    Offset(11, 6), // 35
    Offset(12, 6), // 36
    Offset(13, 6), // 37
    Offset(14, 6), // 38 Yellow home entry
    Offset(14, 7), // 39 Yellow start
    // Right segment below yellow lane (row 8, moving left)
    Offset(14, 8), // 40
    Offset(13, 8), // 41
    Offset(12, 8), // 42
    Offset(11, 8), // 43
    Offset(10, 8), // 44
    Offset(9, 8), // 45
    Offset(8, 8), // 46
    // Turn up towards red entry
    Offset(8, 9), // 47
    Offset(8, 10), // 48
    Offset(8, 11), // 49
    Offset(9, 12), // 50 transition
    Offset(8, 12), // 51 Red home entry
  ];
}
