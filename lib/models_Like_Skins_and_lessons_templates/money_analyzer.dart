import 'finance_concepts.dart';

// looks at what someone actually did in the app and gives ONE useful
// takeaway, not another stats screen. every finding has: a real number
// from their own data, one small action, and a concept to link back to
// the academy lesson. pure dart, no flutter/storage, so its easy to test

// how serious a finding is
enum MoneyFindingKind {
  // theyre already doing this well, worth calling out
  strength,

  // worth watching, not costing them anything yet
  watch,

  // actually going wrong, with a number to back it up
  fix,
}

// the areas we score separately, cause you can be consistent and broke,
// or good with money and not understand any of it. one score wouldve
// hidden which part is actually the weak one
enum MoneyDimension {
  // do they show up? logging days, gaps, streaks
  consistency,

  // is money actually moving, not just habit points
  saving,

  // do they finish what they start
  followThrough,

  // do they get it? lesson + quiz accuracy
  learning,

  // are they actually engaging with decisions, town/lives/variety
  exposure,
}

extension MoneyDimensionInfo on MoneyDimension {
  String get label => switch (this) {
    MoneyDimension.consistency => 'Showing up',
    MoneyDimension.saving => 'Money moving',
    MoneyDimension.followThrough => 'Finishing',
    MoneyDimension.learning => 'Understanding',
    MoneyDimension.exposure => 'Trying things',
  };

  // what a low score here actually means
  String get weakness => switch (this) {
    MoneyDimension.consistency => 'You come back in bursts, then stop.',
    MoneyDimension.saving => 'The habits are happening, the money is not.',
    MoneyDimension.followThrough => 'You start more than you finish.',
    MoneyDimension.learning => 'You are doing it without reading why.',
    MoneyDimension.exposure => 'You have only met a corner of this.',
  };
}

// one finished life, how the coach reads it. net worth alone doesnt say
// WHY a life went well or bad, so this tracks school/work/debt/home stuff
// too so the coach can point at something the player can actually change
class LifeReading {
  const LifeReading({
    required this.age,
    required this.netWorth,
    required this.happiness,
    this.degrees = 0,
    this.borrowedForSchool = 0,
    this.promotions = 0,
    this.workYears = 0,
    this.assetsValue = 0,
    this.loansOwed = 0,
    this.ownedHome = false,
    this.hadPartner = false,
    this.children = 0,
  });

  final int age;
  final int netWorth;
  final int happiness;
  final int degrees;
  final int borrowedForSchool;
  final int promotions;
  final int workYears;
  final int assetsValue;

  // loans + borrowed cash combined, at the end
  final int loansOwed;
  final bool ownedHome;
  final bool hadPartner;
  final int children;

  // borrowed for school and still owed money when the life ended
  bool get schoolDebtLeft => borrowedForSchool >= 1500 && loansOwed > 0;

  // owed more than they owned
  bool get underwater => loansOwed > 0 && loansOwed > assetsValue;

  // worked long enough that a promotion shouldve happened, and didnt
  bool get stalled => workYears >= 12 && promotions == 0;
}

// everything the analyzer can see. flat numbers, not the actual controllers,
// so the rules can run without supabase/storage/widgets attached
class MoneySnapshot {
  const MoneySnapshot({
    this.loggedDaysLast14 = 0,
    this.daysSinceLastLog = neverLogged,
    this.longestStreak = 0,
    this.pinnedHabits = 0,
    this.habitsLoggedLast14 = 0,
    this.moneySaved = 0,
    this.choicesKept = 0,
    this.jarXp = 0,
    this.lessonsCompleted = 0,
    this.lessonsAvailable = 0,
    this.conceptAccuracy = const <FinanceConcept, double>{},
    this.pastLifeNetWorths = const <int>[],
    this.townSpotsVisited = 0,
    this.townSpotsAvailable = 0,
    this.challengesStarted = 0,
    this.challengesFinished = 0,
    this.cascadeRuns = 0,
    this.cascadeLevelsCleared = 0,
    this.cascadeWantsShare = 0,
    this.cascadeSavesShare = 0,
    this.distinctEndings = 0,
    this.lives = const <LifeReading>[],
  });

