import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/chart_theme.dart';
import '../models/analytics_models.dart';
import 'stat_card.dart';
import 'stat_summary_row.dart';

/// Card 2: Cash Flow Summary — income/expense/net with amber progress bars and
/// "vs previous period" deltas.
class CashFlowSummaryCard extends StatelessWidget {
  const CashFlowSummaryCard({
    super.key,
    required this.summary,
    this.onRangeTap,
    this.rangeLabel,
  });

  final CashFlowSummary summary;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);

    final maxValue = [summary.income, summary.expense].fold(
      0.0,
      (m, v) => v > m ? v : m,
    );

    return StatCard(
      title: 'Cash Flow Summary',
      icon: Icons.currency_exchange_rounded,
      subtitle: rangeLabel,
      trailing: onRangeTap != null
          ? IconButton(
              onPressed: onRangeTap,
              tooltip: 'Change range',
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatSummaryRow(
            income: summary.income,
            expense: summary.expense,
            net: summary.net,
          ),
          const SizedBox(height: 16),
          _ProgressRow(
            label: 'Income',
            amount: summary.income,
            ratio: maxValue == 0 ? 0 : summary.income / maxValue,
            color: palette.income,
            delta: summary.incomeVsPrevious,
          ),
          const SizedBox(height: 10),
          _ProgressRow(
            label: 'Expense',
            amount: summary.expense,
            ratio: maxValue == 0 ? 0 : summary.expense / maxValue,
            color: palette.expense,
            delta: summary.expenseVsPrevious,
          ),
          const SizedBox(height: 10),
          _ProgressRow(
            label: 'Net',
            amount: summary.net,
            ratio: maxValue == 0
                ? 0
                : (summary.net.abs() / maxValue).clamp(0, 1),
            color: palette.net,
            delta: 0,
            deltaLabel: 'saved',
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
    required this.delta,
    this.deltaLabel,
  });

  final String label;
  final double amount;
  final double ratio;
  final Color color;
  final double delta;
  final String? deltaLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = ratio.clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 8,
              color: color,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 84,
          child: Text(
            formatCurrencyNoCents(amount),
            textAlign: TextAlign.right,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            delta == 0
                ? (deltaLabel ?? '—')
                : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: theme.textTheme.labelSmall?.copyWith(
              color: delta > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}