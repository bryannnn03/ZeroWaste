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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'expiresOn': expiresOn,
        'daysUntilExpiry': daysUntilExpiry,
        'urgency': urgency.name,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final urgencyStr = json['urgency'] as String? ?? 'ok';
    final urgencyVal = UrgencyLevel.values.firstWhere(
      (e) => e.name == urgencyStr.toLowerCase(),
      orElse: () => UrgencyLevel.ok,
    );
    return FoodItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String? ?? '',
      expiresOn: json['expiresOn'] as String? ?? '',
      daysUntilExpiry: (json['daysUntilExpiry'] as num?)?.toInt() ?? 0,
      urgency: urgencyVal,
    );
  }
}