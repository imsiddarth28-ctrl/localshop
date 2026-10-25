class AppValidators {
  static final RegExp _phoneRegExp = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _joinCodeRegExp = RegExp(r'^[A-Z0-9]{6}$');

  /// Validates standard Indian 10-digit mobile number starting with 6, 7, 8, or 9
  static bool isValidIndianPhone(String? phone) {
    if (phone == null) return false;
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return _phoneRegExp.hasMatch(cleaned.substring(2));
    }
    return _phoneRegExp.hasMatch(cleaned);
  }

  /// Sanitizes phone to standard +91XXXXXXXXXX format
  static String formatToE164(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '+91$cleaned';
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return '+$cleaned';
    }
    return '+$cleaned';
  }

  /// Generates the synthetic email for Supabase Auth: <91XXXXXXXXXX>@thelocalshop.app
  static String generateSyntheticEmail(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final tenDigits = cleaned.length >= 10 ? cleaned.substring(cleaned.length - 10) : cleaned;
    return '91$tenDigits@thelocalshop.app';
  }

  /// Password validator (minimum 6 characters)
  static bool isValidPassword(String? password) {
    if (password == null) return false;
    return password.trim().length >= 6;
  }

  /// Validates 6-character colony join code
  static bool isValidJoinCode(String? code) {
    if (code == null) return false;
    return _joinCodeRegExp.hasMatch(code.trim().toUpperCase());
  }

  /// Sanitizes user input against HTML tags, script injection, and excessive whitespace
  static String sanitizeText(String? input) {
    if (input == null) return '';
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .trim();
  }
}
