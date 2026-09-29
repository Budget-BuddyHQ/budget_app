import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:flutter_test/flutter_test.dart';

LifeSimController _at(int age, {int money = 500}) => LifeSimController(
  random: Random(7),
  initialAge: age,
  startMoney: money,
);

void main() {
  group('a toddler cannot live an adult life', () {
    // The bug this locks down: every one of these was reachable at age three.
    // The menu offered a grown adult's options to a three-year-old, which is
    // the single biggest thing that made the sim feel unreal.
    const forbiddenAtThree = <LifeAction>[
      LifeAction.study,
      LifeAction.library,
      LifeAction.exercise,
      LifeAction.goOut,
      LifeAction.buyGift,
      LifeAction.volunteer,
      LifeAction.sideJob,
      LifeAction.findJob,
      LifeAction.invest,
      LifeAction.gamble,
      LifeAction.practice,
    ];

    for (final action in forbiddenAtThree) {
      test('${action.name} is blocked at 3', () {
        expect(_at(3).allows(action), isFalse);
        expect(_at(3).gateFor(action), isNotNull);
      });
    }

    test('the reason is written for the player, not for a log', () {
      // "You are too little for that" *is* the content at age three — being
      // told what you cannot do yet is how the early years teach that a life
      // has stages. So these have to be sentences, not error codes.
      for (final action in forbiddenAtThree) {
        final reason = _at(3).gateFor(action)!;
        expect(reason, isNotEmpty);
        expect(reason.length, greaterThan(8), reason: action.name);
        expect(reason, isNot(contains('_')), reason: action.name);
      }
    });

    test('seeing a doctor is never blocked by age', () {
      // A parent takes a small child to the doctor. Gating this would punish
      // exactly the character who has least control over it.
      expect(_at(1).allows(LifeAction.doctor), isTrue);
      expect(_at(40).allows(LifeAction.doctor), isTrue);
    });

    test('spending time with someone is never blocked by age', () {
      expect(_at(2).allows(LifeAction.spendTime), isTrue);
    });
  });

  group('the gates actually stop the action, not just grey out a button', () {
    // The rules live in the controller precisely so they hold no matter who
    // calls. A menu-only check would leave them unenforced everywhere else.
    test('a toddler who calls study directly gains nothing', () {
      final life = _at(3);
      final before = life.smarts;
      life.study();
      expect(life.smarts, before);
    });

    test('a toddler cannot work out', () {
      final life = _at(3);
      final before = life.health;
      life.exercise();
      expect(life.health, before);
    });

    test('a toddler cannot invest', () {
      final life = _at(3, money: 900);
      life.invest(100);
      expect(life.investments, 0);
      expect(life.money, 900);
    });

    test('a child cannot gamble', () {
      final life = _at(12, money: 900);
      life.takeARisk();
      expect(life.money, 900);
    });

    test('a child cannot take a side job', () {
      final life = _at(9);
      final before = life.money;
      life.workSideJob();
      expect(life.money, before);
    });
  });

  group('gates open at the right age', () {
    void opensAt(LifeAction action, int age) {
      test('${action.name} opens at $age', () {
        expect(
          _at(age - 1).allows(action),
          isFalse,
          reason: '${action.name} was already open at ${age - 1}',
        );
        expect(_at(age).allows(action), isTrue);
      });
    }

    opensAt(LifeAction.study, 5);
    opensAt(LifeAction.library, 6);
    opensAt(LifeAction.buyGift, 6);
    opensAt(LifeAction.volunteer, 10);
    opensAt(LifeAction.exercise, 12);
    opensAt(LifeAction.goOut, 12);
    opensAt(LifeAction.sideJob, 14);
    opensAt(LifeAction.findJob, 16);
    opensAt(LifeAction.invest, 16);
    // Switched off for everybody for now, so it opens at no age. The age
    // table still says 18 for the day the switch comes back on.
    if (kLifeGamblingEnabled) opensAt(LifeAction.gamble, 18);
    opensAt(LifeAction.practice, 4);

    test('every action has a decision, none fall through', () {
      // A missing entry would silently default to "allowed at any age",
      // which is the exact failure mode being fixed here.
      for (final action in LifeAction.values) {
        expect(
          () => _at(30).allows(action),
          returnsNormally,
          reason: action.name,
        );
      }
    });
  });

  group('a finished life closes everything', () {
    test('retiring blocks every action', () {
      final life = _at(70);
      life.retire();
      for (final action in LifeAction.values) {
        expect(life.allows(action), isFalse, reason: action.name);
      }
    });
  });
}
