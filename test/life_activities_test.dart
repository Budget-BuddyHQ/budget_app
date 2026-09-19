import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_activities.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_education.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';

import 'support/fixed_random.dart';

/// What to do with a year.
///
/// **Asked for as:** *"the options are so simple, it's so boring"* and *"the
/// late game is so repetitive."* The Activities menu was eight rows.
void main() {
  LifeSimController person({
    int age = 25,
    int money = 1000,
    bool lucky = false,
  }) {
    final life = LifeSimController(
      random: lucky ? FixedRandom.lucky() : FixedRandom.unlucky(),
      name: 'Tester',
      initialAge: age,
      startMoney: money,
    );
    life.debugSetStats(health: 60, happiness: 50, smarts: 50, looks: 50);
    return life;
  }

  void year(LifeSimController life) {
    life.ageUp();
    life.debugClearEvent();
  }

  String feed(LifeSimController life) =>
      life.history.map((e) => e.text).join(' | ');

  group('the catalogue', () {
    test('is big enough to have variety', () {
      expect(kActivities.length, greaterThanOrEqualTo(30));
      for (final category in ActivityCategory.values) {
        if (category == ActivityCategory.sport ||
            category == ActivityCategory.special) {
          continue; // these are driven by their own screens
        }
        expect(
          activitiesIn(category),
          isNotEmpty,
          reason: '${category.label} is an empty list',
        );
      }
    });

    test('has unique ids and sane numbers', () {
      final ids = <String>{};
      for (final a in kActivities) {
        expect(ids.add(a.id), isTrue, reason: 'duplicate ${a.id}');
        expect(a.cost, greaterThanOrEqualTo(0));
        expect(a.minAge, inInclusiveRange(6, 25), reason: a.title);
        expect(a.cap, inInclusiveRange(1, 3), reason: a.title);
        expect(a.tiers.first, 1.0);
        expect(a.title, isNotEmpty);
        expect(a.outcome, isNotEmpty);
      }
    });

    test('a later use never pays more than the one before', () {
      for (final a in kActivities) {
        for (var i = 1; i < a.tiers.length; i++) {
          expect(a.tiers[i], lessThanOrEqualTo(a.tiers[i - 1]), reason: a.id);
        }
      }
    });

    test('nothing in it is gambling, crime, drugs or fighting', () {
      // Life is for ages nine and up and stays family friendly. A rule that only
      // lives in a comment gets broken by the next person to add a row, so it is
      // a test.
      const banned = [
        'gambl',
        'casino',
        'lottery',
        'bet ',
        'steal',
        'rob',
        'crime',
        'drug',
        'fight',
        'weapon',
        'alcohol',
        'beer',
        'vape',
        'smok',
      ];
      for (final a in kActivities) {
        final text = '${a.title} ${a.blurb} ${a.outcome}'.toLowerCase();
        for (final word in banned) {
          expect(text, isNot(contains(word)), reason: '"$word" in ${a.id}');
        }
      }
    });

    test(
      'an activity that costs money and is not about earning teaches nothing '
      'false',
      () {
        // Anything flagged as teaching must name a real concept.
        for (final a in kActivities.where((a) => a.teaches != null)) {
          expect(FinanceConcept.values, contains(a.teaches));
        }
      },
    );

    test('the dating activities are for adults', () {
      for (final a in kActivities.where((a) => a.partnerChance > 0)) {
        expect(a.minAge, greaterThanOrEqualTo(18), reason: a.id);
      }
    });
  });

  group('doing something', () {
    test('changes what it says and nothing else', () {
      final life = person();
      final joy = life.happiness;
      final well = life.health;
      final cash = life.money;
      expect(life.doActivity('run'), isTrue);
      expect(life.health, well + 5);
      expect(life.happiness, joy + 1);
      expect(life.money, cash);
      expect(feed(life), contains('went for a run'));
    });

    test('costs what it costs, from cash', () {
      final life = person();
      final cash = life.money;
      life.doActivity('clothes'); // 60
      expect(life.money, cash - 60);
      expect(life.looks, 55);
    });

    test('a year has room for a few, and fades', () {
      final life = person();
      life.doActivity('run');
      final second = life.health;
      life.doActivity('run');
      expect(life.health - second, 3, reason: 'half strength, rounded up');
      life.doActivity('run');
      life.doActivity('run');
      expect(life.activityGate(activityById('run')!), 'Done for this year');
      expect(life.activityNote(activityById('run')!), 'Done for this year');
    });

    test('and the note says what is left', () {
      final life = person();
      expect(life.activityNote(activityById('run')!), '3 uses left this year');
      life.doActivity('run');
      expect(
        life.activityNote(activityById('run')!),
        '2 uses left · pays 50% now',
      );
    });

    test('comes back next year', () {
      final life = person();
      for (var i = 0; i < 3; i++) {
        life.doActivity('run');
      }
      expect(life.doActivity('run'), isFalse);
      year(life);
      expect(life.doActivity('run'), isTrue);
    });

    test('a costly one cannot be done without the money', () {
      final life = person(money: 10);
      expect(life.activityGate(activityById('holiday')!), contains('450'));
      expect(life.doActivity('holiday'), isFalse);
    });

    test('a child is not stopped by a price, and the family pays', () {
      final kid = person(age: 10, money: 0);
      expect(kid.activityGate(activityById('amusement')!), isNull);
      kid.doActivity('amusement');
      expect(kid.money, 0);
      expect(kid.happiness, greaterThan(50));
    });

    test('but earning something is different: the stake is your own', () {
      final kid = person(age: 12, money: 5);
      expect(kid.activityGate(activityById('market_stand')!), contains('20'));
    });

    test('is closed until the age it opens at', () {
      final life = person(age: 12);
      expect(life.activityGate(activityById('holiday')!), 'You need to be 18');
      expect(life.doActivity('holiday'), isFalse);
    });

    test('teaches when it is about money', () {
      final life = person();
      life.doActivity('clothes');
      expect(life.conceptsMet, contains(FinanceConcept.needsVsWants));
    });

    test('hanging out warms every friend a little', () {
      final life = person(age: 14)
        ..debugAddPerson('Sam', closeness: 40)
        ..debugAddPerson('Kim', closeness: 50);
      life.doActivity('hang_out');
      expect(life.people.firstWhere((p) => p.name == 'Sam').closeness, 43);
      expect(life.people.firstWhere((p) => p.name == 'Kim').closeness, 53);
    });

    test('a club builds the skill it is about', () {
      final life = person(age: 14);
      expect(life.skillLevel(LifeSkill.charisma), 0);
      life.doActivity('club_drama');
      expect(life.skillLevel(LifeSkill.charisma), 6);
    });

    test('selling things can make a little, or lose a little', () {
      final good = person(age: 14);
      final goodCash = good.money;
      good.doActivity('market_stand'); // unlucky dice roll the top of the range
      expect(good.money, greaterThan(goodCash - 20));

      final bad = person(age: 14, lucky: true);
      final badCash = bad.money;
      bad.doActivity('market_stand'); // lucky rolls the bottom: a loss
      expect(bad.money, lessThan(badCash - 20 + 1));
      expect(feed(bad), contains('Some days do'));
    });
  });

  group('sport', () {
    test('you have to be nine to try out', () {
      final kid = person(age: 8);
      expect(kid.tryoutGate(LifeSport.soccer), 'You need to be 9');
    });

    test('the odds follow skill and health, never certain, never hopeless', () {
      expect(tryoutChance(skill: 0, health: 0), greaterThanOrEqualTo(10));
      expect(tryoutChance(skill: 100, health: 100), lessThanOrEqualTo(95));
      expect(
        tryoutChance(skill: 60, health: 70),
        greaterThan(tryoutChance(skill: 10, health: 70)),
      );
    });

    test('making the team puts you on it, with a friend', () {
      final life = person(age: 13, lucky: true);
      expect(life.tryOut(LifeSport.soccer), isTrue);
      expect(life.sport, LifeSport.soccer);
      expect(life.sportStanding, greaterThanOrEqualTo(45));
      expect(life.friendList.any((p) => p.role == 'Teammate'), isTrue);
    });

    test('missing out stings, and you can try again once more', () {
      final life = person(age: 13);
      final joy = life.happiness;
      life.tryOut(LifeSport.soccer);
      expect(life.sport, isNull);
      expect(life.happiness, joy - 3);
      life.tryOut(LifeSport.tennis);
      expect(life.tryoutGate(LifeSport.track), 'Done for this year');
    });

    test('training builds standing, and less each time', () {
      final life = person(age: 13, lucky: true)..tryOut(LifeSport.soccer);
      final base = life.sportStanding;
      life.trainWithTeam();
      final first = life.sportStanding - base;
      final mid = life.sportStanding;
      life.trainWithTeam();
      expect(life.sportStanding - mid, lessThan(first));
      life.trainWithTeam();
      expect(life.trainGate(), 'Done for this year');
    });

    test('a season moves standing and builds the skill', () {
      final life = person(age: 13, lucky: true)..tryOut(LifeSport.soccer);
      final skill = life.skillLevel(LifeSkill.sports);
      year(life);
      expect(life.skillLevel(LifeSkill.sports), greaterThan(skill));
      expect(life.seasonsPlayed, 1);
    });

    test('standing drifts back, so it has to be kept up', () {
      final life = person(age: 20)
        ..debugSetStats(health: 40)
        ..debugSetSport(LifeSport.soccer, standing: 90);
      for (var i = 0; i < 4; i++) {
        year(life);
        life.debugSetStats(health: 40, happiness: 60);
      }
      expect(life.sportStanding, lessThan(90));
    });

    test('leaving the team clears the standing', () {
      final life = person(age: 13, lucky: true)..tryOut(LifeSport.soccer);
      expect(life.leaveTeam(), isTrue);
      expect(life.sport, isNull);
      expect(life.sportStanding, 0);
      expect(life.leaveTeam(), isFalse);
    });

    test('a standout earns a scholarship, which is what it is for', () {
      final life = person(age: 18);
      final program = studyProgramById('college_business')!;
      expect(life.tuitionQuote(program).scholarship, 0);
      life.debugSetSport(LifeSport.soccer, standing: 88);
      final quote = life.tuitionQuote(program);
      expect(quote.scholarship, greaterThan(0));
      expect(quote.you, lessThan(program.tuition));
    });

    test('a pro contract needs standing, an age, and a team', () {
      expect(person(age: 20).proTryoutGate(), 'Join a team first');
      final weak = person(age: 20)
        ..debugSetSport(LifeSport.soccer, standing: 60);
      expect(weak.proTryoutGate(), contains('85'));
      final old = person(age: 40)
        ..debugSetSport(LifeSport.soccer, standing: 95);
      expect(old.proTryoutGate(), contains('younger'));
      final ready = person(age: 22)
        ..debugSetSport(LifeSport.soccer, standing: 92);
      expect(ready.proTryoutGate(), isNull);
    });

    test('signing is a job that is not on any board', () {
      final life = person(age: 22, lucky: true)
        ..debugSetSport(LifeSport.soccer, standing: 92);
      expect(life.tryOutForPros(), isTrue);
      expect(life.isProAthlete, isTrue);
      expect(life.job, 'Professional Soccer Player');
      expect(life.salary, 1500);
      expect(life.currentJob!.boardListed, isFalse);
      expect(life.conceptsMet, contains(FinanceConcept.incomeVsWealth));
    });

    test('a miss is described as normal', () {
      final life = person(age: 22)
        ..debugSetSport(LifeSport.soccer, standing: 92);
      life.tryOutForPros(); // unlucky: does not sign
      expect(life.isProAthlete, isFalse);
      expect(feed(life), contains('Another year of training'));
    });

    test('a professional career ends, and it says why it matters to save', () {
      // Signed at 31, the last age the scouts look at, so retirement at 38 is
      // seven seasons away.
      final life = person(age: 31, lucky: true)
        ..debugSetSport(LifeSport.soccer, standing: 95);
      expect(life.tryOutForPros(), isTrue);
      expect(life.isProAthlete, isTrue);
      for (var i = 0; i < 8; i++) {
        year(life);
        life.debugSetStats(health: 85, happiness: 65);
      }
      expect(life.isProAthlete, isFalse);
      expect(life.hasJob, isFalse);
      expect(feed(life), contains('retired from professional sport'));
    });
  });

  group('elected office', () {
    test('needs age, Charisma and a campaign fund, and says which', () {
      expect(person(age: 20).officeGate(), 'You need to be 25');
      expect(person(age: 30).officeGate(), contains('Charisma'));
      final poor = person(age: 30, money: 40)
        ..debugSetSkill(LifeSkill.charisma, 60);
      expect(poor.officeGate(), contains('100'));
    });

    test('the odds follow Charisma', () {
      final low = person(age: 30)..debugSetSkill(LifeSkill.charisma, 30);
      final high = person(age: 30)..debugSetSkill(LifeSkill.charisma, 90);
      expect(high.electionChance, greaterThan(low.electionChance));
    });

    test('winning is a job with a salary that is not on a board', () {
      final life = person(age: 30, lucky: true)
        ..debugSetSkill(LifeSkill.charisma, 60);
      final cash = life.money;
      expect(life.runForOffice(), isTrue);
      expect(life.job, 'City Councillor');
      expect(life.salary, 500);
      expect(life.money, lessThan(cash));
      expect(life.currentJob!.boardListed, isFalse);
    });

    test('losing costs the campaign and is described as normal', () {
      final life = person(age: 30)..debugSetSkill(LifeSkill.charisma, 60);
      final cash = life.money;
      life.runForOffice(); // unlucky: loses
      expect(life.money, cash - 100);
      expect(life.hasJob, isFalse);
      expect(feed(life), contains('Most people who win lost first'));
    });

    test('one campaign a year', () {
      final life = person(age: 30)..debugSetSkill(LifeSkill.charisma, 60);
      life.runForOffice();
      expect(life.officeGate(), 'Done for this year');
    });

    test('a councillor can be promoted up the ladder', () {
      final life = person(age: 30, lucky: true)
        ..debugSetSkill(LifeSkill.charisma, 60);
      life.runForOffice();
      life.debugSetPerformance(80, yearsInRole: 3);
      expect(life.nextPromotion!.title, 'Mayor');
      expect(life.promotionBlocker(), isNull);
    });
  });
}
