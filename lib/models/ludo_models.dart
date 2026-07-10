import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/models/move_event.dart';
import 'package:meta/meta.dart';

enum PlayerColor { red, green, yellow, blue }

enum PlayerKind { human, bot }

enum BotDifficulty { easy, normal, hard }

enum PlayerAvatarId { sisiliya, flora, abdul, kiran }

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

extension PlayerAvatarMetadata on PlayerAvatarId {
  String get label {
    return switch (this) {
      PlayerAvatarId.sisiliya => 'Sisiliya',
      PlayerAvatarId.flora => 'Flora',
      PlayerAvatarId.abdul => 'Abdul',
      PlayerAvatarId.kiran => 'Kiran',
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
    this.extraTurnOnSixNoMove = true,
    this.doublePieceBlockades = false,
  });

  final OpenRollRule openRollRule;
  final bool mustLeaveBaseOnSix;
  final bool blockOwnFields;
  final bool extraTurnOnFinish;
  final bool extraTurnOnCapture;
  final bool threeSixesEndTurn;
  final bool mustCapture;
  final bool extraTurnOnSixNoMove;
  final bool doublePieceBlockades;

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
    bool? extraTurnOnSixNoMove,
    bool? doublePieceBlockades,
  }) {
    return RuleOptions(
      openRollRule: openRollRule ?? this.openRollRule,
      mustLeaveBaseOnSix: mustLeaveBaseOnSix ?? this.mustLeaveBaseOnSix,
      blockOwnFields: blockOwnFields ?? this.blockOwnFields,
      extraTurnOnFinish: extraTurnOnFinish ?? this.extraTurnOnFinish,
      extraTurnOnCapture: extraTurnOnCapture ?? this.extraTurnOnCapture,
      threeSixesEndTurn: threeSixesEndTurn ?? this.threeSixesEndTurn,
      mustCapture: mustCapture ?? this.mustCapture,
      extraTurnOnSixNoMove: extraTurnOnSixNoMove ?? this.extraTurnOnSixNoMove,
      doublePieceBlockades: doublePieceBlockades ?? this.doublePieceBlockades,
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
      'extraTurnOnSixNoMove': extraTurnOnSixNoMove,
      'doublePieceBlockades': doublePieceBlockades,
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
      extraTurnOnSixNoMove: json['extraTurnOnSixNoMove'] != false,
      doublePieceBlockades: json['doublePieceBlockades'] == true,
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
    final id = _intInRange(json['id'], 0, GameConstants.piecesPerPlayer - 1);
    final steps = _intInRange(json['steps'], -1, GameConstants.finishStep);
    return LudoPiece(
      color: _playerColorFromJson(json['color']),
      id: id ?? 0,
      steps: steps ?? -1,
    );
  }
}

@immutable
class LudoPlayer {
  LudoPlayer({
    required this.color,
    required this.name,
    required List<LudoPiece> pieces,
    this.kind = PlayerKind.human,
    this.botDifficulty = BotDifficulty.normal,
    PlayerAvatarId? avatarId,
  })  : avatarId = avatarId ?? _defaultAvatarFor(color),
        pieces = List.unmodifiable(pieces);

  final PlayerColor color;
  final String name;
  final List<LudoPiece> pieces;
  final PlayerKind kind;
  final BotDifficulty botDifficulty;
  final PlayerAvatarId avatarId;

  int get finishedCount => pieces.where((piece) => piece.isFinished).length;
  bool get hasWon => finishedCount == pieces.length;
  bool get isBot => kind == PlayerKind.bot;

  LudoPlayer copyWith({
    String? name,
    List<LudoPiece>? pieces,
    PlayerKind? kind,
    BotDifficulty? botDifficulty,
    PlayerAvatarId? avatarId,
  }) {
    return LudoPlayer(
      color: color,
      name: name ?? this.name,
      pieces: pieces ?? this.pieces,
      kind: kind ?? this.kind,
      botDifficulty: botDifficulty ?? this.botDifficulty,
      avatarId: avatarId ?? this.avatarId,
    );
  }

