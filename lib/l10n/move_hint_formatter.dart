import 'package:flutter/widgets.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/l10n/player_color_localizations.dart';
import 'package:ludo_club/logic/ludo_rules.dart';
import 'package:ludo_club/models/ludo_models.dart';

class MoveHintFormatter {
  const MoveHintFormatter._();

  static String? format(
    BuildContext context,
    LudoGameState state,
    LudoPiece piece,
  ) {
    final target = LudoRules.legalTargetStepsFor(state, piece);
    if (target == null) {
      return null;
    }
    final l10n = AppLocalizations.of(context)!;
    if (target < LudoRules.trackLength) {
      final targetIndex = LudoRules.globalIndexFor(piece.color, target);
      if (!LudoRules.safeFields.contains(targetIndex)) {
        final capturedColors = state.players
            .where((player) => player.color != piece.color)
            .expand((player) => player.pieces)
            .where(
              (candidate) => LudoRules.globalIndexOf(candidate) == targetIndex,
            )
            .map((candidate) => candidate.color)
            .toSet();
        if (capturedColors.isNotEmpty) {
          final labels = capturedColors
              .map((color) => localizedPlayerColor(l10n, color))
              .join(', ');
          return l10n.moveHintCapture(piece.id + 1, labels);
        }
      }
    }
    if (target == LudoRules.finishStep) {
      return l10n.moveHintFinish(piece.id + 1);
    }
    if (piece.isInBase) {
      return l10n.moveHintEnter(piece.id + 1);
    }
    if (target >= LudoRules.trackLength) {
      return l10n.moveHintHome(piece.id + 1);
    }
    return l10n.moveHintField(
      piece.id + 1,
      LudoRules.globalIndexFor(piece.color, target) + 1,
    );
  }
}
