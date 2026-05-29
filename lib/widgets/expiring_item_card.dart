import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/food_item.dart';
import '../utils/category_helpers.dart';
import 'status_badge.dart';
import 'animated_card_wrapper.dart';

class ExpiringItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback? onTap;

  const ExpiringItemCard({super.key, required this.item, this.onTap});

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
        return AppColors.soonOrangeBg.withValues(alpha: 0.35);
      case UrgencyLevel.ok:
        return Colors.white;
    }
  }

  Color get _accentColor {
    switch (item.urgency) {
      case UrgencyLevel.urgent:
        return AppColors.urgentRed;
      case UrgencyLevel.soon:
        return AppColors.soonOrange;
      case UrgencyLevel.ok:
        return AppColors.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expiryLabel = item.daysUntilExpiry == 0
        ? 'Expires today!'
        : item.daysUntilExpiry == 1
            ? 'Expires in 1 day'
            : 'Expires in ${item.daysUntilExpiry} days';

    final categoryIcon = CategoryHelpers.iconFor(item.category);
    final categoryColor = CategoryHelpers.colorFor(item.category);

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
              // Left accent bar (4px) with rounded top-left and bottom-left corners
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Name & Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // Category Icon next to name
                                Icon(categoryIcon, size: 12, color: categoryColor),
                                const SizedBox(width: 4),
                                Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: categoryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(LucideIcons.package, size: 12, color: AppColors.mutedForeground),
                                const SizedBox(width: 4),
                                Text(
                                  item.quantityDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Days until expiry pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.clock, size: 10, color: _accentColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    expiryLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(urgency: item.urgency),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}