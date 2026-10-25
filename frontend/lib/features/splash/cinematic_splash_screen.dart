import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass/glass.dart';
import '../auth/presentation/providers/auth_provider.dart';
import 'cinematic_splash_painter.dart';

class CinematicSplashScreen extends ConsumerStatefulWidget {
  const CinematicSplashScreen({super.key});

  @override
  ConsumerState<CinematicSplashScreen> createState() => _CinematicSplashScreenState();
}

class _CinematicSplashScreenState extends ConsumerState<CinematicSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _initFlow();
  }

  Future<void> _initFlow() async {
    // 1. Check if first launch
    final prefs = await SharedPreferences.getInstance();
    final hasSeenSplash = prefs.getBool('has_seen_full_splash') ?? false;
    _isFirstLaunch = !hasSeenSplash;

    if (!mounted) return;

    // Check reduced motion
    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (!_isFirstLaunch || disableAnim) {
      // Short 1s logo-only version
      _animController.duration = const Duration(milliseconds: 1000);
      _animController.forward(from: 0.80);
    } else {
      await prefs.setBool('has_seen_full_splash', true);
      _animController.forward();
    }

    // 2. Preload Auth Session concurrently while animation plays
    _preloadData();

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _preloadData() async {
    // Trigger auth state read
    try {
      ref.read(authProvider);
    } catch (_) {}
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      final user = authState.user!;
      if (user.mustChangePassword) {
        context.go('/forced-change-password');
      } else if (!user.isOnboarded) {
        if (user.role.toDbString() == 'shop_owner') {
          context.go('/onboarding/shop');
        } else {
          context.go('/onboarding/customer');
        }
      } else if (user.role.toDbString() == 'shop_owner' && user.shopStatus == 'pending') {
        context.go('/pending-approval');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/login');
    }
  }

  void _skip() {
    _animController.stop();
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = context.tr;

    return GlassScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Skip Button in Top Right
            Positioned(
              top: 16,
              right: 20,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _animController.value < 0.85 ? 1.0 : 0.0,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        backgroundColor: isDark ? const Color(0x22FFFFFF) : const Color(0x330F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusChip)),
                      ),
                      onPressed: _skip,
                      child: Text(
                        'Skip',
                        style: AppTokens.label(isDark).copyWith(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. Cinematic 3D Scene with Perspective Tilt
            Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  final progress = _animController.value;

                  // 3D Perspective Matrix tilt
                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(0.04 * math.sin(progress * math.pi)); // gentle settle to 0

                  return Transform(
                    transform: matrix,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 380,
                      child: CustomPaint(
                        painter: CinematicSplashPainter(
                          progress: progress,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. Final Logo Shimmer Reveal in Act 4 (Hero Target for Login Screen)
            Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  final progress = _animController.value;
                  if (progress < 0.78) return const SizedBox.shrink();

                  final t = ((progress - 0.78) / 0.22).clamp(0.0, 1.0);
                  final scale = 0.85 + 0.15 * Curves.easeOutBack.transform(t);
                  final opacity = Curves.easeIn.transform(t);

                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Hero(
                            tag: 'app_logo_hero',
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0x2934D399) : const Color(0x33059669),
                                border: Border.all(
                                  color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 48,
                                color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            tr.appTitle,
                            style: AppTokens.headingLarge(isDark).copyWith(
                              letterSpacing: 0.5,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr.appTagline,
                            textAlign: TextAlign.center,
                            style: AppTokens.bodyMedium(isDark).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
