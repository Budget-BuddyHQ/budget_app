import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../widgets_custom_lotties/game_toast.dart';

class StockMarketPage extends StatefulWidget {
  const StockMarketPage({super.key});

  @override
  State<StockMarketPage> createState() => _StockMarketPageState();
}

class _StockMarketPageState extends State<StockMarketPage> {
  final Set<String> _expandedSymbols = <String>{};
  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    _scheduleMinuteRefresh();
  }

  void _scheduleMinuteRefresh() {
    _minuteTimer?.cancel();
    final now = DateTime.now();
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute).add(const Duration(minutes: 1));
    final initialDelay = nextMinute.difference(now);

    _minuteTimer = Timer(initialDelay, () {
      if (!mounted) return;
      setState(() {});
      _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) return;
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    super.dispose();
  }

  Future<void> _buyLot(BuildContext context, _MarketQuote quote) async {
    final result = await context.read<UserStatsController>().buyStockLot(
      symbol: quote.symbol,
      goldCost: quote.buyCost,
      companyName: quote.company,
    );

    if (!context.mounted) {
      return;
    }

    GameToast.show(
      context,
      title: result.success ? 'Buy order filled' : 'Trade blocked',
      message: result.success
          ? '${quote.symbol} added to your holdings for ${quote.buyCost} gold.'
          : result.message,
      icon: result.success
          ? Icons.trending_up_rounded
          : Icons.info_outline_rounded,
      accent: result.success
          ? const Color(0xFF85EFAC)
          : const Color(0xFFFFB084),
    );
  }

  Future<void> _sellLot(BuildContext context, _MarketQuote quote) async {
    final result = await context.read<UserStatsController>().sellStockLot(
      symbol: quote.symbol,
      goldReturn: quote.sellValue,
      companyName: quote.company,
    );

    if (!context.mounted) {
      return;
    }

    GameToast.show(
      context,
      title: result.success ? 'Sell order filled' : 'Trade blocked',
      message: result.success
          ? '${quote.symbol} sold for ${quote.sellValue} gold.'
          : result.message,
      icon: result.success
          ? Icons.attach_money_rounded
          : Icons.info_outline_rounded,
      accent: result.success
          ? const Color(0xFFE1BB72)
          : const Color(0xFFFFB084),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final minuteNow = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute);
    final quotes = _marketSeeds
      .map((seed) => _quoteFromSeed(seed, minuteNow))
      .toList(growable: false);

    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final totalMarketValue = quotes.fold<int>(
          0,
          (sum, quote) =>
              sum + ((stats.holdings['stock_${quote.symbol}'] ?? 0) * quote.currentPrice),
        );
        final totalLots = quotes.fold<int>(
          0,
          (sum, quote) => sum + (stats.holdings['stock_${quote.symbol}'] ?? 0),
        );
        final totalAssets = stats.gold + totalMarketValue;
        final weightedChange = quotes.fold<double>(
          0,
          (sum, quote) {
            final lots = stats.holdings['stock_${quote.symbol}'] ?? 0;
            return sum + (quote.recentChangePercent * lots);
          },
        );
        final avgChangePercent = totalLots > 0 ? weightedChange / totalLots : 0.0;
        final weightedOpenChange = quotes.fold<double>(
          0,
          (sum, quote) {
            final lots = stats.holdings['stock_${quote.symbol}'] ?? 0;
            return sum + (quote.openingChangePercent * lots);
          },
        );
        final avgOpenChangePercent = totalLots > 0 ? weightedOpenChange / totalLots : 0.0;
        final ownedSymbols = quotes
            .where((quote) => (stats.holdings['stock_${quote.symbol}'] ?? 0) > 0)
            .length;
        final portfolioTip = _portfolioTip(totalLots, ownedSymbols, avgChangePercent);

        return Scaffold(
          backgroundColor: const Color(0xFF071711),
          appBar: AppBar(
            backgroundColor: const Color(0xFF071711),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Market Board',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh board',
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Welcome to the Budget Buddy Stock Exchange',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Buy and sell lots, view price history, and practice portfolio management. Use the history toggle to inspect intraday movement.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _MarketHero(
                  gold: stats.gold,
                  totalLots: totalLots,
                  totalMarketValue: totalMarketValue,
                ),
                const SizedBox(height: 18),
                _PortfolioSummary(
                  cash: stats.gold,
                  marketValue: totalMarketValue,
                  netWorth: totalAssets,
                  changePercent: avgChangePercent,
                  openingChangePercent: avgOpenChangePercent,
                  tip: portfolioTip,
                ),
                const SizedBox(height: 18),
                const _SectionTitle(
                  title: 'Trade Board',
                  subtitle:
                      'Buy lots with gold, hold them through swings, and sell back into your wallet when the board looks good.',
                ),
                const SizedBox(height: 14),
                for (final quote in quotes) ...[
                  _StockCard(
                    quote: quote,
                    ownedLots: stats.holdings['stock_${quote.symbol}'] ?? 0,
                    expanded: _expandedSymbols.contains(quote.symbol),
                    onToggleExpand: () {
                      setState(() {
                        if (_expandedSymbols.contains(quote.symbol)) {
                          _expandedSymbols.remove(quote.symbol);
                        } else {
                          _expandedSymbols.add(quote.symbol);
                        }
                      });
                    },
                    onBuy: () => _buyLot(context, quote),
                    onSell: () => _sellLot(context, quote),
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 4),
                const _SectionTitle(
                  title: 'Live Feed Note',
                  subtitle:
                      'This board uses a local market simulation right now. The screen is ready to swap to a real stock API once we choose a provider and key flow.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MarketHero extends StatelessWidget {
  const _MarketHero({
    required this.gold,
    required this.totalLots,
    required this.totalMarketValue,
  });

  final int gold;
  final int totalLots;
  final int totalMarketValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF173C2F).withValues(alpha: 0.96),
            const Color(0xFF214D3E).withValues(alpha: 0.90),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 620;
          final chips = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MarketMetric(
                label: 'Available Gold',
                value: '$gold',
                accent: const Color(0xFFE1BB72),
              ),
              _MarketMetric(
                label: 'Owned Lots',
                value: '$totalLots',
                accent: const Color(0xFF85EFAC),
              ),
              _MarketMetric(
                label: 'Market Value',
                value: '$totalMarketValue',
                accent: const Color(0xFF58C7FF),
              ),
            ],
          );

          final copy = Column(
            crossAxisAlignment:
                stacked ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                'STOCKS SIDE MODE',
                style: TextStyle(
                  color: const Color(0xFFFFD45C).withValues(alpha: 0.96),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Practice market timing without leaving the game loop.',
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Each lot costs gold, moves with the board, and can be sold back into your run economy when you want liquidity.',
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              chips,
            ],
          );

          return copy;
        },
      ),
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  const _PortfolioSummary({
    required this.cash,
    required this.marketValue,
    required this.netWorth,
    required this.changePercent,
    required this.openingChangePercent,
    required this.tip,
  });

  final int cash;
  final int marketValue;
  final int netWorth;
  final double changePercent;
  final double openingChangePercent;
  final String tip;

  @override
  Widget build(BuildContext context) {
    final positive = changePercent >= 0;
    final changeLabel = positive ? 'Up ${changePercent.toStringAsFixed(1)}%' : 'Down ${changePercent.abs().toStringAsFixed(1)}%';
    final changeColor = positive ? const Color(0xFF85EFAC) : const Color(0xFFFF8A80);
    final openPositive = openingChangePercent >= 0;
    final openLabel = openPositive ? 'Up ${openingChangePercent.toStringAsFixed(1)}%' : 'Down ${openingChangePercent.abs().toStringAsFixed(1)}%';
    final openColor = openPositive ? const Color(0xFF58C7FF) : const Color(0xFFFF8A80);

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
            style: const TextStyle(
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
                label: 'Since Open',
                value: openLabel,
                color: openColor,
              ),
              _ValueBadge(
                label: 'Current Move',
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

String _portfolioTip(int totalLots, int ownedSymbols, double avgChangePercent) {
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

class _MarketMetric extends StatelessWidget {
  const _MarketMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
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
    required this.expanded,
    required this.onToggleExpand,
    required this.onBuy,
    required this.onSell,
  });

  final _MarketQuote quote;
  final int ownedLots;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final recentPositive = quote.recentChangePercent >= 0;
    final recentColor = recentPositive ? const Color(0xFF85EFAC) : const Color(0xFFFF8A80);
    final openPositive = quote.openingChangePercent >= 0;
    final openColor = openPositive ? const Color(0xFF58C7FF) : const Color(0xFFFF8A80);

    return Container(
      padding: const EdgeInsets.all(18),
       decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: recentColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 520;
              final headerInfo = Expanded(
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
                    label: 'Since Open',
                    value:
                        '${openPositive ? '+' : ''}${quote.openingChangePercent.toStringAsFixed(1)}%',
                    color: openColor,
                  ),
                  _ValueBadge(
                    label: 'Since Last',
                    value:
                        '${recentPositive ? '+' : ''}${quote.recentChangePercent.toStringAsFixed(1)}%',
                    color: recentColor,
                  ),
                  _ValueBadge(
                    label: 'Owned',
                    value: '$ownedLots',
                    color: const Color(0xFF58C7FF),
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 12),
                    badges,
                  ],
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
          const SizedBox(height: 14),
          Text(
            quote.thesis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
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
                  label: Text(
                    'Buy ${quote.buyCost}g',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              );
              final expandButton = TextButton.icon(
                onPressed: onToggleExpand,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(
                  expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                ),
                label: Text(
                  expanded ? 'Hide history' : 'Show history',
                  style: const TextStyle(fontWeight: FontWeight.w900),
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
                  label: Text(
                    'Sell ${quote.sellValue}g',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              );

              if (stacked) {
                return Column(
                  children: [
                    Row(children: [buyButton]),
                    const SizedBox(height: 10),
                    Row(children: [sellButton]),
                    const SizedBox(height: 10),
                    Row(children: [Expanded(child: expandButton)]),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [buyButton, const SizedBox(width: 12), sellButton],
                  ),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: expandButton)]),
                ],
              );
            },
          ),
          if (expanded) ...[
            const SizedBox(height: 16),
            _StockHistoryChart(history: quote.history),
          ],
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
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

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

