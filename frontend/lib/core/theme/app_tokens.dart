import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Performance tiers for adaptive glassmorphism
enum GlassTier {
  low, // sigma 8, fake glass on lists, static aurora
  medium, // sigma 14, real blur on hero/bars, fake glass on lists
  high, // sigma 18, full blur & animated aurora
}

/// Dual-purpose TextStyle: acts as a standard TextStyle (with .copyWith) AND as a callable (isDark)
class AppTextStyle extends TextStyle {
  final TextStyle Function(bool isDark) _builder;

  AppTextStyle(TextStyle baseDark, this._builder)
      : super(
          inherit: baseDark.inherit,
          color: baseDark.color,
          fontSize: baseDark.fontSize,
          fontWeight: baseDark.fontWeight,
          fontStyle: baseDark.fontStyle,
          letterSpacing: baseDark.letterSpacing,
          height: baseDark.height,
          fontFamily: baseDark.fontFamily,
        );

  TextStyle call([bool isDark = true]) => _builder(isDark);
}

class AppTokens {
  // ---------------------------------------------------------------------------
  // 1. BRAND & SEMANTIC PALETTE
  // ---------------------------------------------------------------------------
  // Dark mode primary & accent
  static const Color primaryDark = Color(0xFF34D399); // Vibrant emerald
  static const Color accentDark = Color(0xFFFBBF24); // Warm amber
  static const Color infoDark = Color(0xFF60A5FA); // Sky blue
  static const Color dangerDark = Color(0xFFF87171); // Soft coral
  static const Color successDark = primaryDark;

  // Light mode primary & accent (AA contrast calibrated)
  static const Color primaryLight = Color(0xFF059669); // Deep emerald
  static const Color accentLight = Color(0xFFD97706); // Deep amber
  static const Color infoLight = Color(0xFF2563EB); // Royal blue
  static const Color dangerLight = Color(0xFFDC2626); // Crimson
  static const Color successLight = primaryLight;

  // Universal static fallbacks / constants
  static const Color primaryConst = primaryDark;
  static const Color accentWarm = accentDark;
  static const Color info = infoDark;
  static const Color danger = dangerDark;
  static const Color success = successDark;

  // Adaptive palette helpers
  static Color primary(bool isDark) => isDark ? primaryDark : primaryLight;
  static Color accent(bool isDark) => isDark ? accentDark : accentLight;
  static Color infoColor(bool isDark) => isDark ? infoDark : infoLight;
  static Color dangerColor(bool isDark) => isDark ? dangerDark : dangerLight;
  static Color successColor(bool isDark) => isDark ? successDark : successLight;

  // ---------------------------------------------------------------------------
  // 2. BACKGROUNDS & GRADIENTS
  // ---------------------------------------------------------------------------
  // Dark Background: #0A0F1C -> #101828
  static const Color bgDarkStart = Color(0xFF0A0F1C);
  static const Color bgDarkEnd = Color(0xFF101828);

  // Light Background: #EEF3F8 -> #F8FAFC
  static const Color bgLightStart = Color(0xFFEEF3F8);
  static const Color bgLightEnd = Color(0xFFF8FAFC);

  // Aurora Blob Colors
  static const Color auroraEmerald = Color(0x4034D399); // 25% emerald
  static const Color auroraIndigo = Color(0x336366F1); // 20% indigo
  static const Color auroraAmber = Color(0x1FFBBF24); // 12% amber

  // Light Aurora Blobs (35% opacity)
  static const Color auroraMint = Color(0x59A7F3D0);
  static const Color auroraPeach = Color(0x59FED7AA);
  static const Color auroraSky = Color(0x59BAE6FD);

  // ---------------------------------------------------------------------------
  // 3. GLASS PROPERTIES
  // ---------------------------------------------------------------------------
  // Dark Glass
  static const Color glassFillDark = Color(0x14FFFFFF); // 8% white
  static const Color glassBorderDark = Color(0x29FFFFFF); // 16% white
  static const Color glassHighlightDark = Color(0x47FFFFFF); // 28% white
  static const Color textPrimaryDark = Color(0xFFF4F7FB);
  static const Color textSecondaryDark = Color(0xADF4F7FB); // 68%

