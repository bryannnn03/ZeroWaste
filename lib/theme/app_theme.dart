import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand
  static const brandGreen = Color(0xFF2DB84E);
  static const greenDark = Color(0xFF1FA83E);
  static const greenHeader = Color(0xFF22A845);
  static const mintBg = Color(0xFFEEF8F1);
  static const pageBg = Color(0xFFF6F8F6);

  // Gradients
  static const brandGreenGradientStart = Color(0xFF199D3C);
  static const brandGreenGradientEnd = Color(0xFF2DB84E);

  // Urgency
  static const urgentRed = Color(0xFFEF4444);
  static const urgentRedBg = Color(0xFFFEF2F2);
  static const soonOrange = Color(0xFFF97316);
  static const soonOrangeBg = Color(0xFFFFF7ED);
  static const priorityRoseBg = Color(0xFFFFF1F2);

  // Info
  static const infoBlue = Color(0xFF3B82F6);
  static const infoBlueBg = Color(0xFFEFF6FF);

  // Medium
  static const yellowMedium = Color(0xFFEAB308);
  static const yellowMediumBg = Color(0xFFFEFCE8);

  // Neutral
  static const foreground = Color(0xFF111827);
  static const mutedForeground = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const white = Colors.white;

  // ── New design tokens ───────────────────────────────────────────────
  static const surfaceGlass = Color(0xFFFAFDF9);
  static const shimmerBase = Color(0xFFE8F5E9);
  static const shimmerHighlight = Color(0xFFC8E6C9);
  static const emeraldDeep = Color(0xFF16A34A);
  static const emeraldLight = Color(0xFFBBF7D0);
  static const mint = Color(0xFFBBF7D0);

  static const double cardRadius = 18.0;
  static const double sheetRadius = 28.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.pageBg,
      colorScheme: ColorScheme.light(
        primary: AppColors.brandGreen,
        onPrimary: Colors.white,
        secondary: AppColors.mintBg,
        surface: Colors.white,
        error: AppColors.urgentRed,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.foreground),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.brandGreen,
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.sheetRadius)),
        ),
        showDragHandle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          side: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.brandGreen.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          minimumSize: const Size(64, 50),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brandGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.urgentRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.urgentRed, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
    );
  }
}
