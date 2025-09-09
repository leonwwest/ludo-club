import 'package:flutter/material.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/widgets/ludo_pin.dart';
import 'package:ludo_club/utils/color_utils.dart';
import 'package:ludo_club/constants/game_constants.dart';

class BoardWidget extends StatelessWidget {
  final List<Piece> pieces;
  final Function(Piece) onPieceSelected;
  final PlayerColor currentPlayer;
  final Set<Piece> movablePieces;

  const BoardWidget({
    Key? key,
    required this.pieces,
    required this.onPieceSelected,
    required this.currentPlayer,
    required this.movablePieces,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Board background using PNG image
              _buildBoardBackground(size),
              // Pieces - Using for loop instead of map for better performance
              ..._buildAllPieces(size),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildAllPieces(double boardSize) {
    return pieces.map((piece) => _buildPiece(piece, boardSize)).toList();
  }

  Widget _buildBoardBackground(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size.square(size),
        painter: LudoBoardPainter(),
      ),
    );
  }

  Widget _buildPiece(Piece piece, double boardSize) {
    final position = _calculatePiecePosition(piece, boardSize);
    final isMovable = movablePieces.contains(piece);
    final pieceSize = boardSize * GameConstants.pinSizeRatio;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: GameConstants.pieceMoveDuration),
      curve: Curves.easeOut,
      left: position.dx - pieceSize / 2,
      top: position.dy - (pieceSize * GameConstants.pinHeightRatio) / 2,
      child: LudoPin(
        key: ValueKey('pin-${piece.color.name}-${piece.id}'),
        color: ColorUtils.getColorString(piece.color),
        id: piece.id + 1,
        size: pieceSize,
        isSelected: piece.color == currentPlayer && isMovable,
        isHighlighted: isMovable,
        onTap: isMovable ? () => onPieceSelected(piece) : null,
      ),
    );
  }

  Offset _calculatePiecePosition(Piece piece, double boardSize) {
    final cellSize = boardSize / GameConstants.boardGridSize;
    
    // Starting home positions (fieldId = -1)
    if (piece.position.isHome && piece.position.fieldId == -1) {
      switch (piece.color) {
        case PlayerColor.red:
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return Offset(
            cellSize * (1.5 + col * 2),
            cellSize * (11.5 + row * 2),
          );
        case PlayerColor.green:
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return Offset(
            cellSize * (1.5 + col * 2),
            cellSize * (1.5 + row * 2),
          );
        case PlayerColor.blue:
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return Offset(
            cellSize * (11.5 + col * 2),
            cellSize * (1.5 + row * 2),
          );
        case PlayerColor.yellow:
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return Offset(
            cellSize * (11.5 + col * 2),
            cellSize * (11.5 + row * 2),
          );
      }
    }
    
    // Home stretch positions (fieldId >= 0, isHome = true)
    if (piece.position.isHome && piece.position.fieldId >= 0) {
      return _getHomeStretchPosition(piece, cellSize);
    }
    
    // Main path positions
    final pathPositions = _getMainPathPositions(boardSize);
    if (piece.position.fieldId >= 0 && piece.position.fieldId < pathPositions.length) {
      return pathPositions[piece.position.fieldId];
    }
    
    // Default center position
    return Offset(boardSize / 2, boardSize / 2);
  }

  Offset _getHomeStretchPosition(Piece piece, double cellSize) {
    final position = piece.position.fieldId;
    
    switch (piece.color) {
      case PlayerColor.red:
        // Red home stretch goes upward in the center column toward the goal
        // Align entry next to main path index 51 at (8,12)
        return Offset(cellSize * 7.5, cellSize * (12.5 - position));
      case PlayerColor.green:
        return Offset(cellSize * (1.5 + position), cellSize * 7.5);
      case PlayerColor.blue:
        return Offset(cellSize * 7.5, cellSize * (1.5 + position));
      case PlayerColor.yellow:
        return Offset(cellSize * (13.5 - position), cellSize * 7.5);
    }
  }

  List<Offset> _getMainPathPositions(double boardSize) {
    final cellSize = boardSize / GameConstants.boardGridSize;
    final positions = <Offset>[];
    Offset c(int col, int row) => Offset(
          cellSize * (col + 0.5),
          cellSize * (row + 0.5),
        );

    // 52 main-path positions, clockwise, matching logic indices:
    // Red start (0) at (6,13)
    positions.addAll([
      c(6, 13), // 0
      c(6, 12), // 1
      c(6, 11), // 2
      c(6, 10), // 3
      c(6, 9),  // 4
      c(6, 8),  // 5
      c(5, 8),  // 6
      c(4, 8),  // 7
      c(3, 8),  // 8
      c(2, 8),  // 9
      c(1, 8),  // 10
      c(0, 8),  // 11
      c(0, 7),  // 12 (Green home entry)
      c(1, 7),  // 13 (Green start)
      c(2, 7),  // 14
      c(3, 7),  // 15
      c(4, 7),  // 16
      c(5, 7),  // 17
      c(6, 7),  // 18
      c(6, 6),  // 19
      c(6, 5),  // 20
      c(6, 4),  // 21
      c(6, 3),  // 22
      c(6, 2),  // 23
      c(6, 1),  // 24
      c(6, 0),  // 25 (Blue home entry)
      c(7, 0),  // 26 (Blue start)
      c(7, 1),  // 27
      c(7, 2),  // 28
      c(7, 3),  // 29
      c(7, 4),  // 30
      c(7, 5),  // 31
      c(7, 6),  // 32
      c(8, 6),  // 33
      c(9, 6),  // 34
      c(10, 6), // 35
      c(11, 6), // 36
      c(12, 6), // 37
      c(13, 6), // 38
      c(14, 6), // 39 (Yellow start)
      c(14, 7), // 40
      c(13, 7), // 41
      c(12, 7), // 42
      c(11, 7), // 43
      c(10, 7), // 44
      c(9, 7),  // 45
      c(8, 7),  // 46
      c(8, 8),  // 47
      c(8, 9),  // 48
      c(8, 10), // 49
      c(8, 11), // 50
      c(8, 12), // 51 (Red home entry)
    ]);

    return positions;
  }
}
