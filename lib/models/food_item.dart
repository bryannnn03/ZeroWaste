enum UrgencyLevel { urgent, soon, ok }

class FoodItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String unit;
  final String expiresOn;
  final int daysUntilExpiry;
  final UrgencyLevel urgency;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.expiresOn,
    required this.daysUntilExpiry,
    required this.urgency,
  });

  /// Display helper — e.g. "250 g", "12 pieces", "1 loaf"
  String get quantityDisplay => unit.isEmpty ? '$quantity' : '$quantity $unit';
}