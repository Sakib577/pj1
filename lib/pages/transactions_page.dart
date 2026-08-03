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
  final _searchController = TextEditingController();
  String? _categoryFilter;
  DateTimeRange? _dateRange;
  int _visibleCount = 100;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
    );
    if (picked != null && mounted) {
      setState(() {
        _dateRange = picked;
        _visibleCount = 100;
      });
    }
  }

  Future<void> _pickCategory() async {
    final categories = FinanceAppScope.of(context)
        .transactions
        .map((item) => item.categoryName)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('All categories'),
              onTap: () => Navigator.pop(sheetContext, ''),
            ),
            for (final category in categories)
              ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(category),
                onTap: () => Navigator.pop(sheetContext, category),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _categoryFilter = selected.isEmpty ? null : selected;
        _visibleCount = 100;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = FinanceAppScope.of(context);
    final all = state.transactions;
    var transactions = switch (_filterIndex) {
      1 => all.where((item) => !item.negative).toList(),
      2 => all.where((item) => item.negative).toList(),
      _ => all,
    };
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      transactions = transactions
          .where(
            (item) =>
                item.title.toLowerCase().contains(query) ||
                item.categoryName.toLowerCase().contains(query) ||
                (item.note?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }
    if (_categoryFilter != null) {
      transactions = transactions
          .where((item) => item.categoryName == _categoryFilter)
          .toList();
    }
    if (_dateRange != null) {
      transactions = transactions.where((item) {
        final date = item.createdAt;
        if (date == null) return false;
        final day = DateTime(date.year, date.month, date.day);
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
        );
        return !day.isBefore(start) && !day.isAfter(end);
      }).toList();
    }
    final hasMore = transactions.length > _visibleCount;
    final visibleTransactions = transactions.take(_visibleCount).toList();

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
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() => _visibleCount = 100),
                  decoration: InputDecoration(
                    hintText: 'Search transactions',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Date range',
                      icon: Icon(
                        Icons.date_range_outlined,
                        color: _dateRange == null
                            ? const Color(0xFF64748B)
                            : const Color(0xFFF59E0B),
                      ),
                      onPressed: _pickDateRange,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
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
                      const SizedBox(width: 8),
                      _CategoryFilterButton(
                        selected: _categoryFilter != null,
                        onPressed: _pickCategory,
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          Expanded(
            child: visibleTransactions.isEmpty
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
                      for (final item in visibleTransactions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TransactionTile(
                            item: item,
                            onTap: () => showTransactionActions(context, item),
                          ),
                        ),
                      if (hasMore)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _visibleCount += 100),
                            icon: const Icon(Icons.expand_more),
                            label: Text('Load older (${transactions.length - _visibleCount} remaining)'),
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

class _CategoryFilterButton extends StatelessWidget {
  const _CategoryFilterButton({required this.selected, required this.onPressed});
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Filter by category',
      onPressed: onPressed,
      icon: Icon(
        Icons.filter_list,
        color: selected ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
      ),
    );
  }
}
