import 'package:flutter/foundation.dart';

import '../../state/finance_app_state.dart';
import '../models/analytics_models.dart';
import '../repositories/analytics_repository.dart';
import '../utils/date_ranges.dart';

/// Computes and caches the [StatisticsBundle] for an active [DateRange].
///
/// The controller only recomputes when the underlying data identity OR the
/// selected range actually changes, so re-builds of the statistics page are
/// cheap. It reads from the in-memory [FinanceAppState] and never writes.
class StatisticsController extends ChangeNotifier {
  StatisticsController({required FinanceAppState state}) : _state = state {
    _state.addListener(_onStateChanged);
  }

  final FinanceAppState _state;
  final AnalyticsRepository _repository = const AnalyticsRepository();
  DateRange _range = const DateRange.preset(DateRangePreset.last30);
  String _cacheKey = '';
  StatisticsBundle? _cache;

  DateRange get range => _range;

  void setRange(DateRange range) {
    if (range.label == _range.label && range.custom == _range.custom) {
      if (!range.custom ||
          (range.start == _range.start && range.end == _range.end)) {
        return;
      }
    }
    _range = range;
    _cache = null;
    // Recompute eagerly so charts get instant data.
    _compute();
  }

  /// Returns the cached (or freshly computed) bundle for [range].
  StatisticsBundle get bundle {
    _computeIfStale();
    return _cache!;
  }

  StatisticsBundle computeFor(DateTime now) {
    final window = buildWindowFromDateRange(now: now, range: _range);
    return _repository.bundleFor(_state, window);
  }

  void _compute() {
    final window = buildWindowFromDateRange(
      now: DateTime.now(),
      range: _range,
    );
    _cache = _repository.bundleFor(_state, window);
    _cacheKey = _identityKey;
    notifyListeners();
  }

  void _computeIfStale() {
    if (_cache == null || _identityKey != _cacheKey) {
      _compute();
    }
  }

  void _onStateChanged() {
    // Ignore notifications that do not change the raw transaction shape.
    _computeIfStale();
  }

  /// A cheap identity hash over the data that feeds the analytics engine.
  String get _identityKey {
    final txns = _state.transactions;
    final len = txns.length;
    final lastTs = txns.isEmpty
        ? 0
        : (txns.first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .millisecondsSinceEpoch;
    return '$len:$lastTs:${_state.budgets.length}:${_state.debts.length}:'
        '${_state.savingsGoals.length}';
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }
}