import 'dart:math';

import 'finance_concepts.dart';

/// What a life remembers about itself, so it can be looked back on.
///
/// # Why this exists
///
/// The end-of-run screen could only say what a life *was*: a net worth, five
/// stats, an ending. It could not say what the player *did*, because by the time
/// the life ended nothing had been kept. The controller held the present and
/// threw the past away every year.
///
/// So a life now keeps three small things as it goes:
///
///  * a **curve**, one point a year, so the debrief can draw the life's
///    money as a line and point at the year it peaked or fell,
///  * **moments**, the decisions and the shocks that moved real money, with
///    what each one cost and what the other options would have,
///  * a **tally**, a handful of running totals (income, savings, interest, missed
///    weeks, contacts) that turn "a net worth of 900" into "you saved 4% of what
///    you earned".
///
/// All of it is plain data with no Flutter in it, so a debrief can be built from
/// a life that would take twenty minutes to play into existence.

/// One year of a life's money, as a point on its curve.
class LifeYearPoint {
  const LifeYearPoint({
    required this.age,
    required this.netWorth,
    required this.happiness,
    required this.health,
  });

  final int age;
  final int netWorth;
  final int happiness;
  final int health;

  /// Four numbers in a list. A life is up to ninety of these, and they are kept
  /// inside a JSON blob that is rewritten on nearly every action, so the keys
  /// are not repeated ninety times.
  List<int> toJson() => <int>[age, netWorth, happiness, health];

  factory LifeYearPoint.fromJson(Object? raw) {
    final list = raw is List ? raw : const <Object?>[];
    int at(int i) => i < list.length ? _asInt(list[i]) : 0;
    return LifeYearPoint(
      age: at(0),
      netWorth: at(1),
      happiness: at(2),
      health: at(3),
    );
  }
}

/// Coerces what JSON hands back. A number can arrive as an int, a double or a
/// string depending on what touched it, and one bad field must not lose a life.
int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

/// What kind of thing a moment was.
enum LifeMomentKind {
  /// The player chose between options in an event.
  decision,

  /// An unavoidable bill that had to be paid from somewhere.
  shock,
}

/// One thing that moved real money, with what the road not taken would have.
///
/// For a decision, [betterDelta] is the best money outcome among the options the
/// player did *not* pick and [worseDelta] the worst, so the debrief can say both
/// "you left N on the table" and "you dodged N by choosing well". A shock has no
/// alternatives, so both are null.
///
/// Money is only one axis, and the debrief says so. A choice that cost coins and
/// bought happiness is not a mistake, which is why "money left on the table" is
/// a figure the player reads with the choice beside it, never a verdict.
class LifeMoment {
  const LifeMoment({
    required this.age,
    required this.kind,
    required this.title,
    required this.chose,
    required this.moneyDelta,
    this.betterDelta,
    this.betterOption,
    this.worseDelta,
    this.concept,
    this.covered = true,
  });

  final int age;
  final LifeMomentKind kind;

  /// What was going on, in the event's own words or the bill's reason.
  final String title;

  /// What the player picked, or what the bill was for.
  final String chose;

  /// What it did to their money. Negative is a cost.
  final int moneyDelta;

  /// The best money outcome among the options not taken, and its label.
  final int? betterDelta;
  final String? betterOption;

  /// The worst money outcome among the options not taken.
  final int? worseDelta;

  final FinanceConcept? concept;

  /// For a shock, whether savings and cash covered it without borrowing.
  final bool covered;

  /// Coins the best other option would have kept, or 0.
  int get regret {
    final better = betterDelta;
    if (better == null) return 0;
    final gap = better - moneyDelta;
    return gap > 0 ? gap : 0;
  }

  /// Coins this choice saved over the worst other option, or 0.
  int get edge {
    final worse = worseDelta;
    if (worse == null) return 0;
    final gap = moneyDelta - worse;
    return gap > 0 ? gap : 0;
  }

  /// Whether this was the best money option on the table.
  bool get tookTheBest => kind == LifeMomentKind.decision && regret == 0;

