import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../state/finance_app_state.dart';
import '../utils/currency_formatters.dart';
import '../utils/currency_settings.dart';
import '../widgets/empty_state_card.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  // 0 = Active, 1 = Closed
  int _statusIndex = 0;

  Future<void> _openAddPage() async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddDebtPage()),
    );
    if (added == true && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Debt added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(DebtItem debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete debt?'),
        content: Text('The ${debt.type.label.toLowerCase()} record with '
            '${debt.person} will be removed.'),
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
    if (confirmed == true && mounted) {
      FinanceAppScope.of(context).deleteDebt(debt.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = FinanceAppScope.of(context).debts
        .where((debt) => debt.isClosed == (_statusIndex == 1))
        .toList();
    final borrowed = all.where((debt) => debt.type == DebtType.borrowed).toList();
    final lent = all.where((debt) => debt.type == DebtType.lent).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Debts',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPage,
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Debt'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF2F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Active',
                      selected: _statusIndex == 0,
                      onTap: () => setState(() => _statusIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Closed',
                      selected: _statusIndex == 1,
                      onTap: () => setState(() => _statusIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: all.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: EmptyStateCard(
                      title: _statusIndex == 0
                          ? 'No active debts'
                          : 'No closed debts',
                      subtitle: _statusIndex == 0
                          ? 'Add money you borrowed or lent to track it here.'
                          : 'Close, forgive, or repay an active debt to move it here.',
                      icon: _statusIndex == 0
                          ? Icons.handshake_outlined
                          : Icons.task_alt,
                    ),
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                    children: [
                      _SectionLabel(title: 'Borrowed'),
                      const SizedBox(height: 8),
                      if (borrowed.isEmpty)
                        const _EmptySubsection(label: 'No borrowed debts here')
                      else
                        for (final debt in borrowed) ...[
                          _DebtCard(
                            debt: debt,
                            onDelete: () => _confirmDelete(debt),
                          ),
                          const SizedBox(height: 12),
                        ],
                      const SizedBox(height: 8),
                      _SectionLabel(title: 'Lent'),
                      const SizedBox(height: 8),
                      if (lent.isEmpty)
                        const _EmptySubsection(label: 'No lent debts here')
                      else
                        for (final debt in lent) ...[
                          _DebtCard(
                            debt: debt,
                            onDelete: () => _confirmDelete(debt),
                          ),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class AddDebtPage extends StatefulWidget {
  const AddDebtPage({super.key});

  @override
  State<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends State<AddDebtPage> {
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DebtType _type = DebtType.borrowed;

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onSave() {
    final person = _personController.text.trim();
    if (person.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter who this debt is with'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final note = _noteController.text.trim();
    FinanceAppScope.of(context).addDebt(
      DebtItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        person: person,
        amount: CurrencySettings.toUsd(amount.abs()),
        type: _type,
        note: note.isEmpty ? null : note,
        createdAt: DateTime.now(),
      ),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New Debt',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: _SegmentButton(
                        label: 'Borrowed',
                        selected: _type == DebtType.borrowed,
                        onTap: () => setState(
                          () => _type = DebtType.borrowed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SegmentButton(
                        label: 'Lent',
                        selected: _type == DebtType.lent,
                        onTap: () => setState(() => _type = DebtType.lent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _type == DebtType.borrowed
                    ? 'I borrowed this from someone and need to pay it back.'
                    : 'I lent this to someone and expect it back.',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _personController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  labelText: _type == DebtType.borrowed
                      ? 'Borrowed from'
                      : 'Lent to',
                  hintText: _type == DebtType.borrowed
                      ? 'e.g. Alex'
                      : 'e.g. Sam',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  labelText: 'Amount',
                  hintText: '0',
                  prefixText: '${CurrencySettings.symbol} ',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Rent share for August',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onSave,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Save Debt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt, required this.onDelete});

  final DebtItem debt;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isBorrowed = debt.type == DebtType.borrowed;
    final color = isBorrowed
        ? const Color(0xFFF97316)
        : const Color(0xFF22C55E);
    final state = FinanceAppScope.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isBorrowed ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.person,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      debt.note == null
                          ? debt.type.label
                          : '${debt.type.label} · ${debt.note}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isBorrowed ? '-' : '+'}${formatCurrency(debt.amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
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
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (debt.settlement == DebtSettlement.active) ...[
                _DebtActionButton(
                  label: isBorrowed ? 'Close' : 'Forgive',
                  filled: true,
                  color: const Color(0xFFF59E0B),
                  onPressed: () => state.setDebtClosed(debt.id, true),
                ),
                const SizedBox(width: 8),
                _DebtActionButton(
                  label: 'Repaid',
                  filled: false,
                  color: const Color(0xFF22C55E),
                  onPressed: () => state.markDebtRepaid(debt.id),
                ),
              ] else ...[
                Text(
                  debt.isRepaid
                      ? 'Repaid'
                      : isBorrowed
                      ? 'Closed'
                      : 'Forgiven',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                _DebtActionButton(
                  label: 'Reopen',
                  filled: false,
                  color: const Color(0xFF6B7280),
                  onPressed: () => state.setDebtClosed(debt.id, false),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtActionButton extends StatelessWidget {
  const _DebtActionButton({
    required this.label,
    required this.filled,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          border: Border.all(
            color: filled ? color : color.withValues(alpha: 0.6),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    );
  }
}

class _EmptySubsection extends StatelessWidget {
  const _EmptySubsection({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
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
        padding: const EdgeInsets.symmetric(vertical: 12),
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
