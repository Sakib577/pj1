import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../analytics/repositories/analytics_repository.dart';
import '../analytics/utils/date_ranges.dart';
import '../state/finance_app_state.dart';
import '../utils/csv_export.dart';
import '../utils/currency_formatters.dart';
import '../utils/currency_settings.dart';
import '../utils/pdf_export.dart';
import 'settings_page.dart';

enum FinanceTool { converter, report }

class FinanceToolsPage extends StatefulWidget {
  const FinanceToolsPage({super.key, required this.tool});
  final FinanceTool tool;
  @override
  State<FinanceToolsPage> createState() => _FinanceToolsPageState();
}

class _FinanceToolsPageState extends State<FinanceToolsPage> {
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
    _amountController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.tool) {
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
      },
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
          const Divider(height: 40),
          const Text(
            'Export transactions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save every transaction as a spreadsheet-ready CSV file.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _exportCsv(state),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Export CSV'),
          ),
          const Divider(height: 40),
          const Text(
            'Export PDF',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save the statistics graphs or the accounting reports as a PDF.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _exportPdf(state),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(FinanceAppState state) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export PDF',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bar_chart_rounded),
                  title: const Text('Export statistics'),
                  subtitle: const Text('Charts and insights for this month'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(sheetContext).pop('statistics'),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Export reports'),
                  subtitle: const Text('All six accounting reports'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(sheetContext).pop('reports'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'statistics':
        await _exportStatisticsPdf(state);
      case 'reports':
        await _exportReportsPdf(state);
    }
  }

  Future<void> _exportStatisticsPdf(FinanceAppState state) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _withLoading(
        () async {
          final now = DateTime.now();
          final window = buildWindowFromDateRange(now: now);
          final bundle = const AnalyticsRepository().bundleFor(state, window);
          final bytes = await buildStatisticsPdf(bundle: bundle, now: now);
          await _shareBytes(bytes, 'expense_tracker_statistics');
        },
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Statistics PDF exported.')),
      );
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not export the statistics PDF.')),
        );
      }
    }
  }

  Future<void> _exportReportsPdf(FinanceAppState state) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _withLoading(
        () async {
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, 1);
          final bytes = await buildReportsPdf(
            state: state,
            start: start,
            end: now,
            rangeLabel: 'This month',
            now: now,
          );
          await _shareBytes(bytes, 'expense_tracker_reports');
        },
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Reports PDF exported.')),
      );
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not export the reports PDF.')),
        );
      }
    }
  }

  Future<void> _withLoading(Future<void> Function() action) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Generating PDF…'),
            ],
          ),
        ),
      ),
    );
    try {
      await action();
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _shareBytes(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final file = File(
      '${dir.path}/${fileName}_${now.year.toString().padLeft(4, '0')}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}.pdf',
    );
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: fileName,
      ),
    );
  }

  Future<void> _exportCsv(FinanceAppState state) async {
    final messenger = ScaffoldMessenger.of(context);
    if (state.transactions.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No transactions to export yet.')),
      );
      return;
    }
    try {
      final csv = buildTransactionsCsv(state.transactions);
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final file = File(
        '${dir.path}/expense_tracker_${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}.csv',
      );
      await file.writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Expense Tracker transactions',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not export the CSV file.')),
        );
      }
    }
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
