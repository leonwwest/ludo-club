import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';

void main() {
  group('LudoRules', () {
    test('a six brings a piece out of base and grants another roll', () {
      var state = LudoGameState.newGame(playerCount: 2);

      state = LudoRules.roll(state, 6);
      state = LudoRules.movePiece(state, state.currentPlayer.pieces.first);

      final red = state.players.first;
      expect(red.pieces.first.steps, 0);
      expect(state.currentPlayer.color, PlayerColor.red);
      expect(state.phase, TurnPhase.waitingForRoll);
    });

    test('captures an opponent on an unsafe field', () {
      var state = _stateWithPieces(redSteps: 0, yellowSteps: 17, diceValue: 4);

      state = LudoRules.movePiece(state, state.currentPlayer.pieces.first);

      final red = state.players.firstWhere(
        (player) => player.color == PlayerColor.red,
      );
      final yellow = state.players.firstWhere(
        (player) => player.color == PlayerColor.yellow,
      );
      expect(red.pieces.first.steps, 4);
      expect(yellow.pieces.first.steps, -1);
      expect(state.moveSummary?.didCapture, isTrue);
      expect(state.currentPlayer.color, PlayerColor.red);
    });

    test('does not capture on a safe field', () {
      var state = _stateWithPieces(redSteps: 5, yellowSteps: 21, diceValue: 3);

      state = LudoRules.movePiece(state, state.currentPlayer.pieces.first);

      final yellow = state.players.firstWhere(
        (player) => player.color == PlayerColor.yellow,
      );
      expect(yellow.pieces.first.steps, 21);
      expect(state.moveSummary?.didCapture, isFalse);
      expect(state.currentPlayer.color, PlayerColor.yellow);
    });

    test('requires exact finish', () {
      var state = LudoGameState.newGame(playerCount: 2);
      final red = state.players.first;
      state = state.copyWith(
        players: [
          red.copyWith(
            pieces: [
              red.pieces.first.copyWith(steps: 56),
              ...red.pieces.skip(1),
            ],
          ),
          state.players.last,
        ],
      );

      final blocked = LudoRules.roll(state, 2);
      expect(blocked.currentPlayer.color, PlayerColor.yellow);
      expect(blocked.phase, TurnPhase.waitingForRoll);

      state = state.copyWith(phase: TurnPhase.waitingForMove, diceValue: 1);
      final finished = LudoRules.movePiece(
        state,
        state.currentPlayer.pieces.first,
      );
      expect(finished.players.first.pieces.first.isFinished, isTrue);
    });

    test('ends the game when the last piece reaches finish', () {
      var state = LudoGameState.newGame(playerCount: 2);
      final red = state.players.first;
      state = state.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 1,
        players: [
          red.copyWith(
            pieces: [
              red.pieces[0].copyWith(steps: 57),
              red.pieces[1].copyWith(steps: 57),
              red.pieces[2].copyWith(steps: 57),
              red.pieces[3].copyWith(steps: 56),
            ],
          ),
          state.players.last,
        ],
      );

      state = LudoRules.movePiece(state, state.currentPlayer.pieces.last);

      expect(state.phase, TurnPhase.gameOver);
      expect(state.winner, PlayerColor.red);
    });

    test('allows three opening rolls when that rule is enabled', () {
      var state = LudoGameState.newGame(
        playerCount: 2,
        rules: const RuleOptions(openRollRule: OpenRollRule.threeRolls),
      );

      state = LudoRules.roll(state, 2);

      expect(state.currentPlayer.color, PlayerColor.red);
      expect(state.phase, TurnPhase.waitingForRoll);
      expect(state.pendingOpenRolls, 2);
      expect(state.moveLog.first.message, contains('kein Zug'));
    });

    test('can require a six to leave base before moving another piece', () {
      var state = LudoGameState.newGame(
        playerCount: 2,
        rules: const RuleOptions(mustLeaveBaseOnSix: true),
      );
      final red = state.players.first;
      state = state.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 6,
        players: [
          red.copyWith(
            pieces: [
              red.pieces.first.copyWith(steps: 5),
              ...red.pieces.skip(1),
            ],
          ),
          state.players.last,
        ],
      );

      final movable = LudoRules.movablePieces(state);

      expect(movable.every((piece) => piece.isInBase), isTrue);
      expect(movable, hasLength(3));
    });

    test('can block landing on own occupied fields', () {
      var state = LudoGameState.newGame(
        playerCount: 2,
        rules: const RuleOptions(blockOwnFields: true),
      );
      final red = state.players.first;
      state = state.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 3,
        players: [
          red.copyWith(
            pieces: [
              red.pieces[0].copyWith(steps: 4),
              red.pieces[1].copyWith(steps: 7),
              ...red.pieces.skip(2),
            ],
          ),
          state.players.last,
        ],
      );

      expect(
        LudoRules.canMove(state, state.currentPlayer.pieces.first),
        isFalse,
      );
    });

    test('can grant an extra turn when a piece reaches finish', () {
      var state = LudoGameState.newGame(
        playerCount: 2,
        rules: const RuleOptions(extraTurnOnFinish: true),
      );
      final red = state.players.first;
      state = state.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 1,
        players: [
          red.copyWith(
            pieces: [
              red.pieces.first.copyWith(steps: 56),
              ...red.pieces.skip(1),
            ],
          ),
          state.players.last,
        ],
      );

      state = LudoRules.movePiece(state, state.currentPlayer.pieces.first);

      expect(state.currentPlayer.color, PlayerColor.red);
      expect(state.phase, TurnPhase.waitingForRoll);
    });

    test('can end the turn after the third consecutive six', () {
      var state = LudoGameState.newGame(
        playerCount: 2,
        rules: const RuleOptions(threeSixesEndTurn: true),
      );
      final red = state.players.first;
      state = state.copyWith(
        consecutiveSixes: 2,
        players: [
          red.copyWith(
            pieces: [
              red.pieces.first.copyWith(steps: 0),
              ...red.pieces.skip(1),
            ],
          ),
          state.players.last,
        ],
      );

      state = LudoRules.roll(state, 6);

      expect(state.currentPlayer.color, PlayerColor.yellow);
      expect(state.phase, TurnPhase.waitingForRoll);
      expect(state.consecutiveSixes, 0);
      expect(state.moveLog.first.message, contains('dritte 6'));
    });

    test('can force capturing moves when a capture is available', () {
      var state = LudoGameState.newGame(
        playerCount: 2,
        rules: const RuleOptions(mustCapture: true),
      );
      final red = state.players.first;
      final yellow = state.players.last;
      state = state.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 4,
        players: [
          red.copyWith(
            pieces: [
              red.pieces[0].copyWith(steps: 0),
              red.pieces[1].copyWith(steps: 5),
              ...red.pieces.skip(2),
            ],
          ),
          yellow.copyWith(
            pieces: [
              yellow.pieces.first.copyWith(steps: 17),
              ...yellow.pieces.skip(1),
            ],
          ),
        ],
      );

      expect(LudoRules.canMove(state, state.currentPlayer.pieces[0]), isTrue);
      expect(LudoRules.canMove(state, state.currentPlayer.pieces[1]), isFalse);
      expect(
        LudoRules.moveHintFor(state, state.currentPlayer.pieces[0]),
        contains('schlägt'),
      );
    });

    test('can disable bonus turns after captures', () {
      var state = _stateWithPieces(
        redSteps: 0,
        yellowSteps: 17,
        diceValue: 4,
        rules: const RuleOptions(extraTurnOnCapture: false),
      );

      state = LudoRules.movePiece(state, state.currentPlayer.pieces.first);

      expect(state.moveSummary?.didCapture, isTrue);
      expect(state.currentPlayer.color, PlayerColor.yellow);
    });

    test('ignores must-capture when the only capture lands on a safe field',
        () {
      final initial = LudoGameState.newGame(
        playerCount: 2,
        rules: const RuleOptions(mustCapture: true),
      );
      final red = initial.players.first;
      final yellow = initial.players.last;
      final state = initial.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 3,
        players: [
          red.copyWith(
            pieces: [
              red.pieces[0].copyWith(steps: 5),
              red.pieces[1].copyWith(steps: 10),
              ...red.pieces.skip(2),
            ],
          ),
          yellow.copyWith(
            pieces: [
              yellow.pieces.first.copyWith(steps: 21),
              ...yellow.pieces.skip(1),
            ],
          ),
        ],
      );

      expect(LudoRules.globalIndexFor(PlayerColor.red, 8), 21);
      expect(LudoRules.safeFields, contains(21));
      expect(LudoRules.canMove(state, state.currentPlayer.pieces[0]), isTrue);
      expect(LudoRules.canMove(state, state.currentPlayer.pieces[1]), isTrue);
    });

    test('does not move a piece that would overshoot the finish', () {
      final initial = LudoGameState.newGame(playerCount: 2);
      final red = initial.players.first;
      final state = initial.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 2,
        players: [
          red.copyWith(
            pieces: [
              red.pieces.first.copyWith(steps: LudoRules.finishStep),
              ...red.pieces.skip(1),
            ],
          ),
          initial.players.last,
        ],
      );

      expect(LudoRules.movablePieces(state), isEmpty);
      expect(
        LudoRules.movePiece(state, state.currentPlayer.pieces.first),
        same(state),
      );
    });

    test('keeps only the latest eight move log entries', () {
      var state = LudoGameState.newGame(playerCount: 2).copyWith(
        moveLog: [
          for (var i = 0; i < 8; i++)
            MoveLogEntry(message: 'old $i', color: PlayerColor.red),
        ],
        phase: TurnPhase.waitingForMove,
        diceValue: 6,
      );

      state = LudoRules.movePiece(state, state.currentPlayer.pieces.first);

      expect(state.moveLog, hasLength(8));
      expect(state.moveLog.first.message, contains('Figur 1'));
      expect(state.moveLog.last.message, 'old 6');
    });
  });
}

LudoGameState _stateWithPieces({
  required int redSteps,
  required int yellowSteps,
  required int diceValue,
  RuleOptions rules = const RuleOptions(),
}) {
  final initial = LudoGameState.newGame(playerCount: 2, rules: rules);
  final red = initial.players.firstWhere(
    (player) => player.color == PlayerColor.red,
  );
  final yellow = initial.players.firstWhere(
    (player) => player.color == PlayerColor.yellow,
  );

  return initial.copyWith(
    phase: TurnPhase.waitingForMove,
    diceValue: diceValue,
    players: [
      red.copyWith(
        pieces: [
          red.pieces.first.copyWith(steps: redSteps),
          ...red.pieces.skip(1),
        ],
      ),
      yellow.copyWith(
        pieces: [
          yellow.pieces.first.copyWith(steps: yellowSteps),
          ...yellow.pieces.skip(1),
        ],
      ),
    ],
  );
}
