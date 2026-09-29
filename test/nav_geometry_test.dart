import 'package:budget_app/screens_minigames_admin_etc/onboarding/coach_mark.dart';
import 'package:budget_app/ui/widgets/pop_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the tutorial thinks the bottom tabs are, against where they are.
///
/// **The bug this exists for.** The spotlight could not use a `GlobalKey` to
/// find a tab — `MainNavigation` keeps every screen alive in an `IndexedStack`
/// and each renders its own bar, so one static key per tab attaches to several
/// widgets at once — so it computed the rectangle from constants instead: full
/// screen width divided by the tab count, 72px tall, flush to the bottom.
///
/// Every one of those was wrong. The bar is 80-106px tall depending on the
/// viewport, inset 14px each side, and lifted 6-12px off the bottom. So the
/// highlight was the wrong size *and* offset on both axes, and drew its box
/// beside the tab it was pointing at. It was reported three times and the
/// comment above the code claimed it was "exact rather than a guess".
///
/// It is exact now because there is only one copy of the numbers. This is what
/// holds that: it renders a real bar, measures a real tab, and compares.
void main() {
  /// Renders [PopNavBar] at [size] and returns the real on-screen rect of the
  /// tab labelled [label], plus what [PopNavBar.tabRect] predicts for it.
  Future<({Rect actual, Rect predicted})> measure(
    WidgetTester tester,
    Size size,
    int index,
    String label, {
    EdgeInsets padding = EdgeInsets.zero,
  }) async {
    // Never measure the *active* tab. It is painted through a
    // `Transform.scale(1.16)` and lifted six pixels, and while a transform
    // does not change layout it does move what `getRect` reports for
    // anything under it. The spotlight covers the whole cell either way, so
    // the cell is what this is about.
    final activeIndex = (index + 1) % PopNavBar.appTabs.length;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size, padding: padding),
        // A `Scaffold`'s `bottomNavigationBar` slot, because that is how the
        // app mounts it. An `Align` was the first attempt and it quietly
        // broke the measurement: `Align` hands down *loose* width, so the bar
        // shrink-wrapped its row instead of spanning the screen and every
        // column came out narrower than in the real app.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: PopNavBar(
              items: PopNavBar.appTabs,
              activeIndex: activeIndex,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // The tile's own hit area, which is what a player aims at.
    // `.first` is the closest InkWell ancestor — the tile's own. `.last`
    // walks all the way out to the enclosing `Material`, which is the whole
    // bar.
    final tile = find
        .ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        )
        .first;
    return (
      actual: tester.getRect(tile),
      predicted: PopNavBar.tabRect(size, padding, index),
    );
  }

  group('the predicted tab rect matches the real one', () {
    for (final (name, size) in const <(String, Size)>[
      ('large phone', Size(430, 932)),
      ('mid phone', Size(390, 844)),
      ('small phone', Size(320, 568)),
      ('tablet', Size(834, 1112)),
      ('short landscape', Size(844, 390)),
    ]) {
      testWidgets('on a $name', (tester) async {
        final r = await measure(tester, size, 1, 'Arcade');

        // Horizontal: the tile sits inside its predicted column. Not an exact
        // match, because the tile carries a small margin of its own — but it
        // must be *within* the prediction, not beside it, which is exactly
        // what went wrong before.
        expect(
          r.actual.center.dx,
          closeTo(r.predicted.center.dx, 2),
          reason: '$name: the highlight is centered on the wrong column',
        );
        expect(
          r.predicted.left,
          lessThanOrEqualTo(r.actual.left + 1),
          reason: '$name: prediction starts right of the real tab',
        );
        expect(
          r.predicted.right,
          greaterThanOrEqualTo(r.actual.right - 1),
          reason: '$name: prediction ends left of the real tab',
        );

        // Vertical: the real tab has to be inside the predicted band. The old
        // 72px-flush-to-the-bottom guess failed here by tens of pixels.
        expect(
          r.predicted.top,
          lessThanOrEqualTo(r.actual.top + 1),
          reason: '$name: prediction starts below the real tab '
              '(${r.predicted.top} vs ${r.actual.top})',
        );
        expect(
          r.predicted.bottom,
          greaterThanOrEqualTo(r.actual.bottom - 1),
          reason: '$name: prediction ends above the real tab '
              '(${r.predicted.bottom} vs ${r.actual.bottom})',
        );
      });
    }
  });

  testWidgets('it survives a bottom safe-area inset', (tester) async {
    // A phone with a home indicator. The bar sits above it; a prediction that
    // ignores the inset points below the tab.
    const size = Size(390, 844);
    final r = await measure(
      tester,
      size,
      3,
      'Learn',
      padding: const EdgeInsets.only(bottom: 34),
    );
    expect(r.predicted.top, lessThanOrEqualTo(r.actual.top + 1));
    expect(r.predicted.bottom, greaterThanOrEqualTo(r.actual.bottom - 1));
  });

  testWidgets('every tab lands on its own tab', (tester) async {
    // An off-by-one in the index maths would still pass the tests above for
    // the middle tab, so each is checked against its own label.
    const size = Size(430, 932);
    const labels = <String>['Life', 'Arcade', 'Home', 'Learn', 'Style'];
    for (var i = 0; i < labels.length; i++) {
      final r = await measure(tester, size, i, labels[i]);
      expect(
        r.actual.center.dx,
        closeTo(r.predicted.center.dx, 2),
        reason: 'tab $i ("${labels[i]}") is predicted in the wrong column',
      );
    }
  });

  testWidgets('the spotlight helper agrees with the bar', (tester) async {
    // `TutorialTargets.navTabRect` is the entry point the overlay actually
    // calls, and it used to hold its own copy of the numbers.
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late BuildContext ctx;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: size),
        child: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(
      TutorialTargets.navTabRect(ctx, 2),
      PopNavBar.tabRect(size, EdgeInsets.zero, 2),
    );
  });
}
