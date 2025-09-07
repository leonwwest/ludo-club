class GameConstants {
  // Board dimensions
  static const int boardGridSize = 15;
  static const int totalMainPathFields = 52;
  static const int homePathLength = 6;
  static const int tokensPerPlayer = 4;
  static const int diceSides = 6;
  static const int requiredRollToLeaveBase = 6;
  
  // Animation durations
  static const int diceAnimationDuration = 800;
  static const int pieceMoveDuration = 200;
  static const int bounceAnimationDuration = 200;
  static const int shakeAnimationDuration = 600;
  
  // Game timing
  static const int diceRollSteps = 6;
  static const int diceRollStepDelay = 50;
  static const int aiMinThinkingTime = 500;
  static const int aiMaxThinkingTime = 1500;
  
  // UI dimensions
  static const double pinSizeRatio = 1.0 / 15.0; // Pin size relative to board size
  static const double pinHeightRatio = 1.2; // Teardrop height multiplier
  static const double boardCornerRadius = 8.0;
  
  // Default positions
  static const int basePosition = -1;
  static const int finishedPosition = 99;
} 
