/// Money ideas, as powers you can switch on for a few years.
///
/// **The problem this solves.** The app's whole claim is that understanding a
/// money idea is worth something. Until now, meeting one produced a chip on a
/// screen and a line in a log — a collectible. The simulation carried on
/// exactly the same whether you had met sixteen ideas or none, which quietly
/// said the opposite of what every lesson says.
///
/// A power turns an idea into a mechanic. Knowing what an emergency fund is
/// *for* now literally absorbs a shock; understanding compound growth
/// literally compounds faster. The lesson is not decoration on top of the
/// game, it is the game's stat sheet.
///
/// **The rule that makes it teach rather than just buff.** You can only arm a
/// power for a concept you have actually met in *this run* — through an event,
/// a town decision or a lesson. So the route to being strong runs through
/// understanding, and a player optimising for score is, without being told to,
/// optimising for learning. That is the entire design.
///
/// Powers are deliberately temporary. A permanent buff is a number you collect
/// once and forget; something that runs out in six years is a decision about
/// *when*, which is what an idea like opportunity cost is actually about.
library;

import 'finance_concepts.dart';

/// What a power does to the simulation.
///
/// Named for the effect rather than the concept, because two ideas can pull
/// the same lever from different directions and the controller only cares
/// about the lever.
enum PowerEffect {
  /// Expense shocks cost less — the fund, or the sense to see one coming.
  softenShocks,

  /// Investments compound faster.
  fasterGrowth,

  /// Debt interest is charged at a lower rate.
  slowerDebt,

  /// A slice of income is moved to savings before anything else happens.
  autoSave,

  /// Day-to-day living costs less.
  cheaperLiving,

  /// Salary rises, and rises again on a raise.
  betterPay,

  /// Illness costs less money and less health.
  healthGuard,

  /// Hunger builds more slowly when money is short.
  stretchFood,
}

/// One money idea, armed.
class ConceptPower {
  const ConceptPower({
    required this.concept,
    required this.name,
    required this.blurb,
    required this.effect,
    required this.years,
    required this.magnitude,
  });

  /// The idea you have to have met to arm this.
  final FinanceConcept concept;

  /// Short name, shown on the power itself.
  final String name;

  /// What it does, in the terms a player thinks in.
  final String blurb;

  final PowerEffect effect;

  /// How many years it stays on for.
  final int years;

  /// Strength, 0..1, read differently per effect — a fraction of a cost
  /// removed, a fraction of a rate added. Kept as one number so the
  /// controller has one thing to reason about.
  final double magnitude;
}