class _MarketSeed {
  const _MarketSeed({
    required this.symbol,
    required this.company,
    required this.sector,
    required this.basePrice,
    required this.volatility,
    required this.phase,
    required this.thesis,
  });

  final String symbol;
  final String company;
  final String sector;
  final int basePrice;
  final double volatility;
  final double phase;
  final String thesis;
}

class _MarketQuote {
  const _MarketQuote({
    required this.symbol,
    required this.company,
    required this.sector,
    required this.currentPrice,
    required this.previousPrice,
    required this.openingPrice,
    required this.recentChangePercent,
    required this.openingChangePercent,
    required this.buyCost,
    required this.sellValue,
    required this.history,
    required this.thesis,
  });

  final String symbol;
  final String company;
  final String sector;
  final int currentPrice;
  final int previousPrice;
  final int openingPrice;
  final double recentChangePercent;
  final double openingChangePercent;
  final int buyCost;
  final int sellValue;
  final List<int> history; // downsampled history used for chart
  final String thesis;
}

_MarketQuote _quoteFromSeed(_MarketSeed seed, DateTime now, [int displayPoints = 360]) {
  // build a full 24-hour minute base history (long-term GBM)
  const minutes24h = 24 * 60;
  final baseHistory = _buildPriceHistory(seed, now, minutes24h); // List<double>

  // overlay short-term intraday noise only on the most recent window so "since open" stays calmer
  final augmented = List<double>.from(baseHistory);
  final applyWindow = math.min(baseHistory.length, 240); // minutes to apply short noise
  final startIndex = baseHistory.length - applyWindow;
  var shortNoise = 0.0;
  const shortPhi = 0.88;
  final shortSigma = math.max(0.006, seed.volatility * 0.06);
  for (var i = startIndex; i < baseHistory.length; i += 1) {
    final minuteTime = now.subtract(Duration(minutes: baseHistory.length - 1 - i));
    final tick = minuteTime.millisecondsSinceEpoch;
    final zShort = _gaussianNoise(seed, tick + 1234567);
    shortNoise = shortPhi * shortNoise + shortSigma * zShort;
    augmented[i] = baseHistory[i] * math.exp(shortNoise);
  }

  final currentDouble = augmented.last;
  final previousDouble = augmented.length > 1 ? augmented[augmented.length - 2] : currentDouble;
  final recentChangePercent = previousDouble > 0 ? ((currentDouble - previousDouble) / previousDouble) * 100 : 0.0;

  // opening price = price at start of day (UTC) derived from baseHistory (no short noise)
  final openingMinute = DateTime.utc(now.year, now.month, now.day);
  final minutesSinceOpen = now.difference(openingMinute).inMinutes;
  double openingDouble;
  if (minutesSinceOpen >= 0 && minutesSinceOpen < baseHistory.length) {
    final openingIndex = baseHistory.length - 1 - minutesSinceOpen;
    openingDouble = baseHistory[openingIndex.clamp(0, baseHistory.length - 1)];
  } else {
    openingDouble = baseHistory.first;
  }
  final openingChangePercent = openingDouble > 0 ? ((currentDouble - openingDouble) / openingDouble) * 100 : 0.0;

  // produce integer chart history by sampling the augmented (short-noise applied) history
  final chartHistory = <int>[];
  if (augmented.length <= displayPoints) {
    chartHistory.addAll(augmented.map((d) => d.round()));
  } else {
    for (var index = 0; index < displayPoints; index += 1) {
      final sampleIndex = ((index * (augmented.length - 1)) / (displayPoints - 1)).round();
      chartHistory.add(augmented[sampleIndex].round());
    }
    final currentPriceRounded = currentDouble.round();
    if (chartHistory.last != currentPriceRounded) {
      chartHistory[chartHistory.length - 1] = currentPriceRounded;
    }
  }

  final currentPrice = currentDouble.round();
  final previousPrice = previousDouble.round();
  final openingPrice = openingDouble.round();

  return _MarketQuote(
    symbol: seed.symbol,
    company: seed.company,
    sector: seed.sector,
    currentPrice: currentPrice,
    previousPrice: previousPrice,
    openingPrice: openingPrice,
    recentChangePercent: recentChangePercent,
    openingChangePercent: openingChangePercent,
    buyCost: currentPrice,
    sellValue: currentPrice,
    history: chartHistory,
    thesis: seed.thesis,
  );
}

