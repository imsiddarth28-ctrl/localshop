import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_local_shop/core/theme/app_colors.dart';
import 'package:the_local_shop/core/widgets/elder_friendly_button.dart';
import 'package:the_local_shop/features/auth/domain/models/app_role.dart';
import 'package:the_local_shop/features/auth/presentation/providers/auth_provider.dart';
import 'package:the_local_shop/features/bill_builder/presentation/widgets/bill_builder_dialog.dart';
import 'package:the_local_shop/features/orders/domain/models/chat_message.dart';
import 'package:the_local_shop/features/orders/domain/models/order.dart';
import 'package:the_local_shop/core/utils/validators.dart';
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

class _OrderChatScreenState extends ConsumerState<OrderChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
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

  void _simulatePhotoUpload() {
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
  }

  void _simulateVoiceNote() {
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
  }

  void _confirmAndPayOrder(CustomerOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Confirm Order with ${order.shopName}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Total Bill: ₹${order.grandTotal.toInt()} • ${order.slot.title}',
                          style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Confirm Order with Payment Option:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 32),
              title: const Text('Confirm & Pay via UPI', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Instant transfer via GPay / PhonePe / Paytm to ${order.shopName}'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(orderProvider.notifier).payOrder(orderId: order.id, method: 'upi');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order Confirmed via UPI! Shopkeeper is packing your items.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.payments_rounded, color: AppColors.secondary, size: 32),
              title: const Text('Confirm with Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Pay cash to delivery boy when items reach your door'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(orderProvider.notifier).payOrder(orderId: order.id, method: 'cod');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order Confirmed (Cash on Delivery)! Shopkeeper is preparing delivery.'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Itemized bill sent to customer for confirmation!'),
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
    final orderList = orderState.orders.where((o) => o.id == widget.orderId).toList();

    if (orderList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Chat')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final order = orderList.first;
    final messages = orderState.messagesByOrderId[order.id] ?? [];
    final isShopkeeper = user?.role == AppRole.shopOwner;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isShopkeeper ? order.customerName : order.shopName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              isShopkeeper
                  ? '📞 ${order.customerPhone} • 📍 ${order.customerAddress}'
                  : '📍 Locality Shop (Within 1 km) • ${order.slot.title}',
              style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk, color: AppColors.primary),
            tooltip: 'Call',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling ${isShopkeeper ? order.customerPhone : order.shopPhone}...')),
              );
            },
          ),
          if (isShopkeeper)
            IconButton(
              icon: const Icon(Icons.receipt_long, color: AppColors.secondary),
              tooltip: 'Build & Send Bill',
              onPressed: () => _openBillBuilder(order),
            ),
        ],
      ),
      body: Column(
        children: [
          // Order Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryContainer.withOpacity(0.4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.label.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Total: ₹${order.grandTotal.toInt()} • ${order.paymentStatus == 'paid_online' ? 'PAID ONLINE' : (order.paymentStatus == 'cod' ? 'CASH ON DELIVERY' : 'Awaiting Confirmation')}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                if (isShopkeeper)
                  PopupMenuButton<OrderStatus>(
                    icon: const Icon(Icons.more_vert),
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

          // Messages Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, idx) {
                final msg = messages[idx];
                return _buildMessageBubble(msg, order, isShopkeeper);
              },
            ),
          ),

          // Quick Suggestion Pills
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickGroceryPills.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final pill = _quickGroceryPills[i];
                return ActionChip(
                  label: Text(pill, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    final current = _textController.text;
                    _textController.text = current.isEmpty ? pill : '$current, $pill';
                  },
                );
              },
            ),
          ),

          // Bottom Chat Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_rounded, color: AppColors.secondary, size: 28),
                    tooltip: 'Attach Handwritten Note Photo',
                    onPressed: _simulatePhotoUpload,
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 28),
                    tooltip: 'Send Voice Note',
                    onPressed: _simulateVoiceNote,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: isShopkeeper ? 'Reply to customer...' : 'Type items or note...',
                        filled: true,
                        fillColor: AppColors.cardLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendTextMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, CustomerOrder order, bool isCurrentUserShopkeeper) {
    if (msg.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: Text(
            msg.content,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        ),
      );
    }

    final isMe = (isCurrentUserShopkeeper && msg.isShopkeeper) || (!isCurrentUserShopkeeper && msg.isCustomer);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe ? (isCurrentUserShopkeeper ? AppColors.secondaryContainer : AppColors.primaryContainer) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.senderName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: msg.isShopkeeper ? AppColors.secondary : AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),

            // Message Content
            if (msg.type == MessageType.photo && msg.mediaUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  msg.mediaUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: Colors.grey.shade300,
                    child: const Center(child: Icon(Icons.broken_image, size: 40)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(msg.content, style: const TextStyle(fontSize: 15)),
            ] else if (msg.type == MessageType.voice) ...[
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Voice note (${msg.voiceDurationSeconds ?? 14}s)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else if (msg.type == MessageType.billCard && msg.billItems != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt, color: AppColors.secondary, size: 20),
                        SizedBox(width: 8),
                        Text('Itemized Bill from Shopkeeper', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const Divider(),
                    ...msg.billItems!.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.name} (${item.quantity.toInt()} ${item.unit})',
                                  style: const TextStyle(fontSize: 14)),
                              Text('₹${item.total.toInt()}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery + Packing:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        Text('₹${(order.deliveryFee + order.packingFee).toInt()}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('₹${(msg.billTotal ?? order.grandTotal).toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
                      ],
                    ),
                    // Confirmation Action for Customer
                    if (!isCurrentUserShopkeeper && order.paymentStatus == 'pending') ...[
                      const SizedBox(height: 12),
                      ElderFriendlyButton(
                        text: 'Confirm Order & Pay (₹${order.grandTotal.toInt()})',
                        icon: Icons.check_circle_rounded,
                        onPressed: () => _confirmAndPayOrder(order),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Text(msg.content, style: const TextStyle(fontSize: 16, height: 1.3)),
            ],

            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
