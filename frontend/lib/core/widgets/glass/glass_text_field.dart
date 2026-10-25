import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

class GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final int maxLines;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  String? _errorText;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void triggerErrorShake() {
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;
    final dangerColor = isDark ? AppTokens.dangerDark : AppTokens.dangerLight;

    final hasError = _errorText != null;

    final borderColor = hasError
        ? dangerColor
        : (_isFocused
            ? primaryColor
            : (isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight));

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Floating Label
          Text(
            widget.label,
            style: AppTokens.label(
              isDark,
              color: hasError
                  ? dangerColor
                  : (_isFocused ? primaryColor : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight)),
            ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),

          // 2. Translucent Glass Input Box
          AnimatedContainer(
            duration: AppTokens.durationSmall,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusField),
              color: isDark ? AppTokens.glassFillDark : AppTokens.glassFillLight,
              border: Border.all(color: borderColor, width: _isFocused || hasError ? 1.5 : 1.0),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: (hasError ? dangerColor : primaryColor).withOpacity(isDark ? 0.25 : 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: isDark ? const Color(0x1A000000) : AppTokens.glassShadowLight,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusField),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                enabled: widget.enabled,
                maxLines: widget.maxLines,
                style: AppTokens.bodyLarge(isDark).copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppTokens.bodyMedium(isDark).copyWith(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: _isFocused ? primaryColor : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
                          size: 20,
                        )
                      : null,
                  suffixIcon: widget.suffixIcon,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (val) {
                  final result = widget.validator?.call(val);
                  setState(() => _errorText = result);
                  if (result != null) {
                    triggerErrorShake();
                  }
                  return result;
                },
                onChanged: (val) {
                  if (_errorText != null) {
                    final res = widget.validator?.call(val);
                    setState(() => _errorText = res);
                  }
                  widget.onChanged?.call(val);
                },
                onFieldSubmitted: widget.onSubmitted,
              ),
            ),
          ),

          // 3. Inline Error Text
          if (_errorText != null) ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 14, color: dangerColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: AppTokens.bodySmall(isDark).copyWith(
                        color: dangerColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
