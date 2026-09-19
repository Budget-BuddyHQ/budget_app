import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_wellbeing.dart';

import 'support/fixed_random.dart';

/// Running yourself down costs shifts, and shifts are pay.
///
/// **Asked for as:** *"make punishments if you're not happy or if you're not
/// healthy, like you are going to have to skip out on work."* Health and
/// happiness were meters that nothing in the money game ever read: a character
/// at 8 Health and 5 Happiness collected the same paycheck as one at 90 and 90.
///
/// These hold three things. The thresholds are sane, so it takes real
/// neglect to lose anything. The cost lands in the paycheck, and exactly. And it
/// is a lesson rather than a trap: there is a warning first, recovery resets it,
/// and the wording is safe for an eight-year-old.
void main() {
  /// A salaried adult in a year with no shocks, no illness and no events that
  /// move money, so the paycheck is the only thing that can differ.
  LifeSimController worker({int health = 85, int happiness = 65}) {
    final life = LifeSimController(
      random: FixedRandom.unlucky(),
      name: 'Tester',
      gender: Gender.nonBinary,
      origin: LifeOrigin.workingClass,
      initialAge: 30,
      startMoney: 0,
      startJob: 'Barista',
      startSalary: 1000,
    );
    life.debugSetStats(health: health, happiness: happiness);
    return life;
  }

  /// Everything the feed has said, since `log` is only the latest banner line.
  String feed(LifeSimController life) =>
      life.history.map((entry) => entry.text).join(' | ');

  /// Ages a year, taking the default option on any event so the next year can
  /// run, then puts the stats back so a test can hold them steady.
  void year(LifeSimController life, {int? health, int? happiness}) {
    life.ageUp();
    if (life.currentEvent != null) life.chooseOption(0);
    life.debugSetStats(health: health, happiness: happiness);
  }

  group('the thresholds', () {
    test('a healthy, settled character loses nothing', () {
      final strain = assessWorkStrain(health: 85, happiness: 65);
      expect(strain.missesWork, isFalse);
      expect(strain.payShare, 1.0);
      expect(strain.level, StrainLevel.none);
    });

    test('there is a warning before there is a cost', () {
      // Low enough to worry, not low enough to cost a single shift.
      final watch = assessWorkStrain(health: 50, happiness: 65);
      expect(watch.level, StrainLevel.watch);
      expect(watch.missesWork, isFalse);
      expect(strainWarning(watch, jobAtRisk: false), isNotNull);
    });

    test('the cost steps up with how low it goes', () {
      double missed(int health) =>
          assessWorkStrain(health: health, happiness: 65).missedShare;
      expect(missed(39), 0.12);
      expect(missed(24), 0.28);
      expect(missed(11), 0.45);
      expect(missed(39), lessThan(missed(24)));
      expect(missed(24), lessThan(missed(11)));
    });

    test('a flat mood costs shifts too, but a little less', () {
      double missed(int happiness) =>
          assessWorkStrain(health: 85, happiness: happiness).missedShare;
      expect(missed(34), 0.08);
      expect(missed(19), 0.18);
      expect(missed(7), 0.30);
    });

    test('two bad numbers are worse than one, and no year is ever lost', () {
      final both = assessWorkStrain(health: 5, happiness: 3);
      expect(both.missedShare, 0.6, reason: 'capped, not summed to 0.75');
      expect(both.payShare, closeTo(0.4, 0.0001));
      expect(both.cause, 'poor health and a flat mood');
      expect(both.fromHealth && both.fromMood, isTrue);
    });

    test('weeks are whole and match the share', () {
      expect(assessWorkStrain(health: 24, happiness: 65).weeksMissed, 15);
      expect(assessWorkStrain(health: 85, happiness: 65).weeksMissed, 0);
    });

    test('every warning says what to do, not just what is wrong', () {
      for (final health in <int>[50, 30, 10]) {
        final strain = assessWorkStrain(health: health, happiness: 65);
        final text = strainWarning(strain, jobAtRisk: false)!;
        expect(
          text.contains('Rest') ||
              text.contains('Exercise') ||
              text.contains('check-up'),
          isTrue,
          reason: 'health $health: "$text" is a nag with no way out',
        );
      }
      expect(
        strainWarning(
          assessWorkStrain(health: 10, happiness: 65),
          jobAtRisk: true,
        ),
        contains('at risk'),
      );
    });
  });

  group('the cost lands in the paycheck', () {
    test('a healthy year saves 20% of the salary', () {
      final life = worker();
      life.ageUp();
      // 1000 salary, 50/30/20 default: 200 goes to savings.
      expect(life.emergencyFund, 200);
      expect(life.weeksMissedTotal, 0);
    });

    test('an unwell year is paid for the weeks that were worked', () {
      final life = worker(health: 20);
      life.ageUp();
      // Health 20 misses 28%: paid 720, so 20% saved is 144, not 200.
      expect(life.emergencyFund, 144);
      expect(life.weeksMissedTotal, 15);
      expect(feed(life), contains('missed about 15 weeks'));
    });

    test('a worn-out year costs too', () {
      final life = worker(happiness: 5);
      life.ageUp();
      // Happiness 5 misses 30%: paid 700, 20% is 140.
      expect(life.emergencyFund, 140);
    });

    test('it takes real neglect: a character at 40 health loses nothing', () {
      final life = worker(health: 40);
      life.ageUp();
      expect(life.emergencyFund, 200);
    });

    test('the ledger still balances when pay is docked', () {
      // A shortfall must never destroy money. The paycheck is smaller, and
      // everything computed from it shrinks with it.
      final healthy = worker();
      final unwell = worker(health: 10);
      healthy.ageUp();
      unwell.ageUp();
      final gap =
          (healthy.money + healthy.emergencyFund) -
          (unwell.money + unwell.emergencyFund);
      // Health 10 misses 45% of 1000. The whole of the gap is the docked pay,
      // less what the smaller wants budget stopped spending.
      expect(gap, greaterThan(0));
      expect(gap, lessThanOrEqualTo(450));
    });
  });

  group('losing the job', () {
    test('one bad year is a warning, not the end', () {
      final life = worker(health: 10);
      life.ageUp();
      expect(life.hasJob, isTrue);
      expect(life.timesLaidOff, 0);
    });

    test('and it says so while there is still a year to act in', () {
      final life = worker(health: 10);
      year(life, health: 10);
      expect(life.jobAtRisk, isTrue);
      expect(life.strainNotice, contains('at risk'));
    });

    test('a second bad year in a row ends the job', () {
      final life = worker(health: 10);
      year(life, health: 10);
      life.ageUp();
      expect(life.job, 'Unemployed');
      expect(life.salary, 0);
      expect(life.timesLaidOff, 1);
      expect(feed(life), contains('let you go'));
    });

    test('recovering in between resets the clock', () {
      final life = worker(health: 10);
      year(life, health: 90); // got better
      life.ageUp();
      expect(life.hasJob, isTrue, reason: 'punished for a year already fixed');
      expect(life.timesLaidOff, 0);
    });

    test('a milder cost never loses the job however long it lasts', () {
      // Health 39 costs 12%, under the line the employer counts. It is a
      // reason to look after yourself, not a career-ending one.
      final life = worker(health: 39);
      for (var i = 0; i < 6; i++) {
        year(life, health: 39);
      }
      expect(life.hasJob, isTrue);
      expect(life.timesLaidOff, 0);
    });
  });

  group('who it applies to', () {
    test('an unemployed adult has nothing to miss', () {
      final life = LifeSimController(
        random: FixedRandom.unlucky(),
        initialAge: 30,
      )..debugSetStats(health: 5, happiness: 5);
      life.ageUp();
      expect(life.weeksMissedTotal, 0);
      expect(life.strainNotice, isNull);
    });

    test('a child is never told they missed work', () {
      final child = LifeSimController(
        random: FixedRandom.unlucky(),
        initialAge: 9,
      )..debugSetStats(health: 5, happiness: 5);
      expect(child.strainNotice, isNull);
      child.ageUp();
      expect(child.weeksMissedTotal, 0);
      expect(child.timesLaidOff, 0);
    });

    test('a poorly child misses a little school, and nothing worse', () {
      final child = LifeSimController(
        random: FixedRandom.unlucky(),
        initialAge: 9,
      )..debugSetStats(health: 10, smarts: 50);
      child.ageUp();
      expect(child.smarts, 48, reason: 'two points behind, no more');
      expect(feed(child), contains('missed a lot of school'));
    });
  });

  group('safe for the youngest players', () {
    test('no message names a condition or dwells on a low mood', () {
      // Everything a player can be told about neglect, gathered up. The
      // vocabulary is work, shifts, rest and pay.
      final messages = <String>[
        for (final health in <int>[50, 30, 10])
          for (final happiness in <int>[50, 30, 5])
            strainWarning(
                  assessWorkStrain(health: health, happiness: happiness),
                  jobAtRisk: false,
                ) ??
                '',
        strainWarning(
          assessWorkStrain(health: 10, happiness: 5),
          jobAtRisk: true,
        )!,
      ];
      const banned = <String>[
        'depress',
        'suicid',
        'self-harm',
        'hopeless',
        'worthless',
        'die',
        'kill',
        'anxiety',
        'disorder',
        'therapy',
      ];
      for (final text in messages) {
        for (final word in banned) {
          expect(
            text.toLowerCase().contains(word),
            isFalse,
            reason: '"$text" contains "$word"',
          );
        }
      }
    });
  });
}
