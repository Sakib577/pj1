import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../utils/currency_formatters.dart';
import 'chart_theme.dart';

/// A full month calendar grid. Each day cell shows income (green) and expense
/// (orange) totals and reports taps via [onDayTap].
class StatCalendar extends StatelessWidget {
  const StatCalendar({
    super.key,
    required this.month,
    required this.transactions,
    this.onDayTap,
  });

  final DateTime month;

  /// All transactions in interest (filtered by the caller).
  final List<TransactionItem> transactions;
  final void Function(DateTime day, List<TransactionItem> dayTxns)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final theme = Theme.of(context);
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = firstOfMonth.weekday - DateTime.monday;

    // Build per-day maps.
    final incomeByDay = <String, double>{};
    final expenseByDay = <String, double>{};
    final txnsByDay = <String, List<TransactionItem>>{};
    for (final t in transactions) {
      final d = t.createdAt;
      if (d == null || d.month != month.month || d.year != month.year) continue;
      final key = '${d.year}-${d.month}-${d.day}';
      txnsByDay.putIfAbsent(key, () => []).add(t);
      if (t.negative) {
        expenseByDay[key] = (expenseByDay[key] ?? 0) + t.amount;
      } else {
        incomeByDay[key] = (incomeByDay[key] ?? 0) + t.amount;
      }
    }

    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.axisLabel,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: leading + daysInMonth,
          itemBuilder: (context, index) {
            final dayNum = index - leading + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const SizedBox.shrink();
            }
            final day = DateTime(month.year, month.month, dayNum);
            final key = '${day.year}-${day.month}-${day.day}';
            final income = incomeByDay[key] ?? 0;
            final expense = expenseByDay[key] ?? 0;
            final dayTxns = txnsByDay[key] ?? const [];

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onDayTap?.call(day, dayTxns),
              child: Container(
                decoration: BoxDecoration(
                  color: income > 0 || expense > 0
                      ? palette.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: income > 0 || expense > 0
                      ? Border.all(color: palette.grid.withValues(alpha: 0.5))
                      : null,
                ),
                padding: const EdgeInsets.all(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dayNum',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (expense > 0)
                      Text(
                        formatCurrencyNoCents(expense),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.expense,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (income > 0)
                      Text(
                        formatCurrencyNoCents(income),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.income,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}