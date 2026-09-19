import 'package:flutter/material.dart';

import '../controllers_that_updates_stats/life_sim_controller.dart';
import 'life_sim_models.dart';
import 'life_debrief.dart';
import 'finance_concepts.dart';

/// A distinct "how this life turned out" outcome, shown on
/// [LifeEpilogueScreen] once a run ends. Deliberately built from stats the
/// game already tracks — no new stat plumbing — and deliberately not
/// horror-themed: these read as financial-literacy outcomes (a rich but
/// lonely life is not a "win"; a broke but happy one is not a "loss").
enum LifeEndingArchetype {
  goneTooSoon('Gone Too Soon', Icons.bolt_rounded, Color(0xFFB388FF)),
  cautionaryTale('Cautionary Tale', Icons.warning_rounded, Color(0xFFFF8A80)),
  richButLonely('Rich but Lonely', Icons.savings_rounded, Color(0xFFFFD45C)),
  brokeButHappy(
    'Broke but Happy',
    Icons.sentiment_very_satisfied_rounded,
    Color(0xFF85EFAC),
  ),
  legacyBuilder(
    'Legacy Builder',
    Icons.emoji_events_rounded,
    Color(0xFFE1BB72),
  ),
  comfortableRetiree(
    'Comfortable Retiree',
    Icons.beach_access_rounded,
    Color(0xFF58C7FF),
  ),
  quietLife('A Quiet Life', Icons.nights_stay_rounded, Color(0xFF69C6FF));

  const LifeEndingArchetype(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  /// A face for this ending.
  ///
  /// An ending screen that differs only in its accent colour and one
  /// Material glyph reads as the same screen seven times — which is exactly
  /// what it was. A portrait makes each ending a *person* the player ended
  /// up as, and that is the thing worth collecting.
  ///
  /// Curated one-by-one rather than assigned by index, because the match is
  /// the whole point: the Noble's face is hidden under a top hat, which is
  /// what "rich but lonely" looks like, and no automatic mapping would find
  /// that.
  String get portrait => switch (this) {
    LifeEndingArchetype.goneTooSoon =>
      'assets/images/ending_faces/gone_too_soon.png',
    LifeEndingArchetype.cautionaryTale =>
      'assets/images/ending_faces/cautionary_tale.png',
    LifeEndingArchetype.richButLonely =>
      'assets/images/ending_faces/rich_but_lonely.png',
    LifeEndingArchetype.brokeButHappy =>
      'assets/images/ending_faces/broke_but_happy.png',
    LifeEndingArchetype.legacyBuilder =>
      'assets/images/ending_faces/legacy_builder.png',
    LifeEndingArchetype.comfortableRetiree =>
      'assets/images/ending_faces/comfortable_retiree.png',
    LifeEndingArchetype.quietLife =>
      'assets/images/ending_faces/quiet_life.png',
  };

  String get blurb => switch (this) {
    LifeEndingArchetype.goneTooSoon =>
      'Life had other plans — a reminder that health and safety are the '
          'foundation everything else is built on.',
    LifeEndingArchetype.cautionaryTale =>
      'The choices added up the wrong way. A rough one — but every future '
          'life starts smarter for it.',
    LifeEndingArchetype.richButLonely =>
      'The bank account is impressive. The rest of the story is quieter '
          'than it should be.',
    LifeEndingArchetype.brokeButHappy =>
      'Never rich, never really worried either. Turns out that counts for '
          'a lot.',
    LifeEndingArchetype.legacyBuilder =>
      'Wealth, health, and the people who cared about you — all of it, at '
          'once. The rare full set.',
    LifeEndingArchetype.comfortableRetiree =>
      'No fireworks, no scares — just a steady climb and a good landing.',
    LifeEndingArchetype.quietLife =>
      'Not every life is a headline. This one was solid, unremarkable, and '
          'entirely yours.',
  };
}

extension LifeEndingHint on LifeEndingArchetype {
  /// How somebody would actually reach this ending, in one line.
  ///
  /// **Why the endings needed this.** The collection is the strongest reason
  /// in the app to play a second life — it is the one thing that rewards
  /// playing *differently* rather than playing more, which is exactly the
  /// behaviour a financial-literacy game wants. But it was only ever a row of
  /// locked tiles saying "Undiscovered", which tells a player there is
  /// something to find and nothing whatsoever about how to find it. A
  /// collection you cannot make progress towards on purpose is not a
  /// collection, it is a record of your luck.
  ///
  /// These are deliberately a nudge and not a recipe. "Retire with more
  /// friends than money" is enough to change how somebody plays the next run
  /// without turning the game into a checklist to execute.
  /// How worth chasing this ending is, lowest first.
  ///
  /// **This is a safety ordering, not a difficulty one.** The epilogue
  /// suggests the next ending to go for, and the first version simply took
  /// the first one missing from the enum — which is `goneTooSoon`, so the
  /// game's advice to a child who had just finished their first life was
  /// "ignore your health long enough and the run ends early".
  ///
  /// The two failure endings are still collectable and still described
  /// honestly; they are just never the thing the app *suggests* while
  /// anything else is outstanding. What it leads with is the ending its whole
  /// curriculum is pointed at: budget, keep a fund, retire with enough.
  int get chaseOrder => switch (this) {
    LifeEndingArchetype.comfortableRetiree => 0,
    LifeEndingArchetype.legacyBuilder => 1,
    LifeEndingArchetype.brokeButHappy => 2,
    LifeEndingArchetype.quietLife => 3,
    LifeEndingArchetype.richButLonely => 4,
    LifeEndingArchetype.cautionaryTale => 5,
    LifeEndingArchetype.goneTooSoon => 6,
  };

