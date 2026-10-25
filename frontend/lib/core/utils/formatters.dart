import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _inrCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrDecimalFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format amount in Indian Rupees: ₹150 or ₹150.50
  static String formatINR(double amount) {
    if (amount % 1 == 0) {
      return _inrCurrencyFormat.format(amount);
    }
    return _inrDecimalFormat.format(amount);
  }

  /// Format phone display: +91 98765 43210
  static String formatPhoneDisplay(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '+91 ${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      final body = cleaned.substring(2);
      return '+91 ${body.substring(0, 5)} ${body.substring(5)}';
    }
    return phone;
  }
}
