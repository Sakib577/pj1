import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'auth_gate.dart';
import 'firebase_options.dart';
import 'services/currency_preferences.dart';
import 'state/finance_app_state.dart';
import 'widgets/app_lock_gate.dart';

// Global error handler flag — keep at top level so it survives hot restart.
// Holds the most recent crash message so the UI can render it instead of a
// white/frozen screen in release builds.
String? _lastError;

/// Catches **all** unhandled errors (sync + async) and renders a red error
/// screen instead of a white/frozen screen in release builds.
void _setupGlobalErrorHandlers() {
  // ---------- Flutter framework errors (e.g. overflow, null widget) ----------
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    // In release mode, show a visible screen AND still call the original
    // handler so the error still reaches the console / platform dispatcher.
    _lastError = details.exceptionAsString();
    originalOnError?.call(details);
  };

  // ---------- Dart unhandled async errors (e.g. futures without catch) ----------
  // PlatformDispatcher.onError is used instead of runZonedGuarded so the whole
  // app stays in the root zone. runZonedGuarded forked a new zone, so a reload
  // or hot restart that re-ran main() initialized the binding in an old zone
  // while runApp ran in the new one, triggering the "zone mismatch" warning.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _lastError = '$error\n\n$stack';
    // Re-run the app with the error visible (the root widget checks for this),
    // matching the previous runZonedGuarded error handler behaviour.
    runApp(const MyApp());
    return true;
  };
}

// Entry point: Flutter starts running the app from here.
Future<void> main() async {
  // Initialize the binding in the root zone so it matches the zone used by
  // runApp below (also on Reload / hot restart, which re-enter main()).
  WidgetsFlutterBinding.ensureInitialized();
  _setupGlobalErrorHandlers();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // -- Firestore offline persistence MUST be configured BEFORE any other
    //    Firestore access. If any Firestore call happens first (e.g. inside a
    //    StatefulWidget field initializer), the default settings lock in and
    //    this call throws because settings can only be set once. In release
    //    builds this can silently fail and leave the app with no local cache,
    //    producing a white screen on first launch after login.
    await _enableOfflinePersistence();
    // Restore the display currency and its last known rates before any UI is
    // built, so an offline launch never renders a selected sign with USD values.
    await CurrencyPreferences.hydrate();
  } catch (error, stack) {
    // Startup failed: render the error screen instead of a white page.
    _lastError = '$error\n\n$stack';
  }
  runApp(const MyApp());
}

// Best-effort: if the platform does not support durable local storage (e.g.
// some web browsers) the app still runs fully online.
Future<void> _enableOfflinePersistence() async {
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (_) {
    // Ignore: offline support is an enhancement, not a hard requirement.
  }
}

/// Shows a visible red error screen when a crash has been captured, instead
/// of a white/frozen screen. Tapping "Reload" restarts the app.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF5F5),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The app encountered an error. Details are shown below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: SelectableText(
                    message.length > 2000
                        ? '${message.substring(0, 2000)}...\n\n(truncated)'
                        : message,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    _lastError = null;
                    main();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Root widget: keeps global app settings like theme and initial page.
class MyApp extends StatefulWidget {
  const MyApp({super.key, this.home});

  final Widget? home;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FinanceAppState _appState = FinanceAppState();
  int _stateRevision = 0;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _stateRevision++);
      });
    } else {
      setState(() => _stateRevision++);
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If a crash was captured, show the error screen instead of a white page.
    final message = _lastError;
    if (message != null) {
      return _ErrorScreen(message: message);
    }
    const seed = Color(0xFFF59E0B);
    return FinanceAppScope(
      state: _appState,
      revision: _stateRevision,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Expense Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed),
          scaffoldBackgroundColor: const Color(0xFFF7F5EF),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Color(0xFF0F172A),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF0F172A)),
          ),
        ),
        home: AppLockGate(child: widget.home ?? const AuthGate()),
      ),
    );
  }
}