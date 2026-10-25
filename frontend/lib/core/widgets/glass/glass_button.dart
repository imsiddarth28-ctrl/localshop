import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_tokens.dart';

enum GlassButtonVariant {
  filled,
  outline,
}

class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final GlassButtonVariant? variant;
  final bool isLoading;
  final IconData? icon;
  final Color? customColor;
  final double? width;
  final double height;

  const GlassButton({
    super.key,
    this.text = '',
    required this.onPressed,
    this.isSecondary = false,
    this.variant,
    this.isLoading = false,
    this.icon,
    this.customColor,
    this.width,
    this.height = 54.0,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.customColor ?? (isDark ? AppTokens.primaryDark : AppTokens.primaryLight);

    final isSecondary = widget.isSecondary || widget.variant == GlassButtonVariant.outline;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: AppTokens.durationMicro,
      curve: AppTokens.curveSpring,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height,
        constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          boxShadow: isSecondary || !isEnabled
              ? []
              : [
                  BoxShadow(
                    color: primaryColor.withOpacity(isDark ? 0.35 : 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          child: Stack(
            children: [
              // 1. Background Fill / Gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                    gradient: isSecondary
                        ? LinearGradient(
                            colors: isDark
                                ? [const Color(0x1FFFFFFF), const Color(0x0AFFFFFF)]
                                : [const Color(0x80FFFFFF), const Color(0x4DFFFFFF)],
                          )
                        : LinearGradient(
                            colors: isEnabled
                                ? [primaryColor, primaryColor.withOpacity(0.85)]
                                : [Colors.grey.shade600, Colors.grey.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: Border.all(
                      color: isSecondary
                          ? (isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight)
                          : primaryColor.withOpacity(0.5),
                      width: 1.0,
                    ),
                  ),
                ),
              ),

              // 2. Top-Edge Gleam (Highlight)
              if (!isSecondary && isEnabled)
                Positioned(
                  top: 0,
                  left: 12,
                  right: 12,
                  height: 1.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. Button Content or Spinner
              Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSecondary ? primaryColor : (isDark ? const Color(0xFF0A0F1C) : Colors.white),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 18,
                              color: isSecondary
                                  ? (isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight)
                                  : (isDark ? const Color(0xFF0A0F1C) : Colors.white),
                            ),
                            if (widget.text.isNotEmpty) const SizedBox(width: 8),
                          ],
                          if (widget.text.isNotEmpty)
                            Text(
                              widget.text,
                              style: AppTokens.label(
                                isDark,
                                color: isSecondary
                                    ? (isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight)
                                    : (isDark ? const Color(0xFF0A0F1C) : Colors.white),
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
              ),

              // 4. InkWell Touch with Haptics
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                    onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
                    onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
                    onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
                    onTap: isEnabled
                        ? () {
                            HapticFeedback.lightImpact();
                            widget.onPressed?.call();
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
