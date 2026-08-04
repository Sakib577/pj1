import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/chart_theme.dart';
import '../models/analytics_models.dart';
import 'stat_card.dart';

/// Card 9: Monthly Overview — summary of eight key figures.
class MonthlyOverviewCard extends StatelessWidget {
  const MonthlyOverviewCard({
    super.key,
    required this.overview,
    this.onRangeTap,
    this.rangeLabel,
  });

  final MonthlyOverview overview;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = ChartPalette.of(context);

    return StatCard(
      title: 'Monthly Overview',
      icon: Icons.calendar_month_rounded,
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
          Row(
            children: [
              _Figure(
                label: 'Income',
                value: overview.income,
                color: palette.income,
              ),
              _Figure(
                label: 'Expense',
                value: overview.expense,
                color: palette.expense,
              ),
              _Figure(
                label: 'Net',
                value: overview.net,
                color: palette.net,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _TextRow(label: 'Saved', value: formatCurrencyNoCents(overview.saved)),
          _TextRow(
            label: 'Avg daily spend',
            value: formatCurrencyNoCents(overview.avgDailySpend),
          ),
          _TextRow(label: 'Busiest day', value: overview.busiestDay),
          _TextRow(label: 'Top category', value: overview.topCategory),
          _TextRow(
            label: 'Transactions',
            value: '${overview.transactionCount}',
          ),
          const SizedBox(height: 4),
          Text(
            'Tip: keep your saved amount positive to build healthy savings.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
}

class _TextRow extends StatelessWidget {
  const _TextRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}