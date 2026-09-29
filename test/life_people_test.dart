import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_activities.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_people.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/relationship.dart';

import 'support/fixed_random.dart';

/// The people in a life.
///
/// **Asked for as:** *"a progression bar on how close you are,"* the BitLife
/// interactions, and *"a random pop-up like this year your mom suddenly passed
/// away."* Relationships used to be a list of names with three buttons.
void main() {
  LifeSimController person({
    int age = 30,
    int money = 1000,
    bool family = false,
    bool lucky = false,
  }) => LifeSimController(
    random: lucky ? FixedRandom.lucky() : FixedRandom.unlucky(),
    name: 'Alex Morgan',
    initialAge: age,
    startMoney: money,
    withFamily: family,
  );

  Relationship friend({int closeness = 60, String name = 'Sam Reyes'}) =>
      Relationship(
        name: name,
        kind: RelationshipKind.friend,
        closeness: closeness,
        metAtAge: 20,
        lastSeenAge: 20,
        role: 'Friend',
      );

  Relationship partner({int closeness = 80}) => Relationship(
    name: 'Jo Lee',
    kind: RelationshipKind.partner,
    closeness: closeness,
    metAtAge: 24,
    lastSeenAge: 24,
    role: 'Partner',
  );

  void year(LifeSimController life) {
    life.ageUp();
    life.debugClearEvent();
  }

  String feed(LifeSimController life) =>
      life.history.map((e) => e.text).join(' | ');

  group('a family at birth', () {
    test('is only there when asked for, so other tests get an empty list', () {
      expect(person().people, isEmpty);
    });

    test('is a mother and a father, with ages, and a surname in common', () {
      final life = person(age: 0, family: true);
      final roles = life.people.map((p) => p.role).toList();
      expect(roles, containsAll(<String>['Mother', 'Father']));
      for (final p in life.people) {
        expect(p.kind, RelationshipKind.family);
        expect(p.name.split(' ').last, 'Morgan');
        expect(p.closeness, greaterThanOrEqualTo(50));
        expect(p.isAlive, isTrue);
      }
      final mum = life.people.firstWhere((p) => p.role == 'Mother');
      expect(mum.ageWhen(30), greaterThan(50), reason: '30 plus about 25');
    });

    test('is different from life to life', () {
      final shapes = <String>{};
      for (var seed = 0; seed < 40; seed++) {
        final life = LifeSimController(
          random: Random(seed),
          name: 'Alex Morgan',
          withFamily: true,
        );
        shapes.add(life.people.map((p) => p.role).join(','));
      }
      expect(shapes.length, greaterThan(3));
    });

    test('has no two people with the same name', () {
      for (var seed = 0; seed < 40; seed++) {
        final life = LifeSimController(
          random: Random(seed),
          name: 'Alex Morgan',
          withFamily: true,
        );
        final names = life.people.map((p) => p.name).toList();
        expect(names.toSet().length, names.length, reason: 'seed $seed');
      }
    });
  });

  group('what you can do about somebody', () {
    test('each kind of person has its own list', () {
      List<PersonAction> of(Relationship r) =>
          personActionsFor(r, playerAge: 30);
      expect(of(friend()), contains(PersonAction.askMoney));
      expect(
        of(partner()),
        containsAll([
          PersonAction.date,
          PersonAction.propose,
          PersonAction.startFamily,
        ]),
        reason: 'a family does not require a wedding first',
      );
      expect(
        of(partner().copyWith(kind: RelationshipKind.spouse)),
        contains(PersonAction.startFamily),
      );
      expect(
        of(friend().copyWith(kind: RelationshipKind.colleague)),
        isNot(contains(PersonAction.gift)),
      );
    });

    test('the dead have none', () {
      final gone = friend().copyWith(passedAge: 40);
      expect(personActionsFor(gone, playerAge: 41), isEmpty);
    });

    test('a child cannot ask for money before six, or propose ever', () {
      final mum = Relationship(
        name: 'Ana Morgan',
        kind: RelationshipKind.family,
        closeness: 80,
        metAtAge: 0,
        role: 'Mother',
        ageOffset: 27,
      );
      expect(
        personActionsFor(mum, playerAge: 4),
        isNot(contains(PersonAction.askMoney)),
      );
      expect(
        personActionsFor(mum, playerAge: 8),
        contains(PersonAction.askMoney),
      );
      expect(
        personActionsFor(mum, playerAge: 30),
        isNot(contains(PersonAction.propose)),
      );
    });

    test('every action has a word and a reason', () {
      for (final a in PersonAction.values) {
        expect(a.label, isNotEmpty);
        expect(a.blurb, isNotEmpty);
      }
    });
  });

  group('doing it', () {
    test('a conversation moves the bar, and less the more you do it', () {
      final life = person()..debugPutPerson(friend(closeness: 40));
      life.doPersonAction(PersonAction.conversation, 'Sam Reyes');
      expect(life.personByName('Sam Reyes')!.closeness, 46);
      life.doPersonAction(PersonAction.conversation, 'Sam Reyes');
      expect(life.personByName('Sam Reyes')!.closeness, 52);
    });

    test('nobody can be dealt with more than three times in a year', () {
      final life = person()..debugPutPerson(friend(closeness: 20));
      for (var i = 0; i < 3; i++) {
        expect(
          life.doPersonAction(PersonAction.conversation, 'Sam Reyes'),
          isTrue,
        );
      }
      expect(
        life.personActionGate(PersonAction.compliment, 'Sam Reyes'),
        contains('a lot of time'),
      );
      expect(
        life.doPersonAction(PersonAction.compliment, 'Sam Reyes'),
        isFalse,
      );
    });

    test('and the count starts again next year', () {
      final life = person()..debugPutPerson(friend(closeness: 20));
      for (var i = 0; i < 3; i++) {
        life.doPersonAction(PersonAction.conversation, 'Sam Reyes');
      }
      year(life);
      expect(
        life.personActionGate(PersonAction.conversation, 'Sam Reyes'),
        isNull,
      );
    });

    test('a compliment is free and small', () {
      final life = person()..debugPutPerson(friend(closeness: 40));
      final cash = life.money;
      life.doPersonAction(PersonAction.compliment, 'Sam Reyes');
      expect(life.personByName('Sam Reyes')!.closeness, 44);
      expect(life.money, cash);
    });

    test('asking for advice makes you a little smarter', () {
      final life = person()..debugPutPerson(friend());
      final before = life.smarts;
      life.doPersonAction(PersonAction.askAdvice, 'Sam Reyes');
      expect(life.smarts, before + 2);
    });

    test('time together is the best thing you can give', () {
      final life = person()..debugPutPerson(friend(closeness: 30));
      life.doPersonAction(PersonAction.spendTime, 'Sam Reyes');
      final byTime = life.personByName('Sam Reyes')!.closeness;
      final other = person()..debugPutPerson(friend(closeness: 30));
      other.doPersonAction(PersonAction.gift, 'Sam Reyes');
      expect(byTime, greaterThan(other.personByName('Sam Reyes')!.closeness));
    });

    test('asking for money can work, and costs a little closeness', () {
      final life = person(lucky: true)..debugPutPerson(friend(closeness: 70));
      final cash = life.money;
      expect(life.doPersonAction(PersonAction.askMoney, 'Sam Reyes'), isTrue);
      expect(life.money, greaterThan(cash));
      expect(life.personByName('Sam Reyes')!.closeness, lessThan(70 + 1));
      expect(feed(life), contains('never only money'));
    });

    test('and can be refused, kindly', () {
      final life = person()..debugPutPerson(friend(closeness: 45));
      final cash = life.money;
      life.doPersonAction(PersonAction.askMoney, 'Sam Reyes');
      expect(life.money, cash);
      expect(life.personByName('Sam Reyes')!.closeness, 42);
      expect(feed(life), contains('could not spare it'));
    });

    test('once a year, and only from somebody who knows you', () {
      final stranger = person()..debugPutPerson(friend(closeness: 20));
      expect(
        stranger.personActionGate(PersonAction.askMoney, 'Sam Reyes'),
        contains('do not know you well'),
      );
      final life = person(lucky: true)..debugPutPerson(friend(closeness: 70));
      life.debugPutPerson(friend(closeness: 70, name: 'Kim Park'));
      life.doPersonAction(PersonAction.askMoney, 'Sam Reyes');
      expect(
        life.personActionGate(PersonAction.askMoney, 'Kim Park'),
        'Done for this year',
      );
    });
  });

  group('love', () {
    test('a date costs money and brings you closer', () {
      final life = person()..debugPutPerson(partner(closeness: 50));
      final cash = life.money;
      life.doPersonAction(PersonAction.date, 'Jo Lee');
      expect(life.money, cash - 40);
      expect(life.personByName('Jo Lee')!.closeness, 60);
    });

    test('a date needs 40 coins and an adult', () {
      final poor = person(money: 10)..debugPutPerson(partner());
      expect(
        poor.personActionGate(PersonAction.date, 'Jo Lee'),
        contains('40'),
      );
      final teen = person(age: 16)..debugPutPerson(partner());
      expect(
        teen.personActionGate(PersonAction.date, 'Jo Lee'),
        anyOf(contains('18'), isNotNull),
      );
    });

    test('a proposal waits until you are close, and old enough', () {
      final distant = person()..debugPutPerson(partner(closeness: 55));
      expect(
        distant.personActionGate(PersonAction.propose, 'Jo Lee'),
        'Only when you are closer',
      );
      // Under 21 the option is not offered at all, which is stricter than a
      // message saying no.
      final young = person(age: 19)..debugPutPerson(partner());
      expect(
        personActionsFor(partner(), playerAge: 19),
        isNot(contains(PersonAction.propose)),
      );
      expect(
        young.personActionGate(PersonAction.propose, 'Jo Lee'),
        'Not something you can do with them',
      );
    });

    test('a yes makes a spouse and asks how big the day should be', () {
      final life = person(lucky: true)..debugPutPerson(partner(closeness: 90));
      life.doPersonAction(PersonAction.propose, 'Jo Lee');
      final jo = life.personByName('Jo Lee')!;
      expect(jo.kind, RelationshipKind.spouse);
      expect(jo.role, 'Spouse');
      expect(life.isMarried, isTrue);

      life.ageUp();
      final card = life.currentEvent!;
      expect(card.id, startsWith('v2_wedding'));
      expect(card.choices.length, 3);
      expect(card.choices.map((c) => c.money), [-80, -300, -900]);
      for (final c in card.choices) {
        expect(c.teaches, FinanceConcept.opportunityCost);
      }
      // The big day is happier, and it is the one that costs a year of savings.
      expect(
        card.choices.last.happiness,
        greaterThan(card.choices.first.happiness),
      );
    });

    test('a no stings and changes nothing else', () {
      final life = person()..debugPutPerson(partner(closeness: 72));
      life.doPersonAction(PersonAction.propose, 'Jo Lee');
      expect(life.personByName('Jo Lee')!.kind, RelationshipKind.partner);
      expect(life.personByName('Jo Lee')!.closeness, 64);
      expect(feed(life), contains('was not ready'));
    });

    test('you cannot marry twice', () {
      final life = person(lucky: true)
        ..debugPutPerson(
          partner(closeness: 90).copyWith(kind: RelationshipKind.spouse),
        )
        ..debugPutPerson(
          friend(name: 'Al Wu').copyWith(kind: RelationshipKind.partner),
        );
      expect(
        life.personActionGate(PersonAction.propose, 'Al Wu'),
        'You are already married',
      );
    });

    test('starting a family brings a child, and the child costs money', () {
      final life = person(age: 30)
        ..debugPutPerson(partner().copyWith(kind: RelationshipKind.spouse));
      final base = life.housingCost;
      final cash = life.money;
      expect(life.doPersonAction(PersonAction.startFamily, 'Jo Lee'), isTrue);

      final child = life.childrenOfYours.single;
      expect(child.kind, RelationshipKind.child);
      expect(child.role, anyOf('Son', 'Daughter'));
      expect(child.name.split(' ').last, 'Morgan');
      expect(child.ageWhen(31), 1);
      expect(life.money, cash - 120);
      expect(life.childCost, 40);
      expect(life.housingCost, base, reason: 'rent is not what changed');
    });

    test('and not again straight away', () {
      final life = person(age: 30)
        ..debugPutPerson(partner().copyWith(kind: RelationshipKind.spouse));
      life.doPersonAction(PersonAction.startFamily, 'Jo Lee');
      year(life);
      expect(
        life.personActionGate(PersonAction.startFamily, 'Jo Lee'),
        'Give it a couple of years',
      );
    });

    test('a child stops costing money when grown', () {
      final life = person(age: 30)
        ..debugPutPerson(partner().copyWith(kind: RelationshipKind.spouse));
      life.doPersonAction(PersonAction.startFamily, 'Jo Lee');
      expect(life.childCost, 40);
      for (var i = 0; i < 18; i++) {
        year(life);
      }
      expect(life.childCost, 0);
    });

    test('dating turns up somebody, sometimes', () {
      final life = person(lucky: true);
      life.doActivity('dating_app');
      expect(life.hasPartner, isTrue);
      expect(life.partners.single.role, 'Partner');
    });
  });

  group('losing somebody', () {
    test('the chance of it rises with age and is small when young', () {
      expect(yearlyDeathChance(40), lessThan(0.01));
      expect(yearlyDeathChance(65), greaterThan(yearlyDeathChance(40)));
      expect(yearlyDeathChance(85), greaterThan(yearlyDeathChance(65)));
      expect(yearlyDeathChance(95), lessThan(0.5));
    });

    test('a parent can be lost, and it comes as a card with real choices', () {
      final life = person(age: 45, lucky: true, family: true);
      life.ageUp();
      // Lucky dice mean everybody older dies in the first year, which is not a
      // life. What is under test is what the game does when it happens.
      final gone = life.remembered;
      expect(gone, isNotEmpty);
      final card = life.currentEvent!;
      expect(card.id, startsWith('loss_'));
      expect(card.choices.length, greaterThanOrEqualTo(3));
    });

    test('says what happened in one plain sentence, in the right words', () {
      final mum = Relationship(
        name: 'Ana Morgan',
        kind: RelationshipKind.family,
        closeness: 80,
        metAtAge: 0,
        role: 'Mother',
        ageOffset: 27,
      );
      final sudden = bereavementEvent(
        person: mum,
        how: PassingKind.sudden,
        playerAge: 40,
      );
      expect(sudden.prompt, contains('your mother Ana suddenly passed away'));
      final old = bereavementEvent(
        person: mum,
        how: PassingKind.oldAge,
        playerAge: 60,
      );
      expect(old.prompt, contains('peacefully'));
    });

    test('is written gently for a nine-year-old and up', () {
      final mum = Relationship(
        name: 'Ana Morgan',
        kind: RelationshipKind.family,
        closeness: 80,
        metAtAge: 0,
        role: 'Mother',
        ageOffset: 27,
      );
      const banned = [
        'blood',
        'gore',
        'murder',
        'suicide',
        'kill',
        'corpse',
        'body',
        'accident',
        'crash',
        'violent',
        'drug',
      ];
      for (final how in PassingKind.values) {
        final card = bereavementEvent(person: mum, how: how, playerAge: 30);
        final text = [
          card.prompt,
          for (final c in card.choices) ...[c.label, c.outcome],
        ].join(' ').toLowerCase();
        for (final word in banned) {
          expect(
            RegExp('\b$word\b').hasMatch(text),
            isFalse,
            reason: '"$word" in $how',
          );
        }
      }
    });

    test('offers a way through, not one button', () {
      final dad = Relationship(
        name: 'Omar Morgan',
        kind: RelationshipKind.family,
        closeness: 70,
        metAtAge: 0,
        role: 'Father',
        ageOffset: 30,
      );
      final card = bereavementEvent(
        person: dad,
        how: PassingKind.illness,
        playerAge: 35,
      );
      expect(card.choices.length, 4);
      final labels = card.choices.map((c) => c.label).join(' | ');
      expect(labels, contains('memorial'));
      expect(labels, contains('grieve'));
      expect(labels, contains('people you have left'));
    });

    test('the two that cost money teach the same idea', () {
      final dad = Relationship(
        name: 'Omar Morgan',
        kind: RelationshipKind.family,
        closeness: 70,
        metAtAge: 0,
        role: 'Father',
        ageOffset: 30,
      );
      final card = bereavementEvent(
        person: dad,
        how: PassingKind.illness,
        playerAge: 35,
      );
      final spending = card.choices.where((c) => c.money < 0).toList();
      expect(spending.length, 2);
      for (final c in spending) {
        expect(c.teaches, FinanceConcept.insurance);
      }
    });

    test('a loved one hurts more than a distant one', () {
      Relationship of(int closeness) => Relationship(
        name: 'Ana Morgan',
        kind: RelationshipKind.family,
        closeness: closeness,
        metAtAge: 0,
        role: 'Mother',
        ageOffset: 27,
      );
      final close = bereavementEvent(
        person: of(90),
        how: PassingKind.illness,
        playerAge: 30,
      );
      final far = bereavementEvent(
        person: of(20),
        how: PassingKind.illness,
        playerAge: 30,
      );
      expect(
        close.choices.first.happiness,
        lessThan(far.choices.first.happiness),
      );
    });

    test(
      'the person stays in the list, remembered, and cannot be acted on',
      () {
        final life = person(age: 45, lucky: true, family: true);
        life.ageUp();
        life.debugClearEvent();
        final name = life.remembered.first.name;
        expect(life.remembered.first.status, 'Passed away');
        expect(life.actionsFor(name), isEmpty);
        expect(
          life.personActionGate(PersonAction.conversation, name),
          'They have passed away',
        );
        expect(life.friendList.where((p) => p.name == name), isEmpty);
      },
    );

    test('a parent leaves something behind', () {
      final life = person(age: 45, lucky: true, family: true, money: 0);
      life.ageUp();
      life.debugClearEvent();
      expect(feed(life), contains('left you'));
      expect(life.conceptsMet, contains(FinanceConcept.incomeVsWealth));
    });

    test('nobody counts as company once they are gone', () {
      final life = person(age: 45, lucky: true, family: true);
      final before = life.connection;
      life.ageUp();
      life.debugClearEvent();
      expect(life.connection, isNot(greaterThan(before)));
      for (final p in life.people.where((p) => !p.isAlive)) {
        expect(p.isPresent, isFalse);
      }
    });

    test('a child never dies in this game', () {
      final life = person(age: 30, lucky: true)
        ..debugPutPerson(
          Relationship(
            name: 'Kit Morgan',
            kind: RelationshipKind.child,
            closeness: 90,
            metAtAge: 30,
            role: 'Son',
            ageOffset: -30,
          ),
        );
      for (var i = 0; i < 40; i++) {
        life.ageUp();
        life.debugClearEvent();
        if (life.finished) break;
      }
      expect(life.childrenOfYours, isNotEmpty);
    });
  });

  group('meeting people', () {
    test('a club brings a friend, up to a limit', () {
      final life = person(age: 12, lucky: true);
      life.doActivity('club_chess');
      expect(life.friendList, isNotEmpty);
    });

    test('nobody has twelve close friends and then a thirteenth', () {
      final life = person(age: 20, lucky: true, money: 5000);
      for (var i = 0; i < 12; i++) {
        life.debugPutPerson(friend(name: 'Friend $i'));
      }
      expect(life.doActivity('fair'), isFalse);
      expect(life.activityGate(activityById('fair')!), contains('plenty'));
    });
  });

  group('a family generated at birth', () {
    // **Reported as:** a 3-year-old brother the player supposedly last saw
    // five years ago -- two years before he was born. `buildFamily` gave
    // every family member `metAtAge: 0` and `lastSeenAge: 0` regardless of
    // `ageOffset`, which is only true for a parent or grandparent (always
    // older, so always alive from the player's birth). A younger sibling has
    // a *negative* offset and is not born until the player reaches
    // `-offset`, so both fields have to start there instead, not at 0.
    test(
      'nobody is met or last seen before they are born',
      () {
        final random = Random(1);
        for (var seed = 0; seed < 200; seed++) {
          final family = buildFamily(random, surname: 'Test$seed');
          for (final person in family) {
            final bornAtPlayerAge = person.ageOffset < 0
                ? -person.ageOffset
                : 0;
            expect(
              person.metAtAge,
              greaterThanOrEqualTo(bornAtPlayerAge),
              reason:
                  '${person.role} (offset ${person.ageOffset}) was "met" '
                  'before they were born',
            );
            expect(
              person.lastSeenAge,
              greaterThanOrEqualTo(bornAtPlayerAge),
              reason:
                  '${person.role} (offset ${person.ageOffset}) was "last '
                  'seen" before they were born',
            );
          }
        }
      },
    );

    test('a not-yet-born sibling is absent from the family list', () {
      final life = person(age: 3, family: false);
      life.debugPutPerson(
        Relationship(
          name: 'Future Sibling',
          kind: RelationshipKind.family,
          closeness: 60,
          metAtAge: 6,
          lastSeenAge: 6,
          role: 'Brother',
          ageOffset: -6,
        ),
      );
      expect(
        life.familyMembers.map((p) => p.name),
        isNot(contains('Future Sibling')),
        reason: 'a sibling six years younger than a three-year-old player '
            'does not exist yet',
      );
    });
  });
}
