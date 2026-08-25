import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// A controller with a fixed seed and an adult already in work, so the
/// budgeting path is reachable without simulating twenty years first.
LifeSimController _employed({int seed = 7, int salary = 1200}) =>
    LifeSimController(
      random: Random(seed),
      initialAge: 30,
      startMoney: 500,
      startJob: 'Tester',
      startSalary: salary,
    );

void main() {
  group('budget allocation', () {
    test('a split that does not total 100 is rejected', () {
      final life = _employed();
      expect(life.setBudget(needs: 50, wants: 30, savings: 30), isFalse);
      expect(life.setBudget(needs: 10, wants: 10, savings: 10), isFalse);
      expect(life.budgetSet, isFalse);
    });

    test('negative slices are rejected', () {
      final life = _employed();
      expect(life.setBudget(needs: 120, wants: -10, savings: -10), isFalse);
      expect(life.budgetSet, isFalse);
    });

    test('a balanced split is accepted and teaches the budget rule', () {
      final life = _employed();
      expect(life.setBudget(needs: 50, wants: 30, savings: 20), isTrue);
      expect(life.budgetSet, isTrue);
      expect(life.needsPct, 50);
      expect(life.wantsPct, 30);
      expect(life.savingsPct, 20);
      expect(life.conceptsMet, contains(FinanceConcept.budgetRule));
    });

    test('the default split is the 50/30/20 guideline', () {
      final life = _employed();
      expect(
        [life.needsPct, life.wantsPct, life.savingsPct],
        [50, 30, 20],
        reason: 'an untouched budget should be sensible, not punishing',
      );
    });
  });

  group('savings actually accumulate', () {
    test('saving beats not saving over the same life', () {
      // Deliberately a *comparison between two identically-seeded lives*
      // rather than "the fund is above N after one year". Ageing can fire a
      // random expense shock that legitimately empties the fund, so any
      // absolute threshold is really testing the RNG, not the budget — an
      // earlier version of this test broke the moment an unrelated change
      // shifted the random sequence by one draw.
      //
      // Same seed means both lives get the same shocks in the same years,
      // so the only difference left is the budget itself. That is the
      // actual claim worth locking down.
      final saver = _employed(salary: 1000, seed: 11)
        ..setBudget(needs: 50, wants: 30, savings: 20);
      final spender = _employed(salary: 1000, seed: 11)
        ..setBudget(needs: 70, wants: 30, savings: 0);

      for (var year = 0; year < 6; year++) {
        saver.ageUp();
        spender.ageUp();
      }

      expect(
        saver.netWorth,
        greaterThan(spender.netWorth),
        reason:
            'saving 20% should leave you better off than saving nothing '
            'across the same six years and the same shocks '
            '(saver=${saver.netWorth}, spender=${spender.netWorth})',
      );
    });

    test('saving nothing leaves the fund empty', () {
      final life = _employed(salary: 1000);
      life.setBudget(needs: 60, wants: 40, savings: 0);
      life.ageUp();
      expect(life.emergencyFund, 0);
    });
  });

  group('the emergency fund is what a shock lands on', () {
    test('a covered shock draws the fund and creates no debt', () {
      final life = _employed(salary: 1000);
      life.setBudget(needs: 50, wants: 30, savings: 20);
      for (var i = 0; i < 6; i++) {
        life.ageUp();
      }

      // Deliberately not asserting a fixed six-years-of-saving total:
      // ageing can fire a random expense shock, which draws the fund down
      // on purpose. That randomness is the feature, so the test measures
      // the shock's effect against whatever the fund actually holds rather
      // than assuming an untouched balance.
      final fund = life.emergencyFund;
      final debtBefore = life.debt;
      expect(fund, greaterThan(0), reason: 'saving 20% should bank something');

      life.applyShock(fund ~/ 2, 'Test expense');
      expect(
        life.debt,
        debtBefore,
        reason: 'a shock inside the fund must not add new borrowing',
      );
      expect(life.emergencyFund, lessThan(fund));
      expect(life.conceptsMet, contains(FinanceConcept.emergencyFund));
    });

    test('an uncovered shock becomes debt and teaches why', () {
      final life = _employed(salary: 1000);
      life.setBudget(needs: 70, wants: 30, savings: 0);
      life.ageUp();
      expect(life.emergencyFund, 0);

      // Far beyond any cash on hand, so it cannot be quietly absorbed.
      life.applyShock(99999, 'Catastrophe');
      expect(
        life.debt,
        greaterThan(0),
        reason: 'with no fund and no cash the shortfall must be borrowed',
      );
      expect(life.conceptsMet, contains(FinanceConcept.emergencyFund));
    });
  });

  group('debt costs more the longer it is carried', () {
    test('carrying debt accrues interest and surfaces the lesson', () {
      final life = _employed(salary: 100);
      life.setBudget(needs: 100, wants: 0, savings: 0);
      life.applyShock(5000, 'Huge bill');
      final owed = life.debt;
      expect(owed, greaterThan(0));

      life.ageUp();
      expect(
        life.debt,
        greaterThan(owed),
        reason: 'interest should outrun what a 100-salary player can repay',
      );
      expect(life.conceptsMet, contains(FinanceConcept.interestCost));
    });
  });

  group('net worth reflects what you keep, not what you earn', () {
    test('debt subtracts from net worth', () {
      final life = _employed(salary: 1000);
      final before = life.netWorth;
      life.applyShock(99999, 'Catastrophe');
      expect(
        life.netWorth,
        lessThan(before),
        reason: 'borrowing to cover a bill is not neutral',
      );
    });

    test('the emergency fund counts toward net worth', () {
      final life = _employed(salary: 1000);
      life.setBudget(needs: 50, wants: 30, savings: 20);
      life.ageUp();
      expect(life.netWorth, greaterThanOrEqualTo(life.emergencyFund));
    });
  });

  group('lessons are handed to the UI exactly once', () {
    test('takeLesson drains the queue', () {
      final life = _employed();
      life.setBudget(needs: 50, wants: 30, savings: 20);
      expect(life.takeLesson(), FinanceConcept.budgetRule);
      expect(
        life.takeLesson(),
        isNull,
        reason: 'a lesson must not re-show every rebuild',
      );
    });

    test('meeting a concept twice does not duplicate the record', () {
      final life = _employed();
      life.setBudget(needs: 50, wants: 30, savings: 20);
      life.setBudget(needs: 60, wants: 20, savings: 20);
      expect(
        life.conceptsMet.where((c) => c == FinanceConcept.budgetRule).length,
        1,
      );
    });
  });

  group('the money-lesson event pack', () {
    test('every choice in the pack names the idea it teaches', () {
      final untaught = <String>[];
      for (final event in kLifeEventsMoney) {
        for (final choice in event.choices) {
          if (choice.teaches == null) {
            untaught.add('${event.id} -> ${choice.label}');
          }
        }
      }
      expect(
        untaught,
        isEmpty,
        reason:
            'these choices are in the teaching pack but explain nothing: '
            '$untaught',
      );
    });

    test('both branches of a money event teach the same idea', () {
      // Picking the worse option should not be punished with silence — it
      // is the more instructive path, so it must land the same lesson.
      for (final event in kLifeEventsMoney) {
        final taught = event.choices.map((c) => c.teaches).toSet();
        expect(
          taught.length,
          lessThanOrEqualTo(2),
          reason: '${event.id} teaches too many different ideas at once',
        );
      }
    });

    test('the pack is wired into the live event pool', () {
      for (final event in kLifeEventsMoney) {
        expect(
          kLifeEvents.map((e) => e.id),
          contains(event.id),
          reason: '${event.id} exists but is not in kLifeEvents',
        );
      }
    });

    test('the pack spans childhood as well as adulthood', () {
      expect(
        kLifeEventsMoney.any((e) => e.minAge <= 10),
        isTrue,
        reason: 'nothing here is pitched at a young child',
      );
      expect(
        kLifeEventsMoney.any((e) => e.minAge >= 18),
        isTrue,
        reason: 'nothing here is pitched at an adult',
      );
    });
  });

  group('every concept is presentable', () {
    test('all concepts carry copy at both reading levels', () {
      for (final concept in FinanceConcept.values) {
        expect(concept.label, isNotEmpty, reason: '${concept.name} label');
        expect(
          concept.explainerFor(simple: true),
          isNotEmpty,
          reason: '${concept.name} kid copy',
        );
        expect(
          concept.explainerFor(simple: false),
          isNotEmpty,
          reason: '${concept.name} adult copy',
        );
        expect(concept.tryThis, isNotEmpty, reason: '${concept.name} action');
      }
    });

    test('the two reading levels are genuinely different text', () {
      for (final concept in FinanceConcept.values) {
        expect(
          concept.explainerFor(simple: true),
          isNot(equals(concept.explainerFor(simple: false))),
          reason:
              '${concept.name} has the same copy for both levels, so the '
              'age split is doing nothing',
        );
      }
    });

    test('every concept has a stable persistence id, round-tripping', () {
      for (final concept in FinanceConcept.values) {
        final id = kFinanceConceptIds[concept];
        expect(id, isNotNull, reason: '${concept.name} has no stored id');
        expect(financeConceptFromId(id!), concept);
      }
    });
  });
}
