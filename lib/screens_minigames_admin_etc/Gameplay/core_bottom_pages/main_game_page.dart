import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';

/// The main-game tab: a launcher for **Life** (the BitLife-style main game),
/// with quick jumps to Academy and Arcade. The old open-world map lived here
/// and has been removed.
class MainGamePage extends StatelessWidget {
  const MainGamePage({
    super.key,
    this.activeTabIndex = AppTabIndex.adventure,
    this.onNavSelected,
  });

  final int activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  Future<void> _playLife(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).pushNamed('/life');
  }

  void _openTab(int tab) {
    HapticFeedback.lightImpact();
    onNavSelected?.call(tab);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStatsController>(
      builder: (context, controller, _) {
        final stats = controller.stats;
        return Scaffold(
          backgroundColor: const Color(0xFF071711),
          bottomNavigationBar: onNavSelected == null
              ? null
              : CustomBottomNav(
                  activeIndex: activeTabIndex,
                  onSelected: onNavSelected!,
                ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              children: [
                const Text(
                  'Play',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Level ${stats.level} • ${stats.gold} gold',
                  style: const TextStyle(
                    color: Color(0xFFFFD45C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                _LifeHeroCard(onPlay: () => _playLife(context)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ShortcutCard(
                        label: 'Academy',
                        subtitle: 'Lessons & quizzes',
                        icon: Icons.school_rounded,
                        color: const Color(0xFF58C7FF),
                        onTap: () => _openTab(AppTabIndex.academy),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ShortcutCard(
                        label: 'Arcade',
                        subtitle: 'Mini-games',
                        icon: Icons.sports_esports_rounded,
                        color: const Color(0xFFFF8FB1),
                        onTap: () => _openTab(AppTabIndex.minigames),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LifeHeroCard extends StatelessWidget {
  const _LifeHeroCard({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C5038), Color(0xFF081B14)],
          ),
          border: Border.all(color: const Color(0xFF85EFAC).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD45C).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'MAIN GAME',
                    style: TextStyle(
                      color: Color(0xFFFFD45C),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Play Life',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Grow up year by year, make real money decisions, and shape your '
              'money, happiness, health, and smarts.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onPlay,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF85EFAC),
                foregroundColor: const Color(0xFF06251A),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Start your life',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
