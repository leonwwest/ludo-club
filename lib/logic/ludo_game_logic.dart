import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/models/board_zone.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';

class MoveResult {
  final GameState newState;
  final List<Piece> capturedOpponents;
  final bool isFinishMove;
  final bool pieceMoved;
  final bool grantsExtraRoll;

  const MoveResult({
    required this.newState,
    this.capturedOpponents = const [],
    this.isFinishMove = false,
    this.pieceMoved = false,
    this.grantsExtraRoll = false,
  });

  Piece? get capturedOpponentPiece =>
      capturedOpponents.isEmpty ? null : capturedOpponents.first;

  bool get didCapture => capturedOpponents.isNotEmpty;
}

enum ValidationError {
  notYourTurn,
  noDie,
  invalidDie,
  blockedByBarrier,
  occupiedByOpponent,
  exceedsGoal,
}

class MoveValidation {
  final bool isValid;
  final ValidationError? error;

  const MoveValidation.valid()
      : isValid = true,
        error = null;

  const MoveValidation.invalid(this.error) : isValid = false;
}

enum ExtraRollOnSixRule { never, onlyIfMoved, always }

enum TripleSixRule { loseTurn, invalidateLast, none }

enum _PieceZone { base, track, home, finished }

enum _MoveKind { enterFromBase, advanceOnTrack, enterHome, advanceHome }

class RulesConfig {
  final int trackLength;
  final int homeLength;
  final bool exactFinish;
  final bool startNeedsSix;
  final ExtraRollOnSixRule extraRollOnSixRule;
  final bool extraRollOnCapture;
  final bool extraRollOnFinish;
  final TripleSixRule tripleSixRule;
  final Set<int> safeSquares;
  final bool captureOnSafeAllowed;
  final bool allowBlockades;
  final bool blockadePassThrough;
  final bool ownStartIsSafe;
  final bool stackOnStartAllowed;
  final bool cannotEnterIfOwnStoneAtStart;
  final bool captureReturnsToHome;
  final int requiredFinishedPawns;

  const RulesConfig({
    required this.trackLength,
    required this.homeLength,
    required this.exactFinish,
    required this.startNeedsSix,
    required this.extraRollOnSixRule,
    required this.extraRollOnCapture,
    required this.extraRollOnFinish,
    required this.tripleSixRule,
    required this.safeSquares,
    required this.captureOnSafeAllowed,
    required this.allowBlockades,
    required this.blockadePassThrough,
    required this.ownStartIsSafe,
    required this.stackOnStartAllowed,
    required this.cannotEnterIfOwnStoneAtStart,
    required this.captureReturnsToHome,
    required this.requiredFinishedPawns,
  });

  factory RulesConfig.fromState(GameState state) {
    final rules = state.rules;
    final extraRule = rules.extraTurnOnSix
        ? ExtraRollOnSixRule.always
        : ExtraRollOnSixRule.never;
    final triple = rules.maxConsecutiveSixes <= 0
        ? TripleSixRule.none
        : TripleSixRule.loseTurn;
    final safeSquares = rules.safeFieldsEnabled
        ? Set<int>.of(GameConstants.safeMainPathFields)
        : <int>{};
    return RulesConfig(
      trackLength: GameConstants.totalMainPathFields,
      homeLength: GameConstants.homePathLength,
      exactFinish: rules.exactRollToFinish,
      startNeedsSix: rules.mustRollSixToStart,
      extraRollOnSixRule: extraRule,
      extraRollOnCapture: rules.extraTurnOnCapture,
      extraRollOnFinish: rules.extraTurnOnFinish,
      tripleSixRule: triple,
      safeSquares: safeSquares,
      captureOnSafeAllowed: !rules.safeFieldsEnabled,
      allowBlockades: !rules.multipleOccupancyAllowed,
      blockadePassThrough: false,
      ownStartIsSafe: rules.safeFieldsEnabled,
      stackOnStartAllowed: !rules.multipleOccupancyAllowed,
      cannotEnterIfOwnStoneAtStart: true,
      captureReturnsToHome: rules.captureReturnsToHome,
      requiredFinishedPawns: rules.piecesToWin,
    );
  }
}

