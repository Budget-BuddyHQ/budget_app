import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/daily_plan_controller.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../models_Like_Skins_and_lessons_templates/daily_quest.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';
import '../../../themes_colors/app_theme.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../dashboard/daily_plan_card.dart';
import '../minigames_pages/react_challenge_screen.dart';

/// The first thing the Daily tab shows: what to do today, in order.
///
/// **What was actually confusing.** "Daily" named three unrelated things at
/// once and showed only one of them. The top strip's *Daily* button opened a
/// screen titled **Money Habits** whose five tabs were My Week, Find/Create
/// Habits, Challenges, My Jar and Coach — not one of them called Today, and
/// four of them about a habit tracker rather than about today. Home had a
/// separate *Daily* button that went to the same tab, and a card above it
/// that pushed a **second live copy** of the same screen on top of the one
/// already sitting in the tab stack. Meanwhile [DailyPlanController] was
/// wired up in `main.dart`, rebuilt a full ordered plan on every stats
/// change, and persisted a streak — and [DailyPlanCard], whose own doc
/// comment calls it "the home screen's spine", was **referenced by nothing**.
/// The one screen designed to answer "what do I do today" had never been
/// mounted.
///
/// So this tab is not new UI invented to fill a gap; it is the gap's
/// original occupant, finally put on screen, with the habit tracker moved
/// behind it where it belongs.
///
/// **What ticking a quest means.** Arriving at the surface, not finishing it
/// — and that is a deliberate limit, not an oversight. Real completion is
/// only checkable for some of these: a logged habit is recorded per day, but
/// `arcadePlays` is a lifetime counter with no date on it, and the learning
/// slot always points at the *next uncompleted* lesson, so finishing it
/// makes the quest's own id disappear rather than tick. Rather than invent
/// per-quest tracking, the plan counts the day you showed up, which is what
/// the streak underneath it has always meant.
class TodayTab extends StatelessWidget {
  const TodayTab({
    super.key,
    required this.onNavSelected,
    required this.onOpenInnerTab,
  });

  /// Switches the app's main tab. Null when this screen was pushed as a route
  /// rather than hosted as the Daily tab, in which case there is no tab bar
  /// to drive and quests fall back to named routes.
  final ValueChanged<int>? onNavSelected;

  /// Switches to one of this screen's own tabs — where the habit quest goes.
  final ValueChanged<int> onOpenInnerTab;

  void _goToTab(BuildContext context, int tab, String fallbackRoute) {
    final selector = onNavSelected;
    if (selector != null) {
      selector(tab);
      return;
    }
    Navigator.of(context).pushNamed(fallbackRoute);
  }

  Future<void> _openQuest(BuildContext context, DailyQuest quest) async {
    // Recorded before navigating. Switching a tab does not return a future,
    // so there is no "came back" moment to hang this on.
    await context.read<DailyPlanController>().completeQuest(quest.id);
    if (!context.mounted) return;

    switch (quest.surface) {
      case QuestSurface.academyLesson:
      case QuestSurface.academyPractice:
        _goToTab(context, AppTabIndex.academy, '/lessons');
      case QuestSurface.arcade:
        _goToTab(context, AppTabIndex.minigames, '/minigames');
      case QuestSurface.adventure:
        _goToTab(context, AppTabIndex.adventure, '/main-gameplay');
      case QuestSurface.moneyHabit:
        // Stays on this screen — the habit tracker is two tabs across, not a
        // different destination.
        onOpenInnerTab(MoneyHabitsTab.week);
    }
  }

  Future<void> _launchDailyChallenge(BuildContext context) async {
    final userStatsController = context.read<UserStatsController>();
    final stats = userStatsController.stats;

    final result = await Navigator.of(context).push<ReactGameCloseResult>(
      MaterialPageRoute(
        builder: (_) => ReactChallengeScreen(
          gameId: 'daily_budget_battle',
          difficulty: 'normal',
          playerLevel: stats.level,
          userId: stats.id,
          isCompleted: userStatsController.isTodayChallengeCompleted,
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
      message: '+${result.goldEarned} gold | +${result.xpEarned} XP',
      icon: Icons.workspace_premium_rounded,
      accent: const Color(0xFFFFD45C),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<UserStatsController>();
    final plan = context.watch<DailyPlanController>().plan;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreakBanner(
          streakDays: plan?.streakDays ?? 0,
          lastKeptDateKey: stats.stats.dailyStreakDateKey,
        ),
        const SizedBox(height: 16),
        DailyPlanCard(
          showStreak: false,
          onOpenQuest: (quest) => _openQuest(context, quest),
        ),
        const SizedBox(height: 16),
        DailyChallengeCard(
          isCompleted: stats.isTodayChallengeCompleted,
          onPlay: () => _launchDailyChallenge(context),
          onPlayAgain: () => _launchDailyChallenge(context),
        ),
      ],
    );
  }
}

/// The streak, as a week of days rather than as a number.
///
/// **Why the week is derived and not stored.** A streak of N days ending on
/// `lastKeptDateKey` says precisely which days were kept: the N days up to
/// and including that one. Nothing else needs recording, and there is no
/// second copy of the truth to fall out of step with the counter — a real
/// risk here, because this app already carries two different streaks (this
/// one, and the habit streak on My Jar) and they are not the same thing.
///
/// A bare "3" cannot show a player that they are one day from a week, or
/// that yesterday is the one they missed. Seven cells can.
class StreakBanner extends StatelessWidget {
  const StreakBanner({
    super.key,
    required this.streakDays,
    required this.lastKeptDateKey,
    this.today,
  });

  final int streakDays;

