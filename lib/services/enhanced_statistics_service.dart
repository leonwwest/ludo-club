import 'package:ludo_club/services/database_service.dart';
import 'package:ludo_club/models/database_models.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/services/ai_service.dart';
import 'package:uuid/uuid.dart';

class EnhancedStatisticsService {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  // Initialize predefined achievements
  static final List<Achievement> _predefinedAchievements = [
    Achievement(
      id: 'first_win',
      title: 'First Victory',
      description: 'Win your first game',
      iconUrl: 'assets/achievements/first_win.png',
      type: AchievementType.wins,
      criteria: {'wins': 1},
      points: 10,
    ),
    Achievement(
      id: 'hat_trick',
      title: 'Hat Trick',
      description: 'Win 3 games in a row',
      iconUrl: 'assets/achievements/hat_trick.png',
      type: AchievementType.wins,
      criteria: {'win_streak': 3},
      points: 25,
    ),
    Achievement(
      id: 'century',
      title: 'Century',
      description: 'Play 100 games',
      iconUrl: 'assets/achievements/century.png',
      type: AchievementType.games,
      criteria: {'games_played': 100},
      points: 50,
    ),
    Achievement(
      id: 'token_master',
      title: 'Token Master',
      description: 'Get 100 tokens home',
      iconUrl: 'assets/achievements/token_master.png',
      type: AchievementType.tokens,
      criteria: {'tokens_home': 100},
      points: 30,
    ),
    Achievement(
      id: 'hunter',
      title: 'Hunter',
      description: 'Capture 50 opponent tokens',
      iconUrl: 'assets/achievements/hunter.png',
      type: AchievementType.captures,
      criteria: {'captures': 50},
      points: 40,
    ),
    Achievement(
      id: 'lucky_roller',
      title: 'Lucky Roller',
      description: 'Roll 100 sixes',
      iconUrl: 'assets/achievements/lucky_roller.png',
      type: AchievementType.special,
      criteria: {'sixes': 100},
      points: 35,
    ),
    Achievement(
      id: 'ai_slayer',
      title: 'AI Slayer',
      description: 'Beat AI on Expert difficulty',
      iconUrl: 'assets/achievements/ai_slayer.png',
      type: AchievementType.special,
      criteria: {'ai_expert_wins': 1},
      points: 75,
    ),
  ];

  // Record a completed game and update all statistics
  Future<void> recordGameResult({
    required GameState finalGameState,
    required Duration gameDuration,
    required Map<String, List<int>> playerRolls,
    required Map<String, int> captures,
    required String gameType,
    bool isOnlineGame = false,
  }) async {
    final gameId = _uuid.v4();
    final endTime = DateTime.now();
    final startTime = endTime.subtract(gameDuration);

    // Calculate final scores (tokens reached home)
    final Map<String, int> finalScores = {};
    for (final player in finalGameState.players) {
      // Count tokens that actually reached the goal according to core logic
      final tokensHome = player.pieces.where((piece) => piece.isSafe).length;
      finalScores[player.id] = tokensHome;
    }

    // Calculate rolls per player
    final Map<String, int> rollsPerPlayer = {};
    final Map<String, double> averageRollPerPlayer = {};
    for (final playerId in playerRolls.keys) {
      final rolls = playerRolls[playerId]!;
      rollsPerPlayer[playerId] = rolls.length;
      averageRollPerPlayer[playerId] = rolls.isNotEmpty ? 
          rolls.reduce((a, b) => a + b) / rolls.length : 0.0;
    }

    // Create game history record
    final gameHistory = GameHistory(
      id: gameId,
      gameType: gameType,
      playerIds: finalGameState.players.map((p) => p.id).toList(),
      playerNames: finalGameState.players.map((p) => p.name).toList(),
      winnerId: finalGameState.winner?.id,
      winnerName: finalGameState.winner?.name,
      gameDuration: gameDuration,
      startTime: startTime,
      endTime: endTime,
      finalScores: finalScores,
      capturesPerPlayer: captures,
      rollsPerPlayer: rollsPerPlayer,
      averageRollPerPlayer: averageRollPerPlayer,
      totalTurns: playerRolls.values.fold(0, (sum, rolls) => sum + rolls.length),
      wasOnline: isOnlineGame,
    );

    // Save game history
    await _db.saveGameHistory(gameHistory);

    // Update player statistics
    await _db.updatePlayerStatsAfterGame(
      gameHistory: gameHistory,
      playerRolls: playerRolls,
    );

    // Check for achievements for each player
    for (final player in finalGameState.players) {
      if (player.type == PlayerType.human) {
        await _checkAndUnlockAchievements(player.id, finalGameState, gameHistory);
      }
    }
  }

