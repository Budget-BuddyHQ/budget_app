import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/life_ending.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../../widgets_custom_lotties/idle_hover_icon.dart';

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
          backgroundColor: AppTheme.deepForest,
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
                Text(
                  'Play',
                  style: GoogleFonts.baloo2(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Level ${stats.level} • ${stats.gold} gold',
                  style: GoogleFonts.baloo2(
                    color: const Color(0xFFFFD45C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _LifeHeroCard(onPlay: () => _playLife(context)),
                const SizedBox(height: 18),
                _EndingsCollection(
                  discovered: stats.discoveredEndings.toSet(),
                  onPlay: () => _playLife(context),
                ),
                const SizedBox(height: 18),
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

/// The endings collection — every [LifeEndingArchetype] as a slot, filled in
/// once the player actually reaches it.
///
/// This is what turns Life from "a run you finish" into "a set you complete":
/// endings were already computed and shown on the epilogue, but nothing
/// remembered them, so there was no reason to replay for a different one.
class _EndingsCollection extends StatelessWidget {
  const _EndingsCollection({required this.discovered, required this.onPlay});

  final Set<String> discovered;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    const all = LifeEndingArchetype.values;
    final found = all.where((e) => discovered.contains(e.name)).length;
    final complete = found == all.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.getPuffyDecoration(
        accent: const Color(0xFFFFD45C),
        fillColor: AppTheme.panelStrong,
        restAlpha: 0.1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The spinning/glowing treatment, on the one element that
              // earns it: the collection's own trophy.
              IdleHoverIcon(
                idleAmplitude: 0,
                continuousSpin: complete,
                pulseAmplitude: complete ? 0.0 : 0.10,
                period: const Duration(seconds: 6),
                child: Icon(
                  complete
                      ? Icons.workspace_premium_rounded
                      : Icons.auto_stories_rounded,
                  color: const Color(0xFFFFD45C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Endings',
                  style: GoogleFonts.baloo2(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$found / ${all.length}',
                style: GoogleFonts.baloo2(
                  color: const Color(0xFFFFD45C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            complete
                ? 'Every ending found. However you live it, you have seen where it goes.'
                : 'How your life turns out decides the ending you get. Play differently to find the rest.',
            style: GoogleFonts.quicksand(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              // Slot grid sized off available width so it reflows from a
              // narrow phone up to a tablet without a fixed column count.
              final columns = (constraints.maxWidth / 108).floor().clamp(2, 7);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: all.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 92,
                ),
                itemBuilder: (context, index) {
                  final ending = all[index];
                  return _EndingSlot(
                    ending: ending,
                    found: discovered.contains(ending.name),
                  );
                },
              );
            },
          ),
          if (!complete) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF85EFAC),
                  side: BorderSide(
                    color: const Color(0xFF85EFAC).withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: Text(
                  'Live another life',
                  style: GoogleFonts.baloo2(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EndingSlot extends StatelessWidget {
  const _EndingSlot({required this.ending, required this.found});

  final LifeEndingArchetype ending;
  final bool found;

  @override
  Widget build(BuildContext context) {
    // Undiscovered slots deliberately keep their silhouette and colour but
    // hide the name — enough to hint the set's shape without spoiling it.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: found
            ? ending.color.withValues(alpha: 0.13)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: found
              ? ending.color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            found ? ending.icon : Icons.lock_rounded,
            color: found
                ? ending.color
                : Colors.white.withValues(alpha: 0.28),
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            found ? ending.label : 'Undiscovered',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.baloo2(
              color: found
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
              fontSize: 10.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A5F46), Color(0xFF12301F)],
          ),
          border: Border.all(color: const Color(0xFF85EFAC).withValues(alpha: 0.32)),
          boxShadow: AppTheme.puffyShadow(const Color(0xFF85EFAC), restAlpha: 0.2),
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
                  child: Text(
                    'MAIN GAME',
                    style: GoogleFonts.baloo2(
                      color: const Color(0xFFFFD45C),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Play Life',
              style: GoogleFonts.baloo2(
                color: Colors.white,
                fontSize: 40,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Grow up year by year, make real money decisions, and shape your '
              'money, happiness, health, and smarts.',
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.82),
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
              label: Text(
                'Start your life',
                style: GoogleFonts.baloo2(fontWeight: FontWeight.w700, fontSize: 15),
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
        decoration: AppTheme.getPuffyDecoration(
          accent: color,
          fillColor: AppTheme.panelStrong,
          restAlpha: 0.14,
          borderRadius: AppTheme.radiusLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.baloo2(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.quicksand(
                color: Colors.white.withValues(alpha: 0.65),
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
