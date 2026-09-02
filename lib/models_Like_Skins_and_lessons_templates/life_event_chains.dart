import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_sim_models.dart';

/// Multi-year storylines: events that only exist because of an earlier
/// choice, and that pay it off years later.
///
/// **The problem this solves.** The other four packs are a hundred-odd
/// standalone beats. A run draws sixty of them in a random order, so two
/// runs differ in *which cards came up* and never in what the life was
/// about. That is why the game reads as repetitive at a hundred events —
/// the variety is real, but it is all the same shape.
///
/// A chain is different. Adopting a dog at nine is a small, cheap, obvious
/// choice; the vet bill at fifteen is what makes it a decision you made.
/// And that is exactly the shape a money lesson needs: taking a credit card
/// at twenty-two teaches nothing on its own, and the minimum-payment trap
/// three years later teaches everything, but only if the game remembers the
/// card. See [LifeFlag].
///
/// **Rules these follow.**
/// - The opener is never gated on a flag, so it can always start.
/// - Every middle beat sets or clears something, so a chain always moves.
/// - Every chain has at least one *ending* that closes it (`clearsFlag`), so
///   a life cannot be stuck holding an open thread for sixty years.
/// - Both branches of a money decision teach the same concept, so the
///   lesson does not depend on getting it right — losing money to a
///   minimum payment is the more memorable way to learn what one costs.
/// - Openers are `repeatable: false` by default like everything else, so a
///   chain starts at most once per life.
const List<LifeEvent> kLifeEventsChains = <LifeEvent>[
  // =====================================================================
  // The dog. The cheapest possible way to make an emergency fund matter,
  // because the shock arrives attached to something you care about.
  // =====================================================================
  LifeEvent(
    id: 'chain_pet_adopt',
    prompt:
        'There is a scruffy dog at the shelter with your name on it, '
        'apparently. Taking him home costs 60 coins and he eats every day '
        'after that.',
    icon: Icons.pets_rounded,
    minAge: 8,
    maxAge: 40,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Take him home',
        outcome:
            'His name is Biscuit. Best 60 coins you ever spent, and the '
            'first thing you have ever paid for every single day.',
        money: -60,
        happiness: 14,
        setsFlag: LifeFlag.hasPet,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Work out the yearly cost first',
        outcome:
            'Food, jabs, the odd vet trip — call it 200 a year, every year. '
            'You took him anyway, but you knew what you were signing up for.',
        money: -60,
        happiness: 12,
        smarts: 5,
        setsFlag: LifeFlag.hasPet,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Walk away',
        outcome:
            'You think about him sometimes. Not every good thing is a thing '
            'you can afford right now, and that is allowed.',
        happiness: -4,
        smarts: 3,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_pet_vet',
    prompt:
        'Biscuit has stopped eating. The vet can operate, but it is 700 '
        'coins and she needs an answer today.',
    icon: Icons.medical_services_rounded,
    weight: 1.6,
    requiresFlag: LifeFlag.hasPet,
    forbidsFlag: LifeFlag.petGone,
    choices: [
      LifeChoice(
        label: 'Pay it',
        outcome:
            'He is groggy for a week and then he is Biscuit again. This is '
            'the bill an emergency fund exists for — the one you cannot '
            'schedule and would not skip.',
        money: -700,
        happiness: 10,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Put it on a payment plan',
        outcome:
            'Nine easy payments of 95. That is 855 for a 700 bill — the '
            'extra 155 is what borrowing costs, and "easy" is what it is '
            'sold as.',
        money: -855,
        happiness: 6,
        smarts: 4,
        teaches: FinanceConcept.interestCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_pet_old',
    prompt: 'Biscuit is grey around the muzzle now and sleeps most of the day.',
    icon: Icons.pets_rounded,
    minAge: 20,
    weight: 1.1,
    requiresFlag: LifeFlag.hasPet,
    forbidsFlag: LifeFlag.petGone,
    choices: [
      LifeChoice(
        label: 'Give him the best last year you can',
        outcome:
            'Soft food, short walks, a lot of sitting in the sun together. '
            'He went peacefully. Some money buys things that were never '
            'going to show up in a net worth.',
        money: -240,
        happiness: -6,
        clearsFlag: LifeFlag.hasPet,
        setsFlag: LifeFlag.petGone,
      ),
    ],
  ),

  // =====================================================================
  // The first credit card. The single most useful chain in the game: a
  // small yes, then the consequence, then a way out.
  // =====================================================================
  LifeEvent(
    id: 'chain_card_offer',
    prompt:
        'A card company offers you your first credit card. No annual fee, '
        '1,500 coin limit, 22% a year on anything you do not pay off.',
    icon: Icons.credit_card_rounded,
    minAge: 18,
    maxAge: 34,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Take it and pay it off in full monthly',
        outcome:
            'Used properly a card is a free 30-day loan that builds your '
            'credit history. Paid in full, that 22% never touches you.',
        smarts: 6,
        setsFlag: LifeFlag.hasCreditCard,
        teaches: FinanceConcept.creditScore,
      ),
      LifeChoice(
        label: 'Take it — 1,500 coins of breathing room',
        outcome:
            'It does not feel like debt when it is sitting there unused. '
            'That is the design.',
        happiness: 4,
        setsFlag: LifeFlag.hasCreditCard,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Decline for now',
        outcome:
            'No card means no interest, and also no credit history — which '
            'lenders read as an unknown rather than as a good risk. Both '
            'sides of that are real.',
        smarts: 4,
        teaches: FinanceConcept.creditScore,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_card_minimum',
    prompt:
        'The card is at 1,200 coins after a rough few months. The statement '
        'offers a minimum payment of 30.',
    icon: Icons.receipt_long_rounded,
    weight: 1.5,
    requiresFlag: LifeFlag.hasCreditCard,
    forbidsFlag: LifeFlag.cardDebtSpiral,
    choices: [
      LifeChoice(
        label: 'Pay the minimum',
        outcome:
            'Paying 30 on a 1,200 balance at 22% clears about eight coins of '
            'what you owe — the other 22 is interest. At that rate it takes '
            'over seven years and costs you roughly double.',
        money: -30,
        happiness: -3,
        setsFlag: LifeFlag.cardDebtSpiral,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Throw everything at it',
        outcome:
            'It hurt for one year instead of seven. The interest you did '
            'not pay is the highest guaranteed return available to you.',
        money: -1200,
        happiness: -8,
        smarts: 8,
        clearsFlag: LifeFlag.hasCreditCard,
        setsFlag: LifeFlag.cardPaidOff,
        teaches: FinanceConcept.interestCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_card_spiral',
    prompt:
        'Three years of minimum payments later, the balance is higher than '
        'when you started. A consolidation loan would cut the rate to 9%.',
    icon: Icons.warning_amber_rounded,
    weight: 1.7,
    requiresFlag: LifeFlag.cardDebtSpiral,
    choices: [
      LifeChoice(
        label: 'Consolidate and cut up the card',
        outcome:
            'Same debt, less than half the interest, and one payment instead '
            'of a rolling balance. The cutting-up part is what stops it '
            'refilling.',
        money: -400,
        smarts: 9,
        happiness: 5,
        clearsFlag: LifeFlag.cardDebtSpiral,
        setsFlag: LifeFlag.cardPaidOff,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Consolidate and keep the card for emergencies',
        outcome:
            'The rate dropped. Within a year the card was at 600 again, '
            'because a card with room on it is a card that gets used. Now '
            'you owe on both.',
        money: -400,
        happiness: -6,
        teaches: FinanceConcept.impulseSpending,
      ),
    ],
  ),

  // =====================================================================
  // Index investing, and the crash that tests it. The whole point of the
  // chain is that the crash beat is unreachable unless you invested — so
  // "hold or sell" is a decision you earned.
  // =====================================================================
  LifeEvent(
    id: 'chain_index_start',
    prompt:
        'A colleague explains index funds: instead of picking a company you '
        'buy a slice of hundreds of them, and it costs almost nothing to '
        'hold.',
    icon: Icons.show_chart_rounded,
    minAge: 20,
    weight: 1.2,
    minMoney: 400,
    choices: [
      LifeChoice(
        label: 'Put 400 in and set up a monthly amount',
        outcome:
            'Boring on purpose. Owning hundreds of companies means no single '
            'one can sink you — that is diversification, and it is the only '
            'free lunch in investing.',
        money: -400,
        smarts: 7,
        setsFlag: LifeFlag.investsIndex,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Put it all in one company you like instead',
        outcome:
            'It might work. It also means one bad quarter at one firm is a '
            'bad year for all your money.',
        money: -400,
        happiness: 3,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Keep it in cash where you can see it',
        outcome:
            'Safe from crashes, not safe from prices. Cash sitting still '
            'quietly buys less every year.',
        smarts: 3,
        teaches: FinanceConcept.inflation,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_index_crash',
    prompt:
        'The market has dropped 30% in five weeks. Every headline says it '
        'will fall further. Your fund is worth a third less than you put in.',
    icon: Icons.trending_down_rounded,
    weight: 1.6,
    requiresFlag: LifeFlag.investsIndex,
    choices: [
      LifeChoice(
        label: 'Sell before it gets worse',
        outcome:
            'You turned a paper loss into a real one. A fall only costs you '
            'money at the moment you sell — every recovery in history left '
            'behind the people who got out at the bottom.',
        money: -300,
        happiness: -10,
        smarts: 5,
        clearsFlag: LifeFlag.investsIndex,
        setsFlag: LifeFlag.soldInCrash,
        teaches: FinanceConcept.compoundGrowth,
      ),
      LifeChoice(
        label: 'Do nothing and stop reading the news',
        outcome:
            'Four uncomfortable years later it was worth more than before '
            'the crash. Doing nothing was the entire strategy and it was '
            'the hardest thing you did all decade.',
        happiness: -6,
        smarts: 9,
        setsFlag: LifeFlag.heldThroughCrash,
        teaches: FinanceConcept.compoundGrowth,
      ),
      LifeChoice(
        label: 'Buy more while it is cheap',
        outcome:
            'The same slice of the same companies for a third less. It felt '
            'reckless and it was, in fact, the plan working — but only '
            'because you had money you did not need this year.',
        money: -500,
        happiness: -4,
        smarts: 7,
        setsFlag: LifeFlag.heldThroughCrash,
        teaches: FinanceConcept.compoundGrowth,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_index_payoff',
    prompt: 'You check the fund you have not touched in twenty years.',
    icon: Icons.auto_graph_rounded,
    minAge: 45,
    weight: 1.3,
    requiresFlag: LifeFlag.heldThroughCrash,
    choices: [
      LifeChoice(
        label: 'Look at what the boring option did',
        outcome:
            'Most of it is not money you put in. It is growth on growth on '
            'growth — the part that only exists because you left it alone '
            'long enough for time to do the work.',
        money: 6000,
        happiness: 12,
        smarts: 6,
        // Closes the thread. The fund is still there — `investsIndex` is
        // untouched — but the *story* about holding through a crash has now
        // been told, and leaving the flag up would keep the draw's
        // open-chain boost pointed at a beat with nothing left to say.
        clearsFlag: LifeFlag.heldThroughCrash,
        teaches: FinanceConcept.compoundGrowth,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_index_regret',
    prompt:
        'The market you sold out of has doubled since. A colleague who did '
        'nothing is retiring early.',
    icon: Icons.history_toggle_off_rounded,
    minAge: 40,
    weight: 1.2,
    requiresFlag: LifeFlag.soldInCrash,
    choices: [
      LifeChoice(
        label: 'Start again, and this time leave it alone',
        outcome:
            'The years you missed are gone and no amount of regret buys them '
            'back. Starting late beats not starting.',
        money: -500,
        smarts: 8,
        happiness: 4,
        clearsFlag: LifeFlag.soldInCrash,
        setsFlag: LifeFlag.investsIndex,
        teaches: FinanceConcept.sunkCost,
      ),
      LifeChoice(
        label: 'Wait for a dip to get back in',
        outcome:
            'You waited four more years. There was a dip; it was higher than '
            'the price you refused to pay. Time in the market beats timing '
            'the market.',
        happiness: -5,
        smarts: 4,
        teaches: FinanceConcept.sunkCost,
      ),
    ],
  ),

  // =====================================================================
  // The side hustle. Income you built rather than were given, with a real
  // exit — the earning-versus-keeping lesson in three beats.
  // =====================================================================
  LifeEvent(
    id: 'chain_hustle_start',
    prompt:
        'People keep asking if you would do it for money — the thing you '
        'are quietly good at.',
    icon: Icons.handyman_rounded,
    minAge: 15,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Charge for it',
        outcome:
            'First paying customer. Money you made rather than money you '
            'were given is a different feeling entirely.',
        money: 180,
        happiness: 8,
        skill: LifeSkill.business,
        skillGain: 2,
        setsFlag: LifeFlag.hasSideHustle,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Keep it a hobby',
        outcome:
            'Not everything you are good at has to become a job. Protecting '
            'the thing you like is a real reason to leave money on the '
            'table.',
        happiness: 6,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_hustle_grow',
    prompt:
        'The side work has more demand than you have evenings. Going bigger '
        'means 900 coins of equipment up front.',
    icon: Icons.rocket_launch_rounded,
    weight: 1.4,
    requiresFlag: LifeFlag.hasSideHustle,
    forbidsFlag: LifeFlag.soldTheBusiness,
    choices: [
      LifeChoice(
        label: 'Reinvest the profits into equipment',
        outcome:
            'Spending your earnings on something that earns is the whole '
            'difference between income and wealth. It is also the scariest '
            '900 coins you have spent.',
        money: -900,
        smarts: 5,
        skill: LifeSkill.business,
        skillGain: 3,
        // No longer a side hustle — which also closes that thread, so the
        // wind-down beat cannot later offer to shut down a real business.
        clearsFlag: LifeFlag.hasSideHustle,
        setsFlag: LifeFlag.hustleGrew,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Bank the profits and stay small',
        outcome:
            'Steady, safe, and it stays exactly the size it is. That is a '
            'legitimate choice, not a failure of nerve.',
        money: 500,
        happiness: 4,
        teaches: FinanceConcept.payYourselfFirst,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_hustle_wind_down',
    prompt:
        'The side work has stopped being fun. It is still evenings and '
        'weekends, and the money is no longer worth them.',
    icon: Icons.nightlight_round,
    minAge: 25,
    weight: 1.2,
    requiresFlag: LifeFlag.hasSideHustle,
    forbidsFlag: LifeFlag.hustleGrew,
    choices: [
      LifeChoice(
        label: 'Wind it down',
        outcome:
            'You gave the last customers to a friend and got your evenings '
            'back. Income you stop wanting is a cost, and stopping is '
            'allowed.',
        happiness: 9,
        clearsFlag: LifeFlag.hasSideHustle,
      ),
      LifeChoice(
        label: 'Raise your prices and take half the work',
        outcome:
            'Half the hours, nearly the same money, and the customers who '
            'left were the ones costing you the most to keep.',
        money: 600,
        happiness: 6,
        smarts: 6,
        skill: LifeSkill.business,
        skillGain: 2,
        clearsFlag: LifeFlag.hasSideHustle,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_hustle_offer',
    prompt: 'Someone wants to buy the business for four years of its profit.',
    icon: Icons.store_rounded,
    weight: 1.5,
    minAge: 25,
    requiresFlag: LifeFlag.hustleGrew,
    choices: [
      LifeChoice(
        label: 'Sell',
        outcome:
            'A business is worth what its future profits are worth today. '
            'You just turned a thing that earns into a lump you have to '
            'decide about — which is a harder problem than it sounds.',
        money: 8000,
        happiness: 8,
        clearsFlag: LifeFlag.hustleGrew,
        setsFlag: LifeFlag.soldTheBusiness,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Keep it — it pays every year',
        outcome:
            'Four years of profit for something that pays forever is only a '
            'good deal for the buyer. You kept the goose.',
        money: 1400,
        smarts: 7,
        skill: LifeSkill.business,
        skillGain: 2,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),

  // =====================================================================
  // The first car. Cheap to buy, expensive to own — the gap between a
  // price and a cost.
  // =====================================================================
  LifeEvent(
    id: 'chain_car_buy',
    prompt:
        'You can afford a car. A tidy used one is 1,800; the shiny one on '
        'finance is 240 a month for five years.',
    icon: Icons.directions_car_rounded,
    minAge: 17,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Buy the used one outright',
        outcome:
            'Less impressive, entirely yours, and no payment lands in a bad '
            'month. Owning the cheap thing outright beats renting the '
            'expensive one.',
        money: -1800,
        happiness: 7,
        smarts: 5,
        setsFlag: LifeFlag.hasCar,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Finance the shiny one',
        outcome:
            '240 a month for sixty months is 14,400 for a car worth half '
            'that by the end. A monthly price is a very effective way of '
            'not telling you the total.',
        money: -1440,
        happiness: 12,
        looks: 4,
        setsFlag: LifeFlag.hasCar,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Stay on the bus a while longer',
        outcome:
            'Slower, and about 2,000 coins a year cheaper once you count '
            'fuel, insurance and repairs. The sticker price was never the '
            'cost.',
        money: 300,
        happiness: -4,
        smarts: 7,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_car_repair',
    prompt: 'The car needs 600 coins of work to stay on the road.',
    icon: Icons.build_rounded,
    weight: 1.4,
    repeatable: true,
    requiresFlag: LifeFlag.hasCar,
    forbidsFlag: LifeFlag.carGone,
    choices: [
      LifeChoice(
        label: 'Fix it',
        outcome:
            'Running costs are the part nobody budgets for. This is what '
            '"needs" money is actually for.',
        money: -600,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Sell it and go without',
        outcome:
            'No repairs, no insurance, no fuel. Getting rid of a thing that '
            'costs money every month is a pay rise you give yourself.',
        money: 500,
        happiness: -5,
        smarts: 6,
        clearsFlag: LifeFlag.hasCar,
        setsFlag: LifeFlag.carGone,
        teaches: FinanceConcept.lifestyleCreep,
      ),
    ],
  ),

  // =====================================================================
  // Renting with a friend. Money and relationships in the same decision,
  // which is the version of this problem people actually meet.
  // =====================================================================
  LifeEvent(
    id: 'chain_rent_move',
    prompt:
        'A friend suggests splitting a flat. Half the rent each, and you '
        'both sign the same lease.',
    icon: Icons.house_rounded,
    minAge: 18,
    maxAge: 40,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Move in together',
        outcome:
            'Rent halved, and you are now jointly liable for all of it — '
            'which is the part of "splitting" the lease does not split.',
        money: 400,
        happiness: 9,
        addRelationship: 'Sam',
        setsFlag: LifeFlag.rentsWithFriend,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Get a smaller place on your own',
        outcome:
            'More expensive, and nobody else can make your rent late. You '
            'are paying for control.',
        money: -300,
        happiness: 3,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_rent_missed',
    prompt:
        'Sam has lost their job and cannot make rent this month. The '
        'landlord does not care whose half is missing.',
    icon: Icons.report_problem_rounded,
    weight: 1.5,
    requiresFlag: LifeFlag.rentsWithFriend,
    choices: [
      LifeChoice(
        label: 'Cover it and agree a repayment plan in writing',
        outcome:
            'Awkward for ten minutes, clear for both of you afterwards. '
            'Money between friends survives on being written down.',
        money: -500,
        happiness: 3,
        smarts: 6,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Cover it and say nothing',
        outcome:
            'You paid, they never quite got round to it, and neither of you '
            'mentions it. It cost 500 coins and a friendship.',
        money: -500,
        happiness: -9,
        clearsFlag: LifeFlag.rentsWithFriend,
      ),
      LifeChoice(
        label: 'Let it go to the landlord',
        outcome:
            'A joint lease means a missed payment is *your* missed payment '
            'too. It sat on your credit file for six years.',
        happiness: -6,
        smarts: 5,
        teaches: FinanceConcept.creditScore,
      ),
    ],
  ),

  // =====================================================================
  // Studying, and paying for it. The biggest number most people borrow
  // before a house.
  // =====================================================================
  LifeEvent(
    id: 'chain_study_loan',
    prompt:
        'You have a place on a course. It costs 6,000 coins you do not have.',
    icon: Icons.school_rounded,
    minAge: 17,
    maxAge: 30,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Take the loan',
        outcome:
            'Borrowing to buy something that raises what you can earn is the '
            'one kind of debt that can pay for itself — as long as it '
            'actually does.',
        smarts: 12,
        setsFlag: LifeFlag.hasStudentLoan,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Work first, study part time',
        outcome:
            'Slower, no debt, and you arrived with experience. There is more '
            'than one route and the expensive one is not automatically the '
            'best one.',
        money: 900,
        smarts: 7,
        setsFlag: LifeFlag.gotDegree,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Skip it',
        outcome:
            'No debt and no qualification. Whether that was the right call '
            'depends entirely on what you did with the four years.',
        money: 300,
      ),
    ],
  ),
  LifeEvent(
    id: 'chain_study_repay',
    prompt:
        'The loan repayments start. There is an option to overpay and clear '
        'it years early.',
    icon: Icons.account_balance_rounded,
    minAge: 22,
    weight: 1.3,
    requiresJob: true,
    requiresFlag: LifeFlag.hasStudentLoan,
    choices: [
      LifeChoice(
        label: 'Overpay and be done with it',
        outcome:
            'Years of interest you will never pay. The freedom of owing '
            'nobody anything is worth more than the arithmetic says.',
        money: -2200,
        happiness: 8,
        smarts: 5,
        clearsFlag: LifeFlag.hasStudentLoan,
        setsFlag: LifeFlag.loanRepaid,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Pay the minimum and invest the difference',
        outcome:
            'Reasonable *if* the investment beats the loan rate and you '
            'actually invest it. Most people who say this spend it instead.',
        money: -600,
        smarts: 7,
        teaches: FinanceConcept.compoundGrowth,
      ),
    ],
  ),

  // =====================================================================
  // Lifestyle creep, made mechanical: the raise, then the year after.
  // =====================================================================
  LifeEvent(
    id: 'chain_raise_creep',
    prompt: 'A solid raise lands. Your monthly income just went up by a fifth.',
    icon: Icons.trending_up_rounded,
    minAge: 22,
    weight: 1.3,
    requiresJob: true,
    choices: [
      LifeChoice(
        label: 'Bank the whole raise, live on the old number',
        outcome:
            'You already knew you could live on the old salary — you were '
            'doing it last month. Everything above it is free savings.',
        money: 900,
        smarts: 8,
        teaches: FinanceConcept.payYourselfFirst,
      ),
      LifeChoice(
        label: 'Upgrade the flat',
        outcome:
            'Nicer place, same amount left at the end of the month. A raise '
            'that raises your costs is not a raise — that is lifestyle '
            'creep, and it is why earning more so rarely feels like more.',
        happiness: 10,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Split it — half saved, half spent',
        outcome:
            'You feel the raise and you keep some of it. Boring, workable, '
            'and the version people actually stick to.',
        money: 400,
        happiness: 5,
        smarts: 4,
        teaches: FinanceConcept.budgetRule,
      ),
    ],
  ),
];
