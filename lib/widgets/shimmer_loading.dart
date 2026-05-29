import 'package:flutter/material.dart';

/// A branded shimmer loading placeholder.
///
/// Usage:
/// ```dart
/// ShimmerLoading(width: double.infinity, height: 80, borderRadius: 16)
/// ```
class ShimmerLoading extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                Color(0xFFE8F5E9),
                Color(0xFFC8E6C9),
                Color(0xFFE8F5E9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A row of shimmer placeholders with a header shimmer above.
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final double borderRadius;

  const ShimmerList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 80,
    this.spacing = 12,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: ShimmerLoading(
            width: double.infinity,
            height: itemHeight,
            borderRadius: borderRadius,
          ),
        ),
      ),
    );
  }
}
