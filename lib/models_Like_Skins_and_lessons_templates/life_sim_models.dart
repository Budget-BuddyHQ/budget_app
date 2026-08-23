import 'package:flutter/material.dart';

import 'finance_concepts.dart';

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
    this.fame = 0,
    this.skill,
    this.skillGain = 0,
    this.addTrait,
    this.teaches,
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

  /// Fame delta. Fame gates the bigger career events and scales their money.
  final int fame;

  /// Raises one skill — the mechanism behind "practise, then get the gig".
  final LifeSkill? skill;
  final int skillGain;

  /// Some choices reveal a trait rather than requiring one.
  final LifeTrait? addTrait;

  /// The money idea this choice is actually about.
  ///
  /// This is the hook that turns a life event from "a number moved" into a
  /// teaching moment: when set, the screen shows a short, age-appropriate
  /// explainer after the outcome, and the concept is recorded as one the
  /// player has met. Optional — plenty of events are pure story and should
  /// stay that way rather than having a lesson bolted on.
  final FinanceConcept? teaches;
}

/// A learnable skill. Skills gate career events and scale their payoff — a
/// music contract should not fire for someone who has never practised.
enum LifeSkill {
  music('Music', Icons.music_note_rounded),
  sports('Sports', Icons.sports_basketball_rounded),
  business('Business', Icons.work_rounded),
  charisma('Charisma', Icons.record_voice_over_rounded);

  const LifeSkill(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// A personality trait, rolled at birth. Traits are the "hidden modifiers"
/// layer: they bias which events can fire and nudge outcomes, so two runs
/// with identical stats still diverge.
enum LifeTrait {
  ambitious('Ambitious', Icons.trending_up_rounded),
  cautious('Cautious', Icons.shield_rounded),
  reckless('Reckless', Icons.bolt_rounded),
  generous('Generous', Icons.volunteer_activism_rounded),
  frugal('Frugal', Icons.savings_rounded);

  const LifeTrait(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// A snapshot of the character, passed to [LifeEvent.matches] so an event can
/// state its own requirements instead of the controller hard-coding them.
@immutable
class LifeContext {
  const LifeContext({
    required this.age,
    required this.money,
    required this.happiness,
    required this.health,
    required this.smarts,
    required this.fame,
    required this.skills,
    required this.traits,
    required this.hasJob,
  });

  final int age;
  final int money;
  final int happiness;
  final int health;
  final int smarts;
  final int fame;
  final Map<LifeSkill, int> skills;
  final Set<LifeTrait> traits;
  final bool hasJob;

  int skill(LifeSkill s) => skills[s] ?? 0;
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
    this.weight = 1.0,
    this.requiresSkill,
    this.minSkill = 0,
    this.requiresTrait,
    this.minFame = 0,
    this.minMoney = 0,
    this.requiresJob = false,
    this.repeatable = false,
  });

  final String id;
  final String prompt;
  final IconData icon;
  final List<LifeChoice> choices;
  final int minAge;
  final int maxAge;

  /// Relative likelihood once eligible. Everything defaults to 1.0; rare or
  /// dramatic events sit below that, common beats above.
  final double weight;

  /// Gates — an event only enters the pool when every one of these passes.
  final LifeSkill? requiresSkill;
  final int minSkill;
  final LifeTrait? requiresTrait;
  final int minFame;
  final int minMoney;
  final bool requiresJob;

  /// Whether this beat can happen more than once in a single life.
  ///
  /// Defaults to **false**, because most events are once-in-a-lifetime by
  /// nature — you discover you like music once, you leave home once. Before
  /// this flag existed the draw had no memory at all, and a simulation of 400
  /// lives showed 24 of the ~40 events in an average life were repeats, with
  /// `phone_breaks` and `crypto_tip` each firing eight times in one run. That
  /// is the single biggest reason the game felt repetitive.
  ///
  /// Set true only for things that genuinely recur — market crashes, rent
  /// rises, a car that keeps breaking. Even then the controller enforces a
  /// cooldown so they can't land in consecutive years.
  final bool repeatable;

  bool eligibleAt(int age) => age >= minAge && age <= maxAge;

  /// Full eligibility: age plus every declared requirement.
  bool matches(LifeContext c) {
    if (!eligibleAt(c.age)) return false;
    if (requiresSkill != null && c.skill(requiresSkill!) < minSkill) {
      return false;
    }
    if (requiresTrait != null && !c.traits.contains(requiresTrait)) {
      return false;
    }
    if (c.fame < minFame) return false;
    if (c.money < minMoney) return false;
    if (requiresJob && !c.hasJob) return false;
    return true;
  }
}

/// The event pool — childhood, school, friends, health and love alongside the
/// money lessons, so it plays like a life rather than a finance quiz.
/// The original hand-written pool. Kept under its own name so the
/// fill-the-gaps pack below can be added without rewriting this list —
/// [kLifeEvents] is the composed set everything actually reads.
const List<LifeEvent> _kLifeEventsCore = <LifeEvent>[
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
        outcome: 'You already know how to ask for what you want.',
        happiness: 4,
        smarts: 3,
      ),
      LifeChoice(
        label: '"Why?"',
        outcome: 'You ask a lot of questions — a very curious mind!',
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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
    repeatable: true,
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

  // ---------------- Skill discovery ----------------
  // Entry points into each career track. Common (weight 1.2) and early, so
  // most runs get the chance to start building something.
  LifeEvent(
    id: 'discover_music',
    prompt: 'The school is handing out instruments. Want one?',
    icon: Icons.music_note_rounded,
    minAge: 8,
    maxAge: 18,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Take the guitar',
        outcome: 'Three chords and a lot of enthusiasm. It is a start.',
        skill: LifeSkill.music,
        skillGain: 12,
        happiness: 6,
      ),
      LifeChoice(
        label: 'Not for me',
        outcome: 'You gave the last spot to someone else.',
        happiness: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'discover_sports',
    prompt: 'Tryouts are open for the school team.',
    icon: Icons.sports_basketball_rounded,
    minAge: 8,
    maxAge: 20,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Go all in',
        outcome: 'You made the squad. Your legs hate you.',
        skill: LifeSkill.sports,
        skillGain: 12,
        health: 6,
        happiness: 4,
      ),
      LifeChoice(
        label: 'Skip it',
        outcome: 'More time for other things.',
        smarts: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'discover_business',
    prompt: 'A local shop needs someone to help run the counter.',
    icon: Icons.work_rounded,
    minAge: 14,
    maxAge: 30,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Take the shifts',
        outcome: 'Stock, tills, and your first taste of running things.',
        skill: LifeSkill.business,
        skillGain: 14,
        money: 150,
        happiness: -2,
      ),
      LifeChoice(
        label: 'Pass',
        outcome: 'You kept your evenings.',
        happiness: 4,
      ),
    ],
  ),

