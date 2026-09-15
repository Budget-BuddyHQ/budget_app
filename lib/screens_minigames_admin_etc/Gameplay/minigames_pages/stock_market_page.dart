import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../services_backend_and_other_services/market_data_service.dart';
import '../../../services_backend_and_other_services/supabase_service.dart'
    show LedgerTransaction, UserStats;
import '../../../widgets_custom_lotties/game_toast.dart';
import '../../../widgets_custom_lotties/hover_lift.dart';
import '../../../widgets_custom_lotties/mini_sparkline.dart';
import '../../../widgets_custom_lotties/price_chart.dart';
import '../../../widgets_custom_lotties/symbol_badge.dart';
import 'order_ticket_page.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/age_scaled_note.dart';
import '../../../navigation_tools_and_animation/pauses_in_background.dart';

/// Real, tradeable stock: a [LiveQuote] plus the display/trade dressing
/// (icon, accent, thesis, bid-ask spread) that Finnhub doesn't provide.
class _TradeQuote {
  const _TradeQuote({
    required this.symbol,
    required this.company,
    required this.sector,
    required this.currentPrice,
    required this.livePrice,
    required this.changePercent,
    required this.buyCost,
    required this.sellValue,
    required this.history,
    required this.thesis,
    required this.icon,
    required this.accent,
  });

  final String symbol;
  final String company;
  final String sector;

  /// The price trades settle at, in whole coins.
  final int currentPrice;

  /// The same price without the rounding, for display only.
  ///
  /// **Why both.** 10 coins = \$1, so one coin is ten cents — and most of what
  /// a real share does in twenty seconds is smaller than that. Rounded to
  /// whole coins the number sat perfectly still while the percentage beside
  /// it changed, which reads as a broken feed rather than as a quiet market.
  /// Showing one decimal gives it cent resolution, and the *trades* keep using
  /// the integer so nothing about the economy moves.
  final double livePrice;
  final double changePercent;
  final int buyCost;
  final int sellValue;
  final List<int> history;
  final String thesis;
  final IconData icon;
  final Color accent;
}

const Map<String, ({IconData icon, Color accent, String sector, String thesis})>
_kSymbolStyle = {
  'AAPL': (
    icon: Icons.apple,
    accent: Color(0xFFE1BB72),
    sector: 'Technology',
    thesis: 'The iPhone and Mac maker — real earnings, real stock.',
  ),
  'MSFT': (
    icon: Icons.window_rounded,
    accent: Color(0xFF58C7FF),
    sector: 'Technology',
    thesis: 'Windows, Office, and Azure cloud at global scale.',
  ),
  'NKE': (
    icon: Icons.directions_run_rounded,
    accent: Color(0xFFFF8FB1),
    sector: 'Apparel',
    thesis: 'The sneaker and sportswear brand you see everywhere.',
  ),
  'SBUX': (
    icon: Icons.local_cafe_rounded,
    accent: Color(0xFF85EFAC),
    sector: 'Retail',
    thesis: 'The coffee shop on every corner, now a stock you can own.',
  ),
  'DIS': (
    icon: Icons.movie_rounded,
    accent: Color(0xFFB388FF),
    sector: 'Media',
    thesis: 'Movies, parks, and streaming under one roof.',
  ),
  'SPY': (
    icon: Icons.query_stats_rounded,
    accent: Color(0xFFFFD45C),
    sector: 'Index fund',
    thesis: 'Tracks the S&P 500 — 500 companies in one share.',
  ),
  'AMZN': (
    icon: Icons.shopping_cart_rounded,
    accent: Color(0xFFFFB084),
    sector: 'E-commerce',
    thesis: 'Online retail, logistics, and AWS cloud computing.',
  ),
  'GOOGL': (
    icon: Icons.travel_explore_rounded,
    accent: Color(0xFF69C6FF),
    sector: 'Technology',
    thesis: 'Search, ads, YouTube, and Android.',
  ),
  'TSLA': (
    icon: Icons.electric_car_rounded,
    accent: Color(0xFFFF5C5C),
    sector: 'Automotive',
    thesis: 'Electric vehicles and energy storage.',
  ),
  'NFLX': (
    icon: Icons.smart_display_rounded,
    accent: Color(0xFFE1454A),
    sector: 'Media',
    thesis: 'Streaming shows and movies worldwide.',
  ),
  'NVDA': (
    icon: Icons.memory_rounded,
    accent: Color(0xFF7CE07C),
    sector: 'Technology',
    thesis: 'Chips that power gaming and AI.',
  ),
  'META': (
    icon: Icons.groups_rounded,
    accent: Color(0xFF6C9BFF),
    sector: 'Technology',
    thesis: 'Instagram, Facebook, and WhatsApp.',
  ),
  'KO': (
    icon: Icons.local_drink_rounded,
    accent: Color(0xFFFF6B6B),
    sector: 'Beverages',
    thesis: 'The soda you can buy almost anywhere on Earth.',
  ),
  'MCD': (
    icon: Icons.lunch_dining_rounded,
    accent: Color(0xFFFFD45C),
    sector: 'Retail',
    thesis: 'Fast food at global scale, in almost every country.',
  ),
  'PYPL': (
    icon: Icons.account_balance_wallet_rounded,
    accent: Color(0xFF58C7FF),
    sector: 'Financial tech',
    thesis: 'Moves money online for millions of people and stores.',
  ),
  'AMD': (
    icon: Icons.developer_board_rounded,
    accent: Color(0xFFE1454A),
    sector: 'Technology',
    thesis: 'Processors and graphics chips competing with Nvidia and Intel.',
  ),
};

/// Bid-ask spread: what a buyer pays and a seller receives always differ a
/// little, and it widens on more volatile days — without this, buying and
/// selling the same lot back to back was a free, infinite source of gold.
_TradeQuote _tradeQuoteFor(LiveQuote quote) {
  final style = _kSymbolStyle[quote.symbol];
  // Real prices arrive in dollars; the board trades in coins (10 coins = $1).
  final price = coinsForUsd(quote.current);
  final spreadFraction = (0.015 + quote.percentChange.abs() / 100 * 0.5).clamp(
    0.01,
    0.06,
  );
  final buyCost = (price * (1 + spreadFraction / 2)).round();
  final sellValue = math.max(1, (price * (1 - spreadFraction / 2)).round());

  return _TradeQuote(
    symbol: quote.symbol,
    company: quote.company,
    sector: style?.sector ?? 'Public company',
    currentPrice: price,
    livePrice: quote.current * kCoinsPerDollar,
    changePercent: quote.percentChange,
    buyCost: buyCost,
    sellValue: sellValue,
    history: quote.miniSeries.map(coinsForUsd).toList(growable: false),
    thesis: style?.thesis ?? 'A real, publicly traded company.',
    icon: style?.icon ?? Icons.show_chart_rounded,
    accent: style?.accent ?? const Color(0xFF85EFAC),
  );
}

class StockMarketPage extends StatefulWidget {
  const StockMarketPage({super.key});

  @override
  State<StockMarketPage> createState() => _StockMarketPageState();
}

