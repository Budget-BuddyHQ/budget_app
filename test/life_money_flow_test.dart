import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';

import 'support/fixed_random.dart';

/// Where a paycheck goes, and what happens when something costs more than the
/// cash.
///
/// **Reported as:** *"the budget amount is still weird, like I had 4000 and it
/// went crashing down to 0 and I can't get it up, and I'm getting raises."*
///
/// Two separate faults sat behind that. The needs slice of a paycheck was
/// deducted in full even when living cost far less, so on a 1,552 salary about
/// 600 a year vanished and **nothing in a paycheck ever reached spendable
/// cash**. And an event that cost more than the cash on hand was clamped to
/// zero, so the shortfall was erased instead of owed. Cash could only ever fall.
void main() {
  LifeSimController adult({int salary = 1000, int money = 0, int age = 30}) {
    final life = LifeSimController(
      random: FixedRandom.unlucky(),
      name: 'Tester',
      gender: Gender.nonBinary,
      origin: LifeOrigin.workingClass,
      initialAge: age,
      startMoney: money,
      startJob: salary > 0 ? 'Barista' : null,
      startSalary: salary,
    );
    life.debugSetStats(health: 85, happiness: 65);
    return life;
  }

  void year(LifeSimController life) {
    life.ageUp();
    life.debugClearEvent();
    life.debugSetStats(health: 85, happiness: 65);
  }

  String feed(LifeSimController life) =>
      life.history.map((e) => e.text).join(' | ');

  const bill = LifeEvent(
    id: 'test_bill',
    prompt: 'A bill arrives.',
    icon: Icons.receipt_long_rounded,
    choices: [
      LifeChoice(label: 'Pay it', outcome: 'Paid.', money: -900),
      LifeChoice(label: 'Ignore it', outcome: 'Ignored.'),
    ],
  );

  group('pay reaches cash', () {
    test(
      'the part of the needs slice that living did not cost stays yours',
      () {
        final life = adult(salary: 1000, money: 0);
        life.setBudget(needs: 50, wants: 30, savings: 20);

        year(life);

        // Needs slice 500, living cost 180: 320 was never needed.
        expect(life.money, 320);
        expect(life.emergencyFund, 200);
        expect(feed(life), contains('Living cost 180, so 320 stayed yours'));
      },
    );

    test('a needs slice that only just covers living leaves nothing spare', () {
      final life = adult(salary: 360, money: 0);
      life.setBudget(needs: 50, wants: 30, savings: 20);
      year(life);
      expect(life.money, 0);
      expect(feed(life), isNot(contains('stayed yours')));
    });

    test('a slice too small for living still costs health, as before', () {
      final life = adult(salary: 1000, money: 0);
      life.setBudget(needs: 10, wants: 80, savings: 10);
      final before = life.health;
      // Not `year`: that helper puts health back, which hides the very thing
      // this is checking.
      life.ageUp();
      life.debugClearEvent();
      expect(life.health, lessThan(before), reason: 'needs must still bite');
    });

    test('over-budgeting needs is not a way to lose money', () {
      // Two lives, identical but for where the same 20% goes. If it vanished
      // into needs, net worth would differ; it stays yours, so it does not.
      final tight = adult(salary: 1000)
        ..setBudget(needs: 50, wants: 30, savings: 20);
      final loose = adult(salary: 1000)
        ..setBudget(needs: 70, wants: 30, savings: 0);
      year(tight);
      year(loose);
      expect(loose.netWorth, tight.netWorth);
    });

    test('4,000 in cash on a working salary does not run down to nothing', () {
      // The reported run, without the random bills: a paid job and a default
      // budget. Cash used to be the one number that could only fall.
      final life = adult(salary: 1552, money: 4000, age: 35);
      var lowest = life.money;
      for (var i = 0; i < 10; i++) {
        year(life);
        if (life.money < lowest) lowest = life.money;
      }
      expect(lowest, greaterThanOrEqualTo(4000));
      expect(life.money, greaterThan(4000));
    });

    test(
      'a working adult can always afford a check-up after a year of pay',
      () {
        final life = adult(salary: 1000, money: 0);
        year(life);
        life.debugSetStats(health: 40);
        life.visitDoctor();
        expect(life.health, greaterThan(40));
      },
    );
  });

  group('a cost that the cash cannot cover', () {
    test('comes out of savings before it is borrowed', () {
      final life = adult(salary: 1000, money: 400);
      life.setBudget(needs: 50, wants: 30, savings: 20);
      year(life); // banks 200 in the fund and 320 spare in cash.
      life.debugSetStats(money: 400);
      expect(life.emergencyFund, 200);

      life.debugSetEvent(bill);
      life.chooseOption(0);

      // 900: 400 cash, 200 savings, 300 borrowed.
      expect(life.money, 0);
      expect(life.emergencyFund, 0);
      expect(life.debt, 300);
      expect(feed(life), contains('300 of it is now borrowed'));
    });

    test('is never destroyed: net worth falls by exactly the cost', () {
      final life = adult(salary: 1000, money: 400);
      final before = life.netWorth;
      life.debugSetEvent(bill);
      life.chooseOption(0);
      expect(life.netWorth, before - 900);
    });

    test('says so when savings had to be used', () {
      final life = adult(salary: 1000, money: 0);
      life.setBudget(needs: 50, wants: 30, savings: 20);
      year(life);
      life.debugSetStats(money: 100);
      life.debugSetEvent(
        const LifeEvent(
          id: 'test_small',
          prompt: 'A smaller bill.',
          icon: Icons.receipt_long_rounded,
          choices: [LifeChoice(label: 'Pay', outcome: 'Paid.', money: -250)],
        ),
      );
      life.chooseOption(0);
      expect(life.debt, 0);
      expect(feed(life), contains('came out of savings'));
    });

    test('a child is covered by the family and never owes', () {
      final child = adult(salary: 0, money: 50, age: 12);
      child.debugSetEvent(bill);
      child.chooseOption(0);
      expect(child.money, 0);
      expect(child.debt, 0, reason: 'a twelve-year-old cannot be in debt');
    });

    test('a gain is still just cash', () {
      final life = adult(salary: 1000, money: 100);
      life.debugSetEvent(
        const LifeEvent(
          id: 'test_gift',
          prompt: 'A gift.',
          icon: Icons.card_giftcard_rounded,
          choices: [LifeChoice(label: 'Take it', outcome: 'Nice.', money: 250)],
        ),
      );
      life.chooseOption(0);
      expect(life.money, 350);
    });
  });
}
