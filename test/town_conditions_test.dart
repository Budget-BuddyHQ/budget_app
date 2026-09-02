import 'dart:math';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_conditions.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Town conditions — what the place is like on the day you walk in.
///
/// The maths here is small and the signs in it are easy to get backwards,
/// which is the whole reason for this file: a negative amount is money
/// leaving you, so "cheaper" has to move it *towards* zero. Get that one
/// wrong and a sale charges you extra, silently, in a game about money.
void main() {
  group('prices move the right way', () {
    final marketDay = kTownConditions.firstWhere((c) => c.id == 'market_day');
    final pricesUp = kTownConditions.firstWhere((c) => c.id == 'prices_up');
    final quiet = kTownConditions.firstWhere((c) => c.id == 'quiet_week');
    final ordinary = kTownConditions.firstWhere((c) => c.id == 'ordinary');

    test('a cheap day costs you less, not more', () {
      // -100 is a hundred coins leaving. Cheaper must mean a smaller loss.
      final normal = ordinary.priceFor(-100, TownSpotKind.market);
      final sale = marketDay.priceFor(-100, TownSpotKind.market);
      expect(normal, -100);
      expect(sale, greaterThan(normal));
      expect(sale, lessThan(0), reason: 'a discount is not a payout');
    });

    test('a dear day costs you more', () {
      final dear = pricesUp.priceFor(-100, TownSpotKind.cafe);
      expect(dear, lessThan(-100));
    });

    test('a condition only touches the buildings it names', () {
      // Market day is about food. It must not quietly discount the clinic.
      expect(marketDay.priceFor(-100, TownSpotKind.clinic), -100);
      expect(marketDay.priceFor(-100, TownSpotKind.pawnShop), -100);
    });

    test('selling and buying move independently', () {
      // A good week to sell is not a good week to buy, and folding both into
      // one multiplier would teach that a shop's prices and its offers rise
      // together — which is the opposite of true.
      expect(
        quiet.priceFor(60, TownSpotKind.pawnShop),
        greaterThan(60),
        reason: 'the pawn shop is paying over the odds',
      );
      expect(
        quiet.priceFor(-60, TownSpotKind.pawnShop),
        -60,
        reason: 'paying more for stock does not make its shelves cheaper',
      );
    });

    test('a cheap day does not turn an earning into a loss', () {
      for (final condition in kTownConditions) {
        for (final kind in TownSpotKind.values) {
          expect(
            condition.priceFor(50, kind),
            greaterThan(0),
            reason: '${condition.id} at $kind flipped an earning negative',
          );
          expect(
            condition.priceFor(-50, kind),
            lessThan(0),
            reason: '${condition.id} at $kind turned a cost into a payout',
          );
          expect(condition.priceFor(0, kind), 0);
        }
      }
    });
  });

  group('the mix', () {
    test('ordinary days are the common case', () {
      // If every visit were an event, none of them would be one.
      final random = Random(3);
      var ordinaryDays = 0;
      const runs = 2000;
      for (var i = 0; i < runs; i++) {
        if (rollTownCondition(random).isOrdinary) ordinaryDays++;
      }
      final share = ordinaryDays / runs;
      expect(
        share,
        inInclusiveRange(0.35, 0.60),
        reason: 'ordinary came up ${(share * 100).round()}% of the time',
      );
    });

    test('every condition is reachable', () {
      final random = Random(11);
      final seen = <String>{};
      for (var i = 0; i < 5000; i++) {
        seen.add(rollTownCondition(random).id);
      }
      for (final condition in kTownConditions) {
        expect(
          seen,
          contains(condition.id),
          reason: '${condition.id} never came up in 5000 visits',
        );
      }
    });

    test('exactly one condition is the ordinary one', () {
      expect(kTownConditions.where((c) => c.isOrdinary).length, 1);
    });
  });

  group('what it says', () {
    test('every special day explains itself in terms of money', () {
      for (final condition in kTownConditions) {
        expect(condition.label.length, inInclusiveRange(4, 26));
        expect(
          condition.note.length,
          greaterThan(40),
          reason: '${condition.id} has nothing to say',
        );
      }
    });

    test('a hint appears exactly where prices actually change', () {
      for (final condition in kTownConditions) {
        for (final kind in TownSpotKind.values) {
          final hint = condition.hintFor(kind);
          final changes = condition.priceFor(-100, kind) != -100 ||
              condition.priceFor(100, kind) != 100;
          expect(
            hint != null,
            changes,
            reason:
                '${condition.id} at $kind: hint=${hint != null}, '
                'prices changed=$changes — these must agree or the sign is '
                'lying to the player',
          );
        }
      }
    });

    test('an ordinary day hints at nothing anywhere', () {
      final ordinary = kTownConditions.firstWhere((c) => c.isOrdinary);
      for (final kind in TownSpotKind.values) {
        expect(ordinary.hintFor(kind), isNull);
      }
    });
  });

  group('the quoted price is the charged price', () {
    // The map applies `priceFor` before charging; the interior applies it
    // before printing. If those two ever disagree the game quotes one number
    // and takes another, which is the single worst thing a money game can do.
    // Holding them to the same function is the only way they stay equal, so
    // this checks the function is total and stable rather than checking two
    // call sites that could both drift.
    test('the same inputs always give the same number', () {
      for (final condition in kTownConditions) {
        for (final kind in TownSpotKind.values) {
          for (final amount in const <int>[-180, -60, -8, -1, 1, 25, 400]) {
            final first = condition.priceFor(amount, kind);
            final second = condition.priceFor(amount, kind);
            expect(first, second);
          }
        }
      }
    });

    test('small prices do not round away to nothing', () {
      // -1 at 0.7 is -0.7, and rounding that to 0 would make the cheapest
      // items free on a sale day.
      for (final condition in kTownConditions) {
        for (final kind in TownSpotKind.values) {
          expect(
            condition.priceFor(-1, kind),
            isNot(0),
            reason: '${condition.id} at $kind made a 1-coin item free',
          );
        }
      }
    });
  });

  test('an unknown id falls back rather than throwing', () {
    // Called with whatever was persisted, which may be from an older build.
    expect(townConditionById('no_such_day').id, kTownConditions.first.id);
    expect(townConditionById('market_day').id, 'market_day');
  });
}
