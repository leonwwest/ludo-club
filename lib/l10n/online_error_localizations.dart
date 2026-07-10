import 'package:ludo_club/l10n/app_localizations.dart';

String localizedOnlineError(AppLocalizations l10n, Object? error) {
  final message = error?.toString() ?? '';
  if (message.contains('Raum nicht gefunden')) {
    return l10n.onlineErrorRoomNotFound;
  }
  if (message.contains('Raum ist bereits voll')) {
    return l10n.onlineErrorRoomFull;
  }
  if (message.contains('Raumcode') || message.contains('room identity')) {
    return l10n.invalidRoomCode;
  }
  if (message.contains('Host')) {
    return l10n.onlineHostRestartOnly;
  }
  if (message.contains('nicht möglich') ||
      message.contains('nicht erlaubt') ||
      message.contains('Zuerst Raum') ||
      message.contains('Figur fehlt') ||
      message.contains('Unbekannte Aktion')) {
    return l10n.onlineErrorActionRejected;
  }
  if (message.contains('ungültige Daten') ||
      message.contains('Ungültige Nachricht') ||
      message.contains('Invalid')) {
    return l10n.onlineErrorInvalidData;
  }
  if (message.contains('TimeoutException') ||
      message.contains('Zeitüberschreitung') ||
      message.contains('antwortet nicht')) {
    return l10n.onlineErrorTimeout;
  }
  if (message.contains('SocketException') ||
      message.contains('Connection refused') ||
      message.contains('WebSocket')) {
    return l10n.onlineErrorUnavailable;
  }
  return l10n.onlineConnectionError;
}