  /// yyyy-mm-dd of the most recent day the streak was kept, or empty.
  final String lastKeptDateKey;

  /// Injectable so the "which cell is today" logic is testable without
  /// waiting for midnight.
  final DateTime? today;

  static const Color _flame = Color(0xFFFF8A5B);

  static const List<String> _initials = <String>[
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  /// The seven days ending today, oldest first, each flagged with whether the
  /// streak covers it.
  static List<({DateTime day, bool kept})> weekFor({
    required int streakDays,
    required String lastKeptDateKey,
    required DateTime today,
  }) {
    final anchor = DateTime.tryParse(lastKeptDateKey);
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));
    return <({DateTime day, bool kept})>[
      for (var i = 0; i < 7; i++)
        () {
          final day = start.add(Duration(days: i));
          if (anchor == null || streakDays <= 0) {
            return (day: day, kept: false);
          }
          final gap = DateTime(
            anchor.year,
            anchor.month,
            anchor.day,
          ).difference(day).inDays;
          // Inside the run means: on or before the last kept day, and no
          // further back than the run is long.
          return (day: day, kept: gap >= 0 && gap < streakDays);
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final now = today ?? DateTime.now();
    final week = weekFor(
      streakDays: streakDays,
      lastKeptDateKey: lastKeptDateKey,
      today: now,
    );
    final active = streakDays > 0;
    final keptToday = week.isNotEmpty && week.last.kept;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.getPuffyDecoration(
        accent: active ? _flame : AppTheme.greenPrimary,
        fillColor: const Color(0xFF1B3B30),
        restAlpha: 0.18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (active ? _flame : Colors.white).withValues(
                    alpha: active ? 0.16 : 0.06,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 28,
                  color: active ? _flame : Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedLabel(
                      active ? '$streakDays day streak' : 'Start your streak',
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Deliberately *not* "N of M done" — the plan card
                      // directly below says exactly that, and the same
                      // figure twice within 150px is how a screen starts
                      // reading as a form. This line is about the streak;
                      // that one is about the list.
                      !active
                          ? 'Finish anything below to start one.'
                          : keptToday
                          ? 'Today is in the bag. See you tomorrow.'
                          : 'Do one thing today to keep it alive.',
                      style: GoogleFonts.quicksand(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Capped rather than stretched. Seven equal shares of a desktop
          // card is a 127px box holding one letter and a tick, which reads
          // as an empty table; at a phone width the cap never binds and the
          // strip fills the card as before.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 414),
            child: Row(
              children: [
                for (var i = 0; i < week.length; i++) ...[
                  Expanded(
                    child: _DayCell(
                      initial: _initials[week[i].day.weekday - 1],
                      kept: week[i].kept,
                      isToday: i == week.length - 1,
                    ),
                  ),
                  if (i != week.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.initial,
    required this.kept,
    required this.isToday,
  });

  final String initial;
  final bool kept;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    const flame = StreakBanner._flame;
    return Semantics(
      label: kept ? 'Kept' : 'Missed',
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: kept
              ? flame.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? Colors.white.withValues(alpha: 0.45)
                : (kept
                      ? flame.withValues(alpha: 0.42)
                      : Colors.white.withValues(alpha: 0.08)),
            width: isToday ? 1.6 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              initial,
              style: GoogleFonts.pixelifySans(
                color: kept ? flame : Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Icon(
              kept ? Icons.check_rounded : Icons.remove_rounded,
              size: 13,
              color: kept ? flame : Colors.white.withValues(alpha: 0.22),
            ),
          ],
        ),
      ),
    );
  }
}

/// The React Challenge minigame, on the tab its name refers to.
///
/// Moved off My Week, which is the habit grid and has nothing to do with it,
/// and un-hardcoded on the way: the call site used to pass a literal
/// `isCompleted: false` while the controller sitting right above it exposed
/// [UserStatsController.isTodayChallengeCompleted], so the entire "Challenge
/// Completed!" half of this widget was unreachable — a player who had
/// already played was told to go and play.
class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({
    super.key,
    required this.onPlay,
    this.isCompleted = false,
    this.onPlayAgain,
  });

  final VoidCallback onPlay;
  final bool isCompleted;
  final VoidCallback? onPlayAgain;

  static const Color _done = Color(0xFF4CAF50);
  static const Color _todo = Color(0xFFFFD45C);

  @override
  Widget build(BuildContext context) {
    final accent = isCompleted ? _done : _todo;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        (isCompleted ? (onPlayAgain ?? onPlay) : onPlay)();
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.getPuffyDecoration(
          accent: accent,
          fillColor: isCompleted
              ? const Color(0xFF1E3320)
              : const Color(0xFF3B301A),
          restAlpha: 0.18,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.bolt_rounded,
                color: accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedLabel(
                    isCompleted ? 'Challenge cleared' : "Today's Challenge",
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted
                        ? 'Gold and XP claimed. Play again for practice.'
                        : 'Test your budgeting reflexes — gold and XP '
                              'either way.',
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
            Icon(Icons.chevron_right_rounded, color: accent, size: 30),
          ],
        ),
      ),
    );
  }
}

/// The Daily screen's own tabs, by name.
///
/// Named because a "Today" tab was inserted at the front and every literal
/// index in the app and its tests silently shifted by one — `initialTab: 3`
/// meaning My Jar in four different test files is exactly the sort of thing
/// that keeps passing while pointing somewhere else.
abstract final class MoneyHabitsTab {
  static const int today = 0;
  static const int week = 1;
  static const int find = 2;
  static const int challenges = 3;
  static const int jar = 4;
  static const int coach = 5;

  static const int count = 6;
}