class _MoveCandidate {
  final Piece piece;
  final PiecePosition targetPosition;
  final List<Piece> capturedPieces;
  final bool didFinish;
  final bool didMove;
  final _MoveKind kind;

  const _MoveCandidate({
    required this.piece,
    required this.targetPosition,
    this.capturedPieces = const [],
    this.didFinish = false,
    this.didMove = true,
    required this.kind,
  });

  bool get didCapture => capturedPieces.isNotEmpty;
}

class _MoveEvaluation {
  final _MoveCandidate? move;
  final ValidationError? error;

  const _MoveEvaluation.valid(this.move) : error = null;
  const _MoveEvaluation.invalid(this.error) : move = null;

  bool get isValid => move != null && error == null;
}

class LudoGame {
  LudoGame._();

  static const Map<PlayerColor, int> startFields = {
    PlayerColor.red: 0,
    PlayerColor.green: 13,
    PlayerColor.blue: 26,
    PlayerColor.yellow: 39,
  };

  static const int homePathLength = GameConstants.homePathLength;
  static const int totalMainFields = GameConstants.totalMainPathFields;

  static bool isSafeField(int index) {
    return GameConstants.safeMainPathFields.contains(index);
  }

  static List<Piece> getMovablePieces(GameState state) {
    final die = state.lastDiceValue ?? 0;
    if (die <= 0) return const [];
    final config = RulesConfig.fromState(state);
    final trackOccupants = _buildTrackOccupancy(state);
    final currentPlayer = state.currentPlayer;
    final moves = <Piece>[];
    for (final piece in currentPlayer.pieces) {
      final evaluation =
          _evaluateMove(state, piece, die, config, trackOccupants);
      if (evaluation.isValid) {
        moves.add(piece);
      }
    }
    return moves;
  }

  static MoveValidation validateMove(GameState state, Piece piece, int die) {
    final config = RulesConfig.fromState(state);
    final trackOccupants = _buildTrackOccupancy(state);
    final evaluation = _evaluateMove(state, piece, die, config, trackOccupants);
    if (evaluation.isValid) {
      return const MoveValidation.valid();
    }
    return MoveValidation.invalid(evaluation.error);
  }

  static MoveResult movePiece(GameState state, Piece piece) {
    final die = state.lastDiceValue ?? 0;
    final config = RulesConfig.fromState(state);
    final trackOccupants = _buildTrackOccupancy(state);
    final evaluation = _evaluateMove(state, piece, die, config, trackOccupants);

    if (!evaluation.isValid || evaluation.move == null) {
      return MoveResult(newState: state);
    }

    final move = evaluation.move!;
    final players = state.players
        .map((player) => Player(
              id: player.id,
              name: player.name,
              type: player.type,
              color: player.color,
              pieces: List<Piece>.from(player.pieces),
              aiDifficulty: player.aiDifficulty,
            ))
        .toList();

    for (final captured in move.capturedPieces) {
      _resetPieceToBase(players, captured);
    }

    final moverIndex =
        players.indexWhere((player) => player.color == piece.color);
    final mover = players[moverIndex];
    final updatedPieces = List<Piece>.from(mover.pieces);
    final pieceIndex =
        updatedPieces.indexWhere((candidate) => candidate.id == piece.id);

    final bool onTrack = !move.targetPosition.isHome;
    final bool inHome =
        move.targetPosition.isHome && move.targetPosition.fieldId >= 0;
    bool isSafe = false;
    if (onTrack) {
      isSafe = config.safeSquares.contains(move.targetPosition.fieldId);
    } else if (inHome) {
      isSafe = move.targetPosition.fieldId >= config.homeLength;
    }

    updatedPieces[pieceIndex] = Piece(
      piece.color,
      piece.id,
      move.targetPosition,
      isSafe: isSafe,
    );

    players[moverIndex] = Player(
      id: mover.id,
      name: mover.name,
      color: mover.color,
      type: mover.type,
      pieces: updatedPieces,
      aiDifficulty: mover.aiDifficulty,
    );

    final Player updatedPlayer = players[moverIndex];
    final finishedCount = updatedPlayer.pieces
        .where(
            (p) => p.position.isHome && p.position.fieldId >= config.homeLength)
        .length;

    PlayerColor? winner = state.winnerId;
    if (winner == null && finishedCount >= config.requiredFinishedPawns) {
      winner = updatedPlayer.color;
    }

    final newState = state.copyWith(players: players, winnerId: winner);
    final grantsExtra = _shouldGrantExtraRoll(config, die, move);

    return MoveResult(
      newState: newState,
      capturedOpponents: move.capturedPieces,
      isFinishMove: move.didFinish,
      pieceMoved: move.didMove,
      grantsExtraRoll: grantsExtra,
    );
  }

