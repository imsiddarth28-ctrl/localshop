import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_tokens.dart';
import 'glass_performance.dart';

class GlassScaffold extends ConsumerStatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  ConsumerState<GlassScaffold> createState() => _GlassScaffoldState();
}

class _GlassScaffoldState extends ConsumerState<GlassScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _auroraController;

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tier = ref.watch(glassTierProvider);
    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (tier == GlassTier.low || disableAnim) {
      if (_auroraController.isAnimating) _auroraController.stop();
    } else {
      if (!_auroraController.isAnimating) _auroraController.repeat();
    }

    return Scaffold(
      extendBody: widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      backgroundColor: Colors.transparent,
      appBar: widget.appBar,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Deep Vertical Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppTokens.bgDarkStart, AppTokens.bgDarkEnd]
                    : [AppTokens.bgLightStart, AppTokens.bgLightEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Drifting Aurora Blobs (Blurred Radial Gradients)
          if (tier != GlassTier.low && !disableAnim)
            AnimatedBuilder(
              animation: _auroraController,
              builder: (context, _) {
                final t = _auroraController.value * 2 * math.pi;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Blob 1: Emerald / Mint
                    Positioned(
                      top: -120 + 40 * math.sin(t),
                      left: -80 + 50 * math.cos(t),
                      child: _buildBlob(
                        size: 380,
                        color: isDark ? AppTokens.auroraEmerald : AppTokens.auroraMint,
                      ),
                    ),
                    // Blob 2: Indigo / Sky
                    Positioned(
                      bottom: -100 + 60 * math.cos(t * 0.8),
                      right: -100 + 40 * math.sin(t * 0.8),
                      child: _buildBlob(
                        size: 420,
                        color: isDark ? AppTokens.auroraIndigo : AppTokens.auroraSky,
                      ),
                    ),
                    // Blob 3: Amber / Peach
                    Positioned(
                      top: 260 + 50 * math.sin(t * 1.2),
                      right: -60 + 30 * math.cos(t * 1.2),
                      child: _buildBlob(
                        size: 320,
                        color: isDark ? AppTokens.auroraAmber : AppTokens.auroraPeach,
                      ),
                    ),
                  ],
                );
              },
            )
          else
            // Static blobs for low tier
            Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -80,
                  left: -50,
                  child: _buildBlob(
                    size: 350,
                    color: isDark ? AppTokens.auroraEmerald : AppTokens.auroraMint,
                  ),
                ),
                Positioned(
                  bottom: -80,
                  right: -60,
                  child: _buildBlob(
                    size: 360,
                    color: isDark ? AppTokens.auroraIndigo : AppTokens.auroraSky,
                  ),
                ),
              ],
            ),

          // 3. Child Body Layer
          widget.body,
        ],
      ),
    );
  }

  Widget _buildBlob({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
          stops: const [0.0, 0.75],
        ),
      ),
    );
  }
}
