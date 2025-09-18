import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/game_rules.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';

GameState _stateWithPieces({
  required List<Piece> red,
  required List<Piece> green,
  int lastDie = 0,
  GameRules rules = GameRules.standard,
  PlayerColor turn = PlayerColor.green,
}) {
  return GameState(
    players: [
      Player(id: 'r', name: 'R', color: PlayerColor.red, pieces: red),
      Player(id: 'g', name: 'G', color: PlayerColor.green, pieces: green),
    ],
    currentTurnPlayerId: turn,
    lastDiceValue: lastDie,
    startIndices: LudoGame.startFields,
    rules: rules,
  );
}

void main() {
  test('Cannot land on a blockade', () {
    // Red blockade at index 5
    final red = [
      Piece(PlayerColor.red, 0, const PiecePosition(5, isHome: false)),
      Piece(PlayerColor.red, 1, const PiecePosition(5, isHome: false)),
      for (int i = 2; i < 4; i++)
        Piece(PlayerColor.red, i, const PiecePosition(-1))
    ];

    // Green tries to move onto index 5 from index 3 with die=2
    final greenPiece =
        Piece(PlayerColor.green, 0, const PiecePosition(3, isHome: false));
    final green = [
      greenPiece,
      for (int i = 1; i < 4; i++)
        Piece(PlayerColor.green, i, const PiecePosition(-1))
    ];
    final state = _stateWithPieces(red: red, green: green, lastDie: 2);

    final v = LudoGame.validateMove(state, greenPiece, 2);
    expect(v.isValid, isFalse);
  });

  test('Cannot pass through a blockade', () {
    final red = [
      Piece(PlayerColor.red, 0, const PiecePosition(5, isHome: false)),
      Piece(PlayerColor.red, 1, const PiecePosition(5, isHome: false)),
      for (int i = 2; i < 4; i++)
        Piece(PlayerColor.red, i, const PiecePosition(-1))
    ];
    // Green at index 3 tries to move 3 steps (4,5,6): blocked at 5
    final greenPiece =
        Piece(PlayerColor.green, 0, const PiecePosition(3, isHome: false));
    final green = [
      greenPiece,
      for (int i = 1; i < 4; i++)
        Piece(PlayerColor.green, i, const PiecePosition(-1))
    ];
    final state = _stateWithPieces(red: red, green: green, lastDie: 3);

    final v = LudoGame.validateMove(state, greenPiece, 3);
    expect(v.isValid, isFalse);
  });
}
