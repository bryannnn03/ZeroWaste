import 'package:flutter/material.dart';

class AnimatedCardWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  const AnimatedCardWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16.0,
  });

  @override
  State<AnimatedCardWrapper> createState() => _AnimatedCardWrapperState();
}

class _AnimatedCardWrapperState extends State<AnimatedCardWrapper> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Pressed scale: 0.975, Hover scale: 1.01, Default: 1.0
    final scale = _isPressed ? 0.975 : (_isHovered ? 1.01 : 1.0);
    // Softer shadows with wider spread and lower opacity
    final shadowOpacity = _isPressed ? 0.01 : (_isHovered ? 0.08 : 0.03);
    final shadowBlur = _isHovered ? 20.0 : 10.0;
    final shadowOffset = _isHovered ? const Offset(0, 8) : const Offset(0, 4);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuart,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadowOpacity),
                  blurRadius: shadowBlur,
                  offset: shadowOffset,
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
