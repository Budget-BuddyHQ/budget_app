import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/relationship.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixed_random.dart';

/// A card never talks about something the life does not have.
///
/// **Reported as:** *"a life event will ask you to give a sibling something
/// while you don't have a sibling"*, and *"the life event will just conflict
/// with what you have."* The cards were written as if every life had a
/// brother, a car, a landlord, a boss and a mortgage. These pin the gates that
/// make each one only appear when it is true, and the choices that used to
/// invent people ("Your sibling", "Partner", a person called "Dog").
void main() {
  LifeContext ctx({
    int age = 30,
    int money = 5000,
    bool hasJob = true,
    bool hasSibling = false,
    bool hasPartner = false,
    bool hasChild = false,
    bool hasLivingParent = false,
    bool renting = false,
    int mortgage = 0,
    Set<LifeFlag> flags = const <LifeFlag>{},
    Set<AssetKind> owns = const <AssetKind>{},
  }) => LifeContext(
    age: age,
    money: money,
    happiness: 60,
    health: 80,
    smarts: 60,
    fame: 0,
    skills: const {},
    traits: const {},
    hasJob: hasJob,
    hasSibling: hasSibling,
    hasPartner: hasPartner,
    hasChild: hasChild,
    hasLivingParent: hasLivingParent,
    renting: renting,
    mortgage: mortgage,
    flags: flags,
    owns: owns,
  );

  LifeEvent event(String id) => kLifeEvents.firstWhere((e) => e.id == id);

  String said(LifeEvent e) =>
      [e.prompt, for (final c in e.choices) c.label].join(' ').toLowerCase();

  group('what a card talks about, the life has', () {
    // Each rule: words in the prompt or a choice, and the gates any one of
    // which makes them true. A new card that names a sibling without
    // `requiresSibling` fails here, with its id.
    final rules = <String, (RegExp, bool Function(LifeEvent))>{
      'sibling': (
        RegExp(r'\b(sibling|siblings|brother|sister)\b'),
        (e) => e.requiresSibling,
      ),
      'partner': (
        RegExp(
          r'\byour (partner|spouse|wife|husband)\b|\bsomeone you have been seeing\b',
        ),
        (e) => e.requiresPartner,
      ),
      'child': (
        RegExp(r'\byour (child|kid|son|daughter|children|kids)\b'),
        (e) => e.requiresChild,
      ),
      'parent': (
        RegExp(r'\b(a parent is|your parents|your mom|your dad|your mum)\b'),
        (e) => e.requiresParent || e.maxAge <= 12,
      ),
      'car': (
        RegExp(r'\byour car\b|\bthe car needs\b'),
        (e) =>
            e.requiresFlag == LifeFlag.hasCar ||
            e.requiresAsset == AssetKind.vehicle,
      ),
      'landlord': (
        RegExp(r'\b(landlord|your rent)\b'),
        (e) => e.requiresRenting || e.requiresFlag == LifeFlag.rentsWithFriend,
      ),
      'mortgage': (
        RegExp(r'\bthe mortgage\b|\bthe roof\b'),
        (e) =>
            e.requiresMortgage ||
            e.requiresAsset == AssetKind.home ||
            e.forbidsAsset == AssetKind.home,
      ),
      'work': (
        RegExp(
          r'\b(your boss|your manager|a coworker|colleague|at work|work offers'
          r'|retire now)\b',
        ),
        (e) =>
            e.requiresJob ||
            e.requiresTrack != null ||
            e.requiresFlag != null ||
            e.requiresStudent,
      ),
      'school': (
        RegExp(
          r'\b(your school(?! days)|your teacher|a classmate|your class)\b',
        ),
        (e) => e.requiresStudent || e.maxAge <= 19,
      ),
    };

    for (final MapEntry(key: name, value: (words, gated)) in rules.entries) {
      test('a card that mentions $name only comes when there is one', () {
        final loose = [
          for (final e in kLifeEvents)
            if (words.hasMatch(said(e)) && !gated(e)) e.id,
        ];
        expect(loose, isEmpty, reason: loose.join(', '));
      });
    }
  });

  group('the gates', () {
    test('no sibling, no sibling loan', () {
      final e = event('f_sibling_loan');
      expect(e.matches(ctx()), isFalse);
      expect(e.matches(ctx(hasSibling: true)), isTrue);
    });

    test('a first crush is not offered to somebody already taken', () {
      final e = event('first_crush');
      expect(e.matches(ctx(age: 14)), isTrue);
      expect(e.matches(ctx(age: 14, hasPartner: true)), isFalse);
    });

    test('"you are becoming a parent" is the first child only', () {
      final e = event('first_child');
      expect(e.matches(ctx()), isTrue);
      expect(e.matches(ctx(hasChild: true)), isFalse);
    });

    test('moving in together needs somebody to move in with, and rent', () {
      final e = event('x_moving_in');
      expect(e.matches(ctx(renting: true)), isFalse);
      expect(e.matches(ctx(hasPartner: true)), isFalse);
      expect(e.matches(ctx(hasPartner: true, renting: true)), isTrue);
    });

    test('a car repair needs a car', () {
      for (final id in ['car_repair', 'x_car_dies']) {
        expect(event(id).matches(ctx()), isFalse, reason: id);
        expect(
          event(id).matches(ctx(flags: {LifeFlag.hasCar})),
          isTrue,
          reason: id,
        );
      }
      // And nobody is offered their first car while they own one.
      expect(
        event('chain_car_buy').matches(ctx(flags: {LifeFlag.hasCar})),
        isFalse,
      );
    });

    test('a mortgage offer is not made to somebody who owns a home', () {
      for (final id in ['mortgage_offer', 'a_mortgage_or_rent']) {
        expect(
          event(id).matches(ctx(renting: true, owns: {AssetKind.home})),
          isFalse,
          reason: id,
        );
      }
    });

    test('clearing the mortgage needs a mortgage and the cash for it', () {
      final e = event('pay_off_mortgage');
      expect(e.matches(ctx(age: 45)), isFalse);
      expect(e.matches(ctx(age: 45, mortgage: 900, money: 500)), isFalse);
      expect(e.matches(ctx(age: 45, mortgage: 900, money: 1000)), isTrue);
    });

    test('a scam pretending to be your school needs a school', () {
      final e = event('t_gift_card_scam');
      expect(e.matches(ctx(age: 40)), isFalse);
    });
  });

  group('nobody is invented', () {
    test('no choice adds a placeholder person', () {
      // `addRelationship` names a friend. These names were standing in for
      // family, a partner or a pet, and became friends called that.
      const placeholders = {
        'partner',
        'your child',
        'your grandchild',
        'your sibling',
        'dog',
        'cat',
      };
      final fake = [
        for (final e in kLifeEvents)
          for (final c in e.choices)
            if (placeholders.contains(c.addRelationship?.toLowerCase()))
              '${e.id}: ${c.addRelationship}',
      ];
      expect(fake, isEmpty, reason: fake.join('\n'));
    });

    LifeSimController life({int age = 30}) => LifeSimController(
      random: FixedRandom.unlucky(),
      name: 'Tester',
      initialAge: age,
      startMoney: 5000,
      startJob: 'Baker',
      startSalary: 300,
    );

    void play(LifeSimController l, String id, String label) {
      final e = event(id);
      l.debugSetEvent(e);
      l.chooseOption(e.choices.indexWhere((c) => c.label.startsWith(label)));
    }

    test('becoming a parent gives you a real child', () {
      final l = life();
      expect(l.context.hasChild, isFalse);
      play(l, 'first_child', 'Start a savings account');
      final kids = l.people.where((p) => p.kind == RelationshipKind.child);
      expect(kids, hasLength(1));
      expect(kids.single.name, isNot('Your child'));
      expect(l.context.hasChild, isTrue);
    });

    test('a first crush gives you a real partner', () {
      final l = life(age: 15);
      play(l, 'first_crush', 'Tell them');
      expect(l.context.hasPartner, isTrue);
      expect(l.people.map((p) => p.name), isNot(contains('Partner')));
    });

    test('a grandchild is a newborn, not somebody your age', () {
      final l = life(age: 60);
      play(l, 'grandchild', 'Open a long-term account');
      final g = l.people.where(
        (p) => p.role.startsWith('Grand') && p.metAtAge == 60,
      );
      expect(g, hasLength(1));
      expect(g.single.ageWhen(60), 0);
    });

    test('begging for a dog gives you a dog, not a person', () {
      final l = life(age: 9);
      play(l, 'pet', 'Beg for a dog');
      expect(l.flags, contains(LifeFlag.hasPet));
      expect(l.people.map((p) => p.name), isNot(contains('Dog')));
    });

    test(
      'buying through the mortgage offer gives you the home and the loan',
      () {
        final l = life();
        play(l, 'mortgage_offer', 'Buy within your means');
        expect(l.flags, contains(LifeFlag.ownsHome));
        expect(l.context.mortgage, greaterThan(0));
      },
    );

    test('clearing the mortgage clears what is actually owed', () {
      final l = life(age: 45);
      play(l, 'a_mortgage_or_rent', 'Buy');
      final owed = l.context.mortgage;
      expect(owed, greaterThan(0));
      l.debugSetStats(money: owed + 1000);
      expect(event('pay_off_mortgage').matches(l.context), isTrue);
      play(l, 'pay_off_mortgage', 'Clear it');
      expect(l.context.mortgage, 0);
      expect(l.money, 1000);
    });
  });
}
