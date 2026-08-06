import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import 'category_detail_page.dart';
import 'categories_page.dart';
import '../state/finance_app_state.dart';
import '../utils/currency_settings.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key, this.initialIsIncome});

  /// Preselects the Income tab (instead of the default Expense tab). Used by
  /// the home-screen widget deep links so the tab matches the tapped card.
  final bool? initialIsIncome;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController _noteController = TextEditingController();
  late bool _isIncome = widget.initialIsIncome ?? false;
  String _amountExpression = '0';
  ExpenseCategory? _selectedCategory;
  String? _selectedSubcategory;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyTap(String value) {
    setState(() {
      if (value == 'back') {
        _amountExpression = _backspaceExpression(_amountExpression);
        return;
      }

      if (value == '=') {
        final evaluated = _evaluateExpression(_amountExpression);
        if (evaluated != null) {
          _amountExpression = _formatExpressionResult(evaluated);
        }
        return;
      }

      if (_isOperator(value)) {
        if (_amountExpression == '0') {
          _amountExpression = value == '-' ? '-' : '0';
          return;
        }

        final lastChar = _amountExpression[_amountExpression.length - 1];
        if (_isOperator(lastChar)) {
          _amountExpression =
              _amountExpression.substring(0, _amountExpression.length - 1) +
              value;
        } else {
          _amountExpression += value;
        }
        return;
      }

      if (value == '.') {
        final currentNumber = _currentNumberSegment(_amountExpression);
        if (currentNumber.contains('.')) return;
        if (_amountExpression.isEmpty ||
            _isOperator(_amountExpression[_amountExpression.length - 1])) {
          _amountExpression += '0.';
          return;
        }
        _amountExpression = '$_amountExpression.';
        return;
      }

      if (_amountExpression == '0') {
        _amountExpression = value;
      } else if (_amountExpression == '-') {
        _amountExpression = '-$value';
      } else {
        _amountExpression += value;
      }
    });
  }

  double _calculateAmount() {
    final normalized = _amountExpression.endsWith('.')
        ? _amountExpression.substring(0, _amountExpression.length - 1)
        : _amountExpression;
    return _evaluateExpression(normalized) ?? double.tryParse(normalized) ?? 0;
  }

  bool _isOperator(String value) =>
      value == '+' || value == '-' || value == '*' || value == '/';

  String _backspaceExpression(String input) {
    if (input.length <= 1) {
      return '0';
    }

    final shortened = input.substring(0, input.length - 1);
    return shortened.isEmpty || shortened == '-' ? '0' : shortened;
  }

  String _currentNumberSegment(String input) {
    var lastOperatorIndex = -1;
    for (var index = input.length - 1; index >= 0; index--) {
      if (_isOperator(input[index])) {
        lastOperatorIndex = index;
        break;
      }
    }
    return input.substring(lastOperatorIndex + 1);
  }

  String _formatExpressionResult(double value) {
    final text = value.toStringAsFixed(8).replaceFirst(RegExp(r'\.0+$'), '');
    return text
        .replaceFirst(RegExp(r'(\.\d*?)0+$'), r'$1')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  double? _evaluateExpression(String expression) {
    final cleaned = expression.replaceAll('÷', '/').replaceAll('×', '*');
    try {
      return _ExpressionParser(cleaned).parse();
    } catch (_) {
      return null;
    }
  }

  void _onSave() {
    final note = _noteController.text.trim();
    final amount = _calculateAmount();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final state = FinanceAppScope.of(context);
    final category =
        _selectedCategory ??
        (_isIncome
            ? state.recentIncomeCategories.first
            : state.recentExpenseCategories.first);
    state.addTransaction(
      amount: amount,
      icon: _isIncome ? Icons.trending_up : Icons.trending_down,
      iconColor: _isIncome ? const Color(0xFF22C55E) : const Color(0xFFF97316),
      isIncome: _isIncome,
      category: category,
      subcategory: _selectedSubcategory,
      note: note.isEmpty ? null : note,
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final appState = FinanceAppScope.of(context);
    final categories = _isIncome
        ? appState.incomeCategories
        : appState.expenseCategories;
    final currentCategory = _selectedCategory ?? categories.first;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            final gap = compact ? 4.0 : 8.0;
            final keypadHeight = (constraints.maxHeight * 0.34).clamp(
              170.0,
              300.0,
            );
            final amountFontSize = (constraints.maxHeight * 0.033).clamp(
              22.0,
              28.0,
            );
            final noteVerticalPadding = compact ? 10.0 : 12.0;

            return Padding(
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
                            onTap: () => setState(() {
                              _isIncome = true;
                              _selectedCategory = null;
                              _selectedSubcategory = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                      ],
                    ),
                  ),
                  SizedBox(height: gap),
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
                              onTap: () => _openCategoriesPage(context),
                            ),
                          );
                        }

                        final category = categories[index];
                        return SizedBox(
                          width: 96,
                          child: _CategoryShortcut(
                            category: category,
                            selected: currentCategory.id == category.id,
                            onTap: () => _pickSubcategory(category),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_selectedSubcategory != null) ...[
                    SizedBox(height: gap),
                    Text(
                      '${currentCategory.name} · $_selectedSubcategory',
                      style: const TextStyle(
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  SizedBox(height: gap + 6),
                  TextField(
                    controller: _noteController,
                    key: const ValueKey('transaction-note'),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: 'Add a note for this transaction',
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: noteVerticalPadding,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          // The keypad expression is already in the selected
                          // display currency. Do not run it through the USD
                          // formatter here; conversion happens only on save.
                          '${_isIncome ? '' : '-'}${CurrencySettings.symbol}$_amountExpression',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: amountFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
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

  Future<void> _openCategoriesPage(BuildContext context) async {
    final appState = FinanceAppScope.of(context);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => CategoriesPage(isIncome: _isIncome)),
    );
    if (!mounted) return;
    final refreshedCategories = _isIncome
        ? appState.incomeCategories
        : appState.expenseCategories;
    final selected = _selectedCategory;
    if (selected != null &&
        !refreshedCategories.any((category) => category.id == selected.id)) {
      setState(() {
        _selectedCategory = null;
        _selectedSubcategory = null;
      });
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
      MaterialPageRoute(
        builder: (_) => CategoryDetailPage(
          category: category,
          onAddSubcategory: (name, emoji) =>
              FinanceAppScope.of(context).addSubcategory(
                categoryId: category.id,
                name: name,
                emoji: emoji,
                isIncome: _isIncome,
              ),
        ),
      ),
    );
    if (selection != null && mounted) {
      setState(() {
        _selectedCategory = selection.category;
        _selectedSubcategory = selection.subcategory;
      });
    }
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
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnHeight = constraints.maxHeight;
        final otherButtonHeight = columnHeight / 4;
        final operatorButtonHeight = columnHeight / 5;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100F172A),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _KeyCell(
                      label: '7',
                      onTap: () => onTap('7'),
                      height: otherButtonHeight,
                    ),
                    _KeyCell(
                      label: '4',
                      onTap: () => onTap('4'),
                      height: otherButtonHeight,
                    ),
                    _KeyCell(
                      label: '1',
                      onTap: () => onTap('1'),
                      height: otherButtonHeight,
                    ),
                    _KeyCell(
                      label: '.',
                      onTap: () => onTap('.'),
                      height: otherButtonHeight,
                    ),
                  ],
                ),
              ),
              _ColumnDivider(height: columnHeight),
              Expanded(
                child: Column(
                  children: [
                    _KeyCell(
                      label: '8',
                      onTap: () => onTap('8'),
                      height: otherButtonHeight,
                    ),
                    _KeyCell(
                      label: '5',
                      onTap: () => onTap('5'),
                      height: otherButtonHeight,
                    ),
                    _KeyCell(
                      label: '2',
                      onTap: () => onTap('2'),
                      height: otherButtonHeight,
                    ),
                    _KeyCell(
                      label: '0',
                      onTap: () => onTap('0'),
                      height: otherButtonHeight,
                    ),
                  ],
                ),
              ),
              _ColumnDivider(height: columnHeight),
              Expanded(
                child: Column(
                  children: [
                    _KeyCell(
                      label: '9',
                      onTap: () => onTap('9'),
                      height: otherButtonHeight,
                    ),
                    _KeyCell(
                      label: '6',
                      onTap: () => onTap('6'),
                      height: otherButtonHeight,
                    ),
                    _KeyCell(
                      label: '3',
                      onTap: () => onTap('3'),
                      height: otherButtonHeight,
                    ),
                    _KeyCell(
                      label: '<-',
                      onTap: () => onTap('back'),
                      height: otherButtonHeight,
                    ),
                  ],
                ),
              ),
              _ColumnDivider(height: columnHeight),
              Expanded(
                child: Column(
                  children: [
                    _OperatorCell(
                      label: '÷',
                      onTap: () => onTap('/'),
                      height: operatorButtonHeight,
                    ),
                    _OperatorCell(
                      label: '×',
                      onTap: () => onTap('*'),
                      height: operatorButtonHeight,
                    ),
                    _OperatorCell(
                      label: '-',
                      onTap: () => onTap('-'),
                      height: operatorButtonHeight,
                    ),
                    _OperatorCell(
                      label: '+',
                      onTap: () => onTap('+'),
                      height: operatorButtonHeight,
                    ),
                    _OperatorCell(
                      label: '=',
                      onTap: () => onTap('='),
                      height: operatorButtonHeight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KeyCell extends StatelessWidget {
  const _KeyCell({
    required this.label,
    required this.onTap,
    required this.height,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('key-$label'),
      height: height,
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: label == '<-'
              ? const Icon(
                  Icons.backspace_outlined,
                  color: Color(0xFF6B7280),
                  size: 22,
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E8E),
                  ),
                ),
        ),
      ),
    );
  }
}

