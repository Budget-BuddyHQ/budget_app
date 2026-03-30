import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import 'bill_dodger_game.dart';
import 'game_hub_screen.dart';
import 'react_game_screen.dart';
import 'town_square_screen.dart';

class MainGameScreen extends StatelessWidget {
  const MainGameScreen({
    super.key,
    this.activeTabIndex = 0,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _openReactGame(
    BuildContext context, {
    required String gameId,
    required String difficulty,
  }) async {
    final stats = context.read<UserStatsController>().stats;

    final result = await Navigator.push<ReactGameCloseResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ReactGameScreen(
          gameId: gameId,
          difficulty: difficulty,
          playerLevel: stats.level,
          userId: stats.id,
        ),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0E362B),
        content: Text(
          '${result.status.toUpperCase()}: +${result.goldEarned} gold, '
          '+${result.xpEarned} XP. ${result.syncState.message}',
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0E362B),
        content: Text(
          'Bill Dodger: +${result.goldEarned} gold, '
          '+${result.xpEarned} XP. ${result.syncState.message}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        final savingsRate = ((stats.gold / 5200) * 100).clamp(1, 100).toDouble();
        final roiBase = stats.portfolioHistory.isEmpty
            ? 0.0
            : ((stats.portfolioHistory.last - stats.portfolioHistory.first) * 100);
        final roi = roiBase.clamp(-20, 35).toDouble();

        return Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFF041A14),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected,
                ),
          body: Stack(
            children: [
              const _DashboardBackdrop(),
              SafeArea(
                child: controller.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF85EFAC),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DashboardHeader(
                              currentBalance: stats.gold,
                              levelTitle: stats.levelTitle,
                            ),
                            const SizedBox(height: 14),
                            _WorldPortalStrip(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TownSquareScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _QuickLaunchSection(
                              onTownSquare: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TownSquareScreen(),
                                ),
                              ),
                              onBillDodger: () => _openBillDodger(context),
                              onGameHub: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GameHubScreen(),
                                ),
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
                              vaultBalanceLabel:
                                  '${stats.holdings['indexFunds'] ?? 0} funds',
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
                                  value: _withCommas(stats.literacyPoints),
                                  accent: const Color(0xFF7FE7C4),
                                  icon: Icons.auto_awesome_outlined,
                                ),
                                _StatPill(
                                  label: 'ROI',
                                  value:
                                      '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(1)}%',
                                  accent: const Color(0xFFA78BFA),
                                  icon: Icons.trending_up_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _WealthGrowthCard(
                              weeklyGain: stats.gold ~/ 7,
                              chartPoints: stats.portfolioHistory.isEmpty
                                  ? const [0.28, 0.37, 0.34, 0.52, 0.48, 0.67, 0.82]
                                  : stats.portfolioHistory,
                            ),
                            const SizedBox(height: 24),
                            _QuestCard(
                              savingsProgress: savingsRate / 100,
                              literacyProgress:
                                  (stats.literacyPoints / 1400)
                                      .clamp(0.0, 1.0)
                                      .toDouble(),
                            ),
                            const SizedBox(height: 24),
                            _MomentumCard(
                              streakDays: 6,
                              challengeLabel: 'Receipt Rescue',
                              tip: controller.statusMessage ??
                                  stats.wizardAdvice,
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
          child: _GlowOrb(size: 260, color: Color(0x5585EFAC)),
        ),
        const Positioned(
          top: 260,
          right: -70,
          child: _GlowOrb(size: 220, color: Color(0x334ADE80)),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 390
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _QuickLaunchTile(
                title: 'Town Square',
                subtitle: 'Enter the world map',
                icon: Icons.map_rounded,
                accent: const Color(0xFF85EFAC),
                onTap: onTownSquare,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _QuickLaunchTile(
                title: 'Bill Dodger',
                subtitle: 'Fast budget reflex game',
                icon: Icons.receipt_long_rounded,
                accent: const Color(0xFFFFC36B),
                onTap: onBillDodger,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _QuickLaunchTile(
                title: 'Game Hub',
                subtitle: 'Browse all modes',
                icon: Icons.dashboard_customize_rounded,
                accent: const Color(0xFFA78BFA),
                onTap: onGameHub,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickLaunchTile extends StatelessWidget {
  const _QuickLaunchTile({
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
          ],
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
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF062C21),
        size: 30,
      ),
    );
  }
}

class _ChallengeHeroCard extends StatelessWidget {
  const _ChallengeHeroCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
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
          const SizedBox(height: 8),
          const Text(
            'The Budget Battle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Launch the React challenge and turn smart decisions into gold, XP, and cloud-synced progress.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _GlowingActionButton(
            label: 'Start Challenge',
            icon: Icons.bolt_rounded,
            onPressed: onPressed,
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
    return _GlassPanel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crypto Vault',
                  style: TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Digital Shell Safe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$vaultBalanceLabel waiting in the vault.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 14),
                _MiniAccentButton(
                  label: 'View Stash',
                  onPressed: onPressed,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Image.asset(
            'assets/UI1/src/assets/f0dfd56a541371c704f7587e4add851958a11a86.png',
            width: 92,
            height: 92,
            fit: BoxFit.contain,
          ),
        ],
      ),
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
                ),
              ),
            ],
          ),
        ],
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
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF85EFAC),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Wealth Growth',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '+ \$${MainGameScreen._withCommas(weeklyGain)}',
                style: const TextStyle(
                  color: Color(0xFF85EFAC),
                  fontWeight: FontWeight.w900,
                ),
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
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Quests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _QuestProgressRow(
            label: 'Savings Quest',
            progress: savingsProgress,
            color: const Color(0xFF85EFAC),
          ),
          const SizedBox(height: 16),
          _QuestProgressRow(
            label: 'Financial IQ',
            progress: literacyProgress,
            color: const Color(0xFF4ADE80),
          ),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$streakDays day streak',
            style: const TextStyle(
              color: Color(0xFF85EFAC),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
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
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: safeProgress,
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.09),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 22,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
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
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF85EFAC),
        foregroundColor: const Color(0xFF062C21),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900),
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
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFA78BFA),
        foregroundColor: Colors.white,
      ),
      child: Text(label),
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

    final safePoints = points
        .map((value) => value.clamp(0.0, 1.0).toDouble())
        .toList(growable: false);
    final linePath = Path();
    final fillPath = Path();

    for (var i = 0; i < safePoints.length; i++) {
      final x = (size.width / (safePoints.length - 1)) * i;
      final y = size.height - (safePoints[i] * (size.height - 8)) - 4;
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

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _AreaSparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
