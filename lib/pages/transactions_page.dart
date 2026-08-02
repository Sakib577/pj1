import 'package:flutter/material.dart';

import '../state/finance_app_state.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/transaction_actions.dart';
import '../widgets/transaction_tile.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  // 0 = All, 1 = Income, 2 = Expenses
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = FinanceAppScope.of(context);
    final all = state.transactions;
    final transactions = switch (_filterIndex) {
      1 => all.where((item) => !item.negative).toList(),
      2 => all.where((item) => item.negative).toList(),
      _ => all,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recent Transactions',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
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
                    child: _FilterButton(
                      label: 'All',
                      selected: _filterIndex == 0,
                      onTap: () => setState(() => _filterIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterButton(
                      label: 'Income',
                      selected: _filterIndex == 1,
                      onTap: () => setState(() => _filterIndex = 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterButton(
                      label: 'Expenses',
                      selected: _filterIndex == 2,
                      onTap: () => setState(() => _filterIndex = 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: EmptyStateCard(
                      title: 'No transactions yet',
                      subtitle:
                          'Add your first transaction to start tracking.',
                      icon: Icons.receipt_long,
                    ),
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      for (final item in transactions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TransactionTile(
                            item: item,
                            onTap: () => showTransactionActions(context, item),
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({
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
