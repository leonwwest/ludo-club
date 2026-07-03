import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/models/move_event.dart';

class LudoRules {
  const LudoRules._();

  static const int piecesPerPlayer = GameConstants.piecesPerPlayer;
  static const int trackLength = GameConstants.trackLength;
  static const int homeLength = GameConstants.homeLength;
  static const int finishStep = GameConstants.finishStep;
  static const Set<int> safeFields = GameConstants.safeFields;

  static bool isValidDiceValue(int value) =>
      value >= GameConstants.diceMin && value <= GameConstants.diceMax;

  static int? globalIndexOf(LudoPiece piece) {
    if (!piece.isOnMainTrack) {
      return null;
    }
    return globalIndexFor(piece.color, piece.steps);
  }

  static int globalIndexFor(PlayerColor color, int steps) {
    return (color.startIndex + steps) % trackLength;
  }

  static int? homeLaneIndexOf(LudoPiece piece) {
    if (!piece.isInHomeLane && !piece.isFinished) {
      return null;
    }
    return piece.steps - trackLength;
  }

  static int? targetStepsFor(LudoPiece piece, int diceValue) {
    if (!isValidDiceValue(diceValue) || piece.isFinished) {
      return null;
    }
    if (piece.isInBase) {
      return diceValue == 6 ? 0 : null;
    }

    final target = piece.steps + diceValue;
    return target <= finishStep ? target : null;
  }

  static int? legalTargetStepsFor(
    LudoGameState state,
    LudoPiece piece,
  ) {
    final diceValue = state.diceValue;
    if (state.phase != TurnPhase.waitingForMove || diceValue == null) {
      return null;
    }
    if (piece.color != state.currentPlayer.color) {
      return null;
    }

    final baseTargets = [
      for (final candidate in state.currentPlayer.pieces)
        if (candidate.isInBase) candidate,
    ];
    if (state.rules.mustLeaveBaseOnSix &&
        diceValue == 6 &&
        baseTargets.isNotEmpty &&
        !piece.isInBase) {
      return null;
    }

    final target = targetStepsFor(piece, diceValue);
    if (target == null) {
      return null;
    }
    if (state.rules.blockOwnFields &&
        _isOwnFieldBlocked(state, piece, target)) {
      return null;
    }
    if (state.rules.mustCapture &&
        _currentPlayerHasCapture(state, diceValue) &&
        _capturedPiecesFor(state, piece, target).isEmpty) {
      return null;
    }
    return target;
  }

  static String? moveHintFor(LudoGameState state, LudoPiece piece) {
    final target = legalTargetStepsFor(state, piece);
    if (target == null) {
      return null;
    }

    final captured = _capturedPiecesFor(state, piece, target);
    if (captured.isNotEmpty) {
      final colors =
          captured.map((piece) => piece.color.colorLabel).toSet().join(', ');
      return 'Figur ${piece.id + 1} schlägt $colors.';
    }
    if (target == finishStep) {
      return 'Figur ${piece.id + 1} erreicht das Ziel.';
    }
    if (piece.isInBase) {
      return 'Figur ${piece.id + 1} kommt ins Spiel.';
    }
    if (target >= trackLength) {
      return 'Figur ${piece.id + 1} zieht in die Zielgasse.';
    }
    return 'Figur ${piece.id + 1} zieht auf Feld ${globalIndexFor(piece.color, target) + 1}.';
  }

  static List<LudoPiece> movablePieces(LudoGameState state) {
    if (state.phase != TurnPhase.waitingForMove) {
      return const [];
    }

    return state.currentPlayer.pieces
        .where((piece) => legalTargetStepsFor(state, piece) != null)
        .toList(growable: false);
  }

  static bool canMove(LudoGameState state, LudoPiece piece) {
    return movablePieces(state).any(
      (candidate) => candidate.color == piece.color && candidate.id == piece.id,
    );
  }