  Map<String, Object> toJson() {
    return {
      'color': color.name,
      'name': name,
      'kind': kind.name,
      'botDifficulty': botDifficulty.name,
      'avatarId': avatarId.name,
      'pieces': [for (final piece in pieces) piece.toJson()],
    };
  }

  factory LudoPlayer.fromJson(Map<String, Object?> json) {
    final piecesJson = json['pieces'];
    final color = _playerColorFromJson(json['color']);
    final rawName = json['name'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : color.label;
    return LudoPlayer(
      color: color,
      name: name,
      kind: _playerKindFromJson(json['kind']),
      botDifficulty: _botDifficultyFromJson(json['botDifficulty']),
      avatarId: _playerAvatarFromJson(
        json['avatarId'],
        color: color,
      ),
      pieces: _normalizedPieces(color, piecesJson),
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
      pieceId: _intInRange(
            json['pieceId'],
            0,
            GameConstants.piecesPerPlayer - 1,
          ) ??
          0,
      fromSteps:
          _intInRange(json['fromSteps'], -1, GameConstants.finishStep) ?? -1,
      toSteps: _intInRange(json['toSteps'], -1, GameConstants.finishStep) ?? -1,
      captured: capturedJson is List
          ? [
              for (final piece in capturedJson)
                if (_jsonMap(piece) case final pieceJson?)
                  LudoPiece.fromJson(pieceJson),
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
class PlayerMatchStats {
  const PlayerMatchStats({
    this.rolls = 0,
    this.moves = 0,
    this.captures = 0,
    this.sixes = 0,
    this.wins = 0,
  });

  final int rolls;
  final int moves;
  final int captures;
  final int sixes;
  final int wins;

  int get actions => moves;

  PlayerMatchStats copyWith({
    int? rolls,
    int? moves,
    int? captures,
    int? sixes,
    int? wins,
  }) {
    return PlayerMatchStats(
      rolls: rolls ?? this.rolls,
      moves: moves ?? this.moves,
      captures: captures ?? this.captures,
      sixes: sixes ?? this.sixes,
      wins: wins ?? this.wins,
    );
  }

  Map<String, Object> toJson() {
    return {
      'rolls': rolls,
      'moves': moves,
      'captures': captures,
      'sixes': sixes,
      'wins': wins,
    };
  }

  factory PlayerMatchStats.fromJson(Map<String, Object?> json) {
    return PlayerMatchStats(
      rolls: _nonNegativeInt(json['rolls']),
      moves: _nonNegativeInt(json['moves']),
      captures: _nonNegativeInt(json['captures']),
      sixes: _nonNegativeInt(json['sixes']),
      wins: _nonNegativeInt(json['wins']),
    );
  }
}

@immutable
class MatchHistoryEntry {
  const MatchHistoryEntry({
    required this.winner,
    required this.finishedAtEpochMilliseconds,
    required this.durationMilliseconds,
    required this.rolls,
    required this.moves,
    required this.captures,
    required this.sixes,
  });

  final PlayerColor winner;
  final int finishedAtEpochMilliseconds;
  final int durationMilliseconds;
  final int rolls;
  final int moves;
  final int captures;
  final int sixes;

  DateTime get finishedAt =>
      DateTime.fromMillisecondsSinceEpoch(finishedAtEpochMilliseconds);
  Duration get duration => Duration(milliseconds: durationMilliseconds);

  Map<String, Object> toJson() {
    return {
      'winner': winner.name,
      'finishedAtEpochMilliseconds': finishedAtEpochMilliseconds,
      'durationMilliseconds': durationMilliseconds,
      'rolls': rolls,
      'moves': moves,
      'captures': captures,
      'sixes': sixes,
    };
  }

  static MatchHistoryEntry? tryFromJson(Object? value) {
    final json = _jsonMap(value);
    final winner = _tryPlayerColorFromJson(json?['winner']);
    final finishedAt = _positiveInt(json?['finishedAtEpochMilliseconds']);
    if (json == null || winner == null || finishedAt == null) {
      return null;
    }
    return MatchHistoryEntry(
      winner: winner,
      finishedAtEpochMilliseconds: finishedAt,
      durationMilliseconds: _nonNegativeInt(json['durationMilliseconds']),
      rolls: _nonNegativeInt(json['rolls']),
      moves: _nonNegativeInt(json['moves']),
      captures: _nonNegativeInt(json['captures']),
      sixes: _nonNegativeInt(json['sixes']),
    );
  }
}

@immutable
class MatchStats {
  MatchStats({
    required this.startedAtEpochMilliseconds,
    this.finishedAtEpochMilliseconds,
    this.rolls = 0,
    this.moves = 0,
    this.captures = 0,
    this.sixes = 0,
    Map<PlayerColor, PlayerMatchStats> byPlayer = const {},
    List<MatchHistoryEntry> history = const [],
  })  : byPlayer = Map.unmodifiable(byPlayer),
        history = List.unmodifiable(history);

  factory MatchStats.newMatch({
    MatchStats? previous,
    DateTime? startedAt,
  }) {
    final priorPlayers = previous?.byPlayer ?? const {};
    return MatchStats(
      startedAtEpochMilliseconds:
          (startedAt ?? DateTime.now()).millisecondsSinceEpoch,
      byPlayer: {
        for (final entry in priorPlayers.entries)
          entry.key: PlayerMatchStats(wins: entry.value.wins),
      },
      history: previous?.history ?? const [],
    );
  }

  final int startedAtEpochMilliseconds;
  final int? finishedAtEpochMilliseconds;
  final int rolls;
  final int moves;
  final int captures;
  final int sixes;
  final Map<PlayerColor, PlayerMatchStats> byPlayer;
  final List<MatchHistoryEntry> history;

  int get actions => moves;
  DateTime get startedAt =>
      DateTime.fromMillisecondsSinceEpoch(startedAtEpochMilliseconds);
  DateTime? get finishedAt => finishedAtEpochMilliseconds == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(finishedAtEpochMilliseconds!);
  Duration get duration => elapsed();

  Duration elapsed({DateTime? at}) {
    final end = finishedAtEpochMilliseconds ??
        (at ?? DateTime.now()).millisecondsSinceEpoch;
    final elapsed = end - startedAtEpochMilliseconds;
    return Duration(milliseconds: elapsed < 0 ? 0 : elapsed);
  }

  PlayerMatchStats forPlayer(PlayerColor color) {
    return byPlayer[color] ?? const PlayerMatchStats();
  }

  int winsFor(PlayerColor color) => forPlayer(color).wins;

  MatchStats recordRoll(PlayerColor color, int diceValue) {
    final player = forPlayer(color);
    return copyWith(
      rolls: rolls + 1,
      sixes: sixes + (diceValue == GameConstants.diceMax ? 1 : 0),
      byPlayer: {
        ...byPlayer,
        color: player.copyWith(
          rolls: player.rolls + 1,
          sixes: player.sixes + (diceValue == GameConstants.diceMax ? 1 : 0),
        ),
      },
    );
  }

  MatchStats recordMove(PlayerColor color, {required int capturedCount}) {
    final safeCapturedCount = capturedCount < 0 ? 0 : capturedCount;
    final player = forPlayer(color);
    return copyWith(
      moves: moves + 1,
      captures: captures + safeCapturedCount,
      byPlayer: {
        ...byPlayer,
        color: player.copyWith(
          moves: player.moves + 1,
          captures: player.captures + safeCapturedCount,
        ),
      },
    );
  }

  MatchStats recordWin(PlayerColor color, {DateTime? at}) {
    final finishedAt = (at ?? DateTime.now()).millisecondsSinceEpoch;
    final elapsed = finishedAt - startedAtEpochMilliseconds;
    final durationMs = elapsed < 0 ? 0 : elapsed;
    final player = forPlayer(color);
    final entry = MatchHistoryEntry(
      winner: color,
      finishedAtEpochMilliseconds: finishedAt,
      durationMilliseconds: durationMs,
      rolls: rolls,
      moves: moves,
      captures: captures,
      sixes: sixes,
    );
    return copyWith(
      finishedAtEpochMilliseconds: finishedAt,
      byPlayer: {
        ...byPlayer,
        color: player.copyWith(wins: player.wins + 1),
      },
      history: [entry, ...history].take(50).toList(growable: false),
    );
  }

  MatchStats copyWith({
    int? startedAtEpochMilliseconds,
    Object? finishedAtEpochMilliseconds = _unset,
    int? rolls,
    int? moves,
    int? captures,
    int? sixes,
    Map<PlayerColor, PlayerMatchStats>? byPlayer,
    List<MatchHistoryEntry>? history,
  }) {
    return MatchStats(
      startedAtEpochMilliseconds:
          startedAtEpochMilliseconds ?? this.startedAtEpochMilliseconds,
      finishedAtEpochMilliseconds:
          identical(finishedAtEpochMilliseconds, _unset)
              ? this.finishedAtEpochMilliseconds
              : finishedAtEpochMilliseconds as int?,
      rolls: rolls ?? this.rolls,
      moves: moves ?? this.moves,
      captures: captures ?? this.captures,
      sixes: sixes ?? this.sixes,
      byPlayer: byPlayer ?? this.byPlayer,
      history: history ?? this.history,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'startedAtEpochMilliseconds': startedAtEpochMilliseconds,
      'finishedAtEpochMilliseconds': finishedAtEpochMilliseconds,
      'rolls': rolls,
      'moves': moves,
      'captures': captures,
      'sixes': sixes,
      'byPlayer': {
        for (final entry in byPlayer.entries)
          entry.key.name: entry.value.toJson(),
      },
      'history': [for (final entry in history) entry.toJson()],
    };
  }

  factory MatchStats.fromJson(Map<String, Object?> json) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final start = _positiveInt(json['startedAtEpochMilliseconds']) ?? now;
    final rawFinished = _positiveInt(json['finishedAtEpochMilliseconds']);
    final byPlayerJson = _jsonMap(json['byPlayer']);
    final historyJson = json['history'];
    return MatchStats(
      startedAtEpochMilliseconds: start,
      finishedAtEpochMilliseconds:
          rawFinished != null && rawFinished >= start ? rawFinished : null,
      rolls: _nonNegativeInt(json['rolls']),
      moves: _nonNegativeInt(json['moves']),
      captures: _nonNegativeInt(json['captures']),
      sixes: _nonNegativeInt(json['sixes']),
      byPlayer: {
        if (byPlayerJson != null)
          for (final color in PlayerColor.values)
            if (_jsonMap(byPlayerJson[color.name]) case final stats?)
              color: PlayerMatchStats.fromJson(stats),
      },
      history: historyJson is List
          ? [
              for (final value in historyJson)
                if (MatchHistoryEntry.tryFromJson(value) case final entry?)
                  entry,
            ].take(50).toList(growable: false)
          : const [],
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
    required this.stats,
  })  : players = List.unmodifiable(players),
        moveLog = List.unmodifiable(moveLog);

  factory LudoGameState.newGame({
    int playerCount = 4,
    RuleOptions rules = const RuleOptions(),
    Map<PlayerColor, String> playerNames = const {},
    Map<PlayerColor, PlayerKind> playerKinds = const {},
    Map<PlayerColor, PlayerAvatarId> playerAvatars = const {},
    Map<PlayerColor, BotDifficulty> botDifficulties = const {},
    MatchStats? previousStats,
    DateTime? startedAt,
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
            kind: playerKinds[color] ?? PlayerKind.human,
            botDifficulty: botDifficulties[color] ?? BotDifficulty.normal,
            avatarId: playerAvatars[color] ?? _defaultAvatarFor(color),
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
      stats: MatchStats.newMatch(
        previous: previousStats,
        startedAt: startedAt,
      ),
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
  final MatchStats stats;

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
    MatchStats? stats,
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
      stats: stats ?? this.stats,
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
      'stats': stats.toJson(),
    };
  }

  factory LudoGameState.fromJson(Map<String, Object?> json) {
    final playersJson = json['players'];
    final rulesJson = _jsonMap(json['rules']);
    final rules = rulesJson == null
        ? const RuleOptions()
        : RuleOptions.fromJson(rulesJson);
    final players = _playersFromJson(playersJson);
    final fallbackCount = playersJson is List &&
            playersJson.length >= GameConstants.minPlayers &&
            playersJson.length <= GameConstants.maxPlayers
        ? playersJson.length
        : GameConstants.maxPlayers;
    final fallback = LudoGameState.newGame(
      playerCount: fallbackCount,
      rules: rules,
    );
    final restoredPlayers = players ?? fallback.players;
    final rawCurrentPlayerIndex = _safeInt(json['currentPlayerIndex']) ?? 0;
    final currentPlayerIndex = rawCurrentPlayerIndex.clamp(
      0,
      restoredPlayers.length - 1,
    );
    final requestedPhase = TurnPhase.values.firstWhere(
      (phase) => phase.name == json['phase'],
      orElse: () => TurnPhase.waitingForRoll,
    );
    final validDice = _intInRange(
      json['diceValue'],
      GameConstants.diceMin,
      GameConstants.diceMax,
    );
    var phase = requestedPhase;
    var diceValue = validDice;
    if (phase == TurnPhase.waitingForMove && diceValue == null) {
      phase = TurnPhase.waitingForRoll;
    }
    final parsedWinner = _tryPlayerColorFromJson(json['winner']);
    var winner = parsedWinner != null &&
            restoredPlayers.any((player) => player.color == parsedWinner)
        ? parsedWinner
        : null;
    if (phase == TurnPhase.gameOver) {
      final winnerPlayer = winner == null
          ? null
          : restoredPlayers.firstWhere(
              (player) => player.color == winner,
              orElse: () => restoredPlayers.first,
            );
      if (winnerPlayer?.hasWon != true) {
        phase = TurnPhase.waitingForRoll;
        winner = null;
        diceValue = null;
      }
    } else {
      winner = null;
    }
    final moveSummary = _moveSummaryFromJson(json['moveSummary']);
    final moveLog = _moveLogFromJson(json['moveLog']);
    final statsJson = _jsonMap(json['stats']);
    final currentPlayer = restoredPlayers[currentPlayerIndex];
    final maxPendingRolls =
        currentPlayer.pieces.every((piece) => piece.isInBase)
            ? rules.rollsWhenNoPieceIsOut
            : GameConstants.minPendingRolls;
    final pendingOpenRolls =
        (_safeInt(json['pendingOpenRolls']) ?? maxPendingRolls)
            .clamp(GameConstants.minPendingRolls, maxPendingRolls);
    final consecutiveSixes = (_safeInt(json['consecutiveSixes']) ?? 0).clamp(
      0,
      GameConstants.consecutiveSixesLimit,
    );
    final rawMessage = json['turnMessage'];
    return LudoGameState(
      players: restoredPlayers,
      currentPlayerIndex: currentPlayerIndex,
      phase: phase,
      diceValue: diceValue,
      winner: winner,
      moveSummary: moveSummary,
      turnMessage: rawMessage is String && rawMessage.trim().isNotEmpty
          ? rawMessage
          : '${currentPlayer.name} ist dran.',
      rules: rules,
      pendingOpenRolls: pendingOpenRolls,
      consecutiveSixes: consecutiveSixes,
      moveLog: moveLog,
      stats: statsJson == null
          ? MatchStats.newMatch()
          : MatchStats.fromJson(statsJson),
    );
  }
}

class _Unset {
  const _Unset();
}

const _unset = _Unset();

Map<String, Object?>? _jsonMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is! Map) {
    return null;
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      return null;
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

int? _safeInt(Object? value) => value is int ? value : null;

int? _positiveInt(Object? value) {
  final parsed = _safeInt(value);
  return parsed != null && parsed > 0 ? parsed : null;
}

int _nonNegativeInt(Object? value) {
  final parsed = _safeInt(value);
  return parsed != null && parsed >= 0 ? parsed : 0;
}

int? _intInRange(Object? value, int minimum, int maximum) {
  final parsed = _safeInt(value);
  if (parsed == null || parsed < minimum || parsed > maximum) {
    return null;
  }
  return parsed;
}

List<LudoPiece> _normalizedPieces(PlayerColor color, Object? value) {
  final piecesById = <int, LudoPiece>{};
  if (value is List) {
    for (var index = 0; index < value.length; index++) {
      final json = _jsonMap(value[index]);
      if (json == null) {
        continue;
      }
      final id = _intInRange(
            json['id'],
            0,
            GameConstants.piecesPerPlayer - 1,
          ) ??
          (index < GameConstants.piecesPerPlayer ? index : null);
      if (id == null || piecesById.containsKey(id)) {
        continue;
      }
      piecesById[id] = LudoPiece(
        color: color,
        id: id,
        steps: _intInRange(json['steps'], -1, GameConstants.finishStep) ?? -1,
      );
    }
  }
  return [
    for (var id = 0; id < GameConstants.piecesPerPlayer; id++)
      piecesById[id] ?? LudoPiece(color: color, id: id, steps: -1),
  ];
}

List<LudoPlayer>? _playersFromJson(Object? value) {
  if (value is! List ||
      value.length < GameConstants.minPlayers ||
      value.length > GameConstants.maxPlayers) {
    return null;
  }
  final players = <LudoPlayer>[];
  final colors = <PlayerColor>{};
  for (final rawPlayer in value) {
    final json = _jsonMap(rawPlayer);
    final color = _tryPlayerColorFromJson(json?['color']);
    if (json == null || color == null || !colors.add(color)) {
      return null;
    }
    players.add(LudoPlayer.fromJson({...json, 'color': color.name}));
  }
  return players;
}

MoveSummary? _moveSummaryFromJson(Object? value) {
  final json = _jsonMap(value);
  if (json == null) {
    return null;
  }
  try {
    return MoveSummary.fromJson(json);
  } on Object {
    return null;
  }
}

List<MoveLogEntry> _moveLogFromJson(Object? value) {
  if (value is! List) {
    return const [];
  }
  final entries = <MoveLogEntry>[];
  for (final rawEntry in value.take(GameConstants.moveLogCap)) {
    final json = _jsonMap(rawEntry);
    if (json == null) {
      continue;
    }
    try {
      entries.add(MoveLogEntry.fromJson(json));
    } on Object {
      // A corrupt log item must not make an otherwise usable save unloadable.
    }
  }
  return entries;
}

PlayerColor? _tryPlayerColorFromJson(Object? value) {
  for (final color in PlayerColor.values) {
    if (color.name == value) {
      return color;
    }
  }
  return null;
}

PlayerColor _playerColorFromJson(Object? value) {
  return _tryPlayerColorFromJson(value) ?? PlayerColor.red;
}

PlayerKind _playerKindFromJson(Object? value) {
  return PlayerKind.values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => PlayerKind.human,
  );
}

BotDifficulty _botDifficultyFromJson(Object? value) {
  return BotDifficulty.values.firstWhere(
    (difficulty) => difficulty.name == value,
    orElse: () => BotDifficulty.normal,
  );
}

PlayerAvatarId _playerAvatarFromJson(
  Object? value, {
  required PlayerColor color,
}) {
  return PlayerAvatarId.values.firstWhere(
    (avatar) => avatar.name == value,
    orElse: () => _defaultAvatarFor(color),
  );
}

PlayerAvatarId _defaultAvatarFor(PlayerColor color) {
  return switch (color) {
    PlayerColor.red => PlayerAvatarId.sisiliya,
    PlayerColor.green => PlayerAvatarId.flora,
    PlayerColor.yellow => PlayerAvatarId.abdul,
    PlayerColor.blue => PlayerAvatarId.kiran,
  };
}
