import 'dart:convert';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:ludo_club/services/database_service.dart';
import 'package:ludo_club/models/database_models.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:uuid/uuid.dart';

class EnhancedSaveLoadService {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  // Save a game with enhanced metadata
  Future<String> saveGame({
    required GameState gameState,
    required String name,
    required String userId,
    String? thumbnail,
    Map<String, dynamic>? metadata,
    bool isOnlineGame = false,
    String? lobbyId,
  }) async {
    final gameId = _uuid.v4();
    
    final savedGame = EnhancedSavedGame(
      id: gameId,
      userId: userId,
      name: name,
      thumbnail: thumbnail ?? '',
      timestamp: DateTime.now(),
      gameStateJson: json.encode(gameState.toJson()),
      metadata: metadata ?? _generateMetadata(gameState),
      isOnlineGame: isOnlineGame,
      lobbyId: lobbyId,
    );

    await _db.saveGame(savedGame);
    return gameId;
  }

  // Save game with automatic screenshot
  Future<String> saveGameWithScreenshot({
    required GameState gameState,
    required String name,
    required String userId,
    required RenderRepaintBoundary boundary,
    Map<String, dynamic>? metadata,
    bool isOnlineGame = false,
    String? lobbyId,
  }) async {
    // Capture screenshot
    final image = await boundary.toImage(pixelRatio: 0.5);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final thumbnail = byteData != null ? 
        base64Encode(byteData.buffer.asUint8List()) : '';

    return await saveGame(
      gameState: gameState,
      name: name,
      userId: userId,
      thumbnail: thumbnail,
      metadata: metadata,
      isOnlineGame: isOnlineGame,
      lobbyId: lobbyId,
    );
  }

  // Load a specific game
  Future<GameState?> loadGame(String gameId) async {
    try {
      final savedGames = await _db.getSavedGames(''); // This should be filtered by user
      final savedGame = savedGames.firstWhere(
        (game) => game.id == gameId,
        orElse: () => throw Exception('Game not found'),
      );

      final gameStateJson = json.decode(savedGame.gameStateJson) as Map<String, dynamic>;
      return GameState.fromJson(gameStateJson);
    } catch (e) {
      return null;
    }
  }