  static LudoGameState roll(LudoGameState state, int diceValue) {
    if (state.phase != TurnPhase.waitingForRoll ||
        !isValidDiceValue(diceValue)) {
      return state;
    }

    final consecutiveSixes = diceValue == 6 ? state.consecutiveSixes + 1 : 0;
    final rolled = state.copyWith(
      phase: TurnPhase.waitingForMove,
      diceValue: diceValue,
      consecutiveSixes: consecutiveSixes,
      moveSummary: null,
      turnMessage: '${state.currentPlayer.name} würfelt $diceValue.',
    );

    if (state.rules.threeSixesEndTurn &&
        consecutiveSixes >= GameConstants.consecutiveSixesLimit) {
      return _advanceTurn(
        rolled.copyWith(
          moveLog: _appendLog(
            state,
            ThreeSixesEvent(player: state.currentPlayer.color),
          ),
        ),
        diceValue: null,
        message:
            '${state.currentPlayer.name} würfelt die dritte 6. Der Zug verfällt.',
      );
    }

    if (movablePieces(rolled).isNotEmpty) {
      return rolled;
    }

    if (_canUseAnotherOpenRoll(rolled)) {
      final remaining = state.pendingOpenRolls - 1;
      return rolled.copyWith(
        phase: TurnPhase.waitingForRoll,
        pendingOpenRolls: remaining,
        turnMessage:
            '${state.currentPlayer.name} würfelt $diceValue und darf nochmal (${remaining + 1}. Versuch).',
        moveLog: _appendLog(
          state,
          NoMoveEvent(
            player: state.currentPlayer.color,
            diceValue: diceValue,
          ),
        ),
      );
    }

    return _advanceTurn(
      rolled.copyWith(
        moveLog: _appendLog(
          state,
          NoMoveEvent(
            player: state.currentPlayer.color,
            diceValue: diceValue,
          ),
        ),
      ),
      diceValue: diceValue,
      message:
          '${state.currentPlayer.name} würfelt $diceValue und kann nicht ziehen.',
    );
  }

  static LudoGameState movePiece(LudoGameState state, LudoPiece piece) {
    final diceValue = state.diceValue;
    if (state.phase != TurnPhase.waitingForMove || diceValue == null) {
      return state;
    }
    if (piece.color != state.currentPlayer.color) {
      return state;
    }

    final targetSteps = legalTargetStepsFor(state, piece);
    if (targetSteps == null) {
      return state;
    }

    final fromSteps = piece.steps;
    final capturedPieces = _capturedPiecesFor(state, piece, targetSteps);
    final updatedPlayers = _playersAfterMove(
      state,
      piece: piece,
      targetSteps: targetSteps,
      capturedPieces: capturedPieces,
    );
    final updatedMover = updatedPlayers.firstWhere(
      (player) => player.color == piece.color,
    );
    final finished = targetSteps == finishStep;
    final winner = updatedMover.hasWon ? updatedMover.color : null;
    final extraTurn = winner == null &&
        (diceValue == 6 ||
            (capturedPieces.isNotEmpty && state.rules.extraTurnOnCapture) ||
            (finished && state.rules.extraTurnOnFinish));
    final summary = MoveSummary(
      mover: piece.color,
      pieceId: piece.id,
      fromSteps: fromSteps,
      toSteps: targetSteps,
      captured: capturedPieces,
      extraTurn: extraTurn,
      finished: finished,
    );

    if (winner != null) {
      return state.copyWith(
        players: updatedPlayers,
        phase: TurnPhase.gameOver,
        winner: winner,
        moveSummary: summary,
        turnMessage: '${updatedMover.name} gewinnt die Partie.',
        moveLog: _appendLog(
          state,
          WinEvent(player: updatedMover.color),
        ),
      );
    }

    if (extraTurn) {
      final reason = capturedPieces.isNotEmpty
          ? 'schlägt eine Figur'
          : finished
              ? 'erreicht das Ziel'
              : 'hat eine 6';
      return state.copyWith(
        players: updatedPlayers,
        phase: TurnPhase.waitingForRoll,
        diceValue: null,
        pendingOpenRolls: _pendingOpenRollsFor(updatedMover, state.rules),
        moveSummary: summary,
        turnMessage: '${updatedMover.name} $reason und ist nochmal dran.',
        moveLog: _appendLog(
          state,
          MovePieceEvent(
            player: updatedMover.color,
            pieceId: piece.id,
            diceValue: diceValue,
            capturedCount: capturedPieces.length,
            finished: finished,
          ),
        ),
      );
    }

    return _advanceTurn(
      state.copyWith(
        players: updatedPlayers,
        moveSummary: summary,
        moveLog: _appendLog(
          state,
          MovePieceEvent(
            player: updatedMover.color,
            pieceId: piece.id,
            diceValue: diceValue,
            capturedCount: capturedPieces.length,
            finished: finished,
          ),
        ),
      ),
      diceValue: null,
      message: '${updatedMover.name} zieht Figur ${piece.id + 1}.',
    );
  }

