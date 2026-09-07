import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'player_profile.dart';

/// Leak Patrol — the whack-a-mole.
///
/// # What it is for
///
/// The arcade already had allocation (Coin Cascade) and combat recall
/// (Finance Brawl). The gap was the money most people actually lose: not a
/// bad investment, but **small charges nobody looked at**. Subscriptions
/// still running, a fee on an account, an offer that was never a real offer.
///
/// It also gives the Mushroom Goomba a job. It had been in the skin
/// catalogue, buyable, equippable, and its 8-frame walk cycle was reached by
/// `AvatarSkin.walkFrames` — a method with **zero callers anywhere**. The
/// sprite existed and never once animated.
///
/// # The one rule
///
/// **Tap the leaks. Leave the real charges alone.**
///
/// That distinction is the entire lesson, and it is why this is not simply
/// "tap everything fast". Rent is not a leak. A bill you agreed to is not a
/// leak. Somebody who taps every mole is not being vigilant, they are being
/// indiscriminate — and cancelling your own electricity is its own kind of
/// mistake. Tapping a legitimate charge **costs you**, which is what forces
/// the player to actually read.
///
/// # Why a timer rather than lives
///
/// A fail-on-mistake game punishes the exact hesitation this is trying to
/// train — reading before acting. A clock rewards accuracy under mild
/// pressure and lets a careful player finish, which is the behaviour worth
/// building.

/// What pops up out of a hole.
enum LeakKind {
  /// Money quietly leaving. Tap it.
  leak,

  /// A charge you genuinely owe. Leave it.
  legitimate,
}

/// One thing that can appear.
@immutable
class LeakItem {
  const LeakItem({
    required this.id,
    required this.label,
    required this.kind,
    required this.why,
    required this.concept,
    this.value = 6,
    this.minAge = 0,
  });

  final String id;

  /// What the player reads in the half-second it is up.
  final String label;

  final LeakKind kind;

  /// Shown on the results card. Every item explains itself, because a game
  /// that only tells you "wrong" teaches reflexes rather than judgement.
  final String why;

  final FinanceConcept concept;

  /// Coins saved by catching it, or lost by wrongly cancelling it.
  final int value;

  /// Some of these need vocabulary a young player has not met.
  final int minAge;

  bool get isLeak => kind == LeakKind.leak;
}

/// Everything that can pop up.
///
/// Deliberately more legitimate charges than a player expects. If leaks were
/// the common case, tapping everything would be the winning strategy and the
/// game would teach the opposite of what it is for.
const List<LeakItem> kLeakItems = <LeakItem>[
  // --- leaks: tap these -------------------------------------------------
  LeakItem(
    id: 'unused_sub',
    label: 'Gym you stopped going to',
    kind: LeakKind.leak,
    why: 'Still charging every month. A subscription you do not use is the '
        'purest form of money leaving for nothing.',
    concept: FinanceConcept.impulseSpending,
    value: 8,
  ),
  LeakItem(
    id: 'free_trial',
    label: 'Free trial, day 31',
    kind: LeakKind.leak,
    why: 'Free trials are designed around the day you forget. That is the '
        'product.',
    concept: FinanceConcept.impulseSpending,
    value: 9,
  ),
  LeakItem(
    id: 'double_charge',
    label: 'Charged twice for one thing',
    kind: LeakKind.leak,
    why: 'Mistakes happen and almost nobody checks. Money back is only ever '
        'given to people who ask.',
    concept: FinanceConcept.needsVsWants,
    value: 10,
  ),
  LeakItem(
    id: 'guaranteed_return',
    label: '"Guaranteed 40% return"',
    kind: LeakKind.leak,
    why: 'Nothing guarantees a return like that. The word guaranteed is the '
        'tell, not the reassurance.',
    concept: FinanceConcept.diversification,
    value: 12,
    minAge: 10,
  ),
  LeakItem(
    id: 'overdraft_fee',
    label: 'Fee for being 20p short',
    kind: LeakKind.leak,
    why: 'A charge for not having money, applied when you have least of it. '
        'Worth arguing about every time.',
    concept: FinanceConcept.interestCost,
    value: 9,
    minAge: 9,
  ),
  LeakItem(
    id: 'auto_renew',
    label: 'Auto-renewed at triple',
    kind: LeakKind.leak,
    why: 'The cheap first year was the offer. The renewal is the real price, '
        'and it renews itself so you never compare.',
    concept: FinanceConcept.impulseSpending,
    value: 10,
    minAge: 10,
  ),
  LeakItem(
    id: 'app_extra',
    label: 'Game coins you did not mean to buy',
    kind: LeakKind.leak,
    why: 'One tap, real money. The easiest spending is always the least '
        'decided.',
    concept: FinanceConcept.impulseSpending,
    value: 7,
  ),

  // --- real charges: leave these -----------------------------------------
  LeakItem(
    id: 'rent',
    label: 'Rent',
    kind: LeakKind.legitimate,
    why: 'You live there. Cancelling the things you actually need is not '
        'thrift, it is a different mistake.',
    concept: FinanceConcept.needsVsWants,
    value: 12,
  ),
  LeakItem(
    id: 'groceries',
    label: 'Food shop',
    kind: LeakKind.legitimate,
    why: 'Eating is a need. A budget that cuts it is one you abandon by '
        'Thursday.',
    concept: FinanceConcept.needsVsWants,
    value: 10,
  ),
  LeakItem(
    id: 'bus_pass',
    label: 'Bus pass you use daily',
    kind: LeakKind.legitimate,
    why: 'It costs money and it earns money, because it gets you to work.',
    concept: FinanceConcept.opportunityCost,
    value: 8,
  ),
  LeakItem(
    id: 'savings_transfer',
    label: 'Money moving to savings',
    kind: LeakKind.legitimate,
    why: 'That is not money leaving, it is money moving. Stopping it is the '
        'most expensive tap on this board.',
    concept: FinanceConcept.payYourselfFirst,
    value: 14,
  ),
  LeakItem(
    id: 'phone_bill',
    label: 'Phone bill you agreed to',
    kind: LeakKind.legitimate,
    why: 'A bill you chose and use is not a leak. The skill is telling those '
        'apart, not cancelling everything.',
    concept: FinanceConcept.needsVsWants,
    value: 8,
  ),
  LeakItem(
    id: 'insurance',
    label: 'Insurance premium',
    kind: LeakKind.legitimate,
    why: 'It feels like a leak right up until the year you need it. That is '
        'what it is for.',
    concept: FinanceConcept.insurance,
    value: 10,
    minAge: 11,
  ),
];

