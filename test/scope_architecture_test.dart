import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirrors the FinanceAppScope architecture used in main.dart: an
// InheritedNotifier exposing a ChangeNotifier, where the notifier defers
// notifyListeners() to just after the frame to avoid Flutter's
// InheritedElement '_dependents.isEmpty' assertion during route/dialog pops.
class Repo extends ChangeNotifier {
  int count = 0;
  bool _notifyScheduled = false;
  @override
  void notifyListeners() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      super.notifyListeners();
    });
  }
}

class RepoScope extends InheritedNotifier<Repo> {
  const RepoScope({super.key, required Repo notifier, required super.child})
      : super(notifier: notifier);
  static Repo of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RepoScope>()!.notifier!;
}

Widget harness() {
  final repo = Repo();
  return RepoScope(
    notifier: repo,
    child: MaterialApp(
      home: Builder(builder: (context) {
        final r = RepoScope.of(context);
        return Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
                r.count++;
                r.notifyListeners();
              },
              child: Text('Open ${r.count}'),
            ),
          ),
        );
      }),
    ),
  );
}

void main() {
  testWidgets('dialog closes and notifier fires without assertion', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Open 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dependent rebuilds when notifier fires', (tester) async {
    await tester.pumpWidget(harness());
    expect(find.text('Open 0'), findsOneWidget);
    final repo = RepoScope.of(tester.element(find.text('Open 0')));
    repo.count++;
    repo.notifyListeners();
    await tester.pump();
    await tester.pump();
    expect(find.text('Open 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple rapid notifies do not crash', (tester) async {
    await tester.pumpWidget(harness());
    final repo = RepoScope.of(tester.element(find.text('Open 0')));
    for (var i = 0; i < 50; i++) {
      repo.notifyListeners();
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
