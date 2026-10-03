import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_events_shocks.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/reading_grade.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixed_random.dart';

/// The bad days: a boss who lets you go, a fire, a flood, a crash, a hospital
/// bill.
///
/// **Asked for as:** *"make sure that disasters, or other BitLife events about
/// finance, happen, like your boss cutting you from your job."* Before this, a
/// simulation of 300 working lives found 140 of them never once met a layoff
/// card, and almost nothing that went wrong had a name. These hold three things:
/// the cards are written the way every other card here is, they are drawn often
/// enough to be met, and they are never drawn for a child.
void main() {
  final ours = [for (final e in kLifeEventsShocks) e];

  group('the cards themselves', () {
    test('every id in the shock set is a real event', () {
      final real = {for (final e in kLifeEvents) e.id};
      for (final id in kShockEventIds) {
        expect(
          real,
          contains(id),
          reason: '$id is named as a shock but does not exist',
        );
      }
    });

    test('and ids are not reused', () {
      final ids = [for (final e in kLifeEvents) e.id];
      expect(ids.toSet().length, ids.length);
    });

    test('they can come round again, because trouble does', () {
      for (final e in ours) {
        expect(e.repeatable, isTrue, reason: e.id);
      }
    });

    test('and are for somebody who has something to lose', () {
      for (final e in ours) {
        expect(e.minAge, greaterThanOrEqualTo(18), reason: e.id);
      }
    });

    test('every choice says what happened and names the money idea', () {
      for (final e in ours) {
        expect(e.choices.length, greaterThanOrEqualTo(2), reason: e.id);
        for (final c in e.choices) {
          expect(c.outcome.trim(), isNotEmpty, reason: '${e.id}: ${c.label}');
          expect(
            c.teaches,
            isNotNull,
            reason: '${e.id}: "${c.label}" teaches nothing',
          );
        }
      }
    });

    test('and none of them is a trap with a free way out', () {
      // The teaching layer's rule: the safe choice costs something, and the
      // cheap choice costs something else. A card where one option is simply
      // better would be a quiz.
      for (final e in ours) {
        final costs = [for (final c in e.choices) c.money];
        expect(
          costs.toSet().length,
          greaterThan(1),
          reason: '${e.id} charges every choice the same',
        );
      }
    });

    test('in plain words, because a child can be playing an adult', () {
      for (final e in ours) {
        expect(
          mentionsAdultTopic(e.prompt),
          isFalse,
          reason: '"${e.prompt}" would be hidden from a young player',
        );
        expect(
          readingGrade(e.prompt),
          lessThanOrEqualTo(9),
          reason: '"${e.prompt}" is hard to read',
        );
      }
    });

    test('and the ones that name a price say the price', () {
      for (final e in ours) {
        for (final c in e.choices) {
          final match = RegExp(r'\((\d+) coins').firstMatch(c.label);
          if (match == null) continue;
          expect(
            -c.money,
            int.parse(match.group(1)!),
            reason: '${e.id}: "${c.label}" says one price and charges another',
          );
        }
      }
    });
  });

  group('losing the job to a card', () {
    LifeSimController worker() => LifeSimController(
      random: FixedRandom.unlucky(),
      name: 'Tester',
      initialAge: 34,
      startMoney: 500,
      startJob: 'Barista',
      startSalary: 1000,
    );

    final letGo = kLifeEventsShocks.firstWhere(
      (e) => e.id == 's_boss_lets_you_go',
    );

    test('takes the job away, and counts it', () {
      for (var i = 0; i < letGo.choices.length; i++) {
        final life = worker();
        expect(life.hasJob, isTrue);
        life.debugSetEvent(letGo);
        life.chooseOption(i);
        final label = letGo.choices[i].label;
        expect(life.job, isNot('Barista'), reason: label);
        expect(life.salary, lessThan(1000), reason: label);
        expect(life.timesLaidOff, 1, reason: label);
      }
    });

    test('taking the first offer means working again, on less', () {
      // It used to leave the player Unemployed at 0 under text that says
      // "you are working again within weeks, and on less".
      final i = letGo.choices.indexWhere(
        (c) => c.label.startsWith('Take the first job'),
      );
      final life = worker();
      life.debugSetEvent(letGo);
      life.chooseOption(i);
      expect(life.hasJob, isTrue);
      expect(life.salary, greaterThan(0));
      expect(life.salary, lessThan(1000));
    });

    test('and opens the job board, so there is somewhere to go next', () {
      final life = worker();
      life.debugSetEvent(letGo);
      life.chooseOption(0);
      expect(life.takeFollowUp(), LifeFollowUp.openJobs);
    });

    test('the savings choice is what an emergency fund is for', () {
      final rich = worker()..debugSetStats(money: 3000);
      final broke = worker()..debugSetStats(money: 0);
      rich.debugSetEvent(letGo);
      broke.debugSetEvent(letGo);
      rich.chooseOption(0);
      broke.chooseOption(0);
      expect(rich.debt, 0, reason: 'they had it covered');
      expect(
        broke.debt,
        greaterThan(0),
        reason: 'with nothing saved it is borrowed',
      );
    });

    test('is only offered to somebody who has a job', () {
      final life = LifeSimController(
        random: FixedRandom.unlucky(),
        name: 'Tester',
        initialAge: 34,
        startMoney: 500,
      );
      expect(life.hasJob, isFalse);
      expect(letGo.matches(life.context), isFalse);
    });
  });

  group('how often they come', () {
    /// Lives from 22 to 62 with a job, taking the first option each time.
    List<({List<String> ids, int laidOffCards})> lives(int count) {
      final out = <({List<String> ids, int laidOffCards})>[];
      for (var i = 0; i < count; i++) {
        final life = LifeSimController(
          random: Random(i),
          name: 'Sim $i',
          initialAge: 22,
          startMoney: 1500,
          startJob: 'Barista',
          startSalary: 900,
        );
        final ids = <String>[];
        var cards = 0;
        for (var y = 0; y < 40 && !life.finished; y++) {
          life.ageUp();
          final e = life.currentEvent;
          ids.add(e?.id ?? '');
          if (e != null) {
            if (const {
              's_boss_lets_you_go',
              'a_redundancy',
              'redundancy',
            }.contains(e.id)) {
              cards++;
            }
            life.chooseOption(0);
          }
        }
        out.add((ids: ids, laidOffCards: cards));
      }
      return out;
    }

    late final sample = lives(120);

    test('almost every working life meets a boss letting somebody go', () {
      final met = sample.where((l) => l.laidOffCards > 0).length;
      expect(
        met / sample.length,
        greaterThanOrEqualTo(0.8),
        reason: 'only $met of ${sample.length} lives ever lost a job to a card',
      );
    });

    test('and it is not every other year', () {
      final mean =
          sample.fold<int>(0, (sum, l) => sum + l.laidOffCards) / sample.length;
      expect(mean, lessThan(3), reason: 'a life of $mean layoffs feels unfair');
      expect(mean, greaterThan(0.8));
    });

    test('an adult never goes long without something going wrong', () {
      var worst = 0;
      for (final l in sample) {
        var gap = 0;
        for (final id in l.ids) {
          if (kShockEventIds.contains(id)) {
            gap = 0;
          } else {
            gap++;
            if (gap > worst) worst = gap;
          }
        }
      }
      expect(
        worst,
        lessThanOrEqualTo(kShockGraceYears + 1),
        reason: 'one life went $worst years with no shock at all',
      );
    });

    test('a child is never dealt one', () {
      for (var i = 0; i < 40; i++) {
        final life = LifeSimController(
          random: Random(i),
          name: 'Kid $i',
          initialAge: 5,
        );
        while (life.age < 17 && !life.finished) {
          life.ageUp();
          final e = life.currentEvent;
          if (e != null) {
            expect(
              kShockEventIds.contains(e.id) && e.minAge >= 18,
              isFalse,
              reason: 'a child at ${life.age} was dealt ${e.id}',
            );
            life.chooseOption(0);
          }
        }
      }
    });
  });
}
