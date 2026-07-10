import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/online/room_protocol.dart';

class OnlineRoomServer {
  OnlineRoomServer({
    InternetAddress? host,
    this.port = 8080,
    Random? random,
    Duration? reservationTtl,
    Duration? cleanupInterval,
    this.heartbeatInterval = const Duration(seconds: 25),
  })  : host = host ?? InternetAddress.loopbackIPv4,
        _random = random ?? Random.secure(),
        reservationTtl = reservationTtl ?? const Duration(minutes: 5),
        cleanupInterval = cleanupInterval ?? const Duration(minutes: 1);

  final InternetAddress host;
  final int port;
  final Duration reservationTtl;
  final Duration cleanupInterval;
  final Duration heartbeatInterval;
  final Random _random;
  final Map<String, _Room> _rooms = {};
  HttpServer? _server;
  Timer? _cleanupTimer;

  int get boundPort => _server?.port ?? port;
  int get roomCount => _rooms.length;

  Future<void> start() async {
    if (_server != null) {
      return;
    }
    _server = await HttpServer.bind(host, port);
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      _removeExpiredRooms();
    });
    unawaited(_serve(_server!));
  }

  Future<void> close() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    for (final room in _rooms.values) {
      await room.close();
    }
    _rooms.clear();
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _serve(HttpServer server) async {
    await for (final request in server) {
      if (request.uri.path == '/health') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'ok': true, 'rooms': _rooms.length}));
        await request.response.close();
        continue;
      }
      if (request.uri.path != '/ws' ||
          !WebSocketTransformer.isUpgradeRequest(request)) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Ludo Club room server');
        await request.response.close();
        continue;
      }
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        socket.pingInterval = heartbeatInterval;
        _attach(socket);
      } on Object {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
      }
    }
  }

  void _attach(WebSocket socket) {
    _Connection? connection;
    final identifyTimer = Timer(const Duration(seconds: 10), () {
      if (connection == null) {
        _sendError(socket, 'Zeitüberschreitung beim Raumbeitritt.');
        unawaited(
          _closeSocket(socket, statusCode: WebSocketStatus.policyViolation),
        );
      }
    });
    socket.listen(
      (payload) {
        final message = RoomProtocol.decode(payload);
        if (message == null) {
          _sendError(socket, 'Ungültige Nachricht.');
          return;
        }
        final type = message['type'];
        if (connection == null) {
          if (type == RoomMessageType.createRoom) {
            connection = _createRoom(socket, message);
          } else if (type == RoomMessageType.joinRoom) {
            connection = _joinRoom(socket, message);
          } else {
            _sendError(socket, 'Zuerst Raum erstellen oder beitreten.');
          }
          if (connection != null) {
            identifyTimer.cancel();
          }
          return;
        }
        _handleRoomCommand(connection!, message);
      },
      onDone: () {
        identifyTimer.cancel();
        _disconnect(connection);
      },
      onError: (_) {
        identifyTimer.cancel();
        _disconnect(connection);
      },
      cancelOnError: true,
    );
  }

  _Connection? _createRoom(
    WebSocket socket,
    Map<String, Object?> message,
  ) {
    final requestedCount = _safeInt(message['playerCount']) ?? 2;
    final playerCount = requestedCount.clamp(2, 4);
    final rulesJson = message['rules'];
    final rules = rulesJson is Map
        ? RuleOptions.fromJson(Map<String, Object?>.from(rulesJson))
        : const RuleOptions();
    final code = _newRoomCode();
    final room = _Room(
      code: code,
      state: LudoGameState.newGame(playerCount: playerCount, rules: rules),
      requiredPlayers: playerCount,
      hostToken: _newToken(),
    );
    _rooms[code] = room;
    final connection = _reserveAndConnect(
      room: room,
      socket: socket,
      token: room.hostToken,
      name: RoomProtocol.normalizePlayerName(message['name']),
    );
    room.broadcast();
    return connection;
  }

  _Connection? _joinRoom(
    WebSocket socket,
    Map<String, Object?> message,
  ) {
    final code = RoomProtocol.normalizeRoomCode(message['roomCode']);
    final room = _rooms[code];
    if (room == null) {
      _sendError(socket, 'Raum nicht gefunden.');
      return null;
    }
    final requestedToken = message['sessionToken']?.toString() ?? '';
    final existing = room.reservations[requestedToken];
    if (existing != null) {
      final previousSocket = existing.socket;
      existing
        ..socket = socket
        ..lastSeen = DateTime.now();
      if (previousSocket != null && !identical(previousSocket, socket)) {
        unawaited(_closeSocket(previousSocket));
      }
      final connection = _Connection(
        room: room,
        reservation: existing,
        socket: socket,
      );
      room.broadcast();
      return connection;
    }
    if (room.reservations.length >= room.requiredPlayers) {
      _sendError(socket, 'Raum ist bereits voll.');
      return null;
    }
    final connection = _reserveAndConnect(
      room: room,
      socket: socket,
      token: _newToken(),
      name: RoomProtocol.normalizePlayerName(message['name']),
    );
    room.broadcast();
    return connection;
  }

  _Connection _reserveAndConnect({
    required _Room room,
    required WebSocket socket,
    required String token,
    required String name,
  }) {
    final occupiedColors = room.reservations.values
        .map((reservation) => reservation.color)
        .toSet();
    final color = room.state.activeColors.firstWhere(
      (candidate) => !occupiedColors.contains(candidate),
    );
    final reservation = _Reservation(
      token: token,
      color: color,
      name: name,
      socket: socket,
    );
    room.reservations[token] = reservation;
    room.state = room.state.copyWith(
      players: [
        for (final player in room.state.players)
          if (player.color == color) player.copyWith(name: name) else player,
      ],
      turnMessage: room.state.currentPlayer.color == color
          ? '$name ist dran.'
          : room.state.turnMessage,
    );
    return _Connection(
      room: room,
      reservation: reservation,
      socket: socket,
    );
  }

  void _handleRoomCommand(
    _Connection connection,
    Map<String, Object?> message,
  ) {
    final room = connection.room;
    final reservation = connection.reservation;
    if (!identical(reservation.socket, connection.socket)) {
      return;
    }
    reservation.lastSeen = DateTime.now();
    switch (message['type']) {
      case RoomMessageType.rollDice:
        if (!_canAct(room, reservation) ||
            room.state.phase != TurnPhase.waitingForRoll) {
          _sendError(reservation.socket, 'Würfeln ist gerade nicht möglich.');
          return;
        }
        room.state = LudoRules.roll(room.state, _random.nextInt(6) + 1);
        room.broadcast();
        return;
      case RoomMessageType.movePiece:
        if (!_canAct(room, reservation) ||
            room.state.phase != TurnPhase.waitingForMove) {
          _sendError(reservation.socket, 'Ziehen ist gerade nicht möglich.');
          return;
        }
        final pieceId = _safeInt(message['pieceId']);
        if (pieceId == null) {
          _sendError(reservation.socket, 'Figur fehlt.');
          return;
        }
        final piece = room.state.currentPlayer.pieces
            .where((candidate) => candidate.id == pieceId)
            .firstOrNull;
        if (piece == null || !LudoRules.canMove(room.state, piece)) {
          _sendError(reservation.socket, 'Dieser Zug ist nicht erlaubt.');
          return;
        }
        room.state = LudoRules.movePiece(room.state, piece);
        room.broadcast();
        return;
      case RoomMessageType.restartGame:
        if (reservation.token != room.hostToken) {
          _sendError(reservation.socket, 'Nur der Host kann neu starten.');
          return;
        }
        final names = {
          for (final player in room.state.players) player.color: player.name,
        };
        room.state = LudoGameState.newGame(
          playerCount: room.requiredPlayers,
          rules: room.state.rules,
          playerNames: names,
          previousStats: room.state.stats,
        );
        room.broadcast();
        return;
      case RoomMessageType.leaveRoom:
        room.reservations.remove(reservation.token);
        if (room.reservations.isEmpty) {
          _rooms.remove(room.code);
          unawaited(_closeSocket(connection.socket));
          return;
        }
        if (room.hostToken == reservation.token) {
          room.hostToken = room.reservations.keys.firstOrNull ?? '';
        }
        unawaited(_closeSocket(connection.socket));
        room.broadcast();
        return;
      default:
        _sendError(reservation.socket, 'Unbekannte Aktion.');
        return;
    }
  }

  bool _canAct(_Room room, _Reservation reservation) {
    return room.started &&
        room.state.phase != TurnPhase.gameOver &&
        room.state.currentPlayer.color == reservation.color;
  }

  void _disconnect(_Connection? connection) {
    if (connection == null) {
      return;
    }
    if (!identical(connection.reservation.socket, connection.socket)) {
      return;
    }
    connection.reservation
      ..socket = null
      ..lastSeen = DateTime.now();
    connection.room.broadcast();
  }

  void _removeExpiredRooms() {
    final now = DateTime.now();
    final emptyRooms = <String>[];
    for (final entry in _rooms.entries) {
      entry.value.reservations.removeWhere((_, reservation) {
        return reservation.socket == null &&
            now.difference(reservation.lastSeen) > reservationTtl;
      });
      if (entry.value.reservations.isEmpty) {
        emptyRooms.add(entry.key);
      } else {
        if (!entry.value.reservations.containsKey(entry.value.hostToken)) {
          entry.value.hostToken =
              entry.value.reservations.keys.firstOrNull ?? '';
        }
        entry.value.broadcast();
      }
    }
    for (final code in emptyRooms) {
      _rooms.remove(code);
    }
  }

  String _newRoomCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    while (true) {
      final code = List.generate(
        RoomProtocol.roomCodeLength,
        (_) => alphabet[_random.nextInt(alphabet.length)],
      ).join();
      if (!_rooms.containsKey(code)) {
        return code;
      }
    }
  }

  String _newToken() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final entropy = List.generate(4, (_) => _random.nextInt(1 << 32))
        .map((value) => value.toRadixString(36))
        .join();
    return '$timestamp$entropy';
  }

  void _sendError(WebSocket? socket, String message) {
    if (socket?.readyState == WebSocket.open) {
      try {
        socket!.add(
          RoomProtocol.encode(RoomMessageType.error, {
            'message': message,
          }),
        );
      } on Object {
        // Connection closed between the ready-state check and the send.
      }
    }
  }
}

