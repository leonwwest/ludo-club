import 'dart:math';

import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';

/// Pure, seedable move selection for computer-controlled players.
class BotStrategy {
  const BotStrategy._();

  static LudoPiece? choosePiece(
    LudoGameState state, {
    required BotDifficulty difficulty,
    Random? random,
  }) {
    final candidates = LudoRules.movablePieces(state);
    if (candidates.isEmpty) {
      return null;
    }
    if (difficulty == BotDifficulty.easy) {
      return candidates[(random ?? Random()).nextInt(candidates.length)];
    }

    var bestPiece = candidates.first;
    var bestScore = double.negativeInfinity;
    for (final piece in candidates) {
      final score = difficulty == BotDifficulty.hard
          ? _hardScore(state, piece)
          : _normalScore(state, piece);
      if (score > bestScore) {
        bestScore = score;
        bestPiece = piece;
      }
    }
    return bestPiece;
  }

  static double _normalScore(LudoGameState state, LudoPiece piece) {
    final target = LudoRules.legalTargetStepsFor(state, piece) ?? piece.steps;
    final simulated = LudoRules.movePiece(state, piece);
    final summary = simulated.moveSummary;
    var score = target.toDouble();
    if (summary?.didCapture == true) {
      score += 500 + (summary!.captured.length * 30);
    }
    if (summary?.finished == true) {
      score += 350;
    }
    if (piece.isInBase) {
      score += 140;
    }
    if (target >= LudoRules.trackLength) {
      score += 80;
    } else {
      final targetGlobal = LudoRules.globalIndexFor(piece.color, target);
      if (LudoRules.safeFields.contains(targetGlobal)) {
        score += 110;
      }
    }
    if (simulated.phase == TurnPhase.gameOver) {
      score += 1000;
    }
    return score;
  }

  static double _hardScore(LudoGameState state, LudoPiece piece) {
    final simulated = LudoRules.movePiece(state, piece);
    final movedPiece = simulated.players
        .firstWhere((player) => player.color == piece.color)
        .pieces
        .firstWhere((candidate) => candidate.id == piece.id);
    final riskBefore = _captureRisk(state, piece);
    final riskAfter = _captureRisk(simulated, movedPiece);
    return _normalScore(state, piece) +
        (riskBefore * 18) -
        (riskAfter * 32) +
        _lookaheadScore(simulated, piece.color);
  }

  static int _captureRisk(LudoGameState state, LudoPiece piece) {
    final targetGlobal = LudoRules.globalIndexOf(piece);
    if (targetGlobal == null || LudoRules.safeFields.contains(targetGlobal)) {
      return 0;
    }

    var risk = 0;
    for (final player in state.players) {
      if (player.color == piece.color) {
        continue;
      }
      for (final opponent in player.pieces) {
        final opponentGlobal = LudoRules.globalIndexOf(opponent);
        if (opponentGlobal == null) {
          continue;
        }
        final distance =
            (targetGlobal - opponentGlobal) % LudoRules.trackLength;
        if (distance >= 1 &&
            distance <= 6 &&
            opponent.steps + distance < LudoRules.trackLength) {
          risk += 7 - distance;
        }
      }
    }
    return risk;
  }

  static double _lookaheadScore(
    LudoGameState state,
    PlayerColor mover,
  ) {
    if (state.phase == TurnPhase.gameOver) {
      return 0;
    }
    final moverIndex =
        state.players.indexWhere((player) => player.color == mover);
    if (moverIndex < 0) {
      return 0;
    }

    var total = 0.0;
    for (var dice = 1; dice <= 6; dice++) {
      final lookahead = state.copyWith(
        currentPlayerIndex: moverIndex,
        phase: TurnPhase.waitingForMove,
        diceValue: dice,
        winner: null,
      );
      var bestForRoll = 0.0;
      for (final candidate in LudoRules.movablePieces(lookahead)) {
        final target = LudoRules.legalTargetStepsFor(lookahead, candidate) ??
            candidate.steps;
        var value = (target - candidate.steps).toDouble();
        final result = LudoRules.movePiece(lookahead, candidate);
        if (result.moveSummary?.didCapture == true) {
          value += 45;
        }
        if (result.moveSummary?.finished == true) {
          value += 35;
        }
        if (value > bestForRoll) {
          bestForRoll = value;
        }
      }
      total += bestForRoll;
    }
    return total / 6;
  }
}
