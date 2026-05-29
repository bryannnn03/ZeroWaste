import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatefulWidget {
  final UrgencyLevel urgency;
  final int? daysLeft;
  final bool showDays;

  const StatusBadge({
    super.key,
    required this.urgency,
    this.daysLeft,
    this.showDays = false,
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    if (widget.urgency == UrgencyLevel.urgent) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      )..repeat(reverse: true);
      _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void didUpdateWidget(covariant StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.urgency == UrgencyLevel.urgent && _controller == null) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      )..repeat(reverse: true);
      _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
    } else if (widget.urgency != UrgencyLevel.urgent && _controller != null) {
      _controller!.dispose();
      _controller = null;
      _animation = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showDays && widget.daysLeft != null) {
      return _wrapWithPulse(_buildDaysBadge());
    }
    return _wrapWithPulse(_buildTextBadge());
  }

  Widget _wrapWithPulse(Widget child) {
    if (widget.urgency == UrgencyLevel.urgent && _animation != null) {
      return ScaleTransition(scale: _animation!, child: child);
    }
    return child;
  }

  Widget _buildDaysBadge() {
    final dayLabel = widget.daysLeft == 1 ? '1 DAY' : '${widget.daysLeft} DAYS';
    Color bgColor;
    switch (widget.urgency) {
      case UrgencyLevel.urgent:
        bgColor = AppColors.urgentRed;
      case UrgencyLevel.soon:
        bgColor = AppColors.soonOrange;
      case UrgencyLevel.ok:
        bgColor = AppColors.yellowMedium;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        dayLabel,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildTextBadge() {
    if (widget.urgency == UrgencyLevel.ok) return const SizedBox.shrink();

    String label;
    Color textColor;
    Color bgColor;
    Color borderColor;

    if (widget.urgency == UrgencyLevel.urgent) {
      label = 'URGENT';
      textColor = AppColors.urgentRed;
      bgColor = AppColors.urgentRed.withValues(alpha: 0.1);
      borderColor = AppColors.urgentRed.withValues(alpha: 0.2);
    } else {
      label = 'SOON';
      textColor = AppColors.soonOrange;
      bgColor = AppColors.soonOrange.withValues(alpha: 0.1);
      borderColor = AppColors.soonOrange.withValues(alpha: 0.2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
