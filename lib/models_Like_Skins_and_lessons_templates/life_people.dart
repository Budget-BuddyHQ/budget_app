import 'dart:math';

import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_sim_models.dart';
import 'relationship.dart';

/// The people in a life: who is in your family, what you can do about them, and
/// what happens when they are gone.
///
/// **Asked for as:** *"make it like BitLife, where there is a progression bar on
/// how close you are,"* with *"family and friends"*, and a random pop-up like
/// *"this year your mom suddenly passed away."* Relationships were a list of
/// names with three buttons, everybody was a friend, and nobody was ever born
/// into a family or left it.
///
/// A life now starts with a family (a mother, a father, perhaps brothers,
/// sisters and grandparents), each with an age, and a person can be lost. That
/// is the part with weight, so it is written carefully: it is gentle, it says
/// what happened without describing it, and it always leaves the player
/// something to do. Life is for players nine and up and says up front that this
/// is in it. See `life_advisory.dart`.
///
/// Pure Dart. The controller owns the people and applies these rules.

/// Women's first names, for a family that needs a mother or a sister.
const List<String> kFemaleFirstNames = <String>[
  'Aisha',
  'Priya',
  'Hannah',
  'Mei',
  'Zainab',
  'Sofia',
  'Ingrid',
  'Amara',
  'Leila',
  'Grace',
  'Noor',
  'Camila',
  'Yuki',
  'Fatima',
  'Elena',
  'Ruth',
  'Imani',
  'Sana',
  'Clara',
  'Nadia',
  'Rosa',
  'Tessa',
  'Ana',
  'Joy',
];

/// Men's first names.
const List<String> kMaleFirstNames = <String>[
  'Marcus',
  'Diego',
  'Kwame',
  'Luca',
  'Owen',
  'Tariq',
  'Mateo',
  'Samir',
  'Jonah',
  'Andre',
  'Kenji',
  'Ravi',
  'Isaac',
  'Omar',
  'Felix',
  'Tomas',
  'Elijah',
  'Nico',
  'Hugo',
  'Jamal',
  'Anton',
  'Ben',
  'Caleb',
  'Idris',
];

/// The last word of a full name.
String surnameOf(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? '' : parts.last;
}

/// A first name that is not already taken, with [surname] added.
String freshFamilyName(
  Random random, {
  required bool female,
  required String surname,
  required Set<String> taken,
}) {
  final pool = female ? kFemaleFirstNames : kMaleFirstNames;
  for (var attempt = 0; attempt < 40; attempt++) {
    final name = '${pool[random.nextInt(pool.length)]} $surname';
    if (!taken.contains(name)) return name;
  }
  return '${pool.first} $surname ${taken.length + 1}';
}

/// The family a life begins with.
///
/// Two parents, sometimes a brother or sister, sometimes a grandparent. Never
/// none, because a life with nobody to lose is not the same game. Ages are
/// stored as offsets from the player's, so a mother 27 years older stays 27
/// years older as the years pass.
List<Relationship> buildFamily(Random random, {required String surname}) {
  final taken = <String>{};
  Relationship make({
    required String role,
    required bool female,
    required int offset,
    required int closeness,
    RelationshipKind kind = RelationshipKind.family,
  }) {
    final name = freshFamilyName(
      random,
      female: female,
      surname: surname,
      taken: taken,
    );
    taken.add(name);
    return Relationship(
      name: name,
      kind: kind,
      closeness: closeness,
      metAtAge: 0,
      lastSeenAge: 0,
      role: role,
      ageOffset: offset,
    );
  }

  final family = <Relationship>[
    make(
      role: 'Mother',
      female: true,
      offset: 22 + random.nextInt(12),
      closeness: 72 + random.nextInt(14),
    ),
    make(
      role: 'Father',
      female: false,
      offset: 24 + random.nextInt(12),
      closeness: 68 + random.nextInt(14),
    ),
  ];

  final siblings = random.nextInt(100) < 58
      ? (random.nextInt(100) < 25 ? 2 : 1)
      : 0;
  for (var i = 0; i < siblings; i++) {
    final girl = random.nextBool();
    final older = random.nextBool();
    final gap = 1 + random.nextInt(6);
    family.add(
      make(
        role: girl ? 'Sister' : 'Brother',
        female: girl,
        offset: older ? gap : -gap,
        closeness: 55 + random.nextInt(20),
      ),
    );
  }

  if (random.nextInt(100) < 55) {
    family.add(
      make(
        role: 'Grandmother',
        female: true,
        offset: 50 + random.nextInt(14),
        closeness: 55 + random.nextInt(20),
      ),
    );
  }
  if (random.nextInt(100) < 40) {
    family.add(
      make(
        role: 'Grandfather',
        female: false,
        offset: 52 + random.nextInt(14),
        closeness: 55 + random.nextInt(20),
      ),
    );
  }
  return family;
}

