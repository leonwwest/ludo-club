'''import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/services/game_service.dart';

// Helper to create a GameState for tests
GameState _createGameStateForTest({
  required List<Player> players,
  required PlayerColor currentTurn,
  required Map<PlayerColor, List<Piece>> pieces,
  int? lastDiceValue,
}) {
  return GameState(
    players: players,
    currentTurnPlayerId: currentTurn,
    pieces: pieces,
    lastDiceValue: lastDiceValue,
    startIndices: {
      PlayerColor.red: 0,
      PlayerColor.green: 10,
      PlayerColor.blue: 20,
      PlayerColor.yellow: 30,
    },
  );
}

void main() {
  group('GameService Tests', () {
    late GameState gameState;
    late GameService gameService;

    final player1 = Player(id: 'p1', name: 'Player 1', color: PlayerColor.red);
    final player2 = Player(id: 'p2', name: 'Player 2', color: PlayerColor.green);

    group('rollDice() Tests', () {
      test('Dice rolls within 1-6 range', () {
        gameState = _createGameStateForTest(
          players: [player1],
          currentTurn: PlayerColor.red,
          pieces: {
            PlayerColor.red: List.generate(4, (i) => Piece(PlayerColor.red, i, PiecePosition(GameState.basePosition)))
          },
        );
        gameService = GameService(gameState);

        for (int i = 0; i < 50; i++) {
          int roll = gameService.rollDice();
          expect(roll, greaterThanOrEqualTo(1));
          expect(roll, lessThanOrEqualTo(6));
        }
      });

      test('Bonus roll on first or second six keeps turn', () {
        gameState = _createGameStateForTest(
          players: [player1, player2],
          currentTurn: PlayerColor.red,
          pieces: {
            PlayerColor.red: [Piece(PlayerColor.red, 0, PiecePosition(0)), ...List.generate(3, (i) => Piece(PlayerColor.red, i + 1, PiecePosition(GameState.basePosition)))],
            PlayerColor.green: List.generate(4, (i) => Piece(PlayerColor.green, i, PiecePosition(GameState.basePosition))),
          },
        );
        gameService = GameService(gameState);
        final originalPlayer = gameState.currentTurnPlayerId;

        // 1st six
        gameService.debugNextDiceValue = 6;
        gameService.rollDice();
        
        expect(gameState.lastDiceValue, 6);
        expect(gameState.currentTurnPlayerId, originalPlayer, reason: "Turn should not change on 1st six.");
        expect(gameState.currentRollCount, 1);

        // 2nd six
        gameService.debugNextDiceValue = 6;
        gameService.rollDice();
        
        expect(gameState.lastDiceValue, 6);
        expect(gameState.currentTurnPlayerId, originalPlayer, reason: "Turn should not change on 2nd six.");
        expect(gameState.currentRollCount, 2);
      });

      test('Three consecutive sixes end turn', () {
        gameState = _createGameStateForTest(
          players: [player1, player2],
          currentTurn: PlayerColor.red,
          pieces: {
            PlayerColor.red: List.generate(4, (i) => Piece(PlayerColor.red, i, PiecePosition(i))),
            PlayerColor.green: List.generate(4, (i) => Piece(PlayerColor.green, i, PiecePosition(GameState.basePosition))),
          },
        );
        gameService = GameService(gameState);
        final originalPlayer = gameState.currentTurnPlayerId;

        // 1st six
        gameService.debugNextDiceValue = 6;
        gameService.rollDice();
        
        // 2nd six
        gameService.debugNextDiceValue = 6;
        gameService.rollDice();

        // 3rd six
        gameService.debugNextDiceValue = 6;
        gameService.rollDice();
        
        expect(gameState.lastDiceValue, isNull);
        expect(gameState.currentTurnPlayerId, isNot(originalPlayer));
        expect(gameState.currentTurnPlayerId, PlayerColor.green);
        expect(gameState.currentRollCount, 0);
      });
    });

    group('Moving Pawn Out of Base Tests', () {
      test('Cannot move from base without a 6', () {
        gameState = _createGameStateForTest(
          players: [player1],
          currentTurn: PlayerColor.red,
          pieces: { PlayerColor.red: List.generate(4, (i) => Piece(PlayerColor.red, i, PiecePosition(GameState.basePosition))) },
          lastDiceValue: 5,
        );
        gameService = GameService(gameState);
        
        final moves = gameService.getPossibleMoveDetails();
        expect(moves, isEmpty);
      });

      test('Can move from base with a 6', () {
        gameState = _createGameStateForTest(
          players: [player1],
          currentTurn: PlayerColor.red,
          pieces: { PlayerColor.red: List.generate(4, (i) => Piece(PlayerColor.red, i, PiecePosition(GameState.basePosition))) },
          lastDiceValue: 6,
        );
        gameService = GameService(gameState);

        final moves = gameService.getPossibleMoveDetails();
        expect(moves, isNotEmpty);
        expect(moves.any((move) => move['targetPosition'] == gameState.startIndices[PlayerColor.red]!), isTrue);
      });

      test('Successfully moves pawn from base on a 6', () {
        gameState = _createGameStateForTest(
          players: [player1],
          currentTurn: PlayerColor.red,
          pieces: { PlayerColor.red: List.generate(4, (i) => Piece(PlayerColor.red, i, PiecePosition(GameState.basePosition))) },
          lastDiceValue: 6,
        );
        gameService = GameService(gameState);
        gameState.currentRollCount = 1;

        final moves = gameService.getPossibleMoveDetails();
        final moveOutOfBase = moves.firstWhere((m) => m['targetPosition'] == gameState.startIndices[PlayerColor.red]!);
        
        final tokenIndexToMove = moveOutOfBase['tokenIndex']!;
        final capturedId = gameService.moveToken(PlayerColor.red, tokenIndexToMove, gameState.startIndices[PlayerColor.red]!);
        
        expect(capturedId, isNull);
        expect(gameState.pieces[PlayerColor.red]![tokenIndexToMove].position.fieldId, gameState.startIndices[PlayerColor.red]!);
        expect(gameState.currentRollCount, 1); 
        expect(gameState.lastDiceValue, 6); 
      });
    });
    
    group('Basic Movement & Capture Tests', () {
      test('Pawn moves correctly on board', () {
        gameState = _createGameStateForTest(
          players: [player1],
          currentTurn: PlayerColor.red,
          pieces: { PlayerColor.red: [Piece(PlayerColor.red, 0, PiecePosition(5)), ...List.generate(3, (i) => Piece(PlayerColor.red, i + 1, PiecePosition(GameState.basePosition)))] },
          lastDiceValue: 3,
        );
        gameService = GameService(gameState);
        
        final capturedId = gameService.moveToken(PlayerColor.red, 0, 8); // 5 + 3 = 8
        
        expect(capturedId, isNull); 
        expect(gameState.pieces[PlayerColor.red]![0].position.fieldId, 8);
        expect(gameState.currentRollCount, 0);
        expect(gameState.lastDiceValue, isNull);
      });

      test('Pawn captures opponent token', () {
        gameState = _createGameStateForTest(
          players: [player1, player2],
          currentTurn: PlayerColor.red,
          pieces: {
            PlayerColor.red: [Piece(PlayerColor.red, 0, PiecePosition(5)), ...List.generate(3, (i) => Piece(PlayerColor.red, i + 1, PiecePosition(GameState.basePosition)))],
            PlayerColor.green: [Piece(PlayerColor.green, 0, PiecePosition(8)), ...List.generate(3, (i) => Piece(PlayerColor.green, i + 1, PiecePosition(GameState.basePosition)))],
          },
          lastDiceValue: 3, 
        );
        gameState.currentRollCount = 1; 
        gameService = GameService(gameState);

        final capturedId = gameService.moveToken(PlayerColor.red, 0, 8);
        
        expect(capturedId, isNotNull);
        expect(capturedId, 'p2');
        expect(gameState.pieces[PlayerColor.red]![0].position.fieldId, 8);
        expect(gameState.pieces[PlayerColor.green]![0].position.fieldId, GameState.basePosition);
        expect(gameState.currentRollCount, 0);
        expect(gameState.lastDiceValue, isNull);
      });

      test('Pawn cannot capture on a safe spot', () {
        final p2Start = gameState.startIndices[PlayerColor.green]!; // 10 (safe spot)
        gameState = _createGameStateForTest(
          players: [player1, player2],
          currentTurn: PlayerColor.red,
          pieces: {
            PlayerColor.red: [Piece(PlayerColor.red, 0, PiecePosition(p2Start - 3)), ...List.generate(3, (i) => Piece(PlayerColor.red, i + 1, PiecePosition(GameState.basePosition)))],
            PlayerColor.green: [Piece(PlayerColor.green, 0, PiecePosition(p2Start)), ...List.generate(3, (i) => Piece(PlayerColor.green, i + 1, PiecePosition(GameState.basePosition)))],
          },
          lastDiceValue: 3,
        );
        gameState.currentRollCount = 1; 
        gameService = GameService(gameState);

        expect(gameState.isSafeField(p2Start), isTrue);

        final capturedId = gameService.moveToken(PlayerColor.red, 0, p2Start);
        
        expect(capturedId, isNull); 
        expect(gameState.pieces[PlayerColor.red]![0].position.fieldId, p2Start);
        expect(gameState.pieces[PlayerColor.green]![0].position.fieldId, p2Start); // Still there
        expect(gameState.currentRollCount, 0);
        expect(gameState.lastDiceValue, isNull);
      });
    });

    group('Home Path Logic Tests', () {
      setUp(() {
        gameState = _createGameStateForTest(
          players: [player1],
          currentTurn: PlayerColor.red,
          pieces: { PlayerColor.red: List.generate(4, (i) => Piece(PlayerColor.red, i, PiecePosition(GameState.basePosition))) },
        );
        gameService = GameService(gameState);
      });

      test('getPossibleMoveDetails - Entering home path correctly', () {
        gameState.pieces[PlayerColor.red]![0].position = PiecePosition(38);
        gameState.lastDiceValue = 3;
        
        final moves = gameService.getPossibleMoveDetails();
        
        expect(moves, isNotEmpty);
        final specificMove = moves.firstWhere((m) => m['tokenIndex'] == 0);
        expect(specificMove['targetPosition'], GameState.totalFields + 1);
      });

      test('getPossibleMoveDetails - Moving within home path correctly', () {
        gameState.pieces[PlayerColor.red]![0].position = PiecePosition(GameState.totalFields + 0);
        gameState.lastDiceValue = 2;

        final moves = gameService.getPossibleMoveDetails();
        
        expect(moves, isNotEmpty);
        final specificMove = moves.firstWhere((m) => m['tokenIndex'] == 0);
        expect(specificMove['targetPosition'], GameState.totalFields + 2);
      });
      
      test('getPossibleMoveDetails - Exact roll to finish token', () {
        gameState.pieces[PlayerColor.red]![0].position = PiecePosition(GameState.totalFields + 2);
        gameState.lastDiceValue = 2;

        final moves = gameService.getPossibleMoveDetails();
        
        expect(moves, isNotEmpty);
        final specificMove = moves.firstWhere((m) => m['tokenIndex'] == 0);
        expect(specificMove['targetPosition'], GameState.finishedPosition);
      });

      test('getPossibleMoveDetails - Cannot overshoot finish', () {
        gameState.pieces[PlayerColor.red]![0].position = PiecePosition(GameState.totalFields + 2);
        gameState.lastDiceValue = 3;

        final moves = gameService.getPossibleMoveDetails();
        final specificTokenMoves = moves.where((m) => m['tokenIndex'] == 0).toList();
        expect(specificTokenMoves, isEmpty);
      });
    });
  });
}
'''