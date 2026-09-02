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
  });

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
      findings.add(
        MoneyFinding(
          id: 'lives_improving',
          kind: MoneyFindingKind.strength,
          dimension: MoneyDimension.exposure,
          title: 'Your last life went better than the one before',
          evidence: 'Net worth $previous, then $newest.',
          action:
              'Whatever you did differently, do it again — and this time '
              'notice which decision it was.',
          concept: FinanceConcept.compoundGrowth,
        ),
      );
    } else if (snap.pastLifeNetWorths.length >= 3) {
      findings.add(
        MoneyFinding(
          id: 'lives_flat',
          kind: MoneyFindingKind.watch,
          dimension: MoneyDimension.exposure,
          title: 'Your lives are not getting richer',
          evidence:
              'Last three finished at '
              '${snap.pastLifeNetWorths.take(3).join(', ')}.',
          action:
              'Next run, open the Money menu in the first ten years '
              'instead of the last ten. Almost all of the difference is made '
              'early.',
          concept: FinanceConcept.compoundGrowth,
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
