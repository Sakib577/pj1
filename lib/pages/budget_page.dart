import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../utils/currency_formatters.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key, required this.budgets});

  final List<BudgetCategory> budgets;

  @override
  Widget build(BuildContext context) {
    // Build totals from all category entries so summary stays in sync.
    final totalLimit = budgets.fold<double>(0, (sum, b) => sum + b.limit);
    final totalSpent = budgets.fold<double>(0, (sum, b) => sum + b.spent);
    final progress = totalLimit == 0 ? 0.0 : (totalSpent / totalLimit).clamp(0.0, 1.0);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BudgetSummaryCard(totalLimit: totalLimit, totalSpent: totalSpent, progress: progress),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Create New Budget tapped'), behavior: SnackBarBehavior.floating),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create New Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _BudgetSectionHeader(title: 'Categories', trailing: 'View All'),
            const SizedBox(height: 12),
            if (budgets.isEmpty)
              const _BudgetEmptyState()
            else
              for (final b in budgets) ...[
                _BudgetCategoryCard(item: b),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _BudgetEmptyState extends StatelessWidget {
  const _BudgetEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 34, color: Color(0xFFF59E0B)),
          SizedBox(height: 10),
          Text('No budgets yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('Create a budget to track category spending.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _BudgetSectionHeader extends StatelessWidget {
  const _BudgetSectionHeader({required this.title, this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        if (trailing != null)
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$trailing tapped'), behavior: SnackBarBehavior.floating),
              );
            },
            child: Text(trailing!, style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({required this.totalLimit, required this.totalSpent, required this.progress});

  final double totalLimit;
  final double totalSpent;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9F0A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x33F59E0B), blurRadius: 16, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Budget', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(formatCurrency(totalLimit), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spent: ${formatCurrency(totalSpent)}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              Text('${(progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFFBE6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  const _BudgetCategoryCard({required this.item});
  final BudgetCategory item;

  @override
  Widget build(BuildContext context) {
    // Per-category progress (spent / limit) for row indicator.
    final progress = (item.spent / item.limit).clamp(0.0, 1.0);
    final isNearLimit = progress >= 0.8;
    final statusText = isNearLimit ? 'Near limit' : 'Healthy';
    final statusColor = isNearLimit ? const Color(0xFFE36306) : const Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(item.icon, color: const Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                    Text('${item.daysLeft} days left', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  ],
                ),
              ),
              Text('${formatCurrency(item.spent)} / ${formatCurrency(item.limit)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).round()}% spent', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
            ),
          ),
        ],
      ),
    );
  }
}
