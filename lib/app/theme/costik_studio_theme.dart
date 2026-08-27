import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CostikStudioTheme {
  const CostikStudioTheme._();

  static const navy = Color(0xFF0F172A);
  static const slate = Color(0xFF475569);
  static const softSlate = Color(0xFF64748B);
  static const background = Color(0xFFF8FAFC);
  static const primary = Color(0xFF2563EB);
  static const cyan = Color(0xFF06B6D4);
  static const amber = Color(0xFFF59E0B);

  static ThemeData get light {
    final textTheme = GoogleFonts.manropeTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: cyan,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme.apply(bodyColor: navy, displayColor: navy),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        foregroundColor: navy,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
    );
  }
}