class _Room {
  _Room({
    required this.code,
    required this.state,
    required this.requiredPlayers,
    required this.hostToken,
  });

  final String code;
  final int requiredPlayers;
  String hostToken;
  final Map<String, _Reservation> reservations = {};
  LudoGameState state;

  int get connectedPlayers => reservations.values
      .where((reservation) => reservation.socket != null)
      .length;
  bool get started => connectedPlayers == requiredPlayers;

  void broadcast() {
    for (final reservation in reservations.values) {
      final socket = reservation.socket;
      if (socket == null || socket.readyState != WebSocket.open) {
        continue;
      }
      try {
        socket.add(
          RoomProtocol.encode(RoomMessageType.roomState, {
            'roomCode': code,
            'state': state.toJson(),
            'localColor': reservation.color.name,
            'connectedPlayers': connectedPlayers,
            'requiredPlayers': requiredPlayers,
            'started': started,
            'isHost': reservation.token == hostToken,
            'sessionToken': reservation.token,
          }),
        );
      } on Object {
        if (identical(reservation.socket, socket)) {
          reservation
            ..socket = null
            ..lastSeen = DateTime.now();
        }
      }
    }
  }

  Future<void> close() async {
    for (final reservation in reservations.values) {
      try {
        await reservation.socket?.close();
      } on Object {
        // The peer may have completed its close handshake already.
      }
    }
  }
}

class _Reservation {
  _Reservation({
    required this.token,
    required this.color,
    required this.name,
    required this.socket,
  }) : lastSeen = DateTime.now();

  final String token;
  final PlayerColor color;
  final String name;
  WebSocket? socket;
  DateTime lastSeen;
}

class _Connection {
  const _Connection({
    required this.room,
    required this.reservation,
    required this.socket,
  });

  final _Room room;
  final _Reservation reservation;
  final WebSocket socket;
}

int? _safeInt(Object? value) => value is int ? value : null;

Future<void> _closeSocket(WebSocket socket, {int? statusCode}) async {
  try {
    await socket.close(statusCode);
  } on Object {
    // The peer may already have completed its close handshake.
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
