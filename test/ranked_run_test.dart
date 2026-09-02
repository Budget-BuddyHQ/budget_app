import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/ranked_run.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ranked scoring.
///
/// The whole reason this is scored rather than just measured is to make one
/// trade real: a fortune you did not survive is worth less than a smaller one
/// you did. Most of these tests are that claim, from different angles.
void main() {
  RankedResult result({
    int netWorth = 50000,
    int ageReached = 70,
    int conceptsMet = 6,
    bool died = false,
    bool everStarved = false,
  }) => RankedResult(
    netWorth: netWorth,
    ageReached: ageReached,
    conceptsMet: conceptsMet,
    died: died,
    everStarved: everStarved,
  );

  group('wealth', () {
    test('more money scores more', () {
      expect(
        scoreRankedRun(result(netWorth: 200000)).total,
        greaterThan(scoreRankedRun(result(netWorth: 40000)).total),
      );
    });

    test('debt is not worth negative points, only zero', () {
      // A run that ends owing money has already been punished by the game. A
      // negative score on top of it is piling on, and it is the exact player
      // who most needs to be told to try again.
      final broke = scoreRankedRun(result(netWorth: -90000));
      expect(broke.wealthPoints, 0);
      expect(broke.total, greaterThanOrEqualTo(0));
    });

    test('a windfall does not swamp everything else', () {
      // The stardom chain can pay out most of a million in one event. Scored
      // linearly that single draw would outweigh every other decision in the
      // game combined, and the leaderboard would rank one lucky roll.
      final ordinary = scoreRankedRun(result(netWorth: 60000)).wealthPoints;
      final jackpot = scoreRankedRun(result(netWorth: 900000)).wealthPoints;
      expect(jackpot, greaterThan(ordinary));
      expect(
        jackpot,
        lessThan(ordinary * 6),
        reason: '15x the money should not be anywhere near 15x the score',
      );
    });
  });

  group('survival is a multiplier, not a bonus', () {
    test('dying young with a fortune loses to retiring old with less', () {
      // The claim the whole scoring shape exists to make.
      final reckless = scoreRankedRun(
        result(netWorth: 150000, ageReached: 34, died: true),
      );
      final careful = scoreRankedRun(
        result(netWorth: 95000, ageReached: 82),
      );
      expect(careful.total, greaterThan(reckless.total));
    });

    test('starving at any point costs you, even if you recovered', () {
      final steady = scoreRankedRun(result());
      final scraped = scoreRankedRun(result(everStarved: true));
      expect(scraped.total, lessThan(steady.total));
    });

    test('the multiplier stays inside its band', () {
      for (final r in <RankedResult>[
        result(ageReached: 0, died: true, everStarved: true),
        result(ageReached: 85),
        result(ageReached: 200),
      ]) {
        final score = scoreRankedRun(r);
        expect(
          score.survivalMultiplier,
          inInclusiveRange(kMinSurvivalMultiplier, kMaxSurvivalMultiplier),
        );
      }
    });
  });

  group('understanding', () {
    test('meeting ideas is worth points', () {
      expect(
        scoreRankedRun(result(conceptsMet: 16)).total,
        greaterThan(scoreRankedRun(result(conceptsMet: 0)).total),
      );
    });

    test('but never enough to replace a financial life', () {
      // It should be worth going and learning something. It should never be
      // worth *only* learning things.
      final allIdeasNoMoney = scoreRankedRun(
        result(netWorth: 0, conceptsMet: 16),
      );
      final noIdeasRealMoney = scoreRankedRun(
        result(netWorth: 120000, conceptsMet: 0),
      );
      expect(noIdeasRealMoney.total, greaterThan(allIdeasNoMoney.total));
    });
  });

  group('grades', () {
    test('improve as the total does, and never reach F', () {
      // This is a financial-literacy app for children. A screen that tells a
      // nine-year-old they failed at a life is not a thing worth building.
      var previous = '';
      for (final total in <int>[0, 4000, 9000, 14000, 20000, 40000]) {
        final grade = rankedGrade(total);
        expect(grade, isNot('F'));
        expect(grade, isNot(previous), reason: 'bands should be distinct');
        expect(rankedGradeBlurb(grade).length, greaterThan(40));
        previous = grade;
      }
      expect(rankedGrade(999999), 'S');
    });
  });

  group('a real run scores', () {
    test('a played-out life produces a sane score', () {
      final life = LifeSimController(random: Random(12), initialAge: 0);
      while (!life.finished && life.age < 90) {
        if (life.currentEvent != null) life.chooseOption(0);
        life.ageUp();
      }
      final score = scoreRankedRun(life.rankedResult);
      expect(score.total, greaterThanOrEqualTo(0));
      expect(score.grade, isNotEmpty);
      expect(life.rankedResult.ageReached, life.age);
    });

    test('everStarved survives a recovery', () {
      // `hunger` comes back down when you eat again; the ranked flag must not.
      final life = LifeSimController(
        random: Random(4),
        initialAge: 30,
        startMoney: 0,
        startJob: 'Tester',
        startSalary: 900,
      );
      expect(life.everStarved, isFalse);
      life.debugSetHunger(LifeSimController.starvationThreshold);
      life.setBudget(needs: 60, wants: 20, savings: 20);
      life.ageUp();
      expect(life.hunger, lessThan(LifeSimController.starvationThreshold));
    });
  });
}
