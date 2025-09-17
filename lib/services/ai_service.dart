import 'dart:math';

import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_rules.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';

enum AIDifficulty {
  beginner,
  intermediate,
  expert,
}

class AIDecision {
  final Piece? selectedPiece;
  final String reasoning;
  final double confidence;

  AIDecision({
    this.selectedPiece,
    required this.reasoning,
    this.confidence = 0.5,
  });
}

class AIService {
  final Random _random;

  AIService({Random? random}) : _random = random ?? Random();

  Future<AIDecision> makeMove(
      GameState gameState, AIDifficulty difficulty) async {
    final movablePieces = LudoGame.getMovablePieces(gameState);
    if (movablePieces.isEmpty) {
      return AIDecision(
        reasoning: 'No movable pieces available',
        confidence: 1.0,
      );
    }

    final baseDelay = 300 + _random.nextInt(700);
    final adjustedDelay =
        (baseDelay * gameState.rules.aiThinkingTimeMultiplier).round();
    if (adjustedDelay > 0) {
      await Future.delayed(Duration(milliseconds: adjustedDelay));
    }

    switch (difficulty) {
      case AIDifficulty.beginner:
        return _makeBeginnerMove(gameState, movablePieces);
      case AIDifficulty.intermediate:
        return _makeIntermediateMove(gameState, movablePieces);
      case AIDifficulty.expert:
        return _makeExpertMove(gameState, movablePieces);
    }
  }

  AIDecision _makeBeginnerMove(GameState gameState, List<Piece> movablePieces) {
    if (_random.nextDouble() < 0.7) {
      final randomPiece = movablePieces[_random.nextInt(movablePieces.length)];
      return AIDecision(
        selectedPiece: randomPiece,
        reasoning: 'Random move selection',
        confidence: 0.3,
      );
    }

    final piecesInBase = movablePieces
        .where((p) =>
            p.position.isHome &&
            p.position.fieldId == GameConstants.basePosition)
        .toList();
    if (piecesInBase.isNotEmpty) {
      return AIDecision(
        selectedPiece: piecesInBase.first,
        reasoning: 'Bringing a piece into play',
        confidence: 0.55,
      );
    }

    final evaluated = _evaluateCandidates(gameState, movablePieces);
    if (evaluated.isNotEmpty) {
      final pick = evaluated.first;
      return AIDecision(
        selectedPiece: pick.piece,
        reasoning: pick.primaryReason,
      );
    }

    final fallback = movablePieces[_random.nextInt(movablePieces.length)];
    return AIDecision(
      selectedPiece: fallback,
      reasoning: 'Fallback selection',
      confidence: 0.3,
    );
  }

  AIDecision _makeIntermediateMove(
      GameState gameState, List<Piece> movablePieces) {
    final evaluated = _evaluateCandidates(gameState, movablePieces);
    if (evaluated.isEmpty) {
      final randomPiece = movablePieces[_random.nextInt(movablePieces.length)];
      return AIDecision(
        selectedPiece: randomPiece,
        reasoning: 'No evaluated moves – random fallback',
        confidence: 0.3,
      );
    }

    evaluated.sort((a, b) => b.score.compareTo(a.score));
    final best = evaluated.first;
    if (evaluated.length > 1 &&
        best.score - evaluated[1].score < 8 &&
        _random.nextDouble() < 0.2) {
      final alt = evaluated[1 + _random.nextInt(evaluated.length - 1)];
      return AIDecision(
        selectedPiece: alt.piece,
        reasoning: '${alt.primaryReason} (alternate)',
        confidence: 0.55,
      );
    }

    return AIDecision(
      selectedPiece: best.piece,
      reasoning: best.primaryReason,
      confidence: (0.55 + min(best.score, 60) / 150).clamp(0.55, 0.8),
    );
  }

  AIDecision _makeExpertMove(GameState gameState, List<Piece> movablePieces) {
    final evaluated = _evaluateCandidates(gameState, movablePieces);
    if (evaluated.isEmpty) {
      final randomPiece = movablePieces[_random.nextInt(movablePieces.length)];
      return AIDecision(
        selectedPiece: randomPiece,
        reasoning: 'No evaluated moves – random fallback',
      );
    }

    evaluated.sort((a, b) => b.score.compareTo(a.score));
    final best = evaluated.first;
    final confidence = (0.65 + min(best.score, 80) / 120).clamp(0.65, 0.95);
    return AIDecision(
      selectedPiece: best.piece,
      reasoning: best.primaryReason,
      confidence: confidence,
    );
  }

  List<_MoveEvaluation> _evaluateCandidates(
      GameState state, List<Piece> pieces) {
    final evaluations = <_MoveEvaluation>[];
    for (final piece in pieces) {
      final eval = _evaluateMove(state, piece);
      if (eval != null) {
        evaluations.add(eval);
      }
    }
    return evaluations;
  }

