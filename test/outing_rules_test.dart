import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/outing_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('who may leave the house', () {
    OutingPermission at({
      int age = 20,
      int health = 90,
      HouseholdStrictness strictness = HouseholdStrictness.normal,
      Weather weather = Weather.clear,
    }) => OutingPermission.evaluate(
      age: age,
      health: health,
      strictness: strictness,
      weather: weather,
    );

    test('a small child cannot go out alone', () {
      final p = at(age: 3);
      expect(p.allowed, isFalse);
      expect(p.reason, OutingBlockReason.tooYoung);
      expect(p.message, isNotEmpty);
    });

    test('a healthy adult in clear weather can', () {
      expect(at().allowed, isTrue);
    });

    test('household strictness decides the in-between years', () {
      // 11 is the interesting age: allowed in a relaxed home, not in a
      // strict one. This is the whole point of the factor — same age, same
      // weather, different life.
      expect(at(age: 11, strictness: HouseholdStrictness.relaxed).allowed, isTrue);
      expect(at(age: 11, strictness: HouseholdStrictness.strict).allowed, isFalse);
      expect(
        at(age: 11, strictness: HouseholdStrictness.strict).reason,
        OutingBlockReason.strictParents,
      );
    });

    test('nobody is held back by household rules from 16', () {
      for (final s in HouseholdStrictness.values) {
        expect(
          at(age: 16, strictness: s).allowed,
          isTrue,
          reason: '$s still blocks a 16-year-old',
        );
      }
    });

    test('a storm keeps even an adult in, ordinary rain does not', () {
      expect(at(weather: Weather.storm).allowed, isFalse);
      expect(at(weather: Weather.storm).reason, OutingBlockReason.badWeather);
      // Rain is atmosphere, not an obstacle — gating on it would close the
      // town roughly a quarter of all years, which is tedious not realistic.
      expect(at(weather: Weather.rain).allowed, isTrue);
      expect(at(weather: Weather.snow).allowed, isTrue);
    });

    test('being seriously unwell keeps you in', () {
      final p = at(health: 5);
      expect(p.allowed, isFalse);
      expect(p.reason, OutingBlockReason.unwell);
    });

    test('age is reported before weather when both would block', () {
      // The message should always name the thing that has to change first,
      // so a toddler in a storm is told they are too young.
      expect(at(age: 3, weather: Weather.storm).reason, OutingBlockReason.tooYoung);
    });
  });

  group('weather rolls', () {
    test('every weather is reachable and clear is the common case', () {
      final counts = <Weather, int>{};
      final random = Random(4);
      for (var i = 0; i < 4000; i++) {
        final w = WeatherInfo.roll(random);
        counts[w] = (counts[w] ?? 0) + 1;
      }
      for (final w in Weather.values) {
        expect(counts[w] ?? 0, greaterThan(0), reason: '$w never rolled');
      }
      expect(
        counts[Weather.clear]!,
        greaterThan(counts[Weather.storm]!),
        reason: 'storms should be an event, not the norm',
      );
    });

    test('only a storm blocks going out', () {
      for (final w in Weather.values) {
        expect(w.blocksOuting, w == Weather.storm, reason: '$w');
      }
    });
  });

  group('the controller wires it up', () {
    test('a newborn is not allowed out', () {
      final life = LifeSimController(random: Random(3));
      expect(life.age, 0);
      expect(life.outingPermission.allowed, isFalse);
      expect(life.outingPermission.reason, OutingBlockReason.tooYoung);
    });

    test('the same seed always produces the same household', () {
      // Guards a real bug: `strictness` was a `late final` with a random
      // initialiser, so it consumed its random number whenever it was first
      // *read* — meaning the whole downstream RNG sequence depended on
      // whether the UI happened to check it. Now assigned in the
      // constructor, so a seed fully determines the life.
      final a = LifeSimController(random: Random(99));
      final b = LifeSimController(random: Random(99));
      expect(a.strictness, b.strictness);

      // Reading it early on one of them must not shift anything either.
      final c = LifeSimController(random: Random(99));
      c.outingPermission;
      final d = LifeSimController(random: Random(99));
      for (var i = 0; i < 20; i++) {
        c.ageUp();
        d.ageUp();
      }
      expect(c.age, d.age);
      expect(c.money, d.money);
      expect(c.happiness, d.happiness);
    });

    test('ageing re-rolls the weather over a life', () {
      final life = LifeSimController(random: Random(8), initialAge: 5);
      final seen = <Weather>{};
      for (var i = 0; i < 60 && !life.finished; i++) {
        life.ageUp();
        // `ageUp` deliberately no-ops while an event is waiting on a
        // choice, so a loop that only calls ageUp gets stuck on the first
        // event and the character never actually ages.
        if (life.currentEvent != null) {
          life.chooseOption(0);
        }
        seen.add(life.weather);
      }
      expect(
        seen.length,
        greaterThan(1),
        reason: 'weather never changed across a whole life',
      );
    });
  });
}