  // ---------------- Career: music ----------------
  // Gated on real skill. None of these can fire for someone who never
  // picked up an instrument, which is the whole point of the skill system.
  LifeEvent(
    id: 'first_gig',
    prompt: 'A cafe offers you a Friday night slot.',
    icon: Icons.mic_rounded,
    minAge: 15,
    weight: 0.9,
    requiresSkill: LifeSkill.music,
    minSkill: 20,
    choices: [
      LifeChoice(
        label: 'Play the set',
        outcome: 'Eleven people watched. Two of them clapped. You loved it.',
        money: 60,
        // 12, not 4. record_deal below gates on fame 10, and first_gig was the
        // only event that could supply any music fame at all — so at 4 the
        // ladder stopped dead here and the top three music events were
        // mathematically unreachable. A 400-life simulation never once fired
        // record_deal, sold_out_tour or fame_scandal.
        fame: 12,
        skill: LifeSkill.music,
        skillGain: 5,
        happiness: 8,
      ),
      LifeChoice(
        label: 'Too nervous',
        outcome: 'You stayed home and practised instead.',
        skill: LifeSkill.music,
        skillGain: 3,
        happiness: -4,
      ),
    ],
  ),
  LifeEvent(
    id: 'record_deal',
    prompt: 'A small label wants to record an EP with you.',
    icon: Icons.album_rounded,
    minAge: 17,
    weight: 0.6,
    requiresSkill: LifeSkill.music,
    minSkill: 45,
    minFame: 10,
    choices: [
      LifeChoice(
        label: 'Sign it',
        outcome: 'The EP does modestly well. People know your name now.',
        money: 900,
        fame: 18,
        skill: LifeSkill.music,
        skillGain: 6,
        happiness: 12,
      ),
      LifeChoice(
        label: 'Stay independent',
        outcome: 'Less money up front, but the songs stay yours.',
        money: 250,
        fame: 8,
        happiness: 6,
        smarts: 5,
      ),
    ],
  ),
  LifeEvent(
    id: 'sold_out_tour',
    prompt: 'Your booking agent thinks you could sell out a tour.',
    icon: Icons.travel_explore_rounded,
    minAge: 19,
    weight: 0.4,
    requiresSkill: LifeSkill.music,
    minSkill: 65,
    // 26, not 35: the best reachable fame before this point is first_gig (12)
    // plus record_deal (18) = 30, and only if both fired and the player took
    // the bolder option each time.
    minFame: 26,
    choices: [
      LifeChoice(
        label: 'Book the tour',
        outcome: 'Sixteen cities. Exhausting, lucrative, unforgettable.',
        money: 4200,
        fame: 25,
        health: -10,
        happiness: 15,
      ),
      LifeChoice(
        label: 'Just a few dates',
        outcome: 'Smaller run, and you still have a voice at the end.',
        money: 1400,
        fame: 10,
        health: -3,
        happiness: 9,
      ),
    ],
  ),

  // ---------------- Career: sports & business ----------------
  LifeEvent(
    id: 'scout_visit',
    prompt: 'A scout came to watch your game.',
    icon: Icons.sports_basketball_rounded,
    minAge: 16,
    weight: 0.6,
    requiresSkill: LifeSkill.sports,
    minSkill: 45,
    choices: [
      LifeChoice(
        label: 'Play your hardest',
        outcome: 'A semi-pro contract. Modest money, real progress.',
        money: 1200,
        fame: 14,
        setJob: 'Athlete',
        setSalary: 380,
        happiness: 14,
      ),
      LifeChoice(
        label: 'Play it safe',
        outcome: 'No injury, no contract either.',
        happiness: -2,
        health: 3,
      ),
    ],
  ),
  LifeEvent(
    id: 'start_business',
    prompt: 'You have an idea worth actually starting.',
    icon: Icons.storefront_rounded,
    minAge: 20,
    weight: 0.5,
    requiresSkill: LifeSkill.business,
    minSkill: 40,
    minMoney: 500,
    choices: [
      LifeChoice(
        label: 'Fund it yourself',
        outcome: 'Lean, slow, and entirely yours.',
        money: -500,
        setJob: 'Founder',
        setSalary: 460,
        smarts: 8,
        happiness: 10,
      ),
      LifeChoice(
        label: 'Find an investor',
        outcome: 'Faster start, smaller slice.',
        money: 400,
        setJob: 'Founder',
        setSalary: 520,
        smarts: 5,
        happiness: 6,
      ),
      LifeChoice(
        label: 'Keep it a daydream',
        outcome: 'Maybe next year.',
        happiness: -3,
      ),
    ],
  ),

