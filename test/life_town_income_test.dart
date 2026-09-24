import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_town_income.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';

import 'support/fixed_random.dart';

/// The town has to be worth walking around.
///
/// **Asked for as:** *"make the map get you money too."* The diagnosis was
/// specific: a map coin was worth 3 to 5 and every point of it went to the
/// account, never to the character whose money the run is about. Collected
/// coins were stored on the account, so after the first life every coin was
/// gone for good. And building scenes pay once, ever, so a second life through
/// the same town earned nothing.
///
/// These hold the fix: coins pay life money at a value that means something,
/// they restock every year, and the whole thing runs through a yearly allowance
/// so the map is a job you can choose to do and not a treadmill.
void main() {
  LifeSimController life({int age = 30}) => LifeSimController(
    random: FixedRandom.unlucky(),
    name: 'Tester',
    initialAge: age,
    startMoney: 0,
  );

  group('the numbers', () {
    test('a coin is worth four times its face value', () {
      expect(TownIncome.coinWorth(3), 12);
      expect(TownIncome.coinWorth(5), 20);
    });

    test('a full sweep of the first town is a side job, not a career', () {
      final sweep = kTownCoins.fold<int>(
        0,
        (sum, coin) => sum + TownIncome.coinWorth(coin.value),
      );
      // Worth feeling: more than a token. Worth less than a year's allowance,
      // so the coins alone never hit the cap and hustles have room after.
      expect(sweep, greaterThan(60));
      expect(sweep, lessThan(TownIncome.yearlyAllowance));
    });

    test('under the allowance pays in full', () {
      expect(TownIncome.payFor(0, 100), 100);
      expect(TownIncome.payFor(100, 100), 100);
    });

    test('over the allowance pays a quarter', () {
      expect(TownIncome.payFor(240, 100), 25);
      expect(TownIncome.payFor(500, 100), 25);
    });

    test('straddling it splits the amount', () {
      // 40 of room left: 40 in full, the other 60 at a quarter (15).
      expect(TownIncome.payFor(200, 100), 55);
    });

    test('never negative, never more than was earned', () {
      for (final so in <int>[0, 100, 240, 1000]) {
        for (final gross in <int>[0, 1, 50, 500]) {
          final paid = TownIncome.payFor(so, gross);
          expect(paid, greaterThanOrEqualTo(0));
          expect(paid, lessThanOrEqualTo(gross));
        }
      }
      expect(TownIncome.payFor(0, -20), 0);
    });

    test('the map can say when the year is spent', () {
      expect(TownIncome.isSpent(239), isFalse);
      expect(TownIncome.isSpent(240), isTrue);
    });
  });

  group('picking up a coin', () {
    test('pays life money, not just account gold', () {
      final l = life();
      final paid = l.takeTownCoin('c1', 5);
      expect(paid, 20);
      expect(l.money, 20);
      expect(l.townEarnedThisYear, 20);
      expect(l.townEarnedTotal, 20);
    });

    test('the same coin pays once a year', () {
      final l = life();
      l.takeTownCoin('c1', 5);
      expect(l.takeTownCoin('c1', 5), 0);
      expect(l.money, 20);
      expect(l.townCoinTaken('c1'), isTrue);
    });

    test('and is back next year', () {
      final l = life();
      l.takeTownCoin('c1', 5);
      l.ageUp();
      if (l.currentEvent != null) l.chooseOption(0);
      expect(l.townCoinTaken('c1'), isFalse);
      final before = l.money;
      expect(l.takeTownCoin('c1', 5), 20);
      expect(l.money, before + 20);
    });

    test('a different life starts with every coin on the map', () {
      final first = life();
      first.takeTownCoin('c1', 5);
      final second = life();
      expect(second.townCoinTaken('c1'), isFalse);
      expect(second.takeTownCoin('c1', 5), 20);
    });

    test('the fade starts once the year is spent', () {
      final l = life();
      // 12 coins of 5 is 240, exactly the allowance.
      for (var i = 0; i < 12; i++) {
        expect(l.takeTownCoin('c$i', 5), 20);
      }
      expect(l.townAllowanceSpent, isTrue);
      expect(l.takeTownCoin('extra', 5), 5, reason: 'a quarter of 20');
    });

    test('the allowance comes back with the year', () {
      final l = life();
      for (var i = 0; i < 12; i++) {
        l.takeTownCoin('c$i', 5);
      }
      l.ageUp();
      if (l.currentEvent != null) l.chooseOption(0);
      expect(l.townAllowanceSpent, isFalse);
      expect(l.townEarnedThisYear, 0);
      expect(l.townEarnedTotal, 240, reason: 'the life keeps its total');
    });

    test('a finished life takes no more coins', () {
      final l = life();
      l.retire();
      expect(l.takeTownCoin('c1', 5), 0);
    });
  });

  group('everything else the town pays goes through the same allowance', () {
    test('a paid job counts towards the year', () {
      final l = life();
      final credited = l.applyTownOutcome(gold: 60, xp: 4, literacy: 2);
      expect(credited, 60);
      expect(l.townEarnedThisYear, 60);
      expect(l.money, 60);
    });

    test('hustles and coins share one pot', () {
      final l = life();
      for (var i = 0; i < 10; i++) {
        l.takeTownCoin('c$i', 5); // 200
      }
      final credited = l.applyTownOutcome(gold: 100, xp: 0, literacy: 0);
      // 40 of room: 40 in full, 60 at a quarter.
      expect(credited, 55);
    });

    test('spending is never softened', () {
      final l = life();
      for (var i = 0; i < 12; i++) {
        l.takeTownCoin('c$i', 5);
      }
      final before = l.money;
      final credited = l.applyTownOutcome(gold: -30, xp: 0, literacy: 0);
      expect(credited, -30, reason: 'a full price once the allowance is spent');
      expect(l.money, before - 30);
    });

    test('a finished life is paid nothing', () {
      final l = life();
      l.retire();
      expect(l.applyTownOutcome(gold: 50, xp: 0, literacy: 0), 0);
      expect(l.money, 0);
    });
  });

  group('it cannot be farmed', () {
    test('a whole life of sweeping is bounded by the allowance', () {
      // The worst case: a player who does nothing but sweep every coin, every
      // year, for sixty years, and takes the fade on everything over.
      final l = life(age: 18);
      var years = 0;
      while (years < 60 && !l.finished) {
        for (var i = 0; i < 40; i++) {
          l.takeTownCoin('c$i', 5);
        }
        l.ageUp();
        if (l.currentEvent != null) l.chooseOption(0);
        years++;
      }
      // 40 coins of 20 is 800 gross. The first 240 pays in full and the other
      // 560 at a quarter (140): 380 a year at the very most.
      expect(l.townEarnedTotal, lessThanOrEqualTo(380 * years));
    });
  });
}
