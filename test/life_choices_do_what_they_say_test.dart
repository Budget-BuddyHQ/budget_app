import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixed_random.dart';

/// A choice does what its outcome says.
///
/// **Reported as:** *"some of the options that you click yes to just never
/// appear or give you benefits."* Each of these was a card whose text and data
/// disagreed, so the player read about a raise, a job or $50 and got nothing:
///
/// * A salary with no job title was never read. Ten choices across seven
///   cards — promotions, negotiated offers, royalties for life, the job after a
///   layoff — moved nothing at all.
/// * A job or raise at a fixed salary is ignored for anybody already paid
///   more, by design ("never quietly demote"). The card still said "more work,
///   more pay" to somebody earning four times the offer.
/// * A layoff card left the job in place at full pay on every branch.
/// * Birthday money never arrived, so spending it took $50 from the player.
void main() {
  LifeSimController working(int age, int salary) {
    final life = LifeSimController(
      random: FixedRandom.unlucky(),
      name: 'Tester',
      initialAge: age,
      startMoney: 5000,
      startJob: 'Baker',
      startSalary: salary,
    );
    life.debugSetStats(smarts: 70, health: 80, happiness: 60);
    return life;
  }

  int playable(LifeEvent e) => e.minAge.clamp(16, 120);

  group('a pay change always lands', () {
    test('an offer is only shown to somebody it would actually pay more', () {
      // Not a gate on everything: a card can also mean it, and say so with
      // `replacesJob`. What it cannot do is offer a figure that is silently
      // dropped.
      final silent = <String>[];
      for (final e in kLifeEvents) {
        for (final c in e.choices) {
          final pay = c.setSalary;
          if (pay == null || pay == 0 || c.replacesJob) continue;
          final gate = e.maxSalary;
          if (gate == null || gate > pay) {
            silent.add('${e.id}: "${c.label}" offers $pay, gate $gate');
          }
        }
      }
      expect(silent, isEmpty, reason: silent.join('\n'));
    });

    test('every pay-changing choice changes the pay when played', () {
      for (final e in kLifeEvents) {
        for (var i = 0; i < e.choices.length; i++) {
          final c = e.choices[i];
          final pay = c.setSalary;
          if (pay == null) continue;
          // The hardest case for each kind: a deliberate switch must land on
          // somebody paid far more, an offer on somebody just under its gate.
          final start = c.replacesJob || pay == 0
              ? 3000
              : (e.maxSalary ?? pay) - 1;
          final life = working(playable(e), start);
          life.debugSetEvent(e);
          life.chooseOption(i);
          expect(
            life.salary,
            pay,
            reason: '${e.id}: "${c.label}" said ${c.outcome}',
          );
          if (c.setJob != null) {
            expect(life.job, c.setJob, reason: '${e.id}: "${c.label}"');
          }
        }
      }
    });

    test('no card hands out a degree without the schooling', () {
      // "Work first, study part time" set the Degree chip while the job
      // board still said a degree was needed. The chip is read from the
      // education record now, so a card that sets it would be overwritten —
      // and one that tries is promising something it cannot give.
      for (final e in kLifeEvents) {
        for (final c in e.choices) {
          expect(
            c.setsFlag,
            isNot(LifeFlag.gotDegree),
            reason: '${e.id}: "${c.label}"',
          );
        }
      }
      final life = working(25, 900);
      final study = kLifeEvents.firstWhere((e) => e.id == 'chain_study_loan');
      life.debugSetEvent(study);
      life.chooseOption(
        study.choices.indexWhere((c) => c.label.startsWith('Work first')),
      );
      expect(life.flags, isNot(contains(LifeFlag.gotDegree)));
    });

    test('a layoff ends the job on every branch', () {
      for (final id in <String>['a_redundancy', 's_boss_lets_you_go']) {
        final e = kLifeEvents.firstWhere((e) => e.id == id);
        for (var i = 0; i < e.choices.length; i++) {
          final life = working(30, 1500);
          life.debugSetEvent(e);
          life.chooseOption(i);
          expect(
            life.salary,
            isNot(1500),
            reason: '$id: "${e.choices[i].label}" kept the old job',
          );
        }
      }
    });

    test('taking a job by choice is not counted as being laid off', () {
      // `replacesJob` and `laidOff` are separate on purpose: starting a
      // business is not something that happened to you.
      final e = kLifeEvents.firstWhere((e) => e.id == 'start_business');
      final c = e.choices.firstWhere((c) => c.setJob == 'Founder');
      expect(c.replacesJob, isTrue);
      expect(c.laidOff, isFalse);
    });
  });

  group('the money a card describes is the money that moves', () {
    LifeSimController child() {
      final life = LifeSimController(
        random: FixedRandom.unlucky(),
        name: 'Kid',
        initialAge: 10,
        startMoney: 100,
      );
      return life;
    }

    int play(String id, String label) {
      final e = kLifeEvents.firstWhere((e) => e.id == id);
      final i = e.choices.indexWhere((c) => c.label.startsWith(label));
      expect(i, isNot(-1), reason: 'no "$label" on $id');
      final life = child();
      final before = life.money;
      life.debugSetEvent(e);
      life.chooseOption(i);
      return life.money - before;
    }

    test('birthday money arrives, and saving it keeps it', () {
      expect(play('c_birthday_money', 'Save it all'), 50);
      expect(play('c_birthday_money', 'Put half away'), 25);
      expect(
        play('c_birthday_money', 'Spend the lot'),
        0,
        reason: 'spending a gift should not cost the player their own money',
      );
    });

    test('pocket money kept back is pocket money you have', () {
      expect(play('c_first_pocket_money', 'Keep'), 12);
    });

    test('hiding the broken window does not make it cheaper', () {
      final hid = play('c_broke_a_window', 'Say nothing');
      final owned = play('c_broke_a_window', 'Own up');
      expect(hid, lessThanOrEqualTo(owned));
    });
  });

  group('the same moment does not come round twice', () {
    test('one card per topic per life, and a repeat only after a gap', () {
      // Simulated lives, choosing at random, read back for any topic that
      // fired twice too close together or twice when it should not repeat.
      final repeatable = {for (final e in kLifeEvents) e.id: e.repeatable};
      final topicOf = {
        for (final e in kLifeEvents)
          if (e.topic != null) e.id: e.topic!,
      };
      final problems = <String>[];
      for (var seed = 0; seed < 250; seed++) {
        final pick = Random(seed + 31);
        final life = LifeSimController(
          random: Random(seed),
          startMoney: LifeOrigin.comfortable.familyMoney,
          withFamily: true,
        );
        final fired = <String, List<(String, int)>>{};
        while (!life.finished && life.age < 85) {
          life.ageUp();
          final e = life.currentEvent;
          if (e == null) continue;
          final topic = topicOf[e.id];
          if (topic != null) {
            (fired[topic] ??= <(String, int)>[]).add((e.id, life.age));
          }
          life.chooseOption(pick.nextInt(e.choices.length));
        }
        fired.forEach((topic, hits) {
          for (var i = 1; i < hits.length; i++) {
            final (id, age) = hits[i];
            final (prevId, prevAge) = hits[i - 1];
            if (!repeatable[id]! || age - prevAge < 6) {
              problems.add(
                'seed $seed: $topic fired $prevId at $prevAge then $id at $age',
              );
            }
          }
        });
      }
      expect(problems, isEmpty, reason: problems.take(10).join('\n'));
    });

    test('downsizing needs a house, and sells it', () {
      // Two of the three versions were drawn for renters and paid out — one
      // of them 40,000 — while the house stayed owned.
      final cards = kLifeEvents.where((e) => e.topic == 'downsize').toList();
      expect(cards, hasLength(3));
      for (final e in cards) {
        expect(
          e.requiresAsset == AssetKind.home ||
              e.requiresFlag == LifeFlag.ownsHome,
          isTrue,
          reason: '${e.id} can be drawn without a home',
        );
        for (final c in e.choices) {
          expect(
            c.money,
            lessThan(5000),
            reason: '${e.id}: "${c.label}" pays out without selling anything',
          );
          final sells =
              c.label.startsWith('Downsize') || c.label.startsWith('Sell');
          if (sells) {
            expect(c.sellsAsset, AssetKind.home, reason: c.label);
          }
        }
      }
    });
  });
}
