import 'package:flutter/material.dart';

/// Data model for **Life** — the main game: a BitLife-style life simulator.
/// You are born, age up a year at a time, and your choices move four stats
/// (Happiness, Health, Smarts, Looks) plus money. Money lessons are woven in
/// rather than being the whole game.
///
/// Pure data. Rules live in `LifeSimController`; the screen renders what the
/// controller exposes, so the game can grow without touching UI wiring.

/// One line in the life feed, tagged with the age it happened at.
@immutable
class LifeLogEntry {
  const LifeLogEntry({required this.age, required this.text});

  final int age;
  final String text;
}

enum Gender { male, female, nonBinary }

extension GenderInfo on Gender {
  String get label => switch (this) {
    Gender.male => 'Male',
    Gender.female => 'Female',
    Gender.nonBinary => 'Non-binary',
  };

  IconData get icon => switch (this) {
    Gender.male => Icons.male_rounded,
    Gender.female => Icons.female_rounded,
    Gender.nonBinary => Icons.transgender_rounded,
  };
}

/// Where the life starts. Origin sets the family's money and a couple of
/// stat nudges — the "born on third base" lesson, made concrete.
enum LifeOrigin { struggling, workingClass, comfortable, wealthy }

extension LifeOriginInfo on LifeOrigin {
  String get label => switch (this) {
    LifeOrigin.struggling => 'Struggling',
    LifeOrigin.workingClass => 'Working class',
    LifeOrigin.comfortable => 'Comfortable',
    LifeOrigin.wealthy => 'Wealthy',
  };

  String get blurb => switch (this) {
    LifeOrigin.struggling =>
      'Money is tight. Every choice counts, but you learn fast.',
    LifeOrigin.workingClass => 'Enough to get by, nothing spare.',
    LifeOrigin.comfortable => 'A steady home with a little cushion.',
    LifeOrigin.wealthy => 'A big head start — easy to waste.',
  };

  /// Family money the child can lean on, in coins.
  int get familyMoney => switch (this) {
    LifeOrigin.struggling => 0,
    LifeOrigin.workingClass => 150,
    LifeOrigin.comfortable => 600,
    LifeOrigin.wealthy => 2500,
  };

  int get startingSmarts => switch (this) {
    LifeOrigin.struggling => 48,
    LifeOrigin.workingClass => 46,
    LifeOrigin.comfortable => 52,
    LifeOrigin.wealthy => 55,
  };

  int get startingHappiness => switch (this) {
    LifeOrigin.struggling => 58,
    LifeOrigin.workingClass => 65,
    LifeOrigin.comfortable => 70,
    LifeOrigin.wealthy => 72,
  };
}

/// Life stages, from birth. Drives which events can fire and what a year costs.
enum LifeStage { baby, child, teen, youngAdult, adult, senior }

extension LifeStageInfo on LifeStage {
  String get label => switch (this) {
    LifeStage.baby => 'Baby',
    LifeStage.child => 'Child',
    LifeStage.teen => 'Teen',
    LifeStage.youngAdult => 'Young Adult',
    LifeStage.adult => 'Adult',
    LifeStage.senior => 'Senior',
  };

  static LifeStage forAge(int age) {
    if (age < 4) return LifeStage.baby;
    if (age < 13) return LifeStage.child;
    if (age < 18) return LifeStage.teen;
    if (age < 30) return LifeStage.youngAdult;
    if (age < 60) return LifeStage.adult;
    return LifeStage.senior;
  }
}

/// One option on a life event, with its outcome text and effects.
@immutable
class LifeChoice {
  const LifeChoice({
    required this.label,
    required this.outcome,
    this.money = 0,
    this.happiness = 0,
    this.health = 0,
    this.smarts = 0,
    this.looks = 0,
    this.setJob,
    this.setSalary,
    this.addRelationship,
  });

  final String label;
  final String outcome;
  final int money;
  final int happiness;
  final int health;
  final int smarts;
  final int looks;

  /// If set, the choice lands a job at this yearly salary.
  final String? setJob;
  final int? setSalary;

  /// If set, adds someone to the player's relationships list.
  final String? addRelationship;
}

/// A prompt that appears when you age up.
@immutable
class LifeEvent {
  const LifeEvent({
    required this.id,
    required this.prompt,
    required this.icon,
    required this.choices,
    this.minAge = 0,
    this.maxAge = 200,
  });

  final String id;
  final String prompt;
  final IconData icon;
  final List<LifeChoice> choices;
  final int minAge;
  final int maxAge;

  bool eligibleAt(int age) => age >= minAge && age <= maxAge;
}

