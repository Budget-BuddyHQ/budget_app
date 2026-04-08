import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/game_toast.dart';
import 'bill_dodger.dart';
import 'budget_challenge.dart';
import 'leaderboard_screen.dart';
import 'react_challenge_screen.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({
    super.key,
    this.activeTabIndex = 1,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _launchBudgetBattle(BuildContext context) async {
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
      title: result.status == 'victory'
          ? 'Budget Battle Won'
          : 'Budget Battle Complete',
      message:
          '+${result.goldEarned} gold | +${result.xpEarned} XP | ${result.syncState.message}',
      icon: Icons.workspace_premium_rounded,
      accent: const Color(0xFFFFD45C),
    );
  }

  Future<void> _launchBillDodger(BuildContext context) async {
    final result = await Navigator.of(context).push<BillDodgerCloseResult>(
      MaterialPageRoute(builder: (_) => const BillDodgerScreen()),
    );

    if (!context.mounted || result == null) {
      return;
    }

    GameToast.show(
      context,
      title: 'Bill Dodger Cleared',
      message:
          '+${result.goldEarned} gold | +${result.xpEarned} XP | ${result.syncState.message}',
      icon: Icons.savings_rounded,
      accent: const Color(0xFF85EFAC),
    );
  }

  Future<void> _launchBudgetChallenge(BuildContext context) async {
    final result = await Navigator.of(context).push<BudgetChallengeCloseResult>(
      MaterialPageRoute(builder: (_) => const BudgetChallengeScreen()),
    );

    if (!context.mounted || result == null) {
      return;
    }

    GameToast.show(
      context,
      title: 'Budget Challenge Complete',
      message:
          '+${result.goldEarned} gold | +${result.xpEarned} XP | ${result.syncState.message}',
      icon: Icons.shopping_cart_rounded,
      accent: const Color(0xFF58C7FF),
    );
  }

  void _comingSoon(BuildContext context, String label) {
    HapticFeedback.lightImpact();
    GameToast.show(
      context,
      title: '$label coming soon',
      message: 'This game slot is reserved in the MVP and will arrive next.',
      icon: Icons.auto_awesome_rounded,
      accent: const Color(0xFFFFD45C),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = <_HubGameTile>[
      _HubGameTile(
        title: 'Budget Battle',
        subtitle: 'Featured finance duel',
        icon: Icons.workspace_premium_rounded,
        accent: const Color(0xFFFFD45C),
        onTap: () => _launchBudgetBattle(context),
      ),
      _HubGameTile(
        title: 'Bill Dodger',
        subtitle: 'Arcade survival',
        icon: Icons.sports_esports_rounded,
        accent: const Color(0xFF85EFAC),
        onTap: () => _launchBillDodger(context),
      ),
      _HubGameTile(
        title: 'Budget Sprint',
        subtitle: 'Fast price choices',
        icon: Icons.bolt_rounded,
        accent: const Color(0xFF58C7FF),
        onTap: () => _launchBudgetChallenge(context),
      ),
      _HubGameTile(
        title: 'Prodigy Demo',
        subtitle: 'Preview arena',
        icon: Icons.auto_awesome_motion_rounded,
        accent: const Color(0xFFA78BFA),
        onTap: () => _comingSoon(context, 'Prodigy Demo'),
      ),
      _HubGameTile(
        title: 'Grocery Rush',
        subtitle: 'Coming soon',
        icon: Icons.local_grocery_store_rounded,
        accent: const Color(0xFFFFB084),
        onTap: () => _comingSoon(context, 'Grocery Rush'),
      ),
      _HubGameTile(
        title: 'Lessons',
        subtitle: 'Open academy path',
        icon: Icons.school_rounded,
        accent: const Color(0xFF85EFAC),
        onTap: () => onNavSelected?.call(3),
      ),
      _HubGameTile(
        title: 'Customize',
        subtitle: 'Equip new turtle skins',
        icon: Icons.style_rounded,
        accent: const Color(0xFFFFD45C),
        onTap: () => onNavSelected?.call(2),
      ),
      _HubGameTile(
        title: 'Leaderboard',
        subtitle: 'Check world rank',
        icon: Icons.emoji_events_rounded,
        accent: const Color(0xFF58C7FF),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
          );
        },
      ),
      _HubGameTile(
        title: 'More Soon',
        subtitle: 'June MVP slot',
        icon: Icons.add_circle_outline_rounded,
        accent: const Color(0xFF85EFAC),
        onTap: () => _comingSoon(context, 'Next minigame'),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF071711),
      bottomNavigationBar: onNavSelected == null
          ? null
          : CustomBottomNav(
              activeIndex: activeTabIndex,
              onSelected: onNavSelected,
            ),
      body: Stack(
        children: [
          const _HubBackdrop(),
          SafeArea(
              child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 126),
              children: [
                const _HubHero(),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth < 620 ? 2 : 3;
                    final aspect = crossAxisCount == 2 ? 1.05 : 0.88;
                    return GridView.builder(
                      itemCount: cards.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: aspect,
                      ),
                      itemBuilder: (context, index) => cards[index],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HubHero extends StatelessWidget {
  const _HubHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game Hub',
                  style: TextStyle(
                    color: const Color(0xFF85EFAC).withValues(alpha: 0.96),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pick your next training arena',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A 3x3 minigame board keeps the MVP easy to scan and fast to play on mobile.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF85EFAC).withValues(alpha: 0.34),
                  const Color(0xFF0D2B20),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubGameTile extends StatelessWidget {
  const _HubGameTile({
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.66),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubBackdrop extends StatelessWidget {
  const _HubBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF071711), Color(0xFF0B231B), Color(0xFF113127)],
            ),
          ),
        ),
        Positioned(
          right: -70,
          top: -50,
          child: _Glow(color: const Color(0xFF85EFAC).withValues(alpha: 0.16)),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 18,
          ),
        ],
      ),
    );
  }
}
