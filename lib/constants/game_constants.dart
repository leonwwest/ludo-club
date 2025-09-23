class GameConstants {
  // Board dimensions
  static const int boardGridSize = 15;
  static const int totalMainPathFields = 52;
  static const int homePathLength = 6;
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
  // Visual padding used inside LudoPin (AnimatedContainer padding)
  // Used to correct placement so the SVG tip aligns to board centers
  static const double pinPaddingPx = 4.0;
  static const double boardCornerRadius = 8.0;

  // High-res board asset margins expressed as a fraction of the image side.
  // These measurements ensure piece coordinates align with the printed grid.
  // New board art has only a slim decorative frame, so we use per-side
  // measurements taken from the asset (in pixels) to anchor the logical grid.
  static const double boardInsetLeftRatio = 0.00220511787544;
  static const double boardInsetRightRatio = 0.00347480686762;
  static const double boardInsetTopRatio = 0.00245336875042;
  static const double boardInsetBottomRatio = 0.00444077375595;

  // Main-path safe tiles shared across rulesets
  static const Set<int> safeMainPathFields = {
    0,
    5,
    13,
    18,
    26,
    31,
    39,
    44,
  };

  // UI-only offset to align logical main-path indices to the board asset.
  // If pieces appear one tile after the expected colored start tile, set to -1.
  static const int uiMainPathIndexOffset = 0;

  // Default positions
  static const int basePosition = -1;
  static const int finishedPosition = 99;
}
