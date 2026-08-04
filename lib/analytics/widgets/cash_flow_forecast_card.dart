import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/stat_line_chart.dart';
import '../models/stat_models.dart';
import 'stat_card.dart';

/// Card 19: Cash Flow Forecast — line with a marked forecast tail.
class CashFlowForecastCard extends StatelessWidget {
  const CashFlowForecastCard({
    super.key,
    required this.points,
    this.onRangeTap,
    this.rangeLabel,
  });

  final List<ForecastPoint> points;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actual = points.where((p) => !p.forecast).toList();
    final forecast = points.where((p) => p.forecast).toList();

    final maxY = points.isEmpty
        ? 1.0
        : points.map((p) => p.value.abs()).fold<double>(0, (m, v) => v > m ? v : m);
    final minValue = points.isEmpty
        ? 0.0
        : points.map((p) => p.value).fold<double>(0, (m, v) => v < m ? v : m);
    final hasNegative = minValue < 0;

    return StatCard(
      title: 'Cash Flow Forecast',
      icon: Icons.follow_the_signs_rounded,
      subtitle: rangeLabel,
      child: points.isEmpty
          ? const SizedBox(
              height: 120,
              child: Center(child: Text('No data to forecast')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projected daily net over the next ${forecast.length} days',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                StatLineChart(
                  series: [
                    actual.map((p) => SeriesPoint(x: p.x, y: p.value)).toList(),
                    forecast.map((p) => SeriesPoint(x: p.x, y: p.value)).toList(),
                  ],
                  seriesColors: const [
                    Color(0xFFF59E0B),
                    Color(0xFF94A3B8),
                  ],
                  showTooltip: true,
                  tooltipBuilder: (point, index) =>
                      '${index == 1 ? 'Fcst ' : ''}${formatCurrencyNoCents(point.y)}',
                  maxY: maxY * 1.2,
                  minY: hasNegative ? -maxY * 1.2 : null,
                  height: 160,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _LegendDot(color: const Color(0xFFF59E0B), label: 'Actual'),
                    const SizedBox(width: 16),
                    _LegendDot(color: const Color(0xFF94A3B8), label: 'Forecast'),
                  ],
                ),
              ],
            ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}