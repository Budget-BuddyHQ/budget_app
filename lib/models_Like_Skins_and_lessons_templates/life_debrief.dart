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
/// on. Four areas can: a player who scores well on saving and badly on growth
/// has a different next run from one who did the reverse.
library;

import 'finance_concepts.dart';

/// The four things a life is graded on.
enum LifeArea {
  /// Did money get put aside at all, and was there a cushion at the end.
  saving,

  /// Was money borrowed, and was it still owed when the life ended.
  debt,

  /// Was anything put to work, or did it all sit in cash.
  growth,

  /// Did the run meet the ideas the game teaches.
  learning,
}

extension LifeAreaInfo on LifeArea {
  String get label => switch (this) {
    LifeArea.saving => 'Saving',
    LifeArea.debt => 'Debt',
    LifeArea.growth => 'Growing it',
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
  });

  final String id;
  final LifeFindingKind kind;
  final LifeArea area;

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

  /// Everything owned minus everything owed, as the game counts it.
  int get worth => netWorth;

  /// Roughly how many years of a modest life the cushion covers. Uses the
  /// same 1,200-a-year figure the sim uses for basic living costs.
  double get cushionYears => emergencyFund / 1200;
}

/// The finished debrief.
class LifeDebrief {
  const LifeDebrief({
    required this.scores,
    required this.findings,
    required this.headline,
  });

  /// 0..100 per area.
  final Map<LifeArea, int> scores;

  /// Ordered fix, then watch, then strength, so a player who reads one line
  /// reads the one that cost them something.
  final List<LifeFinding> findings;

  /// One sentence about the run as a whole.
  final String headline;

  /// The average of the four areas, which is what the letter comes from.
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
}

int _clamp100(num value) => value.clamp(0, 100).round();

/// Grades one finished life.
///
/// Every rule reads a number this run produced. Nothing here looks at other
/// runs, at the player's account, or at how long they have had the app.
LifeDebrief debriefLife(LifeRunFacts facts) {
  final findings = <LifeFinding>[];

  // ---- Saving ------------------------------------------------------------
  //
  // Three months of costs is the figure every source in the Academy uses, so
  // three years of the sim's living costs is the full score here.
  final savingScore = _clamp100((facts.cushionYears / 3) * 100);

  if (facts.emergencyFund <= 0 && facts.age >= 25) {
    findings.add(
      LifeFinding(
        id: 'no_cushion',
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

  if (!facts.budgetSet && facts.age >= 20) {
    findings.add(
      LifeFinding(
        id: 'never_budgeted',
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

  // ---- Debt --------------------------------------------------------------
  //
  // Measured against what was owned, because 500 owed on 50,000 is a
  // different life from 500 owed on nothing.
  final owned = facts.cash + facts.investments + facts.emergencyFund;
  final debtRatio = owned <= 0
      ? (facts.debt > 0 ? 1.0 : 0.0)
      : facts.debt / (owned + facts.debt);
  final debtScore = _clamp100((1 - debtRatio) * 100);

  if (facts.debt > 0 && debtRatio > 0.25) {
    findings.add(
      LifeFinding(
        id: 'ended_in_debt',
        kind: LifeFindingKind.fix,
        area: LifeArea.debt,
        title: 'The debt outlived you',
        evidence:
            'You finished owing ${facts.debt}, which is '
            '${(debtRatio * 100).round()}% of everything you had.',
        action:
            'Clear the highest-cost debt before investing. Interest you owe '
            'is guaranteed; returns are not.',
        concept: FinanceConcept.interestCost,
      ),
    );
  } else if (facts.debt == 0 && facts.age >= 30) {
    findings.add(
      LifeFinding(
        id: 'debt_free',
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

  // ---- Learning ----------------------------------------------------------
  final learningScore = facts.conceptsAvailable <= 0
      ? 0
      : _clamp100((facts.conceptsMet / facts.conceptsAvailable) * 100);

  if (facts.conceptsMet <= 2 && facts.age >= 30) {
    findings.add(
      LifeFinding(
        id: 'skipped_the_ideas',
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

  findings.sort((a, b) => a.kind.index.compareTo(b.kind.index));

  final scores = <LifeArea, int>{
    LifeArea.saving: savingScore,
    LifeArea.debt: debtScore,
    LifeArea.growth: growthScore,
    LifeArea.learning: learningScore,
  };

  return LifeDebrief(
    scores: scores,
    findings: findings,
    headline: _headline(facts, findings),
  );
}

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
  return 'A decent life with one habit worth changing.';
}