/// The event pool — childhood, school, friends, health and love alongside the
/// money lessons, so it plays like a life rather than a finance quiz.
const List<LifeEvent> kLifeEvents = <LifeEvent>[
  // ---------------- Childhood ----------------
  LifeEvent(
    id: 'first_words',
    prompt: 'You are learning to talk. What is your first word?',
    icon: Icons.child_care_rounded,
    maxAge: 3,
    choices: [
      LifeChoice(
        label: '"Mama"',
        outcome: 'Your mother cried happy tears.',
        happiness: 8,
      ),
      LifeChoice(
        label: '"More!"',
        outcome: 'Demanding from day one.',
        happiness: 4,
        smarts: 3,
      ),
      LifeChoice(
        label: '"Why?"',
        outcome: 'Your parents are already exhausted. Curious mind, though.',
        smarts: 7,
        happiness: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'playground',
    prompt: 'A kid at the playground shoves you off the swing.',
    icon: Icons.park_rounded,
    minAge: 4,
    maxAge: 11,
    choices: [
      LifeChoice(
        label: 'Tell a grown-up',
        outcome: 'The teacher sorted it out. Good instinct.',
        happiness: 3,
        smarts: 2,
      ),
      LifeChoice(
        label: 'Shove them back',
        outcome: 'You both ended up in trouble.',
        happiness: -4,
        health: -2,
      ),
      LifeChoice(
        label: 'Invite them to play',
        outcome: 'Somehow you became friends.',
        happiness: 8,
        addRelationship: 'Childhood friend',
      ),
    ],
  ),
  LifeEvent(
    id: 'pet',
    prompt: 'Your family is thinking about getting a pet.',
    icon: Icons.pets_rounded,
    minAge: 5,
    maxAge: 16,
    choices: [
      LifeChoice(
        label: 'Beg for a dog',
        outcome: 'A scruffy rescue dog joins the family. Best friend acquired.',
        happiness: 14,
        health: 4,
        money: -60,
        addRelationship: 'Dog',
      ),
      LifeChoice(
        label: 'Ask for a goldfish',
        outcome: 'Low maintenance, low drama, mildly boring.',
        happiness: 4,
        money: -10,
      ),
      LifeChoice(
        label: 'No pets',
        outcome: 'You kept the house calm and the budget intact.',
        smarts: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'allowance',
    prompt: 'Your parents offer 20 coins a week for chores.',
    icon: Icons.cleaning_services_rounded,
    minAge: 7,
    maxAge: 15,
    choices: [
      LifeChoice(
        label: 'Do every chore',
        outcome: 'You earned it all and learned what work feels like.',
        money: 120,
        happiness: -3,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Do the easy ones',
        outcome: 'Half the money, half the effort.',
        money: 55,
      ),
      LifeChoice(
        label: 'Skip chores',
        outcome: 'Free time now, empty pockets later.',
        happiness: 5,
        money: 0,
      ),
    ],
  ),
  LifeEvent(
    id: 'school_project',
    prompt: 'Big school project. Group or solo?',
    icon: Icons.science_rounded,
    minAge: 8,
    maxAge: 18,
    choices: [
      LifeChoice(
        label: 'Lead the group',
        outcome: 'You carried the team and everyone noticed.',
        smarts: 7,
        happiness: 3,
        addRelationship: 'Study partner',
      ),
      LifeChoice(
        label: 'Work solo',
        outcome: 'Total control, total workload. Solid grade.',
        smarts: 6,
        happiness: -3,
      ),
      LifeChoice(
        label: 'Coast on the group',
        outcome: 'You passed, but nobody wants you next time.',
        smarts: 1,
        happiness: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'sports_tryout',
    prompt: 'Tryouts for the school team are this week.',
    icon: Icons.sports_soccer_rounded,
    minAge: 9,
    maxAge: 22,
    choices: [
      LifeChoice(
        label: 'Train hard and try out',
        outcome: 'You made the team. Fitter and prouder.',
        health: 12,
        happiness: 8,
        looks: 4,
      ),
      LifeChoice(
        label: 'Show up unprepared',
        outcome: 'Cut in the first round. Ouch.',
        happiness: -6,
        health: 2,
      ),
      LifeChoice(
        label: 'Skip it',
        outcome: 'You stayed on the couch.',
        health: -4,
        happiness: 2,
      ),
    ],
  ),
  // ---------------- Teen ----------------
  LifeEvent(
    id: 'first_crush',
    prompt: 'You have a crush on someone in your class.',
    icon: Icons.favorite_rounded,
    minAge: 12,
    maxAge: 19,
    choices: [
      LifeChoice(
        label: 'Tell them',
        outcome: 'They said yes! First relationship unlocked.',
        happiness: 15,
        looks: 2,
        addRelationship: 'Partner',
      ),
      LifeChoice(
        label: 'Say nothing',
        outcome: 'The moment passed. You wonder sometimes.',
        happiness: -5,
      ),
      LifeChoice(
        label: 'Ask a friend to ask them',
        outcome: 'Middle-school diplomacy. It went okay.',
        happiness: 5,
      ),
    ],
  ),
  LifeEvent(
    id: 'first_paycheck',
    prompt: 'You earned your first paycheck from a summer job.',
    icon: Icons.payments_rounded,
    minAge: 15,
    maxAge: 24,
    choices: [
      LifeChoice(
        label: 'Save most of it',
        outcome: 'You banked it. Boring now, powerful later.',
        money: 150,
        happiness: -3,
        smarts: 5,
      ),
      LifeChoice(
        label: 'Split save and spend',
        outcome: 'A little fun, a little future. Balanced.',
        money: 90,
        happiness: 6,
        smarts: 3,
      ),
      LifeChoice(
        label: 'Blow it all',
        outcome: 'Great weekend, empty wallet by Monday.',
        money: 10,
        happiness: 12,
        smarts: -2,
      ),
    ],
  ),
  LifeEvent(
    id: 'phone_breaks',
    prompt: 'Your phone screen cracks badly.',
    icon: Icons.phone_iphone_rounded,
    minAge: 12,
    choices: [
      LifeChoice(
        label: 'Buy a cheaper model',
        outcome: 'Not flashy, but you stayed out of debt.',
        money: -120,
        happiness: 2,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Put it on credit',
        outcome: 'You have a phone now — and interest piling up.',
        money: -60,
        happiness: 4,
        smarts: -4,
      ),
      LifeChoice(
        label: 'Tape it and wait',
        outcome: 'Ugly, but you kept every coin.',
        happiness: -6,
        smarts: 5,
      ),
    ],
  ),
  LifeEvent(
    id: 'party',
    prompt: 'There is a huge party the night before an exam.',
    icon: Icons.celebration_rounded,
    minAge: 14,
    maxAge: 30,
    choices: [
      LifeChoice(
        label: 'Go out',
        outcome: 'Unforgettable night, forgettable exam result.',
        happiness: 14,
        smarts: -5,
        health: -3,
      ),
      LifeChoice(
        label: 'Stay in and study',
        outcome: 'You aced it while everyone else was recovering.',
        smarts: 9,
        happiness: -4,
      ),
      LifeChoice(
        label: 'Go for one hour',
        outcome: 'You showed your face and still got to bed early.',
        happiness: 7,
        smarts: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'crypto_tip',
    prompt: 'A classmate swears a coin will "10x by Friday". Get in?',
    icon: Icons.currency_bitcoin_rounded,
    minAge: 15,
    choices: [
      LifeChoice(
        label: 'Go all in',
        outcome: 'It dumped. "Guaranteed" is never guaranteed.',
        money: -200,
        happiness: -8,
        smarts: 7,
      ),
      LifeChoice(
        label: 'Risk a tiny bit',
        outcome: 'You risked only what you could lose. Smart.',
        money: -20,
        smarts: 5,
      ),
      LifeChoice(
        label: 'Pass',
        outcome: 'You dodged the hype.',
        smarts: 6,
        happiness: -1,
      ),
    ],
  ),
  LifeEvent(
    id: 'driving_test',
    prompt: 'Time for your driving test.',
    icon: Icons.directions_car_rounded,
    minAge: 16,
    maxAge: 30,
    choices: [
      LifeChoice(
        label: 'Take lessons first',
        outcome: 'Passed first time. Money well spent.',
        money: -180,
        happiness: 10,
        smarts: 3,
      ),
      LifeChoice(
        label: 'Wing it',
        outcome: 'Failed. You have to pay for a retake anyway.',
        money: -60,
        happiness: -6,
      ),
    ],
  ),
  // ---------------- Adult ----------------
  LifeEvent(
    id: 'scholarship',
    prompt: 'A scholarship needs a hard exam. Grind for it?',
    icon: Icons.school_rounded,
    minAge: 16,
    maxAge: 26,
    choices: [
      LifeChoice(
        label: 'Study hard',
        outcome: 'You aced it and won the scholarship!',
        money: 400,
        happiness: -4,
        smarts: 11,
      ),
      LifeChoice(
        label: 'Wing it',
        outcome: 'Missed by a bit. Next time.',
        smarts: 2,
        happiness: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'job_offer',
    prompt: 'A local shop offers you a steady part-time job.',
    icon: Icons.store_rounded,
    minAge: 16,
    maxAge: 45,
    choices: [
      LifeChoice(
        label: 'Take it',
        outcome: 'Steady income unlocked — a salary lands each year now.',
        happiness: 3,
        setJob: 'Shop Assistant',
        setSalary: 260,
      ),
      LifeChoice(
        label: 'Hold out for better',
        outcome: 'You kept your time free, and your wallet thin.',
        happiness: 4,
        smarts: 1,
      ),
    ],
  ),
  LifeEvent(
    id: 'move_out',
    prompt: 'You could move into your own place.',
    icon: Icons.house_rounded,
    minAge: 18,
    maxAge: 35,
    choices: [
      LifeChoice(
        label: 'Get your own flat',
        outcome: 'Freedom! And rent. So much rent.',
        money: -400,
        happiness: 12,
      ),
      LifeChoice(
        label: 'Share with friends',
        outcome: 'Cheaper, louder, more fun.',
        money: -180,
        happiness: 8,
        addRelationship: 'Housemate',
      ),
      LifeChoice(
        label: 'Stay home and save',
        outcome: 'Less independence, much more saved.',
        money: 250,
        happiness: -6,
        smarts: 4,
      ),
    ],
  ),
  LifeEvent(
    id: 'emergency_fund',
    prompt: 'A quiet year. Build an emergency fund?',
    icon: Icons.savings_rounded,
    minAge: 18,
    choices: [
      LifeChoice(
        label: 'Set aside savings',
        outcome: 'A cushion for the next surprise. Peace of mind.',
        money: -80,
        happiness: 4,
        smarts: 7,
      ),
      LifeChoice(
        label: 'Spend it on fun',
        outcome: 'Great memories, no cushion.',
        happiness: 11,
        smarts: -3,
      ),
    ],
  ),
  LifeEvent(
    id: 'car_repair',
    prompt: 'Your car needs a 250-coin repair to get you to work.',
    icon: Icons.car_repair_rounded,
    minAge: 18,
    choices: [
      LifeChoice(
        label: 'Pay from savings',
        outcome: 'Exactly what savings are for.',
        money: -250,
        happiness: -2,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Payday loan',
        outcome: 'Quick cash, brutal fees. Ouch.',
        money: -120,
        happiness: -6,
        smarts: -5,
      ),
    ],
  ),
  LifeEvent(
    id: 'raise',
    prompt: 'Your boss offers a raise for more responsibility.',
    icon: Icons.trending_up_rounded,
    minAge: 20,
    choices: [
      LifeChoice(
        label: 'Take the raise',
        outcome: 'More work, more pay. Career climbing.',
        happiness: -3,
        smarts: 5,
        setJob: 'Team Lead',
        setSalary: 520,
      ),
      LifeChoice(
        label: 'Keep work-life balance',
        outcome: 'You value your time over the bump. Fair.',
        happiness: 8,
      ),
    ],
  ),
  LifeEvent(
    id: 'gym',
    prompt: 'You have not moved much in months.',
    icon: Icons.fitness_center_rounded,
    minAge: 16,
    choices: [
      LifeChoice(
        label: 'Join a gym',
        outcome: 'Sore, but stronger and sharper.',
        money: -90,
        health: 14,
        looks: 6,
      ),
      LifeChoice(
        label: 'Run outside for free',
        outcome: 'Free, effective, occasionally rainy.',
        health: 10,
        looks: 3,
      ),
      LifeChoice(
        label: 'Do nothing',
        outcome: 'The couch won again.',
        health: -8,
        happiness: 3,
      ),
    ],
  ),
  LifeEvent(
    id: 'checkup',
    prompt: 'You have been putting off a doctor visit.',
    icon: Icons.medical_services_rounded,
    minAge: 20,
    choices: [
      LifeChoice(
        label: 'Go for the check-up',
        outcome: 'Caught something small before it got big.',
        money: -70,
        health: 12,
      ),
      LifeChoice(
        label: 'Ignore it',
        outcome: 'Probably fine. Probably.',
        health: -10,
        money: 0,
      ),
    ],
  ),
  LifeEvent(
    id: 'friend_loan',
    prompt: 'A close friend asks to borrow 300 coins.',
    icon: Icons.handshake_rounded,
    minAge: 18,
    choices: [
      LifeChoice(
        label: 'Lend it',
        outcome: 'They promised to pay you back. Friendships and money mix badly.',
        money: -300,
        happiness: 5,
      ),
      LifeChoice(
        label: 'Offer a smaller gift',
        outcome: 'You gave what you could afford to lose. Wise.',
        money: -80,
        happiness: 6,
        smarts: 5,
      ),
      LifeChoice(
        label: 'Say no kindly',
        outcome: 'Awkward, but honest.',
        happiness: -4,
        smarts: 3,
      ),
    ],
  ),
];
