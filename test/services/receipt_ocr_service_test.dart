import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerowaste/services/receipt_ocr_service.dart';

void main() {
  group('ExtractedItem.fromJson', () {
    group('name parsing', () {
      test('uses name from JSON and cleans it', () {
        final item = ExtractedItem.fromJson({
          'name': 'GARDENIA WHITE BREAD',
          'quantity': 1,
          'unit': 'loaf',
          'category': 'Bakery',
          'estimated_expiry_days': 4,
        });
        // _cleanItemName title-cases and expands brands
        expect(item.name, isNotEmpty);
        expect(item.name.toLowerCase(), contains('gardenia'));
      });

      test('defaults to "Unknown Item" when name is null', () {
        final item = ExtractedItem.fromJson({
          'name': null,
          'quantity': 1,
          'unit': 'pcs',
          'category': 'Other',
          'estimated_expiry_days': 7,
        });
        expect(item.name, 'Unknown Item');
      });

      test('trims whitespace from name', () {
        final item = ExtractedItem.fromJson({
          'name': '  Milk  ',
          'quantity': 1,
          'unit': 'bottle',
          'category': 'Dairy',
          'estimated_expiry_days': 5,
        });
        expect(item.name, isNot(startsWith(' ')));
        expect(item.name, isNot(endsWith(' ')));
      });
    });

    group('quantity parsing', () {
      test('parses integer quantity', () {
        final item = ExtractedItem.fromJson({
          'name': 'Apple',
          'quantity': 3,
          'unit': 'pcs',
          'category': 'Produce',
          'estimated_expiry_days': 7,
        });
        expect(item.quantity, 3.0);
      });

      test('parses double quantity', () {
        final item = ExtractedItem.fromJson({
          'name': 'Chicken',
          'quantity': 1.5,
          'unit': 'kg',
          'category': 'Meat',
          'estimated_expiry_days': 2,
        });
        expect(item.quantity, 1.5);
      });

      test('defaults to 1.0 when quantity is null', () {
        final item = ExtractedItem.fromJson({
          'name': 'Rice',
          'quantity': null,
          'unit': 'bag',
          'category': 'Pantry',
          'estimated_expiry_days': 365,
        });
        expect(item.quantity, 1.0);
      });
    });

    group('category parsing', () {
      test('uses category from JSON', () {
        final item = ExtractedItem.fromJson({
          'name': 'Chicken',
          'quantity': 1,
          'unit': 'g',
          'category': 'Meat',
          'estimated_expiry_days': 2,
        });
        expect(item.category, 'Meat');
      });

      test('defaults to "Other" when category is null', () {
        final item = ExtractedItem.fromJson({
          'name': 'Mystery Item',
          'quantity': 1,
          'unit': 'pcs',
          'category': null,
          'estimated_expiry_days': 7,
        });
        expect(item.category, 'Other');
      });
    });

    group('expiry date calculation', () {
      test('adds estimated_expiry_days to today', () {
        final before = DateTime.now();
        final item = ExtractedItem.fromJson({
          'name': 'Bread',
          'quantity': 1,
          'unit': 'loaf',
          'category': 'Bakery',
          'estimated_expiry_days': 4,
        });
        final after = DateTime.now();
        final expectedMin = before.add(const Duration(days: 4));
        final expectedMax = after.add(const Duration(days: 4));
        expect(
          item.expiryDate.isAfter(expectedMin.subtract(const Duration(minutes: 1))) &&
              item.expiryDate.isBefore(expectedMax.add(const Duration(minutes: 1))),
          isTrue,
        );
      });

      test('defaults to 7 days when estimated_expiry_days is null', () {
        final before = DateTime.now();
        final item = ExtractedItem.fromJson({
          'name': 'Unknown',
          'quantity': 1,
          'unit': 'pcs',
          'category': 'Other',
          'estimated_expiry_days': null,
        });
        final expected = before.add(const Duration(days: 7));
        // Check the date is approximately 7 days from now (within a minute)
        final diff = item.expiryDate.difference(expected).abs();
        expect(diff.inMinutes, lessThan(1));
      });

      test('handles 0 expiry days (expires today)', () {
        final item = ExtractedItem.fromJson({
          'name': 'Fresh Coriander',
          'quantity': 1,
          'unit': 'bunch',
          'category': 'Produce',
          'estimated_expiry_days': 0,
        });
        final today = DateTime.now();
        expect(item.expiryDate.year, today.year);
        expect(item.expiryDate.month, today.month);
        expect(item.expiryDate.day, today.day);
      });
    });

    group('unit normalisation', () {
      test('maps "loaf" unit to "loaf"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Bread',
          'quantity': 1,
          'unit': 'loaf',
          'category': 'Bakery',
          'estimated_expiry_days': 4,
        });
        expect(item.unit, 'loaf');
      });

      test('maps "loaves" unit to "loaf"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Bread',
          'quantity': 2,
          'unit': 'loaves',
          'category': 'Bakery',
          'estimated_expiry_days': 4,
        });
        expect(item.unit, 'loaf');
      });

      test('maps "gram" to "g"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Chicken',
          'quantity': 500,
          'unit': 'gram',
          'category': 'Meat',
          'estimated_expiry_days': 2,
        });
        expect(item.unit, 'g');
      });

      test('maps "grams" to "g"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Beef',
          'quantity': 300,
          'unit': 'grams',
          'category': 'Meat',
          'estimated_expiry_days': 2,
        });
        expect(item.unit, 'g');
      });

      test('maps "kg" to "kg"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Rice',
          'quantity': 5,
          'unit': 'kg',
          'category': 'Pantry',
          'estimated_expiry_days': 365,
        });
        expect(item.unit, 'kg');
      });

      test('maps "ml" to "ml"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Sauce',
          'quantity': 200,
          'unit': 'ml',
          'category': 'Pantry',
          'estimated_expiry_days': 365,
        });
        expect(item.unit, 'ml');
      });

      test('maps "liter" to "L"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Water',
          'quantity': 1,
          'unit': 'liter',
          'category': 'Beverages',
          'estimated_expiry_days': 365,
        });
        expect(item.unit, 'L');
      });

      test('maps "can" to "tin"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Tuna',
          'quantity': 1,
          'unit': 'can',
          'category': 'Pantry',
          'estimated_expiry_days': 730,
        });
        expect(item.unit, 'tin');
      });

      test('maps "cans" to "tin"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Sardines',
          'quantity': 3,
          'unit': 'cans',
          'category': 'Pantry',
          'estimated_expiry_days': 730,
        });
        expect(item.unit, 'tin');
      });

      test('maps "packet" to "packet"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Maggi Noodles',
          'quantity': 5,
          'unit': 'packet',
          'category': 'Snacks',
          'estimated_expiry_days': 180,
        });
        expect(item.unit, 'packet');
      });

      test('maps "bottle" to "bottle"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Soy Sauce',
          'quantity': 1,
          'unit': 'bottle',
          'category': 'Pantry',
          'estimated_expiry_days': 365,
        });
        expect(item.unit, 'bottle');
      });

      test('maps "bunch" to "bunch"', () {
        final item = ExtractedItem.fromJson({
          'name': 'Banana',
          'quantity': 1,
          'unit': 'bunch',
          'category': 'Produce',
          'estimated_expiry_days': 3,
        });
        expect(item.unit, 'bunch');
      });

      test('falls back to item-name inference when unit is empty — bread → loaf', () {
        final item = ExtractedItem.fromJson({
          'name': 'Gardenia White Bread',
          'quantity': 1,
          'unit': '',
          'category': 'Bakery',
          'estimated_expiry_days': 4,
        });
        expect(item.unit, 'loaf');
      });

      test('falls back to item-name inference for chicken → g', () {
        final item = ExtractedItem.fromJson({
          'name': 'Fresh Chicken Drumstick',
          'quantity': 500,
          'unit': '',
          'category': 'Meat',
          'estimated_expiry_days': 2,
        });
        expect(item.unit, 'g');
      });

      test('falls back to item-name inference for banana → bunch', () {
        final item = ExtractedItem.fromJson({
          'name': 'Fresh Banana',
          'quantity': 1,
          'unit': '',
          'category': 'Produce',
          'estimated_expiry_days': 3,
        });
        expect(item.unit, 'bunch');
      });

      test('falls back to item-name inference for sardine → tin', () {
        final item = ExtractedItem.fromJson({
          'name': 'Ayam Brand Sardine',
          'quantity': 1,
          'unit': '',
          'category': 'Pantry',
          'estimated_expiry_days': 730,
        });
        expect(item.unit, 'tin');
      });

      test('falls back to item-name inference for apple → pcs', () {
        final item = ExtractedItem.fromJson({
          'name': 'Red Apple',
          'quantity': 3,
          'unit': '',
          'category': 'Produce',
          'estimated_expiry_days': 7,
        });
        expect(item.unit, 'pcs');
      });

      test('empty unit with unknown item name defaults to pcs', () {
        final item = ExtractedItem.fromJson({
          'name': 'Xzq Unknown Thing',
          'quantity': 1,
          'unit': '',
          'category': 'Other',
          'estimated_expiry_days': 7,
        });
        expect(item.unit, 'pcs');
      });
    });
  });

  group('ReceiptOcrService.extractItems and fallbacks', () {
    test('extractItems returns items on first-attempt success', () async {
      final mockResponse = {
        'choices': [
          {
            'message': {
              'content': '```json\n[\n  {"name": "GDN WHT BRD", "quantity": 1, "unit": "loaf", "category": "Bakery", "estimated_expiry_days": 4}\n]\n```'
            }
          }
        ]
      };

      await http.runWithClient(() async {
        final items = await ReceiptOcrService.extractItems(
          XFile.fromData(Uint8List.fromList([0, 1, 2, 3]), name: 'receipt.jpg'),
        );
        expect(items, hasLength(1));
        expect(items.first.name, 'Gardenia White Bread'); // brand expanded & cleaned
        expect(items.first.category, 'Bakery');
      }, () => MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      }));
    });

    test('extractItems falls back to next model on 429/500 errors', () async {
      int requestCount = 0;
      final mockResponse = {
        'choices': [
          {
            'message': {
              'content': '[\n  {"name": "Milk", "quantity": 2, "unit": "bottle", "category": "Dairy", "estimated_expiry_days": 5}\n]'
            }
          }
        ]
      };

      await http.runWithClient(() async {
        final items = await ReceiptOcrService.extractItems(
          XFile.fromData(Uint8List.fromList([0]), name: 'receipt.jpg'),
        );
        expect(items, hasLength(1));
        expect(items.first.name, 'Milk');
        expect(requestCount, 2); // 1st failed (429), 2nd succeeded (200)
      }, () => MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('Rate limit exceeded', 429);
        }
        return http.Response(jsonEncode(mockResponse), 200);
      }));
    });

    test('extractItems bubbles up 401 error immediately without fallback', () async {
      int requestCount = 0;

      await http.runWithClient(() async {
        await expectLater(
          () => ReceiptOcrService.extractItems(
            XFile.fromData(Uint8List.fromList([0]), name: 'receipt.jpg'),
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid OpenRouter API key'),
          )),
        );
        expect(requestCount, 1); // fails immediately
      }, () => MockClient((request) async {
        requestCount++;
        return http.Response('Unauthorized', 401);
      }));
    });

    test('extractItems filters out non-food items', () async {
      final mockResponse = {
        'choices': [
          {
            'message': {
              'content': '[\n  {"name": "Gardenia Bread", "quantity": 1, "unit": "loaf", "category": "Bakery", "estimated_expiry_days": 4},\n  {"name": "Colgate Toothpaste", "quantity": 1, "unit": "box", "category": "Other", "estimated_expiry_days": 180}\n]'
            }
          }
        ]
      };

      await http.runWithClient(() async {
        final items = await ReceiptOcrService.extractItems(
          XFile.fromData(Uint8List.fromList([0]), name: 'receipt.png'),
        );
        expect(items, hasLength(1));
        expect(items.first.name, 'Gardenia Bread');
        // toothpaste is on the non-food blocklist, so it should be filtered out
      }, () => MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      }));
    });
  });
}
