import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:flutter_test/flutter_test.dart';

/// The endings collection, and the nudge the epilogue gives towards it.
///
/// **Why this is the retention mechanic worth building.** It is the only thing
/// in the app that rewards playing *differently* rather than playing more,
/// which is exactly the behavior a financial-literacy game wants. Nothing
/// here is a streak, a timer or a "come back tomorrow" — the reason to open
/// the app again is that there is a specific life you have not lived yet.
///
/// It sat on the Play hub, below the fold, as tiles reading "Undiscovered":
/// visible only to somebody who had already decided to come back, and telling
/// them there was something to find but nothing about how to find it.
void main() {
  group('every ending explains how to reach it', () {
    test('the hint is a usable sentence', () {
      for (final ending in LifeEndingArchetype.values) {
        expect(
          ending.howToReach.length,
          greaterThan(30),
          reason: '${ending.label} has no real hint',
        );
        expect(
          ending.howToReach.endsWith('.'),
          isTrue,
          reason: '${ending.label} hint is not a sentence',
        );
      }
    });

    test('a hint is a nudge, not a recipe', () {
      // Long enough to change how somebody plays, short enough that the game
      // does not become a checklist to execute.
      for (final ending in LifeEndingArchetype.values) {
        expect(
          ending.howToReach.length,
          lessThan(130),
          reason: '${ending.label} reads as instructions',
        );
      }
    });
  });

  group('what the game suggests you chase', () {
    test('the two failure endings are never suggested first', () {
      // **The bug this exists for.** The first version took the first ending
      // missing from the enum, which is `goneTooSoon` — so the advice to a
      // child who had just finished their first life was "ignore your health
      // long enough and the run ends early".
      final ordered = LifeEndingArchetype.values.toList()
        ..sort((a, b) => a.chaseOrder.compareTo(b.chaseOrder));

      expect(ordered.first, LifeEndingArchetype.comfortableRetiree);
      expect(
        ordered.last,
        LifeEndingArchetype.goneTooSoon,
        reason: 'dying young should be the last thing the game suggests',
      );
      expect(
        ordered[ordered.length - 2],
        LifeEndingArchetype.cautionaryTale,
      );
    });

    test('the ending the curriculum points at comes first', () {
      // Budget, keep an emergency fund, retire with enough. If the app is
      // going to suggest a life, it should suggest that one.
      expect(LifeEndingArchetype.comfortableRetiree.chaseOrder, 0);
    });

    test('the order is a total ordering with no ties', () {
      final seen = <int>{};
      for (final ending in LifeEndingArchetype.values) {
        expect(
          seen.add(ending.chaseOrder),
          isTrue,
          reason: '${ending.label} shares a chase order with another ending',
        );
      }
      expect(seen.length, LifeEndingArchetype.values.length);
    });
  });

  group('the collection is completable', () {
    test('every ending is reachable from some real life', () {
      // A collectable that cannot be collected is worse than no collectable.
      final reached = <LifeEndingArchetype>{};
      for (final died in <bool>[true, false]) {
        for (var age = 20; age <= 90; age += 5) {
          for (final worth in <int>[-5000, 0, 8000, 60000, 400000]) {
            for (final happy in <int>[10, 45, 85]) {
              for (final smarts in <int>[20, 60, 95]) {
                reached.add(
                  resolveLifeEnding(
                    died: died,
                    age: age,
                    netWorth: worth,
                    happiness: happy,
                    smarts: smarts,
                  ),
                );
              }
            }
          }
        }
      }
      final unreachable = LifeEndingArchetype.values
          .where((e) => !reached.contains(e))
          .toList();
      expect(
        unreachable,
        isEmpty,
        reason: 'these endings can never happen: '
            '${unreachable.map((e) => e.label).join(", ")}',
      );
    });

    test('every ending has a face and a blurb', () {
      for (final ending in LifeEndingArchetype.values) {
        expect(ending.portrait, endsWith('.png'));
        expect(ending.blurb.length, greaterThan(40));
      }
    });
  });
}
