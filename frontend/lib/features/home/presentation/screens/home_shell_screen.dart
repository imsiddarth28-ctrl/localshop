import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_local_shop/core/constants/app_constants.dart';
import 'package:the_local_shop/core/l10n/app_locale.dart';
import 'package:the_local_shop/core/theme/app_tokens.dart';
import 'package:the_local_shop/core/theme/theme_provider.dart';
import 'package:the_local_shop/core/utils/formatters.dart';
import 'package:the_local_shop/core/widgets/glass/glass.dart';
import 'package:the_local_shop/core/widgets/language_selector.dart';
import 'package:the_local_shop/features/admin/presentation/screens/admin_dashboard_view.dart';
import 'package:the_local_shop/features/auth/domain/models/app_role.dart';
import 'package:the_local_shop/features/auth/presentation/providers/auth_provider.dart';
import 'package:the_local_shop/features/shop_dashboard/presentation/screens/shop_dashboard_view.dart';
import 'package:the_local_shop/features/shops/presentation/widgets/customer_shop_list_view.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return GlassScaffold(
        body: Center(
          child: GlassCard(
            padding: const EdgeInsets.all(AppTokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock_rounded, size: 48, color: AppTokens.accentDark),
                const SizedBox(height: 12),
                Text('Session expired. Please log in.', style: AppTokens.bodyLarge(isDark)),
                const SizedBox(height: 18),
                GlassButton(
                  text: 'Go to Login',
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isShopkeeper = user.role == AppRole.shopOwner;
    final isAdmin = user.role == AppRole.admin;

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  user.colonyName ?? 'Greenwood Heights',
                  style: AppTokens.headingSmall(isDark).copyWith(fontSize: 18),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(0.2),
                  ),
                  child: Text(
                    'GRN101',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              isAdmin
                  ? "Admin Control Center"
                  : (isShopkeeper ? "Shopkeeper Store Dashboard" : "Colony Resident Portal"),
              style: AppTokens.bodySmall(isDark).copyWith(
                fontSize: 11,
                color: isDark ? AppTokens.accentDark : AppTokens.accentLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageSelector(),
          ),
        ],
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _navIndex,
        onTap: (idx) => setState(() => _navIndex = idx),
        items: [
          GlassNavItem(
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront_rounded,
            label: isShopkeeper ? 'My Shop' : (isAdmin ? 'Admin' : 'Shops'),
          ),
          const GlassNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Orders',
          ),
          const GlassNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero User Greeting Glass Card
              GlassCard(
                useRealBlur: true,
                padding: const EdgeInsets.all(AppTokens.space20),
                accentBorderColor: isShopkeeper
                    ? (isDark ? AppTokens.accentDark : AppTokens.accentLight)
                    : (isDark ? AppTokens.primaryDark : AppTokens.primaryLight),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isShopkeeper
                                ? (isDark ? AppTokens.accentDark : AppTokens.accentLight)
                                : (isDark ? AppTokens.primaryDark : AppTokens.primaryLight))
                            .withOpacity(0.2),
                        border: Border.all(
                          color: isShopkeeper
                              ? (isDark ? AppTokens.accentDark : AppTokens.accentLight)
                              : (isDark ? AppTokens.primaryDark : AppTokens.primaryLight),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isShopkeeper
                            ? Icons.storefront_rounded
                            : (isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded),
                        size: 28,
                        color: isShopkeeper
                            ? (isDark ? AppTokens.accentDark : AppTokens.accentLight)
                            : (isDark ? AppTokens.primaryDark : AppTokens.primaryLight),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name.isNotEmpty ? user.name : 'Resident',
                            style: AppTokens.headingSmall(isDark).copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.formatPhoneDisplay(user.phone),
                            style: AppTokens.bodySmall(isDark),
                          ),
                          if (user.address != null && user.address!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.home_rounded, size: 13, color: AppTokens.accentDark),
                                const SizedBox(width: 4),
                                Text(
                                  user.address!,
                                  style: AppTokens.bodySmall(isDark).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                        color: isDark ? const Color(0x1FFFFFFF) : const Color(0x330F172A),
                      ),
                      child: Text(
                        user.role.toDisplayName(),
                        style: AppTokens.bodySmall(isDark).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Tab Navigation Switcher
              if (_navIndex == 0) ...[
                // Main View based on role
                if (isAdmin)
                  const AdminDashboardView()
                else if (isShopkeeper)
                  const ShopDashboardView()
                else
                  const CustomerShopListView(),
              ] else if (_navIndex == 1) ...[
                // Orders tab view
                if (isShopkeeper)
                  const ShopDashboardView()
                else
                  const CustomerShopListView(),
              ] else ...[
                // Profile & Settings Glass Card
                _buildProfileSettingsView(context, tr, isDark, user),
              ],

              const SizedBox(height: 90), // Bottom nav clearance
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSettingsView(BuildContext context, dynamic tr, bool isDark, dynamic user) {
    final currentTier = ref.watch(glassTierProvider);

    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferences & Performance', style: AppTokens.headingSmall(isDark).copyWith(fontSize: 18)),
          const SizedBox(height: 14),

          // Reduce effects / performance toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('High Performance Glass', style: AppTokens.bodyLarge(isDark).copyWith(fontSize: 15)),
            subtitle: Text('Toggles real backdrop blurs & animated aurora', style: AppTokens.bodySmall(isDark)),
            value: currentTier != GlassTier.low,
            activeColor: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
            onChanged: (val) {
              ref.read(glassTierProvider.notifier).setTier(val ? GlassTier.high : GlassTier.low);
            },
          ),
          const Divider(),

          // Colony Info Tile
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_city_rounded, color: AppTokens.primaryDark),
            title: Text('Colony: ${user.colonyName ?? "Greenwood Heights"}', style: AppTokens.bodyLarge(isDark).copyWith(fontSize: 15)),
            subtitle: Text('Join Code: GRN101 • Max 3 shops', style: AppTokens.bodySmall(isDark)),
          ),
          const Divider(),

          const SizedBox(height: 20),
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
    );
  }
}
