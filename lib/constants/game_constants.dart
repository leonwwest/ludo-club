class GameConstants {
  // Board dimensions
  static const int boardGridSize = 15;
  static const int totalMainPathFields = 52;
  static const int homePathLength = 5;
  static const int tokensPerPlayer = 4;
  static const int diceSides = 6;
  static const int requiredRollToLeaveBase = 6;

  // Animation durations
  static const int diceAnimationDuration = 350; // Faster dice spin
  static const int pieceMoveDuration = 140; // Snappier piece moves
  static const int bounceAnimationDuration = 140;
  static const int shakeAnimationDuration = 300;

  // Game timing
  static const int diceRollSteps = 4; // Fewer intermediate faces
  static const int diceRollStepDelay = 40; // Quicker cycle
  static const int aiMinThinkingTime = 150;
  static const int aiMaxThinkingTime = 350;

  // UI dimensions
  static const double pinSizeRatio =
      1.0 / 15.0; // Pin size relative to board size
  static const double pinHeightRatio = 1.2; // Teardrop height multiplier
  static const double boardCornerRadius = 8.0;

  // Main-path safe tiles shared across rulesets
  static const Set<int> safeMainPathFields = {
    0,
    8,
    13,
    21,
    26,
    34,
    39,
    47,
  };

  // Default positions
  static const int basePosition = -1;
  static const int finishedPosition = 99;
}
