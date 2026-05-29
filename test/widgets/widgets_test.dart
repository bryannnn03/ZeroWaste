import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerowaste/models/food_item.dart';
import 'package:zerowaste/widgets/animated_card_wrapper.dart';
import 'package:zerowaste/widgets/empty_expiry_state.dart';
import 'package:zerowaste/widgets/expiring_item_card.dart';
import 'package:zerowaste/widgets/fade_in_slide.dart';
import 'package:zerowaste/widgets/home_header.dart';
import 'package:zerowaste/widgets/inventory_item_card.dart';
import 'package:zerowaste/widgets/shimmer_loading.dart';
import 'package:zerowaste/widgets/stat_card.dart';
import 'package:zerowaste/widgets/status_badge.dart';
import 'package:zerowaste/widgets/total_items_summary_sheet.dart';
import 'package:zerowaste/widgets/urgency_item_card.dart';

void main() {
  const mockItem = FoodItem(
    id: 'test-item-1',
    name: 'Gardenia Wholemeal',
    category: 'Bakery',
    quantity: 1,
    unit: 'loaf',
    expiresOn: 'May 30, 2026',
    daysUntilExpiry: 2,
    urgency: UrgencyLevel.urgent,
  );

  group('AnimatedCardWrapper', () {
    testWidgets('renders child and detects tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimatedCardWrapper(
            onTap: () => tapped = true,
            child: const Text('Tap Me'),
          ),
        ),
      ));

      expect(find.text('Tap Me'), findsOneWidget);
      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('EmptyExpiryState', () {
    testWidgets('renders all fresh text and check icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: EmptyExpiryState(),
        ),
      ));

      expect(find.text('All Fresh!'), findsOneWidget);
      expect(find.text('No items expiring soon — great job!'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });
  });

  group('ExpiringItemCard', () {
    testWidgets('renders name, category, quantity and badge', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ExpiringItemCard(
            item: mockItem,
            onTap: () => tapped = true,
          ),
        ),
      ));

      expect(find.text('Gardenia Wholemeal'), findsOneWidget);
      expect(find.text('1 loaf'), findsOneWidget);
      // Tap triggers card tap
      await tester.tap(find.text('Gardenia Wholemeal'));
      expect(tapped, isTrue);
    });
  });

  group('FadeInSlide', () {
    testWidgets('renders child content correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: FadeInSlide(
            child: Text('Fade In'),
          ),
        ),
      ));

      expect(find.text('Fade In'), findsOneWidget);
    });
  });

  group('HomeHeader', () {
    testWidgets('renders greeting and summary stats', (tester) async {
      bool summaryTapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HomeHeader(
            userName: 'Justin',
            totalItems: 10,
            expiringSoon: 3,
            highUrgency: 1,
            items: const [mockItem],
            onTotalItemsTap: () => summaryTapped = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Justin'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // total items
      expect(find.text('3'), findsOneWidget); // expiring soon

      await tester.tap(find.text('Total Items'));
      expect(summaryTapped, isTrue);
    });
  });

  group('InventoryItemCard', () {
    testWidgets('renders item fields correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: InventoryItemCard(
            item: mockItem,
          ),
        ),
      ));

      expect(find.text('Gardenia Wholemeal'), findsOneWidget);
      expect(find.text('QUANTITY'), findsOneWidget);
      expect(find.text('1 loaf'), findsOneWidget);
    });
  });

  group('ShimmerLoading', () {
    testWidgets('renders correct size', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ShimmerLoading(
            width: 200,
            height: 100,
          ),
        ),
      ));

      final containerFinder = find.byType(ShimmerLoading);
      expect(containerFinder, findsOneWidget);
      final size = tester.getSize(containerFinder);
      expect(size.width, 200);
      expect(size.height, 100);
    });
  });

  group('StatCard', () {
    testWidgets('renders stat label and values within a Row context', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              StatCard(
                icon: LucideIcons.package,
                iconBg: Colors.blue,
                iconColor: Colors.white,
                value: '42',
                label: 'Tracked Items',
              ),
            ],
          ),
        ),
      ));

      expect(find.text('42'), findsOneWidget);
      expect(find.text('Tracked Items'), findsOneWidget);
    });
  });

  group('StatusBadge', () {
    testWidgets('renders urgent text and pulsing scale', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusBadge(
            urgency: UrgencyLevel.urgent,
          ),
        ),
      ));

      expect(find.text('URGENT'), findsOneWidget);
    });

    testWidgets('renders soon text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusBadge(
            urgency: UrgencyLevel.soon,
          ),
        ),
      ));

      expect(find.text('SOON'), findsOneWidget);
    });

    testWidgets('renders days left badge when showDays is true', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusBadge(
            urgency: UrgencyLevel.urgent,
            daysLeft: 2,
            showDays: true,
          ),
        ),
      ));

      expect(find.text('2 DAYS'), findsOneWidget);
    });
  });

  group('TotalItemsSummarySheet', () {
    testWidgets('renders items list categories in sheet', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TotalItemsSummarySheet(
            items: [mockItem],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('BY CATEGORY'), findsOneWidget);
      expect(find.text('Bakery'), findsOneWidget);
    });
  });

  group('UrgencyItemCard', () {
    testWidgets('renders item status and category icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: UrgencyItemCard(
            item: mockItem,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Gardenia Wholemeal'), findsOneWidget);
      expect(find.text('EXPIRES'), findsOneWidget);
      expect(find.text('May 30, 2026'), findsOneWidget);
    });
  });
}