  /// How much this moment matters to a story about the life. The larger of what
  /// it cost, what it left on the table and what it saved.
  int get weight => [moneyDelta.abs(), regret, edge].reduce(max);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'a': age,
    'k': kind.index,
    't': title,
    'c': chose,
    'm': moneyDelta,
    if (betterDelta != null) 'bd': betterDelta,
    if (betterOption != null) 'bo': betterOption,
    if (worseDelta != null) 'wd': worseDelta,
    if (concept != null) 'cn': concept!.name,
    if (!covered) 'cv': false,
  };

  factory LifeMoment.fromJson(Map<dynamic, dynamic> json) {
    final kindIndex = _asInt(json['k']);
    FinanceConcept? concept;
    for (final value in FinanceConcept.values) {
      if (value.name == json['cn']) concept = value;
    }
    return LifeMoment(
      age: _asInt(json['a']),
      kind: kindIndex >= 0 && kindIndex < LifeMomentKind.values.length
          ? LifeMomentKind.values[kindIndex]
          : LifeMomentKind.decision,
      title: '${json['t'] ?? ''}',
      chose: '${json['c'] ?? ''}',
      moneyDelta: _asInt(json['m']),
      betterDelta: json['bd'] == null ? null : _asInt(json['bd']),
      betterOption: json['bo'] == null ? null : '${json['bo']}',
      worseDelta: json['wd'] == null ? null : _asInt(json['wd']),
      concept: concept,
      covered: json['cv'] != false,
    );
  }
}

/// Running totals for one life.
///
/// Every field is a plain number, so the debrief's evidence lines can quote them
/// and a test can build one in a line.
class LifeRunTally {
  const LifeRunTally({
    this.adultYears = 0,
    this.workYears = 0,
    this.yearsUnemployed = 0,
    this.studentYears = 0,
    this.weeksMissed = 0,
    this.timesLaidOff = 0,
    this.raises = 0,
    this.referrals = 0,
    this.contactsMade = 0,
    this.townEarned = 0,
    this.sideJobs = 0,
    this.incomeTotal = 0,
    this.savedTotal = 0,
    this.interestPaid = 0,
    this.debtRepaid = 0,
    this.degreesEarned = 0,
    this.studentBorrowed = 0,
    this.promotions = 0,
    this.assetsBought = 0,
    this.shocksHit = 0,
    this.shocksCovered = 0,
    this.firstJobAge,
    this.peakNetWorth = 0,
    this.peakAge,
    this.lowNetWorth = 0,
    this.lowAge,
  });

  /// Years lived as an adult (18 and over), the denominator for anything about
  /// working life.
  final int adultYears;

  /// Adult years that began with a paying job.
  final int workYears;

  /// Adult years that began without one.
  final int yearsUnemployed;

  /// Adult years spent studying. Neither working nor out of work, and the
  /// debrief must not call a student unemployed.
  final int studentYears;

  final int weeksMissed;
  final int timesLaidOff;
  final int raises;
  final int referrals;
  final int contactsMade;

  /// Life money the town paid, after the yearly allowance.
  final int townEarned;
  final int sideJobs;

  /// Everything paid in, across every paycheck.
  final int incomeTotal;

  /// Everything moved into savings out of it.
  final int savedTotal;

  /// Interest charged on debt across the whole life.
  final int interestPaid;

  /// Borrowed money the player chose to pay back, on top of anything the
  /// yearly budget took.
  final int debtRepaid;

  /// Qualifications finished, from a trade certificate to a doctorate.
  final int degreesEarned;

  /// Everything borrowed to pay for school, over the whole life.
  final int studentBorrowed;

  /// Promotions won, as opposed to raises. Moving up a rung, not being paid more
  /// for the same one.
  final int promotions;

  /// Things bought: cars, homes, pets, businesses.
  final int assetsBought;

  final int shocksHit;
  final int shocksCovered;

  final int? firstJobAge;
  final int peakNetWorth;
  final int? peakAge;
  final int lowNetWorth;
  final int? lowAge;

  /// The share of everything earned that was put aside, 0 to 1.
  ///
  /// The single most honest number a personal-finance life produces, and the one
  /// the 50/30/20 rule is a claim about.
  double get savingsRate =>
      incomeTotal <= 0 ? 0 : (savedTotal / incomeTotal).clamp(0.0, 1.0);

  /// Whether there was a working life at all to talk about.
  bool get hadWorkingLife => adultYears >= 3;

