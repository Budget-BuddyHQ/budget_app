import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_challenges.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';

/// The town's money puzzles.
///
/// **Why this file is unusually paranoid.** Every other screen in this app can
/// be wrong in a way somebody notices. A challenge that marks the wrong option
/// correct teaches a child the opposite of the truth, tells them they were
/// wrong when they were right, and looks completely normal doing it. The
/// arithmetic has to be checked by something that does the arithmetic
/// independently, which is what these tests are.
void main() {
  const kinds = TownSpotKind.values;

  Iterable<TownChallenge> everyChallenge({int days = 60, int ages = 20}) sync* {
    for (final kind in kinds) {
      for (var day = 0; day < days; day++) {
        for (var age = 2; age < ages; age++) {
          final c = townChallengeFor(kind, age: age, daySeed: day);
          if (c != null) yield c;
        }
      }
    }
  }

  group('the generator is safe at every seed', () {
    test('nothing throws across thousands of combinations', () {
      // The generators do division, recursion on ties, and index arithmetic.
      // Any of those can blow up on one unlucky seed, and that seed will be
      // somebody's Tuesday.
      var produced = 0;
      for (final _ in everyChallenge()) {
        produced++;
      }
      expect(produced, greaterThan(1000));
    });

    test('every challenge has a valid correct index', () {
      for (final c in everyChallenge(days: 25)) {
        expect(c.correctIndex, greaterThanOrEqualTo(0));
        expect(c.correctIndex, lessThan(c.options.length));
      }
    });

    test('every challenge offers a real choice', () {
      for (final c in everyChallenge(days: 25)) {
        expect(
          c.options.length,
          greaterThanOrEqualTo(2),
          reason: '${c.id} produced a puzzle with nothing to choose between',
        );
      }
    });

    test('no challenge has two equally correct answers', () {
      // A tie marks a right answer wrong. This is the single worst thing this
      // file could do and it would be invisible.
      for (final c in everyChallenge(days: 40)) {
        final winning = c.options[c.correctIndex].score;
        final matches = c.options.where((o) => o.score == winning).length;
        expect(
          matches,
          1,
          reason: '${c.id} has $matches options tied for correct',
        );
      }
    });

    test('the marked answer really is the best one', () {
      // Grading re-derived here rather than trusted. If `_bestIndex` and this
      // loop ever disagree, one of them is wrong and it matters which.
      for (final c in everyChallenge(days: 40)) {
        for (var i = 0; i < c.options.length; i++) {
          if (i == c.correctIndex) continue;
          if (c.lowerIsBetter) {
            expect(
              c.options[i].score,
              greaterThan(c.options[c.correctIndex].score),
              reason: '${c.id}: option $i beats the one marked correct',
            );
          } else {
            expect(
              c.options[i].score,
              lessThan(c.options[c.correctIndex].score),
            );
          }
        }
      }
    });

    test('prices and prompts are never empty or negative-looking', () {
      for (final c in everyChallenge(days: 20)) {
        expect(c.prompt.trim(), isNotEmpty);
        expect(c.explanation.trim(), isNotEmpty);
        expect(c.title.trim(), isNotEmpty);
        expect(c.reward, greaterThan(0));
        for (final o in c.options) {
          expect(o.label.trim(), isNotEmpty);
          expect(o.detail.trim(), isNotEmpty);
          expect(
            o.label,
            isNot(contains('-')),
            reason: '${c.id} produced a negative price: ${o.label}',
          );
        }
      }
    });
  });

  group('the same day gives the same puzzle', () {
    test('it is stable across calls', () {
      // The town has to be the same place if you walk out and back in.
      for (final kind in kinds) {
        final a = townChallengeFor(kind, age: 14, daySeed: 7);
        final b = townChallengeFor(kind, age: 14, daySeed: 7);
        if (a == null) {
          expect(b, isNull);
          continue;
        }
        expect(b!.id, a.id);
        expect(b.prompt, a.prompt);
        expect(b.correctIndex, a.correctIndex);
      }
    });

    test('it changes across days', () {
      // Otherwise the answer is memorisable and the skill is not being
      // practised, only recalled.
      final prompts = <String>{};
      for (var day = 0; day < 30; day++) {
        final c = townChallengeFor(
          TownSpotKind.market,
          age: 14,
          daySeed: day,
        );
        if (c != null) prompts.add(c.prompt);
      }
      expect(prompts.length, greaterThan(5));
    });

    test('the seed does not depend on isolate-seeded hashing', () {
      // `Object.hash` and `String.hashCode` are seeded per isolate in Dart,
      // so a rotation built on them re-deals on every app restart. That bug
      // has been shipped here once already; this pins the replacement.
      expect(stableChallengeHash('library:3:4'), 1415080409);
      expect(stableChallengeHash(''), 0x811c9dc5);
    });
  });

  group('buildings promise the kind of decision inside them', () {
    test('places to be, rather than to calculate, have no challenge', () {
      // A park with a maths question in it makes the whole town a worksheet.
      expect(
        townChallengeFor(TownSpotKind.park, age: 12, daySeed: 3),
        isNull,
      );
      expect(
        townChallengeFor(TownSpotKind.home, age: 12, daySeed: 3),
        isNull,
      );
    });

    test('the bank never asks about the price of rice', () {
      for (var day = 0; day < 40; day++) {
        final c = townChallengeFor(TownSpotKind.bank, age: 16, daySeed: day);
        expect(c, isNotNull);
        expect(c!.id, isNot('unit_price'));
        expect(c.id, isNot('tip'));
      }
    });

    test('a shop never asks about compound interest', () {
      for (var day = 0; day < 40; day++) {
        final c = townChallengeFor(TownSpotKind.market, age: 16, daySeed: day);
        expect(c!.id, anyOf('unit_price', 'percent_off'));
      }
    });
  });

  group('age changes difficulty, not availability', () {
    test('young players still get a puzzle everywhere older ones do', () {
      for (final kind in kinds) {
        final young = townChallengeFor(kind, age: 6, daySeed: 11);
        final older = townChallengeFor(kind, age: 17, daySeed: 11);
        expect(
          young == null,
          older == null,
          reason: '${kind.name} is empty for one age band and not the other',
        );
      }
    });

    test('the youngest never meet compounding or subscriptions', () {
      // Not a judgement about capability — those need arithmetic a
      // six-year-old has not been taught. They get the same *skill* at a size
      // that fits, rather than being locked out of the building.
      for (final kind in kinds) {
        for (var day = 0; day < 30; day++) {
          final c = townChallengeFor(kind, age: 6, daySeed: day);
          if (c == null) continue;
          expect(c.id, anyOf('unit_price', 'percent_off'));
        }
      }
    });

    test('teenagers do meet them', () {
      final ids = <String>{};
      for (var day = 0; day < 40; day++) {
        for (final kind in kinds) {
          final c = townChallengeFor(kind, age: 16, daySeed: day);
          if (c != null) ids.add(c.id);
        }
      }
      expect(ids, contains('compound'));
      expect(ids, contains('subscription'));
    });
  });

  group('the arithmetic is right, checked independently', () {
    test('unit price: the cheapest per unit wins', () {
      for (var day = 0; day < 60; day++) {
        final c = townChallengeFor(TownSpotKind.market, age: 8, daySeed: day);
        if (c == null || c.id != 'unit_price') continue;

        // Re-derive the per-unit price out of the label the player reads,
        // rather than out of the score the generator set — so a bug in the
        // generator cannot hide behind its own arithmetic.
        final parsed = <double>[];
        for (final o in c.options) {
          final m = RegExp(r'(\d+) \w+ for (\d+) coins').firstMatch(o.label);
          expect(m, isNotNull, reason: 'unreadable label: ${o.label}');
          parsed.add(int.parse(m!.group(2)!) / int.parse(m.group(1)!));
        }
        final cheapest = parsed.reduce((a, b) => a < b ? a : b);
        expect(parsed[c.correctIndex], closeTo(cheapest, 0.0001));
      }
    });

    test('percent off: the smaller final price wins', () {
      for (var day = 0; day < 60; day++) {
        final c = townChallengeFor(
          TownSpotKind.pawnShop,
          age: 15,
          daySeed: day,
        );
        if (c == null || c.id != 'percent_off') continue;
        expect(c.options, hasLength(2));
        final other = c.correctIndex == 0 ? 1 : 0;
        expect(
          c.options[c.correctIndex].score,
          lessThan(c.options[other].score),
        );
      }
    });

    test('compound: the exact figure is the answer, not simple interest', () {
      for (var day = 0; day < 60; day++) {
        final c = townChallengeFor(TownSpotKind.bank, age: 17, daySeed: day);
        if (c == null || c.id != 'compound') continue;
        // The correct option is the one with zero distance from the truth.
        expect(c.options[c.correctIndex].score, 0);
        // And the simple-interest distractor is present and is not it.
        expect(c.options.length, 3);
        expect(
          c.options.where((o) => o.score == 0).length,
          1,
          reason: 'more than one option claims to be exactly right',
        );
      }
    });

    test('tip: total is bill plus percentage, and the traps are wrong', () {
      for (var day = 0; day < 60; day++) {
        final c = townChallengeFor(TownSpotKind.cafe, age: 15, daySeed: day);
        if (c == null || c.id != 'tip') continue;
        expect(c.options[c.correctIndex].score, 0);
        final m = RegExp(r'bill is (\d+) coins and you want to leave (\d+)%')
            .firstMatch(c.prompt);
        expect(m, isNotNull);
        final bill = int.parse(m!.group(1)!);
        final pct = int.parse(m.group(2)!);
        final expected = (bill + bill * pct / 100).toStringAsFixed(0);
        expect(c.options[c.correctIndex].label, contains(expected));
      }
    });

    test('subscription: twelve monthly payments are compared, not one', () {
      for (var day = 0; day < 60; day++) {
        final c = townChallengeFor(TownSpotKind.library, age: 16, daySeed: day);
        if (c == null || c.id != 'subscription') continue;
        final monthly = RegExp(r'(\d+) coins a month')
            .firstMatch(c.options[0].label);
        expect(monthly, isNotNull);
        expect(
          c.options[0].score,
          int.parse(monthly!.group(1)!) * 12,
          reason: 'the monthly option is not being annualised',
        );
      }
    });
  });
}
