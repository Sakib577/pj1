import 'package:flutter/material.dart';

import '../models/analytics_models.dart';
import 'stat_card.dart';

/// Card 10: Financial Health — indicator chips for several health metrics.
class FinancialHealthCard extends StatelessWidget {
  const FinancialHealthCard({
    super.key,
    required this.metrics,
    this.onRangeTap,
    this.rangeLabel,
  });

  final List<FinancialHealthMetric> metrics;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overall = metrics.isEmpty
        ? 0.0
        : metrics.fold<double>(0, (s, m) => s + m.value) / metrics.length;

    return StatCard(
      title: 'Financial Health',
      icon: Icons.favorite_rounded,
      subtitle: rangeLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: overall,
                        strokeWidth: 8,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: _scoreColor(overall),
                      ),
                    ),
                    Text(
                      (overall * 100).toStringAsFixed(0),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _scoreLabel(overall),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _scoreColor(overall),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on ${metrics.length} key metrics',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metric in metrics)
                _HealthChip(metric: metric),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double value) {
    if (value >= 0.66) return const Color(0xFF16A34A);
    if (value >= 0.33) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  String _scoreLabel(double value) {
    if (value >= 0.66) return 'Healthy';
    if (value >= 0.33) return 'Fair';
    return 'Needs attention';
  }
}

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.metric});

  final FinancialHealthMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = metric.value >= 0.66
        ? const Color(0xFF16A34A)
        : metric.value >= 0.33
        ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.message,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}