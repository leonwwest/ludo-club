import 'dart:collection';

import 'package:ludo_club/models/game_phase.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/pawn.dart';
import 'package:ludo_club/models/rules_config.dart';

class PlayerSetup {
  final PlayerId id;
  final PlayerColor color;
  final int startIndex;
  final int homeEntryIndex;
  final int pawnCount;

  const PlayerSetup({
    required this.id,
    required this.color,
    required this.startIndex,
    required this.homeEntryIndex,
    this.pawnCount = 4,
  });
}

enum MoveKind {
  enterFromBase,
  advanceOnTrack,
  enterHomeStretch,
  advanceHomeStretch,
}

class Move {
  final PawnId pawnId;
  final MoveKind kind;
  final PawnState from;
  final PawnState to;
  final List<int> traversedTrack;
  final List<PawnId> captured;
  final bool finishes;

  const Move({
    required this.pawnId,
    required this.kind,
    required this.from,
    required this.to,
    required this.traversedTrack,
    required this.captured,
    required this.finishes,
  });
}

class MoveResolution {
  final GameState state;
  final Move move;
  final bool didCapture;
  final bool createdBlockade;
  final bool removedBlockade;

  const MoveResolution({
    required this.state,
    required this.move,
    required this.didCapture,
    required this.createdBlockade,
    required this.removedBlockade,
  });
}

class LudoGame {
  const LudoGame._();

  static GameState initialize({
    required List<PlayerSetup> players,
    required RulesConfig rules,
  }) {
    final pawns = <PawnId, Pawn>{};
    final playerList = <Player>[];

    for (final setup in players) {
      final pawnIds = <PawnId>[];
      for (var i = 0; i < setup.pawnCount; i++) {
        final pawnId = '${setup.id}_$i';
        pawnIds.add(pawnId);
        pawns[pawnId] =
            Pawn(id: pawnId, ownerId: setup.id, state: const PawnState.base());
      }
      playerList.add(Player(
        id: setup.id,
        color: setup.color,
        startIndex: setup.startIndex,
        homeEntryIndex: setup.homeEntryIndex,
        pawnIds: pawnIds,
      ));
    }

    if (playerList.isEmpty) {
      throw ArgumentError('At least one player required');
    }

    return GameState(
      players: playerList,
      pawns: pawns,
      currentPlayer: playerList.first.id,
      phase: GamePhase.roll,
      rules: rules,
    );
  }

  static GameState roll(GameState state, int dice) {
    if (state.phase != GamePhase.roll) {
      throw StateError('Cannot roll dice outside roll phase');
    }

    final player = state.currentPlayerData;
    final isSix = dice == 6;
    final updatedConsecutive = isSix ? player.consecutiveSixes + 1 : 0;

    final updatedPlayers = state.players.map((p) {
      if (p.id == player.id) {
        return p.copyWith(consecutiveSixes: updatedConsecutive);
      }
      return p;
    }).toList();

    GameState working = state.copyWith(
      players: updatedPlayers,
      dice: dice,
    );

    if (isSix && updatedConsecutive >= 3 &&
        working.rules.tripleSixRule != TripleSixRule.none) {
      working = _applyTripleSixPenalty(working, player, dice);
      return working;
    }

    final moves = legalMoves(working);
    if (moves.isEmpty) {
      final bool grantExtra = _shouldGrantExtraRoll(
        rules: working.rules,
        dice: dice,
        moved: false,
        didCapture: false,
        didFinish: false,
      );

      return working.copyWith(
        phase: GamePhase.resolve,
        extraRollAwarded: grantExtra,
      );
    }

    return working.copyWith(phase: GamePhase.move, extraRollAwarded: false);
  }

  static List<Move> legalMoves(GameState state) {
    final dice = state.dice;
    if (dice == null) return const [];
    final player = state.currentPlayerData;

    final pawnMap = state.pawns;
    final trackOccupancy = _groupPawnsByTrack(state);
    final blockades =
        _computeBlockades(state, excludePawn: null, occupancy: trackOccupancy);

    final moves = <Move>[];
    for (final pawnId in player.pawnIds) {
      final pawn = pawnMap[pawnId];
      if (pawn == null) continue;
      switch (pawn.state.kind) {
        case PawnKind.base:
          final move = _generateBaseMove(
            state: state,
            pawn: pawn,
            trackOccupancy: trackOccupancy,
            dice: dice,
          );
          if (move != null) moves.add(move);
          break;
        case PawnKind.track:
          final move = _generateTrackMove(
            state: state,
            pawn: pawn,
            dice: dice,
            occupancy: trackOccupancy,
            blockades: blockades,
          );
          if (move != null) moves.add(move);
          break;
        case PawnKind.homeStretch:
          final move = _generateHomeStretchMove(
            state: state,
            pawn: pawn,
            dice: dice,
          );
          if (move != null) moves.add(move);
          break;
        case PawnKind.finished:
          break;
      }
    }
    return moves;
  }

