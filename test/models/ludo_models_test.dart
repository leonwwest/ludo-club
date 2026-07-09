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

    test('fromJson clamps currentPlayerIndex', () {
      final restored = LudoGameState.fromJson(const {
        'currentPlayerIndex': 999,
      });

      expect(restored.currentPlayerIndex, lessThanOrEqualTo(3));
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
      );

      final restored = RuleOptions.fromJson(rules.toJson());

      expect(restored.openRollRule, OpenRollRule.threeRolls);
      expect(restored.mustLeaveBaseOnSix, isTrue);
      expect(restored.blockOwnFields, isTrue);
      expect(restored.extraTurnOnFinish, isTrue);
      expect(restored.extraTurnOnCapture, isFalse);
      expect(restored.threeSixesEndTurn, isTrue);
      expect(restored.mustCapture, isTrue);
    });

    test('RuleOptions.fromJson falls back to defaults for missing fields', () {
      final restored = RuleOptions.fromJson(const {});

      expect(restored.openRollRule, OpenRollRule.oneRoll);
      expect(restored.extraTurnOnCapture, isTrue);
    });

    test('LudoPlayer kind and avatar round-trip through JSON', () {
      final player = LudoPlayer(
        color: PlayerColor.green,
        name: 'Flora',
        kind: PlayerKind.bot,
        avatarId: PlayerAvatarId.kiran,
        pieces: const [
          LudoPiece(color: PlayerColor.green, id: 0, steps: -1),
        ],
      );

      final restored = LudoPlayer.fromJson(player.toJson());

      expect(restored.kind, PlayerKind.bot);
      expect(restored.avatarId, PlayerAvatarId.kiran);
      expect(restored.isBot, isTrue);
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
