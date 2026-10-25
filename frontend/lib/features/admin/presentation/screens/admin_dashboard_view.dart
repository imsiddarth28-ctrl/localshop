import 'package:flutter/material.dart';
import 'package:the_local_shop/core/theme/app_colors.dart';
import 'package:the_local_shop/core/widgets/elder_friendly_button.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  bool _pendingShopApproved = true;
  bool _resetRequestHandled = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin Summary KPIs
        Row(
          children: [
            Expanded(
              child: _buildKpiCard('Colonies', '1 Active', Icons.location_city, AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard('Colony Shops', '3 / 3 Cap', Icons.store, AppColors.secondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard('Total GMV', '₹18,420', Icons.currency_rupee, AppColors.success),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Colony Config Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Colony: Greenwood Heights', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('JOIN CODE: GRN101', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Residents: 142 enrolled • Shop Cap: Max 3 (Enforced via Postgres RLS & Trigger)', style: TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Pending Shop Approval Queue
        const Text('Pending Shop Registrations (Queue)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (!_pendingShopApproved)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Vijaya Bakery & Sweets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                      child: const Text('PENDING APPROVAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Owner: Vijaya Lakshmi • +91 95555 55555\nCategory: Bakery & Confectionery • Hours: 8 AM - 9 PM', style: TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop registration rejected')));
                          setState(() => _pendingShopApproved = true);
                        },
                        child: const Text('Reject', style: TextStyle(color: AppColors.error)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Shop Approved! (Note: Colony cap verified)'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          setState(() => _pendingShopApproved = true);
                        },
                        child: const Text('Approve Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('All shop applications reviewed. Queue is clean! ✨', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success)),
            ),
          ),

        const SizedBox(height: 20),

        // Password Reset Request Queue
        const Text('Password Reset Requests (Admin Moderation)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (!_resetRequestHandled)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_reset, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Text('Sita Devi (+91 94444 44441)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Requested: 15 mins ago • Reason: Forgotten password', style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 10),
                ElderFriendlyButton(
                  text: 'Generate Temp Password (Temp@123)',
                  icon: Icons.key_rounded,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Temporary password generated! User must reset password on next login.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    setState(() => _resetRequestHandled = true);
                  },
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: const Center(
              child: Text('No active password reset requests', style: TextStyle(color: Colors.black54)),
            ),
          ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
