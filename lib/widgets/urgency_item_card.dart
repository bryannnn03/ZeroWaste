import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import '../utils/category_helpers.dart';
import 'status_badge.dart';
import 'animated_card_wrapper.dart';

class UrgencyItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback? onTap;

  const UrgencyItemCard({super.key, required this.item, this.onTap});

  Color get _borderColor {
    switch (item.urgency) {
      case UrgencyLevel.urgent:
        return AppColors.urgentRed;
      case UrgencyLevel.soon:
        return AppColors.soonOrange;
      case UrgencyLevel.ok:
        return AppColors.yellowMedium;
    }
  }

  Color get _bgTint {
    switch (item.urgency) {
      case UrgencyLevel.urgent:
        return AppColors.urgentRedBg.withValues(alpha: 0.4);
      case UrgencyLevel.soon:
        return AppColors.soonOrangeBg.withValues(alpha: 0.4);
      case UrgencyLevel.ok:
        return AppColors.yellowMediumBg.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Colored left accent bar with rounded corners
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          StatusBadge(urgency: item.urgency, daysLeft: item.daysUntilExpiry, showDays: true),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: AppColors.border.withValues(alpha: 0.35)),
                      ),
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
                                    const Icon(LucideIcons.calendarDays, size: 12, color: AppColors.mutedForeground),
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