  static List<LudoPiece> _capturedPiecesFor(
    LudoGameState state,
    LudoPiece movingPiece,
    int targetSteps,
  ) {
    if (targetSteps < 0 || targetSteps >= trackLength) {
      return const [];
    }

    final targetGlobalIndex = globalIndexFor(movingPiece.color, targetSteps);
    if (safeFields.contains(targetGlobalIndex)) {
      return const [];
    }

    return state.players
        .where((player) => player.color != movingPiece.color)
        .expand((player) => player.pieces)
        .where((piece) => globalIndexOf(piece) == targetGlobalIndex)
        .toList(growable: false);
  }

  static List<LudoPlayer> _playersAfterMove(
    LudoGameState state, {
    required LudoPiece piece,
    required int targetSteps,
    required List<LudoPiece> capturedPieces,
  }) {
    final capturedKeys = {
      for (final captured in capturedPieces) _pieceKey(captured),
    };

    return [
      for (final player in state.players)
        player.copyWith(
          pieces: [
            for (final currentPiece in player.pieces)
              if (_pieceKey(currentPiece) == _pieceKey(piece))
                currentPiece.copyWith(steps: targetSteps)
              else if (capturedKeys.contains(_pieceKey(currentPiece)))
                currentPiece.copyWith(steps: -1)
              else
                currentPiece,
          ],
        ),
    ];
  }

  static LudoGameState _advanceTurn(
    LudoGameState state, {
    required int? diceValue,
    required String message,
  }) {
    final nextPlayerIndex =
        (state.currentPlayerIndex + 1) % state.players.length;
    final nextPlayer = state.players[nextPlayerIndex];
    return state.copyWith(
      currentPlayerIndex: nextPlayerIndex,
      phase: TurnPhase.waitingForRoll,
      diceValue: diceValue,
      consecutiveSixes: 0,
      pendingOpenRolls: _pendingOpenRollsFor(nextPlayer, state.rules),
      turnMessage: '$message ${nextPlayer.name} ist dran.',
    );
  }

  static String _pieceKey(LudoPiece piece) => '${piece.color.name}:${piece.id}';

  static bool _canUseAnotherOpenRoll(LudoGameState state) {
    return state.currentPlayer.pieces.every((piece) => piece.isInBase) &&
        state.pendingOpenRolls > GameConstants.minPendingRolls;
  }

  static int _pendingOpenRollsFor(LudoPlayer player, RuleOptions rules) {
    return player.pieces.every((piece) => piece.isInBase)
        ? rules.rollsWhenNoPieceIsOut
        : 1;
  }

  static bool _isOwnFieldBlocked(
    LudoGameState state,
    LudoPiece movingPiece,
    int targetSteps,
  ) {
    if (targetSteps >= trackLength) {
      return false;
    }

    final targetGlobalIndex = globalIndexFor(movingPiece.color, targetSteps);
    return state.currentPlayer.pieces.any((piece) {
      return piece.id != movingPiece.id &&
          globalIndexOf(piece) == targetGlobalIndex;
    });
  }

  static bool _currentPlayerHasCapture(LudoGameState state, int diceValue) {
    for (final piece in state.currentPlayer.pieces) {
      if (_baseRuleBlocksPiece(state, piece, diceValue)) {
        continue;
      }
      final target = targetStepsFor(piece, diceValue);
      if (target == null) {
        continue;
      }
      if (state.rules.blockOwnFields &&
          _isOwnFieldBlocked(state, piece, target)) {
        continue;
      }
      if (_capturedPiecesFor(state, piece, target).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static bool _baseRuleBlocksPiece(
    LudoGameState state,
    LudoPiece piece,
    int diceValue,
  ) {
    if (!state.rules.mustLeaveBaseOnSix || diceValue != 6 || piece.isInBase) {
      return false;
    }
    return state.currentPlayer.pieces.any((candidate) => candidate.isInBase);
  }

  static List<MoveLogEntry> _appendLog(
    LudoGameState state,
    MoveEvent event,
  ) {
    return [
      MoveLogEntry(event: event, color: event.player),
      ...state.moveLog,
    ].take(GameConstants.moveLogCap).toList(growable: false);
  }
}