/// The chance in a given year that somebody of [personAge] dies.
///
/// Low until the sixties and then climbing, so that most people are lucky
/// enough to keep their parents into their own adulthood and few keep them to
/// the end. A young loss is rare and a late one is ordinary, which is the truth
/// and the reason the rare one is worth a card.
double yearlyDeathChance(int personAge) {
  if (personAge < 50) return 0.002;
  if (personAge < 60) return 0.006;
  if (personAge < 70) return 0.018;
  if (personAge < 80) return 0.05;
  if (personAge < 90) return 0.13;
  return 0.26;
}

/// How a loss happened. Changes the words, never the options.
enum PassingKind {
  sudden,
  illness,
  oldAge;

  static PassingKind roll(Random random, int personAge) {
    if (personAge >= 80) return PassingKind.oldAge;
    return random.nextInt(100) < 35 ? PassingKind.sudden : PassingKind.illness;
  }
}

/// The card shown when somebody in your life has died.
///
/// **How it is written.** It says what happened in one plain sentence and does
/// not describe it. It offers real choices, because a card with a single button
/// reads as being told what to feel, and the choices are the ones people
/// actually face: what to spend, and whether to slow down. Both spending choices
/// teach the same idea, because the part of this that is about money is that it
/// arrives at the worst time, which is the whole argument for insurance and a
/// little in savings.
LifeEvent bereavementEvent({
  required Relationship person,
  required PassingKind how,
  required int playerAge,
}) {
  final first = person.name.split(' ').first;
  final who = person.role.isEmpty
      ? person.kind.label.toLowerCase()
      : person.role.toLowerCase();
  final prompt = switch (how) {
    PassingKind.sudden =>
      'This year, your $who $first suddenly passed away. Nobody saw it '
          'coming.',
    PassingKind.illness =>
      'After a long illness, your $who $first passed away this year.',
    PassingKind.oldAge =>
      'Your $who $first passed away this year, peacefully, after a long life.',
  };

  final close = person.closeness >= 60;
  return LifeEvent(
    id: 'loss_${person.name}_$playerAge',
    prompt: prompt,
    icon: Icons.favorite_border_rounded,
    choices: [
      LifeChoice(
        label: 'Hold a proper memorial',
        outcome:
            'Everybody who loved $first came. It cost a lot, it mattered, and '
            'it is the kind of bill that turns up when nobody is ready for it.',
        money: -150,
        happiness: close ? -4 : -2,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Keep it small and simple',
        outcome:
            'A quiet day, and what $first would have wanted. Nobody who loved '
            'them thought less of it. Planning ahead makes days like this '
            'easier on the people left to organise them.',
        money: -40,
        happiness: close ? -6 : -3,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Take some time to grieve',
        outcome:
            'You did very little for a few weeks, and that was allowed. '
            'Grief is not a task with a deadline.',
        happiness: close ? -9 : -5,
        health: -1,
      ),
      LifeChoice(
        label: 'Lean on the people you have left',
        outcome:
            'You called the ones who would pick up. It did not fix it, and it '
            'helped. The people around you are worth more than they cost.',
        happiness: close ? -5 : -2,
        smarts: 2,
      ),
    ],
  );
}

/// The card shown when a pet has died.
LifeEvent petLossEvent({
  required String petName,
  required String kind,
  required int playerAge,
}) {
  return LifeEvent(
    id: 'pet_loss_${petName}_$playerAge',
    prompt: '$petName the $kind has died. They had a good life with you.',
    icon: Icons.pets_rounded,
    choices: [
      LifeChoice(
        label: 'Say a proper goodbye',
        outcome:
            'You buried them somewhere they liked. It hurt, and it helped.',
        happiness: -6,
      ),
      LifeChoice(
        label: 'Keep busy',
        outcome:
            'You filled the week with things to do. The quiet came back '
            'anyway, later.',
        happiness: -4,
        smarts: 1,
      ),
    ],
  );
}

