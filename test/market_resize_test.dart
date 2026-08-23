import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/dashboard_shell.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/stock_market_page.dart';
import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

List<LiveQuote> _fakeQuotes() {
  final now = DateTime.now();
  const symbols = <(String, String, double, double)>[
    ('AAPL', 'Apple Inc.', 1900.0, 1.2),
    ('MSFT', 'Microsoft Corp.', 4100.0, -0.8),
    ('SPY', 'SPDR S&P 500 ETF', 5400.0, 0.4),
    ('KO', 'Coca-Cola Co.', 620.0, 0.1),
    ('TSLA', 'Tesla Inc.', 2400.0, -2.6),
    ('SBUX', 'Starbucks Corp.', 850.0, -0.3),
  ];
  return [
    for (final (symbol, company, price, pct) in symbols)
      LiveQuote(
        symbol: symbol,
        company: company,
        current: price,
        change: price * pct / 100,
        percentChange: pct,
        high: price * 1.02,
        low: price * 0.98,
        open: price * 0.995,
        previousClose: price / (1 + pct / 100),
        fetchedAt: now,
      ),
  ];
}

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserStatsController>(
        create: (_) => UserStatsController(service: SupabaseService.instance),
      ),
      ChangeNotifierProvider<AppSettingsController>(
        create: (_) => AppSettingsController(),
      ),
      ChangeNotifierProvider<MarketDataService>(
        create: (_) => MarketDataService()..seedQuotesForTest(_fakeQuotes()),
      ),
      ChangeNotifierProxyProvider<UserStatsController, DailyPlanController>(
        create: (context) =>
            DailyPlanController(context.read<UserStatsController>()),
        update: (_, userStats, previous) =>
            previous ?? DailyPlanController(userStats),
      ),
      ChangeNotifierProxyProvider<UserStatsController, MoneyHabitController>(
        create: (context) =>
            MoneyHabitController(context.read<UserStatsController>()),
        update: (_, userStats, previous) =>
            previous ?? MoneyHabitController(userStats),
      ),
    ],
    child: MaterialApp(theme: AppTheme.getLightTheme(), home: child),
  );
}

/// Sizes a desktop window can actually be dragged through, smallest last.
/// `main.dart` sets a 340x480 minimum, so everything down to that is reachable
/// by a user with a mouse.
const List<Size> _shrinkSteps = <Size>[
  Size(1280, 800),
  Size(1024, 768),
  Size(820, 640),
  Size(640, 560),
  Size(500, 520),
  Size(420, 500),
  Size(340, 480),
];

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // The rest of the layout sweep sets a viewport *before* the first pump, so
  // every widget is built once at its final size. Dragging a desktop window
  // smaller is a different code path: the tree is already mounted, and it
  // relayouts with state (tab controllers, scroll positions, animations)
  // carried over. That path had no coverage at all.
  //
  // This also asserts on *every* exception rather than only "overflowed by"
  // messages — the sweep quietly discards anything else, so a null-check
  // failure during build would leave it reporting clean.
  testWidgets('Market Board survives being dragged down to the minimum size', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = _shrinkSteps.first;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const StockMarketPage()));
    await tester.pump(const Duration(milliseconds: 300));

    for (final size in _shrinkSteps.skip(1)) {
      tester.view.physicalSize = size;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        errors.map((e) => e.exception.toString()),
        isEmpty,
        reason:
            'shrinking to ${size.width.toInt()}x${size.height.toInt()} threw',
      );
    }
  });

  testWidgets(
    'Dashboard shell survives being dragged down to the minimum size',
    (tester) async {
      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousOnError);

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = _shrinkSteps.first;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const DashboardShell()));
      await tester.pump(const Duration(milliseconds: 300));

      for (final size in _shrinkSteps.skip(1)) {
        tester.view.physicalSize = size;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          errors.map((e) => e.exception.toString()),
          isEmpty,
          reason:
              'shrinking dashboard to ${size.width.toInt()}x'
              '${size.height.toInt()} threw',
        );
      }
    },
  );

  testWidgets('every Market Board tab survives the same shrink', (
    tester,
  ) async {
    const tabs = <String>['Trade', 'Orders', 'P&L', 'Analytics'];

    for (final tab in tabs) {
      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = _shrinkSteps.first;

      await tester.pumpWidget(_wrap(const StockMarketPage()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(tab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      for (final size in _shrinkSteps.skip(1)) {
        tester.view.physicalSize = size;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      FlutterError.onError = previousOnError;
      expect(
        errors.map((e) => e.exception.toString()),
        isEmpty,
        reason: 'the $tab tab threw while the window was being shrunk',
      );
    }

    tester.view.reset();
  });
}
