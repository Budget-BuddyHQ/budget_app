import 'package:flutter/material.dart';

/// Data model for **Life** — the main game: a BitLife-style life simulator with
/// a financial-literacy spine, meant to sit alongside the open-world map (not
/// as a "minigame"). Age up year by year, make money decisions, and watch four
/// stats — Money, Happiness, Health, Smarts — play out.
///
/// Pure data. The rules live in `LifeSimController`; the screen renders what the
/// controller exposes, so the game can grow (more events, jobs, an economy tie)
/// without touching the UI wiring.

/// One line in the BitLife-style life feed, tagged with the age it happened at.
@immutable
class LifeLogEntry {
  const LifeLogEntry({required this.age, required this.text});

  final int age;
  final String text;
}

enum LifeStage { teen, youngAdult, adult, senior }

extension LifeStageInfo on LifeStage {
  String get label => switch (this) {
    LifeStage.teen => 'Teen',
    LifeStage.youngAdult => 'Young Adult',
    LifeStage.adult => 'Adult',
    LifeStage.senior => 'Senior',
  };

  static LifeStage forAge(int age) {
    if (age < 18) return LifeStage.teen;
    if (age < 30) return LifeStage.youngAdult;
    if (age < 60) return LifeStage.adult;
    return LifeStage.senior;
  }
}

/// One option on a life event, with its outcome text and stat/money effects.
@immutable
class LifeChoice {
  const LifeChoice({
    required this.label,
    required this.outcome,
    this.money = 0,
    this.happiness = 0,
    this.health = 0,
    this.smarts = 0,
    this.setJob,
    this.setSalary,
  });

  final String label;
  final String outcome;
  final int money;
  final int happiness;
  final int health;
  final int smarts;

  /// If set, the choice lands the player a job at this yearly salary.
  final String? setJob;
  final int? setSalary;
}

/// A prompt that appears when you age up, teaching a money idea through the
/// trade-offs between its [choices].
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

/// The event pool. Each teaches a concrete money lesson through its outcomes.
const List<LifeEvent> kLifeEvents = <LifeEvent>[
  LifeEvent(
    id: 'first_paycheck',
    prompt:
        'You earned your first paycheck from a summer job. What do you do with it?',
    icon: Icons.payments_rounded,
    minAge: 15,
    maxAge: 22,
    choices: [
      LifeChoice(
        label: 'Save most of it',
        outcome: 'You banked it. Boring now, powerful later.',
        money: 150,
        happiness: -3,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Split save/spend',
        outcome: 'A little fun, a little future. Balanced.',
        money: 90,
        happiness: 5,
        smarts: 2,
      ),
      LifeChoice(
        label: 'Blow it all',
        outcome: 'Fun weekend, empty wallet by Monday.',
        money: 10,
        happiness: 12,
        smarts: -2,
      ),
    ],
  ),
  LifeEvent(
    id: 'phone_breaks',
    prompt: 'Your phone cracks. A new one is 300 coins you don\'t have spare.',
    icon: Icons.phone_iphone_rounded,
    minAge: 14,
    choices: [
      LifeChoice(
        label: 'Buy a cheaper model',
        outcome: 'Not flashy, but you stayed out of debt.',
        money: -120,
        happiness: 2,
        smarts: 3,
      ),
      LifeChoice(
        label: 'Put it on credit',
        outcome: 'You have a phone now — and interest piling up.',
        money: -60,
        happiness: 4,
        smarts: -4,
      ),
      LifeChoice(
        label: 'Tape it up and wait',
        outcome: 'Ugly, but you kept every coin.',
        money: 0,
        happiness: -6,
        smarts: 5,
      ),
    ],
  ),
  LifeEvent(
    id: 'crypto_tip',
    prompt: 'A classmate swears a coin will "10x by Friday." Get in?',
    icon: Icons.currency_bitcoin_rounded,
    minAge: 15,
    choices: [
      LifeChoice(
        label: 'Go all in',
        outcome: 'It dumped. "Guaranteed" is never guaranteed.',
        money: -200,
        happiness: -8,
        smarts: 6,
      ),
      LifeChoice(
        label: 'Risk a tiny bit',
        outcome: 'You risked only what you could lose. Smart.',
        money: -20,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Pass',
        outcome: 'You dodged the hype. Slow and steady.',
        smarts: 6,
        happiness: -1,
      ),
    ],
  ),
  LifeEvent(
    id: 'scholarship',
    prompt: 'A scholarship needs a hard exam. Grind for it?',
    icon: Icons.school_rounded,
    minAge: 16,
    maxAge: 25,
    choices: [
      LifeChoice(
        label: 'Study hard',
        outcome: 'You aced it and won the scholarship!',
        money: 400,
        happiness: -4,
        smarts: 10,
      ),
      LifeChoice(
        label: 'Wing it',
        outcome: 'You missed by a bit. Next time.',
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
    maxAge: 40,
    choices: [
      LifeChoice(
        label: 'Take it',
        outcome: 'Steady income unlocked. Salary added each year.',
        happiness: 3,
        setJob: 'Shop Assistant',
        setSalary: 260,
      ),
      LifeChoice(
        label: 'Hold out for better',
        outcome: 'You kept your time free — and your wallet thin.',
        happiness: 4,
        smarts: 1,
      ),
    ],
  ),
  LifeEvent(
    id: 'emergency_fund',
    prompt: 'Nothing went wrong this year. Build an emergency fund?',
    icon: Icons.savings_rounded,
    minAge: 18,
    choices: [
      LifeChoice(
        label: 'Set aside savings',
        outcome: 'A cushion for the next surprise. Peace of mind.',
        money: -80,
        happiness: 3,
        smarts: 6,
      ),
      LifeChoice(
        label: 'Spend it on fun',
        outcome: 'Great memories — but no cushion.',
        happiness: 10,
        smarts: -3,
      ),
    ],
  ),
  LifeEvent(
    id: 'car_repair',
    prompt: 'Your car needs a 250-coin repair to get to work.',
    icon: Icons.car_repair_rounded,
    minAge: 18,
    choices: [
      LifeChoice(
        label: 'Pay from savings',
        outcome: 'This is exactly what savings are for.',
        money: -250,
        happiness: -2,
        smarts: 3,
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
    prompt: 'Your boss offers a raise if you take on more responsibility.',
    icon: Icons.trending_up_rounded,
    minAge: 20,
    choices: [
      LifeChoice(
        label: 'Take the raise',
        outcome: 'More work, more pay. Career climbing.',
        happiness: -3,
        smarts: 4,
        setJob: 'Team Lead',
        setSalary: 520,
      ),
      LifeChoice(
        label: 'Keep work-life balance',
        outcome: 'You value your time over the bump. Fair.',
        happiness: 6,
      ),
    ],
  ),
];
