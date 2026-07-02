import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef DiceRoller = int Function();

class GameController extends ChangeNotifier {
  GameController({
    DiceRoller? diceRoller,
    int initialPlayerCount = 4,
    LudoGameState? initialState,
  })  : _diceRoller = diceRoller ?? _rollDie,
        _state = initialState ??
            LudoGameState.newGame(playerCount: initialPlayerCount);

  static const String _saveKey = 'ludo_club_saved_game_v1';
  static final Random _random = Random();

  final DiceRoller _diceRoller;
  LudoGameState _state;
  final List<LudoGameState> _history = [];

  LudoGameState get state => _state;
  int get playerCount => _state.players.length;
  List<LudoPiece> get movablePieces => LudoRules.movablePieces(_state);
  bool get hasMoveLog => _state.moveLog.isNotEmpty;
  bool get canUndo => _history.isNotEmpty;

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
  }) async {
    _rememberState();
    final currentNames = {
      for (final player in _state.players) player.color: player.name,
    };
    _state = LudoGameState.newGame(
      playerCount: playerCount ?? _state.players.length,
      rules: rules ?? _state.rules,
      playerNames: playerNames ?? currentNames,
    );
    notifyListeners();
    await _save();
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
    await _save();
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
    await _save();
  }

  Future<void> rollDice() async {
    if (_state.phase != TurnPhase.waitingForRoll) {
      return;
    }
    _rememberState();
    _state = LudoRules.roll(_state, _diceRoller());
    notifyListeners();
    await _save();
  }

  Future<void> movePiece(LudoPiece piece) async {
    if (!isMovable(piece)) {
      return;
    }
    _rememberState();
    _state = LudoRules.movePiece(_state, piece);
    notifyListeners();
    await _save();
  }

  Future<void> movePieceById(PlayerColor color, int id) async {
    final player = _state.players.firstWhere(
      (candidate) => candidate.color == color,
    );
    final piece = player.pieces.firstWhere((candidate) => candidate.id == id);
    await movePiece(piece);
  }

  Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  Future<void> undoLastAction() async {
    if (_history.isEmpty) {
      return;
    }
    _state = _history.removeLast();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(_state.toJson()));
  }

  void _rememberState() {
    _history.add(_state);
    if (_history.length > GameConstants.undoHistoryLimit) {
      _history.removeAt(0);
    }
  }

  static Future<LudoGameState?> loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_saveKey);
    if (saved == null) {
      return null;
    }
    final decoded = jsonDecode(saved);
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    return LudoGameState.fromJson(decoded);
  }

  static int _rollDie() => _random.nextInt(6) + 1;
}
