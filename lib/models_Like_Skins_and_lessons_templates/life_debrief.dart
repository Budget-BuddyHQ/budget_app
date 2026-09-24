/// What one finished life says about how it was played.
///
/// # Why this exists separately from the Coach
///
/// The Coach (`money_analyzer.dart`) reads a player's whole history across the
/// app and answers "what should you change about how you are using this".
/// It is deliberately slow-moving, and it says nothing about the run you just
/// finished, because one run is noise against a fortnight of habits.
///
/// The end of a life is the other moment, and it was the emptier one. The
/// epilogue named the ending, listed five stats and paid out the gold, which
/// tells a player *what happened* and nothing about *what they did*. Somebody
/// who retired at 68 with no emergency fund, everything in cash and a
/// thousand in debt got the same screen as somebody who did none of that.
///
/// So this is a debrief for the single run, built from the numbers that run
/// actually produced, and it follows the Coach's rule about what an opinion
/// has to carry:
///
///  * **evidence** out of that life, not a general claim,
///  * **one thing to do differently**, small enough to try next run,
///  * **the concept**, where one applies, so the finding can point at the
///    lesson that explains it.
///
/// Evidence and an action are required by the constructor. The concept is
/// optional, because a few of these are about the run rather than about an
/// idea the Academy teaches.
///
/// # Why grades per area rather than one score
///
/// Ranked already gives a single number, and a single number cannot be acted
/// on. Six areas can: a player who scores well on saving and badly on growth
/// has a different next run from one who did the reverse.
///
/// # Why it also tells a story
///
/// Areas say *where* a run was strong or weak. They do not say *when*, and the
/// "when" is the part a player can learn from: the year the money peaked, the
/// bill that arrived with nothing behind it, the one decision that cost the most
/// and what the other option would have done. So the debrief also carries a
/// [LifeStory], built from what the life remembered about itself as it went (see
/// `life_run_record.dart`).
///
/// Money is only one axis, and the story says so. A choice that cost coins and
/// bought happiness is not a mistake, so "money left on the table" is always
/// shown with the choice beside it and is never a verdict.
library;

import 'finance_concepts.dart';
import 'life_run_record.dart';

/// The things a life is graded on.
///
/// Career and People appear only when the life had enough of either to say
/// something honest: a child who died at nine has no working life to grade.
enum LifeArea {
  /// Did money get put aside at all, and was there a cushion at the end.
  saving,

  /// Was money borrowed, and was it still owed when the life ended.
  debt,

  /// Was anything put to work, or did it all sit in cash.
  growth,

  /// Was there steady work, and did looking after yourself protect it.
  career,

  /// Who was still there, and who you knew.
  people,

  /// Did the run meet the ideas the game teaches.
  learning,
}

extension LifeAreaInfo on LifeArea {
  String get label => switch (this) {
    LifeArea.saving => 'Saving',
    LifeArea.debt => 'Debt',
    LifeArea.growth => 'Growing it',
    LifeArea.career => 'Career',
    LifeArea.people => 'People',
    LifeArea.learning => 'Learning',
  };
}

/// How serious a finding is, and what colour it earns on screen.
enum LifeFindingKind {
  /// Cost this run real money or years. Shown first.
  fix,

  /// Not wrong, but the next run can do better.
  watch,

  /// Worth naming, because a debrief that only lists faults gets ignored.
  strength,
}

/// One thing the debrief noticed about this life.
class LifeFinding {
  const LifeFinding({
    required this.id,
    required this.kind,
    required this.area,
    required this.title,
    required this.evidence,
    required this.action,
    this.concept,
    this.priority = 0,
  });

  final String id;
  final LifeFindingKind kind;
  final LifeArea area;

  /// How much this cost, for ordering within a kind. Higher comes first.
  ///
  /// **Why it exists.** Findings used to be ordered by the order the rules ran,
  /// which is the order the areas are listed in: saving, then debt, then growth,
  /// then career. So a life that was let go from its job could have that cut off
  /// behind three smaller savings notes, on a screen whose own headline says
  /// "start with the first line". The first line has to be the one that cost the
  /// most, so each finding says how much that is.
  final int priority;

  /// Six words at most. It is a heading, not the point.
  final String title;

  /// A number out of this run. "You retired with 0 saved" is an argument a
  /// player cannot wave away; "saving is important" is one they can.
  final String evidence;

  /// One thing to do differently, phrased for the next run.
  final String action;

  /// The idea behind it, where the Academy teaches one.
  final FinanceConcept? concept;
}

