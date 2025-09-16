import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/game_phase.dart';
import 'package:ludo_club/models/game_rules.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/services/ai_service.dart';
import 'package:ludo_club/services/audio_service.dart';

class _FixedRandom implements Random {
  _FixedRandom(this._values);

  final List<int> _values;
  int _index = 0;

  int _nextValue() {
    if (_values.isEmpty) {
      return 0;
    }
    final index = _index < _values.length ? _index : _values.length - 1;
    final value = _values[index];
    if (_index < _values.length - 1) {
      _index += 1;
    }
    return value;
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be positive');
    }
    return _nextValue() % max;
  }

  @override
  double nextDouble() => (_nextValue() % 1000) / 1000;

  @override
  bool nextBool() => (_nextValue() & 1) == 0;
}

class _TestAIService extends AIService {
  _TestAIService() : super(random: _FixedRandom(const [0]));

  bool wasCalled = false;

  @override
  Future<AIDecision> makeMove(
      GameState gameState, AIDifficulty difficulty) async {
    wasCalled = true;
    final movable = LudoGame.getMovablePieces(gameState);
    return AIDecision(
      selectedPiece: movable.isNotEmpty ? movable.first : null,
      reasoning: 'test',
      confidence: 1.0,
    );
  }
}

class _NoopAudioService implements AudioServiceBase {
  bool _enabled = true;
  double _volume = 1.0;

  @override
  Future<void> init() async {}

  @override
  void setVolume(double volume) {
    _volume = volume;
  }

  @override
  void setSoundEnabled(bool enabled) {
    _enabled = enabled;
  }

  @override
  bool get isSoundEnabled => _enabled;

  @override
  double get volume => _volume;

  @override
  Future<void> playDiceSound() async {}

  @override
  Future<void> playMoveSound() async {}

  @override
  Future<void> playCaptureSound() async {}

  @override
  Future<void> playFinishSound() async {}

  @override
  Future<void> playVictorySound() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Rolling a six grants an extra turn to the same player', () async {
    final random = _FixedRandom(const [5, 2]);
    final provider =
        GameProvider(random: random, audioService: _NoopAudioService());

    final players = [
      Player(
        id: 'red',
        name: 'Red',
        color: PlayerColor.red,
        pieces: List.generate(
          GameConstants.tokensPerPlayer,
          (index) => Piece(PlayerColor.red, index,
              const PiecePosition(GameState.basePosition)),
        ),
      ),
      Player(
        id: 'green',
        name: 'Green',
        color: PlayerColor.green,
        pieces: List.generate(
          GameConstants.tokensPerPlayer,
          (index) => Piece(PlayerColor.green, index,
              const PiecePosition(GameState.basePosition)),
        ),
      ),
    ];

    provider.startNewGame(players);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await provider.rollDice();
    final movable = provider.getMovablePieces();
    expect(movable, isNotEmpty);

    await provider.movePiece(movable.first);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(provider.currentPlayerColor, PlayerColor.red);
    expect(provider.phase, GamePhase.waitingForRoll);
  });

  test('AI takes an automatic turn when it is the current player', () {
    fakeAsync((async) {
      final random = _FixedRandom(const [0, 2, 0]);
      final aiService = _TestAIService();
      final provider = GameProvider(
        aiService: aiService,
        random: random,
        audioService: _NoopAudioService(),
      );

      provider.setRules(
        GameRules.standard.copyWith(
          aiThinkingTimeMultiplier: 0,
          mustRollSixToStart: false,
        ),
      );

      final players = [
        Player(
          id: 'ai_red',
          name: 'AI Red',
          color: PlayerColor.red,
          type: PlayerType.ai,
          aiDifficulty: AIDifficulty.beginner,
          pieces: List.generate(
            GameConstants.tokensPerPlayer,
            (index) => Piece(PlayerColor.red, index,
                const PiecePosition(GameState.basePosition)),
          ),
        ),
        Player(
          id: 'green',
          name: 'Green',
          color: PlayerColor.green,
          pieces: List.generate(
            GameConstants.tokensPerPlayer,
            (index) => Piece(PlayerColor.green, index,
                const PiecePosition(GameState.basePosition)),
          ),
        ),
      ];

      provider.startNewGame(players);
      async.flushMicrotasks();

      async.elapse(const Duration(milliseconds: 800));
      async.flushMicrotasks();

      expect(aiService.wasCalled, isTrue);
      expect(provider.currentPlayerColor, PlayerColor.green);
      expect(provider.phase, GamePhase.waitingForRoll);
    });
  });
}
