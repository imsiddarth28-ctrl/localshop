import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass/glass.dart';
import '../../data/repositories/auth_repository.dart';
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
      GlassSnackbar.showInfo(context, 'Status checked: Still pending colony admin review.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final user = ref.watch(authProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        title: Text(tr.appTitle, style: AppTokens.headingSmall(isDark).copyWith(fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight),
            tooltip: tr.logout,
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassCard(
                padding: const EdgeInsets.all(AppTokens.space32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: (isDark ? AppTokens.accentDark : AppTokens.accentLight).withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isDark ? AppTokens.accentDark : AppTokens.accentLight).withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        size: 42,
                        color: isDark ? AppTokens.accentDark : AppTokens.accentLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr.pendingApprovalTitle,
                      textAlign: TextAlign.center,
                      style: AppTokens.headingMedium(isDark).copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr.pendingApprovalDesc,
                      textAlign: TextAlign.center,
                      style: AppTokens.bodyMedium(isDark),
                    ),
                    if (user?.shopName != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x330F172A),
                        ),
                        child: Text(
                          'Store: ${user!.shopName}',
                          style: AppTokens.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    GlassButton(
                      text: tr.checkStatusBtn,
                      isLoading: _isChecking,
                      icon: Icons.refresh_rounded,
                      onPressed: _checkStatus,
                    ),
                    const SizedBox(height: 14),
                    GlassButton(
                      text: tr.logout,
                      isSecondary: true,
                      icon: Icons.logout_rounded,
                      onPressed: () async {
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
