import 'package:the_local_shop/features/orders/domain/models/chat_message.dart';
import 'package:the_local_shop/features/orders/domain/models/order.dart';
import 'package:the_local_shop/features/shops/domain/models/shop.dart';

class OrderRepository {
  // In-memory persistent state for realistic demo interaction
  final List<Shop> _shops = [
    const Shop(
      id: 'e0000000-0000-0000-0000-000000000001',
      name: 'Sri Balaji Kirana & General Store',
      category: 'Kirana & Groceries',
      colonyId: 'c0000000-0000-0000-0000-000000000001',
      ownerId: 'b0000000-0000-0000-0000-000000000001',
      ownerName: 'Balaji Sharma',
      phone: '+919111111111',
      address: 'Shop #1, Community Center, Greenwood Heights',
      hours: '7:00 AM - 10:00 PM',
      rating: 4.8,
      reviewCount: 142,
      distanceKm: 0.2,
      deliveryFeeInstant: 10,
      deliveryFeeMorning: 5,
      deliveryFeeEvening: 5,
      upiId: 'balajistore@okhdfcbank',
      isHoliday: false,
    ),
    const Shop(
      id: 'e0000000-0000-0000-0000-000000000002',
      name: 'Greenwood Fresh Milk & Farm Veggies',
      category: 'Dairy & Fresh Vegetables',
      colonyId: 'c0000000-0000-0000-0000-000000000001',
      ownerId: 'b0000000-0000-0000-0000-000000000002',
      ownerName: 'Ramesh Patel',
      phone: '+919222222222',
      address: 'Block B Entry Gate, Greenwood Heights',
      hours: '6:00 AM - 9:00 PM',
      rating: 4.9,
      reviewCount: 96,
      distanceKm: 0.5,
      deliveryFeeInstant: 10,
      deliveryFeeMorning: 5,
      deliveryFeeEvening: 5,
      upiId: 'rameshdairy@okaxis',
      isHoliday: false,
    ),
    const Shop(
      id: 'e0000000-0000-0000-0000-000000000003',
      name: 'Apollo Colony Meds & Wellness',
      category: 'Pharmacy & Essentials',
      colonyId: 'c0000000-0000-0000-0000-000000000001',
      ownerId: 'b0000000-0000-0000-0000-000000000003',
      ownerName: 'Dr. K. Srinivas',
      phone: '+919333333333',
      address: 'Near Main Gate, Greenwood Heights',
      hours: '8:00 AM - 11:00 PM',
      rating: 4.7,
      reviewCount: 64,
      distanceKm: 0.8,
      deliveryFeeInstant: 10,
      deliveryFeeMorning: 5,
      deliveryFeeEvening: 5,
      upiId: 'apollocolony@icici',
      isHoliday: false,
    ),
  ];

  final List<CustomerOrder> _orders = [];
  final Map<String, List<ChatMessage>> _orderMessages = {};

  // Queries: Only shops within 1 km and matching the resident's locality (colonyId)
  List<Shop> getShopsForColony(String colonyId) {
    return _shops
        .where((s) => s.colonyId == colonyId && s.distanceKm <= 1.0)
        .toList();
  }

  Shop? getShopById(String shopId) {
    try {
      return _shops.firstWhere((s) => s.id == shopId);
    } catch (_) {
      return null;
    }
  }

  void toggleShopHoliday(String shopId, bool isHoliday) {
    final idx = _shops.indexWhere((s) => s.id == shopId);
    if (idx != -1) {
      _shops[idx] = _shops[idx].copyWith(isHoliday: isHoliday);
    }
  }

  List<CustomerOrder> getOrdersForUser(String userId, {bool isShopkeeper = false}) {
    if (isShopkeeper) {
      return _orders.where((o) => o.shopId.contains('e0000000-0000-0000-0000-000000000001')).toList();
    }
    return _orders.where((o) => o.customerId == userId).toList();
  }

