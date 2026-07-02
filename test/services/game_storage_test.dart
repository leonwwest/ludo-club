import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/services/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  GameStorage createStorage({Duration? delay}) {
    final storage = GameStorage(debounceDelay: delay ?? Duration.zero);
    addTearDown(storage.dispose);
    return storage;
  }

  group('GameStorage.loadSavedState', () {
    test('returns null when no saved state exists', () async {
      final storage = createStorage();
      expect(await storage.loadSavedState(), isNull);
    });

    test('returns state when valid JSON is saved', () async {
      final state = LudoGameState.newGame(playerCount: 2);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'ludo_club_saved_game_v1',
        jsonEncode(state.toJson()),
      );

      final storage = createStorage();
      final loaded = await storage.loadSavedState();
      expect(loaded, isNotNull);
      expect(loaded!.players, hasLength(2));
    });

    test('returns null when saved JSON is corrupt', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ludo_club_saved_game_v1', 'not valid json {{{');

      final storage = createStorage();
      expect(await storage.loadSavedState(), isNull);
    });

    test('returns null when decoded value is not a Map', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'ludo_club_saved_game_v1',
        jsonEncode([1, 2, 3]),
      );

      final storage = createStorage();
      expect(await storage.loadSavedState(), isNull);
    });
  });

  group('GameStorage.save', () {
    test('saves state to SharedPreferences', () async {
      final state = LudoGameState.newGame(playerCount: 3);
      final storage = createStorage();

      await storage.save(state);
      await storage.flush();

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('ludo_club_saved_game_v1');
      expect(saved, isNotNull);

      final decoded = jsonDecode(saved!) as Map<String, Object?>;
      final loaded = LudoGameState.fromJson(decoded);
      expect(loaded.players, hasLength(3));
    });
  });

  group('GameStorage.clearSavedGame', () {
    test('removes saved state', () async {
      final state = LudoGameState.newGame();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'ludo_club_saved_game_v1',
        jsonEncode(state.toJson()),
      );

      final storage = createStorage();
      await storage.clearSavedGame();

      expect(prefs.getString('ludo_club_saved_game_v1'), isNull);
    });
  });
}
