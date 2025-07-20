import 'package:ludo_club/logic/ludo_game_logic.dart';

class Player {
  final String id;
  final String name;
  final bool isAI;
  final PlayerColor color;

  Player(
      {required this.id,
      required this.name,
      this.isAI = false,
      required this.color});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isAI': isAI,
      'color': color.toString(),
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      isAI: json['isAI'] as bool,
      color: PlayerColor.values.firstWhere(
          (e) => e.toString() == json['color'] as String,
          orElse: () => PlayerColor.red),
    );
  }
}

class GameState {
  List<Player> players;
  PlayerColor currentTurnPlayerId;
  int? lastDiceValue;
  int currentRollCount;
  PlayerColor? winnerId;
  String? gameId;
  final Map<PlayerColor, List<Piece>> pieces;

  GameState({
    required this.players,
    required this.currentTurnPlayerId,
    this.lastDiceValue,
    this.currentRollCount = 0,
    this.winnerId,
    this.gameId,
    required this.pieces,
  });

  Map<String, dynamic> toJson() {
    return {
      'players': players.map((p) => p.toJson()).toList(),
      'currentTurnPlayerId': currentTurnPlayerId.toString(),
      'lastDiceValue': lastDiceValue,
      'currentRollCount': currentRollCount,
      'winnerId': winnerId?.toString(),
      'gameId': gameId,
      'pieces': pieces.map((key, value) => MapEntry(
          key.toString(), value.map((p) => p.toString()).toList())),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      players: (json['players'] as List<dynamic>)
          .map((playerJson) =>
              Player.fromJson(playerJson as Map<String, dynamic>))
          .toList(),
      currentTurnPlayerId: PlayerColor.values.firstWhere(
          (e) => e.toString() == json['currentTurnPlayerId'] as String,
          orElse: () => PlayerColor.red),
      lastDiceValue: json['lastDiceValue'] as int?,
      currentRollCount: json['currentRollCount'] as int,
      winnerId: json['winnerId'] == null
          ? null
          : PlayerColor.values.firstWhere(
              (e) => e.toString() == json['winnerId'] as String,
              orElse: () => PlayerColor.red),
      gameId: json['gameId'] as String?,
      pieces: (json['pieces'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          PlayerColor.values
              .firstWhere((e) => e.toString() == key, orElse: () => PlayerColor.red),
          (value as List<dynamic>).map((p) => Piece.fromString(p)).toList(),
        ),
      ),
    );
  }

  Player get currentPlayer =>
      players.firstWhere((p) => p.color == currentTurnPlayerId);

  bool get isCurrentPlayerAI => currentPlayer.isAI;

  Player? get winner =>
      winnerId != null ? players.firstWhere((p) => p.color == winnerId) : null;

  bool get isGameOver => winnerId != null;

  GameState copy() {
    return GameState(
      players: players.map((p) => Player(id: p.id, name: p.name, isAI: p.isAI, color: p.color)).toList(),
      currentTurnPlayerId: currentTurnPlayerId,
      lastDiceValue: lastDiceValue,
      currentRollCount: currentRollCount,
      winnerId: winnerId,
      gameId: gameId,
      pieces: pieces.map((key, value) => MapEntry(key, value.map((p) => Piece.fromString(p.toString())).toList())),
    );
  }
}

extension on Piece {
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