  // graded lives w/ full detail, newest first
  final List<LifeReading> lives;

  // sentinel for "never logged anything". cant be 0, thats "logged today"
  static const int neverLogged = 999;

  final int loggedDaysLast14;
  final int daysSinceLastLog;
  final int longestStreak;

  final int pinnedHabits;

  // distinct habits actually logged in the last 2 weeks vs pinnedHabits
  final int habitsLoggedLast14;

  final double moneySaved;
  final double choicesKept;
  final int jarXp;

  final int lessonsCompleted;
  final int lessonsAvailable;

  // best accuracy per concept 0..1. missing = never tested, not a 0
  final Map<FinanceConcept, double> conceptAccuracy;

  // net worth at the end of each finished life, newest first
  final List<int> pastLifeNetWorths;

  final int townSpotsVisited;
  final int townSpotsAvailable;

  final int challengesStarted;
  final int challengesFinished;

  // coin cascade runs + how the board got split. this game is basically
  // 50/30/20 with no labels on it, so its the most honest behavior data
  // we have, way better than a quiz answer. shares are 0..1, averaged
  final int cascadeRuns;
  final int cascadeLevelsCleared;
  final double cascadeWantsShare;
  final double cascadeSavesShare;

  // enough runs to be a pattern, not just one bad day
  bool get hasCascadeHistory => cascadeRuns >= 2;

  // different life endings reached. someone chasing endings on purpose
  // gets poorer runs, dont want to scold them for that
  final int distinctEndings;

  bool get hasEverLogged => daysSinceLastLog < neverLogged;

  // basically no history yet, every rule below would fire and be useless
  bool get isNewcomer =>
      !hasEverLogged &&
      pinnedHabits == 0 &&
      lessonsCompleted == 0 &&
      pastLifeNetWorths.isEmpty;
}

// one thing the analyzer noticed
class MoneyFinding {
  const MoneyFinding({
    required this.id,
    required this.kind,
    required this.dimension,
    required this.title,
    required this.evidence,
    required this.action,
    this.concept,
    this.showsBudgetHowTo = false,
  });

  /// Whether the advice is "set your budget in Life", and the card should
  /// offer the how-to. A younger tester read that advice and could not find
  /// where to do it. See `how_to_budget.dart`.
  final bool showsBudgetHowTo;

  // stable key, safe to log/persist. never reuse one
  final String id;
  final MoneyFindingKind kind;
  final MoneyDimension dimension;

  // short phrase, what was noticed
  final String title;

  // the number from their data backing it up
  final String evidence;

  // one thing to do, small enough for today
  final String action;

  // hooks into the academy lesson, if theres one
  final FinanceConcept? concept;
}

// the full readout, score per area + findings behind them
class MoneyReport {
  const MoneyReport({
    required this.scores,
    required this.findings,
    required this.isNewcomer,
  });

  // 0..100 per area, kept separate on purpose (see MoneyDimension)
  final Map<MoneyDimension, int> scores;

  // ordered worst first so the useful line is the one they actually read
  final List<MoneyFinding> findings;

  // not enough history yet to say anything honest
  final bool isNewcomer;

  // weakest area, null if nothing scored yet
  MoneyDimension? get weakest {
    if (scores.isEmpty) return null;
    var worst = scores.entries.first;
    for (final entry in scores.entries) {
      if (entry.value < worst.value) worst = entry;
    }
    return worst.key;
  }

  // single line to show if theres only room for one
  MoneyFinding? get headline => findings.isEmpty ? null : findings.first;
}

