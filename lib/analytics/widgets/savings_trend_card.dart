import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/stat_line_chart.dart';
import '../models/stat_models.dart';
import 'stat_card.dart';

/// Card 18: Savings Trend — monthly savings line with goal marker.
class SavingsTrendCard extends StatelessWidget {
  const SavingsTrendCard({
    super.key,
    required this.series,
    this.goalTarget,
    this.onRangeTap,
    this.rangeLabel,
  });

  final List<TrendSeries> series;
  final double? goalTarget;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = series.isEmpty ? <SeriesPoint>[] : series.first.points;
    final current = series.isEmpty
        ? 0.0
        : series.first.current;

    final values = <double>[
      ...points.map((p) => p.y),
      ?goalTarget,
    ];
    final maxY = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);

    return StatCard(
      title: 'Savings Trend',
      icon: Icons.savings_outlined,
      subtitle: rangeLabel,
      child: points.isEmpty
          ? const SizedBox(
              height: 110,
              child: Center(child: Text('No savings in this period')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatCurrencyNoCents(current),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  goalTarget != null
                      ? '${(current / goalTarget! * 100).clamp(0, 999).toStringAsFixed(0)}% of goal'
                      : 'Saved this period',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                StatLineChart(
                  series: [points],
                  isFilled: true,
                  showTooltip: true,
                  tooltipBuilder: (point, _) => formatCurrencyNoCents(point.y),
                  maxY: maxY * 1.2,
                  height: 160,
                ),
              ],
            ),
    );
  }
}