import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/leak_patrol_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';

/// Leak Patrol.
///
/// **The design this has to protect.** The whole game rests on one
/// distinction: tap the leaks, leave the real charges. If tapping everything
/// wins, it teaches indiscriminate suspicion — which is not vigilance, and
/// cancelling your own electricity is its own kind of mistake.
///
/// So the tests that matter here are the ones about the *board's* balance and
/// about what a careless player scores, not about the arithmetic.
void main() {
  group('tapping everything must not win', () {
    test('real charges are not rare', () {
      final leaks = kLeakItems.where((i) => i.isLeak).length;
      final real = kLeakItems.length - leaks;
      expect(
        real,
        greaterThanOrEqualTo(leaks - 1),
        reason:
            'if leaks are the common case, tapping every hole is the winning '
            'strategy and the game teaches the opposite of its own point',
      );
    });

    test('the most expensive mistake is cancelling a real charge', () {
      final worstLeak = kLeakItems
          .where((i) => i.isLeak)
          .map((i) => i.value)
          .reduce((a, b) => a > b ? a : b);
      final worstReal = kLeakItems
          .where((i) => !i.isLeak)
          .map((i) => i.value)
          .reduce((a, b) => a > b ? a : b);
      expect(
        worstReal,
        greaterThanOrEqualTo(worstLeak),
        reason: 'a wrong tap has to cost at least as much as a right one is '
            'worth, or spraying taps is still optimal',
      );
    });

    test('stopping your own savings transfer is the costliest tap', () {
      final savings = kLeakItems.firstWhere(
        (i) => i.id == 'savings_transfer',
      );
      expect(savings.isLeak, isFalse);
      for (final other in kLeakItems.where((i) => !i.isLeak)) {
        expect(savings.value, greaterThanOrEqualTo(other.value));
      }
    });
  });

  group('scoring', () {
    LeakResult result({
      int caught = 0,
      int missed = 0,
      int wrong = 0,
      int saved = 0,
      int lost = 0,
    }) => LeakResult(
      caught: caught,
      missed: missed,
      wronglyTapped: wrong,
      coinsSaved: saved,
      coinsLost: lost,
    );

    test('a careless player earns nothing rather than owing', () {
      // Never negative: a player who ends up worse off for having played
      // stops playing, and this is already the least fun habit in the app.
      final reckless = result(caught: 1, wrong: 8, saved: 8, lost: 90);
      expect(leakPayout(reckless), 0);
    });

    test('accuracy ignores misses, so doing nothing is not perfect play', () {
      final idle = result(missed: 12);
      expect(idle.accuracy, 0);
      expect(leakPayout(idle), 0);
    });

    test('careful play beats fast play', () {
      final careful = result(caught: 6, missed: 4, saved: 54);
      final spammer = result(caught: 8, wrong: 5, saved: 70, lost: 52);
      expect(leakPayout(careful), greaterThan(leakPayout(spammer)));
    });

    test('a clean round earns the accuracy bonus', () {
      final clean = result(caught: 6, missed: 2, saved: 50);
      final messy = result(caught: 6, wrong: 3, saved: 50, lost: 20);
      expect(leakPayout(clean), greaterThan(leakPayout(messy)));
      expect(clean.accuracy, 1.0);
    });
  });

  group('what the player is told', () {
    test('cancelling more real charges than leaks is named first', () {
      const r = LeakResult(
        caught: 2,
        missed: 1,
        wronglyTapped: 5,
        coinsSaved: 14,
        coinsLost: 48,
      );
      expect(r.headline, contains('Vigilance is not the same as suspicion'));
    });

    test('a perfect round says what the skill was', () {
      const r = LeakResult(
        caught: 5,
        missed: 1,
        wronglyTapped: 0,
        coinsSaved: 45,
        coinsLost: 0,
      );
      expect(r.headline, contains('cancelled nothing you needed'));
    });

    test('doing nothing is not scolded', () {
      const r = LeakResult(
        caught: 0,
        missed: 9,
        wronglyTapped: 0,
        coinsSaved: 0,
        coinsLost: 0,
      );
      expect(r.headline, contains('Reading is fine'));
    });

    test('every item explains itself', () {
      for (final item in kLeakItems) {
        expect(item.label.trim(), isNotEmpty);
        expect(
          item.why.trim().length,
          greaterThan(30),
          reason: '${item.id} says nothing — a game that only tells you '
              '"wrong" teaches reflexes, not judgement',
        );
        expect(item.value, greaterThan(0));
      }
    });

    test('ids are unique', () {
      expect(
        kLeakItems.map((i) => i.id).toSet().length,
        kLeakItems.length,
      );
    });
  });

  group('it scales with the player, unlike the other minigames', () {
    test('younger players get more time to read', () {
      final young = LeakRound.forBand(AgeBand.under9);
      final adult = LeakRound.forBand(AgeBand.adult18plus);

      expect(
        young.visibleMillis,
        greaterThan(adult.visibleMillis),
        reason: 'a game that outruns a six-year-old\'s reading is testing '
            'reflexes, not judgement',
      );
      expect(young.popMillis, greaterThan(adult.popMillis));
      expect(young.holes, lessThanOrEqualTo(adult.holes));
    });

    test('difficulty rises monotonically with age', () {
      const ordered = [
        AgeBand.under9,
        AgeBand.age9to12,
        AgeBand.teen13to15,
        AgeBand.teen16to17,
        AgeBand.adult18plus,
      ];
      for (var i = 1; i < ordered.length; i++) {
        final easier = LeakRound.forBand(ordered[i - 1]);
        final harder = LeakRound.forBand(ordered[i]);
        expect(harder.visibleMillis, lessThanOrEqualTo(easier.visibleMillis));
        expect(harder.popMillis, lessThanOrEqualTo(easier.popMillis));
      }
    });

    test('undisclosed sits in the middle', () {
      final mid = LeakRound.forBand(AgeBand.undisclosed);
      final young = LeakRound.forBand(AgeBand.under9);
      final adult = LeakRound.forBand(AgeBand.adult18plus);
      expect(mid.visibleMillis, lessThan(young.visibleMillis));
      expect(mid.visibleMillis, greaterThan(adult.visibleMillis));
    });

    test('the youngest never meet vocabulary they have not been taught', () {
      final young = leakItemsFor(AgeBand.under9).map((i) => i.id).toSet();
      expect(young, isNot(contains('overdraft_fee')));
      expect(young, isNot(contains('guaranteed_return')));
      expect(young, isNot(contains('insurance')));
    });

    test('but the youngest still get a real board', () {
      final young = leakItemsFor(AgeBand.under9);
      expect(young.length, greaterThanOrEqualTo(8));
      expect(young.where((i) => i.isLeak), isNotEmpty);
      expect(young.where((i) => !i.isLeak), isNotEmpty);
    });

    test('adults get everything', () {
      expect(leakItemsFor(AgeBand.adult18plus).length, kLeakItems.length);
    });
  });
}
