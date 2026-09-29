import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_effort.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/relationship.dart';

import 'support/fixed_random.dart';

/// Nobody gets to press one button forever.
///
/// **Reported as:** *"make sure that in the menu of the main game the player
/// cannot spam the same option, like working out to become happy."* A
/// fading-returns rule existed, but only `exercise` used it. The rest paid in
/// full every time, and two of them were far worse than a stat bump:
///
///  * **Work a side job** paid 40 to 100 coins a tap with happiness clamped at
///    zero, so it was an infinite-money button in a game whose leaderboard
///    ranks net worth.
///  * **Ask for a raise** could be tapped until it landed.
///
/// These hold the whole table: every action has a budget, the budget fades
/// before it runs out, and a new year gives it back.
void main() {
  /// A working adult with money, a job and somebody to see.
  LifeSimController adult({Random? random}) {
    final life = LifeSimController(
      random: random ?? FixedRandom.unlucky(),
      name: 'Tester',
      gender: Gender.nonBinary,
      origin: LifeOrigin.workingClass,
      initialAge: 30,
      startMoney: 100000,
      startJob: 'Barista',
      startSalary: 500,
    );
    life.debugAddPerson('Sam');
    life.debugAddPerson(
      'Dana Whitfield',
      kind: RelationshipKind.colleague,
      closeness: 60,
    );
    // Room to gain, so no action is masked by a stat already at its ceiling.
    life.debugSetStats(smarts: 10, health: 20, happiness: 30, looks: 10);
    return life;
  }

  group('the table', () {
    test('every budget starts at full strength and never rises', () {
      for (final entry in EffortRules.tiers.entries) {
        expect(entry.value.first, 1.0, reason: '${entry.key} starts weak');
        for (var i = 1; i < entry.value.length; i++) {
          expect(
            entry.value[i],
            lessThanOrEqualTo(entry.value[i - 1]),
            reason: '${entry.key} pays more the ${i + 1}th time than before',
          );
        }
      }
    });

    test('no repeatable action is left without a budget', () {
      // The point of the whole change. Everything a player can tap that gives
      // something for nothing has to be limited. Money-limited actions are the
      // deliberate exceptions.
      const unlimitedOnPurpose = <LifeAction>{
        LifeAction.invest, // limited by having the money
        LifeAction.findJob, // nothing to spam once you have one
        LifeAction.payDownDebt, // one for one, so nothing to farm
      };
      for (final action in LifeAction.values) {
        if (unlimitedOnPurpose.contains(action)) continue;
        expect(
          EffortRules.capFor(action),
          isNotNull,
          reason: '$action can be spammed: it has no yearly budget',
        );
      }
    });

    test('the label says what is left and what it pays', () {
      const fresh = ActionBudget(action: LifeAction.study, used: 0);
      expect(fresh.label, '3 uses left this year');
      const fading = ActionBudget(action: LifeAction.study, used: 1);
      expect(fading.label, contains('pays 50% now'));
      const last = ActionBudget(action: LifeAction.study, used: 2);
      expect(last.label, contains('1 use left'));
      const done = ActionBudget(action: LifeAction.study, used: 3);
      expect(done.label, 'Done for this year');
      const free = ActionBudget(action: LifeAction.invest, used: 99);
      expect(free.label, isNull);
      expect(free.exhausted, isFalse);
    });
  });

  group('every limited action stops paying', () {
    /// One call per action, plus the thing to measure afterwards.
    final calls = <LifeAction, void Function(LifeSimController)>{
      LifeAction.study: (l) => l.study(),
      LifeAction.library: (l) => l.visitLibrary(),
      LifeAction.exercise: (l) => l.exercise(),
      LifeAction.goOut: (l) => l.haveFun(),
      LifeAction.doctor: (l) => l.visitDoctor(),
      LifeAction.volunteer: (l) => l.volunteer(),
      LifeAction.sideJob: (l) => l.workSideJob(),
      LifeAction.gamble: (l) => l.takeARisk(),
      LifeAction.practice: (l) => l.practice(LifeSkill.music),
      LifeAction.spendTime: (l) => l.spendTimeWith('Sam'),
      LifeAction.buyGift: (l) => l.giveGift('Sam'),
      LifeAction.workHarder: (l) => l.workHarder(),
      LifeAction.askForRaise: (l) => l.askForRaise(),
      LifeAction.network: (l) => l.attendNetworkingEvent(),
    };

    List<Object> state(LifeSimController l) => <Object>[
      l.money,
      l.happiness,
      l.health,
      l.smarts,
      l.looks,
      l.salary,
      l.investments,
      l.people.map((p) => p.closeness).join(','),
    ];

    for (final entry in calls.entries) {
      // Switched off for everybody, so there is nothing to ration.
      if (entry.key == LifeAction.gamble && !kLifeGamblingEnabled) continue;
      test('${entry.key.name}: once the year is used up, nothing moves', () {
        final life = adult();
        final cap = EffortRules.capFor(entry.key)!;

        for (var i = 0; i < cap; i++) {
          entry.value(life);
        }
        expect(
          life.budgetFor(entry.key).exhausted,
          isTrue,
          reason: '${entry.key} still has uses after $cap',
        );

        final before = state(life);
        for (var i = 0; i < 6; i++) {
          entry.value(life);
        }
        expect(
          state(life),
          before,
          reason: '${entry.key} kept paying after the year had no room left',
        );
      });
    }

    test('a new year gives the budget back', () {
      final life = adult();
      for (var i = 0; i < 6; i++) {
        life.study();
      }
      expect(life.budgetFor(LifeAction.study).exhausted, isTrue);

      life.ageUp();
      expect(life.budgetFor(LifeAction.study).exhausted, isFalse);
      expect(life.budgetFor(LifeAction.study).used, 0);
    });
  });

  group('the two that were worse than a stat bump', () {
    test('a side job can no longer print money', () {
      // Before: 40-100 a tap, unlimited, with happiness clamped at zero. Ten
      // taps was ~700 coins in one year, on top of a salary of 500.
      final life = adult(random: Random(5));
      final start = life.money;
      for (var i = 0; i < 40; i++) {
        life.workSideJob();
      }
      final earned = life.money - start;
      expect(
        earned,
        lessThanOrEqualTo(175),
        reason:
            'forty taps still paid $earned. The ceiling is one full shift, '
            'a half and a quarter of a 100-coin job',
      );
      expect(earned, greaterThan(0));
    });

    test('a raise can be asked for once a year, not until it lands', () {
      // Before: ~30% a tap, 400-1,000 each time it landed. Forty taps was a
      // near-certain, uncapped rise.
      for (var seed = 0; seed < 60; seed++) {
        final life = adult(random: Random(seed));
        final start = life.salary;
        for (var i = 0; i < 30; i++) {
          life.askForRaise();
        }
        expect(
          life.salary - start,
          lessThanOrEqualTo(999),
          reason: 'seed $seed got more than one raise in a single year',
        );
      }
    });

    test('asking a second time says so out loud', () {
      final life = adult();
      life.askForRaise();
      life.askForRaise();
      expect(life.log, contains('already asked'));
    });

    test('working harder pays half as much the second time', () {
      // Same seed on both sides, so the roll is identical and the only
      // difference is which use it is.
      final first = LifeSimController(
        random: FixedRandom.lucky(),
        initialAge: 30,
        startJob: 'Barista',
        startSalary: 500,
      );
      final second = LifeSimController(
        random: FixedRandom.lucky(),
        initialAge: 30,
        startJob: 'Barista',
        startSalary: 500,
      );
      // Effort now moves a performance bar and not the salary directly, so the
      // thing to compare is how far the bar moves.
      first.workHarder();
      final firstBump = first.performance - 60;

      second.workHarder();
      final before = second.performance;
      second.workHarder();
      final secondBump = second.performance - before;

      expect(firstBump, greaterThan(0));
      expect(
        secondBump,
        lessThan(firstBump),
        reason: 'the second push paid as much as the first',
      );
    });
  });

  group('the menu is told', () {
    test('an exhausted action reports why, and age still wins', () {
      final life = adult();
      for (var i = 0; i < 4; i++) {
        life.study();
      }
      expect(life.gateFor(LifeAction.study), isNull, reason: 'not an age gate');
      expect(life.unavailableFor(LifeAction.study), contains('this year'));

      final toddler = LifeSimController(
        random: FixedRandom.unlucky(),
        initialAge: 2,
      );
      expect(
        toddler.unavailableFor(LifeAction.study),
        toddler.gateFor(LifeAction.study),
        reason:
            'a two-year-old is told they are too young, not that they '
            'have done enough studying',
      );
    });

    test('nothing is unavailable that has room', () {
      final life = adult();
      expect(life.unavailableFor(LifeAction.exercise), isNull);
      expect(life.budgetFor(LifeAction.exercise).left, 3);
    });
  });

  group('a costly action still costs', () {
    test('a course costs the same the third time as the first', () {
      // Gains fade. Costs must not: the third course in a year being cheaper
      // would teach the wrong thing about how prices work.
      final life = adult();
      final start = life.money;
      life.study();
      final firstCost = start - life.money;
      life.study();
      life.study();
      final threeCost = start - life.money;
      expect(firstCost, 30);
      expect(threeCost, 90);
    });
  });
}
