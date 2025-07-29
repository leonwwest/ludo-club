import 'dart:ui';

import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';

// Standard Ludo board coordinates - 52 main path positions + 4x6 home paths
const List<Offset> boardCoordinates = [
  // Main path positions (52 total, starting from red's start)
  // Red start area (bottom side, moving left)
  Offset(6, 13), Offset(6, 12), Offset(6, 11), Offset(6, 10), Offset(6, 9),
  // Turn to green area
  Offset(6, 8), Offset(5, 8), Offset(4, 8), Offset(3, 8), Offset(2, 8), Offset(1, 8), Offset(0, 8),
  // Green start area (right side, moving up)
  Offset(0, 6), Offset(1, 6), Offset(2, 6), Offset(3, 6), Offset(4, 6), Offset(5, 6),
  // Turn to blue area  
  Offset(6, 6), Offset(6, 5), Offset(6, 4), Offset(6, 3), Offset(6, 2), Offset(6, 1), Offset(6, 0),
  // Blue area (top side, moving right)
  Offset(8, 0), Offset(8, 1), Offset(8, 2), Offset(8, 3), Offset(8, 4), Offset(8, 5),
  // Turn to yellow area
  Offset(8, 6), Offset(9, 6), Offset(10, 6), Offset(11, 6), Offset(12, 6), Offset(13, 6), Offset(14, 6),
  // Yellow area (left side, moving down)
  Offset(14, 8), Offset(13, 8), Offset(12, 8), Offset(11, 8), Offset(10, 8), Offset(9, 8),
  // Back to red area
  Offset(8, 8), Offset(8, 9), Offset(8, 10), Offset(8, 11), Offset(8, 12), Offset(8, 13), Offset(8, 14),
];

// No more safe indices
// const Set<int> safeIndices = {1, 9, 14, 22, 27, 35, 40, 48};

class MoveResult {
  final GameState newState;
  // No more capture logic
  // final Piece? capturedOpponentPiece;
  final bool isFinishMove;

  MoveResult(this.newState, {this.isFinishMove = false});
}

class LudoGame {
  static const int mainPathLength = 52;
  static const int homePathLength = 6;

  static const Map<PlayerColor, int> startFields = {
    PlayerColor.red: 0,
    PlayerColor.green: 13,
    PlayerColor.blue: 26,
    PlayerColor.yellow: 39,
  };

  static const Map<PlayerColor, int> homeStretchStart = {
    PlayerColor.red: 46,
    PlayerColor.green: 7,
    PlayerColor.blue: 20,
    PlayerColor.yellow: 33,
  };

  static List<Piece> getMovablePieces(GameState state) {
    if (state.lastDiceValue == null || state.lastDiceValue == 0) return [];
    return state.currentPlayer.pieces
        .where((p) => _canMovePiece(state, p))
        .toList();
  }

  static bool _canMovePiece(GameState state, Piece piece) {
    if (state.lastDiceValue == null) return false;

    print('Checking if piece ${piece.color} ${piece.id} can move');
    print('Piece position: fieldId=${piece.position.fieldId}, isHome=${piece.position.isHome}');
    print('Dice value: ${state.lastDiceValue}');

    // Piece is in starting home area
    if (piece.position.isHome && piece.position.fieldId == -1) {
      final canMove = state.lastDiceValue == 6;
      print('Piece is in starting area, can move: $canMove');
      return canMove;
    }

    // Piece is in home stretch
    if (piece.position.isHome && piece.position.fieldId >= 0) {
      int targetPos = piece.position.fieldId + state.lastDiceValue!;
      final canMove = targetPos <= homePathLength;
      print('Piece in home stretch, target: $targetPos, can move: $canMove');
      return canMove;
    }

    // Piece is on main path
    int targetPos = piece.position.fieldId + state.lastDiceValue!;
    final homeStart = homeStretchStart[piece.color]!;
    
    // Check if piece would go past its home entry point
    if (piece.position.fieldId < homeStart && targetPos >= homeStart) {
      // Piece can enter home stretch
      print('Piece can enter home stretch from $targetPos');
      return true;
    }
    
    // Normal main path movement
    if (targetPos < mainPathLength) {
      print('Normal main path movement to $targetPos');
      return true;
    }
    
    print('Move not allowed, target $targetPos exceeds bounds');
    return false;
  }

  static MoveResult movePiece(GameState state, Piece piece) {
    if (!_canMovePiece(state, piece)) {
      return MoveResult(state);
    }

    final dice = state.lastDiceValue!;
    final newPlayers = state.players.map((p) {
      if (p.color != state.currentTurnPlayerId) {
        return p;
      }
      return Player(
        id: p.id,
        name: p.name,
        type: p.type,
        color: p.color,
        pieces: p.pieces.map((p) {
          if (p.id != piece.id) {
            return p;
          }
          return _movePiece(state, piece, dice);
        }).toList(),
      );
    }).toList();

    final movedPiece = newPlayers
        .firstWhere((p) => p.color == state.currentTurnPlayerId)
        .pieces
        .firstWhere((p) => p.id == piece.id);

    // No more capture logic

    final newState = state.copyWith(
      players: newPlayers,
      winnerId: _checkWinner(newPlayers, state.currentTurnPlayerId),
    );

    return MoveResult(
      newState,
      isFinishMove: movedPiece.isSafe,
    );
  }

  static Piece _movePiece(GameState state, Piece piece, int steps) {
    // Move from starting home area to main path
    if (piece.position.isHome && piece.position.fieldId == -1 && steps == 6) {
      return Piece(piece.color, piece.id, PiecePosition(startFields[piece.color]!, isHome: false));
    }

    // Move within home stretch
    if (piece.position.isHome && piece.position.fieldId >= 0) {
      int newFieldId = piece.position.fieldId + steps;
      if (newFieldId == homePathLength) {
        // Piece reaches the finish!
        return Piece(piece.color, piece.id, PiecePosition(homePathLength, isHome: true), isSafe: true);
      } else {
        return Piece(piece.color, piece.id, PiecePosition(newFieldId, isHome: true));
      }
    }

    // Move on main path
    int newFieldId = piece.position.fieldId + steps;
    final homeStart = homeStretchStart[piece.color]!;
    
    // Check if piece enters home stretch
    if (piece.position.fieldId < homeStart && newFieldId >= homeStart) {
      int homePosition = newFieldId - homeStart;
      if (homePosition <= homePathLength) {
        print('Piece ${piece.color} ${piece.id} entering home stretch at position $homePosition');
        return Piece(piece.color, piece.id, PiecePosition(homePosition, isHome: true));
      }
    }
    
    // Normal main path movement
    if (newFieldId < mainPathLength) {
      return Piece(piece.color, piece.id, PiecePosition(newFieldId, isHome: false));
    }
    
    // Shouldn't reach here if _canMovePiece is correct
    return piece;
  }

  static PlayerColor? _checkWinner(List<Player> players, PlayerColor currentPlayer) {
    final player = players.firstWhere((p) => p.color == currentPlayer);
    if (player.pieces.every((p) => p.isSafe)) {
      return currentPlayer;
    }
    return null;
  }
}