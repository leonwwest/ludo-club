import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';
import 'package:ludo_club/models/board_zone.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/constants/game_constants.dart';

void main() {
  group('Board zone mapping', () {
    test('Main path piece maps to ZoneType.main', () {
      final piece = Piece(PlayerColor.green, 0, const PiecePosition(10, isHome: false));
      final zone = LudoGame.zoneForPiece(piece);
      expect(zone.type, ZoneType.main);
      expect(zone.color, isNull);
    });

    test('Home lane piece maps to ZoneType.home with color', () {
      final piece = Piece(PlayerColor.red, 1, const PiecePosition(3));
      final zone = LudoGame.zoneForPiece(piece);
      expect(zone.type, ZoneType.home);
      expect(zone.color, PlayerColor.red);
      expect(zone.matches(ZoneType.home, PlayerColor.red), isTrue);
    });

    test('Goal piece maps to ZoneType.goal with color', () {
      final piece = Piece(PlayerColor.blue, 2, const PiecePosition(GameConstants.homePathLength), isSafe: true);
      final zone = LudoGame.zoneForPiece(piece);
      expect(zone.type, ZoneType.goal);
      expect(zone.color, PlayerColor.blue);
      expect(zone.matches(ZoneType.goal, PlayerColor.blue), isTrue);
    });
  });
}

