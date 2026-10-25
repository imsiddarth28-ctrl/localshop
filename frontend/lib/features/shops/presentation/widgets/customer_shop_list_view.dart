import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_local_shop/core/theme/app_tokens.dart';
import 'package:the_local_shop/core/utils/validators.dart';
import 'package:the_local_shop/core/widgets/glass/glass.dart';
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

  // --- New Order Glass Bottom Sheet ---
  void _showNewOrderDialog(BuildContext context, WidgetRef ref, Shop shop, {String defaultTab = 'text'}) {
    DeliverySlotType selectedSlot = DeliverySlotType.instant;
    final initialNoteController = TextEditingController();

    GlassBottomSheet.show(
      context: context,
      child: StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final primary = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;
          final accent = isDark ? AppTokens.accentDark : AppTokens.accentLight;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Header Info
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withOpacity(0.2),
                      border: Border.all(color: primary.withOpacity(0.5)),
                    ),
                    child: Icon(Icons.storefront_rounded, color: primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: AppTokens.headingSmall(isDark).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '📍 ${shop.distanceKm} km away • ${shop.category}',
                          style: AppTokens.bodySmall(isDark).copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Choose Delivery Slot
              Text(
                '1. Select Delivery Timing',
                style: AppTokens.label(isDark).copyWith(fontSize: 14),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GlassChip(
                      label: 'Instant Delivery',
                      subtitle: '+₹${shop.deliveryFeeInstant.toInt()} • within 30m',
                      icon: Icons.bolt_rounded,
                      activeColor: accent,
                      isSelected: selectedSlot == DeliverySlotType.instant,
                      onTap: () => setModalState(() => selectedSlot = DeliverySlotType.instant),
                    ),
                    const SizedBox(width: 8),
                    GlassChip(
                      label: '7:00 AM Slot',
                      subtitle: '+₹${shop.deliveryFeeMorning.toInt()} • Morning batch',
                      icon: Icons.wb_sunny_outlined,
                      isSelected: selectedSlot == DeliverySlotType.morning,
                      onTap: () => setModalState(() => selectedSlot = DeliverySlotType.morning),
                    ),
                    const SizedBox(width: 8),
                    GlassChip(
                      label: '6:00 PM Slot',
                      subtitle: '+₹${shop.deliveryFeeEvening.toInt()} • Evening batch',
                      icon: Icons.nights_stay_outlined,
                      isSelected: selectedSlot == DeliverySlotType.evening,
                      onTap: () => setModalState(() => selectedSlot = DeliverySlotType.evening),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Initial Needs Note
              Text(
                '2. What items do you need?',
                style: AppTokens.label(isDark).copyWith(fontSize: 14),
              ),
              const SizedBox(height: 8),
              GlassTextField(
                controller: initialNoteController,
                label: 'Grocery List or Request',
                hint: 'e.g. 2L Milk, 1kg Sugar, Bread packet...',
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Start Chat / Order Button
              GlassButton(
                text: 'Send to Shopkeeper & Open Chat',
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
                            ? 'Namaste, I would like to place an order.'
                            : sanitizedNote,
                      );

                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderChatScreen(orderId: order.id)),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  // --- Order Progress Stepper ---
  Widget _buildOrderProgressIndicator(OrderStatus status, bool isDark) {
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
      {'label': 'Out for Delivery', 'icon': Icons.delivery_dining_rounded},
    ];

    final primary = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x1AFFFFFF) : const Color(0x330F172A),
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final stepNum = index + 1;
          final isCompleted = currentStep > stepNum;
          final isCurrent = currentStep == stepNum;

          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? primary
                            : (isCompleted
                                ? primary.withOpacity(0.8)
                                : (isDark ? Colors.white12 : Colors.black12)),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : (steps[index]['icon'] as IconData),
                        size: 14,
                        color: isCurrent || isCompleted ? const Color(0xFF0A0F1C) : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index]['label'] as String,
                      style: AppTokens.bodySmall(isDark).copyWith(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent ? primary : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      color: isCompleted ? primary : (isDark ? Colors.white12 : Colors.black12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;
    final accent = isDark ? AppTokens.accentDark : AppTokens.accentLight;

    final String userColonyId = user?.colonyId ?? 'c0000000-0000-0000-0000-000000000001';
    List<Shop> colonyShops = orderState.shops
        .where((s) => s.colonyId == userColonyId && s.distanceKm <= 1.0)
        .toList();

    if (_selectedCategory != 'All') {
      colonyShops = colonyShops.where((s) => s.category.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
    }

    final List<CustomerOrder> activeOrders = orderState.orders
        .where((o) => o.customerId == user?.id && o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Active Orders Card
        if (activeOrders.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Active Orders',
                    style: AppTokens.headingSmall(isDark).copyWith(fontSize: 17),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                  border: Border.all(color: primary.withOpacity(0.5)),
                ),
                child: Text(
                  '${activeOrders.length} IN TRANSIT',
                  style: AppTokens.bodySmall(isDark).copyWith(color: primary, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...activeOrders.map((CustomerOrder order) {
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(AppTokens.space16),
              accentBorderColor: primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order.shopName, style: AppTokens.label(isDark).copyWith(fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.status.label.toUpperCase(),
                          style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.slot.title} • Total: ₹${order.grandTotal.toInt()}',
                    style: AppTokens.bodySmall(isDark).copyWith(fontWeight: FontWeight.w600),
                  ),
                  _buildOrderProgressIndicator(order.status, isDark),
                  const SizedBox(height: 6),
                  GlassButton(
                    text: 'Open Order Chat',
                    icon: Icons.chat_bubble_rounded,
                    height: 44,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderChatScreen(orderId: order.id)),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),
        ],

        // 2. Quick Action Glass Row (Order via Text / Voice / Photo)
        Text('Quick Order Assistant', style: AppTokens.label(isDark).copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.edit_note_rounded,
                label: 'Text List',
                color: primary,
                isDark: isDark,
                onTap: () {
                  if (colonyShops.isNotEmpty) {
                    _showNewOrderDialog(context, ref, colonyShops.first, defaultTab: 'text');
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.mic_rounded,
                label: 'Voice Note',
                color: accent,
                isDark: isDark,
                onTap: () {
                  if (colonyShops.isNotEmpty) {
                    _showNewOrderDialog(context, ref, colonyShops.first, defaultTab: 'voice');
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.camera_alt_rounded,
                label: 'Photo List',
                color: AppTokens.infoDark,
                isDark: isDark,
                onTap: () {
                  if (colonyShops.isNotEmpty) {
                    _showNewOrderDialog(context, ref, colonyShops.first, defaultTab: 'photo');
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 3. Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GlassChip(
                label: 'All Shops',
                icon: Icons.storefront_rounded,
                isSelected: _selectedCategory == 'All',
                onTap: () => setState(() => _selectedCategory = 'All'),
              ),
              const SizedBox(width: 8),
              GlassChip(
                label: 'Kirana',
                icon: Icons.shopping_basket_outlined,
                isSelected: _selectedCategory == 'Kirana',
                onTap: () => setState(() => _selectedCategory = 'Kirana'),
              ),
              const SizedBox(width: 8),
              GlassChip(
                label: 'Dairy',
                icon: Icons.egg_alt_outlined,
                isSelected: _selectedCategory == 'Dairy',
                onTap: () => setState(() => _selectedCategory = 'Dairy'),
              ),
              const SizedBox(width: 8),
              GlassChip(
                label: 'Vegetables',
                icon: Icons.eco_outlined,
                isSelected: _selectedCategory == 'Vegetables',
                onTap: () => setState(() => _selectedCategory = 'Vegetables'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Colony Shops List
        if (colonyShops.isEmpty) ...[
          GlassCard(
            padding: const EdgeInsets.all(AppTokens.space32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.store_mall_directory_outlined, size: 48, color: isDark ? Colors.white38 : Colors.black38),
                  const SizedBox(height: 10),
                  Text('No colony shops found in this category.', style: AppTokens.bodyMedium(isDark)),
                ],
              ),
            ),
          ),
        ] else ...[
          ...colonyShops.map((Shop shop) {
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(AppTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: shop.isOpen
                              ? primary.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          border: Border.all(
                            color: shop.isOpen ? primary : Colors.grey,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: shop.isOpen ? primary : Colors.grey,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    shop.name,
                                    style: AppTokens.headingSmall(isDark).copyWith(fontSize: 17),
                                  ),
                                ),
                                // Open/Closed Glowing Status Dot
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                                    color: (shop.isOpen ? AppTokens.primaryDark : AppTokens.dangerDark).withOpacity(0.18),
                                    border: Border.all(
                                      color: (shop.isOpen ? AppTokens.primaryDark : AppTokens.dangerDark).withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: shop.isOpen ? AppTokens.primaryDark : AppTokens.dangerDark,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (shop.isOpen ? AppTokens.primaryDark : AppTokens.dangerDark).withOpacity(0.6),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        shop.isOpen ? 'OPEN' : 'CLOSED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: shop.isOpen ? AppTokens.primaryDark : AppTokens.dangerDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '📍 ${shop.distanceKm} km away • ${shop.category}',
                              style: AppTokens.bodySmall(isDark).copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Operating hours & rating
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 17),
                      const SizedBox(width: 4),
                      Text(
                        '${shop.rating} (${shop.reviewCount})',
                        style: AppTokens.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.access_time_rounded, size: 15, color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(
                        shop.hours,
                        style: AppTokens.bodySmall(isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Delivery Slot Pills preview
                  Row(
                    children: [
                      _buildSlotBadge('Instant +₹10', Icons.bolt_rounded, isDark),
                      const SizedBox(width: 6),
                      _buildSlotBadge('7 AM +₹5', Icons.wb_sunny_outlined, isDark),
                      const SizedBox(width: 6),
                      _buildSlotBadge('6 PM +₹5', Icons.nights_stay_outlined, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Start Order Button
                  GlassButton(
                    text: 'Start Shopping / Chat Order',
                    icon: Icons.chat_bubble_outline_rounded,
                    height: 48,
                    onPressed: () => _showNewOrderDialog(context, ref, shop),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTokens.label(isDark).copyWith(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotBadge(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        color: isDark ? const Color(0x1AFFFFFF) : const Color(0x330F172A),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTokens.bodySmall(isDark).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
