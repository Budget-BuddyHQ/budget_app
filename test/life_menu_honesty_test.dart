import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every enabled control has to actually do something.
///
/// **The bug this exists for.** The Money menu's "Invest 100 coins" row was
/// disabled on one condition — whether you held 100 coins — and never asked
/// about age. `investCash` *does* check the age gate and returns silently
/// when it fails, so a two-year-old with 150 coins got a button that looked
/// live, took a tap, and did nothing at all. No error, no message, no change.
///
/// That is the worst shape a bug can take in a game for children: it does not
/// look like a fault, it looks like the game ignoring you.
///
/// **What this file does and does not cover.** The controller was never
/// wrong — `invest` checked the gate correctly the whole time. The bug lived
/// in the menu row, so these tests would not have caught it and it would be
/// dishonest to imply otherwise. What they hold is the contract the menu
/// depends on: that for every action, at every age, "the controller allows
/// you" and "calling it changes something" are the same answer. A row that is
/// offered and does nothing is then only possible if the row disagrees with
/// the controller, and that half is prevented structurally instead — every
/// row must name the `LifeAction` it performs, and `_LifeAction.gatedBy` is
/// applied to all of them in one expression, so there is no longer a place to
/// forget it.
void main() {
  /// A controller parked at [age] with enough of everything to afford things,
  /// so the only thing that can block an action is the age gate itself.
  LifeSimController at(int age) =>
      LifeSimController(random: Random(7), initialAge: age, startMoney: 5000);

  group('gateFor is the only gate', () {
    test('every action is allowed at some age and blocked at none by luck', () {
      // Sanity on the table itself: an action nobody can ever take is a dead
      // menu row, and one nobody is ever blocked from does not need a gate.
      for (final action in LifeAction.values) {
        final allowedSomewhere = <int>[
          for (var age = 0; age <= 80; age++) age,
        ].any((age) => at(age).allows(action));
        expect(
          allowedSomewhere,
          isTrue,
          reason: '$action is blocked at every age from 0 to 80',
        );
      }
    });

    test('gates never un-gate as you get older', () {
      // Once an action opens it should stay open. A gate that closes again is
      // almost always a bug, and it would read to a player as the game taking
      // something away for no stated reason.
      for (final action in LifeAction.values) {
        var opened = false;
        for (var age = 0; age <= 80; age++) {
          final allowed = at(age).allows(action);
          if (allowed) {
            opened = true;
          } else {
            expect(
              opened,
              isFalse,
              reason: '$action was allowed earlier and is blocked at $age',
            );
          }
        }
      }
    });

    test('a blocked action always says why, in words a player can read', () {
      final life = at(2);
      for (final action in LifeAction.values) {
        if (life.allows(action)) continue;
        final reason = life.gateFor(action);
        expect(reason, isNotNull);
        expect(
          reason!.length,
          greaterThan(8),
          reason: '$action blocks with "$reason", which explains nothing',
        );
        // "Not yet" is the fallback in the switch. Hitting it means an action
        // was added without giving it a sentence of its own.
        expect(
          reason,
          isNot('Not yet'),
          reason: '$action fell through to the default gate message',
        );
      }
    });
  });

  group('the actions the menus call', () {
    /// Runs [act] and reports whether anything about the run changed.
    ///
    /// Deliberately coarse — it does not care *what* moved, only that
    /// something did. A control that is offered and changes nothing is the
    /// failure being hunted, whatever the mechanism.
    bool changesSomething(LifeSimController life, void Function() act) {
      final before = <Object>[
        life.money,
        life.investments,
        life.happiness,
        life.health,
        life.smarts,
        life.looks,
        life.job,
        life.log.length,
      ];
      act();
      final after = <Object>[
        life.money,
        life.investments,
        life.happiness,
        life.health,
        life.smarts,
        life.looks,
        life.job,
        life.log.length,
      ];
      return !const ListEquality().equals(before, after);
    }

    /// Every action the menus expose, paired with the call the row makes.
    Map<LifeAction, void Function(LifeSimController)> calls() => {
      LifeAction.study: (l) => l.study(),
      LifeAction.library: (l) => l.visitLibrary(),
      LifeAction.exercise: (l) => l.exercise(),
      LifeAction.goOut: (l) => l.haveFun(),
      LifeAction.doctor: (l) => l.visitDoctor(),
      LifeAction.volunteer: (l) => l.volunteer(),
      LifeAction.sideJob: (l) => l.workSideJob(),
      LifeAction.findJob: (l) => l.findJob(),
      LifeAction.invest: (l) => l.invest(100),
      LifeAction.gamble: (l) => l.takeARisk(),
    };

    test('if the controller allows it, doing it changes the run', () {
      for (final entry in calls().entries) {
        for (final age in const <int>[2, 5, 8, 12, 14, 16, 18, 25, 40, 70]) {
          final life = at(age);
          if (!life.allows(entry.key)) continue;
          expect(
            changesSomething(life, () => entry.value(life)),
            isTrue,
            reason:
                '${entry.key} is allowed at $age but changed nothing when '
                'called — the menu would offer a button that does nothing',
          );
        }
      }
    });

    test('if the controller blocks it, doing it changes nothing', () {
      // The other half of the contract. A blocked action must be inert rather
      // than half-applied — an action that took the money and then refused
      // would be the same bug pointing the other way.
      for (final entry in calls().entries) {
        for (final age in const <int>[0, 1, 2, 3, 5, 9, 13, 15, 17]) {
          final life = at(age);
          if (life.allows(entry.key)) continue;
          expect(
            changesSomething(life, () => entry.value(life)),
            isFalse,
            reason:
                '${entry.key} is blocked at $age but changed the run anyway',
          );
        }
      }
    });
  });

  group('the ages themselves are sane', () {
    test('a two-year-old cannot invest, gamble, work or go out alone', () {
      final toddler = at(2);
      for (final action in const <LifeAction>[
        LifeAction.invest,
        LifeAction.gamble,
        LifeAction.sideJob,
        LifeAction.findJob,
        LifeAction.goOut,
        LifeAction.exercise,
      ]) {
        expect(
          toddler.allows(action),
          isFalse,
          reason: 'a two-year-old should not be able to $action',
        );
      }
    });

    test('a small child can still be taken to a doctor', () {
      // The one action with no floor, and on purpose: a parent takes a child
      // to the clinic. Making health unreachable for the first five years
      // would be a worse simulation, not a stricter one.
      expect(at(1).allows(LifeAction.doctor), isTrue);
    });

    test('an adult can do everything', () {
      final grown = at(30);
      for (final action in LifeAction.values) {
        expect(
          grown.allows(action),
          isTrue,
          reason: '$action is still blocked at 30',
        );
      }
    });
  });
}

/// Local list comparison, so this file needs no extra dependency.
class ListEquality {
  const ListEquality();

  bool equals(List<Object> a, List<Object> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
