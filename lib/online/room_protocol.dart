import 'dart:convert';

import 'package:ludo_club/models/ludo_models.dart';

abstract final class RoomMessageType {
  static const createRoom = 'create_room';
  static const joinRoom = 'join_room';
  static const roomState = 'room_state';
  static const rollDice = 'roll_dice';
  static const movePiece = 'move_piece';
  static const restartGame = 'restart_game';
  static const leaveRoom = 'leave_room';
  static const error = 'error';
  static const pong = 'pong';
}

enum OnlineRoomStatus {
  disconnected,
  connecting,
  waitingForPlayers,
  ready,
  reconnecting,
  error,
}

class RoomProtocol {
  const RoomProtocol._();

  static const int version = 1;
  static const int maxMessageBytes = 128 * 1024;
  static const int roomCodeLength = 6;

  static String encode(String type, [Map<String, Object?> data = const {}]) {
    return jsonEncode({
      'version': version,
      'type': type,
      ...data,
    });
  }

  static Map<String, Object?>? decode(Object? payload) {
    if (payload is! String || payload.length > maxMessageBytes) {
      return null;
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return null;
      }
      final message = Map<String, Object?>.from(decoded);
      if (message['version'] != version || message['type'] is! String) {
        return null;
      }
      return message;
    } on FormatException {
      return null;
    }
  }

  static String normalizeRoomCode(Object? value) {
    final code = value?.toString().trim().toUpperCase() ?? '';
    return RegExp(r'^[A-Z2-9]{6}$').hasMatch(code) ? code : '';
  }

  static String normalizePlayerName(Object? value) {
    final name = value?.toString().trim() ?? '';
    if (name.isEmpty) {
      return 'Gast';
    }
    return name.length <= 24 ? name : name.substring(0, 24);
  }
}

class OnlineRoomSnapshot {
  const OnlineRoomSnapshot({
    required this.roomCode,
    required this.state,
    required this.localColor,
    required this.connectedPlayers,
    required this.requiredPlayers,
    required this.started,
    required this.isHost,
    required this.sessionToken,
  });

  final String roomCode;
  final LudoGameState state;
  final PlayerColor localColor;
  final int connectedPlayers;
  final int requiredPlayers;
  final bool started;
  final bool isHost;
  final String sessionToken;

  bool get canAct =>
      started &&
      state.phase != TurnPhase.gameOver &&
      state.currentPlayer.color == localColor;

  factory OnlineRoomSnapshot.fromMessage(Map<String, Object?> message) {
    final stateJson = message['state'];
    if (stateJson is! Map) {
      throw const FormatException('Room state is missing.');
    }
    final colorName = message['localColor']?.toString();
    final localColor = PlayerColor.values.firstWhere(
      (color) => color.name == colorName,
      orElse: () => throw const FormatException('Invalid local color.'),
    );
    final roomCode = RoomProtocol.normalizeRoomCode(message['roomCode']);
    final sessionToken = message['sessionToken']?.toString() ?? '';
    if (roomCode.isEmpty || sessionToken.isEmpty) {
      throw const FormatException('Invalid room identity.');
    }
    final requiredPlayers = _boundedInt(message['requiredPlayers'], 2, 4) ?? 2;
    final connectedPlayers =
        _boundedInt(message['connectedPlayers'], 0, requiredPlayers) ?? 0;
    return OnlineRoomSnapshot(
      roomCode: roomCode,
      state: LudoGameState.fromJson(Map<String, Object?>.from(stateJson)),
      localColor: localColor,
      connectedPlayers: connectedPlayers,
      requiredPlayers: requiredPlayers,
      started: message['started'] == true,
      isHost: message['isHost'] == true,
      sessionToken: sessionToken,
    );
  }
}

int? _boundedInt(Object? value, int minimum, int maximum) {
  return value is int && value >= minimum && value <= maximum ? value : null;
}
