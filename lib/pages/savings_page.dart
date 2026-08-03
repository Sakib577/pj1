import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../state/finance_app_state.dart';
import '../utils/currency_formatters.dart';
import '../utils/currency_settings.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key, required this.overview, required this.goals});

  final SavingsOverview overview;
  final List<SavingsGoal> goals;

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SavingsProgressCard(overview: widget.overview),
            const SizedBox(height: 14),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF2F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(child: _SavingsSectionButton(label: 'Active Goals', selected: !_showCompleted, onTap: () => setState(() => _showCompleted = false))),
                  Expanded(child: _SavingsSectionButton(label: 'Completed Goals', selected: _showCompleted, onTap: () => setState(() => _showCompleted = true))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_visibleGoals.isEmpty)
              const _SavingsEmptyState()
            else
              for (final goal in _visibleGoals) ...[
                _SavingsGoalCard(
                  goal: goal,
                  onTap: () => _showActions(context, goal),
                  onAddFunds: () => _addFunds(context, goal),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<SavingsGoal> get _visibleGoals => widget.goals
      .where((goal) => (goal.current >= goal.target) == _showCompleted)
      .toList();

  Future<void> _addFunds(BuildContext context, SavingsGoal goal) async {
    final amount = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add to ${goal.title}'),
        content: TextField(
          controller: amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final value = double.tryParse(amount.text.trim()) ?? 0;
    if (saved == true && value > 0 && context.mounted) {
      FinanceAppScope.of(context).addSavingsContribution(goal.id, value);
    }
    amount.dispose();
  }

  Future<void> _showActions(BuildContext context, SavingsGoal goal) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit goal'),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Withdraw funds'),
              onTap: () => Navigator.pop(sheetContext, 'withdraw'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(0xFFDC2626),
              ),
              title: const Text(
                'Delete goal',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'withdraw' && context.mounted) {
      final amount = TextEditingController();
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Withdraw from ${goal.title}'),
          content: TextField(
            controller: amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (max ${formatCurrencyNoCents(goal.current)})',
              prefixText: '${CurrencySettings.symbol} ',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Withdraw')),
          ],
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final value = double.tryParse(amount.text.trim()) ?? 0;
      if (saved == true && value > 0 && value <= CurrencySettings.fromUsd(goal.current) && context.mounted) {
        FinanceAppScope.of(context).withdrawSavingsContribution(goal.id, value);
      }
      amount.dispose();
      return;
    }
    if (choice == 'edit' && context.mounted) {
      final title = TextEditingController(text: goal.title);
      final target = TextEditingController(
        text: CurrencySettings.fromUsd(goal.target).toStringAsFixed(2),
      );
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Edit savings goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Goal name'),
              ),
              TextField(
                controller: target,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Target amount'),
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
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final amount = double.tryParse(target.text.trim()) ?? 0;
      if (saved == true &&
          title.text.trim().isNotEmpty &&
          amount > 0 &&
          context.mounted) {
        FinanceAppScope.of(context).updateSavingsGoal(
          goal.copyWith(
            title: title.text.trim(),
            target: CurrencySettings.toUsd(amount),
          ),
        );
      }
      title.dispose();
      target.dispose();
      return;
    }
    if (choice == 'delete' && context.mounted) {
      FinanceAppScope.of(context).deleteSavingsGoal(goal.id);
    }
  }
}

Future<void> showCreateSavingsGoalDialog(BuildContext context) async {
  final title = TextEditingController();
  final target = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Create savings goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Goal name'),
          ),
          TextField(
            controller: target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Target amount'),
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
  );
  await Future<void>.delayed(const Duration(milliseconds: 300));
  final amount = double.tryParse(target.text.trim()) ?? 0;
  if (saved == true && title.text.trim().isNotEmpty && amount > 0 && context.mounted) {
    FinanceAppScope.of(context).addSavingsGoal(title.text.trim(), amount);
  }
  title.dispose();
  target.dispose();
}

class _SavingsEmptyState extends StatelessWidget {
  const _SavingsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.savings_outlined, size: 34, color: Color(0xFFF59E0B)),
          SizedBox(height: 10),
          Text(
            'No savings goals yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'Create goals to start saving toward targets.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SavingsSectionButton extends StatelessWidget {
  const _SavingsSectionButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? const Color(0xFFB45309) : const Color(0xFF64748B))),
        ),
      ),
    );
  }
}

class _SavingsProgressCard extends StatelessWidget {
  const _SavingsProgressCard({required this.overview});

  final SavingsOverview overview;

  @override
  Widget build(BuildContext context) {
    // Top orange card showing total savings and monthly progress.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9F0A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F59E0B),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Savings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrencyNoCents(overview.totalSavings),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Progress',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(overview.progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: overview.progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFFBE6)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            overview.message,
            style: const TextStyle(fontSize: 15, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SavingsGoalCard extends StatelessWidget {
  const _SavingsGoalCard({
    required this.goal,
    required this.onTap,
    required this.onAddFunds,
  });

  final SavingsGoal goal;
  final VoidCallback onTap;
  final VoidCallback onAddFunds;

  @override
  Widget build(BuildContext context) {
    // Guard target=0 to avoid divide-by-zero while calculating progress.
    final progress = goal.target == 0
        ? 0.0
        : (goal.current / goal.target).clamp(0.0, 1.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: goal.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(goal.icon, color: goal.iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Goal title uses a strong dark color for emphasis and legibility
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${formatCurrencyNoCents(goal.current)} / ${formatCurrencyNoCents(goal.target)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                TextButton.icon(
                  onPressed: onAddFunds,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add funds'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
