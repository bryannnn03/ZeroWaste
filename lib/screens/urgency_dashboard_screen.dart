import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/food_item.dart';
import '../widgets/urgency_item_card.dart';
import '../widgets/fade_in_slide.dart';
import '../supabase_client.dart';
import '../utils/food_item_mapper.dart';
import '../widgets/shimmer_loading.dart';

class UrgencyDashboardScreen extends StatefulWidget {
  const UrgencyDashboardScreen({super.key});

  @override
  State<UrgencyDashboardScreen> createState() => _UrgencyDashboardScreenState();
}

class _UrgencyDashboardScreenState extends State<UrgencyDashboardScreen> {
  List<FoodItem> _items = [];
  bool _loading = true;
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
      final response = await supabase
          .from('inventory')
          .select('id, name, category, quantity, unit, expiry_date')
          .eq('status', 'active')
          .order('expiry_date', ascending: true);

      final items = (response as List)
          .map((row) => rowToFoodItem(row as Map<String, dynamic>))
          .where((i) => i.urgency != UrgencyLevel.ok)
          .toList();

      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load items. Pull down to retry.';
          _loading = false;
        });
      }
    }
  }

  List<FoodItem> get _criticalItems => _items.where((i) => i.urgency == UrgencyLevel.urgent).toList();
  List<FoodItem> get _highItems     => _items.where((i) => i.urgency == UrgencyLevel.soon).toList();
  int get _mediumCount              => 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: RefreshIndicator(
        color: AppColors.urgentRed,
        onRefresh: _load,
        child: _loading ? _buildSkeleton() : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient Header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.urgentRed, AppColors.soonOrange],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button + title row
                    FadeInSlide(
                      delay: Duration.zero,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                              ),
                              child: const Icon(LucideIcons.chevronLeft, size: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                            ),
                            child: const Icon(LucideIcons.alertTriangle, size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Urgency Dashboard',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Items requiring immediate attention',
                                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Summary Card
                    FadeInSlide(
                      delay: const Duration(milliseconds: 150),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryCircle(
                              count: _criticalItems.length,
                              label: 'CRITICAL',
                              sublabel: '≤ 2 days',
                              color: AppColors.urgentRed,
                              bgColor: AppColors.urgentRedBg,
                              delay: const Duration(milliseconds: 250),
                            ),
                            _SummaryCircle(
                              count: _highItems.length,
                              label: 'HIGH',
                              sublabel: '3-5 days',
                              color: AppColors.soonOrange,
                              bgColor: AppColors.soonOrangeBg,
                              delay: const Duration(milliseconds: 350),
                            ),
                            _SummaryCircle(
                              count: _mediumCount,
                              label: 'MEDIUM',
                              sublabel: '6-7 days',
                              color: AppColors.yellowMedium,
                              bgColor: AppColors.yellowMediumBg,
                              delay: const Duration(milliseconds: 450),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  _ErrorBanner(message: _error!, onRetry: _load),
                  const SizedBox(height: 16),
                ],

                // Critical Priority
                if (_criticalItems.isNotEmpty) ...[
                  const FadeInSlide(
                    delay: Duration(milliseconds: 200),
                    child: _SectionHeader(color: AppColors.urgentRed, label: 'Critical Priority'),
                  ),
                  const SizedBox(height: 12),
                  ..._criticalItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return FadeInSlide(
                      delay: Duration(milliseconds: 250 + (idx * 80)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: UrgencyItemCard(item: item),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // High Priority
                if (_highItems.isNotEmpty) ...[
                  FadeInSlide(
                    delay: Duration(milliseconds: 200 + (_criticalItems.length * 80)),
                    child: const _SectionHeader(color: AppColors.soonOrange, label: 'High Priority'),
                  ),
                  const SizedBox(height: 12),
                  ..._highItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return FadeInSlide(
                      delay: Duration(milliseconds: 250 + (_criticalItems.length * 80) + (idx * 80)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: UrgencyItemCard(item: item),
                      ),
                    );
                  }),
                ],

                if (_items.isEmpty && _error == null) ...[
                  const SizedBox(height: 40),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 200),
                    child: _EmptyState(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.urgentRed, AppColors.soonOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: List.generate(4, (i) => const Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerLoading(
                  width: double.infinity,
                  height: 100,
                  borderRadius: 16,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final Color color;
  final String label;
  const _SectionHeader({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.foreground, letterSpacing: -0.2)),
        const SizedBox(width: 12),
        Expanded(
          child: CustomPaint(
            painter: _DottedLinePainter(color: AppColors.border.withValues(alpha: 0.8)),
            child: const SizedBox(height: 1),
          ),
        ),
      ],
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    const double dashWidth = 3;
    const double dashSpace = 3;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: scale.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Center(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 4, top: 4,
                  child: _ConfettiDot(color: AppColors.brandGreen, size: 8),
                ),
                Positioned(
                  right: 8, top: 12,
                  child: _ConfettiDot(color: AppColors.soonOrange, size: 6),
                ),
                Positioned(
                  left: 12, bottom: 8,
                  child: _ConfettiDot(color: AppColors.infoBlue, size: 7),
                ),
                Positioned(
                  right: 4, bottom: 4,
                  child: _ConfettiDot(color: AppColors.mint, size: 9),
                ),
                Container(
                  width: 76, height: 76,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandGreen.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.checkCircle2, size: 36, color: AppColors.brandGreen),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'All Clear!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.foreground, letterSpacing: -0.2),
            ),
            const SizedBox(height: 6),
            const Text(
              'No items need urgent attention right now.',
              style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiDot extends StatelessWidget {
  final Color color;
  final double size;
  const _ConfettiDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.urgentRedBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.urgentRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, size: 18, color: AppColors.urgentRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.urgentRed, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.urgentRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCircle extends StatelessWidget {
  final int count;
  final String label;
  final String sublabel;
  final Color color;
  final Color bgColor;
  final Duration delay;

  const _SummaryCircle({
    required this.count,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.bgColor,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final maxTarget = count > 10 ? count : 10;
    final targetValue = count == 0 ? 0.0 : (count / maxTarget).clamp(0.0, 1.0);

    return FadeInSlide(
      delay: delay,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: targetValue),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 54, height: 54,
                      child: CircularProgressIndicator(
                        value: value,
                        backgroundColor: bgColor,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeWidth: 4.5,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: count),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, countVal, _) {
                        return Text(
                          '$countVal',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.foreground, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(sublabel,
              style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}