// turns a snapshot into a report. rules stay quiet on thin data, a
// brand new player shouldnt get hit with 5 "youre failing" findings at once
MoneyReport analyzeMoney(MoneySnapshot snap) {
  final findings = <MoneyFinding>[];

  if (snap.isNewcomer) {
    return MoneyReport(
      isNewcomer: true,
      scores: const <MoneyDimension, int>{},
      findings: const <MoneyFinding>[
        MoneyFinding(
          id: 'start_here',
          kind: MoneyFindingKind.watch,
          dimension: MoneyDimension.consistency,
          title: 'Nothing to analyze yet',
          evidence: 'No habits saved, no lessons finished, no lives played.',
          action:
              'Save one habit on Track and log it once. Come back after '
              'a few days and this will have something real to say.',
        ),
      ],
    );
  }

  // ---- Showing up -------------------------------------------------------
  final consistency = _score(snap.loggedDaysLast14, 10);
  if (snap.hasEverLogged && snap.daysSinceLastLog >= 5) {
    findings.add(
      MoneyFinding(
        id: 'lapsed',
        kind: MoneyFindingKind.fix,
        dimension: MoneyDimension.consistency,
        title: 'The streak has gone cold',
        evidence: _gap(snap.daysSinceLastLog),
        action:
            'Log one habit today. One is enough — the streak counts days '
            'you turned up, not days you were perfect.',
      ),
    );
  } else if (snap.loggedDaysLast14 >= 10) {
    findings.add(
      MoneyFinding(
        id: 'steady',
        kind: MoneyFindingKind.strength,
        dimension: MoneyDimension.consistency,
        title: 'You actually turn up',
        evidence:
            '${snap.loggedDaysLast14} of the last 14 days logged, '
            'longest run ${snap.longestStreak}.',
        action:
            'This is the part most people never get to. Protect it before '
            'you add anything new.',
      ),
    );
  }

  // ---- Finishing -----
  // pinning a habit is free, logging it isnt. big gap between the two
  // is the classic habit-app failure and its invisible unless you compare
  var followThrough = 100;
  if (snap.pinnedHabits >= 3) {
    followThrough = _score(snap.habitsLoggedLast14, snap.pinnedHabits);
    if (snap.habitsLoggedLast14 * 2 < snap.pinnedHabits) {
      findings.add(
        MoneyFinding(
          id: 'too_many_habits',
          kind: MoneyFindingKind.fix,
          dimension: MoneyDimension.followThrough,
          title: 'More habits pinned than kept',
          evidence:
              'You have ${snap.pinnedHabits} habits saved and logged '
              '${snap.habitsLoggedLast14} of them in the last fortnight.',
          action:
              'Unpin everything except the two you actually did. A short '
              'list you finish beats a long one you avoid opening.',
          concept: FinanceConcept.opportunityCost,
        ),
      );
    }
  }
  if (snap.challengesStarted >= 2 &&
      snap.challengesFinished * 2 < snap.challengesStarted) {
    findings.add(
      MoneyFinding(
        id: 'challenges_abandoned',
        kind: MoneyFindingKind.watch,
        dimension: MoneyDimension.followThrough,
        title: 'Challenges get started, not finished',
        evidence:
            '${snap.challengesFinished} finished out of '
            '${snap.challengesStarted} started.',
        action:
            'Pick the one you got furthest through and finish only that '
            'one before starting another.',
        concept: FinanceConcept.sunkCost,
      ),
    );
  }

  // ---- Money moving -----
  // habit points and streaks feel good but arent actual money. someone
  // couldve been a model user and still be no better off, catch that here
  final saving = _score(snap.moneySaved.round(), 200);
  if (snap.choicesKept >= 10 && snap.moneySaved < 5) {
    findings.add(
      MoneyFinding(
        id: 'motion_not_money',
        kind: MoneyFindingKind.fix,
        dimension: MoneyDimension.saving,
        title: 'Lots of ticks, almost no money',
        evidence:
            '${snap.choicesKept.round()} habits kept, and \$'
            '${snap.moneySaved.toStringAsFixed(0)} saved by them.',
        action:
            'Swap one tracking habit for one that has a number attached — '
            'skip a bought lunch, cancel one subscription. Ticks feel like '
            'progress; only the number is progress.',
        concept: FinanceConcept.payYourselfFirst,
      ),
    );
  } else if (snap.moneySaved >= 50) {
    findings.add(
      MoneyFinding(
        id: 'real_money',
        kind: MoneyFindingKind.strength,
        dimension: MoneyDimension.saving,
        title: 'These habits are worth real money',
        evidence:
            '\$${snap.moneySaved.toStringAsFixed(0)} saved across '
            '${snap.choicesKept.round()} kept choices.',
        action:
            'Give it a job. Money with no name attached gets spent — '
            'decide now what this is for.',
        concept: FinanceConcept.emergencyFund,
      ),
    );
  }

  // ---- Understanding -----
  final learning = snap.lessonsAvailable == 0
      ? 0
      : _score(snap.lessonsCompleted, (snap.lessonsAvailable * 0.4).round());

  final weakConcepts =
      snap.conceptAccuracy.entries.where((entry) => entry.value < 0.6).toList()
        ..sort((a, b) => a.value.compareTo(b.value));
  if (weakConcepts.isNotEmpty) {
    final worst = weakConcepts.first;
    findings.add(
      MoneyFinding(
        id: 'weak_concept_${worst.key.name}',
        kind: MoneyFindingKind.fix,
        dimension: MoneyDimension.learning,
        title: 'One idea keeps catching you out',
        evidence:
            'You are getting ${worst.key.label} right '
            '${(worst.value * 100).round()}% of the time — your lowest.',
        action:
            'Redo the ${worst.key.label} lesson. It is the shortest way '
            'to move every other number on this page.',
        concept: worst.key,
      ),
    );
  } else if (snap.conceptAccuracy.length >= 4) {
    findings.add(
      MoneyFinding(
        id: 'concepts_solid',
        kind: MoneyFindingKind.strength,
        dimension: MoneyDimension.learning,
        title: 'The ideas have landed',
        evidence:
            '${snap.conceptAccuracy.length} money ideas assessed, none '
            'below 60%.',
        action:
            'Go and use one. Understanding it and doing it are different '
            'skills and only the second one saves money.',
      ),
    );
  }

  // ---- Trying things -----
  final exposure = snap.townSpotsAvailable == 0
      ? 0
      : _score(snap.townSpotsVisited, snap.townSpotsAvailable);
  if (snap.townSpotsAvailable > 0 &&
      snap.townSpotsVisited * 3 < snap.townSpotsAvailable) {
    findings.add(
      MoneyFinding(
        id: 'town_unexplored',
        kind: MoneyFindingKind.watch,
        dimension: MoneyDimension.exposure,
        title: 'Most of the town is unopened',
        evidence:
            '${snap.townSpotsVisited} of ${snap.townSpotsAvailable} '
            'places visited.',
        action:
            'Walk into one you have never opened. Each building is a '
            'different money decision, and they change as you get older.',
      ),
    );
  }

  // Lives are the app's own evidence about whether any of this is working.
  if (snap.pastLifeNetWorths.length >= 2) {
    final newest = snap.pastLifeNetWorths.first;
    final previous = snap.pastLifeNetWorths[1];
    if (newest > previous) {
      // "you did better" still assumes richer = the goal, which isnt
      // true if theyre chasing endings on purpose. check for that too
      final chasingEndings =
          snap.distinctEndings >= 3 &&
          snap.distinctEndings >= snap.pastLifeNetWorths.length - 1;

      findings.add(
        MoneyFinding(
          id: 'lives_improving',
          kind: MoneyFindingKind.strength,
          dimension: MoneyDimension.exposure,
          title: chasingEndings
              ? 'A different ending, and richer for it'
              : 'Your last life went better than the one before',
          evidence: chasingEndings
              ? '${snap.distinctEndings} endings found, and net worth still '
                    'went $previous to $newest.'
              : 'Net worth $previous, then $newest.',
          action: chasingEndings
              ? 'You are exploring and building at the same time, which is '
                    'harder than either on its own. The unusual endings '
                    'normally cost money — this run did not.'
              : 'Whatever you did differently, do it again — and this time '
                    'notice which decision it was.',
          concept: FinanceConcept.compoundGrowth,
        ),
      );
    } else if (snap.pastLifeNetWorths.length >= 3) {
      // 3+ different endings = exploring on purpose, not failing to get
      // rich. dont scold for that
      final exploring =
          snap.distinctEndings >= 3 &&
          snap.distinctEndings >= snap.pastLifeNetWorths.length - 1;

      findings.add(
        exploring
            ? MoneyFinding(
                id: 'lives_exploring',
                kind: MoneyFindingKind.strength,
                dimension: MoneyDimension.exposure,
                title: 'You are playing for the endings, not the money',
                evidence:
                    '${snap.distinctEndings} different endings across '
                    '${snap.pastLifeNetWorths.length} lives.',
                action:
                    'Worth knowing what it costs: the runs that reach an '
                    'unusual ending finish poorer, and that is a real '
                    'trade rather than a mistake. Try one run where you '
                    'chase an ending *and* set your budget early — the two '
                    'are not opposites.',
                concept: FinanceConcept.opportunityCost,
                showsBudgetHowTo: true,
              )
            : MoneyFinding(
                id: 'lives_flat',
                kind: MoneyFindingKind.watch,
                dimension: MoneyDimension.exposure,
                title: 'Your lives are not getting richer',
                evidence:
                    'Last three finished at '
                    '${snap.pastLifeNetWorths.take(3).join(', ')}.',
                action:
                    'Next run, set your budget in your first working years '
                    'instead of your last ones. Almost all of the difference '
                    'is made early.',
                concept: FinanceConcept.compoundGrowth,
                showsBudgetHowTo: true,
              ),
      );
    }
  }

  // ---- Cross-domain rules -----
  // these compare TWO areas instead of one, catches stuff no single
  // screen can see on its own. added last so they win over duplicates

  // knowing the definition vs actually doing it are different skills.
  // good quiz score + bad cascade split = they only learned the definition
  final splitKnowledge = <FinanceConcept>[
    FinanceConcept.needsVsWants,
    FinanceConcept.budgetRule,
  ].map((c) => snap.conceptAccuracy[c]).whereType<double>().toList();
  final bestSplitScore = splitKnowledge.isEmpty
      ? null
      : splitKnowledge.reduce((a, b) => a > b ? a : b);

  if (snap.hasCascadeHistory) {
    final wantsPct = (snap.cascadeWantsShare * 100).round();
    final savesPct = (snap.cascadeSavesShare * 100).round();

    if (bestSplitScore != null &&
        bestSplitScore >= 0.8 &&
        snap.cascadeWantsShare >= 0.35) {
      findings.add(
        MoneyFinding(
          id: 'knows_split_plays_otherwise',
          kind: MoneyFindingKind.fix,
          dimension: MoneyDimension.learning,
          title: 'You can define the rule and you do not play it',
          evidence:
              'You score ${(bestSplitScore * 100).round()}% on needs versus '
              'wants, and across ${snap.cascadeRuns} Coin Cascade runs '
              'wants took $wantsPct% of your board.',
          action:
              'Next run, decide before you start that wants stay under a '
              'third — then watch the bills counter instead of the score. '
              'The rule is not the hard part; spending it is.',
          concept: FinanceConcept.budgetRule,
        ),
      );
    } else if (bestSplitScore == null && snap.cascadeLevelsCleared >= 3) {
      findings.add(
        MoneyFinding(
          id: 'plays_split_never_read_it',
          kind: MoneyFindingKind.watch,
          dimension: MoneyDimension.learning,
          title: 'You are good at this without knowing what it is called',
          evidence:
              'Cleared ${snap.cascadeLevelsCleared} Coin Cascade levels, '
              'and have never been assessed on the rule underneath them.',
          action:
              'Coin Cascade is 50/30/20 with the labels taken off. Take the '
              'Budgeting unit and you will recognize every part of it.',
          concept: FinanceConcept.budgetRule,
        ),
      );
    } else if (snap.cascadeSavesShare >= 0.2 && snap.cascadeWantsShare <= 0.3) {
      findings.add(
        MoneyFinding(
          id: 'split_healthy',
          kind: MoneyFindingKind.strength,
          dimension: MoneyDimension.saving,
          title: 'You budget like this when nothing is asking you to',
          evidence:
              'Across ${snap.cascadeRuns} runs: $savesPct% to savings, '
              '$wantsPct% to wants.',
          action:
              'That is a 50/30/20 split, arrived at by playing rather than '
              'by being told. It is the habit worth protecting.',
          concept: FinanceConcept.budgetRule,
        ),
      );
    }

    // same bad pattern showing up in 2 unrelated systems is worth flagging,
    // one high-wants run alone doesnt mean much but this does
    if (snap.cascadeWantsShare >= 0.4 &&
        snap.pastLifeNetWorths.length >= 3 &&
        snap.pastLifeNetWorths.first <= snap.pastLifeNetWorths[2]) {
      findings.add(
        MoneyFinding(
          id: 'wants_pattern_across_games',
          kind: MoneyFindingKind.fix,
          dimension: MoneyDimension.saving,
          title: 'The same habit is showing up in two different games',
          evidence:
              'Wants took $wantsPct% of your Coin Cascade boards, and your '
              'last three lives finished at '
              '${snap.pastLifeNetWorths.take(3).join(', ')}.',
          action:
              'These two games share no code and no rules. When a pattern '
              'appears in both, it is coming from you rather than from the '
              'game — which is the useful kind of bad news.',
          concept: FinanceConcept.opportunityCost,
        ),
      );
    }
  }

  // opposite problem: reading tons of lessons but never actually playing
  if (snap.lessonsCompleted >= 4 &&
      snap.cascadeRuns == 0 &&
      snap.pastLifeNetWorths.isEmpty) {
    findings.add(
      MoneyFinding(
        id: 'reads_never_plays',
        kind: MoneyFindingKind.watch,
        dimension: MoneyDimension.exposure,
        title: 'You have read more than you have decided',
        evidence:
            '${snap.lessonsCompleted} lessons finished, no lives played and '
            'no Coin Cascade runs.',
        action:
            'Play one life. The lessons will stop being facts and start '
            'being things you wish you had done earlier.',
        concept: FinanceConcept.opportunityCost,
      ),
    );
  }

  // ---- Lives, for what they were actually made of -----
  // needs 2+ lives showing the same thing. one life is a story, two is a
  // pattern. borrowing for school + paying it off is fine, only debt left
  // at the end counts against them
  final recent = snap.lives.take(4).toList();

  if (recent.length >= 2) {
    final indebted = recent.where((l) => l.schoolDebtLeft).length;
    if (indebted >= 2) {
      findings.add(
        MoneyFinding(
          id: 'school_debt_pattern',
          kind: MoneyFindingKind.fix,
          dimension: MoneyDimension.saving,
          title: 'Your studying keeps ending in debt',
          evidence:
              '$indebted of your last ${recent.length} lives borrowed for '
              'school and were still paying it back at the end.',
          action:
              'Next run, look at what a course pays before you enrol, or '
              'start with a trade or a state school. Then put spare money on '
              'the loan in the Assets tab in your first working years.',
          concept: FinanceConcept.interestCost,
        ),
      );
    }

    final underwater = recent.where((l) => l.underwater).length;
    if (underwater >= 2) {
      findings.add(
        MoneyFinding(
          id: 'owing_more_than_owning',
          kind: MoneyFindingKind.fix,
          dimension: MoneyDimension.saving,
          title: 'You keep finishing owing more than you own',
          evidence:
              '$underwater of your last ${recent.length} lives ended with '
              'more borrowed than owned.',
          action:
              'Pay the loan with the highest rate first, and buy the cheaper '
              'car. A loan on something that loses value is the one that '
              'outlasts it.',
          concept: FinanceConcept.sunkCost,
        ),
      );
    }

    final stalled = recent.where((l) => l.stalled).length;
    if (stalled >= 2) {
      findings.add(
        MoneyFinding(
          id: 'careers_stall',
          kind: MoneyFindingKind.watch,
          dimension: MoneyDimension.exposure,
          title: 'Your careers stay on one rung',
          evidence:
              '$stalled of your last ${recent.length} lives worked twelve '
              'years or more without one promotion.',
          action:
              'Use Work Harder in the Occupation tab, then ask for the '
              'promotion. If it still will not come, the job board is where a '
              'higher ladder is advertised.',
          concept: FinanceConcept.incomeVsWealth,
        ),
      );
    }

    final ended = recent.where((l) => l.age >= 40).toList();
    if (ended.length >= 3 && ended.every((l) => !l.ownedHome)) {
      findings.add(
        MoneyFinding(
          id: 'never_owned_a_home',
          kind: MoneyFindingKind.watch,
          dimension: MoneyDimension.exposure,
          title: 'None of these lives owned a home',
          evidence:
              'Your last ${ended.length} full lives all ended without one.',
          action:
              'Renting is a real choice. Try one life where you buy a starter '
              'home in your thirties, and compare the loan with the rent you '
              'would have paid. The Assets tab shows both.',
          concept: FinanceConcept.opportunityCost,
        ),
      );
    }
  }

  // did studying actually pay off, comparing lives with/without a degree
  final compared = snap.lives.take(8).toList();
  final studied = compared.where((l) => l.degrees >= 1).toList();
  final notStudied = compared.where((l) => l.degrees == 0).toList();
  if (compared.length >= 3 && studied.isNotEmpty && notStudied.isNotEmpty) {
    int average(List<LifeReading> list) =>
        (list.fold<int>(0, (sum, l) => sum + l.netWorth) / list.length).round();
    final withQualification = average(studied);
    final without = average(notStudied);
    if (withQualification >= without + 500) {
      findings.add(
        MoneyFinding(
          id: 'studying_paid',
          kind: MoneyFindingKind.strength,
          dimension: MoneyDimension.learning,
          title: 'Studying has paid off for you',
          evidence:
              'Lives with a qualification finished at an average of '
              '$withQualification. Lives without finished at $without.',
          action:
              'It is a bet and it has come off. Keep checking what a course '
              'costs and what it leads to before you take the next one.',
          concept: FinanceConcept.opportunityCost,
        ),
      );
    } else if (withQualification + 500 <= without) {
      findings.add(
        MoneyFinding(
          id: 'studying_has_not_paid',
          kind: MoneyFindingKind.watch,
          dimension: MoneyDimension.learning,
          title: 'Studying has not paid back yet',
          evidence:
              'Lives with a qualification finished at an average of '
              '$withQualification. Lives without finished at $without.',
          action:
              'Look at what a course leads to, not only that it is hard. A '
              'trade with a job waiting can beat a degree with none, and '
              'starting to earn earlier is worth real money.',
          concept: FinanceConcept.opportunityCost,
        ),
      );
    }
  }

  // rich lives that werent actually happy ones
  if (compared.length >= 3) {
    final worths = compared.map((l) => l.netWorth).toList()..sort();
    final median = worths[worths.length ~/ 2];
    final richAndFlat = compared
        .where(
          (l) => l.netWorth > 0 && l.netWorth >= median && l.happiness < 45,
        )
        .length;
    if (richAndFlat >= 2) {
      findings.add(
        MoneyFinding(
          id: 'rich_and_flat',
          kind: MoneyFindingKind.watch,
          dimension: MoneyDimension.exposure,
          title: 'Some of your richest lives were not happy ones',
          evidence:
              '$richAndFlat of your ${compared.length} recent lives finished '
              'well off and under 45 out of 100 in happiness.',
          action:
              'Money is a tool for the rest of it. Give one life more time in '
              'the Relationships and Activities tabs, and see what it does to '
              'the ending as well as the number.',
          concept: FinanceConcept.incomeVsWealth,
        ),
      );
    }
  }

  // worst first, otherwise keep the order the rules fired in
  const rank = <MoneyFindingKind, int>{
    MoneyFindingKind.fix: 0,
    MoneyFindingKind.watch: 1,
    MoneyFindingKind.strength: 2,
  };
  final ordered = [...findings]
    ..sort((a, b) => rank[a.kind]!.compareTo(rank[b.kind]!));

  return MoneyReport(
    isNewcomer: false,
    scores: <MoneyDimension, int>{
      MoneyDimension.consistency: consistency,
      MoneyDimension.saving: saving,
      MoneyDimension.followThrough: followThrough,
      MoneyDimension.learning: learning,
      MoneyDimension.exposure: exposure,
    },
    findings: ordered,
  );
}

// value vs target, scaled to 0..100
int _score(num value, num target) {
  if (target <= 0) return 0;
  final ratio = value / target;
  return (ratio.clamp(0.0, 1.0) * 100).round();
}

String _gap(int days) {
  if (days >= MoneySnapshot.neverLogged) return 'Nothing logged yet.';
  if (days == 1) return 'Last logged yesterday.';
  if (days < 14) return 'Last logged $days days ago.';
  if (days < 60) return 'Last logged ${days ~/ 7} weeks ago.';
  if (days < 365) return 'Last logged ${days ~/ 30} months ago.';
  return 'Last logged over a year ago.';
}
