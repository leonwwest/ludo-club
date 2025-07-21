import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';

void main() {
  group('GameState', () {
    // Test data
    final startIndices = <PlayerColor, int>{
      PlayerColor.red: 0,
      PlayerColor.green: 10,
      PlayerColor.blue: 20,
      PlayerColor.yellow: 30,
    };
    final players = [
      Player(id: 'player1', name: 'Player 1', color: PlayerColor.red),
      Player(id: 'player2', name: 'Player 2', isAI: true, color: PlayerColor.green),
      Player(id: 'player3', name: 'Player 3', color: PlayerColor.blue),
      Player(id: 'player4', name: 'Player 4', isAI: true, color: PlayerColor.yellow),
    ];

    final pieces = {
      PlayerColor.red: [
        Piece(PlayerColor.red, 0, PiecePosition(0)),
      ],
      PlayerColor.green: [
        Piece(PlayerColor.green, 0, PiecePosition(10)),
      ],
    };

    group('isSafeField', () {
      test('should return true for a player\'s start field', () {
        final gameState = GameState(
          startIndices: startIndices,
          players: players,
          currentTurnPlayerId: PlayerColor.red,
          pieces: pieces,
        );
        expect(gameState.isSafeField(0), isTrue);
        expect(gameState.isSafeField(10), isTrue);
        expect(gameState.isSafeField(20), isTrue);
        expect(gameState.isSafeField(30), isTrue);
      });

      test('should return false for a non-start field', () {
        final gameState = GameState(
          startIndices: startIndices,
          players: players,
          currentTurnPlayerId: PlayerColor.red,
          pieces: pieces,
        );
        expect(gameState.isSafeField(1), isFalse);
        expect(gameState.isSafeField(11), isFalse);
      });
    });

    group('copy', () {
      test('should copy all fields correctly', () {
        final testPlayers = [
          Player(id: 'player1', name: 'Player 1', color: PlayerColor.red),
          Player(id: 'player2', name: 'Player 2', isAI: true, color: PlayerColor.green),
        ];
        final originalState = GameState(
          startIndices: startIndices,
          players: testPlayers, 
          currentTurnPlayerId: PlayerColor.red,
          lastDiceValue: 6,
          winnerId: PlayerColor.green,
          pieces: pieces,
        );
        final copiedState = originalState.copy();

        expect(copiedState.startIndices, originalState.startIndices);
        expect(copiedState.players.length, originalState.players.length);
        for (int i = 0; i < originalState.players.length; i++) {
          expect(copiedState.players[i].id, originalState.players[i].id);
          expect(copiedState.players[i].name, originalState.players[i].name);
          expect(copiedState.players[i].isAI, originalState.players[i].isAI);
        }
        expect(copiedState.currentTurnPlayerId, originalState.currentTurnPlayerId);
        expect(copiedState.lastDiceValue, originalState.lastDiceValue);
        expect(copiedState.winnerId, originalState.winnerId);
      });

      test('modifications to copied state should not affect original state', () {
        final testPlayersForModification = [
          Player(id: 'player1', name: 'Player 1', color: PlayerColor.red),
          Player(id: 'player2', name: 'Player 2', isAI: true, color: PlayerColor.green),
        ];
        final originalState = GameState(
          startIndices: startIndices,
          players: testPlayersForModification,
          currentTurnPlayerId: PlayerColor.red,
          pieces: pieces,
        );
        final copiedState = originalState.copy();

        final player1Copied = copiedState.players.firstWhere((p) => p.id == 'player1');
        
        if (copiedState.players.length > 1) { 
          copiedState.players[0] = Player(id: 'newPlayer', name: 'New Player', color: PlayerColor.red); 
           expect(originalState.players[0].id, 'player1'); 
        }
       

        copiedState.currentTurnPlayerId = PlayerColor.green;
        expect(originalState.currentTurnPlayerId, PlayerColor.red);
        expect(copiedState.currentTurnPlayerId, PlayerColor.green);

        copiedState.lastDiceValue = 3;
        expect(originalState.lastDiceValue, isNull);
        expect(copiedState.lastDiceValue, 3);

        copiedState.winnerId = PlayerColor.red;
        expect(originalState.winnerId, isNull);
        expect(copiedState.winnerId, PlayerColor.red);
      });
    });

    group('getters', () {
      test('currentPlayer should return the correct player object', () {
        final gameState = GameState(
          startIndices: startIndices,
          players: players,
          currentTurnPlayerId: PlayerColor.green,
          pieces: pieces,
        );
        expect(gameState.currentPlayer.id, 'player2');
        expect(gameState.currentPlayer.name, 'Player 2');
      });

      test('isCurrentPlayerAI should return true for AI player', () {
        final gameState = GameState(
          startIndices: startIndices,
          players: players,
          currentTurnPlayerId: PlayerColor.green, 
          pieces: pieces,
        );
        expect(gameState.isCurrentPlayerAI, isTrue);
      });

      test('isCurrentPlayerAI should return false for human player', () {
        final gameState = GameState(
          startIndices: startIndices,
          players: players,
          currentTurnPlayerId: PlayerColor.red, 
          pieces: pieces,
        );
        expect(gameState.isCurrentPlayerAI, isFalse);
      });

      test('winner should return the correct player object when there is a winner', () {
        final gameState = GameState(
          startIndices: startIndices,
          players: players,
          currentTurnPlayerId: PlayerColor.red,
          winnerId: PlayerColor.yellow,
          pieces: pieces,
        );
        expect(gameState.winner?.id, 'player4');
        expect(gameState.winner?.name, 'Player 4');
      });

      test('winner should return null when there is no winner', () {
        final gameState = GameState(
          startIndices: startIndices,
          players: players,
          currentTurnPlayerId: PlayerColor.red,
          pieces: pieces,
        );
        expect(gameState.winner, isNull);
      });

      test('isGameOver should return true when there is a winner', () {
        final gameState = GameState(
          startIndices: startIndices,
          players: players,
          currentTurnPlayerId: PlayerColor.red,
          winnerId: PlayerColor.blue,
          pieces: pieces,
        );
        expect(gameState.isGameOver, isTrue);
      });

      test('isGameOver should return false when there is no winner', () {
        final gameState = GameState(
          startIndices: startIndices,
          players: players,
          currentTurnPlayerId: PlayerColor.red,
          pieces: pieces,
        );
        expect(gameState.isGameOver, isFalse);
      });
    });
  });
}
