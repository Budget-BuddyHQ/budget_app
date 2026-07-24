import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
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
  static const int _maxPoints = 90;

  final Map<String, List<double>> _series = <String, List<double>>{};
  final math.Random _rand = math.Random();
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    for (final seed in _marketSeeds) {
      final history = _buildPriceHistory(seed, now, 240);
      final sampled = <double>[];
      for (var i = 0; i < _maxPoints; i++) {
        sampled.add(history[(i * (history.length - 1)) ~/ (_maxPoints - 1)]);
      }
      _series[seed.symbol] = sampled;
    }

    _tickTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() {
        for (final seed in _marketSeeds) {
          final points = _series[seed.symbol]!;
          final current = points.last;
          
          var pct = (_rand.nextDouble() * 2 - 1) * 0.012 * (1 + seed.volatility * 4);
          if (_rand.nextDouble() < 0.06) {
            pct += (_rand.nextDouble() * 2 - 1) * 0.05;
          }
          if (_rand.nextDouble() < 0.008) {
            final magnitude = _rand.nextDouble();
            final sign = _rand.nextBool() ? 1 : -1;
            pct += sign * magnitude * magnitude * magnitude * 0.75;
          }
          final next = (current * (1 + pct)).clamp(
            seed.basePrice * 0.3,
            seed.basePrice * 4.0,
          );
          points.add(next);
          if (points.length > _maxPoints) {
            points.removeAt(0);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  _MarketQuote _quoteFor(_MarketSeed seed) {
    final points = _series[seed.symbol]!;
    final current = points.last;
    final previous = points.length > 1 ? points[points.length - 2] : current;
    final opening = points.first;
    final price = current.round();
    return _MarketQuote(
      symbol: seed.symbol,
      company: seed.company,
      sector: seed.sector,
      currentPrice: price,
      previousPrice: previous.round(),
      openingPrice: opening.round(),
      recentChangePercent: previous > 0
          ? (current - previous) / previous * 100
          : 0,
      openingChangePercent: opening > 0
          ? (current - opening) / opening * 100
          : 0,
      buyCost: price,
      sellValue: price,
      history: points.map((p) => p.round()).toList(growable: false),
      thesis: seed.thesis,
      icon: seed.icon,
      accent: seed.accent,
    );
  }

  Future<void> _showTradeDialog({
    required BuildContext context,
    required _MarketQuote quote,
    required bool isBuying,
    required int availableGold,
    required int ownedLots,
  }) async {
    final maxShares = isBuying
        ? (availableGold ~/ quote.currentPrice)
        : ownedLots;

    if (maxShares <= 0) {
      GameToast.show(
        context,
        title: isBuying ? 'Insufficient Gold' : 'No Shares Owned',
        message: isBuying
            ? 'You need at least ${quote.currentPrice} gold to buy 1 share of ${quote.symbol}.'
            : 'You do not own any shares of ${quote.symbol} to sell.',
        icon: Icons.info_outline_rounded,
        accent: const Color(0xFFFFB084),
      );
      return;
    }

    int selectedQuantity = 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final totalAmount = selectedQuantity * quote.currentPrice;

            return AlertDialog(
              backgroundColor: const Color(0xFF10281F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: quote.accent.withValues(alpha: 0.4)),
              ),
              title: Text(
                '${isBuying ? 'Buy' : 'Sell'} ${quote.symbol}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Price: ${quote.currentPrice}g per share',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$selectedQuantity / $maxShares',
                        style: TextStyle(
                          color: quote.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (maxShares > 1)
                    Slider(
                      value: selectedQuantity.toDouble(),
                      min: 1,
                      max: maxShares.toDouble(),
                      divisions: maxShares - 1,
                      activeColor: quote.accent,
                      inactiveColor: Colors.white12,
                      onChanged: (val) {
                        setDialogState(() {
                          selectedQuantity = val.round();
                        });
                      },
                    ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBuying ? 'Total Gold Cost:' : 'Total Gold Return:',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${totalAmount}g',
                        style: const TextStyle(
                          color: Color(0xFFE1BB72),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBuying ? const Color(0xFF85EFAC) : const Color(0xFFFF8A80),
                    foregroundColor: const Color(0xFF103224),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    isBuying ? 'CONFIRM BUY' : 'CONFIRM SELL',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final totalValue = selectedQuantity * quote.currentPrice;
      
      final result = isBuying
          ? await context.read<UserStatsController>().buyStockLot(
                symbol: quote.symbol,
                goldCost: totalValue,
                companyName: quote.company,
                quantity: selectedQuantity,
              )
          : await context.read<UserStatsController>().sellStockLot(
                symbol: quote.symbol,
                goldReturn: totalValue,
                companyName: quote.company,
                quantity: selectedQuantity,
              );

      if (!context.mounted) return;

      GameToast.show(
        context,
        title: result.success
            ? (isBuying ? 'Buy order filled' : 'Sell order filled')
            : 'Trade blocked',
        message: result.success
            ? '${isBuying ? 'Bought' : 'Sold'} $selectedQuantity share${selectedQuantity > 1 ? 's' : ''} of ${quote.symbol} for ${totalValue}g.'
            : result.message,
        icon: result.success
            ? (isBuying ? Icons.trending_up_rounded : Icons.attach_money_rounded)
            : Icons.info_outline_rounded,
        accent: result.success
            ? (isBuying ? const Color(0xFF85EFAC) : const Color(0xFFE1BB72))
            : const Color(0xFFFFB084),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotes = _marketSeeds.map(_quoteFor).toList(growable: false);

    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        
        final totalMarketValue = quotes.fold<int>(
          0,
          (sum, quote) =>
              sum +
              ((stats.holdings['stock_${quote.symbol}'] ?? 0) *
                  quote.currentPrice),
        );
        final totalLots = quotes.fold<int>(
          0,
          (sum, quote) => sum + (stats.holdings['stock_${quote.symbol}'] ?? 0),
        );
        final totalAssets = stats.gold + totalMarketValue;
        final weightedChange = quotes.fold<double>(0, (sum, quote) {
          final lots = stats.holdings['stock_${quote.symbol}'] ?? 0;
          return sum + (quote.recentChangePercent * lots);
        });
        final avgChangePercent = totalLots > 0
            ? weightedChange / totalLots
            : 0.0;
        final weightedOpenChange = quotes.fold<double>(0, (sum, quote) {
          final lots = stats.holdings['stock_${quote.symbol}'] ?? 0;
          return sum + (quote.openingChangePercent * lots);
        });
        final avgOpenChangePercent = totalLots > 0
            ? weightedOpenChange / totalLots
            : 0.0;
        final ownedSymbols = quotes
            .where(
              (quote) => (stats.holdings['stock_${quote.symbol}'] ?? 0) > 0,
            )
            .length;
        final portfolioTip = _portfolioTip(
          totalLots,
          ownedSymbols,
          avgChangePercent,
        );

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
                _TickerTape(quotes: quotes),
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
                  subtitle: 'Buy low, hold through swings, sell high.',
                ),
                const SizedBox(height: 14),
                for (final quote in quotes) ...[
                  _StockCard(
                    quote: quote,
                    ownedLots: stats.holdings['stock_${quote.symbol}'] ?? 0,
                    costBasis: stats.costBasis['stock_${quote.symbol}'] ?? 0,
                    onBuy: () => _showTradeDialog(
                      context: context,
                      quote: quote,
                      isBuying: true,
                      availableGold: stats.gold,
                      ownedLots: stats.holdings['stock_${quote.symbol}'] ?? 0,
                    ),
                    onSell: () => _showTradeDialog(
                      context: context,
                      quote: quote,
                      isBuying: false,
                      availableGold: stats.gold,
                      ownedLots: stats.holdings['stock_${quote.symbol}'] ?? 0,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TickerTape extends StatefulWidget {
  const _TickerTape({required this.quotes});

  final List<_MarketQuote> quotes;

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
        color: const Color(0xFF0A1D17),
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
            final positive = quote.recentChangePercent >= 0;
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
                  '${quote.recentChangePercent.abs().toStringAsFixed(1)}%',
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
                label: 'Owned Shares',
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

          return Column(
            crossAxisAlignment: stacked
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3FCB74),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: const Color(0xFF3FCB74).withValues(alpha: 0.96),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'The board is moving.',
                textAlign: stacked ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              chips,
            ],
          );
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
    final changeLabel = positive
        ? 'Up ${changePercent.toStringAsFixed(1)}%'
        : 'Down ${changePercent.abs().toStringAsFixed(1)}%';
    final changeColor = positive
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);
    final openPositive = openingChangePercent >= 0;
    final openLabel = openPositive
        ? 'Up ${openingChangePercent.toStringAsFixed(1)}%'
        : 'Down ${openingChangePercent.abs().toStringAsFixed(1)}%';
    final openColor = openPositive
        ? const Color(0xFF58C7FF)
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
            style: TextStyle(color: accent, fontWeight: FontWeight.w900),
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

  final _MarketQuote quote;
  final int ownedLots;
  final int costBasis;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final recentPositive = quote.recentChangePercent >= 0;
    final recentColor = recentPositive
        ? const Color(0xFF85EFAC)
        : const Color(0xFFFF8A80);
    final openPositive = quote.openingChangePercent >= 0;
    final openColor = openPositive
        ? const Color(0xFF58C7FF)
        : const Color(0xFFFF8A80);

    // Calculate Average Cost Basis & Position Return Metrics
    final double averageCost = ownedLots > 0 ? (costBasis / ownedLots) : 0.0;
    final double currentValue = (ownedLots * quote.currentPrice).toDouble();
    final double totalProfitLoss = ownedLots > 0 ? (currentValue - costBasis) : 0.0;
    final double profitLossPercent = averageCost > 0
        ? ((quote.currentPrice - averageCost) / averageCost) * 100
        : 0.0;

    final bool isProfitable = totalProfitLoss >= 0;
    final Color plColor = isProfitable ? const Color(0xFF85EFAC) : const Color(0xFFFF8A80);
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

class _MarketSeed {
  const _MarketSeed({
    required this.symbol,
    required this.company,
    required this.sector,
    required this.basePrice,
    required this.volatility,
    required this.phase,
    required this.thesis,
    required this.icon,
    required this.accent,
  });

  final String symbol;
  final String company;
  final String sector;
  final int basePrice;
  final double volatility;
  final double phase;
  final String thesis;
  final IconData icon;
  final Color accent;
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
    required this.icon,
    required this.accent,
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
  final List<int> history;
  final String thesis;
  final IconData icon;
  final Color accent;
}

List<double> _buildPriceHistory(_MarketSeed seed, DateTime now, int points) {
  final base = seed.basePrice.toDouble();
  final symbolBias = _seedFromDescription(
    seed.symbol + seed.company + seed.sector,
  );
  final annualDrift = 0.02 + (symbolBias * 0.008);
  const minutesPerTradingDay = 390;
  final dt = 1 / (252 * minutesPerTradingDay);

  final longScale = 3.0;
  final sigmaLongAnnual = math.max(0.04, seed.volatility * longScale);
  final sigmaLong = sigmaLongAnnual * math.sqrt(dt);

  final startMinute = now.subtract(Duration(minutes: points - 1));
  final values = <double>[];
  var price = base;

  const eventProbBase = 0.002;
  const eventSigmaBase = 0.06;

  for (var index = 0; index < points; index += 1) {
    final minuteTime = startMinute.add(Duration(minutes: index));
    final tick = minuteTime.millisecondsSinceEpoch;

    final zLong = _gaussianNoise(seed, tick);
    final driftLong =
        (annualDrift - 0.5 * sigmaLongAnnual * sigmaLongAnnual) * dt;
    final longTerm = sigmaLong * zLong;
    price *= math.exp(driftLong + longTerm);

    final u = _stableUniform(seed, tick + 7919);
    if (u < eventProbBase) {
      final jumpZ = _gaussianNoise(seed, tick + 46021);
      final jumpFactor = math.exp(jumpZ * eventSigmaBase);
      price *= jumpFactor;
    }

    if (!price.isFinite || price.isNaN) {
      price = base;
    }
    price = price.clamp(24.0, base * 24.0);
    values.add(price);
  }
  return values;
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

    final minPrice = history.reduce(math.min).toDouble();
    final maxPrice = history.reduce(math.max).toDouble();
    final padding = math.max(1.0, (maxPrice - minPrice) * 0.12);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          minX: 0,
          maxX: (history.length - 1).toDouble(),
          minY: minPrice - padding,
          maxY: maxPrice + padding,
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < history.length; i++)
                  FlSpot(i.toDouble(), history[i].toDouble()),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              color: accent,
              barWidth: 2.6,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.32),
                    accent.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
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
  final hash = _stableHash(
    '${seed.symbol}|${seed.company}|${seed.sector}|$tick',
  );
  final u1 = ((hash & 0xFFFF) + 1) / 65537.0;
  final u2 = (((hash >> 16) & 0xFFFF) + 1) / 65537.0;
  final r = math.sqrt(-2.0 * math.log(u1));
  return r * math.cos(2 * math.pi * u2);
}

double _stableUniform(_MarketSeed seed, int tick) {
  final hash = _stableHash(
    '${seed.symbol}|${seed.company}|${seed.sector}|u|$tick',
  );
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
    icon: Icons.account_balance_rounded,
    accent: Color(0xFFE1BB72),
  ),
  _MarketSeed(
    symbol: 'EDU',
    company: 'EduSpark Labs',
    sector: 'Learning tech',
    basePrice: 126,
    volatility: 0.12,
    phase: 1.9,
    thesis:
        'Fast-growing education platform riding stronger classroom adoption.',
    icon: Icons.school_rounded,
    accent: Color(0xFF58C7FF),
  ),
  _MarketSeed(
    symbol: 'GRN',
    company: 'GreenGrid Energy',
    sector: 'Utilities',
    basePrice: 152,
    volatility: 0.08,
    phase: 2.7,
    thesis:
        'Lower volatility name with dependable cash flow and modest upside.',
    icon: Icons.eco_rounded,
    accent: Color(0xFF85EFAC),
  ),
  _MarketSeed(
    symbol: 'RKT',
    company: 'Rocket Retail',
    sector: 'E-commerce',
    basePrice: 112,
    volatility: 0.15,
    phase: 3.5,
    thesis:
        'Higher-risk momentum play that can move quickly in both directions.',
    icon: Icons.rocket_launch_rounded,
    accent: Color(0xFFFF8FB1),
  ),
];