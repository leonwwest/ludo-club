import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/logic/bot_strategy.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/online/online_room_client.dart';
import 'package:ludo_club/online/room_protocol.dart';
import 'package:ludo_club/services/game_storage.dart';

typedef DiceRoller = int Function();

class GameController extends ChangeNotifier {
  GameController({
    DiceRoller? diceRoller,
    Random? random,
    int initialPlayerCount = 4,
    LudoGameState? initialState,
    List<LudoGameState> initialHistory = const [],
    GameStorage? storage,
    Duration botTurnDelay = const Duration(milliseconds: 720),
    bool botAutomationEnabled = true,
  })  : _random = random ?? Random(),
        _diceRoller = diceRoller ?? (() => _defaultRoller(random ?? Random())),
        _state = initialState ??
            LudoGameState.newGame(playerCount: initialPlayerCount),
        _storage = storage ?? GameStorage(),
        _botTurnDelay = botTurnDelay,
        _botAutomationEnabled = botAutomationEnabled {
    final boundedHistory =
        initialHistory.length <= GameConstants.undoHistoryLimit
            ? initialHistory
            : initialHistory.sublist(
                initialHistory.length - GameConstants.undoHistoryLimit,
              );
    _history.addAll(boundedHistory);
    _scheduleBotTurn();
  }

  static int _defaultRoller(Random random) => random.nextInt(6) + 1;

  final DiceRoller _diceRoller;
  final Random _random;
  final GameStorage _storage;
  final Duration _botTurnDelay;
  LudoGameState _state;
  final List<LudoGameState> _history = [];
  List<LudoGameState>? _offlineHistoryBeforeOnline;
  LudoGameState? _offlineStateBeforeOnline;
  OnlineRoomClient? _onlineRoomClient;
  VoidCallback? _onlineRoomListener;
  Timer? _botTurnTimer;
  bool _botAutomationEnabled;
  bool _isDisposed = false;

  LudoGameState get state => _state;
  int get playerCount => _state.players.length;
  List<LudoPiece> get movablePieces =>
      canLocalPlayerAct ? LudoRules.movablePieces(_state) : const [];
  bool get hasMoveLog => _state.moveLog.isNotEmpty;
  bool get isOnlineMatch => _onlineRoomClient != null;
  OnlineRoomSnapshot? get onlineRoomSnapshot => _onlineRoomClient?.snapshot;
  OnlineRoomStatus? get onlineRoomStatus => _onlineRoomClient?.status;
  String? get onlineRoomCode => _onlineRoomClient?.roomCode;
  String? get onlineRoomError => _onlineRoomClient?.errorMessage;
  bool get canRestartOnlineMatch => _onlineRoomClient?.isHost == true;
  bool get canLocalPlayerAct =>
      !isOnlineMatch || _onlineRoomClient?.canAct == true;
  bool get isRemoteTurn =>
      isOnlineMatch && _state.phase != TurnPhase.gameOver && !canLocalPlayerAct;
  bool get isWaitingForOnlinePlayers =>
      isOnlineMatch && _onlineRoomClient?.snapshot?.started != true;
  bool get canUndo => !isOnlineMatch && _history.isNotEmpty;
  bool get canEditRules =>
      !isOnlineMatch &&
      _state.phase == TurnPhase.waitingForRoll &&
      _state.stats.rolls == 0 &&
      _state.stats.moves == 0 &&
      _state.moveLog.isEmpty &&
      _state.players
          .expand((player) => player.pieces)
          .every((piece) => piece.isInBase);
  bool get isBotTurn =>
      !isOnlineMatch &&
      _state.phase != TurnPhase.gameOver &&
      _state.currentPlayer.isBot;

  void setBotAutomationEnabled(bool enabled) {
    if (isOnlineMatch) {
      _botTurnTimer?.cancel();
      return;
    }
    if (_botAutomationEnabled == enabled) {
      return;
    }
    _botAutomationEnabled = enabled;
    if (!enabled) {
      _botTurnTimer?.cancel();
      return;
    }
    _scheduleBotTurn();
  }

  bool isMovable(LudoPiece piece) =>
      canLocalPlayerAct && LudoRules.canMove(_state, piece);
  int? legalTargetStepsFor(LudoPiece piece) {
    if (!canLocalPlayerAct) {
      return null;
    }
    return LudoRules.legalTargetStepsFor(_state, piece);
  }

