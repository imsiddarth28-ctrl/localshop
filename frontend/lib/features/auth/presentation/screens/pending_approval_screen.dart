import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elder_friendly_button.dart';
import '../providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _isChecking = false;

  void _checkStatus() async {
    setState(() => _isChecking = true);
    final user = ref.read(authProvider).user;
    if (user != null) {
      try {
        final repo = ref.read(authRepositoryProvider);
        final refreshed = await repo.fetchUserProfile(user.id);
        ref.read(authProvider.notifier).setDemoUser(refreshed);

        if (refreshed.shopStatus == 'approved' && mounted) {
          context.go('/home');
          return;
        }
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status checked: Still pending colony admin review.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.appTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: tr.logout,
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondaryLight, width: 2),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 54,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                tr.pendingApprovalTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr.pendingApprovalDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tr.pendingApprovalHint,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Check Status Button
              ElderFriendlyButton(
                text: tr.checkStatusBtn,
                isLoading: _isChecking,
                icon: Icons.refresh_rounded,
                onPressed: _checkStatus,
              ),
              const SizedBox(height: 16),

              // Simulation trigger for testing/demo
              TextButton(
                onPressed: () {
                  if (user != null) {
                    final approved = user.copyWith(shopStatus: 'approved');
                    ref.read(authProvider.notifier).setDemoUser(approved);
                    context.go('/home');
                  }
                },
                child: const Text(
                  '⚡ Demo Shortcut: Simulate Admin Approval',
                  style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
