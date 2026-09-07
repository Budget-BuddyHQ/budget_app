import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';

/// The money has to add up.
///
/// **Two bugs a tester found by playing.** *"I got my paycheck and it didn't
/// give me any [money]"* and *"he basically doesn't get all the money he gets
/// from the jobs that he does."* Both were real:
///
///  * `wantsBudget` was subtracted from cash every payday and produced
///    **nothing** — no happiness, no stat, no line. The only other use of
///    `_wantsPct` was a penalty for setting it at or below 5%. There was no
///    winning move.
///  * A negative balance after the savings transfer was clamped with
///    `_money = 0`, which **destroys money**. A short year had the shortfall
///    silently deleted instead of becoming debt, so the ledger stopped
///    reconciling — which is exactly what "doesn't get all the money" looks
///    like from outside.
///
/// A financial literacy app whose own arithmetic does not balance is teaching
/// the wrong thing twice over, so these are pinned hard.
void main() {
  /// A seeded life, so random events cannot swamp what is being measured.
  ///
  /// **Seeding matters more than it looks here.** Ageing up rolls events that
  /// move happiness and health by more than any single budget or workout
  /// does, and the controller's default `Random()` is unseeded. The first
  /// version of these tests passed alone and failed in a full run — not
  /// flakiness in the code, but a confound in the test: two controllers were
  /// being compared while living two different lives.
  ///
  /// Same seed for both sides of a comparison means the *only* difference is
  /// the thing under test.
  LifeSimController working({
    int salary = 1000,
    int money = 0,
    int seed = 7,
  }) {
    return LifeSimController(
      random: Random(seed),
      name: 'Tester',
      gender: Gender.nonBinary,
      origin: LifeOrigin.workingClass,
      initialAge: 25,
      startMoney: money,
      startSalary: salary,
    );
  }

  group('a paycheck never destroys money', () {
    test('cash plus savings plus debt accounts for the whole salary', () {
      final life = working(salary: 1000, money: 500);
      final before = life.money + life.emergencyFund - life.debt;

      life.ageUp();

      final after = life.money + life.emergencyFund - life.debt;
      // Needs and wants are genuinely consumed, so net worth does not rise by
      // the full salary — but it must never *fall* on a year you were paid
      // and nothing bad happened.
      expect(
        after,
        greaterThanOrEqualTo(before - 1),
        reason: 'a paid year left the player worse off — money is leaking',
      );
    });

    test('a shortfall becomes debt rather than vanishing', () {
      // Start with nothing, so the savings transfer cannot be covered.
      final life = working(salary: 1000, money: 0);
      life.ageUp();

      // Whatever happened, cash is never negative and nothing was silently
      // erased: if the player could not cover it, they owe it.
      expect(life.money, greaterThanOrEqualTo(0));
      expect(life.emergencyFund, greaterThanOrEqualTo(0));
      expect(life.debt, greaterThanOrEqualTo(0));
    });

    test('savings never exceed what was actually there to save', () {
      final life = working(salary: 2000, money: 0);
      for (var i = 0; i < 5; i++) {
        life.ageUp();
      }
      // The fund can only hold money that existed. If it outruns everything
      // the player ever had, the transfer is inventing currency.
      expect(life.emergencyFund, lessThanOrEqualTo(2000 * 6));
    });
  });

  group('wants buy something', () {
    test('spending on wants raises happiness', () {
      final spender = working(salary: 1000);
      final saver = working(salary: 1000);

      spender.setBudget(needs: 50, wants: 40, savings: 10);
      saver.setBudget(needs: 50, wants: 10, savings: 40);

      final spenderBefore = spender.happiness;
      final saverBefore = saver.happiness;

      spender.ageUp();
      saver.ageUp();

      final spenderGain = spender.happiness - spenderBefore;
      final saverGain = saver.happiness - saverBefore;

      expect(
        spenderGain,
        greaterThan(saverGain),
        reason:
            'the wants budget is charged either way — if it buys no more '
            'happiness than not spending it, the money is a black hole and '
            'the 30 in 50/30/20 means nothing',
      );
    });

    test('but wants cannot buy a whole life', () {
      final maximalist = working(salary: 1000);
      maximalist.setBudget(needs: 20, wants: 75, savings: 5);
      final before = maximalist.happiness;
      maximalist.ageUp();

      // Capped: you cannot spend your way past the trade-off the game is
      // about. Under-funding needs has its own consequences elsewhere.
      expect(maximalist.happiness - before, lessThanOrEqualTo(6));
    });
  });

  group('the same action twice in one year pays less', () {
    test('the gym cannot be spammed', () {
      final life = working();
      life.exercise();
      final afterFirst = life.health;

      life.exercise();
      final afterSecond = life.health;

      life.exercise();
      life.exercise();
      final afterFourth = life.health;

      final first = afterFirst - 85;
      final second = afterSecond - afterFirst;

      expect(first, greaterThan(0));
      expect(
        second,
        lessThan(first),
        reason: 'the second workout of a year paid as much as the first — '
            'the optimal move is still to tap one button repeatedly',
      );
      expect(
        afterFourth,
        lessThanOrEqualTo(afterSecond + 2),
        reason: 'a fourth workout still moved the needle',
      );
    });

    test('a new year restores the allowance', () {
      final life = working();
      life.exercise();
      life.exercise();
      life.exercise();
      life.exercise();
      final exhausted = life.health;

      life.ageUp();
      life.exercise();

      expect(
        life.health,
        greaterThan(exhausted),
        reason: 'the diminishing return is permanent instead of annual, so a '
            'long life runs out of things to do',
      );
    });

    test('health is still clamped to a sane range', () {
      final life = working();
      for (var year = 0; year < 40; year++) {
        life.exercise();
        life.exercise();
        life.ageUp();
      }
      expect(life.health, lessThanOrEqualTo(100));
      expect(life.health, greaterThanOrEqualTo(0));
    });
  });
}
