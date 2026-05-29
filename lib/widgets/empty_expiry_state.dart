import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class EmptyExpiryState extends StatelessWidget {
  const EmptyExpiryState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        // Very subtle success gradient background
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppColors.brandGreen.withValues(alpha: 0.03),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration circle with Stack of decorative elements
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Faint green outer ring
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.brandGreen.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                ),
                // Inner success badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x332DB84E),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.check, size: 24, color: Colors.white),
                ),
                // Decorative dots
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.brandGreen, shape: BoxShape.circle)),
                ),
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.soonOrange.withValues(alpha: 0.7), shape: BoxShape.circle)),
                ),
                Positioned(
                  top: 24,
                  right: 12,
                  child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.yellowMedium, shape: BoxShape.circle)),
                ),
                Positioned(
                  bottom: 20,
                  left: 10,
                  child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.infoBlue, shape: BoxShape.circle)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'All Fresh!',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.foreground,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No items expiring soon — great job!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
