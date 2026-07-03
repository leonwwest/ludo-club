import 'package:flutter/material.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';
import 'package:ludo_club/models/move_event.dart';

class MoveLogFormatter {
  const MoveLogFormatter._();

  static String format(
    BuildContext context,
    MoveLogEntry entry,
    LudoGameState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final player = _playerName(entry.event.player, state);
    return _formatEvent(context, l10n, entry.event, player);
  }

  static String _playerName(PlayerColor color, LudoGameState state) {
    for (final player in state.players) {
      if (player.color == color) {
        return player.name;
      }
    }
    return color.label;
  }

  static String _formatEvent(
    BuildContext context,
    AppLocalizations l10n,
    MoveEvent event,
    String playerName,
  ) {
    return switch (event) {
      RollEvent(:final diceValue) => l10n.moveLogRoll(playerName, diceValue),
      NoMoveEvent(:final diceValue) =>
        l10n.moveLogNoMove(playerName, diceValue),
      ThreeSixesEvent() => l10n.moveLogThreeSixes(playerName),
      ExtraRollEvent(:final diceValue, :final attempt) =>
        l10n.moveLogRoll(playerName, diceValue),
      MovePieceEvent(
        :final pieceId,
        :final diceValue,
        :final capturedCount,
        :final finished,
      ) =>
        l10n.moveLogMovePiece(
          playerName,
          diceValue,
          pieceId + 1,
          capturedCount > 0 ? l10n.moveLogCapture(capturedCount) : '',
          finished ? l10n.moveLogFinish : '',
        ),
      WinEvent() => l10n.moveLogWin(playerName),
    };
  }
}
