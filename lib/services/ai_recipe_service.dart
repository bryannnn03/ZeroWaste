import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/meal_suggestion.dart';
import '../models/food_item.dart';
import '../supabase_client.dart';

class AiRecipeService {
  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  
  // Store generated recipes globally so both screens can see them
  static final List<MealSuggestion> generatedRecipes = [];

  static String _buildPrompt(List<FoodItem> items) {
    final inventoryStr = items.map((i) => '- ${i.name} (${i.quantityDisplay}) - Expires in ${i.daysUntilExpiry} days').join('\n');
    return '''
You are a creative zero-waste chef. 
I have the following ingredients in my fridge that are expiring soon:

$inventoryStr

Please create a delicious single recipe that uses as many of these expiring ingredients as possible to prevent waste. You may assume I have basic pantry staples (oil, salt, pepper, basic spices, flour, etc.).

Return ONLY valid JSON in exactly this format:
{
  "name": "Name of the dish",
  "timeMinutes": 25,
  "difficulty": "easy", // must be "easy", "medium", or "hard"
  "ingredients": ["1 cup flour", "2 tomatoes", "Salt to taste"],
  "used_inventory_ids": ["id_from_above", ...],
  "instructions": "# Step 1\\nDo this\\n# Step 2\\nDo that"
}

Do not include markdown codeblocks around the JSON. Return just the JSON string. Ensure `used_inventory_ids` perfectly matches the IDs of the items you chose to use.
''';
  }

