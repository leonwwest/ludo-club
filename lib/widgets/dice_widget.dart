import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiceWidget extends StatefulWidget {
  final Function(int) onRoll;
  final bool isEnabled;
  final double size;

  const DiceWidget({
    Key? key, 
    required this.onRoll,
    this.isEnabled = true,
    this.size = 60,
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
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2, // 2 full rotations
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticInOut,
    ));
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

    // Start animations
    _rotationController.forward(from: 0);
    _shakeController.forward(from: 0);
    
    // Simulate rolling with multiple value changes
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 75));
      if (mounted) {
        setState(() {
          currentValue = Random().nextInt(6) + 1;
        });
      }
    }

    // Final value and animations
    await Future.delayed(const Duration(milliseconds: 100));
    final int finalValue = Random().nextInt(6) + 1;
    
    if (mounted) {
      setState(() {
        currentValue = finalValue;
        isRolling = false;
      });
      
      // Bounce effect on landing
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
      
      // Call the callback with the result
      widget.onRoll(finalValue);
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
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(
                sin(_shakeAnimation.value * 4 * pi) * 3,
                cos(_shakeAnimation.value * 4 * pi) * 2,
              ),
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * pi,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: isRolling ? 10 : 6,
                        spreadRadius: isRolling ? 2 : 1,
                        offset: const Offset(0, 3),
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
                      // Dice SVG
                      SvgPicture.asset(
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
                      
                      // Rolling indicator
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
                                Colors.blue.withOpacity(0.1),
                                Colors.purple.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      
                      // Tap hint when not enabled
                      if (!widget.isEnabled)
                        Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: const Icon(
                            Icons.block,
                            color: Colors.white70,
                            size: 20,
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
    );
  }
}