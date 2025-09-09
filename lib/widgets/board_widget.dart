import 'package:flutter/material.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/widgets/ludo_pin.dart';
import 'package:ludo_club/utils/color_utils.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/widgets/ludo_board_tiled.dart';

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
    return SizedBox(width: size, height: size, child: const LudoBoardTiled());
  }

  Widget _buildPiece(Piece piece, double boardSize) {
    final position = _calculatePiecePosition(piece, boardSize);
    final isMovable = movablePieces.contains(piece);
    final pieceSize = boardSize * GameConstants.pinSizeRatio;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: GameConstants.pieceMoveDuration),
      curve: Curves.easeOut,
      left: position.dx - pieceSize / 2,
      // Anchor the bottom tip of the teardrop to the board circle center
      top: position.dy - (pieceSize * GameConstants.pinHeightRatio),
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
        // Red goal lane should be bottom -> center (vertical at column 7)
        return Offset(cellSize * 7.5, cellSize * (12.5 - position));
      case PlayerColor.green:
        return Offset(cellSize * (1.5 + position), cellSize * 7.5);
      case PlayerColor.blue:
        // Blue goal lane should be top -> center (vertical at column 7)
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
      // Move main path above the green lane to row 6 to avoid overlap
      c(1, 6),  // 13 (Green start visual row 6)
      c(2, 6),  // 14
      c(3, 6),  // 15
      c(4, 6),  // 16
      c(5, 6),  // 17
      c(6, 6),  // 18
      c(6, 5),  // 19
      c(6, 4),  // 20
      c(6, 3),  // 21
      c(6, 2),  // 22
      c(6, 1),  // 23
      c(6, 1),  // 24
      c(6, 0),  // 25 (Blue home entry)
      // Shift the top vertical main-path from center column 7 to 8 so it's
      // adjacent to (not overlapping) the blue goal lane.
      c(8, 0),  // 26 (Blue start visual column 8)
      c(8, 1),  // 27
      c(8, 2),  // 28
      c(8, 3),  // 29
      c(8, 4),  // 30
      c(8, 5),  // 31
      c(8, 6),  // 32
      c(9, 6),  // 33
      c(9, 6),  // 34
      c(10, 6), // 35
      c(11, 6), // 36
      c(12, 6), // 37
      c(13, 6), // 38
      c(14, 6), // 39 (Yellow start)
      // Shift the right horizontal main-path below the yellow goal lane
      c(14, 8), // 40
      c(13, 8), // 41
      c(12, 8), // 42
      c(11, 8), // 43
      c(10, 8), // 44
      c(9, 8),  // 45
      c(8, 8),  // 46
      c(8, 9),  // 47
      c(8, 9),  // 48
      c(8, 10), // 49
      c(8, 11), // 50
      c(8, 12), // 51 (Red home entry)
    ]);

    return positions;
  }
}
