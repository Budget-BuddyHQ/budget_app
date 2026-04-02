import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../navigation/fade_page_route.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/skeleton_loader.dart';
import 'bill_dodger.dart';
import 'dashboard_shell.dart';
import 'react_challenge_screen.dart';

class MainGamePage extends StatelessWidget {
  const MainGamePage({
    super.key,
    this.activeTabIndex = 0,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _openReactBattle(BuildContext context) async {
    final controller = context.read<UserStatsController>();
    final stats = controller.stats;

    final result = await Navigator.of(context).push<ReactGameCloseResult>(
      FadePageRoute(
        builder: (_) => ReactChallengeScreen(
          gameId: 'daily_budget_battle',
          difficulty: 'medium',
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
      title: result.status == 'victory' ? 'Daily battle won' : 'Battle complete',
      message:
          '+${result.goldEarned} gold • +${result.xpEarned} XP • ${result.syncState.message}',
      icon: Icons.workspace_premium_rounded,
    );
  }

  Future<void> _openBillDodger(BuildContext context) async {
    final result = await Navigator.of(context).push<BillDodgerCloseResult>(
      FadePageRoute(
        builder: (_) => const BillDodgerScreen(),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final isLoading = controller.isLoading;

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
                const _MainBackdrop(),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MainHeader(
                        username: stats.username,
                        gold: stats.gold,
                        levelTitle: stats.levelTitle,
                      ),
                      const SizedBox(height: 18),
                        _HeroBattleCard(
                        onPlayNow: () => _openReactBattle(context),
                        onOpenDashboard: () {
                          Navigator.of(context).push(
                            FadePageRoute(
                              builder: (_) => const DashboardShell(initialIndex: 0),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickStatCard(
                              label: 'Literacy Points',
                              value: '${stats.literacyPoints}',
                              icon: Icons.psychology_alt_rounded,
                              accent: const Color(0xFF85EFAC),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickStatCard(
                              label: 'Weekly Streak',
                              value: '${(stats.xp / 45).floor().clamp(2, 9)} days',
                              icon: Icons.local_fire_department_rounded,
                              accent: const Color(0xFFFFC36B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Choose your next mission',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MissionCard(
                        title: 'Budget Battle',
                        subtitle:
                            'Play the React mini-game and earn instant gold, XP, and smarter spending instincts.',
                        badge: 'Primary Quest',
                        accent: const Color(0xFF85EFAC),
                        icon: Icons.bolt_rounded,
                        buttonLabel: 'Play Now',
                        onPressed: () => _openReactBattle(context),
                      ),
                      const SizedBox(height: 12),
                      _MissionCard(
                        title: 'Bill Dodger',
                        subtitle:
                            'Glide across the lane, grab needs, dodge wants, and train rapid-fire money choices.',
                        badge: 'Arcade Mode',
                        accent: const Color(0xFFFFC36B),
                        icon: Icons.gamepad_rounded,
                        buttonLabel: 'Start Arcade',
                        secondary: true,
                        onPressed: () => _openBillDodger(context),
                      ),
                      const SizedBox(height: 20),
                      _AdviceCard(advice: stats.wizardAdvice),
                    ],
                  ),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withOpacity(0.08),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                          child: Column(
                            children: const [
                              SkeletonLoader(height: 80, borderRadius: 24),
                              SizedBox(height: 18),
                              SkeletonLoader(height: 240, borderRadius: 32),
                              SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: SkeletonLoader(
                                      height: 110,
                                      borderRadius: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: SkeletonLoader(
                                      height: 110,
                                      borderRadius: 20,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              SkeletonLoader(height: 160, borderRadius: 20),
                              SizedBox(height: 12),
                              SkeletonLoader(height: 160, borderRadius: 20),
                            ],
                          ),
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

class _MainBackdrop extends StatelessWidget {
  const _MainBackdrop();

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
                Color(0xFF071711),
                Color(0xFF0C2B21),
                Color(0xFF11372C),
              ],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF85EFAC).withOpacity(0.10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF85EFAC).withOpacity(0.14),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MainHeader extends StatelessWidget {
  const _MainHeader({
    required this.username,
    required this.gold,
    required this.levelTitle,
  });

  final String username;
  final int gold;
  final String levelTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF85EFAC), Color(0xFF48D58A)],
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Color(0xFF103225),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $username',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$levelTitle • \$${gold.toString()} balance',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.74),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBattleCard extends StatelessWidget {
  const _HeroBattleCard({
    required this.onPlayNow,
    required this.onOpenDashboard,
  });

  final VoidCallback onPlayNow;
  final VoidCallback onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF14372B).withOpacity(0.96),
            const Color(0xFF1D4738).withOpacity(0.92),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF85EFAC).withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'DAILY FEATURE',
                        style: TextStyle(
                          color: Color(0xFF85EFAC),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Play Now and train your finance reflexes.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A cleaner home base, faster rewards, and smooth game launches designed for mobile players.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.76),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF85EFAC).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF85EFAC),
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Play Now',
                  onPressed: onPlayNow,
                  prefixIcon: const Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: Color(0xFF1A4D3D),
                  ),
                  style: const CustomButtonStyle.primary(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Open Dashboard',
                  onPressed: onOpenDashboard,
                  prefixIcon: const Icon(
                    Icons.dashboard_rounded,
                    size: 18,
                    color: Color(0xFF76FF03),
                  ),
                  style: const CustomButtonStyle.secondary(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.66),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.accent,
    required this.icon,
    required this.buttonLabel,
    required this.onPressed,
    this.secondary = false,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color accent;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Icon(icon, color: accent),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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
            onPressed: onPressed,
            style: secondary
                ? const CustomButtonStyle.secondary()
                : const CustomButtonStyle.primary(),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: secondary ? const Color(0xFF76FF03) : const Color(0xFF1A4D3D),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({
    required this.advice,
  });

  final String advice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E4A3A).withOpacity(0.94),
            const Color(0xFF14372B).withOpacity(0.88),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF85EFAC).withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF85EFAC),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wizard Advice',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  advice,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
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
