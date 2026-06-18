import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GameController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

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

    test('updates player names in the current state', () async {
      final controller = GameController(initialPlayerCount: 2);

      await controller.updatePlayerName(PlayerColor.red, 'Mira');

      expect(controller.state.players.first.name, 'Mira');
    });

    test('serializes and restores game state', () {
      final state = LudoGameState.newGame(
        playerCount: 2,
        rules: const RuleOptions(
          blockOwnFields: true,
          extraTurnOnCapture: false,
          threeSixesEndTurn: true,
          mustCapture: true,
        ),
        playerNames: const {PlayerColor.red: 'Mira'},
      ).copyWith(
        consecutiveSixes: 2,
        moveLog: const [
          MoveLogEntry(message: 'Mira: 6 mit Figur 1', color: PlayerColor.red),
        ],
      );

      final restored = LudoGameState.fromJson(state.toJson());

      expect(restored.players.first.name, 'Mira');
      expect(restored.rules.blockOwnFields, isTrue);
      expect(restored.rules.extraTurnOnCapture, isFalse);
      expect(restored.rules.threeSixesEndTurn, isTrue);
      expect(restored.rules.mustCapture, isTrue);
      expect(restored.consecutiveSixes, 2);
      expect(restored.moveLog.single.message, 'Mira: 6 mit Figur 1');
    });

    test('undo restores the state before the last action', () async {
      final controller = GameController(
        diceRoller: () => 6,
        initialPlayerCount: 2,
      );

      await controller.rollDice();
      expect(controller.canUndo, isTrue);
      expect(controller.state.phase, TurnPhase.waitingForMove);

      await controller.undoLastAction();

      expect(controller.canUndo, isFalse);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.state.diceValue, isNull);
    });

    test('exposes concrete move hints for movable pieces', () async {
      final controller = GameController(
        diceRoller: () => 6,
        initialPlayerCount: 2,
      );

      await controller.rollDice();

      expect(
        controller.moveHintFor(controller.movablePieces.first),
        contains('kommt ins Spiel'),
      );
    });
  });
}
