import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// Temporarily commented out due to Firebase dependency issues
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:ludo_club/models/database_models.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:uuid/uuid.dart';
import 'package:ludo_club/constants/game_constants.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  // Temporarily commented out Firebase components
  // static FirebaseFirestore? _firestore;
  // static FirebaseAuth? _auth;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  // Initialize the database service
  Future<void> initialize() async {
    _database = await _initLocalDatabase();
    // Temporarily commented out Firebase initialization
    // _firestore = FirebaseFirestore.instance;
    // _auth = FirebaseAuth.instance;
  }

  // Initialize SQLite database
  Future<Database> _initLocalDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'ludo_club.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  // Create database tables
  Future<void> _createTables(Database db, int version) async {
    // User profiles table
    await db.execute('''
      CREATE TABLE user_profiles (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        email TEXT,
        avatar_url TEXT,
        created_at TEXT NOT NULL,
        last_active TEXT NOT NULL,
        preferences TEXT
      )
    ''');

    // Enhanced player statistics table
    await db.execute('''
      CREATE TABLE player_stats (
        player_id TEXT PRIMARY KEY,
        player_name TEXT NOT NULL,
        games_played INTEGER DEFAULT 0,
        games_won INTEGER DEFAULT 0,
        games_lost INTEGER DEFAULT 0,
        games_drawn INTEGER DEFAULT 0,
        tokens_reached_home INTEGER DEFAULT 0,
        opponents_captured INTEGER DEFAULT 0,
        times_got_captured INTEGER DEFAULT 0,
        average_roll_value REAL DEFAULT 0.0,
        total_rolls INTEGER DEFAULT 0,
        sixes_rolled INTEGER DEFAULT 0,
        longest_win_streak INTEGER DEFAULT 0,
        current_win_streak INTEGER DEFAULT 0,
        total_play_time INTEGER DEFAULT 0,
        last_played TEXT,
        favorite_color INTEGER DEFAULT 0,
        ai_wins TEXT,
        versus_stats TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Game history table
    await db.execute('''
      CREATE TABLE game_history (
        id TEXT PRIMARY KEY,
        game_type TEXT NOT NULL,
        player_ids TEXT NOT NULL,
        player_names TEXT NOT NULL,
        winner_id TEXT,
        winner_name TEXT,
        game_duration INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        final_scores TEXT,
        captures_per_player TEXT,
        rolls_per_player TEXT,
        average_roll_per_player TEXT,
        total_turns INTEGER DEFAULT 0,
        was_online INTEGER DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Achievements table
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_url TEXT NOT NULL,
        type INTEGER NOT NULL,
        criteria TEXT NOT NULL,
        points INTEGER DEFAULT 0,
        unlocked_at TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profiles (id)
      )
    ''');

    // Enhanced saved games table
    await db.execute('''
      CREATE TABLE saved_games (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        thumbnail TEXT,
        timestamp TEXT NOT NULL,
        game_state_json TEXT NOT NULL,
        metadata TEXT,
        is_online_game INTEGER DEFAULT 0,
        lobby_id TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profiles (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_player_stats_name ON player_stats(player_name)');
    await db.execute('CREATE INDEX idx_game_history_type ON game_history(game_type)');
    await db.execute('CREATE INDEX idx_game_history_time ON game_history(start_time)');
    await db.execute('CREATE INDEX idx_achievements_user ON achievements(user_id)');
    await db.execute('CREATE INDEX idx_saved_games_user ON saved_games(user_id)');
  }

  // Handle database upgrades
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database schema migrations here
    if (oldVersion < newVersion) {
      // Add migration logic as needed
    }
  }

  // USER PROFILE OPERATIONS
  Future<UserProfile?> getUserProfile(String userId) async {
    final db = _database!;
    final result = await db.query(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return UserProfile.fromMap(result.first);
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = _database!;
    await db.insert(
      'user_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Firebase sync temporarily disabled due to dependency issues
    // if (_auth?.currentUser != null) {
    //   try {
    //     await _firestore?.collection('users').doc(profile.id).set(profile.toJson());
    //   } catch (e) {
    //     print('Failed to sync user profile to Firebase: $e');
    //   }
    // }
  }

  // PLAYER STATISTICS OPERATIONS
  Future<EnhancedPlayerStats?> getPlayerStats(String playerId) async {
    final db = _database!;
    final result = await db.query(
      'player_stats',
      where: 'player_id = ?',
      whereArgs: [playerId],
    );

    if (result.isNotEmpty) {
      return EnhancedPlayerStats.fromMap(result.first);
    }
    return null;
  }

  Future<List<EnhancedPlayerStats>> getAllPlayerStats() async {
    final db = _database!;
    final result = await db.query('player_stats', orderBy: 'games_won DESC');
    return result.map((map) => EnhancedPlayerStats.fromMap(map)).toList();
  }

  Future<void> savePlayerStats(EnhancedPlayerStats stats) async {
    final db = _database!;
    final statsMap = stats.toMap();
    statsMap['updated_at'] = DateTime.now().toIso8601String();
    
    await db.insert(
      'player_stats',
      statsMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Firebase sync temporarily disabled due to dependency issues
    // if (_auth?.currentUser != null) {
    //   try {
    //     await _firestore?.collection('player_stats').doc(stats.playerId).set(statsMap);
    //   } catch (e) {
    //     print('Failed to sync player stats to Firebase: $e');
    //   }
    // }
  }

  Future<void> updatePlayerStatsAfterGame({
    required GameHistory gameHistory,
    required Map<String, List<int>> playerRolls,
  }) async {
    for (final playerId in gameHistory.playerIds) {
      final currentStats = await getPlayerStats(playerId) ?? 
          EnhancedPlayerStats(playerId: playerId, playerName: playerId);

      final rolls = playerRolls[playerId] ?? [];
      final rollSum = rolls.fold<int>(0, (total, roll) => total + roll);
      final rollCount = rolls.length;
      final sixCount = rolls.where((roll) => roll == GameConstants.requiredRollToLeaveBase).length;

      final updatedStats = EnhancedPlayerStats(
        playerId: currentStats.playerId,
        playerName: currentStats.playerName,
        gamesPlayed: currentStats.gamesPlayed + 1,
        gamesWon: gameHistory.winnerId == playerId ? 
            currentStats.gamesWon + 1 : currentStats.gamesWon,
        gamesLost: gameHistory.winnerId != null && gameHistory.winnerId != playerId ? 
            currentStats.gamesLost + 1 : currentStats.gamesLost,
        tokensReachedHome: currentStats.tokensReachedHome + 
            (gameHistory.finalScores[playerId] ?? 0),
        opponentsCaptured: currentStats.opponentsCaptured + 
            (gameHistory.capturesPerPlayer[playerId] ?? 0),
        totalRolls: currentStats.totalRolls + rollCount,
        sixesRolled: currentStats.sixesRolled + sixCount,
        averageRollValue: rollCount > 0 ? 
            (currentStats.averageRollValue * currentStats.totalRolls + rollSum) / 
            (currentStats.totalRolls + rollCount) : currentStats.averageRollValue,
        totalPlayTime: currentStats.totalPlayTime + gameHistory.gameDuration,
        lastPlayed: gameHistory.endTime,
        currentWinStreak: gameHistory.winnerId == playerId ? 
            currentStats.currentWinStreak + 1 : 0,
        longestWinStreak: gameHistory.winnerId == playerId ? 
            (currentStats.currentWinStreak + 1 > currentStats.longestWinStreak ? 
                currentStats.currentWinStreak + 1 : currentStats.longestWinStreak) : 
            currentStats.longestWinStreak,
      );

      await savePlayerStats(updatedStats);
    }
  }

  // GAME HISTORY OPERATIONS
  Future<void> saveGameHistory(GameHistory history) async {
    final db = _database!;
    await db.insert(
      'game_history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Firebase sync temporarily disabled due to dependency issues
    // if (_auth?.currentUser != null) {
    //   try {
    //     await _firestore?.collection('game_history').doc(history.id).set(history.toMap());
    //   } catch (e) {
    //     print('Failed to sync game history to Firebase: $e');
    //   }
    // }
  }

  Future<List<GameHistory>> getGameHistory({
    String? playerId,
    String? gameType,
    int? limit,
  }) async {
    final db = _database!;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (playerId != null) {
      whereClause = 'player_ids LIKE ?';
      whereArgs.add('%$playerId%');
    }

    if (gameType != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'game_type = ?';
      whereArgs.add(gameType);
    }

    final result = await db.query(
      'game_history',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'start_time DESC',
      limit: limit,
    );

    return result.map((map) => GameHistory.fromMap(map)).toList();
  }

  // SAVED GAMES OPERATIONS
  Future<void> saveGame(EnhancedSavedGame savedGame) async {
    final db = _database!;
    await db.insert(
      'saved_games',
      savedGame.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Firebase sync temporarily disabled due to dependency issues
    // if (_auth?.currentUser != null) {
    //   try {
    //     await _firestore?.collection('saved_games').doc(savedGame.id).set(savedGame.toMap());
    //   } catch (e) {
    //     print('Failed to sync saved game to Firebase: $e');
    //   }
    // }
  }

  Future<List<EnhancedSavedGame>> getSavedGames(String userId) async {
    final db = _database!;
    final result = await db.query(
      'saved_games',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => EnhancedSavedGame.fromMap(map)).toList();
  }

  Future<void> deleteSavedGame(String gameId) async {
    final db = _database!;
    await db.delete(
      'saved_games',
      where: 'id = ?',
      whereArgs: [gameId],
    );

    // Delete from Firebase
    // Firebase sync temporarily disabled due to dependency issues
    // if (_auth?.currentUser != null) {
    //   try {
    //     await _firestore?.collection('saved_games').doc(gameId).delete();
    //   } catch (e) {
    //     print('Failed to delete saved game from Firebase: $e');
    //   }
    // }
  }

  // ACHIEVEMENT OPERATIONS
  Future<List<Achievement>> getUserAchievements(String userId) async {
    final db = _database!;
    final result = await db.query(
      'achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'unlocked_at DESC',
    );

    return result.map((map) => Achievement.fromMap(map)).toList();
  }

  Future<void> unlockAchievement(Achievement achievement) async {
    final db = _database!;
    final achievementMap = achievement.toMap();
    achievementMap['unlocked_at'] = DateTime.now().toIso8601String();
    
    await db.insert(
      'achievements',
      achievementMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Firebase sync temporarily disabled due to dependency issues
    // if (_auth?.currentUser != null) {
    //   try {
    //     await _firestore?.collection('achievements').doc(achievement.id).set(achievementMap);
    //   } catch (e) {
    //     print('Failed to sync achievement to Firebase: $e');
    //   }
    // }
  }

  // SYNC OPERATIONS - Temporarily disabled due to Firebase dependency issues
  Future<void> syncWithFirebase() async {
    // Firebase sync temporarily disabled
    print('Firebase sync is currently disabled due to dependency issues');
    return;
    
    // Original Firebase sync code commented out:
    // if (_auth?.currentUser == null) return;
    // try {
    //   final userId = _auth!.currentUser!.uid;
    //   final localStats = await getAllPlayerStats();
    //   for (final stats in localStats) {
    //     await _firestore?.collection('player_stats').doc(stats.playerId).set(stats.toMap());
    //   }
    //   final gameHistory = await getGameHistory(limit: 100);
    //   for (final game in gameHistory) {
    //     await _firestore?.collection('game_history').doc(game.id).set(game.toMap());
    //   }
    //   print('Sync with Firebase completed successfully');
    // } catch (e) {
    //   print('Failed to sync with Firebase: $e');
    // }
  }

  Future<void> syncFromFirebase() async {
    // Firebase sync temporarily disabled
    print('Firebase sync is currently disabled due to dependency issues');
    return;
    
         // Original Firebase sync code commented out:
     // if (_auth?.currentUser == null) return;
     // try {
     //   final userId = _auth!.currentUser!.uid;
     //   final statsSnapshot = await _firestore?.collection('player_stats').get();
     //   if (statsSnapshot?.docs != null) {
     //     for (final doc in statsSnapshot!.docs) {
     //       final stats = EnhancedPlayerStats.fromMap(doc.data());
     //       await savePlayerStats(stats);
     //     }
     //   }
     //   print('Sync from Firebase completed successfully');
     // } catch (e) {
     //   print('Failed to sync from Firebase: $e');
     // }
  }

  // UTILITY METHODS
  Future<Map<String, dynamic>> getDashboardData(String userId) async {
    final stats = await getPlayerStats(userId);
    final recentGames = await getGameHistory(playerId: userId, limit: 5);
    final achievements = await getUserAchievements(userId);
    final savedGames = await getSavedGames(userId);

    return {
      'stats': stats,
      'recentGames': recentGames,
      'achievements': achievements,
      'savedGames': savedGames,
      'totalAchievements': achievements.where((a) => a.isUnlocked).length,
    };
  }

  Future<List<EnhancedPlayerStats>> getLeaderboard({
    String sortBy = 'games_won',
    int limit = 10,
  }) async {
    final db = _database!;
    final result = await db.query(
      'player_stats',
      orderBy: '$sortBy DESC',
      limit: limit,
    );

    return result.map((map) => EnhancedPlayerStats.fromMap(map)).toList();
  }

  // Clean up resources
  Future<void> dispose() async {
    await _database?.close();
  }
} 
