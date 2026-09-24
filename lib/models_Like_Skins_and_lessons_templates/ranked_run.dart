// ranked mode: one life, scored, same rules for everyone. normal play is
// a sandbox but ranked is "how much can you build from the same start".
// score = wealth (main thing) x survival multiplier (dying young tanks it)
// + a small understanding bonus per concept learned
library;

// everything a finished run needs for scoring
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

  // died instead of retiring on purpose
  final bool died;

  // hit the starvation threshold at any point, not just a near miss
  final bool everStarved;
}

// a scored ranked run
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

  // 0.5 to 1.25, dying young tanks this, retiring on your own terms maxes it
  final double survivalMultiplier;
  final int understandingPoints;

  // letter grade for the results screen. bands are wide on purpose
  final String grade;
}

const double kMinSurvivalMultiplier = 0.5;
const double kMaxSurvivalMultiplier = 1.25;

// scores a finished ranked run
RankedScore scoreRankedRun(RankedResult result) {
  // sqrt so one lucky huge payout (stardom chain etc) cant dominate the
  // whole score and drown out every other decision you made
  final wealth = result.netWorth <= 0
      ? 0
      : (_sqrt(result.netWorth.toDouble()) * 22).round();

  // retiring at 80 = top of the band, dying young = bottom, starving
  // caps you out of the top no matter how the numbers ended up
  var survival =
      kMinSurvivalMultiplier +
      ((result.ageReached.clamp(0, 85) / 85) *
          (kMaxSurvivalMultiplier - kMinSurvivalMultiplier));
  if (result.died) survival -= 0.12;
  if (result.everStarved) survival -= 0.15;
  survival = survival.clamp(kMinSurvivalMultiplier, kMaxSurvivalMultiplier);

  // 140 per concept, worth something but not a substitute for actually
  // building wealth
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

// letter for a total. no F, this is for kids, dont tell a 9 year old
// they failed at life
String rankedGrade(int total) {
  if (total >= 26000) return 'S';
  if (total >= 18000) return 'A';
  if (total >= 12000) return 'B';
  if (total >= 7000) return 'C';
  if (total >= 3000) return 'D';
  return 'E';
}

// what the grade means, one sentence
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

// newtons method, keeps this file dependency-free
double _sqrt(double value) {
  if (value <= 0) return 0;
  var guess = value;
  for (var i = 0; i < 24; i++) {
    guess = (guess + value / guess) / 2;
  }
  return guess;
}
