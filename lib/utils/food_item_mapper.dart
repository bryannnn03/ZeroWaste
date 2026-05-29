import '../models/food_item.dart';

/// Converts a raw Supabase `inventory` row into a [FoodItem].
///
/// Urgency thresholds (days until expiry):
///   ≤ 2  → urgent
///   ≤ 5  → soon
///   > 5  → ok
///
/// Keep this as the single source of truth. Never duplicate this logic
/// inside individual screens — import and call [rowToFoodItem] instead.
FoodItem rowToFoodItem(Map<String, dynamic> row) {
  final expiry =
      DateTime.tryParse(row['expiry_date'] as String? ?? '') ?? DateTime.now();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);
  final days = expiryDate.difference(today).inDays;

  final UrgencyLevel urgency;
  if (days <= 2) {
    urgency = UrgencyLevel.urgent;
  } else if (days <= 5) {
    urgency = UrgencyLevel.soon;
  } else {
    urgency = UrgencyLevel.ok;
  }

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final displayDate =
      '${months[expiry.month - 1]} ${expiry.day}, ${expiry.year}';

  return FoodItem(
    id: row['id'].toString(),
    name: row['name'] as String? ?? '',
    category: row['category'] as String? ?? '',
    quantity: (row['quantity'] as int?) ?? 1,
    unit: row['unit'] as String? ?? '',
    expiresOn: displayDate,
    // Keep raw value (may be negative) so expired-item detection works
    daysUntilExpiry: days,
    urgency: urgency,
  );
}