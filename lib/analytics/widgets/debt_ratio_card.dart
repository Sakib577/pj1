import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/stat_circular_gauge.dart';
import '../models/stat_models.dart';
import 'stat_card.dart';

/// Card 7: Debt-to-Income ratio — circular gauge with green/orange/red zones.
class DebtRatioCard extends StatelessWidget {
  const DebtRatioCard({
    super.key,
    required this.gauge,
    this.onRangeTap,
    this.rangeLabel,
  });

  final GaugeResult gauge;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overallRatio = (gauge.ratio / 3).clamp(0.0, 1.0);
    final (levelColor, levelLabel) = switch (gauge.level) {
      HealthLevel.good => (const Color(0xFF16A34A), 'Healthy'),
      HealthLevel.moderate => (const Color(0xFFD97706), 'Moderate'),
      HealthLevel.poor => (const Color(0xFFDC2626), 'High'),
    };

    return StatCard(
      title: 'Debt-to-Income Ratio',
      icon: Icons.percent_rounded,
      subtitle: rangeLabel,
      child: Row(
        children: [
          StatCircularGauge(
            ratio: overallRatio,
            size: 120,
            centerLabel: '${(gauge.ratio * 100).toStringAsFixed(0)}%',
            centerSubtitle: 'DTI',
            lowColor: const Color(0xFF22C55E),
            midColor: const Color(0xFFF59E0B),
            highColor: const Color(0xFFEF4444),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: levelColor),
                    const SizedBox(width: 6),
                    Text(
                      levelLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: levelColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Total debt: ${formatCurrencyNoCents(gauge.value)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A healthy DTI is below 36%.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}