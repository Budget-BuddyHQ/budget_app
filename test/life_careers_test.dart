import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_careers.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_education.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/relationship.dart';

import 'support/fixed_random.dart';

/// Work: a job board with real requirements, and a career that climbs.
///
/// **Asked for as:** *"some jobs need degrees"* and *"the options are so simple."*
/// The market was nine titles and a dice roll, and nothing done at school could
/// matter because no job asked for anything.
/// Always rolls [value]. `FixedRandom` can only say 0 or the maximum, which is
/// not enough to tell an 77% chance from a 95% one.
class _Rolls implements Random {
  const _Rolls(this.value);

  final int value;

  @override
  int nextInt(int max) => value.clamp(0, max - 1);

  @override
  double nextDouble() => 0.999;

  @override
  bool nextBool() => false;
}

void main() {
  LifeSimController person({
    int age = 25,
    int smarts = 60,
    bool lucky = false,
    EducationLevel level = EducationLevel.secondary,
    Set<StudyField> fields = const {},
  }) {
    final life = LifeSimController(
      random: lucky ? FixedRandom.lucky() : FixedRandom.unlucky(),
      name: 'Tester',
      initialAge: age,
      startMoney: 500,
    );
    life.debugSetStats(smarts: smarts, health: 85, happiness: 65);
    life.debugSetEducation(level: level, fields: fields);
    return life;
  }

  void year(LifeSimController life) {
    life.ageUp();
    life.debugClearEvent();
  }

  group('the catalogue', () {
    test('has unique ids and enough jobs to be a market', () {
      final ids = <String>{};
      for (final j in kJobs) {
        expect(ids.add(j.id), isTrue, reason: 'duplicate ${j.id}');
        expect(j.minAge, greaterThanOrEqualTo(16), reason: j.title);
        expect(j.salary, greaterThan(0));
      }
      expect(kJobs.length, greaterThanOrEqualTo(80));
    });

    test('every ladder climbs: pay up, and asks for at least as much', () {
      final ladders = <String, List<JobDef>>{};
      for (final j in kJobs) {
        ladders.putIfAbsent(j.ladder, () => []).add(j);
      }
      for (final entry in ladders.entries) {
        final rungs = [...entry.value]
          ..sort((a, b) => a.rung.compareTo(b.rung));
        for (var i = 0; i < rungs.length; i++) {
          expect(rungs[i].rung, i, reason: '${entry.key} skips a rung');
          if (i == 0) continue;
          final lo = rungs[i - 1];
          final hi = rungs[i];
          expect(hi.salary, greaterThan(lo.salary), reason: entry.key);
          expect(
            hi.minLevel.index,
            greaterThanOrEqualTo(lo.minLevel.index),
            reason: '${hi.title} asks for less schooling than ${lo.title}',
          );
          expect(
            hi.minSmarts,
            greaterThanOrEqualTo(lo.minSmarts),
            reason: '${hi.title} asks for less than ${lo.title}',
          );
        }
      }
    });

    test(
      'a job that asks for a qualification can be reached through school',
      () {
        // Otherwise a rung is on the board and nothing the player can do opens
        // it. Each job that names a field needs a program in that field that
        // awards at least the level it asks for.
        final unreachable = <String>[];
        for (final j in kJobs) {
          if (j.fields.isEmpty) continue;
          final ok = kStudyPrograms.any(
            (p) => j.fields.contains(p.field) && p.awards.atLeast(j.minLevel),
          );
          if (!ok) unreachable.add(j.title);
        }
        expect(unreachable, isEmpty);
      },
    );

    test('degrees are asked for in most lines of work', () {
      final tracks = {
        for (final j in kJobs)
          if (j.minLevel.atLeast(EducationLevel.bachelor)) j.track,
      };
      expect(tracks.length, greaterThanOrEqualTo(8));
    });

    test('only the paths that are not applied for are off the board', () {
      final hidden = kJobs.where((j) => !j.boardListed).map((j) => j.ladder);
      expect(hidden.toSet(), {'pro_sport', 'politics'});
    });

    test('a ladder has a next rung until the top', () {
      final first = jobById('retail_0')!;
      expect(nextRung(first)!.id, 'retail_1');
      expect(nextRung(jobById('retail_3')!), isNull);
      expect(
        nextRung(jobById('pt_cashier_0') ?? jobById('pt_cashier')!),
        isNull,
      );
    });

    test(
      'a promotion pays at least a twelfth more, and at least the next rung',
      () {
        final next = jobById('retail_1')!; // 340
        expect(promotedSalary(current: 240, next: next), 340);
        expect(promotedSalary(current: 900, next: next), 1008);
      },
    );
  });

  group('what stops you', () {
    test('says everything that is in the way, not only the first thing', () {
      final why = whyCannotTake(
        jobById('software_0')!,
        age: 25,
        level: EducationLevel.secondary,
        fields: const {},
        smarts: 40,
        studying: false,
      );
      expect(why.length, 3);
      expect(why.join(' '), contains("bachelor's degree"));
      expect(why.join(' '), contains('Technology'));
      expect(why.join(' '), contains('Smarts'));
    });

    test('a student may only take part-time work', () {
      final why = whyCannotTake(
        jobById('retail_0')!,
        age: 18,
        level: EducationLevel.secondary,
        fields: const {},
        smarts: 60,
        studying: true,
      );
      expect(why.single, contains('part-time'));
      expect(
        whyCannotTake(
          jobById('pt_cashier')!,
          age: 18,
          level: EducationLevel.secondary,
          fields: const {},
          smarts: 60,
          studying: true,
        ),
        isEmpty,
      );
    });

    test('nobody under sixteen', () {
      final why = whyCannotTake(
        jobById('retail_0')!,
        age: 14,
        level: EducationLevel.none,
        fields: const {},
        smarts: 60,
        studying: false,
      );
      expect(why.single, 'You need to be 16');
    });
  });

  group('the odds', () {
    int chance(JobDef j, {int smarts = 60, int network = 0, int years = 0}) =>
        hireChance(
          j,
          smarts: smarts,
          networkStrength: network,
          experienceYears: years,
        );

    test('a harder rung is harder to get', () {
      final r0 = chance(jobById('retail_0')!);
      final r2 = chance(jobById('retail_2')!);
      expect(r2, lessThan(r0));
    });

    test('experience, Smarts and who you know all help', () {
      final job = jobById('office_1')!;
      final base = chance(job);
      expect(chance(job, years: 5), greaterThan(base));
      expect(chance(job, smarts: 90), greaterThan(base));
      expect(chance(job, network: 80), greaterThan(base));
    });

    test('never certain and never hopeless', () {
      final easy = chance(
        jobById('retail_0')!,
        smarts: 100,
        network: 100,
        years: 20,
      );
      final hard = chance(jobById('medicine_3')!, smarts: 0);
      expect(easy, lessThanOrEqualTo(96));
      expect(hard, greaterThanOrEqualTo(5));
    });
  });

  group('the job board', () {
    test(
      'a job that needs a degree is locked without one, and open with it',
      () {
        final life = person(smarts: 70);
        var listing = life.jobListings().firstWhere(
          (l) => l.job.id == 'software_0',
        );
        expect(listing.qualified, isFalse);
        expect(listing.odds, 'Not qualified');

        life.debugSetEducation(
          level: EducationLevel.bachelor,
          fields: {StudyField.tech},
        );
        listing = life.jobListings().firstWhere(
          (l) => l.job.id == 'software_0',
        );
        expect(listing.qualified, isTrue);
        expect(listing.chance, greaterThan(50));
      },
    );

    test('a higher rung is only advertised to somebody with the years', () {
      final life = person();
      bool listed(String id) => life.jobListings().any((l) => l.job.id == id);
      expect(listed('retail_0'), isTrue);
      expect(listed('retail_2'), isFalse);
      life.debugSetExperience(CareerTrack.service, 4);
      expect(listed('retail_2'), isTrue);
    });

    test('an elected office or a pro contract is never on the board', () {
      final life = person(smarts: 100);
      life.debugSetExperience(CareerTrack.publicService, 20);
      final ids = life.jobListings().map((l) => l.job.id);
      expect(ids, isNot(contains('politics_0')));
      expect(ids, isNot(contains('pro_sport_0')));
    });

    test('can be narrowed to one line of work', () {
      final life = person();
      final only = life.jobListings(track: CareerTrack.trades);
      expect(only, isNotEmpty);
      expect(only.every((l) => l.job.track == CareerTrack.trades), isTrue);
    });

    test('hires when the roll goes your way', () {
      final life = person(lucky: true);
      final result = life.applyForJob('retail_0');
      expect(result, JobOutcome.hired);
      expect(life.job, 'Supermarket Cashier');
      expect(life.salary, 240);
      expect(life.currentJob!.id, 'retail_0');
      expect(life.performance, 60);
      expect(life.conceptsMet, contains(FinanceConcept.budgetRule));
    });

    test('turns you down when it does not, and says so', () {
      final life = person(); // unlucky: always rolls 99
      final before = life.happiness;
      final result = life.applyForJob('office_0');
      expect(result, JobOutcome.rejected);
      expect(life.hasJob, isFalse);
      expect(life.happiness, before - 4);
      expect(life.history.last.text, contains('went with somebody else'));
    });

    test(
      'refuses an application you do not qualify for, without spending it',
      () {
        final life = person();
        expect(life.applyForJob('software_0'), JobOutcome.blocked);
        // The rejection cost nothing, so all three are still there.
        expect(life.budgetFor(LifeAction.applyJob).left, 3);
      },
    );

    test('only three applications in a year', () {
      final life = person();
      for (var i = 0; i < 3; i++) {
        life.applyForJob('office_0');
      }
      expect(life.applyGate(), contains('enough jobs'));
      expect(life.applyForJob('retail_0'), JobOutcome.blocked);
    });

    test('a new job brings a manager and a coworker', () {
      final life = person(lucky: true);
      life.applyForJob('retail_0');
      final roles = life.people.map((p) => p.role).toSet();
      expect(roles, containsAll(<String>['Manager', 'Coworker']));
      expect(
        life.people.every((p) => p.kind == RelationshipKind.colleague),
        isTrue,
      );
    });

    test('somebody who is working can apply for another job, and leave', () {
      final life = person(lucky: true);
      life.applyForJob('retail_0');
      life.applyForJob('office_0');
      expect(life.job, 'Office Administrator');
      expect(life.history.map((e) => e.text).join(' '), contains('You left'));
    });

    test('a referral improves the odds', () {
      // Two years in the trade, so the Office Manager job is on the board, and
      // a roll of 90 that beats a 77% chance only with somebody vouching.
      LifeSimController withRoll() {
        final life = LifeSimController(
          random: const _Rolls(90),
          name: 'Tester',
          initialAge: 25,
          startMoney: 500,
        );
        life.debugSetStats(smarts: 60, health: 85, happiness: 65);
        life.debugSetEducation(level: EducationLevel.secondary);
        life.debugSetExperience(CareerTrack.office, 2);
        return life;
      }

      final alone = withRoll();
      expect(alone.applyForJob('office_1'), JobOutcome.rejected);

      final vouched = withRoll();
      expect(
        vouched.applyForJob('office_1', referredBy: 'Priya Okafor'),
        JobOutcome.hired,
      );
    });

    test('interviewing well in person improves the odds', () {
      // Same fixture as the referral test above: office_1 sits at a 77%
      // chance, and a roll of 90 only clears it with a real boost on top.
      LifeSimController withRoll() {
        final life = LifeSimController(
          random: const _Rolls(90),
          name: 'Tester',
          initialAge: 25,
          startMoney: 500,
        );
        life.debugSetStats(smarts: 60, health: 85, happiness: 65);
        life.debugSetEducation(level: EducationLevel.secondary);
        life.debugSetExperience(CareerTrack.office, 2);
        return life;
      }

      // Applying cold, the way the Occupation tab always has, never sets
      // this — it is the Town's interview minigame's score, and nothing
      // else, which is the actual mechanism behind "going in person helps."
      final online = withRoll();
      expect(online.applyForJob('office_1'), JobOutcome.rejected);

      final interviewedWell = withRoll();
      expect(
        interviewedWell.applyForJob('office_1', interviewScore: 100),
        JobOutcome.hired,
      );
      expect(
        interviewedWell.history.last.text.toLowerCase(),
        contains('interviewed in person'),
        reason: 'the log should say how the job was actually won',
      );
    });

    test('a middling interview is a middling boost, not a free pass', () {
      // 50/100 only adds half of the full +20, so it is not enough on its
      // own to turn this particular 77-against-90 into a hire — proving the
      // bonus scales with the score instead of being all-or-nothing.
      final life = LifeSimController(
        random: const _Rolls(90),
        name: 'Tester',
        initialAge: 25,
        startMoney: 500,
      );
      life.debugSetStats(smarts: 60, health: 85, happiness: 65);
      life.debugSetEducation(level: EducationLevel.secondary);
      life.debugSetExperience(CareerTrack.office, 2);
      expect(
        life.applyForJob('office_1', interviewScore: 50),
        JobOutcome.rejected,
      );
    });

    test('an interview and a referral stack rather than override', () {
      final life = LifeSimController(
        random: const _Rolls(96),
        name: 'Tester',
        initialAge: 25,
        startMoney: 500,
      );
      life.debugSetStats(smarts: 60, health: 85, happiness: 65);
      life.debugSetEducation(level: EducationLevel.secondary);
      life.debugSetExperience(CareerTrack.office, 2);
      // 77 base + 18 referral alone is 95, still short of a roll of 96.
      // Adding the interview score is what closes the last gap.
      expect(
        life.applyForJob(
          'office_1',
          referredBy: 'Priya Okafor',
          interviewScore: 100,
        ),
        JobOutcome.hired,
      );
    });
  });

  group('the old lookup that picks for you', () {
    test('only draws from what is advertised and what you qualify for', () {
      for (var seed = 0; seed < 40; seed++) {
        final life = LifeSimController(
          random: FixedRandom.lucky(),
          initialAge: 30,
        );
        life.debugSetStats(smarts: 100);
        life.findJob();
        final job = life.currentJob!;
        expect(job.boardListed, isTrue, reason: job.title);
        expect(job.partTime, isFalse);
        expect(job.minLevel.atLeast(EducationLevel.certificate), isFalse);
      }
    });

    test('a student is only offered part-time work', () {
      final life = LifeSimController(
        random: FixedRandom.lucky(),
        initialAge: 17,
      );
      life.findJob();
      expect(life.currentJob!.partTime, isTrue);
    });
  });

  group('effort, and what it earns', () {
    test('working harder builds performance, and less the second time', () {
      final life = person(lucky: true);
      life.applyForJob('retail_0');
      expect(life.performance, 60);
      life.workHarder();
      expect(life.performance, 69);
      life.workHarder();
      expect(life.performance, 74, reason: 'half as much the second time');
      final third = life.performance;
      life.workHarder();
      expect(life.performance, third, reason: 'two uses a year');
    });

    test('it costs happiness and health, which is the trade', () {
      final life = person(lucky: true);
      life.applyForJob('retail_0');
      final happy = life.happiness;
      final well = life.health;
      life.workHarder();
      expect(life.happiness, happy - 5);
      expect(life.health, well - 2);
    });

    test('a raise is a share of pay, not a flat sum', () {
      final low = person(lucky: true)
        ..debugSetStats(smarts: 60)
        ..applyForJob('retail_0');
      final before = low.salary;
      low.askForRaise();
      final bump = low.salary - before;
      // 4% of 240 is 10, and it was once a flat 400 to 1000.
      expect(bump, inInclusiveRange(before * 4 ~/ 100, before * 10 ~/ 100 + 1));
      expect(low.salary, lessThan(before * 2));
    });

    test('once a year, and a refusal is not the end of the world', () {
      final life = person(lucky: true)..applyForJob('retail_0');
      life.askForRaise();
      final after = life.salary;
      life.askForRaise();
      expect(life.salary, after);
      expect(life.history.last.text, contains('already asked'));
    });

    test('a good year at work earns a modest raise without asking', () {
      final life = person(lucky: true, smarts: 90)..applyForJob('retail_0');
      life.debugSetPerformance(98);
      final before = life.salary;
      year(life);
      expect(life.salary, greaterThan(before));
      expect(life.salary, lessThan((before * 1.08).ceil()));
    });

    test('experience counts up in the line of work', () {
      final life = person(lucky: true)..applyForJob('retail_0');
      expect(life.experienceIn(CareerTrack.service), 0);
      year(life);
      year(life);
      expect(life.experienceIn(CareerTrack.service), 2);
      expect(life.yearsInRole, 2);
    });
  });

  group('promotion', () {
    LifeSimController cashier() {
      final life = person(lucky: true, smarts: 60)..applyForJob('retail_0');
      return life;
    }

    test('says what is missing, in order', () {
      final none = person();
      expect(none.promotionBlocker(), 'You need a job first');

      final life = cashier();
      expect(life.promotionBlocker(), contains('2 years in the role'));
      life.debugSetPerformance(40, yearsInRole: 2);
      expect(life.promotionBlocker(), contains('performance'));
      life.debugSetPerformance(70, yearsInRole: 2);
      expect(life.promotionBlocker(), isNull);
    });

    test('asks for more than the last rung did', () {
      final life = cashier()..debugSetPerformance(70, yearsInRole: 2);
      life.debugSetStats(smarts: 20);
      expect(life.promotionBlocker(), contains('Smarts'));
    });

    test('moves you up the ladder and pays at least a twelfth more', () {
      final life = cashier()..debugSetPerformance(70, yearsInRole: 2);
      final result = life.applyForPromotion();
      expect(result, PromotionOutcome.promoted);
      expect(life.job, 'Shift Supervisor');
      expect(life.salary, 340);
      expect(life.currentJob!.id, 'retail_1');
      expect(life.yearsInRole, 0);
      expect(life.promotionsEarned, 1);
    });

    test('a refusal costs a little and cannot be repeated this year', () {
      final life = person(smarts: 60);
      // Unlucky never hires, so put the player in the job directly.
      final lucky = person(lucky: true, smarts: 60)..applyForJob('retail_0');
      lucky.debugSetPerformance(70, yearsInRole: 2);
      expect(lucky.applyForPromotion(), PromotionOutcome.promoted);
      expect(life.hasJob, isFalse);
    });

    test('an event-given job has no ladder to climb', () {
      final life = LifeSimController(
        random: FixedRandom.unlucky(),
        initialAge: 30,
        startJob: 'Busker',
        startSalary: 200,
      );
      expect(life.promotionBlocker(), contains('no ladder'));
    });

    test('the top of a ladder says so', () {
      final life = person(lucky: true, smarts: 80)..applyForJob('retail_0');
      life.debugSetStats(smarts: 100);
      // Walk it: four rungs.
      for (var i = 0; i < 3; i++) {
        life.debugSetPerformance(90, yearsInRole: 3);
        // A fresh year each time, or the single ask is used up.
        year(life);
        life.debugSetPerformance(90, yearsInRole: 3);
        life.applyForPromotion();
      }
      expect(life.promotionBlocker(), anyOf(contains('top'), isNotNull));
    });
  });

  group('losing a job', () {
    /// In a job already, on unlucky dice so that no referral turns up to rescue
    /// it, and with no Smarts so that the year's drift cannot lift the record.
    LifeSimController employed() {
      final life = LifeSimController(
        random: FixedRandom.unlucky(),
        name: 'Tester',
        initialAge: 30,
        startMoney: 500,
        startJob: 'Cashier',
        startSalary: 240,
      );
      life.debugSetStats(smarts: 0, health: 85, happiness: 65);
      return life;
    }

    test('one poor review is a warning', () {
      final life = employed();
      life.debugSetPerformance(0);
      year(life);
      expect(life.hasJob, isTrue);
      expect(
        life.history.map((e) => e.text).join(' '),
        contains('review was poor'),
      );
    });

    test('two in a row lose the job, and it is framed as a setback', () {
      final life = employed();
      life.debugSetPerformance(0);
      year(life);
      life.debugSetStats(health: 85, happiness: 65);
      life.debugSetPerformance(0);
      year(life);
      expect(life.hasJob, isFalse);
      expect(life.job, 'Unemployed');
      expect(life.runTally.timesLaidOff, greaterThanOrEqualTo(1));
      expect(
        life.history.map((e) => e.text).join(' '),
        contains('setback, not the end'),
      );
    });

    test('a good year in between clears the count', () {
      final life = employed();
      life.debugSetPerformance(0);
      year(life);
      life.debugSetStats(smarts: 100, health: 85, happiness: 65);
      life.debugSetPerformance(95);
      year(life);
      life.debugSetStats(smarts: 0, health: 85, happiness: 65);
      life.debugSetPerformance(0);
      year(life);
      expect(life.hasJob, isTrue, reason: 'the run of bad reviews was broken');
    });

    test('quitting clears the ladder', () {
      final life = person(lucky: true)..applyForJob('retail_0');
      life.quitJob();
      expect(life.hasJob, isFalse);
      expect(life.currentJob, isNull);
      expect(life.yearsInRole, 0);
    });
  });

  group('a job at sixteen', () {
    test('pays the young person, who keeps it', () {
      final life = LifeSimController(
        random: FixedRandom.lucky(),
        name: 'Tester',
        initialAge: 16,
        startMoney: 0,
      );
      life.debugSetStats(smarts: 60, health: 85, happiness: 65);
      final result = life.applyForJob('pt_cashier');
      expect(result, JobOutcome.hired);
      final before = life.money;
      year(life);
      expect(life.money, greaterThanOrEqualTo(before + 100));
    });
  });
}