  static MoveResolution applyMove(GameState state, Move move) {
    if (state.dice == null) {
      throw StateError('Cannot apply move without a dice value');
    }
    final pawn = state.pawns[move.pawnId];
    if (pawn == null) {
      throw ArgumentError('Unknown pawn ${move.pawnId}');
    }

    final updatedPawns = Map<PawnId, Pawn>.from(state.pawns);

    final captureSnapshots = <PawnSnapshot>[];
    for (final capturedId in move.captured) {
      final capturedPawn = updatedPawns[capturedId];
      if (capturedPawn == null) continue;
      captureSnapshots.add(PawnSnapshot(capturedPawn));
      updatedPawns[capturedId] =
          capturedPawn.copyWith(state: const PawnState.base());
    }

    final movedPawn = pawn.copyWith(state: move.to);
    updatedPawns[move.pawnId] = movedPawn;

    final bool removedBlockade = state.rules.allowBlockades &&
        pawn.state.isTrack &&
        _countColorOnTrack(state, pawn.state.trackIndex, pawn.ownerId) >= 2 &&
        _countColorOnTrackWithOverrides(
              updatedPawns, pawn.state.trackIndex, pawn.ownerId) <
            2;

    final bool createdBlockade = state.rules.allowBlockades &&
        move.to.isTrack &&
        _countColorOnTrackWithOverrides(
              updatedPawns, move.to.trackIndex, pawn.ownerId) >=
            2 &&
        _countColorOnTrack(state, move.to.trackIndex, pawn.ownerId) < 2;

    final movedPlayer = state.currentPlayerData;
    final newFinishedCount = movedPlayer.finishedCount + (move.finishes ? 1 : 0);

    final updatedPlayers = state.players.map((p) {
      if (p.id == movedPlayer.id) {
        return p.copyWith(finishedCount: newFinishedCount);
      }
      return p;
    }).toList();

    var ranking = state.ranking;
    bool rankingUpdated = false;
    if (move.finishes &&
        newFinishedCount >= state.rules.requiredFinishedPawns &&
        !ranking.contains(movedPlayer.id)) {
      final updatedRanking = List<PlayerId>.from(ranking)..add(movedPlayer.id);
      rankingUpdated = true;
      ranking = UnmodifiableListView(updatedRanking);
    }

    final record = MoveRecord(
      playerId: movedPlayer.id,
      pawnId: move.pawnId,
      from: move.from,
      to: move.to,
      captured: captureSnapshots,
      finished: move.finishes,
      rankingUpdated: rankingUpdated,
    );

    final history = List<MoveRecord>.from(state.currentTurnHistory)..add(record);

    final bool didCapture = move.captured.isNotEmpty;

    final bool extraRoll = _shouldGrantExtraRoll(
      rules: state.rules,
      dice: state.dice!,
      moved: true,
      didCapture: didCapture,
      didFinish: move.finishes,
    );

    final nextPhase = ranking.length == state.players.length
        ? GamePhase.gameOver
        : GamePhase.resolve;

    final nextState = state.copyWith(
      pawns: updatedPawns,
      players: updatedPlayers,
      ranking: ranking,
      phase: nextPhase,
      extraRollAwarded: extraRoll,
      currentTurnHistory: history,
    );

    return MoveResolution(
      state: nextState,
      move: move,
      didCapture: didCapture,
      createdBlockade: createdBlockade,
      removedBlockade: removedBlockade,
    );
  }

  static GameState resolveWithoutMove(GameState state) {
    if (state.phase != GamePhase.resolve) {
      throw StateError('Expected resolve phase');
    }
    if (state.rules.requiredFinishedPawns <= state.ranking.length &&
        state.ranking.length == state.players.length) {
      return state.copyWith(phase: GamePhase.gameOver);
    }
    return state;
  }

