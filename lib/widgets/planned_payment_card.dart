import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../utils/currency_formatters.dart';

class PlannedPaymentCard extends StatelessWidget {
  const PlannedPaymentCard({
    super.key,
    required this.payment,
    this.onDelete,
    this.onTap,
  });

  final PlannedPayment payment;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final due = payment.currentDue();
    final today = _dateOnly(DateTime.now());
    final dueText = switch (due.compareTo(today)) {
      < 0 => 'Overdue',
      0 => 'Due today',
      _ => 'Due ${_dateLabel(due)}',
    };
    final dueColor = due.isBefore(today)
        ? const Color(0xFFDC2626)
        : due.isAtSameMomentAs(today)
        ? const Color(0xFFF59E0B)
        : const Color(0xFF6B7280);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: payment.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: payment.emoji != null
                ? Text(payment.emoji!, style: const TextStyle(fontSize: 24))
                : Icon(payment.icon, color: payment.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        payment.repeat.label,
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dueText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: dueColor,
                          fontSize: 13,
                          fontWeight: due.isBefore(today)
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.isIncome ? '+' : '-'}${formatCurrency(payment.amount)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (payment.categoryName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    payment.categoryName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete_outline,
                color: Color(0xFFDC2626),
                size: 20,
              ),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
      ),
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
