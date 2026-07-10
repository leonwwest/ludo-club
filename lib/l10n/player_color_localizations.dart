import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';

String localizedPlayerColor(
  AppLocalizations l10n,
  PlayerColor color,
) {
  return switch (color) {
    PlayerColor.red => l10n.colorRed,
    PlayerColor.green => l10n.colorGreen,
    PlayerColor.yellow => l10n.colorYellow,
    PlayerColor.blue => l10n.colorBlue,
  };
}
