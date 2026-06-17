import 'package:ludo_club/models/ludo_models.dart';

class LudoRules {
  const LudoRules._();

  static const int piecesPerPlayer = 4;
  static const int trackLength = 52;
  static const int homeLength = 6;
  static const int finishStep = trackLength + homeLength - 1;
  static const Set<int> safeFields = {0, 8, 13, 21, 26, 34, 39, 47};

  static bool isValidDiceValue(int value) => value >= 1 && value <= 6;

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

  static List<LudoPiece> movablePieces(LudoGameState state) {
    final diceValue = state.diceValue;
    if (state.phase != TurnPhase.waitingForMove || diceValue == null) {
      return const [];
    }

    return state.currentPlayer.pieces
        .where((piece) => targetStepsFor(piece, diceValue) != null)
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

    final rolled = state.copyWith(
      phase: TurnPhase.waitingForMove,
      diceValue: diceValue,
      moveSummary: null,
      turnMessage: '${state.currentPlayer.name} würfelt $diceValue.',
    );

    if (movablePieces(rolled).isNotEmpty) {
      return rolled;
    }

    return _advanceTurn(
      rolled,
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

    final targetSteps = targetStepsFor(piece, diceValue);
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
    final extraTurn =
        winner == null && (diceValue == 6 || capturedPieces.isNotEmpty);
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
      );
    }

    if (extraTurn) {
      final reason =
          capturedPieces.isNotEmpty ? 'schlägt eine Figur' : 'hat eine 6';
      return state.copyWith(
        players: updatedPlayers,
        phase: TurnPhase.waitingForRoll,
        diceValue: null,
        moveSummary: summary,
        turnMessage: '${updatedMover.name} $reason und ist nochmal dran.',
      );
    }

    return _advanceTurn(
      state.copyWith(players: updatedPlayers, moveSummary: summary),
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
      turnMessage: '$message ${nextPlayer.name} ist dran.',
    );
  }

  static String _pieceKey(LudoPiece piece) => '${piece.color.name}:${piece.id}';
}
