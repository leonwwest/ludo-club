import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameStorage {
  GameStorage({
    this.prefsInstance,
    this.debounceDelay = const Duration(milliseconds: 500),
  });

  final SharedPreferences? prefsInstance;
  final Duration debounceDelay;
  static const String _saveKey = 'ludo_club_saved_game_v1';

  Timer? _debounceTimer;
  LudoGameState? _pendingState;
  Completer<void>? _activeCompleter;
  bool _disposed = false;

  Future<SharedPreferences> get _prefs async =>
      prefsInstance ?? await SharedPreferences.getInstance();

  Future<LudoGameState?> loadSavedState() async {
    try {
      final prefs = await _prefs;
      final saved = prefs.getString(_saveKey);
      if (saved == null) {
        return null;
      }
      final decoded = jsonDecode(saved);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      return LudoGameState.fromJson(decoded);
    } catch (error, stackTrace) {
      debugPrint('GameStorage.loadSavedState failed: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> save(LudoGameState state) async {
    if (_disposed) {
      return;
    }
    _pendingState = state;
    _debounceTimer?.cancel();
    _activeCompleter?.complete();
    _activeCompleter = Completer<void>();
    if (debounceDelay == Duration.zero) {
      await _writePending();
      return;
    }
    _debounceTimer = Timer(debounceDelay, _writePending);
    return _activeCompleter!.future;
  }

  Future<void> flush() async {
    _debounceTimer?.cancel();
    final current = _pendingState;
    if (current == null) {
      _activeCompleter?.complete();
      _activeCompleter = null;
      return;
    }
    try {
      final prefs = await _prefs;
      await prefs.setString(_saveKey, jsonEncode(current.toJson()));
      _pendingState = null;
      _activeCompleter?.complete();
      _activeCompleter = null;
    } catch (error, stackTrace) {
      debugPrint('GameStorage.flush failed: $error\n$stackTrace');
      _activeCompleter?.completeError(error, stackTrace);
      _activeCompleter = null;
    }
  }

  Future<void> clearSavedGame() async {
    _debounceTimer?.cancel();
    _pendingState = null;
    _activeCompleter?.complete();
    _activeCompleter = null;
    try {
      final prefs = await _prefs;
      await prefs.remove(_saveKey);
    } catch (error, stackTrace) {
      debugPrint('GameStorage.clearSavedGame failed: $error\n$stackTrace');
    }
  }

  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _activeCompleter?.complete();
    _pendingState = null;
  }

  Future<void> _writePending() async {
    final current = _pendingState;
    if (current == null) {
      _activeCompleter?.complete();
      _activeCompleter = null;
      return;
    }
    try {
      final prefs = await _prefs;
      await prefs.setString(_saveKey, jsonEncode(current.toJson()));
      _pendingState = null;
      _activeCompleter?.complete();
      _activeCompleter = null;
    } catch (error, stackTrace) {
      debugPrint('GameStorage.save failed: $error\n$stackTrace');
      _activeCompleter?.completeError(error, stackTrace);
      _activeCompleter = null;
    }
  }
}
