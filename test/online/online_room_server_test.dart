import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/online/online_room_server.dart';
import 'package:ludo_club/online/room_protocol.dart';

void main() {
  late OnlineRoomServer server;
  final sockets = <WebSocket>[];

  setUp(() async {
    server = OnlineRoomServer(port: 0, random: Random(42));
    await server.start();
  });

  tearDown(() async {
    for (final socket in sockets) {
      await socket.close();
    }
    sockets.clear();
    await server.close();
  });

  Future<(_SocketInbox, WebSocket)> connect() async {
    final socket = await WebSocket.connect(
      'ws://127.0.0.1:${server.boundPort}/ws',
    );
    sockets.add(socket);
    return (_SocketInbox(socket), socket);
  }

  Future<void> restartServer({
    Random? random,
    Duration? reservationTtl,
    Duration? cleanupInterval,
    Duration? heartbeatInterval,
  }) async {
    await server.close();
    server = OnlineRoomServer(
      port: 0,
      random: random ?? Random(42),
      reservationTtl: reservationTtl,
      cleanupInterval: cleanupInterval,
      heartbeatInterval: heartbeatInterval ?? const Duration(seconds: 25),
    );
    await server.start();
  }

  test('closes a silent connection after its heartbeat is unanswered',
      () async {
    await restartServer(
      heartbeatInterval: const Duration(milliseconds: 40),
    );
    final socket = await Socket.connect('127.0.0.1', server.boundPort);
    final closed = Completer<void>();
    final responseBytes = <int>[];
    final subscription = socket.listen(
      responseBytes.addAll,
      onDone: closed.complete,
      onError: closed.completeError,
      cancelOnError: true,
    );
    addTearDown(() async {
      await subscription.cancel();
      socket.destroy();
    });

    socket.write(
      'GET /ws HTTP/1.1\r\n'
      'Host: 127.0.0.1:${server.boundPort}\r\n'
      'Upgrade: websocket\r\n'
      'Connection: Upgrade\r\n'
      'Sec-WebSocket-Key: dGhlIHNhbXBsZSBu' 'b25jZQ==\r\n'
      'Sec-WebSocket-Version: 13\r\n'
      '\r\n',
    );
    await socket.flush();

    await closed.future.timeout(const Duration(seconds: 3));
    expect(
      String.fromCharCodes(responseBytes),
      contains('101 Switching Protocols'),
    );
  });

  test(
    'creates a private room, joins it and plays an authoritative roll',
    () async {
      final (hostInbox, host) = await connect();
      host.add(
        RoomProtocol.encode(RoomMessageType.createRoom, {
          'name': 'Mira',
          'playerCount': 2,
        }),
      );
      final created = await hostInbox.nextMessage();
      expect(created['type'], RoomMessageType.roomState);
      expect(created['started'], isFalse);
      expect(created['localColor'], 'red');
      final code = created['roomCode']! as String;

      final (guestInbox, guest) = await connect();
      guest.add(
        RoomProtocol.encode(RoomMessageType.joinRoom, {
          'name': 'Noah',
          'roomCode': code,
        }),
      );
      final guestReady = await guestInbox.nextMessage();
      final hostReady = await hostInbox.nextMessage();
      expect(guestReady['started'], isTrue);
      expect(hostReady['started'], isTrue);
      expect(guestReady['localColor'], 'yellow');
      expect(guestReady['connectedPlayers'], 2);

      final beforeState = hostReady['state'];
      host.add(RoomProtocol.encode(RoomMessageType.rollDice));
      final afterRoll = await hostInbox.nextMessage();
      await guestInbox.nextMessage();
      expect(afterRoll['type'], RoomMessageType.roomState);
      expect(afterRoll['state'], isNot(equals(beforeState)));
    },
  );

  test('rejects joins for unknown rooms', () async {
    final (inbox, socket) = await connect();
    socket.add(
      RoomProtocol.encode(RoomMessageType.joinRoom, {
        'name': 'Mira',
        'roomCode': 'ABC234',
      }),
    );

    final message = await inbox.nextMessage();

    expect(message['type'], RoomMessageType.error);
    expect(message['message'], 'Raum nicht gefunden.');
  });

  test('removes a room when its final player leaves explicitly', () async {
    final (hostInbox, host) = await connect();
    host.add(
      RoomProtocol.encode(RoomMessageType.createRoom, {
        'name': 'Mira',
        'playerCount': 2,
      }),
    );
    await hostInbox.nextMessage();
    expect(server.roomCount, 1);

    host.add(RoomProtocol.encode(RoomMessageType.leaveRoom));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(server.roomCount, 0);
  });

  test('reconnects the same session without a stale-socket race', () async {
    final (originalInbox, originalHost) = await connect();
    originalHost.add(
      RoomProtocol.encode(RoomMessageType.createRoom, {
        'name': 'Mira',
        'playerCount': 2,
      }),
    );
    final created = await originalInbox.nextMessage();
    final roomCode = created['roomCode']! as String;
    final sessionToken = created['sessionToken']! as String;

    final (replacementInbox, replacementHost) = await connect();
    replacementHost.add(
      RoomProtocol.encode(RoomMessageType.joinRoom, {
        'name': 'Mira',
        'roomCode': roomCode,
        'sessionToken': sessionToken,
      }),
    );
    final reconnected = await replacementInbox.nextMessage();
    expect(reconnected['sessionToken'], sessionToken);
    expect(reconnected['localColor'], 'red');

    // Let the old socket's onDone callback run after the reservation already
    // points at the replacement. It must not clear the replacement socket.
    await originalHost.close();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final (guestInbox, guest) = await connect();
    guest.add(
      RoomProtocol.encode(RoomMessageType.joinRoom, {
        'name': 'Noah',
        'roomCode': roomCode,
      }),
    );

    final hostReady = await replacementInbox.nextWhere(
      (message) => message['started'] == true,
    );
    final guestReady = await guestInbox.nextWhere(
      (message) => message['started'] == true,
    );
    expect(hostReady['connectedPlayers'], 2);
    expect(guestReady['connectedPlayers'], 2);

    replacementHost.add(RoomProtocol.encode(RoomMessageType.rollDice));
    final afterRoll = await replacementInbox.nextWhere(
      (message) => message['type'] == RoomMessageType.roomState,
    );
    expect(afterRoll['state'], isNot(equals(hostReady['state'])));
  });

  test('transfers host after a disconnected reservation expires', () async {
    await restartServer(
      reservationTtl: const Duration(milliseconds: 40),
      cleanupInterval: const Duration(milliseconds: 10),
    );

    final (hostInbox, host) = await connect();
    host.add(
      RoomProtocol.encode(RoomMessageType.createRoom, {
        'name': 'Mira',
        'playerCount': 2,
      }),
    );
    final created = await hostInbox.nextMessage();
    final roomCode = created['roomCode']! as String;

    final (guestInbox, guest) = await connect();
    guest.add(
      RoomProtocol.encode(RoomMessageType.joinRoom, {
        'name': 'Noah',
        'roomCode': roomCode,
      }),
    );
    await hostInbox.nextWhere((message) => message['started'] == true);
    await guestInbox.nextWhere((message) => message['started'] == true);

    await host.close();

    final transferred = await guestInbox.nextWhere(
      (message) => message['isHost'] == true,
    );
    expect(transferred['started'], isFalse);
    expect(transferred['connectedPlayers'], 1);

    guest.add(RoomProtocol.encode(RoomMessageType.restartGame));
    final restarted = await guestInbox.nextWhere(
      (message) => message['type'] == RoomMessageType.roomState,
    );
    expect(restarted['isHost'], isTrue);
  });

  test('rejects malformed typed counts and piece ids without crashing',
      () async {
    await restartServer(random: _AlwaysSixRandom());

    final (hostInbox, host) = await connect();
    host.add(
      RoomProtocol.encode(RoomMessageType.createRoom, {
        'name': 'Mira',
        'playerCount': {'unexpected': 4},
      }),
    );
    final created = await hostInbox.nextMessage();
    expect(created['requiredPlayers'], 2);
    final roomCode = created['roomCode']! as String;

    final (guestInbox, guest) = await connect();
    guest.add(
      RoomProtocol.encode(RoomMessageType.joinRoom, {
        'name': 'Noah',
        'roomCode': roomCode,
      }),
    );
    await hostInbox.nextWhere((message) => message['started'] == true);
    await guestInbox.nextWhere((message) => message['started'] == true);

    host.add(RoomProtocol.encode(RoomMessageType.rollDice));
    final afterRoll = await hostInbox.nextWhere(
      (message) => message['type'] == RoomMessageType.roomState,
    );
    await guestInbox.nextWhere(
      (message) => message['type'] == RoomMessageType.roomState,
    );
    expect(
      (afterRoll['state']! as Map<String, Object?>)['phase'],
      'waitingForMove',
    );

    for (final malformedId in <Object?>[
      '0',
      0.0,
      {'id': 0},
      [0],
    ]) {
      host.add(
        RoomProtocol.encode(RoomMessageType.movePiece, {
          'pieceId': malformedId,
        }),
      );
      final error = await hostInbox.nextMessage();
      expect(error['type'], RoomMessageType.error);
      expect(error['message'], 'Figur fehlt.');
    }

    host.add(
      RoomProtocol.encode(RoomMessageType.movePiece, {'pieceId': 0}),
    );
    final afterMove = await hostInbox.nextWhere(
      (message) => message['type'] == RoomMessageType.roomState,
    );
    expect(afterMove['state'], isNot(equals(afterRoll['state'])));
    expect(server.roomCount, 1);
  });
}

class _SocketInbox {
  _SocketInbox(WebSocket socket) {
    socket.listen((payload) {
      final message = RoomProtocol.decode(payload);
      if (message == null) {
        return;
      }
      if (_waiters.isNotEmpty) {
        _waiters.removeAt(0).complete(message);
      } else {
        _messages.add(message);
      }
    });
  }

  final List<Map<String, Object?>> _messages = [];
  final List<Completer<Map<String, Object?>>> _waiters = [];

  Future<Map<String, Object?>> nextMessage() {
    if (_messages.isNotEmpty) {
      return Future.value(_messages.removeAt(0));
    }
    final completer = Completer<Map<String, Object?>>();
    _waiters.add(completer);
    return completer.future.timeout(const Duration(seconds: 3));
  }

  Future<Map<String, Object?>> nextWhere(
    bool Function(Map<String, Object?> message) predicate,
  ) async {
    while (true) {
      final message = await nextMessage();
      if (predicate(message)) {
        return message;
      }
    }
  }
}

class _AlwaysSixRandom implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0.999999;

  @override
  int nextInt(int max) => max - 1;
}