List<double> _buildPriceHistory(_MarketSeed seed, DateTime now, int points) {
  final base = seed.basePrice.toDouble();
  final symbolBias = _seedFromDescription(seed.symbol + seed.company + seed.sector);
  final annualDrift = 0.02 + (symbolBias * 0.008);
  const minutesPerTradingDay = 390;
  final dt = 1 / (252 * minutesPerTradingDay);

  // Long-term GBM parameters (reduced to keep day-to-day moves calmer)
  final longScale = 3.0;
  final sigmaLongAnnual = math.max(0.04, seed.volatility * longScale);
  final sigmaLong = sigmaLongAnnual * math.sqrt(dt);

  final startMinute = now.subtract(Duration(minutes: points - 1));
  final values = <double>[];
  var price = base;

  // occasional deterministic 'news' events on the base series (rare)
  const eventProbBase = 0.002; // per-minute chance
  const eventSigmaBase = 0.06;

  for (var index = 0; index < points; index += 1) {
    final minuteTime = startMinute.add(Duration(minutes: index));
    final tick = minuteTime.millisecondsSinceEpoch;

    final zLong = _gaussianNoise(seed, tick);
    final driftLong = (annualDrift - 0.5 * sigmaLongAnnual * sigmaLongAnnual) * dt;
    final longTerm = sigmaLong * zLong;
    price *= math.exp(driftLong + longTerm);

    // deterministic occasional jump/spike based on stable uniform (affects base/day)
    final u = _stableUniform(seed, tick + 7919);
    if (u < eventProbBase) {
      final jumpZ = _gaussianNoise(seed, tick + 46021);
      final jumpFactor = math.exp(jumpZ * eventSigmaBase);
      price *= jumpFactor;
    }

    if (!price.isFinite || price.isNaN) {
      price = base;
    }
    // clamp to reasonable band to avoid extreme explosions
    price = price.clamp(24.0, base * 24.0);
    values.add(price);
  }
  return values;
}

