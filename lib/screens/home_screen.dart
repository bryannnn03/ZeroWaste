import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/food_item.dart';
import '../supabase_client.dart';
import '../widgets/home_header.dart';
import '../widgets/expiring_item_card.dart';
import '../widgets/empty_expiry_state.dart';
import '../widgets/fade_in_slide.dart';
import '../services/ai_recipe_service.dart';
import '../utils/food_item_mapper.dart';
import '../widgets/total_items_summary_sheet.dart';
import '../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToInventory;
  final VoidCallback? onGoToScan;
  final VoidCallback? onGoToMeals;
  const HomeScreen({super.key, this.onGoToInventory, this.onGoToScan, this.onGoToMeals});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FoodItem> _items = [];
  String _userName = '';
  bool _loading = true;
  bool _isGeneratingRecipe = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = supabase.auth.currentUser;
      final meta = user?.userMetadata;
      final name = (meta?['full_name'] as String?)?.trim() ??
          (meta?['name'] as String?)?.trim() ??
          user?.email?.split('@').first ??
          'there';

      final response = await supabase
          .from('inventory')
          .select('id, name, category, quantity, unit, expiry_date')
          .eq('status', 'active')
          .order('expiry_date', ascending: true);

      var items = (response as List)
          .map((row) => rowToFoodItem(row as Map<String, dynamic>))
          .toList();

      final expiredItems = items.where((i) => i.daysUntilExpiry < 0).toList();
      if (expiredItems.isNotEmpty) {
        final expiredIds = expiredItems.map((i) => int.parse(i.id)).toList();
        
        supabase.from('inventory').update({'status': 'wasted'}).inFilter('id', expiredIds).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(LucideIcons.trash2, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('${expiredItems.length} expired item${expiredItems.length > 1 ? 's' : ''} moved to waste.'),
                ]),
                backgroundColor: AppColors.urgentRed,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        });

        items.removeWhere((i) => i.daysUntilExpiry < 0);
      }

      if (mounted) {
        setState(() {
          _userName = name;
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load inventory. Pull down to retry.';
          _loading = false;
        });
      }
    }
  }

  int get _totalItems => _items.length;
  int get _expiringSoon => _items.where((i) => i.urgency != UrgencyLevel.ok).length;
  int get _highUrgency => _items.where((i) => i.urgency == UrgencyLevel.urgent).length;
  List<FoodItem> get _expiringItems =>
      _items.where((i) => i.urgency != UrgencyLevel.ok).take(5).toList();

  Future<void> _handleAiRecipe() async {
    final expiringItems = _expiringItems;
    if (expiringItems.isEmpty) return;

    setState(() => _isGeneratingRecipe = true);
    try {
      await AiRecipeService.generateRecipe(expiringItems);
      if (mounted) {
        if (widget.onGoToMeals != null) {
          widget.onGoToMeals!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate recipe: $e'),
            backgroundColor: AppColors.urgentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingRecipe = false);
    }
  }

  void _showTotalItemsSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TotalItemsSummarySheet(items: _items),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: RefreshIndicator(
        color: AppColors.brandGreen,
        onRefresh: _load,
        child: _loading
            ? _buildSkeleton()
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: HomeHeader(
                      userName: _userName,
                      totalItems: _totalItems,
                      expiringSoon: _expiringSoon,
                      highUrgency: _highUrgency,
                      onTotalItemsTap: _showTotalItemsSummary,
                      items: _items,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null) ...[
                            _ErrorBanner(message: _error!, onRetry: _load),
                            const SizedBox(height: 16),
                          ],
                          FadeInSlide(
                            delay: const Duration(milliseconds: 200),
                            child: _ProgressBanner(highUrgency: _highUrgency),
                          ),
                          const SizedBox(height: 16),
                          
                          // Scan Receipt Button
                          FadeInSlide(
                            delay: const Duration(milliseconds: 250),
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: widget.onGoToScan,
                                  icon: const Icon(LucideIcons.camera, size: 18, color: AppColors.mutedForeground),
                                  label: const Text(
                                    'Scan Receipt',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.foreground,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: AppColors.border, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // AI Chef Button
                          if (_expiringItems.isNotEmpty) ...[
                            FadeInSlide(
                              delay: const Duration(milliseconds: 300),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.brandGreenGradientStart,
                                      AppColors.brandGreenGradientEnd,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandGreen.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: _isGeneratingRecipe ? null : _handleAiRecipe,
                                    icon: _isGeneratingRecipe 
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Icon(LucideIcons.sparkles, size: 18, color: Colors.white),
                                    label: Text(
                                      _isGeneratingRecipe ? 'Generating Magic...' : 'Chef AI: Use Expiring Food',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ] else ...[
                            const SizedBox(height: 24),
                          ],

                          // Heading
                          FadeInSlide(
                            delay: const Duration(milliseconds: 350),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Items Expiring Soon',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.foreground,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: widget.onGoToInventory,
                                  child: Row(
                                    children: [
                                      const Text(
                                        'View All',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brandGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.brandGreen),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Expiring items list
                          if (_expiringItems.isEmpty)
                            const FadeInSlide(
                              delay: Duration(milliseconds: 400),
                              child: EmptyExpiryState(),
                            )
                          else
                            ..._expiringItems.asMap().entries.map(
                              (entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                return FadeInSlide(
                                  delay: Duration(milliseconds: 400 + (idx * 80)),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ExpiringItemCard(
                                      item: item,
                                      onTap: widget.onGoToInventory,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton with a shimmer tint
          const ShimmerLoading(
            width: double.infinity,
            height: 220,
            borderRadius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading(width: double.infinity, height: 60, borderRadius: 16),
                const SizedBox(height: 16),
                const ShimmerLoading(width: double.infinity, height: 50, borderRadius: 16),
                const SizedBox(height: 24),
                const ShimmerLoading(width: 150, height: 20, borderRadius: 4),
                const SizedBox(height: 16),
                ...List.generate(
                  3,
                  (i) => const Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ShimmerLoading(
                      width: double.infinity,
                      height: 80,
                      borderRadius: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  final int highUrgency;
  const _ProgressBanner({required this.highUrgency});

  @override
  Widget build(BuildContext context) {
    final hasUrgent = highUrgency > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasUrgent 
              ? [AppColors.urgentRed, const Color(0xFFEF5350)]
              : [AppColors.brandGreenGradientStart, AppColors.brandGreenGradientEnd],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (hasUrgent ? AppColors.urgentRed : AppColors.brandGreen).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasUrgent ? LucideIcons.alertTriangle : LucideIcons.trendingUp,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUrgent ? 'Attention Needed' : 'Great Progress!',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  hasUrgent
                      ? 'You have $highUrgency item${highUrgency > 1 ? 's' : ''} expiring very soon!'
                      : 'No urgent items right now — keep it up!',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.urgentRedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.urgentRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.urgentRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.urgentRed)),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.urgentRed),
            ),
          ),
        ],
      ),
    );
  }
}