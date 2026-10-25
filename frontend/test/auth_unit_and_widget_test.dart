import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_local_shop/core/utils/validators.dart';
import 'package:the_local_shop/core/utils/formatters.dart';
import 'package:the_local_shop/main.dart';

void main() {
  group('Auth Unit Tests - Validators & Formatters', () {
    test('Validates Indian 10-digit phone numbers', () {
      expect(AppValidators.isValidIndianPhone('9876543210'), isTrue);
      expect(AppValidators.isValidIndianPhone('6123456789'), isTrue);
      expect(AppValidators.isValidIndianPhone('+919876543210'), isTrue);
      expect(AppValidators.isValidIndianPhone('12345'), isFalse);
      expect(AppValidators.isValidIndianPhone('5876543210'), isFalse); // Doesn't start with 6-9
      expect(AppValidators.isValidIndianPhone('abcdefghij'), isFalse);
    });

    test('E164 Phone Formatting', () {
      expect(AppValidators.formatToE164('9876543210'), '+919876543210');
      expect(AppValidators.formatToE164('+91 98765 43210'), '+919876543210');
    });

    test('Generates correct synthetic email for Supabase Auth', () {
      expect(
        AppValidators.generateSyntheticEmail('9876543210'),
        '919876543210@thelocalshop.app',
      );
      expect(
        AppValidators.generateSyntheticEmail('+91 94444 44441'),
        '919444444441@thelocalshop.app',
      );
    });

    test('Colony Join Code Validation (6 chars alphanumeric)', () {
      expect(AppValidators.isValidJoinCode('GRN101'), isTrue);
      expect(AppValidators.isValidJoinCode('grn101'), isTrue); // normalizes
      expect(AppValidators.isValidJoinCode('GRN'), isFalse);
      expect(AppValidators.isValidJoinCode('GRN10199'), isFalse);
      expect(AppValidators.isValidJoinCode('GRN#01'), isFalse);
    });

    test('Password validation (min 6 chars)', () {
      expect(AppValidators.isValidPassword('pass123'), isTrue);
      expect(AppValidators.isValidPassword('123456'), isTrue);
      expect(AppValidators.isValidPassword('12345'), isFalse);
    });

    test('INR Currency formatting', () {
      expect(AppFormatters.formatINR(10.0), '₹10');
      expect(AppFormatters.formatINR(5.0), '₹5');
      expect(AppFormatters.formatINR(148.50), '₹148.50');
    });
  });

  group('Widget Tests - App Smoke Test', () {
    testWidgets('App renders correctly with ProviderScope', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TheLocalShopApp(),
        ),
      );

      // Verify that the app launches and displays the brand title
      await tester.pumpAndSettle();
      expect(find.text('The Local Shop'), findsWidgets);
    });
  });
}
