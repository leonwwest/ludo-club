import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/services/save_load_service.dart';
import 'package:ludo_club/services/audio_service.dart';
import 'package:ludo_club/services/statistics_service.dart';

class GameProvider extends ChangeNotifier {
  late GameState _gameState;
  late LudoGame _ludoGame;
  final SaveLoadService _saveLoadService;
  final AudioService _audioService;
  final StatisticsService _statisticsService;
  bool isAnimating = false;

  bool _showCaptureEffect = false;
  int? _captureEffectBoardIndex;

  bool _showReachedHomeEffect = false;
  PlayerColor? _reachedHomePlayerId;
  int? _reachedHomeTokenIndex;

  GameProvider({
    SaveLoadService? saveLoadService,
    AudioService? audioService,
    StatisticsService? statisticsService,
  })  : _saveLoadService = saveLoadService ?? SaveLoadService(),
        _audioService = audioService ?? AudioService(),
        _statisticsService = statisticsService ?? StatisticsService() {
    _ludoGame = LudoGame(playerColors: PlayerColor.values.toList());
    _gameState = GameState(
      players: PlayerColor.values
          .map((c) => Player(
              id: c.toString(),
              name: c.toString().split('.').last,
              color: c,
              pieces: List.generate(4, (i) => Piece(c, i, const PiecePosition(GameState.basePosition)))))
          .toList(),
      currentTurnPlayerId: _ludoGame.currentTurn,
      startIndices: LudoGame.startFields,
    );
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioService.init();
  }

  GameState get gameState => _gameState;
  bool get showCaptureEffect => _showCaptureEffect;
  int? get captureEffectBoardIndex => _captureEffectBoardIndex;
  bool get showReachedHomeEffect => _showReachedHomeEffect;
  PlayerColor? get reachedHomePlayerId => _reachedHomePlayerId;
  int? get reachedHomeTokenIndex => _reachedHomeTokenIndex;

  void clearCaptureEffect() {
    _showCaptureEffect = false;
    _captureEffectBoardIndex = null;
  }

  void clearReachedHomeEffect() {
    _showReachedHomeEffect = false;
    _reachedHomePlayerId = null;
    _reachedHomeTokenIndex = null;
  }

  Future<int> rollDice() async {
    if (isAnimating) return 0;

    isAnimating = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    await _audioService.playDiceSound();

    final result = _ludoGame.rollDice();
    _gameState.lastDiceValue = _ludoGame.diceValue;
    _gameState.currentTurnPlayerId = _ludoGame.currentTurn;

    isAnimating = false;

    if (result == 6) {
      await _statisticsService.incrementSixesRolled(_gameState.players
          .firstWhere((p) => p.color == _ludoGame.currentTurn)
          .name);
    }
    notifyListeners();

    _handlePotentialAIMove();

    return result;
  }

  Future<void> movePiece(Piece pieceToMove) async {
    if (isAnimating) return;

    isAnimating = true;

    final movingPlayerColor = _ludoGame.currentTurn;
    final movingPlayerMeta = getPlayerMeta(movingPlayerColor);

    final opponentPiecesBeforeMove = _ludoGame.pieces.values
        .expand((list) => list)
        .where((p) => p.color != movingPlayerColor)
        .map((p) => Piece(p.color, p.id, p.position, isSafe: p.isSafe))
        .toList();

    final bool moveSuccessful = _ludoGame.movePiece(pieceToMove);

    if (!moveSuccessful) {
      isAnimating = false;
      return;
    }

    _gameState.lastDiceValue = _ludoGame.diceValue;
    _gameState.currentTurnPlayerId = _ludoGame.currentTurn;

    bool captureOccurred = false;
    for (var oldOpponentPiece in opponentPiecesBeforeMove) {
      final newOpponentPiece = _ludoGame.pieces[oldOpponentPiece.color]!
          .firstWhere((p) => p.id == oldOpponentPiece.id);

      if (newOpponentPiece.position.isHome &&
          !oldOpponentPiece.position.isHome) {
        captureOccurred = true;
        _showCaptureEffect = true;

        _captureEffectBoardIndex = pieceToMove.position.fieldId;

        await _audioService.playCaptureSound();
        final Player capturedPlayerMeta = getPlayerMeta(newOpponentPiece.color);
        await _statisticsService.incrementPawnsCaptured(movingPlayerMeta.name);
        await _statisticsService.incrementPawnsLost(capturedPlayerMeta.name);
        break;
      }
    }

    if (pieceToMove.isSafe) {
      _showReachedHomeEffect = true;
      _reachedHomePlayerId = pieceToMove.color;
      _reachedHomeTokenIndex = pieceToMove.id;

      await _audioService.playFinishSound();

      final didWin =
          _ludoGame.pieces[movingPlayerColor]!.every((p) => p.isSafe);

      if (didWin) {
        _gameState.winnerId = movingPlayerColor;
        await _audioService.playVictorySound();
        await _statisticsService.incrementGamesWon(movingPlayerMeta.name);
      }
    } else if (!captureOccurred) {
      await _audioService.playMoveSound();
    }

    notifyListeners();
    _handlePotentialAIMove();
  }

  List<Piece> getMovablePieces() {
    if (_ludoGame.diceValue == 0) return [];
    return _ludoGame.getMovablePieces();
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

  PlayerColor get currentPlayerColor => _ludoGame.currentTurn;
  int get currentDiceValue => _ludoGame.diceValue;
  List<Piece> get allBoardPieces =>
      _ludoGame.pieces.values.expand((list) => list).toList();
  Player getPlayerMeta(PlayerColor color) =>
      _gameState.players.firstWhere((p) => p.color == color,
          orElse: () => Player(
              id: 'unknown',
              name: 'Unknown Player',
              isAI: true,
              color: color,
              pieces: []));

  void startNewGame(List<Player> playersFromUI) {
    _ludoGame = LudoGame(
        playerColors: playersFromUI.map((p) => p.color).toList());
    _gameState.players = playersFromUI;
    _gameState.currentTurnPlayerId = _ludoGame.currentTurn;
    _gameState.winnerId = null;
    _gameState.lastDiceValue = 0;
    _gameState.currentRollCount = 0;

    final playerNames = playersFromUI.map((p) => p.name).toList();
    _statisticsService.recordGamePlayed(playerNames).catchError((e) {
      debugPrint("Error recording game played stats: $e");
    });

    notifyListeners();
  }

  Future<bool> saveGame({String? customName}) async {
    return await _saveLoadService.saveGame(_gameState, customName: customName);
  }

  Future<bool> loadGame(int index) async {
    final loadedState = await _saveLoadService.loadGame(index);
    if (loadedState != null) {
      _gameState = loadedState;
      _ludoGame = LudoGame(
          playerColors: _gameState.players.map((p) => p.color).toList());
      _gameState.currentTurnPlayerId = _ludoGame.currentTurn;
      _gameState.lastDiceValue = _ludoGame.diceValue;

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteGame(int index) async {
    final result = await _saveLoadService.deleteGame(index);
    if (result) {
      notifyListeners();
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getSavedGames() async {
    return await _saveLoadService.getSavedGames();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  void _handlePotentialAIMove() {
    if (_gameState.isCurrentPlayerAI && !_gameState.isGameOver) {
      Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)),
          () {
        if (_gameState.isCurrentPlayerAI &&
            !_gameState.isGameOver &&
            !isAnimating) {
          final movablePieces = getMovablePieces();
          if (movablePieces.isNotEmpty) {
            movePiece(movablePieces.first);
          }
          notifyListeners();
          _handlePotentialAIMove();
        }
      });
    }
  }
}