/// Everything the debrief is allowed to look at.
///
/// A flat record rather than the controller, so the rules can be tested
/// against a life that would take twenty minutes to play into existence.
class LifeRunFacts {
  const LifeRunFacts({
    required this.age,
    required this.netWorth,
    required this.cash,
    required this.investments,
    required this.emergencyFund,
    required this.debt,
    required this.health,
    required this.happiness,
    required this.conceptsMet,
    required this.died,
    required this.everStarved,
    required this.budgetSet,
    this.savingsPct = 0,
    this.wantsPct = 0,
    this.conceptsAvailable = 16,
    this.record = const LifeRunRecord(),
    this.connection,
    this.networkStrength = 0,
    this.contacts = 0,
    this.educationRank = 0,
    this.educationLabel = '',
    this.assetsValue = 0,
    this.loanBalance = 0,
    this.ownsHome = false,
    this.hasPartner = false,
    this.children = 0,
    this.jobTitle = '',
  });

  final int age;
  final int netWorth;
  final int cash;
  final int investments;
  final int emergencyFund;
  final int debt;
  final int health;
  final int happiness;

  /// How many finance ideas this run actually met.
  final int conceptsMet;
  final int conceptsAvailable;

  final bool died;

  /// Whether hunger ever reached the starvation threshold, even if it
  /// recovered afterwards.
  final bool everStarved;

  /// Whether a budget was ever set. The single most skipped screen in the
  /// game and the one everything else follows from.
  final bool budgetSet;

  /// The budget split, if one was set.
  final int savingsPct;
  final int wantsPct;

  /// What the life remembered as it went: a curve, the moments that moved money,
  /// and the running totals. Empty for a fixture built by hand, in which case
  /// the story and the totals-based findings are simply left out.
  final LifeRunRecord record;

  /// Average closeness of the people who are not contacts, 0 to 100. Null when
  /// it was not measured, which leaves the People area out of the grade.
  final int? connection;

  /// How strong the professional network was at the end, 0 to 100.
  final int networkStrength;

  /// How many contacts were still present at the end.
  final int contacts;

  /// The highest qualification held, as an index into `EducationLevel` and as
  /// words. Both, so the debrief can reason with the number and quote the label
  /// without importing the game's model, which this file stays free of.
  final int educationRank;
  final String educationLabel;

  /// What the player owned at the end, and what they still owed on loans.
  final int assetsValue;
  final int loanBalance;
  final bool ownsHome;

  /// Whether a partner was alive at the end, and how many children the player
  /// had.
  final bool hasPartner;
  final int children;

  /// The job held when the life ended, or empty.
  final String jobTitle;

  LifeRunTally get tally => record.tally;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'age': age,
    'nw': netWorth,
    'cash': cash,
    'inv': investments,
    'ef': emergencyFund,
    'debt': debt,
    'hp': health,
    'hap': happiness,
    'cm': conceptsMet,
    'ca': conceptsAvailable,
    'died': died,
    'starved': everStarved,
    'budget': budgetSet,
    'sv': savingsPct,
    'wt': wantsPct,
    if (connection != null) 'conn': connection,
    'net': networkStrength,
    'con': contacts,
    'edu': educationRank,
    'edl': educationLabel,
    'av': assetsValue,
    'lb': loanBalance,
    'home': ownsHome,
    'pt': hasPartner,
    'kids': children,
    'job': jobTitle,
    'record': record.toJson(),
  };

  factory LifeRunFacts.fromJson(Map<dynamic, dynamic> json) {
    int at(String key, [int fallback = 0]) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse('$value') ?? fallback;
    }

    return LifeRunFacts(
      age: at('age'),
      netWorth: at('nw'),
      cash: at('cash'),
      investments: at('inv'),
      emergencyFund: at('ef'),
      debt: at('debt'),
      health: at('hp'),
      happiness: at('hap'),
      conceptsMet: at('cm'),
      conceptsAvailable: at('ca', 16),
      died: json['died'] == true,
      everStarved: json['starved'] == true,
      budgetSet: json['budget'] == true,
      savingsPct: at('sv'),
      wantsPct: at('wt'),
      record: LifeRunRecord.fromJson(json['record']),
      connection: json['conn'] == null ? null : at('conn'),
      networkStrength: at('net'),
      contacts: at('con'),
      educationRank: at('edu'),
      educationLabel: '${json['edl'] ?? ''}',
      assetsValue: at('av'),
      loanBalance: at('lb'),
      ownsHome: json['home'] == true,
      hasPartner: json['pt'] == true,
      children: at('kids'),
      jobTitle: '${json['job'] ?? ''}',
    );
  }

  /// Everything owned minus everything owed, as the game counts it.
  int get worth => netWorth;

  /// Roughly how many years of a modest life the cushion covers. Uses the
  /// same 1,200-a-year figure the sim uses for basic living costs.
  double get cushionYears => emergencyFund / 1200;
}

/// The run told as events rather than as scores.
class LifeStory {
  const LifeStory({
    this.turningPoint,
    this.regrets = const <LifeMoment>[],
    this.bestCall,
    this.biggestHit,
    this.moneyLeftOnTable = 0,
  });

