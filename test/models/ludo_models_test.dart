import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/ludo_models.dart';

void main() {
  group('LudoGameState', () {
    test('newGame throws ArgumentError for invalid player count', () {
      expect(() => LudoGameState.newGame(playerCount: 1), throwsArgumentError);
      expect(() => LudoGameState.newGame(playerCount: 5), throwsArgumentError);
      expect(() => LudoGameState.newGame(playerCount: 0), throwsArgumentError);
    });

    test('newGame creates correct players for 2 players', () {
      final state = LudoGameState.newGame(
        playerCount: 2,
        playerKinds: const {PlayerColor.yellow: PlayerKind.bot},
        playerAvatars: const {PlayerColor.yellow: PlayerAvatarId.kiran},
      );

      expect(state.players, hasLength(2));
      expect(state.players[0].color, PlayerColor.red);
      expect(state.players[1].color, PlayerColor.yellow);
      expect(state.players[1].kind, PlayerKind.bot);
      expect(state.players[1].avatarId, PlayerAvatarId.kiran);
    });

    test('newGame creates correct players for 3 players', () {
      final state = LudoGameState.newGame(playerCount: 3);

      expect(state.players, hasLength(3));
      expect(state.players[2].color, PlayerColor.yellow);
    });

    test('colorsForPlayerCount clamps invalid counts', () {
      expect(LudoGameState.colorsForPlayerCount(0), hasLength(2));
      expect(LudoGameState.colorsForPlayerCount(99), hasLength(4));
    });

    test('fromJson handles missing fields with defaults', () {
      final restored = LudoGameState.fromJson(const {});

      expect(restored.players, isNotEmpty);
      expect(restored.phase, TurnPhase.waitingForRoll);
      expect(restored.diceValue, isNull);
      expect(restored.winner, isNull);
    });

    test('fromJson handles corrupt players list', () {
      final restored = LudoGameState.fromJson(const {
        'players': 'not a list',
      });

      expect(restored.players, isNotEmpty);
    });

    test('fromJson clamps currentPlayerIndex to restored player count', () {
      final json = LudoGameState.newGame(playerCount: 2).toJson()
        ..['currentPlayerIndex'] = 999;

      final restored = LudoGameState.fromJson(json);

      expect(restored.players, hasLength(2));
      expect(restored.currentPlayerIndex, 1);
      expect(restored.currentPlayer, same(restored.players.last));
    });

    test('fromJson repairs invalid dice and phase combinations', () {
      final json = LudoGameState.newGame(playerCount: 2).toJson()
        ..['phase'] = TurnPhase.waitingForMove.name
        ..['diceValue'] = 99;

      final restored = LudoGameState.fromJson(json);

      expect(restored.phase, TurnPhase.waitingForRoll);
      expect(restored.diceValue, isNull);
    });

    test('fromJson falls back when player count or colors are invalid', () {
      final onePlayer = LudoGameState.fromJson({
        'players': [
          LudoGameState.newGame(playerCount: 2).players.first.toJson(),
        ],
      });
      final duplicated = LudoGameState.fromJson({
        'players': [
          LudoGameState.newGame(playerCount: 2).players.first.toJson(),
          LudoGameState.newGame(playerCount: 2).players.first.toJson(),
        ],
      });

      expect(onePlayer.players, hasLength(4));
      expect(duplicated.players, hasLength(2));
      expect(duplicated.activeColors, [PlayerColor.red, PlayerColor.yellow]);
    });

    test('fromJson normalizes missing and corrupt pieces', () {
      final json = LudoGameState.newGame(playerCount: 2).toJson();
      final players = json['players']! as List<Object?>;
      final red = players.first! as Map<String, Object?>;
      red['pieces'] = [
        {'color': 'blue', 'id': 0, 'steps': 999},
        {'color': 'blue', 'id': 0, 'steps': 12},
        {'color': 'yellow', 'id': 2, 'steps': 14},
      ];

      final restored = LudoGameState.fromJson(json);
      final pieces = restored.players.first.pieces;

      expect(pieces, hasLength(4));
      expect(pieces.map((piece) => piece.id), [0, 1, 2, 3]);
      expect(pieces.every((piece) => piece.color == PlayerColor.red), isTrue);
      expect(pieces[0].steps, -1);
      expect(pieces[1].steps, -1);
      expect(pieces[2].steps, 14);
    });

    test('RuleOptions round-trips through JSON', () {
      const rules = RuleOptions(
        openRollRule: OpenRollRule.threeRolls,
        mustLeaveBaseOnSix: true,
        blockOwnFields: true,
        extraTurnOnFinish: true,
        extraTurnOnCapture: false,
        threeSixesEndTurn: true,
        mustCapture: true,
        extraTurnOnSixNoMove: false,
        doublePieceBlockades: true,
      );

      final restored = RuleOptions.fromJson(rules.toJson());

      expect(restored.openRollRule, OpenRollRule.threeRolls);
      expect(restored.mustLeaveBaseOnSix, isTrue);
      expect(restored.blockOwnFields, isTrue);
      expect(restored.extraTurnOnFinish, isTrue);
      expect(restored.extraTurnOnCapture, isFalse);
      expect(restored.threeSixesEndTurn, isTrue);
      expect(restored.mustCapture, isTrue);
      expect(restored.extraTurnOnSixNoMove, isFalse);
      expect(restored.doublePieceBlockades, isTrue);
    });

    test('RuleOptions.fromJson falls back to defaults for missing fields', () {
      final restored = RuleOptions.fromJson(const {});

      expect(restored.openRollRule, OpenRollRule.oneRoll);
      expect(restored.extraTurnOnCapture, isTrue);
      expect(restored.extraTurnOnSixNoMove, isTrue);
      expect(restored.doublePieceBlockades, isFalse);
    });

    test('LudoPlayer kind and avatar round-trip through JSON', () {
      final player = LudoPlayer(
        color: PlayerColor.green,
        name: 'Flora',
        kind: PlayerKind.bot,
        botDifficulty: BotDifficulty.hard,
        avatarId: PlayerAvatarId.kiran,
        pieces: const [
          LudoPiece(color: PlayerColor.green, id: 0, steps: -1),
        ],
      );

      final restored = LudoPlayer.fromJson(player.toJson());

      expect(restored.kind, PlayerKind.bot);
      expect(restored.avatarId, PlayerAvatarId.kiran);
      expect(restored.botDifficulty, BotDifficulty.hard);
      expect(restored.isBot, isTrue);
    });

    test('old player JSON defaults bot difficulty to normal', () {
      final json = LudoGameState.newGame(playerCount: 2).players.last.toJson()
        ..remove('botDifficulty');

      final restored = LudoPlayer.fromJson(json);

      expect(restored.botDifficulty, BotDifficulty.normal);
    });

    test('match stats and cumulative history round-trip', () {
      final startedAt = DateTime.fromMillisecondsSinceEpoch(1000);
      final finishedAt = DateTime.fromMillisecondsSinceEpoch(5000);
      final stats = MatchStats.newMatch(startedAt: startedAt)
          .recordRoll(PlayerColor.red, 6)
          .recordMove(PlayerColor.red, capturedCount: 2)
          .recordWin(PlayerColor.red, at: finishedAt);

      final restored = MatchStats.fromJson(stats.toJson());

      expect(restored.rolls, 1);
      expect(restored.moves, 1);
      expect(restored.actions, 1);
      expect(restored.captures, 2);
      expect(restored.sixes, 1);
      expect(restored.forPlayer(PlayerColor.red).rolls, 1);
      expect(restored.winsFor(PlayerColor.red), 1);
      expect(restored.duration, const Duration(seconds: 4));
      expect(restored.history, hasLength(1));
      expect(restored.history.single.winner, PlayerColor.red);
      expect(restored.history.single.moves, 1);

      final rematch = MatchStats.newMatch(
        previous: restored,
        startedAt: DateTime.fromMillisecondsSinceEpoch(6000),
      );
      expect(rematch.rolls, 0);
      expect(rematch.winsFor(PlayerColor.red), 1);
      expect(rematch.history, hasLength(1));
    });

    test('old game JSON restores with backward-compatible defaults', () {
      final json = LudoGameState.newGame(playerCount: 2).toJson()
        ..remove('stats');
      final players = json['players']! as List<Object?>;
      for (final player in players) {
        (player! as Map<String, Object?>).remove('botDifficulty');
      }
      (json['rules']! as Map<String, Object?>)
        ..remove('extraTurnOnSixNoMove')
        ..remove('doublePieceBlockades');

      final restored = LudoGameState.fromJson(json);

      expect(restored.stats.rolls, 0);
      expect(
        restored.players.every(
          (player) => player.botDifficulty == BotDifficulty.normal,
        ),
        isTrue,
      );
      expect(restored.rules.extraTurnOnSixNoMove, isTrue);
      expect(restored.rules.doublePieceBlockades, isFalse);
    });

    test('LudoPiece state getters', () {
      const basePiece = LudoPiece(color: PlayerColor.red, id: 0, steps: -1);
      expect(basePiece.isInBase, isTrue);
      expect(basePiece.isOnMainTrack, isFalse);
      expect(basePiece.isFinished, isFalse);

      const trackPiece = LudoPiece(color: PlayerColor.red, id: 0, steps: 10);
      expect(trackPiece.isInBase, isFalse);
      expect(trackPiece.isOnMainTrack, isTrue);
      expect(trackPiece.isInHomeLane, isFalse);

      const homePiece = LudoPiece(color: PlayerColor.red, id: 0, steps: 54);
      expect(homePiece.isInHomeLane, isTrue);
      expect(homePiece.isFinished, isFalse);

      const finishedPiece = LudoPiece(color: PlayerColor.red, id: 0, steps: 57);
      expect(finishedPiece.isFinished, isTrue);
    });

    test('LudoPlayer.hasWon is true when all pieces finished', () {
      final player = LudoPlayer(
        color: PlayerColor.red,
        name: 'Red',
        pieces: const [
          LudoPiece(color: PlayerColor.red, id: 0, steps: 57),
          LudoPiece(color: PlayerColor.red, id: 1, steps: 57),
          LudoPiece(color: PlayerColor.red, id: 2, steps: 57),
          LudoPiece(color: PlayerColor.red, id: 3, steps: 57),
        ],
      );

      expect(player.hasWon, isTrue);
      expect(player.finishedCount, 4);
    });

    test('LudoPlayer.hasWon is false when not all pieces finished', () {
      final player = LudoPlayer(
        color: PlayerColor.red,
        name: 'Red',
        pieces: const [
          LudoPiece(color: PlayerColor.red, id: 0, steps: 57),
          LudoPiece(color: PlayerColor.red, id: 1, steps: 10),
          LudoPiece(color: PlayerColor.red, id: 2, steps: 57),
          LudoPiece(color: PlayerColor.red, id: 3, steps: 57),
        ],
      );

      expect(player.hasWon, isFalse);
      expect(player.finishedCount, 3);
    });
  });
}