/// Items this player can be shown.
List<LeakItem> leakItemsFor(AgeBand band) {
  final age = band.representativeAge;
  return [
    for (final item in kLeakItems)
      if (age >= item.minAge) item,
  ];
}

/// How long a round runs, and how fast things appear.
///
/// Scaled by age, which every other minigame failed to do — Coin Cascade,
/// React Challenge and the Market Board still have no age awareness at all.
/// A six-year-old needs time to *read* before deciding, and a game that
/// outruns their reading is testing reflexes rather than judgement.
@immutable
class LeakRound {
  const LeakRound({
    required this.seconds,
    required this.popMillis,
    required this.visibleMillis,
    required this.holes,
  });

  final int seconds;

  /// Gap between things appearing.
  final int popMillis;

  /// How long each stays up.
  final int visibleMillis;

  final int holes;

  factory LeakRound.forBand(AgeBand band) => switch (band) {
    AgeBand.under9 => const LeakRound(
      seconds: 45,
      popMillis: 1500,
      visibleMillis: 2600,
      holes: 6,
    ),
    AgeBand.age9to12 => const LeakRound(
      seconds: 50,
      popMillis: 1150,
      visibleMillis: 2100,
      holes: 6,
    ),
    AgeBand.teen13to15 => const LeakRound(
      seconds: 55,
      popMillis: 900,
      visibleMillis: 1700,
      holes: 9,
    ),
    AgeBand.teen16to17 => const LeakRound(
      seconds: 60,
      popMillis: 780,
      visibleMillis: 1450,
      holes: 9,
    ),
    AgeBand.adult18plus => const LeakRound(
      seconds: 60,
      popMillis: 700,
      visibleMillis: 1300,
      holes: 9,
    ),
    // Middle of the range, matching how undisclosed is treated everywhere
    // else: guessing young is patronising, guessing old locks people out.
    AgeBand.undisclosed => const LeakRound(
      seconds: 55,
      popMillis: 900,
      visibleMillis: 1700,
      holes: 9,
    ),
  };
}

/// The result of a round.
@immutable
class LeakResult {
  const LeakResult({
    required this.caught,
    required this.missed,
    required this.wronglyTapped,
    required this.coinsSaved,
    required this.coinsLost,
  });

  /// Leaks tapped in time.
  final int caught;

  /// Leaks that got away.
  final int missed;

  /// Real charges the player cancelled.
  final int wronglyTapped;

  final int coinsSaved;
  final int coinsLost;

  int get net => coinsSaved - coinsLost;

  /// Accuracy over every decision the player actually made.
  ///
  /// Misses are excluded on purpose: not tapping something is only sometimes
  /// a decision, and counting every un-tapped hole would make doing nothing
  /// look like perfect play.
  double get accuracy {
    final decisions = caught + wronglyTapped;
    return decisions == 0 ? 0 : caught / decisions;
  }

  /// What the player is told, in one line.
  ///
  /// Ordered by which mistake is worth naming first. Cancelling real charges
  /// leads, because it is the failure the game exists to create — everyone
  /// arrives assuming vigilance means tapping everything.
  String get headline {
    if (caught == 0 && wronglyTapped == 0) {
      return 'Nothing tapped. Reading is fine; the clock still runs.';
    }
    if (wronglyTapped > caught) {
      return 'You cancelled more real charges than leaks. Vigilance is not '
          'the same as suspicion.';
    }
    if (wronglyTapped > 0) {
      return 'Good catches, but $wronglyTapped real ${wronglyTapped == 1 ? 'charge' : 'charges'} '
          'went with them.';
    }
    if (missed > caught) {
      return 'Every tap was right — there were just more getting past you.';
    }
    return 'Caught $caught, cancelled nothing you needed. That is the whole '
        'skill.';
  }
}

/// Gold for a finished round.
///
/// Never negative. A player who ends up worse off for having played would
/// stop playing, and this is the game meant to teach the least-fun habit in
/// the app — checking things.
int leakPayout(LeakResult result) {
  final base = result.net;
  final bonus = result.accuracy >= 0.9 && result.caught >= 3 ? 15 : 0;
  final total = base + bonus;
  return total < 0 ? 0 : total;
}
