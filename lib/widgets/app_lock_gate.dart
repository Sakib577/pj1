import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/biometric_lock_service.dart';
import '../state/finance_app_state.dart';

/// Keeps authenticated app content behind the phone's native biometric prompt.
class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;
  bool? _settingSeen;
  bool _shouldLockOnResume = false;
  bool _autoPromptScheduled = false;
  bool _unlockedThisSession = false;
  final Completer<void> _unlockReady = Completer<void>();
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user == null) return;
      if (FinanceAppScope.of(context).biometricLockEnabled) {
        _scheduleAutomaticUnlock();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = FinanceAppScope.of(context).biometricLockEnabled;
    if (enabled == _settingSeen) return;
    _settingSeen = enabled;
    if (!enabled) {
      if (mounted) setState(() => _locked = false);
      _completeUnlock();
    } else if (FirebaseAuth.instance.currentUser != null) {
      if (BiometricLockService.instance.wasRecentlyAuthenticated) {
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _shouldLockOnResume = true;
      _unlockedThisSession = false;
    } else if (state == AppLifecycleState.resumed && _shouldLockOnResume) {
      _shouldLockOnResume = false;
      final enabled = FinanceAppScope.of(context).biometricLockEnabled;
      if (enabled && FirebaseAuth.instance.currentUser != null) {
        _scheduleAutomaticUnlock();
      }
    }
  }

  void _scheduleAutomaticUnlock() {
    if (_autoPromptScheduled || _authenticating || !mounted) return;
    if (_unlockedThisSession) return;
    if (BiometricLockService.instance.wasRecentlyAuthenticated) {
      _completeUnlock();
      return;
    }
    _autoPromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPromptScheduled = false;
      if (!mounted || !FinanceAppScope.of(context).biometricLockEnabled) {
        return;
      }
      if (FirebaseAuth.instance.currentUser != null) {
        _lockAndAuthenticate();
      }
    });
  }

  /// Signals that the biometric requirement has been satisfied (or is not
  /// needed) for the current lock session.
  void _completeUnlock() {
    if (!_unlockReady.isCompleted) _unlockReady.complete();
    _unlockedThisSession = true;
  }

  Future<void> _lockAndAuthenticate() async {
    if (_authenticating || !mounted) return;
    setState(() => _locked = true);
    _authenticating = true;
    final success = await BiometricLockService.instance.authenticate();
    _authenticating = false;
    if (!mounted) return;
    if (success) {
      setState(() => _locked = false);
      _completeUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = FinanceAppScope.of(context).biometricLockEnabled;
    final user = FirebaseAuth.instance.currentUser;
    if (!enabled || user == null || !_locked) {
      return _AppLockScope(
        unlocked: true,
        unlockReady: _unlockReady.future,
        child: widget.child,
      );
    }

    return _AppLockScope(
      unlocked: false,
      unlockReady: _unlockReady.future,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5EF),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(height: 18),
                const Text(
                  'App locked',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unlock with your phone\'s fingerprint or face authentication.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _authenticating ? null : _lockAndAuthenticate,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock'),
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

  /// Completes once the app has been verified (or biometric lock is disabled),
  /// so prompts only appear after the biometric verification.
  Future<void> get appLockUnlockReady => _AppLockScope.unlockReadyFrom(this);
}