  static GameState endTurn(GameState state) {
    if (state.phase != GamePhase.resolve &&
        state.phase != GamePhase.endTurn &&
        state.phase != GamePhase.roll) {
      throw StateError('Cannot end turn from phase ${state.phase}');
    }

    final currentPlayer = state.currentPlayerData;
    final extraRoll = state.extraRollAwarded;

    final updatedPlayers = state.players.map((p) {
      if (p.id == currentPlayer.id) {
        final resetSixes = extraRoll ? p.consecutiveSixes : 0;
        return p.copyWith(consecutiveSixes: resetSixes);
      }
      return p;
    }).toList();

    if (state.phase == GamePhase.gameOver) {
      return state;
    }

    if (extraRoll) {
      return state.copyWith(
        players: updatedPlayers,
        dice: null,
        extraRollAwarded: false,
        phase: GamePhase.roll,
      );
    }

    final nextPlayerId = _nextPlayerId(state);
    return state.copyWith(
      players: updatedPlayers,
      currentPlayer: nextPlayerId,
      dice: null,
      extraRollAwarded: false,
      currentTurnHistory: const [],
      phase: GamePhase.roll,
    );
  }

  static List<Move> _generateBaseMoves(GameState state, Pawn pawn, int dice,
      Map<int, List<Pawn>> trackOccupancy) {
    final move = _generateBaseMove(
      state: state,
      pawn: pawn,
      dice: dice,
      trackOccupancy: trackOccupancy,
    );
    return move == null ? const [] : [move];
  }

  static Move? _generateBaseMove({
    required GameState state,
    required Pawn pawn,
    required int dice,
    required Map<int, List<Pawn>> trackOccupancy,
  }) {
    final player = state.currentPlayerData;
    if (state.rules.startNeedsSix && dice != 6) {
      return null;
    }

    final startIndex = player.startIndex;
    final occupants = trackOccupancy[startIndex] ?? const <Pawn>[];
    final ownOnStart =
        occupants.where((p) => p.ownerId == pawn.ownerId).toList();
    final opponents =
        occupants.where((p) => p.ownerId != pawn.ownerId).toList();

    if (ownOnStart.isNotEmpty) {
      if (state.rules.cannotEnterIfOwnStoneAtStart) {
        return null;
      }
      if (!state.rules.stackOnStartAllowed) {
        return null;
      }
      if (!state.rules.allowBlockades) {
        return null;
      }
    }

    if (opponents.isNotEmpty) {
      final isSafe = state.rules.safeSquares.contains(startIndex);
      final captureAllowed = !isSafe ||
          state.rules.captureOnSafeAllowed ||
          state.rules.ownStartIsSafe;
      if (!captureAllowed) {
        return null;
      }
    }

    return Move(
      pawnId: pawn.id,
      kind: MoveKind.enterFromBase,
      from: pawn.state,
      to: PawnState.track(startIndex),
      traversedTrack: const [],
      captured: opponents.map((p) => p.id).toList(),
      finishes: false,
    );
  }

  static Move? _generateTrackMove({
    required GameState state,
    required Pawn pawn,
    required int dice,
    required Map<int, List<Pawn>> occupancy,
    required Set<int> blockades,
  }) {
    final trackLength = state.rules.trackLength;
    final player = state.players.firstWhere((p) => p.id == pawn.ownerId);

    final traversed = <int>[];
    var position = pawn.state.trackIndex;
    for (var step = 1; step <= dice; step++) {
      position = (position + 1) % trackLength;
      traversed.add(position);

      if (_isBlocked(state, blockades, position) && step < dice) {
        return null;
      }

      if (position == player.homeEntryIndex) {
        final remaining = dice - step;
        if (remaining > 0) {
          return _handleHomeEntry(
            state: state,
            pawn: pawn,
            traversed: traversed,
            remaining: remaining,
          );
        }
      }
    }

    return _evaluateTrackLanding(
      state: state,
      pawn: pawn,
      traversed: traversed,
      targetIndex: position,
      occupancy: occupancy,
      blockades: blockades,
    );
  }

  static Move? _handleHomeEntry({
    required GameState state,
    required Pawn pawn,
    required List<int> traversed,
    required int remaining,
  }) {
    final homeLength = state.rules.homeLength;
    if (state.rules.exactFinish) {
      if (remaining > homeLength) {
        return null;
      }
      if (remaining == homeLength) {
        return Move(
          pawnId: pawn.id,
          kind: MoveKind.enterHomeStretch,
          from: pawn.state,
          to: const PawnState.finished(),
          traversedTrack: List<int>.from(traversed),
          captured: const [],
          finishes: true,
        );
      }
      final steps = remaining - 1;
      if (steps < 0) {
        return null;
      }
      return Move(
        pawnId: pawn.id,
        kind: MoveKind.enterHomeStretch,
        from: pawn.state,
        to: PawnState.homeStretch(steps),
        traversedTrack: List<int>.from(traversed),
        captured: const [],
        finishes: false,
      );
    }

    if (remaining >= homeLength) {
      return Move(
        pawnId: pawn.id,
        kind: MoveKind.enterHomeStretch,
        from: pawn.state,
        to: const PawnState.finished(),
        traversedTrack: List<int>.from(traversed),
        captured: const [],
        finishes: true,
      );
    }

    final steps = remaining - 1;
    if (steps < 0) {
      return null;
    }
    return Move(
      pawnId: pawn.id,
      kind: MoveKind.enterHomeStretch,
      from: pawn.state,
      to: PawnState.homeStretch(steps),
      traversedTrack: List<int>.from(traversed),
      captured: const [],
      finishes: false,
    );
  }

