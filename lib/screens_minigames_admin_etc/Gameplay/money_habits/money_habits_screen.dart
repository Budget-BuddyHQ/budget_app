import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/money_habit_controller.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../custom_made_widgets/habit_challenge_row_item.dart';
import '../../../models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../../../widgets_custom_lotties/habit_progress_grids.dart';
import '../../../widgets_custom_lotties/savings_jar_widget.dart';
import '../minigames_pages/react_challenge_screen.dart';

/// Entry point for Money Habits: a daily budgeting-habit tracker (skip
/// eating out, save spare change, wait before a big purchase) with a
/// savings jar that fills up as habits stick. A pushed, non-tab screen (own
/// `Scaffold`, no `CustomBottomNav`) with its own internal `TabBar`, the
/// same shape the Market Board already uses for its Assets/Trade/Orders/
/// P&L/Analytics tabs — see docs/MONEY_HABITS_FEATURE.md §4 for the full
/// navigation map.
class MoneyHabitsScreen extends StatefulWidget {
  const MoneyHabitsScreen({
    super.key,
    this.activeTabIndex,
    this.onNavSelected,
  });

  /// Set when this is hosted as the "Daily" bottom tab. Left null when it's
  /// pushed as a route (from Home's daily card), in which case it keeps its
  /// back arrow and shows no bottom nav — the same widget serving both
  /// entry points without a second copy.
  final int? activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  @override
  State<MoneyHabitsScreen> createState() => _MoneyHabitsScreenState();
}

class _MoneyHabitsScreenState extends State<MoneyHabitsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asTab = widget.onNavSelected != null;

    return Scaffold(
      backgroundColor: AppTheme.deepForest,
      bottomNavigationBar: asTab
          ? CustomBottomNav(
              activeIndex: widget.activeTabIndex ?? AppTabIndex.daily,
              onSelected: widget.onNavSelected!,
            )
          : null,
      appBar: AppBar(
        backgroundColor: AppTheme.deepForest,
        foregroundColor: Colors.white,
        elevation: 0,
        // As a tab there is nothing to go back *to*, so the arrow would be
        // a dead control.
        automaticallyImplyLeading: !asTab,
        title: Text('Money Habits', style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          // isScrollable already lets the tabs scroll off-screen on a narrow
          // phone, but with no visible thumb there was no hint that "My Jar"
          // was reachable by swiping — a Scrollbar makes the overflow
          // discoverable instead of silently there.
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          // Deliberately NOT thumbVisibility: true here. TabBar does not
          // expose its internal horizontal ScrollController, so a
          // thumbVisibility Scrollbar (which requires a real controller
          // with exactly one attached ScrollPosition) has nothing correct
          // to bind to — it either throws outright, or silently falls back
          // to the page's *vertical* PrimaryScrollController, which is
          // shared with every other tab's own scroll view inside the same
          // IndexedStack and has several positions attached at once. Both
          // were tried and both broke `flutter test` immediately. Default
          // (non-thumbVisibility) mode needs no controller at all — it
          // tracks TabBar's scroll notifications directly and shows a
          // fading thumb while a drag is in progress, which is still a
          // real discoverability cue that "My Jar" scrolls into view.
          child: Scrollbar(
            thickness: 3,
            radius: const Radius.circular(4),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.greenPrimary,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
              // Icon + word rather than a bare word: "Track" and "Activity"
              // are close enough in meaning that the labels alone did not
              // tell a first-time user which one listed habits and which
              // one logged them.
              tabs: const [
                Tab(icon: Icon(Icons.check_circle_outline_rounded, size: 18), text: 'My Week'),
                Tab(icon: Icon(Icons.search_rounded, size: 18), text: 'Find Habits'),
                Tab(icon: Icon(Icons.flag_rounded, size: 18), text: 'Challenges'),
                Tab(icon: Icon(Icons.savings_rounded, size: 18), text: 'My Jar'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: const [
            _TrackTab(),
            _ActivityTab(),
            _ChallengesTab(),
            _JarTab(),
          ],
        ),
      ),
    );
  }
}

// ==================== Track ====================

class _TrackTab extends StatelessWidget {
  const _TrackTab();

  /// Was Home's "Daily" quick-action button, which opened this game
  /// directly and bypassed the actual Daily tab entirely — two different
  /// things both calling themselves "Daily" was the confusing part. Home's
  /// button now just switches to this tab (see `home_screen.dart`); the
  /// game itself lives here instead, at the top of the screen its name
  /// points to.
  Future<void> _launchDailyChallenge(BuildContext context) async {
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
          ? 'Daily Challenge Cleared'
          : 'Challenge Complete',
      message:
          '+${result.goldEarned} gold | +${result.xpEarned} XP | ${result.syncState.message}',
      icon: Icons.workspace_premium_rounded,
      accent: const Color(0xFFFFD45C),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<MoneyHabitController>();
    final totals = habits.lifetimeTotals;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DailyChallengeCard(onPlay: () => _launchDailyChallenge(context)),
        const SizedBox(height: 16),
        // Shown only until the first habit is pinned. New users landed on
        // an empty grid with no idea what the tabs did or where to start —
        // this spells the loop out once, then gets out of the way.
        if (habits.savedHabits.isEmpty) ...[
          const _HowItWorksCard(),
          const SizedBox(height: 16),
        ],
        _MoneyStatsRow(totals: totals),
        const SizedBox(height: 16),
        Text(
          'This week',
          style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        HabitWeeklyTrackerGrid(
          habits: habits.savedHabits,
          weeklyLog: habits.weeklyLog,
          onCompleteToday: (template) async {
            await habits.completeTrackedHabit(template);
            if (context.mounted) {
              GameToast.show(context, message: 'Logged: ${template.title}');
            }
          },
        ),
        const SizedBox(height: 16),
        if (habits.savedHabits.isNotEmpty) ...[
          Text(
            'Saved habits',
            style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final habit in habits.savedHabits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SavedHabitRow(
                habit: habit,
                onRemove: () => habits.unsaveHabit(habit.id),
              ),
            ),
        ] else
          Text(
            'Tap "Find Habits" above to pick your first one.',
            style: GoogleFonts.quicksand(color: AppTheme.textMuted),
          ),
      ],
    );
  }
}

