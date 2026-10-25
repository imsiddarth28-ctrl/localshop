class Shop {
  final String id;
  final String name;
  final String category;
  final String colonyId;
  final String ownerId;
  final String ownerName;
  final String phone;
  final String address;
  final String hours;
  final String status; // 'approved', 'pending', 'suspended'
  final bool isHoliday;
  final double rating;
  final int reviewCount;
  final double distanceKm; // strictly within 1 km of resident's locality
  final int deliveryFeeInstant;
  final int deliveryFeeMorning;
  final int deliveryFeeEvening;
  final int minOrderAmount;
  final String upiId;
  final String? photoUrl;

  const Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.colonyId,
    required this.ownerId,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.hours,
    this.status = 'approved',
    this.isHoliday = false,
    this.rating = 4.8,
    this.reviewCount = 124,
    this.distanceKm = 0.3,
    this.deliveryFeeInstant = 10,
    this.deliveryFeeMorning = 5,
    this.deliveryFeeEvening = 5,
    this.minOrderAmount = 0,
    this.upiId = 'balajistore@okhdfcbank',
    this.photoUrl,
  });

  bool get isOpen => status == 'approved' && !isHoliday;
  bool get isWithinOneKm => distanceKm <= 1.0;

  Shop copyWith({
    String? name,
    String? category,
    String? address,
    String? hours,
    String? status,
    bool? isHoliday,
    double? rating,
    int? reviewCount,
    double? distanceKm,
    int? deliveryFeeInstant,
    int? deliveryFeeMorning,
    int? deliveryFeeEvening,
    int? minOrderAmount,
    String? upiId,
    String? photoUrl,
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      colonyId: colonyId,
      ownerId: ownerId,
      ownerName: ownerName,
      phone: phone,
      address: address ?? this.address,
      hours: hours ?? this.hours,
      status: status ?? this.status,
      isHoliday: isHoliday ?? this.isHoliday,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      distanceKm: distanceKm ?? this.distanceKm,
      deliveryFeeInstant: deliveryFeeInstant ?? this.deliveryFeeInstant,
      deliveryFeeMorning: deliveryFeeMorning ?? this.deliveryFeeMorning,
      deliveryFeeEvening: deliveryFeeEvening ?? this.deliveryFeeEvening,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      upiId: upiId ?? this.upiId,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'General Store',
      colonyId: json['colony_id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? 'Shopkeeper',
      phone: json['phone'] as String? ?? '+919111111111',
      address: json['address'] as String? ?? '',
      hours: json['hours'] as String? ?? '7:00 AM - 9:30 PM',
      status: json['status'] as String? ?? 'approved',
      isHoliday: json['is_holiday'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 120,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.3,
      deliveryFeeInstant: (json['fee_instant'] as num?)?.toInt() ?? 10,
      deliveryFeeMorning: (json['fee_morning'] as num?)?.toInt() ?? 5,
      deliveryFeeEvening: (json['fee_evening'] as num?)?.toInt() ?? 5,
      minOrderAmount: (json['min_order'] as num?)?.toInt() ?? 0,
      upiId: json['upi_id'] as String? ?? 'localshop@upi',
      photoUrl: json['photo_url'] as String?,
    );
  }
}
