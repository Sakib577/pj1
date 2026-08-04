import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/chart_theme.dart';

/// Income / expense / net mini summary shown at the top of several cards.
class StatSummaryRow extends StatelessWidget {
  const StatSummaryRow({
    super.key,
    required this.income,
    required this.expense,
    this.net,
    this.compact = false,
  });

  final double income;
  final double expense;
  final double? net;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = ChartPalette.of(context);
    final netValue = net ?? income - expense;

    Widget cell(String label, double value, Color color) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatCurrencyNoCents(value),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        cell('Income', income, palette.income),
        cell('Expense', expense, palette.expense),
        cell('Net', netValue, netValue >= 0 ? palette.primary : palette.highlight),
      ],
    );
  }
}