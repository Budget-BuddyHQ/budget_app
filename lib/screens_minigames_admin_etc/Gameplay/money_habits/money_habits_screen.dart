import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/money_habit_controller.dart';
import '../../../custom_made_widgets/habit_challenge_row_item.dart';
import '../../../models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import '../../../models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/custom_bottom_nav.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../../../widgets_custom_lotties/habit_progress_grids.dart';
import '../../../widgets_custom_lotties/savings_jar_widget.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import 'today_tab.dart';
import '../../coach/coach_report_view.dart';

// The inner tab indices are part of this screen's API — `initialTab` takes
// one — so they are re-exported here rather than making every caller import
// the tab file that happens to define them.
export 'today_tab.dart' show MoneyHabitsTab;

/// The numbered step badge on the "How this works" card.
///
/// Mint text on a mint wash on a mint-lit panel — three shades of one color
/// stacked, which measured 2.39:1. Computed once: fill and ink have to move
/// together or the fix comes undone the next time either is touched.
final _stepChip = AppTheme.tintedChip(
  AppTheme.greenPrimary,
  on: AppTheme.panelStrong,
  target: 3.0,
);

/// Mint that stays readable on [AppTheme.panelStrong], for the icons that
/// share that card.
final _panelMint = AppTheme.legibleOn(
  AppTheme.greenPrimary,
  AppTheme.panelStrong,
);

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
    this.initialTab = 0,
    this.debugSnapshot,
  });

  /// Set when this is hosted as the "Daily" bottom tab. Left null when it's
  /// pushed as a route (from Home's daily card), in which case it keeps its
  /// back arrow and shows no bottom nav — the same widget serving both
  /// entry points without a second copy.
  final int? activeTabIndex;
  final ValueChanged<int>? onNavSelected;

  /// Which of the inner tabs opens first. See [MoneyHabitsTab] for the
  /// names — do not pass a literal.
  ///
  /// A test seam, the same shape as `LifeSimPage.debugInitialLife`: the
  /// viewport sweep needs to lay out My Jar and Challenges, and reaching them
  /// by tapping a `TabBar` in a test means driving an animation and finding a
  /// label — which fails for reasons that have nothing to do with the layout
  /// being checked. Also genuinely useful: a deep link to the jar has an
  /// obvious home here now.
  final int initialTab;

  /// Stands in for the player's real history on the Coach tab.
  ///
  /// Null in the app. The same seam as `LifeSimPage.debugInitialLife`, and
  /// for the same reason: the states worth looking at — somebody with a
  /// hundred ticks and no money, somebody who pins six habits a week and logs
  /// none — take a fortnight of real use to reach, so without a way to hand
  /// one in, the only version anybody ever sees is the empty one.
  final MoneySnapshot? debugSnapshot;

  @override
  State<MoneyHabitsScreen> createState() => _MoneyHabitsScreenState();
}

