import 'package:flutter/material.dart';

import '../../models/user_progress_state.dart';
import '../reusable_widgets/custom_bottom_nav.dart';
import 'dashboard_shell.dart';
import 'react_game_screen.dart';




class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  void _onNavSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardShell(initialIndex: 0),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardShell(initialIndex: 1),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardShell(initialIndex: 2),
          ),
        );
        break;
      case 3:
        // Already on Challenges screen.
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardShell(initialIndex: 4),
          ),
        );
        break;
    }
  }

  Future<void> _launchGame(
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

    final syncMessage = result.syncResult.message ??
        (result.syncResult.synced
            ? 'Progress saved to Postgres.'
            : 'Progress saved locally.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.status.toUpperCase()}: +${result.goldEarned} gold, '
          '+${result.xpEarned} XP. $syncMessage',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A4D3D),
      bottomNavigationBar: CustomBottomNav(
        activeIndex: 3,
        onSelected: (index) => _onNavSelected(context, index),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Game Hub',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choose Your Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),

          ),
          const SizedBox(height: 20),
          _GameTile(
            title: 'Bill Dodger',
            icon: Icons.pets,
            subtitle: 'Collect needs, dodge wants',
            onTap: () => Navigator.of(context).pushNamed('/bill_dodger'),
          ),
          const SizedBox(height: 15),
          _GameTile(
            title: 'Epic Mini-Games',
            icon: Icons.sports_esports,
            subtitle: 'Fast rounds for gold and XP',
            onTap: () => _launchGame(
              context,
              gameId: 'epic_mini_games',
              difficulty: 'normal',
            ),
          ),
          const SizedBox(height: 15),
          _GameTile(
            title: 'Lessons and Quests',
            icon: Icons.menu_book,
            subtitle: 'Scenario-based decision missions',
            onTap: () => _launchGame(
              context,
              gameId: 'lessons_and_quests',
              difficulty: 'easy',
            ),
          ),
          const SizedBox(height: 15),
          _GameTile(
            title: 'Daily Challenges',
            icon: Icons.emoji_events,
            subtitle: 'High reward challenge of the day',
            onTap: () => _launchGame(
              context,
              gameId: 'daily_challenge',
              difficulty: 'hard',
            ),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF254E3F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
