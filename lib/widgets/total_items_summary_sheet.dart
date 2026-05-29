import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/food_item.dart';
import '../utils/category_helpers.dart';
import 'fade_in_slide.dart';

/// Bottom sheet showing a quick inventory summary by category and urgency.
class TotalItemsSummarySheet extends StatelessWidget {
  final List<FoodItem> items;
  const TotalItemsSummarySheet({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final urgentCount = items.where((i) => i.urgency == UrgencyLevel.urgent).length;
    final soonCount = items.where((i) => i.urgency == UrgencyLevel.soon).length;
    final okCount = items.where((i) => i.urgency == UrgencyLevel.ok).length;

    // Category breakdown
    final catMap = <String, int>{};
    for (final item in items) {
      catMap[item.category] = (catMap[item.category] ?? 0) + 1;
    }
    final sortedCats = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Find earliest expiry
    String? earliestExpiry;
    if (items.isNotEmpty) {
      final sorted = [...items]..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
      final earliest = sorted.first;
      earliestExpiry = '${earliest.name} (${earliest.daysUntilExpiry == 0 ? "today" : earliest.daysUntilExpiry == 1 ? "1 day" : "${earliest.daysUntilExpiry} days"})';
    }

    // Largest category
    String? largestCat;
    if (sortedCats.isNotEmpty) {
      largestCat = '${sortedCats.first.key} (${sortedCats.first.value})';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.sheetRadius)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Hero total ───────────────────────────────────────────
            FadeInSlide(
              delay: Duration.zero,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.brandGreenGradientStart,
                      AppColors.brandGreenGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandGreen.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.package, size: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedCounter(value: total),
                    const SizedBox(height: 4),
                    Text(
                      'Total Items in Inventory',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Urgency distribution ─────────────────────────────────
            FadeInSlide(
              delay: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.pageBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'URGENCY BREAKDOWN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mutedForeground,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Bar
                    if (total > 0)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 10,
                          child: Row(
                            children: [
                              if (urgentCount > 0)
                                Expanded(
                                  flex: urgentCount,
                                  child: Container(color: AppColors.urgentRed),
                                ),
                              if (soonCount > 0)
                                Expanded(
                                  flex: soonCount,
                                  child: Container(color: AppColors.soonOrange),
                                ),
                              if (okCount > 0)
                                Expanded(
                                  flex: okCount,
                                  child: Container(color: AppColors.brandGreen),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _UrgencyDot(color: AppColors.urgentRed, label: 'Urgent', count: urgentCount),
                        const SizedBox(width: 16),
                        _UrgencyDot(color: AppColors.soonOrange, label: 'Soon', count: soonCount),
                        const SizedBox(width: 16),
                        _UrgencyDot(color: AppColors.brandGreen, label: 'Fresh', count: okCount),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Category breakdown ───────────────────────────────────
            if (sortedCats.isNotEmpty) ...[
              FadeInSlide(
                delay: const Duration(milliseconds: 150),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BY CATEGORY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mutedForeground,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...sortedCats.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final cat = entry.value;
                        return FadeInSlide(
                          delay: Duration(milliseconds: 200 + (idx * 50)),
                          child: _CategoryRow(
                            category: cat.key,
                            count: cat.value,
                            total: total,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Quick insights ───────────────────────────────────────
            FadeInSlide(
              delay: const Duration(milliseconds: 250),
              child: Row(
                children: [
                  if (earliestExpiry != null)
                    Expanded(
                      child: _InsightCard(
                        icon: LucideIcons.clock,
                        iconColor: AppColors.soonOrange,
                        iconBg: AppColors.soonOrangeBg,
                        label: 'Earliest Expiry',
                        value: earliestExpiry,
                      ),
                    ),
                  if (earliestExpiry != null && largestCat != null)
                    const SizedBox(width: 12),
                  if (largestCat != null)
                    Expanded(
                      child: _InsightCard(
                        icon: LucideIcons.barChart3,
                        iconColor: AppColors.infoBlue,
                        iconBg: AppColors.infoBlueBg,
                        label: 'Most Items',
                        value: largestCat,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated counter ─────────────────────────────────────────────────────────

class _AnimatedCounter extends StatefulWidget {
  final int value;
  const _AnimatedCounter({required this.value});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: widget.value.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Text(
        _animation.value.round().toString(),
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

// ── Urgency dot label ────────────────────────────────────────────────────────

class _UrgencyDot extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _UrgencyDot({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

// ── Category row with horizontal bar ─────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String category;
  final int count;
  final int total;
  const _CategoryRow({required this.category, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    final color = CategoryHelpers.colorFor(category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: CategoryHelpers.bgColorFor(category),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              CategoryHelpers.iconFor(category),
              size: 15,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                    Text(
                      '$count item${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
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

// ── Insight card ─────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.mutedForeground,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
