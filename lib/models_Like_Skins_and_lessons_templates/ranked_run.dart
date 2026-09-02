/// Ranked: one life, scored, with the rules fixed.
///
/// **What it is for.** Normal play is a sandbox — you can retire at forty, or
/// spend a run finding out what happens if you never work. Ranked asks one
/// question instead: given the same start everybody else got, how much can you
/// build? That turns the app's whole toolkit — budget splits, the emergency
/// fund, powers, the town — into things you are *optimising* rather than
/// things you are exploring.
///
/// **Why the score is not just net worth.** Net worth alone has one dominant
/// strategy: take every risk, because a run that dies at forty scores the same
/// as one that never started. Real financial competence is not "how big can
/// the number get before something goes wrong", so the score has to notice
/// that you were still standing at the end and that you understood what you
/// were doing.
///
/// So it is three parts, in the order they matter:
///
/// * **Wealth** carries most of it, because that is the stated goal.
/// * **Survival** is a multiplier, not a bonus. Dying at thirty-five with a
///   fortune should not beat retiring at eighty with less, and a multiplier is
///   the only shape that makes the trade real.
/// * **Understanding** adds a modest amount per money idea met. Small on
///   purpose: it should be worth going and learning something, and it should
///   never be worth *only* learning things.
library;

/// Everything a finished run contributes to its score.
class RankedResult {
  const RankedResult({
    required this.netWorth,
    required this.ageReached,
    required this.conceptsMet,
    required this.died,
    required this.everStarved,
  });

  final int netWorth;
  final int ageReached;
  final int conceptsMet;

  /// Whether the run ended in death rather than a chosen retirement.
  final bool died;

  /// Whether hunger ever reached the starvation threshold. A run that came
  /// that close was not a near miss, it was a plan that did not work.
  final bool everStarved;
}

/// A scored ranked run.
class RankedScore {
  const RankedScore({
    required this.total,
    required this.wealthPoints,
    required this.survivalMultiplier,
    required this.understandingPoints,
    required this.grade,
  });

  final int total;
  final int wealthPoints;

  /// 0.5 to 1.25. See [scoreRankedRun] for why this is a multiplier.
  final double survivalMultiplier;
  final int understandingPoints;

  /// A letter, for the result screen. Bands are wide because the interesting
  /// comparison is against your own last run, not against a curve.
  final String grade;
}

/// The lowest possible multiplier — a run that ended early and badly.
const double kMinSurvivalMultiplier = 0.5;

/// The highest — a long life that ended on your terms.
const double kMaxSurvivalMultiplier = 1.25;

/// Scores a finished ranked run.
RankedScore scoreRankedRun(RankedResult result) {
  // Wealth, compressed. A linear score would make the top of the stardom
  // chain — which can pay out most of a million in one event — worth more
  // than every other decision in the game put together, and a leaderboard
  // that only ranks "did you get the guitar event" is not ranking anything.
  // Square root keeps a big win a big win while leaving the ordinary
  // decisions able to matter.
  final wealth = result.netWorth <= 0
      ? 0
      : (_sqrt(result.netWorth.toDouble()) * 22).round();

  // Survival. Retiring at eighty is the top of the band; dying young is the
  // bottom, and starving at any point caps you out of the top regardless of
  // how the numbers ended up.
  var survival =
      kMinSurvivalMultiplier +
      ((result.ageReached.clamp(0, 85) / 85) *
          (kMaxSurvivalMultiplier - kMinSurvivalMultiplier));
  if (result.died) survival -= 0.12;
  if (result.everStarved) survival -= 0.15;
  survival = survival.clamp(kMinSurvivalMultiplier, kMaxSurvivalMultiplier);

  // Understanding. 140 a concept, so meeting all sixteen is worth about as
  // much as a comfortable but unremarkable financial life — meaningful, and
  // nowhere near a substitute for one.
  final understanding = result.conceptsMet * 140;

  final total = ((wealth + understanding) * survival).round();

  return RankedScore(
    total: total,
    wealthPoints: wealth,
    survivalMultiplier: survival,
    understandingPoints: understanding,
    grade: rankedGrade(total),
  );
}

/// The letter for a total.
///
/// Wide bands, and no F. This is a financial-literacy app for children; a
/// scoring screen that tells a nine-year-old they failed at a life is not a
/// thing worth building.
String rankedGrade(int total) {
  if (total >= 26000) return 'S';
  if (total >= 18000) return 'A';
  if (total >= 12000) return 'B';
  if (total >= 7000) return 'C';
  if (total >= 3000) return 'D';
  return 'E';
}

/// What the grade means, in a sentence.
String rankedGradeBlurb(String grade) => switch (grade) {
  'S' =>
    'A life almost nobody manages. You compounded, you covered yourself, '
        'and you were still standing at the end.',
  'A' =>
    'Comfortable, deliberate and well defended. Very few runs finish here.',
  'B' => 'A solid life. Something went right and you did not undo it.',
  'C' =>
    'You got there. There is a lot of room between this and the top, and '
        'most of it is savings.',
  'D' =>
    'Rough. Look at what was happening the year it went wrong — it is '
        'usually one decision, not ten.',
  _ =>
    'A hard run. Try arming a money idea early and setting a budget before '
        'the first paycheck lands.',
};

/// Newton's method, so this file needs no import and stays pure data + maths.
double _sqrt(double value) {
  if (value <= 0) return 0;
  var guess = value;
  for (var i = 0; i < 24; i++) {
    guess = (guess + value / guess) / 2;
  }
  return guess;
}
