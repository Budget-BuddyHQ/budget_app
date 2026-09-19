import 'dart:math';

/// A [Random] that always says the same thing, for tests that need to know
/// exactly what a year will do.
///
/// A seeded `Random` is repeatable but not *predictable*: a test comparing two
/// paychecks still has to hope no random shock landed in one of them. These
/// remove the hope.
///
///  * [FixedRandom.unlucky] never rolls a zero. `nextInt(n)` is always `n - 1`
///    and `nextDouble()` is always 0.999. In the life sim that means no quiet
///    years, no financial shocks, no illnesses and no referrals, so a year's
///    money is the paycheck and nothing else.
///  * [FixedRandom.lucky] always rolls the lowest number. `nextInt(n)` is 0 and
///    `nextDouble()` is 0.0, so every "does it happen" check says yes: every
///    referral fires, every networking event finds somebody.
class FixedRandom implements Random {
  const FixedRandom._({required this.lowInts, required this.fraction});

  factory FixedRandom.unlucky() =>
      const FixedRandom._(lowInts: false, fraction: 0.999);

  factory FixedRandom.lucky() =>
      const FixedRandom._(lowInts: true, fraction: 0.0);

  final bool lowInts;
  final double fraction;

  @override
  int nextInt(int max) => lowInts ? 0 : max - 1;

  @override
  double nextDouble() => fraction;

  @override
  bool nextBool() => lowInts;
}
