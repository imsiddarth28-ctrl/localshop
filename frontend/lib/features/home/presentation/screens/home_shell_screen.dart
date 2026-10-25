import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_local_shop/core/l10n/app_locale.dart';
import 'package:the_local_shop/core/theme/app_colors.dart';
import 'package:the_local_shop/core/utils/formatters.dart';
import 'package:the_local_shop/core/widgets/elder_friendly_button.dart';
import 'package:the_local_shop/core/widgets/language_selector.dart';
import 'package:the_local_shop/features/admin/presentation/screens/admin_dashboard_view.dart';
import 'package:the_local_shop/features/auth/domain/models/app_role.dart';
import 'package:the_local_shop/features/auth/presentation/providers/auth_provider.dart';
import 'package:the_local_shop/features/shop_dashboard/presentation/screens/shop_dashboard_view.dart';
import 'package:the_local_shop/features/shops/presentation/widgets/customer_shop_list_view.dart';

class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Session expired. Please log in.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    final isShopkeeper = user.role == AppRole.shopOwner;
    final isAdmin = user.role == AppRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.colonyName ?? 'Greenwood Heights',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
            Text(
              isAdmin
                  ? "Admin Control Center"
                  : (isShopkeeper ? "Shopkeeper Store Dashboard" : "Colony Resident Portal"),
              style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isShopkeeper
                          ? AppColors.secondary
                          : (isAdmin ? const Color(0xFF2C3E50) : AppColors.primary),
                      isShopkeeper
                          ? AppColors.secondaryLight
                          : (isAdmin ? const Color(0xFF4CA1AF) : AppColors.primaryLight),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isShopkeeper ? AppColors.secondary : AppColors.primary).withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: Icon(
                            isShopkeeper
                                ? Icons.storefront_rounded
                                : (isAdmin ? Icons.admin_panel_settings : Icons.person_rounded),
                            size: 30,
                            color: isShopkeeper
                                ? AppColors.secondary
                                : (isAdmin ? const Color(0xFF2C3E50) : AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name.isNotEmpty ? user.name : 'Welcome',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppFormatters.formatPhoneDisplay(user.phone),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (user.address != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              user.address!,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Dynamic Role-based Content
              if (isAdmin)
                const AdminDashboardView()
              else if (isShopkeeper)
                const ShopDashboardView()
              else
                const CustomerShopListView(),

              const SizedBox(height: 30),

              // Sign Out Button
              ElderFriendlyButton(
                text: tr.logout,
                isSecondary: true,
                icon: Icons.logout_rounded,
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
