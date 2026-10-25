import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_local_shop/core/theme/app_colors.dart';
import 'package:the_local_shop/core/theme/app_tokens.dart';
import 'package:the_local_shop/core/widgets/glass/glass.dart';
import 'package:the_local_shop/features/auth/presentation/providers/auth_provider.dart';
import 'package:the_local_shop/features/bill_builder/presentation/widgets/bill_builder_dialog.dart';
import 'package:the_local_shop/features/chat_order/presentation/screens/order_chat_screen.dart';
import 'package:the_local_shop/features/orders/domain/models/order.dart';
import 'package:the_local_shop/features/orders/presentation/providers/order_provider.dart';
import 'package:the_local_shop/features/shops/domain/models/shop.dart';

class ShopDashboardView extends ConsumerStatefulWidget {
  const ShopDashboardView({super.key});

  @override
  ConsumerState<ShopDashboardView> createState() => _ShopDashboardViewState();
}

class _ShopDashboardViewState extends ConsumerState<ShopDashboardView> {
  int _selectedFilterIdx = 0; // 0: All, 1: Pending, 2: Active, 3: Delivered

  void _openBillBuilder(CustomerOrder order) {
    GlassBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BillBuilderDialog(
        order: order,
        onBillSubmitted: (items, deliveryFee, packingFee) {
          ref.read(orderProvider.notifier).attachBill(
                orderId: order.id,
                items: items,
                deliveryFee: deliveryFee,
                packingFee: packingFee,
              );
          GlassSnackbar.show(
            context,
            message: 'Itemized bill sent to ${order.customerName}!',
            variant: GlassSnackbarVariant.success,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final user = ref.watch(authProvider).user;
    final shopId = user?.shopId ?? 'e0000000-0000-0000-0000-000000000001';
    final Shop shop = orderState.shops.firstWhere(
      (s) => s.id == shopId,
      orElse: () => orderState.shops.first,
    );

    final List<CustomerOrder> shopOrders =
        orderState.orders.where((o) => o.shopId == shop.id).toList();

    final List<CustomerOrder> filteredOrders = shopOrders.where((o) {
      if (_selectedFilterIdx == 1) {
        return o.status == OrderStatus.placed || o.status == OrderStatus.accepted;
      }
      if (_selectedFilterIdx == 2) {
        return o.status == OrderStatus.billed ||
            o.status == OrderStatus.packing ||
            o.status == OrderStatus.outForDelivery;
      }
      if (_selectedFilterIdx == 3) {
        return o.status == OrderStatus.delivered;
      }
      return true;
    }).toList();

    final int deliveredCount =
        shopOrders.where((o) => o.status == OrderStatus.delivered).length;
    final double revenue = shopOrders
        .where((o) =>
            o.status == OrderStatus.delivered || o.paymentStatus == 'paid_online')
        .fold(0.0, (acc, o) => acc + o.grandTotal);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Shop Status & Holiday Mode Toggle Card
        GlassCard(
          useRealBlur: true,
          padding: const EdgeInsets.all(AppTokens.spacing16),
          borderColor: shop.isHoliday
              ? AppTokens.danger.withOpacity(0.4)
              : AppTokens.primary(isDark).withOpacity(0.4),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: shop.isHoliday
                      ? AppTokens.danger.withOpacity(0.15)
                      : AppTokens.primary(isDark).withOpacity(0.18),
                  border: Border.all(
                    color: shop.isHoliday
                        ? AppTokens.danger.withOpacity(0.4)
                        : AppTokens.primary(isDark).withOpacity(0.5),
                  ),
                ),
                child: Icon(
                  shop.isHoliday
                      ? Icons.beach_access_rounded
                      : Icons.storefront_rounded,
                  color: shop.isHoliday ? AppTokens.danger : AppTokens.primary(isDark),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTokens.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: shop.isHoliday
                                ? AppTokens.danger
                                : AppTokens.primary(isDark),
                            boxShadow: [
                              BoxShadow(
                                color: shop.isHoliday
                                    ? AppTokens.danger.withOpacity(0.6)
                                    : AppTokens.primary(isDark).withOpacity(0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          shop.isHoliday ? 'Shop on Holiday' : 'Store is Open',
                          style: AppTokens.headingSmall.copyWith(
                            color: shop.isHoliday
                                ? AppTokens.danger
                                : (isDark
                                    ? AppTokens.textPrimaryDark
                                    : AppTokens.textPrimaryLight),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shop.isHoliday
                          ? 'Residents cannot place new orders'
                          : 'Orders live: 7 AM, 6 PM & Instant',
                      style: AppTokens.bodySmall.copyWith(
                        color: isDark
                            ? AppTokens.textSecondaryDark
                            : AppTokens.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: !shop.isHoliday,
                activeColor: AppTokens.primary(isDark),
                onChanged: (val) {
                  ref.read(orderProvider.notifier).toggleHoliday(shop.id, !val);
                  GlassSnackbar.show(
                    context,
                    message: val
                        ? 'Store is now ONLINE'
                        : 'Holiday mode ENABLED (Store Closed)',
                    variant: val
                        ? GlassSnackbarVariant.success
                        : GlassSnackbarVariant.info,
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTokens.spacing16),

        // Live Count-up Metrics Row
        Row(
          children: [
            Expanded(
              child: _CountUpMetricCard(
                title: "Today's Orders",
                targetValue: shopOrders.length.toDouble(),
                isCurrency: false,
                icon: Icons.shopping_bag_outlined,
                color: AppTokens.primary(isDark),
              ),
            ),
            const SizedBox(width: AppTokens.spacing8),
            Expanded(
              child: _CountUpMetricCard(
                title: 'Delivered',
                targetValue: deliveredCount.toDouble(),
                isCurrency: false,
                icon: Icons.check_circle_outline_rounded,
                color: AppTokens.info,
              ),
            ),
            const SizedBox(width: AppTokens.spacing8),
            Expanded(
              child: _CountUpMetricCard(
                title: 'Revenue',
                targetValue: revenue,
                isCurrency: true,
                icon: Icons.currency_rupee_rounded,
                color: AppTokens.accentWarm,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTokens.spacing16),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill(0, 'All (${shopOrders.length})', isDark),
              const SizedBox(width: 8),
              _buildFilterPill(1, 'Needs Action', isDark),
              const SizedBox(width: 8),
              _buildFilterPill(2, 'In Progress', isDark),
              const SizedBox(width: 8),
              _buildFilterPill(3, 'Completed', isDark),
            ],
          ),
        ),

        const SizedBox(height: AppTokens.spacing16),

        // Orders List
        if (filteredOrders.isEmpty)
          GlassCard(
            useRealBlur: false,
            padding: const EdgeInsets.symmetric(
              vertical: AppTokens.spacing32,
              horizontal: AppTokens.spacing24,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: isDark
                        ? AppTokens.textSecondaryDark
                        : AppTokens.textSecondaryLight,
                  ),
                  const SizedBox(height: AppTokens.spacing12),
                  Text(
                    'No orders in this filter',
                    style: AppTokens.headingSmall.copyWith(
                      color: isDark
                          ? AppTokens.textPrimaryDark
                          : AppTokens.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Incoming orders from residents will appear here automatically.',
                    textAlign: TextAlign.center,
                    style: AppTokens.bodySmall.copyWith(
                      color: isDark
                          ? AppTokens.textSecondaryDark
                          : AppTokens.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredOrders.map((order) {
            return Dismissible(
              key: Key('order_${order.id}'),
              direction: DismissDirection.none, // Preserve tap actions
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.spacing12),
                child: GlassCard(
                  useRealBlur: false,
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Order ID + Status Chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Order #${order.id}',
                                style: AppTokens.headingSmall.copyWith(
                                  fontSize: 16,
                                  color: isDark
                                      ? AppTokens.textPrimaryDark
                                      : AppTokens.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTokens.accentWarm.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  order.slot.title.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTokens.accentWarm,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildStatusBadge(order.status, isDark),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spacing12),

                      // Customer Details Box (Fake Glass)
                      Container(
                        padding: const EdgeInsets.all(AppTokens.spacing12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.03),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusButton),
                          border: Border.all(
                            color: isDark
                                ? AppTokens.glassBorderDark.withOpacity(0.5)
                                : AppTokens.glassBorderLight.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: AppTokens.primary(isDark),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  order.customerName,
                                  style: AppTokens.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppTokens.textPrimaryDark
                                        : AppTokens.textPrimaryLight,
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () {
                                    GlassSnackbar.show(
                                      context,
                                      message:
                                          'Calling ${order.customerName} at ${order.customerPhone}',
                                      variant: GlassSnackbarVariant.info,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.phone_rounded,
                                          size: 14,
                                          color: AppTokens.primary(isDark),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          order.customerPhone,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTokens.primary(isDark),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: isDark
                                      ? AppTokens.textSecondaryDark
                                      : AppTokens.textSecondaryLight,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    order.customerAddress,
                                    style: AppTokens.bodySmall.copyWith(
                                      color: isDark
                                          ? AppTokens.textSecondaryDark
                                          : AppTokens.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (order.notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    size: 14,
                                    color: AppTokens.accentWarm,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Note: "${order.notes}"',
                                      style: AppTokens.bodySmall.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: isDark
                                            ? AppTokens.textPrimaryDark
                                            : AppTokens.textPrimaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTokens.spacing12),

                      // Billed Items / Grand Total Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.items.isEmpty
                                ? 'No bill attached yet'
                                : '${order.items.length} items billed',
                            style: AppTokens.bodySmall.copyWith(
                              color: isDark
                                  ? AppTokens.textSecondaryDark
                                  : AppTokens.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '₹${order.grandTotal.toInt()}',
                                style: AppTokens.headingSmall.copyWith(
                                  fontSize: 16,
                                  color: AppTokens.primary(isDark),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (order.paymentStatus == 'paid_online'
                                          ? AppTokens.primary(isDark)
                                          : AppTokens.accentWarm)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order.paymentStatus == 'paid_online'
                                      ? 'PAID'
                                      : (order.paymentStatus == 'cod'
                                          ? 'COD'
                                          : 'PENDING'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: order.paymentStatus == 'paid_online'
                                        ? AppTokens.primary(isDark)
                                        : AppTokens.accentWarm,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTokens.spacing12),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GlassButton(
                              text: 'Open Chat',
                              icon: Icons.chat_bubble_outline_rounded,
                              variant: GlassButtonVariant.outline,
                              height: 42,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OrderChatScreen(orderId: order.id),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: AppTokens.spacing8),
                          if (order.status == OrderStatus.placed ||
                              order.status == OrderStatus.accepted) ...[
                            Expanded(
                              child: GlassButton(
                                text: 'Build Bill',
                                icon: Icons.receipt_long_rounded,
                                variant: GlassButtonVariant.filled,
                                height: 42,
                                onPressed: () => _openBillBuilder(order),
                              ),
                            ),
                          ] else if (order.status == OrderStatus.billed) ...[
                            Expanded(
                              child: GlassButton(
                                text: 'Awaiting Confirm',
                                icon: Icons.hourglass_top_rounded,
                                variant: GlassButtonVariant.outline,
                                height: 42,
                                onPressed: () {
                                  GlassSnackbar.show(
                                    context,
                                    message:
                                        'Waiting for resident confirmation and payment mode.',
                                    variant: GlassSnackbarVariant.info,
                                  );
                                },
                              ),
                            ),
                          ] else if (order.status == OrderStatus.packing) ...[
                            Expanded(
                              child: GlassButton(
                                text: 'Dispatch',
                                icon: Icons.delivery_dining_rounded,
                                variant: GlassButtonVariant.filled,
                                height: 42,
                                onPressed: () {
                                  ref
                                      .read(orderProvider.notifier)
                                      .updateOrderStatus(
                                        order.id,
                                        OrderStatus.outForDelivery,
                                      );
                                  GlassSnackbar.show(
                                    context,
                                    message:
                                        'Order #${order.id} is out for delivery! 🛵',
                                    variant: GlassSnackbarVariant.success,
                                  );
                                },
                              ),
                            ),
                          ] else if (order.status ==
                              OrderStatus.outForDelivery) ...[
                            Expanded(
                              child: GlassButton(
                                text: 'Mark Delivered',
                                icon: Icons.done_all_rounded,
                                variant: GlassButtonVariant.filled,
                                height: 42,
                                onPressed: () {
                                  ref
                                      .read(orderProvider.notifier)
                                      .updateOrderStatus(
                                        order.id,
                                        OrderStatus.delivered,
                                      );
                                  GlassSnackbar.show(
                                    context,
                                    message:
                                        'Order #${order.id} delivered! 🏡✨',
                                    variant: GlassSnackbarVariant.success,
                                  );
                                },
                              ),
                            ),
                          ] else if (order.status == OrderStatus.delivered) ...[
                            Expanded(
                              child: Container(
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTokens.primary(isDark).withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.radiusButton),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: AppTokens.primary(isDark),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Order Complete',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppTokens.primary(isDark),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatusBadge(OrderStatus status, bool isDark) {
    Color badgeColor;
    switch (status) {
      case OrderStatus.placed:
        badgeColor = AppTokens.accentWarm;
        break;
      case OrderStatus.accepted:
      case OrderStatus.billed:
        badgeColor = AppTokens.info;
        break;
      case OrderStatus.packing:
      case OrderStatus.outForDelivery:
        badgeColor = const Color(0xFF8B5CF6);
        break;
      case OrderStatus.delivered:
        badgeColor = AppTokens.primary(isDark);
        break;
      case OrderStatus.cancelled:
        badgeColor = AppTokens.danger;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFilterPill(int idx, String label, bool isDark) {
    final isSelected = _selectedFilterIdx == idx;
    return InkWell(
      onTap: () => setState(() => _selectedFilterIdx = idx),
      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      child: AnimatedContainer(
        duration: AppTokens.durationMicro,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTokens.primary(isDark)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
          border: Border.all(
            color: isSelected
                ? AppTokens.primary(isDark)
                : (isDark
                    ? AppTokens.glassBorderDark
                    : AppTokens.glassBorderLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? const Color(0xFF0A0F1C) : Colors.white)
                : (isDark
                    ? AppTokens.textSecondaryDark
                    : AppTokens.textSecondaryLight),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CountUpMetricCard extends StatelessWidget {
  final String title;
  final double targetValue;
  final bool isCurrency;
  final IconData icon;
  final Color color;

  const _CountUpMetricCard({
    required this.title,
    required this.targetValue,
    required this.isCurrency,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      useRealBlur: false,
      padding: const EdgeInsets.symmetric(
        vertical: AppTokens.spacing12,
        horizontal: AppTokens.spacing8,
      ),
      borderColor: color.withOpacity(0.25),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: targetValue),
            duration: AppTokens.durationLarge,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final formatted = isCurrency
                  ? '₹${value.toInt()}'
                  : value.toInt().toString();
              return Text(
                formatted,
                style: AppTokens.headingSmall.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppTokens.textPrimaryDark
                      : AppTokens.textPrimaryLight,
                ),
              );
            },
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
