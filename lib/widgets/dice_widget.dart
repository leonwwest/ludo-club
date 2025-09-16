import 'package:flutter/material.dart';
// Removed SVG/foundation imports to simplify and avoid dead code
import 'package:ludo_club/constants/game_constants.dart';

class DiceWidget extends StatefulWidget {
  final Future<void> Function()? onRoll;
  final bool isEnabled;
  final double size;
  final int? currentDiceValue; // Add parameter for actual dice value

  const DiceWidget({
    super.key,
    this.onRoll,
    this.isEnabled = true,
    this.size = 60,
    this.currentDiceValue, // Optional current dice value from game
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with TickerProviderStateMixin {
  int currentValue = 1;
  bool isRolling = false;

  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _shakeController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Set initial dice value
    currentValue = widget.currentDiceValue ?? 1;

    _rotationController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: GameConstants.diceAnimationDuration),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: GameConstants.bounceAnimationDuration),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: GameConstants.shakeAnimationDuration),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1.2, // ~1 rotation for responsiveness
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3, // Bigger bounce effect
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOutQuart,
    ));
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update dice value when it changes from GameProvider
    if (widget.currentDiceValue != null &&
        widget.currentDiceValue != oldWidget.currentDiceValue &&
        !isRolling) {
      setState(() {
        currentValue = widget.currentDiceValue!;
      });
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> rollDice() async {
    if (!widget.isEnabled || isRolling || !mounted) return;

    try {
      setState(() {
        isRolling = true;
      });

      // Start animations (short and responsive)
      _rotationController.forward(from: 0);
      _shakeController.forward(from: 0);
      // Keep pulse minimal to avoid jank

      // Simulate rolling with a few value changes (fast)
      for (int i = 0; i < GameConstants.diceRollSteps; i++) {
        await Future.delayed(
            const Duration(milliseconds: GameConstants.diceRollStepDelay));
        if (mounted) {
          setState(() {
            currentValue = currentValue % GameConstants.diceSides + 1;
          });
        }
      }

      // End animation and wait briefly for GameProvider to provide the actual value
      await Future.delayed(const Duration(milliseconds: 60));
      await widget.onRoll?.call();

      if (!mounted) {
        return;
      }

      setState(() {
        isRolling = false;
        if (widget.currentDiceValue != null && widget.currentDiceValue! > 0) {
          currentValue = widget.currentDiceValue!;
        }
      });

      // Wait a bit for the GameProvider to update, then show bounce effect
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) {
        return;
      }

      _scaleController.forward().then((_) {
        if (mounted) {
          _scaleController.reverse();
        }
      });
    } catch (e) {
      // Reset state if something goes wrong
      if (mounted) {
        setState(() {
          isRolling = false;
        });
      }
    }
  }

  Widget _buildDiceFace() => _buildFallbackDice();

  Widget _buildFallbackDice() {
    return Container(
      width: widget.size * 0.8,
      height: widget.size * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: _buildDiceDots(),
    );
  }

  Widget _buildDiceDots() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dotSize = constraints.maxWidth * 0.15;
        final spacing = constraints.maxWidth * 0.25;

        switch (currentValue) {
          case 1:
            return Center(
              child: _buildDot(dotSize),
            );
          case 2:
            return Stack(
              children: [
                Positioned(
                  left: spacing,
                  top: spacing,
                  child: _buildDot(dotSize),
                ),
                Positioned(
                  right: spacing,
                  bottom: spacing,
                  child: _buildDot(dotSize),
                ),
              ],
            );
          case 3:
            return Stack(
              children: [
                Positioned(
                  left: spacing,
                  top: spacing,
                  child: _buildDot(dotSize),
                ),
                Center(child: _buildDot(dotSize)),
                Positioned(
                  right: spacing,
                  bottom: spacing,
                  child: _buildDot(dotSize),
                ),
              ],
            );
          case 4:
            return Stack(
              children: [
                Positioned(
                    left: spacing, top: spacing, child: _buildDot(dotSize)),
                Positioned(
                    right: spacing, top: spacing, child: _buildDot(dotSize)),
                Positioned(
                    left: spacing, bottom: spacing, child: _buildDot(dotSize)),
                Positioned(
                    right: spacing, bottom: spacing, child: _buildDot(dotSize)),
              ],
            );
          case 5:
            return Stack(
              children: [
                Positioned(
                    left: spacing, top: spacing, child: _buildDot(dotSize)),
                Positioned(
                    right: spacing, top: spacing, child: _buildDot(dotSize)),
                Center(child: _buildDot(dotSize)),
                Positioned(
                    left: spacing, bottom: spacing, child: _buildDot(dotSize)),
                Positioned(
                    right: spacing, bottom: spacing, child: _buildDot(dotSize)),
              ],
            );
          case 6:
            return Stack(
              children: [
                Positioned(
                    left: spacing, top: spacing, child: _buildDot(dotSize)),
                Positioned(
                    right: spacing, top: spacing, child: _buildDot(dotSize)),
                Positioned(
                    left: spacing,
                    top: constraints.maxHeight / 2 - dotSize / 2,
                    child: _buildDot(dotSize)),
                Positioned(
                    right: spacing,
                    top: constraints.maxHeight / 2 - dotSize / 2,
                    child: _buildDot(dotSize)),
                Positioned(
                    left: spacing, bottom: spacing, child: _buildDot(dotSize)),
                Positioned(
                    right: spacing, bottom: spacing, child: _buildDot(dotSize)),
              ],
            );
          default:
            return Center(child: _buildDot(dotSize));
        }
      },
    );
  }

  Widget _buildDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.isEnabled ? Colors.black : Colors.grey.shade600,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build box shadows without collection-if to avoid parser issues
    List<BoxShadow> buildShadows() {
      final shadows = <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: isRolling ? 15 : 6,
          spreadRadius: isRolling ? 3 : 1,
          offset: const Offset(0, 3),
        ),
      ];
      if (isRolling) {
        shadows.add(
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        );
      }
      return shadows;
    }

    return Semantics(
      label: 'Dice',
      hint: widget.isEnabled ? 'Tap to roll' : 'Disabled',
      button: true,
      enabled: widget.isEnabled,
      child: GestureDetector(
        onTap: rollDice,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _rotationAnimation,
            _scaleAnimation,
            _shakeAnimation,
          ]),
          builder: (context, child) {
            final double shakeIntensity = isRolling ? 6.0 : 0.0;

            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.translate(
                offset: Offset(
                  math.sin(_shakeAnimation.value * 6 * math.pi) *
                      shakeIntensity,
                  math.cos(_shakeAnimation.value * 4 * math.pi) *
                      (shakeIntensity * 0.7),
                ),
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 2 * math.pi,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: buildShadows(),
                      gradient: widget.isEnabled
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFFFFFFFF),
                                Color(0xFFF0F0F0),
                              ],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Colors.grey.shade300,
                                Colors.grey.shade400,
                              ],
                            ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Opacity(
                          opacity: isRolling ? 0.8 : 1.0,
                          child: _buildDiceFace(),
                        ),
                        if (isRolling)
                          Container(
                            width: widget.size,
                            height: widget.size,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  Colors.blue.withValues(alpha: 0.15),
                                  Colors.purple.withValues(alpha: 0.15),
                                  Colors.cyan.withValues(alpha: 0.10),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
