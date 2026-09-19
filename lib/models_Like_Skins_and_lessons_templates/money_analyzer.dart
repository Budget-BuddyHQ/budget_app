import 'finance_concepts.dart';

/// Reads what somebody has actually done in this app and tells them one
/// useful thing about it.
///
/// **Why this is not another stats screen.** The app already counts plenty:
/// gold, XP, literacy points, jar fill, lives played. None of that is advice.
/// A number tells you where you are; it does not tell you which single thing
/// to change, and "here are eleven metrics" is how most money apps quietly
/// hand the hard part back to the user.
///
/// So every finding here has three parts and is useless without all of them:
///
/// * **evidence** — a number out of *their* data, not a generic claim. "You
///   pinned six habits and have logged two of them" is arguing with somebody
///   about their own week, which is a much harder position to shrug off than
///   "consistency is important".
/// * **an action** — exactly one, small enough to do today. Findings that end
///   in "consider reviewing your spending" are decoration.
/// * **a concept, where there is one** — so the finding can hand off to the
///   lesson that explains it, and through that to the lesson's source. The
///   Academy already refuses to ship an uncited fact; advice should not get a
///   free pass either.
///
/// **Why it is pure Dart.** No Flutter, no controllers, no storage. The whole
/// thing is [MoneySnapshot] in, `List<MoneyFinding>` out, so the rules can be
/// tested as rules — including the ones that are only reachable for a player
/// with an odd history, which is exactly the population a UI test never
/// reaches.

/// How seriously to take a finding.
enum MoneyFindingKind {
  /// Something they are already doing well. Present because an analyser that
  /// only ever lists faults gets closed and not reopened, and because naming
  /// the thing that is working tells them what to protect.
  strength,

  /// A pattern worth watching. True, not yet costing them anything.
  watch,

  /// Something actively going wrong, with a number attached.
  fix,
}

/// The areas the analyser scores separately.
///
/// Kept apart on purpose: somebody can be extremely consistent and save
/// nothing, or save well and understand none of it. Rolling those into one
/// "money score" would hide the only interesting part, which is *which* of
/// them is the weak one.
enum MoneyDimension {
  /// Do they turn up? Logging days, gaps, streaks.
  consistency,

  /// Is money actually moving? Saved totals, jar progress.
  saving,

  /// Do they finish what they start? Habits pinned against habits logged.
  followThrough,

  /// Do they understand it? Lessons done, quiz accuracy by concept.
  learning,

  /// Are they meeting the decisions at all? Town, lives, breadth of play.
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

  /// What a low score in this area actually means, in one line.
  String get weakness => switch (this) {
    MoneyDimension.consistency => 'You come back in bursts, then stop.',
    MoneyDimension.saving => 'The habits are happening, the money is not.',
    MoneyDimension.followThrough => 'You start more than you finish.',
    MoneyDimension.learning => 'You are doing it without reading why.',
    MoneyDimension.exposure => 'You have only met a corner of this.',
  };
}

/// One finished, graded life, as the Coach reads it.
///
/// **Why the Coach reads lives at all.** Net worth at the end of a life says how
/// it went and nothing about why. Since a life became school, work, a home and a
/// household, the reasons are in the record: whether it was studied for, whether
/// that was borrowed, whether the work led up a ladder, what was owned and owed
/// at the end. Those are the things a player can change on the next one, so those
/// are what the Coach compares across lives.
///
/// Only lives that kept this detail become a reading. A life filed before the
/// detail existed is not "a life with no degree", it is a life nobody wrote that
/// down for, and counting it as one would have the Coach say something untrue.
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

  /// Loans and borrowed cash together, at the end.
  final int loansOwed;
  final bool ownedHome;
  final bool hadPartner;
  final int children;

  /// Studied on borrowed money and still owed something when it ended.
  bool get schoolDebtLeft => borrowedForSchool >= 1500 && loansOwed > 0;

  /// Owed more than was owned.
  bool get underwater => loansOwed > 0 && loansOwed > assetsValue;

  /// Long enough at work for a promotion to have been reasonable, and none came.
  bool get stalled => workYears >= 12 && promotions == 0;
}

