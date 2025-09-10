import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';

GameState _stateWith({
  required List<Player> players,
  required PlayerColor current,
  int? lastDiceValue,
}) {
  return GameState(
    players: players,
    currentTurnPlayerId: current,
    lastDiceValue: lastDiceValue,
    startIndices: LudoGame.startFields,
  );
}

Player _player(PlayerColor color, List<Piece> pieces) =>
    Player(id: color.name, name: color.name, color: color, pieces: pieces);

Piece _base(PlayerColor color, int id) => Piece(color, id, const PiecePosition(-1));

void main() {
  group('Move validation - home/goal rules', () {
    test('TC1: Red enters first home with exact 1 (allowed)', () {
      // Setup: red at main pos 50, die=1
      final red = _player(PlayerColor.red, [
        Piece(PlayerColor.red, 0, const PiecePosition(50, isHome: false)),
        _base(PlayerColor.red, 1),
        _base(PlayerColor.red, 2),
        _base(PlayerColor.red, 3),
      ]);
      final yellow = _player(PlayerColor.yellow, [
        _base(PlayerColor.yellow, 0),
        _base(PlayerColor.yellow, 1),
        _base(PlayerColor.yellow, 2),
        _base(PlayerColor.yellow, 3),
      ]);
      var state = _stateWith(players: [red, yellow], current: PlayerColor.red, lastDiceValue: 1);

      final movable = LudoGame.getMovablePieces(state);
      expect(movable.any((p) => p.color == PlayerColor.red && p.id == 0), isTrue);

      final res = LudoGame.movePiece(state, red.pieces.first);
      state = res.newState;
      final moved = state.players.firstWhere((p) => p.color == PlayerColor.red).pieces.firstWhere((p) => p.id == 0);
      expect(moved.position.isHome, isTrue);
      expect(moved.position.fieldId, equals(1));
    });

    test('TC2: Yellow does not enter red home (stays on main path)', () {
      // Setup: yellow near red entry, die=2
      final yellowPiece = Piece(PlayerColor.yellow, 0, const PiecePosition(50, isHome: false));
      final yellow = _player(PlayerColor.yellow, [yellowPiece, _base(PlayerColor.yellow, 1), _base(PlayerColor.yellow, 2), _base(PlayerColor.yellow, 3)]);
      final red = _player(PlayerColor.red, [_base(PlayerColor.red, 0), _base(PlayerColor.red, 1), _base(PlayerColor.red, 2), _base(PlayerColor.red, 3)]);
      final state = _stateWith(players: [yellow, red], current: PlayerColor.yellow, lastDiceValue: 2);

      final movable = LudoGame.getMovablePieces(state);
      expect(movable.contains(yellowPiece), isTrue);

      final res = LudoGame.movePiece(state, yellowPiece);
      final updatedYellow = res.newState.players.firstWhere((p) => p.color == PlayerColor.yellow);
      final moved = updatedYellow.pieces.firstWhere((p) => p.id == 0);
      // (50 + 2) % 52 = 0
      expect(moved.position.isHome, isFalse);
      expect(moved.position.fieldId, equals(0));
    });

    test('TC3: Red overshoots goal by 1 (invalid)', () {
      // Setup: red in home at 5, die=2 (home length 6)
      final redPiece = Piece(PlayerColor.red, 0, const PiecePosition(5));
      final red = _player(PlayerColor.red, [redPiece, _base(PlayerColor.red, 1), _base(PlayerColor.red, 2), _base(PlayerColor.red, 3)]);
      final green = _player(PlayerColor.green, [_base(PlayerColor.green, 0), _base(PlayerColor.green, 1), _base(PlayerColor.green, 2), _base(PlayerColor.green, 3)]);
      final state = _stateWith(players: [red, green], current: PlayerColor.red, lastDiceValue: 2);

      final v = LudoGame.validateMove(state, redPiece, 2);
      expect(v.isValid, isFalse);
      expect(v.error, ValidationError.exceedsGoal);
    });

    test('TC4: Two reds can stack in home (no capture)', () {
      final redA = Piece(PlayerColor.red, 0, const PiecePosition(2));
      final redB = Piece(PlayerColor.red, 1, const PiecePosition(1));
      final red = _player(PlayerColor.red, [redA, redB, _base(PlayerColor.red, 2), _base(PlayerColor.red, 3)]);
      final blue = _player(PlayerColor.blue, [_base(PlayerColor.blue, 0), _base(PlayerColor.blue, 1), _base(PlayerColor.blue, 2), _base(PlayerColor.blue, 3)]);
      final state = _stateWith(players: [red, blue], current: PlayerColor.red, lastDiceValue: 1);

      final res = LudoGame.movePiece(state, redB);
      final updatedRed = res.newState.players.firstWhere((p) => p.color == PlayerColor.red);
      final a = updatedRed.pieces.firstWhere((p) => p.id == 0);
      final b = updatedRed.pieces.firstWhere((p) => p.id == 1);
      expect(a.position.isHome && b.position.isHome, isTrue);
      expect(a.position.fieldId, equals(2));
      expect(b.position.fieldId, equals(2));
      expect(res.capturedOpponentPiece, isNull);
    });

    test('TC5: Capture on main path works; none in home', () {
      final redPiece = Piece(PlayerColor.red, 0, const PiecePosition(10, isHome: false));
      final yellowPiece = Piece(PlayerColor.yellow, 0, const PiecePosition(11, isHome: false));
      final red = _player(PlayerColor.red, [redPiece, _base(PlayerColor.red, 1), _base(PlayerColor.red, 2), _base(PlayerColor.red, 3)]);
      final yellow = _player(PlayerColor.yellow, [yellowPiece, _base(PlayerColor.yellow, 1), _base(PlayerColor.yellow, 2), _base(PlayerColor.yellow, 3)]);
      var state = _stateWith(players: [red, yellow], current: PlayerColor.red, lastDiceValue: 1);

      final res = LudoGame.movePiece(state, redPiece);
      expect(res.capturedOpponentPiece, isNotNull);
      final newState = res.newState;
      final updatedYellow = newState.players.firstWhere((p) => p.color == PlayerColor.yellow);
      final resetPiece = updatedYellow.pieces.firstWhere((p) => p.id == 0);
      expect(resetPiece.position.isHome, isTrue);
      expect(resetPiece.position.fieldId, equals(-1));

      // Now ensure moves within home do not capture (stacking allowed)
      final ra = Piece(PlayerColor.red, 0, const PiecePosition(1));
      final rb = Piece(PlayerColor.red, 1, const PiecePosition(2));
      final s2 = _stateWith(
        players: [
          _player(PlayerColor.red, [ra, rb, _base(PlayerColor.red, 2), _base(PlayerColor.red, 3)]),
          _player(PlayerColor.yellow, [_base(PlayerColor.yellow, 0), _base(PlayerColor.yellow, 1), _base(PlayerColor.yellow, 2), _base(PlayerColor.yellow, 3)]),
        ],
        current: PlayerColor.red,
        lastDiceValue: 1,
      );
      final res2 = LudoGame.movePiece(s2, ra);
      expect(res2.capturedOpponentPiece, isNull);
      final updRed = res2.newState.players.firstWhere((p) => p.color == PlayerColor.red);
      final a2 = updRed.pieces.firstWhere((p) => p.id == 0);
      final b2 = updRed.pieces.firstWhere((p) => p.id == 1);
      expect(a2.position.fieldId, equals(2));
      expect(b2.position.fieldId, equals(2));
    });
  });
}