  // Check and unlock achievements for a player
  Future<void> _checkAndUnlockAchievements(
    String playerId, 
    GameState gameState, 
    GameHistory gameHistory
  ) async {
    final stats = await _db.getPlayerStats(playerId);
    if (stats == null) return;

    final currentAchievements = await _db.getUserAchievements(playerId);
    final unlockedAchievementIds = currentAchievements
        .where((a) => a.isUnlocked)
        .map((a) => a.id)
        .toSet();

    for (final achievement in _predefinedAchievements) {
      if (unlockedAchievementIds.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.id) {
        case 'first_win':
          shouldUnlock = stats.gamesWon >= 1;
          break;
        case 'hat_trick':
          shouldUnlock = stats.currentWinStreak >= 3;
          break;
        case 'century':
          shouldUnlock = stats.gamesPlayed >= 100;
          break;
        case 'token_master':
          shouldUnlock = stats.tokensReachedHome >= 100;
          break;
        case 'hunter':
          shouldUnlock = stats.opponentsCaptured >= 50;
          break;
        case 'lucky_roller':
          shouldUnlock = stats.sixesRolled >= 100;
          break;
        case 'ai_slayer':
          // Check if player beat AI on expert difficulty
          final wasWinner = gameHistory.winnerId == playerId;
          final playedAgainstExpertAI = gameState.players.any((p) => 
              p.type == PlayerType.ai && 
              p.aiDifficulty == AIDifficulty.expert);
          shouldUnlock = wasWinner && playedAgainstExpertAI;
          break;
      }

      if (shouldUnlock) {
        final unlockedAchievement = Achievement(
          id: achievement.id,
          title: achievement.title,
          description: achievement.description,
          iconUrl: achievement.iconUrl,
          type: achievement.type,
          criteria: achievement.criteria,
          points: achievement.points,
          unlockedAt: DateTime.now(),
        );
        await _db.unlockAchievement(unlockedAchievement);
      }
    }
  }

  // Get comprehensive player statistics
  Future<EnhancedPlayerStats?> getPlayerStats(String playerId) async {
    return await _db.getPlayerStats(playerId);
  }

  // Get all players' statistics
  Future<List<EnhancedPlayerStats>> getAllPlayerStats() async {
    return await _db.getAllPlayerStats();
  }

  // Get leaderboard data
  Future<List<EnhancedPlayerStats>> getLeaderboard({
    LeaderboardType type = LeaderboardType.wins,
    int limit = 10,
  }) async {
    String sortColumn;
    switch (type) {
      case LeaderboardType.wins:
        sortColumn = 'games_won';
        break;
      case LeaderboardType.winRate:
        sortColumn = 'games_won'; // We'll calculate win rate on client side
        break;
      case LeaderboardType.captures:
        sortColumn = 'opponents_captured';
        break;
      case LeaderboardType.tokensHome:
        sortColumn = 'tokens_reached_home';
        break;
      case LeaderboardType.playTime:
        sortColumn = 'total_play_time';
        break;
    }

    final leaderboard = await _db.getLeaderboard(sortBy: sortColumn, limit: limit);
    
    // If sorting by win rate, sort the results properly
    if (type == LeaderboardType.winRate) {
      leaderboard.sort((a, b) => b.winRate.compareTo(a.winRate));
    }

    return leaderboard;
  }

  // Get game history
  Future<List<GameHistory>> getGameHistory({
    String? playerId,
    String? gameType,
    int? limit,
  }) async {
    return await _db.getGameHistory(
      playerId: playerId,
      gameType: gameType,
      limit: limit,
    );
  }

  // Get player achievements
  Future<List<Achievement>> getPlayerAchievements(String playerId) async {
    return await _db.getUserAchievements(playerId);
  }

