import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../analytics/models/analytics_models.dart';
import '../analytics/models/stat_models.dart';
import '../models/finance_models.dart';
import '../reports/models/report_models.dart';
import '../reports/services/report_service.dart';
import '../state/finance_app_state.dart';
import 'currency_settings.dart';

const _reportService = ReportService();

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

const _orange = PdfColor.fromInt(0xFFFF9F0A);
const _green = PdfColor.fromInt(0xFF16A34A);
const _red = PdfColor.fromInt(0xFFDC2626);
const _blue = PdfColor.fromInt(0xFF2563EB);
const _ink = PdfColor.fromInt(0xFF0F172A);
const _slate = PdfColor.fromInt(0xFF64748B);
const _muted = PdfColor.fromInt(0xFF94A3B8);
const _borderGrey = PdfColor.fromInt(0xFFE2E8F0);
const _lightBg = PdfColor.fromInt(0xFFF8FAFC);
const _pageBg = PdfColor.fromInt(0xFFF1F5F9);
const _forecastActual = PdfColor.fromInt(0xFFF59E0B);
const _forecastTail = PdfColor.fromInt(0xFF94A3B8);

const _pageWidth = 515.0;

String get _code => CurrencySettings.code;

double _display(double usd) => CurrencySettings.fromUsd(usd);

/// Formats a raw display-currency value as "1,234.50" (no symbol).
String _num(double value) {
  final negative = value < 0;
  final abs = value.abs().toStringAsFixed(2);
  final parts = abs.split('.');
  final digits = parts.first;
  final reversed = digits.split('').reversed.toList();
  final buffer = StringBuffer();
  for (var i = 0; i < reversed.length; i++) {
    if (i != 0 && i % 3 == 0) buffer.write(',');
    buffer.write(reversed[i]);
  }
  return '${negative ? '-' : ''}${buffer.toString().split('').reversed.join()}'
      '.${parts.last}';
}

/// Formats a USD amount in the display currency with the code prefix.
String _money(double usd) => '$_code ${_num(_display(usd))}';

String _shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// Replaces characters the built-in Helvetica font cannot render with ASCII.
String _sanitize(String s) => s
    .replaceAll('\u2013', '-') // en dash
    .replaceAll('\u2014', '-') // em dash
    .replaceAll('\u2192', '->') // right arrow
    .replaceAll('\u00b7', '|') // middle dot
    .replaceAll('\u2022', '-'); // bullet

pw.TableBorder _tableBorder() {
  return pw.TableBorder(
    left: const pw.BorderSide(color: _borderGrey, width: 0.4),
    right: const pw.BorderSide(color: _borderGrey, width: 0.4),
    top: const pw.BorderSide(color: _borderGrey, width: 0.4),
    bottom: const pw.BorderSide(color: _borderGrey, width: 0.4),
    horizontalInside: const pw.BorderSide(color: _borderGrey, width: 0.4),
    verticalInside: const pw.BorderSide(color: _borderGrey, width: 0.4),
  );
}

pw.Widget _docTitle(String title) {
  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: pw.BoxDecoration(
      color: _orange,
      borderRadius: pw.BorderRadius.circular(12),
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _docMeta(List<String> lines) {
  return pw.Padding(
    padding: const pw.EdgeInsets.fromLTRB(4, 10, 4, 4),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          pw.Text(_sanitize(line), style: pw.TextStyle(fontSize: 9, color: _slate)),
      ],
    ),
  );
}

pw.Widget _sectionTitle(String text, {PdfColor color = _ink}) {
  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(0, 16, 0, 8),
    child: pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 14,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _hint(String text) {
  return pw.Text(_sanitize(text), style: pw.TextStyle(fontSize: 8, color: _muted));
}

pw.Widget _divider() {
  return pw.Divider(color: _borderGrey, height: 18);
}

pw.Widget _empty(String text) {
  return pw.Text(_sanitize(text), style: pw.TextStyle(fontSize: 9, color: _muted));
}

/// Card shell that mirrors the app's [StatCard] look: rounded surface, subtle
/// border, colored accent chip + bold title + grey subtitle, content below.
pw.Widget _statCard({
  required String title,
  required PdfColor accent,
  String? subtitle,
  required pw.Widget child,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(14),
      border: pw.Border.all(color: _borderGrey, width: 0.6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 18,
              height: 18,
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.circular(5),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  if (subtitle != null)
                    pw.Text(
                      _sanitize(subtitle),
                      style: pw.TextStyle(fontSize: 8, color: _muted),
                    ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        child,
      ],
    ),
  );
}

pw.Widget _figure(String label, String value, PdfColor color) {
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _slate)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _textRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _slate)),
        pw.Text(
          _sanitize(value),
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _legendDot(PdfColor color, String label) {
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Container(
        width: 12,
        height: 3,
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(2),
        ),
      ),
      pw.SizedBox(width: 5),
      pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _slate)),
    ],
  );
}

pw.Widget _progressBar(double ratio, PdfColor color) {
  final clamped = ratio.clamp(0.0, 1.0);
  return pw.LayoutBuilder(
    builder: (context, constraints) => pw.Container(
      height: 8,
      decoration: pw.BoxDecoration(
        color: _borderGrey,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Container(
          width: (constraints?.maxWidth ?? 0) * clamped,
          height: 8,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(6),
          ),
        ),
      ),
    ),
  );
}

