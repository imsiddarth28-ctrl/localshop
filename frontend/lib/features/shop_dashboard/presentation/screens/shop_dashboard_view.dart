import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_local_shop/core/theme/app_colors.dart';
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
    showModalBottomSheet(
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Itemized Bill sent to customer!'),
              backgroundColor: AppColors.success,
            ),
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
    final Shop shop = orderState.shops.firstWhere((s) => s.id == shopId, orElse: () => orderState.shops.first);

    // Filter shop orders
    final List<CustomerOrder> shopOrders = orderState.orders.where((o) => o.shopId == shop.id).toList();

    final List<CustomerOrder> filteredOrders = shopOrders.where((o) {
      if (_selectedFilterIdx == 1) return o.status == OrderStatus.placed || o.status == OrderStatus.accepted;
      if (_selectedFilterIdx == 2) return o.status == OrderStatus.billed || o.status == OrderStatus.packing || o.status == OrderStatus.outForDelivery;
      if (_selectedFilterIdx == 3) return o.status == OrderStatus.delivered;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Shop Status & Holiday Mode Toggle Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: shop.isHoliday ? AppColors.error.withOpacity(0.5) : AppColors.success.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: shop.isHoliday ? Colors.red.shade100 : Colors.green.shade100,
                child: Icon(
                  shop.isHoliday ? Icons.beach_access_rounded : Icons.storefront_rounded,
                  color: shop.isHoliday ? AppColors.error : AppColors.success,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.isHoliday ? 'Shop is on Holiday' : 'Shop is Accepting Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: shop.isHoliday ? AppColors.error : AppColors.success,
                      ),
                    ),
                    Text(
                      shop.isHoliday ? 'Residents cannot place new orders' : 'Deliveries active: 7AM, 6PM & Instant (within 1 km)',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Switch(
                value: !shop.isHoliday,
                activeColor: AppColors.success,
                onChanged: (val) {
                  ref.read(orderProvider.notifier).toggleHoliday(shop.id, !val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? 'Store is now ONLINE' : 'Holiday Mode ENABLED (Store Closed)'),
                      backgroundColor: val ? AppColors.success : AppColors.secondary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Live Performance Metrics
        Row(
          children: [
            Expanded(
              child: _buildMetricCard('Today Orders', '${shopOrders.length}', Icons.shopping_bag_outlined, AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Delivered',
                '${shopOrders.where((o) => o.status == OrderStatus.delivered).length}',
                Icons.check_circle_outline,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Revenue',
                '₹${shopOrders.where((o) => o.status == OrderStatus.delivered || o.paymentStatus == 'paid_online').fold(0.0, (acc, o) => acc + o.grandTotal).toInt()}',
                Icons.currency_rupee,
                AppColors.secondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(0, 'All Orders (${shopOrders.length})'),
              const SizedBox(width: 8),
              _buildFilterChip(1, 'New / Needs Action'),
              const SizedBox(width: 8),
              _buildFilterChip(2, 'In Progress / Packing'),
              const SizedBox(width: 8),
              _buildFilterChip(3, 'Completed'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Orders List with Complete Details
        if (filteredOrders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 48, color: Colors.black26),
                  SizedBox(height: 10),
                  Text('No customer orders in this view yet.', style: TextStyle(color: Colors.black54, fontSize: 15)),
                ],
              ),
            ),
          )
        else
          ...filteredOrders.map((order) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Header with Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.status.label.toUpperCase(),
                          style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Customer Details (Full visibility for shopkeeper)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.phone, size: 18, color: AppColors.primary),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Calling customer ${order.customerName} at ${order.customerPhone}...')),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            Text(order.customerPhone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Address: ${order.customerAddress}',
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              'Slot: ${order.slot.title}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                          ],
                        ),
                        if (order.notes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note_rounded, size: 16, color: Colors.black54),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text('Note: "${order.notes}"', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Items & Bill Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.items.isEmpty ? 'Pending Itemized Bill' : '${order.items.length} items billed',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                      ),
                      Text(
                        'Total: ₹${order.grandTotal.toInt()} (${order.paymentStatus == 'paid_online' ? 'PAID ONLINE' : (order.paymentStatus == 'cod' ? 'CASH ON DELIVERY' : 'PENDING')})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Shopkeeper Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Open Chat'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.black87),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OrderChatScreen(orderId: order.id)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (order.status == OrderStatus.placed) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.receipt_long, size: 16, color: Colors.white),
                            label: const Text('Build Bill', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                            onPressed: () => _openBillBuilder(order),
                          ),
                        ),
                      ] else if (order.status == OrderStatus.accepted) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.receipt_long, size: 16, color: Colors.white),
                            label: const Text('Build Bill', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                            onPressed: () => _openBillBuilder(order),
                          ),
                        ),
                      ] else if (order.status == OrderStatus.billed) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.white),
                            label: const Text('Awaiting Confirm', style: TextStyle(color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bill sent! Waiting for customer to confirm and choose payment.')),
                              );
                            },
                          ),
                        ),
                      ] else if (order.status == OrderStatus.packing) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delivery_dining, size: 18, color: Colors.white),
                            label: const Text('Dispatch', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                            onPressed: () {
                              ref.read(orderProvider.notifier).updateOrderStatus(order.id, OrderStatus.outForDelivery);
                            },
                          ),
                        ),
                      ] else if (order.status == OrderStatus.outForDelivery) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.done_all, size: 16, color: Colors.white),
                            label: const Text('Delivered', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                            onPressed: () {
                              ref.read(orderProvider.notifier).updateOrderStatus(order.id, OrderStatus.delivered);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int idx, String label) {
    final isSelected = _selectedFilterIdx == idx;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.secondary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedFilterIdx = idx),
    );
  }
}
