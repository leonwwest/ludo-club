import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';

class GameService {
  GameState? _currentGameState;

  GameState? get currentGameState => _currentGameState;

  GameState createNewGame(List<Player> players) {
    _currentGameState = GameState(
      players: players,
      currentTurnPlayerId: players.first.color,
      startIndices: LudoGame.startFields,
    );
    return _currentGameState!;
  }

  GameState rollDice(GameState state) {
    final diceValue = DateTime.now().millisecond % 6 + 1;
    return state.copyWith(
      lastDiceValue: diceValue,
      currentRollCount: state.currentRollCount + 1,
    );
  }

  MoveResult movePiece(GameState state, Piece piece) {
    return LudoGame.movePiece(state, piece);
  }

  List<Piece> getMovablePieces(GameState state) {
    return LudoGame.getMovablePieces(state);
  }

  GameState advanceToNextPlayer(GameState state) {
    final playerColors = state.players.map((p) => p.color).toList();
    final currentPlayerIndex = playerColors.indexOf(state.currentTurnPlayerId);
    final nextPlayerIndex = (currentPlayerIndex + 1) % playerColors.length;
    
    return state.copyWith(
      currentTurnPlayerId: playerColors[nextPlayerIndex],
      lastDiceValue: 0,
      currentRollCount: 0,
    );
  }

  bool checkWinCondition(GameState state) {
    return state.winnerId != null;
  }
} 