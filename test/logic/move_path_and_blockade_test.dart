import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_rules.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/constants/game_constants.dart';

GameState _state({
  PlayerColor current = PlayerColor.red,
  int? lastDice,
  List<Player>? players,
  GameRules rules = GameRules.standard,
}) {
  final defaultPlayers = [
    Player(
      id: 'p1',
      name: 'P1',
      color: PlayerColor.red,
      pieces: List.generate(
          4,
          (i) => Piece(
              PlayerColor.red, i, const PiecePosition(GameState.basePosition))),
    ),
    Player(
      id: 'p2',
      name: 'P2',
      color: PlayerColor.green,
      pieces: List.generate(
          4,
          (i) => Piece(PlayerColor.green, i,
              const PiecePosition(GameState.basePosition))),
    ),
  ];
  return GameState(
    players: players ?? defaultPlayers,
    currentTurnPlayerId: current,
    lastDiceValue: lastDice,
    startIndices: LudoGame.startFields,
    rules: rules,
  );
}

void main() {
  group('Path and blockade rules', () {
    test('Red enters home at index 1 from 49 with 3', () {
      final redPieces = List.generate(
          4,
          (i) => Piece(
              PlayerColor.red,
              i,
              i == 0
                  ? const PiecePosition(49, isHome: false)
                  : const PiecePosition(GameState.basePosition)));
      final s = _state(
        lastDice: 3,
        players: [
          Player(
              id: 'p1', name: 'P1', color: PlayerColor.red, pieces: redPieces),
          Player(
              id: 'p2',
              name: 'P2',
              color: PlayerColor.green,
              pieces: List.generate(
                  4,
                  (i) => Piece(PlayerColor.green, i,
                      const PiecePosition(GameState.basePosition)))),
        ],
      );
      final r = LudoGame.movePiece(s, redPieces.first);
      final moved = r.newState.players
          .firstWhere((p) => p.color == PlayerColor.red)
          .pieces
          .firstWhere((p) => p.id == 0);
      expect(moved.position.isHome, isTrue);
      expect(moved.position.fieldId, 1);
    });

    test('Green enters home at index 0 from 10 with 2', () {
      final greenPieces = List.generate(
          4,
          (i) => Piece(
              PlayerColor.green,
              i,
              i == 0
                  ? const PiecePosition(10, isHome: false)
                  : const PiecePosition(GameState.basePosition)));
      final s = _state(
        current: PlayerColor.green,
        lastDice: 2,
        players: [
          Player(
              id: 'p1',
              name: 'P1',
              color: PlayerColor.green,
              pieces: greenPieces),
          Player(
              id: 'p2',
              name: 'P2',
              color: PlayerColor.red,
              pieces: List.generate(
                  4,
                  (i) => Piece(PlayerColor.red, i,
                      const PiecePosition(GameState.basePosition)))),
        ],
      );
      final r = LudoGame.movePiece(s, greenPieces.first);
      final moved = r.newState.players
          .firstWhere((p) => p.color == PlayerColor.green)
          .pieces
          .firstWhere((p) => p.id == 0);
      expect(moved.position.isHome, isTrue);
      expect(moved.position.fieldId, 0);
    });

    test('Blockade on safe field blocks passing', () {
      // Create a blockade (two red pieces) on safe field 8; green tries to pass through 8
      final redPieces = [
        Piece(PlayerColor.red, 0, const PiecePosition(8, isHome: false)),
        Piece(PlayerColor.red, 1, const PiecePosition(8, isHome: false)),
        Piece(PlayerColor.red, 2, const PiecePosition(GameState.basePosition)),
        Piece(PlayerColor.red, 3, const PiecePosition(GameState.basePosition)),
      ];
      final greenPieces = [
        Piece(PlayerColor.green, 0, const PiecePosition(6, isHome: false)),
        ...List.generate(
            3,
            (i) => Piece(PlayerColor.green, i + 1,
                const PiecePosition(GameState.basePosition))),
      ];
      final s = _state(
        current: PlayerColor.green,
        lastDice: 2,
        players: [
          Player(
              id: 'p1', name: 'P1', color: PlayerColor.red, pieces: redPieces),
          Player(
              id: 'p2',
              name: 'P2',
              color: PlayerColor.green,
              pieces: greenPieces),
        ],
      );

      final v = LudoGame.validateMove(s, greenPieces.first, 2);
      expect(v.isValid, isFalse);
      expect(v.error, ValidationError.blockedByBarrier);
    });

    test('Leaving base without six allowed when rule disabled', () {
      final rules = GameRules.standard.copyWith(mustRollSixToStart: false);
      final state = _state(lastDice: 3, rules: rules);
      final redPiece = state.players
          .firstWhere((p) => p.color == PlayerColor.red)
          .pieces
          .first;

      final validation = LudoGame.validateMove(state, redPiece, 3);
      expect(validation.isValid, isTrue);

      final result = LudoGame.movePiece(state, redPiece);
      final moved = result.newState.players
          .firstWhere((p) => p.color == PlayerColor.red)
          .pieces
          .first;
      final startIndex = LudoGame.startFields[PlayerColor.red]!;
      expect(moved.position.isHome, isFalse);
      // Without the six-to-start requirement the pawn still enters on the
      // coloured start tile because the board art includes it on the loop.
      expect(moved.position.fieldId, startIndex);
    });

    test('Captures disabled allows sharing the start square', () {
      final redPiece = Piece(
        PlayerColor.red,
        0,
        const PiecePosition(GameState.basePosition),
      );
      final redPlayer = Player(
        id: 'red',
        name: 'Red',
        color: PlayerColor.red,
        pieces: [
          redPiece,
          ...List.generate(
              3,
              (i) => Piece(PlayerColor.red, i + 1,
                  const PiecePosition(GameState.basePosition)))
        ],
      );
      final startIndex = LudoGame.startFields[PlayerColor.red]!;
      final greenPiece = Piece(
        PlayerColor.green,
        0,
        PiecePosition(startIndex, isHome: false),
      );
      final greenPlayer = Player(
        id: 'green',
        name: 'Green',
        color: PlayerColor.green,
        pieces: [
          greenPiece,
          ...List.generate(
              3,
              (i) => Piece(PlayerColor.green, i + 1,
                  const PiecePosition(GameState.basePosition)))
        ],
      );
      final rules = GameRules.standard.copyWith(captureReturnsToHome: false);
      final state = _state(
        lastDice: 6,
        players: [redPlayer, greenPlayer],
        rules: rules,
      );

      final validation = LudoGame.validateMove(state, redPiece, 6);
      expect(validation.isValid, isTrue);
      expect(validation.error, isNull);

      final result = LudoGame.movePiece(state, redPiece);
      final redMoved = result.newState.players
          .firstWhere((p) => p.color == PlayerColor.red)
          .pieces
          .first;
      final greenStayed = result.newState.players
          .firstWhere((p) => p.color == PlayerColor.green)
          .pieces
          .first;
      expect(redMoved.position.fieldId, startIndex);
      expect(greenStayed.position.fieldId, startIndex);
      expect(result.capturedOpponentPiece, isNull);
    });

    test('Custom piecesToWin triggers victory when threshold met', () {
      final rules = GameRules.standard.copyWith(piecesToWin: 2);
      final redPieces = [
        Piece(
          PlayerColor.red,
          0,
          const PiecePosition(GameConstants.homePathLength),
          isSafe: true,
        ),
        Piece(
          PlayerColor.red,
          1,
          const PiecePosition(GameConstants.homePathLength - 1),
        ),
        Piece(PlayerColor.red, 2, const PiecePosition(GameState.basePosition)),
        Piece(PlayerColor.red, 3, const PiecePosition(GameState.basePosition)),
      ];
      final redPlayer = Player(
        id: 'red',
        name: 'Red',
        color: PlayerColor.red,
        pieces: redPieces,
      );
      final greenPlayer = Player(
        id: 'green',
        name: 'Green',
        color: PlayerColor.green,
        pieces: List.generate(
            4,
            (i) => Piece(PlayerColor.green, i,
                const PiecePosition(GameState.basePosition))),
      );

      final state = _state(
        lastDice: 1,
        players: [redPlayer, greenPlayer],
        rules: rules,
      );

      final result = LudoGame.movePiece(state, redPieces[1]);
      expect(result.newState.winnerId, PlayerColor.red);
      expect(result.isFinishMove, isTrue);
    });
  });
}
