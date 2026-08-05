import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/messages.pigeon.dart';
import 'package:firebase_core_platform_interface/src/pigeon/test_api.dart';

import 'package:pj1/analytics/utils/date_ranges.dart';
import 'package:pj1/analytics/widgets/date_range_picker.dart';
import 'package:pj1/analytics/widgets/stat_card.dart';
import 'package:pj1/main.dart';
import 'package:pj1/pages/dashboard_page.dart';
import 'package:pj1/pages/statistics_page.dart';
import 'package:pj1/firebase_options.dart';

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
    TestFirebaseCoreHostApi.setUp(_MockFirebaseCoreHostApi());
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  });

  testWidgets('StatCard renders title and content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(
            title: 'Balance Trend',
            child: Text('content'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Balance Trend'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('Date range picker shows presets', (
    WidgetTester tester,
  ) async {
    DateRange? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                picked = await showStatisticsRangePicker(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Statistics range'), findsOneWidget);
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Custom range'), findsOneWidget);

    await tester.tap(find.text('Last 30 days'));
    await tester.pumpAndSettle();
    expect(picked, isNotNull);
    expect(picked!.label, 'Last 30 days');
  });

  testWidgets('Statistics page renders without exception', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(home: StatisticsPage()),
    );
    await tester.pumpAndSettle();

    // Empty-data state: at least the header renders.
    expect(find.text('Statistics'), findsOneWidget);
  });

  testWidgets('Dashboard drawer opens and shows Statistics item', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(home: DashboardPage()));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);

    // Open the drawer via the menu icon.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Statistics'),
      ),
      findsOneWidget,
    );
  });
}
