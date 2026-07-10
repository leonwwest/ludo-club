import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/online/online_room_client.dart';
import 'package:ludo_club/online/online_room_server.dart';
import 'package:ludo_club/online/room_protocol.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OnlineRoomServer server;
  late Uri serverUri;
  late List<OnlineRoomClient> clients;
  late Set<OnlineRoomClient> controllerOwnedClients;
  late List<GameController> controllers;
  late Set<GameController> disposedControllers;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    server = OnlineRoomServer(port: 0, random: _AlwaysSixRandom());
    await server.start();
    serverUri = Uri.parse('ws://127.0.0.1:${server.boundPort}/ws');
    clients = [];
    controllerOwnedClients = {};
    controllers = [];
    disposedControllers = {};
  });

  tearDown(() async {
    for (final controller in controllers.reversed) {
      if (!disposedControllers.contains(controller)) {
        controller.dispose();
      }
    }
    for (final client in clients.reversed) {
      if (controllerOwnedClients.contains(client)) {
        continue;
      }
      await client.disconnect(preserveRoom: false);
      client.dispose();
    }
    await Future<void>.delayed(Duration.zero);
    await server.close();
  });

  OnlineRoomClient createClient() {
    final client = OnlineRoomClient(
      serverUri: serverUri,
      autoReconnect: false,
    );
    clients.add(client);
    return client;
  }

  GameController createController({
    DiceRoller? diceRoller,
    LudoGameState? initialState,
  }) {
    final controller = GameController(
      diceRoller: diceRoller,
      initialPlayerCount: 2,
      initialState: initialState,
      botAutomationEnabled: false,
    );
    controllers.add(controller);
    return controller;
  }

  Future<(OnlineRoomClient, OnlineRoomClient)> createReadyRoom() async {
    final host = createClient();
    final guest = createClient();
    await host.createRoom(playerName: 'Host');
    await _waitFor(
      host,
      () => host.status == OnlineRoomStatus.waitingForPlayers,
    );
    await guest.joinRoom(roomCode: host.roomCode!, playerName: 'Guest');
    await _waitFor(host, () => host.status == OnlineRoomStatus.ready);
    await _waitFor(guest, () => guest.status == OnlineRoomStatus.ready);
    return (host, guest);
  }

  test(
    'attaches room state, delegates rolls and blocks the remote player',
    () async {
      final (host, guest) = await createReadyRoom();
      var localDiceRolls = 0;
      final hostController = createController(
        diceRoller: () {
          localDiceRolls += 1;
          return 1;
        },
      );
      final guestController = createController();
      controllerOwnedClients.addAll([host, guest]);

      hostController.attachOnlineRoom(host);
      guestController.attachOnlineRoom(guest);

      expect(hostController.isOnlineMatch, isTrue);
      expect(hostController.onlineRoomCode, host.roomCode);
      expect(hostController.state.toJson(), host.state!.toJson());
      expect(hostController.canLocalPlayerAct, isTrue);
      expect(hostController.isRemoteTurn, isFalse);
      expect(hostController.canUndo, isFalse);
      expect(hostController.canEditRules, isFalse);

      expect(guestController.canLocalPlayerAct, isFalse);
      expect(guestController.isRemoteTurn, isTrue);
      expect(guestController.movablePieces, isEmpty);

      final stateBeforeBlockedActions = guestController.state.toJson();
      await guestController.rollDice();
      await guestController.movePiece(
        guestController.state.currentPlayer.pieces.first,
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(guestController.state.toJson(), stateBeforeBlockedActions);
      expect(guest.state?.stats.rolls, 0);

      await hostController.rollDice();
      await _waitFor(host, () => host.state?.stats.rolls == 1);
      await _waitFor(guest, () => guest.state?.stats.rolls == 1);

      expect(localDiceRolls, 0);
      expect(hostController.state.toJson(), host.state!.toJson());
      expect(guestController.state.toJson(), host.state!.toJson());
      expect(hostController.state.diceValue, 6);
      expect(hostController.state.phase, TurnPhase.waitingForMove);
      expect(hostController.movablePieces, hasLength(4));
      expect(guestController.movablePieces, isEmpty);
    },
  );

  test('leaving restores the offline state and its undo history', () async {
    final (host, _) = await createReadyRoom();
    final controller = createController(diceRoller: () => 6);

    await controller.rollDice();
    final offlineState = controller.state.toJson();
    expect(controller.canUndo, isTrue);
    expect(controller.state.phase, TurnPhase.waitingForMove);

    controllerOwnedClients.add(host);
    controller.attachOnlineRoom(host);
    expect(controller.isOnlineMatch, isTrue);
    expect(controller.canUndo, isFalse);
    expect(controller.state.stats.rolls, 0);

    await controller.leaveOnlineRoom();

    expect(controller.isOnlineMatch, isFalse);
    expect(controller.state.toJson(), offlineState);
    expect(controller.canUndo, isTrue);

    await controller.undoLastAction();
    expect(controller.state.phase, TurnPhase.waitingForRoll);
    expect(controller.state.diceValue, isNull);
    expect(controller.state.stats.rolls, 0);
    expect(controller.canUndo, isFalse);
  });

  test('disposing an attached controller is safe during room updates',
      () async {
    final host = createClient();
    final guest = createClient();
    await host.createRoom(playerName: 'Host');
    await _waitFor(
      host,
      () => host.status == OnlineRoomStatus.waitingForPlayers,
    );

    final controller = createController();
    controllerOwnedClients.add(host);
    controller.attachOnlineRoom(host);
    final stateBeforeDispose = controller.state.toJson();

    expect(controller.dispose, returnsNormally);
    disposedControllers.add(controller);

    await guest.joinRoom(roomCode: host.roomCode!, playerName: 'Guest');
    await _waitFor(
      guest,
      () => guest.status == OnlineRoomStatus.waitingForPlayers,
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(controller.state.toJson(), stateBeforeDispose);
    expect(host.rollDice, returnsNormally);
  });
}

Future<void> _waitFor(
  Listenable listenable,
  bool Function() predicate,
) {
  if (predicate()) {
    return Future<void>.value();
  }
  final completer = Completer<void>();
  late VoidCallback listener;
  Timer? timeout;
  listener = () {
    if (!predicate() || completer.isCompleted) {
      return;
    }
    timeout?.cancel();
    listenable.removeListener(listener);
    completer.complete();
  };
  listenable.addListener(listener);
  timeout = Timer(const Duration(seconds: 3), () {
    listenable.removeListener(listener);
    if (!completer.isCompleted) {
      completer.completeError(
        TimeoutException('Online room state did not arrive.'),
      );
    }
  });
  return completer.future;
}

class _AlwaysSixRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => max == 6 ? 5 : 0;
}
