import 'package:flutter/widgets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/l10n/move_log_formatter.dart';
import 'package:ludo_club/models/ludo_models.dart';

class TurnStatusFormatter {
  const TurnStatusFormatter._();

  static String format(BuildContext context, LudoGameState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.phase == TurnPhase.gameOver) {
      final winner = state.players.firstWhere(
        (player) => player.color == state.winner,
        orElse: () => state.currentPlayer,
      );
      return l10n.playerWins(winner.name);
    }
    if (state.phase == TurnPhase.waitingForMove && state.diceValue != null) {
      return l10n.playerRolled(
        state.currentPlayer.name,
        state.diceValue!,
      );
    }
    if (state.moveLog.isNotEmpty) {
      return MoveLogFormatter.format(context, state.moveLog.first, state);
    }
    return l10n.playerTurn(state.currentPlayer.name);
  }
}
