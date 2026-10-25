import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

enum GlassSnackbarVariant {
  info,
  success,
  danger,
  error,
}

class GlassSnackbar {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, isSuccess: true);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, isError: true);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message);
  }

  static void show(
    BuildContext context, {
    required String message,
    GlassSnackbarVariant variant = GlassSnackbarVariant.info,
  }) {
    switch (variant) {
      case GlassSnackbarVariant.success:
        showSuccess(context, message);
        break;
      case GlassSnackbarVariant.danger:
      case GlassSnackbarVariant.error:
        showError(context, message);
        break;
      case GlassSnackbarVariant.info:
        showInfo(context, message);
        break;
    }
  }

  static void _show(
    BuildContext context,
    String message, {
    bool isSuccess = false,
    bool isError = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tintColor = isError
        ? (isDark ? AppTokens.dangerDark : AppTokens.dangerLight)
        : (isSuccess
            ? (isDark ? AppTokens.primaryDark : AppTokens.primaryLight)
            : (isDark ? AppTokens.infoDark : AppTokens.infoLight));

    final icon = isError
        ? Icons.error_outline_rounded
        : (isSuccess ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
            boxShadow: [
              BoxShadow(
                color: tintColor.withOpacity(isDark ? 0.25 : 0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [tintColor.withOpacity(0.2), const Color(0x1A0A0F1C)]
                        : [tintColor.withOpacity(0.12), Colors.white.withOpacity(0.9)],
                  ),
                  borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                  border: Border.all(
                    color: tintColor.withOpacity(0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: tintColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: AppTokens.bodyMediumStyle(isDark).copyWith(
                          color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
