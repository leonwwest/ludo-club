import 'package:flutter/foundation.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/models/move_event.dart';

enum PlayerColor { red, green, yellow, blue }

extension PlayerColorMetadata on PlayerColor {
  String get label {
    return switch (this) {
      PlayerColor.red => 'Sisiliya',
      PlayerColor.green => 'Flora',
      PlayerColor.yellow => 'Abdul',
      PlayerColor.blue => 'Kiran',
    };
  }

  String get shortLabel {
    return switch (this) {
      PlayerColor.red => 'R',
      PlayerColor.green => 'G',
      PlayerColor.yellow => 'Y',
      PlayerColor.blue => 'B',
    };
  }

  int get startIndex {
    return switch (this) {
      PlayerColor.yellow => 0,
      PlayerColor.red => 13,
      PlayerColor.green => 26,
      PlayerColor.blue => 39,
    };
  }

  String get colorLabel {
    return switch (this) {
      PlayerColor.red => 'Rot',
      PlayerColor.green => 'Grün',
      PlayerColor.yellow => 'Gelb',
      PlayerColor.blue => 'Blau',
    };
  }
}

enum TurnPhase { waitingForRoll, waitingForMove, gameOver }

enum OpenRollRule { oneRoll, threeRolls }

@immutable
class RuleOptions {
  const RuleOptions({
    this.openRollRule = OpenRollRule.oneRoll,
    this.mustLeaveBaseOnSix = false,
    this.blockOwnFields = false,
    this.extraTurnOnFinish = false,
    this.extraTurnOnCapture = true,
    this.threeSixesEndTurn = false,
    this.mustCapture = false,
  });

  final OpenRollRule openRollRule;
  final bool mustLeaveBaseOnSix;
  final bool blockOwnFields;
  final bool extraTurnOnFinish;
  final bool extraTurnOnCapture;
  final bool threeSixesEndTurn;
  final bool mustCapture;

  int get rollsWhenNoPieceIsOut =>
      openRollRule == OpenRollRule.threeRolls ? 3 : 1;

  RuleOptions copyWith({
    OpenRollRule? openRollRule,
    bool? mustLeaveBaseOnSix,
    bool? blockOwnFields,
    bool? extraTurnOnFinish,
    bool? extraTurnOnCapture,
    bool? threeSixesEndTurn,
    bool? mustCapture,
  }) {
    return RuleOptions(
      openRollRule: openRollRule ?? this.openRollRule,
      mustLeaveBaseOnSix: mustLeaveBaseOnSix ?? this.mustLeaveBaseOnSix,
      blockOwnFields: blockOwnFields ?? this.blockOwnFields,
      extraTurnOnFinish: extraTurnOnFinish ?? this.extraTurnOnFinish,
      extraTurnOnCapture: extraTurnOnCapture ?? this.extraTurnOnCapture,
      threeSixesEndTurn: threeSixesEndTurn ?? this.threeSixesEndTurn,
      mustCapture: mustCapture ?? this.mustCapture,
    );
  }

  Map<String, Object> toJson() {
    return {
      'openRollRule': openRollRule.name,
      'mustLeaveBaseOnSix': mustLeaveBaseOnSix,
      'blockOwnFields': blockOwnFields,
      'extraTurnOnFinish': extraTurnOnFinish,
      'extraTurnOnCapture': extraTurnOnCapture,
      'threeSixesEndTurn': threeSixesEndTurn,
      'mustCapture': mustCapture,
    };
  }

  factory RuleOptions.fromJson(Map<String, Object?> json) {
    return RuleOptions(
      openRollRule: OpenRollRule.values.firstWhere(
        (rule) => rule.name == json['openRollRule'],
        orElse: () => OpenRollRule.oneRoll,
      ),
      mustLeaveBaseOnSix: json['mustLeaveBaseOnSix'] == true,
      blockOwnFields: json['blockOwnFields'] == true,
      extraTurnOnFinish: json['extraTurnOnFinish'] == true,
      extraTurnOnCapture: json['extraTurnOnCapture'] != false,
      threeSixesEndTurn: json['threeSixesEndTurn'] == true,
      mustCapture: json['mustCapture'] == true,
    );
  }
}

@immutable
class LudoPiece {
  const LudoPiece({required this.color, required this.id, required this.steps});

  final PlayerColor color;
  final int id;

  /// -1 means base. 0-51 is the main loop, 52-57 is the home lane.
  final int steps;

  bool get isInBase => steps < 0;
  bool get isOnMainTrack => steps >= 0 && steps < 52;
  bool get isInHomeLane => steps >= 52 && steps < 57;
  bool get isFinished => steps == 57;

  LudoPiece copyWith({int? steps}) {
    return LudoPiece(color: color, id: id, steps: steps ?? this.steps);
  }

  Map<String, Object> toJson() {
    return {'color': color.name, 'id': id, 'steps': steps};
  }

