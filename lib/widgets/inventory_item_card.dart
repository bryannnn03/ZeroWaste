import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import '../utils/category_helpers.dart';
import 'status_badge.dart';
import 'animated_card_wrapper.dart';

class InventoryItemCard extends StatelessWidget {
  final FoodItem item;
  final bool compact;
  final VoidCallback? onTap;

  const InventoryItemCard({
    super.key,
    required this.item,
    this.compact = false,
    this.onTap,
  });

  Color get _borderColor {
    switch (item.urgency) {
      case UrgencyLevel.urgent:
        return AppColors.urgentRed;
      case UrgencyLevel.soon:
        return AppColors.soonOrange;
      case UrgencyLevel.ok:
        return AppColors.border;
    }
  }

  Color get _bgTint {
    switch (item.urgency) {
      case UrgencyLevel.urgent:
        return AppColors.urgentRedBg;
      case UrgencyLevel.soon:
        return AppColors.soonOrangeBg.withValues(alpha: 0.3);
      case UrgencyLevel.ok:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact() : _buildFull();
  }

  // ── Shared card shell: AnimatedCardWrapper + left accent bar ──────────────
  Widget _cardShell({required Widget child}) {
    return AnimatedCardWrapper(
      onTap: onTap,
      borderRadius: 12,
      child: Container(
        decoration: BoxDecoration(
          color: _bgTint,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar (4 px) with rounded corners
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact() {
    Color quantityColor;
    switch (item.urgency) {
      case UrgencyLevel.urgent:
        quantityColor = AppColors.urgentRed;
      case UrgencyLevel.soon:
        quantityColor = AppColors.soonOrange;
      case UrgencyLevel.ok:
        quantityColor = AppColors.mutedForeground;
    }

    final categoryIcon = CategoryHelpers.iconFor(item.category);
    final categoryColor = CategoryHelpers.colorFor(item.category);

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.foreground),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(categoryIcon, size: 12, color: categoryColor),
                        const SizedBox(width: 4),
                        Text(
                          item.category,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: categoryColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.quantityDisplay,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: quantityColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusBadge(urgency: item.urgency),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.calendarDays, size: 12, color: AppColors.mutedForeground),
              const SizedBox(width: 4),
              Text(
                'Expires in ${item.daysUntilExpiry == 1 ? '1 day' : '${item.daysUntilExpiry} days'}',
                style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFull() {
    final categoryIcon = CategoryHelpers.iconFor(item.category);
    final categoryColor = CategoryHelpers.colorFor(item.category);

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(categoryIcon, size: 12, color: categoryColor),
                        const SizedBox(width: 6),
                        Text(
                          item.category,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: categoryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusBadge(urgency: item.urgency),
            ],
          ),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border.withValues(alpha: 0.35)),
          ),
          // Details row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUANTITY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.quantityDisplay,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.foreground),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(LucideIcons.calendarDays, size: 11, color: AppColors.mutedForeground),
                        const SizedBox(width: 4),
                        const Text(
                          'EXPIRES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mutedForeground,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.expiresOn,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.foreground),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Animated progress bar below details row in full mode showing days until expiry
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: (item.daysUntilExpiry.toDouble() / 30.0).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              Color progressColor;
              switch (item.urgency) {
                case UrgencyLevel.urgent:
                  progressColor = AppColors.urgentRed;
                case UrgencyLevel.soon:
                  progressColor = AppColors.soonOrange;
                case UrgencyLevel.ok:
                  progressColor = AppColors.brandGreen;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: progressColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                ],
              );
            },
          ),
          // Countdown pill
          if (item.urgency != UrgencyLevel.ok) ...[
            const SizedBox(height: 12),
            _ExpiryCountdown(days: item.daysUntilExpiry, urgency: item.urgency),
          ],
        ],
      ),
    );
  }
}

class _ExpiryCountdown extends StatelessWidget {
  final int days;
  final UrgencyLevel urgency;

  const _ExpiryCountdown({required this.days, required this.urgency});

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    switch (urgency) {
      case UrgencyLevel.urgent:
        textColor = AppColors.urgentRed;
        bgColor = AppColors.urgentRed.withValues(alpha: 0.08);
      case UrgencyLevel.soon:
        textColor = AppColors.soonOrange;
        bgColor = AppColors.soonOrange.withValues(alpha: 0.08);
      case UrgencyLevel.ok:
        textColor = AppColors.mutedForeground;
        bgColor = Colors.grey.shade100;
    }

    final label = days == 0
        ? 'Expires today!'
        : days == 1
            ? 'Expires in 1 day'
            : 'Expires in $days days';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textColor)),
        ],
      ),
    );
  }
}