/// Every power, one per money idea.
///
/// One-to-one on purpose. A concept with no power would be a concept the game
/// says does not matter, and this app is not in a position to say that about
/// any of the sixteen — `concept_powers_test.dart` fails the build if one is
/// ever left out.
const List<ConceptPower> kConceptPowers = <ConceptPower>[
  ConceptPower(
    concept: FinanceConcept.emergencyFund,
    name: 'Cushion',
    blurb: 'Unexpected bills cost you 60% less. You saw it coming, sort of.',
    effect: PowerEffect.softenShocks,
    years: 6,
    magnitude: 0.6,
  ),
  ConceptPower(
    concept: FinanceConcept.needsVsWants,
    name: 'Clear Eyes',
    blurb: 'Living costs drop 25%. You stopped buying things twice.',
    effect: PowerEffect.cheaperLiving,
    years: 8,
    magnitude: 0.25,
  ),
  ConceptPower(
    concept: FinanceConcept.compoundGrowth,
    name: 'Snowball',
    blurb: 'Investments grow an extra 4% a year. Time does the work.',
    effect: PowerEffect.fasterGrowth,
    years: 10,
    magnitude: 0.04,
  ),
  ConceptPower(
    concept: FinanceConcept.interestCost,
    name: 'Debt Brake',
    blurb: 'Interest on what you owe is halved. The hole stops widening.',
    effect: PowerEffect.slowerDebt,
    years: 7,
    magnitude: 0.5,
  ),
  ConceptPower(
    concept: FinanceConcept.payYourselfFirst,
    name: 'Automatic',
    blurb: 'A tenth of your pay is saved before you can spend it.',
    effect: PowerEffect.autoSave,
    years: 9,
    magnitude: 0.10,
  ),
  ConceptPower(
    concept: FinanceConcept.insurance,
    name: 'Covered',
    blurb: 'Illness costs 65% less money and hurts less.',
    effect: PowerEffect.healthGuard,
    years: 8,
    magnitude: 0.65,
  ),
  ConceptPower(
    concept: FinanceConcept.budgetRule,
    name: 'The Split',
    blurb: 'Living costs drop 18%, because the plan holds.',
    effect: PowerEffect.cheaperLiving,
    years: 7,
    magnitude: 0.18,
  ),
  ConceptPower(
    concept: FinanceConcept.impulseSpending,
    name: 'Second Thought',
    blurb: 'Living costs drop 22%. The cart gets emptied before checkout.',
    effect: PowerEffect.cheaperLiving,
    years: 6,
    magnitude: 0.22,
  ),
  ConceptPower(
    concept: FinanceConcept.lifestyleCreep,
    name: 'Same Old Coat',
    blurb: 'A raise stays a raise — living costs drop 20%.',
    effect: PowerEffect.cheaperLiving,
    years: 9,
    magnitude: 0.20,
  ),
  ConceptPower(
    concept: FinanceConcept.incomeVsWealth,
    name: 'Worth Asking',
    blurb: 'Your pay is 15% higher. You found out what the job pays.',
    effect: PowerEffect.betterPay,
    years: 8,
    magnitude: 0.15,
  ),
  ConceptPower(
    concept: FinanceConcept.taxes,
    name: 'Read The Slip',
    blurb: 'Take-home pay rises 9%. Nothing was owed that you paid anyway.',
    effect: PowerEffect.betterPay,
    years: 7,
    magnitude: 0.09,
  ),
  ConceptPower(
    concept: FinanceConcept.diversification,
    name: 'Spread Out',
    blurb: 'Investments grow an extra 2% and shrug off a bad year.',
    effect: PowerEffect.fasterGrowth,
    years: 9,
    magnitude: 0.02,
  ),
  ConceptPower(
    concept: FinanceConcept.creditScore,
    name: 'Good Standing',
    blurb: 'Interest on what you owe drops 35%. Better rates, same debt.',
    effect: PowerEffect.slowerDebt,
    years: 8,
    magnitude: 0.35,
  ),
  ConceptPower(
    concept: FinanceConcept.inflation,
    name: 'Real Terms',
    blurb: 'Living costs drop 15%. You noticed the prices moving.',
    effect: PowerEffect.cheaperLiving,
    years: 6,
    magnitude: 0.15,
  ),
  ConceptPower(
    concept: FinanceConcept.opportunityCost,
    name: 'The Other Thing',
    blurb: 'Unexpected bills cost 40% less — you had already chosen.',
    effect: PowerEffect.softenShocks,
    years: 7,
    magnitude: 0.4,
  ),
  ConceptPower(
    concept: FinanceConcept.sunkCost,
    name: 'Walk Away',
    blurb: 'Food stretches twice as far when money is short.',
    effect: PowerEffect.stretchFood,
    years: 8,
    magnitude: 0.5,
  ),
];

/// The power for [concept], or null if somehow there isn't one.
ConceptPower? powerFor(FinanceConcept concept) {
  for (final power in kConceptPowers) {
    if (power.concept == concept) return power;
  }
  return null;
}

/// A power that is currently running, and the age it stops at.
class ActivePower {
  const ActivePower({required this.power, required this.expiresAtAge});

  final ConceptPower power;

  /// The age this switches off at. Exclusive — at this age it is already gone.
  final int expiresAtAge;

  PowerEffect get effect => power.effect;
  double get magnitude => power.magnitude;

  int yearsLeftAt(int age) {
    final left = expiresAtAge - age;
    return left < 0 ? 0 : left;
  }
}
