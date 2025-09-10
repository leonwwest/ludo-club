import 'package:ludo_club/models/ludo_objects.dart';

enum ZoneType { main, home, goal, center }

class BoardZone {
  final ZoneType type;
  final PlayerColor? color;

  const BoardZone(this.type, {this.color});

  bool matches(ZoneType t, [PlayerColor? c]) =>
      type == t && (color == null || c == null || color == c);

  @override
  String toString() => 'BoardZone(type: $type, color: $color)';
}

