import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../state/finance_app_state.dart';
import 'pin_entry_sheet.dart';

/// Keeps authenticated app content behind the configured app lock (biometric
/// or PIN). A new lock session is created each time the app needs verification,
/// so anything awaiting [AppLockContext.appLockUnlockReady] always waits on the
/// *current* session and never a stale, already-completed future.
class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;
  LockType? _settingSeen;
  bool _shouldLockOnResume = false;
  bool _autoPromptScheduled = false;
  bool _unlockedThisSession = false;
  int _lockSessionId = 0;
  Completer<void>? _sessionCompleter;

  /// Replaced with a fresh, uncompleted future each time a lock session
  /// begins, so dependents always wait on the current session.
  final ValueNotifier<Future<void>> _unlockReady =
      ValueNotifier<Future<void>>(Future<void>.value());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unlockReady.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lockType = FinanceAppScope.of(context).lockType;
    if (lockType == _settingSeen) return;
    _settingSeen = lockType;
    if (lockType == LockType.none) {
      // Lock is (still) disabled: no session exists, so do NOT mark the app
      // as "unlocked this session" — that flag would later suppress the first
      // real lock prompt when the user enables the lock.
      _unlockedThisSession = false;
      if (mounted) setState(() => _locked = false);
      _completeSession();
    } else if (FirebaseAuth.instance.currentUser != null) {
      if (AppLockService.instance.wasRecentlyAuthenticated) {
        _completeUnlock();
      } else {
        _scheduleAutomaticUnlock();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The system biometric sheet itself triggers inactive/paused lifecycle
    // events. Ignore those so the app never re-prompts right after a
    // successful verification (which caused duplicate prompts).
    if (_authenticating) return;
    // Only a real background (paused) counts; incidental events like pulling
    // down the notification shade (inactive) must not re-lock the app.
    if (state == AppLifecycleState.paused) {
      _shouldLockOnResume = true;
      _unlockedThisSession = false;
    } else if (state == AppLifecycleState.resumed && _shouldLockOnResume) {
      _shouldLockOnResume = false;
      final lockType = FinanceAppScope.of(context).lockType;
      if (lockType != LockType.none &&
          FirebaseAuth.instance.currentUser != null) {
        _scheduleAutomaticUnlock();
      }
    }
  }

  void _scheduleAutomaticUnlock() {
    if (_autoPromptScheduled || _authenticating || !mounted) return;
    if (_unlockedThisSession) return;
    if (AppLockService.instance.wasRecentlyAuthenticated) {
      _completeUnlock();
      return;
    }
    // Begin the lock session synchronously here, not only in the async prompt
    // below, so that anything awaiting AppLockContext.appLockUnlockReady (e.g.
    // the dashboard's due-payment check) sees an unfinished session future and
    // blocks until this verification actually completes.
    _beginLockSession();
    _autoPromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPromptScheduled = false;
      if (!mounted) return;
      final lockType = FinanceAppScope.of(context).lockType;
      if (lockType == LockType.none) return;
      if (FirebaseAuth.instance.currentUser != null) {
        _lockAndAuthenticate(lockType);
      }
    });
  }

  /// Starts a fresh lock session: increments the session id and swaps in a new
  /// unfinished future so current waiters block on *this* verification. If a
  /// session is already pending, it is left untouched (idempotent).
  void _beginLockSession() {
    if (_sessionCompleter != null) return;
    _lockSessionId++;
    _unlockedThisSession = false;
    final completer = Completer<void>();
    _sessionCompleter = completer;
    _unlockReady.value = completer.future;
  }

  /// Completes any pending session future without marking the current session
  /// as verified (used when the lock is disabled).
  void _completeSession() {
    if (_sessionCompleter != null && !_sessionCompleter!.isCompleted) {
      _sessionCompleter!.complete();
    }
    _sessionCompleter = null;
  }

  /// Completes the current session's unlock requirement.
  void _completeUnlock() {
    _completeSession();
    _unlockedThisSession = true;
  }

  Future<void> _lockAndAuthenticate(LockType lockType) async {
    if (_authenticating || !mounted) return;
    _beginLockSession();
    final sessionId = _lockSessionId;
    setState(() {
      _locked = true;
      _authenticating = true;
    });
    final success = await _authenticateWith(lockType);
    if (!mounted) return;
    if (sessionId != _lockSessionId) {
      setState(() => _authenticating = false);
      return;
    }
    setState(() {
      _authenticating = false;
      if (success) {
        _locked = false;
        _completeUnlock();
      }
    });
  }

  // Verifies the current session without starting a new one (used by the
  // manual Unlock button on the lock screen).
  Future<void> _unlockNow(LockType lockType) async {
    if (_authenticating || !mounted) return;
    setState(() => _authenticating = true);
    final success = await _authenticateWith(lockType);
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (success) {
        _locked = false;
        _completeUnlock();
      }
    });
  }

  Future<bool> _authenticateWith(LockType lockType) async {
    switch (lockType) {
      case LockType.none:
        return true;
      case LockType.biometric:
        return AppLockService.instance.authenticateBiometric();
      case LockType.pin:
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final pin = await showPinEntrySheet(
          context,
          title: 'Enter your PIN',
          cancelLabel: 'Cancel',
        );
        if (pin == null) return false;
        return AppLockService.instance.verifyPin(uid, pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockType = FinanceAppScope.of(context).lockType;
    final user = FirebaseAuth.instance.currentUser;
    // Safety net: if the user became available (or the lock setting loaded)
    // after didChangeDependencies ran, still schedule the first verification.
    // _scheduleAutomaticUnlock is guarded, so this is a no-op once scheduled
    // or after a successful unlock this session.
    if (lockType != LockType.none &&
        user != null &&
        !_locked &&
        !_unlockedThisSession) {
      _scheduleAutomaticUnlock();
    }
    if (lockType == LockType.none || user == null || !_locked) {
      return _AppLockScope(
        unlocked: true,
        unlockReady: _unlockReady.value,
        child: widget.child,
      );
    }

    final isPin = lockType == LockType.pin;
    return _AppLockScope(
      unlocked: false,
      unlockReady: _unlockReady.value,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5EF),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPin ? Icons.pin_outlined : Icons.lock_outline,
                  size: 64,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 18),
                const Text(
                  'App locked',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  isPin
                      ? 'Unlock with your 4-digit PIN.'
                      : 'Unlock with your phone\'s fingerprint or face '
                            'authentication.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed:
                      _authenticating ? null : () => _unlockNow(lockType),
                  icon: Icon(
                    isPin ? Icons.pin_outlined : Icons.fingerprint,
                  ),
                  label: Text(isPin ? 'Enter PIN' : 'Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppLockScope extends InheritedWidget {
  const _AppLockScope({
    required this.unlocked,
    required this.unlockReady,
    required super.child,
  });

  final bool unlocked;
  final Future<void> unlockReady;

  static bool unlockedFrom(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppLockScope>()?.unlocked ??
      true;

  static Future<void> unlockReadyFrom(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppLockScope>()?.unlockReady ??
      Future<void>.value();

  @override
  bool updateShouldNotify(_AppLockScope oldWidget) =>
      unlocked != oldWidget.unlocked || unlockReady != oldWidget.unlockReady;
}

extension AppLockContext on BuildContext {
  bool get appLockUnlocked => _AppLockScope.unlockedFrom(this);

  /// Completes once the current lock session has been verified (or the app
  /// lock is disabled), so prompts only appear after the lock screen.
  Future<void> get appLockUnlockReady => _AppLockScope.unlockReadyFrom(this);
}
