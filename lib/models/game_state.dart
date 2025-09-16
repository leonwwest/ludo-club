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
  final List<Piece> pieces;
  final AIDifficulty? aiDifficulty; // Add AI difficulty level

  Player({
    required this.id,
    required this.name,
    this.type = PlayerType.human,
    required this.color,
    required List<Piece> pieces,
    this.aiDifficulty, // Optional AI difficulty
  }) : pieces = List.unmodifiable(pieces);

  bool get isAI => type == PlayerType.ai;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'color': color.name,
      'pieces': pieces.map((p) => p.toJson()).toList(),
      'aiDifficulty': aiDifficulty?.name,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _parseEnumSafe(json['type'], PlayerType.values, PlayerType.human),
      color: _parseEnumSafe(json['color'], PlayerColor.values, PlayerColor.red),
      pieces: (json['pieces'] as List<dynamic>).map((p) {
        if (p is Map<String, dynamic>) {
          return Piece.fromJson(p);
        }
        // Legacy fallback: comma-separated string format
        return Piece.fromString(p.toString());
      }).toList(),
      aiDifficulty: json['aiDifficulty'] != null
          ? _parseEnumSafe(
              json['aiDifficulty'], AIDifficulty.values, AIDifficulty.beginner)
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
    required List<Player> players,
    required this.currentTurnPlayerId,
    this.lastDiceValue,
    this.currentRollCount = 0,
    this.winnerId,
    this.gameId,
    required Map<PlayerColor, int> startIndices,
    this.phase = GamePhase.waitingForRoll,
    this.rules = GameRules.standard,
  })  : players = List.unmodifiable(players),
        startIndices = Map.unmodifiable(startIndices);

  bool isSafeField(int position) {
    return GameConstants.safeMainPathFields.contains(position);
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
      'currentTurnPlayerId': currentTurnPlayerId.name,
      'lastDiceValue': lastDiceValue,
      'currentRollCount': currentRollCount,
      'winnerId': winnerId?.name,
      'gameId': gameId,
      'startIndices':
          startIndices.map((key, value) => MapEntry(key.name, value)),
      'phase': phase.name,
      'rules': rules.toJson(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      players: (json['players'] as List<dynamic>)
          .map((playerJson) =>
              Player.fromJson(playerJson as Map<String, dynamic>))
          .toList(),
      currentTurnPlayerId: _parseEnumSafe(
          json['currentTurnPlayerId'], PlayerColor.values, PlayerColor.red),
      lastDiceValue: json['lastDiceValue'] as int?,
      currentRollCount: json['currentRollCount'] as int,
      winnerId: json['winnerId'] == null
          ? null
          : _parseEnumSafe(
              json['winnerId'], PlayerColor.values, PlayerColor.red),
      gameId: json['gameId'] as String?,
      startIndices:
          (json['startIndices'] as Map<String, dynamic>).map((key, value) {
        final color = _parseEnumSafe(key, PlayerColor.values, PlayerColor.red);
        return MapEntry(color, value as int);
      }),
      phase: _parseEnumSafe(
          json['phase'], GamePhase.values, GamePhase.waitingForRoll),
      rules: json['rules'] != null
          ? GameRules.fromJson(json['rules'] as Map<String, dynamic>)
          : GameRules.standard,
    );
  }
}

// Helper to parse enum by .name with fallback for legacy toString() values
T _parseEnumSafe<T>(Object? raw, List<T> values, T fallback) {
  if (raw == null) return fallback;
  final s = raw.toString();
  // Preferred: match by .name
  for (final v in values) {
    final name = v.toString().split('.').last; // supports both name and legacy
    if (s == name) return v;
    if (s == v.toString()) return v; // legacy support
  }
  try {
    // If the enum type supports byName, attempt it (when T is known)
    // Fallback already handled above
  } catch (_) {}
  return fallback;
}
