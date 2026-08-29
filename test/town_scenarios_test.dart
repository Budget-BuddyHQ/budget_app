import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_scenarios.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Adventure town is one fixed map with six buildings, and the complaint
/// was that it had "only one type of generation" — the second visit to any
/// building was the first visit, word for word.
///
/// Rotating scenarios is the answer that adds content without adding map. The
/// properties below are what make that rotation feel like a town rather than
/// like a slot machine.
void main() {
  group('the town has more than one thing to say', () {
    test('every spot has at least five encounters', () {
      // Raised from two once the second content pass landed. Two was the bar
      // for "not literally the same scene twice"; five is the bar for a town
      // worth walking back into, because the rotation is by *day* — at two
      // scenes a spot repeats itself every other day, which is how often
      // somebody actually plays.
      for (final spot in kTownSpots) {
        final total = 1 + (kTownScenarios[spot.id]?.length ?? 0);
        expect(
          total,
          greaterThanOrEqualTo(5),
          reason:
              '${spot.id} has only $total encounters, so it comes round again '
              'within a week of daily play',
        );
      }
    });

    test('the town carries a substantial amount of content', () {
      final total = kTownSpots.length +
          kTownScenarios.values.fold<int>(0, (sum, list) => sum + list.length);
      expect(
        total,
        greaterThanOrEqualTo(36),
        reason: 'only $total encounters exist across the whole town',
      );
    });

    test('scenario ids are unique', () {
      // Ids are how a scenario would be referenced from a quest or a save, so
      // a duplicate is a silent aliasing bug rather than a cosmetic one.
      final ids = <String>[
        for (final list in kTownScenarios.values)
          for (final scenario in list) scenario.id,
      ];
      expect(ids.toSet().length, ids.length, reason: 'duplicate scenario id');
    });

    test('scenarios are attached to spots that exist', () {
      final spotIds = kTownSpots.map((spot) => spot.id).toSet();
      final orphans = kTownScenarios.keys
          .where((id) => !spotIds.contains(id))
          .toList();
      expect(orphans, isEmpty, reason: 'scenarios for unknown spots: $orphans');
    });
  });

  group('every encounter is playable', () {
    test('each offers at least two real choices', () {
      // A single-option "choice" is a cutscene. The town's whole design is
      // that walking there is the game and the decision is the lesson.
      for (final list in kTownScenarios.values) {
        for (final scenario in list) {
          expect(
            scenario.choices.length,
            greaterThanOrEqualTo(2),
            reason: '${scenario.id} has nothing to decide',
          );
        }
      }
    });

    test('every choice explains itself', () {
      // The rule the original spots follow: no option is silently wrong, and
      // the outcome line teaches rather than scores. A short outcome is a
      // scoreline.
      for (final list in kTownScenarios.values) {
        for (final scenario in list) {
          expect(scenario.prompt.length, greaterThan(40), reason: scenario.id);
          for (final choice in scenario.choices) {
            expect(choice.label, isNotEmpty, reason: scenario.id);
            expect(
              choice.outcome.length,
              greaterThan(60),
              reason: '${scenario.id} · "${choice.label}" explains nothing',
            );
          }
        }
      }
    });

    test('no encounter is a trap where every option costs money', () {
      // A scene where walking away is not on the table teaches that spending
      // is compulsory, which is the opposite of the lesson.
      for (final list in kTownScenarios.values) {
        for (final scenario in list) {
          final free = scenario.choices.where((c) => c.gold >= 0);
          expect(
            free,
            isNotEmpty,
            reason: '${scenario.id} charges for every option',
          );
        }
      }
    });
  });

  group('the rotation', () {
    test('is stable within a day', () {
      // A scene that rerolls on every entry turns a decision into a slot
      // machine and removes the reason to have walked there.
      final morning = DateTime(2026, 3, 14, 8);
      final evening = DateTime(2026, 3, 14, 21);
      for (final spot in kTownSpots) {
        expect(
          townEncounterFor(spot, now: morning).prompt,
          townEncounterFor(spot, now: evening).prompt,
          reason: '${spot.id} changed scene during the same day',
        );
      }
    });

    test('changes across days', () {
      // The point of the whole exercise. Checked over a fortnight because any
      // single pair of days can legitimately repeat.
      for (final spot in kTownSpots) {
        final seen = <String>{};
        for (var day = 0; day < 14; day++) {
          seen.add(
            townEncounterFor(
              spot,
              now: DateTime(2026, 3, 1).add(Duration(days: day)),
            ).prompt,
          );
        }
        expect(
          seen.length,
          greaterThan(1),
          reason: '${spot.id} showed the same scene for two solid weeks',
        );
      }
    });

    test('reaches every scenario a spot has', () {
      // A scenario that the rotation can never select is content nobody will
      // ever see — worse than not writing it, because it looks written.
      for (final spot in kTownSpots) {
        final total = 1 + (kTownScenarios[spot.id]?.length ?? 0);
        final indices = <int>{};
        for (var day = 0; day < 120; day++) {
          indices.add(
            townScenarioIndexFor(
              spot.id,
              now: DateTime(2026).add(Duration(days: day)),
              extraCount: total - 1,
            ),
          );
        }
        expect(
          indices.length,
          total,
          reason:
              '${spot.id} only ever reaches ${indices.length} of its $total '
              'encounters',
        );
      }
    });

    test('different spots do not all show scene one on the same day', () {
      // The spot id is mixed into the hash for this reason: without it every
      // building would advance in lockstep and the town would have one state
      // rather than six.
      final indices = <int>{
        for (final spot in kTownSpots)
          townScenarioIndexFor(
            spot.id,
            now: DateTime(2026, 5, 2),
            extraCount: kTownScenarios[spot.id]?.length ?? 0,
          ),
      };
      expect(
        indices.length,
        greaterThan(1),
        reason: 'every building is showing the same scene number',
      );
    });
  });
}