  factory LudoPiece.fromJson(Map<String, Object?> json) {
    return LudoPiece(
      color: _playerColorFromJson(json['color']),
      id: json['id'] as int? ?? 0,
      steps: json['steps'] as int? ?? -1,
    );
  }
}

@immutable
class LudoPlayer {
  LudoPlayer({
    required this.color,
    required this.name,
    required List<LudoPiece> pieces,
  }) : pieces = List.unmodifiable(pieces);

  final PlayerColor color;
  final String name;
  final List<LudoPiece> pieces;

  int get finishedCount => pieces.where((piece) => piece.isFinished).length;
  bool get hasWon => finishedCount == pieces.length;

  LudoPlayer copyWith({String? name, List<LudoPiece>? pieces}) {
    return LudoPlayer(
      color: color,
      name: name ?? this.name,
      pieces: pieces ?? this.pieces,
    );
  }

  Map<String, Object> toJson() {
    return {
      'color': color.name,
      'name': name,
      'pieces': [for (final piece in pieces) piece.toJson()],
    };
  }

  factory LudoPlayer.fromJson(Map<String, Object?> json) {
    final piecesJson = json['pieces'];
    return LudoPlayer(
      color: _playerColorFromJson(json['color']),
      name:
          json['name'] as String? ?? _playerColorFromJson(json['color']).label,
      pieces: piecesJson is List
          ? [
              for (final piece in piecesJson)
                if (piece is Map<String, Object?>) LudoPiece.fromJson(piece),
            ]
          : const [],
    );
  }
}

@immutable
class MoveSummary {
  MoveSummary({
    required this.mover,
    required this.pieceId,
    required this.fromSteps,
    required this.toSteps,
    required List<LudoPiece> captured,
    required this.extraTurn,
    required this.finished,
  }) : captured = List.unmodifiable(captured);

  final PlayerColor mover;
  final int pieceId;
  final int fromSteps;
  final int toSteps;
  final List<LudoPiece> captured;
  final bool extraTurn;
  final bool finished;

  bool get didCapture => captured.isNotEmpty;

  Map<String, Object?> toJson() {
    return {
      'mover': mover.name,
      'pieceId': pieceId,
      'fromSteps': fromSteps,
      'toSteps': toSteps,
      'captured': [for (final piece in captured) piece.toJson()],
      'extraTurn': extraTurn,
      'finished': finished,
    };
  }

  factory MoveSummary.fromJson(Map<String, Object?> json) {
    final capturedJson = json['captured'];
    return MoveSummary(
      mover: _playerColorFromJson(json['mover']),
      pieceId: json['pieceId'] as int? ?? 0,
      fromSteps: json['fromSteps'] as int? ?? -1,
      toSteps: json['toSteps'] as int? ?? -1,
      captured: capturedJson is List
          ? [
              for (final piece in capturedJson)
                if (piece is Map<String, Object?>) LudoPiece.fromJson(piece),
            ]
          : const [],
      extraTurn: json['extraTurn'] == true,
      finished: json['finished'] == true,
    );
  }
}

@immutable
class MoveLogEntry {
  const MoveLogEntry({required this.event, required this.color});

  final MoveEvent event;
  final PlayerColor color;

  Map<String, Object> toJson() {
    return {
      'event': event.toJson(),
      'color': color.name,
    };
  }

  factory MoveLogEntry.fromJson(Map<String, Object?> json) {
    final eventJson = json['event'];
    return MoveLogEntry(
      event: eventJson is Map<String, Object?>
          ? MoveEvent.fromJson(eventJson)
          : RollEvent(
              player: _playerColorFromJson(json['color']),
              diceValue: 0,
            ),
      color: _playerColorFromJson(json['color']),
    );
  }
}

@immutable
class LudoGameState {
  LudoGameState({
    required List<LudoPlayer> players,
    required this.currentPlayerIndex,
    required this.phase,
    required this.diceValue,
    required this.winner,
    required this.moveSummary,
    required this.turnMessage,
    required this.rules,
    required this.pendingOpenRolls,
    required this.consecutiveSixes,
    required List<MoveLogEntry> moveLog,
  })  : players = List.unmodifiable(players),
        moveLog = List.unmodifiable(moveLog);

  factory LudoGameState.newGame({
    int playerCount = 4,
    RuleOptions rules = const RuleOptions(),
    Map<PlayerColor, String> playerNames = const {},
  }) {
    if (playerCount < GameConstants.minPlayers ||
        playerCount > GameConstants.maxPlayers) {
      throw ArgumentError(
        'playerCount must be ${GameConstants.minPlayers}-${GameConstants.maxPlayers}, got $playerCount',
      );
    }
    final colors = colorsForPlayerCount(playerCount);
    return LudoGameState(
      players: [
        for (final color in colors)
          LudoPlayer(
            color: color,
            name: playerNames[color]?.trim().isNotEmpty == true
                ? playerNames[color]!.trim()
                : color.label,
            pieces: [
              for (var id = 0; id < 4; id++)
                LudoPiece(color: color, id: id, steps: -1),
            ],
          ),
      ],
      currentPlayerIndex: 0,
      phase: TurnPhase.waitingForRoll,
      diceValue: null,
      winner: null,
      moveSummary: null,
      turnMessage: '${colors.first.label} beginnt.',
      rules: rules,
      pendingOpenRolls: rules.rollsWhenNoPieceIsOut,
      consecutiveSixes: 0,
      moveLog: const [],
    );
  }

