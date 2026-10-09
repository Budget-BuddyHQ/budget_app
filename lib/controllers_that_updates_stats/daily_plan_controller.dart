import 'package:flutter/foundation.dart';

import '../models_Like_Skins_and_lessons_templates/daily_quest.dart';
import '../screens_minigames_admin_etc/Gameplay/core_bottom_pages/arcade_catalog.dart';
import 'user_stats_controller.dart';

/// Owns the once-a-day plan: builds it from the player's state, tracks quest
/// completion, and advances the streak.
///
/// Reads and writes through [UserStatsController] so completion survives a
/// restart and syncs to Supabase like everything else. Kept separate from the
/// stats controller so the daily-plan logic stays readable on its own.
class DailyPlanController extends ChangeNotifier {
  DailyPlanController(this._stats) {
    _stats.addListener(_onStatsChanged);
    _rebuild();
  }

  final UserStatsController _stats;
  static const DailyPlanBuilder _builder = DailyPlanBuilder();

  DailyPlan? _plan;
  DailyPlan? get plan => _plan;

  void _onStatsChanged() => _rebuild();

  /// Today's local date as a stable yyyy-mm-dd key.
  static String _todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  void _rebuild() {
    final stats = _stats.stats;
    final today = _todayKey();

    // A plan is per-day. On a new day the completed set resets to empty; the
    // saved completions from a previous day no longer apply.
    final sameDay = stats.dailyPlanDateKey == today;
    final completed = sameDay ? stats.dailyQuestsDone : <String>{};

    final plan = _builder.build(
      dateKey: today,
      completedIds: completed,
      streakDays: stats.dailyStreak,
      weakSkills: stats.weakSkills,
      completedLessons: stats.completedLessons.toSet(),
      arcadePlays: stats.arcadePlays,
      activeArcadeGameIds: arcadeCatalog.map((g) => g.id).toList(),
      savedHabitIds: stats.savedHabitIds,
      habitsDoneToday: (stats.habitWeeklyLog[today] ?? const <String>[])
          .toSet(),
      dailyChallengeDone: _stats.isTodayChallengeCompleted,
      bestScore: (game) => stats.bestArcadeScore(game) ?? 0,
      // Keeps the learning quest age-appropriate now that the curriculum
      // list is in chronological order — without this an adult's daily
      // quest would be "What Is Money?" (ages 4-6), which is now genuinely
      // the first uncompleted lesson in the list. Null when the player
      // never shared an age, which falls back to plain list order.
      readerStage: stats.ageBand.recommendedStage,
    );

    _plan = plan;
    notifyListeners();
  }

  /// Marks a quest complete, persists it, and advances the streak the first
  /// time any quest is finished on a new day. Idempotent — completing the same
  /// quest twice does nothing.
  Future<void> completeQuest(String questId) async {
    final plan = _plan;
    if (plan == null || plan.isDone(questId)) {
      return;
    }
    final stats = _stats.stats;
    final today = _todayKey();

    final done = <String>{...plan.completedIds, questId};

    // Advance the streak once per day, on the first completion. If the last
    // streak day was yesterday it grows; if there was a gap it resets to 1.
    var streak = stats.dailyStreak;
    final lastStreakDay = stats.dailyStreakDateKey;
    final firstToday = lastStreakDay != today;
    if (firstToday) {
      streak = _isYesterday(lastStreakDay, today) ? streak + 1 : 1;
    }

    await _stats.updateDailyPlanProgress(
      dateKey: today,
      completedQuestIds: done.toList(),
      streak: streak,
      streakDateKey: today,
    );
  }

  static bool _isYesterday(String candidate, String today) {
    final t = DateTime.tryParse(today);
    final c = DateTime.tryParse(candidate);
    if (t == null || c == null) {
      return false;
    }
    return t.difference(c).inDays == 1;
  }

  @override
  void dispose() {
    _stats.removeListener(_onStatsChanged);
    super.dispose();
  }
}
