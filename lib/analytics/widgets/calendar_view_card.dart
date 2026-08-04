import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../charts/stat_calendar.dart';
import 'stat_card.dart';

/// Card 14: Calendar View — monthly grid of income/expense; tap a day for its
/// transactions.
class CalendarViewCard extends StatefulWidget {
  const CalendarViewCard({
    super.key,
    required this.transactions,
    this.onRangeTap,
    this.rangeLabel,
    this.onDayTap,
  });

  final List<TransactionItem> transactions;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;
  final void Function(DateTime day, List<TransactionItem> dayTxns)? onDayTap;

  @override
  State<CalendarViewCard> createState() => _CalendarViewCardState();
}

class _CalendarViewCardState extends State<CalendarViewCard> {
  DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatCard(
      title: 'Calendar',
      icon: Icons.calendar_view_month_rounded,
      subtitle: widget.rangeLabel,
      trailing: widget.onRangeTap != null
          ? IconButton(
              onPressed: widget.onRangeTap,
              tooltip: 'Change range',
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1, 1),
                ),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous month',
              ),
              Text(
                '${_monthName(_month.month)} ${_month.year}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1, 1),
                ),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next month',
              ),
            ],
          ),
          StatCalendar(
            month: _month,
            transactions: widget.transactions,
            onDayTap: widget.onDayTap,
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[m - 1];
  }
}