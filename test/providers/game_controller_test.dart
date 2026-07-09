import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/models/move_event.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:ludo_club/services/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GameController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    GameStorage zeroDelayStorage() => GameStorage(debounceDelay: Duration.zero);

    GameController createController({
      DiceRoller? diceRoller,
      Random? random,
      int initialPlayerCount = 4,
      LudoGameState? initialState,
      GameStorage? storage,
      Duration botTurnDelay = const Duration(milliseconds: 720),
      bool botAutomationEnabled = true,
    }) {
      final controller = GameController(
        diceRoller: diceRoller,
        random: random,
        initialPlayerCount: initialPlayerCount,
        initialState: initialState,
        storage: storage ?? zeroDelayStorage(),
        botTurnDelay: botTurnDelay,
        botAutomationEnabled: botAutomationEnabled,
      );
      addTearDown(controller.dispose);
      return controller;
    }

    test('starts a new game with the requested player count', () async {
      final controller = createController();

      await controller.newGame(playerCount: 2);

      expect(controller.state.players, hasLength(2));
      expect(controller.state.players.map((player) => player.color), [
        PlayerColor.red,
        PlayerColor.yellow,
      ]);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
    });

    test('advances when a player rolls without a legal move', () async {
      final controller = createController(
        diceRoller: () => 3,
        initialPlayerCount: 2,
      );

      await controller.rollDice();

      expect(controller.state.currentPlayer.color, PlayerColor.yellow);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.movablePieces, isEmpty);
    });

    test('exposes movable pieces after rolling a six', () async {
      final controller = createController(
        diceRoller: () => 6,
        initialPlayerCount: 2,
      );

      await controller.rollDice();

      expect(controller.state.phase, TurnPhase.waitingForMove);
      expect(controller.movablePieces, hasLength(4));
    });

    test('updates player names in the current state', () async {
      final controller = createController(initialPlayerCount: 2);

      await controller.updatePlayerName(PlayerColor.red, 'Mira');

      expect(controller.state.players.first.name, 'Mira');
    });

    test('updates player kind in the current state', () async {
      final controller = createController(initialPlayerCount: 2);

      await controller.updatePlayerKind(PlayerColor.yellow, PlayerKind.bot);

      expect(controller.state.players.last.kind, PlayerKind.bot);
      expect(controller.state.players.last.isBot, isTrue);
    });

    test('updates player avatar in the current state', () async {
      final controller = createController(initialPlayerCount: 2);

      await controller.updatePlayerAvatar(
        PlayerColor.yellow,
        PlayerAvatarId.kiran,
      );

      expect(controller.state.players.last.avatarId, PlayerAvatarId.kiran);
    });

    test('new game preserves configured player avatars', () async {
      final controller = createController(initialPlayerCount: 2);

      await controller.updatePlayerAvatar(
        PlayerColor.yellow,
        PlayerAvatarId.kiran,
      );
      await controller.newGame();

      expect(controller.state.players.last.avatarId, PlayerAvatarId.kiran);
      expect(
        controller.state.players.last.pieces.every((piece) => piece.isInBase),
        isTrue,
      );
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
        playerKinds: const {PlayerColor.yellow: PlayerKind.bot},
        playerAvatars: const {PlayerColor.yellow: PlayerAvatarId.kiran},
      ).copyWith(
        consecutiveSixes: 2,
        moveLog: [
          const MoveLogEntry(
            event: MovePieceEvent(
              player: PlayerColor.red,
              pieceId: 0,
              diceValue: 6,
              capturedCount: 0,
              finished: false,
            ),
            color: PlayerColor.red,
          ),
        ],
      );

      final restored = LudoGameState.fromJson(state.toJson());

      expect(restored.players.first.name, 'Mira');
      expect(restored.players.last.kind, PlayerKind.bot);
      expect(restored.players.last.avatarId, PlayerAvatarId.kiran);
      expect(restored.rules.blockOwnFields, isTrue);
      expect(restored.rules.extraTurnOnCapture, isFalse);
      expect(restored.rules.threeSixesEndTurn, isTrue);
      expect(restored.rules.mustCapture, isTrue);
      expect(restored.consecutiveSixes, 2);
      expect(restored.moveLog.single.event, isA<MovePieceEvent>());
      expect(
        (restored.moveLog.single.event as MovePieceEvent).pieceId,
        0,
      );
    });

    test('undo restores the state before the last action', () async {
      final controller = createController(
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
      final controller = createController(
        diceRoller: () => 6,
        initialPlayerCount: 2,
      );

      await controller.rollDice();

      expect(
        controller.moveHintFor(controller.movablePieces.first),
        contains('kommt ins Spiel'),
      );
    });

    test('performs the only legal move when exactly one exists', () async {
      final baseState = LudoGameState.newGame(playerCount: 2);
      final red = baseState.players.first;
      final controller = createController(
        diceRoller: () => 3,
        initialState: baseState.copyWith(
          players: [
            red.copyWith(
              pieces: [
                red.pieces[0].copyWith(steps: 0),
                red.pieces[1].copyWith(steps: 57),
                red.pieces[2].copyWith(steps: 57),
                red.pieces[3].copyWith(steps: 57),
              ],
            ),
            baseState.players.last,
          ],
        ),
      );

      await controller.rollDice();
      final moved = await controller.performOnlyLegalMoveIfAvailable();

      expect(moved, isTrue);
      expect(controller.state.players.first.pieces.first.steps, 3);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.state.currentPlayer.color, PlayerColor.yellow);
    });

    test('does not auto-move when multiple legal moves exist', () async {
      final controller = createController(
        diceRoller: () => 6,
        initialPlayerCount: 2,
      );

      await controller.rollDice();
      final moved = await controller.performOnlyLegalMoveIfAvailable();

      expect(moved, isFalse);
      expect(controller.movablePieces, hasLength(4));
      expect(controller.state.phase, TurnPhase.waitingForMove);
      expect(
        controller.state.players.first.pieces.every((piece) => piece.isInBase),
        isTrue,
      );
    });

    test('persists state after rule and turn updates', () async {
      final storage = zeroDelayStorage();
      final controller = createController(
        diceRoller: () => 6,
        initialPlayerCount: 2,
        storage: storage,
      );

      await controller.updateRules(
        const RuleOptions(
          openRollRule: OpenRollRule.threeRolls,
          blockOwnFields: true,
          mustCapture: true,
        ),
      );
      await controller.rollDice();
      await controller.movePiece(controller.movablePieces.first);
      await storage.flush();

      final restored = await storage.loadSavedState();

      expect(restored, isNotNull);
      expect(restored!.rules.openRollRule, OpenRollRule.threeRolls);
      expect(restored.rules.blockOwnFields, isTrue);
      expect(restored.rules.mustCapture, isTrue);
      expect(restored.players.first.pieces.first.steps, 0);
      expect(restored.phase, TurnPhase.waitingForRoll);
      expect(restored.moveLog.first.event, isA<MovePieceEvent>());
    });

    test('automatically plays bot turns', () async {
      final rolls = [6, 3].iterator;
      final controller = createController(
        diceRoller: () {
          if (rolls.moveNext()) {
            return rolls.current;
          }
          return 2;
        },
        initialState: LudoGameState.newGame(
          playerCount: 2,
          playerKinds: const {PlayerColor.red: PlayerKind.bot},
        ),
        botTurnDelay: Duration.zero,
      );

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.currentPlayer.color, PlayerColor.yellow);
      expect(controller.state.players.first.pieces.first.steps, 3);
      expect(controller.state.moveLog.first.event, isA<MovePieceEvent>());
    });

    test('can pause bot automation until setup is started', () async {
      final rolls = [6, 3].iterator;
      final controller = createController(
        diceRoller: () {
          if (rolls.moveNext()) {
            return rolls.current;
          }
          return 2;
        },
        initialState: LudoGameState.newGame(
          playerCount: 2,
          playerKinds: const {PlayerColor.red: PlayerKind.bot},
        ),
        botTurnDelay: Duration.zero,
        botAutomationEnabled: false,
      );

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.currentPlayer.color, PlayerColor.red);
      expect(controller.state.moveLog, isEmpty);

      controller.setBotAutomationEnabled(true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.currentPlayer.color, PlayerColor.yellow);
      expect(controller.state.moveLog.first.event, isA<MovePieceEvent>());
    });

    test('clearSavedGame removes the persisted state', () async {
      final storage = zeroDelayStorage();
      final controller = createController(
        diceRoller: () => 6,
        initialPlayerCount: 2,
        storage: storage,
      );

      await controller.rollDice();
      await storage.flush();
      expect(await storage.loadSavedState(), isNotNull);

      await controller.clearSavedGame();

      expect(await storage.loadSavedState(), isNull);
    });

    test('undo history keeps the latest twenty-four snapshots', () async {
      final controller = createController(initialPlayerCount: 2);

      for (var index = 0; index < 30; index++) {
        await controller.updateRules(
          RuleOptions(blockOwnFields: index.isEven),
        );
      }

      for (var index = 0; index < 24; index++) {
        expect(controller.canUndo, isTrue);
        await controller.undoLastAction();
      }

      expect(controller.canUndo, isFalse);
      expect(controller.state.rules.blockOwnFields, isFalse);
    });

    test('ignores move requests for non-movable pieces', () async {
      final controller = createController(
        diceRoller: () => 3,
        initialPlayerCount: 2,
      );
      final initialState = controller.state;

      await controller.movePiece(controller.state.currentPlayer.pieces.first);

      expect(controller.state, same(initialState));
      expect(controller.canUndo, isFalse);
    });

    test('throws ArgumentError for invalid player count', () {
      expect(
        () => GameController(initialPlayerCount: 5),
        throwsArgumentError,
      );
      expect(
        () => GameController(initialPlayerCount: 1),
        throwsArgumentError,
      );
    });

    test('supports seedable random for reproducible rolls', () async {
      final controller1 = createController(
        random: Random(42),
        initialPlayerCount: 2,
      );
      final controller2 = createController(
        random: Random(42),
        initialPlayerCount: 2,
      );

      await controller1.rollDice();
      await controller2.rollDice();

      expect(controller1.state.diceValue, controller2.state.diceValue);
    });
  });
}
