import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiceWidget extends StatefulWidget {
  final Function(int) onRoll;
  final bool isEnabled;
  final double size;
  final int? currentDiceValue; // Add parameter for actual dice value

  const DiceWidget({
    Key? key, 
    required this.onRoll,
    this.isEnabled = true,
    this.size = 60,
    this.currentDiceValue, // Optional current dice value from game
  }) : super(key: key);

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> 
    with TickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 800), // Perfectly synced with rolling duration
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 4, // 4 full rotations for more drama
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
    if (!widget.isEnabled || isRolling) return;

    setState(() {
      isRolling = true;
    });

    // Start main animations for spectacular effect
    _rotationController.forward(from: 0);
    _shakeController.forward(from: 0);
    // Removed complex pulse animations to prevent glitches
    
    // Simulate rolling with multiple value changes (faster animation)
    // Optimized for better game speed (400ms total)
    for (int i = 0; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() {
          currentValue = Random().nextInt(6) + 1;
        });
      }
    }

    // End animation and wait for GameProvider to provide the actual value
    // Total time: 6 × 50ms + 100ms = 400ms (faster gameplay!)
    await Future.delayed(const Duration(milliseconds: 100));
    
        if (mounted) {
      setState(() {
        isRolling = false;
      });
      
      // Animations will complete naturally with their duration
      
      // Call the callback to trigger game logic
      // The GameProvider will set the actual dice value
      widget.onRoll(0); // Pass 0 as placeholder, GameProvider handles actual dice roll
      
      // Wait a bit for the GameProvider to update, then show bounce effect
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        // Use the value from GameProvider if available, otherwise keep current
        if (widget.currentDiceValue != null && widget.currentDiceValue! > 0) {
          setState(() {
            currentValue = widget.currentDiceValue!;
          });
        }
        
        // Enhanced bounce effect on landing
        _scaleController.forward().then((_) {
          _scaleController.reverse();
        });
        
        // Simple completion effect (removed complex glow)
        // The bounce effect is sufficient visual feedback
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: rollDice,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationAnimation,
          _scaleAnimation,
          _shakeAnimation,
        ]),
        builder: (context, child) {
          final shakeIntensity = isRolling ? 6.0 : 0.0; // Stronger shake during rolling
          
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(
                sin(_shakeAnimation.value * 6 * pi) * shakeIntensity,
                cos(_shakeAnimation.value * 4 * pi) * (shakeIntensity * 0.7),
              ),
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * pi,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      // Main shadow
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: isRolling ? 15 : 6,
                        spreadRadius: isRolling ? 3 : 1,
                        offset: const Offset(0, 3),
                      ),
                      // Simplified glow effect during rolling
                      if (isRolling)
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 3,
                          offset: const Offset(0, 0),
                        ),
                    ],
                    gradient: widget.isEnabled
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFFF0F0F0),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade400,
                            ],
                          ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dice SVG with stable effects
                      Opacity(
                        opacity: isRolling ? 0.8 : 1.0,
                        child: SvgPicture.asset(
                          'assets/dice/dice_$currentValue.svg',
                          width: widget.size * 0.8,
                          height: widget.size * 0.8,
                          colorFilter: widget.isEnabled
                              ? null
                              : ColorFilter.mode(
                                  Colors.grey.shade600,
                                  BlendMode.srcIn,
                                ),
                        ),
                      ),
                      
                      // Simplified rolling indicator
                      if (isRolling)
                        Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.withOpacity(0.15),
                                Colors.purple.withOpacity(0.15),
                                Colors.cyan.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      
                      // No overlay when disabled - keep dice visible
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}