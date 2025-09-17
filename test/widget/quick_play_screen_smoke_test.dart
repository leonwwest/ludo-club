import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/services/ai_service.dart';
import 'package:ludo_club/services/audio_service.dart';
import 'package:ludo_club/ui/quick_play_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentAudioService implements AudioServiceBase {
  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Future<void> init() async {}

  @override
  bool get isSoundEnabled => true;

  @override
  double get volume => 1.0;

  @override
  Future<void> playCaptureSound() async {}

  @override
  Future<void> playDiceSound() async {}

  @override
  Future<void> playFinishSound() async {}

  @override
  Future<void> playMoveSound() async {}

  @override
  Future<void> playVictorySound() async {}

  @override
  void setSoundEnabled(bool enabled) {}

  @override
  void setVolume(double volume) {}
}

class _DeterministicAIService extends AIService {
  _DeterministicAIService() : super(random: _FixedRandom(const [0, 1, 2]));
}

class _FixedRandom implements Random {
  _FixedRandom(this._values);

  final List<int> _values;
  int _index = 0;

  int _next() {
    final value = _values[_index % _values.length];
    _index += 1;
    return value;
  }

  @override
  bool nextBool() => _next().isEven;

  @override
  double nextDouble() => (_next() % 1000) / 1000.0;

  @override
  int nextInt(int max) {
    assert(max > 0, 'max must be positive');
    return _next() % max;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Quick Play screen shows configuration controls', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => GameProvider(
              audioService: _SilentAudioService(),
              aiService: _DeterministicAIService(),
              random: _FixedRandom(const [0, 1, 2, 3, 4, 5]),
            ),
          ),
        ],
        child: const MaterialApp(home: QuickPlayScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Quick Play'), findsWidgets);
    expect(find.text('Player Settings'), findsOneWidget);
    expect(find.text('AI Difficulty'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Select rule preset'), findsOneWidget);

    // Ensure default state builds minimal player list when toggling preset list
    final dropdownFinder = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(dropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Chaos'), findsWidgets);
  });
}
