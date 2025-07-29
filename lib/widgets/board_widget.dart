import 'package:flutter/material.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/widgets/ludo_pin.dart';

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
              // Board background
              _buildBoardBackground(size),
              // Pieces
              ...pieces.map((piece) => _buildPiece(piece, size)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBoardBackground(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: CustomPaint(
        painter: LudoBoardPainter(),
      ),
    );
  }

  Widget _buildPiece(Piece piece, double boardSize) {
    final position = _calculatePiecePosition(piece, boardSize);
    final isMovable = movablePieces.contains(piece);
    final pieceSize = boardSize / 15; // Responsive size for SVG pins
    
    if (piece.color == currentPlayer) {
      print('BoardWidget: Piece ${piece.color} ${piece.id} - isMovable: $isMovable, position: ${piece.position.fieldId}, isHome: ${piece.position.isHome}');
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      left: position.dx - pieceSize / 2,
      top: position.dy - (pieceSize * 1.2) / 2, // Account for teardrop shape height
      child: LudoPin(
        color: _getColorStringForPlayer(piece.color),
        id: piece.id + 1,
        size: pieceSize,
        isSelected: piece.color == currentPlayer && isMovable,
        isHighlighted: isMovable,
        onTap: isMovable ? () => onPieceSelected(piece) : null,
      ),
    );
  }

  Offset _calculatePiecePosition(Piece piece, double boardSize) {
    final cellSize = boardSize / 15;
    
    // Base positions for each color
    if (piece.position.isHome) {
      switch (piece.color) {
        case PlayerColor.red:
          // Red home is bottom-left
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return Offset(
            cellSize * (1.5 + col * 2),
            cellSize * (11.5 + row * 2),
          );
        case PlayerColor.green:
          // Green home is top-left
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return Offset(
            cellSize * (1.5 + col * 2),
            cellSize * (1.5 + row * 2),
          );
        case PlayerColor.blue:
          // Blue home is top-right
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return Offset(
            cellSize * (11.5 + col * 2),
            cellSize * (1.5 + row * 2),
          );
        case PlayerColor.yellow:
          // Yellow home is bottom-right
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return Offset(
            cellSize * (11.5 + col * 2),
            cellSize * (11.5 + row * 2),
          );
      }
    }
    
    // Main path positions
    final pathPositions = _getMainPathPositions(boardSize);
    if (piece.position.fieldId >= 0 && piece.position.fieldId < pathPositions.length) {
      return pathPositions[piece.position.fieldId];
    }
    
    // Default center position
    return Offset(boardSize / 2, boardSize / 2);
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

  Color _getColorForPlayer(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return Colors.red.shade700;
      case PlayerColor.green:
        return Colors.green.shade700;
      case PlayerColor.blue:
        return Colors.blue.shade700;
      case PlayerColor.yellow:
        return Colors.yellow.shade700;
    }
  }

  String _getColorStringForPlayer(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return 'red';
      case PlayerColor.green:
        return 'green';
      case PlayerColor.blue:
        return 'blue';
      case PlayerColor.yellow:
        return 'yellow';
    }
  }
}

class LudoBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final cellSize = size.width / 15;
    
    // Draw colored home areas
    // Red home (bottom-left)
    paint.color = Colors.red.shade200;
    canvas.drawRect(
      Rect.fromLTWH(0, cellSize * 9, cellSize * 6, cellSize * 6),
      paint,
    );
    
    // Green home (top-left)
    paint.color = Colors.green.shade200;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cellSize * 6, cellSize * 6),
      paint,
    );
    
    // Blue home (top-right)
    paint.color = Colors.blue.shade200;
    canvas.drawRect(
      Rect.fromLTWH(cellSize * 9, 0, cellSize * 6, cellSize * 6),
      paint,
    );
    
    // Yellow home (bottom-right)
    paint.color = Colors.yellow.shade200;
    canvas.drawRect(
      Rect.fromLTWH(cellSize * 9, cellSize * 9, cellSize * 6, cellSize * 6),
      paint,
    );
    
    // Draw colored paths to home
    // Red path
    paint.color = Colors.red.shade400;
    for (int i = 1; i <= 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(cellSize * 7, cellSize * (8 + i), cellSize, cellSize),
        paint,
      );
    }
    
    // Green path
    paint.color = Colors.green.shade400;
    for (int i = 1; i <= 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(cellSize * i, cellSize * 7, cellSize, cellSize),
        paint,
      );
    }
    
    // Blue path
    paint.color = Colors.blue.shade400;
    for (int i = 1; i <= 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(cellSize * 7, cellSize * i, cellSize, cellSize),
        paint,
      );
    }
    
    // Yellow path
    paint.color = Colors.yellow.shade400;
    for (int i = 1; i <= 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(cellSize * (8 + i), cellSize * 7, cellSize, cellSize),
        paint,
      );
    }
    
    // Draw center home triangle
    final centerPath = Path();
    centerPath.moveTo(cellSize * 7.5, cellSize * 6.5);
    centerPath.lineTo(cellSize * 6.5, cellSize * 7.5);
    centerPath.lineTo(cellSize * 7.5, cellSize * 8.5);
    centerPath.lineTo(cellSize * 8.5, cellSize * 7.5);
    centerPath.close();
    
    paint.color = Colors.grey.shade300;
    canvas.drawPath(centerPath, paint);
    
    // Draw starting positions with stars
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Red start
    canvas.drawCircle(
      Offset(cellSize * 6.5, cellSize * 13.5),
      cellSize * 0.3,
      starPaint,
    );
    
    // Green start  
    canvas.drawCircle(
      Offset(cellSize * 1.5, cellSize * 6.5),
      cellSize * 0.3,
      starPaint,
    );
    
    // Blue start
    canvas.drawCircle(
      Offset(cellSize * 8.5, cellSize * 1.5),
      cellSize * 0.3,
      starPaint,
    );
    
    // Yellow start
    canvas.drawCircle(
      Offset(cellSize * 13.5, cellSize * 8.5),
      cellSize * 0.3,
      starPaint,
    );
    
    // Draw grid lines
    final linePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    
    for (int i = 0; i <= 15; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        linePaint,
      );
      
      // Horizontal lines
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        linePaint,
      );
    }
    
    // Draw safe zones and special cells
    // This is a simplified version - you would need to implement
    // the full board design based on standard Ludo layout
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}