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
  });
}

LudoGameState _stateWithPieces({
  required int redSteps,
  required int yellowSteps,
  required int diceValue,
}) {
  final initial = LudoGameState.newGame(playerCount: 2);
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
