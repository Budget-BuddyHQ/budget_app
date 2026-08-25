import 'package:flutter/material.dart';

import '../controllers_that_updates_stats/life_sim_controller.dart';
import 'life_sim_models.dart';

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

/// Deterministic, first-match-wins — same shape as [stageForAge] in
/// lesson.dart. Order matters: more specific/extreme outcomes are checked
/// before the general fallback.
LifeEndingArchetype resolveLifeEnding({
  required bool died,
  required int age,
  required int netWorth,
  required int happiness,
  required int smarts,
}) {
  if (died && age < 50) {
    return LifeEndingArchetype.goneTooSoon;
  }
  if (netWorth < 200 && happiness < 40) {
    return LifeEndingArchetype.cautionaryTale;
  }
  if (netWorth >= 3000 && happiness < 45) {
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
  });

  factory LifeSummary.fromController(LifeSimController life) {
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
      archetype: resolveLifeEnding(
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
  final LifeEndingArchetype archetype;
}