  _MoveEvaluation? _evaluateMove(GameState state, Piece piece) {
    final moveResult = LudoGame.movePiece(state, piece);
    if (identical(moveResult.newState, state)) {
      return null;
    }

    final GameRules rules = state.rules;
    final Player movedPlayer =
        moveResult.newState.players.firstWhere((p) => p.color == piece.color);
    final Piece movedPiece =
        movedPlayer.pieces.firstWhere((candidate) => candidate.id == piece.id);

    double score = 0;
    final List<String> reasons = [];

    if (piece.position.isHome &&
        piece.position.fieldId == GameConstants.basePosition &&
        !movedPiece.position.isHome) {
      score += 12;
      reasons.add('Leads a piece out of base');
    }

    final double progressBefore = _progressValue(piece);
    final double progressAfter = _progressValue(movedPiece);
    final double progressDelta = max(0, progressAfter - progressBefore);
    if (progressDelta > 0) {
      score += progressDelta * 0.6;
    }

    if (moveResult.isFinishMove || movedPiece.isSafe) {
      score += 50;
      reasons.insert(0, 'Finishes a token');
    }

    if (moveResult.didCapture) {
      final captureBonus = rules.captureReturnsToHome ? 35 : 10;
      score += captureBonus;
      reasons.insert(
          0,
          moveResult.capturedOpponents.length > 1
              ? 'Captures opponents'
              : 'Captures opponent');
    }

    if (moveResult.grantsExtraRoll) {
      score += 15;
      reasons.add('Keeps the turn');
    }

    if (!movedPiece.position.isHome &&
        rules.safeFieldsEnabled &&
        LudoGame.isSafeField(movedPiece.position.fieldId)) {
      score += 6;
      reasons.add('Lands on a safe tile');
    }

    if (rules.captureReturnsToHome) {
      final riskPenalty = _captureRiskPenalty(
        moveResult.newState,
        movedPiece,
        rules,
      );
      if (riskPenalty > 0) {
        score -= riskPenalty;
        reasons.add('Risky position (-${riskPenalty.toStringAsFixed(0)})');
      }
    }

    score += _endgameBonus(moveResult.newState, piece.color, rules);
    score += _smallVariation();

    final primaryReason =
        reasons.isNotEmpty ? reasons.first : 'Strong advancement';
    return _MoveEvaluation(
      piece: piece,
      score: score,
      primaryReason: primaryReason,
    );
  }

  double _progressValue(Piece piece) {
    if (piece.isSafe) {
      return GameConstants.totalMainPathFields +
          GameConstants.homePathLength +
          2;
    }
    if (piece.position.isHome) {
      if (piece.position.fieldId == GameConstants.basePosition) {
        return 0;
      }
      return GameConstants.totalMainPathFields + piece.position.fieldId + 1;
    }
    final start = LudoGame.startFields[piece.color] ?? 0;
    final index = piece.position.fieldId;
    final progress = (index - start + GameConstants.totalMainPathFields) %
        GameConstants.totalMainPathFields;
    return progress.toDouble() + 1;
  }

  double _captureRiskPenalty(
    GameState nextState,
    Piece movedPiece,
    GameRules rules,
  ) {
    if (movedPiece.position.isHome) {
      return 0;
    }
    if (rules.safeFieldsEnabled &&
        LudoGame.isSafeField(movedPiece.position.fieldId)) {
      return 0;
    }

    double highestThreat = 0;
    for (final player in nextState.players) {
      if (player.color == movedPiece.color) continue;
      for (final oppPiece in player.pieces) {
        if (oppPiece.position.isHome) continue;
        final distance = _distanceAlongMainPath(
          oppPiece.position.fieldId,
          movedPiece.position.fieldId,
        );
        if (distance > 0 && distance <= GameConstants.diceSides) {
          final threat = 14 - distance * 2;
          highestThreat = max(highestThreat, threat.toDouble());
        }
      }
    }
    return highestThreat;
  }

  double _endgameBonus(GameState state, PlayerColor color, GameRules rules) {
    final player = state.players.firstWhere((p) => p.color == color);
    final finishedCount = player.pieces.where((p) => p.isSafe).length;
    if (finishedCount >= rules.piecesToWin) {
      return 20;
    }
    return finishedCount * 4.0;
  }

  double _smallVariation() => (_random.nextDouble() - 0.5) * 2;

  int _distanceAlongMainPath(int from, int to) {
    return (to - from + GameConstants.totalMainPathFields) %
        GameConstants.totalMainPathFields;
  }
}

class _MoveEvaluation {
  _MoveEvaluation({
    required this.piece,
    required this.score,
    required this.primaryReason,
  });

  final Piece piece;
  final double score;
  final String primaryReason;
}
