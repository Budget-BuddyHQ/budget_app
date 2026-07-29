import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Random with a scripted sequence so events/finances are deterministic.
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
  test('a new life starts as a teen student with starting money', () {
    final life = LifeSimController(random: _ScriptedRandom([0]));
    expect(life.age, 15);
    expect(life.job, 'Student');
    expect(life.money, 200);
    expect(life.netWorth, 200);
    expect(life.currentEvent, isNull);
  });

  test('ageing up advances the year and draws an event', () {
    // nextInt(4)!=0 → an event is drawn (not a quiet year).
    final life = LifeSimController(random: _ScriptedRandom([1, 0]));
    life.ageUp();
    expect(life.age, 16);
    expect(life.currentEvent, isNotNull);
  });

  test('a quiet year (roll 0) draws no event', () {
    final life = LifeSimController(random: _ScriptedRandom([0]));
    life.ageUp();
    expect(life.age, 16);
    expect(life.currentEvent, isNull);
  });

  test('choosing an option applies its effects and clears the event', () {
    final life = LifeSimController(random: _ScriptedRandom([1, 0]));
    life.ageUp();
    final smartsBefore = life.smarts;
    final event = life.currentEvent!;
    // Pick the first choice and confirm the event resolves.
    life.chooseOption(0);
    expect(life.currentEvent, isNull);
    // Every first choice in the pool changes at least one stat/money.
    final changed =
        life.smarts != smartsBefore ||
        life.money != 200 ||
        event.choices[0].happiness != 0;
    expect(changed, isTrue);
  });

  test('investing moves cash into compounding investments', () {
    final life = LifeSimController(random: _ScriptedRandom([0]));
    life.invest(100);
    expect(life.money, 100);
    expect(life.investments, 100);
    // Net worth is preserved by the move itself.
    expect(life.netWorth, 200);
  });

  test('cannot invest more than you hold', () {
    final life = LifeSimController(random: _ScriptedRandom([0]));
    life.invest(9999);
    expect(life.money, 200);
    expect(life.investments, 0);
  });

  test('retiring stops the game and yields a reward', () {
    final life = LifeSimController(random: _ScriptedRandom([0]));
    life.ageUp();
    life.retire();
    expect(life.retired, isTrue);
    final age = life.age;
    life.ageUp(); // no-op after retiring
    expect(life.age, age);
    expect(life.goldReward, greaterThan(0));
  });
}
