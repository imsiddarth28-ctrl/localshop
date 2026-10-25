import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_local_shop/features/orders/data/repositories/order_repository.dart';
import 'package:the_local_shop/features/orders/domain/models/chat_message.dart';
import 'package:the_local_shop/features/orders/domain/models/order.dart';
import 'package:the_local_shop/features/shops/domain/models/shop.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

class OrderState {
  final List<CustomerOrder> orders;
  final List<Shop> shops;
  final Map<String, List<ChatMessage>> messagesByOrderId;
  final bool isLoading;

  const OrderState({
    this.orders = const [],
    this.shops = const [],
    this.messagesByOrderId = const {},
    this.isLoading = false,
  });

  OrderState copyWith({
    List<CustomerOrder>? orders,
    List<Shop>? shops,
    Map<String, List<ChatMessage>>? messagesByOrderId,
    bool? isLoading,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      shops: shops ?? this.shops,
      messagesByOrderId: messagesByOrderId ?? this.messagesByOrderId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderRepository _repo;

  OrderNotifier(this._repo) : super(const OrderState()) {
    refreshAll();
  }

  void refreshAll() {
    final shops = _repo.getShopsForColony('c0000000-0000-0000-0000-000000000001');
    final orders = _repo.getAllOrders();
    final Map<String, List<ChatMessage>> messages = {};
    for (final o in orders) {
      messages[o.id] = _repo.getMessages(o.id);
    }
    state = state.copyWith(shops: shops, orders: orders, messagesByOrderId: messages);
  }

  void toggleHoliday(String shopId, bool isHoliday) {
    _repo.toggleShopHoliday(shopId, isHoliday);
    refreshAll();
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
    final order = _repo.createOrder(
      shopId: shopId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      slot: slot,
      initialMessage: initialMessage,
      mediaUrl: mediaUrl,
    );
    refreshAll();
    return order;
  }

  void sendChatMessage({
    required String orderId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    int? voiceDurationSeconds,
  }) {
    _repo.sendMessage(
      orderId: orderId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      voiceDurationSeconds: voiceDurationSeconds,
    );
    refreshAll();
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    _repo.updateOrderStatus(orderId, newStatus);
    refreshAll();
  }

  void attachBill({
    required String orderId,
    required List<OrderItem> items,
    required double deliveryFee,
    required double packingFee,
  }) {
    _repo.attachBillToOrder(
      orderId: orderId,
      items: items,
      deliveryFee: deliveryFee,
      packingFee: packingFee,
    );
    refreshAll();
  }

  void payOrder({
    required String orderId,
    required String method,
  }) {
    _repo.markOrderPaid(orderId: orderId, method: method);
    refreshAll();
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return OrderNotifier(repo);
});
