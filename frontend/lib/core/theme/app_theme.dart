import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppTokens.primaryLight,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD1FAE5),
        onPrimaryContainer: Color(0xFF065F46),
        secondary: AppTokens.accentLight,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFEF3C7),
        onSecondaryContainer: Color(0xFF92400E),
        error: AppTokens.dangerLight,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: AppTokens.textPrimaryLight,
        outline: AppTokens.glassBorderLight,
      ),
      scaffoldBackgroundColor: AppTokens.bgLightStart,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppTokens.textPrimaryLight, size: 24),
        titleTextStyle: GoogleFonts.sora(
          color: AppTokens.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.sora(fontSize: 32, fontWeight: FontWeight.w700, color: AppTokens.textPrimaryLight, height: 1.2),
        displayMedium: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w700, color: AppTokens.textPrimaryLight, height: 1.25),
        titleLarge: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w600, color: AppTokens.textPrimaryLight),
        titleMedium: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.textPrimaryLight),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500, color: AppTokens.textPrimaryLight, height: 1.45),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, color: AppTokens.textSecondaryLight, height: 1.4),
        bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTokens.textSecondaryLight, height: 1.35),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTokens.textPrimaryLight, letterSpacing: 0.3),
      ),
      cardTheme: CardThemeData(
        color: AppTokens.glassFillLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          side: const BorderSide(color: AppTokens.glassBorderLight, width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppTokens.primaryDark,
        onPrimary: Color(0xFF0A0F1C),
        primaryContainer: Color(0x3334D399),
        onPrimaryContainer: AppTokens.primaryDark,
        secondary: AppTokens.accentDark,
        onSecondary: Color(0xFF0A0F1C),
        secondaryContainer: Color(0x33FBBF24),
        onSecondaryContainer: AppTokens.accentDark,
        error: AppTokens.dangerDark,
        onError: Colors.white,
        surface: AppTokens.bgDarkEnd,
        onSurface: AppTokens.textPrimaryDark,
        outline: AppTokens.glassBorderDark,
      ),
      scaffoldBackgroundColor: AppTokens.bgDarkStart,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppTokens.textPrimaryDark, size: 24),
        titleTextStyle: GoogleFonts.sora(
          color: AppTokens.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.sora(fontSize: 32, fontWeight: FontWeight.w700, color: AppTokens.textPrimaryDark, height: 1.2),
        displayMedium: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w700, color: AppTokens.textPrimaryDark, height: 1.25),
        titleLarge: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w600, color: AppTokens.textPrimaryDark),
        titleMedium: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.textPrimaryDark),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500, color: AppTokens.textPrimaryDark, height: 1.45),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, color: AppTokens.textSecondaryDark, height: 1.4),
        bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTokens.textSecondaryDark, height: 1.35),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTokens.textPrimaryDark, letterSpacing: 0.3),
      ),
      cardTheme: CardThemeData(
        color: AppTokens.glassFillDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          side: const BorderSide(color: AppTokens.glassBorderDark, width: 1),
        ),
      ),
    );
  }
}
