import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LudoPin extends StatefulWidget {
  final String color;
  final int id;
  final double size;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const LudoPin({
    super.key,
    required this.color,
    required this.id,
    this.size = 50,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  State<LudoPin> createState() => _LudoPinState();
}

class _LudoPinState extends State<LudoPin> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      _bounceController.forward().then((_) {
        _bounceController.reverse();
      });
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: widget.isHighlighted
                ? [
                    BoxShadow(
                      color: _getColorForString(widget.color)
                          .withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : _isHovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
          ),
          child: ScaleTransition(
            scale: _bounceAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect for selected pins
                if (widget.isSelected)
                  Container(
                    width: widget.size + 10,
                    height: widget.size + 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _getColorForString(widget.color)
                              .withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                // Main pin SVG
                SvgPicture.asset(
                  'assets/pins/pin_${widget.color}.svg',
                  width: widget.size,
                  height:
                      widget.size * 1.2, // Slightly taller for teardrop shape
                ),

                // ID number overlay - simplified
                Positioned(
                  bottom: widget.size * 0.15,
                  child: Text(
                    '${widget.id}',
                    style: TextStyle(
                      fontSize: widget.size * 0.3,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 3,
                          color: Colors.black.withValues(alpha: 0.8),
                          offset: const Offset(1, 1),
                        ),
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
  }

  Color _getColorForString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return const Color(0xFFCC2936);
      case 'green':
        return const Color(0xFF2F9E44);
      case 'blue':
        return const Color(0xFF1971C2);
      case 'yellow':
        return const Color(0xFFFAB005);
      default:
        return Colors.grey;
    }
  }
}