class _MoneyHabitsScreenState extends State<MoneyHabitsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: MoneyHabitsTab.count,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, MoneyHabitsTab.count - 1),
    );
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
        // Collapsing the toolbar (not just trimming its padding) when this
        // is a tab. The "default toolbar height, no extra title padding"
        // version still cost a full ~56px toolbar row *plus* this 52px tab
        // strip stacked under MainNavigation's own ~60px top bar — three
        // bands of chrome before any real content, which is the "top bit is
        // very expanded" complaint. The title was redundant with that top
        // bar's already-highlighted "Daily" pill, so as a tab there is
        // nothing worth spending the toolbar row on: it collapses to 0 and
        // only the tab strip below remains. Pushed as a standalone route
        // there is no pill above saying "Daily" for the title to duplicate,
        // so the full toolbar (and its title) comes back.
        toolbarHeight: asTab ? 0 : kToolbarHeight,
        backgroundColor: AppTheme.deepForest,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        // as a tab theres nothing to go back *to* so the arrow would just
        // be a dead button
        automaticallyImplyLeading: !asTab,
        title: asTab
            ? null
            : Text(
                'Money Habits',
                style: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
              ),
        // A taller strip than `kTextTabBarHeight`, because these tabs are a
        // pill with an icon *beside* a word rather than a Material label with
        // an icon stacked over it. See [_HabitTab].
        bottom: PreferredSize(
          // isScrollable already lets the tabs run off-screen on a narrow
          // phone but with no visible thumb theres no hint that "My Jar" is
          // even reachable by swiping. scrollbar makes the overflow
          // discoverable instead of just silently being there
          preferredSize: const Size.fromHeight(52),
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
              // A filled pill rather than an underline.
              //
              // The default 3px underline is a Material convention sitting in
              // the middle of a pixel-art game, and against six scrollable
              // tabs it is also the weakest possible "you are here" — a
              // hairline under one word in a row that scrolls. The pill is the
              // same shape the bottom bar uses for its active tab, so the two
              // places in the app that say "this one" now say it the same way.
              indicator: BoxDecoration(
                color: AppTheme.greenPrimary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppTheme.greenPrimary.withValues(alpha: 0.55),
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(999),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.pixelifySans(fontWeight: FontWeight.w700),
              // Icon + word rather than a bare word: "Track" and "Activity"
              // are close enough in meaning that the labels alone did not
              // tell a first-time user which one listed habits and which
              // one logged them.
              tabs: const [
                _HabitTab(Icons.today_rounded, 'Today'),
                _HabitTab(Icons.check_circle_outline_rounded, 'My Week'),
                // Was "Find/Create Habits", which was three times the width
                // of every other tab and carried a slash in it. A slash in a
                // label is two labels that could not agree, and in a strip of
                // six it made the whole row scroll for one tab's sake. The
                // page that lists habits and lets you make one is "Habits".
                _HabitTab(Icons.search_rounded, 'Habits'),
                _HabitTab(Icons.flag_rounded, 'Challenges'),
                _HabitTab(Icons.savings_rounded, 'My Jar'),
                _HabitTab(Icons.insights_rounded, 'Coach'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            TodayTab(
              onNavSelected: widget.onNavSelected,
              onOpenInnerTab: (tab) => _tabController.animateTo(tab),
            ),
            const _TrackTab(),
            const _ActivityTab(),
            const _ChallengesTab(),
            const _JarTab(),
            CoachReportView(snapshot: widget.debugSnapshot),
          ],
        ),
      ),
    );
  }
}

// ==================== Track ====================

