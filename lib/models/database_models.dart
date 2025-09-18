import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/services/ai_service.dart';

// User Profile Model
class UserProfile {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime lastActive;
  final Map<String, dynamic>? preferences;

  UserProfile({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.lastActive,
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'preferences': preferences,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActive: DateTime.parse(json['lastActive'] as String),
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
      'preferences': preferences?.toString(), // Store as JSON string in SQLite
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastActive: DateTime.parse(map['last_active'] as String),
      preferences: map['preferences'] != null
          ? Map<String, dynamic>.from(map['preferences'])
          : null,
    );
  }
}

// Enhanced Player Statistics Model
class EnhancedPlayerStats {
  final String playerId;
  final String playerName;
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final int gamesDrawn;
  final int tokensReachedHome;
  final int opponentsCaptured;
  final int timesGotCaptured;
  final double averageRollValue;
  final int totalRolls;
  final int sixesRolled;
  final int longestWinStreak;
  final int currentWinStreak;
  final Duration totalPlayTime;
  final DateTime? lastPlayed;
  final int favoriteColor; // Store as int, convert to PlayerColor
  final Map<AIDifficulty, int> aiWins; // Wins against different AI levels
  final Map<String, int> versusStats; // Wins vs specific players

  EnhancedPlayerStats({
    required this.playerId,
    required this.playerName,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.gamesDrawn = 0,
    this.tokensReachedHome = 0,
    this.opponentsCaptured = 0,
    this.timesGotCaptured = 0,
    this.averageRollValue = 0.0,
    this.totalRolls = 0,
    this.sixesRolled = 0,
    this.longestWinStreak = 0,
    this.currentWinStreak = 0,
    this.totalPlayTime = Duration.zero,
    this.lastPlayed,
    this.favoriteColor = 0, // Default to red
    this.aiWins = const {},
    this.versusStats = const {},
  });

  double get winRate => gamesPlayed > 0 ? gamesWon / gamesPlayed : 0.0;
  double get captureRatio => timesGotCaptured > 0
      ? opponentsCaptured / timesGotCaptured
      : opponentsCaptured.toDouble();

  PlayerColor get favoritePlayerColor => PlayerColor.values[favoriteColor];

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'player_name': playerName,
      'games_played': gamesPlayed,
      'games_won': gamesWon,
      'games_lost': gamesLost,
      'games_drawn': gamesDrawn,
      'tokens_reached_home': tokensReachedHome,
      'opponents_captured': opponentsCaptured,
      'times_got_captured': timesGotCaptured,
      'average_roll_value': averageRollValue,
      'total_rolls': totalRolls,
      'sixes_rolled': sixesRolled,
      'longest_win_streak': longestWinStreak,
      'current_win_streak': currentWinStreak,
      'total_play_time': totalPlayTime.inSeconds,
      'last_played': lastPlayed?.toIso8601String(),
      'favorite_color': favoriteColor,
      'ai_wins': aiWins.map((k, v) => MapEntry(k.index, v)).toString(),
      'versus_stats': versusStats.toString(),
    };
  }

  factory EnhancedPlayerStats.fromMap(Map<String, dynamic> map) {
    return EnhancedPlayerStats(
      playerId: map['player_id'] as String,
      playerName: map['player_name'] as String,
      gamesPlayed: map['games_played'] as int,
      gamesWon: map['games_won'] as int,
      gamesLost: map['games_lost'] as int,
      gamesDrawn: map['games_drawn'] as int,
      tokensReachedHome: map['tokens_reached_home'] as int,
      opponentsCaptured: map['opponents_captured'] as int,
      timesGotCaptured: map['times_got_captured'] as int,
      averageRollValue: map['average_roll_value'] as double,
      totalRolls: map['total_rolls'] as int,
      sixesRolled: map['sixes_rolled'] as int,
      longestWinStreak: map['longest_win_streak'] as int,
      currentWinStreak: map['current_win_streak'] as int,
      totalPlayTime: Duration(seconds: map['total_play_time'] as int),
      lastPlayed: map['last_played'] != null
          ? DateTime.parse(map['last_played'] as String)
          : null,
      favoriteColor: map['favorite_color'] as int,
      // Note: In a real implementation, you'd properly parse these JSON strings
      // Defaults for maps are handled by the constructor
    );
  }
}

