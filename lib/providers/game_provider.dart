import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_phase.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/services/audio_service.dart';
import 'package:ludo_club/services/ai_service.dart';
import 'package:ludo_club/constants/game_constants.dart';

class GameProvider extends ChangeNotifier {

  final AudioService _audioService;
  final AIService _aiService;

  bool isAnimating = false;
  bool _showReachedHomeEffect = false;
  PlayerColor? _reachedHomePlayerId;
  int? _reachedHomeTokenIndex;
  int _consecutiveSixes = 0; // Track consecutive 6s per active player
  
  bool _showCaptureEffect = false;
  PlayerColor? _capturedPlayerId;
  int? _capturedTokenIndex;

  GameProvider({
    AudioService? audioService,
    AIService? aiService,
  })  : _audioService = audioService ?? AudioService(),
        _aiService = aiService ?? AIService() {
    _gameState = _createDefaultGameState();
    _initAudio();
  }

  // Removed unused _createNewGame method

  Future<void> _initAudio() async {
    await _audioService.init();
  }

    late GameState _gameState;
  
  // Performance cache
  List<Piece>? _cachedMovablePieces;
  int? _lastDiceForCache;

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

    // If current player is AI, automatically handle their turn
    if (_gameState.currentPlayer.isAI) {
      await _handleAITurn();
    }
  }

  Future<void> _handleAITurn() async {
    if (_gameState.isGameOver || !_gameState.currentPlayer.isAI) return;

    try {
      // Add a small delay to make AI feel more natural
      await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));
      
      // AI rolls dice
      await rollDice();
      
      // If there are movable pieces, AI makes a move
      if (_gameState.phase == GamePhase.waitingForMove) {
        final aiDecision = await _aiService.makeMove(
          _gameState, 
          _gameState.currentPlayer.aiDifficulty ?? AIDifficulty.beginner
        );
        
        if (aiDecision.selectedPiece != null) {
          await movePiece(aiDecision.selectedPiece!);
        }
      }
    } catch (e) {
      // If AI turn fails, just skip to next player
      _advanceToNextPlayer();
    }
  }

  Future<void> rollDice() async {
    if (_gameState.phase != GamePhase.waitingForRoll) return;

    try {
      _gameState = _gameState.copyWith(phase: GamePhase.animating);
      notifyListeners();

      // Start sound quickly to reduce perceived latency
      unawaited(_audioService.playDiceSound());

      final diceValue = Random().nextInt(GameConstants.diceSides) + 1;
      _gameState = _gameState.copyWith(lastDiceValue: diceValue, currentRollCount: _gameState.currentRollCount + 1);
      notifyListeners(); // Notify immediately so DiceWidget can show correct value

      // Handle 3x6 rule (maxConsecutiveSixes from rules)
      if (diceValue == 6) {
        final limit = _gameState.rules.maxConsecutiveSixes;
        if (_consecutiveSixes + 1 >= limit) {
          // Third 6 does not count, turn ends
          _consecutiveSixes = 0;
          await Future.delayed(const Duration(milliseconds: 200));
          _advanceToNextPlayer();
          return;
        } else {
          _consecutiveSixes += 1;
        }
      } else {
        _consecutiveSixes = 0;
      }

      final moves = LudoGame.getMovablePieces(_gameState);

      if (moves.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 200));
        _advanceToNextPlayer();
      } else {
        _gameState = _gameState.copyWith(phase: GamePhase.waitingForMove);
        notifyListeners();
      }
    } catch (e) {
      // If dice roll fails, reset to waiting for roll
      _gameState = _gameState.copyWith(phase: GamePhase.waitingForRoll);
      notifyListeners();
    }
  }



  Future<void> movePiece(Piece pieceToMove) async {
    if (_gameState.phase != GamePhase.waitingForMove) {
      return;
    }

    // Validate that the piece belongs to the current player
    if (pieceToMove.color != _gameState.currentTurnPlayerId) {
      return;
    }

    // Validate that the piece is in the list of movable pieces
    final movablePieces = getMovablePieces();
    if (!movablePieces.contains(pieceToMove)) {
      return;
    }

    _gameState = _gameState.copyWith(phase: GamePhase.animating);
    notifyListeners();

    final moveResult = LudoGame.movePiece(_gameState, pieceToMove);
    _gameState = moveResult.newState;
    
    // Clear performance cache after move
    _cachedMovablePieces = null;
    _lastDiceForCache = null;

    // Handle captured piece
    if (moveResult.capturedOpponentPiece != null) {
      final captured = moveResult.capturedOpponentPiece!;
      
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
    final rules = _gameState.rules;
    final gotSix = _gameState.lastDiceValue == 6;
    final gotCapture = moveResult.capturedOpponentPiece != null;
    final getExtraTurn = (rules.extraTurnOnSix && gotSix) || (rules.extraTurnOnCapture && gotCapture);
    if (getExtraTurn) {
      nextTurn().catchError((error) {
        // Handle errors gracefully to prevent crashes
      });
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
    _consecutiveSixes = 0; // reset consecutive 6s on player change
    
    // Clear performance cache on player change
    _cachedMovablePieces = null;
    _lastDiceForCache = null;
    
    nextTurn().catchError((error) {
      // Handle errors gracefully to prevent crashes
    });
  }

  List<Piece> getMovablePieces() {
    // Use cache if dice value hasn't changed
    if (_cachedMovablePieces != null && _lastDiceForCache == _gameState.lastDiceValue) {
      return _cachedMovablePieces!;
    }
    
    // Calculate and cache result
    final movablePieces = LudoGame.getMovablePieces(_gameState);
    _cachedMovablePieces = movablePieces;
    _lastDiceForCache = _gameState.lastDiceValue;
    
    return movablePieces;
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
  Player getPlayerMeta(PlayerColor color) {
    try {
      return _gameState.players.firstWhere((p) => p.color == color);
    } catch (e) {
      // Fallback to first player if color not found
      return _gameState.players.first;
    }
  }

  GameState _createDefaultGameState() {
    // Create a minimal default state with 2 players
    final defaultPlayers = [
      Player(
        id: 'player1',
        name: 'Player 1',
        type: PlayerType.human,
        color: PlayerColor.red,
        pieces: List.generate(GameConstants.tokensPerPlayer, (j) => Piece(PlayerColor.red, j, const PiecePosition(GameState.basePosition))),
      ),
      Player(
        id: 'player2', 
        name: 'Player 2',
        type: PlayerType.human,
        color: PlayerColor.green,
        pieces: List.generate(GameConstants.tokensPerPlayer, (j) => Piece(PlayerColor.green, j, const PiecePosition(GameState.basePosition))),
      ),
    ];
    
    return GameState(
      players: defaultPlayers,
      currentTurnPlayerId: PlayerColor.red,
      startIndices: LudoGame.startFields,
    );
  }

  void startNewGame(List<Player> playersFromUI) {
    // Validate input
    if (playersFromUI.isEmpty) {
      return;
    }
    
    if (playersFromUI.length < 2 || playersFromUI.length > 4) {
      return;
    }
    
    // Ensure no duplicate colors
    final colors = playersFromUI.map((p) => p.color).toSet();
    if (colors.length != playersFromUI.length) {
      return;
    }
    
    _gameState = GameState(
      players: playersFromUI,
      currentTurnPlayerId: playersFromUI.first.color,
      startIndices: LudoGame.startFields,
    );
    notifyListeners();
    nextTurn().catchError((error) {
      // Handle errors gracefully to prevent crashes
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
