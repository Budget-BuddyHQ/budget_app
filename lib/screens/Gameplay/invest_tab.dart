import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/custom_bottom_nav.dart';

class InvestTab extends StatelessWidget {
  const InvestTab({
    super.key,
    this.activeTabIndex = 2,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final indexFunds = stats.holdings['indexFunds'] ?? 0;
        final stockLots = stats.holdings['stocks'] ?? 0;
        final portfolioValue = (indexFunds * 210) + (stockLots * 165);
        final portfolioTrend = stats.portfolioHistory.isEmpty
            ? const <double>[0.24, 0.3, 0.36, 0.44, 0.52, 0.58, 0.64]
            : stats.portfolioHistory;

        return Scaffold(
          backgroundColor: const Color(0xFF0A211A),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected,
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
                          color: Colors.white.withOpacity(0.74),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _PortfolioHeroCard(
                        portfolioValue: portfolioValue,
                        availableGold: stats.gold,
                        chartPoints: portfolioTrend,
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 720;
                          final buyCard = _InvestActionCard(
                            title: 'Buy Index Fund',
                            subtitle:
                                'Spend 200 gold for a steady portfolio boost and a small XP gain.',
                            accent: const Color(0xFF85EFAC),
                            icon: Icons.trending_up_rounded,
                            buttonLabel: 'Invest 200',
                            style: const CustomButtonStyle.primary(),
                            onPressed: () async {
                              final result =
                                  await context.read<UserStatsController>().buyIndexFund();
                              if (!context.mounted) {
                                return;
                              }
                              GameToast.show(
                                context,
                                title: result.success ? 'Investment placed' : 'Not enough gold',
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
                            style: const CustomButtonStyle.secondary(),
                            onPressed: () async {
                              final result =
                                  await context.read<UserStatsController>().sellStocks();
                              if (!context.mounted) {
                                return;
                              }
                              GameToast.show(
                                context,
                                title: result.success ? 'Sale complete' : 'Nothing to sell',
                                message: result.message,
                                icon: result.success
                                    ? Icons.monetization_on_rounded
                                    : Icons.info_outline_rounded,
                                accent: result.success
                                    ? const Color(0xFFFFC36B)
                                    : const Color(0xFFFFC36B),
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
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                        color: Colors.black.withOpacity(0.06),
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                        child: Column(
                          children: const [
                            SkeletonLoader(height: 280, borderRadius: 28),
                            SizedBox(height: 18),
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
}

class _PortfolioHeroCard extends StatelessWidget {
  const _PortfolioHeroCard({
    required this.portfolioValue,
    required this.availableGold,
    required this.chartPoints,
  });

  final int portfolioValue;
  final int availableGold;
  final List<double> chartPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF15382C).withOpacity(0.96),
            const Color(0xFF214D3E).withOpacity(0.92),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF85EFAC).withOpacity(0.12),
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
              color: Colors.white.withOpacity(0.72),
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
          const SizedBox(height: 4),
          Text(
            '\$$availableGold liquid gold available now',
            style: const TextStyle(
              color: Color(0xFF85EFAC),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: LineChart(_buildChartData(chartPoints)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<double> points) {
    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: 0,
      maxY: 1,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: 0.25,
        getDrawingHorizontalLine: (_) => FlLine(
          color: Colors.white.withOpacity(0.06),
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
            points.length,
            (index) => FlSpot(index.toDouble(), points[index]),
          ),
          isCurved: true,
          barWidth: 4,
          color: const Color(0xFF85EFAC),
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 4,
              color: const Color(0xFF85EFAC),
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
                const Color(0xFF85EFAC).withOpacity(0.34),
                const Color(0xFF85EFAC).withOpacity(0.02),
              ],
            ),
          ),
        ),
      ],
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
    required this.style,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String buttonLabel;
  final CustomButtonStyle style;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
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
              color: Colors.white.withOpacity(0.72),
              height: 1.45,
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
              color: Colors.white.withOpacity(0.64),
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

