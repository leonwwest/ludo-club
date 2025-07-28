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
  static const int mainPathLength = 40;
  static const int homePathLength = 4;

  static const Map<PlayerColor, int> startFields = {
    PlayerColor.red: 0,
    PlayerColor.green: 10,
    // We only have 2 players now
    // PlayerColor.blue: 20,
    // PlayerColor.yellow: 30,
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

    if (piece.position.isHome) {
      final canMove = state.lastDiceValue == 6;
      print('Piece is home, can move: $canMove');
      return canMove;
    }

    int targetPos = piece.position.fieldId + state.lastDiceValue!;
    // Simplified condition
    if (targetPos > mainPathLength) {
      print('Target position $targetPos exceeds main path length $mainPathLength');
      return false;
    }
    print('Piece can move to position $targetPos');
    return true;
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
    if (piece.position.isHome && steps == 6) {
      return Piece(piece.color, piece.id, PiecePosition(startFields[piece.color]!, isHome: false));
    }

    int newFieldId = piece.position.fieldId + steps;

    // Simplified logic
    if (newFieldId >= mainPathLength) {
        return Piece(piece.color, piece.id, const PiecePosition(0, isHome: true), isSafe: true);
    } else {
      return Piece(piece.color, piece.id, PiecePosition(newFieldId, isHome: false));
    }
  }

  static PlayerColor? _checkWinner(List<Player> players, PlayerColor currentPlayer) {
    final player = players.firstWhere((p) => p.color == currentPlayer);
    if (player.pieces.every((p) => p.isSafe)) {
      return currentPlayer;
    }
    return null;
  }
}