  static Move? _evaluateTrackLanding({
    required GameState state,
    required Pawn pawn,
    required List<int> traversed,
    required int targetIndex,
    required Map<int, List<Pawn>> occupancy,
    required Set<int> blockades,
  }) {
    if (_isBlocked(state, blockades, targetIndex)) {
      final occupants = occupancy[targetIndex] ?? const <Pawn>[];
      final blockadeOwner = occupants.isEmpty ? null : occupants.first.ownerId;
      if (blockadeOwner != pawn.ownerId) {
        return null;
      }
    }

    final occupants = occupancy[targetIndex] ?? const <Pawn>[];
    final ownPieces =
        occupants.where((p) => p.ownerId == pawn.ownerId).toList();
    final opponents =
        occupants.where((p) => p.ownerId != pawn.ownerId).toList();

    if (opponents.length >= 2) {
      return null;
    }

    if (ownPieces.isNotEmpty) {
      if (!state.rules.allowBlockades) {
        return null;
      }
      if (targetIndex ==
              state.players.firstWhere((p) => p.id == pawn.ownerId).startIndex &&
          !state.rules.stackOnStartAllowed) {
        return null;
      }
    }

    if (opponents.isNotEmpty) {
      final isSafe = state.rules.safeSquares.contains(targetIndex);
      if (isSafe && !state.rules.captureOnSafeAllowed) {
        return null;
      }
    }

    return Move(
      pawnId: pawn.id,
      kind: MoveKind.advanceOnTrack,
      from: pawn.state,
      to: PawnState.track(targetIndex),
      traversedTrack: List<int>.from(traversed),
      captured: opponents.map((p) => p.id).toList(),
      finishes: false,
    );
  }

  static Move? _generateHomeStretchMove({
    required GameState state,
    required Pawn pawn,
    required int dice,
  }) {
    final steps = pawn.state.homeSteps;
    final target = steps + dice;
    final homeLength = state.rules.homeLength;

    if (state.rules.exactFinish) {
      if (target > homeLength) {
        return null;
      }
      if (target == homeLength) {
        return Move(
          pawnId: pawn.id,
          kind: MoveKind.advanceHomeStretch,
          from: pawn.state,
          to: const PawnState.finished(),
          traversedTrack: const [],
          captured: const [],
          finishes: true,
        );
      }
      return Move(
        pawnId: pawn.id,
        kind: MoveKind.advanceHomeStretch,
        from: pawn.state,
        to: PawnState.homeStretch(target),
        traversedTrack: const [],
        captured: const [],
        finishes: false,
      );
    }

    if (target >= homeLength) {
      return Move(
        pawnId: pawn.id,
        kind: MoveKind.advanceHomeStretch,
        from: pawn.state,
        to: const PawnState.finished(),
        traversedTrack: const [],
        captured: const [],
        finishes: true,
      );
    }

    return Move(
      pawnId: pawn.id,
      kind: MoveKind.advanceHomeStretch,
      from: pawn.state,
      to: PawnState.homeStretch(target),
      traversedTrack: const [],
      captured: const [],
      finishes: false,
    );
  }

  static Map<int, List<Pawn>> _groupPawnsByTrack(GameState state) {
    final map = <int, List<Pawn>>{};
    for (final pawn in state.pawns.values) {
      if (pawn.state.isTrack) {
        map.putIfAbsent(pawn.state.trackIndex, () => []).add(pawn);
      }
    }
    return map;
  }

  static Set<int> _computeBlockades(GameState state,
      {required Map<int, List<Pawn>> occupancy, PawnId? excludePawn}) {
    if (!state.rules.allowBlockades || state.rules.blockadePassThrough) {
      return const <int>{};
    }
    final blocked = <int>{};
    occupancy.forEach((index, pawns) {
      final counts = <PlayerId, int>{};
      for (final pawn in pawns) {
        if (pawn.id == excludePawn) continue;
        counts[pawn.ownerId] = (counts[pawn.ownerId] ?? 0) + 1;
      }
      if (counts.values.any((count) => count >= 2)) {
        blocked.add(index);
      }
    });
    return blocked;
  }

