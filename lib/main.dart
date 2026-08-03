import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'auth_gate.dart';
import 'firebase_options.dart';
import 'services/currency_preferences.dart';
import 'state/finance_app_state.dart';

// Entry point: Flutter starts running the app from here.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Restore the display currency and its last known rates before any UI is
  // built, so an offline launch never renders a selected sign with USD values.
  await CurrencyPreferences.hydrate();
  // Enable Firestore offline persistence so the app keeps working (reads and
  // locally-buffered writes) while disconnected, then syncs on reconnect.
  await _enableOfflinePersistence();
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
        home: widget.home ?? const AuthGate(),
      ),
    );
  }
}