pw.Widget _progressRow({
  required String label,
  required double amount,
  required double ratio,
  required PdfColor color,
  double delta = 0,
  String? deltaLabel,
}) {
  return pw.Row(
    children: [
      pw.SizedBox(
        width: 62,
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _slate,
          ),
        ),
      ),
      pw.Expanded(child: _progressBar(ratio, color)),
      pw.SizedBox(width: 10),
      pw.SizedBox(
        width: 82,
        child: pw.Text(
          _num(amount),
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ),
      pw.SizedBox(width: 36),
      pw.SizedBox(
        width: 40,
        child: pw.Text(
          delta == 0
              ? (deltaLabel ?? '-')
              : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: delta > 0 ? _green : _red,
          ),
        ),
      ),
    ],
  );
}

pw.Widget _legendRow(
  PdfColor color,
  String label,
  String amount,
  String percent,
) {
  return pw.Row(
    children: [
      pw.Container(
        width: 10,
        height: 10,
        decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
      ),
      pw.SizedBox(width: 8),
      pw.Expanded(
        child: pw.Text(
          _sanitize(label),
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.normal,
            color: _ink,
          ),
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Text(
        amount,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.SizedBox(width: 8),
      pw.SizedBox(
        width: 34,
        child: pw.Text(
          percent,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(fontSize: 9, color: _slate),
        ),
      ),
    ],
  );
}

pw.Widget _donutWidget({
  required List<_Slice> slices,
  required double size,
  required String centerLabel,
  required String centerSubtitle,
}) {
  return pw.Stack(
    alignment: pw.Alignment.center,
    children: [
      pw.CustomPaint(
        size: PdfPoint(size, size),
        painter: (canvas, size) => _paintDonut(canvas, size.x, size.y, slices),
      ),
      pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            centerLabel,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Text(
            _sanitize(centerSubtitle),
            style: pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _gaugeWidget({
  required double ratio,
  required String centerLabel,
  required String centerSubtitle,
  required PdfColor color,
  double size = 120,
}) {
  return pw.Stack(
    alignment: pw.Alignment.center,
    children: [
      pw.CustomPaint(
        size: PdfPoint(size, size),
        painter: (canvas, size) =>
            _paintGauge(canvas, size.x, size.y, ratio, color),
      ),
      pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            centerLabel,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Text(
            _sanitize(centerSubtitle),
            style: pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _expenseRow(TopExpense top) {
  final t = top.txn;
  final color = PdfColor.fromInt(t.iconColor.toARGB32() & 0xFFFFFF);
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    child: pw.Row(
      children: [
        pw.Container(
          width: 24,
          height: 24,
          decoration: pw.BoxDecoration(
            color: color.withAlpha(0.15),
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _sanitize(t.title),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              if (t.subtitle.isNotEmpty)
                pw.Text(
                  _sanitize(t.subtitle),
                  style: pw.TextStyle(fontSize: 8, color: _muted),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          _num(_display(t.amount)),
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _budgetRow(BudgetProgress entry) {
  final statusColor = PdfColor.fromInt(entry.statusColor.toARGB32() & 0xFFFFFF);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              _sanitize(entry.budget.label),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: pw.BoxDecoration(
              color: statusColor.withAlpha(0.12),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              _sanitize(entry.status),
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      _progressBar(entry.ratio, statusColor),
      pw.SizedBox(height: 5),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${_num(_display(entry.spent))} spent',
            style: pw.TextStyle(fontSize: 8, color: _slate),
          ),
          pw.Text(
            '${_num(_display(entry.remaining))} remaining',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _simpleTable({
  required List<String> headers,
  required List<List<dynamic>> rows,
  Map<int, pw.AlignmentGeometry>? alignments,
  List<int>? boldColumns,
}) {
  final boldColumnsSet = boldColumns?.toSet() ?? <int>{};
  return pw.TableHelper.fromTextArray(
    border: _tableBorder(),
    cellPadding: const pw.EdgeInsets.all(6),
    headers: headers,
    headerDecoration: const pw.BoxDecoration(color: _lightBg),
    headerStyle: pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: _ink,
    ),
    cellStyle: pw.TextStyle(fontSize: 9, color: _ink),
    headerAlignments: alignments,
    cellAlignments: alignments,
    data: [
      for (var r = 0; r < rows.length; r++)
        [
          for (var c = 0; c < rows[r].length; c++)
            pw.Text(
              _sanitize('${rows[r][c]}'),
              style: pw.TextStyle(
                fontSize: 9,
                color: _ink,
                fontWeight: boldColumnsSet.contains(c)
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
            ),
        ],
    ],
  );
}

pw.Widget _statementTable({
  required List<String> headers,
  required List<pw.TableRow> rows,
}) {
  return pw.Table(
    border: _tableBorder(),
    columnWidths: const {
      0: pw.FlexColumnWidth(3),
      1: pw.FlexColumnWidth(2),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _lightBg),
        children: [
          for (final header in headers)
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
        ],
      ),
      ...rows,
    ],
  );
}

// ---------------------------------------------------------------------------
// Statistics PDF
// ---------------------------------------------------------------------------

Future<Uint8List> buildStatisticsPdf({
  required StatisticsBundle bundle,
  required DateTime now,
}) async {
  final doc = pw.Document(
    title: 'Statistics Report',
    author: 'Expense Tracker',
    theme: pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    ),
  );
  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: _pageBg),
        ),
      ),
      build: (context) => [
        _docTitle('Statistics Report'),
        _docMeta([
          'Period: ${bundle.window.label} '
              '(${_shortDate(bundle.window.start)} - ${_shortDate(bundle.window.end)})',
          'Generated: ${_shortDate(now)} | Currency: $_code',
        ]),
        pw.SizedBox(height: 8),
        _cashFlowSection(bundle.cashFlow, bundle.window.label),
        pw.SizedBox(height: 14),
        _categoryDonutSection(bundle.categorySpending),
        pw.SizedBox(height: 14),
        _incomeExpenseSection(bundle.incomeExpenseComparison),
        pw.SizedBox(height: 14),
        _spendingPatternSection(bundle.spendingTrend),
        pw.SizedBox(height: 14),
        _balanceTrendSection(bundle.balanceTrend),
        pw.SizedBox(height: 14),
        _topExpensesSection(bundle.topExpenses),
        pw.SizedBox(height: 14),
        _debtRatioSection(bundle.debtRatio, bundle.window.label),
        pw.SizedBox(height: 14),
        _monthlyOverviewSection(bundle.monthlyOverview),
        pw.SizedBox(height: 14),
        _incomeAnalyticsSection(bundle.incomeAnalytics),
        pw.SizedBox(height: 14),
        _budgetProgressSection(bundle.budgetProgress),
        pw.SizedBox(height: 14),
        _forecastSection(bundle.cashFlowForecast),
      ],
    ),
  );
  return doc.save();
}

pw.Widget _cashFlowSection(CashFlowSummary summary, String rangeLabel) {
  final maxValue = math.max(summary.income, summary.expense);
  return _statCard(
    title: 'Cash Flow Summary',
    accent: _orange,
    subtitle: rangeLabel,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _figure('Income', _num(_display(summary.income)), _green),
            _figure('Expense', _num(_display(summary.expense)), _red),
            _figure('Net', _num(_display(summary.net)), _blue),
          ],
        ),
        pw.SizedBox(height: 14),
        _progressHeader(),
        pw.SizedBox(height: 8),
        _progressRow(
          label: 'Income',
          amount: _display(summary.income),
          ratio: maxValue == 0 ? 0 : summary.income / maxValue,
          color: _green,
          delta: summary.incomeVsPrevious,
        ),
        pw.SizedBox(height: 8),
        _progressRow(
          label: 'Expense',
          amount: _display(summary.expense),
          ratio: maxValue == 0 ? 0 : summary.expense / maxValue,
          color: _red,
          delta: summary.expenseVsPrevious,
        ),
        pw.SizedBox(height: 8),
        _progressRow(
          label: 'Net',
          amount: _display(summary.net),
          ratio: maxValue == 0 ? 0 : (summary.net.abs() / maxValue).clamp(0, 1),
          color: _blue,
          delta: summary.netVsPrevious,
        ),
      ],
    ),
  );
}

pw.Widget _progressHeader() {
  return pw.Row(
    children: [
      pw.SizedBox(width: 62),
      pw.Expanded(child: pw.SizedBox()),
      pw.SizedBox(width: 10),
      pw.SizedBox(
        width: 82,
        child: pw.Text(
          'Amount',
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _slate,
          ),
        ),
      ),
      pw.SizedBox(width: 36),
      pw.SizedBox(
        width: 40,
        child: pw.Text(
          'vs prev',
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _slate,
          ),
        ),
      ),
    ],
  );
}

pw.Widget _categoryDonutSection(List<CategoryStat> categories) {
  final sorted = [...categories]..sort((a, b) => b.amount.compareTo(a.amount));
  final total = sorted.fold<double>(0, (s, c) => s + c.amount);
  final shown = sorted.take(7).toList();
  final restTotal = sorted
      .skip(7)
      .fold<double>(0, (s, c) => s + c.amount);
  final slices = <_Slice>[
    for (var i = 0; i < shown.length; i++)
      _Slice(
        shown[i].name,
        _display(shown[i].amount),
        _sliceColors[i % _sliceColors.length],
      ),
    if (restTotal > 0) _Slice('Other (${sorted.length - shown.length})', _display(restTotal), _muted),
  ];

  final displayTotal = _display(total);
  return _statCard(
    title: 'Spending by Categories',
    accent: _orange,
    child: slices.isEmpty
        ? _empty('No spending recorded in this period.')
        : pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _donutWidget(
                slices: slices,
                size: 150,
                centerLabel: _num(displayTotal),
                centerSubtitle: 'Total',
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    for (final slice in slices)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: _legendRow(
                          slice.color,
                          slice.label,
                          _num(slice.value),
                          displayTotal == 0
                              ? '0%'
                              : '${(slice.value / displayTotal * 100).toStringAsFixed(0)}%',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
  );
}

pw.Widget _incomeExpenseSection(List<GroupedBar> bars) {
  final limited = bars.length > 15 ? bars.sublist(bars.length - 15) : bars;
  return _statCard(
    title: 'Income vs Expenses',
    accent: _orange,
    subtitle: '${bars.length} ${bars.length == 1 ? 'period' : 'periods'}',
    child: limited.isEmpty
        ? _empty('No income or expenses in this period.')
        : pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  _legendDot(_green, 'Income'),
                  pw.SizedBox(width: 16),
                  _legendDot(_red, 'Expenses'),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.SizedBox(
                height: 170,
                child: pw.Stack(
                  children: [
                    pw.Positioned.fill(
                      child: pw.CustomPaint(
                        size: PdfPoint(_pageWidth, 170),
                        painter: (canvas, size) =>
                            _paintBars(canvas, size.x, size.y, limited),
                      ),
                    ),
                    pw.Positioned(
                      left: 10,
                      top: 4,
                      child: pw.Text(
                        _maxBarLabel(limited),
                        style: pw.TextStyle(fontSize: 8, color: _muted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
  );
}

pw.Widget _spendingPatternSection(List<TrendSeries> spendingTrend) {
  final points = spendingTrend.isEmpty ? const <SeriesPoint>[] : spendingTrend.first.points;
  final values = [for (final p in points) _display(p.y)];
  return _statCard(
    title: 'Spending Pattern',
    accent: _orange,
    subtitle: 'Expense per day',
    child: points.length < 2
        ? _empty('No spending in this period.')
        : pw.SizedBox(
            height: 170,
            child: pw.Stack(
              children: [
                pw.Positioned.fill(
                  child: pw.CustomPaint(
                    size: PdfPoint(_pageWidth, 170),
                    painter: (canvas, size) =>
                        _paintLine(canvas, size.x, size.y, values, _orange),
                  ),
                ),
                for (final l in _lineLabels(values, 170))
                  pw.Positioned(
                    left: l.$1,
                    top: l.$2,
                    child: pw.Text(
                      l.$3,
                      style: pw.TextStyle(fontSize: 8, color: _muted),
                    ),
                  ),
              ],
            ),
          ),
  );
}

pw.Widget _balanceTrendSection(TrendSeries trend) {
  final points = trend.points;
  final values = [for (final p in points) _display(p.y)];
  return _statCard(
    title: 'Balance Trend',
    accent: _orange,
    subtitle: points.isEmpty
        ? null
        : '${points.length} points | ${_shortDate(points.first.x)} to '
            '${_shortDate(points.last.x)}',
    child: points.length < 2
        ? _empty('No balance data in this period.')
        : pw.SizedBox(
            height: 170,
            child: pw.Stack(
              children: [
                pw.Positioned.fill(
                  child: pw.CustomPaint(
                    size: PdfPoint(_pageWidth, 170),
                    painter: (canvas, size) =>
                        _paintLine(canvas, size.x, size.y, values, _blue),
                  ),
                ),
                for (final l in _lineLabels(values, 170))
                  pw.Positioned(
                    left: l.$1,
                    top: l.$2,
                    child: pw.Text(
                      l.$3,
                      style: pw.TextStyle(fontSize: 8, color: _muted),
                    ),
                  ),
              ],
            ),
          ),
  );
}

pw.Widget _topExpensesSection(List<TopExpense> expenses) {
  final shown = expenses.take(10).toList();
  return _statCard(
    title: 'Top Expenses',
    accent: _orange,
    child: shown.isEmpty
        ? _empty('No expenses in this period.')
        : pw.Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                _expenseRow(shown[i]),
                if (i != shown.length - 1)
                  pw.Divider(color: _borderGrey, height: 10),
              ],
            ],
          ),
  );
}

pw.Widget _monthlyOverviewSection(MonthlyOverview overview) {
  return _statCard(
    title: 'Monthly Overview',
    accent: _orange,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _figure('Income', _num(_display(overview.income)), _green),
            _figure('Expense', _num(_display(overview.expense)), _red),
            _figure('Net', _num(_display(overview.net)), _blue),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: _borderGrey, height: 1),
        pw.SizedBox(height: 8),
        _textRow('Saved', _num(_display(overview.saved))),
        _textRow('Avg daily spend', _num(_display(overview.avgDailySpend))),
        _textRow('Busiest day', overview.busiestDay),
        _textRow('Top category', overview.topCategory),
        _textRow('Transactions', '${overview.transactionCount}'),
        pw.SizedBox(height: 4),
        pw.Text(
          'Tip: keep your saved amount positive to build healthy savings.',
          style: pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ],
    ),
  );
}

pw.Widget _incomeAnalyticsSection(IncomeAnalytics analytics) {
  final sorted = [...analytics.categories]
    ..sort((a, b) => b.amount.compareTo(a.amount));
  final total = sorted.fold<double>(0, (s, c) => s + c.amount);
  final displayTotal = _display(total);
  final shown = sorted.take(7).toList();
  final rest = sorted.skip(7).fold<double>(0, (s, c) => s + c.amount);
  final slices = <_Slice>[
    for (var i = 0; i < shown.length; i++)
      _Slice(
        shown[i].name,
        _display(shown[i].amount),
        _sliceColors[(i + 2) % _sliceColors.length],
      ),
    if (rest > 0) _Slice('Other', _display(rest), _muted),
  ];
  final largest = analytics.largest;
  return _statCard(
    title: 'Income Analytics',
    accent: _orange,
    child: sorted.isEmpty
        ? _empty('No income recorded in this period.')
        : pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Total income: ${_num(displayTotal)}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _green,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _donutWidget(
                    slices: slices,
                    size: 130,
                    centerLabel: _num(displayTotal),
                    centerSubtitle: 'Total',
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        for (final slice in slices)
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3),
                            child: _legendRow(
                              slice.color,
                              slice.label,
                              _num(slice.value),
                              displayTotal == 0
                                  ? '0%'
                                  : '${(slice.value / displayTotal * 100).toStringAsFixed(0)}%',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (largest != null) ...[
                pw.Divider(color: _borderGrey, height: 18),
                pw.Text(
                  'Largest income',
                  style: pw.TextStyle(fontSize: 8, color: _muted),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Container(
                      width: 20,
                      height: 20,
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(largest.iconColor.toARGB32() & 0xFFFFFF)
                            .withAlpha(0.15),
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        _sanitize(largest.title),
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                    ),
                    pw.Text(
                      _num(_display(largest.amount)),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
  );
}

pw.Widget _budgetProgressSection(List<BudgetProgress> progress) {
  return _statCard(
    title: 'Budget Progress',
    accent: _orange,
    child: progress.isEmpty
        ? _empty('No budgets set yet.')
        : pw.Column(
            children: [
              for (var i = 0; i < progress.length; i++) ...[
                _budgetRow(progress[i]),
                if (i != progress.length - 1)
                  pw.Divider(color: _borderGrey, height: 16),
              ],
            ],
          ),
  );
}

pw.Widget _forecastSection(List<ForecastPoint> points) {
  final values = [for (final p in points) _display(p.value)];
  final firstForecast = points.indexWhere((p) => p.forecast);
  return _statCard(
    title: 'Cash Flow Forecast',
    accent: _orange,
    subtitle: points.isEmpty
        ? null
        : 'Projected daily net over the next ${points.where((p) => p.forecast).length} days',
    child: points.length < 2
        ? _empty('Not enough data to forecast.')
        : pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                height: 170,
                child: pw.CustomPaint(
                  size: PdfPoint(_pageWidth, 170),
                  painter: (canvas, size) => _paintForecast(
                    canvas,
                    size.x,
                    size.y,
                    values,
                    firstForecast < 0 ? values.length : firstForecast,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  _legendDot(_forecastActual, 'Actual'),
                  pw.SizedBox(width: 16),
                  _legendDot(_forecastTail, 'Forecast'),
                ],
              ),
            ],
          ),
  );
}

pw.Widget _debtRatioSection(GaugeResult? gauge, String rangeLabel) {
  final levelColor = switch (gauge?.level) {
    HealthLevel.moderate => _orange,
    HealthLevel.poor => _red,
    _ => _green,
  };
  final levelLabel = switch (gauge?.level) {
    HealthLevel.moderate => 'Moderate',
    HealthLevel.poor => 'High',
    _ => 'Healthy',
  };
  return _statCard(
    title: 'Debt-to-Income Ratio',
    accent: _orange,
    subtitle: rangeLabel,
    child: gauge == null
        ? _empty('No debt-to-income reading for this period.')
        : pw.Row(
            children: [
              _gaugeWidget(
                ratio: (gauge.ratio / 3).clamp(0.0, 1.0),
                centerLabel: '${(gauge.ratio * 100).toStringAsFixed(0)}%',
                centerSubtitle: 'DTI',
                color: levelColor,
              ),
              pw.SizedBox(width: 18),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 9,
                          height: 9,
                          decoration: pw.BoxDecoration(
                            color: levelColor,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          levelLabel,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: levelColor,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Total debt: ${_money(gauge.value)}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'A healthy DTI is below 36%.',
                      style: pw.TextStyle(fontSize: 8, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
  );
}

// ---------------------------------------------------------------------------
// Reports PDF
// ---------------------------------------------------------------------------

Future<Uint8List> buildReportsPdf({
  required FinanceAppState state,
  required DateTime start,
  required DateTime end,
  required String rangeLabel,
  required DateTime now,
}) {
  return buildReportsPdfData(
    txns: state.transactions,
    debts: state.debts,
    budgets: state.budgets,
    goals: state.savingsGoals,
    start: start,
    end: end,
    rangeLabel: rangeLabel,
    now: now,
  );
}

/// Builds the reports PDF from plain data so it can be exercised in tests
/// without a [FinanceAppState].
Future<Uint8List> buildReportsPdfData({
  required List<TransactionItem> txns,
  required List<DebtItem> debts,
  required List<BudgetCategory> budgets,
  required List<SavingsGoal> goals,
  required DateTime start,
  required DateTime end,
  required String rangeLabel,
  required DateTime now,
}) async {
  final doc = pw.Document(
    title: 'Accounting Reports',
    author: 'Expense Tracker',
    theme: pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    ),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        _docTitle('Accounting Reports'),
        _docMeta([
          'Period: $rangeLabel '
              '(${_shortDate(start)} – ${_shortDate(end)})',
          'Generated: ${_shortDate(now)} · Currency: $_code',
        ]),
        _sectionTitle('Cash Flow Statement', color: _blue),
        ..._cashFlowReport(
          _reportService.calculateCashFlowStatement(txns, start, end),
        ),
        _divider(),
        _sectionTitle('Income Statement', color: _blue),
        ..._incomeReport(
          _reportService.calculateIncomeStatement(txns, start, end),
        ),
        _divider(),
        _sectionTitle('Balance Sheet', color: _blue),
        ..._balanceSheetReport(
          _reportService.calculateBalanceSheet(txns, debts, goals),
        ),
        _divider(),
        _sectionTitle('Budget vs Actual', color: _blue),
        ..._budgetReport(
          _reportService.calculateBudgetVsActual(budgets, txns),
        ),
        _divider(),
        _sectionTitle('Debt Report', color: _blue),
        ..._debtReport(_reportService.calculateDebtReport(debts)),
        _divider(),
        _sectionTitle('Savings & Net Worth', color: _blue),
        ..._savingsReport(
          _reportService.calculateSavingsNetWorth(goals, txns, start, end),
        ),
      ],
    ),
  );
  return doc.save();
}

List<pw.Widget> _cashFlowReport(CashFlowStatementReport report) {
  return [
    for (final section in [report.operating, report.investing, report.financing])
      _statementBlock(
        title: section.title,
        incomeItems: section.incomeItems,
        expenseItems: section.expenseItems,
        subtotalLabel: section.subtotalLabel,
        subtotal: section.subtotal,
      ),
    _statementTable(
      headers: const ['', 'Amount'],
      rows: [
        _row('Cash at beginning of period', report.beginningCash),
        _row('Net increase (decrease) in cash', report.netCashFlow,
            color: report.netCashFlow < 0 ? _red : _green),
        _row('Cash at end of period', report.endingCash, bold: true),
      ],
    ),
  ];
}

List<pw.Widget> _incomeReport(IncomeStatementReport report) {
  final profit = report.netIncome >= 0;
  return [
    _statementBlock(
      title: 'Income',
      incomeItems: report.incomeItems,
      expenseItems: const [],
      subtotalLabel: 'Total income',
      subtotal: report.totalIncome,
    ),
    _statementBlock(
      title: 'Expenses',
      incomeItems: const [],
      expenseItems: report.expenseItems,
      subtotalLabel: 'Total expenses',
      subtotal: report.totalExpenses,
    ),
    _statementTable(
      headers: const ['', 'Amount'],
      rows: [
        _row(profit ? 'Net profit' : 'Net loss', report.netIncome.abs(),
            color: profit ? _green : _red, bold: true),
        _row('Gross margin', report.grossMargin,
            suffix: '%', color: _slate),
      ],
    ),
  ];
}

List<pw.Widget> _balanceSheetReport(BalanceSheetReport report) {
  return [
    _lineBlock(title: 'Assets', items: report.assetItems, total: report.totalAssets),
    _lineBlock(
      title: 'Liabilities',
      items: report.liabilityItems,
      total: report.totalLiabilities,
    ),
    _statementTable(
      headers: const ['', 'Amount'],
      rows: [_row('Net worth', report.netWorth, bold: true)],
    ),
  ];
}

List<pw.Widget> _budgetReport(BudgetVsActualReport report) {
  if (report.rows.isEmpty) {
    return [_hint('No budgets set for this period.')];
  }
  return [
    _simpleTable(
      headers: const ['Category', 'Budget', 'Actual', 'Variance', 'Ratio'],
      rows: [
        for (final r in report.rows)
          [
            r.category,
            _num(_display(r.budget)),
            _num(_display(r.actual)),
            _num(_display(r.variance)),
            '${(r.ratio * 100).toStringAsFixed(0)}%',
          ],
        [
          'Total',
          _num(_display(report.totalBudget)),
          _num(_display(report.totalActual)),
          _num(_display(report.totalVariance)),
          '',
        ],
      ],
      alignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      boldColumns: const [1, 2, 3],
    ),
  ];
}

List<pw.Widget> _debtReport(DebtReport report) {
  if (report.totalBorrowed == 0 && report.totalLent == 0) {
    return [_hint('No debts recorded.')];
  }
  return [
    if (report.borrowedActive.isNotEmpty)
      _lineBlock(
        title: 'Borrowed (active)',
        items: report.borrowedActive,
        total: report.borrowedActive.fold(0, (s, i) => s + i.amount),
      ),
    if (report.borrowedSettled.isNotEmpty)
      _lineBlock(
        title: 'Borrowed (settled)',
        items: report.borrowedSettled,
        total: report.borrowedSettled.fold(0, (s, i) => s + i.amount),
      ),
    if (report.lentActive.isNotEmpty)
      _lineBlock(
        title: 'Lent (active)',
        items: report.lentActive,
        total: report.lentActive.fold(0, (s, i) => s + i.amount),
      ),
    if (report.lentSettled.isNotEmpty)
      _lineBlock(
        title: 'Lent (settled)',
        items: report.lentSettled,
        total: report.lentSettled.fold(0, (s, i) => s + i.amount),
      ),
    _statementTable(
      headers: const ['', 'Amount'],
      rows: [
        _row('Total borrowed', report.totalBorrowed),
        _row('Total lent', report.totalLent),
        _row('Net position', report.netPosition, bold: true),
      ],
    ),
  ];
}

List<pw.Widget> _savingsReport(SavingsNetWorthReport report) {
  return [
    if (report.goals.isEmpty)
      _hint('No savings goals yet.')
    else
      _simpleTable(
        headers: const ['Goal', 'Current', 'Target', 'Progress'],
        rows: [
          for (final g in report.goals)
            [
              g.title,
              _num(_display(g.current)),
              _num(_display(g.target)),
              '${(g.progress * 100).toStringAsFixed(0)}%',
            ],
          [
            'Total',
            _num(_display(report.totalSaved)),
            _num(_display(report.totalTarget)),
            '${(report.savingsRate * 100).toStringAsFixed(0)}%',
          ],
        ],
        alignments: const {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerRight,
          2: pw.Alignment.centerRight,
          3: pw.Alignment.centerRight,
        },
        boldColumns: const [1, 2],
      ),
    _statementTable(
      headers: const ['', 'Amount'],
      rows: [
        _row('Total saved', report.totalSaved),
        _row('Target', report.totalTarget),
        _row('Period contribution', report.periodContribution),
        _row('Period withdrawal', report.periodWithdrawal),
        _row('Savings rate', report.savingsRate, suffix: '%'),
      ],
    ),
  ];
}

pw.Widget _statementBlock({
  required String title,
  required List<ReportLineItem> incomeItems,
  required List<ReportLineItem> expenseItems,
  required String subtotalLabel,
  required double subtotal,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.SizedBox(height: 4),
      _statementTable(
        headers: const ['', 'Amount'],
        rows: [
          for (final item in [...incomeItems, ...expenseItems])
            pw.TableRow(
              children: [
                _lineCell(
                  item.label,
                  indent: item.indent,
                  color: item.isTotal ? _ink : _slate,
                  bold: item.isTotal,
                ),
                _amountCell(_num(_display(item.amount)),
                    color: item.isTotal ? _ink : _slate),
              ],
            ),
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _lightBg),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  subtotalLabel,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  _num(_display(subtotal)),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: subtotal < 0 ? _red : _ink,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 8),
    ],
  );
}

pw.Widget _lineBlock({
  required String title,
  required List<ReportLineItem> items,
  required double total,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.SizedBox(height: 4),
      _statementTable(
        headers: const ['', 'Amount'],
        rows: [
          for (final item in items)
            pw.TableRow(
              children: [
                _lineCell(
                  item.label,
                  indent: item.indent,
                  color: item.isTotal ? _ink : _slate,
                  bold: item.isTotal,
                ),
                _amountCell(_num(_display(item.amount)),
                    color: item.isTotal ? _ink : _slate),
              ],
            ),
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _lightBg),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  'Total $title',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  _num(_display(total)),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 8),
    ],
  );
}

pw.TableRow _row(
  String label,
  double amount, {
  bool bold = false,
  PdfColor color = _ink,
  String suffix = '',
}) {
  return pw.TableRow(
    children: [
      _lineCell(label, bold: bold, color: color),
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          '${_num(_display(amount))}$suffix',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
          textAlign: pw.TextAlign.right,
        ),
      ),
    ],
  );
}

pw.Widget _lineCell(
  String text, {
  int indent = 0,
  bool bold = false,
  PdfColor color = _ink,
}) {
  return pw.Padding(
    padding: pw.EdgeInsets.fromLTRB(6 + indent * 8, 6, 6, 6),
    child: pw.Text(
      _sanitize(text),
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
      textAlign: pw.TextAlign.left,
    ),
  );
}

pw.Widget _amountCell(String text, {PdfColor color = _ink}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 9, color: color),
      textAlign: pw.TextAlign.right,
    ),
  );
}

// ---------------------------------------------------------------------------
// Chart painters (origin bottom-left, y up)
// ---------------------------------------------------------------------------

class _Slice {
  const _Slice(this.label, this.value, this.color);
  final String label;
  final double value;
  final PdfColor color;
}

const _sliceColors = [
  PdfColor.fromInt(0xFFF97316),
  PdfColor.fromInt(0xFF3B82F6),
  PdfColor.fromInt(0xFF10B981),
  PdfColor.fromInt(0xFF8B5CF6),
  PdfColor.fromInt(0xFFEF4444),
  PdfColor.fromInt(0xFFF59E0B),
  PdfColor.fromInt(0xFF06B6D4),
  PdfColor.fromInt(0xFF84CC16),
];

void _paintDonut(PdfGraphics canvas, double w, double h, List<_Slice> slices) {
  final total = slices.fold<double>(0, (s, sl) => s + sl.value);
  if (total <= 0) return;
  final cx = w / 2;
  final cy = h / 2;
  final outer = (h / 2) - 6;
  final inner = outer * 0.58;
  var start = -math.pi / 2;
  const segments = 40;
  for (final slice in slices) {
    final sweep = (slice.value / total) * 2 * math.pi;
    if (sweep <= 0) continue;
    canvas.setFillColor(slice.color);
    canvas.moveTo(
      cx + outer * math.cos(start),
      cy + outer * math.sin(start),
    );
    for (var i = 1; i <= segments; i++) {
      final a = start + sweep * i / segments;
      canvas.lineTo(cx + outer * math.cos(a), cy + outer * math.sin(a));
    }
    for (var i = segments; i >= 0; i--) {
      final a = start + sweep * i / segments;
      canvas.lineTo(cx + inner * math.cos(a), cy + inner * math.sin(a));
    }
    canvas.fillPath();
    start += sweep;
  }
  // Donut hole
  canvas
    ..setFillColor(PdfColors.white)
    ..drawEllipse(cx, cy, inner * 0.55, inner * 0.55)
    ..fillPath();
}

void _paintGauge(
  PdfGraphics canvas,
  double w,
  double h,
  double ratio,
  PdfColor color,
) {
  final cx = w / 2;
  final cy = h / 2;
  final radius = w / 2 - 8;
  canvas
    ..setLineWidth(10)
    ..setLineCap(PdfLineCap.round)
    ..setLineJoin(PdfLineJoin.round);
  _strokeArc(canvas, cx, cy, radius, -math.pi / 2, 2 * math.pi, _borderGrey);
  _strokeArc(
    canvas,
    cx,
    cy,
    radius,
    -math.pi / 2,
    ratio.clamp(0.0, 1.0) * 2 * math.pi,
    color,
  );
}

void _strokeArc(
  PdfGraphics canvas,
  double cx,
  double cy,
  double r,
  double from,
  double sweep,
  PdfColor color,
) {
  const segments = 60;
  canvas
    ..setStrokeColor(color)
    ..moveTo(cx + r * math.cos(from), cy + r * math.sin(from));
  for (var i = 1; i <= segments; i++) {
    final a = from + sweep * i / segments;
    canvas.lineTo(cx + r * math.cos(a), cy + r * math.sin(a));
  }
  canvas.strokePath();
}

String _maxBarLabel(List<GroupedBar> bars) {
  var maxAbs = 0.0;
  for (final b in bars) {
    maxAbs = math.max(maxAbs, _display(b.income).abs());
    maxAbs = math.max(maxAbs, _display(b.expense).abs());
  }
  return '$_code ${_num(maxAbs)} max';
}

void _paintBars(PdfGraphics canvas, double w, double h, List<GroupedBar> bars) {
  if (bars.isEmpty) return;
  const padL = 10.0;
  const padR = 10.0;
  const padT = 14.0;
  const padB = 16.0;
  final plotW = w - padL - padR;
  final plotH = h - padT - padB;
  var maxAbs = 0.0;
  for (final b in bars) {
    maxAbs = math.max(maxAbs, _display(b.income).abs());
    maxAbs = math.max(maxAbs, _display(b.expense).abs());
  }
  if (maxAbs <= 0) return;
  final groupW = plotW / bars.length;
  final barW = (groupW * 0.26).clamp(2.0, 10.0);

  for (var g = 1; g <= 4; g++) {
    final y = padB + plotH * g / 4;
    canvas
      ..setStrokeColor(_borderGrey)
      ..setLineWidth(0.4)
      ..drawLine(padL, y, w - padR, y)
      ..strokePath();
  }

  for (var i = 0; i < bars.length; i++) {
    final income = _display(bars[i].income).abs();
    final expense = _display(bars[i].expense).abs();
    final cx = padL + groupW * (i + 0.5);
    if (income > 0) {
      final bh = (income / maxAbs) * plotH;
      canvas
        ..setFillColor(_green)
        ..drawRect(cx - barW - 1, padB, barW, bh)
        ..fillPath();
    }
    if (expense > 0) {
      final bh = (expense / maxAbs) * plotH;
      canvas
        ..setFillColor(_red)
        ..drawRect(cx + 1, padB, barW, bh)
        ..fillPath();
    }
  }
}

void _paintLine(
  PdfGraphics canvas,
  double w,
  double h,
  List<double> values,
  PdfColor color,
) {
  if (values.length < 2) return;
  final minV = values.reduce(math.min);
  final maxV = values.reduce(math.max);
  final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
  const padL = 14.0;
  const padR = 14.0;
  const padT = 12.0;
  const padB = 16.0;
  final plotW = w - padL - padR;
  final plotH = h - padT - padB;

  PdfPoint at(int i) {
    final x = padL + plotW * (values.length == 1 ? 0.5 : i / (values.length - 1));
    final y = padB + plotH * ((values[i] - minV) / range);
    return PdfPoint(x, y);
  }

  for (var g = 1; g <= 3; g++) {
    final y = padB + plotH * g / 4;
    canvas
      ..setStrokeColor(_borderGrey)
      ..setLineWidth(0.4)
      ..drawLine(padL, y, w - padR, y)
      ..strokePath();
  }

  canvas
    ..setFillColor(PdfColor(color.red, color.green, color.blue, 0.15))
    ..moveTo(at(0).x, padB);
  for (var i = 0; i < values.length; i++) {
    final p = at(i);
    canvas.lineTo(p.x, p.y);
  }
  canvas.lineTo(at(values.length - 1).x, padB);
  canvas.fillPath();

  canvas
    ..setStrokeColor(color)
    ..setLineWidth(1.2)
    ..moveTo(at(0).x, at(0).y);
  for (var i = 1; i < values.length; i++) {
    final p = at(i);
    canvas.lineTo(p.x, p.y);
  }
  canvas.strokePath();
}

void _paintForecast(
  PdfGraphics canvas,
  double w,
  double h,
  List<double> values,
  int firstForecast,
) {
  if (values.length < 2) return;
  final minV = values.reduce(math.min);
  final maxV = values.reduce(math.max);
  final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
  const padL = 14.0;
  const padR = 14.0;
  const padT = 12.0;
  const padB = 16.0;
  final plotW = w - padL - padR;
  final plotH = h - padT - padB;

  PdfPoint at(int i) {
    final x = padL + plotW * (values.length == 1 ? 0.5 : i / (values.length - 1));
    final y = padB + plotH * ((values[i] - minV) / range);
    return PdfPoint(x, y);
  }

  final solidEnd = firstForecast.clamp(1, values.length - 1);

  canvas
    ..setStrokeColor(_forecastActual)
    ..setLineWidth(1.2)
    ..moveTo(at(0).x, at(0).y);
  for (var i = 1; i <= solidEnd; i++) {
    final p = at(i);
    canvas.lineTo(p.x, p.y);
  }
  canvas.strokePath();

  if (solidEnd < values.length - 1) {
    canvas
      ..setStrokeColor(_forecastTail)
      ..setLineWidth(1.2)
      ..setLineDashPattern(const [3, 3])
      ..moveTo(at(solidEnd).x, at(solidEnd).y);
    for (var i = solidEnd + 1; i < values.length; i++) {
      final p = at(i);
      canvas.lineTo(p.x, p.y);
    }
    canvas
      ..strokePath()
      ..setLineDashPattern(const []);
  }
}

List<(double, double, String)> _lineLabels(List<double> values, double height) {
  if (values.isEmpty) return [];
  final minV = values.reduce(math.min);
  final maxV = values.reduce(math.max);
  return [
    (14, height - 18, _num(minV)),
    (_pageWidth - 70, height - 18, _num(maxV)),
  ];
}
