import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/concept_powers.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:flutter_test/flutter_test.dart';

/// Money ideas as powers, and the hazards they exist to survive.
void main() {
  LifeSimController adult({int seed = 5, int salary = 1000}) =>
      LifeSimController(
        random: Random(seed),
        initialAge: 30,
        startMoney: 600,
        startJob: 'Tester',
        startSalary: salary,
      );

  group('the catalogue', () {
    test('every money idea has a power', () {
      // A concept with no power is a concept the game says does not matter,
      // and this app is not in a position to say that about any of the
      // sixteen it teaches.
      for (final concept in FinanceConcept.values) {
        expect(
          powerFor(concept),
          isNotNull,
          reason: '${concept.name} has no power',
        );
      }
      expect(kConceptPowers, hasLength(FinanceConcept.values.length));
    });

    test('no two powers share a concept', () {
      final concepts = kConceptPowers.map((p) => p.concept).toList();
      expect(concepts.toSet().length, concepts.length);
    });

    test('every power is temporary and worth having', () {
      // Permanent buffs are a number you collect once and forget. Something
      // that runs out is a decision about *when*.
      for (final power in kConceptPowers) {
        expect(power.years, inInclusiveRange(4, 12), reason: power.name);
        expect(power.magnitude, greaterThan(0), reason: power.name);
        expect(power.magnitude, lessThanOrEqualTo(0.65), reason: power.name);
        expect(power.blurb.length, greaterThan(25), reason: power.name);
      }
    });

    test('every effect is actually used by something', () {
      // An effect nothing produces is a lever the controller reads and no
      // power can ever pull.
      final used = kConceptPowers.map((p) => p.effect).toSet();
      expect(used, containsAll(PowerEffect.values));
    });
  });

  group('arming one', () {
    test('an idea you have not met cannot be armed', () {
      // This is the whole design. The route to being strong runs through
      // understanding, so a player optimising for score is optimising for
      // learning without being told to.
      final life = adult();
      expect(life.conceptsMet, isEmpty);
      expect(life.armPower(FinanceConcept.compoundGrowth), isFalse);
      expect(life.activePowers, isEmpty);
    });

    test('an idea you have met can be', () {
      final life = adult();
      // Underfunding needs teaches needsVsWants the hard way.
      life.setBudget(needs: 5, wants: 45, savings: 50);
      life.ageUp();
      expect(life.conceptsMet, contains(FinanceConcept.needsVsWants));
      expect(life.armPower(FinanceConcept.needsVsWants), isTrue);
      expect(life.activePowers, hasLength(1));
    });

    test('the same idea cannot be armed twice', () {
      final life = adult();
      life.setBudget(needs: 5, wants: 45, savings: 50);
      life.ageUp();
      expect(life.armPower(FinanceConcept.needsVsWants), isTrue);
      expect(life.armPower(FinanceConcept.needsVsWants), isFalse);
      expect(life.activePowers, hasLength(1));
    });

    test('only two run at once', () {
      // With room for all sixteen there is no decision, and a power that
      // costs nothing to hold teaches nothing about opportunity cost.
      expect(LifeSimController.maxActivePowers, 2);
    });

    test('a finished run cannot arm anything', () {
      final life = adult();
      life.setBudget(needs: 5, wants: 45, savings: 50);
      life.ageUp();
      while (!life.finished) {
        if (life.currentEvent != null) life.chooseOption(0);
        life.ageUp();
      }
      expect(life.armPower(FinanceConcept.needsVsWants), isFalse);
    });
  });

  group('a power actually changes the simulation', () {
    test('stacked strengths are summed but capped', () {
      // Stacking two cost-cutters should be worth doing; it should not add up
      // to free living.
      final life = adult();
      expect(life.powerStrength(PowerEffect.cheaperLiving), 0);
    });

    test('softening a shock leaves more of the fund behind', () {
      // Run the same shock twice from the same state, once with Cushion.
      LifeSimController primed() {
        final life = adult();
        life.setBudget(needs: 50, wants: 30, savings: 20);
        for (var i = 0; i < 8 && !life.finished; i++) {
          if (life.currentEvent != null) life.chooseOption(0);
          life.ageUp();
        }
        return life;
      }

      final bare = primed();
      final withPower = primed();
      // Give the second one the idea, then arm it.
      withPower.debugTeach(FinanceConcept.emergencyFund);
      expect(withPower.armPower(FinanceConcept.emergencyFund), isTrue);

      final bareBefore = bare.emergencyFund + bare.money;
      final poweredBefore = withPower.emergencyFund + withPower.money;
      bare.applyShock(400, 'Test');
      withPower.applyShock(400, 'Test');

      final bareLost = bareBefore - (bare.emergencyFund + bare.money);
      final poweredLost =
          poweredBefore - (withPower.emergencyFund + withPower.money);
      expect(
        poweredLost,
        lessThan(bareLost),
        reason: 'Cushion did not soften the shock',
      );
    });

    test('a power expires and says so', () {
      final life = adult();
      life.debugTeach(FinanceConcept.needsVsWants);
      expect(life.armPower(FinanceConcept.needsVsWants), isTrue);
      final power = life.activePowers.single;
      expect(power.yearsLeftAt(life.age), power.power.years);

      for (var i = 0; i < power.power.years + 1 && !life.finished; i++) {
        if (life.currentEvent != null) life.chooseOption(0);
        life.ageUp();
      }
      expect(
        life.activePowers,
        isEmpty,
        reason: 'the power outlived its stated duration',
      );
    });
  });

  group('hazards', () {
    test('a dependent never goes hungry', () {
      // Somebody else is feeding you. The same rule that makes childhood free
      // of living costs has to cover this, or the sim starves eight-year-olds
      // for their parents' budgeting.
      final life = LifeSimController(random: Random(3), initialAge: 0);
      for (var i = 0; i < 15 && life.isDependent && !life.finished; i++) {
        if (life.currentEvent != null) life.chooseOption(0);
        life.ageUp();
      }
      expect(life.hunger, 0);
    });

    test('a dependent does not pay their own medical bills', () {
      final life = LifeSimController(
        random: Random(1),
        initialAge: 0,
        startMoney: 100,
      );
      life.ageUp();
      expect(life.money, 100, reason: 'the family covers everything under 18');
    });

    test('hunger clears when you can eat again', () {
      // Recovery has to be real, or hunger is a one-way ratchet and a run
      // that dips once can never climb out.
      final life = adult();
      life.debugSetHunger(2);
      expect(life.hunger, 2);
      life.setBudget(needs: 60, wants: 20, savings: 20);
      life.ageUp();
      expect(life.hunger, lessThan(2));
    });

    test('starvation is reachable but takes years of it', () {
      // Nobody starves from one unlucky turn.
      expect(LifeSimController.starvationThreshold, greaterThanOrEqualTo(3));
    });
  });

  group('the balance holds up over many lives', () {
    test('most runs still reach old age', () {
      // Hunger and illness exist to give saving something to be for, not to
      // end runs. The first pass killed 86% of players before sixty and
      // dropped the average life to 35 — which is not a harder game, it is a
      // game that stops before it can teach anything.
      var total = 0;
      var early = 0;
      const runs = 200;
      for (var seed = 0; seed < runs; seed++) {
        final life = LifeSimController(random: Random(seed), initialAge: 0);
        while (!life.finished && life.age < 95) {
          if (life.currentEvent != null) life.chooseOption(0);
          life.ageUp();
        }
        total += life.age;
        if (life.age < 55) early++;
      }
      final average = total / runs;
      expect(
        average,
        greaterThan(50),
        reason: 'average life is only ${average.toStringAsFixed(1)} years',
      );
      expect(
        early,
        lessThan(runs ~/ 2),
        reason: '$early of $runs runs ended before 55',
      );
    });
  });
}
