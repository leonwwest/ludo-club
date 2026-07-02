abstract final class GameConstants {
  static const int minPlayers = 2;
  static const int maxPlayers = 4;
  static const int piecesPerPlayer = 4;
  static const int moveLogCap = 8;
  static const int undoHistoryLimit = 24;
  static const int consecutiveSixesLimit = 3;
  static const int minPendingRolls = 1;
  static const int maxOpenRolls = 3;
  static const int trackLength = 52;
  static const int homeLength = 6;
  static const int finishStep = trackLength + homeLength - 1;
  static const int gridSize = 15;
  static const int diceMin = 1;
  static const int diceMax = 6;
  static const Set<int> safeFields = {0, 8, 13, 21, 26, 34, 39, 47};
}
