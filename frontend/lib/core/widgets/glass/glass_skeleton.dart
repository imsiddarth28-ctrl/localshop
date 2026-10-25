import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

class GlassSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const GlassSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppTokens.radiusCard,
  });

  const GlassSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 999.0;

  @override
  State<GlassSkeleton> createState() => _GlassSkeletonState();
}

class _GlassSkeletonState extends State<GlassSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0x1AFFFFFF) : const Color(0x330F172A);
    final highlightColor = isDark ? const Color(0x38FFFFFF) : const Color(0x660F172A);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3.0 * _controller.value, 0.0),
              end: Alignment(-0.5 + 3.0 * _controller.value, 0.0),
              colors: [baseColor, highlightColor, baseColor],
            ),
            border: Border.all(
              color: isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight,
              width: 1.0,
            ),
          ),
        );
      },
    );
  }
}
