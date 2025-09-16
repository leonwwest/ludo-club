import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_rules.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/services/ai_service.dart';

class _DeterministicRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.5;

  @override
  int nextInt(int max) => 0;
}

GameState _state({
  required List<Player> players,
  required PlayerColor current,
  required int lastDice,
  required GameRules rules,
}) {
  return GameState(
    players: players,
    currentTurnPlayerId: current,
    lastDiceValue: lastDice,
    startIndices: LudoGame.startFields,
    rules: rules,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Expert prefers finishing move when capture yields no reset', () async {
    final rules = GameRules.standard.copyWith(
      aiThinkingTimeMultiplier: 0,
      captureReturnsToHome: false,
      multipleOccupancyAllowed: true,
    );

    final redPieces = [
      Piece(PlayerColor.red, 0, const PiecePosition(6, isHome: false)),
      Piece(PlayerColor.red, 1,
          const PiecePosition(GameConstants.homePathLength - 1)),
      Piece(PlayerColor.red, 2, const PiecePosition(GameState.basePosition)),
      Piece(PlayerColor.red, 3, const PiecePosition(GameState.basePosition)),
    ];
    final greenPieces = [
      Piece(PlayerColor.green, 0, const PiecePosition(7, isHome: false)),
      Piece(PlayerColor.green, 1, const PiecePosition(GameState.basePosition)),
      Piece(PlayerColor.green, 2, const PiecePosition(GameState.basePosition)),
      Piece(PlayerColor.green, 3, const PiecePosition(GameState.basePosition)),
    ];

    final state = _state(
      players: [
        Player(
            id: 'red', name: 'Red', color: PlayerColor.red, pieces: redPieces),
        Player(
            id: 'green',
            name: 'Green',
            color: PlayerColor.green,
            pieces: greenPieces),
      ],
      current: PlayerColor.red,
      lastDice: 1,
      rules: rules,
    );

    final ai = AIService(random: _DeterministicRandom());
    final decision = await ai.makeMove(state, AIDifficulty.expert);

    expect(decision.selectedPiece, isNotNull);
    expect(decision.selectedPiece!.id, 1);
  });

  test('Expert prioritises capture when captures reset to home', () async {
    final rules = GameRules.standard.copyWith(aiThinkingTimeMultiplier: 0);
    final redPieces = [
      Piece(PlayerColor.red, 0, const PiecePosition(5, isHome: false)),
      Piece(PlayerColor.red, 1, const PiecePosition(10, isHome: false)),
      Piece(PlayerColor.red, 2, const PiecePosition(GameState.basePosition)),
      Piece(PlayerColor.red, 3, const PiecePosition(GameState.basePosition)),
    ];
    final greenPieces = [
      Piece(PlayerColor.green, 0, const PiecePosition(7, isHome: false)),
      Piece(PlayerColor.green, 1, const PiecePosition(GameState.basePosition)),
      Piece(PlayerColor.green, 2, const PiecePosition(GameState.basePosition)),
      Piece(PlayerColor.green, 3, const PiecePosition(GameState.basePosition)),
    ];

    final state = _state(
      players: [
        Player(
            id: 'red', name: 'Red', color: PlayerColor.red, pieces: redPieces),
        Player(
            id: 'green',
            name: 'Green',
            color: PlayerColor.green,
            pieces: greenPieces),
      ],
      current: PlayerColor.red,
      lastDice: 2,
      rules: rules,
    );

    final ai = AIService(random: _DeterministicRandom());
    final decision = await ai.makeMove(state, AIDifficulty.expert);

    expect(decision.selectedPiece, isNotNull);
    expect(decision.selectedPiece!.id, 0);
  });
}
