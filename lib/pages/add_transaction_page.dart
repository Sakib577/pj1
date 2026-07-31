import 'package:flutter/material.dart';

import '../data/mock_data.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  // Local UI state for this form.
  bool _isIncome = false;
  String _amount = '124.50';
  int _categoryIndex = 0;

  void _onDigitTap(String value) {
    setState(() {
      if (value == 'back') {
        // Delete one typed character.
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
          if (_amount.isEmpty) _amount = '0';
        }
        return;
      }

      if (value == '.') {
        // Allow only one decimal point.
        if (_amount.contains('.')) return;
        _amount = '$_amount.';
        return;
      }

      if (_amount == '0') {
        // Replace default zero with first real digit.
        _amount = value;
      } else {
        _amount = '$_amount$value';
      }
    });
  }

  void _onSave() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction saved'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayAmount = _amount.isEmpty ? '0' : _amount;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Adjust spacing for shorter screens so content does not feel crowded.
            final compact = constraints.maxHeight < 720;
            final gap = compact ? 8.0 : 12.0;
            final keypadHeight = (constraints.maxHeight * 0.35).clamp(200.0, 300.0);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFEFF2F7), borderRadius: BorderRadius.circular(14)),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: const Color(0xFFFFF4E8), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const Text(
                          'AMOUNT',
                          style: TextStyle(letterSpacing: 0.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_isIncome ? '' : '-'}\$$displayAmount',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: gap + 2),
                  const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(height: gap - 2),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      itemCount: AppMockData.addTransactionCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = AppMockData.addTransactionCategories[index];
                        final selected = index == _categoryIndex;
                        return InkWell(
                          onTap: () => setState(() => _categoryIndex = index),
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: selected ? item.color : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: selected ? item.color : const Color(0xFFE5E7EB), width: 1.2),
                                ),
                                child: Icon(item.icon, color: selected ? Colors.white : const Color(0xFF6B7280)),
                              ),
                              const SizedBox(height: 6),
                              // Category label: when selected we show a dark/strong
                              // foreground so the choice is clearly visible to the user.
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                  color: selected ? const Color(0xFF0F172A) : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: gap),
                  const Spacer(),
                  SizedBox(height: keypadHeight, child: _Keypad(onTap: _onDigitTap)),
                  SizedBox(height: gap),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _onSave,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Save Transaction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
  const _SegmentButton({required this.label, required this.selected, required this.onTap});
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
        child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: selected ? const Color(0xFFF59E0B) : const Color(0xFF6B7280)))),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onTap});
  final ValueChanged<String> onTap;

  static const keys = ['7', '8', '9', '÷', '4', '5', '6', '×', '1', '2', '3', '-', 'back', '0', '.', '+'];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1.5),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        return InkWell(
          onTap: () => onTap(key),
          child: Center(
            child: key == 'back'
                ? const Icon(Icons.backspace, color: Color(0xFFEF4444))
                : Text(key, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
        );
      },
    );
  }
}

