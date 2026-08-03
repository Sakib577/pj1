import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pj1/widgets/morphing_fab.dart';

class FabPosition {
  final double alignX;
  final double bottomOffset;
  final double rightPadding;
  const FabPosition(this.alignX, this.bottomOffset, this.rightPadding);

  static FabPosition lerp(FabPosition a, FabPosition b, double t) {
    return FabPosition(
      a.alignX + (b.alignX - a.alignX) * t,
      a.bottomOffset + (b.bottomOffset - a.bottomOffset) * t,
      a.rightPadding + (b.rightPadding - a.rightPadding) * t,
    );
  }
}

class FabPositionTween extends Tween<FabPosition> {
  FabPositionTween({required FabPosition super.end});

  @override
  FabPosition lerp(double t) {
    final a = begin ?? end ?? const FabPosition(0, 0, 0);
    final b = end ?? begin ?? const FabPosition(0, 0, 0);
    return FabPosition.lerp(a, b, t);
  }
}

// Tab positions (mirrors DashboardPage: Home = center notch, rest = endFloat)
const double _navH = 80.0;
const FabPosition _homePos     = FabPosition(0.0, _navH - 28, 0.0);
const FabPosition _endFloat    = FabPosition(1.0, _navH + 16, 16.0);

void main() {
  group('FabPositionTween', () {
    test('lerps alignX halfway Home → endFloat', () {
      final tween = FabPositionTween(end: _endFloat)..begin = _homePos;
      expect(tween.lerp(0.5).alignX, closeTo(0.5, 0.001));
    });

    test('no movement when staying on endFloat (tab 1→2→3)', () {
      final tween = FabPositionTween(end: _endFloat)..begin = _endFloat;
      final mid = tween.lerp(0.5);
      expect(mid.alignX, closeTo(1.0, 0.001));
      expect(mid.bottomOffset, closeTo(_navH + 16, 0.001));
      expect(mid.rightPadding, closeTo(16.0, 0.001));
    });

    test('fully settled at Home is center notch', () {
      final tween = FabPositionTween(end: _homePos)..begin = _homePos;
      final pos = tween.lerp(1.0);
      expect(pos.alignX, closeTo(0.0, 0.001));
    });

    test('fully settled at endFloat is far right', () {
      final tween = FabPositionTween(end: _endFloat)..begin = _endFloat;
      final pos = tween.lerp(1.0);
      expect(pos.alignX, closeTo(1.0, 0.001));
      expect(pos.rightPadding, closeTo(16.0, 0.001));
    });
  });

  group('MorphingFab', () {
    testWidgets('renders compact (icon only) when no label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: MorphingFab(onPressed: () {})))),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('New budget'), findsNothing);
    });

    testWidgets('renders extended pill when label provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(
          child: MorphingFab(label: 'New budget', onPressed: () {}),
        ))),
      );
      await tester.pumpAndSettle();
      expect(find.text('New budget'), findsOneWidget);
    });

    testWidgets('label cross-fades between extended labels (budget→goal)', (tester) async {
      String label = 'New budget';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(
          child: StatefulBuilder(builder: (ctx, set) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MorphingFab(label: label, onPressed: () {}),
              ElevatedButton(onPressed: () => set(() => label = 'New goal'), child: const Text('switch')),
            ],
          )),
        ))),
      );
      await tester.pumpAndSettle();
      expect(find.text('New budget'), findsOneWidget);

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();
      expect(find.text('New goal'), findsOneWidget);
      expect(find.text('New budget'), findsNothing);
    });

    testWidgets('label cross-fades between goal→debt', (tester) async {
      String label = 'New goal';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(
          child: StatefulBuilder(builder: (ctx, set) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MorphingFab(label: label, onPressed: () {}),
              ElevatedButton(onPressed: () => set(() => label = 'Add Debt'), child: const Text('switch')),
            ],
          )),
        ))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();
      expect(find.text('Add Debt'), findsOneWidget);
      expect(find.text('New goal'), findsNothing);
    });

    testWidgets('morphs wider compact → extended', (tester) async {
      String? label;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(
          child: StatefulBuilder(builder: (ctx, set) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MorphingFab(label: label, onPressed: () {}),
              ElevatedButton(onPressed: () => set(() => label = 'Add Debt'), child: const Text('extend')),
            ],
          )),
        ))),
      );
      await tester.pumpAndSettle();
      final before = tester.getSize(find.byType(MorphingFab)).width;
      await tester.tap(find.text('extend'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(MorphingFab)).width, greaterThan(before));
    });
  });
}
