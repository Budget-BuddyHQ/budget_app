import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_debrief.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_run_record.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';

import 'support/fixed_random.dart';

/// Debt you can do something about.
///
/// **Found by** simulating 300 lives with a bot that budgeted and looked after
/// itself. About one in ten of them ended owing over a million on a salary of a
/// few hundred, and every one of them started with a single bill of 265 to 895
/// at twenty-two. The 20% savings slice went into a fund that earned nothing
/// while the debt beside it grew at 18%, nothing ever paid it, and there was no
/// button to. The debrief kept telling people to pay their debt down.
///
/// These hold four things. The lender is paid before the fund is. A player can
/// pay it back on purpose. Compounding still bites below a sane ceiling, because
/// that is the lesson. And past the ceiling it stops, because a number that size
/// is arithmetic and not a lesson.
void main() {
  /// A salaried adult in a year with no shocks, no illness and no referrals, so
  /// the only money that moves is the paycheck and the debt.
  ///
  /// **Why 360.** An adult's living cost is 180, which is exactly the needs
  /// slice of a 360 salary on 50/30/20. Any more and the part of the needs slice
  /// that living did not cost comes back as spare cash, which is correct and is
  /// tested elsewhere, but it would mix a second flow into every number below.
  /// At 360 the only money that moves is the savings slice and the lender.
  LifeSimController worker({int salary = 360}) {
    final life = LifeSimController(
      random: FixedRandom.unlucky(),
      name: 'Tester',
      gender: Gender.nonBinary,
      origin: LifeOrigin.workingClass,
      initialAge: 30,
      startMoney: 0,
      startJob: 'Barista',
      startSalary: salary,
    );
    life.debugSetStats(health: 85, happiness: 65);
    return life;
  }

  void year(LifeSimController life) {
    life.ageUp();
    // Dropped, not answered: an event's first option can cost real money, and
    // a cost is now borrowed when there is nothing to pay it with.
    life.debugClearEvent();
    life.debugSetStats(health: 85, happiness: 65);
  }

  String feed(LifeSimController life) =>
      life.history.map((entry) => entry.text).join(' | ');

  group('the lender is paid before the fund', () {
    test('a debt the pay can cover stops growing', () {
      final life = worker();
      life.setBudget(needs: 50, wants: 30, savings: 20);
      life.applyShock(300, 'Boiler');
      expect(life.debt, 300);

      for (var i = 0; i < 4; i++) {
        year(life);
      }

      // 18% of 300 is 54, and the 72 savings slice covers it every year.
      expect(life.debt, 300, reason: 'interest is taken out of pay, not added');
      expect(
        life.emergencyFund,
        4 * (72 - 54),
        reason: 'only what is left after the lender reaches the fund',
      );
      expect(life.conceptsMet, contains(FinanceConcept.interestCost));
    });

    test('interest the pay cannot cover is still added', () {
      final life = worker();
      life.setBudget(needs: 50, wants: 30, savings: 20);
      life.applyShock(600, 'Roof');

      year(life);

      // 108 is due, the slice is 72, so 36 is added: small income against a
      // big debt still gets worse, which is what the game is teaching.
      expect(life.debt, 600 + 36);
      expect(life.emergencyFund, 0);
    });

    test('the lender takes its cut out of the paycheck line, in words', () {
      final life = worker();
      life.setBudget(needs: 50, wants: 30, savings: 20);
      life.applyShock(300, 'Boiler');
      year(life);
      expect(feed(life), contains('54 of it taken from your pay'));
    });

    test('with no budget slice to spare it still compounds', () {
      final life = worker(salary: 180);
      life.setBudget(needs: 100, wants: 0, savings: 0);
      life.applyShock(500, 'Boiler');
      year(life);
      expect(life.debt, 500 + 90);
    });
  });

  group('paying it back on purpose', () {
    test('uses cash first', () {
      final life = worker();
      life.applyShock(500, 'Boiler');
      life.debugSetStats(money: 300);

      final paid = life.payDownDebt();

      expect(paid, 300);
      expect(life.money, 0);
      expect(life.debt, 200);
      expect(life.runTally.debtRepaid, 300);
    });

    test('then savings, so the trade is real', () {
      final life = worker();
      life.setBudget(needs: 50, wants: 30, savings: 20);
      life.applyShock(300, 'Boiler');
      year(life);
      expect(life.emergencyFund, 18);
      expect(life.money, 0);

      final paid = life.payDownDebt();

      expect(paid, 18, reason: 'nothing in cash, so it came from savings');
      expect(life.emergencyFund, 0);
      expect(life.debt, 282);
    });

    test('never pays more than is owed', () {
      final life = worker();
      life.applyShock(200, 'Boiler');
      life.debugSetStats(money: 300);

      final paid = life.payDownDebt(10000);

      expect(paid, 200);
      expect(life.debt, 0);
      expect(life.money, 100, reason: 'the rest of the cash stays yours');
    });

    test('a partial amount pays exactly that', () {
      final life = worker();
      life.applyShock(500, 'Boiler');
      life.debugSetStats(money: 300);
      expect(life.payDownDebt(120), 120);
      expect(life.debt, 380);
      expect(life.money, 180);
    });

    test('clearing it says so and lifts the mood', () {
      final life = worker();
      life.applyShock(200, 'Boiler');
      life.debugSetStats(money: 300, happiness: 40);

      life.payDownDebt();

      expect(feed(life), contains('paid off everything you owed'));
      expect(life.happiness, 44);
      expect(life.conceptsMet, contains(FinanceConcept.interestCost));
    });

    test('says what it saved a year, in the numbers of this debt', () {
      final life = worker();
      life.applyShock(500, 'Boiler');
      life.debugSetStats(money: 300);
      life.payDownDebt();
      // 18% of the 300 paid back.
      expect(feed(life), contains('about 54 less a year'));
    });

    test('owing nothing is a no-op, not an error', () {
      final life = worker();
      life.debugSetStats(money: 300);
      expect(life.payDownDebt(), 0);
      expect(life.money, 300);
      expect(life.runTally.debtRepaid, 0);
    });

    test('with nothing to pay with it says so and changes nothing', () {
      final life = worker();
      life.applyShock(100, 'Boiler');
      expect(life.money, 0);
      expect(life.emergencyFund, 0);

      expect(life.payDownDebt(), 0);

      expect(life.debt, 100);
      expect(feed(life), contains('nothing to pay it with'));
    });

    test('is not something a child can do', () {
      final child = LifeSimController(
        random: FixedRandom.unlucky(),
        initialAge: 12,
      );
      expect(child.gateFor(LifeAction.payDownDebt), isNotNull);
      expect(child.allows(LifeAction.payDownDebt), isFalse);
      expect(child.payDownDebt(), 0);
    });

    test('is limited by money and not by a yearly budget', () {
      final life = worker();
      life.applyShock(500, 'Boiler');
      life.debugSetStats(money: 500);
      // Fifty separate payments in one year. Every other repeatable action
      // fades; this one converts cash to less debt one for one, so there is
      // nothing in it to farm and nothing to ration.
      for (var i = 0; i < 50; i++) {
        life.payDownDebt(1);
      }
      expect(life.debt, 450);
      expect(life.budgetFor(LifeAction.payDownDebt).exhausted, isFalse);
    });
  });

  group('the ceiling', () {
    test('below ten years of pay it compounds as it always did', () {
      final life = worker(salary: 180);
      life.setBudget(needs: 100, wants: 0, savings: 0);
      life.applyShock(1000, 'Boiler');

      year(life);
      final afterOne = life.debt;
      year(life);

      expect(afterOne, 1000 + 180);
      expect(life.debt, greaterThan(afterOne));
      expect(life.debt, lessThanOrEqualTo(1800));
    });

    test('at ten years of pay the balance stops growing, and says why', () {
      final life = worker(salary: 180);
      life.setBudget(needs: 100, wants: 0, savings: 0);
      life.applyShock(1790, 'Boiler');

      year(life);
      expect(life.debt, 1800, reason: 'only the 10 of room is added');
      expect(life.runTally.interestPaid, 10);

      year(life);
      year(life);
      expect(life.debt, 1800, reason: 'a debt that size stays where it is');
      expect(
        life.runTally.interestPaid,
        10,
        reason: 'and nothing more is charged on top',
      );
      expect(feed(life), contains('stopped growing'));
    });

    test('a bill bigger than the ceiling is still borrowed in full', () {
      // The ceiling only limits what interest can add. A shock is what it is.
      final life = worker(salary: 180);
      life.applyShock(50000, 'Catastrophe');
      expect(life.debt, 50000);
    });

    test(
      'the pay still goes to the lender even when the balance is capped',
      () {
        final life = worker();
        life.setBudget(needs: 50, wants: 30, savings: 20);
        life.applyShock(3600, 'Catastrophe');
        year(life);
        // Owes exactly ten years of pay, so nothing is added, but the lender
        // still takes what the slice can cover: 72 of the 648 due.
        expect(life.debt, 3600);
        expect(life.emergencyFund, 0);
        expect(life.runTally.interestPaid, 72);
      },
    );
  });

  group('over whole lives', () {
    test('a life that never manages its money does not end in millions', () {
      // The regression this file exists for, at the scale it was found.
      // Deterministic: every life is seeded, and the bot does nothing but find
      // a job and take the first option, which is the worst case for debt.
      var worst = 0;
      for (var seed = 0; seed < 40; seed++) {
        final life = LifeSimController(random: Random(seed));
        for (var y = 0; y < 90 && !life.finished; y++) {
          if (life.currentEvent == null && life.age >= 16 && !life.hasJob) {
            life.findJob();
          }
          life.ageUp();
          if (life.currentEvent != null) life.chooseOption(0);
        }
        if (life.debt > worst) worst = life.debt;
      }
      expect(
        worst,
        lessThan(100000),
        reason: 'a runaway balance means compounding is unbounded again',
      );
    });

    test('a life that uses the button ends better than one that ignores it', () {
      int endingNetWorth(int seed, {required bool payBack}) {
        final life = LifeSimController(random: Random(seed));
        for (var y = 0; y < 60 && !life.finished; y++) {
          if (life.age >= 18 && !life.budgetSet) {
            life.setBudget(needs: 50, wants: 30, savings: 20);
          }
          if (payBack && life.debt > 0) life.payDownDebt();
          if (life.currentEvent == null && life.age >= 16 && !life.hasJob) {
            life.findJob();
          }
          life.ageUp();
          if (life.currentEvent != null) life.chooseOption(0);
        }
        return life.netWorth;
      }

      // Lives, not totals. This used to add up 25 net worths and compare the
      // sums, which is a comparison one lucky life can decide: when the event
      // pool grew, seed 13 landed a windfall for the player who ignored their
      // debt and swung the total by 31,000 on its own, in the wrong direction,
      // while the payer came out ahead in 14 of the 25 lives and behind in 3.
      // Counting which life ended better is the claim ("paying back is the
      // better move") without letting the size of one outlier vote.
      var better = 0;
      var worse = 0;
      for (var seed = 0; seed < 100; seed++) {
        final paid = endingNetWorth(seed, payBack: true);
        final ignored = endingNetWorth(seed, payBack: false);
        if (paid > ignored) better++;
        if (paid < ignored) worse++;
      }
      expect(
        better,
        greaterThan(worse * 2),
        reason:
            'paying an 18% debt back has to be the better move: it won in '
            '$better lives and lost in $worse',
      );
    });
  });

  group('the debrief', () {
    LifeRunFacts facts({required int debtRepaid}) => LifeRunFacts(
      age: 60,
      netWorth: 3000,
      cash: 500,
      investments: 1000,
      emergencyFund: 1500,
      debt: 0,
      health: 60,
      happiness: 60,
      conceptsMet: 6,
      conceptsAvailable: 16,
      died: false,
      everStarved: false,
      budgetSet: true,
      savingsPct: 20,
      wantsPct: 30,
      record: LifeRunRecord(
        curve: <LifeYearPoint>[
          for (var age = 18; age <= 60; age++)
            LifeYearPoint(
              age: age,
              netWorth: (age - 18) * 70,
              happiness: 60,
              health: 70,
            ),
        ],
        moments: const <LifeMoment>[],
        tally: LifeRunTally(
          adultYears: 42,
          workYears: 40,
          incomeTotal: 30000,
          savedTotal: 6000,
          interestPaid: 300,
          debtRepaid: debtRepaid,
          peakNetWorth: 2940,
          peakAge: 60,
        ),
      ),
    );

    test('praises paying a debt back, quoting how much', () {
      final finding = debriefLife(
        facts(debtRepaid: 400),
      ).findings.firstWhere((f) => f.id == 'paid_it_down');
      expect(finding.kind, LifeFindingKind.strength);
      expect(finding.evidence, contains('400'));
      expect(finding.concept, FinanceConcept.interestCost);
    });

    test('says nothing about it when it never happened', () {
      final ids = debriefLife(facts(debtRepaid: 0)).findings.map((f) => f.id);
      expect(ids, isNot(contains('paid_it_down')));
    });
  });
}
