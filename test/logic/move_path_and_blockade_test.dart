import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';

GameState _state({
  PlayerColor current = PlayerColor.red,
  int? lastDice,
  List<Player>? players,
}) {
  final defaultPlayers = [
    Player(
      id: 'p1',
      name: 'P1',
      color: PlayerColor.red,
      pieces: List.generate(4, (i) => Piece(PlayerColor.red, i, const PiecePosition(GameState.basePosition, isHome: true))),
    ),
    Player(
      id: 'p2',
      name: 'P2',
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
  group('Path and blockade rules', () {
    test('Red enters home at index 1 from 49 with 3', () {
      final redPieces = List.generate(4, (i) => Piece(PlayerColor.red, i,
          i == 0 ? const PiecePosition(49, isHome: false) : const PiecePosition(GameState.basePosition, isHome: true)));
      final s = _state(
        lastDice: 3,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.red, pieces: redPieces),
          Player(id: 'p2', name: 'P2', color: PlayerColor.green, pieces: List.generate(4, (i) => Piece(PlayerColor.green, i, const PiecePosition(GameState.basePosition, isHome: true)))),
        ],
      );
      final r = LudoGame.movePiece(s, redPieces.first);
      final moved = r.newState.players.firstWhere((p) => p.color == PlayerColor.red).pieces.firstWhere((p) => p.id == 0);
      expect(moved.position.isHome, isTrue);
      expect(moved.position.fieldId, 1);
    });

    test('Green enters home at index 0 from 10 with 2', () {
      final greenPieces = List.generate(4, (i) => Piece(PlayerColor.green, i,
          i == 0 ? const PiecePosition(10, isHome: false) : const PiecePosition(GameState.basePosition, isHome: true)));
      final s = _state(
        current: PlayerColor.green,
        lastDice: 2,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.green, pieces: greenPieces),
          Player(id: 'p2', name: 'P2', color: PlayerColor.red, pieces: List.generate(4, (i) => Piece(PlayerColor.red, i, const PiecePosition(GameState.basePosition, isHome: true)))),
        ],
      );
      final r = LudoGame.movePiece(s, greenPieces.first);
      final moved = r.newState.players.firstWhere((p) => p.color == PlayerColor.green).pieces.firstWhere((p) => p.id == 0);
      expect(moved.position.isHome, isTrue);
      expect(moved.position.fieldId, 0);
    });

    test('Blockade on safe field blocks passing', () {
      // Create a blockade (two red pieces) on safe field 8; green tries to pass through 8
      final redPieces = [
        Piece(PlayerColor.red, 0, const PiecePosition(8, isHome: false)),
        Piece(PlayerColor.red, 1, const PiecePosition(8, isHome: false)),
        Piece(PlayerColor.red, 2, const PiecePosition(GameState.basePosition, isHome: true)),
        Piece(PlayerColor.red, 3, const PiecePosition(GameState.basePosition, isHome: true)),
      ];
      final greenPieces = [
        Piece(PlayerColor.green, 0, const PiecePosition(6, isHome: false)),
        ...List.generate(3, (i) => Piece(PlayerColor.green, i + 1, const PiecePosition(GameState.basePosition, isHome: true))),
      ];
      final s = _state(
        current: PlayerColor.green,
        lastDice: 2,
        players: [
          Player(id: 'p1', name: 'P1', color: PlayerColor.red, pieces: redPieces),
          Player(id: 'p2', name: 'P2', color: PlayerColor.green, pieces: greenPieces),
        ],
      );

      final v = LudoGame.validateMove(s, greenPieces.first, 2);
      expect(v.isValid, isFalse);
      expect(v.error, ValidationError.blockedByBarrier);
    });
  });
}