  /// The single moment most worth looking back at: the decision that cost the
  /// most against the best alternative, or failing that the biggest hit.
  final LifeMoment? turningPoint;

  /// Up to three decisions that left the most money behind, worst first.
  final List<LifeMoment> regrets;

  /// The decision where taking the best option saved the most over the worst.
  final LifeMoment? bestCall;

  /// The single biggest cost, whether a choice or a bill.
  final LifeMoment? biggestHit;

  /// Coins the best money option would have kept, summed over every decision.
  final int moneyLeftOnTable;

  bool get isEmpty =>
      turningPoint == null &&
      regrets.isEmpty &&
      bestCall == null &&
      biggestHit == null;
}

/// The finished debrief.
class LifeDebrief {
  const LifeDebrief({
    required this.scores,
    required this.findings,
    required this.headline,
    this.story = const LifeStory(),
    this.record = const LifeRunRecord(),
    this.nextRun = '',
  });

  /// 0..100 per area. An area with nothing to grade is absent, not zero.
  final Map<LifeArea, int> scores;

  /// Ordered fix, then watch, then strength, so a player who reads one line
  /// reads the one that cost them something.
  final List<LifeFinding> findings;

  /// One sentence about the run as a whole.
  final String headline;

  /// The run told as events. See [LifeStory].
  final LifeStory story;

  /// The curve and the running totals, for the screen to draw and quote.
  final LifeRunRecord record;

  /// One concrete challenge for the next life, aimed at the weakest area.
  final String nextRun;

  /// The average of the areas, which is what the letter comes from.
  int get overall {
    if (scores.isEmpty) return 0;
    final total = scores.values.reduce((a, b) => a + b);
    return (total / scores.length).round();
  }

  /// A, B, C or D. No F: this is a game somebody chose to play, and a debrief
  /// that opens by failing them is one they close.
  String get grade {
    final score = overall;
    if (score >= 80) return 'A';
    if (score >= 60) return 'B';
    if (score >= 40) return 'C';
    return 'D';
  }

  /// The weakest area, which is what the next run should aim at.
  LifeArea? get weakest {
    if (scores.isEmpty) return null;
    var worst = scores.entries.first;
    for (final entry in scores.entries) {
      if (entry.value < worst.value) worst = entry;
    }
    return worst.key;
  }

  /// The findings worth putting on screen, at most [max] of them.
  ///
  /// **Never only faults.** The list is ordered worst first, so taking the top
  /// few would show nothing but problems for any run with a few of them, and
  /// the class doc is right that a debrief that only lists faults gets closed.
  /// So the last slot is reserved for the best thing the run did, when there is
  /// one, and the rest go to what cost the most.
  List<LifeFinding> shown({int max = 4}) {
    if (findings.length <= max) return findings;
    final problems = findings
        .where((f) => f.kind != LifeFindingKind.strength)
        .toList();
    final strengths = findings
        .where((f) => f.kind == LifeFindingKind.strength)
        .toList();
    if (strengths.isEmpty) return problems.take(max).toList();
    return <LifeFinding>[...problems.take(max - 1), strengths.first];
  }
}

int _clamp100(num value) => value.clamp(0, 100).round();

String _pct(double share) => '${(share * 100).round()}%';

