import 'package:flutter/foundation.dart';

import '../models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import 'user_stats_controller.dart';

/// Owns the Money Habits feature's derived state (saved habits, weekly log,
/// jar stage/mood) the same way [DailyPlanController] owns the daily plan:
/// it wraps [UserStatsController], listens for stats changes, and
/// recomputes everything from `stats.spendingHabits` — there is no separate
/// persistence path. See docs/MONEY_HABITS_FEATURE.md for the full
/// data-flow reference.
class MoneyHabitController extends ChangeNotifier {
  MoneyHabitController(this._stats) {
    _stats.addListener(_onStatsChanged);
  }

  final UserStatsController _stats;

  void _onStatsChanged() => notifyListeners();

  @override
  void dispose() {
    _stats.removeListener(_onStatsChanged);
    super.dispose();
  }

  // ---------------- Derived from UserStats (always in sync) ----------------

  List<HabitTemplate> get customHabits => _stats.stats.customHabitTemplates;

  List<HabitTemplate> get allAvailableHabits => <HabitTemplate>[
    ...habitCatalog,
    ...customHabits,
  ];

  List<HabitTemplate> get savedHabits => _stats.stats.savedHabitIds
      .map((id) => habitTemplateById(id, customHabits: customHabits))
      .whereType<HabitTemplate>()
      .toList(growable: false);

  Map<String, double> get savedHabitParams => _stats.stats.savedHabitParams;

  double paramValueFor(HabitTemplate template) =>
      savedHabitParams[template.id] ?? template.adjustable?.defaultValue ?? 1;

  Map<String, List<String>> get weeklyLog => _stats.stats.habitWeeklyLog;

  Map<String, int> get activityCalendar => _stats.stats.habitActivityCalendar;

  HabitImpact get lifetimeTotals => _stats.stats.habitTotals;

  Map<String, HabitImpact> get monthlyTotals => _stats.stats.habitMonthly;

  /// This month's totals vs. last month's, keyed off the local calendar —
  /// null for "last month" the first month an account is active.
  ({HabitImpact thisMonth, HabitImpact? lastMonth}) get monthComparison {
    final now = DateTime.now();
    final thisKey = HabitDateKeys.keyFor(now).substring(0, 7);
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastKey = HabitDateKeys.keyFor(lastMonthDate).substring(0, 7);
    final monthly = monthlyTotals;
    return (
      thisMonth: monthly[thisKey] ?? HabitImpact.zero,
      lastMonth: monthly[lastKey],
    );
  }

  int get jarXp => _stats.stats.jarXp;

  JarStage get jarStage => JarStage.forXp(jarXp);

  JarMood get jarMood => JarMood.forDaysSinceActive(
    HabitDateKeys.daysSince(_stats.stats.jarLastActive),
  );

  bool isSavedToday(String habitId) {
    final today = HabitDateKeys.todayKey();
    return (weeklyLog[today] ?? const <String>[]).contains(habitId);
  }

  Set<String> get completedChallengeTasks =>
      _stats.stats.completedChallengeTasks.toSet();

  bool isChallengeTaskAvailable(ChallengeTask task) {
    final done = completedChallengeTasks;
    return task.prerequisites.every(done.contains);
  }

  // ---------------- Mutations — all delegate to UserStatsController ----------------

  Future<void> saveHabit(HabitTemplate template, {double? paramValue}) =>
      _stats.saveHabit(template.id, paramValue: paramValue);

  Future<void> createCustomHabit({
    required String title,
    required String blurb,
    required double moneySavedUsd,
  }) => _stats.createCustomHabit(
    title: title,
    blurb: blurb,
    moneySavedUsd: moneySavedUsd,
  );

  Future<void> unsaveHabit(String habitId) => _stats.unsaveHabit(habitId);

  Future<void> completeTrackedHabit(HabitTemplate template) =>
      _stats.completeHabit(template, units: paramValueFor(template));

  Future<void> completeChallengeTask(
    ChallengeTask challengeTask, {
    double? units,
  }) async {
    final template = challengeTask.template;
    if (template == null) return;

    await _stats.completeHabit(
      template,
      units: units,
      challengeTaskId: challengeTask.id,
    );
  }

  double challengeProgress(HabitChallenge challenge) {
    if (challenge.tasks.isEmpty) return 0;
    final done = completedChallengeTasks;
    final completedCount = challenge.tasks
        .where((t) => done.contains(t.id))
        .length;
    return completedCount / challenge.tasks.length;
  }
}
