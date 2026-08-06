import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/messages.pigeon.dart';
import 'package:firebase_core_platform_interface/src/pigeon/test_api.dart';

import 'package:pj1/firebase_options.dart';
import 'package:pj1/pages/add_transaction_page.dart';
import 'package:pj1/services/home_widget_service.dart';
import 'package:pj1/state/finance_app_state.dart';
import 'package:pj1/utils/currency_settings.dart';

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

Widget _wrap(Widget child, FinanceAppState state) {
  return FinanceAppScope(
    state: state,
    revision: 0,
    child: MaterialApp(home: child),
  );
}

Color? _textColor(WidgetTester tester, String label) {
  final text = tester.widget<Text>(find.text(label));
  return text.style?.color;
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

  group('AddTransactionPage.initialIsIncome', () {
    testWidgets('starts on the Expense tab by default', (tester) async {
      final state = FinanceAppState();
      addTearDown(state.dispose);
      await tester.pumpWidget(_wrap(const AddTransactionPage(), state));
      await tester.pumpAndSettle();

      const amber = Color(0xFFF59E0B);
      expect(_textColor(tester, 'Expense'), amber);
      expect(_textColor(tester, 'Income'), isNot(amber));
    });

    testWidgets('starts on the Income tab when initialIsIncome is true', (
      tester,
    ) async {
      final state = FinanceAppState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        _wrap(const AddTransactionPage(initialIsIncome: true), state),
      );
      await tester.pumpAndSettle();

      const amber = Color(0xFFF59E0B);
      expect(_textColor(tester, 'Income'), amber);
      expect(_textColor(tester, 'Expense'), isNot(amber));
    });
  });

  group('HomeWidgetService.snapshotJson', () {
    test('preformats values with the active display currency', () {
      CurrencySettings.update(code: 'BDT', rates: {'BDT': 123.5, 'USD': 1});
      final json = HomeWidgetService.snapshotJson(
        balance: 100.0,
        income: 50.0,
        expense: 30.0,
        currencyCode: 'BDT',
        uid: 'user-1',
      );
      expect(json, contains('"uid":"user-1"'));
      expect(json, contains('"currency":"BDT"'));
      expect(json, contains('"balance":"৳12,350"'));
      expect(json, contains('"income":"৳6,175"'));
      expect(json, contains('"expense":"৳3,705"'));
    });

    test('strips decimal points while keeping full values', () {
      CurrencySettings.update(code: 'BDT', rates: {'BDT': 123.5, 'USD': 1});
      // 100.16 USD = 12369.76 BDT -> rounded to whole taka, full value shown.
      final json = HomeWidgetService.snapshotJson(
        balance: 100.16,
        income: 50.5,
        expense: 0.4,
        currencyCode: 'BDT',
        uid: 'user-1',
      );
      expect(json, contains('"balance":"৳12,370"'));
      expect(json, contains('"income":"৳6,237"'));
      expect(json, contains('"expense":"৳49"'));
      expect(json, isNot(contains('.')));
    });

    test('omits the uid for signed-out users', () {
      CurrencySettings.update(code: 'USD', rates: {'USD': 1});
      final json = HomeWidgetService.snapshotJson(
        balance: 0,
        income: 0,
        expense: 0,
        currencyCode: 'USD',
        uid: null,
      );
      expect(json, contains('"uid":null'));
      expect(json, contains('"balance":"\$0"'));
    });
  });
}
