import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/constants/game_constants.dart';

// Note: Board geometry is defined in widgets/board_widget.dart; logic operates on indices only.

// No more safe indices
// const Set<int> safeIndices = {1, 9, 14, 22, 27, 35, 40, 48};

class MoveResult {
  final GameState newState;
  final Piece? capturedOpponentPiece;
  final bool isFinishMove;

  MoveResult(this.newState, {this.capturedOpponentPiece, this.isFinishMove = false});
}

class LudoGame {
  static const int mainPathLength = GameConstants.totalMainPathFields;
  static const int homePathLength = GameConstants.homePathLength;

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

    // Piece is in starting home area
    if (piece.position.isHome && piece.position.fieldId == -1) {
      return state.lastDiceValue == GameConstants.requiredRollToLeaveBase;
    }

    // Piece is in home stretch
    if (piece.position.isHome && piece.position.fieldId >= 0) {
      int targetPos = piece.position.fieldId + state.lastDiceValue!;
      return targetPos <= homePathLength;
    }

    // Piece is on main path
    int currentPos = piece.position.fieldId;
    int steps = state.lastDiceValue!;
    final homeStart = homeStretchStart[piece.color]!;
    
    // Check if piece passes through or lands on home stretch entry
    for (int i = 1; i <= steps; i++) {
      int checkPos = (currentPos + i) % mainPathLength;
      if (checkPos == homeStart) {
        final remainingSteps = steps - i;
        // Allow entry only if remaining steps fit home path length
        if (remainingSteps <= homePathLength) {
          return true; // can enter home stretch this turn
        } else {
          break; // treat as normal main-path movement
        }
      }
    }

    // Normal main path movement is always allowed (with wrapping)
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
            // Capture occurred
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
    if (piece.position.isHome && piece.position.fieldId == -1 && steps == GameConstants.requiredRollToLeaveBase) {
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
        // Entering home stretch if fits; otherwise continue normal movement
        if (remainingSteps <= homePathLength) {
          return Piece(piece.color, piece.id, PiecePosition(remainingSteps, isHome: true));
        } else {
          // break to perform normal main-path movement
          break;
        }
      }
    }
    
    // Normal main path movement with wrapping
    int newFieldId = (currentPos + steps) % mainPathLength;
    // Moving on main path
    return Piece(piece.color, piece.id, PiecePosition(newFieldId, isHome: false));
  }

  static PlayerColor? _checkWinner(List<Player> players, PlayerColor currentPlayer) {
    try {
      final player = players.firstWhere((p) => p.color == currentPlayer);
      if (player.pieces.every((p) => p.isSafe)) {
        return currentPlayer;
      }
    } catch (e) {
      // Player not found, no winner
    }
    return null;
  }
}
