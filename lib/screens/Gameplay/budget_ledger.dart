import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../services/supabase_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../reusable_widgets/custom_bottom_nav.dart';

class BudgetLedger extends StatelessWidget {
  const BudgetLedger({
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
        final debitTransactions = transactions
            .where((transaction) => transaction.amount < 0)
            .toList(growable: false);
        final totalSpent = debitTransactions.fold<int>(
          0,
          (sum, item) => sum + item.amount.abs(),
        );
        final totalEarned = transactions.fold<int>(
          0,
          (sum, item) => item.amount > 0 ? sum + item.amount : sum,
        );

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
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                  children: [
                    const Text(
                      'Budget Ledger',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A clean view of where your gold goes, what comes back, and how steady your habits feel.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.74),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _BudgetHeroCard(
                      currentBalance: stats.gold,
                      totalSpent: totalSpent,
                      totalEarned: totalEarned,
                    ),
                    const SizedBox(height: 18),
                    _SpendingDonutCard(
                      transactions: debitTransactions,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Recent activity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      itemCount: transactions.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == transactions.length - 1 ? 0 : 12,
                          ),
                          child: _WalletTransactionCard(
                            transaction: transactions[index],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (controller.isLoading)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.06),
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                        child: Column(
                          children: const [
                            SkeletonLoader(height: 120, borderRadius: 24),
                            SizedBox(height: 18),
                            SkeletonLoader(height: 260, borderRadius: 24),
                            SizedBox(height: 18),
                            SkeletonLoader(height: 102, borderRadius: 22),
                            SizedBox(height: 12),
                            SkeletonLoader(height: 102, borderRadius: 22),
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

class _BudgetHeroCard extends StatelessWidget {
  const _BudgetHeroCard({
    required this.currentBalance,
    required this.totalSpent,
    required this.totalEarned,
  });

  final int currentBalance;
  final int totalSpent;
  final int totalEarned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF173C2F).withValues(alpha: 0.96),
            const Color(0xFF214D3E).withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Gold',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$$currentBalance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _BudgetMetricChip(
                  label: 'Spent',
                  value: '\$$totalSpent',
                  accent: const Color(0xFFFF8A80),
                  icon: Icons.north_east_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BudgetMetricChip(
                  label: 'Earned',
                  value: '\$$totalEarned',
                  accent: const Color(0xFF85EFAC),
                  icon: Icons.south_west_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetMetricChip extends StatelessWidget {
  const _BudgetMetricChip({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
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
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.64),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpendingDonutCard extends StatelessWidget {
  const _SpendingDonutCard({
    required this.transactions,
  });

  final List<LedgerTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final chartData = _buildCategoryTotals(transactions);
    final sections = _buildSections(chartData);
    final total = chartData.values.fold<int>(0, (sum, value) => sum + value);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A donut chart keeps this fast and readable for first-time users.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 420;
              final chart = SizedBox(
                height: 210,
                width: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 54,
                        sections: sections,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Monthly Spend',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final legend = Column(
                children: chartData.entries.map((entry) {
                  final color = _categoryColor(entry.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _titleCase(entry.key),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '\$${entry.value}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(growable: false),
              );

              if (stacked) {
                return Column(
                  children: [
                    chart,
                    const SizedBox(height: 18),
                    legend,
                  ],
                );
              }

              return Row(
                children: [
                  chart,
                  const SizedBox(width: 18),
                  Expanded(child: legend),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, int> _buildCategoryTotals(List<LedgerTransaction> transactions) {
    if (transactions.isEmpty) {
      return const <String, int>{
        'essentials': 220,
        'invest': 140,
        'unlock': 90,
      };
    }

    final totals = <String, int>{};
    for (final transaction in transactions) {
      totals.update(
        transaction.category,
        (value) => value + transaction.amount.abs(),
        ifAbsent: () => transaction.amount.abs(),
      );
    }
    return totals;
  }

  List<PieChartSectionData> _buildSections(Map<String, int> totals) {
    final total = totals.values.fold<int>(0, (sum, value) => sum + value);
    return totals.entries.map((entry) {
      final percent = total == 0 ? 0.0 : entry.value / total;
      return PieChartSectionData(
        color: _categoryColor(entry.key),
        radius: 22,
        value: math.max(percent * 100, 4).toDouble(),
        title: '${(percent * 100).round()}%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList(growable: false);
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'invest':
        return const Color(0xFF85EFAC);
      case 'unlock':
        return const Color(0xFFFFC36B);
      case 'challenge':
        return const Color(0xFF65D5FF);
      default:
        return const Color(0xFFFF8A80);
    }
  }

  String _titleCase(String input) {
    final normalized = input.replaceAll('_', ' ');
    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _WalletTransactionCard extends StatelessWidget {
  const _WalletTransactionCard({
    required this.transaction,
  });

  final LedgerTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final credit = transaction.amount >= 0;
    final accent = credit ? const Color(0xFF85EFAC) : const Color(0xFFFFB2AB);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              credit ? Icons.call_received_rounded : Icons.call_made_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SmallPill(label: transaction.relativeLabel),
                    const SizedBox(width: 8),
                    _SmallPill(label: transaction.category.toUpperCase()),
                  ],
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
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.74),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
