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
    final metrics = _BoardGeometry(boardSize);
    final pathPositions = _getMainPathPositions(metrics);
    return pieces
        .map((piece) => _buildPiece(piece, boardSize, metrics, pathPositions))
        .toList();
  }

  Widget _buildBoardBackground(double size) {
    // Use the provided board asset image as background.
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GameConstants.boardCornerRadius),
        child: Image.asset(
          'assets/board/board.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  Widget _buildPiece(
    Piece piece,
    double boardSize,
    _BoardGeometry metrics,
    List<Offset> pathPositions,
  ) {
    final position =
        _calculatePiecePosition(piece, boardSize, metrics, pathPositions);
    final isMovable = movablePieces.contains(piece);
    final pieceSize = metrics.innerSide * GameConstants.pinSizeRatio;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: GameConstants.pieceMoveDuration),
      curve: Curves.easeOut,
      left: position.dx - pieceSize / 2,
      top: position.dy -
          (pieceSize * GameConstants.pinHeightRatio) -
          GameConstants.pinPaddingPx,
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

  Offset _calculatePiecePosition(
    Piece piece,
    double boardSize,
    _BoardGeometry metrics,
    List<Offset> pathPositions,
  ) {
    Offset toPx(double unitX, double unitY) => metrics.toPx(unitX, unitY);

    if (piece.position.isHome && piece.position.fieldId == -1) {
      switch (piece.color) {
        case PlayerColor.red:
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return toPx(1.5 + col * 2, 11.5 + row * 2);
        case PlayerColor.green:
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return toPx(1.5 + col * 2, 1.5 + row * 2);
        case PlayerColor.yellow:
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return toPx(11.5 + col * 2, 1.5 + row * 2);
        case PlayerColor.blue:
          final row = piece.id ~/ 2;
          final col = piece.id % 2;
          return toPx(11.5 + col * 2, 11.5 + row * 2);
      }
    }

    if (piece.position.isHome && piece.position.fieldId >= 0) {
      return _getHomeStretchPosition(piece, metrics);
    }

    if (piece.position.fieldId >= 0 &&
        piece.position.fieldId < pathPositions.length) {
      return pathPositions[piece.position.fieldId];
    }

    return Offset(boardSize / 2, boardSize / 2);
  }

  Offset _getHomeStretchPosition(Piece piece, _BoardGeometry metrics) {
    final position = piece.position.fieldId;
    Offset toPx(double unitX, double unitY) => metrics.toPx(unitX, unitY);

    final steps = GameConstants.homePathLength.toDouble();
    final clamped = position.clamp(0, GameConstants.homePathLength).toDouble();

    switch (piece.color) {
      case PlayerColor.red:
        if (clamped >= steps) {
          return toPx(7.5, 7.5);
        }
        return toPx(7.5, 12.5 - clamped);
      case PlayerColor.green:
        if (clamped >= steps) {
          return toPx(7.5, 7.5);
        }
        return toPx(1.5 + clamped, 7.5);
      case PlayerColor.yellow:
        if (clamped >= steps) {
          return toPx(7.5, 7.5);
        }
        return toPx(7.5, 1.5 + clamped);
      case PlayerColor.blue:
        if (clamped >= steps) {
          return toPx(7.5, 7.5);
        }
        return toPx(13.5 - clamped, 7.5);
    }
  }

  List<Offset> _getMainPathPositions(_BoardGeometry metrics) {
    final offset = GameConstants.uiMainPathIndexOffset;
    final coords = LudoPath.coords;
    final length = coords.length;
    return List<Offset>.generate(length, (i) {
      final mapped = (i + offset) % length;
      final idx = mapped < 0 ? mapped + length : mapped;
      final g = coords[idx];
      return metrics.toPx(g.dx + 0.5, g.dy + 0.5);
    }, growable: false);
  }
}

class _BoardGeometry {
  const _BoardGeometry._({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.innerWidth,
    required this.innerHeight,
    required this.cellWidth,
    required this.cellHeight,
  });

  factory _BoardGeometry(double boardSize) {
    final left = boardSize * GameConstants.boardInsetLeftRatio;
    final right = boardSize * GameConstants.boardInsetRightRatio;
    final top = boardSize * GameConstants.boardInsetTopRatio;
    final bottom = boardSize * GameConstants.boardInsetBottomRatio;
    final innerWidth = boardSize - left - right;
    final innerHeight = boardSize - top - bottom;
    final cellWidth = innerWidth / GameConstants.boardGridSize;
    final cellHeight = innerHeight / GameConstants.boardGridSize;
    return _BoardGeometry._(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      innerWidth: innerWidth,
      innerHeight: innerHeight,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
  }

  final double left;
  final double top;
  final double right;
  final double bottom;
  final double innerWidth;
  final double innerHeight;
  final double cellWidth;
  final double cellHeight;

  double get innerSide => innerWidth < innerHeight ? innerWidth : innerHeight;

  Offset toPx(double unitX, double unitY) {
    return Offset(
      left + cellWidth * unitX,
      top + cellHeight * unitY,
    );
  }
}
