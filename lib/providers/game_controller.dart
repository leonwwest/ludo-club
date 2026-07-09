import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/services/game_storage.dart';

typedef DiceRoller = int Function();

class GameController extends ChangeNotifier {
  GameController({
    DiceRoller? diceRoller,
    Random? random,
    int initialPlayerCount = 4,
    LudoGameState? initialState,
    GameStorage? storage,
    Duration botTurnDelay = const Duration(milliseconds: 720),
    bool botAutomationEnabled = true,
  })  : _diceRoller = diceRoller ?? (() => _defaultRoller(random ?? Random())),
        _state = initialState ??
            LudoGameState.newGame(playerCount: initialPlayerCount),
        _storage = storage ?? GameStorage(),
        _botTurnDelay = botTurnDelay,
        _botAutomationEnabled = botAutomationEnabled {
    _scheduleBotTurn();
  }

  static int _defaultRoller(Random random) => random.nextInt(6) + 1;

  final DiceRoller _diceRoller;
  final GameStorage _storage;
  final Duration _botTurnDelay;
  LudoGameState _state;
  final List<LudoGameState> _history = [];
  Timer? _botTurnTimer;
  bool _botAutomationEnabled;
  bool _isDisposed = false;

  LudoGameState get state => _state;
  int get playerCount => _state.players.length;
  List<LudoPiece> get movablePieces => LudoRules.movablePieces(_state);
  bool get hasMoveLog => _state.moveLog.isNotEmpty;
  bool get canUndo => _history.isNotEmpty;
  bool get isBotTurn =>
      _state.phase != TurnPhase.gameOver && _state.currentPlayer.isBot;

  void setBotAutomationEnabled(bool enabled) {
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

  bool isMovable(LudoPiece piece) => LudoRules.canMove(_state, piece);
  int? legalTargetStepsFor(LudoPiece piece) {
    return LudoRules.legalTargetStepsFor(_state, piece);
  }

  String? moveHintFor(LudoPiece piece) {
    return LudoRules.moveHintFor(_state, piece);
  }

  Future<void> newGame({
    int? playerCount,
    RuleOptions? rules,
    Map<PlayerColor, String>? playerNames,
    Map<PlayerColor, PlayerKind>? playerKinds,
    Map<PlayerColor, PlayerAvatarId>? playerAvatars,
  }) async {
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
    _state = LudoGameState.newGame(
      playerCount: playerCount ?? _state.players.length,
      rules: rules ?? _state.rules,
      playerNames: playerNames ?? currentNames,
      playerKinds: playerKinds ?? currentKinds,
      playerAvatars: playerAvatars ?? currentAvatars,
    );
    notifyListeners();
    await _storage.save(_state);
    _scheduleBotTurn();
  }

  Future<void> updatePlayerName(PlayerColor color, String name) async {
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
    await _storage.save(_state);
    _scheduleBotTurn();
  }

  Future<void> updatePlayerKind(PlayerColor color, PlayerKind kind) async {
    _state = _state.copyWith(
      players: [
        for (final player in _state.players)
          if (player.color == color) player.copyWith(kind: kind) else player,
      ],
    );
    notifyListeners();
    await _storage.save(_state);
    _scheduleBotTurn();
  }

  Future<void> updatePlayerAvatar(
    PlayerColor color,
    PlayerAvatarId avatarId,
  ) async {
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
    await _storage.save(_state);
    _scheduleBotTurn();
  }

  Future<void> updateRules(RuleOptions rules) async {
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
    await _storage.save(_state);
    _scheduleBotTurn();
  }

  Future<void> rollDice() async {
    if (_state.phase != TurnPhase.waitingForRoll) {
      return;
    }
    _rememberState();
    _state = LudoRules.roll(_state, _diceRoller());
    notifyListeners();
    await _storage.save(_state);
    _scheduleBotTurn();
  }

  Future<void> movePiece(LudoPiece piece) async {
    if (!isMovable(piece)) {
      return;
    }
    _rememberState();
    _state = LudoRules.movePiece(_state, piece);
    notifyListeners();
    await _storage.save(_state);
    _scheduleBotTurn();
  }

  Future<void> movePieceById(PlayerColor color, int id) async {
    final player = _state.players.firstWhere(
      (candidate) => candidate.color == color,
    );
    final piece = player.pieces.firstWhere((candidate) => candidate.id == id);
    await movePiece(piece);
  }

  Future<void> clearSavedGame() async {
    await _storage.clearSavedGame();
  }

  Future<void> undoLastAction() async {
    if (_history.isEmpty) {
      return;
    }
    _botTurnTimer?.cancel();
    _state = _history.removeLast();
    notifyListeners();
    _scheduleBotTurn();
  }

  Future<void> playBotTurn() async {
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
    final candidates = movablePieces;
    if (candidates.isEmpty) {
      return null;
    }

    LudoPiece? bestPiece;
    var bestScore = -1;
    for (final piece in candidates) {
      final simulated = LudoRules.movePiece(_state, piece);
      final summary = simulated.moveSummary;
      final target =
          LudoRules.legalTargetStepsFor(_state, piece) ?? piece.steps;
      var score = target;
      if (summary?.didCapture == true) {
        score += 500;
      }
      if (summary?.finished == true) {
        score += 350;
      }
      if (piece.isInBase) {
        score += 140;
      }
      if (simulated.phase == TurnPhase.gameOver) {
        score += 1000;
      }
      if (score > bestScore) {
        bestScore = score;
        bestPiece = piece;
      }
    }
    return bestPiece;
  }

  void _scheduleBotTurn() {
    _botTurnTimer?.cancel();
    if (_isDisposed || !_botAutomationEnabled || !isBotTurn) {
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

  static Future<LudoGameState?> loadSavedState() async {
    final storage = GameStorage();
    return storage.loadSavedState();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _botTurnTimer?.cancel();
    _storage.dispose();
    super.dispose();
  }
}
