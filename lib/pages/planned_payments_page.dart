import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../state/finance_app_state.dart';
import '../utils/currency_settings.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/planned_payment_card.dart';
import 'categories_page.dart';
import 'category_detail_page.dart';

class PlannedPaymentsPage extends StatefulWidget {
  const PlannedPaymentsPage({super.key});

  @override
  State<PlannedPaymentsPage> createState() => _PlannedPaymentsPageState();
}

class _PlannedPaymentsPageState extends State<PlannedPaymentsPage> {
  Future<void> _openAddPage() async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddPlannedPaymentPage()),
    );
    if (added == true && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Planned payment added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(PlannedPayment payment) async {
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
    if (confirmed == true && mounted) {
      FinanceAppScope.of(context).removePlannedPayment(payment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payments = FinanceAppScope.of(context).plannedPayments;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Planned Payments',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPage,
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add payment'),
      ),
      body: payments.isEmpty
          ? const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: EmptyStateCard(
                title: 'No planned payments yet',
                subtitle:
                    'Schedule a one-time or repeating payment to stay on top of bills.',
                icon: Icons.event_note_outlined,
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                for (final payment in payments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PlannedPaymentCard(
                      payment: payment,
                      onDelete: () => _confirmDelete(payment),
                    ),
                  ),
              ],
            ),
    );
  }
}

class AddPlannedPaymentPage extends StatefulWidget {
  const AddPlannedPaymentPage({super.key});

  @override
  State<AddPlannedPaymentPage> createState() => _AddPlannedPaymentPageState();
}

class _AddPlannedPaymentPageState extends State<AddPlannedPaymentPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customDaysController = TextEditingController(
    text: '7',
  );

  bool _isIncome = false;
  ExpenseCategory? _selectedCategory;
  String? _selectedSubcategory;
  RepeatFrequency _repeat = RepeatFrequency.monthly;
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickSubcategory(ExpenseCategory category) async {
    if (category.subcategories.isEmpty) {
      setState(() {
        _selectedCategory = category;
        _selectedSubcategory = null;
      });
      return;
    }
    final selection = await Navigator.of(context).push<CategorySelection>(
      MaterialPageRoute(builder: (_) => CategoryDetailPage(category: category)),
    );
    if (selection != null && mounted) {
      setState(() {
        _selectedCategory = selection.category;
        _selectedSubcategory = selection.subcategory;
      });
    }
  }

  Future<void> _openCategoriesPage() async {
    final appState = FinanceAppScope.of(context);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => CategoriesPage(isIncome: _isIncome)),
    );
    if (!mounted) return;
    final refreshed = _isIncome
        ? appState.incomeCategories
        : appState.expenseCategories;
    final selected = _selectedCategory;
    if (selected != null &&
        !refreshed.any((category) => category.id == selected.id)) {
      setState(() {
        _selectedCategory = null;
        _selectedSubcategory = null;
      });
    }
  }

  void _onSave() {
    final state = FinanceAppScope.of(context);
    final categories = _isIncome
        ? state.incomeCategories
        : state.expenseCategories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No categories available yet.'),
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

    var customDays = int.tryParse(_customDaysController.text.trim()) ?? 7;
    if (customDays < 1) customDays = 1;
    if (_repeat == RepeatFrequency.custom && customDays < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter how often it repeats (at least 1 day)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final category =
        _selectedCategory ??
        (_isIncome
            ? state.recentIncomeCategories.first
            : state.recentExpenseCategories.first);
    final defaultTitle = _selectedSubcategory == null
        ? category.name
        : '${category.name} · $_selectedSubcategory';
    final title = _titleController.text.trim().isEmpty
        ? defaultTitle
        : _titleController.text.trim();

    state.addPlannedPayment(
      PlannedPayment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        amount: CurrencySettings.toUsd(amount.abs()),
        icon: category.icon ?? Icons.category_rounded,
        iconColor: _isIncome
            ? const Color(0xFF22C55E)
            : const Color(0xFFF97316),
        categoryName: category.name,
        emoji: category.isUserDefined ? category.emoji : null,
        subcategory: _selectedSubcategory,
        isIncome: _isIncome,
        repeat: _repeat,
        customEveryDays: customDays,
        startDate: _startDate,
        createdAt: DateTime.now(),
      ),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final appState = FinanceAppScope.of(context);
    final categories = _isIncome
        ? appState.incomeCategories
        : appState.expenseCategories;
    final currentCategory =
        _selectedCategory ?? categories.firstOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New Planned Payment',
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
                        label: 'Expense',
                        selected: !_isIncome,
                        onTap: () => setState(() {
                          _isIncome = false;
                          _selectedCategory = null;
                          _selectedSubcategory = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SegmentButton(
                        label: 'Income',
                        selected: _isIncome,
                        onTap: () => setState(() {
                          _isIncome = true;
                          _selectedCategory = null;
                          _selectedSubcategory = null;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == categories.length) {
                      return SizedBox(
                        width: 96,
                        child: _AddCategoryShortcut(
                          onTap: _openCategoriesPage,
                        ),
                      );
                    }
                    final category = categories[index];
                    return SizedBox(
                      width: 96,
                      child: _CategoryShortcut(
                        category: category,
                        selected: currentCategory?.id == category.id,
                        onTap: () => _pickSubcategory(category),
                      ),
                    );
                  },
                ),
              ),
              if (_selectedSubcategory != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${currentCategory?.name} · $_selectedSubcategory',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'e.g. Electricity bill',
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
              const SizedBox(height: 20),
              const Text(
                'Repeat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final frequency in RepeatFrequency.values)
                    _RepeatChip(
                      label: frequency.label,
                      selected: _repeat == frequency,
                      onTap: () => setState(() => _repeat = frequency),
                    ),
                ],
              ),
              if (_repeat == RepeatFrequency.custom) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customDaysController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    labelText: 'Repeat every',
                    hintText: '7',
                    suffixText: 'days',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Start date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.event_outlined,
                    color: Color(0xFFF59E0B),
                  ),
                  title: Text(_formatDate(_startDate)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onSave,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Save Planned Payment'),
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
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  static String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

class _RepeatChip extends StatelessWidget {
  const _RepeatChip({
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
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF59E0B) : Colors.white,
          border: Border.all(
            color: selected
                ? const Color(0xFFF59E0B)
                : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4E8) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            category.isUserDefined
                ? Text(
                    category.emoji ?? '🏷️',
                    style: const TextStyle(fontSize: 24),
                  )
                : Icon(category.icon, color: const Color(0xFFF59E0B)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryShortcut extends StatelessWidget {
  const _AddCategoryShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 96,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: Color(0xFFF59E0B)),
            SizedBox(height: 4),
            Text(
              'Add category',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
