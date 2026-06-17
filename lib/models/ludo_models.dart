import 'package:flutter/foundation.dart';

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

  String get avatarAsset {
    return switch (this) {
      PlayerColor.red => 'assets/avatars/sisiliya_v2.png',
      PlayerColor.green => 'assets/avatars/flora_v2.png',
      PlayerColor.yellow => 'assets/avatars/abdul_v2.png',
      PlayerColor.blue => 'assets/avatars/kiran_v2.png',
    };
  }

  String get pinAsset {
    return switch (this) {
      PlayerColor.red => 'assets/pins/pin_red_v2.png',
      PlayerColor.green => 'assets/pins/pin_green_v2.png',
      PlayerColor.yellow => 'assets/pins/pin_yellow_v2.png',
      PlayerColor.blue => 'assets/pins/pin_blue_v2.png',
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
}

@immutable
class LudoPlayer {
  const LudoPlayer({
    required this.color,
    required this.name,
    required this.pieces,
  });

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
}

@immutable
class MoveSummary {
  const MoveSummary({
    required this.mover,
    required this.pieceId,
    required this.fromSteps,
    required this.toSteps,
    required this.captured,
    required this.extraTurn,
    required this.finished,
  });

  final PlayerColor mover;
  final int pieceId;
  final int fromSteps;
  final int toSteps;
  final List<LudoPiece> captured;
  final bool extraTurn;
  final bool finished;

  bool get didCapture => captured.isNotEmpty;
}

@immutable
class LudoGameState {
  const LudoGameState({
    required this.players,
    required this.currentPlayerIndex,
    required this.phase,
    required this.diceValue,
    required this.winner,
    required this.moveSummary,
    required this.turnMessage,
  });

  factory LudoGameState.newGame({int playerCount = 4}) {
    assert(playerCount >= 2 && playerCount <= 4);
    final colors = colorsForPlayerCount(playerCount);
    return LudoGameState(
      players: [
        for (final color in colors)
          LudoPlayer(
            color: color,
            name: color.label,
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
    );
  }

  final List<LudoPlayer> players;
  final int currentPlayerIndex;
  final TurnPhase phase;
  final int? diceValue;
  final PlayerColor? winner;
  final MoveSummary? moveSummary;
  final String turnMessage;

  LudoPlayer get currentPlayer => players[currentPlayerIndex];
  List<PlayerColor> get activeColors =>
      players.map((player) => player.color).toList();

  static List<PlayerColor> colorsForPlayerCount(int playerCount) {
    return switch (playerCount) {
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
    );
  }
}

class _Unset {
  const _Unset();
}

const _unset = _Unset();
