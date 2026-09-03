import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two ways to find work, and why they are different.
///
/// **The design this holds.** The town has a notice board with cards pinned
/// to it; the menu has a search you do from wherever you are sitting. Both are
/// real ways people find work, so neither is blocked — but turning up in
/// person is better, and the game should agree.
///
/// Before this, the board handed out 15 or 40 coins and could not employ
/// anybody: the one building in the game named after employment was a coin
/// dispenser with a career theme, and the only real route to a job was a menu
/// row. That is the wrong way round — the board is the thing a person walks
/// to.
void main() {
  LifeSimController jobless({int age = 20, int smarts = 60}) {
    final life = LifeSimController(
      random: Random(5),
      initialAge: age,
      startMoney: 200,
    );
    return life;
  }

  group('the board hires', () {
    test('it has an option that actually gets you a job', () {
      final board = kTownSpots.firstWhere((s) => s.kind == TownSpotKind.job);
      expect(
        board.choices.any((c) => c.hires),
        isTrue,
        reason: 'the job board cannot employ anybody',
      );
    });

    test('walking in with no job gets you one', () {
      final life = jobless();
      expect(life.hasJob, isFalse);
      life.applyTownOutcome(gold: 0, xp: 10, literacy: 6, hires: true);
      expect(
        life.hasJob,
        isTrue,
        reason: 'asking at the board did not hire anybody',
      );
    });

    test('it does not hire a child', () {
      // The board is on a map a seven-year-old can walk around.
      final child = jobless(age: 7);
      child.applyTownOutcome(gold: 0, xp: 10, literacy: 6, hires: true);
      expect(child.hasJob, isFalse);
    });

    test('it does not overwrite a job you already have', () {
      final life = LifeSimController(
        random: Random(2),
        initialAge: 30,
        startJob: 'Baker',
        startSalary: 900,
      );
      life.applyTownOutcome(gold: 0, xp: 10, literacy: 6, hires: true);
      expect(life.job, 'Baker');
      expect(life.salary, 900);
    });

    test('an ordinary town choice hires nobody', () {
      final life = jobless();
      life.applyTownOutcome(gold: 15, xp: 8, literacy: 0);
      expect(life.hasJob, isFalse);
    });
  });

  group('in person beats a form', () {
    test('the board pays better on average than applying online', () {
      // Best-of-three against best-of-two on the same job table. Averaged
      // over many runs because a single hire proves nothing — the point is
      // the bias, not any one result.
      double meanSalary({required bool viaBoard}) {
        var total = 0;
        const runs = 400;
        for (var seed = 0; seed < runs; seed++) {
          final life = LifeSimController(
            random: Random(seed),
            initialAge: 20,
            startMoney: 200,
          );
          life.findJob(viaJobBoard: viaBoard);
          total += life.salary;
        }
        return total / runs;
      }

      final online = meanSalary(viaBoard: false);
      final inPerson = meanSalary(viaBoard: true);
      expect(
        inPerson,
        greaterThan(online),
        reason: 'walking to the board pays $inPerson against $online online — '
            'turning up has to be worth something',
      );
      // ...and not so much that the menu route becomes a trap.
      expect(
        inPerson,
        lessThan(online * 1.5),
        reason: 'the board is not meant to be the only sensible way to work',
      );
    });

    test('both channels say which one you used', () {
      // The log is where every lesson in this app lives, so it has to record
      // *how* the job was found, not just that it was.
      final online = jobless();
      online.findJob();
      expect(online.log.toLowerCase(), contains('online'));

      final board = jobless();
      board.findJob(viaJobBoard: true);
      expect(board.log.toLowerCase(), contains('board'));
    });

    test('neither channel works before you are old enough', () {
      for (final viaBoard in <bool>[true, false]) {
        final child = jobless(age: 12);
        expect(child.findJob(viaJobBoard: viaBoard), isFalse);
        expect(child.hasJob, isFalse);
      }
    });
  });
}
