import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plays a life the way a person would — varied choices, occasional practice —
/// and reports which events fired.
({List<String> fired, int years}) _play(int seed, {LifeSkill? focus}) {
  final rng = Random(seed * 7919 + 13);
  final life = LifeSimController(
    random: Random(seed),
    startMoney: LifeOrigin.comfortable.familyMoney,
  );
  final fired = <String>[];

  while (!life.finished && life.age < 85) {
    life.ageUp();
    final event = life.currentEvent;
    if (event != null) {
      fired.add(event.id);
      life.chooseOption(focus == null ? rng.nextInt(event.choices.length) : 0);
    }
    if (life.age > 6) {
      if (focus != null) {
        if (rng.nextBool()) life.practise(focus);
      } else if (rng.nextInt(3) == 0) {
        life.practise(LifeSkill.values[rng.nextInt(LifeSkill.values.length)]);
      }
    }
  }
  return (fired: fired, years: life.age);
}

int _repeatsIn(List<String> fired) {
  final counts = <String, int>{};
  for (final id in fired) {
    counts.update(id, (v) => v + 1, ifAbsent: () => 1);
  }
  return counts.values
      .where((c) => c > 1)
      .fold<int>(0, (sum, c) => sum + (c - 1));
}

void main() {
  // These thresholds come from actually simulating the game rather than
  // guessing. Before the fixes they measured: 24.4 average repeats per life,
  // 41 in the worst run, and a pool that sat flat at ~19 eligible events from
  // age 32 to 85 — which is what "it gets repetitive after a while" was.
  group('event variety across a full life', () {
    late List<List<String>> runs;

    setUpAll(() {
      runs = [for (var seed = 0; seed < 200; seed++) _play(seed).fired];
    });

    test('an average life repeats few events', () {
      final total = runs.map(_repeatsIn).reduce((a, b) => a + b);
      final average = total / runs.length;
      expect(
        average,
        lessThan(14),
        reason:
            'averaging ${average.toStringAsFixed(1)} repeated events per life '
            '— more than half of what a player sees would be a rerun',
      );
    });

    test('no single event dominates one life', () {
      for (final fired in runs) {
        final counts = <String, int>{};
        for (final id in fired) {
          counts.update(id, (v) => v + 1, ifAbsent: () => 1);
        }
        for (final entry in counts.entries) {
          expect(
            entry.value,
            lessThanOrEqualTo(7),
            reason:
                '${entry.key} fired ${entry.value} times in a single life',
          );
        }
      }
    });

    test('a non-repeatable event never fires twice in one life', () {
      final once = {
        for (final e in kLifeEvents)
          if (!e.repeatable) e.id,
      };
      for (final fired in runs) {
        final seen = <String>{};
        for (final id in fired) {
          if (!once.contains(id)) continue;
          expect(
            seen.add(id),
            isTrue,
            reason: '$id is not repeatable but fired twice in one life',
          );
        }
      }
    });
  });

  group('pool depth by age', () {
    LifeContext plain(int age) => LifeContext(
      age: age,
      money: 800,
      happiness: 50,
      health: 60,
      smarts: 50,
      fame: 0,
      skills: const {},
      traits: const {},
      hasJob: age >= 22,
    );

    test('the adult and senior years are not starved', () {
      // The stretch from 30 onward is over half a playthrough. It used to draw
      // from the same ~19 events for fifty years.
      for (final age in [32, 40, 50, 60, 70, 80]) {
        final count = kLifeEvents.where((e) => e.matches(plain(age))).length;
        expect(
          count,
          greaterThanOrEqualTo(25),
          reason: 'only $count events are eligible at age $age',
        );
      }
    });

    test('the childhood years are not starved either', () {
      // Ages 10-11 had *zero* eligible events at one point — a life would
      // silently skip straight through them with nothing to decide. Lower
      // bar than the adult years because childhood is a handful of turns,
      // not fifty, but it must never be empty.
      for (final age in [5, 8, 10, 11, 13]) {
        final count = kLifeEvents.where((e) => e.matches(plain(age))).length;
        expect(
          count,
          greaterThanOrEqualTo(3),
          reason: 'only $count events are eligible at age $age',
        );
      }
    });
  });

  group('career ladders are actually completable', () {
    test('a dedicated musician can reach the top of the music track', () {
      // Regression guard for a real content bug: first_gig granted 4 fame and
      // record_deal required 10, with no other source of music fame — so the
      // top three events on this ladder could never fire for anybody. 400
      // simulated lives never saw one of them.
      //
      // Widened 120 -> 300 when the chain pack (kLifeEventsChains) landed,
      // for the same reason the sweep below was widened 200 -> 400: this is
      // a *sampling* guard, so its sensitivity falls with every batch of
      // new content competing for the same draws. The tell that it is the
      // sample and not the content is that the exhaustive sweep below —
      // which is strictly harder to pass — still went green.
      final seen = <String>{};
      for (var seed = 0; seed < 300; seed++) {
        seen.addAll(_play(seed + 900, focus: LifeSkill.music).fired);
      }
      for (final id in ['first_gig', 'record_deal', 'sold_out_tour']) {
        expect(
          seen,
          contains(id),
          reason: '$id is unreachable even for a player who commits to music',
        );
      }
    });

    test('every event in the pool can fire for somebody', () {
      // 400 rather than 200 seeds. This is a sampling guard, and its
      // sensitivity scales with pool size: the rarest events here sit at
      // weight 0.4 behind a skill *and* a fame gate, so every batch of new
      // content shrinks their share of the draw and eventually one stops
      // showing up by luck alone. That happened when the money-lesson pack
      // (kLifeEventsMoney) landed — `sold_out_tour` vanished from this
      // sweep while the dedicated-musician test above still reached it
      // every time, which is the tell that the event was fine and the
      // sample was too small. Widen the sample rather than lower the bar;
      // the guarantee worth keeping is "nothing is unreachable".
      final seen = <String>{};
      for (var seed = 0; seed < 400; seed++) {
        seen.addAll(_play(seed).fired);
        for (final skill in LifeSkill.values) {
          seen.addAll(_play(seed + 4000, focus: skill).fired);
        }
      }
      final unreachable = kLifeEvents
          .map((e) => e.id)
          .where((id) => !seen.contains(id))
          .toList();
      expect(
        unreachable,
        isEmpty,
        reason:
            'these events exist but no simulated player ever saw them: '
            '$unreachable',
      );
    });
  });
}
