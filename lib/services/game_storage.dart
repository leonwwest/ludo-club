import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedGameSnapshot {
  SavedGameSnapshot({
    required this.state,
    List<LudoGameState> history = const [],
  }) : history = List.unmodifiable(history);

  final LudoGameState state;
  final List<LudoGameState> history;
}

/// Minimal persistence surface used by [GameStorage].
///
/// Keeping the backend explicit makes ordering guarantees testable without
/// relying on timing inside the shared-preferences plugin.
abstract interface class GameStorageBackend {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}

class SharedPreferencesGameStorageBackend implements GameStorageBackend {
  SharedPreferencesGameStorageBackend([this._prefsInstance]);

  final SharedPreferences? _prefsInstance;
  Future<SharedPreferences>? _prefsFuture;

  Future<SharedPreferences> get _prefs => _prefsInstance != null
      ? Future<SharedPreferences>.value(_prefsInstance)
      : _prefsFuture ??= SharedPreferences.getInstance();

  @override
  Future<String?> read(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final prefs = await _prefs;
    final didWrite = await prefs.setString(key, value);
    if (!didWrite) {
      throw StateError('SharedPreferences rejected the game-state write.');
    }
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await _prefs;
    final didRemove = await prefs.remove(key);
    if (!didRemove && prefs.containsKey(key)) {
      throw StateError('SharedPreferences rejected clearing the saved game.');
    }
  }
}

/// Serializes every storage operation in call order.
///
/// A save snapshots the state immediately and receives a monotonically
/// increasing revision. Later saves, clears, and reads cannot overtake an
/// earlier operation, so a slow older write can never replace newer state.
///
/// [dispose] is synchronous because it is called from `ChangeNotifier.dispose`.
/// It stops accepting new operations but deliberately leaves already queued
/// work alive. Call and await [flush] before disposal whenever the surrounding
/// lifecycle offers an asynchronous shutdown hook and a durability guarantee
/// is required before that hook returns.
class GameStorage {
  GameStorage({
    SharedPreferences? prefsInstance,
    GameStorageBackend? backend,
    // Retained for source compatibility. Writes are now serialized immediately.
    Duration debounceDelay = Duration.zero,
  })  : assert(
          prefsInstance == null || backend == null,
          'Provide either prefsInstance or backend, not both.',
        ),
        _backend =
            backend ?? SharedPreferencesGameStorageBackend(prefsInstance);

  static const String _saveKey = 'ludo_club_saved_game_v1';
  static const int _schemaVersion = 2;

  final GameStorageBackend _backend;
  Future<_StorageSettlement> _settledRevision = Future.value(
    const _StorageSettlement(revision: 0),
  );
  int _nextRevision = 0;
  bool _disposed = false;

  Future<SavedGameSnapshot?> loadSavedGame() {
    return _enqueue<SavedGameSnapshot?>('loadSavedGame', () async {
      try {
        final saved = await _backend.read(_saveKey);
        if (saved == null) {
          return null;
        }
        final decoded = jsonDecode(saved);
        final decodedMap = _stringMap(decoded);
        if (decodedMap == null) {
          return null;
        }
        final stateMap = _stringMap(decodedMap['state']);
        if (stateMap == null) {
          return SavedGameSnapshot(
            state: LudoGameState.fromJson(decodedMap),
          );
        }
        final rawHistory = decodedMap['history'];
        return SavedGameSnapshot(
          state: LudoGameState.fromJson(stateMap),
          history: _decodeHistory(rawHistory),
        );
      } catch (error, stackTrace) {
        debugPrint('GameStorage.loadSavedGame failed: $error\n$stackTrace');
        return null;
      }
    });
  }

  Future<LudoGameState?> loadSavedState() async {
    return (await loadSavedGame())?.state;
  }

  Future<void> save(
    LudoGameState state, {
    List<LudoGameState> history = const [],
  }) {
    final boundedHistory = history.length <= GameConstants.undoHistoryLimit
        ? history
        : history.sublist(history.length - GameConstants.undoHistoryLimit);
    final encoded = jsonEncode({
      'schemaVersion': _schemaVersion,
      'state': state.toJson(),
      'history': [for (final snapshot in boundedHistory) snapshot.toJson()],
    });
    return _enqueue<void>('save', () => _backend.write(_saveKey, encoded));
  }

  Future<void> clearSavedGame() {
    return _enqueue<void>(
      'clearSavedGame',
      () => _backend.remove(_saveKey),
    );
  }

  /// Waits for every operation that was queued before this call.
  ///
  /// Operations scheduled after [flush] starts belong to the next revision and
  /// are intentionally not part of the returned future.
  Future<void> flush() async {
    final targetRevision = _nextRevision;
    final barrier = _settledRevision;
    final settlement = await barrier;
    if (settlement.revision < targetRevision) {
      throw StateError(
        'Storage flush stopped at revision ${settlement.revision}; '
        'expected at least $targetRevision.',
      );
    }
    if (settlement.error case final error?) {
      Error.throwWithStackTrace(error, settlement.stackTrace!);
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    // Do not cancel the chain: synchronous disposal must not discard a save
    // that the controller already queued.
    unawaited(
      flush().catchError((Object error, StackTrace stackTrace) {
        debugPrint('GameStorage.dispose flush failed: $error\n$stackTrace');
      }),
    );
  }

  Future<T> _enqueue<T>(String operationName, Future<T> Function() operation) {
    if (_disposed) {
      return Future<T>.error(
        StateError('GameStorage is disposed; cannot $operationName.'),
      );
    }

    final revision = ++_nextRevision;
    final gate = _settledRevision;
    final result = gate.then<T>((_) => operation());

    // This recovery branch keeps later revisions runnable after an individual
    // failure. The original result still reports that failure to its caller.
    _settledRevision = result.then<_StorageSettlement>(
      (_) => _StorageSettlement(revision: revision),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('GameStorage.$operationName failed: $error\n$stackTrace');
        return _StorageSettlement(
          revision: revision,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    return result;
  }
}

class _StorageSettlement {
  const _StorageSettlement({
    required this.revision,
    this.error,
    this.stackTrace,
  });

  final int revision;
  final Object? error;
  final StackTrace? stackTrace;
}

Map<String, Object?>? _stringMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is! Map) {
    return null;
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      return null;
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<LudoGameState> _decodeHistory(Object? value) {
  if (value is! List) {
    return const [];
  }
  final decoded = <LudoGameState>[];
  for (final entry in value) {
    final json = _stringMap(entry);
    if (json == null) {
      continue;
    }
    try {
      decoded.add(LudoGameState.fromJson(json));
    } on Object {
      // A corrupt undo entry must not invalidate the current saved game.
    }
  }
  if (decoded.length <= GameConstants.undoHistoryLimit) {
    return decoded;
  }
  return decoded.sublist(decoded.length - GameConstants.undoHistoryLimit);
}