  static bool _isBlocked(GameState state, Set<int> blockades, int index) {
    if (!state.rules.allowBlockades) return false;
    if (state.rules.blockadePassThrough) return false;
    return blockades.contains(index);
  }

  static bool _shouldGrantExtraRoll({
    required RulesConfig rules,
    required int dice,
    required bool moved,
    required bool didCapture,
    required bool didFinish,
  }) {
    var extra = false;
    if (dice == 6) {
      switch (rules.extraRollOnSix) {
        case ExtraRollOnSix.always:
          extra = true;
          break;
        case ExtraRollOnSix.onlyIfMoved:
          if (moved) extra = true;
          break;
        case ExtraRollOnSix.never:
          break;
      }
    }
    if (didCapture && rules.extraRollOnCapture) {
      extra = true;
    }
    if (didFinish && rules.extraRollOnFinish) {
      extra = true;
    }
    return extra;
  }

  static int _countColorOnTrack(GameState state, int trackIndex, PlayerId ownerId) {
    return state.pawns.values
        .where((pawn) =>
            pawn.ownerId == ownerId &&
            pawn.state.isTrack &&
            pawn.state.trackIndex == trackIndex)
        .length;
  }

  static int _countColorOnTrackWithOverrides(
      Map<PawnId, Pawn> pawns, int trackIndex, PlayerId ownerId) {
    return pawns.values
        .where((pawn) =>
            pawn.ownerId == ownerId &&
            pawn.state.isTrack &&
            pawn.state.trackIndex == trackIndex)
        .length;
  }

  static PlayerId _nextPlayerId(GameState state) {
    if (state.players.isEmpty) {
      throw StateError('No players configured');
    }
    var index =
        state.players.indexWhere((player) => player.id == state.currentPlayer);
    if (index == -1) index = 0;
    for (var offset = 1; offset <= state.players.length; offset++) {
      final candidate = state.players[(index + offset) % state.players.length];
      if (!state.ranking.contains(candidate.id)) {
        return candidate.id;
      }
    }
    return state.currentPlayer;
  }

  static GameState _applyTripleSixPenalty(
      GameState state, Player player, int dice) {
    final rule = state.rules.tripleSixRule;
    switch (rule) {
      case TripleSixRule.loseTurn:
        final updatedPlayers = state.players.map((p) {
          if (p.id == player.id) {
            return p.copyWith(consecutiveSixes: 0);
          }
          return p;
        }).toList();
        return state.copyWith(
          players: updatedPlayers,
          dice: dice,
          extraRollAwarded: false,
          phase: GamePhase.endTurn,
        );
      case TripleSixRule.invalidateLast:
        if (state.currentTurnHistory.isEmpty) {
          final updatedPlayers = state.players.map((p) {
            if (p.id == player.id) {
              return p.copyWith(consecutiveSixes: 0);
            }
            return p;
          }).toList();
          return state.copyWith(
            players: updatedPlayers,
            dice: dice,
            extraRollAwarded: false,
            phase: GamePhase.endTurn,
          );
        }
        final history = List<MoveRecord>.from(state.currentTurnHistory);
        final last = history.removeLast();

        final pawns = Map<PawnId, Pawn>.from(state.pawns);
        final movedPawn = pawns[last.pawnId];
        if (movedPawn != null) {
          pawns[last.pawnId] = movedPawn.copyWith(state: last.from);
        }
        for (final snapshot in last.captured) {
          pawns[snapshot.pawn.id] = snapshot.pawn;
        }

        final updatedPlayers = state.players.map((p) {
          if (p.id == player.id) {
            final newFinished =
                p.finishedCount - (last.finished ? 1 : 0);
            return p.copyWith(
              finishedCount: newFinished.clamp(0, p.finishedCount),
              consecutiveSixes: 0,
            );
          }
          return p;
        }).toList();

        var ranking = state.ranking;
        if (last.rankingUpdated && ranking.contains(player.id)) {
          final updated = List<PlayerId>.from(ranking)..remove(player.id);
          ranking = UnmodifiableListView(updated);
        }

        return state.copyWith(
          players: updatedPlayers,
          pawns: pawns,
          ranking: ranking,
          dice: dice,
          extraRollAwarded: false,
          currentTurnHistory: history,
          phase: GamePhase.endTurn,
        );
      case TripleSixRule.none:
        return state;
    }
  }
}
