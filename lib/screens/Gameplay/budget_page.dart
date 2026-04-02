import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/skeleton_loader.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({
    super.key,
    this.activeTabIndex = 1,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final transactions = stats.transactions;
        final expenses = transactions.where((item) => item.amount < 0).toList();
        final incomes = transactions.where((item) => item.amount >= 0).toList();
        final totalSpent = expenses.fold<int>(0, (sum, item) => sum + item.amount.abs());
        final totalEarned = incomes.fold<int>(0, (sum, item) => sum + item.amount);
        final portfolioPoints = stats.portfolioHistory.isEmpty
            ? const <double>[0.22, 0.28, 0.36, 0.42, 0.5, 0.57, 0.64]
            : stats.portfolioHistory;
        final categories = _categoryTotals(expenses);

        return Scaffold(
          backgroundColor: const Color(0xFF081A14),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected,
                ),
          body: Stack(
            children: [
              const _Backdrop(),
              SafeArea(
                child: controller.isLoading
                    ? const _BudgetSkeleton()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
                        children: [
                          const Text(
                            'Financials',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'One clear home for your budget ledger, investment lab, and recent activity.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SummaryCard(
                            balance: stats.gold,
                            totalSpent: totalSpent,
                            totalEarned: totalEarned,
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked = constraints.maxWidth < 760;
                              final spending = _SpendingCard(
                                categories: categories,
                                totalSpent: totalSpent,
                              );
                              final investing = _InvestingCard(
                                points: portfolioPoints,
                                holdings: stats.holdings,
                              );

                              if (stacked) {
                                return Column(
                                  children: [
                                    spending,
                                    const SizedBox(height: 12),
                                    investing,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: spending),
                                  const SizedBox(width: 12),
                                  Expanded(child: investing),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked = constraints.maxWidth < 680;
                              final investAction = _ActionCard(
                                title: 'Buy Index Fund',
                                subtitle:
                                    'Spend 200 gold to grow your long-term portfolio safely.',
                                accent: const Color(0xFF85EFAC),
                                icon: Icons.trending_up_rounded,
                                buttonLabel: 'Invest 200',
                                style: const CustomButtonStyle.primary(),
                                onPressed: () async {
                                  final result = await context.read<UserStatsController>().buyIndexFund();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  GameToast.show(
                                    context,
                                    title: result.success ? 'Investment placed' : 'Action blocked',
                                    message: result.message,
                                    icon: result.success
                                        ? Icons.savings_rounded
                                        : Icons.warning_amber_rounded,
                                    accent: result.success
                                        ? const Color(0xFF85EFAC)
                                        : const Color(0xFFFFB084),
                                  );
                                },
                              );
                              final sellAction = _ActionCard(
                                title: 'Sell Stocks',
                                subtitle:
                                    'Convert one stock lot into 140 gold and lower your short-term risk.',
                                accent: const Color(0xFFFFD45C),
                                icon: Icons.sell_rounded,
                                buttonLabel: 'Sell 140',
                                style: const CustomButtonStyle.secondary(),
                                onPressed: () async {
                                  final result = await context.read<UserStatsController>().sellStocks();
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
                                    accent: const Color(0xFFFFD45C),
                                  );
                                },
                              );

                              if (stacked) {
                                return Column(
                                  children: [
                                    investAction,
                                    const SizedBox(height: 12),
                                    sellAction,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: investAction),
                                  const SizedBox(width: 12),
                                  Expanded(child: sellAction),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          _ActivityPanel(transactions: transactions),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, int> _categoryTotals(List<LedgerTransaction> expenses) {
    if (expenses.isEmpty) {
      return const <String, int>{
        'Needs': 320,
        'Investing': 180,
        'Unlocks': 110,
      };
    }

    final totals = <String, int>{};
    for (final item in expenses) {
      final category = switch (item.category.toLowerCase()) {
        'invest' => 'Investing',
        'unlock' => 'Unlocks',
        'challenge' => 'Challenge Fees',
        _ => 'Needs',
      };
      totals.update(category, (value) => value + item.amount.abs(), ifAbsent: () => item.amount.abs());
    }
    return totals;
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF06150F),
            Color(0xFF0B2119),
            Color(0xFF103127),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.balance,
    required this.totalSpent,
    required this.totalEarned,
  });

  final int balance;
  final int totalSpent;
  final int totalEarned;

  @override
  Widget build(BuildContext context) {
    final net = totalEarned - totalSpent;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clean Financial Snapshot',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$$balance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'Earned',
                  value: '\$$totalEarned',
                  accent: const Color(0xFF85EFAC),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  label: 'Spent',
                  value: '\$$totalSpent',
                  accent: const Color(0xFFFFB084),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  label: 'Net',
                  value: '${net >= 0 ? '+' : ''}\$$net',
                  accent: net >= 0
                      ? const Color(0xFF85EFAC)
                      : const Color(0xFFFFB084),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({
    required this.categories,
    required this.totalSpent,
  });

  final Map<String, int> categories;
  final int totalSpent;

  @override
  Widget build(BuildContext context) {
    final total = math.max(1, categories.values.fold(0, (sum, value) => sum + value));
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pie charts make the budget understandable at a glance.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 52,
                sectionsSpace: 4,
                sections: categories.entries.map((entry) {
                  final percent = entry.value / total;
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    color: _categoryColor(entry.key),
                    radius: 22,
                    title: '${(percent * 100).round()}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Monthly spend: \$$totalSpent',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...categories.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _categoryColor(entry.key),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '\$${entry.value}',
                    style: TextStyle(
                      color: _categoryColor(entry.key),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Investing':
        return const Color(0xFF85EFAC);
      case 'Unlocks':
        return const Color(0xFFFFD45C);
      case 'Challenge Fees':
        return const Color(0xFF58C7FF);
      default:
        return const Color(0xFFFFB084);
    }
  }
}

class _InvestingCard extends StatelessWidget {
  const _InvestingCard({
    required this.points,
    required this.holdings,
  });

  final List<double> points;
  final Map<String, int> holdings;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invest Lab',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Trend lines show growth without overwhelming the player.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: 0,
                maxY: 1,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
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
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    barWidth: 4,
                    color: const Color(0xFF85EFAC),
                    spots: List<FlSpot>.generate(
                      points.length,
                      (index) => FlSpot(index.toDouble(), points[index]),
                    ),
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF85EFAC).withValues(alpha: 0.28),
                          const Color(0xFF85EFAC).withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Index funds: ${holdings['indexFunds'] ?? 0} | Stocks: ${holdings['stocks'] ?? 0}',
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
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
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
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
          const SizedBox(height: 16),
          CustomButton(
            label: buttonLabel,
            onPressed: () => onPressed(),
            style: style,
            prefixIcon: Icon(icon, size: 18, color: style.textColor),
          ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({
    required this.transactions,
  });

  final List<LedgerTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          iconColor: const Color(0xFF85EFAC),
          collapsedIconColor: const Color(0xFF85EFAC),
          title: const Text(
            'Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            'The raw ledger stays tucked away until the user asks for it.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 12,
            ),
          ),
          children: transactions.map((transaction) {
            final positive = transaction.amount >= 0;
            final accent = positive
                ? const Color(0xFF85EFAC)
                : const Color(0xFFFFB084);

            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    positive ? Icons.call_received_rounded : Icons.call_made_rounded,
                    color: accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            height: 1.35,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        transaction.amountLabel,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        transaction.relativeLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _BudgetSkeleton extends StatelessWidget {
  const _BudgetSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
      children: const [
        SkeletonLoader(height: 180, borderRadius: 28),
        SizedBox(height: 18),
        SkeletonLoader(height: 320, borderRadius: 24),
        SizedBox(height: 12),
        SkeletonLoader(height: 320, borderRadius: 24),
        SizedBox(height: 18),
        SkeletonLoader(height: 170, borderRadius: 24),
        SizedBox(height: 12),
        SkeletonLoader(height: 170, borderRadius: 24),
        SizedBox(height: 18),
        SkeletonLoader(height: 220, borderRadius: 24),
      ],
    );
  }
}