  String? moveHintFor(LudoPiece piece) {
    if (!canLocalPlayerAct) {
      return null;
    }
    return LudoRules.moveHintFor(_state, piece);
  }

  void attachOnlineRoom(OnlineRoomClient client) {
    if (identical(_onlineRoomClient, client)) {
      return;
    }
    _botTurnTimer?.cancel();
    _detachOnlineListener(disposeClient: true);
    _offlineStateBeforeOnline ??= _state;
    _offlineHistoryBeforeOnline ??= List<LudoGameState>.of(_history);
    _history.clear();
    _onlineRoomClient = client;
    void listener() {
      if (_isDisposed) {
        return;
      }
      final snapshot = client.snapshot;
      if (snapshot != null) {
        _state = snapshot.state;
      }
      notifyListeners();
    }

    _onlineRoomListener = listener;
    client.addListener(listener);
    listener();
  }

  Future<void> leaveOnlineRoom() async {
    final client = _onlineRoomClient;
    if (client == null) {
      return;
    }
    final listener = _onlineRoomListener;
    if (listener != null) {
      client.removeListener(listener);
    }
    _onlineRoomListener = null;
    _onlineRoomClient = null;
    try {
      await client.leaveRoom();
    } finally {
      client.dispose();
      _state = _offlineStateBeforeOnline ?? LudoGameState.newGame();
      _offlineStateBeforeOnline = null;
      _history
        ..clear()
        ..addAll(_offlineHistoryBeforeOnline ?? const []);
      _offlineHistoryBeforeOnline = null;
      if (!_isDisposed) {
        notifyListeners();
        _scheduleBotTurn();
      }
    }
  }

  Future<void> newGame({
    int? playerCount,
    RuleOptions? rules,
    Map<PlayerColor, String>? playerNames,
    Map<PlayerColor, PlayerKind>? playerKinds,
    Map<PlayerColor, PlayerAvatarId>? playerAvatars,
    Map<PlayerColor, BotDifficulty>? botDifficulties,
  }) async {
    if (isOnlineMatch) {
      _onlineRoomClient?.restartGame();
      return;
    }
    _botTurnTimer?.cancel();
    _rememberState();
    final currentNames = {
      for (final player in _state.players) player.color: player.name,
    };
    final currentKinds = {
      for (final player in _state.players) player.color: player.kind,
    };
    final currentAvatars = {
      for (final player in _state.players) player.color: player.avatarId,
    };
    final currentBotDifficulties = {
      for (final player in _state.players) player.color: player.botDifficulty,
    };
    _state = LudoGameState.newGame(
      playerCount: playerCount ?? _state.players.length,
      rules: rules ?? _state.rules,
      playerNames: playerNames ?? currentNames,
      playerKinds: playerKinds ?? currentKinds,
      playerAvatars: playerAvatars ?? currentAvatars,
      botDifficulties: botDifficulties ?? currentBotDifficulties,
      previousStats: _state.stats,
    );
    notifyListeners();
    await _persistState();
    _scheduleBotTurn();
  }

