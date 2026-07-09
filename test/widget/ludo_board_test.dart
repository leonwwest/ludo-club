import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:ludo_club/services/game_storage.dart';
import 'package:ludo_club/widgets/ludo_board.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  GameController createController({
    DiceRoller? diceRoller,
    int initialPlayerCount = 4,
  }) {
    final controller = GameController(
      diceRoller: diceRoller,
      initialPlayerCount: initialPlayerCount,
      storage: GameStorage(debounceDelay: Duration.zero),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Widget wrapWithL10n(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: Scaffold(
        body: SizedBox.square(
          dimension: 420,
          child: child,
        ),
      ),
    );
  }

  testWidgets('renders every piece on the board', (tester) async {
    final controller = createController(diceRoller: () => 6);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: wrapWithL10n(const LudoBoard()),
      ),
    );

    expect(find.byType(LudoBoard), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image || widget.image is! AssetImage) {
          return false;
        }
        return (widget.image as AssetImage).assetName.startsWith(
              'assets/pins/',
            );
      }),
      findsNWidgets(16),
    );
  });

  testWidgets('shows target halos and move hints after a playable roll',
      (tester) async {
    final controller = createController(
      diceRoller: () => 6,
      initialPlayerCount: 2,
    );

    await controller.rollDice();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: wrapWithL10n(const LudoBoard()),
      ),
    );

    expect(controller.movablePieces, hasLength(4));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            widget.message?.contains('kommt ins Spiel') == true,
      ),
      findsNWidgets(4),
    );
  });
}
