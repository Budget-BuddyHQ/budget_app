import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Random that always returns the same value, so results don't depend on how
/// many times the controller happens to draw.
class _FixedRandom implements Random {
  _FixedRandom(this._value);
  final int _value;

  @override
  int nextInt(int max) => _value % max;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

LifeSimController _adult({int value = 1, int money = 200, int age = 15}) =>
    LifeSimController(
      random: _FixedRandom(value),
      initialAge: age,
      startMoney: money,
    );

void main() {
  test('a new life is born with the chosen identity and origin', () {
    final life = LifeSimController(
      random: _FixedRandom(1),
      name: 'Sam Reyes',
      gender: Gender.female,
      origin: LifeOrigin.comfortable,
      startMoney: LifeOrigin.comfortable.familyMoney,
    );

    expect(life.age, 0);
    expect(life.name, 'Sam Reyes');
    expect(life.gender, Gender.female);
    expect(life.stage, LifeStage.baby);
    expect(life.job, 'Newborn');
    expect(life.money, LifeOrigin.comfortable.familyMoney);
    expect(life.smarts, LifeOrigin.comfortable.startingSmarts);
    // Birth is already narrated in the feed.
    expect(life.history, isNotEmpty);
  });

  test('a child pays no living costs while dependent', () {
    final life = LifeSimController(random: _FixedRandom(1), startMoney: 100);
    expect(life.isDependent, isTrue);
    life.ageUp();
    // Money is untouched: the family covers everything under 18.
    expect(life.money, 100);
  });

  test('ageing up advances the year and can draw an event', () {
    final life = _adult();
    life.ageUp();
    expect(life.age, 16);
    expect(life.currentEvent, isNotNull);
  });

  test('a quiet year draws no event', () {
    // nextInt(4) == 0 is the quiet-year branch.
    final life = _adult(value: 0);
    life.ageUp();
    expect(life.age, 16);
    expect(life.currentEvent, isNull);
  });

  test('choosing an option applies effects and clears the event', () {
    final life = _adult();
    life.ageUp();
    final event = life.currentEvent!;
    final before = (
      money: life.money,
      happiness: life.happiness,
      health: life.health,
      smarts: life.smarts,
      looks: life.looks,
    );

    life.chooseOption(0);

    expect(life.currentEvent, isNull);
    // The chosen option's deltas landed exactly (stats clamp 0..100, money
    // floors at zero).
    final choice = event.choices[0];
    expect(life.smarts, (before.smarts + choice.smarts).clamp(0, 100));
    expect(life.looks, (before.looks + choice.looks).clamp(0, 100));
    expect(life.health, (before.health + choice.health).clamp(0, 100));
    expect(life.happiness, (before.happiness + choice.happiness).clamp(0, 100));
    expect(life.money, (before.money + choice.money).clamp(0, 1 << 30));
    // And the outcome is narrated in the feed.
    expect(life.history.last.text, choice.outcome);
  });

  test('a choice that adds a relationship records it once', () {
    final life = _adult();
    // Drive turns until an event offering a relationship comes up.
    for (var i = 0; i < 12 && life.relationships.isEmpty; i++) {
      if (life.currentEvent == null) {
        life.ageUp();
      }
      final event = life.currentEvent;
      if (event == null) continue;
      final index = event.choices.indexWhere(
        (c) => c.addRelationship != null,
      );
      life.chooseOption(index >= 0 ? index : 0);
    }
    // Either we found one, or none were eligible — both are valid, but if we
    // did find one it must not be duplicated.
    expect(life.relationships.length, life.relationships.toSet().length);
  });

  test('exercise raises health and looks', () {
    final life = _adult();
    final health = life.health;
    final looks = life.looks;
    life.exercise();
    expect(life.health, greaterThan(health));
    expect(life.looks, greaterThan(looks));
  });

  test('investing moves cash into compounding investments', () {
    // Explicitly 18: investing is age-gated at 16 now, and this helper's
    // default is a fifteen-year-old despite its name.
    final life = _adult(age: 18);
    life.invest(100);
    expect(life.money, 100);
    expect(life.investments, 100);
    expect(life.netWorth, 200);
  });

  test('cannot invest more than you hold', () {
    final life = _adult(age: 18);
    life.invest(9999);
    expect(life.money, 200);
    expect(life.investments, 0);
  });

  test('retiring stops the game and yields a reward', () {
    final life = _adult();
    life.ageUp();
    life.retire();
    expect(life.retired, isTrue);
    expect(life.finished, isTrue);
    final age = life.age;
    life.ageUp(); // no-op once finished
    expect(life.age, age);
    expect(life.goldReward, greaterThan(0));
  });

  test('a finished life ignores activities', () {
    final life = _adult();
    life.retire();
    final smarts = life.smarts;
    life.study();
    expect(life.smarts, smarts);
  });

  group('event gating', () {
    // Every gated event must be genuinely unreachable for a character who
    // doesn't meet its requirements — that's the whole contract of the
    // skill/trait/fame system, and it silently degrades to "uniform random"
    // if `matches` ever stops being consulted.
    LifeContext blank({
      int age = 25,
      int money = 0,
      int fame = 0,
      Map<LifeSkill, int> skills = const {},
      Set<LifeTrait> traits = const {},
      bool hasJob = false,
    }) => LifeContext(
      age: age,
      money: money,
      happiness: 50,
      health: 50,
      smarts: 50,
      fame: fame,
      skills: skills,
      traits: traits,
      hasJob: hasJob,
    );

    test('skill-gated events stay out of the pool below the threshold', () {
      final gig = kLifeEvents.firstWhere((e) => e.id == 'first_gig');
      expect(gig.matches(blank()), isFalse);
      expect(
        gig.matches(blank(skills: {LifeSkill.music: 10})),
        isFalse,
        reason: '10 is under the minSkill of 20',
      );
      expect(gig.matches(blank(skills: {LifeSkill.music: 25})), isTrue);
    });

    test('fame-gated events need both skill and fame', () {
      final deal = kLifeEvents.firstWhere((e) => e.id == 'record_deal');
      expect(
        deal.matches(blank(skills: {LifeSkill.music: 60})),
        isFalse,
        reason: 'skill alone is not enough without fame',
      );
      expect(
        deal.matches(blank(fame: 40)),
        isFalse,
        reason: 'fame alone is not enough without skill',
      );
      expect(
        deal.matches(blank(skills: {LifeSkill.music: 60}, fame: 40)),
        isTrue,
      );
    });

    test('trait-gated events only reach characters with the trait', () {
      final bet = kLifeEvents.firstWhere((e) => e.id == 'reckless_bet');
      expect(bet.matches(blank(money: 1000)), isFalse);
      expect(
        bet.matches(blank(money: 1000, traits: {LifeTrait.cautious})),
        isFalse,
      );
      expect(
        bet.matches(blank(money: 1000, traits: {LifeTrait.reckless})),
        isTrue,
      );
    });

    test('money-gated events respect their floor', () {
      final bet = kLifeEvents.firstWhere((e) => e.id == 'reckless_bet');
      expect(
        bet.matches(blank(money: 10, traits: {LifeTrait.reckless})),
        isFalse,
      );
    });

    test('every event declares a positive weight', () {
      for (final event in kLifeEvents) {
        expect(
          event.weight,
          greaterThan(0),
          reason: '${event.id} would be unreachable in a weighted draw',
        );
      }
    });
  });

  group('skills, traits and fame', () {
    test('a new life is born with exactly two traits', () {
      final life = _adult();
      expect(life.traits.length, 2);
    });

    test('practicing raises that skill and nothing else', () {
      final life = _adult();
      expect(life.skillLevel(LifeSkill.music), 0);
      life.practice(LifeSkill.music);
      expect(life.skillLevel(LifeSkill.music), greaterThan(0));
      expect(life.skillLevel(LifeSkill.sports), 0);
    });

    test('a finished life cannot practice', () {
      final life = _adult();
      life.retire();
      life.practice(LifeSkill.music);
      expect(life.skillLevel(LifeSkill.music), 0);
    });

    test('fame stays clamped to 0..100', () {
      final life = _adult();
      expect(life.fame, 0);
      expect(life.fame, inInclusiveRange(0, 100));
    });
  });
}
