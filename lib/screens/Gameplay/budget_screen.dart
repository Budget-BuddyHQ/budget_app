import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../services/supabase_service.dart';
import '../reusable_widgets/custom_bottom_nav.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({
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
        final weeklyGoalProgress = (stats.gold / 3800).clamp(0.1, 1.0);
        final completionProgress =
            ((stats.literacyPoints + stats.xp) / 2400).clamp(0.05, 1.0);

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
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    children: [
                      const Text(
                        'Budget Ledger',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Every coin earned or spent is stored in your budget history.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _BudgetSummaryCard(
                        currentBalance: stats.gold,
                        weeklyGoalProgress: weeklyGoalProgress.toDouble(),
                        completionProgress: completionProgress.toDouble(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (transactions.isEmpty)
                        const _EmptyLedgerState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            return _TransactionRow(transaction: transaction);
                          },
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.currentBalance,
    required this.weeklyGoalProgress,
    required this.completionProgress,
  });

  final int currentBalance;
  final double weeklyGoalProgress;
  final double completionProgress;

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
          const Text(
            'Weekly Money Snapshot',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current Balance: \$$currentBalance',
            style: const TextStyle(
              color: Color(0xFF85EFAC),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'Current Weekly Goals',
            progress: weeklyGoalProgress,
            trailing: '${(weeklyGoalProgress * 100).round()}%',
          ),
          const SizedBox(height: 10),
          _ProgressRow(
            label: 'Overall Completion',
            progress: completionProgress,
            trailing: '${(completionProgress * 100).round()}%',
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.progress,
    required this.trailing,
  });

  final String label;
  final double progress;
  final String trailing;

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
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress.clamp(0.0, 1.0).toDouble(),
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF85EFAC)),
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final LedgerTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final accent = transaction.isCredit ? const Color(0xFF85EFAC) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF254E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B6B59)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: transaction.isCredit
                ? const Color(0xFF85EFAC).withOpacity(0.18)
                : Colors.white.withOpacity(0.08),
            child: Icon(
              transaction.isCredit ? Icons.add : Icons.remove,
              color: accent,
            ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.relativeLabel,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.amountLabel,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLedgerState extends StatelessWidget {
  const _EmptyLedgerState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF254E3F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3B6B59)),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long, color: Color(0xFF85EFAC), size: 36),
          SizedBox(height: 10),
          Text(
            'Your ledger will appear here once your first transaction lands.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}