/// Everything the analyser is allowed to look at.
///
/// A flat snapshot rather than the controllers themselves, so the rules take
/// plain numbers and can be exercised without Supabase, storage or a widget
/// tree. Built by [MoneySnapshot.from] on the UI side.
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

  /// Graded lives that kept their detail, newest first.
  ///
  /// This is what lets the Coach say *why* a life went the way it did, and not
  /// only that the number moved. See [LifeReading].
  final List<LifeReading> lives;

  /// The sentinel the habit store uses when nothing has ever been logged.
  ///
  /// Not zero, and not null: zero means "logged today", which is the opposite.
  static const int neverLogged = 999;

  final int loggedDaysLast14;
  final int daysSinceLastLog;
  final int longestStreak;

  final int pinnedHabits;

  /// Distinct habits that actually appear in the last fortnight's log — the
  /// number that matters against [pinnedHabits].
  final int habitsLoggedLast14;

  final double moneySaved;
  final double choicesKept;
  final int jarXp;

  final int lessonsCompleted;
  final int lessonsAvailable;

  /// Best accuracy per concept, 0..1. Absent means never assessed, which is
  /// deliberately different from scoring zero.
  final Map<FinanceConcept, double> conceptAccuracy;

  /// Net worth at the end of each finished life, newest first.
  final List<int> pastLifeNetWorths;

  final int townSpotsVisited;
  final int townSpotsAvailable;

  final int challengesStarted;
  final int challengesFinished;

  /// Coin Cascade runs finished, and how the board was actually divided.
  ///
  /// **Why an arcade game feeds the coach at all.** Coin Cascade is the one
  /// place in this app where a player allocates money under pressure without
  /// being asked to. Nothing on that screen says "budget" while it is being
  /// played — needs clear bills, wants raise them, savings win — so the split
  /// that comes out is behaviour rather than an answer to a question about
  /// behaviour. That makes it the most honest number the app holds, and the
  /// only one worth checking a quiz score against.
  ///
  /// Shares are 0..1, averaged over finished runs.
  final int cascadeRuns;
  final int cascadeLevelsCleared;
  final double cascadeWantsShare;
  final double cascadeSavesShare;

  /// Enough runs to talk about a pattern rather than an off day.
  bool get hasCascadeHistory => cascadeRuns >= 2;

  /// How many different life endings have been reached.
  ///
  /// **Why the analyser needs to know.** Net worth is the obvious measure of
  /// a life and it is not the only one somebody plays for. A player working
  /// through the endings deliberately gets poorer runs on purpose — and being
  /// told "your lives are not getting richer" for doing the thing the game
  /// rewards is the fastest way to teach somebody that the coach is not
  /// paying attention.
  final int distinctEndings;

  bool get hasEverLogged => daysSinceLastLog < neverLogged;

  /// True for somebody with essentially no history, where every rule below
  /// would fire at once and none of them would be useful.
  bool get isNewcomer =>
      !hasEverLogged &&
      pinnedHabits == 0 &&
      lessonsCompleted == 0 &&
      pastLifeNetWorths.isEmpty;
}

/// One thing the analyser noticed.
class MoneyFinding {
  const MoneyFinding({
    required this.id,
    required this.kind,
    required this.dimension,
    required this.title,
    required this.evidence,
    required this.action,
    this.concept,
  });

  /// Stable key. Safe to log or persist against; never reuse one.
  final String id;
  final MoneyFindingKind kind;
  final MoneyDimension dimension;

  /// What was noticed, as a short phrase.
  final String title;

  /// The number out of their own data that says so.
  final String evidence;

  /// One thing to do, small enough to do today.
  final String action;

  /// The idea behind it, where there is one — the hook into the Academy and
  /// its citations.
  final FinanceConcept? concept;
}

/// The whole read-out: a score per area, and the findings behind them.
class MoneyReport {
  const MoneyReport({
    required this.scores,
    required this.findings,
    required this.isNewcomer,
  });

  /// 0..100 per area. See [MoneyDimension] for why these are not averaged
  /// into one number.
  final Map<MoneyDimension, int> scores;

  /// Ordered: what is going wrong first, then what to watch, then what is
  /// going right. Somebody who reads one line should read the useful one.
  final List<MoneyFinding> findings;

  /// True when there is not enough history to say anything honest yet.
  final bool isNewcomer;

  /// The weakest area, or null when nothing has been scored.
  MoneyDimension? get weakest {
    if (scores.isEmpty) return null;
    var worst = scores.entries.first;
    for (final entry in scores.entries) {
      if (entry.value < worst.value) worst = entry;
    }
    return worst.key;
  }