  // Light Glass
  static const Color glassFillLight = Color(0x8CFFFFFF); // 55% white
  static const Color glassBorderLight = Color(0xCCFFFFFF); // 80% white
  static const Color glassShadowLight = Color(0x140F172A); // 8% slate
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);

  // ---------------------------------------------------------------------------
  // 4. RADII & ELEVATIONS
  // ---------------------------------------------------------------------------
  static const double radiusCard = 24.0;
  static const double radiusButton = 16.0;
  static const double radiusSheet = 32.0;
  static const double radiusChip = 999.0;
  static const double radiusField = 16.0;

  // ---------------------------------------------------------------------------
  // 5. SPACING SCALE
  // ---------------------------------------------------------------------------
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Spacing aliases
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing14 = 14.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // ---------------------------------------------------------------------------
  // 6. MOTION SYSTEM (Durations & Curves)
  // ---------------------------------------------------------------------------
  static const Duration durationMicro = Duration(milliseconds: 120);
  static const Duration durationSmall = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 320);
  static const Duration durationLarge = Duration(milliseconds: 500);
  static const Duration durationHero = Duration(milliseconds: 900);

  static const Curve curveEnter = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
  static const Curve curvePop = Curves.easeOutBack;
  static const Curve curveSpring = Cubic(0.34, 1.56, 0.64, 1.0);

  // ---------------------------------------------------------------------------
  // 7. TYPOGRAPHY HELPERS (Sora for Headings, Plus Jakarta Sans for Body)
  // ---------------------------------------------------------------------------
  static TextStyle _hLarge(bool isDark) => GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: isDark ? textPrimaryDark : textPrimaryLight,
        height: 1.2,
      );

  static TextStyle _hMedium(bool isDark) => GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: isDark ? textPrimaryDark : textPrimaryLight,
        height: 1.25,
      );

  static TextStyle _hSmall(bool isDark) => GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? textPrimaryDark : textPrimaryLight,
        height: 1.3,
      );

  static TextStyle _bLarge(bool isDark) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? textPrimaryDark : textPrimaryLight,
        height: 1.45,
      );

  static TextStyle _bMedium(bool isDark) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark ? textSecondaryDark : textSecondaryLight,
        height: 1.4,
      );

  static TextStyle _bSmall(bool isDark) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? textSecondaryDark : textSecondaryLight,
        height: 1.35,
      );

  // Hybrid properties: works as a TextStyle directly AND as a function(isDark)!
  static final AppTextStyle headingLarge = AppTextStyle(_hLarge(true), _hLarge);
  static final AppTextStyle headingMedium = AppTextStyle(_hMedium(true), _hMedium);
  static final AppTextStyle headingSmall = AppTextStyle(_hSmall(true), _hSmall);
  static final AppTextStyle bodyLarge = AppTextStyle(_bLarge(true), _bLarge);
  static final AppTextStyle bodyMedium = AppTextStyle(_bMedium(true), _bMedium);
  static final AppTextStyle bodySmall = AppTextStyle(_bSmall(true), _bSmall);

  // Explicit parametric style getters
  static TextStyle headingLargeStyle(bool isDark) => _hLarge(isDark);
  static TextStyle headingMediumStyle(bool isDark) => _hMedium(isDark);
  static TextStyle headingSmallStyle(bool isDark) => _hSmall(isDark);
  static TextStyle bodyLargeStyle(bool isDark) => _bLarge(isDark);
  static TextStyle bodyMediumStyle(bool isDark) => _bMedium(isDark);
  static TextStyle bodySmallStyle(bool isDark) => _bSmall(isDark);

  static TextStyle label(bool isDark, {Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? (isDark ? textPrimaryDark : textPrimaryLight),
        letterSpacing: 0.3,
      );
}
