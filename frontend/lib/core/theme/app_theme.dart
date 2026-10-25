import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.secondary,
        error: AppColors.error,
        onError: Colors.white,
        background: AppColors.backgroundLight,
        onBackground: AppColors.textPrimaryLight,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        surfaceVariant: AppColors.cardLight,
        onSurfaceVariant: AppColors.textSecondaryLight,
        outline: AppColors.dividerLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight, size: 28),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight, height: 1.2),
        displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight, height: 1.2),
        titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
        titleMedium: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
        bodyLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight, height: 1.4),
        bodyMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textSecondaryLight, height: 1.4),
        labelLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(58),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(58),
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: const TextStyle(fontSize: 16, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(fontSize: 16, color: AppColors.textMutedLight),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.textSecondaryLight,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.dividerLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.dividerLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.secondaryLight,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondary,
        onSecondaryContainer: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        background: AppColors.backgroundDark,
        onBackground: AppColors.textPrimaryDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceVariant: AppColors.cardDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        outline: AppColors.dividerDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark, size: 28),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark, height: 1.2),
        displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark, height: 1.2),
        titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
        titleMedium: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
        bodyLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark, height: 1.4),
        bodyMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textSecondaryDark, height: 1.4),
        labelLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(58),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size.fromHeight(58),
          side: const BorderSide(color: AppColors.primaryLight, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: const TextStyle(fontSize: 16, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(fontSize: 16, color: AppColors.textMutedDark),
        prefixIconColor: AppColors.primaryLight,
        suffixIconColor: AppColors.textSecondaryDark,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.dividerDark, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.dividerDark, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
