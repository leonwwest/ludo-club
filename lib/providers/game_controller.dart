import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';

typedef DiceRoller = int Function();

class GameController extends ChangeNotifier {
  GameController({DiceRoller? diceRoller, int initialPlayerCount = 4})
      : _diceRoller = diceRoller ?? _rollDie,
        _state = LudoGameState.newGame(playerCount: initialPlayerCount);

  static final Random _random = Random();

  final DiceRoller _diceRoller;
  LudoGameState _state;

  LudoGameState get state => _state;
  int get playerCount => _state.players.length;
  List<LudoPiece> get movablePieces => LudoRules.movablePieces(_state);

  bool isMovable(LudoPiece piece) => LudoRules.canMove(_state, piece);

  void newGame({int? playerCount}) {
    _state = LudoGameState.newGame(
      playerCount: playerCount ?? _state.players.length,
    );
    notifyListeners();
  }

  void rollDice() {
    if (_state.phase != TurnPhase.waitingForRoll) {
      return;
    }
    _state = LudoRules.roll(_state, _diceRoller());
    notifyListeners();
  }

  void movePiece(LudoPiece piece) {
    if (!isMovable(piece)) {
      return;
    }
    _state = LudoRules.movePiece(_state, piece);
    notifyListeners();
  }

  void movePieceById(PlayerColor color, int id) {
    final player = _state.players.firstWhere(
      (candidate) => candidate.color == color,
    );
    final piece = player.pieces.firstWhere((candidate) => candidate.id == id);
    movePiece(piece);
  }

  static int _rollDie() => _random.nextInt(6) + 1;
}
