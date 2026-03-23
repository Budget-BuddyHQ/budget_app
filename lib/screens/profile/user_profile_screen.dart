import 'package:budget_app/models/user_progress_state.dart';
import 'package:flutter/material.dart';
import '../Gameplay/game_hub_screen.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import '../reusable_widgets/progress_metrics_widgets.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

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

        return Scaffold(
          backgroundColor: background,
          bottomNavigationBar: const CustomBottomNav(activeIndex: 5),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _ProfileTopBar(),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileHeaderCard(
                          background: cardBg,
                          border: cardBorder,
                          accent: accent,
                          levelTitle: user.levelTitle,
                          currentBalance: user.gold,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your Stats',
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
                              accent: accent,
                              title: 'Literacy Points',
                              value: _withCommas(user.literacyPoints),
                              subtitle: 'Knowledge Score',
                              icon: Icons.psychology,
                            ),
                            FinanceMetricCard(
                              background: cardBg,
                              border: cardBorder,
                              accent: accent,
                              title: 'Savings Rate',
                              value: '${savingsRate.toStringAsFixed(0)}%',
                              subtitle: 'of goal',
                              icon: Icons.savings,
                              progressValue: savingsRate / 100,
                            ),
                            FinanceMetricCard(
                              background: cardBg,
                              border: cardBorder,
                              accent: accent,
                              title: 'Rank',
                              value: '#3',
                              subtitle: 'Leaderboard',
                              icon: Icons.emoji_events,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Level Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _LevelProgressCard(
                          background: cardBg,
                          border: cardBorder,
                          accent: accent,
                          level: user.level,
                          pointsToNextLevel: _pointsToNextLevel(user.xp),
                          levelProgress: _levelProgress(user.xp),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Current Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ProgressCard(
                          background: cardBg,
                          border: cardBorder,
                          accent: accent,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Badges Earned',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _BadgesCard(
                          background: cardBg,
                          border: cardBorder,
                          accent: accent,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _AccountCard(background: cardBg, border: cardBorder),
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

  static int _pointsToNextLevel(int xp) {
    final nextThreshold = ((xp ~/ 150) + 1) * 150;
    return nextThreshold - xp;
  }

  static double _levelProgress(int xp) {
    return (xp % 150) / 150;
  }

  static String _withCommas(int value) {
    final raw = value.toString();
    final regExp = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return raw.replaceAllMapped(regExp, (match) => ',');
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4E3B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.person, color: Colors.white70, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.settings, color: Colors.white70, size: 18),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.background,
    required this.border,
    required this.accent,
    required this.levelTitle,
    required this.currentBalance,
  });

  final Color background;
  final Color border;
  final Color accent;
  final String levelTitle;
  final int currentBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFF85EFAC),
            child: Icon(Icons.person, size: 36, color: Color(0xFF1A4D3D)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Username3189',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            levelTitle,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Current Balance: \$${UserProfileScreen._withCommas(currentBalance)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: const Color(0xFF1A4D3D),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({
    required this.background,
    required this.border,
    required this.accent,
    required this.level,
    required this.pointsToNextLevel,
    required this.levelProgress,
  });

  final Color background;
  final Color border;
  final Color accent;
  final int level;
  final int pointsToNextLevel;
  final double levelProgress;

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
          Text(
            'Level $level -> Level ${level + 1}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You need $pointsToNextLevel more points to reach the next title.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: levelProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(levelProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.background,
    required this.border,
    required this.accent,
  });

  final Color background;
  final Color border;
  final Color accent;

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
        children: [
          ProgressBarInfoRow(
            label: 'Current Weekly Goals',
            value: 0.65,
            percentText: '65%',
            accent: accent,
          ),
          const SizedBox(height: 12),
          ProgressBarInfoRow(
            label: 'Overall Completion',
            value: 0.42,
            percentText: '42%',
            accent: accent,
          ),
          const SizedBox(height: 12),
          ProgressBarInfoRow(
            label: 'Challenge Participation',
            value: 0.74,
            percentText: '74%',
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _BadgesCard extends StatelessWidget {
  const _BadgesCard({
    required this.background,
    required this.border,
    required this.accent,
  });

  final Color background;
  final Color border;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 24) / 3;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: itemWidth > 120 ? itemWidth : constraints.maxWidth,
                child: _BadgeItem(
                  icon: Icons.savings,
                  label: 'Smart Saver',
                  accent: accent,
                ),
              ),
              SizedBox(
                width: itemWidth > 120 ? itemWidth : constraints.maxWidth,
                child: _BadgeItem(
                  icon: Icons.menu_book,
                  label: 'Fast Learner',
                  accent: accent,
                ),
              ),
              SizedBox(
                width: itemWidth > 120 ? itemWidth : constraints.maxWidth,
                child: _BadgeItem(
                  icon: Icons.emoji_events,
                  label: 'Top 3 Rank',
                  accent: accent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: accent.withValues(alpha: 0.18),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.background, required this.border});

  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: const Column(
        children: [
          _AccountTile(
            icon: Icons.notifications_none,
            label: 'Notification Settings',
          ),
          _AccountTile(icon: Icons.lock_outline, label: 'Privacy Settings'),
          _AccountTile(icon: Icons.logout, label: 'Log Out', isLast: true),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.label,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
        ],
      ),
    );
  }
}
