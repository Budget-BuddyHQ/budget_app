import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import 'bill_dodger_game.dart';
import 'dashboard_shell.dart';
import 'learning_path_screen.dart';
import 'react_game_screen.dart';
import 'town_square_screen.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  void _onNavSelected(BuildContext context, int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardShell(initialIndex: index.clamp(0, 4).toInt()),
      ),
    );
  }

  Future<void> _launchReactGame(
    BuildContext context, {
    required String gameId,
    required String difficulty,
    required String title,
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
        content: Text(
          '$title complete: +${result.goldEarned} gold, '
          '+${result.xpEarned} XP. ${result.syncState.message}',
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bill Dodger: +${result.goldEarned} gold, '
          '+${result.xpEarned} XP. ${result.syncState.message}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081F18),
      bottomNavigationBar: CustomBottomNav(
        activeIndex: 3,
        onSelected: (index) => _onNavSelected(context, index),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
          children: [
            const Text(
              'Game Hub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose where your finance adventure goes next.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _HubCard(
              title: 'Town Square',
              subtitle: 'Main world hub for quests, study, and minigames',
              icon: Icons.map_rounded,
              accent: const Color(0xFF85EFAC),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TownSquareScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _HubCard(
              title: 'Bill Dodger',
              subtitle: 'Dodge wants, collect needs, and protect your budget',
              icon: Icons.receipt_long_rounded,
              accent: const Color(0xFFFFC36B),
              onTap: () => _launchBillDodger(context),
            ),
            const SizedBox(height: 14),
            _HubCard(
              title: 'Budget Battle',
              subtitle: 'React minigame challenge with synced rewards',
              icon: Icons.bolt_rounded,
              accent: const Color(0xFF85EFAC),
              onTap: () => _launchReactGame(
                context,
                gameId: 'daily_budget_battle',
                difficulty: 'normal',
                title: 'Budget Battle',
              ),
            ),
            const SizedBox(height: 14),
            _HubCard(
              title: 'Lessons and Quests',
              subtitle: 'Progress through the learning path and unlock nodes',
              icon: Icons.menu_book_rounded,
              accent: const Color(0xFF7FE7C4),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LearningPathScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _HubCard(
              title: 'Challenge Portal',
              subtitle: 'Hard-mode web challenge for extra XP',
              icon: Icons.auto_awesome_rounded,
              accent: const Color(0xFFA78BFA),
              onTap: () => _launchReactGame(
                context,
                gameId: 'daily_challenge',
                difficulty: 'hard',
                title: 'Challenge Portal',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
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
              Colors.white.withValues(alpha: 0.09),
              Colors.white.withValues(alpha: 0.03),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent, size: 26),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.66),
                      fontSize: 12,
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
    );
  }
}
