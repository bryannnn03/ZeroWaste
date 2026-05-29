import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/meal_suggestion.dart';
import '../widgets/fade_in_slide.dart';
import '../services/ai_recipe_service.dart';
import '../supabase_client.dart';

class MealsScreen extends StatefulWidget {
  final VoidCallback? onItemsConsumed;
  const MealsScreen({super.key, this.onItemsConsumed});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  final Set<String> _expandedMeals = {};
  bool _isCooking = false;
  bool _loadingDb = false;

  @override
  void initState() {
    super.initState();
    _loadPersistedMeals();
  }

  Future<void> _loadPersistedMeals() async {
    setState(() => _loadingDb = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final rows = await supabase
          .from('meal_recommendations')
          .select('id, name, time_minutes, difficulty, ingredients, steps, is_approved')
          .eq('user_id', userId)
          .eq('is_approved', false)
          .order('created_at', ascending: false);

      final existingIds = AiRecipeService.generatedRecipes.map((m) => m.id).toSet();

      for (final row in (rows as List)) {
        final mealId = row['id'].toString();
        if (existingIds.contains(mealId)) continue;

        final ingredientRows = await supabase
            .from('meal_ingredients')
            .select('item_id')
            .eq('meal_id', mealId);

        final itemIds = (ingredientRows as List)
            .map((r) => r['item_id'].toString())
            .toList();

        final meal = MealSuggestion.fromRow(row, itemIds: itemIds);
        AiRecipeService.generatedRecipes.add(meal);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingDb = false);
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedMeals.contains(id)) {
        _expandedMeals.remove(id);
      } else {
        _expandedMeals.add(id);
      }
    });
  }

  Future<void> _handleCooked(MealSuggestion meal) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConsumptionChoiceSheet(),
    );

    if (choice == null || !mounted) return;

    setState(() => _isCooking = true);
    try {
      final idsToConsume = meal.consumedItemIds ?? [];

      if (choice == 'full') {
        if (idsToConsume.isNotEmpty) {
          await supabase
              .from('inventory')
              .update({'status': 'consumed', 'quantity': 0})
              .inFilter('id', idsToConsume);
        }
      } else {
        if (idsToConsume.isNotEmpty) {
          await supabase
              .from('inventory')
              .update({'is_opened': true})
              .inFilter('id', idsToConsume);
        }
      }

      await supabase
          .from('meal_recommendations')
          .update({
            'is_approved': true,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', meal.id);

      setState(() {
        AiRecipeService.generatedRecipes.remove(meal);
      });

      widget.onItemsConsumed?.call();

      if (mounted) {
        final message = choice == 'full'
            ? 'Ingredients marked as consumed!'
            : 'Got it! Partially used items are still in your inventory.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ]),
            backgroundColor: AppColors.brandGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.urgentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meals = AiRecipeService.generatedRecipes;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const FadeInSlide(
                delay: Duration.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart Recipes',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.foreground, letterSpacing: -0.5)),
                    SizedBox(height: 2),
                    Text('AI-Generated from your fridge inventory',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.brandGreen)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_loadingDb)
                const Center(child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: CircularProgressIndicator(color: AppColors.brandGreen),
                ))
              else if (meals.isEmpty)
                FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  child: _buildEmptyState(),
                )
              else
                ...meals.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final meal = entry.value;
                  return FadeInSlide(
                    delay: Duration(milliseconds: 100 + (idx * 80)),
                    child: _buildMealCard(meal),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.brandGreen.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(LucideIcons.chefHat, size: 36, color: AppColors.brandGreen),
          ),
          const SizedBox(height: 16),
          const Text('No AI Recipes Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.foreground, letterSpacing: -0.2)),
          const SizedBox(height: 8),
          const Text(
            'Generate custom zero-waste recipes using ingredients already in your fridge!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground, height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          // Step indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEmptyStep(1, LucideIcons.home, 'Go Home'),
              const Icon(LucideIcons.arrowRight, size: 16, color: AppColors.border),
              _buildEmptyStep(2, LucideIcons.sparkles, 'Tap Chef AI'),
              const Icon(LucideIcons.arrowRight, size: 16, color: AppColors.border),
              _buildEmptyStep(3, LucideIcons.utensils, 'Get Recipes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStep(int number, IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.pageBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Center(child: Icon(icon, size: 16, color: AppColors.mutedForeground)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.foreground),
        ),
      ],
    );
  }

  Widget _buildMealCard(MealSuggestion meal) {
    final isExpanded = _expandedMeals.contains(meal.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top gradient bar accent
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.brandGreenGradientStart, AppColors.brandGreenGradientEnd],
              ),
            ),
          ),
          // Header (Tappable)
          InkWell(
            onTap: () => _toggleExpand(meal.id),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(meal.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.foreground, letterSpacing: -0.3)),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        color: AppColors.mutedForeground,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChip(LucideIcons.clock, '${meal.timeMinutes} min', AppColors.infoBlueBg, AppColors.infoBlue),
                      const SizedBox(width: 8),
                      _buildChip(LucideIcons.flame, meal.difficultyLabel, AppColors.soonOrangeBg, AppColors.soonOrange),
                      if (meal.isPriority) ...[
                        const SizedBox(width: 8),
                        _buildChip(LucideIcons.alertTriangle, 'Saves Food', AppColors.urgentRedBg, AppColors.urgentRed),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable Content using AnimatedSize for smooth resizing
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass,
                      border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.35))),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('INGREDIENTS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.mutedForeground, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: meal.ingredients.map((ing) {
                            final isPriorityIng = meal.priorityIngredients.any((p) => p.toLowerCase().contains(ing.toLowerCase()) || ing.toLowerCase().contains(p.toLowerCase()));
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                              decoration: BoxDecoration(
                                color: isPriorityIng ? AppColors.urgentRed.withValues(alpha: 0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isPriorityIng ? AppColors.urgentRed.withValues(alpha: 0.3) : AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(ing,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isPriorityIng ? AppColors.urgentRed : AppColors.foreground,
                                  )),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        
                        const Text('HOW TO COOK',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.mutedForeground, letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        ...meal.steps.asMap().entries.map((entry) {
                          final stepNum = entry.key + 1;
                          final stepText = entry.value;
                          final isLast = stepNum == meal.steps.length;
                          return _buildStepCard(stepNum, stepText, isLast);
                        }),
                        const SizedBox(height: 24),
                        
                        // Cooking confirmation button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isCooking ? null : () => _handleCooked(meal),
                            icon: _isCooking 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(LucideIcons.utensilsCrossed, size: 18),
                            label: Text(_isCooking ? 'Marking as consumed...' : 'I Cooked This!',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textCol),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildStepCard(int stepNum, String text, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNum',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.brandGreen,
                            AppColors.brandGreen.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 6),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsumptionChoiceSheet extends StatelessWidget {
  const _ConsumptionChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.utensilsCrossed, size: 28, color: AppColors.brandGreen),
          ),
          const SizedBox(height: 16),

          const Text(
            'How much did you use?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This helps keep your inventory accurate.',
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'full'),
              icon: const Icon(LucideIcons.checkCircle, size: 18, color: Colors.white),
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fully Used',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('All ingredients are finished',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppColors.brandGreen.withValues(alpha: 0.25),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, 'partial'),
              icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.foreground),
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Partially Used',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppColors.foreground)),
                  Text('Some ingredients are still left',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                          color: AppColors.mutedForeground.withValues(alpha: 0.85))),
                ],
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.foreground,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}