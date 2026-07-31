String formatCurrency(double value) {
  // Build comma-separated thousands manually so no extra intl package is needed.
  final parts = value.toStringAsFixed(2).split('.');
  final digits = parts.first;
  final reversed = digits.split('').reversed.toList();
  final buffer = StringBuffer();

  for (int i = 0; i < reversed.length; i++) {
    if (i != 0 && i % 3 == 0) buffer.write(',');
    buffer.write(reversed[i]);
  }

  final formattedWhole = buffer.toString().split('').reversed.join();
  return '\$${formattedWhole}.${parts.last}';
}

String formatCurrencyNoCents(double value) {
  // Reuse full formatter first, then trim trailing .00 for cleaner UI labels.
  final formatted = formatCurrency(value);
  return formatted.endsWith('.00') ? formatted.substring(0, formatted.length - 3) : formatted;
}

