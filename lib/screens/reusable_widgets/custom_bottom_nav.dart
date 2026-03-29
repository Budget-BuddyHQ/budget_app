import 'package:flutter/material.dart';

import '../Gameplay/main_game_screen.dart';
import '../Gameplay/town_square_screen.dart';
import '../profile/user_profile_screen.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.activeIndex,
    this.activeColor = const Color(0xFF85EFAC),
  });

  final int activeIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final items = <_NavConfig>[
      _NavConfig(
        label: 'Home',
        icon: Icons.home_rounded,
        onTap: activeIndex == 0
            ? null
            : () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainGameScreen()),
                ),
      ),
      _NavConfig(label: 'Budget', icon: Icons.wallet_rounded),
      _NavConfig(label: 'Invest', icon: Icons.insights_rounded),
      _NavConfig(label: 'Challenges', icon: Icons.emoji_events_rounded),
      _NavConfig(
        label: 'Play',
        icon: Icons.sports_esports_rounded,
        onTap: activeIndex == 4
            ? null
            : () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TownSquareScreen()),
                ),
      ),
      _NavConfig(
        label: 'Profile',
        icon: Icons.person_rounded,
        onTap: activeIndex == 5
            ? null
            : () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                ),
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  const Color(0xFF062C21).withValues(alpha: 0.96),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 28,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavItem(
                      label: items[i].label,
                      icon: items[i].icon,
                      active: activeIndex == i,
                      activeColor: activeColor,
                      onTap: items[i].onTap,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavConfig {
  const _NavConfig({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? const Color(0xFF062C21) : Colors.white70;
    final labelColor = active ? const Color(0xFF062C21) : Colors.white60;
    final highlightTop = activeColor.withValues(alpha: 0.28);
    final highlightBottom = activeColor.withValues(alpha: 0.92);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 58;
        final showLabel = !compact || active;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: EdgeInsets.symmetric(
                vertical: showLabel ? 8 : 10,
                horizontal: 4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: active
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [highlightTop, highlightBottom],
                      )
                    : null,
                boxShadow: active
                    ? [
                        const BoxShadow(
                          color: Color(0xFF166534),
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.26),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
                border: Border.all(
                  color: active
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: active ? 22 : 20),
                  if (showLabel) const SizedBox(height: 4),
                  if (showLabel)
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: compact ? 9 : 10,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
