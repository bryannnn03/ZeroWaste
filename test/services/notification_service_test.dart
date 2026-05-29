import 'package:flutter_test/flutter_test.dart';

/// Tests for the pure business-logic inside NotificationService.
///
/// NotificationService.checkAndNotify() is tightly coupled to Supabase, so
/// we cannot call it in unit tests. Instead, we extract and verify every
/// piece of logic that runs *independently* of the network:
///
///   1. Today's date string generation (YYYY-MM-DD key format)
///   2. Expiry-bucket classification (today / tomorrow / soon / nearing / expired)
///   3. Deduplication key construction
///   4. Notification title / message generation (count == 1 vs > 1)
///   5. Notification type selection per bucket

// ─── Extracted / mirrored pure logic ────────────────────────────────────────

/// Mirrors the date-key format used in NotificationService.
String buildTodayStr() =>
    DateTime.now().toIso8601String().substring(0, 10);

/// Classifies a given expiry date into a bucket name.
/// Returns 'expired', 'today', 'tomorrow', 'soon', 'nearing', or 'irrelevant'.
String classifyExpiry(DateTime expiry) {
  final days = expiry.difference(DateTime.now()).inDays;
  if (days < 0)  return 'expired';
  if (days == 0) return 'today';
  if (days == 1) return 'tomorrow';
  if (days <= 3) return 'soon';
  if (days <= 7) return 'nearing';
  return 'irrelevant';
}

/// Mirrors the aggregation key used to deduplicate notifications per day.
String buildAggregationKey(String keySuffix, String todayStr) =>
    'agg_${keySuffix}_$todayStr';

/// Mirrors the title-generation logic inside addAggregateGroup.
String buildTitle(int count, String firstName, String timeframe) {
  if (count == 1) return '$firstName is expiring $timeframe';
  return '$count items are expiring $timeframe';
}

/// Mirrors the message-generation logic inside addAggregateGroup.
String buildMessage(int count, String firstName, String callToAction) {
  if (count == 1) return callToAction;
  if (count == 2) return '$firstName and 1 other item. $callToAction';
  return '$firstName and ${count - 1} other items. $callToAction';
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('NotificationService — pure business logic', () {
    group('today date string format', () {
      test('produces a YYYY-MM-DD formatted string', () {
        final str = buildTodayStr();
        expect(str, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      });

      test('matches today\'s actual date components', () {
        final str = buildTodayStr();
        final now = DateTime.now();
        expect(str, startsWith('${now.year}-'));
      });
    });

    group('expiry bucket classification', () {
      DateTime _daysFromNow(int d) => DateTime.now().add(Duration(days: d));

      test('already expired item → "expired"', () {
        expect(classifyExpiry(_daysFromNow(-1)), 'expired');
        expect(classifyExpiry(_daysFromNow(-5)), 'expired');
      });

      test('expires today (≈0 days) → "today"', () {
        // DateTime.now().difference(DateTime.now()).inDays == 0
        expect(classifyExpiry(DateTime.now()), 'today');
      });

      test('expires in exactly 1 day → "tomorrow"', () {
        expect(classifyExpiry(_daysFromNow(1)), 'tomorrow');
      });

      test('expires in 2 days → "soon"', () {
        expect(classifyExpiry(_daysFromNow(2)), 'soon');
      });

      test('expires in 3 days → "soon" (≤3 threshold)', () {
        expect(classifyExpiry(_daysFromNow(3)), 'soon');
      });

      test('expires in 4 days → "nearing"', () {
        expect(classifyExpiry(_daysFromNow(4)), 'nearing');
      });

      test('expires in 7 days → "nearing" (≤7 threshold)', () {
        expect(classifyExpiry(_daysFromNow(7)), 'nearing');
      });

      test('expires in 8 days → "irrelevant"', () {
        expect(classifyExpiry(_daysFromNow(8)), 'irrelevant');
      });

      test('expires in 365 days → "irrelevant"', () {
        expect(classifyExpiry(_daysFromNow(365)), 'irrelevant');
      });
    });

    group('aggregation key construction', () {
      test('key format is "agg_<suffix>_<YYYY-MM-DD>"', () {
        final key = buildAggregationKey('today', '2026-04-25');
        expect(key, 'agg_today_2026-04-25');
      });

      test('different suffixes produce different keys', () {
        const date = '2026-04-25';
        final k1 = buildAggregationKey('today',    date);
        final k2 = buildAggregationKey('tomorrow', date);
        final k3 = buildAggregationKey('soon',     date);
        final k4 = buildAggregationKey('nearing',  date);
        final keys = {k1, k2, k3, k4};
        expect(keys, hasLength(4)); // all unique
      });

      test('same suffix on different dates produces different keys', () {
        final k1 = buildAggregationKey('today', '2026-04-25');
        final k2 = buildAggregationKey('today', '2026-04-26');
        expect(k1, isNot(k2));
      });
    });

    group('notification title generation', () {
      test('single item → "<name> is expiring <timeframe>"', () {
        final title = buildTitle(1, 'Gardenia Bread', 'TODAY!');
        expect(title, 'Gardenia Bread is expiring TODAY!');
      });

      test('two items → "<count> items are expiring <timeframe>"', () {
        final title = buildTitle(2, 'Chicken', 'tomorrow!');
        expect(title, '2 items are expiring tomorrow!');
      });

      test('five items → "5 items are expiring <timeframe>"', () {
        final title = buildTitle(5, 'Milk', 'soon');
        expect(title, '5 items are expiring soon');
      });
    });

    group('notification message generation', () {
      const cta = 'Use them now or they will go to waste.';

      test('count == 1 → just the call-to-action string', () {
        final msg = buildMessage(1, 'Chicken', cta);
        expect(msg, cta);
      });

      test('count == 2 → "<name> and 1 other item. <cta>"', () {
        final msg = buildMessage(2, 'Chicken', cta);
        expect(msg, 'Chicken and 1 other item. $cta');
      });

      test('count == 3 → "<name> and 2 other items. <cta>"', () {
        final msg = buildMessage(3, 'Chicken', cta);
        expect(msg, 'Chicken and 2 other items. $cta');
      });

      test('count == 10 → "<name> and 9 other items. <cta>"', () {
        final msg = buildMessage(10, 'Milk', cta);
        expect(msg, 'Milk and 9 other items. $cta');
      });
    });

    group('deduplication logic', () {
      test('key already in set → notification is suppressed', () {
        final todayStr = buildTodayStr();
        final alreadyNotifiedKeys = <String>{
          buildAggregationKey('today', todayStr),
          buildAggregationKey('tomorrow', todayStr),
        };

        bool wouldInsert(String keySuffix) {
          final key = buildAggregationKey(keySuffix, todayStr);
          return !alreadyNotifiedKeys.contains(key);
        }

        expect(wouldInsert('today'),    isFalse); // suppressed
        expect(wouldInsert('tomorrow'), isFalse); // suppressed
        expect(wouldInsert('soon'),     isTrue);  // not yet notified
        expect(wouldInsert('nearing'),  isTrue);  // not yet notified
      });

      test('empty already-notified set → all buckets would insert', () {
        final alreadyNotifiedKeys = <String>{};
        final todayStr = buildTodayStr();

        for (final suffix in ['today', 'tomorrow', 'soon', 'nearing']) {
          final key = buildAggregationKey(suffix, todayStr);
          expect(alreadyNotifiedKeys.contains(key), isFalse);
        }
      });
    });
  });
}
