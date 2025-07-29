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
  final Piece? capturedOpponentPiece;
  final bool isFinishMove;

  MoveResult(this.newState, {this.capturedOpponentPiece, this.isFinishMove = false});
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

  // Home stretch entry positions - where each color enters their final stretch
  static const Map<PlayerColor, int> homeStretchStart = {
    PlayerColor.red: 51,    // Red enters home stretch at position 51
    PlayerColor.green: 12,  // Green enters home stretch at position 12 (just before their start at 13)
    PlayerColor.blue: 25,   // Blue enters home stretch at position 25
    PlayerColor.yellow: 38, // Yellow enters home stretch at position 38
  };

  // Safe fields where pieces cannot be captured
  static const Set<int> safeFields = {
    0,   // Red start
    8,   // Safe field 1
    13,  // Green start  
    21,  // Safe field 2
    26,  // Blue start
    34,  // Safe field 3
    39,  // Yellow start
    47,  // Safe field 4
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
    int currentPos = piece.position.fieldId;
    int steps = state.lastDiceValue!;
    final homeStart = homeStretchStart[piece.color]!;
    
    // Calculate target position with wrapping
    int targetPos = (currentPos + steps) % mainPathLength;
    
    // Check if piece passes through or lands on home stretch entry
    for (int i = 1; i <= steps; i++) {
      int checkPos = (currentPos + i) % mainPathLength;
      if (checkPos == homeStart) {
        print('Piece can enter home stretch at position $checkPos');
        return true;
      }
    }
    
    // Normal main path movement is always allowed (with wrapping)
    print('Normal main path movement to $targetPos (wrapped)');
    return true;
  }

  static MoveResult movePiece(GameState state, Piece piece) {
    if (!_canMovePiece(state, piece)) {
      return MoveResult(state);
    }

    final dice = state.lastDiceValue!;
    // First, move the piece
    final movedPiece = _movePiece(state, piece, dice);
    
    // Check for captures (only on main path, not in home areas)
    Piece? capturedPiece;
    List<Player> updatedPlayers = state.players.map((p) => p).toList();
    
    if (!movedPiece.position.isHome && !safeFields.contains(movedPiece.position.fieldId)) {
      // Look for opponent pieces on the same position (only if not on safe field)
      for (int i = 0; i < updatedPlayers.length; i++) {
        if (updatedPlayers[i].color == state.currentTurnPlayerId) continue;
        
        for (int j = 0; j < updatedPlayers[i].pieces.length; j++) {
          final opponentPiece = updatedPlayers[i].pieces[j];
          
          if (!opponentPiece.position.isHome && 
              opponentPiece.position.fieldId == movedPiece.position.fieldId) {
            print('Capture! ${movedPiece.color} ${movedPiece.id} captures ${opponentPiece.color} ${opponentPiece.id}');
            capturedPiece = opponentPiece;
            
            // Send captured piece back to home
            updatedPlayers[i] = Player(
              id: updatedPlayers[i].id,
              name: updatedPlayers[i].name,
              type: updatedPlayers[i].type,
              color: updatedPlayers[i].color,
              pieces: updatedPlayers[i].pieces.map((p) {
                if (p.id == opponentPiece.id) {
                  return Piece(p.color, p.id, const PiecePosition(-1, isHome: true));
                }
                return p;
              }).toList(),
            );
            break;
          }
        }
        if (capturedPiece != null) break;
      }
    }
    
    // Now update the current player's piece
    final newPlayers = updatedPlayers.map((p) {
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
          return movedPiece;
        }).toList(),
      );
    }).toList();

    final newState = state.copyWith(
      players: newPlayers,
      winnerId: _checkWinner(newPlayers, state.currentTurnPlayerId),
    );

    return MoveResult(
      newState,
      capturedOpponentPiece: capturedPiece,
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
    int currentPos = piece.position.fieldId;
    final homeStart = homeStretchStart[piece.color]!;
    
    // Check if piece enters home stretch during this move
    for (int i = 1; i <= steps; i++) {
      int checkPos = (currentPos + i) % mainPathLength;
      if (checkPos == homeStart) {
        // Calculate how many steps are left after reaching home stretch entry
        int remainingSteps = steps - i;
        print('Piece ${piece.color} ${piece.id} entering home stretch with $remainingSteps steps remaining');
        
        if (remainingSteps <= homePathLength) {
          return Piece(piece.color, piece.id, PiecePosition(remainingSteps, isHome: true));
        } else {
          // Too many steps to enter home stretch safely, shouldn't happen
          return piece;
        }
      }
    }
    
    // Normal main path movement with wrapping
    int newFieldId = (currentPos + steps) % mainPathLength;
    print('Piece ${piece.color} ${piece.id} moving to position $newFieldId on main path');
    return Piece(piece.color, piece.id, PiecePosition(newFieldId, isHome: false));
  }

  static PlayerColor? _checkWinner(List<Player> players, PlayerColor currentPlayer) {
    final player = players.firstWhere((p) => p.color == currentPlayer);
    if (player.pieces.every((p) => p.isSafe)) {
      return currentPlayer;
    }
    return null;
  }
}