// Game History Model
class GameHistory {
  final String id;
  final String gameType; // "quick_play", "vs_ai", "multiplayer"
  final List<String> playerIds;
  final List<String> playerNames;
  final String? winnerId;
  final String? winnerName;
  final Duration gameDuration;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, int> finalScores; // tokens home per player
  final Map<String, int> capturesPerPlayer;
  final Map<String, int> rollsPerPlayer;
  final Map<String, double> averageRollPerPlayer;
  final int totalTurns;
  final bool wasOnline;

  GameHistory({
    required this.id,
    required this.gameType,
    required this.playerIds,
    required this.playerNames,
    this.winnerId,
    this.winnerName,
    required this.gameDuration,
    required this.startTime,
    required this.endTime,
    this.finalScores = const {},
    this.capturesPerPlayer = const {},
    this.rollsPerPlayer = const {},
    this.averageRollPerPlayer = const {},
    this.totalTurns = 0,
    this.wasOnline = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_type': gameType,
      'player_ids': playerIds.join(','),
      'player_names': playerNames.join(','),
      'winner_id': winnerId,
      'winner_name': winnerName,
      'game_duration': gameDuration.inSeconds,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'final_scores': finalScores.toString(),
      'captures_per_player': capturesPerPlayer.toString(),
      'rolls_per_player': rollsPerPlayer.toString(),
      'average_roll_per_player': averageRollPerPlayer.toString(),
      'total_turns': totalTurns,
      'was_online': wasOnline ? 1 : 0,
    };
  }

  factory GameHistory.fromMap(Map<String, dynamic> map) {
    return GameHistory(
      id: map['id'] as String,
      gameType: map['game_type'] as String,
      playerIds: (map['player_ids'] as String).split(','),
      playerNames: (map['player_names'] as String).split(','),
      winnerId: map['winner_id'] as String?,
      winnerName: map['winner_name'] as String?,
      gameDuration: Duration(seconds: map['game_duration'] as int),
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      totalTurns: map['total_turns'] as int,
      wasOnline: (map['was_online'] as int) == 1,
      // Note: In a real implementation, you'd properly parse these JSON strings
    );
  }
}

// Achievement Model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final AchievementType type;
  final Map<String, dynamic> criteria;
  final int points;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.criteria,
    this.points = 0,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_url': iconUrl,
      'type': type.index,
      'criteria': criteria.toString(),
      'points': points,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      iconUrl: map['icon_url'] as String,
      type: AchievementType.values[map['type'] as int],
      criteria: const {}, // Would parse JSON string in real implementation
      points: map['points'] as int,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'] as String)
          : null,
    );
  }
}

enum AchievementType {
  games,
  wins,
  captures,
  tokens,
  special,
}

// Enhanced Saved Game Model
class EnhancedSavedGame {
  final String id;
  final String userId;
  final String name;
  final String thumbnail; // Base64 encoded screenshot
  final DateTime timestamp;
  final String gameStateJson;
  final Map<String, dynamic> metadata;
  final bool isOnlineGame;
  final String? lobbyId;

  EnhancedSavedGame({
    required this.id,
    required this.userId,
    required this.name,
    required this.thumbnail,
    required this.timestamp,
    required this.gameStateJson,
    this.metadata = const {},
    this.isOnlineGame = false,
    this.lobbyId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'thumbnail': thumbnail,
      'timestamp': timestamp.toIso8601String(),
      'game_state_json': gameStateJson,
      'metadata': metadata.toString(),
      'is_online_game': isOnlineGame ? 1 : 0,
      'lobby_id': lobbyId,
    };
  }

  factory EnhancedSavedGame.fromMap(Map<String, dynamic> map) {
    return EnhancedSavedGame(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      thumbnail: map['thumbnail'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      gameStateJson: map['game_state_json'] as String,
      // metadata defaults to an empty map
      isOnlineGame: (map['is_online_game'] as int) == 1,
      lobbyId: map['lobby_id'] as String?,
    );
  }
}
