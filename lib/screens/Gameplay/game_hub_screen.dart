import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';

import 'react_game_screen.dart';


  Future<void> _launchGame(
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
        content: Text(
          '${result.status.toUpperCase()}: +${result.goldEarned} gold, '
          '+${result.xpEarned} XP. ${result.syncState.message}',
        ),
      ),
    );
  }

      bottomNavigationBar: const CustomBottomNav(activeIndex: 3),
          'Game Hub',
      body: ListView(
        children: [
          const Text(
            'Choose Your Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 20),
          _GameTile(
            title: 'Epic Mini-Games',
            icon: Icons.sports_esports,
            subtitle: 'Fast rounds for gold and XP',
            onTap: () => _launchGame(
              context,
              gameId: 'epic_mini_games',
              difficulty: 'normal',
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
        ],
    required this.subtitle,
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      child: Ink(
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
}
