import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/models/board_zone.dart';

// Internal representation of a simulated move (top-level; Dart disallows class-in-class)
class _SimResult {
  final bool isValid;
  final ValidationError error;
  final PiecePosition finalPosition;
  final bool finalIsSafe;
  final List<int> traversedMainPath;

  const _SimResult.valid(this.finalPosition, {this.finalIsSafe = false, this.traversedMainPath = const []})
      : isValid = true,
        error = ValidationError.none;

  const _SimResult.invalid(this.error)
      : isValid = false,
        finalPosition = const PiecePosition(GameConstants.basePosition),
        finalIsSafe = false,
        traversedMainPath = const [];
}

// Note: Board geometry is defined in widgets/board_widget.dart; logic operates on indices only.

// No more safe indices
// const Set<int> safeIndices = {1, 9, 14, 22, 27, 35, 40, 48};

class MoveResult {
  final GameState newState;
  final Piece? capturedOpponentPiece;
  final bool isFinishMove;

  MoveResult(this.newState, {this.capturedOpponentPiece, this.isFinishMove = false});
}

enum ValidationError {
  none,
  invalidHomeEntry,
  foreignHomeZone,
  foreignCenterZone,
  exceedsGoal,
  blockedByBarrier,
}

class ValidationResult {
  final bool isValid;
  final ValidationError error;
  const ValidationResult.valid() : isValid = true, error = ValidationError.none;
  const ValidationResult.invalid(this.error) : isValid = false;
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

  // Safe fields where pieces cannot be captured (when enabled via rules)
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

  // Non-playable main path fields (these lie on the colored center triangles).
  // Pieces must never stop on these tiles; skip them during movement.
  static const Set<int> nonPlayableMainPathFields = {18, 46};

  // Return the next playable index after 'current' (wraps around), skipping
  // any indices in nonPlayableMainPathFields.
  static int _nextPlayableIndex(int current) {
    int next = (current + 1) % mainPathLength;
    while (nonPlayableMainPathFields.contains(next)) {
      next = (next + 1) % mainPathLength;
    }
    return next;
  }

  /// Compute positions on the main path that are blocked by a blockade.
  /// Policy:
  /// - Blockades form when two or more pieces of the same color occupy a main-path field.
  /// - Blockades can exist on any main-path field, including safe fields.
  /// - Home lanes and goal are never considered for blockades.
  /// - When `rules.multipleOccupancyAllowed` is true, blockades are disabled.
  static Set<int> _blockadePositions(GameState state) {
    if (state.rules.multipleOccupancyAllowed) return <int>{};
    final Map<int, Map<PlayerColor, int>> counts = {};
    for (final player in state.players) {
      for (final p in player.pieces) {
        if (!p.position.isHome) {
          final idx = p.position.fieldId;
          counts.putIfAbsent(idx, () => {});
          final colorCounts = counts[idx]!;
          colorCounts[p.color] = (colorCounts[p.color] ?? 0) + 1;
        }
      }
    }
    final blocked = <int>{};
    counts.forEach((idx, byColor) {
      for (final entry in byColor.entries) {
        if (entry.value >= 2) {
          blocked.add(idx);
          break;
        }
      }
    });
    return blocked;
  }

  // Map remaining steps at home entry to lane index (legacy behavior).
  static int _mapToHomeLaneIndex(PlayerColor color, int remaining) {
    if (remaining == 0) {
      return color == PlayerColor.green ? 0 : 1;
    }
    return remaining;
  }

