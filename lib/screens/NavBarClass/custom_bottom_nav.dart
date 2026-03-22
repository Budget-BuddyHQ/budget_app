import 'package:flutter/material.dart';
import '../Gameplay/game_hub_screen.dart';
import '../user_profile_screen.dart';
import '../main_game_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int activeIndex;

  const CustomBottomNav({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 25),
      decoration: const BoxDecoration(color: Color(0xFF1F4E3B)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            label: 'Home',
            icon: Icons.home,
            active: activeIndex == 0,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainGameScreen()),
              );
            },
          ),
          _NavItem(
            label: 'Budget',
            icon: Icons.attach_money,
            active: activeIndex == 1,
          ),
          _NavItem(
            label: 'Invest',
            icon: Icons.trending_up,
            active: activeIndex == 2,
          ),
          _NavItem(
            label: 'Challenges',
            icon: Icons.emoji_events,
            active: activeIndex == 3,
          ),
          _NavItem(
            label: 'Games',
            icon: Icons.gamepad,
            active: activeIndex == 4,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GameHubScreen()),
              );
            },
          ),
          _NavItem(
            label: 'Profile',
            icon: Icons.person,
            active: activeIndex == 5,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
