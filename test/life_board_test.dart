import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_board_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_board_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Random with a scripted sequence so the dice are deterministic.
class _ScriptedRandom implements Random {
  _ScriptedRandom(this._values);
  final List<int> _values;
  int _i = 0;

  @override
  int nextInt(int max) {
    final value = _values[_i % _values.length];
    _i++;
    return value % max;
  }

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

void main() {
  test('a fresh board starts with cash and no assets', () {
    final game = LifeBoardController(random: _ScriptedRandom([0]));
    expect(game.cash, 500);
    expect(game.position, 0);
    expect(game.netWorth, 500);
    expect(game.ownedAssets, isEmpty);
    expect(game.turns, 0);
  });

  test('landing on an opportunity offers an affordable asset you can buy', () {
    // nextInt(6) -> 3 gives a roll of 4, landing on index 4 (Market Stall).
    final game = LifeBoardController(random: _ScriptedRandom([3]));
    game.roll();

    expect(game.position, 4);
    expect(game.turns, 1);
    expect(game.currentTile.type, LifeTileType.opportunity);
    expect(game.pendingOffer, isNotNull);

    final offer = game.pendingOffer!;
    final cashBefore = game.cash;
    expect(game.acceptOffer(), isTrue);
    expect(game.cash, cashBefore - offer.cost);
    expect(game.ownedAssets.map((a) => a.id), contains(offer.id));
    expect(game.passiveIncome, offer.incomePerLap);
    expect(game.pendingOffer, isNull);
  });

  test('declining an offer leaves you unchanged', () {
    final game = LifeBoardController(random: _ScriptedRandom([3]));
    game.roll();
    expect(game.pendingOffer, isNotNull);

    game.declineOffer();
    expect(game.pendingOffer, isNull);
    expect(game.ownedAssets, isEmpty);
    expect(game.cash, 500);
  });

  test('passing Start completes a lap and pays salary', () {
    // A path around the board that avoids chance/opportunity tiles (so the
    // scripted dice aren't consumed by their random effects), ending on a wrap
    // back to Start: 0→3→5→7→8→9→11→13→14→15→0.
    final steps = [3, 2, 2, 1, 1, 2, 2, 1, 1, 1];
    final game = LifeBoardController(
      random: _ScriptedRandom(steps.map((s) => s - 1).toList()),
    );

    final cashBefore = game.cash;
    for (var i = 0; i < steps.length; i++) {
      game.roll();
    }

    expect(game.position, 0);
    expect(game.laps, 1);
    expect(game.turns, steps.length);
    // The lap payout (200 base) means cash moved even after bills.
    expect(game.cash, isNot(cashBefore));
    expect(game.goldReward, greaterThan(0));
  });
}
