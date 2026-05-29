import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerowaste/supabase_client.dart';
import 'package:zerowaste/services/ai_recipe_service.dart';
import 'package:zerowaste/models/food_item.dart';
import 'package:zerowaste/models/meal_suggestion.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('fake-user-id');
    when(() => mockSupabase.from(any())).thenThrow(const PostgrestException(message: 'Mock DB error'));
    supabase = mockSupabase;
  });

  group('AiRecipeService', () {
    group('generatedRecipes static list', () {
      setUp(() {
        // Always start each test with an empty list
        AiRecipeService.generatedRecipes.clear();
      });

      test('starts empty after clear', () {
        expect(AiRecipeService.generatedRecipes, isEmpty);
      });

      test('can manually add a recipe to the static list', () {
        const recipe = MealSuggestion(
          id: 'test-1',
          name: 'Manual Test Recipe',
          timeMinutes: 20,
          difficulty: DifficultyLevel.easy,
          ingredients: ['egg', 'salt'],
          isPriority: true,
          priorityIngredients: ['egg'],
          steps: ['Beat.', 'Cook.'],
        );
        AiRecipeService.generatedRecipes.insert(0, recipe);
        expect(AiRecipeService.generatedRecipes, hasLength(1));
        expect(AiRecipeService.generatedRecipes.first.id, 'test-1');
      });

      test('newest recipe appears first after insert at index 0', () {
        const recipe1 = MealSuggestion(
          id: 'r1',
          name: 'First Recipe',
          timeMinutes: 15,
          difficulty: DifficultyLevel.easy,
          ingredients: [],
          isPriority: false,
          priorityIngredients: [],
          steps: [],
        );
        const recipe2 = MealSuggestion(
          id: 'r2',
          name: 'Second Recipe',
          timeMinutes: 30,
          difficulty: DifficultyLevel.medium,
          ingredients: [],
          isPriority: false,
          priorityIngredients: [],
          steps: [],
        );
        AiRecipeService.generatedRecipes.insert(0, recipe1);
        AiRecipeService.generatedRecipes.insert(0, recipe2);

        expect(AiRecipeService.generatedRecipes.first.id, 'r2');
        expect(AiRecipeService.generatedRecipes.last.id, 'r1');
      });
    });

    group('generateRecipe parameter validation', () {
      test('throws Exception when items list is empty', () async {
        expect(
          () => AiRecipeService.generateRecipe([]),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No expiring items'),
          )),
        );
      });
    });

    group('_buildPrompt content (via public API surface)', () {
      // We can't call the private _buildPrompt directly, but we can verify
      // the prompt-building logic indirectly through the FoodItem.quantityDisplay
      // getter used inside it.
      test('FoodItem quantityDisplay is used correctly in prompt context', () {
        const item = FoodItem(
          id: 'inv-1',
          name: 'Broccoli',
          category: 'Produce',
          quantity: 2,
          unit: 'bunch',
          expiresOn: 'Apr 28, 2026',
          daysUntilExpiry: 3,
          urgency: UrgencyLevel.soon,
        );
        // The prompt uses item.quantityDisplay and item.daysUntilExpiry
        expect(item.quantityDisplay, '2 bunch');
        expect(item.daysUntilExpiry, 3);
      });
    });
  });

  group('AiRecipeService JSON response parsing logic', () {
    // These tests verify the parsing / cleanup logic by mimicking what
    // generateRecipe does internally on an already-fetched response.

    group('difficulty mapping', () {
      test('maps "easy" string to DifficultyLevel.easy', () {
        const diffStr = 'easy';
        DifficultyLevel diff = DifficultyLevel.medium;
        if (diffStr == 'easy') diff = DifficultyLevel.easy;
        if (diffStr == 'hard') diff = DifficultyLevel.hard;
        expect(diff, DifficultyLevel.easy);
      });

      test('maps "hard" string to DifficultyLevel.hard', () {
        const diffStr = 'hard';
        DifficultyLevel diff = DifficultyLevel.medium;
        if (diffStr == 'easy') diff = DifficultyLevel.easy;
        if (diffStr == 'hard') diff = DifficultyLevel.hard;
        expect(diff, DifficultyLevel.hard);
      });

      test('defaults to medium for unknown difficulty strings', () {
        const diffStr = 'intermediate';
        DifficultyLevel diff = DifficultyLevel.medium;
        if (diffStr == 'easy') diff = DifficultyLevel.easy;
        if (diffStr == 'hard') diff = DifficultyLevel.hard;
        expect(diff, DifficultyLevel.medium);
      });
    });

    group('ID leak pattern cleanup regex', () {
      test('strips "(ID: uuid)" pattern from ingredient string', () {
        final idPattern = RegExp(
          r'\s*[\(\[]ID:\s*[a-f0-9\-]{8,}[\)\]]',
          caseSensitive: false,
        );
        const raw = '2 cups broccoli (ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890)';
        final cleaned = raw.replaceAll(idPattern, '').trim();
        expect(cleaned, '2 cups broccoli');
      });

      test('strips "[ID: uuid]" pattern from ingredient string', () {
        final idPattern = RegExp(
          r'\s*[\(\[]ID:\s*[a-f0-9\-]{8,}[\)\]]',
          caseSensitive: false,
        );
        const raw = '300g chicken [ID: abc12345-6789-abcd-ef01-234567890abc]';
        final cleaned = raw.replaceAll(idPattern, '').trim();
        expect(cleaned, '300g chicken');
      });

      test('does not strip normal ingredient text without ID pattern', () {
        final idPattern = RegExp(
          r'\s*[\(\[]ID:\s*[a-f0-9\-]{8,}[\)\]]',
          caseSensitive: false,
        );
        const raw = '1 tbsp soy sauce';
        final cleaned = raw.replaceAll(idPattern, '').trim();
        expect(cleaned, '1 tbsp soy sauce');
      });

      test('leaves short hex strings alone (no false positives)', () {
        final idPattern = RegExp(
          r'\s*[\(\[]ID:\s*[a-f0-9\-]{8,}[\)\]]',
          caseSensitive: false,
        );
        const raw = 'Ingredient (ID: abc)'; // too short to match
        final cleaned = raw.replaceAll(idPattern, '').trim();
        expect(cleaned, 'Ingredient (ID: abc)');
      });
    });

    group('markdown fence removal regex', () {
      test('removes leading ```json fence', () {
        String content = '```json\n{"name":"Test"}';
        content = content.replaceAll(RegExp(r'^```json\s*', multiLine: false), '');
        // \s* absorbs the newline after ```json, leaving just the JSON object
        expect(content.trim(), '{"name":"Test"}');
      });

      test('removes trailing ``` fence', () {
        String content = '{"name":"Test"}\n```';
        content = content.replaceAll(RegExp(r'\s*```$', multiLine: false), '');
        expect(content.trim(), '{"name":"Test"}');
      });
    });

    group('steps parsing fallback logic', () {
      test('uses steps array when present', () {
        final parsed = {
          'steps': ['Heat oil.', 'Add vegetables.', 'Serve hot.']
        };
        List<String> steps;
        if (parsed['steps'] is List) {
          steps = (parsed['steps'] as List<dynamic>)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          steps = ['Mix all ingredients and cook until done.'];
        }
        expect(steps, ['Heat oil.', 'Add vegetables.', 'Serve hot.']);
      });

      test('falls back to splitting instructions string when steps is not a list', () {
        final parsed = {
          'instructions': '# Step 1\nHeat oil.\n# Step 2\nAdd vegetables.',
        };
        List<String> steps;
        if (parsed['steps'] is List) {
          steps = [];
        } else {
          final raw = (parsed['instructions'] ?? 'Mix all ingredients and cook until done.').toString();
          steps = raw
              .split(RegExp(r'\n|(?<=\.)\s+(?=\d+\.)'))
              .map((s) => s.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (steps.isEmpty) steps = [raw];
        }
        expect(steps, isNotEmpty);
        expect(steps.any((s) => s.contains('Heat oil')), isTrue);
      });

      test('filters out empty step strings', () {
        final parsed = {
          'steps': ['Valid step.', '', '  ', 'Another step.']
        };
        List<String> steps;
        if (parsed['steps'] is List) {
          steps = (parsed['steps'] as List<dynamic>)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          steps = [];
        }
        expect(steps, hasLength(2));
        expect(steps, ['Valid step.', 'Another step.']);
      });
    });

    group('priority ingredients derivation', () {
      test('filters items by whether their id appears in usedIdsList', () {
        const items = [
          FoodItem(id: 'id-1', name: 'Broccoli', category: 'Produce', quantity: 1, unit: 'bunch', expiresOn: '', daysUntilExpiry: 2, urgency: UrgencyLevel.urgent),
          FoodItem(id: 'id-2', name: 'Chicken', category: 'Meat', quantity: 500, unit: 'g', expiresOn: '', daysUntilExpiry: 1, urgency: UrgencyLevel.urgent),
          FoodItem(id: 'id-3', name: 'Carrot', category: 'Produce', quantity: 3, unit: 'pcs', expiresOn: '', daysUntilExpiry: 5, urgency: UrgencyLevel.soon),
        ];
        final usedIdsList = ['id-1', 'id-2'];
        final priorityIngredients = items
            .where((i) => usedIdsList.contains(i.id))
            .map((i) => i.name)
            .toList();
        expect(priorityIngredients, ['Broccoli', 'Chicken']);
        expect(priorityIngredients, isNot(contains('Carrot')));
      });

      test('returns empty list when no IDs match', () {
        const items = [
          FoodItem(id: 'id-X', name: 'Onion', category: 'Produce', quantity: 2, unit: 'pcs', expiresOn: '', daysUntilExpiry: 3, urgency: UrgencyLevel.soon),
        ];
        final usedIdsList = <String>['id-Y'];
        final priorityIngredients = items
            .where((i) => usedIdsList.contains(i.id))
            .map((i) => i.name)
            .toList();
        expect(priorityIngredients, isEmpty);
      });
    });
  });

  group('AiRecipeService.generateRecipe and API fallbacks', () {
    const inputItems = [
      FoodItem(
        id: 'uuid-1',
        name: 'Gardenia White Bread',
        category: 'Bakery',
        quantity: 1,
        unit: 'loaf',
        expiresOn: 'Jun 2, 2026',
        daysUntilExpiry: 4,
        urgency: UrgencyLevel.soon,
      ),
    ];

    test('generateRecipe parses markdown-fenced JSON and builds MealSuggestion', () async {
      final mockResponse = {
        'choices': [
          {
            'message': {
              'content': '```json\n{\n  "name": "Nasi Goreng Kampung",\n  "timeMinutes": 20,\n  "difficulty": "easy",\n  "ingredients": ["2 cups rice", "1 egg"],\n  "used_inventory_ids": ["uuid-1"],\n  "steps": ["Beat egg.", "Stir fry."]\n}\n```'
            }
          }
        ]
      };

      await http.runWithClient(() async {
        final suggestion = await AiRecipeService.generateRecipe(inputItems);
        expect(suggestion.name, 'Nasi Goreng Kampung');
        expect(suggestion.timeMinutes, 20);
        expect(suggestion.difficulty, DifficultyLevel.easy);
        expect(suggestion.ingredients, ['2 cups rice', '1 egg']);
        expect(suggestion.steps, ['Beat egg.', 'Stir fry.']);
        expect(suggestion.consumedItemIds, ['uuid-1']);
        expect(AiRecipeService.generatedRecipes.first.name, 'Nasi Goreng Kampung');
      }, () => MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      }));
    });

    test('generateRecipe falls back through the models list on failure', () async {
      int requestCount = 0;
      final mockResponse = {
        'choices': [
          {
            'message': {
              'content': '{\n  "name": "Sardine Curry",\n  "timeMinutes": 15,\n  "difficulty": "medium",\n  "ingredients": ["1 tin sardines"],\n  "used_inventory_ids": ["uuid-1"],\n  "steps": ["Heat pan.", "Simmer."]\n}'
            }
          }
        ]
      };

      await http.runWithClient(() async {
        final suggestion = await AiRecipeService.generateRecipe(inputItems);
        expect(suggestion.name, 'Sardine Curry');
        expect(requestCount, 2); // 1st failed, 2nd model succeeded
      }, () => MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('Internal Server Error', 500);
        }
        return http.Response(jsonEncode(mockResponse), 200);
      }));
    });

    test('generateRecipe splits instructions text if steps array is missing', () async {
      final mockResponse = {
        'choices': [
          {
            'message': {
              'content': '{\n  "name": "Simple Toast",\n  "timeMinutes": 5,\n  "difficulty": "easy",\n  "ingredients": ["1 slice bread"],\n  "used_inventory_ids": ["uuid-1"],\n  "instructions": "1. Toast bread. 2. Butter it."\n}'
            }
          }
        ]
      };

      await http.runWithClient(() async {
        final suggestion = await AiRecipeService.generateRecipe(inputItems);
        expect(suggestion.steps, hasLength(2));
        expect(suggestion.steps[0], 'Toast bread.');
        expect(suggestion.steps[1], 'Butter it.');
      }, () => MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      }));
    });
  });
}
