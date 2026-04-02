import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../services/supabase_service.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/skeleton_loader.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import '../reusable_widgets/progress_metrics_widgets.dart';
import 'bill_dodger.dart';
import 'leaderboard_screen.dart';
import 'react_game_screen.dart';
import 'town_square.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.activeTabIndex = 0,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _openBudgetBattle(BuildContext context) async {
    final stats = context.read<UserStatsController>().stats;
    final result = await Navigator.of(context).push<ReactGameCloseResult>(
      MaterialPageRoute(
        builder: (_) => ReactGameScreen(
          gameId: 'daily_budget_battle',
          difficulty: 'normal',
          playerLevel: stats.level,
          userId: stats.id,
        ),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    GameToast.show(
      context,
      title: result.status == 'victory' ? 'Budget Battle Won' : 'Battle Complete',
      message:
          '+${result.goldEarned} gold | +${result.xpEarned} XP | ${result.syncState.message}',
      icon: Icons.workspace_premium_rounded,
    );
  }

  Future<void> _openBillDodger(BuildContext context) async {
    final result = await Navigator.of(context).push<BillDodgerCloseResult>(
      MaterialPageRoute(builder: (_) => const BillDodgerScreen()),
    );

    if (!context.mounted || result == null) {
      return;
    }

    GameToast.show(
      context,
      title: 'Arcade Rewards Banked',
      message:
          '+${result.goldEarned} gold | +${result.xpEarned} XP | ${result.syncState.message}',
      icon: Icons.savings_rounded,
      accent: const Color(0xFFFFD45C),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final leaderboard = _buildLeaderboard(stats);
        final playerEntry = leaderboard.firstWhere(
          (entry) => entry.isCurrentUser,
          orElse: () => leaderboard.first,
        );
        final savingsRate = ((stats.gold / 5200) * 100).clamp(1, 100).toDouble();
        final battleScore = _scoreForLeaderboard(stats);
        final completion = ((stats.literacyPoints + stats.xp) / 2500)
            .clamp(0.0, 1.0)
            .toDouble();

        return Scaffold(
          backgroundColor: const Color(0xFF071812),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected,
                ),
          body: Stack(
            children: [
              const _HomeBackdrop(),
              SafeArea(
                child: controller.isLoading
                    ? const _HomeSkeleton()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
                        children: [
                          _RankHeroCard(
                            username: stats.username,
                            score: battleScore,
                            rank: playerEntry.rank,
                            totalPlayers: leaderboard.length + 124,
                            levelTitle: stats.levelTitle,
                          ),
                          const SizedBox(height: 18),
                          _LeaderboardPreviewCard(
                            entries: leaderboard.take(5).toList(growable: false),
                            onOpenFullBoard: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LeaderboardScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ResponsiveMetricGrid(
                            children: [
                              FinanceMetricCard(
                                background: Colors.white.withValues(alpha: 0.06),
                                border: Colors.white.withValues(alpha: 0.08),
                                title: 'Savings Rate',
                                value: '${savingsRate.toStringAsFixed(0)}%',
                                subtitle: 'global discipline meter',
                                icon: Icons.savings_rounded,
                                accent: const Color(0xFF85EFAC),
                                progressValue: savingsRate / 100,
                              ),
                              FinanceMetricCard(
                                background: Colors.white.withValues(alpha: 0.06),
                                border: Colors.white.withValues(alpha: 0.08),
                                title: 'Literacy Rank',
                                value: '#${math.max(1, 210 - stats.level * 8)}',
                                subtitle: '${stats.literacyPoints} mastery points',
                                icon: Icons.auto_awesome_rounded,
                                accent: const Color(0xFFFFD45C),
                              ),
                              FinanceMetricCard(
                                background: Colors.white.withValues(alpha: 0.06),
                                border: Colors.white.withValues(alpha: 0.08),
                                title: 'Progression',
                                value: '${(completion * 100).round()}%',
                                subtitle: 'campaign completion',
                                icon: Icons.flag_rounded,
                                accent: const Color(0xFF58C7FF),
                                progressValue: completion,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _QuickPortalStrip(
                            onTownSquare: () {
                              if (onNavSelected != null) {
                                onNavSelected!(2);
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const TownSquare()),
                              );
                            },
                            onBudgetBattle: () => _openBudgetBattle(context),
                            onBillDodger: () => _openBillDodger(context),
                          ),
                          const SizedBox(height: 18),
                          _MentorPanel(
                            title: 'Global Mentor Brief',
                            message: stats.wizardAdvice,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_RankEntry> _buildLeaderboard(UserStats stats) {
    final playerScore = _scoreForLeaderboard(stats);
    final base = <_RankEntry>[
      const _RankEntry(name: 'Goldwarden Ivy', score: 7350),
      const _RankEntry(name: 'Ledger Lion', score: 6980),
      const _RankEntry(name: 'Mint Mage', score: 6725),
      const _RankEntry(name: 'SaverSage', score: 6550),
      _RankEntry(name: stats.username, score: playerScore, isCurrentUser: true),
      const _RankEntry(name: 'Budget Bard', score: 5450),
      const _RankEntry(name: 'Coin Captain', score: 5180),
      const _RankEntry(name: 'Wallet Witch', score: 4970),
    ];

    final ranked = [...base]..sort((a, b) => b.score.compareTo(a.score));
    return ranked
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(rank: entry.key + 1),
        )
        .toList(growable: false);
  }

  int _scoreForLeaderboard(UserStats stats) {
    return stats.gold + (stats.xp * 2) + (stats.literacyPoints * 2);
  }
}

class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF06150F),
                Color(0xFF0C241B),
                Color(0xFF113528),
              ],
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -40,
          child: _GlowOrb(
            size: 220,
            color: const Color(0xFF4ADE80).withValues(alpha: 0.14),
          ),
        ),
        Positioned(
          top: 180,
          left: -70,
          child: _GlowOrb(
            size: 180,
            color: const Color(0xFFFFD45C).withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.42,
              spreadRadius: size * 0.06,
            ),
          ],
        ),
      ),
    );
  }
}

class _RankHeroCard extends StatelessWidget {
  const _RankHeroCard({
    required this.username,
    required this.score,
    required this.rank,
    required this.totalPlayers,
    required this.levelTitle,
  });

  final String username;
  final int score;
  final int rank;
  final int totalPlayers;
  final String levelTitle;

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
            const Color(0xFF0D281E).withValues(alpha: 0.98),
            const Color(0xFF143B2E).withValues(alpha: 0.94),
            const Color(0xFF1A4938).withValues(alpha: 0.90),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Rank & Progression',
                      style: TextStyle(
                        color: const Color(0xFFB7F7D0).withValues(alpha: 0.96),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      levelTitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE55C), Color(0xFF59D78D)],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.60), width: 3),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFF062C21),
                  size: 42,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroChip(
                  label: 'Global rank',
                  value: '#$rank',
                  accent: const Color(0xFFFFD45C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroChip(
                  label: 'League score',
                  value: '$score',
                  accent: const Color(0xFF85EFAC),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroChip(
                  label: 'Active wizards',
                  value: '$totalPlayers',
                  accent: const Color(0xFF58C7FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardPreviewCard extends StatelessWidget {
  const _LeaderboardPreviewCard({
    required this.entries,
    required this.onOpenFullBoard,
  });

  final List<_RankEntry> entries;
  final VoidCallback onOpenFullBoard;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Global Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOpenFullBoard,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'The front page starts with competition, momentum, and visible rank.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LeaderboardRow(entry: entry),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
  });

  final _RankEntry entry;

  @override
  Widget build(BuildContext context) {
    final accent = entry.isCurrentUser
        ? const Color(0xFFFFD45C)
        : const Color(0xFF85EFAC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? const Color(0x26FFD45C)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: entry.isCurrentUser
              ? const Color(0x66FFD45C)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Text(
            '#${entry.rank}',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withValues(alpha: 0.16),
            child: Text(
              entry.name.isEmpty ? '?' : entry.name[0].toUpperCase(),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.name,
              style: TextStyle(
                color: entry.isCurrentUser ? const Color(0xFFFFE9A1) : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            entry.score.toString(),
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

class _QuickPortalStrip extends StatelessWidget {
  const _QuickPortalStrip({
    required this.onTownSquare,
    required this.onBudgetBattle,
    required this.onBillDodger,
  });

  final VoidCallback onTownSquare;
  final VoidCallback onBudgetBattle;
  final VoidCallback onBillDodger;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fast Travel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = constraints.maxWidth < 640
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _PortalCard(
                    title: 'Town Square',
                    subtitle: 'Enter the main world and choose your next portal.',
                    icon: Icons.auto_awesome_rounded,
                    accent: const Color(0xFF4ADE80),
                    onTap: onTownSquare,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _PortalCard(
                    title: 'Budget Battle',
                    subtitle: 'Jump into the featured web challenge for fast rewards.',
                    icon: Icons.shield_rounded,
                    accent: const Color(0xFFFFD45C),
                    onTap: onBudgetBattle,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _PortalCard(
                    title: 'Bill Dodger',
                    subtitle: 'Smooth arcade practice for needs versus wants.',
                    icon: Icons.sports_esports_rounded,
                    accent: const Color(0xFF58C7FF),
                    onTap: onBillDodger,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.26)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MentorPanel extends StatelessWidget {
  const _MentorPanel({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF113528).withValues(alpha: 0.96),
            const Color(0xFF0C271D).withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD45C).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFFFFD45C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.45,
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

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
      children: const [
        SkeletonLoader(height: 220, borderRadius: 30),
        SizedBox(height: 18),
        SkeletonLoader(height: 260, borderRadius: 26),
        SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: SkeletonLoader(height: 132, borderRadius: 20)),
            SizedBox(width: 12),
            Expanded(child: SkeletonLoader(height: 132, borderRadius: 20)),
          ],
        ),
        SizedBox(height: 12),
        SkeletonLoader(height: 132, borderRadius: 20),
        SizedBox(height: 18),
        SkeletonLoader(height: 230, borderRadius: 24),
        SizedBox(height: 18),
        SkeletonLoader(height: 120, borderRadius: 24),
      ],
    );
  }
}

class _RankEntry {
  const _RankEntry({
    required this.name,
    required this.score,
    this.rank = 0,
    this.isCurrentUser = false,
  });

  final String name;
  final int score;
  final int rank;
  final bool isCurrentUser;

  _RankEntry copyWith({
    String? name,
    int? score,
    int? rank,
    bool? isCurrentUser,
  }) {
    return _RankEntry(
      name: name ?? this.name,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