class _OperatorCell extends StatelessWidget {
  const _OperatorCell({
    required this.label,
    required this.onTap,
    required this.height,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isEquals = label == '=';
    return SizedBox(
      height: height,
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: const Color(0xFFFFF3E6),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isEquals ? 24 : 22,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnDivider extends StatelessWidget {
  const _ColumnDivider({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: height, color: const Color(0xFFE8EEF5));
  }
}

class _ExpressionParser {
  _ExpressionParser(this._input);

  final String _input;
  int _index = 0;

  double parse() {
    final value = _parseExpression();
    _skipWhitespace();
    if (_index != _input.length) {
      throw FormatException('Unexpected token');
    }
    return value;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      _skipWhitespace();
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parseFactor();
    while (true) {
      _skipWhitespace();
      if (_match('*')) {
        value *= _parseFactor();
      } else if (_match('/')) {
        value /= _parseFactor();
      } else {
        return value;
      }
    }
  }

  double _parseFactor() {
    _skipWhitespace();
    if (_match('+')) {
      return _parseFactor();
    }
    if (_match('-')) {
      return -_parseFactor();
    }
    if (_match('(')) {
      final value = _parseExpression();
      if (!_match(')')) {
        throw FormatException('Missing closing parenthesis');
      }
      return value;
    }
    return _parseNumber();
  }

  double _parseNumber() {
    _skipWhitespace();
    final start = _index;
    var seenDot = false;

    while (_index < _input.length) {
      final char = _input[_index];
      final isDigit = char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
      if (isDigit) {
        _index++;
        continue;
      }
      if (char == '.' && !seenDot) {
        seenDot = true;
        _index++;
        continue;
      }
      break;
    }

    if (start == _index) {
      throw FormatException('Expected number');
    }

    return double.parse(_input.substring(start, _index));
  }

  void _skipWhitespace() {
    while (_index < _input.length && _input[_index].trim().isEmpty) {
      _index++;
    }
  }

  bool _match(String value) {
    if (_index < _input.length && _input[_index] == value) {
      _index++;
      return true;
    }
    return false;
  }
}