class _StockHistoryChart extends StatelessWidget {
  const _StockHistoryChart({
    required this.history,
  });

  final List<int> history;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 165,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(12),
      child: CustomPaint(
        painter: _StockHistoryPainter(history),
      ),
    );
  }
}

class _StockHistoryPainter extends CustomPainter {
  _StockHistoryPainter(this.history);

  final List<int> history;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) {
      return;
    }

    final minPrice = history.reduce(math.min).toDouble();
    final maxPrice = history.reduce(math.max).toDouble();
    final range = math.max(1.0, maxPrice - minPrice);
    final linePaint = Paint()
      ..color = const Color(0xFF85EFAC)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final markerPaint = Paint()
      ..color = const Color(0xFF85EFAC)
      ..style = PaintingStyle.fill;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    for (var index = 0; index < history.length; index += 1) {
      final x = (size.width - 4) * (index / (history.length - 1)) + 2;
      final y = size.height - ((history[index] - minPrice) / range) * size.height;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);
    final endX = (size.width - 4) * ((history.length - 1) / (history.length - 1)) + 2;
    final endY = size.height - ((history.last - minPrice) / range) * size.height;
    canvas.drawCircle(Offset(endX, endY), 4, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _StockHistoryPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}

int _stableHash(String input) {
  var hash = 5381;
  for (final codeUnit in input.codeUnits) {
    hash = ((hash << 5) + hash) ^ codeUnit;
  }
  return hash & 0x7FFFFFFF;
}

