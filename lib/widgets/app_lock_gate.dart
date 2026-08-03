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
  bool _settingSeen = false;
  bool _shouldLockOnResume = false;
  bool _autoPromptScheduled = false;
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
    } else if (FirebaseAuth.instance.currentUser != null) {
      if (!BiometricLockService.instance.wasRecentlyAuthenticated) {
        _scheduleAutomaticUnlock();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _shouldLockOnResume = true;
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
    if (BiometricLockService.instance.wasRecentlyAuthenticated) return;
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

  Future<void> _lockAndAuthenticate() async {
    if (_authenticating || !mounted) return;
    setState(() => _locked = true);
    _authenticating = true;
    final success = await BiometricLockService.instance.authenticate();
    _authenticating = false;
    if (!mounted) return;
    if (success) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = FinanceAppScope.of(context).biometricLockEnabled;
    final user = FirebaseAuth.instance.currentUser;
    if (enabled && user != null && !_locked && !_authenticating) {
      _scheduleAutomaticUnlock();
    }
    if (!enabled || user == null || !_locked) {
      return _AppLockScope(unlocked: true, child: widget.child);
    }

    return _AppLockScope(
      unlocked: false,
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
  const _AppLockScope({required this.unlocked, required super.child});

  final bool unlocked;

  static bool unlockedFrom(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppLockScope>()?.unlocked ??
      true;

  @override
  bool updateShouldNotify(_AppLockScope oldWidget) =>
      unlocked != oldWidget.unlocked;
}

extension AppLockContext on BuildContext {
  bool get appLockUnlocked => _AppLockScope.unlockedFrom(this);
}
