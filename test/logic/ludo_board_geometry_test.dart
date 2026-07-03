import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_board_geometry.dart';
import 'package:ludo_club/models/ludo_models.dart';

void main() {
  group('BoardGeometry', () {
    test('track has 52 cells', () {
      expect(BoardGeometry.track, hasLength(52));
    });

    test('trackCell returns correct cell for each index', () {
      expect(BoardGeometry.trackCell(0), const GridCell(6, 1));
      expect(BoardGeometry.trackCell(12), const GridCell(0, 8));
      expect(BoardGeometry.trackCell(51), const GridCell(6, 0));
    });

    test('trackCell wraps around', () {
      expect(
        BoardGeometry.trackCell(52),
        BoardGeometry.trackCell(0),
      );
      expect(
        BoardGeometry.trackCell(104),
        BoardGeometry.trackCell(0),
      );
    });

    test('startColorFor returns correct color for start indices', () {
      expect(BoardGeometry.startColorFor(0), PlayerColor.yellow);
      expect(BoardGeometry.startColorFor(13), PlayerColor.red);
      expect(BoardGeometry.startColorFor(26), PlayerColor.green);
      expect(BoardGeometry.startColorFor(39), PlayerColor.blue);
    });

    test('startColorFor returns null for non-start indices', () {
      expect(BoardGeometry.startColorFor(1), isNull);
      expect(BoardGeometry.startColorFor(7), isNull);
      expect(BoardGeometry.startColorFor(50), isNull);
    });

    test('homeLaneCell returns correct cells for yellow', () {
      expect(BoardGeometry.homeLaneCell(PlayerColor.yellow, 0),
          const GridCell(7, 1));
      expect(BoardGeometry.homeLaneCell(PlayerColor.yellow, 4),
          const GridCell(7, 5));
    });

    test('homeLaneCell returns correct cells for red', () {
      expect(
          BoardGeometry.homeLaneCell(PlayerColor.red, 0), const GridCell(1, 7));
      expect(
          BoardGeometry.homeLaneCell(PlayerColor.red, 4), const GridCell(5, 7));
    });

    test('homeLaneCell returns correct cells for green', () {
      expect(BoardGeometry.homeLaneCell(PlayerColor.green, 0),
          const GridCell(7, 13));
      expect(BoardGeometry.homeLaneCell(PlayerColor.green, 4),
          const GridCell(7, 9));
    });

    test('homeLaneCell returns correct cells for blue', () {
      expect(BoardGeometry.homeLaneCell(PlayerColor.blue, 0),
          const GridCell(13, 7));
      expect(BoardGeometry.homeLaneCell(PlayerColor.blue, 4),
          const GridCell(9, 7));
    });

    test('positionFor returns base offset for base pieces', () {
      const size = Size(600, 600);
      final offset = BoardGeometry.positionFor(
        const LudoPiece(color: PlayerColor.yellow, id: 0, steps: -1),
        size,
      );
      expect(offset.dx, greaterThan(0));
      expect(offset.dy, greaterThan(0));
    });

    test('positionFor returns track offset for main track pieces', () {
      const size = Size(600, 600);
      final offset = BoardGeometry.positionFor(
        const LudoPiece(color: PlayerColor.yellow, id: 0, steps: 0),
        size,
      );
      expect(offset.dx, greaterThan(0));
      expect(offset.dy, greaterThan(0));
    });

    test('positionFor returns finished offset for finished pieces', () {
      const size = Size(600, 600);
      final offset = BoardGeometry.positionFor(
        const LudoPiece(color: PlayerColor.yellow, id: 0, steps: 57),
        size,
      );
      final center = BoardGeometry.cellCenter(7, 7, 600 / 15);
      expect(offset.dx, closeTo(center.dx, 50));
      expect(offset.dy, closeTo(center.dy, 50));
    });

    test('stackJitter returns zero for single piece', () {
      expect(
        BoardGeometry.stackJitter(0, 1, 40),
        Offset.zero,
      );
    });

    test('stackJitter returns non-zero for multiple pieces', () {
      final jitter = BoardGeometry.stackJitter(0, 2, 40);
      expect(jitter, isNot(Offset.zero));
    });

    test('cellCenter returns center of cell', () {
      expect(
        BoardGeometry.cellCenter(0, 0, 40),
        const Offset(20, 20),
      );
      expect(
        BoardGeometry.cellCenter(7, 7, 40),
        const Offset(300, 300),
      );
    });
  });
}
