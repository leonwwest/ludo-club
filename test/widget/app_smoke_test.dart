import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/main.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('renders the rebuilt game screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameController(diceRoller: () => 6),
        child: const LudoClubApp(),
      ),
    );

    expect(find.text('Ludo Club'), findsOneWidget);
    expect(find.text('Neu starten'), findsOneWidget);
    expect(find.text('Zurück'), findsOneWidget);
    expect(find.text('Schlankes lokales Brettspiel'), findsOneWidget);
    expect(find.text('Spieler-Setup'), findsOneWidget);
    expect(find.text('Regeln'), findsOneWidget);
    expect(find.text('Zugprotokoll'), findsOneWidget);
    expect(find.text('3 Startwürfe'), findsOneWidget);
    expect(find.text('Dritte 6 beendet den Zug'), findsOneWidget);
    expect(find.text('Schlagzwang'), findsOneWidget);
  });
}
