import 'package:flutter_test/flutter_test.dart';
import 'package:pj1/utils/currency_formatters.dart';
import 'package:pj1/utils/currency_settings.dart';

void main() {
  group('formatCurrencyNoCents', () {
    setUp(() => CurrencySettings.update(code: 'BDT', rates: {'BDT': 123.5}));

    test('converts to display currency before rounding', () {
      // 500 BDT = ~4.05 USD. Rounding the USD first (to 4) then converting
      // would show 494; converting first must keep 500.
      final usd = CurrencySettings.toUsd(500);
      expect(formatCurrencyNoCents(usd), '৳500');
    });

    test('small sub-currency contributions keep their full value', () {
      final usd = CurrencySettings.toUsd(10);
      expect(formatCurrencyNoCents(usd), '৳10');
    });
  });
}
