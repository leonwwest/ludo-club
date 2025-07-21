import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/ui/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('HomeScreen UI Tests', () {
    testWidgets('renders HomeScreen with essential elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => GameProvider(),
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('Ludo Club'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('Start New Game'), findsOneWidget);
      expect(find.text('Load Game'), findsOneWidget);
      expect(find.text('Number of Players:'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('Player count selection updates UI', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => GameProvider(),
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      expect(find.descendant(of: find.byType(DropdownButton<int>), matching: find.text('2')), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3').last);
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(DropdownButton<int>), matching: find.text('3')), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4').last);
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(DropdownButton<int>), matching: find.text('4')), findsOneWidget);
    });
  });
}