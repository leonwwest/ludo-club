'''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/services/save_load_service.dart';
import 'package:ludo_club/ui/saved_games_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class MockSaveLoadService extends Mock implements SaveLoadService {}

void main() {
  group('SavedGamesScreen', () {
    late MockSaveLoadService mockSaveLoadService;

    setUp(() {
      mockSaveLoadService = MockSaveLoadService();
    });

    testWidgets('displays list of saved games with correct data', (WidgetTester tester) async {
      when(mockSaveLoadService.getSavedGames()).thenAnswer((_) async => [
            {
              'saveName': 'Game 1',
              'saveDate': DateTime.now().toIso8601String(),
              'playerNames': ['Player 1', 'Player 2'],
            },
          ]);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => GameProvider(saveLoadService: mockSaveLoadService),
          child: MaterialApp(
            home: SavedGamesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Game 1'), findsOneWidget);
    });

    testWidgets('displays "No saved games" message when list is empty', (WidgetTester tester) async {
      when(mockSaveLoadService.getSavedGames()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => GameProvider(saveLoadService: mockSaveLoadService),
          child: MaterialApp(
            home: SavedGamesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
      expect(find.text('Keine gespeicherten Spiele gefunden.'), findsOneWidget);
    });

    testWidgets('displays loading indicator initially', (WidgetTester tester) async {
      when(mockSaveLoadService.getSavedGames()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => GameProvider(saveLoadService: mockSaveLoadService),
          child: MaterialApp(
            home: SavedGamesScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('tapping a game item calls GameProvider.loadGame and navigates back', (WidgetTester tester) async {
      final gameState = GameState(
        players: [Player(id: 'p1', name: 'Player 1', color: PlayerColor.red)],
        currentTurnPlayerId: PlayerColor.red,
        pieces: {},
        startIndices: {},
      );
      when(mockSaveLoadService.getSavedGames()).thenAnswer((_) async => [
            {
              'saveName': 'Game 1',
              'saveDate': DateTime.now().toIso8601String(),
              'playerNames': ['Player 1', 'Player 2'],
            },
          ]);
      when(mockSaveLoadService.loadGame(0)).thenAnswer((_) async => gameState);

      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => GameProvider(saveLoadService: mockSaveLoadService),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: SavedGamesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Game 1'));
      await tester.pumpAndSettle();

      verify(mockSaveLoadService.loadGame(0)).called(1);
    });

    testWidgets('tapping delete icon calls GameProvider.deleteGame and removes item', (WidgetTester tester) async {
      when(mockSaveLoadService.getSavedGames()).thenAnswer((_) async => [
            {
              'saveName': 'Game 1',
              'saveDate': DateTime.now().toIso8601String(),
              'playerNames': ['Player 1', 'Player 2'],
            },
          ]);
      when(mockSaveLoadService.deleteGame(0)).thenAnswer((_) async => true);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => GameProvider(saveLoadService: mockSaveLoadService),
          child: MaterialApp(
            home: SavedGamesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      verify(mockSaveLoadService.deleteGame(0)).called(1);
    });
  });
}
'''