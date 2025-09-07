import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';

GameState _makeState({
  PlayerColor current = PlayerColor.red,
  int? lastDice,
  List<Player>? players,
}) {
  List<Player> defaultPlayers = [
    Player(
      id: 'p1',
      name: 'Player 1',
      color: PlayerColor.red,
      pieces: List.generate(4, (i) => Piece(PlayerColor.red, i, const PiecePosition(GameState.basePosition, isHome: true))),
    ),
    Player(
      id: 'p2',
      name: 'Player 2',
      color: PlayerColor.green,
      pieces: List.generate(4, (i) => Piece(PlayerColor.green, i, const PiecePosition(GameState.basePosition, isHome: true))),
    ),
  ];

  return GameState(
    players: players ?? defaultPlayers,
    currentTurnPlayerId: current,
    lastDiceValue: lastDice,
    startIndices: LudoGame.startFields,
  );
}

void main() {
  group('LudoGame logic', () {
    test('No moves when dice is null or zero', () {
      expect(LudoGame.getMovablePieces(_makeState(lastDice: null)), isEmpty);
      expect(LudoGame.getMovablePieces(_makeState(lastDice: 0)), isEmpty);
    });

    test('Pieces can leave home only on a 6', () {
      final stateNoMove = _makeState(lastDice: 5);
      expect(LudoGame.getMovablePieces(stateNoMove), isEmpty);

      final stateMove = _makeState(lastDice: 6);
      final movable = LudoGame.getMovablePieces(stateMove);
      expect(movable.length, 4, reason: 'All 4 red pieces can move on a 6');

      final moved = LudoGame.movePiece(stateMove, movable.first);
      final red = moved.newState.players.firstWhere((p) => p.color == PlayerColor.red);
      final piece = red.pieces.firstWhere((p) => p.id == movable.first.id);
      expect(piece.position.isHome, isFalse);
      expect(piece.position.fieldId, LudoGame.startFields[PlayerColor.red]);
    });

    test('Normal main path movement without home entry', () {
      // Red piece at 10, roll 5 -> goes to 15 (no home entry near here)
      final redPieces = List.generate(4, (i) => Piece(PlayerColor.red, i,
          i == 0 ? const PiecePosition(10, isHome: false) : const PiecePosition(GameState.basePosition, isHome: true)));
      final state = _makeState(
        lastDice: 5,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.red, pieces: redPieces),
          Player(id: 'p2', name: 'P2', color: PlayerColor.green, pieces: List.generate(4, (i) => Piece(PlayerColor.green, i, const PiecePosition(GameState.basePosition, isHome: true)))),
        ],
      );
      final moved = LudoGame.movePiece(state, redPieces.first);
      final redAfter = moved.newState.players.firstWhere((p) => p.color == PlayerColor.red);
      expect(redAfter.pieces.first.position.fieldId, 15);
      expect(moved.capturedOpponentPiece, isNull);
    });

    test('Captures when landing on opponent on non-safe field', () {
      // Red piece at 1, green piece at 2, roll 1 -> capture at 2 (not safe)
      final redPieces = List.generate(4, (i) => Piece(PlayerColor.red, i,
          i == 0 ? const PiecePosition(1, isHome: false) : const PiecePosition(GameState.basePosition, isHome: true)));
      final greenPieces = List.generate(4, (i) => Piece(PlayerColor.green, i,
          i == 0 ? const PiecePosition(2, isHome: false) : const PiecePosition(GameState.basePosition, isHome: true)));

      final state = _makeState(
        lastDice: 1,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.red, pieces: redPieces),
          Player(id: 'p2', name: 'P2', color: PlayerColor.green, pieces: greenPieces),
        ],
      );

      final movable = LudoGame.getMovablePieces(state);
      expect(movable.map((p) => p.id), contains(0));

      final result = LudoGame.movePiece(state, movable.firstWhere((p) => p.id == 0));
      expect(result.capturedOpponentPiece, isNotNull);

      final newGreen = result.newState.players.firstWhere((p) => p.color == PlayerColor.green);
      final captured = newGreen.pieces.firstWhere((p) => p.id == 0);
      expect(captured.position.isHome, isTrue);
      expect(captured.position.fieldId, GameState.basePosition);
    });

    test('No capture occurs on safe fields', () {
      // Safe fields include 8; land on 8 where opponent stands
      final redPieces = [
        Piece(PlayerColor.red, 0, const PiecePosition(7, isHome: false)),
        ...List.generate(3, (i) => Piece(PlayerColor.red, i + 1, const PiecePosition(GameState.basePosition, isHome: true))),
      ];
      final greenPieces = [
        Piece(PlayerColor.green, 0, const PiecePosition(8, isHome: false)),
        ...List.generate(3, (i) => Piece(PlayerColor.green, i + 1, const PiecePosition(GameState.basePosition, isHome: true))),
      ];
      final state = _makeState(
        lastDice: 1,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.red, pieces: redPieces),
          Player(id: 'p2', name: 'P2', color: PlayerColor.green, pieces: greenPieces),
        ],
      );
      final result = LudoGame.movePiece(state, redPieces.first);
      expect(result.capturedOpponentPiece, isNull);
      final redAfter = result.newState.players.firstWhere((p) => p.color == PlayerColor.red);
      final greenAfter = result.newState.players.firstWhere((p) => p.color == PlayerColor.green);
      expect(redAfter.pieces.first.position.fieldId, 8);
      expect(greenAfter.pieces.first.position.fieldId, 8);
    });

    test('Enters home stretch and can finish', () {
      // Red at 49 with roll 3 -> enters home stretch at position 1
      final redPieces = List.generate(4, (i) => Piece(PlayerColor.red, i,
          i == 0 ? const PiecePosition(49, isHome: false) : const PiecePosition(GameState.basePosition, isHome: true)));
      final state = _makeState(
        lastDice: 3,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.red, pieces: redPieces),
          Player(id: 'p2', name: 'P2', color: PlayerColor.green, pieces: List.generate(4, (i) => Piece(PlayerColor.green, i, const PiecePosition(GameState.basePosition, isHome: true)))),
        ],
      );

      final result = LudoGame.movePiece(state, redPieces.first);
      final redAfter = result.newState.players.firstWhere((p) => p.color == PlayerColor.red);
      final moved = redAfter.pieces.firstWhere((p) => p.id == 0);
      expect(moved.position.isHome, isTrue);
      expect(moved.position.fieldId, 1);

      // Now in home stretch at 5, roll 1 -> finished and safe
      final state2 = _makeState(
        lastDice: 1,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.red, pieces: [
            Piece(PlayerColor.red, 0, const PiecePosition(5, isHome: true)),
            ...List.generate(3, (i) => Piece(PlayerColor.red, i + 1, const PiecePosition(GameState.basePosition, isHome: true))),
          ]),
          Player(id: 'p2', name: 'P2', color: PlayerColor.green, pieces: List.generate(4, (i) => Piece(PlayerColor.green, i, const PiecePosition(GameState.basePosition, isHome: true)))),
        ],
      );
      final finish = LudoGame.movePiece(state2, state2.currentPlayer.pieces.first);
      final redFinal = finish.newState.players.firstWhere((p) => p.color == PlayerColor.red);
      final finishedPiece = redFinal.pieces.firstWhere((p) => p.id == 0);
      expect(finishedPiece.isSafe, isTrue);
      expect(finishedPiece.position.isHome, isTrue);
      expect(finishedPiece.position.fieldId, LudoGame.homePathLength);
      expect(finish.isFinishMove, isTrue);
    });

    test('Cannot overshoot in home stretch', () {
      // Red piece at home position 5, roll 2 -> cannot move
      final redPieces = [
        Piece(PlayerColor.red, 0, const PiecePosition(5, isHome: true)),
        ...List.generate(3, (i) => Piece(PlayerColor.red, i + 1, const PiecePosition(GameState.basePosition, isHome: true))),
      ];
      final state = _makeState(
        lastDice: 2,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.red, pieces: redPieces),
          Player(id: 'p2', name: 'P2', color: PlayerColor.green, pieces: List.generate(4, (i) => Piece(PlayerColor.green, i, const PiecePosition(GameState.basePosition, isHome: true)))),
        ],
      );
      final movable = LudoGame.getMovablePieces(state);
      expect(movable.where((p) => p.id == 0), isEmpty);
    });

    test('Winner is set when all pieces finished', () {
      // Three pieces already safe, fourth at 5 in home; roll 1 -> winner
      final redPieces = [
        Piece(PlayerColor.red, 0, const PiecePosition(LudoGame.homePathLength, isHome: true), isSafe: true),
        Piece(PlayerColor.red, 1, const PiecePosition(LudoGame.homePathLength, isHome: true), isSafe: true),
        Piece(PlayerColor.red, 2, const PiecePosition(LudoGame.homePathLength, isHome: true), isSafe: true),
        Piece(PlayerColor.red, 3, const PiecePosition(5, isHome: true)),
      ];
      final state = _makeState(
        lastDice: 1,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.red, pieces: redPieces),
          Player(id: 'p2', name: 'P2', color: PlayerColor.green, pieces: List.generate(4, (i) => Piece(PlayerColor.green, i, const PiecePosition(GameState.basePosition, isHome: true)))),
        ],
      );
      final result = LudoGame.movePiece(state, redPieces[3]);
      expect(result.newState.winnerId, PlayerColor.red);
    });

    test('Wrap-around on main path without home entry (blue)', () {
      // Blue home entry at 25; piece at 51 with roll 3 wraps to 2
      final bluePieces = List.generate(4, (i) => Piece(PlayerColor.blue, i,
          i == 0 ? const PiecePosition(51, isHome: false) : const PiecePosition(GameState.basePosition, isHome: true)));
      final state = _makeState(
        current: PlayerColor.blue,
        lastDice: 3,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.red, pieces: List.generate(4, (i) => Piece(PlayerColor.red, i, const PiecePosition(GameState.basePosition, isHome: true)))),
          Player(id: 'p2', name: 'P2', color: PlayerColor.blue, pieces: bluePieces),
        ],
      );
      final result = LudoGame.movePiece(state, bluePieces.first);
      final blueAfter = result.newState.players.firstWhere((p) => p.color == PlayerColor.blue);
      final moved = blueAfter.pieces.firstWhere((p) => p.id == 0);
      expect(moved.position.isHome, isFalse);
      expect(moved.position.fieldId, 2);
    });

    test('Green enters home stretch at index 12', () {
      // Green home entry is 12; from 10 with roll 2 -> home index 0
      final greenPieces = List.generate(4, (i) => Piece(PlayerColor.green, i,
          i == 0 ? const PiecePosition(10, isHome: false) : const PiecePosition(GameState.basePosition, isHome: true)));
      final state = _makeState(
        current: PlayerColor.green,
        lastDice: 2,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.green, pieces: greenPieces),
          Player(id: 'p2', name: 'P2', color: PlayerColor.red, pieces: List.generate(4, (i) => Piece(PlayerColor.red, i, const PiecePosition(GameState.basePosition, isHome: true)))),
        ],
      );
      final result = LudoGame.movePiece(state, greenPieces.first);
      final greenAfter = result.newState.players.firstWhere((p) => p.color == PlayerColor.green);
      final moved = greenAfter.pieces.firstWhere((p) => p.id == 0);
      expect(moved.position.isHome, isTrue);
      expect(moved.position.fieldId, 0);
    });

    test('Overshoot at home entry continues on main path', () {
      // Red entry at 51; from 40 with roll 20 -> remaining after entry would be 9 (>6)
      // Should NOT enter home; continue to (40+20)%52 = 8
      final redPieces = [
        Piece(PlayerColor.red, 0, const PiecePosition(40, isHome: false)),
        ...List.generate(3, (i) => Piece(PlayerColor.red, i + 1, const PiecePosition(GameState.basePosition, isHome: true))),
      ];
      final state = _makeState(
        lastDice: 20,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.red, pieces: redPieces),
          Player(id: 'p2', name: 'P2', color: PlayerColor.green, pieces: List.generate(4, (i) => Piece(PlayerColor.green, i, const PiecePosition(GameState.basePosition, isHome: true)))),
        ],
      );
      final result = LudoGame.movePiece(state, redPieces.first);
      final redAfter = result.newState.players.firstWhere((p) => p.color == PlayerColor.red);
      final moved = redAfter.pieces.firstWhere((p) => p.id == 0);
      expect(moved.position.isHome, isFalse);
      expect(moved.position.fieldId, 8);
    });
  });
}