  static Future<MealSuggestion> generateRecipe(List<FoodItem> items) async {
    if (items.isEmpty) throw Exception('No expiring items to cook with!');

    // Build two separate sections: human-readable names for the recipe,
    // and an ID reference table so the LLM knows which IDs to use in used_inventory_ids.
    final ingredientLines = items.map((i) => '- ${i.name} (${i.quantityDisplay}, expires in ${i.daysUntilExpiry} days)').join('\n');
    final idReferenceTable = items.map((i) => '  "${i.name}": "${i.id}"').join(',\n');

    final prompt = '''
You are helping someone who has some cooking experience but is still an amateur — not a professional chef.
They enjoy cooking real, tasty food at home but prefer dishes that are straightforward, forgiving, and don't require expert techniques.

I have the following ingredients expiring soon that I need to use up:

$ingredientLines

For inventory tracking, here is the ID reference table (do NOT put these IDs anywhere in the recipe):
{
$idReferenceTable
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
YOUR TASK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Suggest ONE specific, well-loved dish that uses as many of my expiring ingredients as possible.
For most ingredients, prefer easy or medium difficulty dishes.
EXCEPTION: If the expiring ingredients include something special or premium — such as whole fish, crab, lobster, scallops, duck, lamb, beef tenderloin, wagyu, abalone, or other luxury produce — you MAY suggest a hard dish that does justice to those ingredients (e.g. Steamed Whole Fish with Ginger & Soy, Butter Crab, Roast Duck, Rack of Lamb).
You may assume I have pantry staples: cooking oil, salt, pepper, soy sauce, oyster sauce,
sugar, garlic, ginger, onion, cornstarch, eggs, and basic dried spices.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CRITICAL — DISH NAME RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Always use a SPECIFIC, REAL dish name that people actually search for and crave.
NEVER use generic AI-sounding names like:
  ✗ "Chicken Vegetable Stir Fry"
  ✗ "Mixed Protein Bowl"
  ✗ "Expiring Ingredient Medley"
  ✗ "Zero Waste Scramble"
  ✗ "Healthy One-Pan Meal"

Instead, name the dish like a real recipe, for example:
  ✓ "Nasi Goreng Kampung"  ✓ "Mee Goreng Mamak"  ✓ "Butter Chicken"
  ✓ "Tom Yam Soup"        ✓ "Char Kway Teow"   ✓ "Egg Fried Rice"
  ✓ "Ayam Masak Merah"    ✓ "Claypot Tofu"     ✓ "Sardine Curry"
  ✓ "Pasta Aglio e Olio"  ✓ "Beef Bolognese"   ✓ "Potato Wedges"
  ✓ "Mushroom Soup"       ✓ "Banana Pancakes"  ✓ "French Toast"
  ✓ "Omelette Rice"       ✓ "Spinach Dhal"     ✓ "Chicken Congee"
  ✓ "Simple Laksa"        ✓ "Sambal Goreng"    ✓ "Tuna Pasta"
  ✓ "Caesar Salad"        ✓ "Frittata"         ✓ "Shepherd's Pie"

Choose the dish that makes the BEST use of the expiring ingredients, sounds genuinely delicious, AND is realistic for a home cook to pull off.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEPS RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Write steps clearly for someone who knows the basics but may not know advanced techniques:
- Use plain, friendly language — like explaining to a housemate.
- Be specific with heat levels, times, and quantities in each step.
- If a step could go wrong, add a short tip (e.g. "don't let the garlic burn").
- Each step = one clear action. 1-2 sentences max.
- No markdown, no numbered prefixes, no bullet points.
- Example good step: "Heat 2 tbsp oil in a pan over medium heat, add the garlic and fry for about 30 seconds until golden — don't let it burn."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OTHER RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- "ingredients" must contain ONLY human-readable strings like "300g chicken thigh, sliced" or "2 tbsp oyster sauce". Never include IDs.
- "used_inventory_ids" must contain the UUID strings from the ID reference table for each expiring ingredient you used.
- "difficulty" must be exactly one of: "easy", "medium", or "hard".
- Return ONLY raw JSON with no markdown code fences.

JSON format:
{
  "name": "Nasi Goreng Kampung",
  "timeMinutes": 20,
  "difficulty": "easy",
  "ingredients": ["2 cups leftover cooked rice", "2 eggs", "100g chicken, diced", "3 cloves garlic, minced", "2 tbsp soy sauce", "1 tsp belacan (shrimp paste)", "Salt and pepper to taste", "Spring onions for garnish"],
  "used_inventory_ids": ["uuid-from-reference-table"],
  "steps": [
    "Beat the eggs in a small bowl and set aside.",
    "Heat 2 tbsp oil in a wok over high heat until smoking hot.",
    "Add the garlic and belacan, frying for 30 seconds until fragrant.",
    "Add the diced chicken and stir-fry for 3 minutes until cooked through.",
    "Push everything to the side, pour in the beaten egg, and scramble until just set.",
    "Add the rice, breaking up any clumps, and toss everything together for 2 minutes.",
    "Season with soy sauce, salt and pepper. Garnish with spring onions and serve immediately."
  ]
}
''';

    // Use OpenRouter's built-in free router first (auto-selects an available free model),
    // then fall back to specific known-working free model IDs.
    const models = [
      'openrouter/auto',          // OpenRouter's smart free router
      'meta-llama/llama-3.3-70b-instruct:free',
      'google/gemma-3-12b-it:free',
      'nvidia/llama-3.1-nemotron-nano-8b-v1:free',
    ];

    http.Response? response;
    String? lastError;

    for (final model in models) {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer ${AppConfig.openRouterApiKey}',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://zerowaste.app',
          'X-Title': 'ZeroWaste',
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 1200,
          'temperature': 0.85,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (res.statusCode == 200) {
        response = res;
        break;
      } else {
        // Extract the error message from the body for better debugging
        String bodyMsg = '';
        try {
          final errData = jsonDecode(res.body);
          bodyMsg = errData['error']?['message'] ?? res.body;
        } catch (_) {
          bodyMsg = res.body;
        }
        lastError = '[$model] HTTP ${res.statusCode}: $bodyMsg';
      }
    }

    if (response == null) {
      throw Exception('All AI models failed. Last error: $lastError');
    }

    final data = jsonDecode(response.body);
    final rawContent = data['choices']?[0]?['message']?['content'] as String? ?? '';
    
    // Clean up potential markdown codeblocks if the LLM ignores instructions
    String cleanContent = rawContent.trim();
    // Remove ```json ... ``` or ``` ... ``` fences
    cleanContent = cleanContent.replaceAll(RegExp(r'^```json\s*', multiLine: false), '');
    cleanContent = cleanContent.replaceAll(RegExp(r'^```\s*', multiLine: false), '');
    cleanContent = cleanContent.replaceAll(RegExp(r'\s*```$', multiLine: false), '');
    cleanContent = cleanContent.trim();

    final Map<String, dynamic> parsed = jsonDecode(cleanContent);

    final diffStr = parsed['difficulty']?.toString().toLowerCase() ?? 'medium';
    DifficultyLevel diff = DifficultyLevel.medium;
    if (diffStr == 'easy') diff = DifficultyLevel.easy;
    if (diffStr == 'hard') diff = DifficultyLevel.hard;

    final usedIdsList = (parsed['used_inventory_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    
    // Figure out priority ingredients based on what was used
    final priorityIngredients = items.where((i) => usedIdsList.contains(i.id)).map((i) => i.name).toList();

    // Defensive cleanup: strip any leaked ID patterns the LLM may have included in ingredient names
    final idPattern = RegExp(r'\s*[\(\[]ID:\s*[a-f0-9\-]{8,}[\)\]]', caseSensitive: false);
    final cleanedIngredients = (parsed['ingredients'] as List<dynamic>?)
        ?.map((e) => e.toString().replaceAll(idPattern, '').trim())
        .where((e) => e.isNotEmpty)
        .toList() ?? [];

    // Parse steps — prefer the new "steps" array, fall back to splitting "instructions" string
    List<String> steps;
    if (parsed['steps'] is List) {
      steps = (parsed['steps'] as List<dynamic>)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      // Fallback: split legacy instructions string on newlines / numbered prefixes
      final raw = (parsed['instructions'] ?? parsed['steps'] ?? 'Mix all ingredients and cook until done.').toString();
      steps = raw
          .split(RegExp(r'\n|(?<=\.)\s+(?=\d+\.)'))
          .map((s) => s.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (steps.isEmpty) steps = [raw];
    }

    // ── Persist to Supabase ─────────────────────────────────────────────
    String persistedId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final userId = supabase.auth.currentUser?.id;
      // 1. Insert into meal_recommendations and get the generated UUID back
      final mealInsert = await supabase
          .from('meal_recommendations')
          .insert({
            'user_id': userId,
            'name': parsed['name'] ?? 'Mystery Chef Special',
            'time_minutes': parsed['timeMinutes'] ?? 30,
            'difficulty': diffStr,
            'ingredients': cleanedIngredients,
            'steps': steps,
            'is_approved': false,
          })
          .select('id')
          .single();

      persistedId = mealInsert['id'].toString();

      // 2. Insert junction rows into meal_ingredients
      if (usedIdsList.isNotEmpty) {
        final ingredientRows = usedIdsList
            .map((itemId) => {'meal_id': persistedId, 'item_id': itemId})
            .toList();
        await supabase.from('meal_ingredients').insert(ingredientRows);
      }
    } catch (_) {
      // Persist failure is non-fatal — recipe still works in-memory this session
    }

    final recipe = MealSuggestion(
      id: persistedId,
      name: parsed['name'] ?? 'Mystery Chef Special',
      timeMinutes: parsed['timeMinutes'] ?? 30,
      difficulty: diff,
      ingredients: cleanedIngredients,
      isPriority: true,
      priorityIngredients: priorityIngredients,
      steps: steps,
      consumedItemIds: usedIdsList,
    );

    // Insert at front so newest is always top of the Meals Screen
    generatedRecipes.insert(0, recipe);
    return recipe;
  }
}