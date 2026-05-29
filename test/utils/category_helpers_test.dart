import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerowaste/utils/category_helpers.dart';

void main() {
  group('CategoryHelpers', () {
    group('iconFor', () {
      test('maps Produce to apple icon', () {
        expect(CategoryHelpers.iconFor('Produce'), LucideIcons.apple);
      });

      test('maps Dairy to milk icon', () {
        expect(CategoryHelpers.iconFor('Dairy'), LucideIcons.milk);
      });

      test('maps Meat to beef icon', () {
        expect(CategoryHelpers.iconFor('Meat'), LucideIcons.beef);
      });

      test('maps Seafood to fish icon', () {
        expect(CategoryHelpers.iconFor('Seafood'), LucideIcons.fish);
      });

      test('maps Bakery to croissant icon', () {
        expect(CategoryHelpers.iconFor('Bakery'), LucideIcons.croissant);
      });

      test('maps Frozen to snowflake icon', () {
        expect(CategoryHelpers.iconFor('Frozen'), LucideIcons.snowflake);
      });

      test('maps Beverages to coffee icon', () {
        expect(CategoryHelpers.iconFor('Beverages'), LucideIcons.coffee);
      });

      test('maps Pantry to warehouse icon', () {
        expect(CategoryHelpers.iconFor('Pantry'), LucideIcons.warehouse);
      });

      test('maps Snacks to cookie icon', () {
        expect(CategoryHelpers.iconFor('Snacks'), LucideIcons.cookie);
      });

      test('falls back to shoppingBag icon for unknown category', () {
        expect(CategoryHelpers.iconFor('unknown'), LucideIcons.shoppingBag);
      });

      test('ignores case differences', () {
        expect(CategoryHelpers.iconFor('mEaT'), LucideIcons.beef);
        expect(CategoryHelpers.iconFor('PRODUCE'), LucideIcons.apple);
      });
    });

    group('colorFor', () {
      test('maps Produce to green color', () {
        expect(CategoryHelpers.colorFor('produce'), const Color(0xFF22C55E));
      });

      test('maps Meat to red color', () {
        expect(CategoryHelpers.colorFor('meat'), const Color(0xFFEF4444));
      });

      test('falls back to gray for unknown category', () {
        expect(CategoryHelpers.colorFor('unknown'), const Color(0xFF6B7280));
      });

      test('ignores case differences', () {
        expect(CategoryHelpers.colorFor('DaIrY'), const Color(0xFF3B82F6));
      });
    });

    group('bgColorFor', () {
      test('returns color with 10% opacity', () {
        final color = CategoryHelpers.colorFor('Produce');
        final bgColor = CategoryHelpers.bgColorFor('Produce');
        expect(bgColor, color.withOpacity(0.1));
      });
    });
  });
}
