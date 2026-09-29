import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_age_bands.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_conditions.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_scenarios.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';

/// The town is a place to learn, not a place to farm.
///
/// **The report:** "by repeatedly entering certain places and town, users can
/// get more and more money for doing the exact same thing."
///
/// **What was actually happening.** `AdventureWorldScreen._openSpot` handed
/// the chosen option's gold, XP and literacy to `applyChallengePayload` on
/// every single visit, and remembered nothing. The coins scattered on the
/// floor had been de-duplicated long ago — with a comment saying in as many
/// words that a respawning coin would be "an unlimited tap on the economy" —
/// but the buildings, which pay several times more, had no equivalent.
///
/// The anti-repetition work made it faster rather than causing it.
/// `TownCondition` is rolled once per entry to the town and feeds the scene
/// rotation, so stepping outside and back in re-deals all twelve buildings.
/// That is exactly the right behavior for keeping the place interesting, and
/// it turned the exploit from "re-take one choice" into "re-take twelve fresh
/// ones, on demand, forever".
///
/// The fix is the coins' fix, one level up: a persisted ledger of encounters
/// that have already paid, keyed on the *conversation* rather than the
/// building — so a shop you have dealt with today still has something
/// different to say tomorrow, it just does not pay you twice for the same
/// decision.
void main() {
  final day = DateTime(2026, 5, 4, 12);

  group('an encounter can be identified, which is what the ledger needs', () {
    test('every encounter has an id, including the built-in one', () {
      for (final spot in kTownSpots) {
        final encounter = townEncounterFor(spot, now: day);
        expect(encounter.id, isNotEmpty);
      }
    });

    test('the id names the conversation, not the building', () {
      // If the key were the spot id, one visit would shut a shop for good and
      // the whole rotation would be wasted. If it were the day, the ledger
      // would reset every midnight and the farm would reopen on a timer.
      final ids = <String>{};
      for (final spot in kTownSpots) {
        for (final condition in kTownConditions) {
          for (var age = 6; age <= 70; age += 4) {
            ids.add(
              townEncounterFor(
                spot,
                now: day,
                lifeAge: age,
                conditionId: condition.id,
              ).id,
            );
          }
        }
      }
      expect(
        ids.length,
        greaterThan(kTownSpots.length),
        reason:
            'the town only produces ${ids.length} distinct encounter ids '
            'across ${kTownSpots.length} spots — the ledger would lock whole '
            'buildings rather than individual conversations',
      );
    });

    test('the same conversation keeps the same id', () {
      // A ledger key that moved would let the farm straight back in: every
      // visit would look like a scene that had never paid out.
      for (final spot in kTownSpots) {
        final first = townEncounterFor(
          spot,
          now: day,
          lifeAge: 30,
          conditionId: 'ordinary',
        );
        final second = townEncounterFor(
          spot,
          now: DateTime(2026, 5, 4, 23, 59),
          lifeAge: 30,
          conditionId: 'ordinary',
        );
        expect(first.id, second.id, reason: '${spot.id} re-keys within a day');
      }
    });
  });

  group('the payout pool is finite', () {
    test('walking in and out cannot produce unlimited paying encounters', () {
      // The property that actually matters, stated as a number. Re-entering
      // the town re-rolls the condition, so the *most* a player can reach on
      // one day at one age is one encounter per (spot, condition) pair — and
      // because several conditions land on the same scene, the real figure is
      // lower still. Whatever it is, it is bounded, enumerable, and every one
      // of them is a different decision rather than the same one repeated.
      const age = 30;
      final reachable = <String>{};
      for (final spot in kTownSpots) {
        for (final condition in kTownConditions) {
          reachable.add(
            townEncounterFor(
              spot,
              now: day,
              lifeAge: age,
              conditionId: condition.id,
            ).id,
          );
        }
      }

      // One per spot would mean the condition does nothing and the town is
      // static again; one per (spot, condition) would mean no two conditions
      // ever agree, which the hash makes vanishingly unlikely.
      expect(reachable.length, greaterThan(kTownSpots.length));
      expect(
        reachable.length,
        lessThanOrEqualTo(kTownSpots.length * kTownConditions.length),
      );
    });

    test('the screen zeroes both directions on a settled encounter', () {
      // Withholding only the income would be worse than doing nothing: a shop
      // would keep taking money for a purchase it no longer rewards, so
      // re-reading a scene you had already worked through would *cost* you.
      final source = File(
        'lib/screens_minigames_admin_etc/Gameplay/adventure/'
        'adventure_world_screen.dart',
      ).readAsStringSync();

      for (final line in const <String>[
        'final goldDelta = settled ? 0 : affordable;',
        'final xpDelta = settled ? 0 : choice.xp;',
        'final literacyDelta = settled ? 0 : choice.literacy;',
      ]) {
        expect(
          source,
          contains(line),
          reason: 'the settled-encounter payout rule has changed: $line',
        );
      }

      expect(
        source,
        contains("'town_resolved_scenes': _resolvedScenes.toList()"),
        reason: 'the ledger is no longer being saved, so it resets on exit',
      );
      expect(
        source,
        contains('_resolvedScenes.addAll(stats.townResolvedSceneIds)'),
        reason: 'the ledger is no longer being loaded, so it resets on entry',
      );
    });
  });

  group('the town grows up with the character', () {
    test('every banded id is a scenario that exists', () {
      // A typo here fails open — the scenario keeps its default of "any age"
      // and a nine-year-old gets asked about their overdraft — so it has to
      // be checked rather than assumed.
      final known = <String>{
        for (final list in kTownScenarios.values)
          for (final scenario in list) scenario.id,
      };
      for (final id in kTownScenarioMinAge.keys) {
        expect(
          known,
          contains(id),
          reason: '$id has an age band but is not a scenario in kTownScenarios',
        );
      }
    });

    test('a small child is never handed an adult problem', () {
      // Rent arrears, overdraft coverage, a heating bill, a room-share advert.
      // `OutingPermission` will not even let this character leave the house
      // alone before six, and `life_age_gates` will not give them a job — a
      // town that then asks how they are covering the rent undoes both.
      for (final spot in kTownSpots) {
        for (final condition in kTownConditions) {
          for (var age = 6; age < 13; age++) {
            final encounter = townEncounterFor(
              spot,
              now: day,
              lifeAge: age,
              conditionId: condition.id,
            );
            expect(
              townScenarioMinAge(encounter.id),
              lessThanOrEqualTo(age),
              reason:
                  '${spot.id} offered "${encounter.id}" to a $age-year-old',
            );
          }
        }
      }
    });

    test('growing up opens things up rather than closing them down', () {
      // The bands are a floor, never a ceiling. An adult should be able to
      // reach everything a child could, plus more — otherwise ageing would
      // quietly delete content, which is the opposite of the point.
      for (final spot in kTownSpots) {
        final child = townScenariosFor(spot, lifeAge: 8).map((s) => s.id);
        final adult = townScenariosFor(
          spot,
          lifeAge: 30,
        ).map((s) => s.id).toSet();
        expect(
          adult,
          containsAll(child),
          reason: '${spot.id} takes scenes away as the character ages',
        );
      }

      final childTotal = kTownSpots
          .map((spot) => townScenariosFor(spot, lifeAge: 8).length)
          .reduce((a, b) => a + b);
      final adultTotal = kTownSpots
          .map((spot) => townScenariosFor(spot, lifeAge: 30).length)
          .reduce((a, b) => a + b);
      expect(
        adultTotal,
        greaterThan(childTotal),
        reason:
            'the town offers the same $childTotal scenes at eight and at '
            'thirty, so the age bands are doing nothing',
      );
    });

    test('no building runs out of things to say at any age', () {
      // Filtering could in principle strip a spot down to nothing. It cannot
      // here, because the built-in encounter is index 0 and is never banded —
      // but that is a property worth pinning rather than reasoning about,
      // since it is the difference between a quiet building and a crash.
      for (final spot in kTownSpots) {
        for (var age = 6; age <= 90; age += 2) {
          final encounter = townEncounterFor(spot, now: day, lifeAge: age);
          expect(encounter.choices, isNotEmpty);
          expect(encounter.prompt, isNotEmpty);
        }
      }
    });

    test('the town still visits everything once nobody is living a life', () {
      // Wandering the town on its own has no character and therefore no age,
      // so nothing is filtered and all the content stays reachable.
      for (final spot in kTownSpots) {
        expect(
          townScenariosFor(spot, lifeAge: null).length,
          kTownScenarios[spot.id]?.length ?? 0,
        );
      }
    });
  });
}
