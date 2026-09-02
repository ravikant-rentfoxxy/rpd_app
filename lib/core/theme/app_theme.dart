import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final display = GoogleFonts.bricolageGrotesqueTextTheme();
    final body = GoogleFonts.archivoTextTheme();
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brand,
        secondary: AppColors.brandLight,
        surface: AppColors.card,
        error: AppColors.bad,
      ),
    );
    return base.copyWith(
      textTheme: body.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -1.2,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.6,
        ),
        titleLarge: display.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        bodyMedium: body.bodyMedium?.copyWith(
          fontSize: 15,
          height: 1.6,
          color: AppColors.ink,
          fontFamilyFallback: const ['Noto Sans Devanagari'],
        ),
        labelSmall: body.labelSmall?.copyWith(fontSize: 11, color: AppColors.ink3),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
