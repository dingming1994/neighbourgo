import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NeighbourGo Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Brand
  static const primary      = Color(0xFF1A7F64); // Deep teal-green
  static const primaryLight = Color(0xFF2ECC8A); // Mint green
  static const primaryDark  = Color(0xFF155F4B);
  static const accent       = Color(0xFFF4A621); // Warm amber
  static const accentLight  = Color(0xFFFFF3E0);

  // Backgrounds
  static const bgLight  = Color(0xFFF5FAF8);
  static const bgCard   = Color(0xFFFFFFFF);
  static const bgMint   = Color(0xFFE8F8F2);

  // Text
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF555555);
  static const textHint      = Color(0xFF999999);

  // Status
  static const success = Color(0xFF1A7F64);
  static const warning = Color(0xFFF4A621);
  static const error   = Color(0xFFD32F2F);
  static const info    = Color(0xFF1976D2);

  // Divider
  static const divider = Color(0xFFEEEEEE);
  static const border  = Color(0xFFDDDDDD);

  // Badge colours per category
  static const Map<String, Color> categoryColors = {
    'cleaning':    Color(0xFF29B6F6),
    'tutoring':    Color(0xFF7E57C2),
    'pet_care':    Color(0xFFEF5350),
    'errands':     Color(0xFF66BB6A),
    'queuing':     Color(0xFFFF7043),
    'handyman':    Color(0xFF8D6E63),
    'moving':      Color(0xFF26A69A),
    'personal_care': Color(0xFFEC407A),
    'admin':       Color(0xFF78909C),
    'events':      Color(0xFFFFCA28),
  };
}

class AppSpacing {
  AppSpacing._();
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  AppRadius._();
  static const sm  = Radius.circular(8);
  static const md  = Radius.circular(12);
  static const lg  = Radius.circular(16);
  static const xl  = Radius.circular(24);
  static const full = Radius.circular(999);
  static BorderRadius card = BorderRadius.circular(16);
  static BorderRadius button = BorderRadius.circular(12);
  static BorderRadius chip = BorderRadius.circular(999);
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      tertiary: AppColors.accent,
      background: AppColors.bgLight,
      surface: AppColors.bgCard,
      error: AppColors.error,
    ),
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgCard,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadius.button,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.button,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.button,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.button,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(color: AppColors.divider),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bgMint,
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.chip),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgCard,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textHint),
    ),
  );
}
