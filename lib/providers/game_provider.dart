import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_phase.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/services/audio_service.dart';

class GameProvider extends ChangeNotifier {
  late GameState _gameState;
  final AudioService _audioService;

  bool isAnimating = false;
  bool _showReachedHomeEffect = false;
  PlayerColor? _reachedHomePlayerId;
  int? _reachedHomeTokenIndex;
  
  bool _showCaptureEffect = false;
  PlayerColor? _capturedPlayerId;
  int? _capturedTokenIndex;

  GameProvider({
    AudioService? audioService,
  })  : _audioService = audioService ?? AudioService() {
    _createNewGame([PlayerColor.red, PlayerColor.green]); // Default to 2 players
    _initAudio();
  }

  void _createNewGame(List<PlayerColor> playerColors) {
    _gameState = GameState(
      players: playerColors
          .map((c) => Player(
              id: c.toString(),
              name: 'Player ${playerColors.indexOf(c) + 1}',
              color: c,
              type: PlayerType.human, // All players are human
              pieces: List.generate(4, (i) => Piece(c, i, const PiecePosition(GameState.basePosition, isHome: true)))))
          .toList(),
      currentTurnPlayerId: playerColors.first,
      startIndices: LudoGame.startFields,
    );
    // Debug: Game created with players
    unawaited(nextTurn());
  }

  Future<void> _initAudio() async {
    await _audioService.init();
  }

  GameState get gameState => _gameState;
  GamePhase get phase => _gameState.phase;
  bool get showReachedHomeEffect => _showReachedHomeEffect;
  PlayerColor? get reachedHomePlayerId => _reachedHomePlayerId;
  int? get reachedHomeTokenIndex => _reachedHomeTokenIndex;
  
  bool get showCaptureEffect => _showCaptureEffect;
  PlayerColor? get capturedPlayerId => _capturedPlayerId;
  int? get capturedTokenIndex => _capturedTokenIndex;

  void clearReachedHomeEffect() {
    _showReachedHomeEffect = false;
    _reachedHomePlayerId = null;
    _reachedHomeTokenIndex = null;
  }
  
  void clearCaptureEffect() {
    _showCaptureEffect = false;
    _capturedPlayerId = null;
    _capturedTokenIndex = null;
  }

  Future<void> nextTurn() async {
    if (_gameState.isGameOver) return;

    _gameState = _gameState.copyWith(phase: GamePhase.waitingForRoll);
    notifyListeners();
  }

  Future<void> rollDice() async {
    // Debug: rollDice called
    if (_gameState.phase != GamePhase.waitingForRoll) return;

    _gameState = _gameState.copyWith(phase: GamePhase.animating);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));
    await _audioService.playDiceSound();

    final diceValue = Random().nextInt(6) + 1;
    _gameState = _gameState.copyWith(lastDiceValue: diceValue, currentRollCount: _gameState.currentRollCount + 1);

    final moves = LudoGame.getMovablePieces(_gameState);

    if (moves.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      _advanceToNextPlayer();
    } else {
      _gameState = _gameState.copyWith(phase: GamePhase.waitingForMove);
      notifyListeners();
    }
  }

  // Debug method to force roll a 6
  Future<void> debugRollSix() async {
    print('debugRollSix called, current phase: ${_gameState.phase}');
    if (_gameState.phase != GamePhase.waitingForRoll) return;

    _gameState = _gameState.copyWith(phase: GamePhase.animating);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    print('Debug: Setting dice to 6');
    _gameState = _gameState.copyWith(lastDiceValue: 6, currentRollCount: _gameState.currentRollCount + 1);

    final moves = LudoGame.getMovablePieces(_gameState);
    print('Movable pieces with dice 6: ${moves.length}');
    for (var piece in moves) {
      print('  - Piece ${piece.color} ${piece.id} at position ${piece.position.fieldId}, isHome: ${piece.position.isHome}');
    }

    if (moves.isEmpty) {
      print('ERROR: No movable pieces even with dice 6!');
      await Future.delayed(const Duration(milliseconds: 500));
      _advanceToNextPlayer();
    } else {
      print('Setting phase to waitingForMove');
      _gameState = _gameState.copyWith(phase: GamePhase.waitingForMove);
      notifyListeners();
    }
  }

  Future<void> movePiece(Piece pieceToMove) async {
    if (_gameState.phase != GamePhase.waitingForMove) {
      return;
    }

    _gameState = _gameState.copyWith(phase: GamePhase.animating);
    notifyListeners();

    final moveResult = LudoGame.movePiece(_gameState, pieceToMove);
    _gameState = moveResult.newState;

    // Handle captured piece
    if (moveResult.capturedOpponentPiece != null) {
      final captured = moveResult.capturedOpponentPiece!;
      print('GameProvider: Piece captured! ${captured.color} ${captured.id} sent home');
      
      _showCaptureEffect = true;
      _capturedPlayerId = captured.color;
      _capturedTokenIndex = captured.id;
      
      await _audioService.playCaptureSound();
    } else if (moveResult.isFinishMove) {
      _showReachedHomeEffect = true;
      _reachedHomePlayerId = pieceToMove.color;
      _reachedHomeTokenIndex = pieceToMove.id;
      await _audioService.playFinishSound();
    } else {
      await _audioService.playMoveSound();
    }

    if (_gameState.isGameOver) {
      await _audioService.playVictorySound();
      _gameState = _gameState.copyWith(phase: GamePhase.finished);
      notifyListeners();
      return;
    }

    // Check for 6 or capture: get another turn
    if (_gameState.lastDiceValue == 6 || moveResult.capturedOpponentPiece != null) {
      unawaited(nextTurn());
    } else {
      _advanceToNextPlayer();
    }
  }

  void _advanceToNextPlayer() {
    final playerColors = _gameState.players.map((p) => p.color).toList();
    final currentPlayerIndex = playerColors.indexOf(_gameState.currentTurnPlayerId);
    final nextPlayerIndex = (currentPlayerIndex + 1) % playerColors.length;
    _gameState = _gameState.copyWith(
      currentTurnPlayerId: playerColors[nextPlayerIndex],
      lastDiceValue: 0,
      currentRollCount: 0,
    );
    unawaited(nextTurn());
  }

  List<Piece> getMovablePieces() {
    return LudoGame.getMovablePieces(_gameState);
  }

  void setSoundEnabled(bool enabled) {
    _audioService.setSoundEnabled(enabled);
    notifyListeners();
  }

  bool get isSoundEnabled => _audioService.isSoundEnabled;

  void setVolume(double volume) {
    _audioService.setVolume(volume);
    notifyListeners();
  }

  double get volume => _audioService.volume;

  PlayerColor get currentPlayerColor => _gameState.currentTurnPlayerId;
  int get currentDiceValue => _gameState.lastDiceValue ?? 0;
  List<Piece> get allBoardPieces =>
      _gameState.players.expand((p) => p.pieces).toList();
  Player getPlayerMeta(PlayerColor color) =>
      _gameState.players.firstWhere((p) => p.color == color);

  void startNewGame(List<Player> playersFromUI) {
    // Just use the players directly
    _gameState = GameState(
      players: playersFromUI,
      currentTurnPlayerId: playersFromUI.first.color,
      startIndices: LudoGame.startFields,
    );
    print('startNewGame called with ${playersFromUI.length} players');
    print('Current player after startNewGame: ${_gameState.currentTurnPlayerId}');
    notifyListeners();
    unawaited(nextTurn());
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
