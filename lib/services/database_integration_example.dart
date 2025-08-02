// This file shows practical examples of integrating the new database services
// into your existing Ludo Club UI components

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ludo_club/services/enhanced_statistics_service.dart';
import 'package:ludo_club/services/enhanced_save_load_service.dart';
import 'package:ludo_club/models/database_models.dart';
import 'package:ludo_club/models/game_state.dart';

// Example: Enhanced Player Stats Screen
class EnhancedPlayerStatsScreen extends StatefulWidget {
  final String playerId;
  
  const EnhancedPlayerStatsScreen({super.key, required this.playerId});

  @override
  State<EnhancedPlayerStatsScreen> createState() => _EnhancedPlayerStatsScreenState();
}

class _EnhancedPlayerStatsScreenState extends State<EnhancedPlayerStatsScreen> {
  final EnhancedStatisticsService _statsService = EnhancedStatisticsService();
  PlayerDashboardData? _dashboardData;
  AdvancedStats? _advancedStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    try {
      final dashboardData = await _statsService.getDashboardData(widget.playerId);
      final advancedStats = await _statsService.getAdvancedStats(widget.playerId);
      
      setState(() {
        _dashboardData = dashboardData;
        _advancedStats = advancedStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = _dashboardData?.stats;
    final advanced = _advancedStats;

    return Scaffold(
      appBar: AppBar(
        title: Text('${stats?.playerName ?? "Player"} Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: () => _syncWithCloud(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Stats Card
            _buildBasicStatsCard(stats),
            const SizedBox(height: 16),
            
            // Advanced Stats Card
            _buildAdvancedStatsCard(advanced),
            const SizedBox(height: 16),
            
            // Achievements Card
            _buildAchievementsCard(_dashboardData?.achievements ?? []),
            const SizedBox(height: 16),
            
            // Recent Games
            _buildRecentGamesCard(_dashboardData?.recentGames ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicStatsCard(EnhancedPlayerStats? stats) {
    if (stats == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Basic Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('Games Played', stats.gamesPlayed.toString()),
                _buildStatItem('Games Won', stats.gamesWon.toString()),
                _buildStatItem('Win Rate', '${(stats.winRate * 100).toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatItem('Tokens Home', stats.tokensReachedHome.toString()),
                _buildStatItem('Captures', stats.opponentsCaptured.toString()),
                _buildStatItem('Win Streak', stats.currentWinStreak.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedStatsCard(AdvancedStats? advanced) {
    if (advanced == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Advanced Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('Avg Roll', advanced.averageRollValue.toStringAsFixed(2)),
                _buildStatItem('Sixes %', '${advanced.sixesPercentage.toStringAsFixed(1)}%'),
                _buildStatItem('Best Streak', advanced.bestWinStreak.toString()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatItem('Avg Game', '${advanced.averageGameDuration.toStringAsFixed(1)}m'),
                _buildStatItem('Capture Ratio', advanced.captureRatio.toStringAsFixed(2)),
                _buildStatItem('Favorite Mode', advanced.favoriteGameType),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(List<Achievement> achievements) {
    final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Achievements (${unlockedAchievements.length}/${achievements.length})', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (unlockedAchievements.isEmpty)
              const Text('No achievements unlocked yet!')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unlockedAchievements.map((achievement) => 
                  Chip(
                    label: Text(achievement.title),
                    avatar: const Icon(Icons.star, size: 16),
                  )
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGamesCard(List<GameHistory> recentGames) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Games', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (recentGames.isEmpty)
              const Text('No recent games')
            else
              Column(
                children: recentGames.take(5).map((game) => 
                  ListTile(
                    leading: Icon(
                      game.winnerId == widget.playerId ? Icons.emoji_events : Icons.games,
                      color: game.winnerId == widget.playerId ? Colors.amber : Colors.grey,
                    ),
                    title: Text('${game.gameType} - ${game.playerNames.join(', ')}'),
                    subtitle: Text('${game.gameDuration.inMinutes}m - ${game.endTime.toString().substring(0, 16)}'),
                    trailing: game.winnerId == widget.playerId ? 
                        const Text('Won', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)) :
                        const Text('Lost', style: TextStyle(color: Colors.red)),
                  )
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _syncWithCloud() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Syncing with cloud...'),
          ],
        ),
      ),
    );

    try {
      await _statsService.syncWithCloud();
      Navigator.of(context).pop(); // Close dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully synced with cloud!')),
      );
      
      // Reload data
      await _loadPlayerData();
    } catch (e) {
      Navigator.of(context).pop(); // Close dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }
}

// Example: Enhanced Saved Games Screen
class EnhancedSavedGamesScreen extends StatefulWidget {
  final String userId;
  
  const EnhancedSavedGamesScreen({super.key, required this.userId});

  @override
  State<EnhancedSavedGamesScreen> createState() => _EnhancedSavedGamesScreenState();
}

class _EnhancedSavedGamesScreenState extends State<EnhancedSavedGamesScreen> {
  final EnhancedSaveLoadService _saveService = EnhancedSaveLoadService();
  List<SavedGameInfo> _savedGames = [];
  GameSaveSort _currentSort = GameSaveSort.newest;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedGames();
  }

  Future<void> _loadSavedGames() async {
    setState(() => _isLoading = true);
    
    try {
      final games = await _saveService.getSavedGamesFiltered(
        userId: widget.userId,
        sort: _currentSort,
      );
      
      setState(() {
        _savedGames = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Games'),
        actions: [
          PopupMenuButton<GameSaveSort>(
            icon: const Icon(Icons.sort),
            onSelected: (sort) {
              setState(() => _currentSort = sort);
              _loadSavedGames();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: GameSaveSort.newest, child: Text('Newest First')),
              const PopupMenuItem(value: GameSaveSort.oldest, child: Text('Oldest First')),
              const PopupMenuItem(value: GameSaveSort.name, child: Text('Name')),
              const PopupMenuItem(value: GameSaveSort.progress, child: Text('Progress')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedGames.isEmpty
              ? const Center(child: Text('No saved games'))
              : ListView.builder(
                  itemCount: _savedGames.length,
                  itemBuilder: (context, index) {
                    final game = _savedGames[index];
                    return _buildGameCard(game);
                  },
                ),
    );
  }

  Widget _buildGameCard(SavedGameInfo game) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: game.thumbnail.isNotEmpty
            ? Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: MemoryImage(base64.decode(game.thumbnail)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                ),
                child: const Icon(Icons.games),
              ),
        title: Text(game.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Players: ${game.playerNames.join(', ')}'),
            Text('Progress: ${game.gameProgress}% • ${game.timestamp.toString().substring(0, 16)}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'load', child: Text('Load Game')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (action) {
            switch (action) {
              case 'load':
                _loadGame(game);
                break;
              case 'delete':
                _deleteGame(game);
                break;
            }
          },
        ),
        onTap: () => _loadGame(game),
      ),
    );
  }

  Future<void> _loadGame(SavedGameInfo game) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading game...'),
          ],
        ),
      ),
    );

    try {
      final gameState = await _saveService.loadGame(game.id);
      Navigator.of(context).pop(); // Close loading dialog
      
      if (gameState != null) {
        // Navigate to game screen with loaded state
        // Navigator.of(context).pushReplacement(
        //   MaterialPageRoute(
        //     builder: (context) => GameScreen(initialGameState: gameState),
        //   ),
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load game')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading game: $e')),
      );
    }
  }

  Future<void> _deleteGame(SavedGameInfo game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Game'),
        content: Text('Are you sure you want to delete "${game.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _saveService.deleteSavedGame(game.id);
      
      if (success) {
        setState(() {
          _savedGames.removeWhere((g) => g.id == game.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete game')),
        );
      }
    }
  }
}

// Example: Integration in GameProvider
class GameProviderDatabaseIntegration {
  final EnhancedStatisticsService _statsService = EnhancedStatisticsService();
  final EnhancedSaveLoadService _saveService = EnhancedSaveLoadService();

  // Record game completion
  Future<void> recordGameCompletion(
    GameState finalGameState,
    Duration gameDuration,
    Map<String, List<int>> playerRolls,
    Map<String, int> captures,
  ) async {
    try {
      await _statsService.recordGameResult(
        finalGameState: finalGameState,
        gameDuration: gameDuration,
        playerRolls: playerRolls,
        captures: captures,
        gameType: 'quick_play', // or determine based on game mode
      );
    } catch (e) {
      print('Failed to record game result: $e');
      // Game continues even if stats recording fails
    }
  }

  // Auto-save during game
  String? _currentAutoSaveId;
  
  Future<void> performAutoSave(GameState gameState, String userId) async {
    try {
      _currentAutoSaveId = await _saveService.autoSave(
        gameState: gameState,
        userId: userId,
        existingAutoSaveId: _currentAutoSaveId,
      );
    } catch (e) {
      print('Auto-save failed: $e');
      // Continue game even if auto-save fails
    }
  }
}

// Helper function to show leaderboard
Future<void> showLeaderboard(BuildContext context) async {
  final statsService = EnhancedStatisticsService();
  
  showDialog(
    context: context,
    builder: (context) => FutureBuilder<List<EnhancedPlayerStats>>(
      future: statsService.getLeaderboard(type: LeaderboardType.wins, limit: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return AlertDialog(
            title: const Text('Leaderboard'),
            content: const Text('Failed to load leaderboard'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        }
        
        final players = snapshot.data!;
        
        return AlertDialog(
          title: const Text('Leaderboard - Most Wins'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(player.playerName),
                  subtitle: Text('Win Rate: ${(player.winRate * 100).toStringAsFixed(1)}%'),
                  trailing: Text('${player.gamesWon} wins'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    ),
  );
} 