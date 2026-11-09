import 'package:intl/intl.dart';

/// Utility class for formatting currency and numbers adhering to pt-BR, pt-PT, and en-US locales.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats amount into appropriate currency string according to currency code and locale.
  static String format({
    required double amount,
    required String currencyCode,
    String? locale,
  }) {
    final effectiveLocale = locale ?? _resolveLocale(currencyCode);

    try {
      final format = NumberFormat.currency(
        locale: effectiveLocale,
        name: currencyCode.toUpperCase(),
        symbol: _getSymbol(currencyCode),
        decimalDigits: 2,
      );
      return format.format(amount);
    } catch (_) {
      // Robust fallback formatting
      final isEuroOrReal = currencyCode.toUpperCase() == 'BRL' || currencyCode.toUpperCase() == 'EUR';
      final formattedNumber = isEuroOrReal
          ? amount.toStringAsFixed(2).replaceAll('.', ',')
          : amount.toStringAsFixed(2);
      return '${_getSymbol(currencyCode)} $formattedNumber';
    }
  }

  /// Compact formatting (e.g., R$ 1,5k / $1.5k) for dashboard cards and badges.
  static String formatCompact({
    required double amount,
    required String currencyCode,
    String? locale,
  }) {
    final effectiveLocale = locale ?? _resolveLocale(currencyCode);
    final symbol = _getSymbol(currencyCode);

    try {
      final compactFormat = NumberFormat.compact(locale: effectiveLocale);
      return '$symbol ${compactFormat.format(amount)}';
    } catch (_) {
      return '$symbol ${amount.toStringAsFixed(0)}';
    }
  }

  static String _resolveLocale(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'BRL':
        return 'pt_BR';
      case 'EUR':
        return 'pt_PT';
      case 'USD':
      default:
        return 'en_US';
    }
  }

  static String _getSymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'BRL':
        return 'R\$';
      case 'EUR':
        return '€';
      case 'USD':
      default:
        return '\$';
    }
  }
}
