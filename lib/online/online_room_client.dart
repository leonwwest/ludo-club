import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/online/room_protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OnlineRoomClient extends ChangeNotifier {
  OnlineRoomClient({
    required Uri serverUri,
    this.autoReconnect = true,
  }) : serverUri = _webSocketUri(serverUri);

  final Uri serverUri;
  final bool autoReconnect;

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Timer? _reconnectTimer;
  Timer? _identifyTimer;
  OnlineRoomSnapshot? _snapshot;
  OnlineRoomStatus _status = OnlineRoomStatus.disconnected;
  String? _errorMessage;
  String? _roomCode;
  String? _playerName;
  String? _sessionToken;
  int? _createPlayerCount;
  RuleOptions? _createRules;
  int _reconnectAttempt = 0;
  bool _disposed = false;
  bool _manualDisconnect = false;
  bool _awaitingRoomState = false;
  bool _actionInFlight = false;

  OnlineRoomStatus get status => _status;
  OnlineRoomSnapshot? get snapshot => _snapshot;
  LudoGameState? get state => _snapshot?.state;
  String? get errorMessage => _errorMessage;
  String? get roomCode => _snapshot?.roomCode ?? _roomCode;
  PlayerColor? get localColor => _snapshot?.localColor;
  bool get isConnected => _channel != null;
  bool get canAct =>
      !_disposed &&
      _status == OnlineRoomStatus.ready &&
      _channel != null &&
      !_actionInFlight &&
      _snapshot?.canAct == true;
  bool get isHost =>
      !_disposed &&
      _status == OnlineRoomStatus.ready &&
      !_actionInFlight &&
      _snapshot?.isHost == true;

  Future<void> createRoom({
    required String playerName,
    int playerCount = 2,
    RuleOptions rules = const RuleOptions(),
  }) async {
    _roomCode = null;
    _sessionToken = null;
    _playerName = RoomProtocol.normalizePlayerName(playerName);
    _createPlayerCount = playerCount.clamp(2, 4);
    _createRules = rules;
    await _connectAndIdentify();
  }

  Future<void> joinRoom({
    required String roomCode,
    required String playerName,
    String? sessionToken,
  }) async {
    final normalizedCode = RoomProtocol.normalizeRoomCode(roomCode);
    if (normalizedCode.isEmpty) {
      throw const FormatException('Ungültiger Raumcode.');
    }
    _roomCode = normalizedCode;
    _playerName = RoomProtocol.normalizePlayerName(playerName);
    _sessionToken = sessionToken ?? _sessionToken;
    _createPlayerCount = null;
    _createRules = null;
    await _connectAndIdentify();
  }

  void rollDice() {
    if (!canAct || state?.phase != TurnPhase.waitingForRoll) {
      return;
    }
    _sendAction(RoomProtocol.encode(RoomMessageType.rollDice));
  }

  void movePiece(int pieceId) {
    if (!canAct || state?.phase != TurnPhase.waitingForMove) {
      return;
    }
    _sendAction(
      RoomProtocol.encode(RoomMessageType.movePiece, {
        'pieceId': pieceId,
      }),
    );
  }

  void restartGame() {
    if (!isHost) {
      return;
    }
    _sendAction(RoomProtocol.encode(RoomMessageType.restartGame));
  }

  Future<void> leaveRoom() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _identifyTimer?.cancel();
    _awaitingRoomState = false;
    _actionInFlight = false;
    _send(RoomProtocol.encode(RoomMessageType.leaveRoom));
    await _closeTransport();
    _snapshot = null;
    _roomCode = null;
    _sessionToken = null;
    _setStatus(OnlineRoomStatus.disconnected);
  }

  Future<void> disconnect({bool preserveRoom = true}) async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _identifyTimer?.cancel();
    _awaitingRoomState = false;
    _actionInFlight = false;
    await _closeTransport();
    _snapshot = null;
    if (!preserveRoom) {
      _roomCode = null;
      _sessionToken = null;
    }
    _setStatus(OnlineRoomStatus.disconnected);
  }

  Future<void> _connectAndIdentify() async {
    _errorMessage = null;
    _reconnectTimer?.cancel();
    _identifyTimer?.cancel();
    _awaitingRoomState = false;
    _actionInFlight = false;
    _manualDisconnect = true;
    await _closeTransport();
    _manualDisconnect = false;
    _setStatus(
      _reconnectAttempt == 0
          ? OnlineRoomStatus.connecting
          : OnlineRoomStatus.reconnecting,
    );
    try {
      final channel = WebSocketChannel.connect(serverUri);
      _channel = channel;
      await channel.ready.timeout(const Duration(seconds: 10));
      if (_disposed) {
        await channel.sink.close();
        return;
      }
      _subscription = channel.stream.listen(
        _handlePayload,
        onDone: _handleDisconnected,
        onError: (Object error) => _handleDisconnected(error),
        cancelOnError: true,
      );
      _identify();
      _awaitingRoomState = true;
      _identifyTimer?.cancel();
      _identifyTimer = Timer(const Duration(seconds: 10), () {
        if (_awaitingRoomState && !_disposed) {
          unawaited(_handleIdentificationTimeout());
        }
      });
    } on Object catch (error) {
      _channel = null;
      _handleDisconnected(error);
    }
  }

  void _identify() {
    final name = _playerName ?? 'Gast';
    if (_createPlayerCount case final count?) {
      _send(
        RoomProtocol.encode(RoomMessageType.createRoom, {
          'name': name,
          'playerCount': count,
          'rules': (_createRules ?? const RuleOptions()).toJson(),
        }),
      );
      return;
    }
    _send(
      RoomProtocol.encode(RoomMessageType.joinRoom, {
        'roomCode': _roomCode,
        'name': name,
        if (_sessionToken?.isNotEmpty == true) 'sessionToken': _sessionToken,
      }),
    );
  }

  void _handlePayload(Object? payload) {
    final message = RoomProtocol.decode(payload);
    if (message == null) {
      _setError('Der Server hat ungültige Daten gesendet.');
      return;
    }
    switch (message['type']) {
      case RoomMessageType.roomState:
        try {
          _awaitingRoomState = false;
          _actionInFlight = false;
          _identifyTimer?.cancel();
          final snapshot = OnlineRoomSnapshot.fromMessage(message);
          _snapshot = snapshot;
          _roomCode = snapshot.roomCode;
          _sessionToken = snapshot.sessionToken;
          _createPlayerCount = null;
          _createRules = null;
          _reconnectAttempt = 0;
          _errorMessage = null;
          _setStatus(
            snapshot.started
                ? OnlineRoomStatus.ready
                : OnlineRoomStatus.waitingForPlayers,
          );
          return;
        } on FormatException catch (error) {
          _setError(error.message);
          return;
        }
      case RoomMessageType.error:
        _awaitingRoomState = false;
        _actionInFlight = false;
        _identifyTimer?.cancel();
        final errorMessage = message['message']?.toString() ?? 'Online-Fehler.';
        if (_snapshot != null && _channel != null) {
          _errorMessage = errorMessage;
          _setStatus(
            _snapshot!.started
                ? OnlineRoomStatus.ready
                : OnlineRoomStatus.waitingForPlayers,
          );
        } else {
          _setError(errorMessage);
        }
        return;
      default:
        return;
    }
  }

  void _handleDisconnected([Object? error]) {
    if (_disposed || _manualDisconnect) {
      return;
    }
    _subscription = null;
    _channel = null;
    _awaitingRoomState = false;
    _actionInFlight = false;
    _identifyTimer?.cancel();
    if (!autoReconnect || _roomCode == null || _reconnectAttempt >= 5) {
      _setError(error?.toString() ?? 'Verbindung getrennt.');
      return;
    }
    _reconnectAttempt += 1;
    _setStatus(OnlineRoomStatus.reconnecting);
    final exponent = (_reconnectAttempt - 1).clamp(0, 3).toInt();
    final delay = Duration(seconds: 1 << exponent);
    _reconnectTimer = Timer(delay, () {
      unawaited(_connectAndIdentify());
    });
  }

  void _send(String message) {
    try {
      _channel?.sink.add(message);
    } on Object catch (error) {
      _handleDisconnected(error);
    }
  }

  void _sendAction(String message) {
    _actionInFlight = true;
    _errorMessage = null;
    notifyListeners();
    _send(message);
  }

  void _setError(String message) {
    _identifyTimer?.cancel();
    _awaitingRoomState = false;
    _actionInFlight = false;
    _errorMessage = message;
    _setStatus(OnlineRoomStatus.error);
  }

  void _setStatus(OnlineRoomStatus value) {
    if (_status == value && !_disposed) {
      notifyListeners();
      return;
    }
    _status = value;
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _identifyTimer?.cancel();
    _awaitingRoomState = false;
    _actionInFlight = false;
    unawaited(_subscription?.cancel());
    unawaited(_channel?.sink.close());
    super.dispose();
  }

  Future<void> _handleIdentificationTimeout() async {
    if (!_awaitingRoomState || _disposed) {
      return;
    }
    _awaitingRoomState = false;
    _manualDisconnect = true;
    await _closeTransport();
    _manualDisconnect = false;
    if (_disposed) {
      return;
    }
    _handleDisconnected(
      TimeoutException('Der Raum-Server antwortet nicht.'),
    );
  }

  Future<void> _closeTransport() async {
    final subscription = _subscription;
    final channel = _channel;
    _subscription = null;
    _channel = null;
    try {
      await subscription?.cancel();
    } on Object {
      // Cleanup continues even if a transport already failed.
    }
    try {
      await channel?.sink.close();
    } on Object {
      // Cleanup continues even if the peer already disappeared.
    }
  }
}

Uri _webSocketUri(Uri input) {
  final scheme = switch (input.scheme) {
    'https' => 'wss',
    'http' => 'ws',
    'wss' || 'ws' => input.scheme,
    _ => 'ws',
  };
  final path = input.path.isEmpty || input.path == '/' ? '/ws' : input.path;
  return input.replace(scheme: scheme, path: path);
}