  // Simulate a move path and outcome using current rules, including blockade checks.
  static _SimResult _simulate(GameState state, Piece piece, int die) {
    if (die <= 0) return const _SimResult.invalid(ValidationError.invalidHomeEntry);
    final blocked = _blockadePositions(state);

    // Leaving base
    if (piece.position.isHome && piece.position.fieldId == GameConstants.basePosition) {
      if (die != GameConstants.requiredRollToLeaveBase) {
        return const _SimResult.invalid(ValidationError.invalidHomeEntry);
      }
      final startIdx = startFields[piece.color]!;
      if (blocked.contains(startIdx)) {
        return const _SimResult.invalid(ValidationError.invalidHomeEntry);
      }
          return _SimResult.valid(PiecePosition(startIdx, isHome: false));
    }

    // In home lane
    if (piece.position.isHome && piece.position.fieldId >= 0) {
      if (state.rules.exactRollToFinish) {
        if (piece.position.fieldId == homePathLength && die == 1) {
          return const _SimResult.valid(PiecePosition(homePathLength), finalIsSafe: true);
        }
                final target = piece.position.fieldId + die;
        if (target > homePathLength) {
          return const _SimResult.invalid(ValidationError.exceedsGoal);
        }
        return _SimResult.valid(PiecePosition(target));
      } else {
        final target = piece.position.fieldId + die;
        if (target >= homePathLength) {
          return const _SimResult.valid(PiecePosition(homePathLength), finalIsSafe: true);
        }
        return _SimResult.valid(PiecePosition(target));
      }
    }

    // On main path
    final traversed = <int>[];
    int pos = piece.position.fieldId;
    final homeStart = homeStretchStart[piece.color]!;
    for (int i = 1; i <= die; i++) {
      pos = _nextPlayableIndex(pos);
      if (blocked.contains(pos)) {
        return const _SimResult.invalid(ValidationError.blockedByBarrier);
      }
      traversed.add(pos);
      if (pos == homeStart) {
        final remaining = die - i;
        final laneIndex = _mapToHomeLaneIndex(piece.color, remaining);
        if (remaining >= 0) {
          if (state.rules.exactRollToFinish) {
            if (laneIndex == homePathLength) {
              return const _SimResult.valid(PiecePosition(homePathLength), finalIsSafe: true);
            }
            if (laneIndex <= homePathLength - 1) {
              return _SimResult.valid(PiecePosition(laneIndex), traversedMainPath: traversed);
            }
            // overshoot -> continue on main path
          } else {
            if (laneIndex >= homePathLength) {
              return const _SimResult.valid(PiecePosition(homePathLength), finalIsSafe: true);
            }
            return _SimResult.valid(PiecePosition(laneIndex), traversedMainPath: traversed);
          }
        }
      }
    }
    // Standard main-path landing (pos already incremented die times via _nextPlayableIndex)
    return _SimResult.valid(PiecePosition(pos, isHome: false), traversedMainPath: traversed);
  }

  static List<Piece> getMovablePieces(GameState state) {
    if (state.lastDiceValue == null || state.lastDiceValue == 0) return [];
    return state.currentPlayer.pieces
        .where((p) => validateMove(state, p, state.lastDiceValue!).isValid)
        .toList();
  }

  // _canMovePiece is superseded by validateMove + _simulate

  static MoveResult movePiece(GameState state, Piece piece) {
    final sim = _simulate(state, piece, state.lastDiceValue ?? 0);
    if (!sim.isValid) {
      return MoveResult(state);
    }

    final movedPiece = Piece(piece.color, piece.id, sim.finalPosition, isSafe: sim.finalIsSafe);
    
    // Check for captures (only on main path, not in home areas)
    Piece? capturedPiece;
    List<Player> updatedPlayers = state.players.map((p) => p).toList();
    
    final bool isSafeField = safeFields.contains(movedPiece.position.fieldId);
    final bool canCaptureHere = !movedPiece.position.isHome && (!state.rules.safeFieldsEnabled || !isSafeField);
    if (canCaptureHere) {
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
                  return Piece(p.color, p.id, const PiecePosition(-1));
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

  // _movePiece superseded by _simulate

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

  // Map a piece position to a zone for rule checks
  static BoardZone _zoneFor(Piece piece) {
    if (!piece.position.isHome) {
      return const BoardZone(ZoneType.main);
    }
    if (piece.isSafe || piece.position.fieldId == homePathLength) {
      return BoardZone(ZoneType.goal, color: piece.color);
    }
    return BoardZone(ZoneType.home, color: piece.color);
  }

  // Public helper for tests/UI to map a piece to its logical zone
  static BoardZone zoneForPiece(Piece piece) => _zoneFor(piece);

  static ValidationResult validateMove(GameState state, Piece piece, int die) {
    final sim = _simulate(state, piece, die);
    if (sim.isValid) return const ValidationResult.valid();
    return ValidationResult.invalid(sim.error);
  }
}
