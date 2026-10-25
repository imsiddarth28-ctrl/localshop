import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_tokens.dart';

class GlassChip extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const GlassChip({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = activeColor ?? (isDark ? AppTokens.primaryDark : AppTokens.primaryLight);

    return AnimatedContainer(
      duration: AppTokens.durationMedium,
      curve: AppTokens.curvePop,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        color: isSelected
            ? primary.withOpacity(isDark ? 0.22 : 0.15)
            : (isDark ? AppTokens.glassFillDark : AppTokens.glassFillLight),
        border: Border.all(
          color: isSelected ? primary : (isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primary.withOpacity(isDark ? 0.3 : 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? primary
                        : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
                  ),
                  const SizedBox(width: 6),
                ],
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTokens.label(
                        isDark,
                        color: isSelected
                            ? primary
                            : (isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight),
                      ).copyWith(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTokens.bodySmall(isDark).copyWith(
                          color: isSelected ? primary.withOpacity(0.9) : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