/// The habit grid: what is pinned, and which of them were logged this week.
///
/// The daily-challenge minigame used to lead this tab, which put "Today's
/// Challenge" at the top of a screen about the *week* and left the Today tab
/// with nothing to lead with. It lives on Today now — see [DailyChallengeCard].
class _TrackTab extends StatelessWidget {
  const _TrackTab();

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<MoneyHabitController>();
    final totals = habits.lifetimeTotals;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
          style: GoogleFonts.pixelifySans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
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
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
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
            'Tap "Habits" above to pick your first one.',
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
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    const steps = <({int n, IconData icon, String title, String body})>[
      (
        n: 1,
        icon: Icons.search_rounded,
        title: 'Pick a habit',
        body: 'Open "Habits" and choose a few that are meaningful and doable.',
      ),
      (
        n: 2,
        icon: Icons.check_circle_rounded,
        title: 'Log it each day',
        body:
            'Tap today\'s circle under "This week". Each day builds consistency!',
      ),
      (
        n: 3,
        icon: Icons.savings_rounded,
        title: 'Fill your jar',
        body: 'Every completion adds points. The jar grows as they add up.',
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
              Icon(Icons.lightbulb_rounded, color: _panelMint, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: FittedLabel(
                  'How this works',
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
                    color: _stepChip.fill,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.greenPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${step.n}',
                    style: AppTheme.numeric(
                      // Mint on a mint wash over a mint-lit panel: the step
                      // numbers measured 2.39:1, which on a "how this works"
                      // explainer is the one place you cannot afford it.
                      color: _stepChip.ink,
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
                          Icon(step.icon, size: 15, color: _panelMint),
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedLabel(
                              step.title,
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
  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
  });

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
          Text(
            value,
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
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
            child: Text(
              habit.title,
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove from tracker',
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white54,
              size: 18,
            ),
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
  bool _showCustomCreator = false;
  final GlobalKey<FormState> _customFormKey = GlobalKey<FormState>();
  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _customBlurbController = TextEditingController();
  final TextEditingController _customAmountController = TextEditingController();

  // Explicit controller, shared with the Scrollbar below. A Scrollbar with
  // no controller binds to the ambient PrimaryScrollController — which the
  // tab's own vertical ListView already claims — so the thumb would track
  // the wrong axis (and crashes outright with thumbVisibility, since every
  // offstage tab in the IndexedStack has a position attached to it too).
  final ScrollController _filterScroll = ScrollController();

  @override
  void dispose() {
    _filterScroll.dispose();
    _customTitleController.dispose();
    _customBlurbController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<MoneyHabitController>();
    final list = _showCustomCreator
        ? habits.customHabits
        : habits.allAvailableHabits
              .where((t) => _filter == null || t.category == _filter)
              .toList();

    return Column(
      children: [
        Padding(
          // Bottom padding trimmed 8 -> 2 to pay for the scrollbar's own
          // 8px lane, so adding it costs no extra vertical space and the
          // top of this tab stays as open as it was.
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          // NOT thumbVisibility: true. This tab lives inside a TabBarView,
          // which builds the adjacent tab *offstage* — so on the frame this
          // is built but not laid out, the controller has no attached
          // ScrollPosition yet, and a persistent thumb has nothing to
          // measure against:
          //
          //   Scrollbar's ScrollController has no ScrollPosition attached
          //
          // which threw on every open of the Daily tab. Default mode has no
          // such requirement — it tracks scroll notifications and fades the
          // thumb in during a drag, which is still the discoverability cue
          // this row needs.
          child: Scrollbar(
            controller: _filterScroll,
            thickness: 3,
            radius: const Radius.circular(3),
            child: SingleChildScrollView(
              controller: _filterScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: !_showCustomCreator && _filter == null,
                    onTap: () => setState(() {
                      _showCustomCreator = false;
                      _filter = null;
                    }),
                  ),
                  for (final category in HabitCategory.values) ...[
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: category.label,
                      selected: !_showCustomCreator && _filter == category,
                      accent: category.accent,
                      onTap: () => setState(() {
                        _showCustomCreator = false;
                        _filter = category;
                      }),
                    ),
                  ],
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Create your own',
                    selected: _showCustomCreator,
                    accent: AppTheme.greenPrimary,
                    onTap: () => setState(() {
                      _showCustomCreator = true;
                      _filter = null;
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              if (_showCustomCreator) ...[
                _CreateHabitCard(
                  formKey: _customFormKey,
                  titleController: _customTitleController,
                  blurbController: _customBlurbController,
                  amountController: _customAmountController,
                  onCreate: () => _createCustomHabit(context, habits),
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  Text(
                    'Your custom habits will show up here after you create them.',
                    style: GoogleFonts.quicksand(color: AppTheme.textMuted),
                  )
                else
                  Text(
                    'Your habits',
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              for (final habit in list) ...[
                _ActivityCard(
                  habit: habit,
                  saved: habits.savedHabits.any((h) => h.id == habit.id),
                  onTap: () => _openHabitSheet(context, habit, habits),
                ),
                const SizedBox(height: 10),
              ],
            ],
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
      builder: (sheetContext) =>
          _HabitDetailSheet(habit: habit, habits: habits),
    );
  }

  Future<void> _createCustomHabit(
    BuildContext context,
    MoneyHabitController habits,
  ) async {
    if (!(_customFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = double.parse(
      _customAmountController.text.replaceAll(RegExp(r'[\$,]'), '').trim(),
    );
    await habits.createCustomHabit(
      title: _customTitleController.text,
      blurb: _customBlurbController.text,
      moneySavedUsd: amount,
    );

    _customTitleController.clear();
    _customBlurbController.clear();
    _customAmountController.clear();
    if (context.mounted) {
      GameToast.show(context, message: 'Custom habit created and saved');
    }
  }
}

class _CreateHabitCard extends StatelessWidget {
  const _CreateHabitCard({
    required this.formKey,
    required this.titleController,
    required this.blurbController,
    required this.amountController,
    required this.onCreate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController blurbController;
  final TextEditingController amountController;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.getPuffyDecoration(
        accent: AppTheme.greenPrimary,
        fillColor: AppTheme.panelStrong,
        restAlpha: 0.16,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_rounded, color: _panelMint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Create your own',
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Can\'t find a habit for your unique financial situation? Create your own!',
              style: GoogleFonts.pixelifySans(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 14),
            TextFormField(
              controller: titleController,
              textInputAction: TextInputAction.next,
              maxLength: 40,
              style: GoogleFonts.pixelifySans(color: Colors.white),
              decoration: _customInputDecoration('Title'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Add a title.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: blurbController,
              textInputAction: TextInputAction.next,
              minLines: 2,
              maxLines: 3,
              maxLength: 120,
              style: GoogleFonts.pixelifySans(color: Colors.white),
              decoration: _customInputDecoration('Description'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Add a description.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              style: GoogleFonts.pixelifySans(color: Colors.white),
              decoration: _customInputDecoration(
                'Money saved',
              ).copyWith(prefixText: '\$ '),
              validator: (value) {
                final amount = double.tryParse(
                  (value ?? '').replaceAll(RegExp(r'[\$,]'), '').trim(),
                );
                if (amount == null || amount <= 0) {
                  return 'Enter a savings amount.';
                }
                if (amount > 10000) {
                  return 'Use a smaller daily amount.';
                }
                return null;
              },
              onFieldSubmitted: (_) => onCreate(),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.greenPrimary,
                  foregroundColor: AppTheme.deepForest,
                ),
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.quicksand(color: AppTheme.textMuted),
      counterStyle: GoogleFonts.quicksand(color: Colors.white38, fontSize: 10),
      filled: true,
      fillColor: AppTheme.panel,
      errorStyle: GoogleFonts.quicksand(color: const Color(0xFFFFA39A)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.greenPrimary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: Color(0xFFFF8474)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: Color(0xFFFF8474)),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent,
  });

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
          border: Border.all(
            color: color.withValues(alpha: selected ? 1 : 0.4),
          ),
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

/// A circular thumbnail for a habit.
///
/// **Asked for as:** *"finishing adding the images to the daily screens."*
/// Only 6 of the 16 cards had a picture at all, and each of those was a
/// hotlinked Wikimedia photo — a stock image dropped into a hand-drawn pixel
/// game, and one that needed the network to show at all. Every habit now has
/// its own badge, drawn in the app's own palette by
/// `tool/make_habit_icons.py`, bundled with the app rather than fetched.
///
/// [HabitTemplate.photoUrl] still exists and is still tried, for a real photo
/// a future habit is given on purpose, but it is no longer what most of the
/// catalog leans on, and nothing here depends on the network to render.
class _HabitPhoto extends StatelessWidget {
  const _HabitPhoto({required this.habit, required this.size});

  final HabitTemplate habit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/money_habits/${habit.id}.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          final photoUrl = habit.photoUrl;
          if (photoUrl == null) return _iconFallback();
          return Image.network(
            photoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _iconFallback();
            },
            errorBuilder: (context, error, stack) => _iconFallback(),
          );
        },
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
  const _ActivityCard({
    required this.habit,
    required this.saved,
    required this.onTap,
  });

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
        decoration: AppTheme.getPuffyDecoration(
          accent: habit.category.accent,
          restAlpha: 0.14,
        ),
        child: Row(
          children: [
            _HabitPhoto(habit: habit, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    habit.blurb,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.quicksand(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (saved)
              Icon(
                Icons.bookmark_rounded,
                color: habit.category.accent,
                size: 20,
              ),
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
    _units =
        widget.habits.savedHabitParams[widget.habit.id] ??
        widget.habit.adjustable?.defaultValue ??
        1;
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final adjustable = habit.adjustable;
    final impact = habit.impactFor(_units);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
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
                child: Text(
                  habit.title,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            habit.blurb,
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (adjustable != null) ...[
            Text(
              adjustable.label,
              style: GoogleFonts.pixelifySans(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StepperButton(
                  icon: Icons.remove_rounded,
                  onTap: () => setState(
                    () => _units = (_units - adjustable.step).clamp(
                      adjustable.min,
                      adjustable.max,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    adjustable.unit == 'dollars'
                        ? '\$${_units.toStringAsFixed(_units % 1 == 0 ? 0 : 1)}'
                        : '${_units.toStringAsFixed(_units % 1 == 0 ? 0 : 1)} ${adjustable.unit}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StepperButton(
                  icon: Icons.add_rounded,
                  onTap: () => setState(
                    () => _units = (_units + adjustable.step).clamp(
                      adjustable.min,
                      adjustable.max,
                    ),
                  ),
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
                    await widget.habits.saveHabit(
                      habit,
                      paramValue: adjustable != null ? _units : null,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.bookmark_add_rounded),
                  label: const Text('Save to Home'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.greenPrimary,
                    foregroundColor: AppTheme.deepForest,
                  ),
                  onPressed: () async {
                    await widget.habits.completeTrackedHabit(habit);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      GameToast.show(
                        context,
                        message: 'Logged: ${habit.title}',
                      );
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
        decoration: BoxDecoration(
          color: AppTheme.panel,
          shape: BoxShape.circle,
        ),
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
        _MiniStat(
          label: 'Money saved',
          value: '\$${impact.moneySavedUsd.toStringAsFixed(2)}',
        ),
        _MiniStat(
          label: 'Smart choices',
          value: impact.choicesKept.toStringAsFixed(0),
        ),
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
          Text(
            value,
            style: GoogleFonts.pixelifySans(
              color: _panelMint,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.quicksand(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
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
          decoration: AppTheme.getPuffyDecoration(
            accent: challenge.category.accent,
            restAlpha: 0.18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    challenge.category.icon,
                    color: challenge.category.accent,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: GoogleFonts.pixelifySans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          challenge.subtitle,
                          style: GoogleFonts.quicksand(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                challenge.description,
                style: GoogleFonts.pixelifySans(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
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
              Text(
                '${(progress * 100).round()}% complete',
                style: GoogleFonts.quicksand(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              HabitChallengeRowItem(
                tasks: challenge.tasks,
                statusFor: (task) {
                  if (habits.completedChallengeTasks.contains(task.id)) {
                    return HabitRowStatus.completed;
                  }
                  if (habits.isChallengeTaskAvailable(task)) {
                    return HabitRowStatus.available;
                  }
                  return HabitRowStatus.locked;
                },
                onTaskTap: (task) async {
                  await habits.completeChallengeTask(task);
                  if (context.mounted) {
                    final title = task.template?.title ?? task.id;
                    GameToast.show(
                      context,
                      message: 'Challenge habit complete: $title',
                    );
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

/// The Jar tab: the screen that answers "is this working?".
///
/// Rebuilt because the old one was a scaled-up Material glyph, a bare
/// `LinearProgressIndicator` and a grey paragraph — three unrelated pieces
/// stacked with no shape to them. What it was missing was not decoration:
///
/// * **Where am I overall?** One bar toward the next stage says how far to the
///   next step and never how far through the whole thing you are.
/// * **What did this earn me?** The habit points were shown; the money and the
///   choices they came from were on another tab entirely.
/// * **What do I do now?** The closing paragraph was a sentence, not an
///   action, and it looked identical whether the player was on a streak or had
///   not logged anything in a fortnight.
class _JarTab extends StatelessWidget {
  const _JarTab();

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<MoneyHabitController>();
    final stage = habits.jarStage;
    final mood = habits.jarMood;
    final next = stage.next;
    final totals = habits.lifetimeTotals;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        // The jar itself, on its own tinted plinth so it reads as an object
        // in a scene rather than as an image floating on the page.
        Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            // Flat, at the middle of the fade it replaced: the shade the
            // contrast audit already measures the mood chips against.
            color: Color.lerp(
              Color.lerp(AppTheme.panelStrong, mood.color, 0.10),
              AppTheme.panel,
              0.5,
            ),
            border: Border.all(
              color: mood.color.withValues(alpha: 0.26),
              width: 1.5,
            ),
            boxShadow: AppTheme.ledgeShadow(mood.color, restAlpha: 0.18),
          ),
          child: Column(
            children: [
              SavingsJarWidget(
                stage: stage,
                mood: mood,
                // The real number, not a stage bucket. See
                // [MoneyHabitController.jarFill].
                fill: habits.jarFill,
                size: 210,
              ),
              const SizedBox(height: 10),
              FittedLabel(
                stage.label,
                style: GoogleFonts.pixelifySans(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _MoodPill(
                mood: mood,
                daysSince: habits.daysSinceJarActive,
                everActive: habits.jarEverActive,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // The whole ladder, not just the next rung.
        JarMilestones(stage: stage, xp: habits.jarXp),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.panel,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FittedLabel(
                      next == null ? 'Jar full' : 'Next: ${next.label}',
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    next == null
                        ? '${habits.jarXp} pts'
                        : '${habits.jarXp} / ${next.xpThreshold}',
                    style: GoogleFonts.pixelifySans(
                      color: _jarAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: stage.progressToNext(habits.jarXp),
                  minHeight: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor: const AlwaysStoppedAnimation(
                    AppTheme.greenPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                next == null
                    ? 'Every habit from here still counts — the totals below '
                          'keep climbing.'
                    : '${next.xpThreshold - habits.jarXp} more points to go.',
                style: GoogleFonts.quicksand(
                  color: AppTheme.textMuted,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // What the points actually represent. These numbers existed on
        // another tab; the jar is where a player looks to feel good about
        // them, so they belong here too.
        Row(
          children: [
            Expanded(
              child: _JarStat(
                icon: Icons.payments_rounded,
                label: 'Saved',
                value: '\$${totals.moneySavedUsd.toStringAsFixed(0)}',
                accent: AppTheme.greenPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _JarStat(
                icon: Icons.check_circle_rounded,
                label: 'Good calls',
                value: '${totals.choicesKept.round()}',
                accent: const Color(0xFF69C6FF),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _JarNextStep(
          mood: mood,
          daysSince: habits.daysSinceJarActive,
          everActive: habits.jarEverActive,
        ),
      ],
    );
  }
}

/// Mint that stays readable on the jar card. See [AppTheme.legibleOn].
final _jarAccent = AppTheme.legibleOn(const Color(0xFFFFD45C), AppTheme.panel);

class _MoodPill extends StatelessWidget {
  const _MoodPill({
    required this.mood,
    required this.daysSince,
    required this.everActive,
  });

  final JarMood mood;
  final int daysSince;

  /// False for a player who has never logged anything, whose
  /// [daysSince] is the 999 sentinel rather than a real gap.
  final bool everActive;

  /// How long since the jar last moved, in the coarsest unit that still
  /// answers the question.
  ///
  /// It used to read "last logged 999 days ago", which is three problems in
  /// one line: the pill is 201px wide on a small phone and that string wants
  /// 260, "last logged" repeats what the pill already says, and a raw day
  /// count stops meaning anything somewhere around a fortnight. Nobody reads
  /// 340 and thinks "eleven months" — they read it as "a lot".
  String get _detail {
    if (!everActive) return 'not started yet';
    if (daysSince <= 0) return 'today';
    if (daysSince == 1) return 'yesterday';
    if (daysSince < 14) return '$daysSince days ago';
    if (daysSince < 60) return '${daysSince ~/ 7} weeks ago';
    if (daysSince < 365) return '${daysSince ~/ 30} months ago';
    return 'over a year ago';
  }

  @override
  Widget build(BuildContext context) {
    // Opaque fill and a measured ink — the mood colors run from mint to a
    // pale amber, and amber-on-amber was one of the contrast audit's finds.
    final chip = AppTheme.tintedChip(mood.color, on: AppTheme.panelStrong);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: mood.color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 13, color: chip.ink),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              // The label alone said "Slipping" with no indication of how far
              // — which is a judgement without a fact attached to it.
              '${mood.label} · $_detail',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.pixelifySans(
                color: chip.ink,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JarStat extends StatelessWidget {
  const _JarStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // Full AA, not the large-text allowance: the value on this card is 20px
    // and bold, but the little icon beside the label is 15px, and the ink is
    // shared between them. Sizing the target to the largest thing that uses
    // a color is how small icons end up under the bar.
    final chip = AppTheme.tintedChip(accent, alpha: 0.14);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: chip.ink),
              const SizedBox(width: 6),
              Flexible(
                child: FittedLabel(
                  label,
                  style: GoogleFonts.quicksand(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedLabel(
            value,
            style: GoogleFonts.pixelifySans(
              color: chip.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The closing card, which now says what to do rather than what is true.
class _JarNextStep extends StatelessWidget {
  const _JarNextStep({
    required this.mood,
    required this.daysSince,
    required this.everActive,
  });

  final JarMood mood;
  final int daysSince;

  /// False for a player who has never logged anything, whose [daysSince] is
  /// the 999 sentinel rather than a real gap. Somebody who has not started is
  /// not somebody who has lapsed.
  final bool everActive;

  @override
  Widget build(BuildContext context) {
    final slipping = mood == JarMood.slipping;
    final accent = slipping ? AppTheme.warningOrange : AppTheme.greenPrimary;
    final chip = AppTheme.tintedChip(accent, alpha: 0.12, target: 3.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: chip.fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            slipping ? Icons.restart_alt_rounded : Icons.trending_up_rounded,
            color: chip.ink,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slipping ? 'Pick it back up' : 'Keep it going',
                  style: GoogleFonts.pixelifySans(
                    color: chip.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  !everActive
                      ? 'Nothing in the jar yet. Save one habit on Track and '
                            'log it once — that is the whole of getting '
                            'started.'
                      : slipping
                      ? 'It has been $daysSince ${daysSince == 1 ? 'day' : 'days'}. '
                            'One habit on Track is enough to restart the '
                            'streak — the jar keeps everything you have '
                            'already put in.'
                      : 'Log a habit on Track, or take on a challenge on '
                            'Activity. Both drop points straight into the jar.',
                  style: GoogleFonts.quicksand(
                    color: AppTheme.textMuted,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One tab in the Daily strip: an icon *beside* a word, inside a pill.
///
/// Material's default stacks the icon over the label, which on six scrollable
/// tabs makes a strip that is tall, narrow-columned and still scrolls. Side by
/// side is wider per tab and shorter overall, and it lets the selected pill be
/// a shape rather than a hairline — the same shape the bottom bar uses, so the
/// two "you are here" markers in the app finally agree.
class _HabitTab extends StatelessWidget {
  const _HabitTab(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Tab(
    height: 40,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 7), Text(label)],
      ),
    ),
  );
}
