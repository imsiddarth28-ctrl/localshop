class AppConstants {
  static const String appName = 'The Local Shop';
  static const String appVersion = '1.0.0';
  static const String syntheticEmailDomain = 'thelocalshop.app';

  // Phone Configuration (India)
  static const String countryCode = '+91';
  static const int phoneLength = 10;

  // Authentication & Security
  static const int minPasswordLength = 6;
  static const int maxFailedLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // Delivery Fees (INR ₹)
  static const double defaultInstantFee = 10.0;
  static const double defaultSlotFee = 5.0;

  // Batch Delivery Slots
  static const String morningSlotTime = '7:00 AM';
  static const String eveningSlotTime = '6:00 PM';
  static const String defaultMorningCutoff = '22:00'; // 10:00 PM previous night
  static const String defaultEveningCutoff = '16:00'; // 4:00 PM same day

  // Storage Buckets
  static const String bucketChatMedia = 'chat-media';
  static const String bucketShopPhotos = 'shop-photos';
  static const String bucketAvatars = 'avatars';

  // Demo Colony Default
  static const String demoColonyJoinCode = 'GRN101';

  // Shop Categories
  static const List<String> shopCategories = [
    'Grocery',
    'Dairy',
    'Vegetables',
    'Medical',
    'Stationery',
    'Bakery',
    'Other',
  ];
}
