import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/models/move_event.dart';

void main() {
  group('MoveEvent serialization', () {
    test('RollEvent round-trips through JSON', () {
      const event = RollEvent(player: PlayerColor.red, diceValue: 6);
      final restored = MoveEvent.fromJson(event.toJson());

      expect(restored, isA<RollEvent>());
      expect((restored as RollEvent).player, PlayerColor.red);
      expect(restored.diceValue, 6);
    });

    test('NoMoveEvent round-trips through JSON', () {
      const event = NoMoveEvent(player: PlayerColor.blue, diceValue: 3);
      final restored = MoveEvent.fromJson(event.toJson());

      expect(restored, isA<NoMoveEvent>());
      expect((restored as NoMoveEvent).player, PlayerColor.blue);
      expect(restored.diceValue, 3);
    });

    test('ThreeSixesEvent round-trips through JSON', () {
      const event = ThreeSixesEvent(player: PlayerColor.green);
      final restored = MoveEvent.fromJson(event.toJson());

      expect(restored, isA<ThreeSixesEvent>());
      expect((restored as ThreeSixesEvent).player, PlayerColor.green);
    });

    test('ExtraRollEvent round-trips through JSON', () {
      const event = ExtraRollEvent(
        player: PlayerColor.yellow,
        diceValue: 4,
        attempt: 2,
      );
      final restored = MoveEvent.fromJson(event.toJson());

      expect(restored, isA<ExtraRollEvent>());
      expect((restored as ExtraRollEvent).player, PlayerColor.yellow);
      expect(restored.diceValue, 4);
      expect(restored.attempt, 2);
    });

    test('MovePieceEvent round-trips through JSON', () {
      const event = MovePieceEvent(
        player: PlayerColor.red,
        pieceId: 2,
        diceValue: 5,
        capturedCount: 1,
        finished: true,
      );
      final restored = MoveEvent.fromJson(event.toJson());

      expect(restored, isA<MovePieceEvent>());
      expect((restored as MovePieceEvent).player, PlayerColor.red);
      expect(restored.pieceId, 2);
      expect(restored.diceValue, 5);
      expect(restored.capturedCount, 1);
      expect(restored.finished, isTrue);
    });

    test('WinEvent round-trips through JSON', () {
      const event = WinEvent(player: PlayerColor.blue);
      final restored = MoveEvent.fromJson(event.toJson());

      expect(restored, isA<WinEvent>());
      expect((restored as WinEvent).player, PlayerColor.blue);
    });

    test('fromJson falls back to RollEvent for unknown type', () {
      final restored = MoveEvent.fromJson({
        'type': 'unknown',
        'player': 'red',
        'diceValue': 3,
      });

      expect(restored, isA<RollEvent>());
      expect((restored as RollEvent).diceValue, 3);
    });

    test('fromJson falls back to red for unknown player', () {
      final restored = MoveEvent.fromJson({
        'type': 'roll',
        'player': 'invalid',
        'diceValue': 1,
      });

      expect(restored.player, PlayerColor.red);
    });
  });

  group('MoveLogEntry serialization', () {
    test('round-trips through JSON with MovePieceEvent', () {
      final entry = MoveLogEntry(
        event: const MovePieceEvent(
          player: PlayerColor.green,
          pieceId: 1,
          diceValue: 6,
          capturedCount: 2,
          finished: false,
        ),
        color: PlayerColor.green,
      );

      final restored = MoveLogEntry.fromJson(entry.toJson());

      expect(restored.color, PlayerColor.green);
      expect(restored.event, isA<MovePieceEvent>());
      expect((restored.event as MovePieceEvent).pieceId, 1);
      expect((restored.event as MovePieceEvent).capturedCount, 2);
    });

    test('falls back to RollEvent when event JSON is missing', () {
      final restored = MoveLogEntry.fromJson({
        'color': 'red',
      });

      expect(restored.color, PlayerColor.red);
      expect(restored.event, isA<RollEvent>());
    });
  });
}
