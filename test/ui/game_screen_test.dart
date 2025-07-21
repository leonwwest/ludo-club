import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/ui/game_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('GameScreen UI Tests', () {
    testWidgets('renders GameScreen with initial elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => GameProvider(),
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.textContaining("Red's Turn"), findsOneWidget);
    });

    testWidgets('tapping dice area calls GameProvider.rollDice()', (WidgetTester tester) async {
      final gameProvider = GameProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameProvider,
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );

      final initialRollCount = gameProvider.gameState.currentRollCount;
      await tester.tap(find.byTooltip('Roll Dice'));
      await tester.pumpAndSettle();

      expect(gameProvider.gameState.currentRollCount, initialRollCount + 1);
    });

    testWidgets('dice value is displayed after roll', (WidgetTester tester) async {
      final gameProvider = GameProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameProvider,
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Roll Dice'));
      await tester.pumpAndSettle();

      expect(find.text(gameProvider.gameState.lastDiceValue.toString()), findsOneWidget);
    });

    testWidgets('current player is highlighted or indicated', (WidgetTester tester) async {
      final gameProvider = GameProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameProvider,
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );

      expect(find.textContaining("Red's Turn"), findsOneWidget);

      gameProvider.movePiece(gameProvider.getMovablePieces().first);
      await tester.pumpAndSettle();

      expect(find.textContaining("Green's Turn"), findsOneWidget);
    });

    testWidgets('Game Over dialog or display appears when game ends', (WidgetTester tester) async {
      final gameProvider = GameProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameProvider,
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );

      gameProvider.gameState.winnerId = PlayerColor.red;
      await tester.pumpAndSettle();

      expect(find.textContaining('wins!'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);
    });

    testWidgets('Play Again button on Game Over dialog starts a new game', (WidgetTester tester) async {
      final gameProvider = GameProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameProvider,
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );

      gameProvider.gameState.winnerId = PlayerColor.red;
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play Again'));
      await tester.pumpAndSettle();

      expect(gameProvider.gameState.winnerId, isNull);
    });

    testWidgets('Restart game button resets the game', (WidgetTester tester) async {
      final gameProvider = GameProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: gameProvider,
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );

      await gameProvider.rollDice();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Restart Game'));
      await tester.pumpAndSettle();

      expect(gameProvider.gameState.lastDiceValue, 0);
    });
  });
}