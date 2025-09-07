import 'dart:math';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/constants/game_constants.dart';

enum AIDifficulty {
  beginner,
  intermediate, 
  expert
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
  final Random _random = Random();

  /// Main entry point for AI decision making
  Future<AIDecision> makeMove(GameState gameState, AIDifficulty difficulty) async {
    final movablePieces = LudoGame.getMovablePieces(gameState);
    
    if (movablePieces.isEmpty) {
      return AIDecision(
        selectedPiece: null,
        reasoning: "No movable pieces available",
        confidence: 1.0,
      );
    }

    // Add some thinking delay to make AI feel more natural (adjusted by rules)
    final baseDelay = 300 + _random.nextInt(700);
    final adjustedDelay = (baseDelay * gameState.rules.aiThinkingTimeMultiplier).round();
    await Future.delayed(Duration(milliseconds: adjustedDelay));

    switch (difficulty) {
      case AIDifficulty.beginner:
        return _makeBeginnerMove(gameState, movablePieces);
      case AIDifficulty.intermediate:
        return _makeIntermediateMove(gameState, movablePieces);
      case AIDifficulty.expert:
        return _makeExpertMove(gameState, movablePieces);
    }
  }

  /// Beginner AI: Random moves with basic logic
  AIDecision _makeBeginnerMove(GameState gameState, List<Piece> movablePieces) {
    // 70% random, 30% basic logic
    if (_random.nextDouble() < 0.7) {
      final randomPiece = movablePieces[_random.nextInt(movablePieces.length)];
      return AIDecision(
        selectedPiece: randomPiece,
        reasoning: "Random move selection",
        confidence: 0.3,
      );
    }

    // Basic logic: prefer moving pieces out of home
    final piecesInHome = movablePieces.where((p) => p.position.isHome).toList();
    if (piecesInHome.isNotEmpty) {
      return AIDecision(
        selectedPiece: piecesInHome.first,
        reasoning: "Moving piece out of home",
        confidence: 0.6,
      );
    }

    // Fallback to random
    final randomPiece = movablePieces[_random.nextInt(movablePieces.length)];
    return AIDecision(
      selectedPiece: randomPiece,
      reasoning: "Fallback random selection",
      confidence: 0.3,
    );
  }

  /// Intermediate AI: Strategic piece selection and blocking
  AIDecision _makeIntermediateMove(GameState gameState, List<Piece> movablePieces) {
    final diceValue = gameState.lastDiceValue ?? 1;

    // 1. Priority: Move pieces out of home if possible
    final piecesInHome = movablePieces.where((p) => p.position.isHome).toList();
    if (piecesInHome.isNotEmpty && diceValue == GameConstants.requiredRollToLeaveBase) {
      return AIDecision(
        selectedPiece: piecesInHome.first,
        reasoning: "Moving piece out of home with 6",
        confidence: 0.9,
      );
    }

    // 2. Priority: Capture opponent pieces
    for (final piece in movablePieces) {
      final moveResult = LudoGame.movePiece(gameState, piece);
      if (moveResult.capturedOpponentPiece != null) {
        return AIDecision(
          selectedPiece: piece,
          reasoning: "Capturing opponent piece",
          confidence: 0.85,
        );
      }
    }

    // 3. Priority: Move piece that's furthest along
    final piecesOnBoard = movablePieces.where((p) => !p.position.isHome).toList();
    if (piecesOnBoard.isNotEmpty) {
      // Simple heuristic: piece with highest fieldId is furthest along
      final furthestPiece = piecesOnBoard.reduce((a, b) => 
          a.position.fieldId > b.position.fieldId ? a : b);
      return AIDecision(
        selectedPiece: furthestPiece,
        reasoning: "Advancing furthest piece",
        confidence: 0.6,
      );
    }

    // Fallback
    final randomPiece = movablePieces[_random.nextInt(movablePieces.length)];
    return AIDecision(
      selectedPiece: randomPiece,
      reasoning: "Strategic fallback selection",
      confidence: 0.4,
    );
  }

  /// Expert AI: Advanced tactics with better decision making
  AIDecision _makeExpertMove(GameState gameState, List<Piece> movablePieces) {
    final diceValue = gameState.lastDiceValue ?? 1;

    // 1. Priority: High-value captures (pieces far from home)
    for (final piece in movablePieces) {
      final moveResult = LudoGame.movePiece(gameState, piece);
      if (moveResult.capturedOpponentPiece != null) {
        final capturedPiece = moveResult.capturedOpponentPiece!;
        final captureValue = capturedPiece.position.isHome ? 5 : 
                            (capturedPiece.position.fieldId + 10); // Higher value for pieces further along
        
        if (captureValue > 15) { // Only high-value captures
          return AIDecision(
            selectedPiece: piece,
            reasoning: "High-value capture opportunity",
            confidence: 0.9,
          );
        }
      }
    }

    // 2. Priority: Move pieces out of home strategically
    final piecesInHome = movablePieces.where((p) => p.position.isHome).toList();
    if (piecesInHome.isNotEmpty && diceValue == GameConstants.requiredRollToLeaveBase) {
      return AIDecision(
        selectedPiece: piecesInHome.first,
        reasoning: "Strategic home exit",
        confidence: 0.85,
      );
    }

    // 3. Priority: Advance pieces close to finishing
    final piecesOnBoard = movablePieces.where((p) => !p.position.isHome).toList();
    if (piecesOnBoard.isNotEmpty) {
      // Find piece closest to finishing (highest fieldId)
      final bestPiece = piecesOnBoard.reduce((a, b) => 
          a.position.fieldId > b.position.fieldId ? a : b);
      
      return AIDecision(
        selectedPiece: bestPiece,
        reasoning: "Advancing toward finish",
        confidence: 0.75,
      );
    }

    // 4. Fallback with weighted selection
    final weights = movablePieces.map((piece) => _calculatePieceWeight(piece)).toList();
    final totalWeight = weights.fold<double>(0.0, (sum, weight) => sum + weight);
    final randomValue = _random.nextDouble() * totalWeight;
    
    double currentWeight = 0.0;
    for (int i = 0; i < movablePieces.length; i++) {
      currentWeight += weights[i];
      if (randomValue <= currentWeight) {
        return AIDecision(
          selectedPiece: movablePieces[i],
          reasoning: "Weighted expert selection",
          confidence: 0.6,
        );
      }
    }
    
    return AIDecision(
      selectedPiece: movablePieces.last,
      reasoning: "Expert fallback",
      confidence: 0.5,
    );
  }

  /// Calculate a simple weight for piece selection
  double _calculatePieceWeight(Piece piece) {
    if (piece.position.isHome) return 1.0;
    return 2.0 + (piece.position.fieldId * 0.1); // Higher weight for pieces further along
  }
} 
