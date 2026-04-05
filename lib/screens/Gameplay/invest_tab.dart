import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/custom_bottom_nav.dart';

class InvestTab extends StatefulWidget {
  const InvestTab({
    super.key,
    this.activeTabIndex = 2,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  State<InvestTab> createState() => _InvestTabState();
}

class _InvestTabState extends State<InvestTab> {
  _ChartRange _selectedRange = _ChartRange.sevenDays;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final indexFunds = stats.holdings['indexFunds'] ?? 0;
        final stockLots = stats.holdings['stocks'] ?? 0;

        final indexFundValue = indexFunds * 210;
        final stockValue = stockLots * 165;
        final portfolioValue = indexFundValue + stockValue;
        final availableGold = stats.gold;

        final rawTrend = stats.portfolioHistory.isEmpty
            ? const <double>[0.24, 0.28, 0.31, 0.36, 0.41, 0.48, 0.54, 0.61]
            : stats.portfolioHistory;

        final chartPoints = _buildChartSeries(rawTrend, _selectedRange);
        final changePercent = _computeChangePercent(chartPoints);
        final positiveTrend = changePercent >= 0;

        final allocationTotal = math.max(1, indexFundValue + stockValue);
        final indexAllocation = indexFundValue / allocationTotal;
        final stockAllocation = stockValue / allocationTotal;

        final diversificationScore = _computeDiversificationScore(
          indexFunds: indexFunds,
          stockLots: stockLots,
        );

        final riskLabel = _computeRiskLabel(
          indexFunds: indexFunds,
          stockLots: stockLots,
        );

        final nextGoal = _buildGoalMessage(
          availableGold: availableGold,
          indexFunds: indexFunds,
          stockLots: stockLots,
        );

        final suggestion = _buildSuggestion(
          availableGold: availableGold,
          indexFunds: indexFunds,
          stockLots: stockLots,
          trendUp: positiveTrend,
        );

        return Scaffold(
          backgroundColor: const Color(0xFF0A211A),
          bottomNavigationBar: widget.onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: widget.activeTabIndex,
                  onSelected: widget.onNavSelected,
                ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invest Lab',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A simpler, friendlier investing view with a big top number and clear next actions.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.74),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _PortfolioHeroCard(
                        portfolioValue: portfolioValue,
                        availableGold: availableGold,
                        chartPoints: chartPoints,
                        changePercent: changePercent,
                        positiveTrend: positiveTrend,
                        selectedRange: _selectedRange,
                        onRangeChanged: (range) {
                          setState(() {
                            _selectedRange = range;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      _InsightGrid(
                        cards: [
                          _InsightCard(
                            title: 'Liquid Gold',
                            value: '\$$availableGold',
                            subtitle: availableGold >= 200
                                ? 'You can place an investment now.'
                                : 'Keep playing to unlock more actions.',
                            icon: Icons.account_balance_wallet_rounded,
                            accent: const Color(0xFF85EFAC),
                          ),
                          _InsightCard(
                            title: 'Trend',
                            value:
                                '${positiveTrend ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                            subtitle: positiveTrend
                                ? 'Your portfolio has been moving up.'
                                : 'A small dip can be a chance to rebalance.',
                            icon: positiveTrend
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            accent: positiveTrend
                                ? const Color(0xFF85EFAC)
                                : const Color(0xFFFFC36B),
                          ),
                          _InsightCard(
                            title: 'Risk Profile',
                            value: riskLabel,
                            subtitle: stockLots > indexFunds
                                ? 'You lean toward riskier lots.'
                                : 'Your mix stays relatively steady.',
                            icon: Icons.shield_moon_rounded,
                            accent: const Color(0xFFA6F0C2),
                          ),
                          _InsightCard(
                            title: 'Diversification',
                            value: '$diversificationScore%',
                            subtitle: diversificationScore >= 75
                                ? 'Nice balance across holdings.'
                                : 'Adding variety can lower concentration.',
                            icon: Icons.pie_chart_rounded,
                            accent: const Color(0xFF7DE9D1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 720;

                          final buyCard = _InvestActionCard(
                            title: 'Buy Index Fund',
                            subtitle:
                                'Spend 200 gold for a steadier portfolio boost and a small XP gain.',
                            accent: const Color(0xFF85EFAC),
                            icon: Icons.trending_up_rounded,
                            buttonLabel: 'Invest 200',
                            helperText: availableGold >= 200
                                ? 'Ready now'
                                : 'Need ${200 - availableGold} more gold',
                            style: const CustomButtonStyle.primary(),
                            onPressed: () async {
                              final result = await context
                                  .read<UserStatsController>()
                                  .buyIndexFund();
                              if (!context.mounted) {
                                return;
                              }
                              GameToast.show(
                                context,
                                title: result.success
                                    ? 'Investment placed'
                                    : 'Not enough gold',
                                message: result.message,
                                icon: result.success
                                    ? Icons.savings_rounded
                                    : Icons.warning_amber_rounded,
                                accent: result.success
                                    ? const Color(0xFF85EFAC)
                                    : const Color(0xFFFFC36B),
                              );
                            },
                          );

                          final sellCard = _InvestActionCard(
                            title: 'Sell Stocks',
                            subtitle:
                                'Take 140 gold back into your balance and rebalance your risk.',
                            accent: const Color(0xFFFFC36B),
                            icon: Icons.sell_rounded,
                            buttonLabel: 'Sell 140',
                            helperText: stockLots > 0
                                ? '$stockLots lots available to reduce'
                                : 'No stock lots available right now',
                            style: const CustomButtonStyle.secondary(),
                            onPressed: () async {
                              final result = await context
                                  .read<UserStatsController>()
                                  .sellStocks();
                              if (!context.mounted) {
                                return;
                              }
                              GameToast.show(
                                context,
                                title: result.success
                                    ? 'Sale complete'
                                    : 'Nothing to sell',
                                message: result.message,
                                icon: result.success
                                    ? Icons.monetization_on_rounded
                                    : Icons.info_outline_rounded,
                                accent: const Color(0xFFFFC36B),
                              );
                            },
                          );

                          if (stacked) {
                            return Column(
                              children: [
                                buyCard,
                                const SizedBox(height: 12),
                                sellCard,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: buyCard),
                              const SizedBox(width: 12),
                              Expanded(child: sellCard),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 860;

                          final allocationCard = _AllocationCard(
                            indexFunds: indexFunds,
                            stockLots: stockLots,
                            indexFundValue: indexFundValue,
                            stockValue: stockValue,
                            indexAllocation: indexAllocation,
                            stockAllocation: stockAllocation,
                          );

                          final strategyCard = _StrategyLabCard(
                            suggestion: suggestion,
                            nextGoal: nextGoal,
                            availableGold: availableGold,
                            progressToIndexFund:
                                (availableGold / 200).clamp(0.0, 1.0),
                            progressToBuffer:
                                (availableGold / 400).clamp(0.0, 1.0),
                          );

                          if (stacked) {
                            return Column(
                              children: [
                                allocationCard,
                                const SizedBox(height: 12),
                                strategyCard,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: allocationCard),
                              const SizedBox(width: 12),
                              Expanded(child: strategyCard),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current holdings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _HoldingRow(
                              label: 'Index Funds',
                              value: '$indexFunds lots',
                            ),
                            const SizedBox(height: 10),
                            _HoldingRow(
                              label: 'Stocks',
                              value: '$stockLots lots',
                            ),
                            const SizedBox(height: 10),
                            _HoldingRow(
                              label: 'Estimated Value',
                              value: '\$$portfolioValue',
                            ),
                            const SizedBox(height: 10),
                            _HoldingRow(
                              label: 'Liquid Gold',
                              value: '\$$availableGold',
                            ),
                            const SizedBox(height: 10),
                            _HoldingRow(
                              label: 'Wizard Advice',
                              value: stats.wizardAdvice,
                              multiLine: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.isLoading)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.06),
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                        child: Column(
                          children: const [
                            SkeletonLoader(height: 320, borderRadius: 28),
                            SizedBox(height: 18),
                            SkeletonLoader(height: 120, borderRadius: 24),
                            SizedBox(height: 12),
                            SkeletonLoader(height: 170, borderRadius: 24),
                            SizedBox(height: 12),
                            SkeletonLoader(height: 170, borderRadius: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<double> _buildChartSeries(List<double> raw, _ChartRange range) {
    if (raw.isEmpty) {
      return const [0.2, 0.3, 0.34, 0.4, 0.48, 0.56, 0.62];
    }

    switch (range) {
      case _ChartRange.sevenDays:
        if (raw.length <= 7) return raw;
        return raw.sublist(raw.length - 7);
      case _ChartRange.thirtyDays:
        if (raw.length <= 30) return raw;
        return raw.sublist(raw.length - 30);
      case _ChartRange.all:
        return raw;
    }
  }

  double _computeChangePercent(List<double> points) {
    if (points.length < 2) return 0;
    final first = points.first;
    final last = points.last;
    if (first == 0) return 0;
    return ((last - first) / first) * 100;
  }

  int _computeDiversificationScore({
    required int indexFunds,
    required int stockLots,
  }) {
    final total = indexFunds + stockLots;
    if (total == 0) return 0;
    final diff = (indexFunds - stockLots).abs();
    final raw = (100 - ((diff / total) * 100)).round();
    return raw.clamp(0, 100);
  }

  String _computeRiskLabel({
    required int indexFunds,
    required int stockLots,
  }) {
    if (stockLots == 0 && indexFunds == 0) return 'Starter';
    if (stockLots > indexFunds * 2) return 'High';
    if (stockLots > indexFunds) return 'Elevated';
    if (indexFunds > stockLots * 2) return 'Low';
    return 'Balanced';
  }

  String _buildGoalMessage({
    required int availableGold,
    required int indexFunds,
    required int stockLots,
  }) {
    if (availableGold < 200) {
      return 'Earn ${200 - availableGold} more gold to unlock your next index fund purchase.';
    }
    if (indexFunds == 0) {
      return 'Your first index fund would give your lab a steadier base.';
    }
    if (stockLots == 0) {
      return 'You are very conservative right now. Add variety when you are ready.';
    }
    return 'You have enough gold to keep compounding or hold a safer cash buffer.';
  }

  String _buildSuggestion({
    required int availableGold,
    required int indexFunds,
    required int stockLots,
    required bool trendUp,
  }) {
    if (availableGold >= 400 && indexFunds <= stockLots) {
      return 'You have strong buying power. Adding an index fund now would improve stability while keeping momentum.';
    }
    if (!trendUp && stockLots > indexFunds) {
      return 'Your mix leans riskier during a softer trend. Selling a stock lot could rebalance the lab.';
    }
    if (availableGold < 200) {
      return 'Keep playing games and stacking gold. Your next major invest action unlocks at 200 gold.';
    }
    return 'You are in a solid position. Either hold your gold buffer or place one steady investment.';
  }
}

enum _ChartRange {
  sevenDays,
  thirtyDays,
  all,
}

class _PortfolioHeroCard extends StatelessWidget {
  const _PortfolioHeroCard({
    required this.portfolioValue,
    required this.availableGold,
    required this.chartPoints,
    required this.changePercent,
    required this.positiveTrend,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final int portfolioValue;
  final int availableGold;
  final List<double> chartPoints;
  final double changePercent;
  final bool positiveTrend;
  final _ChartRange selectedRange;
  final ValueChanged<_ChartRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final trendColor =
        positiveTrend ? const Color(0xFF85EFAC) : const Color(0xFFFFC36B);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF15382C).withValues(alpha: 0.96),
            const Color(0xFF214D3E).withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF85EFAC).withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Portfolio Value',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$$portfolioValue',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '\$$availableGold liquid gold available now',
                style: const TextStyle(
                  color: Color(0xFF85EFAC),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: trendColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      positiveTrend
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: trendColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${positiveTrend ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _RangeChip(
                label: '7D',
                selected: selectedRange == _ChartRange.sevenDays,
                onTap: () => onRangeChanged(_ChartRange.sevenDays),
              ),
              const SizedBox(width: 8),
              _RangeChip(
                label: '30D',
                selected: selectedRange == _ChartRange.thirtyDays,
                onTap: () => onRangeChanged(_ChartRange.thirtyDays),
              ),
              const SizedBox(width: 8),
              _RangeChip(
                label: 'All',
                selected: selectedRange == _ChartRange.all,
                onTap: () => onRangeChanged(_ChartRange.all),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(_buildChartData(chartPoints, trendColor)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<double> points, Color trendColor) {
    final safePoints = points.isEmpty ? const [0.2, 0.3, 0.4, 0.5] : points;
    final minY = safePoints.reduce(math.min);
    final maxY = safePoints.reduce(math.max);
    final paddedMinY = math.max(0.0, minY - 0.08);
    final paddedMaxY = math.min(1.2, maxY + 0.08);

    return LineChartData(
      minX: 0,
      maxX: (safePoints.length - 1).toDouble(),
      minY: paddedMinY,
      maxY: paddedMaxY,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF19382D),
          tooltipRoundedRadius: 12,
          getTooltipItems: (spots) {
            return spots
                .map(
                  (spot) => LineTooltipItem(
                    'Point ${spot.x.toInt() + 1}\n${spot.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList();
          },
        ),
      ),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: (paddedMaxY - paddedMinY) / 3,
        getDrawingHorizontalLine: (_) => FlLine(
          color: Colors.white.withValues(alpha: 0.06),
          strokeWidth: 1,
        ),
      ),
      titlesData: const FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: List<FlSpot>.generate(
            safePoints.length,
            (index) => FlSpot(index.toDouble(), safePoints[index]),
          ),
          isCurved: true,
          barWidth: 4,
          color: trendColor,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
              radius: 4,
              color: trendColor,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                trendColor.withValues(alpha: 0.34),
                trendColor.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const Color(0xFF85EFAC).withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.04);

    final border = selected
        ? const Color(0xFF85EFAC).withValues(alpha: 0.34)
        : Colors.white.withValues(alpha: 0.08);

    final textColor =
        selected ? const Color(0xFF85EFAC) : Colors.white.withValues(alpha: 0.76);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InsightGrid extends StatelessWidget {
  const _InsightGrid({
    required this.cards,
  });

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        if (isSmall) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 12),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestActionCard extends StatelessWidget {
  const _InvestActionCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.buttonLabel,
    required this.helperText,
    required this.style,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String buttonLabel;
  final String helperText;
  final CustomButtonStyle style;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            helperText,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: buttonLabel,
            onPressed: () => onPressed(),
            prefixIcon: Icon(icon, size: 18, color: style.textColor),
            style: style,
          ),
        ],
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({
    required this.indexFunds,
    required this.stockLots,
    required this.indexFundValue,
    required this.stockValue,
    required this.indexAllocation,
    required this.stockAllocation,
  });

  final int indexFunds;
  final int stockLots;
  final int indexFundValue;
  final int stockValue;
  final double indexAllocation;
  final double stockAllocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Allocation breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _AllocationBar(
            label: 'Index Funds',
            lots: '$indexFunds lots',
            value: '\$$indexFundValue',
            progress: indexAllocation.clamp(0.0, 1.0),
            accent: const Color(0xFF85EFAC),
          ),
          const SizedBox(height: 14),
          _AllocationBar(
            label: 'Stocks',
            lots: '$stockLots lots',
            value: '\$$stockValue',
            progress: stockAllocation.clamp(0.0, 1.0),
            accent: const Color(0xFFFFC36B),
          ),
        ],
      ),
    );
  }
}

class _AllocationBar extends StatelessWidget {
  const _AllocationBar({
    required this.label,
    required this.lots,
    required this.value,
    required this.progress,
    required this.accent,
  });

  final String label;
  final String lots;
  final String value;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              lots,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }
}

class _StrategyLabCard extends StatelessWidget {
  const _StrategyLabCard({
    required this.suggestion,
    required this.nextGoal,
    required this.availableGold,
    required this.progressToIndexFund,
    required this.progressToBuffer,
  });

  final String suggestion;
  final String nextGoal;
  final int availableGold;
  final double progressToIndexFund;
  final double progressToBuffer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Strategy lab',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _MiniAdviceChip(
            icon: Icons.auto_awesome_rounded,
            accent: const Color(0xFF85EFAC),
            text: suggestion,
          ),
          const SizedBox(height: 12),
          _MiniAdviceChip(
            icon: Icons.flag_rounded,
            accent: const Color(0xFFFFC36B),
            text: nextGoal,
          ),
          const SizedBox(height: 16),
          Text(
            'Progress to next index fund',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressToIndexFund,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF85EFAC)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Progress to safer 400-gold buffer',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressToBuffer,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFFC36B)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Current cash buffer: \$$availableGold',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAdviceChip extends StatelessWidget {
  const _MiniAdviceChip({
    required this.icon,
    required this.accent,
    required this.text,
  });

  final IconData icon;
  final Color accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  final String label;
  final String value;
  final bool multiLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

