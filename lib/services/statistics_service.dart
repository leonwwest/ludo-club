import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerStats {
  final String playerName;
  int gamesPlayed;
  int gamesWon;
  int tokensReachedHome;
  int opponentsCaptured;

  PlayerStats({
    required this.playerName,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.tokensReachedHome = 0,
    this.opponentsCaptured = 0,
  });

  double get winRate => gamesPlayed > 0 ? gamesWon / gamesPlayed : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'tokensReachedHome': tokensReachedHome,
      'opponentsCaptured': opponentsCaptured,
    };
  }

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      playerName: json['playerName'] as String,
      gamesPlayed: json['gamesPlayed'] as int,
      gamesWon: json['gamesWon'] as int,
      tokensReachedHome: json['tokensReachedHome'] as int,
      opponentsCaptured: json['opponentsCaptured'] as int,
    );
  }

  PlayerStats copyWith({
    String? playerName,
    int? gamesPlayed,
    int? gamesWon,
    int? tokensReachedHome,
    int? opponentsCaptured,
  }) {
    return PlayerStats(
      playerName: playerName ?? this.playerName,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      tokensReachedHome: tokensReachedHome ?? this.tokensReachedHome,
      opponentsCaptured: opponentsCaptured ?? this.opponentsCaptured,
    );
  }
}

class StatisticsService {
  static const String _playerStatsListKey = 'player_stats_list';
  final SharedPreferences _prefs;

  StatisticsService(this._prefs);

  static Future<StatisticsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StatisticsService(prefs);
  }

  Future<List<PlayerStats>> getAllPlayerStats() async {
    try {
      final jsonString = _prefs.getString(_playerStatsListKey);
      if (jsonString == null) return [];
      
      final decoded = json.decode(jsonString);
      if (decoded is! List) return [];
      
      return decoded
          .where((item) => item is Map<String, dynamic>)
          .map((json) => PlayerStats.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return []; // Return empty list on any parsing error
    }
  }

  Future<PlayerStats> getPlayerStats(String playerName) async {
    final allStats = await getAllPlayerStats();
    return allStats.firstWhere(
      (stats) => stats.playerName == playerName,
      orElse: () => PlayerStats(playerName: playerName),
    );
  }

  Future<void> updatePlayerStats(PlayerStats stats) async {
    final allStats = await getAllPlayerStats();
    final index = allStats.indexWhere((s) => s.playerName == stats.playerName);
    
    if (index >= 0) {
      allStats[index] = stats;
    } else {
      allStats.add(stats);
    }
    
    await _saveToDisk(allStats);
  }

  Future<void> recordGameResult({
    required String winnerName,
    required List<String> allPlayerNames,
    Map<String, int>? tokensReachedHome,
    Map<String, int>? opponentsCaptured,
  }) async {
    final allStats = await getAllPlayerStats();
    
    for (final playerName in allPlayerNames) {
      final existingIndex = allStats.indexWhere((s) => s.playerName == playerName);
      final existing = existingIndex >= 0 
          ? allStats[existingIndex] 
          : PlayerStats(playerName: playerName);
      
      final updated = existing.copyWith(
        gamesPlayed: existing.gamesPlayed + 1,
        gamesWon: playerName == winnerName ? existing.gamesWon + 1 : existing.gamesWon,
        tokensReachedHome: existing.tokensReachedHome + (tokensReachedHome?[playerName] ?? 0),
        opponentsCaptured: existing.opponentsCaptured + (opponentsCaptured?[playerName] ?? 0),
      );
      
      if (existingIndex >= 0) {
        allStats[existingIndex] = updated;
      } else {
        allStats.add(updated);
      }
    }
    
    await _saveToDisk(allStats);
  }

  Future<void> clearAllStats() async {
    await _prefs.remove(_playerStatsListKey);
  }

  Future<void> _saveToDisk(List<PlayerStats> stats) async {
    final jsonList = stats.map((s) => s.toJson()).toList();
    await _prefs.setString(_playerStatsListKey, json.encode(jsonList));
  }
} 