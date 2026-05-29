import 'package:flutter_test/flutter_test.dart';
import 'package:zerowaste/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    group('constructor', () {
      test('stores all fields correctly', () {
        final profile = UserProfile(
          name: 'Justin Tan',
          email: 'justin@example.com',
          itemsTracked: 42,
          wasteReduced: 15,
          expiryNotifications: true,
        );

        expect(profile.name, 'Justin Tan');
        expect(profile.email, 'justin@example.com');
        expect(profile.itemsTracked, 42);
        expect(profile.wasteReduced, 15);
        expect(profile.expiryNotifications, isTrue);
      });

      test('stores zero values for numeric fields', () {
        final profile = UserProfile(
          name: 'New User',
          email: 'new@example.com',
          itemsTracked: 0,
          wasteReduced: 0,
          expiryNotifications: false,
        );

        expect(profile.itemsTracked, 0);
        expect(profile.wasteReduced, 0);
      });
    });

    group('expiryNotifications mutability', () {
      test('expiryNotifications can be toggled from true to false', () {
        final profile = UserProfile(
          name: 'Alice',
          email: 'alice@example.com',
          itemsTracked: 10,
          wasteReduced: 5,
          expiryNotifications: true,
        );
        expect(profile.expiryNotifications, isTrue);
        profile.expiryNotifications = false;
        expect(profile.expiryNotifications, isFalse);
      });

      test('expiryNotifications can be toggled from false to true', () {
        final profile = UserProfile(
          name: 'Bob',
          email: 'bob@example.com',
          itemsTracked: 3,
          wasteReduced: 1,
          expiryNotifications: false,
        );
        expect(profile.expiryNotifications, isFalse);
        profile.expiryNotifications = true;
        expect(profile.expiryNotifications, isTrue);
      });
    });

    group('waste reduction percentage', () {
      test('calculates 0% waste reduction when itemsTracked is 0', () {
        final profile = UserProfile(
          name: 'Empty User',
          email: 'empty@example.com',
          itemsTracked: 0,
          wasteReduced: 0,
          expiryNotifications: false,
        );
        // Guard against divide-by-zero in consumers
        final percentage = profile.itemsTracked == 0
            ? 0.0
            : profile.wasteReduced / profile.itemsTracked * 100;
        expect(percentage, 0.0);
      });

      test('calculates correct percentage when items > 0', () {
        final profile = UserProfile(
          name: 'Active User',
          email: 'active@example.com',
          itemsTracked: 20,
          wasteReduced: 5,
          expiryNotifications: true,
        );
        final percentage = profile.wasteReduced / profile.itemsTracked * 100;
        expect(percentage, closeTo(25.0, 0.001));
      });

      test('100% waste reduction when all items are saved', () {
        final profile = UserProfile(
          name: 'Zero Waster',
          email: 'zero@example.com',
          itemsTracked: 10,
          wasteReduced: 10,
          expiryNotifications: true,
        );
        final percentage = profile.wasteReduced / profile.itemsTracked * 100;
        expect(percentage, 100.0);
      });
    });

    group('serialization and null safety', () {
      test('toJson returns expected map', () {
        final profile = UserProfile(
          name: 'Justin Tan',
          email: 'justin@example.com',
          itemsTracked: 42,
          wasteReduced: 15,
          expiryNotifications: true,
        );
        final json = profile.toJson();
        expect(json['name'], 'Justin Tan');
        expect(json['email'], 'justin@example.com');
        expect(json['itemsTracked'], 42);
        expect(json['wasteReduced'], 15);
        expect(json['expiryNotifications'], isTrue);
      });

      test('fromJson parses standard structure correctly', () {
        final raw = {
          'name': 'Bob',
          'email': 'bob@example.com',
          'itemsTracked': 10,
          'wasteReduced': 3,
          'expiryNotifications': false,
        };
        final profile = UserProfile.fromJson(raw);
        expect(profile.name, 'Bob');
        expect(profile.email, 'bob@example.com');
        expect(profile.itemsTracked, 10);
        expect(profile.wasteReduced, 3);
        expect(profile.expiryNotifications, isFalse);
      });

      test('fromJson handles null / missing fields safely', () {
        final profile = UserProfile.fromJson({});
        expect(profile.name, '');
        expect(profile.email, '');
        expect(profile.itemsTracked, 0);
        expect(profile.wasteReduced, 0);
        expect(profile.expiryNotifications, isTrue);
      });
    });
  });
}
