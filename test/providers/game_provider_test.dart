'''import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/providers/game_provider.dart';

void main() {
  group('GameProvider', () {
    late GameProvider gameProvider;

    setUp(() {
      gameProvider = GameProvider();
    });

    group('rollDice', () {
      test('rollDice updates gameState and notifies listeners', () async {
        bool listenerCalled = false;
        gameProvider.addListener(() {
          listenerCalled = true;
        });

        final actualRoll = await gameProvider.rollDice();

        expect(listenerCalled, isTrue);
        expect(gameProvider.gameState.lastDiceValue, isNotNull);
        expect(gameProvider.gameState.lastDiceValue, actualRoll);
      });
    });

    test('movePiece updates gameState and notifies listeners', () async {
      final initialPlayerColor = gameProvider.currentPlayerColor;
      final pieceToMove = gameProvider.getMovablePieces().first;

      bool listenerCalled = false;
      gameProvider.addListener(() {
        listenerCalled = true;
      });

      await gameProvider.movePiece(pieceToMove);

      expect(listenerCalled, isTrue);
      expect(gameProvider.gameState.currentTurnPlayerId, isNot(initialPlayerColor));
    });
  });
}
'''