import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../models/analytics_models.dart';
import 'stat_card.dart';

/// Card 11: Category Analytics — per-category grid of percentage, avg, max/min,
/// count, per-day, and monthly average.
class CategoryAnalyticsCard extends StatelessWidget {
  const CategoryAnalyticsCard({
    super.key,
    required this.analytics,
    this.onRangeTap,
    this.rangeLabel,
  });

  final CategoryAnalytics analytics;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    return StatCard(
      title: 'Category Analytics',
      icon: Icons.category_rounded,
      subtitle: rangeLabel,
      child: analytics.categories.isEmpty
          ? const SizedBox(
              height: 90,
              child: Center(child: Text('No spending data available')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryLine(stats: analytics.categories, type: 'Expense'),
                const SizedBox(height: 12),
                for (final c in analytics.categories)
                  _CategoryRow(stat: c),
              ],
            ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.stats, required this.type});

  final List<dynamic> stats;
  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = stats.fold<double>(
      0,
      (s, c) => s + (c as dynamic).amount,
    );
    return Text(
      '${stats.length} $type ${stats.length == 1 ? 'category' : 'categories'}'
      ' · ${formatCurrencyNoCents(total)} total',
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.stat});

  final dynamic stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = stat.name as String;
    final amount = stat.amount as double;
    final percent = stat.percent as double;
    final avg = stat.avg as double;
    final max = stat.max as double;
    final perDay = stat.perDay as double;
    final monthlyAvg = stat.monthlyAvg as double;
    final count = stat.count as int;
    final color = stat.color as Color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatCurrencyNoCents(amount),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${percent.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _MiniStat(label: 'Avg', value: formatCurrencyNoCents(avg)),
              _MiniStat(label: 'Max', value: formatCurrencyNoCents(max)),
              _MiniStat(label: 'Count', value: '$count'),
              _MiniStat(label: 'Per day', value: formatCurrencyNoCents(perDay)),
              _MiniStat(label: 'Monthly', value: formatCurrencyNoCents(monthlyAvg)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '$label· $value',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}