/// Grades one finished life.
///
/// Every rule reads a number this run produced. Nothing here looks at other
/// runs, at the player's account, or at how long they have had the app.
LifeDebrief debriefLife(LifeRunFacts facts) {
  final findings = <LifeFinding>[];
  final tally = facts.tally;

  // ---- Saving ------------------------------------------------------------
  //
  // Three months of costs is the figure every source in the Academy uses, so
  // three years of the sim's living costs is the full score here.
  final cushionScore = _clamp100((facts.cushionYears / 3) * 100);

  // Where the run kept a record of its pay, the share of it that was saved
  // counts as well. A cushion measured only at the end punishes somebody who
  // built one and sensibly spent it in retirement, and the 20% in 50/30/20 is
  // a claim about what you save, not about what is left.
  final rateScore = tally.incomeTotal > 0
      ? _clamp100(tally.savingsRate / 0.2 * 100)
      : null;
  final savingScore = rateScore == null
      ? cushionScore
      : _clamp100(cushionScore * 0.6 + rateScore * 0.4);

  if (facts.emergencyFund <= 0 && facts.age >= 25) {
    findings.add(
      LifeFinding(
        id: 'no_cushion',
        priority: 60,
        kind: LifeFindingKind.fix,
        area: LifeArea.saving,
        title: 'No cushion, ever',
        evidence: 'You reached ${facts.age} with nothing set aside.',
        action:
            'Next run, put something into the emergency fund the first year '
            'you have income. Any amount starts it.',
        concept: FinanceConcept.emergencyFund,
      ),
    );
  } else if (facts.cushionYears >= 3) {
    findings.add(
      LifeFinding(
        id: 'real_cushion',
        priority: 55,
        kind: LifeFindingKind.strength,
        area: LifeArea.saving,
        title: 'You built a real cushion',
        evidence:
            'Your emergency fund covered about '
            '${facts.cushionYears.toStringAsFixed(1)} years of costs.',
        action:
            'That is the thing that turns a bad event into an inconvenience. '
            'Keep it before you chase returns.',
        concept: FinanceConcept.emergencyFund,
      ),
    );
  }

  if (tally.incomeTotal > 0 && tally.adultYears >= 8) {
    if (tally.savingsRate >= 0.15) {
      findings.add(
        LifeFinding(
          id: 'saved_well',
          priority: 60,
          kind: LifeFindingKind.strength,
          area: LifeArea.saving,
          title: 'You paid yourself first',
          evidence:
              'You saved ${_pct(tally.savingsRate)} of everything you earned '
              'across ${tally.workYears} working years.',
          action:
              'That is the 20% in 50/30/20 doing its job. Automate it and it '
              'stops being a decision.',
          concept: FinanceConcept.payYourselfFirst,
        ),
      );
    } else if (tally.savingsRate < 0.05) {
      findings.add(
        LifeFinding(
          id: 'saved_little',
          priority: 55,
          kind: LifeFindingKind.watch,
          area: LifeArea.saving,
          title: 'Almost nothing put aside',
          evidence:
              'You saved ${_pct(tally.savingsRate)} of everything you earned '
              'over ${tally.workYears} working years.',
          action:
              'Set the split on your first paycheck and give savings a real '
              'slice. What you do not see, you do not spend.',
          concept: FinanceConcept.payYourselfFirst,
        ),
      );
    }
  }

  if (!facts.budgetSet && facts.age >= 20) {
    findings.add(
      LifeFinding(
        id: 'never_budgeted',
        priority: 40,
        kind: LifeFindingKind.fix,
        area: LifeArea.saving,
        title: 'You never set a budget',
        evidence: 'You reached ${facts.age} without setting one, not once.',
        action:
            'Set one the first year you are paid. It decides what happens to '
            'every wage after it, so skipping it is a decision too.',
        concept: FinanceConcept.budgetRule,
      ),
    );
  }

  if (facts.everStarved) {
    findings.add(
      LifeFinding(
        id: 'went_hungry',
        priority: 95,
        kind: LifeFindingKind.fix,
        area: LifeArea.saving,
        title: 'You went hungry',
        evidence:
            'This run went without food, and finished on ${facts.health} '
            'health.',
        action:
            'Needs come out of the budget before wants. A plan that cuts '
            'food is one you abandon by Thursday.',
        concept: FinanceConcept.needsVsWants,
      ),
    );
  }

  if (tally.shocksHit >= 1) {
    final borrowed = tally.shocksHit - tally.shocksCovered;
    if (borrowed > 0) {
      findings.add(
        LifeFinding(
          id: 'shocks_borrowed',
          priority: 70,
          kind: LifeFindingKind.fix,
          area: LifeArea.saving,
          title: 'Bills you had to borrow for',
          evidence:
              '$borrowed of the ${tally.shocksHit} unexpected bills in this '
              'life had to be borrowed, because nothing was set aside.',
          action:
              'An emergency fund is what turns a bill into an inconvenience. '
              'Build it before anything else.',
          concept: FinanceConcept.emergencyFund,
        ),
      );
    } else if (tally.shocksHit >= 2) {
      findings.add(
        LifeFinding(
          id: 'shocks_covered',
          priority: 50,
          kind: LifeFindingKind.strength,
          area: LifeArea.saving,
          title: 'Every bill was covered',
          evidence:
              'You were hit by ${tally.shocksHit} unexpected bills and paid '
              'every one without borrowing.',
          action:
              'That is exactly what savings are for. It is why the fund '
              'comes before the returns.',
          concept: FinanceConcept.emergencyFund,
        ),
      );
    }
  }

  // ---- Debt --------------------------------------------------------------
  //
  // Measured against what was owned, because 500 owed on 50,000 is a
  // different life from 500 owed on nothing.
  final owned = facts.cash + facts.investments + facts.emergencyFund;
  final debtRatio = owned <= 0
      ? (facts.debt > 0 ? 1.0 : 0.0)
      : facts.debt / (owned + facts.debt);
  var debtScore = _clamp100((1 - debtRatio) * 100);
  if (tally.incomeTotal > 0 && tally.interestPaid > 0) {
    // Interest already paid is a cost even if the debt is gone by the end.
    debtScore = _clamp100(
      debtScore - (tally.interestPaid / tally.incomeTotal * 300).clamp(0, 30),
    );
  }

  if (facts.debt > 0 && debtRatio > 0.25) {
    findings.add(
      LifeFinding(
        id: 'ended_in_debt',
        priority: 80,
        kind: LifeFindingKind.fix,
        area: LifeArea.debt,
        title: 'The debt outlived you',
        evidence:
            'You finished owing ${facts.debt}, which is '
            '${(debtRatio * 100).round()}% of everything you had.',
        action:
            'Open Money and pay back what you owe before you invest. Interest '
            'you owe is guaranteed; returns are not.',
        concept: FinanceConcept.interestCost,
      ),
    );
  } else if (facts.debt == 0 && facts.age >= 30) {
    findings.add(
      LifeFinding(
        id: 'debt_free',
        priority: 40,
        kind: LifeFindingKind.strength,
        area: LifeArea.debt,
        title: 'You owed nobody',
        evidence: 'You reached ${facts.age} owing nothing at all.',
        action:
            'Worth protecting. Borrowing is easiest to take on in exactly '
            'the years it is hardest to pay back.',
        concept: FinanceConcept.interestCost,
      ),
    );
  }

  if (tally.interestPaid >= 100) {
    findings.add(
      LifeFinding(
        id: 'interest_cost',
        priority: 50,
        kind: LifeFindingKind.fix,
        area: LifeArea.debt,
        title: 'Interest was the real cost',
        evidence:
            'Borrowing cost you ${tally.interestPaid} in interest over this '
            'life. That is what paying later costs.',
        action:
            'Borrowing costs about 18% a year here. Pay it back from Money '
            'before you spend on wants.',
        concept: FinanceConcept.interestCost,
      ),
    );
  }

  if (tally.debtRepaid > 0) {
    findings.add(
      LifeFinding(
        id: 'paid_it_down',
        priority: 45,
        kind: LifeFindingKind.strength,
        area: LifeArea.debt,
        title: 'You paid back what you borrowed',
        evidence:
            'You chose to pay back ${tally.debtRepaid} of what you owed, '
            'on top of what your budget took.',
        action:
            'Keep doing it. Paying off a debt that costs 18% a year is a '
            'guaranteed return, which nothing else here offers.',
        concept: FinanceConcept.interestCost,
      ),
    );
  }

  // ---- Growth ------------------------------------------------------------
  //
  // Cash that never gets invested loses quietly to inflation, which is the
  // slowest and least visible way to lose money in this game.
  final investedShare = owned <= 0 ? 0.0 : facts.investments / owned;
  final growthScore = _clamp100(investedShare * 160);

  if (facts.investments <= 0 && facts.cash >= 2000) {
    findings.add(
      LifeFinding(
        id: 'all_in_cash',
        priority: 30,
        kind: LifeFindingKind.watch,
        area: LifeArea.growth,
        title: 'It all sat in cash',
        evidence:
            'You finished with ${facts.cash} in cash and nothing invested.',
        action:
            'Once the cushion is there, put a slice to work. Money that sits '
            'still loses to prices going up.',
        concept: FinanceConcept.compoundGrowth,
      ),
    );
  } else if (investedShare >= 0.4 && facts.emergencyFund > 0) {
    findings.add(
      LifeFinding(
        id: 'money_working',
        priority: 45,
        kind: LifeFindingKind.strength,
        area: LifeArea.growth,
        title: 'Your money worked too',
        evidence:
            '${(investedShare * 100).round()}% of what you owned was '
            'invested, with a cushion still in place.',
        action:
            'That order is the whole trick. Cushion first, then growth, not '
            'the other way round.',
        concept: FinanceConcept.compoundGrowth,
      ),
    );
  }

  // ---- Career ------------------------------------------------------------
  //
  // Only for a life with a working stretch to talk about. A child who died at
  // nine has no career to grade, and a zero would be a false one.
  int? careerScore;
  if (tally.hadWorkingLife) {
    final employedShare = tally.workYears / tally.adultYears;
    final missedShare = tally.workYears == 0
        ? 0.0
        : tally.weeksMissed / (tally.workYears * 52);
    careerScore = _clamp100(
      employedShare * 70 +
          (tally.raises.clamp(0, 4)) * 5 +
          (tally.weeksMissed == 0 ? 10 : 0) -
          tally.timesLaidOff * 15 -
          (missedShare * 100).clamp(0, 30),
    );

    if (tally.timesLaidOff > 0) {
      findings.add(
        LifeFinding(
          id: 'laid_off',
          priority: 90,
          kind: LifeFindingKind.fix,
          area: LifeArea.career,
          title: 'Missed work cost you the job',
          evidence:
              'You missed about ${tally.weeksMissed} weeks of work and were '
              'let go ${tally.timesLaidOff == 1 ? 'once' : '${tally.timesLaidOff} times'}.',
          action:
              'Health and mood are part of holding a job. Rest, a check-up '
              'and time with people all protect your shifts.',
          concept: FinanceConcept.incomeVsWealth,
        ),
      );
    } else if (tally.weeksMissed >= 8) {
      findings.add(
        LifeFinding(
          id: 'missed_work',
          priority: 50,
          kind: LifeFindingKind.watch,
          area: LifeArea.career,
          title: 'You lost pay to missed work',
          evidence:
              'About ${tally.weeksMissed} weeks of work were missed across '
              '${tally.workYears} working years, and paid for accordingly.',
          action:
              'Look after your health and mood before they cost you shifts. '
              'A check-up is cheaper than a lost month.',
          concept: FinanceConcept.incomeVsWealth,
        ),
      );
    }

    if (tally.yearsUnemployed >= 5) {
      findings.add(
        LifeFinding(
          id: 'long_gap',
          priority: 45,
          kind: LifeFindingKind.watch,
          area: LifeArea.career,
          title: 'Years without a paycheck',
          evidence:
              '${tally.yearsUnemployed} of your ${tally.adultYears} adult '
              'years started without a job.',
          action:
              'Use the job board in town and the people you know. Leads come '
              'from other people far more often than from forms.',
          concept: FinanceConcept.incomeVsWealth,
        ),
      );
    }

    if (tally.raises >= 2) {
      findings.add(
        LifeFinding(
          id: 'raises_earned',
          priority: 45,
          kind: LifeFindingKind.strength,
          area: LifeArea.career,
          title: 'You kept getting paid more',
          evidence:
              'Your pay rose ${tally.raises} times, through effort, asking '
              'and people who spoke for you.',
          action:
              'Ask once a year and keep your health up. Both paid off here.',
          concept: FinanceConcept.incomeVsWealth,
        ),
      );
    }
  }

  // ---- School, work, and what you own --------------------------------------
  //
  // The parts of a life that were added late and now carry the most money: what
  // studying cost and what it bought, whether the work led anywhere, and what
  // was left standing at the end. Each one is worded so that a choice that was
  // a fair trade is not called a mistake: a degree that was borrowed for and
  // paid for is a strength here, and one that was borrowed for and never cleared
  // is the fault.
  final borrowedForSchool = tally.studentBorrowed;
  if (borrowedForSchool >= 1500 && facts.loanBalance > 0) {
    findings.add(
      LifeFinding(
        id: 'school_debt_carried',
        priority: 70,
        kind: LifeFindingKind.fix,
        area: LifeArea.debt,
        title: 'School was borrowed for and not cleared',
        evidence:
            'You borrowed $borrowedForSchool to study and still owed '
            '${facts.loanBalance} on loans when the run ended.',
        action:
            'Look at the pay a course leads to before you sign, or start at a '
            'state school or a trade. Paying a loan down in the Assets tab '
            'stops the interest stacking up.',
        concept: FinanceConcept.interestCost,
      ),
    );
  } else if (borrowedForSchool >= 1500 && facts.loanBalance == 0) {
    findings.add(
      LifeFinding(
        id: 'school_debt_cleared',
        priority: 40,
        kind: LifeFindingKind.strength,
        area: LifeArea.debt,
        title: 'You borrowed for school and paid it off',
        evidence:
            'You borrowed $borrowedForSchool to study and owed nothing on '
            'loans by the end.',
        action:
            'That is what a student loan is for: it moves the cost to when '
            'you can carry it. Keep doing it in that order.',
        concept: FinanceConcept.interestCost,
      ),
    );
  }

  if (tally.degreesEarned >= 1 && tally.promotions >= 1) {
    findings.add(
      LifeFinding(
        id: 'qualification_paid',
        priority: 45,
        kind: LifeFindingKind.strength,
        area: LifeArea.career,
        title: 'Your qualification opened doors',
        evidence:
            'You finished ${tally.degreesEarned} '
            '${tally.degreesEarned == 1 ? 'qualification' : 'qualifications'} '
            'and were promoted ${tally.promotions} '
            '${tally.promotions == 1 ? 'time' : 'times'}.',
        action:
            'Study that leads onto a career ladder pays back for decades. '
            'Spend on it on purpose, and check where it leads first.',
        concept: FinanceConcept.opportunityCost,
      ),
    );
  }

  if (tally.workYears >= 12 &&
      tally.promotions == 0 &&
      tally.timesLaidOff == 0) {
    findings.add(
      LifeFinding(
        id: 'stuck_on_a_rung',
        priority: 40,
        kind: LifeFindingKind.watch,
        area: LifeArea.career,
        title: 'You never moved up',
        evidence: '${tally.workYears} working years and not one promotion.',
        action:
            'Work Harder in the Occupation tab lifts how the job is going, '
            'and once it is high enough you can ask for a promotion. A better '
            'qualification opens the next ladder up.',
        concept: FinanceConcept.incomeVsWealth,
      ),
    );
  }

  if (facts.age >= 30 &&
      facts.loanBalance > 0 &&
      facts.loanBalance > facts.assetsValue) {
    findings.add(
      LifeFinding(
        id: 'owed_more_than_owned',
        priority: 75,
        kind: LifeFindingKind.fix,
        area: LifeArea.debt,
        title: 'You owed more than you owned',
        evidence:
            'Loans of ${facts.loanBalance} against ${facts.assetsValue} of '
            'things you owned.',
        action:
            'A loan on something that loses value stays behind after the '
            'thing is gone. Put more down, borrow for fewer years, or buy '
            'cheaper.',
        concept: FinanceConcept.sunkCost,
      ),
    );
  } else if (facts.ownsHome && facts.assetsValue > facts.loanBalance) {
    findings.add(
      LifeFinding(
        id: 'owned_something',
        priority: 42,
        kind: LifeFindingKind.strength,
        area: LifeArea.growth,
        title: 'You owned a home',
        evidence:
            'You finished owning things worth ${facts.assetsValue}, with '
            '${facts.loanBalance} still owed on loans.',
        action:
            'A home is a bill and an asset at once. When the loan is gone the '
            'place is yours and the rent goes with it.',
        concept: FinanceConcept.incomeVsWealth,
      ),
    );
  }

  // ---- People ------------------------------------------------------------
  int? peopleScore;
  if (facts.connection != null && facts.age >= 16) {
    final personal = facts.connection!.clamp(0, 100);
    peopleScore = facts.age >= 18
        ? _clamp100(personal * 0.6 + facts.networkStrength * 0.4)
        : _clamp100(personal.toDouble());

    if (tally.referrals >= 1) {
      findings.add(
        LifeFinding(
          id: 'network_paid',
          priority: 50,
          kind: LifeFindingKind.strength,
          area: LifeArea.people,
          title: 'Knowing people paid off',
          evidence:
              'Your network passed you ${tally.referrals} '
              '${tally.referrals == 1 ? 'lead' : 'leads'}, from ${tally.contactsMade} '
              'contacts made.',
          action:
              'That is what a network is worth. Keep contacts warm with a '
              'coffee and they keep sending work your way.',
          concept: FinanceConcept.incomeVsWealth,
        ),
      );
    } else if (facts.age >= 28 && tally.contactsMade == 0) {
      findings.add(
        LifeFinding(
          id: 'no_network',
          priority: 35,
          kind: LifeFindingKind.watch,
          area: LifeArea.people,
          title: 'You never built a network',
          evidence:
              'You reached ${facts.age} without making a single work contact.',
          action:
              'Go to one networking event a year and talk to people in town. '
              'Most work is found through somebody who knows somebody.',
          concept: FinanceConcept.incomeVsWealth,
        ),
      );
    }

    if (personal >= 65 &&
        facts.age >= 25 &&
        (facts.hasPartner || facts.children > 0)) {
      findings.add(
        LifeFinding(
          id: 'held_together',
          priority: 35,
          kind: LifeFindingKind.strength,
          area: LifeArea.people,
          title: 'The people around you held',
          evidence:
              'Your closest people finished at $personal out of 100'
              '${facts.children > 0 ? ', with ${facts.children} '
                        '${facts.children == 1 ? 'child' : 'children'}' : ''}.',
          action:
              'Time is what does that, and it costs nothing. The people are '
              'what the money was for.',
        ),
      );
    }

    if (personal < 25 && facts.age >= 25) {
      findings.add(
        LifeFinding(
          id: 'faded_people',
          priority: 40,
          kind: LifeFindingKind.watch,
          area: LifeArea.people,
          title: 'The people faded',
          evidence:
              'Your closest relationships had drifted to $personal out of 100 '
              'by the time you were ${facts.age}.',
          action:
              'Time is the one thing that repairs a relationship, and it is '
              'free. A day together beats any present.',
        ),
      );
    }
  }

  // ---- Learning ----------------------------------------------------------
  final learningScore = facts.conceptsAvailable <= 0
      ? 0
      : _clamp100((facts.conceptsMet / facts.conceptsAvailable) * 100);

  if (facts.conceptsMet <= 2 && facts.age >= 30) {
    findings.add(
      LifeFinding(
        id: 'skipped_the_ideas',
        priority: 20,
        kind: LifeFindingKind.watch,
        area: LifeArea.learning,
        title: 'You clicked past the ideas',
        evidence:
            'This life met ${facts.conceptsMet} of '
            '${facts.conceptsAvailable} money ideas.',
        action:
            'The events that explain something are the ones that pay later. '
            'Read one all the way through next run.',
      ),
    );
  } else if (learningScore >= 60) {
    findings.add(
      LifeFinding(
        id: 'met_the_ideas',
        priority: 30,
        kind: LifeFindingKind.strength,
        area: LifeArea.learning,
        title: 'You met most of the ideas',
        evidence:
            '${facts.conceptsMet} of ${facts.conceptsAvailable} concepts came '
            'up and stuck.',
        action: 'Those unlock the powers that make the next run easier.',
      ),
    );
  }

  // ---- Health, which is not an area but ends runs -------------------------
  if (facts.died && facts.age < 55) {
    findings.add(
      LifeFinding(
        id: 'ended_early',
        priority: 60,
        kind: LifeFindingKind.watch,
        area: LifeArea.saving,
        title: 'The run ended early',
        evidence: 'You died at ${facts.age}, so the money never had time.',
        action:
            'Health is the multiplier on every plan. Spending on it early '
            'buys the years the plan needs.',
      ),
    );
  }

  // Sorted by seriousness, then by cost, then by the order they were found.
  // `List.sort` is not guaranteed stable, so the order is carried explicitly.
  final ordered =
      <(int, LifeFinding)>[
        for (var i = 0; i < findings.length; i++) (i, findings[i]),
      ]..sort((a, b) {
        final byKind = a.$2.kind.index.compareTo(b.$2.kind.index);
        if (byKind != 0) return byKind;
        // The costliest first, then the order the rules found them in.
        final byCost = b.$2.priority.compareTo(a.$2.priority);
        return byCost != 0 ? byCost : a.$1.compareTo(b.$1);
      });
  final sorted = <LifeFinding>[for (final entry in ordered) entry.$2];

  final scores = <LifeArea, int>{
    LifeArea.saving: savingScore,
    LifeArea.debt: debtScore,
    LifeArea.growth: growthScore,
    if (careerScore != null) LifeArea.career: careerScore,
    if (peopleScore != null) LifeArea.people: peopleScore,
    LifeArea.learning: learningScore,
  };

  return LifeDebrief(
    scores: scores,
    findings: sorted,
    headline: _headline(facts, sorted),
    story: _buildStory(facts.record.moments),
    record: facts.record,
    nextRun: _nextRun(_weakestOf(scores)),
  );
}

