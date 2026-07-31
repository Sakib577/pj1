import 'package:flutter/material.dart';

import '../state/finance_app_state.dart';
import '../utils/currency_formatters.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController _titleController = TextEditingController();
  bool _isIncome = false;
  String _amountExpression = '0';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _onKeyTap(String value) {
    setState(() {
      if (value == 'back') {
        if (_amountExpression.length <= 1) {
          _amountExpression = '0';
        } else {
          _amountExpression = _amountExpression.substring(
            0,
            _amountExpression.length - 1,
          );
          if (_amountExpression.isEmpty) {
            _amountExpression = '0';
          }
        }
        return;
      }

      if (value == '.') {
        if (_amountExpression.contains('.')) return;
        _amountExpression = '$_amountExpression.';
        return;
      }

      if (_amountExpression == '0') {
        _amountExpression = value;
      } else {
        _amountExpression += value;
      }
    });
  }

  double _calculateAmount() {
    final normalized = _amountExpression.endsWith('.')
        ? _amountExpression.substring(0, _amountExpression.length - 1)
        : _amountExpression;
    return double.tryParse(normalized) ?? 0;
  }

  void _onSave() {
    final title = _titleController.text.trim();
    final amount = _calculateAmount();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a transaction title'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FinanceAppScope.of(context).addTransaction(
      title: title,
      amount: amount,
      icon: _isIncome ? Icons.trending_up : Icons.trending_down,
      iconColor: _isIncome ? const Color(0xFF22C55E) : const Color(0xFFF97316),
      isIncome: _isIncome,
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final amount = _calculateAmount();
    final displayAmount = formatCurrencyInput(amount);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Transaction',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            final gap = compact ? 8.0 : 12.0;
            final keypadHeight = (constraints.maxHeight * 0.35).clamp(
              200.0,
              300.0,
            );

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                            label: 'Income',
                            selected: _isIncome,
                            onTap: () => setState(() => _isIncome = true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SegmentButton(
                            label: 'Expense',
                            selected: !_isIncome,
                            onTap: () => setState(() => _isIncome = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: gap + 4),
                  TextField(
                    controller: _titleController,
                    key: const ValueKey('transaction-title'),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Transaction title',
                      hintText: 'Enter a clear name',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: gap + 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'AMOUNT',
                          style: TextStyle(
                            letterSpacing: 0.5,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_isIncome ? '' : '-'}$displayAmount',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: gap),
                  SizedBox(
                    height: keypadHeight,
                    child: _Keypad(onTap: _onKeyTap),
                  ),
                  SizedBox(height: gap),
                  SizedBox(
                    width: double.infinity,
                    key: const ValueKey('save-transaction'),
                    child: ElevatedButton.icon(
                      onPressed: _onSave,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Save Transaction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onTap});

  final ValueChanged<String> onTap;

  static const keys = [
    '7',
    '8',
    '9',
    'back',
    '4',
    '5',
    '6',
    '.',
    '1',
    '2',
    '3',
    '0',
  ];

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['7', '8', '9', 'back'],
      ['4', '5', '6', '.'],
      ['1', '2', '3', '0'],
    ];

    return Column(
      children: [
        for (final row in rows) ...[
          Expanded(
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: InkWell(
                      key: ValueKey('key-$key'),
                      onTap: () => onTap(key),
                      child: Center(
                        child: key == 'back'
                            ? const Icon(
                                Icons.backspace,
                                color: Color(0xFFEF4444),
                              )
                            : Text(
                                key,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
