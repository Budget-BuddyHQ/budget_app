import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_assets.dart';
import 'life_sim_models.dart';

/// The years where money decisions get expensive.
///
/// **The gap this closes.** Counting eligible events by age showed the pool
/// thinning out badly after about 45. the years a run spends the *longest*
/// in were pulling from the same handful of scenes, so the back half of every
/// life felt like a rerun of the front half. and it skipped most of what
/// actually happens to an adults money anyway — insurance, a mortgage, being
/// made redundant, a parent who needs help, a scam aimed right at somebody
/// with savings.
///
/// **What makes these different from the earlier packs.** A teenager's money
/// events are about a single purchase. These are about *systems* — the choice
/// is rarely "buy or don't", it is "which structure do you want to be inside
/// when something goes wrong". So most of them have no purely-good option, and
/// the outcome line names the trade rather than scoring it.
///
/// Every event is written to survive being met at a bad moment: nothing here
/// bankrupts a careful player outright, because a simulation that can end your
/// run on a dice roll teaches that planning does not matter.
const List<LifeEvent> kLifeEventsAdult = <LifeEvent>[
  // --- Insurance: the thing nobody buys until they needed it ----------
  LifeEvent(
    id: 'a_renters_insurance',
    topic: 'renters_insurance',
    prompt:
        'Your building has had two break-ins this year. Renters insurance is '
        '\$14 a month.',
    icon: Icons.shield_moon_rounded,
    minAge: 19,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Take the policy',
        outcome:
            'You are out \$168 a year for something you hope never to use. '
            'That is what insurance is: paying a small certain amount to '
            'avoid a large uncertain one.',
        money: -168,
        smarts: 2,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Skip it — you do not own much',
        outcome:
            'A fair call if it is true. The test is not what your things cost '
            'you, it is what replacing all of them at once would cost.',
        happiness: 2,
      ),
      LifeChoice(
        label: 'Add up what a full replacement would cost first',
        outcome:
            'About \$3,400 — more than you guessed, which is the usual answer. '
            'You take the policy knowing why.',
        money: -168,
        smarts: 5,
        teaches: FinanceConcept.emergencyFund,
      ),
    ],
  ),
  LifeEvent(
    id: 'a_health_deductible',
    prompt:
        'Open enrolment. The cheaper plan saves \$60 a month and has a '
        '\$4,000 deductible instead of \$1,000.',
    icon: Icons.medical_information_rounded,
    minAge: 22,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Take the cheaper premium',
        outcome:
            'You save \$720 a year and carry \$3,000 more risk. That is the '
            'right trade only if you could actually find \$4,000 in a bad '
            'month.',
        money: 720,
        smarts: 3,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Keep the lower deductible',
        outcome:
            'It costs more every month and it is the version you can survive '
            'without warning. Insurance is bought for the bad year, not the '
            'average one.',
        money: -720,
        health: 3,
        smarts: 3,
      ),
      LifeChoice(
        label: 'Match the plan to what is in savings',
        outcome:
            'The honest method: a high deductible is affordable exactly when '
            'you already hold the deductible in cash. You pick accordingly.',
        smarts: 6,
        teaches: FinanceConcept.emergencyFund,
      ),
    ],
  ),

  // --- Housing --------------------------------------------------------
  LifeEvent(
    id: 'a_mortgage_or_rent',
    prompt:
        'You could buy a small place. The mortgage payment is close to your '
        'rent, but the deposit is most of your savings.',
    icon: Icons.house_rounded,
    minAge: 25,
    minMoney: 400,
    weight: 0.7,
    forbidsAsset: AssetKind.home,
    choices: [
      LifeChoice(
        label: 'Buy (210 coins down, the rest on a mortgage)',
        outcome:
            'The payment is similar and the costs are not: repairs, insurance '
            'and tax are yours now. What you gain is that the payment stops '
            'rising every year. It is on the Assets tab, with the loan '
            'beside it.',
        money: -210,
        happiness: 6,
        smarts: 4,
        grantsAsset: 'home_flat',
        grantsFinanced: true,
      ),
      LifeChoice(
        label: 'Keep renting and keep the savings liquid',
        outcome:
            'Renting is not throwing money away — it is buying flexibility '
            'and someone else handling the boiler. It is the right answer when '
            'you might move.',
        happiness: 2,
        smarts: 3,
      ),
      LifeChoice(
        label: 'Work out the full cost of owning first',
        outcome:
            'Mortgage plus tax plus insurance plus a repair fund comes to '
            'noticeably more than the rent. You are not put off — you are just '
            'no longer surprised.',
        smarts: 7,
        teaches: FinanceConcept.budgetRule,
      ),
    ],
  ),
  LifeEvent(
    id: 'a_boiler_dies',
    prompt: 'The boiler dies in February. Replacing it is \$1,900.',
    icon: Icons.plumbing_rounded,
    minAge: 25,
    requiresFlag: LifeFlag.ownsHome,
    weight: 0.8,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Pay from the repair fund',
        outcome:
            'This is exactly what that money was for. Nothing about the month '
            'changes except that you are cold for two days.',
        money: -1900,
        smarts: 4,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Put it on a card',
        outcome:
            'Warm tonight, and at 24% APR the boiler costs closer to \$2,300 '
            'by the time it is paid off. Debt is a way of moving a cost, not '
            'removing it.',
        money: -1900,
        happiness: -4,
        smarts: 3,
      ),
      LifeChoice(
        label: 'Get three quotes first',
        outcome:
            'The spread between the cheapest and dearest is \$600. Two phone '
            'calls were worth more per hour than your job.',
        money: -1400,
        smarts: 6,
      ),
    ],
  ),

  LifeEvent(
    id: 'a_downsize',
    topic: 'downsize',
    prompt:
        'The place is bigger than you need and the upkeep is eating the '
        'month. A smaller flat would free up real money.',
    icon: Icons.move_down_rounded,
    minAge: 45,
    requiresFlag: LifeFlag.ownsHome,
    weight: 0.5,
    choices: [
      LifeChoice(
        label: 'Sell and move somewhere smaller',
        outcome:
            'You release the difference in cash and your monthly costs drop. '
            'A house is only an asset while you can afford to keep it — '
            'selling one is a decision, not a defeat.',
        happiness: -2,
        smarts: 6,
        sellsAsset: AssetKind.home,
        clearsFlag: LifeFlag.ownsHome,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Stay — the space is worth the cost',
        outcome:
            'Perfectly valid, as long as it is a choice. What sinks people is '
            'paying for space they stopped using years ago without noticing.',
        happiness: 4,
        smarts: 2,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Rent out the spare room instead',
        outcome:
            'The upkeep is covered and you keep the house. The cost is that '
            'the space is no longer entirely yours — every income has a price '
            'somewhere.',
        money: 2600,
        happiness: -3,
        smarts: 5,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),

  // --- Work, mid-career ------------------------------------------------
  LifeEvent(
    id: 'a_redundancy',
    prompt: 'Your company announces layoffs. Yours is one of the roles going.',
    icon: Icons.work_off_rounded,
    minAge: 24,
    requiresJob: true,
    weight: 0.55,
    choices: [
      LifeChoice(
        label: 'Live off the emergency fund while you look',
        outcome:
            'Three months of expenses buys you three months of choosing. That '
            'is the entire point of the fund — not the money, the not having '
            'to take the first thing offered.',
        money: -900,
        // Every branch of this card used to leave the job in place at full
        // pay, under a prompt that says the role is going.
        setJob: 'Unemployed',
        setSalary: 0,
        followUp: LifeFollowUp.openJobs,
        happiness: -6,
        smarts: 5,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Take the first job that comes up',
        outcome:
            'Employed again quickly, at less than you were on. Urgency is '
            'expensive, and it is what having no cushion buys you.',
        setSalary: 220,
        replacesJob: true,
        laidOff: true,
        happiness: -3,
        smarts: 3,
      ),
      LifeChoice(
        label: 'Retrain into something adjacent',
        outcome:
            'A hard six months, and a much stronger application at the end '
            'of it. A downturn is the cheapest time to change direction, '
            'because the thing you were doing has already stopped.',
        setJob: 'Unemployed',
        setSalary: 0,
        followUp: LifeFollowUp.openJobs,
        money: -600,
        smarts: 8,
        skill: LifeSkill.business,
        skillGain: 12,
      ),
    ],
  ),
  LifeEvent(
    id: 'a_salary_negotiation',
    prompt:
        'You have been offered a role. The number is fair; the range for the '
        'job goes about 12% higher.',
    // The role is the Analyst job these choices set. Above 320 it would be a
    // pay cut called an offer.
    maxSalary: 320,
    icon: Icons.handshake_rounded,
    minAge: 21,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Accept it as offered',
        outcome:
            'A fine salary, and every future raise is a percentage of this '
            'number. A starting figure compounds for as long as you stay.',
        setJob: 'Analyst',
        setSalary: 320,
        happiness: 3,
      ),
      LifeChoice(
        label: 'Ask for the top of the range',
        outcome:
            'They meet you near the middle. Asking cost one uncomfortable '
            'sentence and moved every raise you will ever get from here.',
        setJob: 'Analyst',
        setSalary: 360,
        smarts: 6,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Ask what the range is before naming a number',
        outcome:
            'They tell you. You ask for the upper half of it and get it — the '
            'person with the information usually does.',
        setJob: 'Analyst',
        setSalary: 370,
        smarts: 8,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),

  // --- Family and other people -----------------------------------------
  LifeEvent(
    id: 'a_parent_needs_help',
    topic: 'parent_money',
    prompt:
        'A parent is short on money and has not said so directly. You can '
        'tell.',
    icon: Icons.elderly_rounded,
    minAge: 26,
    weight: 0.7,
    choices: [
      LifeChoice(
        label: 'Send what you can spare',
        outcome:
            'You send \$400 and mean it. Helping family is a real budget line '
            'for a lot of people, and pretending otherwise is what makes it '
            'wreck a plan.',
        money: -400,
        happiness: 6,
      ),
      LifeChoice(
        label: 'Offer to go through their bills with them',
        outcome:
            'Two subscriptions and an insurance policy nobody needed. You cost '
            'yourself an afternoon and saved them \$90 a month, permanently.',
        happiness: 8,
        smarts: 6,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Set up a small standing amount instead of a lump sum',
        outcome:
            'Less dramatic and far more useful — it is money they can plan '
            'around, and it is a number you can afford every month rather '
            'than once.',
        money: -180,
        happiness: 5,
        smarts: 5,
      ),
    ],
  ),
  LifeEvent(
    id: 'a_friend_asks_for_loan',
    topic: 'friend_loan',
    prompt: 'A friend asks to borrow \$500. They are good for it, probably.',
    icon: Icons.volunteer_activism_rounded,
    minAge: 20,
    minMoney: 500,
    weight: 0.8,
    choices: [
      LifeChoice(
        label: 'Lend it',
        outcome:
            'They pay back most of it, eventually. Lending to friends usually '
            'costs a little money and some of the friendship.',
        money: -180,
        happiness: -2,
      ),
      LifeChoice(
        label: 'Give half, and call it a gift',
        outcome:
            'No debt, no awkwardness, no waiting for a text. The old advice — '
            'only lend what you would be willing to give — turns out to be '
            'about the friendship rather than the money.',
        money: -250,
        happiness: 5,
        smarts: 5,
      ),
      LifeChoice(
        label: 'Say no, and say why',
        outcome:
            'Uncomfortable and clean. "I do not lend money" is a policy rather '
            'than a judgement of them, which is why it is easier to say twice.',
        happiness: -3,
        smarts: 4,
      ),
    ],
  ),

  // --- Scams aimed at people with money --------------------------------
  LifeEvent(
    id: 'a_investment_pitch',
    prompt:
        'Someone you half-know is raising money for a venture. "Guaranteed 20% '
        'a year."',
    icon: Icons.warning_amber_rounded,
    minAge: 24,
    minMoney: 800,
    weight: 0.7,
    choices: [
      LifeChoice(
        label: 'Put in \$1,000',
        outcome:
            'It goes quiet after eight months. Guaranteed and 20% cannot both '
            'be true — a guarantee is worth about 4%, and anything above that '
            'is being paid for with risk somebody is not mentioning.',
        money: -1000,
        smarts: 6,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Ask who regulates it',
        outcome:
            'The answer is vague, and vague is the answer. You keep your '
            'money and lose an acquaintance, which is the cheaper half of that '
            'trade.',
        smarts: 9,
        happiness: -2,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Put in only what you could lose entirely',
        outcome:
            'You risk \$150 with your eyes open. It does not come back, and '
            'nothing about your year changes — which is the only sane way to '
            'take a bet like this.',
        money: -150,
        smarts: 7,
      ),
    ],
  ),

  // --- The long game ----------------------------------------------------
  LifeEvent(
    id: 'a_pension_review',
    topic: 'pension_review',
    prompt:
        'Your retirement statement arrives. You have not looked at what it is '
        'invested in since the day you joined.',
    icon: Icons.savings_rounded,
    minAge: 30,
    weight: 0.85,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'File it unopened',
        outcome:
            'Most people do. The default fund is usually fine and its fee '
            'usually is not — and a fee you never look at is one you pay for '
            'forty years.',
        happiness: 1,
      ),
      LifeChoice(
        label: 'Check the fee',
        outcome:
            '1.1% a year. Moving to the 0.2% index option leaves roughly a '
            'fifth more in the pot by retirement, for one afternoon of '
            'paperwork.',
        smarts: 9,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Increase the contribution by 1%',
        outcome:
            'Barely noticeable now, and it is the change with the longest '
            'runway available to you. One percent for thirty years is not a '
            'small number at the end.',
        money: -60,
        smarts: 7,
        teaches: FinanceConcept.compoundGrowth,
      ),
    ],
  ),
  LifeEvent(
    id: 'a_will_and_beneficiaries',
    prompt:
        'A form asks who your accounts should go to. You have never filled '
        'one in.',
    icon: Icons.description_rounded,
    minAge: 32,
    weight: 0.6,
    choices: [
      LifeChoice(
        label: 'Fill it in properly',
        outcome:
            'Twenty minutes. Beneficiary forms override a will on most '
            'accounts, which means an out-of-date one quietly beats every '
            'other instruction you have left.',
        smarts: 8,
        happiness: 3,
      ),
      LifeChoice(
        label: 'Leave it for now',
        outcome:
            'The default is your estate, which means probate, delay and legal '
            'cost for whoever is left. Not filling it in is a decision too.',
        happiness: -1,
      ),
    ],
  ),
  LifeEvent(
    id: 'a_lifestyle_creep',
    prompt:
        'You got a raise eight months ago. Your savings rate has not moved.',
    icon: Icons.trending_up_rounded,
    minAge: 25,
    requiresJob: true,
    weight: 0.9,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Work out where it went',
        outcome:
            'A better flat, a better phone, more takeaway. None of it was a '
            'mistake and all of it was automatic — which is the whole '
            'mechanism of lifestyle creep.',
        smarts: 7,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Move half of the next raise straight to savings',
        outcome:
            'Deciding in advance where a raise goes is what turns earning more '
            'into having more. Half is enough that the raise still feels like '
            'one.',
        money: 240,
        smarts: 8,
        teaches: FinanceConcept.payYourselfFirst,
      ),
      LifeChoice(
        label: 'Enjoy it — you earned it',
        outcome:
            'Fair, and worth doing on purpose rather than by drift. The '
            'difference between the two is whether you could say where the '
            'money went.',
        happiness: 6,
      ),
    ],
  ),
];
