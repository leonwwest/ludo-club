import 'package:shared_preferences/shared_preferences.dart';
// Temporarily commented out due to Firebase dependency issues
// import 'package:firebase_core/firebase_core.dart';
import 'package:ludo_club/services/database_service.dart';
import 'package:ludo_club/services/statistics_service.dart'; // Old service
import 'package:ludo_club/services/save_load_service.dart'; // Old service
import 'package:ludo_club/models/database_models.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class DatabaseInitializationService {
  static const String _migrationVersionKey = 'db_migration_version';
  static const int _currentMigrationVersion = 1;
  
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  // Initialize the entire database system
  Future<bool> initializeDatabase() async {
    try {
      // Initialize Firebase - temporarily disabled due to dependency issues
      // await Firebase.initializeApp();
      
      // Initialize local database
      await _db.initialize();
      
      // Check if migration is needed
      final prefs = await SharedPreferences.getInstance();
      final migrationVersion = prefs.getInt(_migrationVersionKey) ?? 0;
      
      if (migrationVersion < _currentMigrationVersion) {
        await _performMigration(migrationVersion);
        await prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
      }
      
      // Create default user profile if none exists
      await _createDefaultUserProfile();
      
      return true;
    } catch (e) {
      print('Failed to initialize database: $e');
      return false;
    }
  }

  // Perform migration from old SharedPreferences system
  Future<void> _performMigration(int fromVersion) async {
    print('Performing database migration from version $fromVersion');
    
    if (fromVersion == 0) {
      // Initial migration from SharedPreferences
      await _migrateFromSharedPreferences();
    }
    
    // Add more migration steps here for future versions
  }

  // Migrate data from the old SharedPreferences system
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Migrate old player statistics
      await _migratePlayerStatistics(prefs);
      
      // Migrate old saved games
      await _migrateSavedGames(prefs);
      
      print('Migration from SharedPreferences completed successfully');
    } catch (e) {
      print('Error during migration: $e');
      // Don't throw - we want the app to continue working even if migration fails
    }
  }

  // Migrate old player statistics to new format
  Future<void> _migratePlayerStatistics(SharedPreferences prefs) async {
    try {
      // Get old statistics using the old service method
      final jsonString = prefs.getString('player_stats_list');
      if (jsonString == null) return;
      
      final decoded = json.decode(jsonString);
      if (decoded is! List) return;
      
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final oldStats = PlayerStats.fromJson(item);
          
          // Convert to new enhanced format
          final enhancedStats = EnhancedPlayerStats(
            playerId: _uuid.v4(), // Generate new ID
            playerName: oldStats.playerName,
            gamesPlayed: oldStats.gamesPlayed,
            gamesWon: oldStats.gamesWon,
            gamesLost: oldStats.gamesPlayed - oldStats.gamesWon,
            tokensReachedHome: oldStats.tokensReachedHome,
            opponentsCaptured: oldStats.opponentsCaptured,
            // Set defaults for new fields
            averageRollValue: 3.5, // Default dice average
            totalRolls: oldStats.gamesPlayed * 20, // Estimate
            sixesRolled: (oldStats.gamesPlayed * 20 / 6).round(), // Estimate
            lastPlayed: DateTime.now().subtract(const Duration(days: 30)), // Estimate
          );
          
          await _db.savePlayerStats(enhancedStats);
        }
      }
      
      print('Migrated ${decoded.length} player statistics records');
    } catch (e) {
      print('Error migrating player statistics: $e');
    }
  }

  // Migrate old saved games to new format
  Future<void> _migrateSavedGames(SharedPreferences prefs) async {
    try {
      final jsonString = prefs.getString('saved_games');
      if (jsonString == null) return;
      
      final decoded = json.decode(jsonString);
      if (decoded is! List) return;
      
      final defaultUserId = await _getOrCreateDefaultUserId();
      
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          // Parse old saved game format
          final oldSavedGame = SavedGame.fromJson(item);
          
          // Convert to new enhanced format
          final enhancedSavedGame = EnhancedSavedGame(
            id: oldSavedGame.id,
            userId: defaultUserId,
            name: oldSavedGame.name,
            thumbnail: '', // No thumbnail in old format
            timestamp: oldSavedGame.timestamp,
            gameStateJson: json.encode(oldSavedGame.gameState.toJson()),
            metadata: _generateLegacyMetadata(oldSavedGame.gameState),
            isOnlineGame: false, // Old games were local only
          );
          
          await _db.saveGame(enhancedSavedGame);
        }
      }
      
      print('Migrated ${decoded.length} saved games');
    } catch (e) {
      print('Error migrating saved games: $e');
    }
  }

  // Create or get default user profile
  Future<void> _createDefaultUserProfile() async {
    const defaultUserId = 'default_user';
    
    final existingProfile = await _db.getUserProfile(defaultUserId);
    if (existingProfile == null) {
      final defaultProfile = UserProfile(
        id: defaultUserId,
        username: 'Player',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        preferences: {
          'soundEnabled': true,
          'musicEnabled': true,
          'animationsEnabled': true,
          'theme': 'default',
        },
      );
      
      await _db.saveUserProfile(defaultProfile);
      print('Created default user profile');
    }
  }

  // Get or create default user ID
  Future<String> _getOrCreateDefaultUserId() async {
    const defaultUserId = 'default_user';
    await _createDefaultUserProfile();
    return defaultUserId;
  }

  // Generate metadata for legacy game states
  Map<String, dynamic> _generateLegacyMetadata(dynamic gameState) {
    try {
      // Attempt to extract basic info from game state
      return {
        'migratedFromLegacy': true,
        'migrationDate': DateTime.now().toIso8601String(),
        'playerCount': 4, // Default assumption
        'gameProgress': 0, // Unknown for legacy games
        'isGameOver': false,
      };
    } catch (e) {
      return {
        'migratedFromLegacy': true,
        'migrationDate': DateTime.now().toIso8601String(),
        'migrationError': e.toString(),
      };
    }
  }

  // Verify database integrity
  Future<DatabaseHealthCheck> verifyDatabaseIntegrity() async {
    final health = DatabaseHealthCheck();
    
    try {
      // Check if we can read from all tables
      final userProfiles = await _db.getUserProfile('test');
      health.userProfilesAccessible = true;
      
      final playerStats = await _db.getAllPlayerStats();
      health.playerStatsAccessible = true;
      health.playerStatsCount = playerStats.length;
      
      final gameHistory = await _db.getGameHistory(limit: 1);
      health.gameHistoryAccessible = true;
      health.gameHistoryCount = gameHistory.length;
      
      final savedGames = await _db.getSavedGames('default_user');
      health.savedGamesAccessible = true;
      health.savedGamesCount = savedGames.length;
      
      health.isHealthy = true;
    } catch (e) {
      health.isHealthy = false;
      health.errorMessage = e.toString();
    }
    
    return health;
  }

  // Reset database (for development/testing)
  Future<bool> resetDatabase() async {
    try {
      // This would need to be implemented in DatabaseService
      // For now, we can clear SharedPreferences as a fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Re-initialize
      await initializeDatabase();
      
      return true;
    } catch (e) {
      print('Error resetting database: $e');
      return false;
    }
  }

  // Backup database to SharedPreferences (as fallback)
  Future<bool> createBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      
      // Backup player stats
      final playerStats = await _db.getAllPlayerStats();
      await prefs.setString(
        'backup_player_stats_$timestamp',
        json.encode(playerStats.map((s) => s.toMap()).toList()),
      );
      
      // Backup saved games
      final savedGames = await _db.getSavedGames('default_user');
      await prefs.setString(
        'backup_saved_games_$timestamp',
        json.encode(savedGames.map((g) => g.toMap()).toList()),
      );
      
      await prefs.setString('last_backup', timestamp);
      return true;
    } catch (e) {
      print('Error creating backup: $e');
      return false;
    }
  }

  // Clean up old migration data
  Future<void> cleanupOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove old SharedPreferences keys after successful migration
      await prefs.remove('player_stats_list');
      await prefs.remove('saved_games');
      
      print('Cleaned up old migration data');
    } catch (e) {
      print('Error cleaning up old data: $e');
    }
  }
}

// Data class for database health check
class DatabaseHealthCheck {
  bool isHealthy = false;
  bool userProfilesAccessible = false;
  bool playerStatsAccessible = false;
  bool gameHistoryAccessible = false;
  bool savedGamesAccessible = false;
  int playerStatsCount = 0;
  int gameHistoryCount = 0;
  int savedGamesCount = 0;
  String? errorMessage;
  
  Map<String, dynamic> toMap() {
    return {
      'isHealthy': isHealthy,
      'userProfilesAccessible': userProfilesAccessible,
      'playerStatsAccessible': playerStatsAccessible,
      'gameHistoryAccessible': gameHistoryAccessible,
      'savedGamesAccessible': savedGamesAccessible,
      'playerStatsCount': playerStatsCount,
      'gameHistoryCount': gameHistoryCount,
      'savedGamesCount': savedGamesCount,
      'errorMessage': errorMessage,
      'checkTime': DateTime.now().toIso8601String(),
    };
  }
} 