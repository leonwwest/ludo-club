import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/game_rules.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';

GameState _stateFor(PlayerColor color, List<Piece> pieces, int lastDie,
    {required GameRules rules}) {
  final otherColor =
      color == PlayerColor.red ? PlayerColor.green : PlayerColor.red;
  return GameState(
    players: [
      Player(id: 'p1', name: 'P1', color: color, pieces: pieces),
      Player(
          id: 'p2',
          name: 'P2',
          color: otherColor,
          pieces: List.generate(
              4, (i) => Piece(otherColor, i, const PiecePosition(-1)))),
    ],
    currentTurnPlayerId: color,
    lastDiceValue: lastDie,
    startIndices: LudoGame.startFields,
    rules: rules,
  );
}

void main() {
  test('Exact roll required: overshoot in home lane is invalid', () {
    final rules = const GameRules();
    final piece = Piece(
      PlayerColor.red,
      0,
      const PiecePosition(GameConstants.homePathLength - 1),
    );
    final state = _stateFor(
        PlayerColor.red,
        [
          piece,
          for (int i = 1; i < 4; i++)
            Piece(PlayerColor.red, i, const PiecePosition(-1))
        ],
        2,
        rules: rules);

    final v = LudoGame.validateMove(state, piece, 2);
    expect(v.isValid, isFalse);
  });

  test('Non-exact finish: overshoot is allowed and clamps to finish', () {
    final rules = const GameRules(exactRollToFinish: false);
    final piece = Piece(
      PlayerColor.red,
      0,
      const PiecePosition(GameConstants.homePathLength - 2),
    );
    var state = _stateFor(
        PlayerColor.red,
        [
          piece,
          for (int i = 1; i < 4; i++)
            Piece(PlayerColor.red, i, const PiecePosition(-1))
        ],
        2,
        rules: rules);

    final v = LudoGame.validateMove(state, piece, 2);
    expect(v.isValid, isTrue);

    // Perform the move
    final res = LudoGame.movePiece(state, piece);
    state = res.newState;
    final moved = state.currentPlayer.pieces.firstWhere((p) => p.id == 0);
    expect(moved.isSafe, isTrue);
    expect(moved.position.fieldId, LudoGame.homePathLength);
  });
}