  static BoardZone zoneForPiece(Piece piece) {
    if (!piece.position.isHome) {
      return const BoardZone(ZoneType.main);
    }
    if (piece.isSafe &&
        piece.position.fieldId >= GameConstants.homePathLength) {
      return BoardZone(ZoneType.goal, color: piece.color);
    }
    return BoardZone(ZoneType.home, color: piece.color);
  }

  static _MoveEvaluation _evaluateMove(
    GameState state,
    Piece piece,
    int die,
    RulesConfig config,
    Map<int, List<Piece>> trackOccupants,
  ) {
    if (piece.color != state.currentTurnPlayerId) {
      return const _MoveEvaluation.invalid(ValidationError.notYourTurn);
    }
    if (die <= 0) {
      return const _MoveEvaluation.invalid(ValidationError.noDie);
    }

    final zone = _zoneOf(piece, config);
    switch (zone) {
      case _PieceZone.base:
        return _evaluateBaseMove(state, piece, die, config, trackOccupants);
      case _PieceZone.track:
        return _evaluateTrackMove(state, piece, die, config, trackOccupants);
      case _PieceZone.home:
        return _evaluateHomeMove(piece, die, config);
      case _PieceZone.finished:
        return const _MoveEvaluation.invalid(ValidationError.invalidDie);
    }
  }

  static _MoveEvaluation _evaluateBaseMove(
    GameState state,
    Piece piece,
    int die,
    RulesConfig config,
    Map<int, List<Piece>> trackOccupants,
  ) {
    if (config.startNeedsSix && die != GameConstants.requiredRollToLeaveBase) {
      return const _MoveEvaluation.invalid(ValidationError.invalidDie);
    }

    final startIndex = _startIndexFor(state, piece.color);
    final occupants = List<Piece>.from(trackOccupants[startIndex] ?? const []);
    final ownPieces =
        occupants.where((candidate) => candidate.color == piece.color).toList();
    final opponents =
        occupants.where((candidate) => candidate.color != piece.color).toList();

    if (ownPieces.isNotEmpty) {
      if (config.cannotEnterIfOwnStoneAtStart ||
          (!config.stackOnStartAllowed) ||
          (config.allowBlockades && ownPieces.length >= 2)) {
        return const _MoveEvaluation.invalid(ValidationError.blockedByBarrier);
      }
    }

    if (opponents.isNotEmpty) {
      if (_isBlockade(opponents, config)) {
        return const _MoveEvaluation.invalid(ValidationError.blockedByBarrier);
      }
      final isSafeStart =
          config.safeSquares.contains(startIndex) || config.ownStartIsSafe;
      final canCapture = config.captureReturnsToHome &&
          (!isSafeStart || config.captureOnSafeAllowed);
      if (!canCapture) {
        return const _MoveEvaluation.invalid(
            ValidationError.occupiedByOpponent);
      }
    }

    final target = PiecePosition(startIndex, isHome: false);
    final move = _MoveCandidate(
      piece: piece,
      targetPosition: target,
      capturedPieces: List<Piece>.from(
          config.captureReturnsToHome ? opponents : const <Piece>[]),
      kind: _MoveKind.enterFromBase,
    );
    return _MoveEvaluation.valid(move);
  }

