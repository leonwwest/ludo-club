import 'dart:ui';

class LudoPath {
  static const List<Offset> coords = [
    // Simplified path for a 15x15 board
    Offset(7, 13), Offset(7, 12), Offset(7, 11), Offset(7, 10), Offset(7, 9),
    Offset(6, 8), Offset(5, 8), Offset(4, 8), Offset(3, 8), Offset(2, 8), Offset(1, 8),
    Offset(0, 7), 
    Offset(1, 6), Offset(2, 6), Offset(3, 6), Offset(4, 6), Offset(5, 6), Offset(6, 6),
    Offset(7, 5), Offset(7, 4), Offset(7, 3), Offset(7, 2), Offset(7, 1), Offset(7, 0),
    Offset(8, 1), Offset(8, 2), Offset(8, 3), Offset(8, 4), Offset(8, 5), Offset(8, 6),
    Offset(9, 7), 
    Offset(10, 7), Offset(11, 7), Offset(12, 7), Offset(13, 7), Offset(14, 7),
    Offset(13, 8), Offset(12, 8), Offset(11, 8), Offset(10, 8), Offset(9, 8),
    // Home stretches
    Offset(7, 12), Offset(7, 11), Offset(7, 10), Offset(7, 9), Offset(7, 8), Offset(7, 7),
    Offset(1, 7), Offset(2, 7), Offset(3, 7), Offset(4, 7), Offset(5, 7), Offset(6, 7),
  ];
}