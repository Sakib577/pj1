import '../models/finance_models.dart';
import 'currency_settings.dart';

/// Builds an RFC 4180 CSV string of every transaction (oldest first).
///
/// Amounts are converted from the app's USD storage into the user's display
/// currency so the numbers match what is shown in the app. Expenses are
/// negative, income positive.
String buildTransactionsCsv(List<TransactionItem> transactions) {
  final sorted = [...transactions]
    ..sort((a, b) => _time(a).compareTo(_time(b)));
  final buffer = StringBuffer();
  buffer.writeln(_csvRow([
    'Date',
    'Time',
    'Title',
    'Category',
    'Note',
    'Type',
    'Amount ($_code)',
  ]));
  for (final txn in sorted) {
    final date = _formatDate(_time(txn));
    final time = _formatTime(_time(txn));
    final note = (txn.note ?? '').trim();
    final amount = CurrencySettings.fromUsd(txn.amount);
    final signedAmount = (txn.negative ? -amount : amount).toStringAsFixed(2);
    buffer.writeln(
      _csvRow([
        date,
        time,
        txn.title.trim(),
        txn.categoryName.trim(),
        note,
        txn.negative ? 'Expense' : 'Income',
        signedAmount,
      ]),
    );
  }
  return buffer.toString();
}

String get _code => CurrencySettings.code;

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _formatTime(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '$h:$min';
}

DateTime _time(TransactionItem item) => item.createdAt ?? DateTime(0);

/// Wraps and quotes each field, then joins them with commas.
String _csvRow(List<String> fields) => fields.map(_escapeCsvField).join(',');

/// Escapes a single CSV field per RFC 4180.
String _escapeCsvField(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
