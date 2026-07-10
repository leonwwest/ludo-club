import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/services/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  GameStorage createStorage({GameStorageBackend? backend}) {
    final storage = GameStorage(backend: backend);
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
      expect(_playerCount(saved!), 3);
    });

    test('persists and restores bounded undo history', () async {
      final storage = createStorage();
      final beforeRoll = LudoGameState.newGame(playerCount: 2);
      final afterRoll = beforeRoll.copyWith(
        phase: TurnPhase.waitingForMove,
        diceValue: 6,
      );

      await storage.save(afterRoll, history: [beforeRoll]);
      final restored = await storage.loadSavedGame();

      expect(restored, isNotNull);
      expect(restored!.state.diceValue, 6);
      expect(restored.history, hasLength(1));
      expect(restored.history.single.phase, TurnPhase.waitingForRoll);
      expect(restored.history.single.diceValue, isNull);
    });

    test('serializes overlapping writes so the latest state wins', () async {
      final backend = _ControlledBackend(writeCount: 2);
      final storage = createStorage(backend: backend);

      final firstSave = storage.save(LudoGameState.newGame(playerCount: 2));
      await backend.waitForWrite(0);
      final latestSave = storage.save(LudoGameState.newGame());

      await Future<void>.delayed(Duration.zero);
      expect(backend.startedWrites, 1);

      backend.releaseWrite(0);
      await backend.waitForWrite(1);
      expect(_playerCount(backend.writePayloads[0]), 2);

      backend.releaseWrite(1);
      await Future.wait([firstSave, latestSave]);

      expect(_playerCount(backend.value!), 4);
      expect(backend.operations, ['write', 'write']);
    });

    test('flush waits for the latest revision queued before it', () async {
      final backend = _ControlledBackend(writeCount: 2);
      final storage = createStorage(backend: backend);

      final firstSave = storage.save(LudoGameState.newGame(playerCount: 2));
      await backend.waitForWrite(0);
      final latestSave = storage.save(LudoGameState.newGame(playerCount: 3));
      var didFlush = false;
      final flush = storage.flush().then((_) => didFlush = true);

      backend.releaseWrite(0);
      await backend.waitForWrite(1);
      expect(didFlush, isFalse);

      backend.releaseWrite(1);
      await Future.wait([firstSave, latestSave, flush]);
      expect(didFlush, isTrue);
      expect(_playerCount(backend.value!), 3);
    });

    test('dispose keeps an already queued write alive', () async {
      final backend = _ControlledBackend(writeCount: 1);
      final storage = createStorage(backend: backend);

      final save = storage.save(LudoGameState.newGame(playerCount: 3));
      await backend.waitForWrite(0);
      storage.dispose();
      backend.releaseWrite(0);

      await save;
      expect(_playerCount(backend.value!), 3);
      await expectLater(
        storage.save(LudoGameState.newGame()),
        throwsA(isA<StateError>()),
      );
    });

    test('flush reports a failed latest write', () async {
      final storage = createStorage(backend: _FailingBackend());

      await expectLater(
        storage.save(LudoGameState.newGame(playerCount: 2)),
        throwsA(isA<StateError>()),
      );

      await expectLater(storage.flush(), throwsA(isA<StateError>()));
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

    test('cannot be overtaken by an older in-flight save', () async {
      final backend = _ControlledBackend(writeCount: 1);
      final storage = createStorage(backend: backend);

      final save = storage.save(LudoGameState.newGame(playerCount: 2));
      await backend.waitForWrite(0);
      final clear = storage.clearSavedGame();

      backend.releaseWrite(0);
      await Future.wait([save, clear]);

      expect(backend.value, isNull);
      expect(backend.operations, ['write', 'remove']);
    });

    test('preserves clear then save ordering during overlap', () async {
      final backend = _ControlledBackend(writeCount: 2);
      final storage = createStorage(backend: backend);

      final oldSave = storage.save(LudoGameState.newGame(playerCount: 2));
      await backend.waitForWrite(0);
      final clear = storage.clearSavedGame();
      final newSave = storage.save(LudoGameState.newGame());

      backend.releaseWrite(0);
      await backend.waitForWrite(1);
      backend.releaseWrite(1);
      await Future.wait([oldSave, clear, newSave]);

      expect(backend.operations, ['write', 'remove', 'write']);
      expect(_playerCount(backend.value!), 4);
    });
  });
}

int _playerCount(String encoded) {
  final decoded = jsonDecode(encoded) as Map<String, Object?>;
  final state = decoded['state'];
  final stateJson = state is Map ? Map<String, Object?>.from(state) : decoded;
  return LudoGameState.fromJson(stateJson).players.length;
}

class _FailingBackend implements GameStorageBackend {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> write(String key, String value) {
    throw StateError('disk full');
  }
}

class _ControlledBackend implements GameStorageBackend {
  _ControlledBackend({required int writeCount})
      : _writeStarted = List.generate(writeCount, (_) => Completer<void>()),
        _writeGates = List.generate(writeCount, (_) => Completer<void>());

  final List<Completer<void>> _writeStarted;
  final List<Completer<void>> _writeGates;
  final List<String> operations = [];
  final List<String> writePayloads = [];
  String? value;
  int startedWrites = 0;

  Future<void> waitForWrite(int index) => _writeStarted[index].future;

  void releaseWrite(int index) => _writeGates[index].complete();

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> remove(String key) async {
    operations.add('remove');
    value = null;
  }

  @override
  Future<void> write(String key, String encoded) async {
    final index = startedWrites++;
    operations.add('write');
    writePayloads.add(encoded);
    _writeStarted[index].complete();
    await _writeGates[index].future;
    value = encoded;
  }
}
