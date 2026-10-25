import 'package:flutter/material.dart';
import 'package:the_local_shop/core/theme/app_tokens.dart';
import 'package:the_local_shop/core/widgets/glass/glass.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  bool _pendingShopApproved = false;
  bool _resetRequestHandled = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin Summary KPIs (Glass Cards with Real/Fake Blur)
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                'Active Colonies',
                '1 Active',
                Icons.location_city_rounded,
                AppTokens.primary(isDark),
                isDark,
              ),
            ),
            const SizedBox(width: AppTokens.spacing8),
            Expanded(
              child: _buildKpiCard(
                'Colony Shops',
                '3 / 3 Cap',
                Icons.storefront_rounded,
                AppTokens.accentWarm,
                isDark,
              ),
            ),
            const SizedBox(width: AppTokens.spacing8),
            Expanded(
              child: _buildKpiCard(
                'Total GMV',
                '₹18,420',
                Icons.currency_rupee_rounded,
                AppTokens.info,
                isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTokens.spacing16),

        // Colony Config Card
        GlassCard(
          useRealBlur: true,
          padding: const EdgeInsets.all(AppTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Greenwood Heights',
                          style: AppTokens.headingSmall.copyWith(
                            fontSize: 17,
                            color: isDark
                                ? AppTokens.textPrimaryDark
                                : AppTokens.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Colony Hub • 142 Residents Enrolled',
                          style: AppTokens.bodySmall.copyWith(
                            color: isDark
                                ? AppTokens.textSecondaryDark
                                : AppTokens.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.primary(isDark).withOpacity(0.16),
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusChip),
                      border: Border.all(
                        color: AppTokens.primary(isDark).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      'JOIN: GRN101',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: AppTokens.primary(isDark),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spacing12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AppTokens.accentWarm,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Shop Cap: Max 3 enforced via Postgres RLS & DB Triggers',
                        style: AppTokens.bodySmall.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppTokens.textSecondaryDark
                              : AppTokens.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTokens.spacing20),

        // Section Title: Pending Shop Registrations
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Shop Registrations',
              style: AppTokens.headingSmall.copyWith(
                fontSize: 16,
                color: isDark
                    ? AppTokens.textPrimaryDark
                    : AppTokens.textPrimaryLight,
              ),
            ),
            if (!_pendingShopApproved)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.accentWarm.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '1 PENDING',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTokens.accentWarm,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spacing10),

        if (!_pendingShopApproved)
          GlassCard(
            useRealBlur: false,
            padding: const EdgeInsets.all(AppTokens.spacing16),
            borderColor: AppTokens.accentWarm.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vijaya Bakery & Sweets',
                      style: AppTokens.headingSmall.copyWith(
                        fontSize: 16,
                        color: isDark
                            ? AppTokens.textPrimaryDark
                            : AppTokens.textPrimaryLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.accentWarm.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'AWAITING APPROVAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTokens.accentWarm,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Owner: Vijaya Lakshmi • +91 95555 55555\nCategory: Bakery & Confectionery • Hours: 8 AM - 9 PM',
                  style: AppTokens.bodySmall.copyWith(
                    height: 1.4,
                    color: isDark
                        ? AppTokens.textSecondaryDark
                        : AppTokens.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppTokens.spacing12),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        text: 'Reject',
                        icon: Icons.close_rounded,
                        variant: GlassButtonVariant.outline,
                        height: 40,
                        onPressed: () {
                          GlassSnackbar.show(
                            context,
                            message: 'Shop registration rejected',
                            variant: GlassSnackbarVariant.info,
                          );
                          setState(() => _pendingShopApproved = true);
                        },
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacing10),
                    Expanded(
                      child: GlassButton(
                        text: 'Approve Shop',
                        icon: Icons.check_circle_outline_rounded,
                        variant: GlassButtonVariant.filled,
                        height: 40,
                        onPressed: () {
                          GlassSnackbar.show(
                            context,
                            message:
                                'Shop approved! Colony cap verified (3/3).',
                            variant: GlassSnackbarVariant.success,
                          );
                          setState(() => _pendingShopApproved = true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          GlassCard(
            useRealBlur: false,
            padding: const EdgeInsets.symmetric(
              vertical: AppTokens.spacing20,
              horizontal: AppTokens.spacing16,
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppTokens.primary(isDark),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'All shop applications reviewed. Queue is clean! ✨',
                    style: AppTokens.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTokens.primary(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: AppTokens.spacing20),

        // Password Reset Request Queue
        Text(
          'Password Reset Requests (Moderation)',
          style: AppTokens.headingSmall.copyWith(
            fontSize: 16,
            color: isDark
                ? AppTokens.textPrimaryDark
                : AppTokens.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppTokens.spacing10),

        if (!_resetRequestHandled)
          GlassCard(
            useRealBlur: false,
            padding: const EdgeInsets.all(AppTokens.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_reset_rounded,
                      color: AppTokens.accentWarm,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sita Devi (+91 94444 44441)',
                      style: AppTokens.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTokens.textPrimaryDark
                            : AppTokens.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Requested: 15 mins ago • Reason: Forgotten password',
                  style: AppTokens.bodySmall.copyWith(
                    color: isDark
                        ? AppTokens.textSecondaryDark
                        : AppTokens.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppTokens.spacing12),
                GlassButton(
                  text: 'Generate Temp Password (Temp@123)',
                  icon: Icons.key_rounded,
                  variant: GlassButtonVariant.filled,
                  height: 42,
                  onPressed: () {
                    GlassSnackbar.show(
                      context,
                      message:
                          'Temporary password generated! User must reset on next login.',
                      variant: GlassSnackbarVariant.success,
                    );
                    setState(() => _resetRequestHandled = true);
                  },
                ),
              ],
            ),
          )
        else
          GlassCard(
            useRealBlur: false,
            padding: const EdgeInsets.symmetric(
              vertical: AppTokens.spacing20,
              horizontal: AppTokens.spacing16,
            ),
            child: Center(
              child: Text(
                'No active password reset requests',
                style: AppTokens.bodySmall.copyWith(
                  color: isDark
                      ? AppTokens.textSecondaryDark
                      : AppTokens.textSecondaryLight,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildKpiCard(
    String title,
    String val,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return GlassCard(
      useRealBlur: false,
      padding: const EdgeInsets.symmetric(
        vertical: AppTokens.spacing14,
        horizontal: AppTokens.spacing8,
      ),
      borderColor: color.withOpacity(0.25),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            val,
            style: AppTokens.headingSmall.copyWith(
              fontSize: 16,
              color: isDark
                  ? AppTokens.textPrimaryDark
                  : AppTokens.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTokens.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTokens.textSecondaryDark
                  : AppTokens.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
