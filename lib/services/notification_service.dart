import '../supabase_client.dart';

/// Generates in-app expiry notifications by writing rows to the `notifications`
/// Supabase table. Call [checkAndNotify] once on app start (or whenever the
/// inventory changes). It deduplicates by generating at most ONE aggregate
/// notification per timeframe bucket per day.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Future<void> checkAndNotify() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final userId = user.id;

      // Check if user has opted out of notifications
      final meta = user.userMetadata;
      final notificationsEnabled = meta?['expiry_notifications'] as bool? ?? true;
      if (!notificationsEnabled) return;

      // 1. Fetch active inventory for this user
      final rows = await supabase
          .from('inventory')
          .select('id, name, expiry_date')
          .eq('status', 'active')
          .order('expiry_date', ascending: true);

      if ((rows as List).isEmpty) return;

      // 2. Fetch notification agg keys already created TODAY to avoid duplicates
      final todayStr = DateTime.now().toIso8601String().substring(0, 10); // "YYYY-MM-DD"
      final existing = await supabase
          .from('notifications')
          .select('item_id') // We use item_id to store the aggregation key
          .like('item_id', '%$todayStr%')
          .eq('user_id', userId);

      final alreadyNotifiedKeys = <String>{
        for (final r in (existing as List)) r['item_id']?.toString() ?? '',
      };

      // 3. Bucket items by timeframe
      final todayBucket = <Map<String, dynamic>>[];
      final tomorrowBucket = <Map<String, dynamic>>[];
      final soonBucket = <Map<String, dynamic>>[];
      final nearingBucket = <Map<String, dynamic>>[];

      for (final row in rows) {
        final expiry = DateTime.tryParse(row['expiry_date'] as String? ?? '');
        if (expiry == null) continue;

        final days = expiry.difference(DateTime.now()).inDays;
        
        if (days < 0) {
           continue; // already expired
        } else if (days == 0) {
          todayBucket.add(row);
        } else if (days == 1) {
          tomorrowBucket.add(row);
        } else if (days <= 3) {
          soonBucket.add(row);
        } else if (days <= 7) {
          nearingBucket.add(row);
        }
      }

      // 4. Build aggregated notifications
      final toInsert = <Map<String, dynamic>>[];

      void addAggregateGroup({
        required List<Map<String, dynamic>> bucket,
        required String keySuffix,
        required String type,
        required String timeframe,
        required String callToAction,
      }) {
        if (bucket.isEmpty) return;
        
        // This guarantees only 1 notification per bucket per day
        final key = 'agg_${keySuffix}_$todayStr';
        if (alreadyNotifiedKeys.contains(key)) return;

        final count = bucket.length;
        final firstItemName = bucket.first['name'] as String? ?? 'Item';
        
        final String title;
        if (count == 1) {
          title = '$firstItemName is expiring $timeframe';
        } else {
          title = '$count items are expiring $timeframe';
        }

        final String message;
        if (count == 1) {
          message = callToAction;
        } else if (count == 2) {
          message = '$firstItemName and 1 other item. $callToAction';
        } else {
          message = '$firstItemName and ${count - 1} other items. $callToAction';
        }

        toInsert.add({
          'user_id': userId,
          'item_id': key,
          'title': title,
          'message': message,
          'type': type,
          'read': false,
        });
      }

      addAggregateGroup(
        bucket: todayBucket,
        keySuffix: 'today',
        type: 'urgent',
        timeframe: 'TODAY!',
        callToAction: 'Use them now or they will go to waste.',
      );

      addAggregateGroup(
        bucket: tomorrowBucket,
        keySuffix: 'tomorrow',
        type: 'urgent',
        timeframe: 'tomorrow!',
        callToAction: 'Plan a meal quickly before it\'s too late.',
      );

      addAggregateGroup(
        bucket: soonBucket,
        keySuffix: 'soon',
        type: 'warning',
        timeframe: 'soon',
        callToAction: 'Check your inventory and plan your meals.',
      );

      addAggregateGroup(
        bucket: nearingBucket,
        keySuffix: 'nearing',
        type: 'info',
        timeframe: 'in a few days',
        callToAction: 'Add them to your shopping or meal plan.',
      );

      // 5. Batch insert newly generated aggregations
      if (toInsert.isNotEmpty) {
        await supabase.from('notifications').insert(toInsert);
      }
    } catch (e) {
      // Fail silently for background tasks
    }
  }
}
