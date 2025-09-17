import 'package:flutter/material.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/widgets/ludo_pin.dart';
import 'package:ludo_club/utils/color_utils.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/logic/ludo_path.dart';

class BoardWidget extends StatelessWidget {
  final List<Piece> pieces;
  final Function(Piece) onPieceSelected;
  final PlayerColor currentPlayer;
  final Set<Piece> movablePieces;

  const BoardWidget({
    super.key,
    required this.pieces,
    required this.onPieceSelected,
    required this.currentPlayer,
    required this.movablePieces,
  });

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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GameConstants.boardCornerRadius),
          boxShadow: const [
            BoxShadow(blurRadius: 16, offset: Offset(0, 8), color: Color(0x33000000)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/board/ludo_board_actual.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
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
    return LudoPath.coords
        .map((g) => Offset(cellSize * (g.dx + 0.5), cellSize * (g.dy + 0.5)))
        .toList(growable: false);
  }
}
