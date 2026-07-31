import 'package:flutter/material.dart';

import '../state/finance_app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = FinanceAppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Currency')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Default currency', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Choose the currency used across balances, transactions, budgets, savings, and reports.',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.currency_exchange,
                color: Color(0xFFF59E0B),
              ),
              title: const Text('Select currency'),
              subtitle: Text(state.currencyCode),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _pickCurrency(context, state),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFFF59E0B),
              ),
              title: const Text('Update currency list and live rates'),
              subtitle: Text(
                state.ratesUpdatedAt == null
                    ? 'Rates have not been loaded yet.'
                    : 'Last updated ${state.ratesUpdatedAt!.toLocal()}',
              ),
              trailing: state.ratesLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: state.ratesLoading
                  ? null
                  : () async {
                      try {
                        await state.refreshExchangeRates();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not refresh rates. Check your internet connection.',
                              ),
                            ),
                          );
                        }
                      }
                    },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Rate source',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rates by ExchangeRate-API. Open-access rates update once daily.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCurrency(
    BuildContext context,
    FinanceAppState state,
  ) async {
    if (state.availableCurrencyCodes.length == 1 && !state.ratesLoading) {
      try {
        await state.refreshExchangeRates();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connect to the internet to load currencies.'),
            ),
          );
        }
        return;
      }
    }
    if (!context.mounted) return;
    final selected = await showCurrencyPicker(
      context,
      codes: state.availableCurrencyCodes,
      selectedCode: state.currencyCode,
    );
    if (selected != null) state.changeCurrency(selected);
  }
}

Future<String?> showCurrencyPicker(
  BuildContext context, {
  required List<String> codes,
  required String selectedCode,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _CurrencyPicker(
      codes: codes,
      selectedCode: selectedCode,
    ),
  );
}

class _CurrencyPicker extends StatefulWidget {
  const _CurrencyPicker({required this.codes, required this.selectedCode});
  final List<String> codes;
  final String selectedCode;
  @override
  State<_CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<_CurrencyPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final codes = widget.codes
        .where((code) => code.contains(_query.toUpperCase()))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: Column(
            children: [
              const Text(
                'Select currency',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search ISO code, e.g. BDT',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: codes.length,
                  itemBuilder: (_, index) {
                    final code = codes[index];
                    return ListTile(
                      title: Text(code),
                      trailing: code == widget.selectedCode
                          ? const Icon(Icons.check, color: Color(0xFFF59E0B))
                          : null,
                      onTap: () => Navigator.pop(context, code),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
