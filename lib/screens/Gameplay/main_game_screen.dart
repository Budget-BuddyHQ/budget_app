import 'package:flutter/material.dart';

import '../../models/user_progress_state.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import 'bill_dodger_game.dart';
import 'game_hub_screen.dart';
import 'react_game_screen.dart';
import 'town_square_screen.dart';

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
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0E362B),
        content: Text(
          '${result.status.toUpperCase()}: +${result.goldEarned} gold, '
          '+${result.xpEarned} XP. $syncText',
        ),
      ),
    );
  }

  Future<void> _openBillDodger(BuildContext context) async {
    final result = await Navigator.push<BillDodgerCloseResult>(
      context,
      MaterialPageRoute(builder: (_) => const BillDodgerGameScreen()),
    );

    if (!context.mounted || result == null) {
      return;
    }

    final syncText = result.syncResult.queued
        ? 'Cloud save queued (${result.syncResult.queuedCount}) while offline.'
        : 'Progress synced to Base44.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0E362B),
        content: Text(
          'Bill Dodger: +${result.goldEarned} gold, '
          '+${result.xpEarned} XP. $syncText',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserProgressState.instance,
      builder: (context, _) {
        final user = UserProgressState.instance;
        final literacyPoints = user.literacyPoints;
        final savingsRate = ((user.gold / 5200) * 100).clamp(1, 100).toDouble();
        final roi = ((user.xp / 90) - 1.0).clamp(-20, 35).toDouble();

        return Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFF041A14),
          bottomNavigationBar: const CustomBottomNav(activeIndex: 0),
          body: Stack(
            children: [
              const _DashboardBackdrop(),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DashboardHeader(
                        currentBalance: user.gold,
                        levelTitle: user.levelTitle,
                      ),
                      const SizedBox(height: 14),
                      _WorldPortalStrip(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TownSquareScreen()),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _QuickLaunchSection(
                        onTownSquare: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TownSquareScreen()),
                        ),
                        onBillDodger: () => _openBillDodger(context),
                        onGameHub: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GameHubScreen()),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _ChallengeHeroCard(
                        onPressed: () => _openReactGame(
                          context,
                          gameId: 'daily_budget_battle',
                          difficulty: 'normal',
                        ),
                      ),
                      const SizedBox(height: 28),
                      _VaultFeatureCard(
                        vaultBalanceLabel: '+0.004 BTC',
                        onPressed: () => _openReactGame(
                          context,
                          gameId: 'crypto_vault',
                          difficulty: 'hard',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatPill(
                            label: 'Savings',
                            value: '${savingsRate.toStringAsFixed(0)}%',
                            accent: const Color(0xFF85EFAC),
                            icon: Icons.savings_outlined,
                          ),
                          _StatPill(
                            label: 'Literacy',
                            value: _withCommas(literacyPoints),
                            accent: const Color(0xFF7FE7C4),
                            icon: Icons.auto_awesome_outlined,
                          ),
                          _StatPill(
                            label: 'ROI',
                            value: '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(1)}%',
                            accent: const Color(0xFFA78BFA),
                            icon: Icons.trending_up_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _WealthGrowthCard(
                        weeklyGain: 350,
                        chartPoints: const [0.28, 0.37, 0.34, 0.52, 0.48, 0.67, 0.82],
                      ),
                      const SizedBox(height: 24),
                      _QuestCard(
                        savingsProgress: savingsRate / 100,
                        literacyProgress: (literacyPoints / 1400)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                      ),
                      const SizedBox(height: 24),
                      _MomentumCard(
                        streakDays: 6,
                        challengeLabel: 'Receipt Rescue',
                        tip:
                            'Small wins stack fast. One better spending choice today keeps your savings quest moving.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

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
                Color(0xFF062C21),
                Color(0xFF0A3428),
                Color(0xFF0D4032),
              ],
            ),
          ),
        ),
        const Positioned(
          top: -70,
          left: -110,
          child: _GlowOrb(
            size: 260,
            color: Color(0x5585EFAC),
          ),
        ),
        const Positioned(
          top: 260,
          right: -70,
          child: _GlowOrb(
            size: 220,
            color: Color(0x334ADE80),
          ),
        ),
        const Positioned(
          bottom: 120,
          left: 40,
          child: _GlowOrb(
            size: 180,
            color: Color(0x330D9488),
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
              spreadRadius: size * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.currentBalance,
    required this.levelTitle,
  });

  final int currentBalance;
  final String levelTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AvatarBadge(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arcane Balance',
                style: TextStyle(
                  color: const Color(0xFFA3B8B0).withValues(alpha: 0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                  children: [
                    const TextSpan(
                      text: '\$',
                      style: TextStyle(color: Color(0xFF85EFAC)),
                    ),
                    TextSpan(
                      text: MainGameScreen._withCommas(currentBalance),
                      style: const TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: '.00',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                levelTitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _NotificationOrb(),
      ],
    );
  }
}

class _QuickLaunchSection extends StatelessWidget {
  const _QuickLaunchSection({
    required this.onTownSquare,
    required this.onBillDodger,
    required this.onGameHub,
  });

  final VoidCallback onTownSquare;
  final VoidCallback onBillDodger;
  final VoidCallback onGameHub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _IconTile(
              icon: Icons.flash_on_rounded,
              accent: Color(0xFF7FE7C4),
              size: 36,
            ),
            const SizedBox(width: 10),
            const Text(
              'Quick Launch',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = 12.0;
            final isSingleColumn = constraints.maxWidth < 390;
            final tileWidth = isSingleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - spacing) / 2;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _QuickLaunchTile(
                    title: 'Town Square',
                    subtitle: 'Enter the world map',
                    accent: const Color(0xFF85EFAC),
                    icon: Icons.map_rounded,
                    onTap: onTownSquare,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _QuickLaunchTile(
                    title: 'Bill Dodger',
                    subtitle: 'Fast budget reflex game',
                    accent: const Color(0xFFFFC36B),
                    icon: Icons.receipt_long_rounded,
                    onTap: onBillDodger,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _QuickLaunchTile(
                    title: 'Game Hub',
                    subtitle: 'Browse all modes',
                    accent: const Color(0xFFA78BFA),
                    icon: Icons.dashboard_customize_rounded,
                    onTap: onGameHub,
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

class _QuickLaunchTile extends StatelessWidget {
  const _QuickLaunchTile({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
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
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldPortalStrip extends StatelessWidget {
  const _WorldPortalStrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0x1F85EFAC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.map_rounded,
                color: Color(0xFF85EFAC),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter the Town Square',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Jump into the main adventure world.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA3F0B6), Color(0xFF4ADE80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4022C55E),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF062C21),
        size: 30,
      ),
    );
  }
}

class _NotificationOrb extends StatelessWidget {
  const _NotificationOrb();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _GlassPanel(
          padding: const EdgeInsets.all(12),
          borderColor: Colors.white.withValues(alpha: 0.16),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF85EFAC),
            size: 24,
          ),
        ),
        Positioned(
          top: -3,
          right: -3,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5B6A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF062C21), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66FF5B6A),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChallengeHeroCard extends StatelessWidget {
  const _ChallengeHeroCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      glow: true,
      child: Stack(
        children: [
          Positioned(
            top: -26,
            right: -28,
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x3385EFAC),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _IconTile(
                    icon: Icons.bolt_rounded,
                    accent: Color(0xFF85EFAC),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Challenge',
                          style: TextStyle(
                            color: const Color(0xFF85EFAC).withValues(alpha: 0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'The Budget Battle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan your recent shop receipt to earn +50 EXP and boost your savings armor.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const _IconTile(
                    icon: Icons.gps_fixed_rounded,
                    accent: Color(0xFF11271F),
                    iconColor: Color(0xFF85EFAC),
                    dark: true,
                    size: 56,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _GlowingActionButton(
                label: 'Analyze Receipt',
                icon: Icons.receipt_long_rounded,
                onPressed: onPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VaultFeatureCard extends StatelessWidget {
  const _VaultFeatureCard({
    required this.vaultBalanceLabel,
    required this.onPressed,
  });

  final String vaultBalanceLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -54,
          right: 4,
          child: Image.asset(
            'assets/UI1/src/assets/f0dfd56a541371c704f7587e4add851958a11a86.png',
            width: 122,
            height: 122,
            fit: BoxFit.contain,
          ),
        ),
        _GlassPanel(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xCC062C21),
              Color(0xAA0F5132),
            ],
          ),
          borderColor: const Color(0x6685EFAC),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(right: 104),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconTile(
                        icon: Icons.currency_bitcoin_rounded,
                        accent: Color(0xFFA78BFA),
                        iconColor: Colors.white,
                        size: 42,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Crypto Vault',
                          style: TextStyle(
                            color: Color(0xFFA78BFA),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Digital Shell Safe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your future assets are tucked away. $vaultBalanceLabel is waiting in the vault.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MiniAccentButton(
                    label: 'View Stash',
                    onPressed: onPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
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
    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: Colors.white.withValues(alpha: 0.12),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WealthGrowthCard extends StatelessWidget {
  const _WealthGrowthCard({
    required this.weeklyGain,
    required this.chartPoints,
  });

  final int weeklyGain;
  final List<double> chartPoints;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      borderColor: Colors.white.withValues(alpha: 0.10),
      child: Column(
        children: [
          Row(
            children: [
              const _IconTile(
                icon: Icons.trending_up_rounded,
                accent: Color(0xFF2BD37A),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wealth Growth',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Past 7 Days',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+ \$${MainGameScreen._withCommas(weeklyGain)}.00',
                    style: const TextStyle(
                      color: Color(0xFF85EFAC),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Total Gained',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.56),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _AreaSparklinePainter(
                lineColor: const Color(0xFF85EFAC),
                fillColor: const Color(0x3385EFAC),
                points: chartPoints,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.savingsProgress,
    required this.literacyProgress,
  });

  final double savingsProgress;
  final double literacyProgress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _IconTile(
              icon: Icons.flag_rounded,
              accent: Color(0xFF85EFAC),
              size: 38,
            ),
            const SizedBox(width: 10),
            const Text(
              'Active Quests',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _GlassPanel(
          padding: const EdgeInsets.all(18),
          borderColor: Colors.white.withValues(alpha: 0.10),
          child: Column(
            children: [
              _QuestProgressRow(
                label: 'Savings Quest: Epic Mount',
                progress: savingsProgress,
                color: const Color(0xFF85EFAC),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                height: 1,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              _QuestProgressRow(
                label: 'Financial IQ: Advanced Spells',
                progress: literacyProgress,
                color: const Color(0xFF4ADE80),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MomentumCard extends StatelessWidget {
  const _MomentumCard({
    required this.streakDays,
    required this.challengeLabel,
    required this.tip,
  });

  final int streakDays;
  final String challengeLabel;
  final String tip;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      borderColor: Colors.white.withValues(alpha: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x1F85EFAC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x3385EFAC)),
                ),
                child: Text(
                  '$streakDays day streak',
                  style: const TextStyle(
                    color: Color(0xFF85EFAC),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFA78BFA),
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            challengeLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tip,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestProgressRow extends StatelessWidget {
  const _QuestProgressRow({
    required this.label,
    required this.progress,
    required this.color,
  });

  final String label;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 10,
            color: Colors.white.withValues(alpha: 0.10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: safeProgress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.68)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(safeProgress * 100).toStringAsFixed(0)}% complete',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glow = false,
    this.borderColor = const Color(0x1FFFFFFF),
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final Color borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.09),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
        border: Border.all(color: borderColor),
        boxShadow: [
          const BoxShadow(
            color: Color(0x55000000),
            blurRadius: 22,
            offset: Offset(0, 14),
          ),
          if (glow)
            const BoxShadow(
              color: Color(0x2285EFAC),
              blurRadius: 20,
              spreadRadius: 1,
            ),
        ],
      ),
      child: child,
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.accent,
    this.iconColor,
    this.dark = false,
    this.size = 44,
  });

  final IconData icon;
  final Color accent;
  final Color? iconColor;
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [
                  Color(0xFF0F241D),
                  Color(0xFF091813),
                ]
              : [
                  accent.withValues(alpha: 0.94),
                  accent.withValues(alpha: 0.60),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: dark ? 0.10 : 0.24),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconColor ?? const Color(0xFF062C21),
        size: size * 0.46,
      ),
    );
  }
}

class _GlowingActionButton extends StatelessWidget {
  const _GlowingActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFBBF7D0), Color(0xFF4ADE80)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF166534),
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x4485EFAC),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF062C21), size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF062C21),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAccentButton extends StatelessWidget {
  const _MiniAccentButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFFA78BFA), Color(0xFF6D28D9)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF4C1D95),
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _AreaSparklinePainter extends CustomPainter {
  const _AreaSparklinePainter({
    required this.lineColor,
    required this.fillColor,
    required this.points,
  });

  final Color lineColor;
  final Color fillColor;
  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final normalized = points
        .map((value) => value.clamp(0.0, 1.0).toDouble())
        .toList(growable: false);

    final linePath = Path();
    final fillPath = Path();

    for (var i = 0; i < normalized.length; i++) {
      final x = (size.width / (normalized.length - 1)) * i;
      final y = size.height - (normalized[i] * (size.height - 8)) - 4;
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColor, fillColor.withValues(alpha: 0.02)],
      ).createShader(Offset.zero & size);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3
      ..color = lineColor;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 8
      ..color = lineColor.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, glowPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _AreaSparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
