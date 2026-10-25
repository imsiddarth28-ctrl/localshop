enum OrderStatus {
  placed,
  accepted,
  billed,
  packing,
  outForDelivery,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.billed:
        return 'Bill Ready';
      case OrderStatus.packing:
        return 'Packing Items';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get teluguLabel {
    switch (this) {
      case OrderStatus.placed:
        return 'ఆర్డర్ ఇవ్వబడింది';
      case OrderStatus.accepted:
        return 'అంగీకరించబడింది';
      case OrderStatus.billed:
        return 'బిల్లు సిద్ధంగా ఉంది';
      case OrderStatus.packing:
        return 'ప్యాక్ చేస్తున్నారు';
      case OrderStatus.outForDelivery:
        return 'డెలివరీకి బయలుదేరింది';
      case OrderStatus.delivered:
        return 'డెలివరీ పూర్తయింది';
      case OrderStatus.cancelled:
        return 'రద్దు చేయబడింది';
    }
  }
}

enum DeliverySlotType {
  instant,
  morning,
  evening;

  String get title {
    switch (this) {
      case DeliverySlotType.instant:
        return 'Instant Delivery (₹10)';
      case DeliverySlotType.morning:
        return 'Morning Batch 7:00 AM (₹5)';
      case DeliverySlotType.evening:
        return 'Evening Batch 6:00 PM (₹5)';
    }
  }

  String get cutoffHint {
    switch (this) {
      case DeliverySlotType.instant:
        return 'Delivered within 30 mins';
      case DeliverySlotType.morning:
        return 'Order before 6:30 AM';
      case DeliverySlotType.evening:
        return 'Order before 5:30 PM';
    }
  }

  int get fee {
    switch (this) {
      case DeliverySlotType.instant:
        return 10;
      case DeliverySlotType.morning:
      case DeliverySlotType.evening:
        return 5;
    }
  }
}

class OrderItem {
  final String name;
  final double quantity;
  final String unit;
  final double pricePerUnit;

  const OrderItem({
    required this.name,
    required this.quantity,
    this.unit = 'pc',
    required this.pricePerUnit,
  });

  double get total => quantity * pricePerUnit;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'price_per_unit': pricePerUnit,
        'total': total,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String? ?? 'pc',
        pricePerUnit: (json['price_per_unit'] as num).toDouble(),
      );
}

class CustomerOrder {
  final String id;
  final String colonyId;
  final String shopId;
  final String shopName;
  final String shopPhone;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final OrderStatus status;
  final DeliverySlotType slot;
  final List<OrderItem> items;
  final double itemsTotal;
  final double deliveryFee;
  final double packingFee;
  final double grandTotal;
  final String paymentStatus; // 'pending', 'paid_online', 'cod'
  final String? paymentMethod; // 'upi', 'cod'
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerOrder({
    required this.id,
    required this.colonyId,
    required this.shopId,
    required this.shopName,
    required this.shopPhone,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.status = OrderStatus.placed,
    this.slot = DeliverySlotType.instant,
    this.items = const [],
    this.itemsTotal = 0.0,
    this.deliveryFee = 10.0,
    this.packingFee = 2.0,
    this.grandTotal = 12.0,
    this.paymentStatus = 'pending',
    this.paymentMethod,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  CustomerOrder copyWith({
    OrderStatus? status,
    DeliverySlotType? slot,
    List<OrderItem>? items,
    double? itemsTotal,
    double? deliveryFee,
    double? packingFee,
    double? grandTotal,
    String? paymentStatus,
    String? paymentMethod,
    String? notes,
    DateTime? updatedAt,
  }) {
    return CustomerOrder(
      id: id,
      colonyId: colonyId,
      shopId: shopId,
      shopName: shopName,
      shopPhone: shopPhone,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      status: status ?? this.status,
      slot: slot ?? this.slot,
      items: items ?? this.items,
      itemsTotal: itemsTotal ?? this.itemsTotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      packingFee: packingFee ?? this.packingFee,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
