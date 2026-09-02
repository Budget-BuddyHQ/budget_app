import '../services_backend_and_other_services/supabase_service.dart';
import 'finance_concepts.dart';
import 'lesson.dart';
import 'lesson_data.dart';
import 'money_analyzer.dart';
import 'money_habit_models.dart';
import 'town_spot_models.dart';

/// Builds the analyser's input out of what the app has actually stored.
///
/// Kept out of `money_analyzer.dart` on purpose. The analyser is the *rules*
/// and has no idea where a number came from, which is what lets it be tested
/// against a player who has pinned six habits and logged one — a state that
/// takes a fortnight of real use to reach and about four lines to describe.
/// This file is the only part that knows about storage, and it has no
/// judgement in it.

/// Which big idea each unit is mostly about.
///
/// The Academy records accuracy per *node*, and nodes are not tagged with a
/// [FinanceConcept] — questions carry a `skill` string instead, which maps to
/// sources rather than to concepts. Rather than invent a tag on every
/// question, this maps at the unit level, which is the level a unit is
/// actually written at: one unit, one big idea, thirteen of them.
///
/// It is an approximation and worth being honest about — Unit 7 covers credit
/// scores *and* interest costs, and lands here as `creditScore`. What the
/// finding needs is a lesson to send somebody back to, and the unit is
/// exactly that.
const Map<String, FinanceConcept> kUnitConcepts = <String, FinanceConcept>{
  'unit_10': FinanceConcept.needsVsWants, //  1 · Money Is Real
  'unit_11': FinanceConcept.payYourselfFirst, //  2 · Saving and Spending
  'unit_1': FinanceConcept.budgetRule, //  3 · Budgeting
  'unit_7': FinanceConcept.impulseSpending, //  4 · Spending Traps
  'unit_3': FinanceConcept.emergencyFund, //  5 · Saving Systems
  'unit_8': FinanceConcept.inflation, //  6 · Money by the Numbers
  'unit_2': FinanceConcept.creditScore, //  7 · Credit
  'unit_5': FinanceConcept.incomeVsWealth, //  8 · Real-World Money Moves
  'unit_12': FinanceConcept.opportunityCost, //  9 · Big Purchases
  'unit_4': FinanceConcept.compoundGrowth, // 10 · Investing Basics
  'unit_6': FinanceConcept.diversification, // 11 · Stocks and Trading
  'unit_9': FinanceConcept.taxes, // 12 · Retirement and the 401(k)
  'unit_13': FinanceConcept.insurance, // 13 · Protecting Your Money
};

/// Reads [stats] into the flat shape the analyser takes.
MoneySnapshot buildMoneySnapshot(UserStats stats) {
  final weekly = stats.habitWeeklyLog;

  // Days with at least one habit logged. The store already prunes this to a
  // trailing fortnight, so its own length is the window.
  final loggedDays = weekly.values.where((day) => day.isNotEmpty).length;

  // Distinct habits that actually show up, which is the number that means
  // anything next to how many are pinned.
  final loggedHabits = <String>{for (final day in weekly.values) ...day}.length;

  return MoneySnapshot(
    loggedDaysLast14: loggedDays,
    daysSinceLastLog: HabitDateKeys.daysSince(stats.jarLastActive),
    longestStreak: _longestStreak(weekly.keys.toSet()),
    pinnedHabits: stats.savedHabitIds.length,
    habitsLoggedLast14: loggedHabits,
    moneySaved: stats.habitTotals.moneySavedUsd,
    choicesKept: stats.habitTotals.choicesKept,
    jarXp: stats.jarXp,
    lessonsCompleted: stats.completedLessons.length,
    lessonsAvailable: _totalLessons,
    conceptAccuracy: _conceptAccuracy(stats),
    pastLifeNetWorths: [
      for (final record in stats.lifeRecords.newestFirst) record.netWorth,
    ],
    townSpotsVisited: stats.townVisitedSpotIds.length,
    townSpotsAvailable: _townSpots,
    challengesStarted: _challengesTouched(stats),
    challengesFinished: _challengesFinished(stats),
  );
}

int get _totalLessons =>
    lessonUnits.fold<int>(0, (sum, unit) => sum + unit.lessons.length);

/// The town's building count, as the analyser's denominator.
///
/// Read from the spot list rather than written down, so adding a building
/// does not quietly make everybody's exploration score look worse against a
/// number nobody updated.
int get _townSpots => kTownSpots.length;

/// Challenges with at least one task done, and challenges finished outright.
///
/// There is no "started" flag stored anywhere — only the set of completed
/// task ids — so started is inferred from that set. Which is the honest
/// reading anyway: a challenge you opened and closed again without doing a
/// task is not one you started.
int _challengesTouched(UserStats stats) {
  final done = stats.completedChallengeTasks.toSet();
  return habitChallenges
      .where((c) => c.tasks.any((t) => done.contains(t.id)))
      .length;
}

int _challengesFinished(UserStats stats) {
  final done = stats.completedChallengeTasks.toSet();
  return habitChallenges
      .where(
        (c) => c.tasks.isNotEmpty && c.tasks.every((t) => done.contains(t.id)),
      )
      .length;
}

/// Best accuracy per concept, via the unit each one belongs to.
///
/// A unit with no assessed node is *absent* rather than zero: never having
/// opened the credit unit is not the same as being bad at credit, and telling
/// somebody they are weak at a lesson they have never seen is the fastest way
/// to make an analyser worth ignoring.
Map<FinanceConcept, double> _conceptAccuracy(UserStats stats) {
  final out = <FinanceConcept, double>{};
  for (final unit in lessonUnits) {
    final concept = kUnitConcepts[unit.id];
    if (concept == null) continue;
    double? best;
    for (final lesson in unit.lessons) {
      if (lesson.type == LessonNodeType.lesson) continue;
      final accuracy = stats.accuracyFor(lesson.id);
      if (accuracy == null) continue;
      if (best == null || accuracy > best) best = accuracy;
    }
    if (best != null) {
      // Two units can map to the same concept; keep the better showing.
      final existing = out[concept];
      out[concept] = existing == null || best > existing ? best : existing;
    }
  }
  return out;
}

/// The longest run of consecutive logged days in the stored window.
///
/// Only ever as long as the window the store keeps, which is a fortnight —
/// so this is "your best recent run", not a lifetime record. Worth saying
/// because a player who once managed 40 days would otherwise think the number
/// had been lost.
int _longestStreak(Set<String> loggedDayKeys) {
  final days = <DateTime>[];
  for (final key in loggedDayKeys) {
    final parsed = DateTime.tryParse(key);
    if (parsed != null) {
      days.add(DateTime(parsed.year, parsed.month, parsed.day));
    }
  }
  if (days.isEmpty) return 0;
  days.sort();
  var best = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    final gap = days[i].difference(days[i - 1]).inDays;
    if (gap == 1) {
      run++;
      if (run > best) best = run;
    } else if (gap > 1) {
      run = 1;
    }
  }
  return best;
}
