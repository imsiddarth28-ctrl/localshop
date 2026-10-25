import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/customer_onboarding_screen.dart';
import '../../features/auth/presentation/screens/shop_onboarding_screen.dart';
import '../../features/auth/presentation/screens/pending_approval_screen.dart';
import '../../features/auth/presentation/screens/forced_change_password_screen.dart';
import '../../features/home/presentation/screens/home_shell_screen.dart';
import '../../features/auth/domain/models/app_role.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final user = authState.user;
      final isAuth = user != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' ||
          loc == '/signup' ||
          loc == '/splash';

      // 1. Unauthenticated users cannot access protected routes
      if (!isAuth && !isAuthRoute) {
        return '/login';
      }

      // 2. Authenticated user security checks
      if (user != null) {
        // Enforce admin-flagged password change
        if (user.mustChangePassword && loc != '/forced-change-password') {
          return '/forced-change-password';
        }

        // Enforce pending approval screen for shops awaiting admin review
        if (user.role == AppRole.shopOwner && user.shopStatus == 'pending' && loc != '/pending-approval') {
          return '/pending-approval';
        }

        // Enforce onboarding if profile details incomplete
        if (!user.isOnboarded) {
          if (user.role == AppRole.customer && loc != '/onboarding/customer') {
            return '/onboarding/customer';
          }
          if (user.role == AppRole.shopOwner && loc != '/onboarding/shop') {
            return '/onboarding/shop';
          }
        }

        // Authenticated users shouldn't access login/signup
        if (isAuthRoute) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding/customer',
        builder: (context, state) => const CustomerOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/shop',
        builder: (context, state) => const ShopOnboardingScreen(),
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/forced-change-password',
        builder: (context, state) => const ForcedChangePasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShellScreen(),
      ),
    ],
  );
});
