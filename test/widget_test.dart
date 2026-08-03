import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/messages.pigeon.dart';
import 'package:firebase_core_platform_interface/src/pigeon/test_api.dart';

import 'package:pj1/main.dart';
import 'package:pj1/pages/dashboard_page.dart';
import 'package:pj1/firebase_options.dart';

// Mock the Firebase Core Pigeon host API so tests can initialize Firebase
// without a real native SDK / platform channel.
class _MockFirebaseCoreHostApi extends TestFirebaseCoreHostApi {
  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions options,
  ) async {
    return CoreInitializeResponse(
      name: appName,
      options: options,
      pluginConstants: const <String?, Object?>{},
    );
  }

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async => [];

  @override
  Future<CoreFirebaseOptions> optionsFromResource() async {
    return CoreFirebaseOptions(
      apiKey: 'mock',
      appId: 'mock',
      messagingSenderId: 'mock',
      projectId: 'mock',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Use the built-in Firebase Core test API to avoid real platform channels.
    TestFirebaseCoreHostApi.setUp(_MockFirebaseCoreHostApi());
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  });

  testWidgets('Dashboard renders and opens Add Transaction page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(home: DashboardPage()));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);

    // Tap the FAB to open the Add Transaction page.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-note')), findsOneWidget);
  });
}