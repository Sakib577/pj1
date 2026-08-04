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

    final values = <double>[...points.map((p) => p.y)];
    final dataMax = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = dataMax == 0 ? 1.0 : dataMax * 1.2;

    // Draw the goal as a subtle horizontal marker, but only when it is close
    // enough to the actual data that it can be seen. A distant goal (e.g. 7
    // lakh when savings are a few thousand) must not stretch the whole axis.
    final goalLine = goalTarget != null && goalTarget! <= maxY
        ? [
            SeriesPoint(x: points.first.x, y: goalTarget!),
            SeriesPoint(x: points.last.x, y: goalTarget!),
          ]
        : null;

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
                  series: [
                    points,
                    ?goalLine,
                  ].whereType<List<SeriesPoint>>().toList(),
                  seriesColors: const [
                    Color(0xFF22C55E),
                    Color(0xFF94A3B8),
                  ],
                  isFilled: true,
                  showTooltip: true,
                  tooltipBuilder: (point, _) => formatCurrencyNoCents(point.y),
                  maxY: maxY,
                  height: 160,
                ),
              ],
            ),
    );
  }
}