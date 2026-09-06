import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/coin_cascade_models.dart';

/// What Coin Cascade teaches, and what it pays.
///
/// **Two separate complaints, one root cause.** The report was *"I want to
/// know how the coin cascade game is going to teach them about financial
/// literacy… sure it's satisfying but I don't even know what to work for in
/// that game."*
///
/// The first half was a design gap: the mechanics have always been 50/30/20
/// — needs clear bills, wants raise them, savings win — and the game never
/// once said so, so whether anybody learned it depended on them noticing a
/// pattern unprompted. [CascadeReport] is the fix, and this file checks it
/// reads a run correctly rather than confidently.
///
/// The second half was a bug, and a bad one. The result card printed
/// `+N gold` from `CoinCascadeGame.goldEarned`, the arcade toast printed it
/// again — and the only call either of them made was `recordArcadeRun`, which
/// records a score and is documented as *not* touching gold or XP. Nothing
/// anywhere called `applyChallengePayload`. Every Coin Cascade run ever
/// played announced a payout twice and paid nothing. "I don't know what to
/// work for" was a literally accurate description of the game.
void main() {
  group('the report reads a run as a budget', () {
    test('coins are income, not one of the three shares', () {
      // A coin buys extra moves — it is money you have not decided about
      // yet. Folding it into the split would make a lucky coin run look like
      // a budgeting choice, and would put the percentages permanently below
      // where the player actually set them.
      const report = CascadeReport(
        needs: 10,
        wants: 6,
        saves: 4,
        coins: 80,
        billsPaid: 10,
        billsTaken: 2,
      );
      expect(report.allocated, 20);
      expect(report.needsPercent, 50);
      expect(report.wantsPercent, 30);
      expect(report.savesPercent, 20);
    });

    test('a 50/30/20 run is told that it was one', () {
      const report = CascadeReport(
        needs: 50,
        wants: 30,
        saves: 20,
        coins: 0,
        billsPaid: 40,
        billsTaken: 10,
      );
      expect(report.headline, contains('50/30/20'));
    });

    test('the shares always add up to about a hundred', () {
      // Three independent roundings can drift. A split that visibly does not
      // add up is the fastest way to make a player stop believing the rest of
      // the card.
      final random = Random(3);
      for (var i = 0; i < 500; i++) {
        final report = CascadeReport(
          needs: random.nextInt(60),
          wants: random.nextInt(60),
          saves: random.nextInt(60),
          coins: random.nextInt(30),
          billsPaid: random.nextInt(20),
          billsTaken: random.nextInt(20),
        );
        if (report.allocated == 0) continue;
        final total =
            report.needsPercent + report.wantsPercent + report.savesPercent;
        expect(
          total,
          inInclusiveRange(98, 102),
          reason: 'shares sum to $total%',
        );
      }
    });

    test('an empty run says so instead of dividing by zero', () {
      const report = CascadeReport(
        needs: 0,
        wants: 0,
        saves: 0,
        coins: 0,
        billsPaid: 0,
        billsTaken: 0,
      );
      expect(report.needsPercent, 0);
      expect(report.headline, isNotEmpty);
      expect(report.detail, isNotEmpty);
    });

    test('it never grades the player', () {
      // The rule the whole app follows: never say a number is good or bad,
      // show what it did. A run that saved nothing is the one most likely to
      // attract a scolding sentence, so it is the one worth pinning.
      const bad = CascadeReport(
        needs: 20,
        wants: 78,
        saves: 2,
        coins: 0,
        billsPaid: 5,
        billsTaken: 26,
      );
      final text = '${bad.headline} ${bad.detail.join(' ')}'.toLowerCase();
      for (final word in const <String>[
        'bad',
        'wrong',
        'poor',
        'should have',
        'you failed',
        'mistake',
      ]) {
        expect(
          text,
          isNot(contains(word)),
          reason: 'the report has started telling children off: "$word"',
        );
      }
    });

    test('a real run produces a readable split', () {
      // Played by a bot that takes the first legal swap it finds, which is
      // the least deliberate player possible — so if the numbers come out
      // sane here they come out sane for anybody.
      final game = CoinCascadeGame(random: Random(11), level: kCascadeLevels[2]);
      var guard = 0;
      while (game.status == CascadeStatus.playing && guard++ < 300) {
        var moved = false;
        for (var row = 0; row < game.rows && !moved; row++) {
          for (var col = 0; col < game.columns - 1 && !moved; col++) {
            if (game.trySwap(col, row, col + 1, row)) {
              game.resolveAll();
              moved = true;
            }
          }
        }
        if (!moved) break;
      }

      final report = game.report;
      expect(report.allocated, greaterThan(0));
      expect(report.needs + report.wants + report.saves, report.allocated);
      expect(report.billsPaid, greaterThanOrEqualTo(0));
    });

    test('the tallies survive a reset', () {
      final game = CoinCascadeGame(random: Random(5));
      game.resolveAll();
      game.reset();
      expect(game.report.allocated, 0);
      expect(game.report.billsPaid, 0);
      expect(game.report.billsTaken, 0);
    });
  });

  group('Payday Rush', () {
    test('is never won and never runs out of moves', () {
      // A Rush is scored, not passed. If the win check fired, the mode would
      // end the moment somebody hit the ladder's savings goal, which is not
      // what the clock is for.
      final game = CoinCascadeGame(random: Random(2), level: kCascadeRush);
      game.savings = kCascadeLevels.first.savingsGoal * 10;
      expect(game.status, CascadeStatus.playing);

      game.movesLeft = 0;
      expect(
        game.status,
        CascadeStatus.playing,
        reason: 'the Rush ended on moves, which it does not have',
      );
    });

    test('bills still end it', () {
      // The one way to lose a timed run, and the lesson the clock exists to
      // teach: the month arrives whether or not you were ready.
      final game = CoinCascadeGame(random: Random(2), level: kCascadeRush);
      game.bills = game.billCapacity;
      expect(game.status, CascadeStatus.lost);
    });

    test('swapping does not spend a move', () {
      // The level declares 1<<30 moves. Decrementing per swap would tick a
      // counter nothing reads, and the HUD would show a nonsense number.
      final game = CoinCascadeGame(random: Random(4), level: kCascadeRush);
      final before = game.movesLeft;
      var swapped = false;
      for (var row = 0; row < game.rows && !swapped; row++) {
        for (var col = 0; col < game.columns - 1 && !swapped; col++) {
          swapped = game.trySwap(col, row, col + 1, row);
        }
      }
      expect(swapped, isTrue, reason: 'the board had no legal move at all');
      expect(game.movesLeft, before);
    });

    test('the clock can deliver a bill, and only in Rush', () {
      final rush = CoinCascadeGame(random: Random(6), level: kCascadeRush);
      rush.resolveAll();
      final before = rush.bills;
      rush.dropScheduledBill();
      expect(rush.bills, greaterThanOrEqualTo(before));

      // On a ladder level the clock has no business adding anything: bills
      // there arrive on the move schedule, and a second source would change
      // the difficulty of thirteen tuned levels invisibly.
      final ladder = CoinCascadeGame(random: Random(6));
      ladder.resolveAll();
      final ladderBefore = ladder.bills;
      ladder.dropScheduledBill();
      expect(ladder.bills, ladderBefore);
    });

    test('a finished Rush cannot be pushed over by a late timer tick', () {
      // The bill timer and the run ending are separate clocks, so a tick can
      // land during the closing animation. It must not turn a survived run
      // into a lost one after the fact.
      final game = CoinCascadeGame(random: Random(8), level: kCascadeRush);
      game.bills = game.billCapacity;
      final before = game.bills;
      game.dropScheduledBill();
      expect(game.bills, before);
    });
  });

  group('the payout actually reaches the account', () {
    test('the page pays the run rather than only recording a score', () {
      // `recordArcadeRun` is a scoreboard write and is documented as not
      // touching gold or XP. For the whole life of this game it was the only
      // call either the page or the arcade hub made, while both printed a
      // gold figure. This is the assertion that the money is real.
      final page = File(
        'lib/screens_minigames_admin_etc/Gameplay/minigames_pages/'
        'coin_cascade_page.dart',
      ).readAsStringSync();

      expect(
        page,
        contains('applyChallengePayload'),
        reason:
            'nothing in Coin Cascade credits the player, so the gold on the '
            'result card is a number the game made up',
      );
      expect(
        page,
        contains("'cascade_cleared': _clearedThrough"),
        reason: 'ladder progress is session-scoped again',
      );

      // Comments stripped: the note in `_openCoinCascade` explaining this
      // bug necessarily quotes the expression it is warning about.
      final hub = File(
            'lib/screens_minigames_admin_etc/Gameplay/core_bottom_pages/'
            'minigames_page.dart',
          )
          .readAsStringSync()
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      expect(
        hub,
        isNot(contains('game.goldEarned')),
        reason:
            'the arcade toast is quoting the engine’s uncredited figure '
            'again instead of what was paid',
      );
    });
  });
}