  /// The single line to show if there is only room for one.
  MoneyFinding? get headline => findings.isEmpty ? null : findings.first;
}

/// Turns a [MoneySnapshot] into a [MoneyReport].
///
/// Every rule below is written to be *quiet on thin data*. A player three
/// minutes into the app has no consistency, no savings and no lessons, and
/// firing all five faults at them is both true and useless — so the rules
/// that need history check for it first and [MoneyReport.isNewcomer] short-
/// circuits the lot.
MoneyReport analyseMoney(MoneySnapshot snap) {
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
          title: 'Nothing to analyse yet',
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

  // ---- Finishing --------------------------------------------------------
  //
  // The classic. Pinning a habit is free and feels like progress; logging one
  // is neither. A big gap between the two is the most common shape of failure
  // in every habit app there has ever been, and it is invisible unless
  // somebody puts the two numbers side by side.
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

  // ---- Money moving -----------------------------------------------------
  //
  // The one this app is most at risk of getting wrong. Habit points, jar fill
  // and streaks are all satisfying and none of them is money — it is entirely
  // possible to be a model user of this app and be no better off, and if that
  // is happening the analyser has to be the thing that says so.
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

  // ---- Understanding ----------------------------------------------------
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

  // ---- Trying things ----------------------------------------------------
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
      // Even "you did better" assumes richer is the goal.
      //
      // The flat-lives branch below already checks whether somebody is
      // collecting endings rather than chasing money. This branch needed the
      // same check for the same reason: a player working through the endings
      // sees net worth swing wildly between runs, and congratulating them on
      // a number they were not aiming at is the coach talking past them. It
      // is a smaller mistake than the scolding one — nobody minds being
      // praised — but it is the same failure to read what the player is
      // actually doing.
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
      // Are they collecting endings rather than chasing money?
      //
      // Three or more distinct endings across a handful of lives is not
      // somebody failing to get rich — it is somebody exploring the game on
      // purpose, and poorer runs are the *cost* of that rather than a
      // mistake. Scolding them for it would be the coach reading a number
      // without reading the player.
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
                    'chase an ending *and* set your budget in the Assets tab '
                    'early — the two are not opposites.',
                concept: FinanceConcept.opportunityCost,
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
                    'Next run, set your budget in the Assets tab in the first '
                    'ten years instead of the last ten. Almost all of the '
                    'difference is made early.',
                concept: FinanceConcept.compoundGrowth,
              ),
      );
    }
  }

  // ---------------------------------------------------------------------
  // Cross-domain rules.
  //
  // Everything above reads one area and reports on it. These read *two* and
  // report on the gap, which is where the findings a player cannot get from
  // looking at their own screens live. They are added last so that when two
  // rules describe the same behaviour, the specific cross-domain one is the
  // later, more interesting sentence rather than a duplicate of a simpler
  // one above it.
  // ---------------------------------------------------------------------

  // Knowing it and doing it are different, and only one of them is a skill.
  //
  // This is the finding this whole section exists for. A player who scores
  // well on needs-versus-wants and then spends over a third of an unlabelled
  // board on wants has not failed to learn the definition — they have learnt
  // *only* the definition. No single screen in this app can see that: the
  // Academy sees a good score, the arcade sees a finished run, and the gap
  // between them is invisible to both.
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
              'Budgeting unit and you will recognise every part of it.',
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

    // The same shape showing up in two independent systems.
    //
    // One high-wants arcade run is a bad afternoon. High wants *and* lives
    // that are not getting richer is the same decision being made twice, in
    // two places built by different rules, and that is worth saying out loud
    // because neither screen can say it alone.
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

  // Reading without practising, which is the opposite failure and just as
  // real. Someone can finish half the Academy and never make one decision.
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

  // ---------------------------------------------------------------------
  // Lives, read for what they were made of.
  //
  // Each of these needs at least two lives and looks for the same thing showing
  // up more than once, because one life is a story and two are a pattern. Every
  // one is worded so that a fair trade is not called a mistake: borrowing for a
  // qualification and paying it off is fine, and the finding is for the loans
  // that were still there at the end.
  // ---------------------------------------------------------------------
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

  // Did studying pay, across the lives that have both kinds to compare?
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

  // Money that was not the point. Richer lives that were not happier ones.
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

  // Worst first. Within a kind, keep the order the rules produced them in,
  // which runs roughly from habit to money to understanding — the order
  // somebody can actually act on.
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

/// `value` against `target`, as 0..100.
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
