import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_local_shop/core/theme/app_colors.dart';
import 'package:the_local_shop/core/utils/validators.dart';
import 'package:the_local_shop/core/widgets/elder_friendly_button.dart';
import 'package:the_local_shop/features/auth/presentation/providers/auth_provider.dart';
import 'package:the_local_shop/features/chat_order/presentation/screens/order_chat_screen.dart';
import 'package:the_local_shop/features/orders/domain/models/order.dart';
import 'package:the_local_shop/features/orders/presentation/providers/order_provider.dart';
import 'package:the_local_shop/features/shops/domain/models/shop.dart';

class CustomerShopListView extends ConsumerStatefulWidget {
  const CustomerShopListView({super.key});

  @override
  ConsumerState<CustomerShopListView> createState() => _CustomerShopListViewState();
}

class _CustomerShopListViewState extends ConsumerState<CustomerShopListView> {
  String _selectedCategory = 'All';

  void _showNewOrderDialog(BuildContext context, WidgetRef ref, Shop shop) {
    DeliverySlotType selectedSlot = DeliverySlotType.morning;
    final initialNoteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryContainer,
                    child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '📍 ${shop.distanceKm} km away • ${shop.address}',
                          style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('1. Choose Delivery Slot:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),

              // Slot 1: Morning
              RadioListTile<DeliverySlotType>(
                contentPadding: EdgeInsets.zero,
                value: DeliverySlotType.morning,
                groupValue: selectedSlot,
                activeColor: AppColors.primary,
                title: Text('Morning Batch (₹${shop.deliveryFeeMorning.toInt()} fee)', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Delivered 7:00 AM • Order before 6:30 AM'),
                onChanged: (val) => setModalState(() => selectedSlot = val!),
              ),

              // Slot 2: Evening
              RadioListTile<DeliverySlotType>(
                contentPadding: EdgeInsets.zero,
                value: DeliverySlotType.evening,
                groupValue: selectedSlot,
                activeColor: AppColors.primary,
                title: Text('Evening Batch (₹${shop.deliveryFeeEvening.toInt()} fee)', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Delivered 6:00 PM • Order before 5:30 PM'),
                onChanged: (val) => setModalState(() => selectedSlot = val!),
              ),

              // Slot 3: Instant
              RadioListTile<DeliverySlotType>(
                contentPadding: EdgeInsets.zero,
                value: DeliverySlotType.instant,
                groupValue: selectedSlot,
                activeColor: AppColors.secondary,
                title: Text('Instant Delivery (₹${shop.deliveryFeeInstant.toInt()} fee)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                subtitle: const Text('Urgent orders delivered within 30 mins'),
                onChanged: (val) => setModalState(() => selectedSlot = val!),
              ),

              const SizedBox(height: 14),
              const Text('2. What do you need? (Type list or send in chat):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: initialNoteController,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'e.g. 2 packets milk, 1kg sugar, tata salt...',
                  filled: true,
                  fillColor: AppColors.cardLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 16),
              ElderFriendlyButton(
                text: 'Message Shopkeeper & Order',
                icon: Icons.chat_bubble_rounded,
                onPressed: () {
                  final user = ref.read(authProvider).user!;
                  final sanitizedNote = AppValidators.sanitizeText(initialNoteController.text);
                  final order = ref.read(orderProvider.notifier).createOrder(
                        shopId: shop.id,
                        customerId: user.id,
                        customerName: user.name,
                        customerPhone: user.phone,
                        customerAddress: user.address ?? 'Colony Resident',
                        slot: selectedSlot,
                        initialMessage: sanitizedNote.isEmpty
                            ? 'Namaste, I want to place an order.'
                            : sanitizedNote,
                      );
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderChatScreen(orderId: order.id)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderProgressIndicator(OrderStatus status) {
    int currentStep = 0;
    if (status == OrderStatus.placed) currentStep = 1;
    if (status == OrderStatus.accepted || status == OrderStatus.billed) currentStep = 2;
    if (status == OrderStatus.packing) currentStep = 3;
    if (status == OrderStatus.outForDelivery) currentStep = 4;
    if (status == OrderStatus.delivered) currentStep = 5;

    final steps = [
      {'label': 'Placed', 'icon': Icons.send_rounded},
      {'label': 'Billed', 'icon': Icons.receipt_long_rounded},
      {'label': 'Packing', 'icon': Icons.inventory_2_rounded},
      {'label': 'On Way', 'icon': Icons.delivery_dining_rounded},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final stepNum = index + 1;
          final isCompleted = currentStep > stepNum;
          final isCurrent = currentStep == stepNum;

          Color stepColor = Colors.grey.shade400;
          if (isCompleted) stepColor = AppColors.success;
          if (isCurrent) stepColor = AppColors.primary;

          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: isCurrent ? AppColors.primary : (isCompleted ? AppColors.success : Colors.grey.shade300),
                      child: Icon(
                        isCompleted ? Icons.check : (steps[index]['icon'] as IconData),
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      steps[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: stepColor,
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? AppColors.success : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final user = ref.watch(authProvider).user;

    // Strict Locality & 1km filter: customer sees ONLY shops within 1 km and in their locality
    final String userColonyId = user?.colonyId ?? 'c0000000-0000-0000-0000-000000000001';
    List<Shop> colonyShops = orderState.shops
        .where((s) => s.colonyId == userColonyId && s.distanceKm <= 1.0)
        .toList();

    // Category filter
    if (_selectedCategory != 'All') {
      colonyShops = colonyShops.where((s) => s.category.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
    }

    // Filter customer active orders
    final List<CustomerOrder> activeOrders = orderState.orders
        .where((o) => o.customerId == user?.id && o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active Orders Tracker Banner
        if (activeOrders.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Active Orders',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${activeOrders.length} IN PROGRESS',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...activeOrders.map((CustomerOrder order) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          order.shopName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          order.status.label.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${order.slot.title} • ₹${order.grandTotal.toInt()} (${order.paymentStatus == 'paid_online' ? 'Paid' : (order.paymentStatus == 'cod' ? 'Cash on Delivery' : 'Awaiting Bill Confirmation')})',
                    style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                  ),

                  // Order Progress Tracker
                  _buildOrderProgressIndicator(order.status),

                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
                          label: const Text('Open Order Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OrderChatScreen(orderId: order.id)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Locality & 1km Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryContainer.withValues(alpha: 0.6),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shops within 1 km',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                        ),
                        Text(
                          user?.colonyName ?? "Your Verified Colony",
                          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 13),
                        SizedBox(width: 4),
                        Text('VERIFIED', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Direct chat with neighborhood shopkeepers. No catalog browsing needed!',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Quick Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('All', Icons.storefront_rounded),
              const SizedBox(width: 8),
              _buildCategoryChip('Grocery', Icons.shopping_basket_outlined),
              const SizedBox(width: 8),
              _buildCategoryChip('Dairy', Icons.egg_alt_outlined),
              const SizedBox(width: 8),
              _buildCategoryChip('Vegetables', Icons.eco_outlined),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (colonyShops.isEmpty)
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.store_mall_directory_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No shops found in this category within 1 km.',
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ],
              ),
            ),
          )
        else
          ...colonyShops.map((Shop shop) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: shop.isOpen ? AppColors.primaryContainer : Colors.grey.shade200,
                      child: Icon(
                        Icons.storefront_rounded,
                        color: shop.isOpen ? AppColors.primary : Colors.grey,
                        size: 30,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            shop.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: shop.isOpen ? AppColors.success.withValues(alpha: 0.15) : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            shop.isOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              color: shop.isOpen ? AppColors.success : AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '📍 ${shop.distanceKm} km away',
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(shop.category, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text('${shop.rating} (${shop.reviewCount})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time_rounded, size: 15, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(shop.hours, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delivery Slots Pill Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.4),
                          avatar: const Icon(Icons.wb_sunny_outlined, size: 14, color: AppColors.primary),
                          label: Text('Morning 7AM (₹${shop.deliveryFeeMorning.toInt()})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        Chip(
                          backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.4),
                          avatar: const Icon(Icons.nightlight_outlined, size: 14, color: AppColors.primary),
                          label: Text('Evening 6PM (₹${shop.deliveryFeeEvening.toInt()})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        Chip(
                          backgroundColor: AppColors.secondaryContainer.withValues(alpha: 0.4),
                          avatar: const Icon(Icons.bolt, size: 14, color: AppColors.secondary),
                          label: Text('Instant 30m (₹${shop.deliveryFeeInstant.toInt()})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1),

                  // Action Buttons: Call & Order via Chat
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.call_outlined, size: 18),
                          label: const Text('Call Shop'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${shop.ownerName} at ${shop.phone}...')),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
                            label: const Text('Message & Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                            ),
                            onPressed: () => _showNewOrderDialog(context, ref, shop),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300)),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedCategory = label);
        }
      },
    );
  }
}
