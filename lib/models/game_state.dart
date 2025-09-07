import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/models/game_phase.dart';
import 'package:ludo_club/models/game_rules.dart';
import 'package:ludo_club/services/ai_service.dart';
import 'package:ludo_club/constants/game_constants.dart';

enum PlayerType { human, ai }

class Player {
  final String id;
  final String name;
  final PlayerType type;
  final PlayerColor color;
  List<Piece> pieces;
  final AIDifficulty? aiDifficulty; // Add AI difficulty level

  Player({
    required this.id,
    required this.name,
    this.type = PlayerType.human,
    required this.color,
    required this.pieces,
    this.aiDifficulty, // Optional AI difficulty
  });

  bool get isAI => type == PlayerType.ai;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'color': color.toString(),
      'pieces': pieces.map((p) => p.toString()).toList(),
      'aiDifficulty': aiDifficulty?.toString(),
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PlayerType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => PlayerType.human),
      color: PlayerColor.values.firstWhere(
          (e) => e.toString() == json['color'],
          orElse: () => PlayerColor.red),
      pieces: (json['pieces'] as List<dynamic>)
          .map((p) => Piece.fromString(p.toString()))
          .toList(),
      aiDifficulty: json['aiDifficulty'] != null 
          ? AIDifficulty.values.firstWhere(
              (e) => e.toString() == json['aiDifficulty'],
              orElse: () => AIDifficulty.beginner)
          : null,
    );
  }
}

class GameState {
  final List<Player> players;
  final PlayerColor currentTurnPlayerId;
  final int? lastDiceValue;
  final int currentRollCount;
  final PlayerColor? winnerId;
  final String? gameId;
  final Map<PlayerColor, int> startIndices;
  final GamePhase phase;
  final GameRules rules;

  static const int tokensPerPlayer = GameConstants.tokensPerPlayer;
  static const int basePosition = GameConstants.basePosition;
  static const int totalFields = GameConstants.totalMainPathFields;
  static const int homePathLength = GameConstants.homePathLength;
  static const int finishedPosition = GameConstants.finishedPosition;

  GameState({
    required this.players,
    required this.currentTurnPlayerId,
    this.lastDiceValue,
    this.currentRollCount = 0,
    this.winnerId,
    this.gameId,
    required this.startIndices,
    this.phase = GamePhase.waitingForRoll,
    this.rules = GameRules.standard,
  });

  bool isSafeField(int position) {
    return startIndices.containsValue(position);
  }

  Player get currentPlayer {
    try {
      return players.firstWhere((p) => p.color == currentTurnPlayerId);
    } catch (e) {
      // Fallback to first player if current player not found
      return players.first;
    }
  }

  bool get isCurrentPlayerAI => currentPlayer.isAI;

  Player? get winner {
    if (winnerId == null) return null;
    try {
      return players.firstWhere((p) => p.color == winnerId);
    } catch (e) {
      return null;
    }
  }

  bool get isGameOver => winnerId != null;

  GameState copyWith({
    List<Player>? players,
    PlayerColor? currentTurnPlayerId,
    int? lastDiceValue,
    int? currentRollCount,
    PlayerColor? winnerId,
    String? gameId,
    Map<PlayerColor, int>? startIndices,
    GamePhase? phase,
    GameRules? rules,
  }) {
    return GameState(
      players: players ?? this.players,
      currentTurnPlayerId: currentTurnPlayerId ?? this.currentTurnPlayerId,
      lastDiceValue: lastDiceValue ?? this.lastDiceValue,
      currentRollCount: currentRollCount ?? this.currentRollCount,
      winnerId: winnerId ?? this.winnerId,
      gameId: gameId ?? this.gameId,
      startIndices: startIndices ?? this.startIndices,
      phase: phase ?? this.phase,
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'players': players.map((p) => p.toJson()).toList(),
      'currentTurnPlayerId': currentTurnPlayerId.toString(),
      'lastDiceValue': lastDiceValue,
      'currentRollCount': currentRollCount,
      'winnerId': winnerId?.toString(),
      'gameId': gameId,
      'startIndices': startIndices.map((key, value) => MapEntry(key.toString(), value)),
      'phase': phase.toString(),
      'rules': rules.toJson(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      players: (json['players'] as List<dynamic>)
          .map((playerJson) =>
              Player.fromJson(playerJson as Map<String, dynamic>))
          .toList(),
      currentTurnPlayerId: PlayerColor.values.firstWhere(
          (e) => e.toString() == json['currentTurnPlayerId'],
          orElse: () => PlayerColor.red),
      lastDiceValue: json['lastDiceValue'] as int?,
      currentRollCount: json['currentRollCount'] as int,
      winnerId: json['winnerId'] == null
          ? null
          : PlayerColor.values.firstWhere(
              (e) => e.toString() == json['winnerId'],
              orElse: () => PlayerColor.red),
      gameId: json['gameId'] as String?,
      startIndices: (json['startIndices'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          PlayerColor.values
              .firstWhere((e) => e.toString() == key, orElse: () => PlayerColor.red),
          value as int,
        ),
      ),
      phase: GamePhase.values.firstWhere(
          (e) => e.toString() == json['phase'],
          orElse: () => GamePhase.waitingForRoll),
      rules: json['rules'] != null 
          ? GameRules.fromJson(json['rules'] as Map<String, dynamic>)
          : GameRules.standard,
    );
  }
}
