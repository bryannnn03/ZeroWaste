import 'package:flutter_test/flutter_test.dart';
import 'package:zerowaste/models/meal_suggestion.dart';

void main() {
  group('DifficultyLevel enum', () {
    test('has three values: easy, medium, hard', () {
      expect(DifficultyLevel.values, hasLength(3));
      expect(DifficultyLevel.values, containsAll([
        DifficultyLevel.easy,
        DifficultyLevel.medium,
        DifficultyLevel.hard,
      ]));
    });
  });

  group('MealSuggestion', () {
    group('constructor', () {
      test('stores all required fields', () {
        const meal = MealSuggestion(
          id: 'meal-1',
          name: 'Chicken Stir Fry',
          timeMinutes: 25,
          difficulty: DifficultyLevel.easy,
          ingredients: ['300g chicken', '1 cup broccoli', '2 tbsp soy sauce'],
          isPriority: true,
          priorityIngredients: ['chicken', 'broccoli'],
          steps: ['Heat oil.', 'Add chicken.', 'Stir fry.'],
        );

        expect(meal.id, 'meal-1');
        expect(meal.name, 'Chicken Stir Fry');
        expect(meal.timeMinutes, 25);
        expect(meal.difficulty, DifficultyLevel.easy);
        expect(meal.ingredients, hasLength(3));
        expect(meal.isPriority, isTrue);
        expect(meal.priorityIngredients, containsAll(['chicken', 'broccoli']));
        expect(meal.steps, hasLength(3));
      });

      test('isApproved defaults to false', () {
        const meal = MealSuggestion(
          id: 'm2',
          name: 'Fried Rice',
          timeMinutes: 15,
          difficulty: DifficultyLevel.easy,
          ingredients: ['rice'],
          isPriority: false,
          priorityIngredients: [],
          steps: ['Cook rice.'],
        );
        expect(meal.isApproved, isFalse);
      });

      test('consumedItemIds defaults to null', () {
        const meal = MealSuggestion(
          id: 'm3',
          name: 'Omelette',
          timeMinutes: 10,
          difficulty: DifficultyLevel.easy,
          ingredients: ['2 eggs'],
          isPriority: false,
          priorityIngredients: [],
          steps: ['Beat eggs.', 'Cook in pan.'],
        );
        expect(meal.consumedItemIds, isNull);
      });

      test('accepts explicit consumedItemIds list', () {
        const meal = MealSuggestion(
          id: 'm4',
          name: 'Pasta',
          timeMinutes: 20,
          difficulty: DifficultyLevel.medium,
          ingredients: ['pasta', 'tomatoes'],
          isPriority: true,
          priorityIngredients: ['tomatoes'],
          steps: ['Boil pasta.'],
          consumedItemIds: ['item-uuid-1', 'item-uuid-2'],
        );
        expect(meal.consumedItemIds, ['item-uuid-1', 'item-uuid-2']);
      });
    });

    group('difficultyLabel getter', () {
      test('returns "Easy" for DifficultyLevel.easy', () {
        const meal = MealSuggestion(
          id: 'x',
          name: 'Test',
          timeMinutes: 5,
          difficulty: DifficultyLevel.easy,
          ingredients: [],
          isPriority: false,
          priorityIngredients: [],
          steps: [],
        );
        expect(meal.difficultyLabel, 'Easy');
      });

      test('returns "Medium" for DifficultyLevel.medium', () {
        const meal = MealSuggestion(
          id: 'y',
          name: 'Test',
          timeMinutes: 30,
          difficulty: DifficultyLevel.medium,
          ingredients: [],
          isPriority: false,
          priorityIngredients: [],
          steps: [],
        );
        expect(meal.difficultyLabel, 'Medium');
      });

      test('returns "Hard" for DifficultyLevel.hard', () {
        const meal = MealSuggestion(
          id: 'z',
          name: 'Test',
          timeMinutes: 90,
          difficulty: DifficultyLevel.hard,
          ingredients: [],
          isPriority: false,
          priorityIngredients: [],
          steps: [],
        );
        expect(meal.difficultyLabel, 'Hard');
      });
    });

    group('copyWith', () {
      const original = MealSuggestion(
        id: 'cp-1',
        name: 'Soup',
        timeMinutes: 40,
        difficulty: DifficultyLevel.medium,
        ingredients: ['carrots', 'onion'],
        isPriority: true,
        priorityIngredients: ['carrots'],
        steps: ['Boil.', 'Season.'],
        consumedItemIds: ['inv-1'],
        isApproved: false,
      );

      test('copying with isApproved=true returns new object with updated field', () {
        final approved = original.copyWith(isApproved: true);
        expect(approved.isApproved, isTrue);
        expect(approved.id, original.id);
        expect(approved.name, original.name);
      });

      test('copying without changes preserves isApproved', () {
        final copy = original.copyWith();
        expect(copy.isApproved, isFalse);
      });

      test('copyWith preserves all other fields unchanged', () {
        final copy = original.copyWith(isApproved: true);
        expect(copy.id, 'cp-1');
        expect(copy.name, 'Soup');
        expect(copy.timeMinutes, 40);
        expect(copy.difficulty, DifficultyLevel.medium);
        expect(copy.ingredients, ['carrots', 'onion']);
        expect(copy.isPriority, isTrue);
        expect(copy.priorityIngredients, ['carrots']);
        expect(copy.steps, ['Boil.', 'Season.']);
        expect(copy.consumedItemIds, ['inv-1']);
      });

      test('copyWith returns a new instance, not the same reference', () {
        final copy = original.copyWith(isApproved: true);
        expect(identical(copy, original), isFalse);
      });
    });

    group('MealSuggestion.fromRow factory', () {
      test('maps easy difficulty correctly', () {
        final row = {
          'id': 'row-1',
          'name': 'Egg Scramble',
          'time_minutes': 10,
          'difficulty': 'easy',
          'ingredients': ['2 eggs', 'salt'],
          'steps': ['Beat.', 'Cook.'],
          'is_approved': false,
        };
        final meal = MealSuggestion.fromRow(row);
        expect(meal.difficulty, DifficultyLevel.easy);
        expect(meal.id, 'row-1');
        expect(meal.name, 'Egg Scramble');
        expect(meal.timeMinutes, 10);
        expect(meal.isApproved, isFalse);
      });

      test('maps hard difficulty correctly', () {
        final row = {
          'id': 'row-2',
          'name': 'Beef Wellington',
          'time_minutes': 120,
          'difficulty': 'HARD',
          'ingredients': ['beef', 'pastry'],
          'steps': ['Sear.', 'Wrap.', 'Bake.'],
          'is_approved': true,
        };
        final meal = MealSuggestion.fromRow(row);
        expect(meal.difficulty, DifficultyLevel.hard);
        expect(meal.isApproved, isTrue);
      });

      test('defaults to medium for unknown difficulty string', () {
        final row = {
          'id': 'row-3',
          'name': 'Mystery Dish',
          'time_minutes': 30,
          'difficulty': 'extreme',
          'ingredients': ['something'],
          'steps': ['Do it.'],
          'is_approved': false,
        };
        final meal = MealSuggestion.fromRow(row);
        expect(meal.difficulty, DifficultyLevel.medium);
      });

      test('handles null difficulty gracefully (defaults to medium)', () {
        final row = {
          'id': 'row-4',
          'name': 'Simple Salad',
          'time_minutes': 5,
          'difficulty': null,
          'ingredients': ['lettuce'],
          'steps': ['Toss.'],
          'is_approved': false,
        };
        final meal = MealSuggestion.fromRow(row);
        expect(meal.difficulty, DifficultyLevel.medium);
      });

      test('passes itemIds as consumedItemIds', () {
        final row = {
          'id': 'row-5',
          'name': 'Veggie Bowl',
          'time_minutes': 20,
          'difficulty': 'easy',
          'ingredients': ['broccoli'],
          'steps': ['Steam.'],
          'is_approved': false,
        };
        const ids = ['uuid-a', 'uuid-b'];
        final meal = MealSuggestion.fromRow(row, itemIds: ids);
        expect(meal.consumedItemIds, ['uuid-a', 'uuid-b']);
      });

      test('uses empty itemIds by default', () {
        final row = {
          'id': 'row-6',
          'name': 'Bread',
          'time_minutes': 60,
          'difficulty': 'medium',
          'ingredients': ['flour', 'water'],
          'steps': ['Mix.', 'Bake.'],
          'is_approved': false,
        };
        final meal = MealSuggestion.fromRow(row);
        expect(meal.consumedItemIds, isEmpty);
      });

      test('handles null ingredients list gracefully', () {
        final row = {
          'id': 'row-7',
          'name': 'Empty Recipe',
          'time_minutes': 0,
          'difficulty': 'easy',
          'ingredients': null,
          'steps': null,
          'is_approved': false,
        };
        final meal = MealSuggestion.fromRow(row);
        expect(meal.ingredients, isEmpty);
        expect(meal.steps, isEmpty);
      });

      test('id is converted to string from non-string type', () {
        final row = {
          'id': 42,
          'name': 'Numeric ID Dish',
          'time_minutes': 10,
          'difficulty': 'easy',
          'ingredients': [],
          'steps': [],
          'is_approved': false,
        };
        final meal = MealSuggestion.fromRow(row);
        expect(meal.id, '42');
      });

      test('time_minutes defaults to 0 when null', () {
        final row = {
          'id': 'row-8',
          'name': 'Instant Noodles',
          'time_minutes': null,
          'difficulty': 'easy',
          'ingredients': ['noodles'],
          'steps': ['Cook.'],
          'is_approved': false,
        };
        final meal = MealSuggestion.fromRow(row);
        expect(meal.timeMinutes, 0);
      });

      test('isPriority is always set to true from fromRow', () {
        final row = {
          'id': 'row-9',
          'name': 'Priority Meal',
          'time_minutes': 15,
          'difficulty': 'easy',
          'ingredients': [],
          'steps': [],
          'is_approved': false,
        };
        final meal = MealSuggestion.fromRow(row);
        expect(meal.isPriority, isTrue);
      });

      test('priorityIngredients is always empty list from fromRow', () {
        final row = {
          'id': 'row-10',
          'name': 'Some Meal',
          'time_minutes': 20,
          'difficulty': 'medium',
          'ingredients': ['thing'],
          'steps': ['Do thing.'],
          'is_approved': false,
        };
        final meal = MealSuggestion.fromRow(row);
        expect(meal.priorityIngredients, isEmpty);
      });
    });
  });
}
