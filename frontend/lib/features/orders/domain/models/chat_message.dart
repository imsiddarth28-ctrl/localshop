import 'order.dart';

enum MessageType {
  text,
  photo,
  voice,
  billCard,
  systemStatus,
}

class ChatMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'customer', 'shop_owner', 'system'
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final int? voiceDurationSeconds;
  final List<OrderItem>? billItems;
  final double? billTotal;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.type = MessageType.text,
    required this.content,
    this.mediaUrl,
    this.voiceDurationSeconds,
    this.billItems,
    this.billTotal,
    required this.timestamp,
  });

  bool get isCustomer => senderRole == 'customer';
  bool get isShopkeeper => senderRole == 'shop_owner';
  bool get isSystem => senderRole == 'system';
}