  static _MoveEvaluation _evaluateTrackMove(
    GameState state,
    Piece piece,
    int die,
    RulesConfig config,
    Map<int, List<Piece>> trackOccupants,
  ) {
    if (die <= 0) {
      return const _MoveEvaluation.invalid(ValidationError.noDie);
    }

    final from = piece.position.fieldId;
    final entry = _homeEntryIndexFor(state, piece.color, config);
    final stepsToEntry = _distanceOnTrack(from, entry, config.trackLength);

    if (_pathBlockedByBarrier(
        piece, die, trackOccupants, config, config.trackLength)) {
      return const _MoveEvaluation.invalid(ValidationError.blockedByBarrier);
    }

    if (die >= stepsToEntry) {
      final remaining = die - stepsToEntry;
      if (remaining <= config.homeLength) {
        final homeIndex = remaining;
        final target = PiecePosition(homeIndex);
        final move = _MoveCandidate(
          piece: piece,
          targetPosition: target,
          didFinish: homeIndex >= config.homeLength,
          kind: _MoveKind.enterHome,
        );
        return _MoveEvaluation.valid(move);
      }
    }

    final targetIndex = (from + die) % config.trackLength;
    final occupants = List<Piece>.from(trackOccupants[targetIndex] ?? const []);
    final opponents =
        occupants.where((candidate) => candidate.color != piece.color).toList();
    final ownPieces =
        occupants.where((candidate) => candidate.color == piece.color).toList();

    if (opponents.isNotEmpty) {
      if (_isBlockade(opponents, config)) {
        return const _MoveEvaluation.invalid(ValidationError.blockedByBarrier);
      }
      final isSafeTarget = config.safeSquares.contains(targetIndex);
      final canCapture = config.captureReturnsToHome &&
          (!isSafeTarget || config.captureOnSafeAllowed);
      if (!canCapture) {
        if (!isSafeTarget) {
          return const _MoveEvaluation.invalid(
              ValidationError.occupiedByOpponent);
        }
        // Sharing on safe tile is allowed when capture is not permitted.
      }
    }

    if (opponents.isEmpty) {
      if (ownPieces.isNotEmpty) {
        if (!config.allowBlockades) {
          return const _MoveEvaluation.invalid(
              ValidationError.blockedByBarrier);
        }
        if (ownPieces.length >= 2) {
          return const _MoveEvaluation.invalid(
              ValidationError.blockedByBarrier);
        }
      }
    }

    final isSafeTarget = config.safeSquares.contains(targetIndex);
    final canCapture = config.captureReturnsToHome &&
        (!isSafeTarget || config.captureOnSafeAllowed);
    final captured = canCapture ? List<Piece>.from(opponents) : const <Piece>[];

    final move = _MoveCandidate(
      piece: piece,
      targetPosition: PiecePosition(targetIndex, isHome: false),
      capturedPieces: captured,
      kind: _MoveKind.advanceOnTrack,
    );
    return _MoveEvaluation.valid(move);
  }

  static _MoveEvaluation _evaluateHomeMove(
    Piece piece,
    int die,
    RulesConfig config,
  ) {
    if (die <= 0) {
      return const _MoveEvaluation.invalid(ValidationError.noDie);
    }
    final current = piece.position.fieldId;
    var target = current + die;
    if (config.exactFinish && target > config.homeLength) {
      return const _MoveEvaluation.invalid(ValidationError.exceedsGoal);
    }
    if (!config.exactFinish && target > config.homeLength) {
      target = config.homeLength;
    }
    final move = _MoveCandidate(
      piece: piece,
      targetPosition: PiecePosition(target),
      didFinish: target >= config.homeLength,
      didMove: target != current,
      kind: _MoveKind.advanceHome,
    );
    return _MoveEvaluation.valid(move);
  }

