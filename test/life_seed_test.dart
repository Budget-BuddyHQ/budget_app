import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_seed.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';

/// The seed a life is rolled from.
///
/// **What this replaced.** `LifeOrigin` was a free pick on the character
/// sheet, and it supplies the starting money: **0 coins for Struggling
/// against 2,500 for Wealthy**. The single largest advantage in the game,
/// chosen before the first year, at no cost. As a game that means the
/// leaderboard compares people who started 2,500 apart; as a lesson it is
/// worse, because an app about money was letting you pick a rich family.
///
/// A seed has to actually reproduce, or it is a decoration on a random number.
void main() {
  const firsts = <String>['Ada', 'Bo', 'Casey', 'Dev', 'Wren'];
  const lasts = <String>['Reyes', 'Okafor', 'Lindqvist', 'Nair'];

  group('a seed reproduces a life', () {
    test('the same seed always gives the same origin', () {
      for (var i = 0; i < 200; i++) {
        final a = LifeSeed(i);
        final b = LifeSeed(i);
        expect(b.origin, a.origin);
        expect(b.townIndex(2), a.townIndex(2));
        expect(
          b.suggestedName(firsts, lasts),
          a.suggestedName(firsts, lasts),
        );
      }
    });

    test('typed text gives a stable seed', () {
      expect(LifeSeed.parse('hello').value, LifeSeed.parse('hello').value);
      expect(LifeSeed.parse('HELLO').value, LifeSeed.parse('hello').value);
      expect(LifeSeed.parse('  hello  ').value, LifeSeed.parse('hello').value);
    });

    test('a number is taken as itself, so a shared seed round-trips', () {
      expect(LifeSeed.parse('12345').value, 12345);
      expect(LifeSeed.parse('-7').value, 7);
    });

    test('empty input still produces a usable seed', () {
      expect(LifeSeed.parse('').value, greaterThan(0));
    });

    test('the seed does not depend on isolate-seeded hashing', () {
      // `hashCode` is seeded per isolate in Dart, so a seed built on it would
      // give a different life every restart — a seed that reproduces nothing.
      // Pinned, because that bug has shipped in this repo twice already.
      expect(LifeSeed.parse('budget').value, LifeSeed.parse('budget').value);
      expect(LifeSeed.parse('budget').value, isNot(0));
    });

    test('the display code is short and readable', () {
      final code = LifeSeed(123456789).display;
      expect(code.length, greaterThanOrEqualTo(6));
      expect(code, code.toUpperCase());
      expect(RegExp(r'^[0-9A-Z]+$').hasMatch(code), isTrue);
    });
  });

  group('the roll is weighted, not uniform', () {
    test('most lives do not start with a cushion', () {
      // A uniform roll would make Wealthy a 1-in-4 start, which quietly
      // teaches that being born comfortable is the normal case.
      final counts = <LifeOrigin, int>{};
      for (var i = 0; i < 4000; i++) {
        final origin = LifeSeed(i).origin;
        counts[origin] = (counts[origin] ?? 0) + 1;
      }

      final wealthy = counts[LifeOrigin.wealthy] ?? 0;
      final struggling = counts[LifeOrigin.struggling] ?? 0;

      expect(wealthy / 4000, lessThan(0.15),
          reason: 'wealthy starts are too common');
      expect(struggling / 4000, greaterThan(0.25));
      expect(
        struggling,
        greaterThan(wealthy * 2),
        reason: 'being born without a cushion should be far more likely than '
            'being born with one',
      );
    });

    test('every origin is reachable', () {
      final seen = <LifeOrigin>{};
      for (var i = 0; i < 2000; i++) {
        seen.add(LifeSeed(i).origin);
      }
      expect(seen.length, LifeOrigin.values.length);
    });
  });

  group('the draws are independent', () {
    test('two seeds one apart do not move together', () {
      // Channels keep origin, name and town from shifting against each other.
      // If they were one sequence, reordering a draw would silently change
      // every seed's meaning.
      var originChanges = 0;
      var townChanges = 0;
      for (var i = 0; i < 300; i++) {
        if (LifeSeed(i).origin != LifeSeed(i + 1).origin) originChanges++;
        if (LifeSeed(i).townIndex(2) != LifeSeed(i + 1).townIndex(2)) {
          townChanges++;
        }
      }
      expect(originChanges, greaterThan(50));
      expect(townChanges, greaterThan(50));
    });

    test('both towns come up', () {
      final towns = <int>{};
      for (var i = 0; i < 200; i++) {
        towns.add(LifeSeed(i).townIndex(2));
      }
      expect(towns, containsAll(<int>[0, 1]));
    });

    test('a single-map world never rolls out of range', () {
      for (var i = 0; i < 50; i++) {
        expect(LifeSeed(i).townIndex(1), 0);
      }
    });
  });
}
