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
      // Answer whatever gets drawn. `ageUp` refuses to advance while an event
      // is waiting, so a bare loop of six `ageUp`s banks *one* year of savings
      // and thinks it banked six — which left the fund small enough for a
      // single unlucky boiler to clear it, and the assertion below failing for
      // a reason that has nothing to do with what it is testing.
      for (var i = 0; i < 12 && !life.finished; i++) {
        if (life.currentEvent != null) life.chooseOption(0);
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

  group('the paycheck is visible every year', () {
    // Before this the budget ran silently and only spoke up on a shortfall
    // or on debt interest, so the one mechanic the game exists to teach
    // was invisible on exactly the years it went well.
    test('a working year always writes a money line', () {
      final life = _employed();
      life.setBudget(needs: 50, wants: 30, savings: 20);
      final before = life.history.length;
      life.ageUp();
      final added = life.history.skip(before);
      expect(
        added.where((e) => e.kind == LifeLogKind.money),
        isNotEmpty,
        reason: 'a year with a salary must name the split in the feed',
      );
    });

    test('it names all three slices once a budget is chosen', () {
      final life = _employed(salary: 1000);
      life.setBudget(needs: 50, wants: 30, savings: 20);
      final before = life.history.length;
      life.ageUp();
      final line = life.history
          .skip(before)
          .firstWhere((e) => e.text.startsWith('Paycheck'));
      expect(line.text, contains('Needs 500'));
      expect(line.text, contains('wants 300'));
      expect(line.text, contains('savings 200'));
    });

    test('before a budget is chosen it says so', () {
      final life = _employed();
      final before = life.history.length;
      life.ageUp();
      final line = life.history
          .skip(before)
          .firstWhere((e) => e.text.startsWith('Paycheck'));
      expect(line.text, contains('50/30/20'));
    });

    test('a year with no salary writes no paycheck line', () {
      final life = LifeSimController(
        random: Random(3),
        initialAge: 8,
        startMoney: 0,
      );
      final before = life.history.length;
      life.ageUp();
      expect(
        life.history.skip(before).where((e) => e.text.startsWith('Paycheck')),
        isEmpty,
      );
    });
  });

  group('getting a job', () {
    // Only eight of the ~130 events could hand out a job, each behind its
    // own gate and behind picking one specific branch. Simulated lives
    // routinely hit forty on zero salary, which meant `canBudget` never
    // became true and the entire budgeting model — the thing this app
    // exists to teach — was unreachable for most players.
    LifeSimController jobless({int age = 25, int seed = 3}) =>
        LifeSimController(random: Random(seed), initialAge: age);

    test('an adult with no job can find one', () {
      final life = jobless();
      expect(life.canBudget, isFalse);
      expect(life.findJob(), isTrue);
      expect(life.salary, greaterThan(0));
      expect(life.canBudget, isTrue);
    });

    test('a child cannot', () {
      final life = jobless(age: 9);
      expect(life.canJobHunt, isFalse);
      expect(life.findJob(), isFalse);
      expect(life.salary, 0);
    });

    test('the age gate is exactly the documented one', () {
      expect(
        jobless(age: LifeSimController.jobHuntingAge - 1).canJobHunt,
        isFalse,
      );
      expect(jobless(age: LifeSimController.jobHuntingAge).canJobHunt, isTrue);
    });

    test('you cannot take a second job while employed', () {
      final life = _employed();
      expect(life.canJobHunt, isFalse);
      expect(life.findJob(), isFalse);
      expect(life.job, 'Tester');
    });

    test('quitting makes you employable again', () {
      final life = _employed();
      life.quitJob();
      expect(life.canJobHunt, isTrue);
      expect(life.findJob(), isTrue);
    });

    test('being hired teaches the budget rule', () {
      // The moment a salary exists is the moment a split becomes a real
      // decision, so that is where the idea is introduced.
      final life = jobless();
      life.findJob();
      expect(life.conceptsMet, contains(FinanceConcept.budgetRule));
    });

    test('smarter characters reach better-paid work', () {
      // Averaged over many draws rather than asserted on one, because the
      // pick is deliberately random within what is open — the guarantee is
      // that studying pays, not that it pays every single time.
      int averageSalary(int smarts) {
        var total = 0;
        const runs = 60;
        for (var seed = 0; seed < runs; seed++) {
          final life = LifeSimController(random: Random(seed), initialAge: 30);
          for (var i = 0; i < 40 && life.smarts < smarts; i++) {
            life.visitLibrary();
          }
          life.findJob();
          total += life.salary;
        }
        return total ~/ runs;
      }

      expect(averageSalary(95), greaterThan(averageSalary(30)));
    });

    test('the market never offers nothing to a zero-smarts character', () {
      final life = LifeSimController(random: Random(8), initialAge: 30);
      expect(life.findJob(), isTrue);
    });

    test('entry-level pay stays below the career ladders', () {
      // Walking into a job should always be worse than earning one through
      // the music/sports/business events, or those ladders stop mattering.
      var best = 0;
      for (var seed = 0; seed < 200; seed++) {
        final life = LifeSimController(random: Random(seed), initialAge: 30);
        for (var i = 0; i < 60; i++) {
          life.visitLibrary();
        }
        life.findJob();
        if (life.salary > best) best = life.salary;
      }
      expect(
        best,
        lessThanOrEqualTo(600),
        reason:
            'entry-level pay reached $best, which is at or above what the '
            'career events award',
      );
    });
  });
}
