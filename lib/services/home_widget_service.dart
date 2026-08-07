import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/finance_app_state.dart';
import '../utils/currency_formatters.dart';

/// A user-visible intent delivered by the native home-screen widget.
class HomeWidgetIntent {
  const HomeWidgetIntent({required this.action, required this.isIncome});

  /// Matches the native action constants in `MainActivity.kt`.
  static const dashboardAction =
      'com.sakib.expensetracker.action.DASHBOARD';
  static const addTransactionAction =
      'com.sakib.expensetracker.action.ADD_TRANSACTION';

  final String action;
  final bool isIncome;

  bool get isAddTransaction => action == addTransactionAction;
}

/// Bridges the app and the native home-screen widget.
///
/// Data flow (single source of truth stays in Flutter/Dart):
///  * [updateFromState] formats the exact values the dashboard renders (via
///    `formatCurrency`) into a compact JSON snapshot and stores it in
///    SharedPreferences. The native `AppWidgetProvider` reads that snapshot and
///    simply renders the strings — it never recomputes totals or reformats.
///  * Native deep links (Balance / Income / Expense card taps) arrive either as
///    a push (`pendingAction`) or a pull (`getPendingAction`), and are surfaced
///    to the app through the [HomeWidgetIntent] callback.
class HomeWidgetService {
  HomeWidgetService._();

  static final HomeWidgetService instance = HomeWidgetService._();

  static const String _channelName = 'com.sakib.expensetracker/widget';

  /// Key written through the `shared_preferences` plugin, which stores it in
  /// the `FlutterSharedPreferences` file under the `flutter.` prefix. The
  /// native widget reads the same entry with that prefix applied.
  static const String _snapshotKey = 'widget_snapshot';

  final MethodChannel _channel = const MethodChannel(_channelName);

  String? _lastJson;
  bool _initialized = false;

  /// Latest deep-link intent received but not yet consumed by the router. Kept
  /// in Dart memory because the routing widget is unmounted while the app lock
  /// screen is showing — the intent must survive until the lock is released.
  HomeWidgetIntent? _pendingIntent;
  DateTime? _pendingAt;

  /// Called whenever a push arrives so the router can route immediately even
  /// when the app is already in the foreground.
  void Function()? _onPendingChanged;

  bool get isInitialized => _initialized;

  /// Registers the native-to-Dart handler. Safe to call repeatedly (the router
  /// re-mounts after each lock unlock).
  void init() {
    _initialized = true;
    _channel.setMethodCallHandler(_onMethodCall);
  }

  /// Sets the callback fired when a new intent push arrives.
  void setOnPendingChanged(void Function() callback) {
    _onPendingChanged = callback;
  }

  Future<void> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'pendingAction':
        final args = call.arguments;
        if (args is Map && _storePending(args)) {
          _onPendingChanged?.call();
        }
      default:
        break;
    }
  }

  bool _storePending(Map<dynamic, dynamic> args) {
    final action = args['action'];
    if (action is! String || action.isEmpty) return false;
    _pendingIntent = HomeWidgetIntent(
      action: action,
      isIncome: args['isIncome'] == true,
    );
    _pendingAt = DateTime.now();
    return true;
  }

  /// Returns the next unconsumed intent without removing it (so it survives
  /// router remounts), falling back to a pull from `MainActivity` for cold
  /// starts where a push can race the Dart side not being ready yet.
  Future<HomeWidgetIntent?> pullPendingIntent() async {
    if (_pendingIntent != null) {
      return _isStale(_pendingAt) ? null : _pendingIntent;
    }
    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('getPendingAction');
      if (result != null && result.isNotEmpty) {
        _storePending(result);
        return _pendingIntent;
      }
    } catch (_) {
      // Not running on a supported platform (e.g. tests / web): ignore.
    }
    return null;
  }

  /// Clears the buffered intent after it has been routed (or intentionally
  /// skipped). Subsequent pulls then return null.
  void consumePendingIntent() {
    _pendingIntent = null;
    _pendingAt = null;
  }

  /// Clears the buffered intent, but only if it is still [intent] (by
  /// identity). Routing consumes the intent it just handled without erasing a
  /// newer one that arrived while it was in flight — the newer tap is routed
  /// next instead (last tap wins).
  void consumePendingIntentIf(HomeWidgetIntent intent) {
    if (identical(_pendingIntent, intent)) {
      consumePendingIntent();
    }
  }

  bool _isStale(DateTime? at) =>
      at != null && DateTime.now().difference(at) > const Duration(minutes: 2);

  /// Writes a compact, preformatted snapshot whenever the app state changes.
  ///
  /// Only fires when the payload actually changed (deduplicated via
  /// [_lastJson]) and only once the initial load has settled, so a launch
  /// never clobbers the last good widget values with transient zeroes.
  Future<void> updateFromState(FinanceAppState state) async {
    if (state.isLoadingData) return;
    final json = _buildSnapshotJson(state);
    if (json == _lastJson) return;
    _lastJson = json;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_snapshotKey, json);
    } catch (_) {
      return;
    }
    // Ask the native side to re-render every live widget with the new values.
    try {
      await _channel.invokeMethod<void>('updateWidgets');
    } catch (_) {
      // Widget channel unavailable (e.g. tests): the stored snapshot is still
      // fresh for the next widget refresh.
    }
  }

  String _buildSnapshotJson(FinanceAppState state) {
    final user = FirebaseAuth.instance.currentUser;
    return snapshotJson(
      balance: state.currentBalance,
      income: state.stats[0].amount,
      expense: state.stats[1].amount,
      currencyCode: state.currencyCode,
      uid: user?.uid,
    );
  }

  /// Builds the exact payload written for the widget. Exposed for tests; the
  /// values are already formatted with the app's `formatCurrencyNoCents`
  /// (no decimal points, full values), so the native side renders them
  /// verbatim and never reformats.
  @visibleForTesting
  static String snapshotJson({
    required double balance,
    required double income,
    required double expense,
    required String currencyCode,
    String? uid,
  }) {
    return jsonEncode(<String, Object?>{
      'version': 1,
      'uid': uid,
      'currency': currencyCode,
      'balance': formatCurrencyNoCents(balance),
      'income': formatCurrencyNoCents(income),
      'expense': formatCurrencyNoCents(expense),
    });
  }
}