class _StockMarketPageState extends State<StockMarketPage>
    with SingleTickerProviderStateMixin, PausesInBackground {
  late final TabController _tabController;

  /// Polls live prices while the board is open, so quotes and charts move
  /// without the player hitting refresh.
  Timer? _livePoll;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick(force: true));
    // Two seconds behind the cached proxy, five without one. The proxy makes
    // the difference: it holds vendor responses for twelve seconds, so the
    // board's poll rate stops being the same thing as Finnhub's call limit.
    _startLivePoll();
  }

  /// The price poll, started on open and restarted when the app comes back.
  void _startLivePoll() {
    final market = context.read<MarketDataService>();
    _livePoll = Timer.periodic(
      market.usesProxy
          ? MarketDataService.proxyPollInterval
          : MarketDataService.livePollInterval,
      (_) => _tick(),
    );
  }

  @override
  void onAppBackgrounded() {
    // Polling prices for a screen nobody is looking at is somebody's battery
    // and somebody's data plan.
    _livePoll?.cancel();
    _livePoll = null;
  }

  @override
  void onAppForegrounded() {
    if (_livePoll != null) return;
    _startLivePoll();
    _tick(force: true);
  }

  @override
  void dispose() {
    _livePoll?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  /// One live update: refresh quotes, pull real intraday shape for the cards,
  /// settle any resting orders, then record the true net worth so the P&L
  /// curve reflects what actually happened.
  Future<void> _tick({bool force = false}) async {
    if (!mounted) return;
    final market = context.read<MarketDataService>();

    if (force) {
      // The first fill and the pull-to-refresh: everything, once.
      await market.refresh(force: true);
    } else {
      // Otherwise a small batch, weighted to what the player can see.
      //
      // Refreshing all sixteen symbols on a timer spent the whole rate
      // budget on prices that were scrolled off the screen, and capped the
      // board at one update every sixteen seconds. Pinning the holdings
      // means the numbers somebody actually has money in are in every
      // batch; the rest rotate through underneath.
      final stats = context.read<UserStatsController>().stats;
      final owned = <String>{
        for (final entry in stats.holdings.entries)
          if (entry.value != 0 && entry.key.startsWith('stock_'))
            entry.key.substring('stock_'.length),
      };
      // Behind the proxy, one request returns everything and costs one edge
      // invocation, so there is nothing to gain by asking for a subset.
      // Without it, every symbol is a vendor call and the batch cap is the
      // only thing keeping the board inside the rate limit.
      if (market.usesProxy) {
        await market.refresh();
      } else {
        await market.refreshBatch(pinned: owned);
      }
    }
    if (!mounted) return;

    await market.refreshSeries(
      kLiveSymbols.where((s) => s.common).map((s) => s.symbol).toList(),
      force: force,
    );
    if (!mounted) return;

    await _settleWorkingOrders();
    if (!mounted) return;
    await _recordNetWorth();
  }

  /// Snapshots cash + live market value onto the equity curve.
  Future<void> _recordNetWorth() async {
    final controller = context.read<UserStatsController>();
    final market = context.read<MarketDataService>();
    final stats = controller.stats;

    var marketValue = 0.0;
    for (final entry in stats.holdings.entries) {
      if (!entry.key.startsWith('stock_')) continue;
      final quote = market.quoteFor(entry.key.substring(6));
      if (quote == null || !quote.isValid) continue;
      marketValue += entry.value * coinsForUsd(quote.current);
    }
    await controller.recordNetWorth((stats.gold + marketValue).round());
  }

  /// Opens the full-screen order ticket (chart, side, order type, price and
  /// quantity) and settles whatever order comes back from it.
  Future<void> _openOrderTicket({
    required BuildContext context,
    required _TradeQuote quote,
    required bool startAsBuy,
    required int availableGold,
    required double ownedLots,
  }) async {
    final request = await Navigator.of(context).push<OrderRequest>(
      MaterialPageRoute(
        builder: (_) => OrderTicketPage(
          symbol: quote.symbol,
          company: quote.company,
          icon: quote.icon,
          accent: quote.accent,
          lastPrice: quote.currentPrice,
          bidPrice: quote.sellValue,
          askPrice: quote.buyCost,
          ownedLots: ownedLots,
          availableGold: availableGold,
          fallbackSeries: quote.history
              .map((v) => v.toDouble())
              .toList(growable: false),
          startAsBuy: startAsBuy,
        ),
      ),
    );

    if (request == null || !context.mounted) {
      return;
    }

    final controller = context.read<UserStatsController>();
    final totalValue = request.total;

    // A non-marketable limit rests as a working order rather than filling now.
    if (request.isWorking) {
      final result = await controller.placeWorkingOrder(
        symbol: quote.symbol,
        isBuy: request.isBuy,
        quantity: request.quantity,
        limitPrice: request.pricePerShare,
        companyName: quote.company,
      );
      if (!context.mounted) return;
      GameToast.show(
        context,
        title: result.success ? 'Working order placed' : 'Order not placed',
        message: result.success
            ? '${request.isBuy ? 'Buy' : 'Sell'} ${formatShares(request.quantity)} '
                  '${quote.symbol} at ${request.pricePerShare}g is now working. '
                  'It fills when the price reaches your limit.'
            : result.message,
        icon: result.success
            ? Icons.schedule_rounded
            : Icons.info_outline_rounded,
        accent: result.success
            ? const Color(0xFF58C7FF)
            : const Color(0xFFFFB084),
      );
      return;
    }

    final result = switch (request.action) {
      TradeAction.buy => await controller.buyStockLot(
        symbol: quote.symbol,
        goldCost: totalValue,
        companyName: quote.company,
        quantity: request.quantity,
      ),
      TradeAction.sell => await controller.sellStockLot(
        symbol: quote.symbol,
        goldReturn: totalValue,
        companyName: quote.company,
        quantity: request.quantity,
      ),
      TradeAction.short => await controller.shortStockLot(
        symbol: quote.symbol,
        goldCredit: totalValue,
        companyName: quote.company,
        quantity: request.quantity,
      ),
      TradeAction.cover => await controller.coverShortLot(
        symbol: quote.symbol,
        goldCost: totalValue,
        companyName: quote.company,
        quantity: request.quantity,
      ),
    };

    if (!context.mounted) return;

    final actionLabel = switch (request.action) {
      TradeAction.buy => 'Buy order filled',
      TradeAction.sell => 'Sell order filled',
      TradeAction.short => 'Short order filled',
      TradeAction.cover => 'Cover order filled',
    };
    final actionMessage = switch (request.action) {
      TradeAction.buy =>
        'Bought ${formatShares(request.quantity)} share${request.quantity == 1 ? '' : 's'} of ${quote.symbol} for ${totalValue}g.',
      TradeAction.sell =>
        'Sold ${formatShares(request.quantity)} share${request.quantity == 1 ? '' : 's'} of ${quote.symbol} for ${totalValue}g.',
      TradeAction.short =>
        'Shorted ${formatShares(request.quantity)} share${request.quantity == 1 ? '' : 's'} of ${quote.symbol} for ${totalValue}g. Borrow cost is charged daily.',
      TradeAction.cover =>
        'Covered ${formatShares(request.quantity)} share${request.quantity == 1 ? '' : 's'} of ${quote.symbol} for ${totalValue}g.',
    };

    GameToast.show(
      context,
      title: result.success ? actionLabel : 'Trade blocked',
      message: result.success ? actionMessage : result.message,
      icon: result.success
          ? switch (request.action) {
              TradeAction.buy => Icons.trending_up_rounded,
              TradeAction.sell => Icons.attach_money_rounded,
              TradeAction.short => Icons.warning_amber_rounded,
              TradeAction.cover => Icons.check_circle_rounded,
            }
          : Icons.info_outline_rounded,
      accent: result.success
          ? switch (request.action) {
              TradeAction.buy => const Color(0xFF85EFAC),
              TradeAction.sell => const Color(0xFFE1BB72),
              TradeAction.short => const Color(0xFFFFD166),
              TradeAction.cover => const Color(0xFF8BC6FF),
            }
          : const Color(0xFFFFB084),
    );
  }

  /// Fills any resting orders the live price has crossed. Called after each
  /// price refresh. Pulls a quote for working-order symbols that aren't in the
  /// scheduled watch list so limit orders on searched stocks settle too.
  Future<void> _settleWorkingOrders() async {
    if (!mounted) return;
    final controller = context.read<UserStatsController>();
    final market = context.read<MarketDataService>();
    final orders = controller.stats.workingOrders;
    if (orders.isEmpty) return;

    final lastBySymbol = <String, int>{};
    for (final order in orders) {
      var quote = market.quoteFor(order.symbol);
      quote ??= await market.fetchQuoteFor(
        order.symbol,
        company: order.company,
      );
      if (quote != null && quote.isValid) {
        // Compare in coins, matching the order's limit price.
        lastBySymbol[order.symbol] = coinsForUsd(quote.current);
      }
    }
    if (lastBySymbol.isEmpty || !mounted) return;

    final fills = await controller.settleWorkingOrders(lastBySymbol);
    if (fills > 0 && mounted) {
      GameToast.show(
        context,
        title: 'Working order${fills > 1 ? 's' : ''} filled',
        message:
            '$fills resting limit order${fills > 1 ? 's' : ''} '
            'reached the price and filled.',
        icon: Icons.check_circle_rounded,
        accent: const Color(0xFF85EFAC),
      );
    }
  }

  /// Pulls a quote for a symbol found through search (which is almost never
  /// one of the pre-cached [kLiveSymbols]) and then opens its ticket.
  Future<void> _openSearchResult({
    required BuildContext context,
    required SymbolMatch match,
    required UserStats stats,
  }) async {
    final market = context.read<MarketDataService>();
    var quote = market.quoteFor(match.symbol);
    quote ??= await market.fetchQuoteFor(match.symbol, company: match.company);

    if (!context.mounted) return;

    if (quote == null) {
      GameToast.show(
        context,
        title: 'No price available',
        message:
            '${match.symbol} did not return a tradeable price. Free API '
            'plans do not cover every listing.',
        icon: Icons.info_outline_rounded,
        accent: const Color(0xFFFFB084),
      );
      return;
    }

    await _openOrderTicket(
      context: context,
      quote: _tradeQuoteFor(quote),
      startAsBuy: true,
      availableGold: stats.gold,
      ownedLots: stats.holdings['stock_${match.symbol}'] ?? 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserStatsController, MarketDataService>(
      builder: (context, statsController, market, _) {
        final stats = statsController.stats;
        // Whether this player needs the plain-English version of the board.
        // See the tab list below — this screen had no age awareness at all.
        final plainWords = stats.ageBand.prefersSimpleWording;
        final quotes = market.quotes
            .map(_tradeQuoteFor)
            .toList(growable: false);

        final totalMarketValue = quotes.fold<int>(
          0,
          (sum, quote) =>
              sum +
              ((stats.holdings['stock_${quote.symbol}'] ?? 0.0) *
                      quote.currentPrice)
                  .round(),
        );
        final totalLots = quotes.fold<double>(
          0,
          (sum, quote) =>
              sum + (stats.holdings['stock_${quote.symbol}'] ?? 0.0),
        );
        final totalAssets = stats.gold + totalMarketValue;
        final weightedChange = quotes.fold<double>(0, (sum, quote) {
          final lots = stats.holdings['stock_${quote.symbol}'] ?? 0.0;
          return sum + (quote.changePercent * lots);
        });
        final activeLots = totalLots.abs();
        final avgChangePercent = activeLots > 0
            ? weightedChange / activeLots
            : 0.0;
        final ownedSymbols = quotes
            .where(
              (quote) => (stats.holdings['stock_${quote.symbol}'] ?? 0.0) != 0,
            )
            .length;
        final portfolioTip = _portfolioTip(
          totalLots,
          ownedSymbols,
          avgChangePercent,
        );
        // Unrealised P&L across every open position: market value vs. what was
        // actually paid for it.
        final totalUnrealised = quotes.fold<double>(0, (sum, quote) {
          return sum +
              _holdingMetrics(
                ownedLots: stats.holdings['stock_${quote.symbol}'] ?? 0.0,
                costBasis: stats.costBasis['stock_${quote.symbol}'] ?? 0,
                currentPrice: quote.currentPrice,
              ).totalProfitLoss;
        });

        // The backdrop sits *behind* the Scaffold rather than inside its
        // body. An earlier version used `extendBodyBehindAppBar: true` with
        // `SafeArea(top: false)`, which pushed the ticker tape and trending
        // strip up underneath the title and tab bar. Painting the art in a
        // Stack behind a transparent, normally-laid-out Scaffold gets the
        // same full-bleed green without any overlap.
        return Stack(
          children: [
            // The exact welcome-screen recipe: the hand-made village map at
            // BoxFit.cover, a light 0.62 dim, and a soft green glow. The
            // repeating tile pattern used before read as faint texture at
            // best; this is the treatment that actually pops.
            Positioned.fill(
              child: Image.asset(
                AppAssets.villageMapBackground,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Was 0.62/0.66 — the pixel village stayed clearly legible
                  // through it, so every price, label and chart line on this
                  // screen competed with a busy tiled illustration for the
                  // reader's attention. Numbers are the entire point of a
                  // trading screen and they were the thing losing.
                  //
                  // 0.88 keeps the backdrop as texture (you can still tell it
                  // is the village) while stopping it reading as content.
                  color: const Color(0xFF0C2418).withValues(alpha: 0.88),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.3, -0.5),
                    radius: 0.95,
                    colors: [
                      const Color(0xFF78E08F).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  'Market Board',
                  style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
                ),
                actions: [
                  if (plainWords)
                    // Says out loud that this board is the simplified one.
                    // Age scaling nobody can see is indistinguishable from
                    // age scaling that does not exist.
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Center(
                        child: AgeScaledNote(
                          what: 'Words',
                          debugBand: stats.ageBand,
                        ),
                      ),
                    ),
                  _LiveBadge(
                    loading: market.status == LiveMarketStatus.loading,
                    lastFetch: market.lastFetch,
                  ),
                  IconButton(
                    tooltip: 'Refresh prices',
                    onPressed: () => _tick(force: true),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: const Color(0xFF4993FF),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: GoogleFonts.pixelifySans(
                    fontWeight: FontWeight.w700,
                  ),
                  // Plain words for younger readers.
                  //
                  // Asked directly: *"how are we presenting the market board
                  // to younger people?"* — and the honest answer was
                  // "identically to everyone". This screen had **no age
                  // awareness at all**: a six-year-old and an adult both got
                  // Assets / Orders / P&L / Analytics, which is the
                  // vocabulary of a trading terminal.
                  //
                  // The tabs are renamed rather than removed. Hiding Orders
                  // and Analytics from a child would leave a board that
                  // cannot teach what a limit order is; calling P&L
                  // "Win or lose" teaches exactly the same thing in words
                  // they already have. The maths behind every tab is
                  // unchanged.
                  tabs: [
                    Tab(text: plainWords ? 'What you own' : 'Assets'),
                    Tab(text: plainWords ? 'Buy or sell' : 'Trade'),
                    Tab(text: plainWords ? 'Waiting' : 'Orders'),
                    Tab(text: plainWords ? 'Win or lose' : 'P&L'),
                    Tab(text: plainWords ? 'Patterns' : 'Analytics'),
                  ],
                ),
              ),
              body: SafeArea(
                top: false,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PortfolioTab(
                      quotes: quotes,
                      stats: stats,
                      totalMarketValue: totalMarketValue,
                      totalAssets: totalAssets,
                      avgChangePercent: avgChangePercent,
                      portfolioTip: portfolioTip,
                      onGoToTrade: () => _tabController.animateTo(1),
                    ),
                    _TradeTab(
                      status: market.status,
                      errorDetail: market.errorDetail,
                      quotes: quotes,
                      stats: stats,
                      onBuy: (quote) => _openOrderTicket(
                        context: context,
                        quote: quote,
                        startAsBuy: true,
                        availableGold: stats.gold,
                        ownedLots:
                            stats.holdings['stock_${quote.symbol}'] ?? 0.0,
                      ),
                      onSell: (quote) => _openOrderTicket(
                        context: context,
                        quote: quote,
                        startAsBuy: false,
                        availableGold: stats.gold,
                        ownedLots:
                            stats.holdings['stock_${quote.symbol}'] ?? 0.0,
                      ),
                      onOpenMatch: (match) => _openSearchResult(
                        context: context,
                        match: match,
                        stats: stats,
                      ),
                    ),
                    _OrdersTab(
                      transactions: stats.transactions,
                      workingOrders: stats.workingOrders,
                      onCancel: (order) async {
                        final result = await statsController.cancelWorkingOrder(
                          order.id,
                        );
                        if (!context.mounted) return;
                        GameToast.show(
                          context,
                          title: result.success
                              ? 'Order cancelled'
                              : 'Could not cancel',
                          message: result.success
                              ? '${order.isBuy ? 'Buy' : 'Sell'} ${order.quantity} '
                                    '${order.symbol} limit at ${order.limitPrice}g '
                                    'was cancelled.'
                              : result.message,
                          icon: result.success
                              ? Icons.cancel_rounded
                              : Icons.info_outline_rounded,
                          accent: const Color(0xFFFFB084),
                        );
                      },
                    ),
                    _PnlTab(
                      portfolioHistory: statsController.realPortfolioHistory,
                      portfolioHistoryAt: statsController.portfolioHistoryTimes,
                      netWorth: totalAssets,
                      totalEarned: totalUnrealised.round(),
                    ),
                    _AnalyticsTab(
                      quotes: quotes,
                      stats: stats,
                      equityCurve: statsController.realPortfolioHistory,
                      totalMarketValue: totalMarketValue,
                      totalUnrealised: totalUnrealised.round(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// (averageCost, currentValue, totalProfitLoss, profitLossPercent) for a
/// position — shared by the Trade card and the Portfolio holdings row so the
/// two never drift out of sync.
({
  double averageCost,
  double currentValue,
  double totalProfitLoss,
  double profitLossPercent,
})
_holdingMetrics({
  required double ownedLots,
  required int costBasis,
  required int currentPrice,
}) {
  final absLots = ownedLots.abs();
  final isShort = ownedLots < 0;
  final averageCost = absLots > 0 ? (costBasis.abs() / absLots) : 0.0;
  final currentValue = (ownedLots * currentPrice).toDouble();
  final totalProfitLoss = absLots > 0 ? (currentValue - costBasis) : 0.0;
  final priceDeltaPercent = averageCost > 0
      ? ((currentPrice - averageCost) / averageCost) * 100
      : 0.0;
  final profitLossPercent = isShort ? -priceDeltaPercent : priceDeltaPercent;
  return (
    averageCost: averageCost,
    currentValue: currentValue,
    totalProfitLoss: totalProfitLoss,
    profitLossPercent: profitLossPercent,
  );
}

String _portfolioTip(
  double totalLots,
  int ownedSymbols,
  double avgChangePercent,
) {
  if (totalLots.abs() <= 0) {
    return 'No stock positions yet. Start with a small position and build a more balanced portfolio over time.';
  }
  if (ownedSymbols <= 1) {
    return 'Diversify more by spreading risk across multiple companies instead of holding one name.';
  }
  if (avgChangePercent <= -1.0) {
    return 'Your holdings are down. Consider selling your losing investments or trimming weak positions.';
  }
  if (avgChangePercent >= 2.0) {
    return 'Your portfolio is up. Keep diversification in place so gains can stay stable.';
  }
  return 'Maintain a balanced mix of cash and positions so your portfolio can weather swings.';
}

/// Shown in place of the ticker/board whenever there isn't a real quote to
/// trade against yet (no key configured, still loading, or Finnhub failed).
class _MarketStatusNote extends StatelessWidget {
  const _MarketStatusNote({required this.status, this.errorDetail});

  final LiveMarketStatus status;
  final String? errorDetail;

  @override
  Widget build(BuildContext context) {
    if (status == LiveMarketStatus.loading || status == LiveMarketStatus.idle) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF58C7FF)),
            SizedBox(height: 14),
            Text(
              'Loading real market prices…',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    final isNoKey = status == LiveMarketStatus.noApiKey;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB084).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFB084).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFFFB084),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isNoKey
                  ? 'Trading needs a Finnhub API key. Ask whoever set up this build to add one — see tool/README.md.'
                  : (errorDetail ?? 'Live prices are unavailable right now.'),
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

final Set<String> _kCommonSymbols = kLiveSymbols
    .where((s) => s.common)
    .map((s) => s.symbol)
    .toSet();

/// A horizontally-scrolling strip of real-logo cards for a handful of
/// well-known tickers, so the board opens with something that reads as a
/// real trading floor rather than a plain list. Prices/changes come from
/// the same live [quotes] the rest of the board uses — this is a different
/// presentation of real data, not separate promotional content.
class _TrendingPromoStrip extends StatelessWidget {
  const _TrendingPromoStrip({required this.quotes, required this.onTap});

  final List<_TradeQuote> quotes;
  final ValueChanged<_TradeQuote> onTap;

  @override
  Widget build(BuildContext context) {
    final featured = quotes
        .where((quote) => kStockLogoSymbols.contains(quote.symbol))
        .toList(growable: false);
    if (featured.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFFF8A5B),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'TRENDING NOW',
              style: AppTheme.caps(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final quote = featured[index];
              return _TrendingPromoCard(
                quote: quote,
                onTap: () => onTap(quote),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrendingPromoCard extends StatelessWidget {
  const _TrendingPromoCard({required this.quote, required this.onTap});

  final _TradeQuote quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final up = quote.changePercent >= 0;
    final changeColor = up ? const Color(0xFF4BD2A3) : const Color(0xFFFF6B6B);

    return HoverLift(
      accent: quote.accent,
      borderRadius: 22,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 122,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF173B2E),
                Color.lerp(const Color(0xFF10281F), quote.accent, 0.14)!,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: quote.accent.withValues(alpha: 0.30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SymbolBadge(
                symbol: quote.symbol,
                icon: quote.icon,
                accent: quote.accent,
                size: 38,
              ),
              const Spacer(),
              Text(
                quote.symbol,
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${quote.livePrice.toStringAsFixed(1)}g',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    up
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color: changeColor,
                    size: 16,
                  ),
                  Flexible(
                    child: Text(
                      '${quote.changePercent.abs().toStringAsFixed(1)}%',
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.numeric(
                        color: changeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TradeTab extends StatefulWidget {
  const _TradeTab({
    required this.status,
    required this.errorDetail,
    required this.quotes,
    required this.stats,
    required this.onBuy,
    required this.onSell,
    required this.onOpenMatch,
  });

  final LiveMarketStatus status;
  final String? errorDetail;
  final List<_TradeQuote> quotes;
  final UserStats stats;
  final ValueChanged<_TradeQuote> onBuy;
  final ValueChanged<_TradeQuote> onSell;
  final ValueChanged<SymbolMatch> onOpenMatch;

  @override
  State<_TradeTab> createState() => _TradeTabState();
}

class _TradeTabState extends State<_TradeTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;
  List<SymbolMatch> _matches = const <SymbolMatch>[];
  bool _searching = false;
  int _searchGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _primeVisibleLogos();
  }

  @override
  void didUpdateWidget(covariant _TradeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quotes.length != widget.quotes.length) {
      _primeVisibleLogos();
    }
  }

  /// Loads real company logos for the tickers on this tab.
  ///
  /// Only six logos ship as bundled assets, so every other company on the
  /// board wore a generic Material glyph — while its real mark sat one field
  /// away in the `/stock/profile2` response the order ticket was already
  /// fetching for its Company Background panel. This asks for the rest.
  ///
  /// Deferred to a post-frame callback because it notifies listeners when it
  /// finishes, and notifying during `didChangeDependencies` would rebuild a
  /// widget that is mid-build. Rate limiting lives in `primeLogos` itself.
  void _primeVisibleLogos() {
    final symbols = widget.quotes.map((q) => q.symbol).toList(growable: false);
    if (symbols.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MarketDataService>().primeLogos(symbols);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Debounced so typing "WDC" fires one search rather than three, which
  /// matters on a rate-limited free API tier.
  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _matches = const <SymbolMatch>[];
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final generation = ++_searchGeneration;
      final results = await context.read<MarketDataService>().searchSymbols(
        trimmed,
      );
      // A slower earlier request must not overwrite a newer one's results.
      if (!mounted || generation != _searchGeneration) {
        return;
      }
      setState(() {
        _matches = results;
        _searching = false;
      });
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchGeneration++;
    setState(() {
      _query = '';
      _searchController.clear();
      _matches = const <SymbolMatch>[];
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    final commonQuotes = widget.quotes
        .where((q) => _kCommonSymbols.contains(q.symbol))
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (widget.quotes.isNotEmpty) ...[
          _TickerTape(quotes: widget.quotes),
          const SizedBox(height: 18),
          _TrendingPromoStrip(quotes: widget.quotes, onTap: widget.onBuy),
          const SizedBox(height: 18),
        ],
        _SectionTitle(
          title: searching ? 'Search' : 'Trade Board',
          subtitle: searching
              ? 'Tap any result to open its trade ticket.'
              : 'Real companies, real prices. Buy low, sell high.',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          onChanged: _onQueryChanged,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search any stock — symbol or company',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                    onPressed: _clearSearch,
                  ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (searching) ...[
          if (_searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF58C7FF),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_matches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No stocks match "${_query.trim()}".',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            )
          else
            for (final match in _matches) ...[
              _SearchResultRow(
                match: match,
                ownedLots: widget.stats.holdings['stock_${match.symbol}'] ?? 0,
                onTap: () => widget.onOpenMatch(match),
              ),
              const SizedBox(height: 8),
            ],
        ] else if (widget.quotes.isEmpty)
          _MarketStatusNote(
            status: widget.status,
            errorDetail: widget.errorDetail,
          )
        else
          for (final quote in commonQuotes) ...[
            _StockCard(
              quote: quote,
              ownedLots: widget.stats.holdings['stock_${quote.symbol}'] ?? 0,
              costBasis: widget.stats.costBasis['stock_${quote.symbol}'] ?? 0,
              onBuy: () => widget.onBuy(quote),
              onSell: () => widget.onSell(quote),
            ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.match,
    required this.ownedLots,
    required this.onTap,
  });

  final SymbolMatch match;
  final double ownedLots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _kSymbolStyle[match.symbol];
    final accent = style?.accent ?? const Color(0xFF85EFAC);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                style?.icon ?? Icons.show_chart_rounded,
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.symbol,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    match.company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (ownedLots > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF58C7FF).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${formatShares(ownedLots)} sh',
                  style: AppTheme.numeric(
                    color: Color(0xFF58C7FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioTab extends StatelessWidget {
  const _PortfolioTab({
    required this.quotes,
    required this.stats,
    required this.totalMarketValue,
    required this.totalAssets,
    required this.avgChangePercent,
    required this.portfolioTip,
    required this.onGoToTrade,
  });

  final List<_TradeQuote> quotes;
  final UserStats stats;
  final int totalMarketValue;
  final int totalAssets;
  final double avgChangePercent;
  final String portfolioTip;
  final VoidCallback onGoToTrade;

  @override
  Widget build(BuildContext context) {
    // 1. Map existing quotes by symbol for fast lookup
    final quoteMap = {for (final q in quotes) q.symbol: q};

    // 2. Identify all non-zero stock holdings from stats.holdings
    final holdings =
        <
          ({
            _TradeQuote quote,
            double ownedLots,
            ({
              double averageCost,
              double currentValue,
              double totalProfitLoss,
              double profitLossPercent,
            })
            metrics,
          })
        >[];

    stats.holdings.forEach((key, owned) {
      if (!key.startsWith('stock_') || owned == 0) return;
      final symbol = key.substring('stock_'.length);

      final fallbackPrice = (stats.costBasis[key] ?? 10) / kCoinsPerDollar;

      // Fetch quote from market quotes list, or construct a dynamic fallback quote
      final quote =
          quoteMap[symbol] ??
          _tradeQuoteFor(
            LiveQuote(
              symbol: symbol,
              company: symbol,
              current: fallbackPrice,
              change: 0.0,
              percentChange: 0.0,
              high: fallbackPrice,
              low: fallbackPrice,
              open: fallbackPrice,
              previousClose: fallbackPrice,
              fetchedAt: DateTime.now(),
            ),
          );

      final basis = stats.costBasis[key] ?? 0;

      holdings.add((
        quote: quote,
        ownedLots: owned,
        metrics: _holdingMetrics(
          ownedLots: owned,
          costBasis: basis,
          currentPrice: quote.currentPrice,
        ),
      ));
    });

    // 3. Sort by highest holding value
    holdings.sort(
      (a, b) => b.metrics.currentValue.compareTo(a.metrics.currentValue),
    );

    final totalProfitLoss = holdings.fold<double>(
      0,
      (sum, h) => sum + h.metrics.totalProfitLoss,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (quotes.isNotEmpty) ...[
          _TrendingPromoStrip(quotes: quotes, onTap: (_) => onGoToTrade()),
          const SizedBox(height: 18),
        ],
        _PortfolioSummary(
          cash: stats.gold,
          marketValue: totalMarketValue,
          netWorth: totalAssets,
          totalEarned: totalProfitLoss.round(),
          changePercent: avgChangePercent,
          tip: portfolioTip,
        ),
        const SizedBox(height: 18),
        if (totalMarketValue > 0 || stats.gold > 0)
          _AllocationBar(
            cash: stats.gold,
            holdings: holdings.map((h) => h.quote).toList(),
            valueOf: (quote) =>
                ((stats.holdings['stock_${quote.symbol}'] ?? 0.0) *
                        quote.currentPrice)
                    .round(),
          ),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Holdings',
          subtitle: 'Every open position, from largest to smallest.',
        ),
        const SizedBox(height: 14),
        if (holdings.isEmpty)
          _EmptyHoldings(onGoToTrade: onGoToTrade)
        else
          for (final h in holdings) ...[
            _HoldingRow(
              quote: h.quote,
              ownedLots: h.ownedLots,
              metrics: h.metrics,
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    required this.quote,
    required this.ownedLots,
    required this.metrics,
  });

  final _TradeQuote quote;
  final double ownedLots;
  final ({
    double averageCost,
    double currentValue,
    double totalProfitLoss,
    double profitLossPercent,
  })
  metrics;

  @override
  Widget build(BuildContext context) {
    final isProfitable = metrics.totalProfitLoss >= 0;
    final plColor = isProfitable
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);
    final plSign = isProfitable ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: quote.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          SymbolBadge(
            symbol: quote.symbol,
            icon: quote.icon,
            accent: quote.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${quote.symbol} • ${formatShares(ownedLots)} sh',
                  style: AppTheme.numeric(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Avg ${metrics.averageCost.toStringAsFixed(1)}g',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 54,
            height: 32,
            child: MiniSparkline(
              values: quote.history.map((v) => v.toDouble()).toList(),
              color: quote.accent,
              strokeWidth: 1.8,
              // Pulsing last-price dot, so a holding reads as live rather
              // than a frozen thumbnail between the 30s price polls.
              livePulse: true,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${metrics.currentValue.round()}g',
                style: AppTheme.numeric(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$plSign${metrics.totalProfitLoss.round()}g ($plSign${metrics.profitLossPercent.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: plColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHoldings extends StatelessWidget {
  const _EmptyHoldings({required this.onGoToTrade});

  final VoidCallback onGoToTrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            color: Colors.white.withValues(alpha: 0.3),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing in your portfolio yet.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Open a position on the Trade tab to start building one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF85EFAC),
              foregroundColor: const Color(0xFF103224),
            ),
            onPressed: onGoToTrade,
            child: Text(
              'Go to Trade',
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationBar extends StatelessWidget {
  const _AllocationBar({
    required this.cash,
    required this.holdings,
    required this.valueOf,
  });

  final int cash;
  final List<_TradeQuote> holdings;
  final int Function(_TradeQuote) valueOf;

  /// Colours reserved for the allocation chart, chosen to stay legible next
  /// to each other on a dark card.
  static const List<Color> _distinctPalette = <Color>[
    Color(0xFFE1BB72), // sand
    Color(0xFF58C7FF), // blue
    Color(0xFFFF8FB1), // pink
    Color(0xFF85EFAC), // mint
    Color(0xFFB388FF), // violet
    Color(0xFFFFD45C), // gold
    Color(0xFF5EE7D6), // cyan
    Color(0xFFFF8A5B), // orange
    Color(0xFF9BE564), // lime
    Color(0xFFFF6B6B), // red
  ];

  @override
  Widget build(BuildContext context) {
    final raw = <({String label, int value, Color color})>[
      (label: 'Cash', value: cash, color: const Color(0xFFE1BB72)),
      for (final quote in holdings)
        (
          label: quote.symbol,
          // Ensure non-zero positions evaluate to at least 1 so small/fractional values are visible
          value: math.max(1, valueOf(quote)),
          color: quote.accent,
        ),
    ].where((s) => s.value > 0).toList();

    // A stock's own accent can collide with another slice's — Cash and AAPL
    // are both 0xFFE1BB72, so the chart drew two "different" slices in the
    // identical colour and the legend was unreadable. Reassign any repeat to
    // the next unused palette colour so every slice is visually distinct.
    final used = <int>{};
    final segments = <({String label, int value, Color color})>[];
    for (final segment in raw) {
      var color = segment.color;
      if (used.contains(color.toARGB32())) {
        color = _distinctPalette.firstWhere(
          (candidate) => !used.contains(candidate.toARGB32()),
          // More slices than palette entries: fall back to spinning the hue
          // so they still differ rather than silently repeating.
          orElse: () => HSLColor.fromColor(segment.color)
              .withHue((HSLColor.fromColor(segment.color).hue + 137) % 360)
              .toColor(),
        );
      }
      used.add(color.toARGB32());
      segments.add((label: segment.label, value: segment.value, color: color));
    }

    final total = segments.fold<int>(0, (sum, s) => sum + s.value);
    if (total <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allocation',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          // A donut instead of the old 14px stacked bar — at a realistic
          // split (99% cash, 1% each in two stocks) that bar was a solid
          // block with two invisible slivers, so the section read as pure
          // text. The ring gives the tab an actual graphic centrepiece and
          // the slivers still register as ticks on the edge.
          Row(
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: CustomPaint(
                  painter: _AllocationDonutPainter(
                    segments: segments
                        .map((s) => (value: s.value.toDouble(), color: s.color))
                        .toList(growable: false),
                    total: total.toDouble(),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${segments.length}',
                          style: AppTheme.numeric(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        Text(
                          segments.length == 1 ? 'slice' : 'slices',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in segments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FittedLabel(
                                s.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '${((s.value / total) * 100).toStringAsFixed(0)}%',
                              style: AppTheme.numeric(
                                color: s.color,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draws the allocation ring. Hand-rolled for the same reason the price
/// charts are (see the README's fl_chart entry): no interval solver, no
/// upstream NaN/Infinity crash class — values map straight onto sweep angles.
class _AllocationDonutPainter extends CustomPainter {
  const _AllocationDonutPainter({required this.segments, required this.total});

  final List<({double value, Color color})> segments;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || size.shortestSide <= 0) {
      return;
    }
    final stroke = size.shortestSide * 0.17;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.shortestSide - stroke) / 2,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(rect.center, rect.width / 2, track);

    // Start at 12 o'clock and sweep clockwise.
    var start = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    for (final segment in segments) {
      final fraction = segment.value / total;
      if (fraction <= 0) {
        continue;
      }
      // Floor every slice at ~1.2 degrees so a 1% holding is still visible
      // as a tick rather than vanishing into the ring entirely.
      final sweep = math.max(fraction * 2 * math.pi, 0.02);
      paint.color = segment.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_AllocationDonutPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.segments.length != segments.length;
}

class _TickerTape extends StatefulWidget {
  const _TickerTape({required this.quotes});

  final List<_TradeQuote> quotes;

  @override
  State<_TickerTape> createState() => _TickerTapeState();
}

class _TickerTapeState extends State<_TickerTape> with PausesInBackground {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void onAppBackgrounded() {
    // Thirty times a second, scrolling a strip nobody can see.
    _timer?.cancel();
    _timer = null;
  }

  @override
  void onAppForegrounded() {
    _timer ??= _scrollTimer();
  }

  @override
  void initState() {
    super.initState();
    _timer = _scrollTimer();
  }

  Timer _scrollTimer() {
    return Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) {
        return;
      }
      final next = _scrollController.offset + 1.2;
      _scrollController.jumpTo(next >= maxExtent ? 0 : next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.quotes, ...widget.quotes, ...widget.quotes];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A21),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(width: 26),
          itemBuilder: (context, index) {
            final quote = items[index];
            final positive = quote.changePercent >= 0;
            final color = positive
                ? const Color(0xFF85EFAC)
                : const Color(0xFFFF8A80);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SymbolBadge(
                  symbol: quote.symbol,
                  icon: quote.icon,
                  accent: quote.accent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  quote.symbol,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${quote.currentPrice}g',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  positive
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  color: color,
                  size: 18,
                ),
                Text(
                  '${quote.changePercent.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  const _PortfolioSummary({
    required this.cash,
    required this.marketValue,
    required this.netWorth,
    required this.totalEarned,
    required this.changePercent,
    required this.tip,
  });

  final int cash;
  final int marketValue;
  final int netWorth;

  /// Total gold gained (or lost) across every open position, vs. what was
  /// paid for it — the concrete "how much you earn" number, not just a %.
  final int totalEarned;
  final double changePercent;
  final String tip;

  @override
  Widget build(BuildContext context) {
    final positive = changePercent >= 0;
    final changeLabel = positive
        ? 'Up ${changePercent.toStringAsFixed(1)}%'
        : 'Down ${changePercent.abs().toStringAsFixed(1)}%';
    final changeColor = positive
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);
    final earnedPositive = totalEarned >= 0;
    final earnedLabel = '${earnedPositive ? '+' : ''}${coinLabel(totalEarned)}';
    final earnedColor = earnedPositive
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Summary',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ValueBadge(
                label: 'Cash',
                value: coinLabel(cash),
                sub: usdLabel(cash),
                color: const Color(0xFFE1BB72),
              ),
              _ValueBadge(
                label: 'Market Value',
                value: coinLabel(marketValue),
                sub: usdLabel(marketValue),
                color: const Color(0xFF58C7FF),
              ),
              _ValueBadge(
                label: 'Net Worth',
                value: coinLabel(netWorth),
                sub: usdLabel(netWorth),
                color: const Color(0xFF85EFAC),
              ),
              _ValueBadge(
                label: 'Total Earned',
                value: earnedLabel,
                sub: usdLabel(totalEarned.abs()),
                color: earnedColor,
              ),
              _ValueBadge(
                label: 'Today',
                value: changeLabel,
                color: changeColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tip,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatefulWidget {
  const _StockCard({
    required this.quote,
    required this.ownedLots,
    required this.costBasis,
    required this.onBuy,
    required this.onSell,
  });

  final _TradeQuote quote;
  final double ownedLots;
  final int costBasis;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  @override
  State<_StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<_StockCard> {
  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;
    final positive = quote.changePercent >= 0;
    final changeColor = positive
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);

    final metrics = _holdingMetrics(
      ownedLots: widget.ownedLots,
      costBasis: widget.costBasis,
      currentPrice: quote.currentPrice,
    );
    final averageCost = metrics.averageCost;
    final totalProfitLoss = metrics.totalProfitLoss;
    final profitLossPercent = metrics.profitLossPercent;

    final bool isProfitable = totalProfitLoss >= 0;
    final Color plColor = isProfitable
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);
    final String plSign = isProfitable ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: quote.accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 520;
              // Deliberately *not* pre-wrapped in Expanded. It gets used in
              // both a Row (below) and a Column (the stacked branch), and an
              // Expanded inside a Column that has no height constraint — this
              // card lives in a ListView — fails to lay out at all, leaving a
              // render box with no size for the next paint to trip over.
              final headerInfo = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SymbolBadge(
                    symbol: quote.symbol,
                    icon: quote.icon,
                    accent: quote.accent,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${quote.symbol} • ${quote.company}',
                          style: AppTheme.numeric(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          quote.sector,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.66),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final badges = Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ValueBadge(
                    label: 'Price',
                    value: coinLabel(quote.currentPrice),
                    sub: usdLabel(quote.currentPrice),
                    color: const Color(0xFFE1BB72),
                  ),
                  _ValueBadge(
                    label: 'Today',
                    value:
                        '${positive ? '+' : ''}${quote.changePercent.toStringAsFixed(1)}%',
                    color: changeColor,
                  ),
                  _ValueBadge(
                    label: 'Owned',
                    value: formatShares(widget.ownedLots),
                    sub: widget.ownedLots > 0
                        ? usdLabel(widget.ownedLots * quote.currentPrice)
                        : null,
                    color: const Color(0xFF58C7FF),
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [headerInfo, const SizedBox(height: 12), badges],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: headerInfo),
                  const SizedBox(width: 14),
                  Flexible(child: badges),
                ],
              );
            },
          ),

          if (widget.ownedLots > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: plColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: plColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AVG COST BASIS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${averageCost.toStringAsFixed(1)}g / share',
                        style: AppTheme.numeric(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'POSITION RETURN',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$plSign${totalProfitLoss.round()}g ($plSign${profitLossPercent.toStringAsFixed(1)}%)',
                        style: AppTheme.numeric(
                          color: plColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          Text(
            quote.thesis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _StockSparkline(symbol: quote.symbol, accent: quote.accent),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 460;

              final buyButton = Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onBuy,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF85EFAC),
                    foregroundColor: const Color(0xFF103224),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded),
                  label: Text(
                    'Buy Shares',
                    style: GoogleFonts.pixelifySans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
              final sellButton = Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.ownedLots > 0 ? widget.onSell : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.arrow_downward_rounded),
                  label: Text(
                    'Sell Shares',
                    style: GoogleFonts.pixelifySans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );

              if (stacked) {
                return Column(
                  children: [
                    Row(children: [buyButton]),
                    const SizedBox(height: 10),
                    Row(children: [sellButton]),
                  ],
                );
              }

              return Row(
                children: [buyButton, const SizedBox(width: 12), sellButton],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge({
    required this.label,
    required this.value,
    required this.color,
    this.sub,
  });

  final String label;
  final String value;
  final Color color;

  /// Optional second line — used to show the real-money equivalent under a
  /// coin amount, so coins never read as if they were dollars.
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.pixelifySans(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.pixelifySans(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// The inline chart on a trade card.
///
/// Draws the symbol's **real intraday closes** (fetched once per few minutes
/// and cached in [MarketDataService]) with a price axis, so the shape and the
/// numbers are both real. Falls back to the quote's 3-point series when no
/// historical-data key is configured.
class _StockSparkline extends StatefulWidget {
  const _StockSparkline({required this.symbol, required this.accent});

  final String symbol;
  final Color accent;

  static const double height = 168;

  @override
  State<_StockSparkline> createState() => _StockSparklineState();
}

class _StockSparklineState extends State<_StockSparkline> {
  /// Index of the point the pointer is over, or null when not hovering.
  int? _hoverIndex;

  /// Receives the crosshair position from [InteractivePriceChart].
  ///
  /// The pointer-to-index maths used to live here, with its own hardcoded
  /// copy of the painter'''s 52px label gutter. It moved into the chart, which
  /// is the only place that knows how wide the plotted area actually is —
  /// and which now also has to translate between the zoomed window and the
  /// full series, maths this widget has no business duplicating.
  void _setHoverIndex(int? index) {
    if (index == _hoverIndex) return;
    setState(() => _hoverIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.symbol;
    final height = _StockSparkline.height;
    final market = context.watch<MarketDataService>();
    // Coins, so the axis labels match the prices shown on the card.
    final series = market
        .seriesFor(symbol)
        .map((usd) => coinsForUsd(usd).toDouble())
        .toList(growable: false);

    if (series.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No chart data yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final first = series.first;
    final last = series.last;
    final rising = last >= first;
    final lineColor = rising
        ? const Color(0xFF00C287)
        : const Color(0xFFE1454A);
    final changePercent = first == 0 ? 0.0 : ((last - first) / first) * 100;
    final hoverIndex = _hoverIndex;
    final hovered = hoverIndex != null && hoverIndex < series.length
        ? series[hoverIndex]
        : null;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        // No border: this card is always nested inside a bordered parent
        // (_StockCard / the holdings row), and stacking the two read as a
        // doubled outline. The fill alone is enough separation.
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 6),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                series.length > 3 ? 'Today' : 'Recent',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                rising
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color: lineColor,
                size: 16,
              ),
              Text(
                '${changePercent >= 0 ? '+' : ''}'
                '${changePercent.toStringAsFixed(2)}%',
                style: AppTheme.numeric(
                  color: lineColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                // While scrubbing, this reads the hovered point rather than
                // the latest one — the number people actually want when they
                // put a finger on a chart.
                usdLabel(hovered ?? last),
                style: GoogleFonts.pixelifySans(
                  color: hovered == null
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.white,
                  fontSize: 11,
                  fontWeight: hovered == null
                      ? FontWeight.w700
                      : FontWeight.w700,
                ),
              ),
            ],
          ),
          Expanded(
            // [InteractivePriceChart] rather than a bare [PriceChart]. It
            // owns the hover/scrub gestures that used to be wired up here by
            // hand, and adds the pinch-zoom and pan that repeatedly did not
            // work on this screen — because the interactive wrapper existed
            // but no call site had ever used it.
            //
            // The scrub index still comes back out to this widget, since the
            // header above reads it to show the price at the crosshair.
            child: InteractivePriceChart(
              candles: _flatCandles(series),
              mode: ChartMode.line,
              accent: lineColor,
              onHoverIndexChanged: _setHoverIndex,
            ),
          ),
          const SizedBox(height: 6),
          _DayRangeStrip(quote: market.quoteFor(symbol), series: series),
        ],
      ),
    );
  }
}

/// The day's high, low, open and previous close under a chart.
///
/// Prefers the real quote's own figures — Finnhub reports the true session
/// high/low, which the sampled intraday series will usually miss, since the
/// series only holds the points we happened to poll.
class _DayRangeStrip extends StatelessWidget {
  const _DayRangeStrip({required this.quote, required this.series});

  final LiveQuote? quote;
  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final live = quote;
    final high = live != null
        ? coinsForUsd(live.high).toDouble()
        : series.reduce(math.max).toDouble();
    final low = live != null
        ? coinsForUsd(live.low).toDouble()
        : series.reduce(math.min).toDouble();
    final open = live != null
        ? coinsForUsd(live.open).toDouble()
        : series.first;
    final prev = live != null
        ? coinsForUsd(live.previousClose).toDouble()
        : series.first;

    return Row(
      children: [
        Expanded(
          child: _RangeCell(label: 'HIGH', value: high, tone: 1),
        ),
        Expanded(
          child: _RangeCell(label: 'LOW', value: low, tone: -1),
        ),
        Expanded(
          child: _RangeCell(label: 'OPEN', value: open, tone: 0),
        ),
        Expanded(
          child: _RangeCell(label: 'PREV', value: prev, tone: 0),
        ),
      ],
    );
  }
}

class _RangeCell extends StatelessWidget {
  const _RangeCell({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final double value;

  /// 1 green, -1 red, 0 neutral.
  final int tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      1 => const Color(0xFF00C287),
      -1 => const Color(0xFFE1454A),
      _ => Colors.white.withValues(alpha: 0.72),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.pixelifySans(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 8.5,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            usdLabel(value),
            maxLines: 1,
            style: GoogleFonts.pixelifySans(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// A stock buy/sell parsed out of the general ledger. Only 'invest'-category
/// transactions titled exactly "Bought SYMBOL"/"Sold SYMBOL" qualify — this
/// excludes the separate passive index-fund feature ("Bought Index Fund").
class _StockOrder {
  const _StockOrder({
    required this.symbol,
    required this.isBuy,
    required this.isShort,
    required this.isCover,
    required this.amount,
    required this.createdAt,
  });

  final String symbol;
  final bool isBuy;
  final bool isShort;
  final bool isCover;
  final int amount;
  final DateTime createdAt;

  String get actionLabel => switch ((isBuy, isShort, isCover)) {
    (true, false, false) => 'Buy',
    (false, false, false) => 'Sell',
    (false, true, false) => 'Sell Short',
    (false, false, true) => 'Cover Short',
    _ => 'Trade',
  };
}

final RegExp _stockOrderPattern = RegExp(
  r'^(Bought|Sold|Shorted|Covered) ([A-Z]{1,5})$',
);

({String symbol, bool isBuy, bool isShort, bool isCover})? parseStockOrderTitle(
  String title,
) {
  final match = _stockOrderPattern.firstMatch(title);
  if (match == null) {
    return null;
  }

  final verb = match.group(1)!;
  switch (verb) {
    case 'Bought':
      return (
        symbol: match.group(2)!,
        isBuy: true,
        isShort: false,
        isCover: false,
      );
    case 'Sold':
      return (
        symbol: match.group(2)!,
        isBuy: false,
        isShort: false,
        isCover: false,
      );
    case 'Shorted':
      return (
        symbol: match.group(2)!,
        isBuy: false,
        isShort: true,
        isCover: false,
      );
    case 'Covered':
      return (
        symbol: match.group(2)!,
        isBuy: false,
        isShort: false,
        isCover: true,
      );
    default:
      return null;
  }
}

_StockOrder? _parseStockOrder(LedgerTransaction transaction) {
  final parsed = parseStockOrderTitle(transaction.title);
  if (parsed == null) {
    return null;
  }
  return _StockOrder(
    symbol: parsed.symbol,
    isBuy: parsed.isBuy,
    isShort: parsed.isShort,
    isCover: parsed.isCover,
    amount: transaction.amount.abs(),
    createdAt: transaction.createdAt,
  );
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({
    required this.transactions,
    required this.workingOrders,
    required this.onCancel,
  });

  final List<LedgerTransaction> transactions;
  final List<WorkingOrder> workingOrders;
  final ValueChanged<WorkingOrder> onCancel;

  @override
  Widget build(BuildContext context) {
    final orders = transactions
        .map(_parseStockOrder)
        .whereType<_StockOrder>()
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (workingOrders.isNotEmpty) ...[
          const _SectionTitle(
            title: 'Working',
            subtitle:
                'Limit orders resting until the price reaches them. They fill '
                'automatically on the next refresh once the market crosses.',
          ),
          const SizedBox(height: 14),
          for (final order in workingOrders) ...[
            _WorkingOrderRow(order: order, onCancel: () => onCancel(order)),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
        ],
        const _SectionTitle(
          title: 'Filled',
          subtitle: 'Every stock trade that has executed, most recent first.',
        ),
        const SizedBox(height: 14),
        if (orders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  'No filled orders yet.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          )
        else
          for (final order in orders) ...[
            _OrderRow(order: order),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

/// A resting limit order, with the cancel control that returns its reservation.
class _WorkingOrderRow extends StatelessWidget {
  const _WorkingOrderRow({required this.order, required this.onCancel});

  final WorkingOrder order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final style = _kSymbolStyle[order.symbol];
    final sideColor = order.isBuy
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF58C7FF).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF58C7FF).withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          Icon(
            style?.icon ?? Icons.show_chart_rounded,
            color: style?.accent ?? Colors.white70,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${order.symbol} • ${order.isBuy ? 'Buy' : 'Sell'} '
                      '${order.quantity}',
                      style: AppTheme.numeric(
                        color: sideColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF58C7FF).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'WORKING',
                        style: AppTheme.caps(
                          color: Color(0xFF58C7FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Limit ${order.limitPrice}g • total ${order.total}g',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF8A80),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final _StockOrder order;

  @override
  Widget build(BuildContext context) {
    final style = _kSymbolStyle[order.symbol];
    final sideColor = order.isShort
        ? const Color(0xFFFFD166)
        : order.isCover
        ? const Color(0xFF8BC6FF)
        : order.isBuy
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);
    final date = order.createdAt.toLocal();
    final dateLabel =
        '${date.month}/${date.day}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(
            style?.icon ?? Icons.show_chart_rounded,
            color: style?.accent ?? Colors.white70,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.symbol,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order.actionLabel,
                style: GoogleFonts.pixelifySans(
                  color: sideColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${order.amount}g • Filled',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PnlTab extends StatelessWidget {
  const _PnlTab({
    required this.portfolioHistory,
    required this.portfolioHistoryAt,
    required this.netWorth,
    required this.totalEarned,
  });

  final List<double> portfolioHistory;

  /// Real recording times, where the save has them. See [_flatCandles].
  final List<DateTime> portfolioHistoryAt;
  final int netWorth;
  final int totalEarned;

  @override
  Widget build(BuildContext context) {
    final positive = totalEarned >= 0;
    final color = positive ? const Color(0xFF85EFAC) : const Color(0xFFFF8A80);

    // The curve is real net worth in coins, so its own direction — not the P&L
    // sign — decides whether it reads as up or down.
    final curveRising =
        portfolioHistory.length < 2 ||
        portfolioHistory.last >= portfolioHistory.first;
    final curveColor = curveRising
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);
    final curveDelta = portfolioHistory.length < 2
        ? 0.0
        : portfolioHistory.last - portfolioHistory.first;

    final baseline = portfolioHistory.isNotEmpty ? portfolioHistory.first : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _SectionTitle(
          title: 'P&L',
          subtitle: 'Your real net worth, recorded every time prices refresh.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${positive ? '+' : ''}${coinLabel(totalEarned)}',
                style: AppTheme.numeric(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${positive ? '+' : '-'}${usdLabel(totalEarned.abs())} '
                'unrealised on open positions',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 18),
              if (portfolioHistory.length < 2)
                _EquityCurveEmpty(netWorth: netWorth)
              else ...[
                Row(
                  children: [
                    Icon(
                      curveRising
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: curveColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${curveDelta >= 0 ? '+' : ''}${coinLabel(curveDelta)} '
                      'since tracking started',
                      style: TextStyle(
                        color: curveColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 170,
                  // Interactive too. A long-running player accumulates
                  // hundreds of net-worth snapshots, and the whole history
                  // squeezed into 150px is a smear — being able to zoom into
                  // the last twenty is the only way to read a recent trade.
                  child: InteractivePriceChart(
                    candles: _flatCandles(
                      portfolioHistory,
                      times: portfolioHistoryAt,
                      basePrice: baseline,
                    ),
                    mode: ChartMode.line,
                    accent: curveColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${portfolioHistory.length} snapshots • '
                  'low ${coinLabel(portfolioHistory.reduce(math.min))} • '
                  'high ${coinLabel(portfolioHistory.reduce(math.max))}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ValueBadge(
                label: 'Net Worth',
                value: coinLabel(netWorth),
                color: const Color(0xFF58C7FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ValueBadge(
                label: 'In real money',
                value: usdLabel(netWorth),
                color: const Color(0xFFE1BB72),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Wraps a plain value series as flat-bodied candles so it can be drawn by
/// [PriceChart], which gives it a price axis and a current-value tag.
///
/// Passing [basePrice] sets each candle's open price to the initial snapshot value,
/// allowing the chart tooltip to accurately calculate gains and percent changes
/// since tracking began.
List<Candle> _flatCandles(
  List<double> values, {
  List<DateTime>? times,
  double? basePrice,
}) {
  final stamps = times ?? const <DateTime>[];
  final offset = values.length - stamps.length;
  final now = DateTime.now();
  final startingPrice = basePrice ?? (values.isNotEmpty ? values.first : 0.0);

  return [
    for (var i = 0; i < values.length; i++)
      Candle(
        time: (i - offset) >= 0 && (i - offset) < stamps.length
            ? stamps[i - offset].toLocal()
            : now.subtract(Duration(minutes: values.length - i)),
        open: startingPrice,
        high: math.max(startingPrice, values[i]),
        low: math.min(startingPrice, values[i]),
        close: values[i],
      ),
  ];
}

class _EquityCurveEmpty extends StatelessWidget {
  const _EquityCurveEmpty({required this.netWorth});

  final int netWorth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.timeline_rounded,
            color: Colors.white.withValues(alpha: 0.3),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            'Building your equity curve',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Net worth is ${coinLabel(netWorth)}. Each price refresh adds a '
            'real point here, so the line rises and falls with your actual '
            'portfolio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows that quotes are polling, and when they last landed.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.loading, required this.lastFetch});

  final bool loading;
  final DateTime? lastFetch;

  @override
  Widget build(BuildContext context) {
    final fetched = lastFetch;
    final label = fetched == null
        ? '—'
        : '${fetched.hour.toString().padLeft(2, '0')}:'
              '${fetched.minute.toString().padLeft(2, '0')}:'
              '${fetched.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF00C287).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child: loading
                  ? const CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: Color(0xFF00C287),
                    )
                  : const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF00C287),
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Text(
              'LIVE $label',
              style: AppTheme.numeric(
                color: Color(0xFF00C287),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Analytics: the numbers behind the portfolio — concentration, win/loss split,
/// best and worst positions, and trading activity.
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({
    required this.quotes,
    required this.stats,
    required this.equityCurve,
    required this.totalMarketValue,
    required this.totalUnrealised,
  });

  final List<_TradeQuote> quotes;
  final UserStats stats;
  final List<double> equityCurve;
  final int totalMarketValue;
  final int totalUnrealised;

  @override
  Widget build(BuildContext context) {
    final positions =
        quotes
            .map((quote) {
              final owned = stats.holdings['stock_${quote.symbol}'] ?? 0.0;
              return (
                quote: quote,
                owned: owned,
                metrics: _holdingMetrics(
                  ownedLots: owned,
                  costBasis: stats.costBasis['stock_${quote.symbol}'] ?? 0,
                  currentPrice: quote.currentPrice,
                ),
              );
            })
            .where((p) => p.owned != 0)
            .toList()
          ..sort(
            (a, b) =>
                b.metrics.totalProfitLoss.compareTo(a.metrics.totalProfitLoss),
          );

    final winners = positions
        .where((p) => p.metrics.totalProfitLoss > 0)
        .length;
    final losers = positions.where((p) => p.metrics.totalProfitLoss < 0).length;
    final orders = stats.transactions
        .map(_parseStockOrder)
        .whereType<_StockOrder>()
        .toList(growable: false);
    final buys = orders.where((o) => o.isBuy).length;
    final invested = positions.fold<int>(
      0,
      (sum, p) => sum + (stats.costBasis['stock_${p.quote.symbol}'] ?? 0),
    );
    final returnPercent = invested > 0
        ? (totalUnrealised / invested) * 100
        : 0.0;
    // Concentration: the largest position as a share of all holdings.
    final topShare = totalMarketValue > 0 && positions.isNotEmpty
        ? (positions.map((p) => p.metrics.currentValue).reduce(math.max) /
                  totalMarketValue) *
              100
        : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _SectionTitle(
          title: 'Analytics',
          subtitle: 'What your trading actually adds up to.',
        ),
        const SizedBox(height: 14),
        if (positions.isEmpty && orders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.insights_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 34,
                ),
                const SizedBox(height: 12),
                Text(
                  'No data to analyse yet.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Place a trade and your stats will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                ),
              ],
            ),
          )
        else ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(
                label: 'Return on cost',
                value:
                    '${returnPercent >= 0 ? '+' : ''}'
                    '${returnPercent.toStringAsFixed(1)}%',
                sub: 'on ${coinLabel(invested)} invested',
                color: returnPercent >= 0
                    ? const Color(0xFF85EFAC)
                    : const Color(0xFFFF8A80),
              ),
              _MetricTile(
                label: 'Positions',
                value: '${positions.length}',
                sub: '$winners up • $losers down',
                color: const Color(0xFF58C7FF),
              ),
              _MetricTile(
                label: 'Concentration',
                value: '${topShare.toStringAsFixed(0)}%',
                sub: 'in your largest holding',
                color: topShare > 60
                    ? const Color(0xFFFFB084)
                    : const Color(0xFF85EFAC),
              ),
              _MetricTile(
                label: 'Orders filled',
                value: '${orders.length}',
                sub: '$buys buys • ${orders.length - buys} sells',
                color: const Color(0xFFB388FF),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (positions.isNotEmpty) ...[
            const _SectionTitle(
              title: 'Best & worst',
              subtitle: 'Where the gains and losses are actually coming from.',
            ),
            const SizedBox(height: 12),
            _PositionBar(
              label: 'Best',
              entry: positions.first,
              color: const Color(0xFF85EFAC),
            ),
            if (positions.length > 1) ...[
              const SizedBox(height: 10),
              _PositionBar(
                label: 'Worst',
                entry: positions.last,
                color: const Color(0xFFFF8A80),
              ),
            ],
            const SizedBox(height: 20),
          ],
          if (equityCurve.length >= 2) ...[
            const _SectionTitle(
              title: 'Net worth trend',
              subtitle: 'Every recorded snapshot, oldest to newest.',
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: InteractivePriceChart(
                candles: _flatCandles(equityCurve),
                mode: ChartMode.line,
                accent: const Color(0xFF4993FF),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two per row on phones, four across on a tablet.
        final maxWidth = MediaQuery.sizeOf(context).width;
        final width = maxWidth >= 720
            ? (maxWidth - 90) / 4
            : (maxWidth - 44) / 2;
        return Container(
          width: width,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTheme.caps(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.pixelifySans(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PositionBar extends StatelessWidget {
  const _PositionBar({
    required this.label,
    required this.entry,
    required this.color,
  });

  final String label;
  final ({
    _TradeQuote quote,
    double owned,
    ({
      double averageCost,
      double currentValue,
      double totalProfitLoss,
      double profitLossPercent,
    })
    metrics,
  })
  entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pl = entry.metrics.totalProfitLoss;
    final sign = pl >= 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: GoogleFonts.pixelifySans(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SymbolBadge(
            symbol: entry.quote.symbol,
            icon: entry.quote.icon,
            accent: entry.quote.accent,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${entry.quote.symbol} • ${formatShares(entry.owned)} sh',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$sign${coinLabel(pl)} ($sign'
            '${entry.metrics.profitLossPercent.toStringAsFixed(1)}%)',
            style: AppTheme.numeric(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
