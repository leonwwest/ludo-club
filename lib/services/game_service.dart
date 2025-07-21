import 'dart:math';

import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';

class GameService {
  GameState gameState;
  int? debugNextDiceValue;

  GameService(this.gameState);

  int rollDice() {
    final diceValue = debugNextDiceValue ?? Random().nextInt(6) + 1;
    gameState.lastDiceValue = diceValue;
    gameState.currentRollCount++;

    if (diceValue == 6) {
      if (gameState.currentRollCount == 3) {
        _endTurn();
      }
    } else {
      final moves = getPossibleMoveDetails();
      if (moves.isEmpty) {
        _endTurn();
      }
    }

    debugNextDiceValue = null;
    return diceValue;
  }

  List<Map<String, dynamic>> getPossibleMoveDetails() {
    final moves = <Map<String, dynamic>>[];
    final player = gameState.currentPlayer;
    final diceValue = gameState.lastDiceValue;

    if (diceValue == null) {
      return moves;
    }

    for (int i = 0; i < player.pieces.length; i++) {
      final piece = player.pieces[i];
      if (piece.position.fieldId == GameState.basePosition) {
        if (diceValue == 6) {
          moves.add({
            'tokenIndex': i,
            'targetPosition': gameState.startIndices[player.color]!,
          });
        }
      } else if (piece.position.fieldId != GameState.finishedPosition) {
        final newPosition = piece.position.fieldId + diceValue;
        if (newPosition < GameState.totalFields) {
          moves.add({
            'tokenIndex': i,
            'targetPosition': newPosition,
          });
        } else {
          final homePathPosition = newPosition - GameState.totalFields;
          if (homePathPosition < GameState.homePathLength) {
            moves.add({
              'tokenIndex': i,
              'targetPosition': GameState.totalFields + homePathPosition,
            });
          } else if (homePathPosition == GameState.homePathLength) {
            moves.add({
              'tokenIndex': i,
              'targetPosition': GameState.finishedPosition,
            });
          }
        }
      }
    }

    return moves;
  }

  String? moveToken(PlayerColor playerColor, int tokenIndex, int targetPosition) {
    final player = gameState.players.firstWhere((p) => p.color == playerColor);
    final piece = player.pieces[tokenIndex];
    piece.position = PiecePosition(targetPosition);

    String? capturedPiecePlayerId;

    if (!gameState.isSafeField(targetPosition)) {
      for (final otherPlayer in gameState.players) {
        if (otherPlayer.color != playerColor) {
          for (final otherPiece in otherPlayer.pieces) {
            if (otherPiece.position.fieldId == targetPosition) {
              otherPiece.position = const PiecePosition(GameState.basePosition);
              capturedPiecePlayerId = otherPlayer.id;
              break;
            }
          }
        }
        if (capturedPiecePlayerId != null) {
          break;
        }
      }
    }

    if (capturedPiecePlayerId != null) {
      gameState.currentRollCount = 0;
      gameState.lastDiceValue = null;
    } else if (gameState.lastDiceValue != 6) {
      _endTurn();
    }

    return capturedPiecePlayerId;
  }

  void _endTurn() {
    gameState.currentTurnPlayerId = gameState.players[
            (gameState.players.indexWhere((p) => p.color == gameState.currentTurnPlayerId) + 1) %
                gameState.players.length]
        .color;
    gameState.lastDiceValue = null;
    gameState.currentRollCount = 0;
  }
}
