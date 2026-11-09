import 'package:flutter_test/flutter_test.dart';
import 'package:color_fund/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter i18n QA Tests', () {
    test('Formats BRL correctly with symbol and decimals', () {
      final formatted = CurrencyFormatter.format(
        amount: 1500.50,
        currencyCode: 'BRL',
      );

      expect(formatted.contains('R\$'), isTrue);
      expect(formatted.contains('1.500,50') || formatted.contains('1500,50'), isTrue);
    });

    test('Formats USD correctly with dollar sign and decimals', () {
      final formatted = CurrencyFormatter.format(
        amount: 2500.00,
        currencyCode: 'USD',
      );

      expect(formatted.contains('\$'), isTrue);
      expect(formatted.contains('2,500.00') || formatted.contains('2500.00'), isTrue);
    });

    test('Formats EUR correctly with euro symbol', () {
      final formatted = CurrencyFormatter.format(
        amount: 300.00,
        currencyCode: 'EUR',
      );

      expect(formatted.contains('€'), isTrue);
    });

    test('Compact format generates clean short abbreviations', () {
      final compactBRL = CurrencyFormatter.formatCompact(
        amount: 5000.00,
        currencyCode: 'BRL',
      );
      expect(compactBRL.contains('R\$'), isTrue);

      final compactUSD = CurrencyFormatter.formatCompact(
        amount: 10000.00,
        currencyCode: 'USD',
      );
      expect(compactUSD.contains('\$'), isTrue);
    });
  });
}