  String get howToReach => switch (this) {
    LifeEndingArchetype.goneTooSoon =>
      'Ignore your health long enough and the run ends early.',
    LifeEndingArchetype.cautionaryTale =>
      'Spend everything, borrow the rest, and never set a budget.',
    LifeEndingArchetype.richButLonely =>
      'Chase the money and skip every year that was about people.',
    LifeEndingArchetype.brokeButHappy =>
      'Say yes to friends, holidays and the dog. Retire with almost nothing '
          'and no regrets.',
    LifeEndingArchetype.legacyBuilder =>
      'Invest early, hold through a crash, and finish rich, clever and old.',
    LifeEndingArchetype.comfortableRetiree =>
      'Set a budget, keep an emergency fund, retire around eighty with '
          'enough.',
    LifeEndingArchetype.quietLife =>
      'Take the steady options. No debt, no drama, no fortune.',
  };
}

/// Deterministic, first-match-wins — same shape as [stageForAge] in
/// lesson.dart. Order matters: more specific/extreme outcomes are checked
/// before the general fallback.
LifeEndingArchetype resolveLifeEnding({
  required bool died,
  required int age,
  required int netWorth,
  required int happiness,
  required int smarts,

  /// Average closeness of the people still in your life, 0-100.
  ///
  /// Optional with a neutral default so existing callers and tests keep
  /// working. `resolveLifeEndingFor` passes the real figure.
  int connection = 50,
}) {
  if (died && age < 50) {
    return LifeEndingArchetype.goneTooSoon;
  }
  if (netWorth < 200 && happiness < 40) {
    return LifeEndingArchetype.cautionaryTale;
  }
  // **Rich but Lonely is about people now.**
  //
  // It used to fire on `netWorth >= 3000 && happiness < 45` alone, which made
  // it reachable by simply overworking and gave an ending named for loneliness
  // nothing whatsoever to do with anybody else. Relationships were a list of
  // names that never changed, so there was no other signal to use.
  //
  // Now there is. Either being unhappy *or* having let everyone drift away
  // will do it, because both are real versions of the same ending — and a run
  // that kept its people close is no longer handed it for working hard.
  if (netWorth >= 3000 && (happiness < 45 || connection < 30)) {
    return LifeEndingArchetype.richButLonely;
  }
  if (netWorth < 500 && happiness >= 70) {
    return LifeEndingArchetype.brokeButHappy;
  }
  if (netWorth >= 3000 && happiness >= 60 && smarts >= 55) {
    return LifeEndingArchetype.legacyBuilder;
  }
  if (!died && netWorth >= 800) {
    return LifeEndingArchetype.comfortableRetiree;
  }
  return LifeEndingArchetype.quietLife;
}

/// A frozen snapshot of a finished life, taken at the moment it ends —
/// [LifeSimController] gets disposed once the page navigates away, so the
/// epilogue screen needs its own copy of the numbers rather than a live
/// reference into a controller that won't exist anymore.
@immutable
class LifeSummary {
  const LifeSummary({
    required this.name,
    required this.gender,
    required this.origin,
    required this.job,
    required this.age,
    required this.yearsLived,
    required this.died,
    required this.netWorth,
    required this.happiness,
    required this.health,
    required this.smarts,
    required this.looks,
    required this.relationships,
    required this.goldReward,
    required this.archetype,
    this.conceptsMet = 0,
    this.debrief,
    this.facts,
  });

