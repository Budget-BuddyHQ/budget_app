import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_network.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/relationship.dart';

import 'support/fixed_random.dart';

/// Who you know is part of how you earn.
///
/// **Asked for as:** *"for the people, make connections and networking a
/// thing."* People were a list of names whose only job was to be close or
/// drift. This adds the part of working life a teenager cannot see from where
/// they stand: most work is found through somebody who knows somebody, and a
/// raise is far easier when a person other than you has said your name.
///
/// These hold the maths, the loop (meet, keep warm, get a lead), and the one
/// thing that must not happen: contacts are not friends, and a long list of
/// them must not make a lonely life look sociable.
void main() {
  Relationship contact(String name, {int closeness = 60}) => Relationship(
    name: name,
    kind: RelationshipKind.colleague,
    closeness: closeness,
    metAtAge: 20,
  );

  LifeSimController adult({
    Random? random,
    int money = 1000,
    bool employed = true,
  }) {
    return LifeSimController(
      random: random ?? FixedRandom.unlucky(),
      name: 'Tester',
      gender: Gender.nonBinary,
      origin: LifeOrigin.workingClass,
      initialAge: 30,
      startMoney: money,
      startJob: employed ? 'Barista' : null,
      startSalary: employed ? 500 : 0,
    );
  }

  String feed(LifeSimController life) =>
      life.history.map((entry) => entry.text).join(' | ');

  group('the maths', () {
    test('a contact is worth up to 25 points, by how warm they are', () {
      expect(contactPoints(contact('A', closeness: 100)), 25);
      expect(contactPoints(contact('A', closeness: 60)), 15);
      expect(contactPoints(contact('A', closeness: 14)), 0, reason: 'faded');
    });

    test('a friend is not a contact', () {
      final friend = Relationship(
        name: 'Sam',
        kind: RelationshipKind.friend,
        closeness: 100,
        metAtAge: 10,
      );
      expect(contactPoints(friend), 0);
      expect(RelationshipKind.friend.isProfessional, isFalse);
      expect(RelationshipKind.family.isProfessional, isFalse);
      expect(RelationshipKind.colleague.isProfessional, isTrue);
      expect(RelationshipKind.mentor.isProfessional, isTrue);
    });

    test('four close contacts is a full network', () {
      final reading = readNetwork([
        for (var i = 0; i < 4; i++) contact('C$i', closeness: 100),
      ]);
      expect(reading.strength, 100);
      expect(reading.contacts, 4);
      expect(reading.label, 'Strong');
    });

    test('strength never goes past 100', () {
      final reading = readNetwork([
        for (var i = 0; i < 12; i++) contact('C$i', closeness: 100),
      ]);
      expect(reading.strength, 100);
    });

    test('the word matches the number', () {
      String word(int count, int closeness) => readNetwork([
        for (var i = 0; i < count; i++) contact('C$i', closeness: closeness),
      ]).label;
      expect(word(0, 100), 'None yet');
      expect(word(1, 60), 'Thin');
      expect(word(2, 60), 'Growing');
      expect(word(3, 70), 'Solid');
      expect(word(4, 100), 'Strong');
    });

    test('luck alone is a small chance, and a full network a big one', () {
      const none = NetworkReading(contacts: 0, strength: 0);
      const full = NetworkReading(contacts: 4, strength: 100);
      expect(none.referralChance, closeTo(0.03, 1e-9));
      expect(full.referralChance, closeTo(0.31, 1e-9));
      expect(full.referralChance, greaterThan(none.referralChance * 5));
    });

    test('a new name is never one already taken', () {
      final random = Random(1);
      final taken = <String>{};
      for (var i = 0; i < 200; i++) {
        final name = freshContactName(random, taken);
        expect(taken.contains(name), isFalse, reason: '$name came up twice');
        taken.add(name);
      }
    });

    test('the name generator cannot loop or throw when the space is full', () {
      final everyone = <String>{
        for (final first in kContactFirstNames)
          for (final last in kContactLastNames) '$first $last',
      };
      expect(everyone.length, kContactFirstNames.length * 24);
      final name = freshContactName(Random(2), everyone);
      expect(name, isNotEmpty);
      expect(everyone.contains(name), isFalse);
    });

    test('with a job a lead is a raise or a gig; without, it is a job', () {
      final random = Random(4);
      for (var i = 0; i < 50; i++) {
        expect(
          pickReferralKind(hasJob: false, random: random),
          ReferralKind.jobLead,
        );
        expect(
          pickReferralKind(hasJob: true, random: random),
          isNot(ReferralKind.jobLead),
        );
      }
    });
  });

  group('meeting people', () {
    test('a networking event can add a contact', () {
      final life = adult(random: FixedRandom.lucky());
      life.attendNetworkingEvent();
      expect(life.contacts, hasLength(1));
      expect(life.contactsMade, 1);
      expect(life.money, 975, reason: 'a ticket costs 25');
      expect(feed(life), contains('New contact'));
    });

    test('sometimes it does not work, and it says so', () {
      final life = adult(random: FixedRandom.unlucky());
      life.attendNetworkingEvent();
      expect(life.contacts, isEmpty);
      expect(life.money, 975, reason: 'you still went');
      expect(feed(life), contains('nobody new'));
    });

    test('there is not an event every evening', () {
      final life = adult(random: FixedRandom.lucky());
      for (var i = 0; i < 10; i++) {
        life.attendNetworkingEvent();
      }
      expect(life.contactsMade, 2, reason: 'two a year');
    });

    test('nobody under 16 goes to one', () {
      final teen = LifeSimController(
        random: FixedRandom.lucky(),
        initialAge: 15,
      );
      expect(teen.allows(LifeAction.network), isFalse);
      teen.attendNetworkingEvent();
      expect(teen.contacts, isEmpty);
    });

    test('it costs nothing to a teenager the family pays for', () {
      final teen = LifeSimController(
        random: FixedRandom.lucky(),
        initialAge: 16,
        startMoney: 0,
      );
      teen.attendNetworkingEvent();
      expect(teen.contacts, hasLength(1));
      expect(teen.money, 0);
    });

    test('you cannot afford it without the coins', () {
      final life = adult(money: 10);
      life.attendNetworkingEvent();
      expect(life.money, 10);
      expect(life.contacts, isEmpty);
      expect(feed(life), contains('Not enough coins'));
    });
  });

  group('contacts are not friends', () {
    test('they do not make a lonely life look sociable', () {
      // The loneliness endings read `connection`. Four contacts and no friend
      // must still read as nobody there.
      final life = adult();
      life.debugAddPerson('A', kind: RelationshipKind.colleague);
      life.debugAddPerson('B', kind: RelationshipKind.colleague);
      life.debugAddPerson('C', kind: RelationshipKind.colleague);
      expect(life.connection, 0);
      expect(life.relationships, isEmpty);

      life.debugAddPerson('Sam', kind: RelationshipKind.friend, closeness: 70);
      expect(life.connection, 70);
      expect(life.relationships, ['Sam']);
    });

    test('only contacts is not company', () {
      // Same year, same everything, one difference: whether a real friend is
      // still around. With only contacts and a friend who has faded, the year
      // is lonelier, and a list of colleagues does not change that.
      LifeSimController withFriend({required int closeness}) {
        final life = adult();
        life.debugAddPerson('A', kind: RelationshipKind.colleague);
        life.debugAddPerson(
          'Sam',
          kind: RelationshipKind.friend,
          closeness: closeness,
        );
        life.ageUp();
        return life;
      }

      final company = withFriend(closeness: 70);
      final alone = withFriend(closeness: 5);
      expect(
        company.happiness - alone.happiness,
        2,
        reason: 'contacts covered for a friend who was gone',
      );
    });

    test('they still show up in the People list, with the right label', () {
      final life = adult();
      life.debugAddPerson('Dana', kind: RelationshipKind.colleague);
      expect(life.people.single.kind.label, 'Contact');
    });
  });

  group('keeping it warm', () {
    test('contacts fade faster than family', () {
      final life = adult();
      life.debugAddPerson('Colleague', kind: RelationshipKind.colleague);
      life.debugAddPerson('Mum', kind: RelationshipKind.family);
      life.ageUp();
      int closeness(String name) =>
          life.people.firstWhere((p) => p.name == name).closeness;
      expect(closeness('Colleague'), lessThan(closeness('Mum')));
    });

    test('coffee brings a contact back up', () {
      final life = adult();
      life.debugAddPerson(
        'Dana',
        kind: RelationshipKind.colleague,
        closeness: 40,
      );
      life.coffeeWith('Dana');
      expect(life.people.single.closeness, 52);
      expect(life.money, 990, reason: 'coffee costs 10');
    });

    test('coffee only works on a contact', () {
      final life = adult();
      life.debugAddPerson('Sam', kind: RelationshipKind.friend, closeness: 40);
      life.coffeeWith('Sam');
      expect(life.people.single.closeness, 40);
      expect(life.money, 1000);
    });

    test('coffee shares the evening budget with events', () {
      final life = adult(random: FixedRandom.lucky());
      life.debugAddPerson('Dana', kind: RelationshipKind.colleague);
      life.attendNetworkingEvent();
      life.coffeeWith('Dana');
      final closeness = life.people
          .firstWhere((p) => p.name == 'Dana')
          .closeness;
      life.coffeeWith('Dana');
      expect(
        life.people.firstWhere((p) => p.name == 'Dana').closeness,
        closeness,
        reason: 'a third evening in one year was free',
      );
    });
  });

  group('a lead', () {
    test('with no job, a contact gets you one', () {
      final life = adult(random: FixedRandom.lucky(), employed: false);
      life.debugAddPerson(
        'Dana Whitfield',
        kind: RelationshipKind.colleague,
        closeness: 90,
      );
      expect(life.hasJob, isFalse);
      life.ageUp();
      expect(life.hasJob, isTrue);
      expect(life.referrals, 1);
      expect(feed(life), contains('Dana Whitfield put your name forward'));
    });

    test('with a job, it is a raise or a one-off gig', () {
      final life = adult(random: FixedRandom.lucky());
      life.debugAddPerson(
        'Dana Whitfield',
        kind: RelationshipKind.colleague,
        closeness: 90,
      );
      final salary = life.salary;
      life.ageUp();
      expect(life.referrals, 1);
      // A share of pay, like every other raise: 3% on the lucky roll. It was a
      // flat 150, which was a raise of up to 145% on an entry-level salary.
      expect(
        life.salary,
        salary + (salary * 3 / 100).round(),
        reason: 'a good word to the manager',
      );
      expect(feed(life), contains('Dana Whitfield mentioned you'));
    });

    test('the warmest contact is the one who vouches', () {
      final life = adult(random: FixedRandom.lucky(), employed: false);
      life.debugAddPerson(
        'Cold Contact',
        kind: RelationshipKind.colleague,
        closeness: 30,
      );
      life.debugAddPerson(
        'Warm Contact',
        kind: RelationshipKind.colleague,
        closeness: 95,
      );
      life.ageUp();
      expect(feed(life), contains('Warm Contact put your name forward'));
    });

    test('a lead from somebody is better than a form', () {
      // The best of four rolls against the best of two.
      var referredTotal = 0;
      var appliedTotal = 0;
      for (var seed = 0; seed < 80; seed++) {
        final referred = LifeSimController(random: Random(seed), initialAge: 30)
          ..debugSetStats(smarts: 80);
        referred.findJob(referredBy: 'Dana');
        referredTotal += referred.salary;

        final applied = LifeSimController(random: Random(seed), initialAge: 30)
          ..debugSetStats(smarts: 80);
        applied.findJob();
        appliedTotal += applied.salary;
      }
      expect(referredTotal, greaterThan(appliedTotal));
    });

    test('no contacts, no leads, however long the life', () {
      final life = adult(random: Random(9));
      for (var i = 0; i < 25; i++) {
        life.ageUp();
        if (life.currentEvent != null) life.chooseOption(0);
      }
      expect(life.referrals, 0);
    });

    test('nobody under 16 gets one', () {
      final child = LifeSimController(
        random: FixedRandom.lucky(),
        initialAge: 12,
      );
      child.debugAddPerson('Dana', kind: RelationshipKind.colleague);
      child.ageUp();
      expect(child.referrals, 0);
    });
  });

  group('asking for a raise is easier with somebody behind you', () {
    test('a strong network never hurts the odds, and sometimes wins one', () {
      var alone = 0;
      var backed = 0;
      for (var seed = 0; seed < 400; seed++) {
        final solo = LifeSimController(
          random: Random(seed),
          initialAge: 30,
          startJob: 'Barista',
          startSalary: 500,
        );
        solo.askForRaise();
        if (solo.salary > 500) alone++;

        final network = LifeSimController(
          random: Random(seed),
          initialAge: 30,
          startJob: 'Barista',
          startSalary: 500,
        );
        for (var i = 0; i < 4; i++) {
          network.debugAddPerson(
            'Contact $i',
            kind: RelationshipKind.colleague,
            closeness: 100,
          );
        }
        network.askForRaise();
        if (network.salary > 500) backed++;
      }
      expect(backed, greaterThan(alone));
    });
  });

  group('the town', () {
    test('talking to somebody makes them a contact', () {
      final life = adult();
      final line = life.meetTownContact('Shift Worker');
      expect(line, contains('one of your contacts'));
      expect(life.contacts.single.name, 'Shift Worker');
      expect(life.contactsMade, 1);
    });

    test('talking again the same year does not warm them twice', () {
      final life = adult();
      life.meetTownContact('Shift Worker');
      final closeness = life.contacts.single.closeness;
      expect(life.meetTownContact('Shift Worker'), isNull);
      expect(life.contacts.single.closeness, closeness);
    });

    test('but next year it does', () {
      final life = adult();
      life.meetTownContact('Shift Worker');
      life.ageUp();
      if (life.currentEvent != null) life.chooseOption(0);
      final before = life.contacts.single.closeness;
      final line = life.meetTownContact('Shift Worker');
      expect(line, contains('remembered you'));
      expect(life.contacts.single.closeness, before + 8);
    });

    test('a child is not signing up contacts', () {
      final child = LifeSimController(
        random: FixedRandom.unlucky(),
        initialAge: 10,
      );
      expect(child.meetTownContact('Shift Worker'), isNull);
      expect(child.people, isEmpty);
    });

    test('it does not turn a friend into a contact', () {
      final life = adult();
      life.debugAddPerson('Shopper', kind: RelationshipKind.friend);
      expect(life.meetTownContact('Shopper'), isNull);
      expect(life.people.single.kind, RelationshipKind.friend);
    });
  });
}
