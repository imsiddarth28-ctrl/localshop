import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_local_shop/core/theme/app_tokens.dart';
import 'package:the_local_shop/core/utils/validators.dart';
import 'package:the_local_shop/core/widgets/glass/glass.dart';
import 'package:the_local_shop/features/auth/domain/models/app_role.dart';
import 'package:the_local_shop/features/auth/presentation/providers/auth_provider.dart';
import 'package:the_local_shop/features/bill_builder/presentation/widgets/bill_builder_dialog.dart';
import 'package:the_local_shop/features/orders/domain/models/chat_message.dart';
import 'package:the_local_shop/features/orders/domain/models/order.dart';
import 'package:the_local_shop/features/orders/presentation/providers/order_provider.dart';

class OrderChatScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderChatScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends ConsumerState<OrderChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _selectedComposerTab = 0; // 0: Text, 1: Voice, 2: Photo
  bool _isRecordingVoice = false;
  late AnimationController _waveformController;
  bool _showTimeline = true;

  final List<String> _quickGroceryPills = [
    'Milk 1L',
    'Bread 1 pkt',
    'Sugar 1kg',
    'Atta 5kg',
    'Eggs 6pcs',
    'Sunflower Oil 1L',
    'Tata Salt 1kg',
  ];

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppTokens.durationMedium,
          curve: AppTokens.curveEnter,
        );
      }
    });
  }

  void _sendTextMessage() {
    final text = AppValidators.sanitizeText(_textController.text);
    if (text.isEmpty) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    ref.read(orderProvider.notifier).sendChatMessage(
          orderId: widget.orderId,
          senderId: user.id,
          senderName: user.name,
          senderRole: user.role == AppRole.shopOwner ? 'shop_owner' : 'customer',
          content: text,
        );

    _textController.clear();
    _scrollToBottom();
  }

  void _sendPhotoUpload() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    ref.read(orderProvider.notifier).sendChatMessage(
          orderId: widget.orderId,
          senderId: user.id,
          senderName: user.name,
          senderRole: user.role == AppRole.shopOwner ? 'shop_owner' : 'customer',
          type: MessageType.photo,
          content: 'Attached handwritten grocery list photo 📸',
          mediaUrl: 'https://images.unsplash.com/photo-1584445584400-0c487373fbe6?auto=format&fit=crop&w=400&q=80',
        );
    _scrollToBottom();
    GlassSnackbar.showSuccess(context, 'Grocery photo list attached!');
  }

  void _sendVoiceNote() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    ref.read(orderProvider.notifier).sendChatMessage(
          orderId: widget.orderId,
          senderId: user.id,
          senderName: user.name,
          senderRole: user.role == AppRole.shopOwner ? 'shop_owner' : 'customer',
          type: MessageType.voice,
          content: 'Voice note (0:14) 🎙️ "Please deliver fresh packets"',
          voiceDurationSeconds: 14,
        );
    _scrollToBottom();
    setState(() => _isRecordingVoice = false);
    GlassSnackbar.showSuccess(context, 'Voice note sent to shopkeeper!');
  }

  void _confirmAndPayOrder(CustomerOrder order) {
    GlassBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppTokens.primaryDark, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confirm Order with ${order.shopName}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Total Bill: ₹${order.grandTotal.toInt()} • ${order.slot.title}',
                        style: const TextStyle(fontSize: 13, color: AppTokens.accentDark, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Select Payment Option:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(AppTokens.space16),
            onTap: () {
              Navigator.pop(context);
              ref.read(orderProvider.notifier).payOrder(orderId: order.id, method: 'upi');
              GlassSnackbar.showSuccess(context, 'Order Confirmed via UPI! Shopkeeper is packing your items.');
            },
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: AppTokens.primaryDark, size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Confirm & Pay via UPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Instant transfer via GPay / PhonePe / Paytm', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(AppTokens.space16),
            onTap: () {
              Navigator.pop(context);
              ref.read(orderProvider.notifier).payOrder(orderId: order.id, method: 'cod');
              GlassSnackbar.showInfo(context, 'Order Confirmed with Cash on Delivery!');
            },
            child: Row(
              children: [
                const Icon(Icons.payments_rounded, color: AppTokens.accentDark, size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Pay cash to delivery boy when items reach your door', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

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
          GlassSnackbar.showSuccess(context, 'Itemized bill dispatched to customer!');
        },
      ),
    );
  }

  // --- Vertical Glass Timeline with Moving Scooter ---
  Widget _buildVerticalTimeline(CustomerOrder order, bool isDark) {
    int currentStep = 0;
    if (order.status == OrderStatus.placed) currentStep = 1;
    if (order.status == OrderStatus.accepted || order.status == OrderStatus.billed) currentStep = 2;
    if (order.status == OrderStatus.packing) currentStep = 3;
    if (order.status == OrderStatus.outForDelivery) currentStep = 4;
    if (order.status == OrderStatus.delivered) currentStep = 5;

    final steps = [
      {'title': 'Order Placed', 'desc': 'List received by shopkeeper', 'step': 1},
      {'title': 'Billed & Confirmed', 'desc': 'Shopkeeper finalized item prices', 'step': 2},
      {'title': 'Packing Groceries', 'desc': 'Items packed in eco bag', 'step': 3},
      {'title': 'Out for Delivery', 'desc': 'Delivery partner is on the way', 'step': 4},
      {'title': 'Delivered', 'desc': 'Reached your doorstep', 'step': 5},
    ];

    final primary = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;

    return GlassCard(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.route_rounded, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Delivery Timeline', style: AppTokens.label(isDark).copyWith(fontSize: 14)),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _showTimeline = !_showTimeline),
                child: Icon(
                  _showTimeline ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                ),
              ),
            ],
          ),
          if (_showTimeline) ...[
            const SizedBox(height: 12),
            ...List.generate(steps.length, (idx) {
              final s = steps[idx];
              final stepNum = s['step'] as int;
              final isDone = currentStep > stepNum;
              final isCurrent = currentStep == stepNum;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? (isDark ? AppTokens.accentDark : AppTokens.accentLight)
                              : (isDone ? primary : (isDark ? Colors.white12 : Colors.black12)),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: (isDark ? AppTokens.accentDark : AppTokens.accentLight).withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          isCurrent
                              ? Icons.delivery_dining_rounded // moving scooter marker!
                              : (isDone ? Icons.check_rounded : Icons.circle_outlined),
                          size: 13,
                          color: isCurrent || isDone ? const Color(0xFF0A0F1C) : Colors.grey,
                        ),
                      ),
                      if (idx < steps.length - 1)
                        Container(
                          width: 2,
                          height: 24,
                          color: isDone ? primary : (isDark ? Colors.white12 : Colors.black12),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['title'] as String,
                            style: AppTokens.label(isDark).copyWith(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                              color: isCurrent
                                  ? (isDark ? AppTokens.accentDark : AppTokens.accentLight)
                                  : (isDone ? (isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight) : Colors.grey),
                            ),
                          ),
                          Text(
                            s['desc'] as String,
                            style: AppTokens.bodySmall(isDark).copyWith(fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
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

    final orderList = orderState.orders.where((o) => o.id == widget.orderId).toList();
    if (orderList.isEmpty) {
      return GlassScaffold(
        body: Center(
          child: GlassCard(
            padding: const EdgeInsets.all(AppTokens.space24),
            child: const Text('Order details not found.'),
          ),
        ),
      );
    }

    final order = orderList.first;
    final messages = orderState.messagesByOrderId[order.id] ?? [];
    final isShopkeeper = user?.role == AppRole.shopOwner;

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isShopkeeper ? order.customerName : order.shopName,
              style: AppTokens.headingSmall(isDark).copyWith(fontSize: 16),
            ),
            Text(
              isShopkeeper
                  ? '📞 ${order.customerPhone} • 📍 ${order.customerAddress}'
                  : '📍 Colony Shop (Within 1 km) • ${order.slot.title}',
              style: AppTokens.bodySmall(isDark).copyWith(
                fontSize: 11,
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone_in_talk_rounded, color: primary, size: 20),
            tooltip: 'Call Phone',
            onPressed: () {
              GlassSnackbar.showInfo(context, 'Calling ${isShopkeeper ? order.customerPhone : order.shopPhone}...');
            },
          ),
          if (isShopkeeper)
            IconButton(
              icon: Icon(Icons.receipt_long_rounded, color: accent, size: 22),
              tooltip: 'Build & Send Itemized Bill',
              onPressed: () => _openBillBuilder(order),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Sticky Glass Order-Summary Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0x1F0A0F1C) : const Color(0x66FFFFFF)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: primary.withOpacity(0.2),
                    ),
                    child: Text(
                      order.status.label.toUpperCase(),
                      style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    'Bill: ₹${order.grandTotal.toInt()} • ${order.paymentStatus == 'paid_online' ? 'PAID' : (order.paymentStatus == 'cod' ? 'COD' : 'Awaiting Bill')}',
                    style: AppTokens.bodySmall(isDark).copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (isShopkeeper)
                    PopupMenuButton<OrderStatus>(
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      tooltip: 'Advance Status',
                      onSelected: (newStatus) {
                        ref.read(orderProvider.notifier).updateOrderStatus(order.id, newStatus);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: OrderStatus.accepted, child: Text('Accept Order')),
                        const PopupMenuItem(value: OrderStatus.packing, child: Text('Mark Packing')),
                        const PopupMenuItem(value: OrderStatus.outForDelivery, child: Text('Dispatch (Out for Delivery)')),
                        const PopupMenuItem(value: OrderStatus.delivered, child: Text('Mark Delivered')),
                      ],
                    ),
                ],
              ),
            ),

            // 2. Vertical Glass Timeline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: _buildVerticalTimeline(order, isDark),
            ),

            // 3. Messages Stream
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, idx) {
                  final msg = messages[idx];
                  return _buildMessageBubble(msg, order, isShopkeeper, isDark, primary, accent);
                },
              ),
            ),

            // 4. Quick Item Suggestion Pills
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickGroceryPills.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final pill = _quickGroceryPills[i];
                  return ActionChip(
                    backgroundColor: isDark ? AppTokens.glassFillDark : AppTokens.glassFillLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                      side: BorderSide(color: isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight),
                    ),
                    label: Text(pill, style: AppTokens.bodySmall(isDark).copyWith(fontSize: 11)),
                    onPressed: () {
                      final current = _textController.text;
                      _textController.text = current.isEmpty ? pill : '$current, $pill';
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // 5. Order Composer Box (Text, Voice Waveform, Photo Preview)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x2E0A0F1C) : const Color(0xE6FFFFFF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCard)),
                border: Border(
                  top: BorderSide(color: isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Three Glass Tabs (Text | Voice | Photo)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildComposerTab(0, Icons.edit_note_rounded, 'Text List', isDark, primary),
                      const SizedBox(width: 8),
                      _buildComposerTab(1, Icons.mic_rounded, 'Voice Note', isDark, accent),
                      const SizedBox(width: 8),
                      _buildComposerTab(2, Icons.camera_alt_rounded, 'Photo List', isDark, AppTokens.infoDark),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Active Tab Content
                  if (_selectedComposerTab == 0) ...[
                    // Text Input Bar
                    Row(
                      children: [
                        Expanded(
                          child: GlassTextField(
                            controller: _textController,
                            label: '',
                            hint: isShopkeeper ? 'Reply to customer...' : 'Type items or list...',
                            onSubmitted: (_) => _sendTextMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF0A0F1C), size: 20),
                          onPressed: _sendTextMessage,
                        ),
                      ],
                    ),
                  ] else if (_selectedComposerTab == 1) ...[
                    // Voice Note with Live Waveform Animation
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withOpacity(0.2),
                            ),
                            child: Icon(Icons.mic_rounded, color: accent, size: 22),
                          ),
                          const SizedBox(width: 14),
                          // Waveform visualizer
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _waveformController,
                              builder: (context, _) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(14, (index) {
                                    final val = math.sin(_waveformController.value * math.pi + index * 0.4).abs();
                                    return Container(
                                      width: 3.5,
                                      height: 8.0 + val * 24.0,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        color: accent.withOpacity(0.4 + val * 0.6),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          GlassButton(
                            text: 'Send Audio',
                            width: 110,
                            height: 38,
                            customColor: accent,
                            onPressed: _sendVoiceNote,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Photo List Preview & Upload
                    GlassCard(
                      padding: const EdgeInsets.all(AppTokens.space12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1584445584400-0c487373fbe6?auto=format&fit=crop&w=400&q=80',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sample Handwritten Grocery List',
                              style: AppTokens.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          GlassButton(
                            text: 'Send Photo',
                            width: 110,
                            height: 38,
                            customColor: AppTokens.infoDark,
                            onPressed: _sendPhotoUpload,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposerTab(int tabIndex, IconData icon, String label, bool isDark, Color activeColor) {
    final isSelected = _selectedComposerTab == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedComposerTab = tabIndex),
      child: AnimatedContainer(
        duration: AppTokens.durationSmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
          color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? activeColor : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight)),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTokens.bodySmall(isDark).copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage msg,
    CustomerOrder order,
    bool isCurrentUserShopkeeper,
    bool isDark,
    Color primary,
    Color accent,
  ) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x1FFFFFFF) : const Color(0x330F172A),
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
          ),
          child: Text(
            msg.content,
            textAlign: TextAlign.center,
            style: AppTokens.bodySmall(isDark).copyWith(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final isMe = (isCurrentUserShopkeeper && msg.isShopkeeper) || (!isCurrentUserShopkeeper && msg.isCustomer);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? (isCurrentUserShopkeeper ? accent.withOpacity(0.2) : primary.withOpacity(0.2))
              : (isDark ? AppTokens.glassFillDark : AppTokens.glassFillLight),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(
            color: isMe
                ? (isCurrentUserShopkeeper ? accent.withOpacity(0.5) : primary.withOpacity(0.5))
                : (isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender name tag
            Text(
              msg.senderName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isMe ? (isCurrentUserShopkeeper ? accent : primary) : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),

            // Itemized Bill Message
            if (msg.type == MessageType.billCard && msg.billItems != null) ...[
              Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Itemized Bill from Shopkeeper', style: AppTokens.label(isDark).copyWith(fontSize: 14)),
                ],
              ),
              const Divider(),
              ...msg.billItems!.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.name} (${item.quantity.toInt()} ${item.unit})', style: AppTokens.bodySmall(isDark)),
                        Text('₹${item.total.toInt()}', style: AppTokens.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Grand Total:', style: AppTokens.label(isDark)),
                  Text('₹${(msg.billTotal ?? order.grandTotal).toInt()}', style: AppTokens.headingSmall(isDark).copyWith(color: primary)),
                ],
              ),
              if (!isCurrentUserShopkeeper && order.paymentStatus == 'pending') ...[
                const SizedBox(height: 12),
                GlassButton(
                  text: 'Confirm & Pay (₹${order.grandTotal.toInt()})',
                  icon: Icons.check_circle_rounded,
                  height: 44,
                  onPressed: () => _confirmAndPayOrder(order),
                ),
              ],
            ] else ...[
              Text(msg.content, style: AppTokens.bodyMedium(isDark).copyWith(fontSize: 14)),
            ],

            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
