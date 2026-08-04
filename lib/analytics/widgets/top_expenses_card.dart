import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../models/stat_models.dart';
import 'stat_card.dart';

/// Card 6: Top Expenses — ordered list of the largest expenses, tappable.
class TopExpensesCard extends StatelessWidget {
  const TopExpensesCard({
    super.key,
    required this.expenses,
    this.onRangeTap,
    this.rangeLabel,
    this.onTapExpense,
  });

  final List<TopExpense> expenses;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;
  final void Function(TopExpense expense)? onTapExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatCard(
      title: 'Top Expenses',
      icon: Icons.local_fire_department_rounded,
      subtitle: rangeLabel,
      trailing: onRangeTap != null
          ? IconButton(
              onPressed: onRangeTap,
              tooltip: 'Change range',
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
            )
          : null,
      child: expenses.isEmpty
          ? const SizedBox(
              height: 90,
              child: Center(child: Text('No expenses in this period')),
            )
          : Column(
              children: [
                for (var i = 0; i < expenses.length; i++) ...[
                  _ExpenseRow(
                    rank: i + 1,
                    expense: expenses[i],
                    onTap: () => onTapExpense?.call(expenses[i]),
                  ),
                  if (i != expenses.length - 1)
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                ],
              ],
            ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.rank,
    required this.expense,
    required this.onTap,
  });

  final int rank;
  final TopExpense expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txn = expense.txn;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: txn.iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(txn.icon, size: 14, color: txn.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (txn.subtitle.isNotEmpty)
                    Text(
                      txn.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatCurrencyNoCents(txn.amount),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: txn.iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}