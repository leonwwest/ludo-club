import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:ludo_club/models/game_state.dart';

class SaveLoadService {
  static const String _savedGamesKey = 'saved_games';

  Future<bool> saveGame(GameState gameState, {String? customName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();
      final formatter = DateFormat('dd.MM.yyyy HH:mm');
      final saveName = customName ?? 'Save from ${formatter.format(now)}';

      final gameJson = gameState.toJson();
      gameJson['saveName'] = saveName;
      gameJson['saveDate'] = now.millisecondsSinceEpoch;

      final List<String> savedGames = prefs.getStringList(_savedGamesKey) ?? [];

      savedGames.add(jsonEncode(gameJson));

      return await prefs.setStringList(_savedGamesKey, savedGames);
    } catch (e) {
      return false;
    }
  }

  Future<GameState?> loadGame(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedGames = prefs.getStringList(_savedGamesKey) ?? [];

      if (index < 0 || index >= savedGames.length) {
        return null;
      }

      final gameJson = jsonDecode(savedGames[index]) as Map<String, dynamic>;
      return GameState.fromJson(gameJson);
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteGame(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedGames = prefs.getStringList(_savedGamesKey) ?? [];

      if (index < 0 || index >= savedGames.length) {
        return false;
      }

      savedGames.removeAt(index);
      return await prefs.setStringList(_savedGamesKey, savedGames);
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSavedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedGames = prefs.getStringList(_savedGamesKey) ?? [];

      return savedGames.map((gameString) {
        final gameJson = jsonDecode(gameString) as Map<String, dynamic>;
        return {
          'saveName': gameJson['saveName'] as String,
          'saveDate':
              DateTime.fromMillisecondsSinceEpoch(gameJson['saveDate'] as int),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}