import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../reusable_widgets/custom_bottom_nav.dart';

class InvestScreen extends StatelessWidget {
  const InvestScreen({
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
        final holdings = stats.holdings;
        final indexFundLots = holdings['indexFunds'] ?? 0;
        final stockLots = holdings['stocks'] ?? 0;
        final portfolioValue = (indexFundLots * 210) + (stockLots * 165);

        return Scaffold(
          backgroundColor: const Color(0xFF1A4D3D),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected,
                ),
          body: SafeArea(
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF85EFAC)),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invest Lab',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Grow your gold with simulated investment choices that sync everywhere instantly.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.76),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF254E3F),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF3B6B59)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.stacked_line_chart,
                                    color: Color(0xFF85EFAC),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Simulated Portfolio Growth',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (controller.isSaving)
                                    const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF85EFAC),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 220,
                                child: LineChart(
                                  _buildChartData(stats.portfolioHistory),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InvestmentStat(
                                      label: 'Portfolio Value',
                                      value: '\$$portfolioValue',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _InvestmentStat(
                                      label: 'Available Gold',
                                      value: '\$${stats.gold}',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _InvestmentStat(
                                      label: 'Literacy Score',
                                      value: '${stats.literacyPoints}',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionTile(
                                title: 'Buy Index Fund',
                                subtitle:
                                    'Spend 200 gold to grow a steady long-term position.',
                                buttonLabel: 'Invest 200',
                                onPressed: () async {
                                  final result =
                                      await context.read<UserStatsController>().buyIndexFund();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result.message)),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionTile(
                                title: 'Sell Stocks',
                                subtitle:
                                    'Sell one stock lot for 140 gold and rebalance.',
                                buttonLabel: 'Sell 140',
                                onPressed: () async {
                                  final result =
                                      await context.read<UserStatsController>().sellStocks();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result.message)),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF254E3F),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF3B6B59)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Holdings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _HoldingRow(
                                label: 'Index Fund Lots',
                                value: '$indexFundLots',
                              ),
                              const SizedBox(height: 8),
                              _HoldingRow(
                                label: 'Stock Lots',
                                value: '$stockLots',
                              ),
                              const SizedBox(height: 8),
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
          ),
        );
      },
    );
  }

  LineChartData _buildChartData(List<double> series) {
    final safeSeries = series.isEmpty ? const <double>[0.24, 0.3] : series;
    return LineChartData(
      minX: 0,
      maxX: (safeSeries.length - 1).toDouble(),
      minY: 0,
      maxY: 1,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: 0.25,
        getDrawingHorizontalLine: (_) => FlLine(
          color: Colors.white.withOpacity(0.08),
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
            safeSeries.length,
            (index) => FlSpot(index.toDouble(), safeSeries[index]),
          ),
          isCurved: true,
          color: const Color(0xFF85EFAC),
          barWidth: 3,
          isStrokeCapRound: true,
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
              colors: [
                const Color(0xFF85EFAC).withOpacity(0.28),
                const Color(0xFF85EFAC).withOpacity(0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

class _InvestmentStat extends StatelessWidget {
  const _InvestmentStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF254E3F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3B6B59)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF85EFAC),
                foregroundColor: const Color(0xFF1A4D3D),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonLabel),
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
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
