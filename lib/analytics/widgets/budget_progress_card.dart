import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../models/analytics_models.dart';
import 'stat_card.dart';

/// Card 17: Budget Progress — circular gauge per budget + progress bars +
/// remaining, with color shifting green→yellow→red.
class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.progress,
    this.onRangeTap,
    this.rangeLabel,
  });

  final List<BudgetProgress> progress;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatCard(
      title: 'Budget Progress',
      icon: Icons.savings_outlined,
      subtitle: rangeLabel,
      child: progress.isEmpty
          ? const SizedBox(
              height: 110,
              child: Center(
                child: Text(
                  'No budgets set yet.\nAdd a budget to track progress.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < progress.length; i++) ...[
                  _BudgetRow(entry: progress[i]),
                  if (i != progress.length - 1)
                    Divider(
                      height: 24,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                ],
              ],
            ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.entry});

  final BudgetProgress entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = entry.ratio.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.budget.label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: entry.statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.status,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: entry.statusColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            color: entry.statusColor,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${formatCurrencyNoCents(entry.spent)} spent',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${formatCurrencyNoCents(entry.remaining)} remaining',
              style: theme.textTheme.labelSmall?.copyWith(
                color: entry.statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}