import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../pages/add_transaction_page.dart';
import '../services/app_lock_service.dart';
import '../services/home_widget_service.dart';
import '../state/finance_app_state.dart';
import 'app_lock_gate.dart';

/// Routes home-screen widget taps into the running app.
///
/// It sits inside [AppLockGate], so it only routes once the app lock has been
/// shown and released (when one is enabled). The pending intent is buffered in
/// [HomeWidgetService] so it survives the router being unmounted while the
/// lock screen is on top.
///
/// * Balance card → no special action (the app simply opens to the dashboard).
/// * Income / Expense cards → push [AddTransactionPage] with the matching tab
///   preselected.
class WidgetDeepLinkRouter extends StatefulWidget {
  const WidgetDeepLinkRouter({super.key, required this.child});

  final Widget child;

  @override
  State<WidgetDeepLinkRouter> createState() => _WidgetDeepLinkRouterState();
}

class _WidgetDeepLinkRouterState extends State<WidgetDeepLinkRouter>
    with WidgetsBindingObserver {
  bool _resumed = true;
  bool _routing = false;
  Completer<void>? _resumeGate;

  @override
  void initState() {
    super.initState();
    _resumed =
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused;
    WidgetsBinding.instance.addObserver(this);
    HomeWidgetService.instance.init();
    HomeWidgetService.instance.setOnPendingChanged(() {
      if (mounted) unawaited(_consumePending());
    });
    unawaited(_consumePending());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _resumed = false;
      _resumeGate = null;
    } else if (state == AppLifecycleState.resumed) {
      _resumed = true;
      final gate = _resumeGate;
      if (gate != null && !gate.isCompleted) gate.complete();
      unawaited(_consumePending());
    }
  }

  Future<void> _consumePending() async {
    final intent = await HomeWidgetService.instance.pullPendingIntent();
    if (intent == null) return;
    await _routeIntent(intent);
  }

  Future<void> _routeIntent(HomeWidgetIntent intent) async {
    if (_routing) return;
    _routing = true;
    try {
      if (!intent.isAddTransaction) return;
      // Widget taps arrive while the activity is paused: wait until it is
      // foregrounded before doing anything.
      var gate = _resumeGate;
      if (gate == null) {
        gate = _resumeGate = Completer<void>();
        if (_resumed) gate.complete();
      }
      await gate.future;
      if (!mounted) return;
      // Give the lock gate a frame to (re)arm the lock after resume / the
      // initial build, so routing never races ahead of the lock screen.
      await SchedulerBinding.instance.endOfFrame;
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return;
      // Wait until the initial data load has settled AND the app is unlocked
      // for this session (a configured lock must have been shown and released).
      // Security: the gate engages the lock about a frame after lockType loads
      // (which happens just before isLoadingData settles), so the app can
      // briefly report "unlocked" here. gating on unlockedThisSession means a
      // widget tap can never open past a lock that is about to engage; if the
      // lock takes over, this router is unmounted and the buffered intent is
      // retried from initState after the user verifies.
      while (mounted && !_appReadyAndUnlocked()) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !user.emailVerified) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AddTransactionPage(initialIsIncome: intent.isIncome),
        ),
      );
    } finally {
      _routing = false;
      if (mounted) {
        HomeWidgetService.instance.consumePendingIntent();
      }
    }
  }

  bool _appReadyAndUnlocked() {
    if (!mounted) return false;
    final scope = context.getInheritedWidgetOfExactType<FinanceAppScope>();
    if (scope == null) return false;
    if (scope.state.isLoadingData) return false;
    final lockType = scope.state.lockType;
    if (lockType == LockType.none) return true;
    // A lock is configured: it is only safe to route once it has been shown
    // and successfully released this session (the gate unmounts this router
    // while the lock screen is on top and re-mounts it after verification).
    return context.appLockUnlockedNow &&
        context.appLockUnlockedThisSessionNow;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
