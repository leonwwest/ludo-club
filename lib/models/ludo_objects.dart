enum PlayerColor { red, green, blue, yellow }

class PiecePosition {
  final int fieldId;
  final bool isHome;

  const PiecePosition(this.fieldId, {this.isHome = true});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PiecePosition &&
          runtimeType == other.runtimeType &&
          fieldId == other.fieldId &&
          isHome == other.isHome;

  @override
  int get hashCode => fieldId.hashCode ^ isHome.hashCode;
}

class Piece {
  final PlayerColor color;
  final int id;
  final PiecePosition position;
  final bool isSafe;

  Piece(this.color, this.id, this.position, {this.isSafe = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piece &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          id == other.id &&
          position == other.position &&
          isSafe == other.isSafe;

  @override
  int get hashCode => Object.hash(color, id, position, isSafe);

  Map<String, dynamic> toJson() => {
        'color': color.name,
        'id': id,
        'position': {
          'fieldId': position.fieldId,
          'isHome': position.isHome,
        },
        'isSafe': isSafe,
      };

  static Piece fromJson(Map<String, dynamic> json) {
    final color = PlayerColor.values.byName(json['color'] as String);
    final id = json['id'] as int;
    final pos = json['position'] as Map<String, dynamic>;
    final position = PiecePosition(
      pos['fieldId'] as int,
      isHome: pos['isHome'] as bool? ?? true,
    );
    final isSafe = json['isSafe'] as bool? ?? false;
    return Piece(color, id, position, isSafe: isSafe);
  }

  static Piece fromString(String s) {
    final parts = s.split(',');
    final color = PlayerColor.values.firstWhere((e) => e.toString() == parts[0]);
    final id = int.parse(parts[1]);
    final position = PiecePosition(int.parse(parts[2]), isHome: parts[3] == 'true');
    final isSafe = parts[4] == 'true';
    return Piece(color, id, position, isSafe: isSafe);
  }

  @override
  String toString() {
    return '${color.toString()},$id,${position.fieldId},${position.isHome},$isSafe';
  }
}
