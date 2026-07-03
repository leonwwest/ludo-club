import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';

class BoardGeometry {
  const BoardGeometry._();

  static const int gridSize = GameConstants.gridSize;

  static const List<GridCell> track = [
    GridCell(6, 1),
    GridCell(6, 2),
    GridCell(6, 3),
    GridCell(6, 4),
    GridCell(6, 5),
    GridCell(5, 6),
    GridCell(4, 6),
    GridCell(3, 6),
    GridCell(2, 6),
    GridCell(1, 6),
    GridCell(0, 6),
    GridCell(0, 7),
    GridCell(0, 8),
    GridCell(1, 8),
    GridCell(2, 8),
    GridCell(3, 8),
    GridCell(4, 8),
    GridCell(5, 8),
    GridCell(6, 9),
    GridCell(6, 10),
    GridCell(6, 11),
    GridCell(6, 12),
    GridCell(6, 13),
    GridCell(6, 14),
    GridCell(7, 14),
    GridCell(8, 14),
    GridCell(8, 13),
    GridCell(8, 12),
    GridCell(8, 11),
    GridCell(8, 10),
    GridCell(8, 9),
    GridCell(9, 8),
    GridCell(10, 8),
    GridCell(11, 8),
    GridCell(12, 8),
    GridCell(13, 8),
    GridCell(14, 8),
    GridCell(14, 7),
    GridCell(14, 6),
    GridCell(13, 6),
    GridCell(12, 6),
    GridCell(11, 6),
    GridCell(10, 6),
    GridCell(9, 6),
    GridCell(8, 5),
    GridCell(8, 4),
    GridCell(8, 3),
    GridCell(8, 2),
    GridCell(8, 1),
    GridCell(8, 0),
    GridCell(7, 0),
    GridCell(6, 0),
  ];

  static GridCell trackCell(int globalIndex) {
    return track[globalIndex % LudoRules.trackLength];
  }

  static PlayerColor? startColorFor(int globalIndex) {
    for (final color in PlayerColor.values) {
      if (color.startIndex == globalIndex) {
        return color;
      }
    }
    return null;
  }

  static GridCell homeLaneCell(PlayerColor color, int laneIndex) {
    return switch (color) {
      PlayerColor.yellow => GridCell(7, laneIndex + 1),
      PlayerColor.red => GridCell(laneIndex + 1, 7),
      PlayerColor.green => GridCell(7, 13 - laneIndex),
      PlayerColor.blue => GridCell(13 - laneIndex, 7),
    };
  }

  static Offset positionFor(LudoPiece piece, Size size) {
    if (piece.isInBase) {
      return baseOffset(piece.color, piece.id, size);
    }
    if (piece.isFinished) {
      return finishedOffset(piece.color, piece.id, size);
    }
    if (piece.isInHomeLane) {
      return homeOffset(piece.color, piece.steps - LudoRules.trackLength, size);
    }
    return trackOffset(LudoRules.globalIndexOf(piece)!, size);
  }

  static Offset trackOffset(int globalIndex, Size size) {
    final cell = size.shortestSide / gridSize;
    final point = trackCell(globalIndex);
    return cellCenter(point.row, point.col, cell);
  }

  static Offset homeOffset(PlayerColor color, int laneIndex, Size size) {
    final cell = size.shortestSide / gridSize;
    if (laneIndex >= 5) {
      return cellCenter(7, 7, cell);
    }
    final point = homeLaneCell(color, laneIndex);
    return cellCenter(point.row, point.col, cell);
  }

  static Offset baseOffset(PlayerColor color, int id, Size size) {
    final cell = size.shortestSide / gridSize;
    final slots = switch (color) {
      PlayerColor.yellow => const [
          Offset(2.1, 2.1),
          Offset(3.9, 2.1),
          Offset(2.1, 3.9),
          Offset(3.9, 3.9),
        ],
      PlayerColor.red => const [
          Offset(11.1, 2.1),
          Offset(12.9, 2.1),
          Offset(11.1, 3.9),
          Offset(12.9, 3.9),
        ],
      PlayerColor.blue => const [
          Offset(2.1, 11.1),
          Offset(3.9, 11.1),
          Offset(2.1, 12.9),
          Offset(3.9, 12.9),
        ],
      PlayerColor.green => const [
          Offset(11.1, 11.1),
          Offset(12.9, 11.1),
          Offset(11.1, 12.9),
          Offset(12.9, 12.9),
        ],
    };
    final slot = slots[id % slots.length];
    return Offset(slot.dx * cell, slot.dy * cell);
  }

  static Offset finishedOffset(PlayerColor color, int id, Size size) {
    final cell = size.shortestSide / gridSize;
    final angle = -math.pi / 2 + color.index * math.pi / 2 + (id - 1.5) * 0.22;
    return cellCenter(7, 7, cell) +
        Offset(math.cos(angle), math.sin(angle)) * cell * 0.34;
  }

  static Offset stackJitter(int index, int count, double pieceSize) {
    if (count <= 1) {
      return Offset.zero;
    }
    final angle = 2 * math.pi * index / count;
    final radius = pieceSize * 0.16;
    return Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  static Offset cellCenter(int row, int col, double cell) {
    return Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }
}

class GridCell {
  const GridCell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is GridCell && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);
}