  // ---------------- Trait-gated ----------------
  // These only reach players carrying the matching trait — the "two runs
  // with the same stats still diverge" layer.
  LifeEvent(
    id: 'reckless_bet',
    prompt: 'Someone offers you a "sure thing" on a match.',
    icon: Icons.casino_rounded,
    minAge: 18,
    weight: 0.5,
    requiresTrait: LifeTrait.reckless,
    minMoney: 300,
    choices: [
      LifeChoice(
        label: 'Bet big',
        outcome: 'It was not a sure thing. It never is.',
        money: -300,
        happiness: -8,
        smarts: 6,
      ),
      LifeChoice(
        label: 'Walk away',
        outcome: 'Your gut said no, and for once you listened.',
        happiness: 4,
        smarts: 4,
      ),
    ],
  ),
  LifeEvent(
    id: 'frugal_windfall',
    prompt: 'You found an old account with money still in it.',
    icon: Icons.savings_rounded,
    minAge: 18,
    weight: 0.5,
    requiresTrait: LifeTrait.frugal,
    choices: [
      LifeChoice(
        label: 'Invest all of it',
        outcome: 'Straight to work. Exactly what you would do.',
        money: 400,
        smarts: 8,
      ),
      LifeChoice(
        label: 'Treat yourself, just once',
        outcome: 'You have earned it. It still felt strange.',
        money: 150,
        happiness: 10,
      ),
    ],
  ),
  LifeEvent(
    id: 'fame_scandal',
    prompt: 'A tabloid is running a story about you tomorrow.',
    icon: Icons.newspaper_rounded,
    minAge: 18,
    weight: 0.45,
    // 24, not 40 — above the reachable fame ceiling, so this never fired.
    minFame: 24,
    choices: [
      LifeChoice(
        label: 'Get ahead of it',
        outcome: 'You told your side first. It mostly worked.',
        fame: -6,
        happiness: -4,
        smarts: 6,
      ),
      LifeChoice(
        label: 'Say nothing',
        outcome: 'It ran anyway. Everyone talked about it for a week.',
        fame: 8,
        happiness: -10,
      ),
    ],
  ),
  // -------------------------------------------------------------------------
  // Adult and senior years (28+).
  //
  // A 400-life simulation showed the pool was flat at ~19 eligible events from
  // age 32 all the way to 85 — so past thirty every run drew from the same
  // handful and the back half of a life felt identical every time. These fill
  // that stretch, and stay money-decision shaped rather than pure flavour so
  // the extra length still teaches something.
  // -------------------------------------------------------------------------
  LifeEvent(
    id: 'mortgage_offer',
    prompt:
        'You have enough saved for a deposit. The bank offers you a mortgage.',
    icon: Icons.house_rounded,
    minAge: 26,
    maxAge: 55,
    minMoney: 1200,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Buy within your means',
        outcome:
            'Smaller than you wanted, comfortably affordable. You sleep fine.',
        money: -1200,
        happiness: 12,
        smarts: 10,
      ),
      LifeChoice(
        label: 'Stretch for the bigger place',
        outcome: 'Beautiful house. Every month is tight and you feel it.',
        money: -2000,
        happiness: 6,
        health: -6,
        smarts: -3,
      ),
      LifeChoice(
        label: 'Keep renting and invest instead',
        outcome:
            'No garden, but the deposit stays invested and liquid.',
        happiness: -2,
        smarts: 8,
      ),
    ],
  ),
  LifeEvent(
    id: 'promotion_or_balance',
    prompt: 'You are offered a promotion. More money, noticeably more hours.',
    icon: Icons.stairs_rounded,
    minAge: 27,
    maxAge: 58,
    requiresJob: true,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Take it',
        outcome: 'The pay rise is real. So is the calendar.',
        setSalary: 520,
        money: 200,
        happiness: -5,
        health: -5,
        smarts: 6,
      ),
      LifeChoice(
        label: 'Turn it down',
        outcome: 'You kept your evenings. Your manager was surprised.',
        happiness: 10,
        health: 4,
      ),
      LifeChoice(
        label: 'Negotiate a middle version',
        outcome: 'Half the extra scope, most of the raise. Nobody expected it.',
        setSalary: 440,
        happiness: 4,
        smarts: 12,
      ),
    ],
  ),
  LifeEvent(
    id: 'first_child',
    prompt: 'You are becoming a parent.',
    icon: Icons.child_friendly_rounded,
    minAge: 24,
    maxAge: 45,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Start a savings account for them',
        outcome:
            'Small monthly amounts, eighteen years of compounding ahead.',
        money: -300,
        happiness: 18,
        smarts: 10,
        addRelationship: 'Your child',
      ),
      LifeChoice(
        label: 'Focus on the here and now',
        outcome: 'Everything goes on the present. It is a good present.',
        money: -500,
        happiness: 20,
        addRelationship: 'Your child',
      ),
    ],
  ),
  LifeEvent(
    id: 'redundancy',
    prompt: 'Your company restructures. Your role is gone.',
    icon: Icons.work_off_rounded,
    minAge: 25,
    maxAge: 60,
    requiresJob: true,
    weight: 0.7,
    choices: [
      LifeChoice(
        label: 'Live off the emergency fund and search properly',
        outcome:
            'Three stressful months, then a better job than the old one.',
        money: -400,
        setSalary: 480,
        smarts: 12,
        happiness: -6,
      ),
      LifeChoice(
        label: 'Take the first thing offered',
        outcome: 'The gap was short. The pay cut was not.',
        setSalary: 260,
        happiness: -8,
      ),
      LifeChoice(
        label: 'Go freelance',
        outcome: 'Unpredictable months, but the good ones are very good.',
        setJob: 'Freelancer',
        setSalary: 400,
        happiness: 5,
        smarts: 8,
      ),
    ],
  ),
  LifeEvent(
    id: 'parent_needs_help',
    prompt: 'A parent is struggling with money and has not asked directly.',
    icon: Icons.elderly_rounded,
    minAge: 30,
    maxAge: 65,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Help monthly, within a set limit',
        outcome: 'Sustainable for you, and it genuinely changes their year.',
        money: -400,
        happiness: 10,
        smarts: 8,
      ),
      LifeChoice(
        label: 'Give everything you can spare',
        outcome: 'Generous. It also emptied your own buffer.',
        money: -900,
        happiness: 12,
        smarts: -4,
      ),
      LifeChoice(
        label: 'Help them build a budget instead',
        outcome:
            'Harder conversation, longer-lasting than any single transfer.',
        happiness: 4,
        smarts: 16,
      ),
    ],
  ),
  LifeEvent(
    id: 'health_scare',
    prompt: 'A routine scan finds something the doctor wants to watch.',
    icon: Icons.monitor_heart_rounded,
    minAge: 38,
    weight: 0.8,
    choices: [
      LifeChoice(
        label: 'Change how you live',
        outcome: 'Duller weekends, considerably more of them.',
        health: 18,
        happiness: -4,
        smarts: 6,
      ),
      LifeChoice(
        label: 'Carry on as before',
        outcome: 'You felt fine, so you did nothing. It stayed on the file.',
        health: -12,
        happiness: 3,
      ),
    ],
  ),
  LifeEvent(
    id: 'pay_off_mortgage',
    prompt: 'You could clear the rest of the mortgage in one payment.',
    icon: Icons.done_all_rounded,
    minAge: 40,
    minMoney: 2500,
    weight: 0.8,
    choices: [
      LifeChoice(
        label: 'Clear it',
        outcome: 'No more interest, no more monthly. The relief is physical.',
        money: -2500,
        happiness: 20,
        smarts: 8,
      ),
      LifeChoice(
        label: 'Keep the cash invested',
        outcome:
            'The maths favours you if returns beat the interest rate. If.',
        smarts: 10,
        happiness: -2,
      ),
    ],
  ),
  LifeEvent(
    id: 'inheritance',
    prompt: 'A relative leaves you a sum you were not expecting.',
    icon: Icons.card_giftcard_rounded,
    minAge: 30,
    weight: 0.55,
    choices: [
      LifeChoice(
        label: 'Invest most, spend a little',
        outcome: 'One good holiday, and the rest still working for you.',
        money: 1800,
        happiness: 12,
        smarts: 12,
      ),
      LifeChoice(
        label: 'Spend it on something you have always wanted',
        outcome: 'Wonderful. Gone within the year.',
        money: 400,
        happiness: 20,
        smarts: -5,
      ),
      LifeChoice(
        label: 'Split it with siblings beyond the will',
        outcome: 'Less money, a family that still speaks at Christmas.',
        money: 900,
        happiness: 15,
        addRelationship: 'Your sibling',
      ),
    ],
  ),
  LifeEvent(
    id: 'career_change',
    prompt:
        'You are good at your job and no longer interested in it.',
    icon: Icons.swap_horiz_rounded,
    minAge: 33,
    maxAge: 55,
    requiresJob: true,
    weight: 0.75,
    choices: [
      LifeChoice(
        label: 'Retrain while still employed',
        outcome: 'Two exhausting years, then a job you actually want.',
        money: -600,
        setSalary: 460,
        happiness: 14,
        smarts: 16,
      ),
      LifeChoice(
        label: 'Stay and make peace with it',
        outcome: 'Stable, well paid, and quietly flat.',
        money: 200,
        happiness: -6,
      ),
    ],
  ),
  LifeEvent(
    id: 'business_partner_offer',
    prompt: 'A friend wants you to co-found something with them.',
    icon: Icons.groups_rounded,
    minAge: 26,
    maxAge: 55,
    minMoney: 600,
    weight: 0.7,
    choices: [
      LifeChoice(
        label: 'Invest and join',
        outcome: 'Terrifying, occasionally brilliant. You learned a decade.',
        money: -600,
        happiness: 8,
        smarts: 18,
        skill: LifeSkill.business,
        skillGain: 14,
      ),
      LifeChoice(
        label: 'Advise without investing',
        outcome: 'You kept the friendship and your deposit.',
        smarts: 8,
        happiness: 4,
      ),
      LifeChoice(
        label: 'Say no clearly',
        outcome: 'Awkward for a month. Correct for you.',
        happiness: -3,
        smarts: 5,
      ),
    ],
  ),
  LifeEvent(
    id: 'pension_review',
    prompt: 'You finally open the pension statement you have been ignoring.',
    icon: Icons.savings_rounded,
    minAge: 35,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Increase the contribution',
        outcome:
            'A few coins less each month now, a different retirement later.',
        money: -250,
        smarts: 16,
        happiness: 4,
      ),
      LifeChoice(
        label: 'Check the fees and switch funds',
        outcome:
            'You were paying 1% for nothing. Now you are paying almost none.',
        money: 150,
        smarts: 18,
      ),
      LifeChoice(
        label: 'Close it again',
        outcome: 'Out of sight. The default fund keeps doing whatever it does.',
        happiness: 2,
        smarts: -6,
      ),
    ],
  ),
  LifeEvent(
    id: 'midlife_reassessment',
    prompt: 'You catch yourself wondering whether this is it.',
    icon: Icons.psychology_rounded,
    minAge: 40,
    maxAge: 58,
    weight: 0.85,
    choices: [
      LifeChoice(
        label: 'Buy the thing you have always wanted',
        outcome: 'It was fun for a season. The feeling came back.',
        money: -1100,
        happiness: 12,
        smarts: -4,
      ),
      LifeChoice(
        label: 'Change something structural instead',
        outcome:
            'Fewer hours, less money, more of your own life. It stuck.',
        money: -300,
        happiness: 18,
        health: 8,
        smarts: 10,
      ),
    ],
  ),
  LifeEvent(
    id: 'help_child_deposit',
    prompt: 'Your child asks for help with a house deposit.',
    icon: Icons.family_restroom_rounded,
    minAge: 48,
    minMoney: 1500,
    weight: 0.85,
    choices: [
      LifeChoice(
        label: 'Give what you can spare',
        outcome: 'They got the place. You kept your own retirement intact.',
        money: -1200,
        happiness: 16,
        smarts: 8,
      ),
      LifeChoice(
        label: 'Lend it, written down',
        outcome:
            'Awkward to put on paper, much less awkward five years later.',
        money: -1200,
        happiness: 8,
        smarts: 14,
      ),
      LifeChoice(
        label: 'Explain why you cannot',
        outcome: 'Hard to say. They understood more than you expected.',
        happiness: -6,
        smarts: 6,
      ),
    ],
  ),
  LifeEvent(
    id: 'downsize_home',
    prompt: 'The house is bigger than you need now.',
    icon: Icons.holiday_village_rounded,
    minAge: 55,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Downsize and free the money',
        outcome: 'Smaller rooms, a much larger cushion.',
        money: 2200,
        happiness: 6,
        smarts: 12,
      ),
      LifeChoice(
        label: 'Stay for the memories',
        outcome: 'Every room has something in it. Worth the upkeep to you.',
        money: -400,
        happiness: 12,
      ),
    ],
  ),
  LifeEvent(
    id: 'retirement_decision',
    prompt: 'You could retire now, or work three more years.',
    icon: Icons.beach_access_rounded,
    minAge: 60,
    maxAge: 70,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Retire now',
        outcome: 'Less money, and every morning is yours.',
        happiness: 20,
        health: 6,
        setJob: 'Retired',
        setSalary: 0,
      ),
      LifeChoice(
        label: 'Work three more years',
        outcome:
            'The pension is meaningfully bigger for it. So were the years.',
        money: 1400,
        happiness: -6,
        health: -6,
        smarts: 4,
      ),
    ],
  ),
  LifeEvent(
    id: 'scam_target',
    prompt:
        'Someone calls claiming to be your bank, urgently, asking you to move '
        'money to a "safe account".',
    icon: Icons.phone_in_talk_rounded,
    minAge: 55,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Hang up and ring the bank yourself',
        outcome: 'The bank had never called. You did exactly the right thing.',
        smarts: 18,
        happiness: 6,
      ),
      LifeChoice(
        label: 'Do as they ask',
        outcome:
            'It was not your bank. Some of it came back, slowly.',
        money: -1400,
        happiness: -18,
        smarts: 8,
      ),
    ],
  ),
  LifeEvent(
    id: 'write_a_will',
    prompt: 'You have been meaning to write a will for years.',
    icon: Icons.description_rounded,
    minAge: 50,
    weight: 0.95,
    choices: [
      LifeChoice(
        label: 'Write it properly',
        outcome:
            'An unpleasant afternoon that saves your family a terrible year.',
        money: -200,
        smarts: 16,
        happiness: 8,
      ),
      LifeChoice(
        label: 'Put it off again',
        outcome: 'Next year. Definitely next year.',
        happiness: 2,
        smarts: -4,
      ),
    ],
  ),
  LifeEvent(
    id: 'grandchild',
    prompt: 'You become a grandparent.',
    icon: Icons.child_care_rounded,
    minAge: 55,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Open a long-term account for them',
        outcome:
            'Eighteen years of compounding, started the week they were born.',
        money: -400,
        happiness: 22,
        smarts: 12,
        addRelationship: 'Your grandchild',
      ),
      LifeChoice(
        label: 'Spoil them thoroughly',
        outcome: 'You are the favourite and you know exactly why.',
        money: -500,
        happiness: 24,
        addRelationship: 'Your grandchild',
      ),
    ],
  ),
  LifeEvent(
    id: 'late_life_investing',
    prompt:
        'A friend insists you should move your savings into something with '
        'much higher returns.',
    icon: Icons.query_stats_rounded,
    minAge: 62,
    minMoney: 800,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Keep it conservative',
        outcome:
            'Boring, and appropriate — you no longer have decades to recover.',
        money: 200,
        smarts: 16,
      ),
      LifeChoice(
        label: 'Chase the return',
        outcome: 'It moved a lot. Not always upward, and not for long enough.',
        money: -700,
        happiness: -10,
        smarts: 6,
      ),
    ],
  ),
  LifeEvent(
    id: 'volunteer_years',
    prompt: 'A local charity needs someone with your experience.',
    icon: Icons.volunteer_activism_rounded,
    minAge: 58,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Give them a day a week',
        outcome: 'You are useful again, on your own terms.',
        happiness: 16,
        health: 6,
        smarts: 6,
        addRelationship: 'The Thursday crew',
      ),
      LifeChoice(
        label: 'Donate money instead',
        outcome: 'Genuinely helpful, and considerably less of your time.',
        money: -300,
        happiness: 8,
      ),
    ],
  ),
  LifeEvent(
    id: 'teach_someone',
    prompt: 'A younger colleague asks you to mentor them.',
    icon: Icons.school_rounded,
    minAge: 35,
    maxAge: 68,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Say yes',
        outcome:
            'You learned as much as they did, which nobody warns you about.',
        happiness: 12,
        smarts: 10,
        skill: LifeSkill.charisma,
        skillGain: 10,
        addRelationship: 'Your mentee',
      ),
      LifeChoice(
        label: 'You have no time',
        outcome: 'True, and it stayed true.',
        happiness: -3,
      ),
    ],
  ),
  LifeEvent(
    id: 'big_repair_bill',
    prompt: 'The roof needs work. It is not optional.',
    icon: Icons.roofing_rounded,
    minAge: 30,
    repeatable: true,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Pay from the emergency fund',
        outcome: 'Exactly what the fund was for. Rebuild it next year.',
        money: -700,
        smarts: 10,
      ),
      LifeChoice(
        label: 'Put it on credit',
        outcome: 'Fixed today, and more expensive by the time it is paid off.',
        money: -950,
        happiness: -6,
        smarts: -3,
      ),
      LifeChoice(
        label: 'Patch it yourself',
        outcome: 'Held for two winters, then cost more than doing it properly.',
        money: -250,
        health: -5,
        happiness: -2,
      ),
    ],
  ),
  LifeEvent(
    id: 'tax_return_choice',
    prompt: 'Your tax return is more complicated than last year.',
    icon: Icons.receipt_long_rounded,
    minAge: 26,
    repeatable: true,
    requiresJob: true,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Pay an accountant',
        outcome: 'They found reliefs you had never heard of. Net positive.',
        money: 220,
        smarts: 10,
      ),
      LifeChoice(
        label: 'Do it yourself carefully',
        outcome: 'A long weekend, and you now understand your own money.',
        money: 80,
        smarts: 16,
        happiness: -4,
      ),
      LifeChoice(
        label: 'Rush it the night before',
        outcome: 'Filed on time. Probably overpaid.',
        money: -180,
        happiness: -4,
      ),
    ],
  ),
  LifeEvent(
    id: 'friend_business_pitch',
    prompt:
        'An old friend pitches you an investment that "cannot lose".',
    icon: Icons.campaign_rounded,
    minAge: 28,
    minMoney: 500,
    repeatable: true,
    weight: 0.8,
    choices: [
      LifeChoice(
        label: 'Ask for the numbers in writing',
        outcome: 'They never sent them. That was the answer.',
        smarts: 16,
        happiness: 2,
      ),
      LifeChoice(
        label: 'Put in what you can afford to lose',
        outcome: 'It went sideways, but only a slice of you went with it.',
        money: -300,
        smarts: 10,
      ),
      LifeChoice(
        label: 'Go all in',
        outcome: 'Nothing that cannot lose has ever been described that way.',
        money: -1100,
        happiness: -14,
        smarts: 6,
      ),
    ],
  ),
  LifeEvent(
    id: 'sabbatical',
    prompt: 'Your employer offers unpaid leave for three months.',
    icon: Icons.flight_takeoff_rounded,
    minAge: 30,
    maxAge: 60,
    requiresJob: true,
    minMoney: 900,
    weight: 0.7,
    choices: [
      LifeChoice(
        label: 'Take it and travel',
        outcome: 'Expensive, and one of the things you still talk about.',
        money: -900,
        happiness: 22,
        health: 6,
      ),
      LifeChoice(
        label: 'Take it and rest',
        outcome: 'You slept, walked, and came back a different colleague.',
        money: -400,
        happiness: 16,
        health: 12,
      ),
      LifeChoice(
        label: 'Decline',
        outcome: 'Three more months of salary, and the offer did not return.',
        money: 500,
        happiness: -6,
      ),
    ],
  ),
  LifeEvent(
    id: 'estate_conversation',
    prompt: 'Your family has never talked about what happens later.',
    icon: Icons.forum_rounded,
    minAge: 62,
    weight: 0.95,
    choices: [
      LifeChoice(
        label: 'Have the conversation',
        outcome:
            'Uncomfortable for an hour, and it removed a decade of guessing.',
        happiness: 10,
        smarts: 16,
      ),
      LifeChoice(
        label: 'Leave instructions in a drawer',
        outcome: 'Better than nothing. Somebody will find it eventually.',
        smarts: 4,
      ),
    ],
  ),
  LifeEvent(
    id: 'second_wind',
    prompt: 'You have time, savings, and an idea you never tried.',
    icon: Icons.wb_sunny_rounded,
    minAge: 63,
    minMoney: 700,
    weight: 0.85,
    choices: [
      LifeChoice(
        label: 'Start it small',
        outcome: 'It never made much. It made your seventies.',
        money: -400,
        happiness: 20,
        smarts: 10,
        skill: LifeSkill.business,
        skillGain: 10,
      ),
      LifeChoice(
        label: 'Enjoy the rest instead',
        outcome: 'You had earned it, and you knew it.',
        happiness: 12,
        health: 6,
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Fill-the-gaps event pack
//
// The original pool clustered around 14-28 and left real holes: ages 10-11
// had nothing at all, and 29-64 was thin enough that a long life replayed
// the same handful of beats. These widen the middle and late game, and lean
// on non-money life texture (friends, family, health, housing) as well as
// the money spine — a life that is only budgeting decisions stops reading
// as a life.
// ---------------------------------------------------------------------------
const List<LifeEvent> kLifeEventsExtra = <LifeEvent>[
  // ---------------- The 10-11 hole ----------------
  LifeEvent(
    id: 'x_lemonade_stand',
    prompt:
        'You and a friend want to run a lemonade stand. Cups and lemons cost '
        'money up front.',
    icon: Icons.local_drink_rounded,
    minAge: 9,
    maxAge: 12,
    choices: [
      LifeChoice(
        label: 'Work out the costs first',
        outcome:
            'You counted what supplies cost before setting a price. That is '
            'the whole idea behind profit.',
        money: 15,
        smarts: 6,
        happiness: 4,
      ),
      LifeChoice(
        label: 'Just start selling',
        outcome:
            'You sold a lot and still ended up down. Selling is not the same '
            'as earning.',
        money: -5,
        smarts: 3,
        happiness: 3,
      ),
      LifeChoice(
        label: 'Give the lemonade away',
        outcome: 'No money, plenty of friends.',
        happiness: 7,
        addRelationship: 'Neighbourhood friend',
      ),
    ],
  ),
  LifeEvent(
    id: 'x_first_allowance_choice',
    prompt:
        'You get your first regular allowance. There is a toy you want that '
        'costs three weeks of it.',
    icon: Icons.savings_rounded,
    minAge: 9,
    maxAge: 13,
    choices: [
      LifeChoice(
        label: 'Save for three weeks',
        outcome:
            'You waited and bought it outright. Waiting is a skill, and you '
            'just used it.',
        smarts: 6,
        happiness: 6,
      ),
      LifeChoice(
        label: 'Spend it weekly on small stuff',
        outcome:
            'Gone every week, and the toy never happened. Small spending is '
            'still spending.',
        happiness: 3,
        money: -6,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_school_club',
    prompt: 'A club at school is recruiting. It meets twice a week.',
    icon: Icons.groups_rounded,
    minAge: 10,
    maxAge: 15,
    choices: [
      LifeChoice(
        label: 'Join it',
        outcome: 'You found people who like the same things you do.',
        happiness: 8,
        smarts: 4,
        addRelationship: 'Club friend',
      ),
      LifeChoice(
        label: 'Skip it and keep your time',
        outcome: 'Quieter weeks. Not a wrong answer.',
        happiness: 2,
      ),
    ],
  ),

  // ---------------- Late 20s / 30s ----------------
  LifeEvent(
    id: 'x_moving_in',
    prompt:
        'Someone you have been seeing suggests moving in together. It would '
        'halve your rent.',
    icon: Icons.favorite_rounded,
    minAge: 24,
    maxAge: 40,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Move in together',
        outcome:
            'Rent split, life shared. Splitting fixed costs is one of the '
            'biggest money moves there is.',
        money: 2400,
        happiness: 10,
        addRelationship: 'Partner',
      ),
      LifeChoice(
        label: 'Not yet',
        outcome: 'You kept your own place and your own pace.',
        happiness: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_car_dies',
    prompt: 'Your car makes a noise it has never made before. The repair is '
        'about \$1,200.',
    icon: Icons.car_repair_rounded,
    minAge: 20,
    maxAge: 65,
    weight: 1.1,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Pay from savings',
        outcome:
            'This is exactly what an emergency fund is for. Boring right up '
            'until the week it saves you.',
        money: -1200,
        happiness: -2,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Put it on a credit card',
        outcome:
            'Fixed today, more expensive later — interest turns \$1,200 into '
            'more than \$1,200.',
        money: -1500,
        happiness: -5,
      ),
      LifeChoice(
        label: 'Ignore it and hope',
        outcome:
            'It got worse. Deferred maintenance is usually a loan at a bad '
            'rate.',
        money: -2200,
        happiness: -8,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_raise_offer',
    prompt: 'Your manager offers a raise — or the same money plus every '
        'Friday off.',
    icon: Icons.more_time_rounded,
    minAge: 24,
    maxAge: 60,
    requiresJob: true,
    choices: [
      LifeChoice(
        label: 'Take the raise',
        outcome: 'More money, same hours.',
        money: 4000,
        happiness: 4,
      ),
      LifeChoice(
        label: 'Take the Fridays',
        outcome:
            'You bought time with money you never saw. That is a real trade, '
            'not a lost one.',
        happiness: 14,
        health: 6,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_side_project',
    prompt: 'You have an idea for something you could sell on the side.',
    icon: Icons.lightbulb_rounded,
    minAge: 18,
    maxAge: 55,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Spend evenings building it',
        outcome:
            'Slow, tiring, and it made real money. Second income streams '
            'usually start ugly.',
        money: 1800,
        happiness: -3,
        smarts: 8,
      ),
      LifeChoice(
        label: 'Keep it as a hobby',
        outcome: 'No pressure, no income. Also fine.',
        happiness: 6,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_friend_loan',
    prompt: 'A close friend asks to borrow \$500. They are good for it — '
        'probably.',
    icon: Icons.handshake_rounded,
    minAge: 18,
    maxAge: 70,
    weight: 0.8,
    choices: [
      LifeChoice(
        label: 'Lend it',
        outcome:
            'They paid back most of it, eventually. Money between friends is '
            'rarely just money.',
        money: -150,
        happiness: -2,
      ),
      LifeChoice(
        label: 'Give them \$100 instead, no repayment',
        outcome:
            'Smaller help, no debt hanging between you. Often the version '
            'that keeps the friendship.',
        money: -100,
        happiness: 5,
        smarts: 5,
      ),
      LifeChoice(
        label: 'Say no, kindly',
        outcome: 'Awkward for a week. Your budget stayed intact.',
        happiness: -3,
        smarts: 3,
      ),
    ],
  ),

  // ---------------- 40s / 50s ----------------
  LifeEvent(
    id: 'x_health_checkup',
    prompt: 'You have been putting off a check-up for two years.',
    icon: Icons.medical_services_rounded,
    minAge: 35,
    maxAge: 70,
    weight: 1.1,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Go and get it done',
        outcome:
            'Caught something small before it became something expensive. '
            'Prevention is the cheapest healthcare there is.',
        money: -120,
        health: 12,
        smarts: 3,
      ),
      LifeChoice(
        label: 'Put it off again',
        outcome: 'Nothing happened. This time.',
        health: -6,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_kid_money_talk',
    prompt:
        'A younger relative asks you how money actually works. They are '
        'genuinely asking.',
    icon: Icons.family_restroom_rounded,
    minAge: 28,
    maxAge: 75,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Sit down and explain it properly',
        outcome:
            'You taught someone what took you years to learn. That compounds '
            'too.',
        happiness: 12,
        smarts: 6,
        addRelationship: 'Someone who looks up to you',
      ),
      LifeChoice(
        label: '"Just save more"',
        outcome: 'Technically true. Completely useless as advice.',
        happiness: 2,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_retirement_review',
    prompt:
        'A letter arrives about your retirement account. You have not looked '
        'at it in years.',
    icon: Icons.account_balance_rounded,
    minAge: 40,
    maxAge: 70,
    choices: [
      LifeChoice(
        label: 'Actually read it and check the fees',
        outcome:
            'You found a fee quietly eating returns and moved the money. '
            'Fees are small numbers doing large damage.',
        money: 3000,
        smarts: 10,
      ),
      LifeChoice(
        label: 'File it unopened',
        outcome: 'It kept doing whatever it was doing.',
        happiness: 1,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_downsize',
    prompt: 'The house is bigger than you need now. Selling would free up a '
        'lot of money.',
    icon: Icons.home_work_rounded,
    minAge: 50,
    maxAge: 80,
    weight: 0.8,
    choices: [
      LifeChoice(
        label: 'Downsize',
        outcome:
            'Smaller place, smaller bills, more freedom. Housing is most '
            'people\'s biggest line item.',
        money: 40000,
        happiness: 6,
      ),
      LifeChoice(
        label: 'Stay put',
        outcome: 'It is home. Some things are not a spreadsheet.',
        happiness: 8,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_scam_call',
    prompt:
        'Someone calls claiming to be your bank. They need your details to '
        '"secure your account", urgently.',
    icon: Icons.phone_in_talk_rounded,
    minAge: 16,
    maxAge: 90,
    weight: 1.2,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Hang up and call the bank yourself',
        outcome:
            'Correct. Urgency is the oldest tool in the scam kit — a real '
            'bank never needs your password.',
        smarts: 12,
        happiness: 3,
      ),
      LifeChoice(
        label: 'Give them the details',
        outcome:
            'It was a scam. The money took weeks to claw back, and some of '
            'it never came.',
        money: -900,
        happiness: -12,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_subscription_audit',
    prompt: 'Your bank statement shows six subscriptions. You recognise four.',
    icon: Icons.receipt_long_rounded,
    minAge: 18,
    maxAge: 80,
    weight: 1.1,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Cancel the two you forgot',
        outcome:
            'Found money. Forgotten subscriptions are the quietest leak in '
            'most budgets.',
        money: 240,
        smarts: 6,
      ),
      LifeChoice(
        label: 'Leave them, it is only a few dollars',
        outcome:
            '"Only a few dollars" times twelve months times two is not a few '
            'dollars.',
        money: -240,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_mentor',
    prompt: 'Someone senior at work offers to mentor you.',
    icon: Icons.school_rounded,
    minAge: 20,
    maxAge: 55,
    requiresJob: true,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Say yes',
        outcome:
            'They shortcut years of trial and error for you.',
        smarts: 12,
        happiness: 6,
        addRelationship: 'Mentor',
      ),
      LifeChoice(
        label: 'Decline politely',
        outcome: 'You figured it out the long way.',
        smarts: 4,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_market_drop',
    prompt:
        'The market drops hard. Your investments are down 25% on paper and '
        'the news is loud about it.',
    icon: Icons.trending_down_rounded,
    minAge: 22,
    maxAge: 80,
    weight: 0.9,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Do nothing and wait',
        outcome:
            'It recovered. A paper loss only becomes a real one when you '
            'sell into the panic.',
        money: 2500,
        smarts: 10,
      ),
      LifeChoice(
        label: 'Sell everything',
        outcome:
            'You locked the loss in, then watched it climb back without you.',
        money: -3000,
        happiness: -8,
      ),
      LifeChoice(
        label: 'Buy more while it is cheap',
        outcome:
            'Nerve-wracking, and it worked out. It does not always — that is '
            'what risk means.',
        money: 4000,
        happiness: 4,
      ),
    ],
  ),
];

/// Ages 4-8 specifically. The first pass at filling gaps started at 9 and
/// left the youngest years thin enough that `life_variety_test`'s childhood
/// guard failed at age 5 with only two eligible events.
const List<LifeEvent> kLifeEventsEarly = <LifeEvent>[
  LifeEvent(
    id: 'x_lost_tooth',
    prompt: 'You lost a tooth. There is a coin under your pillow.',
    icon: Icons.savings_rounded,
    minAge: 4,
    maxAge: 9,
    choices: [
      LifeChoice(
        label: 'Put it in your piggy bank',
        outcome: 'Saved. That is the first time you chose later over now.',
        money: 5,
        smarts: 4,
        happiness: 4,
      ),
      LifeChoice(
        label: 'Spend it on sweets today',
        outcome: 'Gone in an afternoon, and it was a good afternoon.',
        happiness: 7,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_share_toy',
    prompt: 'Another kid wants a turn with your favourite toy.',
    icon: Icons.child_friendly_rounded,
    minAge: 4,
    maxAge: 8,
    choices: [
      LifeChoice(
        label: 'Share it',
        outcome: 'They shared theirs back. You both got two toys.',
        happiness: 7,
        addRelationship: 'Playground friend',
      ),
      LifeChoice(
        label: 'Keep it to yourself',
        outcome: 'Still your toy. Quieter playtime.',
        happiness: 1,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_helping_chore',
    prompt: 'A grown-up asks if you want to help carry the shopping.',
    icon: Icons.shopping_basket_rounded,
    minAge: 4,
    maxAge: 10,
    choices: [
      LifeChoice(
        label: 'Help out',
        outcome:
            'You noticed food costs money at the till. Small thing, big idea.',
        happiness: 5,
        smarts: 5,
      ),
      LifeChoice(
        label: 'Keep playing',
        outcome: 'Fair enough. You are five.',
        happiness: 3,
      ),
    ],
  ),
  LifeEvent(
    id: 'x_birthday_money',
    prompt: 'A relative gives you birthday money.',
    icon: Icons.cake_rounded,
    minAge: 4,
    maxAge: 12,
    choices: [
      LifeChoice(
        label: 'Save half, spend half',
        outcome:
            'Splitting it was the whole lesson: you got something now *and* '
            'something later.',
        money: 10,
        smarts: 7,
        happiness: 6,
      ),
      LifeChoice(
        label: 'Spend all of it',
        outcome: 'A very good day, and an empty pocket.',
        happiness: 9,
      ),
      LifeChoice(
        label: 'Save all of it',
        outcome: 'Nothing today, more than anyone else by next month.',
        money: 20,
        smarts: 5,
      ),
    ],
  ),
];

/// Every Life event the game draws from: the original pool plus the
/// fill-the-gaps pack. Composed rather than merged by hand so the two sets
/// stay separately readable.

/// Events whose whole job is to teach a money idea.
///
/// **Why these are a separate list.** The existing pools grew as *story* —
/// they move stats and give a life texture, and only incidentally touch
/// money. That left the app in the position the owner called out: lots of
/// features, plenty to do, but nothing that reliably taught budgeting.
///
/// Every choice in this list carries a [LifeChoice.teaches], so whichever
/// option the player picks, the game names the idea afterwards (see
/// `LifeSimController.chooseOption` and `_MoneyLessonSheet`). Both branches
/// teach the same concept — picking the "worse" option is not punished with
/// silence, it is the more instructive path.
///
/// Deliberately spread across ages so a six year old and a nineteen year
/// old each meet ideas pitched at their life, not just at an adult's.
const List<LifeEvent> kLifeEventsMoney = <LifeEvent>[
  // ---- Young children -------------------------------------------------
  LifeEvent(
    id: 'm_two_pockets',
    prompt:
        'You get pocket money. A grown-up shows you two jars: one for '
        'spending, one for saving.',
    icon: Icons.savings_rounded,
    minAge: 5,
    maxAge: 10,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Put some in the saving jar first',
        outcome:
            'You split it before you spent any. The saving jar started '
            'filling up on its own.',
        money: 8,
        smarts: 5,
        happiness: 3,
        teaches: FinanceConcept.payYourselfFirst,
      ),
      LifeChoice(
        label: 'Keep it all in the spending jar',
        outcome:
            'It was all gone by the weekend. The saving jar stayed empty.',
        money: 3,
        happiness: 5,
        teaches: FinanceConcept.payYourselfFirst,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_shop_choice',
    prompt:
        'At the shop you have enough money for the toy OR the new shoes '
        'you actually need. Not both.',
    icon: Icons.shopping_basket_rounded,
    minAge: 5,
    maxAge: 11,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Get the shoes',
        outcome: 'Not exciting. But your feet stopped hurting.',
        health: 5,
        smarts: 4,
        happiness: -1,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Get the toy',
        outcome:
            'Brilliant for a week. The shoes still needed buying later.',
        happiness: 8,
        money: -10,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_wait_a_day',
    prompt:
        'You REALLY want something you saw today. You could buy it now, or '
        'wait until tomorrow to decide.',
    icon: Icons.flash_on_rounded,
    minAge: 6,
    maxAge: 14,
    weight: 1.2,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Sleep on it',
        outcome:
            'By morning you had gone off it. You kept the money and did '
            'not miss the thing at all.',
        money: 12,
        smarts: 5,
        teaches: FinanceConcept.impulseSpending,
      ),
      LifeChoice(
        label: 'Buy it right now',
        outcome:
            'The excitement lasted about an hour. It is somewhere in a '
            'drawer now.',
        money: -14,
        happiness: 4,
        teaches: FinanceConcept.impulseSpending,
      ),
    ],
  ),

  // ---- Older kids and teens -------------------------------------------
  LifeEvent(
    id: 'm_saving_goal',
    prompt:
        'You want something big — far more than you have. A friend says '
        'just ask for it as a present.',
    icon: Icons.flag_rounded,
    minAge: 9,
    maxAge: 16,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Set a savings target and chip away',
        outcome:
            'It took months. Getting there yourself felt different to '
            'being handed it.',
        money: 25,
        smarts: 6,
        happiness: 6,
        teaches: FinanceConcept.payYourselfFirst,
      ),
      LifeChoice(
        label: 'Just ask someone to buy it',
        outcome:
            'You got it sooner. You also learned nothing about how to get '
            'the next one.',
        happiness: 6,
        teaches: FinanceConcept.payYourselfFirst,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_first_payslip',
    prompt:
        'Your first payslip. The number at the bottom is smaller than the '
        'hourly rate you were promised.',
    icon: Icons.receipt_long_rounded,
    minAge: 15,
    maxAge: 24,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Read the deductions line by line',
        outcome:
            'Tax and national insurance. Now you know gross pay and '
            'take-home pay are different numbers.',
        smarts: 8,
        teaches: FinanceConcept.taxes,
      ),
      LifeChoice(
        label: 'Assume it is a mistake and ignore it',
        outcome:
            'It was not a mistake. You budgeted off the wrong number for '
            'months.',
        money: -20,
        happiness: -3,
        teaches: FinanceConcept.taxes,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_phone_contract',
    prompt:
        'A shop offers the newest phone for "only" a small amount a month, '
        'over three years.',
    icon: Icons.credit_card_rounded,
    minAge: 16,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Multiply it out first',
        outcome:
            'Thirty-six payments came to far more than the phone costs '
            'outright. You bought last year is model instead.',
        money: 60,
        smarts: 7,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Sign — it is only a few coins a month',
        outcome:
            'The monthly amount was painless. The total was not.',
        money: -90,
        happiness: 5,
        teaches: FinanceConcept.interestCost,
      ),
    ],
  ),

  // ---- Adults ----------------------------------------------------------
  LifeEvent(
    id: 'm_first_raise',
    prompt: 'You got a raise. Your flat, car and habits all still work fine.',
    icon: Icons.moving_rounded,
    minAge: 20,
    requiresJob: true,
    weight: 1.2,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Keep living on the old amount, save the difference',
        outcome:
            'Nothing about your week changed, and your savings jumped. '
            'That gap is the whole trick.',
        money: 140,
        smarts: 6,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Upgrade the flat to match',
        outcome:
            'Nicer place, same empty account at month end. The raise '
            'vanished into rent.',
        happiness: 7,
        money: -40,
        teaches: FinanceConcept.lifestyleCreep,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_card_offer',
    prompt:
        'A credit card arrives pre-approved. The limit is more than you '
        'earn in two months.',
    icon: Icons.speed_rounded,
    minAge: 18,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Use it small and clear it in full monthly',
        outcome:
            'Paid off every month, so it never cost interest — and it '
            'quietly built a payment history lenders like.',
        smarts: 6,
        money: 20,
        teaches: FinanceConcept.creditScore,
      ),
      LifeChoice(
        label: 'Treat the limit as money you have',
        outcome:
            'The balance stopped going down. Interest made sure of that.',
        money: -120,
        happiness: 4,
        teaches: FinanceConcept.creditScore,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_invest_early',
    prompt:
        'You have some spare money and forty years until you would need '
        'it.',
    icon: Icons.trending_up_rounded,
    minAge: 18,
    maxAge: 35,
    minMoney: 150,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Invest it and leave it alone',
        outcome:
            'You barely thought about it again. Time did the work that no '
            'amount of effort later could.',
        money: -120,
        smarts: 8,
        teaches: FinanceConcept.compoundGrowth,
      ),
      LifeChoice(
        label: 'Keep it as cash — it feels safer',
        outcome:
            'Nothing was lost. Nothing grew either, and prices did not '
            'stand still.',
        happiness: 2,
        teaches: FinanceConcept.inflation,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_hot_tip',
    prompt:
        'Someone at work swears one company is about to take off, and puts '
        'everything they have into it.',
    icon: Icons.scatter_plot_rounded,
    minAge: 20,
    minMoney: 200,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Spread your money across many instead',
        outcome:
            'Boring, and it worked. When one holding dropped, the rest '
            'carried it.',
        money: 90,
        smarts: 7,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Go all in on the tip',
        outcome:
            'It did not take off. Everything was in one place, so '
            'everything went with it.',
        money: -160,
        happiness: -6,
        teaches: FinanceConcept.diversification,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_insurance_call',
    prompt:
        'Renewal time. You could drop your cover and pocket the premium.',
    icon: Icons.health_and_safety_rounded,
    minAge: 22,
    weight: 1.0,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Keep cover for what you could not replace',
        outcome:
            'A small predictable cost, in exchange for not being wiped out '
            'by a rare one.',
        money: -35,
        smarts: 5,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Cancel it and keep the money',
        outcome:
            'Cheaper every month — right up until the month it was not.',
        money: 35,
        happiness: 3,
        teaches: FinanceConcept.insurance,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_sunk_course',
    prompt:
        'You paid up front for a course you have grown to hate. There are '
        'months of it left.',
    icon: Icons.history_toggle_off_rounded,
    minAge: 18,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Walk away and use the time better',
        outcome:
            'The money was gone either way. At least the months were not.',
        happiness: 8,
        smarts: 6,
        teaches: FinanceConcept.sunkCost,
      ),
      LifeChoice(
        label: 'Finish it because you already paid',
        outcome:
            'You saw it through, resenting every session. The fee did not '
            'come back for being endured.',
        happiness: -6,
        smarts: 2,
        teaches: FinanceConcept.sunkCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_two_offers',
    prompt:
        'Two jobs: one pays more but is across an expensive city, the other '
        'pays less near cheap rent.',
    icon: Icons.compare_arrows_rounded,
    minAge: 20,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Work out what you would actually keep',
        outcome:
            'After rent and travel, the "smaller" salary left more in your '
            'pocket. You took it.',
        money: 110,
        smarts: 8,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Take the bigger number',
        outcome:
            'A better salary to say out loud, and less left at the end of '
            'the month.',
        money: -30,
        happiness: 4,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_savings_cushion',
    prompt:
        'Your hours get cut with no warning. Rent is due in two weeks.',
    icon: Icons.umbrella_rounded,
    minAge: 20,
    requiresJob: true,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Lean on the fund you built',
        outcome:
            'Stressful, not catastrophic. That is exactly what the fund is '
            'for — it buys you time to fix things calmly.',
        happiness: -3,
        smarts: 6,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Put rent on credit and hope',
        outcome:
            'Rent got paid. So did the interest, for a long time after.',
        money: -70,
        happiness: -8,
        teaches: FinanceConcept.emergencyFund,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_price_creep',
    prompt:
        'The weekly shop costs noticeably more than it did a few years ago '
        'for the same basket.',
    icon: Icons.local_grocery_store_rounded,
    minAge: 25,
    weight: 0.9,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Ask for a pay review to match',
        outcome:
            'Awkward conversation, better outcome. Standing still while '
            'prices move is a slow pay cut.',
        money: 80,
        smarts: 6,
        teaches: FinanceConcept.inflation,
      ),
      LifeChoice(
        label: 'Absorb it quietly',
        outcome:
            'Same salary, smaller shop. The gap widened every year you did '
            'not mention it.',
        money: -45,
        happiness: -3,
        teaches: FinanceConcept.inflation,
      ),
    ],
  ),
];

const List<LifeEvent> kLifeEvents = <LifeEvent>[
  ..._kLifeEventsCore,
  ...kLifeEventsExtra,
  ...kLifeEventsEarly,
  ...kLifeEventsMoney,
];
