import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../state/finance_app_state.dart';
import '../utils/currency_settings.dart';

/// Shows a bottom sheet for a transaction with Edit and Delete actions. Shared
/// by the dashboard "Recent Transactions" list and the Recent Transactions page
/// so both behave identically.
Future<void> showTransactionActions(
  BuildContext context,
  TransactionItem item,
) async {
  final state = FinanceAppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Color(0xFFF59E0B)),
            title: const Text(
              'Edit transaction',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onTap: () => Navigator.pop(sheetContext, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            title: const Text(
              'Delete transaction',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
            onTap: () => Navigator.pop(sheetContext, 'delete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;

  if (choice == 'delete') {
    final confirmed = await _confirmDeleteTransaction(context, item);
    if (confirmed == true && context.mounted) {
      state.deleteTransaction(item.id!);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }

  final updated = await promptEditTransaction(context, item);
  if (updated != null && context.mounted) {
    state.updateTransaction(updated);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Transaction updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<bool?> _confirmDeleteTransaction(
  BuildContext context,
  TransactionItem item,
) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete transaction?'),
      content: Text('${item.title} will be removed and the balance updated.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

/// Shows the inline "Edit transaction" dialog (amount, income/expense, note).
/// Returns the updated [TransactionItem], or null when cancelled.
Future<TransactionItem?> promptEditTransaction(
  BuildContext context,
  TransactionItem item,
) async {
  final controller = TextEditingController(
    text: CurrencySettings.fromUsd(
      item.amount,
    ).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''),
  );
  final noteController = TextEditingController(text: item.note ?? '');
  var isIncome = !item.negative;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          title: const Text('Edit transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF2F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _EditSegment(
                          label: 'Income',
                          selected: isIncome,
                          onTap: () => setDialogState(() => isIncome = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _EditSegment(
                          label: 'Expense',
                          selected: !isIncome,
                          onTap: () => setDialogState(() => isIncome = false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '${CurrencySettings.symbol} ',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );

  await Future<void>.delayed(const Duration(milliseconds: 300));

  if (saved != true) {
    controller.dispose();
    noteController.dispose();
    return null;
  }
  final parsed = double.tryParse(controller.text.trim()) ?? 0;
  if (parsed <= 0) {
    controller.dispose();
    noteController.dispose();
    return null;
  }

  final amountUsd = CurrencySettings.toUsd(parsed.abs());
  final note = noteController.text.trim();
  controller.dispose();
  noteController.dispose();
  final now = item.createdAt ?? DateTime.now();
  return TransactionItem(
    id: item.id,
    title: item.title,
    subtitle: _editSubtitle(now, note.isEmpty ? null : note),
    amount: amountUsd,
    icon: item.icon,
    iconColor: item.iconColor,
    categoryName: item.categoryName,
    note: note.isEmpty ? null : note,
    negative: !isIncome,
    createdAt: now,
  );
}

/// Shows a bottom sheet for a planned payment with "Confirm & record" and
/// "Delete" actions. Shared by the dashboard and the planned payments page.
Future<void> showPlannedPaymentActions(
  BuildContext context,
  PlannedPayment payment,
) async {
  final state = FinanceAppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFFF59E0B),
            ),
            title: const Text(
              'Confirm & record',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onTap: () => Navigator.pop(sheetContext, 'confirm'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Color(0xFFF59E0B)),
            title: const Text(
              'Edit payment',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onTap: () => Navigator.pop(sheetContext, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            title: const Text(
              'Delete payment',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
            onTap: () => Navigator.pop(sheetContext, 'delete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;

  if (choice == 'confirm') {
    state.confirmPlannedPayment(payment.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          payment.isIncome ? 'Recorded as income' : 'Recorded as expense',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  if (choice == 'edit') {
    final title = TextEditingController(text: payment.title);
    final amount = TextEditingController(
      text: CurrencySettings.fromUsd(payment.amount).toStringAsFixed(2),
    );
    var startDate = payment.startDate;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit planned payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(
                  '${startDate.day}/${startDate.month}/${startDate.year}',
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: startDate,
                  );
                  if (picked != null) setDialogState(() => startDate = picked);
                },
              ),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${CurrencySettings.symbol} ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final value = double.tryParse(amount.text.trim()) ?? 0;
    if (saved == true &&
        value > 0 &&
        title.text.trim().isNotEmpty &&
        context.mounted) {
      state.updatePlannedPayment(
        payment.copyWith(
          title: title.text.trim(),
          amount: CurrencySettings.toUsd(value),
          startDate: startDate,
        ),
      );
    }
    title.dispose();
    amount.dispose();
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete planned payment?'),
      content: Text('${payment.title} will be removed from your schedule.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    state.removePlannedPayment(payment.id);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Planned payment deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _EditSegment extends StatelessWidget {
  const _EditSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

String _editSubtitle(DateTime date, String? note) {
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
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  final base = '${months[date.month - 1]} ${date.day}, $hour:$minute $period';
  return note == null ? base : '$base · $note';
}
