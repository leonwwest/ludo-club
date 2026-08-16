import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/main.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:ludo_club/services/app_settings.dart';
import 'package:ludo_club/services/game_storage.dart';
import 'package:ludo_club/ui/widgets/mobile_action_dock.dart';
import 'package:ludo_club/ui/widgets/move_log_card.dart';
import 'package:ludo_club/ui/widgets/rule_options_card.dart';
import 'package:ludo_club/ui/widgets/setup_card.dart';
import 'package:ludo_club/widgets/ludo_board.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrappedApp(
  GameController controller,
  AppSettingsController settings,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: controller),
      ChangeNotifierProvider.value(value: settings),
    ],
    child: const LudoClubApp(),
  );
}

void main() {
  late AppSettingsController settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await AppSettingsController.load();
    await settings.setLocaleMode(AppLocaleMode.german);
    await settings.completeTutorial();
  });

  testWidgets('renders the rebuilt game screen', (tester) async {
    final controller = GameController(
      diceRoller: () => 6,
      storage: GameStorage(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrappedApp(controller, settings));
    await tester.pumpAndSettle();

    expect(find.text('Ludo Club'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.undo), findsOneWidget);
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
      storage: GameStorage(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrappedApp(controller, settings));
    await tester.pumpAndSettle();
    final startButton = find.text('Partie starten');
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.byType(LudoBoard), findsOneWidget);
    final boardSize = tester.getSize(find.byType(LudoBoard));
    expect(boardSize.width, greaterThan(300));
    expect(boardSize.height, boardSize.width);
    expect(find.byType(MobileActionDock), findsOneWidget);
    expect(find.byType(SetupCard), findsNothing);
    expect(find.byType(RuleOptionsCard), findsNothing);
    expect(find.byType(MoveLogCard), findsNothing);

    await tester.tap(find.text('Spieler'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupCard), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Regeln'));
    await tester.pumpAndSettle();
    expect(find.byType(RuleOptionsCard), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zugprotokoll'));
    await tester.pumpAndSettle();
    expect(find.byType(MoveLogCard), findsOneWidget);
  });
}
