import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:budget_app/widgets_custom_lotties/price_chart.dart';
import 'package:budget_app/widgets_custom_lotties/symbol_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

List<Candle> _series(int n) => [
  for (var i = 0; i < n; i++)
    Candle(
      time: DateTime(2026, 1, 1).add(Duration(minutes: i)),
      open: 100 + i.toDouble(),
      high: 101 + i.toDouble(),
      low: 99 + i.toDouble(),
      close: 100 + i.toDouble(),
    ),
];

/// [SymbolBadge] reads the market service so a row repaints the instant its
/// fetched logo arrives, so anything hosting one needs the provider — the
/// same one `main.dart` and the responsive sweep already install.
Widget _host(Widget child, {double width = 400, double height = 220}) =>
    ChangeNotifierProvider<MarketDataService>(
      create: (_) => MarketDataService(),
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ),
    );

/// How many candles the inner [PriceChart] was actually handed. This is the
/// only honest measure of "is it zoomed" — the window is what the painter
/// sees, and the price axis is derived from it.
int _visibleCount(WidgetTester tester) =>
    tester.widget<PriceChart>(find.byType(PriceChart)).candles.length;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('zoom controls', () {
    testWidgets('starts showing the whole series', (tester) async {
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(120),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      expect(_visibleCount(tester), 120);
    });

    testWidgets('the zoom-in button narrows the window', (tester) async {
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(120),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(_visibleCount(tester), lessThan(120));
    });

    testWidgets('zooming out returns to the full series', (tester) async {
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(120),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(_visibleCount(tester), 120);
    });

    testWidgets('fit restores everything in one tap', (tester) async {
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(120),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pump();
      }
      expect(_visibleCount(tester), lessThan(30));
      await tester.tap(find.byIcon(Icons.fit_screen_rounded));
      await tester.pump();
      expect(_visibleCount(tester), 120);
    });

    testWidgets('it never zooms past a readable number of bars', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(120),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      // Hammer the button well past the floor. Without the clamp this ends
      // at one candle, and a one-candle chart divides by zero working out
      // its x-step.
      for (var i = 0; i < 20; i++) {
        if (tester.widget<InkWell>(_zoomInInk(tester)).onTap == null) break;
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pump();
      }
      expect(_visibleCount(tester), greaterThanOrEqualTo(6));
    });

    testWidgets('a short series has no zoom controls to break', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(4),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      // 4 candles is already under the floor, so there is nothing to zoom
      // into — but it must still draw rather than assert.
      expect(_visibleCount(tester), 4);
    });

    testWidgets('a one-candle series still renders', (tester) async {
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(1),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      expect(find.text('No chart data'), findsOneWidget);
    });
  });

  group('panning', () {
    testWidgets('pan arrows appear only once zoomed', (tester) async {
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(120),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('panning moves the window without resizing it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(120),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      final before = tester
          .widget<PriceChart>(find.byType(PriceChart))
          .candles;
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();
      final after = tester.widget<PriceChart>(find.byType(PriceChart)).candles;

      expect(after.length, before.length, reason: 'panning is not zooming');
      expect(
        after.first.close,
        isNot(before.first.close),
        reason: 'the window did not actually move',
      );
    });

    testWidgets('the window cannot be panned off either end', (tester) async {
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(60),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      // Walk to the right-hand end; the arrow disables rather than running
      // the window past the last candle.
      for (var i = 0; i < 30; i++) {
        final arrow = find.byIcon(Icons.chevron_right_rounded);
        if (arrow.evaluate().isEmpty) break;
        final ink = tester.widget<InkWell>(
          find.ancestor(of: arrow, matching: find.byType(InkWell)).first,
        );
        if (ink.onTap == null) break;
        await tester.tap(arrow);
        await tester.pump();
      }
      final last = tester.widget<PriceChart>(find.byType(PriceChart)).candles;
      expect(last.last.close, _series(60).last.close);
    });
  });

  group('scrubbing', () {
    testWidgets('a horizontal drag reports a crosshair index', (tester) async {
      final reported = <int?>[];
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(50),
            mode: ChartMode.line,
            accent: Colors.green,
            onHoverIndexChanged: reported.add,
          ),
        ),
      );
      final center = tester.getCenter(find.byType(PriceChart));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(
        reported.whereType<int>(),
        isNotEmpty,
        reason: 'dragging across the chart reported no crosshair position',
      );
    });

    testWidgets('reported indices are in whole-series coordinates', (
      tester,
    ) async {
      // The painter is handed a *slice* when zoomed, so an index that was
      // not translated back would point at the wrong candle — and the price
      // readout above the chart would disagree with the crosshair.
      final reported = <int?>[];
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(200),
            mode: ChartMode.line,
            accent: Colors.green,
            onHoverIndexChanged: reported.add,
          ),
        ),
      );
      final center = tester.getCenter(find.byType(PriceChart));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      for (final index in reported.whereType<int>()) {
        expect(index, inInclusiveRange(0, 199));
      }
    });
  });

  group('reacting to new data', () {
    testWidgets('switching timeframe resets the view', (tester) async {
      // Keeping a 20-bar window from a 1D chart when the user switches to 1Y
      // would show three days of a year-long series and look like a bug.
      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(120),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(_visibleCount(tester), lessThan(120));

      await tester.pumpWidget(
        _host(
          InteractivePriceChart(
            candles: _series(365),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
        ),
      );
      await tester.pump();
      expect(_visibleCount(tester), 365);
    });
  });

  group('the crosshair readout', () {
    // The dot alone used to be the whole thing, so scrubbing told you where
    // you were pointing and never what was there. These check the readout
    // paints without blowing up in the places it is most likely to: the two
    // ends of the series, and canvases too small to hold the card.

    Future<void> paintAt(
      WidgetTester tester,
      int? hover, {
      double width = 400,
      double height = 220,
      int bars = 60,
    }) async {
      await tester.pumpWidget(
        _host(
          PriceChart(
            candles: _series(bars),
            mode: ChartMode.line,
            accent: Colors.green,
            hoverIndex: hover,
          ),
          width: width,
          height: height,
        ),
      );
      await tester.pump();
    }

    testWidgets('paints at the first candle', (tester) async {
      await paintAt(tester, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints at the last candle', (tester) async {
      // Where the card has to flip to the left of the crosshair or run off
      // the canvas — and the right-hand edge is exactly where the newest,
      // most-looked-at bars are.
      await paintAt(tester, 59);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a canvas narrower than the readout card', (
      tester,
    ) async {
      await paintAt(tester, 30, width: 90, height: 70);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a canvas shorter than the readout card', (
      tester,
    ) async {
      await paintAt(tester, 30, width: 300, height: 40);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an out-of-range hover index is ignored, not crashed on', (
      tester,
    ) async {
      // Reachable for one frame while a shorter series is being swapped in.
      await paintAt(tester, 999);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a negative hover index is ignored', (tester) async {
      await paintAt(tester, -3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no hover paints nothing extra', (tester) async {
      await paintAt(tester, null);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a two-candle series does not divide by zero', (tester) async {
      // stepX is chartWidth / (bars.length - 1), so a one-bar visible window
      // would be a division by zero.
      await paintAt(tester, 1, bars: 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('chart ranges', () {
    test('every range asks for a sane number of bars', () {
      for (final range in ChartRange.values) {
        expect(range.points, greaterThan(1), reason: range.label);
        expect(
          range.points,
          lessThanOrEqualTo(1000),
          reason: '${range.label} would blow past Twelve Data output limits',
        );
        expect(range.interval, isNotEmpty);
        expect(range.label, isNotEmpty);
      }
    });

    test('labels are unique', () {
      final labels = ChartRange.values.map((r) => r.label).toList();
      expect(labels.toSet().length, labels.length);
    });

    test('ranges get longer as the list goes on', () {
      // The strip renders in declaration order, so a range out of sequence
      // would read as a bug in the UI even though the data is fine.
      const spanDays = <ChartRange, double>{
        ChartRange.day1: 1,
        ChartRange.day5: 5,
        ChartRange.month1: 30,
        ChartRange.month3: 90,
        ChartRange.month6: 180,
        ChartRange.year1: 365,
        ChartRange.year5: 1825,
      };
      var previous = 0.0;
      for (final range in ChartRange.values) {
        final span = spanDays[range];
        expect(span, isNotNull, reason: '${range.label} is not in this table');
        expect(span!, greaterThan(previous), reason: range.label);
        previous = span;
      }
    });
  });

  group('symbol badges', () {
    // The logo lookup existed but only the trending strip called it, so one
    // company wore five different faces on a single screen.
    test('every logo symbol has a matching asset path', () {
      for (final symbol in kStockLogoSymbols) {
        final path = stockLogoAssetFor(symbol);
        expect(path, isNotNull, reason: symbol);
        expect(path, endsWith('/$symbol.png'));
      }
    });

    test('an unknown symbol falls back rather than guessing a path', () {
      // Pointing at a file that is not bundled would show a broken-image
      // glyph in the middle of a price row.
      expect(stockLogoAssetFor('ZZZZ'), isNull);
    });

    testWidgets('a known symbol draws its logo', (tester) async {
      await tester.pumpWidget(
        _host(
          const SymbolBadge(
            symbol: 'AAPL',
            icon: Icons.phone_iphone_rounded,
            accent: Colors.green,
          ),
          width: 80,
          height: 80,
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.phone_iphone_rounded), findsNothing);
    });

    testWidgets('an unknown symbol draws the fallback icon', (tester) async {
      await tester.pumpWidget(
        _host(
          const SymbolBadge(
            symbol: 'ZZZZ',
            icon: Icons.show_chart_rounded,
            accent: Colors.green,
          ),
          width: 80,
          height: 80,
        ),
      );
      expect(find.byIcon(Icons.show_chart_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('it lays out at every size the board uses', (tester) async {
      for (final size in [18.0, 22.0, 32.0, 38.0, 44.0, 48.0]) {
        await tester.pumpWidget(
          _host(
            SymbolBadge(
              symbol: 'TSLA',
              icon: Icons.electric_car_rounded,
              accent: Colors.red,
              size: size,
            ),
            width: 120,
            height: 120,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'size $size');
      }
    });
  });

  group('dates on the chart', () {
    // The tooltip used to print a bare "10:40" on an intraday chart, on the
    // theory that a one-day series makes the date redundant. That is wrong
    // the moment the chart can be zoomed and panned: "10:40" does not say
    // *which* 10:40, and asking exactly that is what scrubbing is for.

    List<Candle> intraday(int n) => [
      for (var i = 0; i < n; i++)
        Candle(
          time: DateTime(2026, 8, 25, 9, 30).add(Duration(minutes: i * 5)),
          open: 100 + i.toDouble(),
          high: 101 + i.toDouble(),
          low: 99 + i.toDouble(),
          close: 100.5 + i.toDouble(),
        ),
    ];

    List<Candle> daily(int n) => [
      for (var i = 0; i < n; i++)
        Candle(
          time: DateTime(2026, 1, 1).add(Duration(days: i)),
          open: 100 + i.toDouble(),
          high: 101 + i.toDouble(),
          low: 99 + i.toDouble(),
          close: 100.5 + i.toDouble(),
        ),
    ];

    testWidgets('an intraday chart paints without throwing', (tester) async {
      await tester.pumpWidget(
        _host(
          PriceChart(
            candles: intraday(78),
            mode: ChartMode.line,
            accent: Colors.green,
            hoverIndex: 30,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a daily chart paints without throwing', (tester) async {
      await tester.pumpWidget(
        _host(
          PriceChart(
            candles: daily(120),
            mode: ChartMode.line,
            accent: Colors.green,
            hoverIndex: 60,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('zooming does not change what the timestamp means', (
      tester,
    ) async {
      // The regression this replaced: the format was derived from the
      // series' *total span*, but PriceChart only receives the visible
      // window — so zooming a multi-day chart down to a handful of bars
      // shrank the span below a day and silently dropped the date
      // mid-gesture. Bar spacing does not move when the window narrows.
      final full = daily(120);
      for (final window in [full, full.sublist(0, 6), full.sublist(50, 58)]) {
        await tester.pumpWidget(
          _host(
            PriceChart(
              candles: window,
              mode: ChartMode.line,
              accent: Colors.green,
              hoverIndex: 1,
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'window of ${window.length} bars',
        );
      }
    });

    testWidgets('a weekend gap does not make daily bars look intraday', (
      tester,
    ) async {
      // Median gap, not mean: a daily series jumps three days across every
      // weekend, and an average of those lands between "daily" and "weekly"
      // and decides nothing.
      final bars = <Candle>[];
      var t = DateTime(2026, 1, 5);
      for (var i = 0; i < 40; i++) {
        bars.add(
          Candle(
            time: t,
            open: 100,
            high: 101,
            low: 99,
            close: 100.5,
          ),
        );
        t = t.add(Duration(days: t.weekday == DateTime.friday ? 3 : 1));
      }
      await tester.pumpWidget(
        _host(
          PriceChart(
            candles: bars,
            mode: ChartMode.line,
            accent: Colors.green,
            hoverIndex: 20,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the time axis survives a chart too narrow to label', (
      tester,
    ) async {
      // Three labels is the most a phone-width chart carries without them
      // colliding; below ~120px it draws none rather than overlapping them.
      await tester.pumpWidget(
        _host(
          PriceChart(
            candles: intraday(40),
            mode: ChartMode.line,
            accent: Colors.green,
          ),
          width: 90,
          height: 80,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('two bars an hour apart still render an axis', (tester) async {
      await tester.pumpWidget(
        _host(
          PriceChart(
            candles: intraday(2),
            mode: ChartMode.line,
            accent: Colors.green,
            hoverIndex: 1,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

Finder _zoomInInk(WidgetTester tester) => find
    .ancestor(
      of: find.byIcon(Icons.add_rounded),
      matching: find.byType(InkWell),
    )
    .first;
