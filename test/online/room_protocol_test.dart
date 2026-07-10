import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/online/room_protocol.dart';

void main() {
  group('RoomProtocol', () {
    test('round-trips versioned messages', () {
      final encoded = RoomProtocol.encode(RoomMessageType.joinRoom, {
        'roomCode': 'ABC234',
      });

      final decoded = RoomProtocol.decode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!['version'], RoomProtocol.version);
      expect(decoded['type'], RoomMessageType.joinRoom);
      expect(decoded['roomCode'], 'ABC234');
    });

    test('rejects malformed, oversized and wrong-version messages', () {
      expect(RoomProtocol.decode('not json'), isNull);
      expect(RoomProtocol.decode('{"version":2,"type":"join_room"}'), isNull);
      expect(
        RoomProtocol.decode('x' * (RoomProtocol.maxMessageBytes + 1)),
        isNull,
      );
    });

    test('normalizes room codes and player names', () {
      expect(RoomProtocol.normalizeRoomCode(' abc234 '), 'ABC234');
      expect(RoomProtocol.normalizeRoomCode('ABC10I'), isEmpty);
      expect(RoomProtocol.normalizePlayerName('  Mira  '), 'Mira');
      expect(RoomProtocol.normalizePlayerName(''), 'Gast');
      expect(RoomProtocol.normalizePlayerName('x' * 30), hasLength(24));
    });
  });
}
