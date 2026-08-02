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
  // Reuse the full formatter; it already omits zero decimals.
  return formatCurrency(value);
}

String formatCurrencyInput(double value) {
  return formatCurrencyNoCents(value);
}