  /// Only what is not zero. Most lives leave most of these at zero, and this is
  /// stored for every life the player keeps.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (adultYears != 0) 'ay': adultYears,
    if (workYears != 0) 'wy': workYears,
    if (yearsUnemployed != 0) 'yu': yearsUnemployed,
    if (studentYears != 0) 'sy': studentYears,
    if (weeksMissed != 0) 'wm': weeksMissed,
    if (timesLaidOff != 0) 'lo': timesLaidOff,
    if (raises != 0) 'rs': raises,
    if (referrals != 0) 'rf': referrals,
    if (contactsMade != 0) 'cm': contactsMade,
    if (townEarned != 0) 'te': townEarned,
    if (sideJobs != 0) 'sj': sideJobs,
    if (incomeTotal != 0) 'it': incomeTotal,
    if (savedTotal != 0) 'st': savedTotal,
    if (interestPaid != 0) 'ip': interestPaid,
    if (debtRepaid != 0) 'dr': debtRepaid,
    if (degreesEarned != 0) 'dg': degreesEarned,
    if (studentBorrowed != 0) 'sb': studentBorrowed,
    if (promotions != 0) 'pr': promotions,
    if (assetsBought != 0) 'ab': assetsBought,
    if (shocksHit != 0) 'sh': shocksHit,
    if (shocksCovered != 0) 'sc': shocksCovered,
    if (firstJobAge != null) 'fj': firstJobAge,
    if (peakNetWorth != 0) 'pn': peakNetWorth,
    if (peakAge != null) 'pa': peakAge,
    if (lowNetWorth != 0) 'ln': lowNetWorth,
    if (lowAge != null) 'la': lowAge,
  };

  factory LifeRunTally.fromJson(Map<dynamic, dynamic> json) {
    int at(String key) => _asInt(json[key]);
    int? opt(String key) => json[key] == null ? null : _asInt(json[key]);
    return LifeRunTally(
      adultYears: at('ay'),
      workYears: at('wy'),
      yearsUnemployed: at('yu'),
      studentYears: at('sy'),
      weeksMissed: at('wm'),
      timesLaidOff: at('lo'),
      raises: at('rs'),
      referrals: at('rf'),
      contactsMade: at('cm'),
      townEarned: at('te'),
      sideJobs: at('sj'),
      incomeTotal: at('it'),
      savedTotal: at('st'),
      interestPaid: at('ip'),
      debtRepaid: at('dr'),
      degreesEarned: at('dg'),
      studentBorrowed: at('sb'),
      promotions: at('pr'),
      assetsBought: at('ab'),
      shocksHit: at('sh'),
      shocksCovered: at('sc'),
      firstJobAge: opt('fj'),
      peakNetWorth: at('pn'),
      peakAge: opt('pa'),
      lowNetWorth: at('ln'),
      lowAge: opt('la'),
    );
  }
}

/// A finished life's memory, gathered.
class LifeRunRecord {
  const LifeRunRecord({
    this.curve = const <LifeYearPoint>[],
    this.moments = const <LifeMoment>[],
    this.tally = const LifeRunTally(),
  });

  final List<LifeYearPoint> curve;
  final List<LifeMoment> moments;
  final LifeRunTally tally;

  /// How many moments a stored record keeps. The whole list can be long, and
  /// the debrief only tells the story of the ones that mattered: the biggest
  /// costs, the best calls and the worst misses. Keeping the heaviest is what
  /// keeps a stored life to a few kilobytes.
  static const int maxStoredMoments = 24;

  Map<String, dynamic> toJson() {
    final heaviest = [...moments]..sort((a, b) => b.weight.compareTo(a.weight));
    final kept = heaviest.take(maxStoredMoments).toList()
      ..sort((a, b) => a.age.compareTo(b.age));
    return <String, dynamic>{
      'curve': [for (final p in curve) p.toJson()],
      'moments': [for (final m in kept) m.toJson()],
      'tally': tally.toJson(),
    };
  }

  factory LifeRunRecord.fromJson(Object? raw) {
    if (raw is! Map) return const LifeRunRecord();
    final curve = raw['curve'];
    final moments = raw['moments'];
    final tally = raw['tally'];
    return LifeRunRecord(
      curve: curve is List
          ? [for (final p in curve) LifeYearPoint.fromJson(p)]
          : const <LifeYearPoint>[],
      moments: moments is List
          ? [
              for (final m in moments)
                if (m is Map) LifeMoment.fromJson(m),
            ]
          : const <LifeMoment>[],
      tally: tally is Map ? LifeRunTally.fromJson(tally) : const LifeRunTally(),
    );
  }
}
