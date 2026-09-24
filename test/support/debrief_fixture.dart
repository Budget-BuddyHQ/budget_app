import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_debrief.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_run_record.dart';

/// A finished life with a full memory, for anything that draws or grades a
/// debrief.
///
/// The screens that show a debrief were being tested with a summary that had
/// none, which meant the curve, the story and the numbers grid had never been
/// laid out at any window size. This is the busy case on purpose: a life that
/// dipped into debt, recovered, was hit by four bills and had one decision that
/// cost real money, so every section of the view has something in it.
///
/// Built from a curve first and the peak and low read off it, so the numbers
/// the tally quotes are the numbers the chart draws.
LifeRunRecord richRunRecord() {
  int worthAt(int age) {
    if (age < 24) return (age - 18) * -70; // borrowing to get started
    if (age < 32) return -420 + (age - 24) * 130;
    if (age < 52) return 620 + (age - 32) * 260;
    return 5820 + (age - 52) * 160;
  }

  final curve = <LifeYearPoint>[
    for (var age = 18; age <= 68; age++)
      LifeYearPoint(
        age: age,
        netWorth: worthAt(age),
        happiness: 62 + (age % 7),
        health: age < 45 ? 84 : 84 - (age - 45),
      ),
  ];

  var peak = curve.first;
  var low = curve.first;
  for (final p in curve) {
    if (p.netWorth > peak.netWorth) peak = p;
    if (p.netWorth < low.netWorth) low = p;
  }

  return LifeRunRecord(
    curve: curve,
    moments: const <LifeMoment>[
      LifeMoment(
        age: 24,
        kind: LifeMomentKind.decision,
        title: 'A friend offers you their old car for cash.',
        chose: 'Buy it on credit',
        moneyDelta: -450,
        betterDelta: 0,
        betterOption: 'Keep taking the bus',
        worseDelta: -450,
        concept: FinanceConcept.interestCost,
      ),
      LifeMoment(
        age: 31,
        kind: LifeMomentKind.decision,
        title: 'You need a new phone plan.',
        chose: 'Compare three quotes',
        moneyDelta: -60,
        betterDelta: -200,
        betterOption: 'Take the first offer',
        worseDelta: -300,
        concept: FinanceConcept.opportunityCost,
      ),
      LifeMoment(
        age: 41,
        kind: LifeMomentKind.shock,
        title: 'The boiler gave out',
        chose: 'Paid from savings',
        moneyDelta: -820,
        concept: FinanceConcept.emergencyFund,
      ),
      LifeMoment(
        age: 52,
        kind: LifeMomentKind.shock,
        title: 'A trip to the dentist',
        chose: 'Borrowed to pay',
        moneyDelta: -310,
        concept: FinanceConcept.emergencyFund,
        covered: false,
      ),
    ],
    tally: LifeRunTally(
      adultYears: 50,
      workYears: 44,
      yearsUnemployed: 6,
      weeksMissed: 21,
      timesLaidOff: 0,
      raises: 3,
      referrals: 2,
      contactsMade: 5,
      townEarned: 640,
      sideJobs: 7,
      incomeTotal: 31000,
      savedTotal: 5300,
      interestPaid: 260,
      shocksHit: 4,
      shocksCovered: 3,
      firstJobAge: 19,
      peakNetWorth: peak.netWorth,
      peakAge: peak.age,
      lowNetWorth: low.netWorth,
      lowAge: low.age,
    ),
  );
}

/// The facts that go with [richRunRecord].
LifeRunFacts richRunFacts() => LifeRunFacts(
  age: 68,
  netWorth: 8400,
  cash: 900,
  investments: 5200,
  emergencyFund: 2300,
  debt: 0,
  health: 61,
  happiness: 70,
  conceptsMet: 9,
  conceptsAvailable: 16,
  died: false,
  everStarved: false,
  budgetSet: true,
  savingsPct: 20,
  wantsPct: 25,
  record: richRunRecord(),
  connection: 58,
  networkStrength: 44,
  contacts: 3,
);

/// A shorter, harder life: never budgeted, borrowed, nothing invested, and let
/// go after missing work. Every section of the view has something *bad* in it.
LifeRunFacts roughRunFacts() => LifeRunFacts(
  age: 47,
  netWorth: -900,
  cash: 0,
  investments: 0,
  emergencyFund: 0,
  debt: 900,
  health: 22,
  happiness: 30,
  conceptsMet: 1,
  conceptsAvailable: 16,
  died: false,
  everStarved: true,
  budgetSet: false,
  record: LifeRunRecord(
    curve: <LifeYearPoint>[
      for (var age = 18; age <= 47; age++)
        LifeYearPoint(
          age: age,
          netWorth: -(age - 18) * 30,
          happiness: 40,
          health: 60 - (age - 18),
        ),
    ],
    moments: const <LifeMoment>[
      LifeMoment(
        age: 26,
        kind: LifeMomentKind.shock,
        title: 'Your phone was stolen',
        chose: 'Borrowed to pay',
        moneyDelta: -420,
        covered: false,
      ),
    ],
    tally: const LifeRunTally(
      adultYears: 29,
      workYears: 14,
      yearsUnemployed: 15,
      weeksMissed: 40,
      timesLaidOff: 1,
      raises: 0,
      incomeTotal: 5200,
      savedTotal: 0,
      interestPaid: 310,
      shocksHit: 2,
      shocksCovered: 0,
      firstJobAge: 21,
      peakNetWorth: 0,
      peakAge: 18,
      lowNetWorth: -870,
      lowAge: 47,
    ),
  ),
  connection: 12,
  networkStrength: 0,
  contacts: 0,
);
