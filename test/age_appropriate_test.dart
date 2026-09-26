import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/volunteer_places.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a young account is allowed to be shown.
///
/// **The hole this closes.** Every gambling gate in the simulation ran off the
/// *character's* age — `LifeAction.gamble` opens at an in-game 18 — which is
/// right for the fiction and no safeguard at all. A four-year-old reaches an
/// eighteen-year-old character in about ninety seconds of tapping Age, and was
/// then offered "Gamble 100 coins. A 42% chance to double it." on the same
/// screen as the library and the doctor.
///
/// `AgeBand.isMinorUnder13` existed the whole time and was referenced by
/// nothing.
///
/// The line drawn here is **staked wagers**, not the subject of gambling. The
/// cautionary events stay for every age: `t_loot_box` states the real odds of
/// a 0.6% drop and `t_skin_gamble` explains a 5% house cut, their outcomes are
/// scripted, and they are the most useful things in the pack for precisely the
/// children this flag protects. Showing a nine-year-old what a loot box does
/// to your money is the job. Letting them pull the lever is not.
void main() {
  LifeSimController adult({bool wagering = true}) => LifeSimController(
    random: Random(4),
    initialAge: 30,
    startMoney: 5000,
    allowWagering: wagering,
  );

  group('the age band decides, not the character', () {
    test('under-13 accounts may not wager; everyone else may', () {
      expect(AgeBand.age9to12.allowsWagering, isFalse);
      // The under-13 bucket was split into 4-8 and 9-12 so the two halves
      // could be *taught* differently. Every protection has to apply to both
      // halves, or splitting a bucket for content reasons quietly opened a
      // gate for the younger one.
      expect(AgeBand.under9.allowsWagering, isFalse);
      expect(AgeBand.under9.isMinorUnder13, isTrue);
      expect(AgeBand.under9.prefersSimpleWording, isTrue);
      expect(AgeBand.teen13to15.allowsWagering, isTrue);
      expect(AgeBand.teen16to17.allowsWagering, isTrue);
      expect(AgeBand.adult18plus.allowsWagering, isTrue);
    });

    test('declining to answer is not treated as a child', () {
      // The sign-up question is optional and skippable. Gating content behind
      // answering a personal question teaches children to over-share to get
      // features, which is a worse outcome than the one being prevented.
      expect(AgeBand.undisclosed.allowsWagering, isTrue);
    });
  });

  group('a young account cannot gamble at any character age', () {
    test('the action does nothing however old the character gets', () {
      for (final age in const <int>[18, 25, 40, 70]) {
        final life = LifeSimController(
          random: Random(1),
          initialAge: age,
          startMoney: 5000,
          allowWagering: false,
        );
        final before = life.money;
        life.takeARisk();
        expect(
          life.money,
          before,
          reason: 'a wager settled at character age $age on a child account',
        );
      }
    });

    test('an adult account can gamble only while the switch is on', () {
      // Gambling is off for everybody for now (`kLifeGamblingEnabled`), on
      // request. This holds both states of the switch so that turning it back
      // on is one line and does not leave a test asserting the opposite.
      final life = adult();
      final before = life.money;
      life.takeARisk();
      if (kLifeGamblingEnabled) {
        expect(life.money, isNot(before));
      } else {
        expect(life.money, before, reason: 'gambling is switched off');
        expect(life.allows(LifeAction.gamble), isFalse);
      }
    });

    test('wager events never draw for a young account', () {
      // Played to the end, many times over: the pool must never surface one.
      final wagers = kLifeEvents.where((e) => e.isWager).map((e) => e.id);
      expect(wagers, isNotEmpty, reason: 'nothing is tagged as a wager');

      for (var seed = 0; seed < 60; seed++) {
        final life = LifeSimController(
          random: Random(seed),
          initialAge: 0,
          allowWagering: false,
        );
        while (!life.finished && life.age < 90) {
          final event = life.currentEvent;
          if (event != null) {
            expect(
              event.isWager,
              isFalse,
              reason: 'seed $seed drew "${event.id}" on a child account',
            );
            life.chooseOption(0);
          }
          life.ageUp();
        }
      }
    });

    test('those same events are reachable for an adult account', () {
      // Otherwise the flag is hiding content from everybody and the test
      // above passes for the wrong reason.
      final seen = <String>{};
      for (var seed = 0; seed < 200; seed++) {
        final life = LifeSimController(
          random: Random(seed),
          initialAge: 0,
          allowWagering: true,
        );
        while (!life.finished && life.age < 90) {
          final event = life.currentEvent;
          if (event != null) {
            if (event.isWager) seen.add(event.id);
            life.chooseOption(
              Random(seed * 3 + life.age).nextInt(event.choices.length),
            );
          }
          life.ageUp();
        }
      }
      if (kLifeGamblingEnabled) {
        expect(
          seen,
          isNotEmpty,
          reason: 'no wager event fired for an adult in 200 runs',
        );
      } else {
        expect(
          seen,
          isEmpty,
          reason: 'gambling is off for everybody, so no wager should draw',
        );
      }
    });

    test('the cautionary events are shown to everybody', () {
      // These teach what the mechanic does. They are not wagers and must not
      // be swept up by the flag.
      for (final id in const <String>['t_loot_box', 't_skin_gamble']) {
        final event = kLifeEvents.firstWhere((e) => e.id == id);
        expect(
          event.isWager,
          isFalse,
          reason:
              '$id is cautionary content, not a wager — hiding it from '
              'young players removes the lesson they most need',
        );
      }
    });
  });

  group('volunteering is a decision now', () {
    test('there is more than one place, and they differ', () {
      expect(kVolunteerPlaces.length, greaterThan(3));
      final hours = kVolunteerPlaces.map((p) => p.hours).toSet();
      expect(hours.length, greaterThan(2), reason: 'they all cost the same');
    });

    test('none of them pay money', () {
      // The whole point of the feature: you give time and get back something
      // money cannot buy. `VolunteerPlace` has no money field on purpose, so
      // what is left to check is that no outcome quietly narrates a payment.
      for (final place in kVolunteerPlaces) {
        expect(
          place.outcome.contains(r'$'),
          isFalse,
          reason: '${place.id} pays out a figure',
        );
        expect(
          RegExp(
            r'(earned|wages|salary|got paid)',
          ).hasMatch(place.outcome.toLowerCase()),
          isFalse,
          reason: '${place.id} reads as paid work',
        );
      }
    });

    test('more hours is broadly more reward, but not linearly', () {
      // Effort and meaning correlate — that is honest. If they correlated
      // *perfectly* there would be no decision, just a biggest button.
      final byHours = kVolunteerPlaces.toList()
        ..sort((a, b) => a.hours.compareTo(b.hours));
      expect(byHours.first.happiness, lessThan(byHours.last.happiness));

      final rates = kVolunteerPlaces.map((p) => p.happinessPerHour).toList();
      expect(
        rates.toSet().length,
        greaterThan(2),
        reason: 'every option pays the same per hour, so there is no trade',
      );
    });

    test('the shortest option is not simply the best', () {
      // A cheap option that dominates would make every other row decoration.
      final cheapest = kVolunteerPlaces.reduce(
        (a, b) => a.hours <= b.hours ? a : b,
      );
      final better = kVolunteerPlaces.where(
        (p) => p.happiness > cheapest.happiness,
      );
      expect(better, isNotEmpty);
    });

    test('young players get a smaller list', () {
      final child = volunteerPlacesFor(10);
      final teen = volunteerPlacesFor(15);
      expect(child.length, lessThan(teen.length));
      expect(child, isNotEmpty, reason: 'a ten-year-old can still help');
    });

    test('picking a place applies that place', () {
      final life = LifeSimController(random: Random(2), initialAge: 20);
      final shelter = kVolunteerPlaces.firstWhere(
        (p) => p.id == 'animal_shelter',
      );
      final before = life.happiness;
      life.volunteer(shelter);
      expect(life.happiness - before, shelter.happiness);
      expect(life.log, shelter.outcome);
    });

    test('calling it with no place still works', () {
      // Older call sites and tests predate the picker.
      final life = LifeSimController(random: Random(2), initialAge: 20);
      final before = life.happiness;
      life.volunteer();
      expect(life.happiness, greaterThan(before));
    });

    test('a place you are too young for is ignored, not applied', () {
      final life = LifeSimController(random: Random(2), initialAge: 10);
      final shop = kVolunteerPlaces.firstWhere((p) => p.id == 'charity_shop');
      life.volunteer(shop);
      expect(
        life.log,
        isNot(shop.outcome),
        reason: 'a ten-year-old was given a job on a till',
      );
    });
  });
}
