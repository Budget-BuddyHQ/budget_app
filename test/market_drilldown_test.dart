import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/stock_market_page.dart';
import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Tapping a stock — anywhere it appears — opens its chart and news, and
/// tapping a past trade opens what it actually was.
///
/// **Asked for as:** *"make it so the user can click on like a stock that they
/// like Apple on the main screen and it shows them a more detailed [look] on
/// their history with the stock and news, etc... and same for the transaction
/// history."* Before this, that detail screen (`OrderTicketPage` — chart,
/// company background, news) only opened from the Buy or Sell button. Looking
/// at a stock and trading it were the same tap, and a past trade's own row had
/// no tap at all even though its full description was already sitting in
/// `LedgerTransaction.description`, unused.
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

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget wrap(Widget child, {UserStats? stats}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserStatsController>(
          create: (_) {
            final controller = UserStatsController(
              service: SupabaseService.instance,
            );
            if (stats != null) controller.seedStatsForTest(stats);
            return controller;
          },
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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> show(WidgetTester tester, {UserStats? stats}) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const StockMarketPage(), stats: stats));
    await settle(tester);
  }

  group('the Trade Board', () {
    testWidgets('tapping a stock — not the buttons — opens its chart', (
      tester,
    ) async {
      await show(tester);
      await tester.tap(find.text('Trade'));
      await settle(tester);

      // The card's header (symbol + company), not "Buy Shares" or "Sell
      // Shares" — a player looking, not trading.
      await tester.tap(find.textContaining('Apple Inc.').first);
      await settle(tester);

      expect(find.text('Company background & news'), findsOneWidget);
      // Nothing was bought: still on the ticket, not back on the board.
      expect(find.text('Buy Shares'), findsNothing);
    });
  });

  group('a holding', () {
    testWidgets('tapping the position opens its chart, not just its numbers', (
      tester,
    ) async {
      final base = UserStats.defaults('test_user');
      final stats = base.copyWith(
        holdings: {...base.holdings, 'stock_AAPL': 2.0},
        spendingHabits: {
          ...base.spendingHabits,
          'cost_basis': {'stock_AAPL': 3200},
        },
      );
      await show(tester, stats: stats);
      // Portfolio is the first tab, so no navigation needed. The trending
      // strip above the holdings list shows the bare symbol too, so this
      // matches the holding row specifically, not that shortcut.
      expect(find.textContaining('AAPL • '), findsOneWidget);

      await tester.tap(find.textContaining('AAPL • '));
      await settle(tester);

      expect(find.text('Company background & news'), findsOneWidget);
    });
  });

  group('a past trade', () {
    testWidgets('tapping it shows the full description, not just the total', (
      tester,
    ) async {
      final base = UserStats.defaults('test_user');
      final stats = base.copyWith(
        transactions: [
          LedgerTransaction(
            id: 'txn_1',
            title: 'Bought AAPL',
            description: 'Opened 2 share(s) of Apple Inc. for 3800 gold.',
            amount: -3800,
            createdAt: DateTime(2026, 1, 15, 9, 30),
            category: 'invest',
          ),
          ...base.transactions,
        ],
      );
      await show(tester, stats: stats);
      await tester.tap(find.text('Orders'));
      await settle(tester);

      // The row shows the symbol and the action separately ("AAPL", "Buy"),
      // not the transaction's own title text.
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('Buy'), findsOneWidget);
      await tester.tap(find.text('AAPL'));
      await settle(tester);

      expect(
        find.text('Opened 2 share(s) of Apple Inc. for 3800 gold.'),
        findsOneWidget,
      );
      expect(find.textContaining('live chart & news'), findsOneWidget);

      // And it actually leads there.
      await tester.tap(find.textContaining('live chart & news'));
      await settle(tester);
      expect(find.text('Company background & news'), findsOneWidget);
    });
  });
}
