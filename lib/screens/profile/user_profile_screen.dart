import 'package:flutter/material.dart';
import '../reusable_widgets/custom_bottom_nav.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF1A4D3D);
    const cardBg = Color(0xFF254E3F);
    const cardBorder = Color(0xFF3B6B59);
    const accent = Color(0xFF85EFAC);

    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: const CustomBottomNav(activeIndex: 5,),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            background: cardBg,
                            border: cardBorder,
                            accent: accent,
                            title: 'Literacy Points',
                            value: '850',
                            subtitle: 'Knowledge Score',
                            icon: Icons.psychology,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            background: cardBg,
                            border: cardBorder,
                            accent: accent,
                            title: 'Savings Rate',
                            value: '72%',
                            subtitle: 'of goal',
                            icon: Icons.savings,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            background: cardBg,
                            border: cardBorder,
                            accent: accent,
                            title: 'Rank',
                            value: '#3',
                            subtitle: 'Leaderboard',
                            icon: Icons.emoji_events,
                          ),
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
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final Color background;
  final Color border;
  final Color accent;

  const _ProfileHeaderCard({
    required this.background,
    required this.border,
    required this.accent,
  });

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
            'Level 7 Finance Wizard',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Current Balance: \$2450',
            style: TextStyle(color: Colors.white70, fontSize: 12),
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

class _StatCard extends StatelessWidget {
  final Color background;
  final Color border;
  final Color accent;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.background,
    required this.border,
    required this.accent,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  final Color background;
  final Color border;
  final Color accent;

  const _LevelProgressCard({
    required this.background,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const progress = 0.68;

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
          const Text(
            'Level 7 → Level 8',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You need 320 more points to reach the next title.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
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
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '68%',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Color background;
  final Color border;
  final Color accent;

  const _ProgressCard({
    required this.background,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: const Column(
        children: [
          _ProgressRow(
            label: 'Current Weekly Goals',
            value: 0.65,
            percentText: '65%',
          ),
          SizedBox(height: 12),
          _ProgressRow(
            label: 'Overall Completion',
            value: 0.42,
            percentText: '42%',
          ),
          SizedBox(height: 12),
          _ProgressRow(
            label: 'Challenge Participation',
            value: 0.74,
            percentText: '74%',
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final String percentText;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.percentText,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF85EFAC);

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
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              percentText,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgesCard extends StatelessWidget {
  final Color background;
  final Color border;
  final Color accent;

  const _BadgesCard({
    required this.background,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BadgeItem(icon: Icons.savings, label: 'Smart Saver', accent: accent),
          _BadgeItem(
            icon: Icons.menu_book,
            label: 'Fast Learner',
            accent: accent,
          ),
          _BadgeItem(
            icon: Icons.emoji_events,
            label: 'Top 3 Rank',
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.accent,
  });

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
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Color background;
  final Color border;

  const _AccountCard({required this.background, required this.border});

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
  final IconData icon;
  final String label;
  final bool isLast;

  const _AccountTile({
    required this.icon,
    required this.label,
    this.isLast = false,
  });

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