  List<CustomerOrder> getAllOrders() {
    return List.unmodifiable(_orders);
  }

  List<ChatMessage> getMessages(String orderId) {
    return List.unmodifiable(_orderMessages[orderId] ?? []);
  }

  CustomerOrder createOrder({
    required String shopId,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required DeliverySlotType slot,
    required String initialMessage,
    String? mediaUrl,
  }) {
    final shop = getShopById(shopId)!;
    final orderId = 'ord-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final deliveryFee = slot.fee.toDouble();

    final order = CustomerOrder(
      id: orderId,
      colonyId: shop.colonyId,
      shopId: shop.id,
      shopName: shop.name,
      shopPhone: shop.phone,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      slot: slot,
      status: OrderStatus.placed,
      deliveryFee: deliveryFee,
      packingFee: 2.0,
      grandTotal: deliveryFee + 2.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _orders.insert(0, order);

    _orderMessages[orderId] = [
      ChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        senderId: customerId,
        senderName: customerName,
        senderRole: 'customer',
        type: mediaUrl != null ? MessageType.photo : MessageType.text,
        content: initialMessage,
        mediaUrl: mediaUrl,
        timestamp: DateTime.now(),
      ),
    ];

    return order;
  }

  void sendMessage({
    required String orderId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    int? voiceDurationSeconds,
  }) {
    final msg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      voiceDurationSeconds: voiceDurationSeconds,
      timestamp: DateTime.now(),
    );

    _orderMessages.putIfAbsent(orderId, () => []).add(msg);
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(status: newStatus, updatedAt: DateTime.now());

      // Add system message to order chat
      _orderMessages.putIfAbsent(orderId, () => []).add(
            ChatMessage(
              id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
              orderId: orderId,
              senderId: 'system',
              senderName: 'System',
              senderRole: 'system',
              type: MessageType.systemStatus,
              content: 'Order status updated to: ${newStatus.label}',
              timestamp: DateTime.now(),
            ),
          );
    }
  }

  void attachBillToOrder({
    required String orderId,
    required List<OrderItem> items,
    required double deliveryFee,
    required double packingFee,
  }) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final itemsTotal = items.fold(0.0, (acc, item) => acc + item.total);
      final grandTotal = itemsTotal + deliveryFee + packingFee;

      _orders[idx] = _orders[idx].copyWith(
        items: items,
        itemsTotal: itemsTotal,
        deliveryFee: deliveryFee,
        packingFee: packingFee,
        grandTotal: grandTotal,
        status: OrderStatus.billed,
        updatedAt: DateTime.now(),
      );

      _orderMessages.putIfAbsent(orderId, () => []).add(
            ChatMessage(
              id: 'bill-${DateTime.now().millisecondsSinceEpoch}',
              orderId: orderId,
              senderId: _orders[idx].shopId,
              senderName: _orders[idx].shopName,
              senderRole: 'shop_owner',
              type: MessageType.billCard,
              content: 'Itemized Bill: ${items.length} items, Total ₹${grandTotal.toStringAsFixed(0)}',
              billTotal: grandTotal,
              billItems: items,
              timestamp: DateTime.now(),
            ),
          );
    }
  }

  void markOrderPaid({
    required String orderId,
    required String method, // 'upi' or 'cod'
  }) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(
        paymentStatus: method == 'upi' ? 'paid_online' : 'cod',
        paymentMethod: method,
        status: OrderStatus.packing,
        updatedAt: DateTime.now(),
      );

      _orderMessages.putIfAbsent(orderId, () => []).add(
            ChatMessage(
              id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
              orderId: orderId,
              senderId: 'system',
              senderName: 'System',
              senderRole: 'system',
              type: MessageType.systemStatus,
              content: method == 'upi'
                  ? 'Payment verified via UPI. Shopkeeper is packing your items.'
                  : 'Payment method chosen: Cash on Delivery (COD). Preparing order.',
              timestamp: DateTime.now(),
            ),
          );
    }
  }
}
