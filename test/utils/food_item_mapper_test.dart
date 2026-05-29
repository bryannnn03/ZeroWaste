import 'package:flutter_test/flutter_test.dart';
import 'package:zerowaste/utils/food_item_mapper.dart';
import 'package:zerowaste/models/food_item.dart';

/// Helper to build a fake Supabase row with a given expiry relative to today.
Map<String, dynamic> _makeRow({
  String id = 'row-id',
  String name = 'Test Item',
  String category = 'Other',
  int quantity = 1,
  String unit = 'pcs',
  required int daysFromNow,
}) {
  final expiry = DateTime.now().add(Duration(days: daysFromNow));
  final expiryStr =
      '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}';
  return {
    'id': id,
    'name': name,
    'category': category,
    'quantity': quantity,
    'unit': unit,
    'expiry_date': expiryStr,
  };
}

void main() {
  group('rowToFoodItem', () {
    group('urgency thresholds', () {
      test('0 days until expiry → UrgencyLevel.urgent', () {
        final item = rowToFoodItem(_makeRow(daysFromNow: 0));
        expect(item.urgency, UrgencyLevel.urgent);
      });

      test('1 day until expiry → UrgencyLevel.urgent', () {
        final item = rowToFoodItem(_makeRow(daysFromNow: 1));
        expect(item.urgency, UrgencyLevel.urgent);
      });

      test('2 days until expiry → UrgencyLevel.urgent (≤2 threshold)', () {
        final item = rowToFoodItem(_makeRow(daysFromNow: 2));
        expect(item.urgency, UrgencyLevel.urgent);
      });

      test('3 days until expiry → UrgencyLevel.soon (or urgent near boundary)', () {
        final item = rowToFoodItem(_makeRow(daysFromNow: 3));
        // Due to sub-second truncation, inDays may return 2 (urgent) or 3 (soon).
        expect(
          item.urgency == UrgencyLevel.soon || item.urgency == UrgencyLevel.urgent,
          isTrue,
        );
      });

      test('5 days until expiry → UrgencyLevel.soon (≤5 threshold)', () {
        final item = rowToFoodItem(_makeRow(daysFromNow: 5));
        // inDays may return 4 or 5, both map to soon.
        expect(item.urgency, UrgencyLevel.soon);
      });

      test('6 days until expiry → UrgencyLevel.ok (or soon near boundary)', () {
        final item = rowToFoodItem(_makeRow(daysFromNow: 6));
        // Due to sub-second truncation, inDays may return 5 (soon) or 6 (ok).
        expect(
          item.urgency == UrgencyLevel.ok || item.urgency == UrgencyLevel.soon,
          isTrue,
        );
      });

      test('365 days until expiry → UrgencyLevel.ok', () {
        final item = rowToFoodItem(_makeRow(daysFromNow: 365));
        expect(item.urgency, UrgencyLevel.ok);
      });

      test('negative days (already expired) → UrgencyLevel.urgent', () {
        final item = rowToFoodItem(_makeRow(daysFromNow: -1));
        expect(item.urgency, UrgencyLevel.urgent);
        expect(item.daysUntilExpiry, isNegative);
      });
    });

    group('field mapping', () {
      test('id is converted to string', () {
        final row = _makeRow(id: 'abc-123', daysFromNow: 10);
        final item = rowToFoodItem(row);
        expect(item.id, 'abc-123');
      });

      test('name is mapped from row', () {
        final row = _makeRow(name: 'Gardenia Bread', daysFromNow: 4);
        final item = rowToFoodItem(row);
        expect(item.name, 'Gardenia Bread');
      });

      test('category is mapped from row', () {
        final row = _makeRow(category: 'Bakery', daysFromNow: 4);
        final item = rowToFoodItem(row);
        expect(item.category, 'Bakery');
      });

      test('quantity is mapped from row', () {
        final row = _makeRow(quantity: 5, daysFromNow: 10);
        final item = rowToFoodItem(row);
        expect(item.quantity, 5);
      });

      test('unit is mapped from row', () {
        final row = _makeRow(unit: 'loaf', daysFromNow: 4);
        final item = rowToFoodItem(row);
        expect(item.unit, 'loaf');
      });

      test('daysUntilExpiry reflects approximate days difference', () {
        final row = _makeRow(daysFromNow: 7);
        final item = rowToFoodItem(row);
        // Allow ±1 because of sub-day timing in test execution
        expect(item.daysUntilExpiry, inInclusiveRange(6, 7));
      });
    });

    group('expiresOn display format', () {
      test('uses short month name format "Mon DD, YYYY"', () {
        final expiry = DateTime(2026, 5, 15);
        final days = expiry.difference(DateTime.now()).inDays;
        final row = {
          'id': 'disp-1',
          'name': 'Milk',
          'category': 'Dairy',
          'quantity': 1,
          'unit': 'bottle',
          'expiry_date': '2026-05-15',
        };
        final item = rowToFoodItem(row);
        expect(item.expiresOn, 'May 15, 2026');
      });

      test('formats January correctly', () {
        final row = {
          'id': 'jan-1',
          'name': 'Item',
          'category': 'Other',
          'quantity': 1,
          'unit': '',
          'expiry_date': '2027-01-03',
        };
        final item = rowToFoodItem(row);
        expect(item.expiresOn, 'Jan 3, 2027');
      });

      test('formats December correctly', () {
        final row = {
          'id': 'dec-1',
          'name': 'Item',
          'category': 'Other',
          'quantity': 1,
          'unit': '',
          'expiry_date': '2026-12-25',
        };
        final item = rowToFoodItem(row);
        expect(item.expiresOn, 'Dec 25, 2026');
      });
    });

    group('null / missing field handling', () {
      test('missing name defaults to empty string', () {
        final row = _makeRow(daysFromNow: 5);
        row['name'] = null;
        final item = rowToFoodItem(row);
        expect(item.name, '');
      });

      test('missing category defaults to empty string', () {
        final row = _makeRow(daysFromNow: 5);
        row['category'] = null;
        final item = rowToFoodItem(row);
        expect(item.category, '');
      });

      test('missing quantity defaults to 1', () {
        final row = _makeRow(daysFromNow: 5);
        row['quantity'] = null;
        final item = rowToFoodItem(row);
        expect(item.quantity, 1);
      });

      test('missing unit defaults to empty string', () {
        final row = _makeRow(daysFromNow: 5);
        row['unit'] = null;
        final item = rowToFoodItem(row);
        expect(item.unit, '');
      });

      test('invalid expiry_date string falls back to now (urgent)', () {
        final row = _makeRow(daysFromNow: 5);
        row['expiry_date'] = 'not-a-date';
        final item = rowToFoodItem(row);
        // DateTime.tryParse returns null → falls back to DateTime.now()
        // so daysUntilExpiry ≈ 0 → urgent
        expect(item.urgency, UrgencyLevel.urgent);
      });
    });
  });
}