/// What you can do about one person.
///
/// The same list the screen shows and the controller checks, so a button can
/// never appear for something that would do nothing.
enum PersonAction {
  conversation(
    'Have a conversation',
    Icons.forum_rounded,
    'Talk about anything. It warms things up.',
  ),
  spendTime(
    'Spend time together',
    Icons.hourglass_top_rounded,
    'A whole day. The best thing you can give anybody.',
  ),
  compliment(
    'Give a compliment',
    Icons.emoji_emotions_rounded,
    'Free, and it lands better than you would think.',
  ),
  gift(
    'Give a gift',
    Icons.card_giftcard_rounded,
    'Costs money and helps less than time does.',
  ),
  askMoney(
    'Ask for money',
    Icons.request_quote_rounded,
    'They might help. Asking can cost you a little closeness.',
  ),
  askAdvice(
    'Ask for advice',
    Icons.lightbulb_rounded,
    'Somebody who has been there. You learn something.',
  ),
  date(
    'Go on a date',
    Icons.local_dining_rounded,
    'A nice evening out. Costs a little.',
  ),
  propose(
    'Propose',
    Icons.diamond_rounded,
    'Ask them to marry you. Do not rush it.',
  ),
  startFamily(
    'Start a family',
    Icons.child_friendly_rounded,
    'Have a child. It is wonderful, and it changes what everything costs.',
  );

  const PersonAction(this.label, this.icon, this.blurb);

  final String label;
  final IconData icon;
  final String blurb;
}

/// The actions available for a person, in the order to show them.
List<PersonAction> personActionsFor(
  Relationship person, {
  required int playerAge,
}) {
  if (!person.isAlive) return const <PersonAction>[];
  final base = <PersonAction>[
    PersonAction.conversation,
    PersonAction.spendTime,
    PersonAction.compliment,
    PersonAction.gift,
  ];
  switch (person.kind) {
    case RelationshipKind.family:
      final isParent = person.role == 'Mother' || person.role == 'Father';
      return [
        ...base,
        if (playerAge >= 6 && (isParent || playerAge >= 12))
          PersonAction.askMoney,
        PersonAction.askAdvice,
      ];
    case RelationshipKind.friend:
      return [
        ...base,
        if (playerAge >= 12) PersonAction.askMoney,
        PersonAction.askAdvice,
      ];
    case RelationshipKind.partner:
      return [
        ...base,
        PersonAction.date,
        if (playerAge >= 21) PersonAction.propose,
        PersonAction.startFamily,
      ];
    case RelationshipKind.spouse:
      return [...base, PersonAction.date, PersonAction.startFamily];
    case RelationshipKind.child:
      return base;
    case RelationshipKind.mentor:
      return [PersonAction.conversation, PersonAction.askAdvice];
    case RelationshipKind.colleague:
      return [PersonAction.conversation, PersonAction.askAdvice];
  }
}

/// How much closeness an action adds, before it fades.
int closenessFor(PersonAction action) => switch (action) {
  PersonAction.conversation => 6,
  PersonAction.spendTime => 12,
  PersonAction.compliment => 4,
  PersonAction.gift => 5,
  PersonAction.askMoney => -2,
  PersonAction.askAdvice => 3,
  PersonAction.date => 10,
  PersonAction.propose => 0,
  PersonAction.startFamily => 6,
};

/// The most a person can be dealt with in a year. A relationship is a few good
/// moments, not a button to be held.
const int kTouchesPerPersonPerYear = 3;

/// The wedding a player can choose, from a quiet one to a big one.
///
/// A decision about money with no right answer: the big one is a lovely day and
/// a bill, and the small one is the same marriage.
enum Wedding {
  small('A small ceremony', 80, 4),
  family('A family wedding', 300, 8),
  big('A big celebration', 900, 12);

  const Wedding(this.label, this.cost, this.joy);

  final String label;
  final int cost;
  final int joy;
}

/// The names a couple's child might have.
String childName(Random random, {required String surname, required bool girl}) {
  final pool = girl ? kFemaleFirstNames : kMaleFirstNames;
  return '${pool[random.nextInt(pool.length)]} $surname';
}
