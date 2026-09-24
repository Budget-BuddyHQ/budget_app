/// What running yourself down costs a working life.
///
/// # Why this exists
///
/// Health and happiness were meters, and nothing in the money game ever read
/// them. A character could sit at 8 Health and 5 Happiness for thirty years
/// and collect exactly the same paycheck as one at 90 and 90. Which is the
/// opposite of how it works, and it left the app unable to say one of the most
/// useful things a money game can say: **your body and your mood are part of
/// your income.**
///
/// So neglect now has a price, in the currency the game is about. Somebody
/// who is unwell or worn out misses work, and missed work is missed pay. Two
/// bad years in a row and the job goes. None of it is random: it follows from
/// two numbers the player can see and can fix.
///
/// # Why it is gentle
///
/// This is played by eight-year-olds as well as adults. The consequences are
/// about **work**, and they are described the way a sensible adult would
/// explain them to a child: you were unwell, so you missed shifts, so you were
/// paid for fewer of them. Nothing here names a condition or dwells on a low
/// mood. "Worn out" is the whole vocabulary, and every warning ends with what
/// to do about it.
///
/// # Why there is a warning before the cost
///
/// A penalty the player never saw coming is a punishment. One they were warned
/// about, could see building, and had four different ways to fix is a lesson.
/// So [WorkStrain.level] climbs through *watch* and *strained* before anything
/// is taken, and the controller shows it while there is still a year left to
/// act in.
///
/// Kept away from Flutter and from the controller so the thresholds are in one
/// readable place and can be tested as numbers.
library;

/// How worried the game is, from nothing to job-threatening.
enum StrainLevel {
  /// Fine. Nothing to say.
  none,

  /// Getting low. No cost yet.
  watch,

  /// Low enough to cost shifts this year.
  strained,

  /// Low enough that a second year like it ends the job.
  severe,
}

/// The share of a year missed at or above which the employer starts counting.
const double kSeriousMissedShare = 0.2;

/// How many consecutive serious years it takes to lose the job.
const int kYearsToLoseJob = 2;

/// Everything the game concludes from how well a working character is.
class WorkStrain {
  const WorkStrain({
    required this.missedShare,
    required this.fromHealth,
    required this.fromMood,
    required this.level,
  });

  /// Fraction of the year missed, 0 to 0.6.
  final double missedShare;

  /// Whether poor health is a cause.
  final bool fromHealth;

  /// Whether a flat mood is a cause.
  final bool fromMood;

  final StrainLevel level;

  bool get missesWork => missedShare > 0;

  /// Whole weeks of the year missed.
  int get weeksMissed => (missedShare * 52).round();

  /// What fraction of the year's pay is still earned.
  double get payShare => 1.0 - missedShare;

  /// Whether this year counts towards losing the job.
  bool get isSerious => missedShare >= kSeriousMissedShare;

  /// What the missed time was, in a phrase that fits a sentence.
  String get cause {
    if (fromHealth && fromMood) return 'poor health and a flat mood';
    if (fromHealth) return 'being unwell';
    return 'being worn out';
  }
}

/// Reads a working character's health and happiness.
///
/// The bands are wide and the steps are deliberate. Most characters spend most
/// of their working lives comfortably above every line, and the first line is
/// a *watch*, not a cost. It takes real, sustained neglect to lose shifts.
WorkStrain assessWorkStrain({required int health, required int happiness}) {
  final fromHealth = health < 40;
  final fromMood = happiness < 35;

  final healthShare = health < 12
      ? 0.45
      : health < 25
      ? 0.28
      : health < 40
      ? 0.12
      : 0.0;
  final moodShare = happiness < 8
      ? 0.30
      : happiness < 20
      ? 0.18
      : happiness < 35
      ? 0.08
      : 0.0;

  // Added together, then capped, so two bad numbers are worse than one but no
  // year is ever entirely lost. A person who can only just turn up still
  // earns something, which is also true.
  final missed = (healthShare + moodShare).clamp(0.0, 0.6);

  final StrainLevel level;
  if (missed >= kSeriousMissedShare) {
    level = StrainLevel.severe;
  } else if (missed > 0) {
    level = StrainLevel.strained;
  } else if (health < 55 || happiness < 45) {
    level = StrainLevel.watch;
  } else {
    level = StrainLevel.none;
  }

  return WorkStrain(
    missedShare: missed,
    fromHealth: fromHealth,
    fromMood: fromMood,
    level: level,
  );
}

/// The line the game shows above the stats, or null when there is none.
///
/// Always says what to do. A warning that only names a problem is a nag.
String? strainWarning(WorkStrain strain, {required bool jobAtRisk}) {
  if (jobAtRisk) {
    return 'Your manager has noticed the missed shifts. Another year like '
        'this and the job is at risk. Rest, a check-up or time with people '
        'all help.';
  }
  switch (strain.level) {
    case StrainLevel.none:
      return null;
    case StrainLevel.watch:
      return 'Running a little low. Rest before it starts costing you shifts.';
    case StrainLevel.strained:
    case StrainLevel.severe:
      final weeks = strain.weeksMissed;
      return 'You are on course to miss about $weeks '
          '${weeks == 1 ? 'week' : 'weeks'} of work this year through '
          '${strain.cause}, and be paid for fewer of them. Exercise, a '
          'check-up or time with people all help.';
  }
}
