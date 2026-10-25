import 'package:flutter/material.dart';
import 'app_tokens.dart';

class AppColors {
  // Brand Emerald & Accent
  static const Color primary = AppTokens.primaryDark;
  static const Color primaryDark = AppTokens.primaryLight;
  static const Color primaryLight = Color(0xFF6EE7B7);
  static const Color primaryContainer = Color(0x1F34D399);

  // Brand Accent (Warm Amber)
  static const Color secondary = AppTokens.accentDark;
  static const Color secondaryLight = Color(0xFFFDE68A);
  static const Color secondaryContainer = Color(0x1FFBBF24);

  // Backgrounds & Surfaces (Day Mode)
  static const Color backgroundLight = AppTokens.bgLightStart;
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = AppTokens.glassFillLight;
  static const Color dividerLight = AppTokens.glassBorderLight;

  // Night Mode
  static const Color backgroundDark = AppTokens.bgDarkStart;
  static const Color surfaceDark = AppTokens.bgDarkEnd;
  static const Color cardDark = AppTokens.glassFillDark;
  static const Color dividerDark = AppTokens.glassBorderDark;

  // Text
  static const Color textPrimaryLight = AppTokens.textPrimaryLight;
  static const Color textSecondaryLight = AppTokens.textSecondaryLight;
  static const Color textMutedLight = Color(0xFF64748B);

  static const Color textPrimaryDark = AppTokens.textPrimaryDark;
  static const Color textSecondaryDark = AppTokens.textSecondaryDark;
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Status & Utility Colors
  static const Color success = AppTokens.primaryDark;
  static const Color error = AppTokens.dangerDark;
  static const Color warning = AppTokens.accentDark;
  static const Color info = AppTokens.infoDark;

  // Slot Badges
  static const Color instantSlotBadge = Color(0xFFF43F5E);
  static const Color morningSlotBadge = Color(0xFF38BDF8);
  static const Color eveningSlotBadge = Color(0xFFA855F7);
}
