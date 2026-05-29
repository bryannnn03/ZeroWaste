import 'package:flutter_test/flutter_test.dart';
import 'package:zerowaste/models/food_item.dart';

void main() {
  group('UrgencyLevel enum', () {
    test('has three distinct values: urgent, soon, ok', () {
      expect(UrgencyLevel.values, hasLength(3));
      expect(UrgencyLevel.values, containsAll([
        UrgencyLevel.urgent,
        UrgencyLevel.soon,
        UrgencyLevel.ok,
      ]));
    });
  });

  group('FoodItem', () {
    const baseItem = FoodItem(
      id: 'abc-123',
      name: 'Gardenia Bread',
      category: 'Bakery',
      quantity: 1,
      unit: 'loaf',
      expiresOn: 'Apr 29, 2026',
      daysUntilExpiry: 4,
      urgency: UrgencyLevel.soon,
    );

    test('stores all fields correctly', () {
      expect(baseItem.id, 'abc-123');
      expect(baseItem.name, 'Gardenia Bread');
      expect(baseItem.category, 'Bakery');
      expect(baseItem.quantity, 1);
      expect(baseItem.unit, 'loaf');
      expect(baseItem.expiresOn, 'Apr 29, 2026');
      expect(baseItem.daysUntilExpiry, 4);
      expect(baseItem.urgency, UrgencyLevel.soon);
    });

    group('quantityDisplay getter', () {
      test('returns "quantity unit" when unit is non-empty', () {
        const item = FoodItem(
          id: '1',
          name: 'Milk',
          category: 'Dairy',
          quantity: 2,
          unit: 'bottle',
          expiresOn: 'May 1, 2026',
          daysUntilExpiry: 6,
          urgency: UrgencyLevel.ok,
        );
        expect(item.quantityDisplay, '2 bottle');
      });

      test('returns only quantity string when unit is empty', () {
        const item = FoodItem(
          id: '2',
          name: 'Apple',
          category: 'Produce',
          quantity: 5,
          unit: '',
          expiresOn: 'May 5, 2026',
          daysUntilExpiry: 10,
          urgency: UrgencyLevel.ok,
        );
        expect(item.quantityDisplay, '5');
      });

      test('handles quantity of 0', () {
        const item = FoodItem(
          id: '3',
          name: 'Salt',
          category: 'Pantry',
          quantity: 0,
          unit: 'bag',
          expiresOn: 'Dec 31, 2027',
          daysUntilExpiry: 600,
          urgency: UrgencyLevel.ok,
        );
        expect(item.quantityDisplay, '0 bag');
      });

      test('handles large quantities', () {
        const item = FoodItem(
          id: '4',
          name: 'Rice',
          category: 'Pantry',
          quantity: 1000,
          unit: 'g',
          expiresOn: 'Jan 1, 2027',
          daysUntilExpiry: 250,
          urgency: UrgencyLevel.ok,
        );
        expect(item.quantityDisplay, '1000 g');
      });
    });

    group('urgency level assignment', () {
      test('urgent item reflects UrgencyLevel.urgent', () {
        const item = FoodItem(
          id: 'u1',
          name: 'Chicken',
          category: 'Meat',
          quantity: 500,
          unit: 'g',
          expiresOn: 'Today',
          daysUntilExpiry: 0,
          urgency: UrgencyLevel.urgent,
        );
        expect(item.urgency, UrgencyLevel.urgent);
      });

      test('soon item reflects UrgencyLevel.soon', () {
        const item = FoodItem(
          id: 's1',
          name: 'Yogurt',
          category: 'Dairy',
          quantity: 1,
          unit: 'bottle',
          expiresOn: 'Soon',
          daysUntilExpiry: 3,
          urgency: UrgencyLevel.soon,
        );
        expect(item.urgency, UrgencyLevel.soon);
      });

      test('ok item reflects UrgencyLevel.ok', () {
        const item = FoodItem(
          id: 'o1',
          name: 'Canned Tuna',
          category: 'Pantry',
          quantity: 1,
          unit: 'tin',
          expiresOn: 'Jun 1, 2028',
          daysUntilExpiry: 700,
          urgency: UrgencyLevel.ok,
        );
        expect(item.urgency, UrgencyLevel.ok);
      });
    });

    group('serialization and null safety', () {
      test('toJson returns expected map', () {
        const item = FoodItem(
          id: '123',
          name: 'Bread',
          category: 'Bakery',
          quantity: 2,
          unit: 'loaf',
          expiresOn: 'May 30, 2026',
          daysUntilExpiry: 5,
          urgency: UrgencyLevel.soon,
        );
        final json = item.toJson();
        expect(json['id'], '123');
        expect(json['name'], 'Bread');
        expect(json['category'], 'Bakery');
        expect(json['quantity'], 2);
        expect(json['unit'], 'loaf');
        expect(json['expiresOn'], 'May 30, 2026');
        expect(json['daysUntilExpiry'], 5);
        expect(json['urgency'], 'soon');
      });

      test('fromJson parses standard structure correctly', () {
        final raw = {
          'id': 'abc',
          'name': 'Milk',
          'category': 'Dairy',
          'quantity': 1,
          'unit': 'bottle',
          'expiresOn': 'Jun 2, 2026',
          'daysUntilExpiry': 4,
          'urgency': 'soon',
        };
        final item = FoodItem.fromJson(raw);
        expect(item.id, 'abc');
        expect(item.name, 'Milk');
        expect(item.category, 'Dairy');
        expect(item.quantity, 1);
        expect(item.unit, 'bottle');
        expect(item.expiresOn, 'Jun 2, 2026');
        expect(item.daysUntilExpiry, 4);
        expect(item.urgency, UrgencyLevel.soon);
      });

      test('fromJson handles null / missing fields safely', () {
        final item = FoodItem.fromJson({});
        expect(item.id, '');
        expect(item.name, '');
        expect(item.category, '');
        expect(item.quantity, 1);
        expect(item.unit, '');
        expect(item.expiresOn, '');
        expect(item.daysUntilExpiry, 0);
        expect(item.urgency, UrgencyLevel.ok);
      });

      test('fromJson handles case-insensitive urgency name matching', () {
        final item = FoodItem.fromJson({'urgency': 'URGENT'});
        expect(item.urgency, UrgencyLevel.urgent);
      });
    });
  });
}
