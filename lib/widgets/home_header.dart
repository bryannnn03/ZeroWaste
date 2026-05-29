import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/food_item.dart';
import 'stat_card.dart';
import 'fade_in_slide.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final int totalItems;
  final int expiringSoon;
  final int highUrgency;
  final VoidCallback? onTotalItemsTap;
  final List<FoodItem> items;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.totalItems,
    required this.expiringSoon,
    required this.highUrgency,
    this.onTotalItemsTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandGreenGradientStart,
            AppColors.brandGreenGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Decorative translucent background circles for depth
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title row ─────────────────────────────────────────────
                  FadeInSlide(
                    delay: Duration.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome Back!',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              userName.isEmpty ? '' : userName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                            ),
                            child: const Icon(LucideIcons.user, size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Stat Cards ────────────────────────────────────────────
                  FadeInSlide(
                    delay: const Duration(milliseconds: 150),
                    child: Row(
                      children: [
                        StatCard(
                          icon: LucideIcons.package,
                          iconBg: AppColors.infoBlueBg,
                          iconColor: AppColors.infoBlue,
                          value: totalItems.toString(),
                          label: 'Total Items',
                          onTap: onTotalItemsTap,
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          icon: LucideIcons.clock,
                          iconBg: AppColors.soonOrangeBg,
                          iconColor: AppColors.soonOrange,
                          value: expiringSoon.toString(),
                          label: 'Expiring Soon',
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          icon: LucideIcons.alertTriangle,
                          iconBg: AppColors.urgentRedBg,
                          iconColor: AppColors.urgentRed,
                          value: highUrgency.toString(),
                          label: 'High Urgency',
                          onTap: () => Navigator.pushNamed(context, '/urgency'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}