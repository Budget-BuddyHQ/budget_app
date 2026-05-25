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
  int _refreshSeed = 0;

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
    setState(() => _refreshSeed += 1);
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
    setState(() => _refreshSeed += 1);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().add(Duration(minutes: _refreshSeed));
    final quotes = _marketSeeds
        .map((seed) => _quoteFromSeed(seed, now))
        .toList(growable: false);

    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final totalMarketValue = quotes.fold<int>(
          0,
          (sum, quote) =>
              sum + ((stats.holdings['stock_${quote.symbol}'] ?? 0) * quote.sellValue),
        );
        final totalLots = quotes.fold<int>(
          0,
          (sum, quote) => sum + (stats.holdings['stock_${quote.symbol}'] ?? 0),
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
                onPressed: () => setState(() => _refreshSeed += 1),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _MarketHero(
                  gold: stats.gold,
                  totalLots: totalLots,
                  totalMarketValue: totalMarketValue,
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
    required this.onBuy,
    required this.onSell,
  });

  final _MarketQuote quote;
  final int ownedLots;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final positive = quote.changePercent >= 0;
    final changeColor =
        positive ? const Color(0xFF85EFAC) : const Color(0xFFFF8A80);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: changeColor.withValues(alpha: 0.22)),
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
                    value: '${quote.price}g',
                    color: const Color(0xFFE1BB72),
                  ),
                  _ValueBadge(
                    label: 'Day',
                    value:
                        '${positive ? '+' : ''}${quote.changePercent.toStringAsFixed(1)}%',
                    color: changeColor,
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
                  ],
                );
              }

              return Row(
                children: [
                  buyButton,
                  const SizedBox(width: 12),
                  sellButton,
                ],
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
    required this.price,
    required this.buyCost,
    required this.sellValue,
    required this.changePercent,
    required this.thesis,
  });

  final String symbol;
  final String company;
  final String sector;
  final int price;
  final int buyCost;
  final int sellValue;
  final double changePercent;
  final String thesis;
}

_MarketQuote _quoteFromSeed(_MarketSeed seed, DateTime now) {
  final clock = now.millisecondsSinceEpoch / Duration.millisecondsPerMinute;
  final primaryWave = math.sin((clock / 5.8) + seed.phase);
  final secondaryWave = math.cos((clock / 11.0) - (seed.phase * 0.7));
  final drift = (primaryWave * seed.volatility) + (secondaryWave * 0.018);
  final price = math.max(48, (seed.basePrice * (1 + drift)).round());
  final changePercent = drift * 100;

  return _MarketQuote(
    symbol: seed.symbol,
    company: seed.company,
    sector: seed.sector,
    price: price,
    buyCost: price,
    sellValue: math.max(24, (price * 0.94).round()),
    changePercent: changePercent,
    thesis: seed.thesis,
  );
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