  // Get dashboard data for a player
  Future<PlayerDashboardData> getDashboardData(String playerId) async {
    final dashboardData = await _db.getDashboardData(playerId);
    
    return PlayerDashboardData(
      stats: dashboardData['stats'] as EnhancedPlayerStats?,
      recentGames: dashboardData['recentGames'] as List<GameHistory>,
      achievements: dashboardData['achievements'] as List<Achievement>,
      savedGameCount: (dashboardData['savedGames'] as List).length,
      unlockedAchievementCount: dashboardData['totalAchievements'] as int,
    );
  }

  // Calculate advanced statistics
  Future<AdvancedStats> getAdvancedStats(String playerId) async {
    final stats = await getPlayerStats(playerId);
    final gameHistory = await getGameHistory(playerId: playerId);
    
    if (stats == null) {
      return AdvancedStats.empty();
    }

    // Calculate advanced metrics
    final bestWinStreak = stats.longestWinStreak;
    final averageGameDuration = gameHistory.isNotEmpty ? 
        gameHistory.map((g) => g.gameDuration.inMinutes).reduce((a, b) => a + b) / gameHistory.length : 0.0;
    
    final gameTypeStats = <String, int>{};
    for (final game in gameHistory) {
      gameTypeStats[game.gameType] = (gameTypeStats[game.gameType] ?? 0) + 1;
    }

    final favoriteGameType = gameTypeStats.isNotEmpty ? 
        gameTypeStats.entries.reduce((a, b) => a.value > b.value ? a : b).key : '';

    final monthlyGames = <String, int>{};
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyGames[monthKey] = gameHistory.where((game) => 
          game.startTime.year == month.year && 
          game.startTime.month == month.month).length;
    }

    return AdvancedStats(
      winRate: stats.winRate,
      averageTokensPerGame: stats.gamesPlayed > 0 ? 
          stats.tokensReachedHome / stats.gamesPlayed : 0.0,
      captureRatio: stats.captureRatio,
      averageRollValue: stats.averageRollValue,
      bestWinStreak: bestWinStreak,
      averageGameDuration: averageGameDuration,
      favoriteGameType: favoriteGameType,
      gamesPerMonth: monthlyGames,
      sixesPercentage: stats.totalRolls > 0 ? 
          (stats.sixesRolled / stats.totalRolls) * 100 : 0.0,
    );
  }

  // Clear all statistics (for testing or reset purposes)
  Future<void> clearAllStats() async {
    // This would require implementing in DatabaseService
    // For now, just clear the current player's stats
  }

  // Sync with cloud
  Future<void> syncWithCloud() async {
    await _db.syncWithFirebase();
  }

  Future<void> syncFromCloud() async {
    await _db.syncFromFirebase();
  }
}

// Supporting data classes
enum LeaderboardType {
  wins,
  winRate,
  captures,
  tokensHome,
  playTime,
}

class PlayerDashboardData {
  final EnhancedPlayerStats? stats;
  final List<GameHistory> recentGames;
  final List<Achievement> achievements;
  final int savedGameCount;
  final int unlockedAchievementCount;

  PlayerDashboardData({
    this.stats,
    required this.recentGames,
    required this.achievements,
    required this.savedGameCount,
    required this.unlockedAchievementCount,
  });
}

class AdvancedStats {
  final double winRate;
  final double averageTokensPerGame;
  final double captureRatio;
  final double averageRollValue;
  final int bestWinStreak;
  final double averageGameDuration;
  final String favoriteGameType;
  final Map<String, int> gamesPerMonth;
  final double sixesPercentage;

  AdvancedStats({
    required this.winRate,
    required this.averageTokensPerGame,
    required this.captureRatio,
    required this.averageRollValue,
    required this.bestWinStreak,
    required this.averageGameDuration,
    required this.favoriteGameType,
    required this.gamesPerMonth,
    required this.sixesPercentage,
  });

  factory AdvancedStats.empty() {
    return AdvancedStats(
      winRate: 0.0,
      averageTokensPerGame: 0.0,
      captureRatio: 0.0,
      averageRollValue: 0.0,
      bestWinStreak: 0,
      averageGameDuration: 0.0,
      favoriteGameType: '',
      gamesPerMonth: {},
      sixesPercentage: 0.0,
    );
  }
} 
