import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';
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
    LudoGameState? initialState,
  }) {
    final controller = GameController(
      diceRoller: diceRoller,
      initialPlayerCount: initialPlayerCount,
      initialState: initialState,
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
    for (var id = 0; id < 4; id++) {
      expect(find.byKey(ValueKey('target-red-$id')), findsOneWidget);
    }
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            widget.message?.contains('kommt ins Spiel') == true,
      ),
      findsNWidgets(8),
    );
  });

  testWidgets('tapping a target halo performs the matching move',
      (tester) async {
    final baseState = LudoGameState.newGame(playerCount: 2);
    final red = baseState.players.first;
    final controller = createController(
      initialState: baseState.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 3,
        players: [
          red.copyWith(
            pieces: [
              red.pieces[0].copyWith(steps: 0),
              red.pieces[1].copyWith(steps: 57),
              red.pieces[2].copyWith(steps: 57),
              red.pieces[3].copyWith(steps: 57),
            ],
          ),
          baseState.players.last,
        ],
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: wrapWithL10n(const LudoBoard()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('target-red-0')));
    await tester.pumpAndSettle();

    expect(controller.state.players.first.pieces.first.steps, 3);
    expect(controller.state.moveLog, isNotEmpty);
  });
}