/// The lowest-scoring area, or null when nothing was graded.
LifeArea? _weakestOf(Map<LifeArea, int> scores) {
  if (scores.isEmpty) return null;
  var worst = scores.entries.first;
  for (final entry in scores.entries) {
    if (entry.value < worst.value) worst = entry;
  }
  return worst.key;
}

/// Turns the moments a life remembered into the story the debrief tells.
LifeStory _buildStory(List<LifeMoment> moments) {
  if (moments.isEmpty) return const LifeStory();

  final decisions = moments
      .where((m) => m.kind == LifeMomentKind.decision)
      .toList();

  final regrets = decisions.where((m) => m.regret >= 60).toList()
    ..sort((a, b) => b.regret.compareTo(a.regret));

  LifeMoment? bestCall;
  for (final m in decisions) {
    if (!m.tookTheBest || m.edge < 60) continue;
    if (bestCall == null || m.edge > bestCall.edge) bestCall = m;
  }

  LifeMoment? biggestHit;
  for (final m in moments) {
    if (m.moneyDelta >= -80) continue;
    if (biggestHit == null || m.moneyDelta < biggestHit.moneyDelta) {
      biggestHit = m;
    }
  }

  return LifeStory(
    turningPoint: regrets.isNotEmpty ? regrets.first : biggestHit,
    regrets: regrets.take(3).toList(),
    bestCall: bestCall,
    biggestHit: biggestHit,
    moneyLeftOnTable: decisions.fold<int>(0, (sum, m) => sum + m.regret),
  );
}

