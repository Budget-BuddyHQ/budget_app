import 'package:flutter/material.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3329),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Game Hub",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose Your Activity",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Mini‑Games Section
            _GameTile(
              title: "Epic Mini‑Games",
              icon: Icons.sports_esports,
              onTap: () {
                // TODO: Navigate to mini‑games screen
              },
            ),

            const SizedBox(height: 15),

            // Learning Section
            _GameTile(
              title: "Lessons & Quests",
              icon: Icons.menu_book,
              onTap: () {
                // TODO: Navigate to lessons screen
              },
            ),

            const SizedBox(height: 15),

            // Challenges Section
            _GameTile(
              title: "Daily Challenges",
              icon: Icons.emoji_events,
              onTap: () {
                // TODO: Navigate to challenge screen
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _GameTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF2E4A3D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}