  final List<LudoPlayer> players;
  final int currentPlayerIndex;
  final TurnPhase phase;
  final int? diceValue;
  final PlayerColor? winner;
  final MoveSummary? moveSummary;
  final String turnMessage;
  final RuleOptions rules;
  final int pendingOpenRolls;
  final int consecutiveSixes;
  final List<MoveLogEntry> moveLog;

  LudoPlayer get currentPlayer => players[currentPlayerIndex];
  List<PlayerColor> get activeColors =>
      players.map((player) => player.color).toList();

  static List<PlayerColor> colorsForPlayerCount(int playerCount) {
    final clamped = playerCount.clamp(
      GameConstants.minPlayers,
      GameConstants.maxPlayers,
    );
    return switch (clamped) {
      2 => const [PlayerColor.red, PlayerColor.yellow],
      3 => const [PlayerColor.red, PlayerColor.green, PlayerColor.yellow],
      _ => PlayerColor.values,
    };
  }

  LudoGameState copyWith({
    List<LudoPlayer>? players,
    int? currentPlayerIndex,
    TurnPhase? phase,
    Object? diceValue = _unset,
    Object? winner = _unset,
    Object? moveSummary = _unset,
    String? turnMessage,
    RuleOptions? rules,
    int? pendingOpenRolls,
    int? consecutiveSixes,
    List<MoveLogEntry>? moveLog,
  }) {
    return LudoGameState(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      phase: phase ?? this.phase,
      diceValue:
          identical(diceValue, _unset) ? this.diceValue : diceValue as int?,
      winner: identical(winner, _unset) ? this.winner : winner as PlayerColor?,
      moveSummary: identical(moveSummary, _unset)
          ? this.moveSummary
          : moveSummary as MoveSummary?,
      turnMessage: turnMessage ?? this.turnMessage,
      rules: rules ?? this.rules,
      pendingOpenRolls: pendingOpenRolls ?? this.pendingOpenRolls,
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
      moveLog: moveLog ?? this.moveLog,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'players': [for (final player in players) player.toJson()],
      'currentPlayerIndex': currentPlayerIndex,
      'phase': phase.name,
      'diceValue': diceValue,
      'winner': winner?.name,
      'moveSummary': moveSummary?.toJson(),
      'turnMessage': turnMessage,
      'rules': rules.toJson(),
      'pendingOpenRolls': pendingOpenRolls,
      'consecutiveSixes': consecutiveSixes,
      'moveLog': [for (final entry in moveLog) entry.toJson()],
    };
  }

  factory LudoGameState.fromJson(Map<String, Object?> json) {
    final playersJson = json['players'];
    final rules = json['rules'] is Map<String, Object?>
        ? RuleOptions.fromJson(json['rules']! as Map<String, Object?>)
        : const RuleOptions();
    final players = playersJson is List
        ? [
            for (final player in playersJson)
              if (player is Map<String, Object?>) LudoPlayer.fromJson(player),
          ]
        : <LudoPlayer>[];
    final fallback = LudoGameState.newGame(
      playerCount: players.length.clamp(2, 4),
      rules: rules,
    );
    final moveSummaryJson = json['moveSummary'];
    final moveLogJson = json['moveLog'];
    return LudoGameState(
      players: players.isEmpty ? fallback.players : players,
      currentPlayerIndex: (json['currentPlayerIndex'] as int? ?? 0)
          .clamp(0, GameConstants.maxPlayers - 1),
      phase: TurnPhase.values.firstWhere(
        (phase) => phase.name == json['phase'],
        orElse: () => TurnPhase.waitingForRoll,
      ),
      diceValue: json['diceValue'] as int?,
      winner:
          json['winner'] == null ? null : _playerColorFromJson(json['winner']),
      moveSummary: moveSummaryJson is Map<String, Object?>
          ? MoveSummary.fromJson(moveSummaryJson)
          : null,
      turnMessage: json['turnMessage'] as String? ?? fallback.turnMessage,
      rules: rules,
      pendingOpenRolls:
          json['pendingOpenRolls'] as int? ?? rules.rollsWhenNoPieceIsOut,
      consecutiveSixes: json['consecutiveSixes'] as int? ?? 0,
      moveLog: moveLogJson is List
          ? [
              for (final entry in moveLogJson)
                if (entry is Map<String, Object?>) MoveLogEntry.fromJson(entry),
            ]
          : const [],
    );
  }
}

class _Unset {
  const _Unset();
}

const _unset = _Unset();

PlayerColor _playerColorFromJson(Object? value) {
  return PlayerColor.values.firstWhere(
    (color) => color.name == value,
    orElse: () => PlayerColor.red,
  );
}
