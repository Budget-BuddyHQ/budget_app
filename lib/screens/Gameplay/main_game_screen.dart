import 'package:flutter/material.dart';


import '../../models/user_progress_state.dart';

import '../reusable_widgets/custom_bottom_nav.dart';
import '../reusable_widgets/progress_metrics_widgets.dart';
import 'react_game_screen.dart';

class MainGameScreen extends StatelessWidget {
  const MainGameScreen({super.key});

  Future<void> _openReactGame(
    BuildContext context, {
    required String gameId,
    required String difficulty,
  }) async {
    final userProgress = UserProgressState.instance;

    final result = await Navigator.push<ReactGameCloseResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ReactGameScreen(
          gameId: gameId,
          difficulty: difficulty,
          playerLevel: userProgress.level,
          userId: userProgress.userId,
        ),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    final syncText = result.syncResult.queued
        ? 'Cloud save queued (${result.syncResult.queuedCount}) while offline.'
        : 'Progress synced to Base44.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.status.toUpperCase()}: +${result.goldEarned} gold, '
          '+${result.xpEarned} XP. $syncText',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF1A4D3D);
    const cardBg = Color(0xFF254E3F);
    const cardBorder = Color(0xFF3B6B59);
    const accent = Color(0xFF85EFAC);

    return AnimatedBuilder(
      animation: UserProgressState.instance,
      builder: (context, _) {
        final user = UserProgressState.instance;
        final savingsRate = ((user.gold / 3400) * 100).clamp(1, 100).toDouble();
        final roi = ((user.xp / 80) - 1.0).clamp(-20, 35).toDouble();

        return Scaffold(
          backgroundColor: background,
          bottomNavigationBar: const CustomBottomNav(activeIndex: 0),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TopBar(
                    currentBalance: user.gold,
                    levelTitle: user.levelTitle,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DailyInsightCard(background: cardBg, border: cardBorder),
                        const SizedBox(height: 16),
                        const Text(
                          "Week's Progress Metrics",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ResponsiveMetricGrid(
                          children: [
                            FinanceMetricCard(
                              background: cardBg,
                              border: cardBorder,
                              title: 'Savings Rate',
                              value: '${savingsRate.toStringAsFixed(0)}%',
                              subtitle: 'of goal',
                              icon: Icons.savings,
                              accent: accent,
                              progressValue: savingsRate / 100,
                            ),
                            FinanceMetricCard(
                              background: cardBg,
                              border: cardBorder,
                              title: 'Literacy Points',
                              value: _withCommas(user.literacyPoints),
                              subtitle: 'Knowledge Score',
                              icon: Icons.psychology,
                              accent: accent,
                            ),
                            FinanceMetricCard(
                              background: cardBg,
                              border: cardBorder,
                              title: 'Investment ROI',
                              value: '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(1)}%',
                              subtitle: 'This Month',
                              icon: Icons.trending_up,
                              accent: accent,
                              sparklinePoints: const [0.24, 0.34, 0.31, 0.53, 0.47, 0.72],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Daily Challenge',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _BudgetBattleCard(
                          background: cardBg,
                          border: cardBorder,
                          accent: accent,
                          onStartChallenge: () => _openReactGame(
                            context,
                            gameId: 'daily_budget_battle',
                            difficulty: 'normal',
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Progress Bar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const ProgressBarInfoRow(
                          label: 'Current Weekly Goals',
                          value: 0.65,
                          percentText: '65%',
                          accent: accent,
                        ),
                        const SizedBox(height: 10),
                        const ProgressBarInfoRow(
                          label: 'Overall Completion',
                          value: 0.42,
                          percentText: '42%',
                          accent: accent,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Leaderboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _LeaderboardTable(
                          background: cardBg,
                          border: cardBorder,
                          accent: accent,
                        ),
                      ],
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

  static String _withCommas(int value) {
    final raw = value.toString();
    final regExp = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return raw.replaceAllMapped(regExp, (match) => ',');
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentBalance,
    required this.levelTitle,
  });

  final int currentBalance;
  final String levelTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4E3B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF85EFAC),
                      child: Icon(Icons.person, size: 18, color: Color(0xFF1A4D3D)),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Current Balance',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.notifications_none, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${MainGameScreen._withCommas(currentBalance)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  levelTitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            );
          }

          return Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF85EFAC),
                child: Icon(Icons.person, size: 18, color: Color(0xFF1A4D3D)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Current Balance: \$${MainGameScreen._withCommas(currentBalance)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  levelTitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.notifications_none, color: Colors.white70),
            ],
          );
        },
      ),
    );
  }
}

class _DailyInsightCard extends StatelessWidget {
  const _DailyInsightCard({required this.background, required this.border});

  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF85EFAC),
                child: Icon(
                  Icons.lightbulb,
                  size: 18,
                  color: Color(0xFF1A4D3D),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Daily Budget Insight',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?auto=format&fit=crop&w=900&q=80',
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'A penny saved is a penny earned. Invest \$10 today for a 5% gain.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BudgetBattleCard extends StatelessWidget {
  const _BudgetBattleCard({
    required this.background,
    required this.border,
    required this.accent,
    required this.onStartChallenge,
  });

  final Color background;
  final Color border;
  final Color accent;
  final VoidCallback onStartChallenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emoji_events, color: Color(0xFF85EFAC), size: 18),
              SizedBox(width: 8),
              Text(
                'THE BUDGET BATTLE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Analyze this \$50 grocery receipt and find 3 savings.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onStartChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF1A4D3D),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Start Challenge'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Skip'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTable extends StatelessWidget {
  const _LeaderboardTable({
    required this.background,
    required this.border,
    required this.accent,
  });

  final Color background;
  final Color border;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const rows = [
      _LeaderRow(rank: '1', name: 'MoneyMaster99', points: '2,450'),
      _LeaderRow(rank: '2', name: 'BudgetPro', points: '2,280'),
      _LeaderRow(rank: '3', name: 'Username3189 (You)', points: '2,150', highlight: true),
      _LeaderRow(rank: '4', name: 'SaverSally', points: '2,020'),
      _LeaderRow(rank: '5', name: 'InvestorMax', points: '1,890'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '#',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Text(
                    'User',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Points',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          for (final row in rows) row,
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.points,
    this.highlight = false,
  });

  final String rank;
  final String name;
  final String points;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF2B5A4A) : Colors.transparent,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(rank, style: const TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: highlight ? const Color(0xFF85EFAC) : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              points,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
