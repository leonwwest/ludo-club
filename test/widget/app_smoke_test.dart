import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/main.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:ludo_club/services/game_storage.dart';
import 'package:ludo_club/ui/widgets/mobile_action_dock.dart';
import 'package:ludo_club/ui/widgets/move_log_card.dart';
import 'package:ludo_club/ui/widgets/rule_options_card.dart';
import 'package:ludo_club/ui/widgets/setup_card.dart';
import 'package:ludo_club/widgets/ludo_board.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrappedApp(GameController controller) {
  return ChangeNotifierProvider.value(
    value: controller,
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('de'),
      home: LudoClubApp(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the rebuilt game screen', (tester) async {
    final controller = GameController(
      diceRoller: () => 6,
      storage: GameStorage(debounceDelay: Duration.zero),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrappedApp(controller));

    expect(find.text('Ludo Club'), findsOneWidget);
    expect(find.text('Neu starten'), findsOneWidget);
    expect(find.text('Zurück'), findsOneWidget);
    expect(find.text('Schlankes lokales Brettspiel'), findsOneWidget);
    expect(find.text('Partie einrichten'), findsOneWidget);
    expect(find.text('Partie starten'), findsOneWidget);
  });

  testWidgets('mobile layout keeps setup rules and log out of the main flow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = GameController(
      diceRoller: () => 6,
      initialPlayerCount: 2,
      storage: GameStorage(debounceDelay: Duration.zero),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrappedApp(controller));
    await tester.tap(find.text('Partie starten'));
    await tester.pumpAndSettle();

    expect(find.byType(LudoBoard), findsOneWidget);
    expect(find.byType(MobileActionDock), findsOneWidget);
    expect(find.byType(SetupCard), findsNothing);
    expect(find.byType(RuleOptionsCard), findsNothing);
    expect(find.byType(MoveLogCard), findsNothing);

    await tester.tap(find.byTooltip('Spieler-Setup'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupCard), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Regeln'));
    await tester.pumpAndSettle();
    expect(find.byType(RuleOptionsCard), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Zugprotokoll'));
    await tester.pumpAndSettle();
    expect(find.byType(MoveLogCard), findsOneWidget);
  });
}
