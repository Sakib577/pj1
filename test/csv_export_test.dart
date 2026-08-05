import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj1/models/finance_models.dart';
import 'package:pj1/utils/csv_export.dart';
import 'package:pj1/utils/currency_settings.dart';

void main() {
  TransactionItem txn({
    required double amount,
    required DateTime date,
    bool negative = true,
    String title = 'Coffee',
    String category = 'Food & Drinks',
    String? note,
  }) => TransactionItem(
    id: 't-$date-$amount',
    title: title,
    subtitle: '',
    amount: amount,
    icon: Icons.restaurant_rounded,
    iconColor: const Color(0xFFF97316),
    categoryName: category,
    note: note,
    negative: negative,
    createdAt: date,
  );

  setUp(() => CurrencySettings.update(code: 'USD', rates: {'USD': 1}));

  group('buildTransactionsCsv', () {
    test('writes a header row and exports every transaction', () {
      final rows = [
        txn(amount: 12.5, date: DateTime(2026, 8, 3)),
        txn(amount: 3000, date: DateTime(2026, 8, 1), negative: false),
      ];
      final csv = buildTransactionsCsv(rows);
      final lines = csv.trimRight().split('\n');

      expect(
        lines.first,
        'Date,Time,Title,Category,Note,Type,Amount (USD)',
      );
      expect(lines.length, 3);

      // Sorted oldest first.
      expect(lines[1], startsWith('2026-08-01,'));
      expect(lines[2], startsWith('2026-08-03,'));

      // Income positive, expense negative, two decimal places.
      expect(lines[1], endsWith(',Income,3000.00'));
      expect(lines[2], endsWith(',Expense,-12.50'));
    });

    test('escapes commas, quotes and newlines in fields', () {
      final csv = buildTransactionsCsv([
        txn(
          amount: 5,
          date: DateTime(2026, 8, 1),
          title: 'Tea, chai',
          note: 'Said "cheers" then\nwent out',
        ),
      ]);
      expect(csv, contains('"Tea, chai"'));
      expect(csv, contains('"Said ""cheers"" then\nwent out"'));
    });

    test('converts amounts into the display currency', () {
      CurrencySettings.update(code: 'BDT', rates: {'USD': 1, 'BDT': 120});
      final csv = buildTransactionsCsv([
        txn(amount: 10, date: DateTime(2026, 8, 1)),
      ]);
      expect(csv, contains('Amount (BDT)'));
      expect(csv.trimRight().split('\n').last, endsWith(',Expense,-1200.00'));
    });

    test('empty list exports just the header', () {
      final csv = buildTransactionsCsv([]);
      expect(csv.trimRight().split('\n').length, 1);
    });
  });
}
