import 'currency_settings.dart';

String formatCurrency(double value) {
  final displayedValue = CurrencySettings.fromUsd(value);
  final isNegative = displayedValue < 0;
  final absoluteValue = displayedValue.abs();
  // Build comma-separated thousands manually so no extra intl package is needed.
  final parts = absoluteValue.toStringAsFixed(2).split('.');
  final digits = parts.first;
  final reversed = digits.split('').reversed.toList();
  final buffer = StringBuffer();

  for (int i = 0; i < reversed.length; i++) {
    if (i != 0 && i % 3 == 0) buffer.write(',');
    buffer.write(reversed[i]);
  }

  final formattedWhole = buffer.toString().split('').reversed.join();
  // Hide decimal digits when the fraction is zero, and trim trailing zeros
  // otherwise, so "1000.00" -> "1000" and "12.50" -> "12.5".
  var fraction = parts.last;
  fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
  final decimal = fraction.isEmpty ? '' : '.$fraction';
  return '${isNegative ? '-' : ''}${CurrencySettings.symbol}$formattedWhole$decimal';
}

String formatCurrencyNoCents(double value) {
  // Convert to the display currency FIRST, then round. Rounding the raw value
  // (USD) before converting loses precision for high-rate currencies: e.g.
  // 4.05 USD at 123.5 BDT/USD is 500 BDT, but rounding 4.05 to 4 USD first
  // would display 494 instead.
  final displayedValue = CurrencySettings.fromUsd(value);
  final isNegative = displayedValue < 0;
  final absoluteValue = displayedValue.abs();
  // Build comma-separated thousands manually so no extra intl package is needed.
  final digits = absoluteValue.toStringAsFixed(0);
  final reversed = digits.split('').reversed.toList();
  final buffer = StringBuffer();

  for (int i = 0; i < reversed.length; i++) {
    if (i != 0 && i % 3 == 0) buffer.write(',');
    buffer.write(reversed[i]);
  }

  final formattedWhole = buffer.toString().split('').reversed.join();
  return '${isNegative ? '-' : ''}${CurrencySettings.symbol}$formattedWhole';
}

String formatCurrencyInput(double value) {
  return formatCurrencyNoCents(value);
}
