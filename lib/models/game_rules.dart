class GameRules {
  final bool mustRollSixToStart; // Must roll 6 to get out of home
  final bool extraTurnOnSix; // Get extra turn when rolling 6
  final bool extraTurnOnCapture; // Get extra turn when capturing opponent
  final int maxConsecutiveSixes; // Maximum consecutive 6s before losing turn
  final bool safeFieldsEnabled; // Safe fields prevent capture
  final bool captureReturnsToHome; // Captured pieces return to home base
  final bool multipleOccupancyAllowed; // Multiple pieces on same field
  final int piecesToWin; // Number of pieces needed in finish to win
  final bool exactRollToFinish; // Need exact roll to enter finish position
  final double aiThinkingTimeMultiplier; // Multiplier for AI thinking time (0.5 = faster, 2.0 = slower)

  const GameRules({
    this.mustRollSixToStart = true,
    this.extraTurnOnSix = true,
    this.extraTurnOnCapture = true,
    this.maxConsecutiveSixes = 3,
    this.safeFieldsEnabled = true,
    this.captureReturnsToHome = true,
    this.multipleOccupancyAllowed = false,
    this.piecesToWin = 4,
    this.exactRollToFinish = true,
    this.aiThinkingTimeMultiplier = 1.0,
  });

  // Standard Ludo rules
  static const GameRules standard = GameRules();

  // Quick play rules (faster games)
  static const GameRules quickPlay = GameRules(
    piecesToWin: 2,
    aiThinkingTimeMultiplier: 0.7,
    maxConsecutiveSixes: 2,
  );

  // Beginner friendly rules
  static const GameRules beginner = GameRules(
    mustRollSixToStart: false,
    exactRollToFinish: false,
    maxConsecutiveSixes: 4,
    aiThinkingTimeMultiplier: 1.2,
  );

  // Expert rules (more challenging)
  static const GameRules expert = GameRules(
    maxConsecutiveSixes: 2,
    multipleOccupancyAllowed: true,
    aiThinkingTimeMultiplier: 0.8,
  );

  // Chaos mode (fun variant)
  static const GameRules chaos = GameRules(
    mustRollSixToStart: false,
    safeFieldsEnabled: false,
    multipleOccupancyAllowed: true,
    maxConsecutiveSixes: 5,
    piecesToWin: 3,
  );

  GameRules copyWith({
    bool? mustRollSixToStart,
    bool? extraTurnOnSix,
    bool? extraTurnOnCapture,
    int? maxConsecutiveSixes,
    bool? safeFieldsEnabled,
    bool? captureReturnsToHome,
    bool? multipleOccupancyAllowed,
    int? piecesToWin,
    bool? exactRollToFinish,
    double? aiThinkingTimeMultiplier,
  }) {
    return GameRules(
      mustRollSixToStart: mustRollSixToStart ?? this.mustRollSixToStart,
      extraTurnOnSix: extraTurnOnSix ?? this.extraTurnOnSix,
      extraTurnOnCapture: extraTurnOnCapture ?? this.extraTurnOnCapture,
      maxConsecutiveSixes: maxConsecutiveSixes ?? this.maxConsecutiveSixes,
      safeFieldsEnabled: safeFieldsEnabled ?? this.safeFieldsEnabled,
      captureReturnsToHome: captureReturnsToHome ?? this.captureReturnsToHome,
      multipleOccupancyAllowed: multipleOccupancyAllowed ?? this.multipleOccupancyAllowed,
      piecesToWin: piecesToWin ?? this.piecesToWin,
      exactRollToFinish: exactRollToFinish ?? this.exactRollToFinish,
      aiThinkingTimeMultiplier: aiThinkingTimeMultiplier ?? this.aiThinkingTimeMultiplier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mustRollSixToStart': mustRollSixToStart,
      'extraTurnOnSix': extraTurnOnSix,
      'extraTurnOnCapture': extraTurnOnCapture,
      'maxConsecutiveSixes': maxConsecutiveSixes,
      'safeFieldsEnabled': safeFieldsEnabled,
      'captureReturnsToHome': captureReturnsToHome,
      'multipleOccupancyAllowed': multipleOccupancyAllowed,
      'piecesToWin': piecesToWin,
      'exactRollToFinish': exactRollToFinish,
      'aiThinkingTimeMultiplier': aiThinkingTimeMultiplier,
    };
  }

  factory GameRules.fromJson(Map<String, dynamic> json) {
    return GameRules(
      mustRollSixToStart: json['mustRollSixToStart'] as bool? ?? true,
      extraTurnOnSix: json['extraTurnOnSix'] as bool? ?? true,
      extraTurnOnCapture: json['extraTurnOnCapture'] as bool? ?? true,
      maxConsecutiveSixes: json['maxConsecutiveSixes'] as int? ?? 3,
      safeFieldsEnabled: json['safeFieldsEnabled'] as bool? ?? true,
      captureReturnsToHome: json['captureReturnsToHome'] as bool? ?? true,
      multipleOccupancyAllowed: json['multipleOccupancyAllowed'] as bool? ?? false,
      piecesToWin: json['piecesToWin'] as int? ?? 4,
      exactRollToFinish: json['exactRollToFinish'] as bool? ?? false,
      aiThinkingTimeMultiplier: json['aiThinkingTimeMultiplier'] as double? ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameRules &&
        other.mustRollSixToStart == mustRollSixToStart &&
        other.extraTurnOnSix == extraTurnOnSix &&
        other.extraTurnOnCapture == extraTurnOnCapture &&
        other.maxConsecutiveSixes == maxConsecutiveSixes &&
        other.safeFieldsEnabled == safeFieldsEnabled &&
        other.captureReturnsToHome == captureReturnsToHome &&
        other.multipleOccupancyAllowed == multipleOccupancyAllowed &&
        other.piecesToWin == piecesToWin &&
        other.exactRollToFinish == exactRollToFinish &&
        other.aiThinkingTimeMultiplier == aiThinkingTimeMultiplier;
  }

  @override
  int get hashCode {
    return Object.hash(
      mustRollSixToStart,
      extraTurnOnSix,
      extraTurnOnCapture,
      maxConsecutiveSixes,
      safeFieldsEnabled,
      captureReturnsToHome,
      multipleOccupancyAllowed,
      piecesToWin,
      exactRollToFinish,
      aiThinkingTimeMultiplier,
    );
  }

  @override
  String toString() {
    return 'GameRules('
        'mustRollSixToStart: $mustRollSixToStart, '
        'extraTurnOnSix: $extraTurnOnSix, '
        'extraTurnOnCapture: $extraTurnOnCapture, '
        'maxConsecutiveSixes: $maxConsecutiveSixes, '
        'safeFieldsEnabled: $safeFieldsEnabled, '
        'captureReturnsToHome: $captureReturnsToHome, '
        'multipleOccupancyAllowed: $multipleOccupancyAllowed, '
        'piecesToWin: $piecesToWin, '
        'exactRollToFinish: $exactRollToFinish, '
        'aiThinkingTimeMultiplier: $aiThinkingTimeMultiplier'
        ')';
  }
} 