  Future<void> updatePlayerName(PlayerColor color, String name) async {
    if (isOnlineMatch) {
      return;
    }
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      return;
    }
    _state = _state.copyWith(
      players: [
        for (final player in _state.players)
          if (player.color == color) player.copyWith(name: cleaned) else player,
      ],
      turnMessage: _state.currentPlayer.color == color
          ? '$cleaned ist dran.'
          : _state.turnMessage,
    );
    notifyListeners();
    await _persistState();
    _scheduleBotTurn();
  }

  Future<void> updatePlayerKind(PlayerColor color, PlayerKind kind) async {
    if (isOnlineMatch) {
      return;
    }
    _state = _state.copyWith(
      players: [
        for (final player in _state.players)
          if (player.color == color) player.copyWith(kind: kind) else player,
      ],
    );
    notifyListeners();
    await _persistState();
    _scheduleBotTurn();
  }

  Future<void> updateBotDifficulty(
    PlayerColor color,
    BotDifficulty difficulty,
  ) async {
    if (isOnlineMatch) {
      return;
    }
    _state = _state.copyWith(
      players: [
        for (final player in _state.players)
          if (player.color == color)
            player.copyWith(botDifficulty: difficulty)
          else
            player,
      ],
    );
    notifyListeners();
    await _persistState();
    _scheduleBotTurn();
  }

  Future<void> updatePlayerAvatar(
    PlayerColor color,
    PlayerAvatarId avatarId,
  ) async {
    if (isOnlineMatch) {
      return;
    }
    _state = _state.copyWith(
      players: [
        for (final player in _state.players)
          if (player.color == color)
            player.copyWith(avatarId: avatarId)
          else
            player,
      ],
    );
    notifyListeners();
    await _persistState();
    _scheduleBotTurn();
  }

  Future<void> updateRules(RuleOptions rules) async {
    if (!canEditRules) {
      return;
    }
    _rememberState();
    _state = _state.copyWith(
      rules: rules,
      pendingOpenRolls: _state.currentPlayer.pieces.every(
        (piece) => piece.isInBase,
      )
          ? rules.rollsWhenNoPieceIsOut
          : 1,
    );
    notifyListeners();
    await _persistState();
    _scheduleBotTurn();
  }

  Future<void> rollDice() async {
    if (isOnlineMatch) {
      _onlineRoomClient?.rollDice();
      return;
    }
    if (_state.phase != TurnPhase.waitingForRoll) {
      return;
    }
    _rememberState();
    _state = LudoRules.roll(_state, _diceRoller());
    notifyListeners();
    await _persistState();
    _scheduleBotTurn();
  }

  Future<void> movePiece(LudoPiece piece) async {
    if (isOnlineMatch) {
      if (isMovable(piece)) {
        _onlineRoomClient?.movePiece(piece.id);
      }
      return;
    }
    if (!isMovable(piece)) {
      return;
    }
    _rememberState();
    _state = LudoRules.movePiece(_state, piece);
    notifyListeners();
    await _persistState();
    _scheduleBotTurn();
  }

  Future<void> movePieceById(PlayerColor color, int id) async {
    final player = _state.players.firstWhere(
      (candidate) => candidate.color == color,
    );
    final piece = player.pieces.firstWhere((candidate) => candidate.id == id);
    await movePiece(piece);
  }

  Future<bool> performOnlyLegalMoveIfAvailable() async {
    final candidates = movablePieces;
    if (candidates.length != 1) {
      return false;
    }
    await movePiece(candidates.single);
    return true;
  }

  Future<void> clearSavedGame() async {
    await _storage.clearSavedGame();
  }

  Future<void> flushStorage() => _storage.flush();

  Future<void> undoLastAction() async {
    if (isOnlineMatch) {
      return;
    }
    if (_history.isEmpty) {
      return;
    }
    _botTurnTimer?.cancel();
    _state = _history.removeLast();
    notifyListeners();
    await _persistState();
    _scheduleBotTurn();
  }

  Future<void> playBotTurn() async {
    if (isOnlineMatch) {
      return;
    }
    if (!isBotTurn) {
      return;
    }
    if (_state.phase == TurnPhase.waitingForRoll) {
      await rollDice();
      return;
    }
    if (_state.phase == TurnPhase.waitingForMove) {
      final piece = _chooseBotPiece();
      if (piece != null) {
        await movePiece(piece);
      }
    }
  }

  LudoPiece? _chooseBotPiece() {
    return BotStrategy.choosePiece(
      _state,
      difficulty: _state.currentPlayer.botDifficulty,
      random: _random,
    );
  }

  void _scheduleBotTurn() {
    _botTurnTimer?.cancel();
    if (_isDisposed || isOnlineMatch || !_botAutomationEnabled || !isBotTurn) {
      return;
    }
    _botTurnTimer = Timer(_botTurnDelay, () {
      unawaited(playBotTurn());
    });
  }

  void _rememberState() {
    _history.add(_state);
    if (_history.length > GameConstants.undoHistoryLimit) {
      _history.removeAt(0);
    }
  }

  Future<void> _persistState() {
    return _storage.save(_state, history: _history);
  }

  static Future<SavedGameSnapshot?> loadSavedGame() async {
    final storage = GameStorage();
    try {
      return await storage.loadSavedGame();
    } finally {
      storage.dispose();
    }
  }

  static Future<LudoGameState?> loadSavedState() async {
    return (await loadSavedGame())?.state;
  }

  void _detachOnlineListener({required bool disposeClient}) {
    final client = _onlineRoomClient;
    final listener = _onlineRoomListener;
    if (client != null && listener != null) {
      client.removeListener(listener);
    }
    if (disposeClient) {
      client?.dispose();
    }
    _onlineRoomListener = null;
    _onlineRoomClient = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _botTurnTimer?.cancel();
    _detachOnlineListener(disposeClient: true);
    _storage.dispose();
    super.dispose();
  }
}
