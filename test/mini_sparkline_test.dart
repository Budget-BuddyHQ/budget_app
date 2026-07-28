import 'package:budget_app/widgets_custom_lotties/mini_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the class of fl_chart crash MiniSparkline was
/// built to replace (imaNNeo/fl_chart#1739, #774: "Unsupported operation:
/// Infinity or NaN" in the axis/grid interval math). MiniSparkline has no
/// axis/interval computation at all, so it should render cleanly at every
/// pathological input a real market feed or a narrow layout could produce.
void main() {
  Future<void> pump(
    WidgetTester tester,
    List<double> values, {
    double width = 300,
    double height = 60,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: MiniSparkline(values: values, color: Colors.green),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders normal price history without error', (tester) async {
    await pump(tester, [100, 102, 101, 105, 103, 108]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles an empty list without error', (tester) async {
    await pump(tester, const []);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles a single point without error', (tester) async {
    await pump(tester, [42]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles every value being identical (zero range)', (
    tester,
  ) async {
    await pump(tester, [50, 50, 50, 50]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles NaN and Infinity mixed into real values', (
    tester,
  ) async {
    await pump(tester, [10, double.nan, 20, double.infinity, 15]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles zero width without error', (tester) async {
    await pump(tester, [1, 2, 3], width: 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles zero height without error', (tester) async {
    await pump(tester, [1, 2, 3], height: 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles a huge value range without error', (tester) async {
    await pump(tester, [1, 1000000, 2, 999999, 3]);
    expect(tester.takeException(), isNull);
  });
}
