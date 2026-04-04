import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../services/supabase_service.dart' show UserStats;
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/game_toast.dart';
import 'bill_dodger.dart';
import 'react_challenge_screen.dart';

class TownSquare extends StatelessWidget {
  const TownSquare({super.key, this.activeTabIndex = 2, this.onNavSelected});

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
          : 'Battle Complete',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;

        return Scaffold(
          backgroundColor: const Color(0xFF08150F),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected,
                ),
          body: Stack(
            children: [
              const _TownBackdrop(),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
                  children: [
                    _TownHeader(stats: stats),
                    const SizedBox(height: 18),
                    _WorldBoard(
                      onBudgetBattle: () => _launchBudgetBattle(context),
                      onBillDodger: () => _launchBillDodger(context),
                      onLessons: () => onNavSelected?.call(3),
                      onFinancials: () => onNavSelected?.call(1),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final tileWidth = constraints.maxWidth < 680
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 12) / 2;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: tileWidth,
                              child: _PortalPanel(
                                title: 'Budget Battle Portal',
                                subtitle:
                                    'Enter the featured challenge arena and bank live rewards.',
                                accent: const Color(0xFFFFD45C),
                                icon: Icons.auto_awesome_rounded,
                                buttonLabel: 'Enter Arena',
                                onPressed: () => _launchBudgetBattle(context),
                              ),
                            ),
                            SizedBox(
                              width: tileWidth,
                              child: _PortalPanel(
                                title: 'Bill Dodger Alley',
                                subtitle:
                                    'Practice needs versus wants with full freedom of movement.',
                                accent: const Color(0xFF85EFAC),
                                icon: Icons.sports_esports_rounded,
                                buttonLabel: 'Play Arcade',
                                onPressed: () => _launchBillDodger(context),
                              ),
                            ),
                            SizedBox(
                              width: tileWidth,
                              child: _PortalPanel(
                                title: 'Academy Steps',
                                subtitle:
                                    'Continue through the node-based learning map and unlock new lessons.',
                                accent: const Color(0xFF58C7FF),
                                icon: Icons.school_rounded,
                                buttonLabel: 'Open Lessons',
                                onPressed: () => onNavSelected?.call(3),
                              ),
                            ),
                            SizedBox(
                              width: tileWidth,
                              child: _PortalPanel(
                                title: 'Treasury Walk',
                                subtitle:
                                    'Review your clean financial snapshot before your next quest.',
                                accent: const Color(0xFFA78BFA),
                                icon: Icons.account_balance_wallet_rounded,
                                buttonLabel: 'Open Financials',
                                onPressed: () => onNavSelected?.call(1),
                              ),
                            ),
                          ],
                        );
                      },
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
}

class _TownBackdrop extends StatelessWidget {
  const _TownBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF07140F), Color(0xFF0B2118), Color(0xFF113227)],
            ),
          ),
        ),
        Positioned(
          top: -110,
          right: -70,
          child: _Aura(
            size: 260,
            color: const Color(0xFF4ADE80).withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          top: 220,
          left: -80,
          child: _Aura(
            size: 220,
            color: const Color(0xFFFFD45C).withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}

class _Aura extends StatelessWidget {
  const _Aura({required this.size, required this.color});

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

class _TownHeader extends StatelessWidget {
  const _TownHeader({required this.stats});

  final UserStats stats;

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
              colors: [Color(0xFFFFE55C), Color(0xFF4ADE80)],
            ),
          ),
          child: const Icon(
            Icons.explore_rounded,
            color: Color(0xFF062C21),
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Town Square',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Level ${stats.level} | ${stats.literacyPoints} literacy | \$${stats.gold}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 12,
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

class _WorldBoard extends StatelessWidget {
  const _WorldBoard({
    required this.onBudgetBattle,
    required this.onBillDodger,
    required this.onLessons,
    required this.onFinancials,
  });

  final VoidCallback onBudgetBattle;
  final VoidCallback onBillDodger;
  final VoidCallback onLessons;
  final VoidCallback onFinancials;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.09),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prodigy-Style World Hub',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The emerald world map is the heart of Budget Buddy: battle, study, and review your economy from one central place.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 320,
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF103225), Color(0xFF0A1C16)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _WorldPathPainter()),
                ),
                const Positioned(
                  top: 0,
                  left: 18,
                  child: _WorldLabel(
                    title: 'Emerald Commons',
                    subtitle: 'central district',
                  ),
                ),
                Positioned(
                  top: 75,
                  left: 28,
                  child: _NodeButton(
                    label: 'Treasury',
                    icon: Icons.account_balance_wallet_rounded,
                    accent: const Color(0xFFA78BFA),
                    onTap: onFinancials,
                  ),
                ),
                Positioned(
                  top: 54,
                  right: 28,
                  child: _NodeButton(
                    label: 'Arena',
                    icon: Icons.workspace_premium_rounded,
                    accent: const Color(0xFFFFD45C),
                    onTap: onBudgetBattle,
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 42,
                  child: _NodeButton(
                    label: 'Bill Dodger',
                    icon: Icons.sports_esports_rounded,
                    accent: const Color(0xFF85EFAC),
                    onTap: onBillDodger,
                  ),
                ),
                Positioned(
                  bottom: 34,
                  right: 36,
                  child: _NodeButton(
                    label: 'Academy',
                    icon: Icons.school_rounded,
                    accent: const Color(0xFF58C7FF),
                    onTap: onLessons,
                  ),
                ),
                Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
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

class _WorldLabel extends StatelessWidget {
  const _WorldLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
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
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeButton extends StatelessWidget {
  const _NodeButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
              border: Border.all(
                color: accent.withValues(alpha: 0.56),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.24),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Icon(icon, color: accent, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalPanel extends StatelessWidget {
  const _PortalPanel({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: const Color(0xFF062C21),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.20, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.10,
        size.width * 0.72,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.40,
        size.width * 0.28,
        size.height * 0.78,
      );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = const Color(0x224ADE80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF85EFAC);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
