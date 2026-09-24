/// What the town map can pay a life, and how much of it in a year.
///
/// # Why the map paid nothing
///
/// Reported as *"make the map get you money too"*, and the diagnosis is
/// specific. The town was wired to the life in one direction only for its
/// buildings and people, and not at all for the thing a player actually does
/// there, which is walking around picking up coins:
///
///  * **Coins paid account gold, never life money.** A coin was worth 3 to 5,
///    all of it went to the account, and none of it reached the character whose
///    money the run is about.
///  * **They never came back.** Collected coins were stored on the account, so
///    after the first life every coin was gone for good and the map had nothing
///    left to pay anybody.
///  * **Building scenes paid once, ever.** The anti-farming rule is right, and
///    it also means a second life through the same town earned nothing.
///
/// So the map read as scenery. This makes it a small, real income: coins are
/// worth something on the scale of the life they are picked up in, and they
/// restock every year, so walking the town is a job you can choose to do.
///
/// # Why it is capped
///
/// A town that pays without limit is a treadmill, and the leaderboard ranks net
/// worth. Each year has an allowance paid at full rate. Beyond it the town still
/// pays, at a quarter, which is the same shape as every other budget in the
/// game (see `life_effort.dart`): the first hours of a year are worth the most.
///
/// Kept in its own file so the numbers are in one readable place and can be
/// tested as numbers.
class TownIncome {
  const TownIncome._();

  /// What a map coin is worth to a life, per point of the coin's face value.
  ///
  /// A coin on the map is 3 to 5. Times four, a full sweep of the first town is
  /// about 108 a year, which is a good side job's worth and roughly a week of
  /// working: enough to feel, well short of being a career.
  static const int coinMultiplier = 4;

  /// How much a year of town income pays at full rate.
  static const int yearlyAllowance = 240;

  /// What is paid beyond the allowance, as a fraction.
  static const double beyondAllowance = 0.25;

  /// Life money for a coin of [faceValue].
  static int coinWorth(int faceValue) => faceValue * coinMultiplier;

  /// What actually gets credited when [gross] is earned, given [earnedSoFar]
  /// this year.
  ///
  /// The part of [gross] that fits under the allowance pays in full and the rest
  /// pays at [beyondAllowance]. Never negative, and never more than [gross].
  static int payFor(int earnedSoFar, int gross) {
    if (gross <= 0) return 0;
    final room = (yearlyAllowance - earnedSoFar).clamp(0, yearlyAllowance);
    final full = gross < room ? gross : room;
    final rest = gross - full;
    return full + (rest * beyondAllowance).round();
  }

  /// Whether the year's allowance is spent, for the map to say so.
  static bool isSpent(int earnedSoFar) => earnedSoFar >= yearlyAllowance;
}
