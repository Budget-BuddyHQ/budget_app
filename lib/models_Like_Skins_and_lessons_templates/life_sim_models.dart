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

  // ---------------- Childhood (expansion) ----------------
  LifeEvent(
    id: 'lemonade_stand',
    prompt: 'You want to run a lemonade stand outside the house.',
    icon: Icons.local_drink_rounded,
    minAge: 6,
    maxAge: 12,
    choices: [
      LifeChoice(
        label: 'Charge a fair price',
        outcome: 'Steady customers all afternoon. Your first real profit.',
        money: 25,
        happiness: 8,
        smarts: 5,
      ),
      LifeChoice(
        label: 'Charge way too much',
        outcome: 'Two sales, then nothing. Turns out price matters.',
        money: 6,
        smarts: 7,
        happiness: -2,
      ),
      LifeChoice(
        label: 'Give it away free',
        outcome: 'Everyone loved you. You made zero coins.',
        happiness: 12,
      ),
    ],
  ),
  LifeEvent(
    id: 'birthday_money',
    prompt: 'Relatives gave you 120 coins for your birthday.',
    icon: Icons.cake_rounded,
    minAge: 7,
    maxAge: 15,
    choices: [
      LifeChoice(
        label: 'Save all of it',
        outcome: 'Straight into savings. Boring now, useful later.',
        money: 120,
        smarts: 6,
        happiness: -2,
      ),
      LifeChoice(
        label: 'Save half, spend half',
        outcome: 'A treat today and something left over. Balanced.',
        money: 60,
        happiness: 8,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Spend it immediately',
        outcome: 'Gone in a weekend. Worth it? Debatable.',
        happiness: 12,
      ),
    ],
  ),
  LifeEvent(
    id: 'lost_wallet',
    prompt: 'You find a wallet with 200 coins and an ID inside.',
    icon: Icons.badge_rounded,
    minAge: 9,
    choices: [
      LifeChoice(
        label: 'Return it',
        outcome: 'They insisted on a reward. Doing the right thing paid twice.',
        money: 50,
        happiness: 10,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Keep the money',
        outcome: 'You are richer. It sat badly with you for weeks.',
        money: 200,
        happiness: -12,
      ),
    ],
  ),

  // ---------------- Teen (expansion) ----------------
  LifeEvent(
    id: 'first_bank_account',
    prompt: 'You are old enough to open your own bank account.',
    icon: Icons.account_balance_rounded,
    minAge: 14,
    maxAge: 22,
    choices: [
      LifeChoice(
        label: 'Open a savings account',
        outcome: 'Your money finally lives somewhere that pays you to keep it.',
        smarts: 10,
        happiness: 4,
      ),
      LifeChoice(
        label: 'Stick to cash',
        outcome: 'Under the mattress it is. Nothing grows there.',
        happiness: -2,
      ),
    ],
  ),
  LifeEvent(
    id: 'concert_tickets',
    prompt: 'Your favourite artist is playing. Tickets are 250 coins.',
    icon: Icons.music_note_rounded,
    minAge: 14,
    maxAge: 30,
    choices: [
      LifeChoice(
        label: 'Buy them',
        outcome: 'One of the best nights of your life. Expensive, but real.',
        money: -250,
        happiness: 18,
      ),
      LifeChoice(
        label: 'Wait for the next tour',
        outcome: 'You kept the money. You also watched clips of it all week.',
        happiness: -6,
        smarts: 4,
      ),
    ],
  ),
  LifeEvent(
    id: 'side_hustle',
    prompt: 'A neighbour offers you weekend work for 40 coins a time.',
    icon: Icons.handyman_rounded,
    minAge: 13,
    maxAge: 24,
    choices: [
      LifeChoice(
        label: 'Take every shift',
        outcome: 'Your first steady income. Tiring, but the money is yours.',
        money: 320,
        happiness: -4,
        smarts: 6,
      ),
      LifeChoice(
        label: 'Take a few',
        outcome: 'Some money, some weekends still free.',
        money: 120,
        happiness: 3,
      ),
      LifeChoice(
        label: 'Pass',
        outcome: 'You kept your weekends. Your wallet noticed.',
        happiness: 5,
      ),
    ],
  ),
  LifeEvent(
    id: 'impulse_sale',
    prompt: 'A "70% OFF TODAY ONLY" banner is staring at you.',
    icon: Icons.local_offer_rounded,
    minAge: 13,
    choices: [
      LifeChoice(
        label: 'Buy it — it is a deal!',
        outcome:
            'A discount on something you did not need is still money spent.',
        money: -150,
        happiness: 6,
      ),
      LifeChoice(
        label: 'Check if you actually wanted it',
        outcome: 'You did not. The banner was the whole reason.',
        smarts: 8,
        happiness: 2,
      ),
    ],
  ),

  // ---------------- Adult (expansion) ----------------
  LifeEvent(
    id: 'credit_card_offer',
    prompt: 'A card with a 2,000 coin limit is pre-approved for you.',
    icon: Icons.credit_card_rounded,
    minAge: 18,
    choices: [
      LifeChoice(
        label: 'Take it, pay in full monthly',
        outcome: 'Used carefully, it quietly builds your credit history.',
        smarts: 10,
        happiness: 4,
      ),
      LifeChoice(
        label: 'Take it and max it out',
        outcome: 'A great month. The interest is going to hurt.',
        money: 2000,
        happiness: 14,
        smarts: -8,
      ),
      LifeChoice(
        label: 'Decline',
        outcome: 'No debt, no credit history either. A real tradeoff.',
        smarts: 3,
      ),
    ],
  ),
  LifeEvent(
    id: 'rent_increase',
    prompt: 'Your landlord is raising the rent by 200 coins a month.',
    icon: Icons.home_work_rounded,
    minAge: 20,
    choices: [
      LifeChoice(
        label: 'Negotiate',
        outcome: 'You talked them down. Asking cost nothing.',
        money: -60,
        smarts: 8,
        happiness: 3,
      ),
      LifeChoice(
        label: 'Move somewhere cheaper',
        outcome: 'A hassle, and a smaller place — but the budget breathes.',
        money: -300,
        happiness: -6,
        smarts: 6,
      ),
      LifeChoice(
        label: 'Just pay it',
        outcome: 'Easiest now, tighter every month after.',
        money: -600,
        happiness: -3,
      ),
    ],
  ),
  LifeEvent(
    id: 'salary_negotiation',
    prompt: 'You have been offered a new role. The salary is negotiable.',
    icon: Icons.trending_up_rounded,
    minAge: 21,
    choices: [
      LifeChoice(
        label: 'Ask for more',
        outcome: 'They met you most of the way. The ask paid for itself.',
        money: 400,
        smarts: 10,
        happiness: 8,
        setJob: 'Analyst',
        setSalary: 520,
      ),
      LifeChoice(
        label: 'Accept the first offer',
        outcome: 'A good job. You will always wonder what was on the table.',
        happiness: 4,
        setJob: 'Analyst',
        setSalary: 420,
      ),
    ],
  ),
  LifeEvent(
    id: 'subscription_audit',
    prompt: 'You count nine active subscriptions on your statement.',
    icon: Icons.receipt_long_rounded,
    minAge: 19,
    choices: [
      LifeChoice(
        label: 'Cancel the unused ones',
        outcome: 'Five were dead weight. That is money back every month.',
        money: 180,
        smarts: 9,
        happiness: 4,
      ),
      LifeChoice(
        label: 'Keep them all',
        outcome: 'Easier than deciding. It quietly adds up.',
        money: -120,
        happiness: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'market_crash',
    prompt: 'The market drops sharply. Your investments are down 30%.',
    icon: Icons.trending_down_rounded,
    minAge: 22,
    choices: [
      LifeChoice(
        label: 'Hold and wait',
        outcome:
            'Painful to watch, but you did not lock in the loss by selling.',
        smarts: 12,
        happiness: -6,
      ),
      LifeChoice(
        label: 'Sell everything',
        outcome: 'You stopped the bleeding — and missed the recovery.',
        money: -200,
        happiness: -10,
        smarts: -4,
      ),
      LifeChoice(
        label: 'Buy more while it is cheap',
        outcome: 'Nerve-racking. Historically, this is when it pays off.',
        money: -400,
        smarts: 10,
        happiness: -3,
      ),
    ],
  ),
  LifeEvent(
    id: 'insurance_choice',
    prompt: 'Your renters insurance is up for renewal.',
    icon: Icons.shield_rounded,
    minAge: 21,
    choices: [
      LifeChoice(
        label: 'Renew it',
        outcome: 'Boring, cheap, and exactly what you want when it matters.',
        money: -90,
        smarts: 7,
        health: 3,
      ),
      LifeChoice(
        label: 'Skip it',
        outcome: 'Saved a little. Carrying the whole risk yourself now.',
        money: 90,
        happiness: -3,
      ),
    ],
  ),
  LifeEvent(
    id: 'family_support',
    prompt: 'A parent is struggling and could use help with bills.',
    icon: Icons.family_restroom_rounded,
    minAge: 24,
    choices: [
      LifeChoice(
        label: 'Help every month',
        outcome: 'It costs you real money. You would do it again.',
        money: -500,
        happiness: 12,
      ),
      LifeChoice(
        label: 'Help once',
        outcome: 'What you could give without wrecking your own plan.',
        money: -200,
        happiness: 8,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Explain you cannot',
        outcome: 'Honest, and hard. Your own budget was already thin.',
        happiness: -10,
      ),
    ],
  ),
  LifeEvent(
    id: 'retirement_fund',
    prompt: 'Work offers to match retirement contributions up to 5%.',
    icon: Icons.savings_rounded,
    minAge: 23,
    choices: [
      LifeChoice(
        label: 'Contribute the full 5%',
        outcome: 'A guaranteed 100% return on that slice. Nothing beats it.',
        money: -300,
        smarts: 14,
        happiness: 5,
      ),
      LifeChoice(
        label: 'Skip it for now',
        outcome: 'More cash today. You left free money on the table.',
        happiness: 3,
        smarts: -5,
      ),
    ],
  ),
];
