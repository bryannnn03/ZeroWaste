enum DifficultyLevel { easy, medium, hard }

class MealSuggestion {
  final String id;
  final String name;
  final int timeMinutes;
  final DifficultyLevel difficulty;
  final List<String> ingredients;
  final bool isPriority;
  final List<String> priorityIngredients;
  final List<String> steps;
  final List<String>? consumedItemIds;
  final bool isApproved;

  const MealSuggestion({
    required this.id,
    required this.name,
    required this.timeMinutes,
    required this.difficulty,
    required this.ingredients,
    required this.isPriority,
    required this.priorityIngredients,
    required this.steps,
    this.consumedItemIds,
    this.isApproved = false,
  });

  /// Build a [MealSuggestion] from a Supabase `meal_recommendations` row.
  /// [itemIds] should be the list of inventory item UUIDs from
  /// the corresponding `meal_ingredients` rows.
  factory MealSuggestion.fromRow(
    Map<String, dynamic> row, {
    List<String> itemIds = const [],
  }) {
    final diffStr = (row['difficulty'] as String?)?.toLowerCase() ?? 'medium';
    final diff = diffStr == 'easy'
        ? DifficultyLevel.easy
        : diffStr == 'hard'
            ? DifficultyLevel.hard
            : DifficultyLevel.medium;

    return MealSuggestion(
      id: row['id'].toString(),
      name: row['name'] as String? ?? '',
      timeMinutes: (row['time_minutes'] as int?) ?? 0,
      difficulty: diff,
      ingredients: List<String>.from(row['ingredients'] as List? ?? []),
      steps: List<String>.from(row['steps'] as List? ?? []),
      isPriority: true,
      priorityIngredients: const [],
      consumedItemIds: itemIds,
      isApproved: row['is_approved'] as bool? ?? false,
    );
  }

  MealSuggestion copyWith({bool? isApproved}) {
    return MealSuggestion(
      id: id,
      name: name,
      timeMinutes: timeMinutes,
      difficulty: difficulty,
      ingredients: ingredients,
      isPriority: isPriority,
      priorityIngredients: priorityIngredients,
      steps: steps,
      consumedItemIds: consumedItemIds,
      isApproved: isApproved ?? this.isApproved,
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
    }
  }
}