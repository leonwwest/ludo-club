import 'package:ludo_club/models/ludo_models.dart';

sealed class MoveEvent {
  const MoveEvent({required this.player});

  final PlayerColor player;

  String get type;

  Map<String, Object?> toJson() {
    return {'type': type, 'player': player.name};
  }

  static MoveEvent fromJson(Map<String, Object?> json) {
    final player = _playerColorFromJson(json['player']);
    switch (json['type'] as String? ?? 'roll') {
      case 'noMove':
        return NoMoveEvent(
          player: player,
          diceValue: json['diceValue'] as int? ?? 0,
        );
      case 'threeSixes':
        return ThreeSixesEvent(player: player);
      case 'extraRoll':
        return ExtraRollEvent(
          player: player,
          diceValue: json['diceValue'] as int? ?? 0,
          attempt: json['attempt'] as int? ?? 1,
        );
      case 'movePiece':
        return MovePieceEvent(
          player: player,
          pieceId: json['pieceId'] as int? ?? 0,
          diceValue: json['diceValue'] as int? ?? 0,
          capturedCount: json['capturedCount'] as int? ?? 0,
          finished: json['finished'] == true,
        );
      case 'win':
        return WinEvent(player: player);
      default:
        return RollEvent(
          player: player,
          diceValue: json['diceValue'] as int? ?? 0,
        );
    }
  }

  static PlayerColor _playerColorFromJson(Object? value) {
    return PlayerColor.values.firstWhere(
      (color) => color.name == value,
      orElse: () => PlayerColor.red,
    );
  }
}

class RollEvent extends MoveEvent {
  const RollEvent({required super.player, required this.diceValue});

  final int diceValue;

  @override
  String get type => 'roll';

  @override
  Map<String, Object?> toJson() {
    return {...super.toJson(), 'diceValue': diceValue};
  }
}

class NoMoveEvent extends MoveEvent {
  const NoMoveEvent({required super.player, required this.diceValue});

  final int diceValue;

  @override
  String get type => 'noMove';

  @override
  Map<String, Object?> toJson() {
    return {...super.toJson(), 'diceValue': diceValue};
  }
}

class ThreeSixesEvent extends MoveEvent {
  const ThreeSixesEvent({required super.player});

  @override
  String get type => 'threeSixes';
}

class ExtraRollEvent extends MoveEvent {
  const ExtraRollEvent({
    required super.player,
    required this.diceValue,
    required this.attempt,
  });

  final int diceValue;
  final int attempt;

  @override
  String get type => 'extraRoll';

  @override
  Map<String, Object?> toJson() {
    return {
      ...super.toJson(),
      'diceValue': diceValue,
      'attempt': attempt,
    };
  }
}

class MovePieceEvent extends MoveEvent {
  const MovePieceEvent({
    required super.player,
    required this.pieceId,
    required this.diceValue,
    required this.capturedCount,
    required this.finished,
  });

  final int pieceId;
  final int diceValue;
  final int capturedCount;
  final bool finished;

  @override
  String get type => 'movePiece';

  @override
  Map<String, Object?> toJson() {
    return {
      ...super.toJson(),
      'pieceId': pieceId,
      'diceValue': diceValue,
      'capturedCount': capturedCount,
      'finished': finished,
    };
  }
}

class WinEvent extends MoveEvent {
  const WinEvent({required super.player});

  @override
  String get type => 'win';
}
