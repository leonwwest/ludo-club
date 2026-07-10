import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/online/online_room_client.dart';
import 'package:ludo_club/online/online_room_server.dart';
import 'package:ludo_club/online/room_protocol.dart';

void main() {
  late OnlineRoomServer server;
  late OnlineRoomClient host;
  late OnlineRoomClient guest;

  setUp(() async {
    server = OnlineRoomServer(port: 0, random: Random(91));
    await server.start();
    final uri = Uri.parse('ws://127.0.0.1:${server.boundPort}/ws');
    host = OnlineRoomClient(serverUri: uri, autoReconnect: false);
    guest = OnlineRoomClient(serverUri: uri, autoReconnect: false);
  });

  tearDown(() async {
    await host.disconnect(preserveRoom: false);
    await guest.disconnect(preserveRoom: false);
    host.dispose();
    guest.dispose();
    await server.close();
  });

  test('creates, joins and receives authoritative state updates', () async {
    await host.createRoom(playerName: 'Mira');
    await _waitFor(
      host,
      () => host.status == OnlineRoomStatus.waitingForPlayers,
    );
    final code = host.roomCode;
    expect(code, hasLength(RoomProtocol.roomCodeLength));

    await guest.joinRoom(roomCode: code!, playerName: 'Noah');
    await _waitFor(host, () => host.status == OnlineRoomStatus.ready);
    await _waitFor(guest, () => guest.status == OnlineRoomStatus.ready);

    expect(host.localColor?.name, 'red');
    expect(guest.localColor?.name, 'yellow');
    expect(host.canAct, isTrue);
    expect(guest.canAct, isFalse);

    final before = host.state!.toJson();
    host.rollDice();
    await _waitFor(
      host,
      () => host.state?.toJson().toString() != before.toString(),
    );
    await _waitFor(
      guest,
      () => guest.state?.toJson().toString() == host.state?.toJson().toString(),
    );

    expect(host.state?.toJson(), guest.state?.toJson());
  });

  test(
    'canAct is false while reconnecting and recovers with the same session',
    () async {
      await host.disconnect(preserveRoom: false);
      host.dispose();
      host = OnlineRoomClient(
        serverUri: Uri.parse('ws://127.0.0.1:${server.boundPort}/ws'),
      );

      await host.createRoom(playerName: 'Mira');
      await _waitFor(
        host,
        () => host.status == OnlineRoomStatus.waitingForPlayers,
      );
      final roomCode = host.roomCode!;
      await guest.joinRoom(roomCode: roomCode, playerName: 'Noah');
      await _waitFor(host, () => host.status == OnlineRoomStatus.ready);
      await _waitFor(guest, () => guest.status == OnlineRoomStatus.ready);
      expect(host.canAct, isTrue);

      final sessionToken = host.snapshot!.sessionToken;
      final observed = <(OnlineRoomStatus, bool)>[];
      void recordState() => observed.add((host.status, host.canAct));
      host.addListener(recordState);
      addTearDown(() => host.removeListener(recordState));

      // A second connection taking over the same reservation forces the
      // client's original socket to close and exercises automatic reconnect.
      final replacement = await WebSocket.connect(
        'ws://127.0.0.1:${server.boundPort}/ws',
      );
      addTearDown(replacement.close);
      final replacementState = Completer<Map<String, Object?>>();
      replacement.listen((payload) {
        final message = RoomProtocol.decode(payload);
        if (message != null && !replacementState.isCompleted) {
          replacementState.complete(message);
        }
      });
      replacement.add(
        RoomProtocol.encode(RoomMessageType.joinRoom, {
          'name': 'Mira',
          'roomCode': roomCode,
          'sessionToken': sessionToken,
        }),
      );
      expect(
        (await replacementState.future
            .timeout(const Duration(seconds: 3)))['sessionToken'],
        sessionToken,
      );

      await _waitFor(
        host,
        () => host.status == OnlineRoomStatus.reconnecting,
      );
      expect(host.canAct, isFalse);

      await _waitFor(
        host,
        () => host.status == OnlineRoomStatus.ready && host.canAct,
      );
      expect(host.snapshot?.sessionToken, sessionToken);
      expect(
        observed,
        contains(
          const (OnlineRoomStatus.reconnecting, false),
        ),
      );

      await host.disconnect();
      expect(host.status, OnlineRoomStatus.disconnected);
      expect(host.canAct, isFalse);

      await host.joinRoom(
        roomCode: roomCode,
        playerName: 'Mira',
        sessionToken: sessionToken,
      );
      expect(host.canAct, isFalse);
      await _waitFor(
        host,
        () => host.status == OnlineRoomStatus.ready && host.canAct,
      );
    },
  );

  test('coalesces repeated roll and move intents until state arrives',
      () async {
    await host.disconnect(preserveRoom: false);
    await guest.disconnect(preserveRoom: false);
    host.dispose();
    guest.dispose();
    await server.close();
    server = OnlineRoomServer(port: 0, random: _AlwaysSixRandom());
    await server.start();
    final uri = Uri.parse('ws://127.0.0.1:${server.boundPort}/ws');
    host = OnlineRoomClient(serverUri: uri, autoReconnect: false);
    guest = OnlineRoomClient(serverUri: uri, autoReconnect: false);

    await host.createRoom(playerName: 'Mira');
    await _waitFor(
      host,
      () => host.status == OnlineRoomStatus.waitingForPlayers,
    );
    await guest.joinRoom(roomCode: host.roomCode!, playerName: 'Noah');
    await _waitFor(host, () => host.status == OnlineRoomStatus.ready);
    await _waitFor(guest, () => guest.status == OnlineRoomStatus.ready);

    host
      ..rollDice()
      ..rollDice();
    expect(host.canAct, isFalse);
    await _waitFor(
      host,
      () => host.state?.phase == TurnPhase.waitingForMove,
    );
    expect(host.errorMessage, isNull);

    host
      ..movePiece(0)
      ..movePiece(0);
    expect(host.canAct, isFalse);
    await _waitFor(
      host,
      () => host.state?.players.first.pieces.first.steps == 0,
    );
    expect(host.status, OnlineRoomStatus.ready);
    expect(host.errorMessage, isNull);
  });
}

Future<void> _waitFor(
  OnlineRoomClient client,
  bool Function() predicate,
) {
  if (predicate()) {
    return Future.value();
  }
  final completer = Completer<void>();
  late VoidCallback listener;
  Timer? timeout;
  listener = () {
    if (!predicate() || completer.isCompleted) {
      return;
    }
    timeout?.cancel();
    client.removeListener(listener);
    completer.complete();
  };
  client.addListener(listener);
  timeout = Timer(const Duration(seconds: 3), () {
    client.removeListener(listener);
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
  bool nextBool() => true;

  @override
  double nextDouble() => 0.999999;

  @override
  int nextInt(int max) => max - 1;
}
