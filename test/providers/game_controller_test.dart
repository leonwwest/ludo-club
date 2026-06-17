import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/providers/game_controller.dart';

void main() {
  group('GameController', () {
    test('starts a new game with the requested player count', () {
      final controller = GameController();

      controller.newGame(playerCount: 2);

      expect(controller.state.players, hasLength(2));
      expect(controller.state.players.map((player) => player.color), [
        PlayerColor.red,
        PlayerColor.yellow,
      ]);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
    });

    test('advances when a player rolls without a legal move', () {
      final controller = GameController(
        diceRoller: () => 3,
        initialPlayerCount: 2,
      );

      controller.rollDice();

      expect(controller.state.currentPlayer.color, PlayerColor.yellow);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.movablePieces, isEmpty);
    });

    test('exposes movable pieces after rolling a six', () {
      final controller = GameController(
        diceRoller: () => 6,
        initialPlayerCount: 2,
      );

      controller.rollDice();

      expect(controller.state.phase, TurnPhase.waitingForMove);
      expect(controller.movablePieces, hasLength(4));
    });
  });
}
