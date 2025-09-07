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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/board/ludo_board_final.webp',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback in case the image fails to load
            return Container(
              width: size,
              height: size,
              color: Colors.white,
                              child: const Center(
                  child: Text(
                    'ludo_board_final.webp\nNot Found',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            );
          },
        ),
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
        return Offset(cellSize * 7.5, cellSize * (13.5 - position));
      case PlayerColor.green:
        return Offset(cellSize * (1.5 + position), cellSize * 7.5);
      case PlayerColor.blue:
        return Offset(cellSize * 7.5, cellSize * (1.5 + position));
      case PlayerColor.yellow:
        return Offset(cellSize * (13.5 - position), cellSize * 7.5);
    }
  }

  List<Offset> _getMainPathPositions(double boardSize) {
    final cellSize = boardSize / 15;
    final positions = <Offset>[];
    
    // Main path - 52 positions going clockwise
    // Starting from red's start position
    
    // Red side (bottom, moving left)
    positions.add(Offset(cellSize * 6.5, cellSize * 13.5));
    for (int i = 1; i <= 5; i++) {
      positions.add(Offset(cellSize * 6.5, cellSize * (14.5 - i)));
    }
    
    // Corner and left side (moving up)
    for (int i = 5; i >= 0; i--) {
      positions.add(Offset(cellSize * (0.5 + i), cellSize * 8.5));
    }
    positions.add(Offset(cellSize * 0.5, cellSize * 7.5));
    
    // Green side (left, moving up)
    positions.add(Offset(cellSize * 0.5, cellSize * 6.5));
    for (int i = 1; i <= 5; i++) {
      positions.add(Offset(cellSize * (0.5 + i), cellSize * 6.5));
    }
    
    // Corner and top side (moving right)
    for (int i = 5; i >= 0; i--) {
      positions.add(Offset(cellSize * 6.5, cellSize * (0.5 + i)));
    }
    positions.add(Offset(cellSize * 7.5, cellSize * 0.5));
    
    // Blue side (top, moving right)
    positions.add(Offset(cellSize * 8.5, cellSize * 0.5));
    for (int i = 1; i <= 5; i++) {
      positions.add(Offset(cellSize * 8.5, cellSize * (0.5 + i)));
    }
    
    // Corner and right side (moving down)
    for (int i = 9; i <= 14; i++) {
      positions.add(Offset(cellSize * i, cellSize * 6.5));
    }
    positions.add(Offset(cellSize * 14.5, cellSize * 7.5));
    
    // Yellow side (right, moving down)
    positions.add(Offset(cellSize * 14.5, cellSize * 8.5));
    for (int i = 13; i >= 9; i--) {
      positions.add(Offset(cellSize * i, cellSize * 8.5));
    }
    
    // Corner and back to start
    for (int i = 9; i <= 14; i++) {
      positions.add(Offset(cellSize * 8.5, cellSize * i));
    }
    
    return positions;
  }
}
