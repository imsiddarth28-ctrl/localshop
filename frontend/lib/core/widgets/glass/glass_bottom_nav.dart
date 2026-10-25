import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_tokens.dart';

class GlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  static final ImageFilter _blur = ImageFilter.blur(sigmaX: 18, sigmaY: 18);

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x4D000000) : AppTokens.glassShadowLight,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            child: Stack(
              children: [
                // 1. Real Blur
                Positioned.fill(
                  child: BackdropFilter(
                    filter: _blur,
                    child: const SizedBox.expand(),
                  ),
                ),

                // 2. Glass Fill & Border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0x2EFFFFFF), const Color(0x14FFFFFF)]
                          : [const Color(0xB3FFFFFF), const Color(0x80FFFFFF)],
                    ),
                    border: Border.all(
                      color: isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(items.length, (index) {
                      final isSelected = index == currentIndex;
                      final item = items[index];

                      return GestureDetector(
                        onTap: () {
                          if (!isSelected) {
                            HapticFeedback.selectionClick();
                            onTap(index);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: AppTokens.durationMedium,
                          curve: AppTokens.curvePop,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                            color: isSelected
                                ? primaryColor.withOpacity(isDark ? 0.22 : 0.15)
                                : Colors.transparent,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 22,
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                AnimatedOpacity(
                                  duration: AppTokens.durationSmall,
                                  opacity: isSelected ? 1.0 : 0.0,
                                  child: Text(
                                    item.label,
                                    style: AppTokens.label(isDark, color: primaryColor).copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // 3. Top Gleam
                Positioned(
                  top: 0,
                  left: 24,
                  right: 24,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
