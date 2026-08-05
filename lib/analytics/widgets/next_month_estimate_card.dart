import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/stat_bar_chart.dart';
import '../models/analytics_models.dart';
import 'stat_card.dart';

/// Card 11: Estimated next month's expense — the projected total shown against
/// recent months of actual spending, with a breakdown of the recurring
/// scheduled bills vs. the variable-spending baseline it was built from.
class NextMonthEstimateCard extends StatelessWidget {
  const NextMonthEstimateCard({
    super.key,
    required this.estimate,
  });

  final NextMonthEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = estimate.total;
    final scheduled = estimate.scheduledBills;
    final variable = estimate.variableBaseline;

    return StatCard(
      title: 'Estimated Next Month\'s Expense',
      icon: Icons.calculate_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCurrencyNoCents(total),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bills due next month + ${estimate.basisLabel.isEmpty ? 'recent spending' : estimate.basisLabel}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_repeat_rounded,
                      size: 14,
                      color: Color(0xFFF59E0B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Projected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: StatBarChart(
              groups: [
                for (final point in estimate.history)
                  StatBarGroup(
                    label: point.label,
                    rods: [
                      StatBarRod(
                        value: point.amount,
                        color: point.isEstimate
                            ? const Color(0xFFF59E0B)
                            : theme.colorScheme.primary
                                .withValues(alpha: 0.35),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _BreakdownRow(
            label: 'Scheduled bills',
            amount: scheduled,
            color: const Color(0xFFF59E0B),
            icon: Icons.event_repeat_rounded,
          ),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: 'Recent spending',
            amount: variable,
            color: theme.colorScheme.primary,
            icon: Icons.receipt_long_rounded,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          formatCurrencyNoCents(amount),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