  // Get all saved games for a user
  Future<List<SavedGameInfo>> getSavedGames(String userId) async {
    try {
      final savedGames = await _db.getSavedGames(userId);
      return savedGames.map((game) => SavedGameInfo.fromEnhancedSavedGame(game)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get saved games with filtering and sorting options
  Future<List<SavedGameInfo>> getSavedGamesFiltered({
    required String userId,
    GameSaveFilter? filter,
    GameSaveSort sort = GameSaveSort.newest,
    int? limit,
  }) async {
    final allGames = await getSavedGames(userId);
    var filteredGames = allGames;

    // Apply filters
    if (filter != null) {
      filteredGames = filteredGames.where((game) {
        switch (filter.type) {
          case FilterType.gameType:
            return game.gameType == filter.value;
          case FilterType.playerCount:
            return game.playerCount == int.parse(filter.value);
          case FilterType.isOnline:
            return game.isOnlineGame == (filter.value == 'true');
          case FilterType.dateRange:
            // Implement date range filtering
            return true;
        }
      }).toList();
    }

    // Apply sorting
    switch (sort) {
      case GameSaveSort.newest:
        filteredGames.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case GameSaveSort.oldest:
        filteredGames.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case GameSaveSort.name:
        filteredGames.sort((a, b) => a.name.compareTo(b.name));
        break;
      case GameSaveSort.progress:
        filteredGames.sort((a, b) => b.gameProgress.compareTo(a.gameProgress));
        break;
    }

    // Apply limit
    if (limit != null && limit > 0) {
      filteredGames = filteredGames.take(limit).toList();
    }

    return filteredGames;
  }

  // Delete a saved game
  Future<bool> deleteSavedGame(String gameId) async {
    try {
      await _db.deleteSavedGame(gameId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Bulk delete saved games
  Future<int> deleteSavedGames(List<String> gameIds) async {
    int deletedCount = 0;
    for (final gameId in gameIds) {
      if (await deleteSavedGame(gameId)) {
        deletedCount++;
      }
    }
    return deletedCount;
  }

  // Auto-save feature (saves game state periodically)
  Future<String?> autoSave({
    required GameState gameState,
    required String userId,
    String? existingAutoSaveId,
  }) async {
    try {
      final autoSaveName = 'Auto-save ${DateTime.now().toString().substring(0, 16)}';
      
      if (existingAutoSaveId != null) {
        // Update existing auto-save
        await deleteSavedGame(existingAutoSaveId);
      }

      final metadata = _generateMetadata(gameState);
      metadata['isAutoSave'] = true;

      return await saveGame(
        gameState: gameState,
        name: autoSaveName,
        userId: userId,
        metadata: metadata,
      );
    } catch (e) {
      return null;
    }
  }

  // Export game data (for backup purposes)
  Future<String> exportGameData(String userId) async {
    try {
      final savedGames = await getSavedGames(userId);
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'userId': userId,
        'savedGames': savedGames.map((game) => game.toJson()).toList(),
      };
      return json.encode(exportData);
    } catch (e) {
      return '';
    }
  }

  // Import game data (from backup)
  Future<bool> importGameData(String userId, String importData) async {
    try {
      final data = json.decode(importData) as Map<String, dynamic>;
      final savedGamesData = data['savedGames'] as List<dynamic>;
      
      for (final gameData in savedGamesData) {
        final gameInfo = SavedGameInfo.fromJson(gameData as Map<String, dynamic>);
        
        // Create new EnhancedSavedGame from imported data
        final savedGame = EnhancedSavedGame(
          id: _uuid.v4(), // Generate new ID to avoid conflicts
          userId: userId,
          name: '${gameInfo.name} (Imported)',
          thumbnail: gameInfo.thumbnail,
          timestamp: DateTime.now(),
          gameStateJson: gameInfo.gameStateJson,
          metadata: gameInfo.metadata,
          isOnlineGame: gameInfo.isOnlineGame,
        );
        
        await _db.saveGame(savedGame);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get storage statistics
  Future<StorageStats> getStorageStats(String userId) async {
    try {
      final savedGames = await getSavedGames(userId);
      
      int totalGames = savedGames.length;
      int totalSize = 0;
      int autoSaves = 0;
      int onlineGames = 0;
      
      for (final game in savedGames) {
        totalSize += game.gameStateJson.length;
        totalSize += game.thumbnail.length;
        
        if (game.metadata['isAutoSave'] == true) {
          autoSaves++;
        }
        
        if (game.isOnlineGame) {
          onlineGames++;
        }
      }
      
      return StorageStats(
        totalSavedGames: totalGames,
        totalStorageSize: totalSize,
        autoSaveCount: autoSaves,
        onlineGameCount: onlineGames,
        oldestSave: savedGames.isNotEmpty ? 
            savedGames.map((g) => g.timestamp).reduce((a, b) => a.isBefore(b) ? a : b) : null,
        newestSave: savedGames.isNotEmpty ? 
            savedGames.map((g) => g.timestamp).reduce((a, b) => a.isAfter(b) ? a : b) : null,
      );
    } catch (e) {
      return StorageStats.empty();
    }
  }

  // Clean up old auto-saves (keep only the most recent N)
  Future<int> cleanupAutoSaves(String userId, {int keepCount = 5}) async {
    try {
      final allGames = await getSavedGames(userId);
      final autoSaves = allGames
          .where((game) => game.metadata['isAutoSave'] == true)
          .toList();
      
      autoSaves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      if (autoSaves.length <= keepCount) {
        return 0; // Nothing to clean up
      }
      
      final toDelete = autoSaves.skip(keepCount).map((game) => game.id).toList();
      return await deleteSavedGames(toDelete);
    } catch (e) {
      return 0;
    }
  }

  // Generate metadata from game state
  Map<String, dynamic> _generateMetadata(GameState gameState) {
    final playerNames = gameState.players.map((p) => p.name).toList();
    final aiPlayers = gameState.players.where((p) => p.isAI).length;
    final humanPlayers = gameState.players.length - aiPlayers;
    
    // Calculate game progress (percentage of tokens reached home)
    int totalTokensHome = 0;
    int maxPossibleTokens = gameState.players.length * GameState.tokensPerPlayer;
    
    for (final player in gameState.players) {
      totalTokensHome += player.pieces.where((piece) => 
          piece.position.fieldId == GameState.finishedPosition).length;
    }
    
    final gameProgress = maxPossibleTokens > 0 ? 
        (totalTokensHome / maxPossibleTokens * 100).round() : 0;

    return {
      'playerNames': playerNames,
      'playerCount': gameState.players.length,
      'aiPlayerCount': aiPlayers,
      'humanPlayerCount': humanPlayers,
      'currentPlayer': gameState.currentPlayer.name,
      'gameProgress': gameProgress,
      'lastDiceValue': gameState.lastDiceValue,
      'isGameOver': gameState.isGameOver,
      'winner': gameState.winner?.name,
      'totalTurns': gameState.currentRollCount,
      'phase': gameState.phase.toString(),
    };
  }
}

// Supporting classes
class SavedGameInfo {
  final String id;
  final String name;
  final String thumbnail;
  final DateTime timestamp;
  final String gameStateJson;
  final Map<String, dynamic> metadata;
  final bool isOnlineGame;
  
  // Computed properties from metadata
  List<String> get playerNames => 
      List<String>.from(metadata['playerNames'] ?? []);
  int get playerCount => metadata['playerCount'] ?? 0;
  String get currentPlayer => metadata['currentPlayer'] ?? '';
  int get gameProgress => metadata['gameProgress'] ?? 0;
  bool get isGameOver => metadata['isGameOver'] ?? false;
  String? get winner => metadata['winner'];
  String get gameType => isOnlineGame ? 'Online' : 'Local';

  SavedGameInfo({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.timestamp,
    required this.gameStateJson,
    required this.metadata,
    required this.isOnlineGame,
  });

  factory SavedGameInfo.fromEnhancedSavedGame(EnhancedSavedGame savedGame) {
    return SavedGameInfo(
      id: savedGame.id,
      name: savedGame.name,
      thumbnail: savedGame.thumbnail,
      timestamp: savedGame.timestamp,
      gameStateJson: savedGame.gameStateJson,
      metadata: savedGame.metadata,
      isOnlineGame: savedGame.isOnlineGame,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumbnail': thumbnail,
      'timestamp': timestamp.toIso8601String(),
      'gameStateJson': gameStateJson,
      'metadata': metadata,
      'isOnlineGame': isOnlineGame,
    };
  }

  factory SavedGameInfo.fromJson(Map<String, dynamic> json) {
    return SavedGameInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      thumbnail: json['thumbnail'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      gameStateJson: json['gameStateJson'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isOnlineGame: json['isOnlineGame'] as bool,
    );
  }
}

class GameSaveFilter {
  final FilterType type;
  final String value;

  GameSaveFilter({required this.type, required this.value});
}

enum FilterType { gameType, playerCount, isOnline, dateRange }
enum GameSaveSort { newest, oldest, name, progress }

class StorageStats {
  final int totalSavedGames;
  final int totalStorageSize;
  final int autoSaveCount;
  final int onlineGameCount;
  final DateTime? oldestSave;
  final DateTime? newestSave;

  StorageStats({
    required this.totalSavedGames,
    required this.totalStorageSize,
    required this.autoSaveCount,
    required this.onlineGameCount,
    this.oldestSave,
    this.newestSave,
  });

  factory StorageStats.empty() {
    return StorageStats(
      totalSavedGames: 0,
      totalStorageSize: 0,
      autoSaveCount: 0,
      onlineGameCount: 0,
    );
  }

  String get formattedSize {
    if (totalStorageSize < 1024) return '$totalStorageSize B';
    if (totalStorageSize < 1024 * 1024) return '${(totalStorageSize / 1024).toStringAsFixed(1)} KB';
    return '${(totalStorageSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
} 
