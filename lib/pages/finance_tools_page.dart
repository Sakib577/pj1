import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/finance_app_state.dart';
import '../utils/currency_formatters.dart';
import '../utils/currency_settings.dart';
import 'settings_page.dart';

enum FinanceTool { plannedPayments, debts, shoppingList, converter, report }

class FinanceToolsPage extends StatefulWidget {
  const FinanceToolsPage({super.key, required this.tool});
  final FinanceTool tool;
  @override
  State<FinanceToolsPage> createState() => _FinanceToolsPageState();
}

class _FinanceToolsPageState extends State<FinanceToolsPage> {
  final _items = <String>[];
  final _controller = TextEditingController();
  final _amountController = TextEditingController(text: '1');
  double _amount = 1;
  late String _sourceCode;
  String _targetCode = 'EUR';

  @override
  void initState() {
    super.initState();
    _sourceCode = CurrencySettings.code;
    if (widget.tool == FinanceTool.converter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = FinanceAppScope.of(context);
        if (state.availableCurrencyCodes.length == 1) {
          state.refreshExchangeRates().catchError((_) {});
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.tool) {
    FinanceTool.plannedPayments => 'Planned Payments',
    FinanceTool.debts => 'Debts',
    FinanceTool.shoppingList => 'Shopping List',
    FinanceTool.converter => 'Currency Converter',
    FinanceTool.report => 'Export Report',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: switch (widget.tool) {
        FinanceTool.converter => _converter(context),
        FinanceTool.report => _report(context),
        _ => _listTool(context),
      },
    );
  }

  Widget _listTool(BuildContext context) {
    final hint = switch (widget.tool) {
      FinanceTool.plannedPayments => 'e.g. Electricity bill on 10 Aug',
      FinanceTool.debts => 'e.g. Alex owes me 500',
      _ => 'e.g. Milk',
    };
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _addItem,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      'No ${_title.toLowerCase()} yet. Add your first item above.',
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, index) => Card(
                      child: ListTile(
                        title: Text(_items[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              setState(() => _items.removeAt(index)),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _converter(BuildContext context) {
    final state = FinanceAppScope.of(context);
    final sourceCode = state.availableCurrencyCodes.contains(_sourceCode)
        ? _sourceCode
        : state.currencyCode;
    final targetCode = state.availableCurrencyCodes.contains(_targetCode)
        ? _targetCode
        : 'USD';
    final sourceRate = CurrencySettings.usdRates[sourceCode] ?? 1;
    final targetRate = CurrencySettings.usdRates[targetCode] ?? 1;
    final result = (_amount / sourceRate) * targetRate;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Live rates • $sourceCode to $targetCode',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount in $sourceCode'),
            controller: _amountController,
            onChanged: (value) =>
                setState(() => _amount = double.tryParse(value) ?? 0),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CurrencySelectButton(
                  label: 'From',
                  code: sourceCode,
                  onPressed: () => _selectCurrency(
                    state: state,
                    selectedCode: sourceCode,
                    onSelected: (code) => setState(() => _sourceCode = code),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CurrencySelectButton(
                  label: 'To',
                  code: targetCode,
                  onPressed: () => _selectCurrency(
                    state: state,
                    selectedCode: targetCode,
                    onSelected: (code) => setState(() => _targetCode = code),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Card(
            color: const Color(0xFFFFF4E8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '$targetCode ${result.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rates by ExchangeRate-API. Refresh rates in Settings before converting.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _report(BuildContext context) {
    final state = FinanceAppScope.of(context);
    final report =
        'Expense Tracker report\nBalance: ${formatCurrency(state.currentBalance)}\nIncome: ${formatCurrency(state.monthlyIncome)}\nExpenses: ${formatCurrency(state.monthlyExpenses)}\nTransactions: ${state.transactions.length}';
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Report preview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(report),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Report copied. Paste it into a spreadsheet or document.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.content_copy),
            label: const Text('Copy report'),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _items.add(value);
      _controller.clear();
    });
  }

  Future<void> _selectCurrency({
    required FinanceAppState state,
    required String selectedCode,
    required ValueChanged<String> onSelected,
  }) async {
    if (state.availableCurrencyCodes.length == 1 && !state.ratesLoading) {
      try {
        await state.refreshExchangeRates();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connect to the internet to load currencies.'),
            ),
          );
        }
        return;
      }
    }
    if (!mounted) return;
    final selected = await showCurrencyPicker(
      context,
      codes: state.availableCurrencyCodes,
      selectedCode: selectedCode,
    );
    if (selected != null) onSelected(selected);
  }
}

class _CurrencySelectButton extends StatelessWidget {
  const _CurrencySelectButton({
    required this.label,
    required this.code,
    required this.onPressed,
  });

  final String label;
  final String code;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.currency_exchange),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Text(code, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
