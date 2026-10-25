import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool useRealBlur; // Set false for scrolling lists (fake glass) to guarantee 60fps
  final double? width;
  final double? height;
  final Color? accentBorderColor;
  final Color? borderColor;

  // Cached filters for optimal GPU performance
  static final ImageFilter _blurHigh = ImageFilter.blur(sigmaX: 18, sigmaY: 18);

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppTokens.radiusCard,
    this.padding = const EdgeInsets.all(AppTokens.space24),
    this.margin,
    this.onTap,
    this.useRealBlur = false,
    this.width,
    this.height,
    this.accentBorderColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fillColors = isDark
        ? [const Color(0x1AFFFFFF), const Color(0x0AFFFFFF)] // 10% -> 4%
        : [const Color(0x99FFFFFF), const Color(0x66FFFFFF)]; // 60% -> 40%

    final effectiveBorderColor = borderColor ?? accentBorderColor;
    final borderColors = effectiveBorderColor != null
        ? [effectiveBorderColor.withOpacity(0.6), effectiveBorderColor.withOpacity(0.2)]
        : (isDark
            ? [const Color(0x47FFFFFF), const Color(0x0FFFFFFF)] // 28% -> 6%
            : [const Color(0xCCFFFFFF), const Color(0x66FFFFFF)]);

    final cardContent = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33000000) : AppTokens.glassShadowLight,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // 1. Real Blur Layer (Only for Hero/Standalone Cards)
            if (useRealBlur)
              Positioned.fill(
                child: BackdropFilter(
                  filter: _blurHigh,
                  child: const SizedBox.expand(),
                ),
              ),

            // 2. Translucent Glass Fill Gradient + Border
            Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  colors: fillColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: borderColors[0],
                  width: 1.0,
                ),
              ),
              child: child,
            ),

            // 3. Subtle Inner Top-Edge Highlight (Gleam)
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              height: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      isDark ? AppTokens.glassHighlightDark : Colors.white,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 4. Tap Ripple
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(borderRadius),
                    onTap: onTap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return RepaintBoundary(child: cardContent);
  }
}
