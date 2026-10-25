import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double? maxHeight;
  final EdgeInsetsGeometry padding;

  static final ImageFilter _blur = ImageFilter.blur(sigmaX: 20, sigmaY: 20);

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.maxHeight,
    this.padding = const EdgeInsets.all(AppTokens.space24),
  });

  static Future<T?> show<T>({
    required BuildContext context,
    Widget? child,
    Widget Function(BuildContext)? builder,
    double? maxHeight,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => GlassBottomSheet(
        maxHeight: maxHeight,
        child: child ?? (builder != null ? builder(ctx) : const SizedBox.shrink()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x66000000) : AppTokens.glassShadowLight,
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
        child: BackdropFilter(
          filter: _blur,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0x2EFFFFFF), const Color(0x1A0A0F1C)]
                    : [const Color(0xE6FFFFFF), const Color(0xB3FFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight,
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x66FFFFFF) : const Color(0x4D0F172A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
