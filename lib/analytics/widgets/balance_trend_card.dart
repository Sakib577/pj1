import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/stat_line_chart.dart';
import '../models/stat_models.dart';
import 'stat_card.dart';

/// Card 1: Balance Trend — filled line area + current/previous/growth %.
class BalanceTrendCard extends StatelessWidget {
  const BalanceTrendCard({
    super.key,
    required this.trend,
    this.onRangeTap,
    this.rangeLabel,
  });

  final TrendSeries trend;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = trend.points;

    return StatCard(
      title: 'Balance Trend',
      icon: Icons.trending_up_rounded,
      subtitle: rangeLabel,
      trailing: onRangeTap != null
          ? IconButton(
              onPressed: onRangeTap,
              tooltip: 'Change range',
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
            )
          : null,
      child: points.isEmpty
          ? const SizedBox(
              height: 90,
              child: Center(child: Text('No transactions in this period')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatCurrencyNoCents(trend.current),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                _DeltaChip(
                  delta: trend.deltaPercent,
                  positiveLabel: 'up from previous',
                  negativeLabel: 'down from previous',
                  flatLabel: 'same as previous',
                ),
                const SizedBox(height: 14),
                StatLineChart(
                  series: [points],
                  isFilled: true,
                  height: 160,
                  showTooltip: true,
                  tooltipBuilder: (point, _) =>
                      formatCurrencyNoCents(point.y),
                ),
              ],
            ),
    );
  }
}

/// A small "▲ x% vs previous" chip used across trend cards.
class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.delta,
    required this.positiveLabel,
    required this.negativeLabel,
    required this.flatLabel,
  });

  final double delta;
  final String positiveLabel;
  final String negativeLabel;
  final String flatLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUp = delta > 0;
    final color = isUp
        ? const Color(0xFF16A34A)
        : delta < 0
        ? const Color(0xFFDC2626)
        : theme.colorScheme.onSurfaceVariant;
    final icon = isUp
        ? Icons.arrow_upward_rounded
        : delta < 0
        ? Icons.arrow_downward_rounded
        : Icons.remove_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 3),
        Text(
          '${isUp ? '+' : ''}${delta.toStringAsFixed(1)}% '
          '${delta > 0 ? positiveLabel : delta < 0 ? negativeLabel : flatLabel}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}