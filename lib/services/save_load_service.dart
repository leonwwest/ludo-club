import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_club/models/game_state.dart';

class SavedGame {
  final String id;
  final DateTime timestamp;
  final GameState gameState;
  final String name;

  SavedGame({
    required this.id,
    required this.timestamp,
    required this.gameState,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'gameState': gameState.toJson(),
      'name': name,
    };
  }

  factory SavedGame.fromJson(Map<String, dynamic> json) {
    return SavedGame(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      gameState: GameState.fromJson(json['gameState'] as Map<String, dynamic>),
      name: json['name'] as String,
    );
  }
}

class SaveLoadService {
  static const String _savedGamesKey = 'saved_games';
  final SharedPreferences _prefs;

  SaveLoadService(this._prefs);

  static Future<SaveLoadService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SaveLoadService(prefs);
  }

  Future<void> saveGame(GameState gameState, String name) async {
    final savedGames = await getSavedGames();
    final newSavedGame = SavedGame(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      gameState: gameState,
      name: name,
    );
    
    savedGames.add(newSavedGame);
    await _saveToDisk(savedGames);
  }

  Future<List<SavedGame>> getSavedGames() async {
    try {
      final jsonString = _prefs.getString(_savedGamesKey);
      if (jsonString == null) return [];
      
      final decoded = json.decode(jsonString);
      if (decoded is! List) return [];
      
      return decoded
          .where((item) => item is Map<String, dynamic>)
          .map((json) => SavedGame.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return []; // Return empty list on any parsing error
    }
  }

  Future<GameState?> loadGame(String gameId) async {
    try {
      final savedGames = await getSavedGames();
      final savedGame = savedGames.firstWhere(
        (game) => game.id == gameId,
        orElse: () => throw Exception('Game not found'),
      );
      return savedGame.gameState;
    } catch (e) {
      return null; // Return null instead of throwing
    }
  }

  Future<void> deleteGame(String gameId) async {
    final savedGames = await getSavedGames();
    savedGames.removeWhere((game) => game.id == gameId);
    await _saveToDisk(savedGames);
  }

  Future<void> _saveToDisk(List<SavedGame> savedGames) async {
    final jsonList = savedGames.map((game) => game.toJson()).toList();
    await _prefs.setString(_savedGamesKey, json.encode(jsonList));
  }
} 