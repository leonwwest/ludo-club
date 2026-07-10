import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/ui/widgets/mobile_action_dock.dart';
import 'package:ludo_club/ui/widgets/online_room_sheet.dart';
import 'package:ludo_club/ui/widgets/status_card.dart';

Widget _localizedHost(Widget child, {Locale locale = const Locale('de')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('remote turn disables rolling and explains who is active', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var rollCalls = 0;
    final state = LudoGameState.newGame(playerCount: 2);

    await tester.pumpWidget(
      _localizedHost(
        MobileActionDock(
          state: state,
          onRoll: () => rollCalls += 1,
          isBotTurn: false,
          isRemoteTurn: true,
          isWaitingForPlayers: false,
          onOpenSetup: null,
          onOpenRules: () {},
          onOpenMoveLog: () {},
          onOpenStats: () {},
        ),
      ),
    );

    expect(find.text('Warte auf Sisiliya …'), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
    expect(find.text('Sisiliya würfelt'), findsNothing);
    expect(rollCalls, 0);
  });

  testWidgets('disconnected room shows the waiting-for-players state', (
    tester,
  ) async {
    final state = LudoGameState.newGame(playerCount: 2);
    await tester.pumpWidget(
      _localizedHost(
        MobileActionDock(
          state: state,
          onRoll: () {},
          isBotTurn: false,
          isRemoteTurn: true,
          isWaitingForPlayers: true,
          onOpenSetup: null,
          onOpenRules: () {},
          onOpenMoveLog: () {},
          onOpenStats: () {},
        ),
      ),
    );

    expect(find.text('Warte auf weitere Spieler …'), findsOneWidget);
  });

  testWidgets('online sheet reports an invalid server address', (tester) async {
    await tester.pumpWidget(
      _localizedHost(
        OnlineRoomSheet(
          initialState: LudoGameState.newGame(playerCount: 2),
          onAttached: (_) {},
          onOpenGame: () {},
          onLeave: () async {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'kein-server');
    final createButton = find.ancestor(
      of: find.text('Raum erstellen'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pump();

    expect(
      find.text(
        'Gib eine gültige WS-, WSS-, HTTP- oder HTTPS-Serveradresse ein.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('English status text does not expose German rule messages', (
    tester,
  ) async {
    final state = LudoRules.roll(
      LudoGameState.newGame(playerCount: 2),
      6,
    );
    await tester.pumpWidget(
      _localizedHost(
        StatusCard(state: state),
        locale: const Locale('en'),
      ),
    );

    expect(find.text('Sisiliya rolled 6.'), findsOneWidget);
    expect(find.textContaining('würfelt'), findsNothing);
  });
}
