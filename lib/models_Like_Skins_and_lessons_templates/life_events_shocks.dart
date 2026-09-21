import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_assets.dart';
import 'life_sim_models.dart';

/// The bad days: a boss who lets you go, a fire, a flood, a crash, a hospital
/// bill, a slow economy.
///
/// **Asked for as:** *"make sure that disasters, or other BitLife events about
/// finance, happen, like your boss cutting you from your job."* Money shocks did
/// happen, but they were nearly all illness bills paid from a fund with one line
/// of text. A simulation of 300 working lives found **140 of them never once lost
/// a job to a layoff card**, and almost nothing had a name: no fire, no flood, no
/// crash. A life where nothing goes wrong cannot teach why savings matter.
///
/// So these exist, and `LifeSimController._drawEvent` makes sure one arrives every
/// few years to anybody old enough to have something to lose. See
/// [kShockEventIds] and [kShockGraceYears].
///
/// **The rules these follow.** Plain words in the prompt, because a nine-year-old
/// can be playing a forty-year-old. Every choice teaches, and none of them is the
/// "wrong answer": the expensive choice is the safe one, the cheap choice costs
/// something else, and the outcome says what. Nothing here shows anybody being
/// hurt on purpose; the trouble is weather, wear and a company's bad year.
const List<LifeEvent> kLifeEventsShocks = <LifeEvent>[
  // ==== Work ================================================================
  LifeEvent(
    id: 's_boss_lets_you_go',
    prompt:
        'Your boss asks to see you in the office. The company is losing money, '
        'and your job is one of the ones it cannot keep.',
    icon: Icons.work_off_rounded,
    minAge: 18,
    maxAge: 64,
    requiresJob: true,
    repeatable: true,
    weight: 1.4,
    choices: [
      LifeChoice(
        label: 'Use your savings while you look for the next job',
        outcome:
            'Your savings pay the bills for a few months, so you can look for a '
            'good job and not just the first one. That is what an emergency '
            'fund is for. It does not make the news better, it buys you time.',
        money: -200,
        happiness: -5,
        setJob: 'Unemployed',
        setSalary: 0,
        followUp: LifeFollowUp.openJobs,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Ask if the company will pay you something to leave',
        outcome:
            'Many companies do, and most people never ask. It arrives as one '
            'lump, and it has to last until the next job starts, so treat it '
            'like an emergency fund and not like a prize.',
        money: 250,
        happiness: -6,
        setJob: 'Unemployed',
        setSalary: 0,
        followUp: LifeFollowUp.openJobs,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Take the first job anybody offers',
        outcome:
            'You are working again within weeks, and on less. When there is '
            'nothing saved you cannot say no to the first offer, and that is '
            'the real cost of having no cushion.',
        money: 60,
        happiness: -8,
        setJob: 'Unemployed',
        setSalary: 0,
        followUp: LifeFollowUp.openJobs,
        teaches: FinanceConcept.emergencyFund,
      ),
    ],
  ),
  LifeEvent(
    id: 's_hours_cut',
    prompt:
        'Your boss says the shop has gone quiet. From next month you will be '
        'given fewer hours.',
    icon: Icons.schedule_rounded,
    minAge: 18,
    maxAge: 64,
    requiresJob: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Pick up a second, small job',
        outcome:
            'More tired, and the money comes back. Having more than one way '
            'to earn is why a cut to one of them is not a disaster.',
        money: -60,
        happiness: -6,
        smarts: 2,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Spend less on wants and keep paying for needs',
        outcome:
            'It stings for a while. Rent and food stay covered, and the '
            'things you can do without are the first to go.',
        money: -120,
        happiness: -3,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Carry on as normal and put it on your card',
        outcome:
            'It felt fine for two months. Then the card bill arrived, with '
            'extra on top for borrowing. You paid for your old life twice.',
        money: -300,
        happiness: -2,
        teaches: FinanceConcept.interestCost,
      ),
    ],
  ),
  LifeEvent(
    id: 's_slow_economy',
    prompt:
        'The news says the economy is slowing down. Shops are closing and '
        'people are being careful with their money.',
    icon: Icons.trending_down_rounded,
    minAge: 20,
    maxAge: 75,
    repeatable: true,
    weight: 0.8,
    choices: [
      LifeChoice(
        label: 'Spend less and keep more in reserve',
        outcome:
            'Slow times come round every few years. The people who are glad '
            'when they do are the ones who saved in the good ones.',
        happiness: -3,
        smarts: 3,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Carry on exactly as before',
        outcome:
            'Your tips and extra hours dried up and your spending did not. '
            'When money gets tight, spending that grew with the good years is '
            'the hardest to cut.',
        money: -250,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Use the quiet time to learn something new (80 coins)',
        outcome:
            'A short course while things were slow. When hiring picks up again, '
            'you are worth more than you were. Time is cheap in a quiet year.',
        money: -80,
        smarts: 6,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),

  // ==== Home ================================================================
  LifeEvent(
    id: 's_kitchen_fire',
    prompt:
        'A pan of oil catches fire in your kitchen. You get out safely, but '
        'the cupboards and the floor are ruined.',
    icon: Icons.local_fire_department_rounded,
    minAge: 20,
    maxAge: 85,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Pay for all the repairs (400 coins)',
        outcome:
            'Fixed properly. It was a big bill, and it is the kind of bill '
            'insurance is for: you pay a little all the time so a day like '
            'this costs you a little, not a lot.',
        money: -400,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Fix only what is unsafe (180 coins)',
        outcome:
            'The wiring and the floor are done, and the cupboards can wait. '
            'It is not pretty. Safe comes first and nice comes later.',
        money: -180,
        happiness: -6,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Get three quotes before you decide (300 coins)',
        outcome:
            'It took two extra weeks, and the cheapest quote was 100 less than '
            'the first. Asking around costs nothing.',
        money: -300,
        smarts: 3,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 's_flood',
    prompt:
        'Heavy rain floods the ground floor of your building. Everything on '
        'the floor is soaked.',
    icon: Icons.flood_rounded,
    minAge: 20,
    maxAge: 85,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Pay for a full clean and repair (350 coins)',
        outcome:
            'Done properly, and dry by the weekend. A flood is the sort of '
            'bill that one emergency fund exists to swallow.',
        money: -350,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Dry it out yourself and keep the receipts (150 coins)',
        outcome:
            'Photos and receipts are how an insurance claim works. It only '
            'pays for what you can show, so keep proof of everything.',
        money: -150,
        smarts: 3,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Ignore the damp and hope it dries',
        outcome:
            'By spring it had turned into mould, and the repair cost more '
            'than the clean-up would have. A small problem left alone grows.',
        money: -450,
        health: -6,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),

  // ==== Road and health ======================================================
  LifeEvent(
    id: 's_car_wreck',
    prompt:
        'Another driver goes through a red light and hits your car. You are '
        'fine, but the car is badly dented.',
    icon: Icons.car_crash_rounded,
    minAge: 18,
    maxAge: 85,
    requiresAsset: AssetKind.vehicle,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Swap details and make a claim (100 coins to start)',
        outcome:
            'A form, a phone call and a small amount to begin with, and the '
            'other driver\'s side paid the rest. That is what insurance is for.',
        money: -100,
        smarts: 2,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Pay for the repair yourself to keep it simple (500 coins)',
        outcome:
            'No forms and no waiting, and five times the bill. Simple can be '
            'the most expensive way to do something.',
        money: -500,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 's_hospital_bill',
    prompt:
        'You slip on an icy step and break your wrist. A few weeks later the '
        'hospital sends a bill.',
    icon: Icons.local_hospital_rounded,
    minAge: 20,
    maxAge: 85,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Pay it all now from your savings (300 coins)',
        outcome:
            'Paid, and done. It hurt to see the number, and it is exactly '
            'the day savings are meant for.',
        money: -300,
        health: -5,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Ask to pay it off in smaller parts (240 coins)',
        outcome:
            'Many hospitals will split a bill if you ask. Read the small '
            'print, because some plans add a fee for spreading it out.',
        money: -240,
        health: -5,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Put the letters in a drawer',
        outcome:
            'The bill did not go away. It got extra charges, then a stern '
            'letter, and it can hurt your record for years. An unopened bill '
            'is still a bill.',
        money: -420,
        happiness: -8,
        health: -5,
        teaches: FinanceConcept.creditScore,
      ),
    ],
  ),
];

/// The events that count as a money shock, for the "one is due" rule.
///
/// The new ones above, and the older ones that were already about something going
/// wrong. A layoff is a shock whichever pack it came from.
const Set<String> kShockEventIds = <String>{
  's_boss_lets_you_go',
  's_hours_cut',
  's_slow_economy',
  's_kitchen_fire',
  's_flood',
  's_car_wreck',
  's_hospital_bill',
  'a_redundancy',
  'redundancy',
  'h_storm_damage',
  'big_repair_bill',
  'car_repair',
};

/// Years an adult can go without meeting a shock before one is due.
///
/// Measured in years drawn, not in shocks missed. At six, a working life from
/// twenty to sixty-five meets six or seven of them, and the odds that some card
/// takes a job away are near a certainty rather than a coin flip. Shorter than
/// that and it reads as a game that is out to get you.
const int kShockGraceYears = 6;