/// One concrete challenge, aimed at the area the run was weakest in.
///
/// A number in every one, because "try to save more" is advice anybody could
/// have given before the player pressed start and a target is something a run
/// can be played against.
String _nextRun(LifeArea? weakest) => switch (weakest) {
  LifeArea.saving =>
    'Build a cushion of three years of costs, about 3,600 coins, before you '
        'turn 35.',
  LifeArea.debt =>
    'Finish the whole life without carrying a balance for more than one year.',
  LifeArea.growth =>
    'Once your cushion is set, put a slice of every paycheck into '
        'investments and leave it for thirty years.',
  LifeArea.career =>
    'Keep Health above 40 and ask for a raise once every year of your '
        'working life.',
  LifeArea.people =>
    'Go to two networking events a year, and keep at least one contact warm '
        'with a coffee every year.',
  LifeArea.learning =>
    'Read every money idea all the way through. Each one you meet unlocks a '
        'power for the years after it.',
  null => '',
};

String _headline(LifeRunFacts facts, List<LifeFinding> findings) {
  final faults = findings.where((f) => f.kind == LifeFindingKind.fix).length;
  if (faults == 0 && facts.netWorth > 0) {
    return 'A clean run. Nothing here cost you money you could have kept.';
  }
  if (faults >= 3) {
    return 'A rough one, and every part of it is fixable. Start with the '
        'first line below.';
  }
  if (facts.netWorth <= 0) {
    return 'You finished with nothing left. The lines below are where it '
        'went.';
  }
  return 'A decent life with ${faults == 1 ? 'one habit' : '$faults habits'} '
      'worth changing.';
}
