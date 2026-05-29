import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Centralized category → icon + color mappings.
/// Import this whenever you need to display a food category visually.
class CategoryHelpers {
  CategoryHelpers._();

  static IconData iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'produce':
        return LucideIcons.apple;
      case 'dairy':
        return LucideIcons.milk;
      case 'meat':
        return LucideIcons.beef;
      case 'seafood':
        return LucideIcons.fish;
      case 'bakery':
        return LucideIcons.croissant;
      case 'frozen':
        return LucideIcons.snowflake;
      case 'beverages':
        return LucideIcons.coffee;
      case 'pantry':
        return LucideIcons.warehouse;
      case 'snacks':
        return LucideIcons.cookie;
      default:
        return LucideIcons.shoppingBag;
    }
  }

  static Color colorFor(String category) {
    switch (category.toLowerCase()) {
      case 'produce':
        return const Color(0xFF22C55E);
      case 'dairy':
        return const Color(0xFF3B82F6);
      case 'meat':
        return const Color(0xFFEF4444);
      case 'seafood':
        return const Color(0xFF0EA5E9);
      case 'bakery':
        return const Color(0xFFF59E0B);
      case 'frozen':
        return const Color(0xFF6366F1);
      case 'beverages':
        return const Color(0xFF8B5CF6);
      case 'pantry':
        return const Color(0xFFF97316);
      case 'snacks':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static Color bgColorFor(String category) {
    return colorFor(category).withOpacity(0.1);
  }
}