double _gaussianNoise(_MarketSeed seed, int tick) {
  final hash = _stableHash('${seed.symbol}|${seed.company}|${seed.sector}|$tick');
  final u1 = ((hash & 0xFFFF) + 1) / 65537.0;
  final u2 = (((hash >> 16) & 0xFFFF) + 1) / 65537.0;
  final r = math.sqrt(-2.0 * math.log(u1));
  return r * math.cos(2 * math.pi * u2);
}

double _stableUniform(_MarketSeed seed, int tick) {
  final hash = _stableHash('${seed.symbol}|${seed.company}|${seed.sector}|u|$tick');
  return (hash % 100000) / 100000.0;
}

double _seedFromDescription(String description) {
  var hash = 0;
  for (final codeUnit in description.codeUnits) {
    hash = ((hash << 5) - hash) + codeUnit;
    hash &= 0x7FFFFFFF;
  }
  return ((hash % 1000) / 1000.0) - 0.5;
}

const List<_MarketSeed> _marketSeeds = <_MarketSeed>[
  _MarketSeed(
    symbol: 'BBK',
    company: 'Budget Buddy Bank',
    sector: 'Consumer finance',
    basePrice: 138,
    volatility: 0.10,
    phase: 0.8,
    thesis: 'Stable regional lender with steady savings-product demand.',
  ),
  _MarketSeed(
    symbol: 'EDU',
    company: 'EduSpark Labs',
    sector: 'Learning tech',
    basePrice: 126,
    volatility: 0.12,
    phase: 1.9,
    thesis: 'Fast-growing education platform riding stronger classroom adoption.',
  ),
  _MarketSeed(
    symbol: 'GRN',
    company: 'GreenGrid Energy',
    sector: 'Utilities',
    basePrice: 152,
    volatility: 0.08,
    phase: 2.7,
    thesis: 'Lower volatility name with dependable cash flow and modest upside.',
  ),
  _MarketSeed(
    symbol: 'RKT',
    company: 'Rocket Retail',
    sector: 'E-commerce',
    basePrice: 112,
    volatility: 0.15,
    phase: 3.5,
    thesis: 'Higher-risk momentum play that can move quickly in both directions.',
  ),
];

