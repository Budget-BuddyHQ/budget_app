import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../services_backend_and_other_services/market_data_service.dart';
import '../../../services_backend_and_other_services/supabase_service.dart'
    show LedgerTransaction, UserStats;
import '../../../widgets_custom_lotties/game_toast.dart';
import '../../../widgets_custom_lotties/mini_sparkline.dart';
import 'order_ticket_page.dart';

/// Real, tradeable stock: a [LiveQuote] plus the display/trade dressing
/// (icon, accent, thesis, bid-ask spread) that Finnhub doesn't provide.
class _TradeQuote {
  const _TradeQuote({
    required this.symbol,
    required this.company,
    required this.sector,
    required this.currentPrice,
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
  final int currentPrice;
  final double changePercent;
  final int buyCost;
  final int sellValue;
  final List<int> history;
  final String thesis;
  final IconData icon;
  final Color accent;
}

const Map<
  String,
  ({IconData icon, Color accent, String sector, String thesis})
>
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
  final spreadFraction = (0.015 + quote.percentChange.abs() / 100 * 0.5)
      .clamp(0.01, 0.06);
  final buyCost = (price * (1 + spreadFraction / 2)).round();
  final sellValue = math.max(1, (price * (1 - spreadFraction / 2)).round());

  return _TradeQuote(
    symbol: quote.symbol,
    company: quote.company,
    sector: style?.sector ?? 'Public company',
    currentPrice: price,
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
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<MarketDataService>().refresh();
      await _settleWorkingOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    final result = request.isBuy
        ? await controller.buyStockLot(
            symbol: quote.symbol,
            goldCost: totalValue,
            companyName: quote.company,
            quantity: request.quantity,
          )
        : await controller.sellStockLot(
            symbol: quote.symbol,
            goldReturn: totalValue,
            companyName: quote.company,
            quantity: request.quantity,
          );

    if (!context.mounted) return;

    GameToast.show(
      context,
      title: result.success
          ? (request.isBuy ? 'Buy order filled' : 'Sell order filled')
          : 'Trade blocked',
      message: result.success
          ? '${request.isBuy ? 'Bought' : 'Sold'} ${formatShares(request.quantity)} share${request.quantity == 1 ? '' : 's'} of ${quote.symbol} for ${totalValue}g.'
          : result.message,
      icon: result.success
          ? (request.isBuy
                ? Icons.trending_up_rounded
                : Icons.attach_money_rounded)
          : Icons.info_outline_rounded,
      accent: result.success
          ? (request.isBuy ? const Color(0xFF85EFAC) : const Color(0xFFE1BB72))
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
      quote ??= await market.fetchQuoteFor(order.symbol, company: order.company);
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
        message: '$fills resting limit order${fills > 1 ? 's' : ''} '
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
    quote ??= await market.fetchQuoteFor(
      match.symbol,
      company: match.company,
    );

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
        final quotes = market.quotes.map(_tradeQuoteFor).toList(
          growable: false,
        );

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
          (sum, quote) => sum + (stats.holdings['stock_${quote.symbol}'] ?? 0.0),
        );
        final totalAssets = stats.gold + totalMarketValue;
        final weightedChange = quotes.fold<double>(0, (sum, quote) {
          final lots = stats.holdings['stock_${quote.symbol}'] ?? 0.0;
          return sum + (quote.changePercent * lots);
        });
        final avgChangePercent = totalLots > 0
            ? weightedChange / totalLots
            : 0.0;
        final ownedSymbols = quotes
            .where(
              (quote) => (stats.holdings['stock_${quote.symbol}'] ?? 0.0) > 0,
            )
            .length;
        final portfolioTip = _portfolioTip(
          totalLots,
          ownedSymbols,
          avgChangePercent,
        );

        return Scaffold(
          backgroundColor: const Color(0xFF0D1117),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D1117),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Market Board',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh prices',
                onPressed: () async {
                  await market.refresh(force: true);
                  await _settleWorkingOrders();
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4993FF),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900),
              tabs: const [
                Tab(text: 'Assets'),
                Tab(text: 'Trade'),
                Tab(text: 'Orders'),
                Tab(text: 'P&L'),
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
                    ownedLots: stats.holdings['stock_${quote.symbol}'] ?? 0.0,
                  ),
                  onSell: (quote) => _openOrderTicket(
                    context: context,
                    quote: quote,
                    startAsBuy: false,
                    availableGold: stats.gold,
                    ownedLots: stats.holdings['stock_${quote.symbol}'] ?? 0.0,
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
                  portfolioHistory: stats.portfolioHistory,
                  netWorth: totalAssets,
                  totalEarned: quotes
                      .fold<double>(0, (sum, quote) {
                        final owned =
                            stats.holdings['stock_${quote.symbol}'] ?? 0.0;
                        final basis =
                            stats.costBasis['stock_${quote.symbol}'] ?? 0;
                        return sum +
                            _holdingMetrics(
                              ownedLots: owned,
                              costBasis: basis,
                              currentPrice: quote.currentPrice,
                            ).totalProfitLoss;
                      })
                      .round(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// (averageCost, currentValue, totalProfitLoss, profitLossPercent) for a
/// position — shared by the Trade card and the Portfolio holdings row so the
/// two never drift out of sync.
({double averageCost, double currentValue, double totalProfitLoss, double profitLossPercent})
_holdingMetrics({
  required double ownedLots,
  required int costBasis,
  required int currentPrice,
}) {
  final averageCost = ownedLots > 0 ? (costBasis / ownedLots) : 0.0;
  final currentValue = (ownedLots * currentPrice).toDouble();
  final totalProfitLoss = ownedLots > 0 ? (currentValue - costBasis) : 0.0;
  final profitLossPercent = averageCost > 0
      ? ((currentPrice - averageCost) / averageCost) * 100
      : 0.0;
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
  if (totalLots <= 0) {
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
                ownedLots:
                    widget.stats.holdings['stock_${match.symbol}'] ?? 0,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF58C7FF).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${formatShares(ownedLots)} sh',
                  style: const TextStyle(
                    color: Color(0xFF58C7FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
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
    final holdings = quotes
        .map((quote) {
          final owned = stats.holdings['stock_${quote.symbol}'] ?? 0.0;
          final basis = stats.costBasis['stock_${quote.symbol}'] ?? 0;
          return (
            quote: quote,
            ownedLots: owned,
            metrics: _holdingMetrics(
              ownedLots: owned,
              costBasis: basis,
              currentPrice: quote.currentPrice,
            ),
          );
        })
        .where((h) => h.ownedLots > 0)
        .toList()
      ..sort(
        (a, b) => b.metrics.currentValue.compareTo(a.metrics.currentValue),
      );

    final totalProfitLoss = holdings.fold<double>(
      0,
      (sum, h) => sum + h.metrics.totalProfitLoss,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: quote.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(quote.icon, color: quote.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${quote.symbol} • ${formatShares(ownedLots)} sh',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${metrics.currentValue.round()}g',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
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
            child: const Text(
              'Go to Trade',
              style: TextStyle(fontWeight: FontWeight.w900),
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

  @override
  Widget build(BuildContext context) {
    final segments = <({String label, int value, Color color})>[
      (label: 'Cash', value: cash, color: const Color(0xFFE1BB72)),
      for (final quote in holdings)
        (label: quote.symbol, value: valueOf(quote), color: quote.accent),
    ].where((s) => s.value > 0).toList();

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
          const Text(
            'Allocation',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (final s in segments)
                    Expanded(
                      flex: math.max(1, ((s.value / total) * 1000).round()),
                      child: ColoredBox(color: s.color),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final s in segments)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.label} ${((s.value / total) * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TickerTape extends StatefulWidget {
  const _TickerTape({required this.quotes});

  final List<_TradeQuote> quotes;

  @override
  State<_TickerTape> createState() => _TickerTapeState();
}

class _TickerTapeState extends State<_TickerTape> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
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
        color: const Color(0xFF161B22),
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
                Icon(quote.icon, color: quote.accent, size: 14),
                const SizedBox(width: 6),
                Text(
                  quote.symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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
    final earnedLabel = '${earnedPositive ? '+' : ''}${totalEarned}g';
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
          const Text(
            'Portfolio Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ValueBadge(
                label: 'Cash',
                value: '${cash}g',
                color: const Color(0xFFE1BB72),
              ),
              _ValueBadge(
                label: 'Market Value',
                value: '${marketValue}g',
                color: const Color(0xFF58C7FF),
              ),
              _ValueBadge(
                label: 'Net Worth',
                value: '${netWorth}g',
                color: const Color(0xFF85EFAC),
              ),
              _ValueBadge(
                label: 'Total Earned',
                value: earnedLabel,
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

class _StockCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final positive = quote.changePercent >= 0;
    final changeColor = positive
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);

    final metrics = _holdingMetrics(
      ownedLots: ownedLots,
      costBasis: costBasis,
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
              final headerInfo = Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: quote.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(quote.icon, color: quote.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${quote.symbol} • ${quote.company}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
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
                ),
              );

              final badges = Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ValueBadge(
                    label: 'Price',
                    value: '${quote.currentPrice}g',
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
                    value: formatShares(ownedLots),
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
                  headerInfo,
                  const SizedBox(width: 14),
                  Flexible(child: badges),
                ],
              );
            },
          ),

          if (ownedLots > 0) ...[
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
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
                        style: TextStyle(
                          color: plColor,
                          fontWeight: FontWeight.w900,
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
          _StockSparkline(history: quote.history, accent: quote.accent),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 460;

              final buyButton = Expanded(
                child: FilledButton.icon(
                  onPressed: onBuy,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF85EFAC),
                    foregroundColor: const Color(0xFF103224),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded),
                  label: const Text(
                    'Buy Shares',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              );
              final sellButton = Expanded(
                child: OutlinedButton.icon(
                  onPressed: ownedLots > 0 ? onSell : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.arrow_downward_rounded),
                  label: const Text(
                    'Sell Shares',
                    style: TextStyle(fontWeight: FontWeight.w900),
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
  });

  final String label;
  final String value;
  final Color color;

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
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
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

class _StockSparkline extends StatelessWidget {
  const _StockSparkline({required this.history, required this.accent});

  final List<int> history;
  final Color accent;

  static const double height = 120;

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return SizedBox(height: height);
    }

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: MiniSparkline(
        values: history.map((v) => v.toDouble()).toList(),
        color: accent,
      ),
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
    required this.amount,
    required this.createdAt,
  });

  final String symbol;
  final bool isBuy;
  final int amount;
  final DateTime createdAt;
}

final RegExp _stockOrderPattern = RegExp(r'^(Bought|Sold) ([A-Z]{1,5})$');

_StockOrder? _parseStockOrder(LedgerTransaction transaction) {
  final match = _stockOrderPattern.firstMatch(transaction.title);
  if (match == null) {
    return null;
  }
  return _StockOrder(
    symbol: match.group(2)!,
    isBuy: match.group(1) == 'Bought',
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
        border: Border.all(color: const Color(0xFF58C7FF).withValues(alpha: 0.30)),
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
                      style: TextStyle(
                        color: sideColor,
                        fontWeight: FontWeight.w900,
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
                      child: const Text(
                        'WORKING',
                        style: TextStyle(
                          color: Color(0xFF58C7FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
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
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w900),
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
    final sideColor = order.isBuy
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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
                order.isBuy ? 'Buy' : 'Sell',
                style: TextStyle(color: sideColor, fontWeight: FontWeight.w900),
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
    required this.netWorth,
    required this.totalEarned,
  });

  final List<double> portfolioHistory;
  final int netWorth;
  final int totalEarned;

  @override
  Widget build(BuildContext context) {
    final positive = totalEarned >= 0;
    final color = positive ? const Color(0xFF85EFAC) : const Color(0xFFFF8A80);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _SectionTitle(
          title: 'P&L',
          subtitle: 'How your invested gold has moved over time.',
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
                '${positive ? '+' : ''}${totalEarned}g',
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total P&L on open positions',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 140,
                child: MiniSparkline(
                  values: portfolioHistory,
                  color: color,
                  strokeWidth: 2.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ValueBadge(
          label: 'Net Worth',
          value: '${netWorth}g',
          color: const Color(0xFF58C7FF),
        ),
      ],
    );
  }
}
