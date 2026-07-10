import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/bot_strategy.dart';
import 'package:ludo_club/models/ludo_models.dart';

void main() {
  group('BotStrategy', () {
    test('easy selection is reproducible with a seeded random source', () {
      final state = LudoGameState.newGame(playerCount: 2).copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 6,
      );

      final first = BotStrategy.choosePiece(
        state,
        difficulty: BotDifficulty.easy,
        random: Random(42),
      );
      final second = BotStrategy.choosePiece(
        state,
        difficulty: BotDifficulty.easy,
        random: Random(42),
      );

      expect(first, isNotNull);
      expect(second?.id, first?.id);
    });

    test('normal prioritizes a capture', () {
      final initial = LudoGameState.newGame(playerCount: 2);
      final red = initial.players.first;
      final yellow = initial.players.last;
      final state = initial.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 4,
        players: [
          red.copyWith(
            pieces: [
              red.pieces[0].copyWith(steps: 0),
              red.pieces[1].copyWith(steps: 8),
              red.pieces[2].copyWith(steps: 57),
              red.pieces[3].copyWith(steps: 57),
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

      final selected = BotStrategy.choosePiece(
        state,
        difficulty: BotDifficulty.normal,
      );

      expect(selected?.id, 0);
    });

    test('normal values a safe destination', () {
      final initial = LudoGameState.newGame(playerCount: 2);
      final red = initial.players.first;
      final state = initial.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 3,
        players: [
          red.copyWith(
            pieces: [
              red.pieces[0].copyWith(steps: 2),
              red.pieces[1].copyWith(steps: 5),
              red.pieces[2].copyWith(steps: 57),
              red.pieces[3].copyWith(steps: 57),
            ],
          ),
          initial.players.last,
        ],
      );

      final selected = BotStrategy.choosePiece(
        state,
        difficulty: BotDifficulty.normal,
      );

      expect(selected?.id, 1);
    });

    test('hard escapes a concrete capture threat normal ignores', () {
      final initial = LudoGameState.newGame(playerCount: 2);
      final red = initial.players.first;
      final yellow = initial.players.last;
      final state = initial.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 6,
        players: [
          red.copyWith(
            pieces: [
              red.pieces[0].copyWith(steps: 1),
              red.pieces[1].copyWith(steps: 30),
              red.pieces[2].copyWith(steps: 57),
              red.pieces[3].copyWith(steps: 57),
            ],
          ),
          yellow.copyWith(
            pieces: [
              for (final piece in yellow.pieces) piece.copyWith(steps: 13),
            ],
          ),
        ],
      );

      final normal = BotStrategy.choosePiece(
        state,
        difficulty: BotDifficulty.normal,
      );
      final hard = BotStrategy.choosePiece(
        state,
        difficulty: BotDifficulty.hard,
      );

      expect(normal?.id, 1);
      expect(hard?.id, 0);
    });
  });
}
