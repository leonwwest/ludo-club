import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/services/game_service.dart';

// Helper to create a GameState for tests
GameState _createGameStateForTest({
  required List<Player> players,
  required PlayerColor currentTurn,
  int? lastDiceValue,
}) {
  return GameState(
    players: players,
    currentTurnPlayerId: currentTurn,
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

    final player1 = Player(id: 'p1', name: 'Player 1', color: PlayerColor.red, 
        pieces: List.generate(4, (i) => Piece(PlayerColor.red, i, const PiecePosition(GameState.basePosition))));
    final player2 = Player(id: 'p2', name: 'Player 2', color: PlayerColor.green,
        pieces: List.generate(4, (i) => Piece(PlayerColor.green, i, const PiecePosition(GameState.basePosition))));

    group('rollDice() Tests', () {
      test('Dice rolls within 1-6 range', () {
        gameState = _createGameStateForTest(
          players: [player1],
          currentTurn: PlayerColor.red,
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
          lastDiceValue: 3,
        );
        gameService = GameService(gameState);
        
        final capturedId = gameService.moveToken(PlayerColor.red, 0, 8); // 5 + 3 = 8
        
        expect(capturedId, isNull); 
        expect(gameState.players.firstWhere((p) => p.color == PlayerColor.red).pieces[0].position.fieldId, 8);
        expect(gameState.currentRollCount, 0);
        expect(gameState.lastDiceValue, isNull);
      });

      test('Pawn captures opponent token', () {
        gameState = _createGameStateForTest(
          players: [player1, player2],
          currentTurn: PlayerColor.red,
          lastDiceValue: 3, 
        );
        gameState.currentRollCount = 1; 
        gameService = GameService(gameState);

        final capturedId = gameService.moveToken(PlayerColor.red, 0, 8);
        
        expect(capturedId, isNotNull);
        expect(capturedId, 'p2');
        expect(gameState.players.firstWhere((p) => p.color == PlayerColor.red).pieces[0].position.fieldId, 8);
        expect(gameState.players.firstWhere((p) => p.color == PlayerColor.green).pieces[0].position.fieldId, GameState.basePosition);
        expect(gameState.currentRollCount, 0);
        expect(gameState.lastDiceValue, isNull);
      });

      test('Pawn cannot capture on a safe spot', () {
        final p2Start = gameState.startIndices[PlayerColor.green]!; // 10 (safe spot)
        gameState = _createGameStateForTest(
          players: [player1, player2],
          currentTurn: PlayerColor.red,
          lastDiceValue: 3,
        );
        gameState.currentRollCount = 1; 
        gameService = GameService(gameState);

        expect(gameState.isSafeField(p2Start), isTrue);

        final capturedId = gameService.moveToken(PlayerColor.red, 0, p2Start);
        
        expect(capturedId, isNull); 
        expect(gameState.players.firstWhere((p) => p.color == PlayerColor.red).pieces[0].position.fieldId, p2Start);
        expect(gameState.players.firstWhere((p) => p.color == PlayerColor.green).pieces[0].position.fieldId, p2Start); // Still there
        expect(gameState.currentRollCount, 0);
        expect(gameState.lastDiceValue, isNull);
      });
    });

    group('Home Path Logic Tests', () {
      setUp(() {
        gameState = _createGameStateForTest(
          players: [player1],
          currentTurn: PlayerColor.red,
        );
        gameService = GameService(gameState);
      });

      test('getPossibleMoveDetails - Entering home path correctly', () {
        gameState.players.firstWhere((p) => p.color == PlayerColor.red).pieces[0].position = const PiecePosition(38);
        gameState.lastDiceValue = 3;
        
        final moves = gameService.getPossibleMoveDetails();
        
        expect(moves, isNotEmpty);
        final specificMove = moves.firstWhere((m) => m['tokenIndex'] == 0);
        expect(specificMove['targetPosition'], GameState.totalFields + 1);
      });

      test('getPossibleMoveDetails - Moving within home path correctly', () {
        gameState.players.firstWhere((p) => p.color == PlayerColor.red).pieces[0].position = const PiecePosition(GameState.totalFields + 0);
        gameState.lastDiceValue = 2;

        final moves = gameService.getPossibleMoveDetails();
        
        expect(moves, isNotEmpty);
        final specificMove = moves.firstWhere((m) => m['tokenIndex'] == 0);
        expect(specificMove['targetPosition'], GameState.totalFields + 2);
      });
      
      test('getPossibleMoveDetails - Exact roll to finish token', () {
        gameState.players.firstWhere((p) => p.color == PlayerColor.red).pieces[0].position = const PiecePosition(GameState.totalFields + 2);
        gameState.lastDiceValue = 2;

        final moves = gameService.getPossibleMoveDetails();
        
        expect(moves, isNotEmpty);
        final specificMove = moves.firstWhere((m) => m['tokenIndex'] == 0);
        expect(specificMove['targetPosition'], GameState.finishedPosition);
      });

      test('getPossibleMoveDetails - Cannot overshoot finish', () {
        gameState.players.firstWhere((p) => p.color == PlayerColor.red).pieces[0].position = const PiecePosition(GameState.totalFields + 2);
        gameState.lastDiceValue = 3;

        final moves = gameService.getPossibleMoveDetails();
        
        final specificTokenMoves = moves.where((m) => m['tokenIndex'] == 0);
        expect(specificTokenMoves, isEmpty);
      });
    });
  });
}