  factory LifeSummary.fromController(LifeSimController life) {
    // Built once and used twice: the debrief grades it now, and the record
    // keeps it so the same grading can be re-run from Past Lives later.
    final facts = LifeRunFacts(
      age: life.age,
      netWorth: life.netWorth,
      cash: life.money,
      investments: life.investments,
      emergencyFund: life.emergencyFund,
      debt: life.debt,
      health: life.health,
      happiness: life.happiness,
      conceptsMet: life.conceptsMet.length,
      conceptsAvailable: FinanceConcept.values.length,
      died: life.dead,
      everStarved: life.everStarved,
      budgetSet: life.budgetSet,
      savingsPct: life.savingsPct,
      wantsPct: life.wantsPct,
      // What the life remembered as it went, so the debrief can tell the
      // story of the run and not only grade where it ended.
      record: life.runRecord,
      connection: life.connection,
      networkStrength: life.networkReading.strength,
      contacts: life.networkReading.contacts,
      educationRank: life.educationLevel.index,
      educationLabel: life.educationLevel.label,
      assetsValue: life.assetsValue,
      loanBalance: life.loanBalance,
      ownsHome: life.ownsHome,
      hasPartner: life.hasPartner,
      children: life.childrenOfYours.length,
      jobTitle: life.job,
    );
    return LifeSummary(
      name: life.name,
      gender: life.gender,
      origin: life.origin,
      job: life.job,
      age: life.age,
      yearsLived: life.yearsLived,
      died: life.dead,
      netWorth: life.netWorth,
      happiness: life.happiness,
      health: life.health,
      smarts: life.smarts,
      looks: life.looks,
      relationships: life.relationships,
      goldReward: life.goldReward,
      conceptsMet: life.conceptsMet.length,
      // Graded from this run's own numbers, at the moment it ends, because
      // the controller is disposed before the epilogue builds.
      debrief: debriefLife(facts),
      facts: facts,
      archetype: resolveLifeEnding(
        connection: life.connection,
        died: life.dead,
        age: life.age,
        netWorth: life.netWorth,
        happiness: life.happiness,
        smarts: life.smarts,
      ),
    );
  }

  final String name;
  final Gender gender;
  final LifeOrigin origin;
  final String job;
  final int age;
  final int yearsLived;
  final bool died;
  final int netWorth;
  final int happiness;
  final int health;
  final int smarts;
  final int looks;
  final List<String> relationships;
  final int goldReward;

  /// What this run's debrief was graded on, kept so a record of it can be
  /// graded again later. Null only for a summary built by hand.
  final LifeRunFacts? facts;

  /// How this run was played, graded area by area. Null only for a summary
  /// built by hand in a test or a render harness.
  final LifeDebrief? debrief;
  final LifeEndingArchetype archetype;

  /// How many distinct money ideas this life ran into. Carried on the
  /// snapshot so [LifeRecord] can keep it after the controller is disposed.
  final int conceptsMet;
}
