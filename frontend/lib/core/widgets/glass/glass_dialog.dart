import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

class GlassDialog extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  static final ImageFilter _blur = ImageFilter.blur(sigmaX: 18, sigmaY: 18);

  const GlassDialog({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.space24),
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => GlassDialog(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x66000000) : AppTokens.glassShadowLight,
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            child: BackdropFilter(
              filter: _blur,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0x2EFFFFFF), const Color(0x140A0F1C)]
                        : [const Color(0xF2FFFFFF), const Color(0xD9FFFFFF)],
                  ),
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(
                    color: isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight,
                    width: 1.2,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
