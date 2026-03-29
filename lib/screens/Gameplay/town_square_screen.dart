import 'package:flutter/material.dart';

import '../../models/user_progress_state.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import 'bill_dodger_game.dart';
import 'game_hub_screen.dart';
import 'leaderboard_screen.dart';
import 'learning_path_screen.dart';
import 'main_game_screen.dart';
import 'react_game_screen.dart';

class TownSquareScreen extends StatelessWidget {
  const TownSquareScreen({super.key});

  Future<void> _launchReactGame(
    BuildContext context, {
    required String gameId,
    required String difficulty,
    required String title,
  }) async {
    final user = UserProgressState.instance;
    final result = await Navigator.push<ReactGameCloseResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ReactGameScreen(
          gameId: gameId,
          difficulty: difficulty,
          playerLevel: user.level,
          userId: user.userId,
          pageTitle: title,
        ),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    final syncText = result.syncResult.queued
        ? 'Cloud save queued while offline.'
        : 'Progress synced.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title complete: +${result.goldEarned} gold, '
          '+${result.xpEarned} XP. $syncText',
        ),
      ),
    );
  }

  Future<void> _launchBillDodger(BuildContext context) async {
    final result = await Navigator.push<BillDodgerCloseResult>(
      context,
      MaterialPageRoute(builder: (_) => const BillDodgerGameScreen()),
    );

    if (!context.mounted || result == null) {
      return;
    }

    final syncText = result.syncResult.queued
        ? 'Cloud save queued while offline.'
        : 'Progress synced.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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

        return Scaffold(
          backgroundColor: const Color(0xFF071B16),
          bottomNavigationBar: const CustomBottomNav(activeIndex: 4),
          body: Stack(
            children: [
              const _TownBackdrop(),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
                  children: [
                    _TownHeader(user: user),
                    const SizedBox(height: 22),
                    _WorldMapHero(
                      onDashboard: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MainGameScreen()),
                      ),
                      onBillDodger: () => _launchBillDodger(context),
                      onReactArena: () => _launchReactGame(
                        context,
                        gameId: 'daily_budget_battle',
                        difficulty: 'normal',
                        title: 'Budget Arena',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Destinations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _TownDestinationCard(
                      title: 'Budget Academy',
                      subtitle: 'Study lessons, unlock nodes, and level up your knowledge tree.',
                      icon: Icons.school_rounded,
                      accent: const Color(0xFF7FE7C4),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LearningPathScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TownDestinationCard(
                      title: 'Bill Dodger Alley',
                      subtitle: 'Fast reflex minigame for practicing needs versus wants.',
                      icon: Icons.receipt_long_rounded,
                      accent: const Color(0xFFFFC36B),
                      onTap: () => _launchBillDodger(context),
                    ),
                    const SizedBox(height: 12),
                    _TownDestinationCard(
                      title: 'Challenge Portal',
                      subtitle: 'Enter the React-powered challenge arena with cloud-saved rewards.',
                      icon: Icons.auto_awesome_rounded,
                      accent: const Color(0xFF85EFAC),
                      onTap: () => _launchReactGame(
                        context,
                        gameId: 'daily_challenge',
                        difficulty: 'hard',
                        title: 'Challenge Portal',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TownDestinationCard(
                      title: 'Guild Hall',
                      subtitle: 'Browse every game screen and future mode from one place.',
                      icon: Icons.dashboard_customize_rounded,
                      accent: const Color(0xFFA78BFA),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GameHubScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TownDestinationCard(
                      title: 'Leaderboard Tower',
                      subtitle: 'See where your account ranks among the top finance wizards.',
                      icon: Icons.leaderboard_rounded,
                      accent: const Color(0xFFF9D66B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                      ),
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
              colors: [
                Color(0xFF071B16),
                Color(0xFF0A2A22),
                Color(0xFF0F3B31),
              ],
            ),
          ),
        ),
        Positioned(
          top: -100,
          left: -70,
          child: _BackdropGlow(
            size: 220,
            color: const Color(0x4485EFAC),
          ),
        ),
        Positioned(
          top: 180,
          right: -90,
          child: _BackdropGlow(
            size: 240,
            color: const Color(0x3352D78C),
          ),
        ),
      ],
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({
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
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.40,
              spreadRadius: size * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}

class _TownHeader extends StatelessWidget {
  const _TownHeader({required this.user});

  final UserProgressState user;

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
              colors: [Color(0xFFBBF7D0), Color(0xFF4ADE80)],
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
                'Level ${user.level} | ${user.literacyPoints} literacy | \$${user.gold}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
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

class _WorldMapHero extends StatelessWidget {
  const _WorldMapHero({
    required this.onDashboard,
    required this.onBillDodger,
    required this.onReactArena,
  });

  final VoidCallback onDashboard;
  final VoidCallback onBillDodger;
  final VoidCallback onReactArena;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
            color: Color(0x44000000),
            blurRadius: 20,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget Buddy World',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your off-brand Prodigy-style hub: train, battle, study, and grow your financial kingdom.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF143E30), Color(0xFF0C231D)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _WorldPathPainter()),
                ),
                _MapNode(
                  top: 22,
                  left: 18,
                  label: 'Treasury',
                  icon: Icons.account_balance_rounded,
                  accent: const Color(0xFF7FE7C4),
                  onTap: onDashboard,
                ),
                _MapNode(
                  top: 52,
                  right: 24,
                  label: 'Arena',
                  icon: Icons.auto_awesome_rounded,
                  accent: const Color(0xFF85EFAC),
                  onTap: onReactArena,
                ),
                _MapNode(
                  bottom: 18,
                  left: 46,
                  label: 'Bill Dodger',
                  icon: Icons.receipt_long_rounded,
                  accent: const Color(0xFFFFC36B),
                  onTap: onBillDodger,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapNode extends StatelessWidget {
  const _MapNode({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.50)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.20),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TownDestinationCard extends StatelessWidget {
  const _TownDestinationCard({
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
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.66),
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _WorldPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.10,
        size.width * 0.72,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.42,
        size.width * 0.32,
        size.height * 0.82,
      );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = const Color(0x2285EFAC)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF85EFAC).withValues(alpha: 0.80);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