  static bool _pathBlockedByBarrier(
    Piece piece,
    int die,
    Map<int, List<Piece>> occupancy,
    RulesConfig config,
    int trackLength,
  ) {
    if (!config.allowBlockades) {
      return false;
    }
    var index = piece.position.fieldId;
    for (var step = 1; step <= die; step++) {
      index = (index + 1) % trackLength;
      final occupants = occupancy[index] ?? const [];
      if (occupants.isEmpty) continue;
      final others = occupants
          .where((candidate) =>
              candidate.color != piece.color || candidate.id != piece.id)
          .toList();
      if (_isBlockade(others, config)) {
        if (config.blockadePassThrough) {
          continue;
        }
        return true;
      }
    }
    return false;
  }

  static Map<int, List<Piece>> _buildTrackOccupancy(GameState state) {
    final map = <int, List<Piece>>{};
    for (final player in state.players) {
      for (final piece in player.pieces) {
        if (!piece.position.isHome) {
          map.putIfAbsent(piece.position.fieldId, () => <Piece>[]).add(piece);
        }
      }
    }
    return map;
  }

  static void _resetPieceToBase(List<Player> players, Piece victim) {
    final playerIndex =
        players.indexWhere((player) => player.color == victim.color);
    if (playerIndex < 0) {
      return;
    }
    final player = players[playerIndex];
    final pieces = List<Piece>.from(player.pieces);
    final idx = pieces.indexWhere((candidate) => candidate.id == victim.id);
    if (idx < 0) {
      return;
    }
    pieces[idx] = Piece(
      victim.color,
      victim.id,
      const PiecePosition(GameState.basePosition),
    );
    players[playerIndex] = Player(
      id: player.id,
      name: player.name,
      color: player.color,
      type: player.type,
      pieces: pieces,
      aiDifficulty: player.aiDifficulty,
    );
  }

  static _PieceZone _zoneOf(Piece piece, RulesConfig config) {
    if (!piece.position.isHome) {
      return _PieceZone.track;
    }
    if (piece.position.fieldId == GameState.basePosition) {
      return _PieceZone.base;
    }
    if (piece.position.fieldId >= config.homeLength) {
      return _PieceZone.finished;
    }
    return _PieceZone.home;
  }

  static bool _isBlockade(List<Piece> occupants, RulesConfig config) {
    if (!config.allowBlockades) return false;
    if (occupants.length < 2) return false;
    final color = occupants.first.color;
    return occupants.every((piece) => piece.color == color);
  }

  static int _startIndexFor(GameState state, PlayerColor color) {
    return state.startIndices[color] ?? startFields[color] ?? 0;
  }

  static int _homeEntryIndexFor(
      GameState state, PlayerColor color, RulesConfig config) {
    final startIndex = _startIndexFor(state, color);
    return (startIndex - 1 + config.trackLength) % config.trackLength;
  }

  static int _distanceOnTrack(int from, int to, int trackLength) {
    return (to - from + trackLength) % trackLength;
  }

  static bool _shouldGrantExtraRoll(
    RulesConfig config,
    int die,
    _MoveCandidate move,
  ) {
    if (die <= 0) return false;
    bool extra = false;
    if (die == GameConstants.requiredRollToLeaveBase) {
      switch (config.extraRollOnSixRule) {
        case ExtraRollOnSixRule.always:
          extra = true;
          break;
        case ExtraRollOnSixRule.onlyIfMoved:
          extra = move.didMove;
          break;
        case ExtraRollOnSixRule.never:
          break;
      }
    }
    if (config.extraRollOnCapture && move.didCapture) {
      extra = true;
    }
    if (config.extraRollOnFinish && move.didFinish) {
      extra = true;
    }
    return extra;
  }
}
