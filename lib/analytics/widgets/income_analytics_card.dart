import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/stat_donut_chart.dart';
import '../models/analytics_models.dart';
import 'stat_card.dart';

/// Card 12: Income Analytics — income sources donut + trend + largest.
class IncomeAnalyticsCard extends StatelessWidget {
  const IncomeAnalyticsCard({
    super.key,
    required this.analytics,
    this.onRangeTap,
    this.rangeLabel,
  });

  final IncomeAnalytics analytics;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = analytics.total;

    final slices = [
      for (final c in analytics.categories)
        StatDonutSlice(
          label: c.name,
          amount: c.amount,
          color: c.color,
          icon: c.icon,
        ),
    ];

    return StatCard(
      title: 'Income Analytics',
      icon: Icons.trending_up_rounded,
      subtitle: rangeLabel,
      trailing: onRangeTap != null
          ? IconButton(
              onPressed: onRangeTap,
              tooltip: 'Change range',
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
            )
          : null,
      child: analytics.categories.isEmpty
          ? const SizedBox(
              height: 110,
              child: Center(child: Text('No income in this period')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total income: ${formatCurrencyNoCents(total)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(height: 12),
                StatDonutChart(
                  slices: slices,
                  height: 150,
                  radius: 42,
                  centerLabel: 'Total',
                  centerSubtitle: formatCurrencyNoCents(total),
                  legendBuilder: (slice) => Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: slice.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          slice.label,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formatCurrencyNoCents(slice.amount),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (analytics.largest != null) ...[
                  const Divider(height: 24),
                  Text(
                    'Largest income',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        analytics.largest!.icon,
                        size: 18,
                        color: analytics.largest!.iconColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          analytics.largest!.title,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        formatCurrencyNoCents(analytics.largest!.amount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}