/// A three-step diagram of the loop: pick → log → fill the jar. Plain
/// numbered steps with icons, because the previous version gave a first-time
/// user four unlabelled tabs and an empty grid and expected them to infer
/// the game from that.
/// The React Challenge minigame ("daily_budget_battle"), launched from the
/// tab its name actually refers to instead of a same-named button on Home
/// that used to skip past this screen entirely.
class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.getPuffyDecoration(
          accent: const Color(0xFFFFD45C),
          fillColor: const Color(0xFF3B301A),
          restAlpha: 0.18,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD45C).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFFFD45C),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Challenge",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A quick budgeting reflex round — gold and XP either way.',
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFFFD45C),
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    const steps = <({int n, IconData icon, String title, String body})>[
      (
        n: 1,
        icon: Icons.search_rounded,
        title: 'Pick a habit',
        body: 'Open Activity and save one you could actually do.',
      ),
      (
        n: 2,
        icon: Icons.check_circle_rounded,
        title: 'Log it each day',
        body: 'Tap today\'s circle on Track when you do it.',
      ),
      (
        n: 3,
        icon: Icons.savings_rounded,
        title: 'Fill your jar',
        body: 'Every log adds points. The jar grows as they add up.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.getPuffyDecoration(
        accent: AppTheme.greenPrimary,
        fillColor: AppTheme.panelStrong,
        restAlpha: 0.16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: AppTheme.greenPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'How this works',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final step in steps) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.greenPrimary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.greenPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${step.n}',
                    style: GoogleFonts.pixelifySans(
                      color: AppTheme.greenPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            step.icon,
                            size: 15,
                            color: AppTheme.greenPrimary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              step.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.pixelifySans(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.body,
                        style: GoogleFonts.quicksand(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (step.n != steps.length) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _MoneyStatsRow extends StatelessWidget {
  const _MoneyStatsRow({required this.totals});

  final HabitImpact totals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Money saved',
            value: '\$${totals.moneySavedUsd.toStringAsFixed(0)}',
            accent: const Color(0xFF4BD2A3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Smart choices',
            value: totals.choicesKept.toStringAsFixed(0),
            accent: const Color(0xFF69C6FF),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: AppTheme.getPuffyDecoration(accent: accent, restAlpha: 0.16),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.quicksand(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SavedHabitRow extends StatelessWidget {
  const _SavedHabitRow({required this.habit, required this.onRemove});

  final HabitTemplate habit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(habit.icon, color: habit.category.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(habit.title, style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            tooltip: 'Remove from tracker',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }
}

// ==================== Activity ====================

class _ActivityTab extends StatefulWidget {
  const _ActivityTab();

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  HabitCategory? _filter;

  // Explicit controller, shared with the Scrollbar below. A Scrollbar with
  // no controller binds to the ambient PrimaryScrollController — which the
  // tab's own vertical ListView already claims — so the thumb would track
  // the wrong axis (and crashes outright with thumbVisibility, since every
  // offstage tab in the IndexedStack has a position attached to it too).
  final ScrollController _filterScroll = ScrollController();

  @override
  void dispose() {
    _filterScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<MoneyHabitController>();
    final list = habitCatalog.where((t) => _filter == null || t.category == _filter).toList();

    return Column(
      children: [
        Padding(
          // Bottom padding trimmed 8 -> 2 to pay for the scrollbar's own
          // 8px lane, so adding it costs no extra vertical space and the
          // top of this tab stays as open as it was.
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          child: Scrollbar(
            controller: _filterScroll,
            thumbVisibility: true,
            thickness: 3,
            radius: const Radius.circular(3),
            child: SingleChildScrollView(
              controller: _filterScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _CategoryChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                  for (final category in HabitCategory.values) ...[
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: category.label,
                      selected: _filter == category,
                      accent: category.accent,
                      onTap: () => setState(() => _filter = category),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final habit = list[index];
              return _ActivityCard(
                habit: habit,
                saved: habits.savedHabits.any((h) => h.id == habit.id),
                onTap: () => _openHabitSheet(context, habit, habits),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openHabitSheet(
    BuildContext context,
    HabitTemplate habit,
    MoneyHabitController habits,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _HabitDetailSheet(habit: habit, habits: habits),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap, this.accent});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppTheme.greenPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.panel,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: selected ? 1 : 0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.pixelifySans(
            color: selected ? AppTheme.deepForest : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// A circular real-photo thumbnail for a habit, matching the reference
/// app's course-icon look — falls back to a plain icon tile when the habit
/// has no [HabitTemplate.photoUrl] yet (most of the catalog, still) or when
/// the network image fails to load, so a bad/offline URL degrades instead
/// of breaking the card.
class _HabitPhoto extends StatelessWidget {
  const _HabitPhoto({required this.habit, required this.size});

  final HabitTemplate habit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photoUrl = habit.photoUrl;
    if (photoUrl == null) {
      return _iconFallback();
    }
    return ClipOval(
      child: Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _iconFallback();
        },
        errorBuilder: (context, error, stack) => _iconFallback(),
      ),
    );
  }

  Widget _iconFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: habit.category.accent.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(habit.icon, color: habit.category.accent, size: size * 0.5),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.habit, required this.saved, required this.onTap});

  final HabitTemplate habit;
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.getPuffyDecoration(accent: habit.category.accent, restAlpha: 0.14),
        child: Row(
          children: [
            _HabitPhoto(habit: habit, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.title, style: GoogleFonts.pixelifySans(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(habit.blurb, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.quicksand(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (saved) Icon(Icons.bookmark_rounded, color: habit.category.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _HabitDetailSheet extends StatefulWidget {
  const _HabitDetailSheet({required this.habit, required this.habits});

  final HabitTemplate habit;
  final MoneyHabitController habits;

  @override
  State<_HabitDetailSheet> createState() => _HabitDetailSheetState();
}

class _HabitDetailSheetState extends State<_HabitDetailSheet> {
  late double _units;

  @override
  void initState() {
    super.initState();
    _units = widget.habits.savedHabitParams[widget.habit.id] ??
        widget.habit.adjustable?.defaultValue ??
        1;
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final adjustable = habit.adjustable;
    final impact = habit.impactFor(_units);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HabitPhoto(habit: habit, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Text(habit.title, style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(habit.blurb, style: GoogleFonts.quicksand(color: AppTheme.textMuted, height: 1.4)),
          const SizedBox(height: 18),
          if (adjustable != null) ...[
            Text(adjustable.label, style: GoogleFonts.pixelifySans(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                _StepperButton(
                  icon: Icons.remove_rounded,
                  onTap: () => setState(() => _units = (_units - adjustable.step).clamp(adjustable.min, adjustable.max)),
                ),
                Expanded(
                  child: Text(
                    adjustable.unit == 'dollars'
                        ? '\$${_units.toStringAsFixed(_units % 1 == 0 ? 0 : 1)}'
                        : '${_units.toStringAsFixed(_units % 1 == 0 ? 0 : 1)} ${adjustable.unit}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                _StepperButton(
                  icon: Icons.add_rounded,
                  onTap: () => setState(() => _units = (_units + adjustable.step).clamp(adjustable.min, adjustable.max)),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          _ImpactPreviewRow(impact: impact),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await widget.habits.saveHabit(habit, paramValue: adjustable != null ? _units : null);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.bookmark_add_rounded),
                  label: const Text('Save to Home'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.greenPrimary, foregroundColor: AppTheme.deepForest),
                  onPressed: () async {
                    await widget.habits.completeTrackedHabit(habit);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      GameToast.show(context, message: 'Logged: ${habit.title}');
                    }
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Complete now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppTheme.panel, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _ImpactPreviewRow extends StatelessWidget {
  const _ImpactPreviewRow({required this.impact});

  final HabitImpact impact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniStat(label: 'Money saved', value: '\$${impact.moneySavedUsd.toStringAsFixed(2)}'),
        _MiniStat(label: 'Smart choices', value: impact.choicesKept.toStringAsFixed(0)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.pixelifySans(color: AppTheme.greenPrimary, fontWeight: FontWeight.w700)),
          Text(label, style: GoogleFonts.quicksand(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ==================== Challenges ====================

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab();

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<MoneyHabitController>();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: habitChallenges.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final challenge = habitChallenges[index];
        final progress = habits.challengeProgress(challenge);
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: AppTheme.getPuffyDecoration(accent: challenge.category.accent, restAlpha: 0.18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(challenge.category.icon, color: challenge.category.accent, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(challenge.title, style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                        Text(challenge.subtitle, style: GoogleFonts.quicksand(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(challenge.description, style: GoogleFonts.quicksand(color: Colors.white70, height: 1.4)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(challenge.category.accent),
                ),
              ),
              const SizedBox(height: 4),
              Text('${(progress * 100).round()}% complete', style: GoogleFonts.quicksand(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 14),
              HabitChallengeRowItem(
                tasks: challenge.tasks,
                statusFor: (task) {
                  if (habits.completedChallengeTasks.contains(task.id)) return HabitRowStatus.completed;
                  if (habits.isChallengeTaskAvailable(task)) return HabitRowStatus.available;
                  return HabitRowStatus.locked;
                },
                onTaskTap: (task) async {
                  await habits.completeChallengeTask(task);
                  if (context.mounted) {
                    final title = task.template?.title ?? task.id;
                    GameToast.show(context, message: 'Challenge habit complete: $title');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== Jar ====================

class _JarTab extends StatelessWidget {
  const _JarTab();

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<MoneyHabitController>();
    final stage = habits.jarStage;
    final mood = habits.jarMood;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(child: SavingsJarWidget(stage: stage, mood: mood, size: 220)),
        const SizedBox(height: 12),
        Center(
          child: Text(stage.label, style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: mood.color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
            child: Text(mood.label, style: GoogleFonts.pixelifySans(color: mood.color, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: stage.progressToNext(habits.jarXp),
            minHeight: 10,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(AppTheme.greenPrimary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stage.next == null
              ? 'Jar\'s full — ${habits.jarXp} habit points earned.'
              : '${habits.jarXp} / ${stage.next!.xpThreshold} habit points to ${stage.next!.label}',
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.panel, borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
          child: Text(
            mood == JarMood.slipping
                ? 'You haven\'t logged a habit in a while — log one on Track or Activity to get back on track.'
                : 'Complete habits on Track or Activity to earn habit points and fill your jar.',
            style: GoogleFonts.quicksand(color: Colors.white70, height: 1.4),
          ),
        ),
      ],
    );
  }
}
