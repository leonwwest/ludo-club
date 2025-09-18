import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/ui/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders and shows key UI', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Ludo Club'), findsOneWidget);
    expect(find.text('Game Settings'), findsOneWidget);
    expect(find.text('Quick Play vs AI'), findsOneWidget);
    expect(find.text('Custom Game'), findsOneWidget);
  });
}
