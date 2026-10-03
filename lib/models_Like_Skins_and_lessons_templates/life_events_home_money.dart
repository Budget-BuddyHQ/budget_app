import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_assets.dart';
import 'life_sim_models.dart';

/// Events about the things you own, the money that comes and goes, and the
/// people you share a life with.
///
/// **Why these are gated on what you have.** A car breaking down is only a story
/// if there is a car. The events here fire on a car, a home, a pet, rent, a
/// partner or a child, so each one is about something the player chose earlier
/// and is now living with. That is what turns a pool of standalone beats into a
/// life with consequences.
///
/// Written for players nine and up. Money choices in one event all teach the same
/// idea, and the options that cost more are not made to sound like mistakes:
/// where a choice is a real trade, the outcome says so.
const List<LifeEvent> kLifeEventsHomeMoney = <LifeEvent>[
  // ==== Things you own =========================================================
  LifeEvent(
    id: 'h_fender_bender',
    prompt:
        'A small bump in a car park leaves a dent in your car. Nobody is '
        'hurt.',
    icon: Icons.car_crash_rounded,
    minAge: 18,
    maxAge: 80,
    requiresAsset: AssetKind.vehicle,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Fix it yourself and skip the insurance (120 coins)',
        outcome:
            'Your premium stayed the same and the bill was all yours. '
            'Insurance exists for the big one, and small ones are a choice.',
        money: -120,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Claim on your insurance (50 excess)',
        outcome:
            'You paid the excess and they paid the rest. That is what '
            'the premiums were for.',
        money: -50,
        smarts: 2,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Leave the dent',
        outcome: 'Free, and it looks a bit sad. It will cost you at resale.',
        happiness: -2,
        teaches: FinanceConcept.insurance,
      ),
    ],
  ),
  LifeEvent(
    id: 'h_warning_light',
    prompt: 'A warning light comes on in your car. It has been on for a week.',
    icon: Icons.build_rounded,
    minAge: 18,
    maxAge: 80,
    requiresAsset: AssetKind.vehicle,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Get it checked now (60 coins)',
        outcome:
            'A small part, caught early. Cheap compared with the '
            'alternative.',
        money: -60,
        smarts: 3,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Leave it a while longer',
        outcome:
            'It was fine for a month and then it was not. The part '
            'that was 60 coins is now 200.',
        money: -200,
        happiness: -3,
        teaches: FinanceConcept.emergencyFund,
      ),
    ],
  ),
  LifeEvent(
    id: 'h_appliance_breaks',
    prompt: 'The fridge stops working in the middle of the night.',
    icon: Icons.kitchen_rounded,
    minAge: 20,
    maxAge: 80,
    requiresAsset: AssetKind.home,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Get it repaired (80 coins)',
        outcome:
            'The repair person had it going in an hour. Cheaper than a '
            'new one.',
        money: -80,
        smarts: 2,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Buy a new one (250 coins)',
        outcome: 'It has a fancier door, and you paid for it.',
        money: -250,
        happiness: 2,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Buy a second-hand one (90 coins)',
        outcome: 'Works fine, and it is not the one from the catalogue.',
        money: -90,
        smarts: 3,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 'h_storm_damage',
    prompt: 'A storm loosens some tiles on your roof. There is a small leak.',
    icon: Icons.thunderstorm_rounded,
    minAge: 21,
    maxAge: 85,
    requiresAsset: AssetKind.home,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Have it fixed now (150 coins)',
        outcome:
            'A dry ceiling and a smaller bill than waiting would have '
            'been.',
        money: -150,
        smarts: 2,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Claim on your home insurance (75 excess)',
        outcome:
            'This is exactly what it is for. You paid the excess and '
            'the rest was covered.',
        money: -75,
        smarts: 3,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Put a bucket under it and hope',
        outcome: 'It got worse with the next rain. The bucket was not a plan.',
        money: -280,
        happiness: -4,
        teaches: FinanceConcept.insurance,
      ),
    ],
  ),
  LifeEvent(
    id: 'h_property_tax',
    prompt: 'The yearly bill for owning your home arrives.',
    icon: Icons.receipt_rounded,
    minAge: 21,
    maxAge: 90,
    requiresAsset: AssetKind.home,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Pay it on time (60 coins)',
        outcome: 'Owning a home means paying for it every year, not only once.',
        money: -60,
        teaches: FinanceConcept.taxes,
      ),
      LifeChoice(
        label: 'Check it before paying',
        outcome:
            'There was a small mistake in your favour. Reading the bill '
            'saved you 15.',
        money: -45,
        smarts: 4,
        teaches: FinanceConcept.taxes,
      ),
    ],
  ),
  LifeEvent(
    id: 'h_pet_sick',
    prompt:
        'Your pet is off their food and looks miserable. The vet wants to '
        'see them.',
    icon: Icons.pets_rounded,
    minAge: 8,
    maxAge: 90,
    requiresAsset: AssetKind.pet,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Pay for the full treatment (90 coins)',
        outcome: 'Back to normal within a week. Worth every coin.',
        money: -90,
        happiness: 5,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Ask about the cheaper option (40 coins)',
        outcome: 'It was not as thorough and it did the job.',
        money: -40,
        happiness: 2,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Wait and see',
        outcome: 'They got worse before they got better. You felt awful.',
        happiness: -9,
        teaches: FinanceConcept.emergencyFund,
      ),
    ],
  ),
  LifeEvent(
    id: 'h_pet_trick',
    prompt: 'Your pet has learned something new and wants you to see it.',
    icon: Icons.emoji_emotions_rounded,
    minAge: 6,
    maxAge: 95,
    requiresAsset: AssetKind.pet,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Watch, and clap',
        outcome: 'Very proud, and so are you.',
        happiness: 6,
      ),
      LifeChoice(
        label: 'Film it and send it to a friend',
        outcome:
            'They watched it four times and replied with six exclamation '
            'marks.',
        happiness: 7,
      ),
    ],
  ),
  LifeEvent(
    id: 'h_rent_rise',
    topic: 'rent_rise',
    prompt: 'Your landlord says the rent is going up next year.',
    icon: Icons.apartment_rounded,
    minAge: 18,
    maxAge: 70,
    requiresRenting: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Accept it',
        outcome: 'The easiest choice and the one that costs most over time.',
        happiness: -3,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Ask to negotiate',
        outcome:
            'You pointed out that you always pay on time. They met you '
            'in the middle.',
        smarts: 4,
        happiness: 2,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Look at cheaper places (40 coins to move)',
        outcome:
            'It was a hassle and the new place costs less each year. '
            'Moving has its own price.',
        money: -40,
        happiness: 1,
        teaches: FinanceConcept.lifestyleCreep,
      ),
    ],
  ),
  LifeEvent(
    id: 'h_leaky_tap',
    prompt: 'The tap in your rented flat has been dripping for weeks.',
    icon: Icons.plumbing_rounded,
    minAge: 18,
    maxAge: 70,
    requiresRenting: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Ask the landlord to fix it, in writing',
        outcome: 'A record helps. It was fixed in a week.',
        smarts: 3,
        happiness: 2,
      ),
      LifeChoice(
        label: 'Fix it yourself',
        outcome: 'A new washer and a video. It took an hour and it felt good.',
        money: -8,
        smarts: 3,
        happiness: 3,
      ),
      LifeChoice(
        label: 'Live with the drip',
        outcome: 'It is a very annoying sound at night.',
        happiness: -3,
      ),
    ],
  ),

  // ==== Money, day to day =========================================================
  LifeEvent(
    id: 'm_found_wallet',
    topic: 'found_wallet',
    prompt:
        'You find a wallet on the pavement with 60 coins and an ID card in '
        'it.',
    icon: Icons.account_balance_wallet_rounded,
    minAge: 10,
    maxAge: 85,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Hand it in',
        outcome: 'The owner was so relieved. You feel good about it.',
        happiness: 7,
        smarts: 2,
      ),
      LifeChoice(
        label: 'Keep the money and post the wallet back',
        outcome: 'You got 60 and a bad feeling that lasted a lot longer.',
        money: 60,
        happiness: -6,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_bonus',
    prompt: 'Your workplace pays out a surprise bonus of 200 coins.',
    icon: Icons.card_giftcard_rounded,
    minAge: 20,
    maxAge: 62,
    requiresJob: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Save all of it',
        outcome: 'Boring, and a lovely feeling next time something goes wrong.',
        money: 200,
        smarts: 4,
        teaches: FinanceConcept.payYourselfFirst,
      ),
      LifeChoice(
        label: 'Half for you, half for later',
        outcome:
            'A treat and a cushion. Most people are happier with a bit '
            'of both.',
        money: 200,
        happiness: 5,
        smarts: 2,
        teaches: FinanceConcept.payYourselfFirst,
      ),
      LifeChoice(
        label: 'Treat yourself to something big',
        outcome: 'It was a great feeling and gone in a weekend.',
        money: 200,
        happiness: 9,
        teaches: FinanceConcept.payYourselfFirst,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_scam_message',
    prompt:
        'A message says you have won a prize, and you only need to send '
        'your bank details to claim it.',
    icon: Icons.phishing_rounded,
    minAge: 12,
    maxAge: 90,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Delete it and block the sender',
        outcome:
            'If you did not enter, you cannot have won. Easy money is '
            'almost never easy.',
        smarts: 4,
        happiness: 1,
      ),
      LifeChoice(
        label: 'Show somebody you trust',
        outcome: 'They spotted three warning signs. Two heads help.',
        smarts: 3,
      ),
      LifeChoice(
        label: 'Click the link to see',
        outcome:
            'It did not take money, but it took a lot of your afternoon '
            'to secure your accounts. Lesson learned.',
        smarts: -1,
        happiness: -5,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_bank_fee',
    prompt:
        'You notice a 25 coin fee on your account for going a little '
        'overdrawn.',
    icon: Icons.account_balance_rounded,
    minAge: 18,
    maxAge: 80,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Set up low-balance alerts',
        outcome:
            'A text before it happens costs nothing. The fee, once, '
            'cost 25.',
        money: -25,
        smarts: 4,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Call and ask them to waive it',
        outcome: 'It was your first time, so they did. Asking is free.',
        smarts: 3,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Shrug and pay it',
        outcome: 'Small fees add up faster than they look.',
        money: -25,
        happiness: -1,
        teaches: FinanceConcept.budgetRule,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_prices_creep',
    prompt:
        'Your shopping costs more than it did last year, for the same '
        'things.',
    icon: Icons.shopping_cart_rounded,
    minAge: 20,
    maxAge: 85,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Adjust your budget to match',
        outcome:
            'Prices creep up a little every year. A budget that never '
            'changes slowly stops working.',
        smarts: 5,
        teaches: FinanceConcept.inflation,
      ),
      LifeChoice(
        label: 'Switch to cheaper brands',
        outcome: 'Most of them were just as good. A few were not.',
        money: 30,
        smarts: 2,
        teaches: FinanceConcept.inflation,
      ),
      LifeChoice(
        label: 'Ignore it',
        outcome:
            'You noticed at the end of the month, when it was too late '
            'to do much.',
        happiness: -2,
        teaches: FinanceConcept.inflation,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_friend_pitch',
    prompt: 'A friend has a business idea and asks if you would put in 200.',
    icon: Icons.lightbulb_rounded,
    minAge: 20,
    maxAge: 60,
    minMoney: 200,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Put in the 200',
        outcome:
            'It did not take off. You still have the friend, and you '
            'learned what it feels like to lose money on somebody you '
            'like.',
        money: -200,
        happiness: -2,
        smarts: 3,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Put in a smaller amount you can afford to lose',
        outcome:
            'It was worth losing and it was not needed. That is the '
            'right way round.',
        money: -50,
        smarts: 5,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Say no, kindly',
        outcome:
            'They understood, mostly. Not every good idea needs your '
            'money.',
        smarts: 3,
        teaches: FinanceConcept.diversification,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_phone_warranty',
    prompt:
        'The shop asks if you want an extended warranty on your new phone '
        'for 40.',
    icon: Icons.phone_iphone_rounded,
    minAge: 14,
    maxAge: 80,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Take the warranty (40 coins)',
        outcome:
            'It was never needed, and you slept fine. That is what '
            'insurance feels like when it works.',
        money: -40,
        teaches: FinanceConcept.insurance,
      ),
      LifeChoice(
        label: 'Decline, and use a case',
        outcome:
            'A case costs less than the warranty and it prevents the '
            'problem.',
        money: -10,
        smarts: 3,
        teaches: FinanceConcept.insurance,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_charity_ask',
    prompt: 'A charity you care about is raising money for a local shelter.',
    icon: Icons.volunteer_activism_rounded,
    minAge: 12,
    maxAge: 90,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Give 30 coins',
        outcome:
            'It felt good to be part of it. Giving is part of a healthy '
            'budget too.',
        money: -30,
        happiness: 6,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Give your time instead',
        outcome: 'Two afternoons sorting donations. Worth more than the coins.',
        happiness: 7,
        smarts: 1,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Not this time',
        outcome:
            'You are looking after your own budget first, which is '
            'allowed.',
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_credit_check',
    prompt: 'You look up your credit score for the first time.',
    icon: Icons.speed_rounded,
    minAge: 21,
    maxAge: 60,
    choices: [
      LifeChoice(
        label: 'Pay every bill on time from now on',
        outcome:
            'Your score is a record of how reliable you have been with '
            'borrowed money. Paying on time is what builds it.',
        smarts: 5,
        teaches: FinanceConcept.creditScore,
      ),
      LifeChoice(
        label: 'Look for mistakes on the report',
        outcome: 'One was wrong, and you had it corrected.',
        smarts: 6,
        teaches: FinanceConcept.creditScore,
      ),
      LifeChoice(
        label: 'Close the tab and forget it',
        outcome: 'Out of sight is not out of mind. It still counted.',
        happiness: -1,
        teaches: FinanceConcept.creditScore,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_budget_app',
    prompt: 'A friend shows you an app that tracks every coin you spend.',
    icon: Icons.pie_chart_rounded,
    minAge: 16,
    maxAge: 70,
    choices: [
      LifeChoice(
        label: 'Try it for a month',
        outcome:
            'You were shocked by how much went on small things. You '
            'kept the app.',
        smarts: 6,
        happiness: 1,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Keep a notebook instead',
        outcome:
            'Slower, and just as good. The habit matters more than the '
            'tool.',
        smarts: 4,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Not for you',
        outcome:
            'Fair enough. Money you do not look at has a way of '
            'wandering.',
        teaches: FinanceConcept.budgetRule,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_new_hobby',
    prompt: 'You have taken up a new hobby. The good gear is very tempting.',
    icon: Icons.palette_rounded,
    minAge: 14,
    maxAge: 75,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Buy the best kit (200 coins)',
        outcome:
            'It looks amazing. You do not know yet if you will stick '
            'with it.',
        money: -200,
        happiness: 5,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Start with the basics (60 coins)',
        outcome: 'Enough to learn on. If it lasts, you can upgrade.',
        money: -60,
        happiness: 4,
        smarts: 3,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Borrow what you need',
        outcome:
            'A friend had it in a cupboard. It cost nothing to find out '
            'if you liked it.',
        happiness: 3,
        smarts: 2,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 'm_garage_sale',
    prompt: 'Your cupboards are full of things you never use.',
    icon: Icons.sell_rounded,
    minAge: 18,
    maxAge: 80,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Have a garage sale',
        outcome:
            'A Saturday, some haggling, and 60 coins for things you had '
            'forgotten.',
        money: 60,
        happiness: 3,
        teaches: FinanceConcept.sunkCost,
      ),
      LifeChoice(
        label: 'Give it to a charity shop',
        outcome: 'A lighter home, and somebody else gets to use it.',
        happiness: 4,
        teaches: FinanceConcept.sunkCost,
      ),
      LifeChoice(
        label: 'Keep it, just in case',
        outcome:
            'It is still in the cupboard. What you paid is gone either '
            'way.',
        teaches: FinanceConcept.sunkCost,
      ),
    ],
  ),

  // ==== Partners and families ====================================================
  LifeEvent(
    id: 'f_move_in',
    prompt: 'You and your partner talk about moving in together.',
    icon: Icons.key_rounded,
    minAge: 21,
    maxAge: 55,
    requiresPartner: true,
    choices: [
      LifeChoice(
        label: 'Move in and split the costs',
        outcome:
            'Rent halves and so do the dishes. It also tests how you '
            'talk about money.',
        money: 40,
        happiness: 6,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Wait another year',
        outcome: 'No rush, and it saved an awkward conversation for later.',
        happiness: 1,
        teaches: FinanceConcept.budgetRule,
      ),
    ],
  ),
  LifeEvent(
    id: 'f_money_argument',
    prompt: 'You and your partner have had an argument about money. Again.',
    icon: Icons.forum_rounded,
    minAge: 22,
    maxAge: 70,
    requiresPartner: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Sit down and make a budget together',
        outcome:
            'It was uncomfortable for an hour and easier for years. '
            'Couples who talk about money argue about it less.',
        smarts: 6,
        happiness: 5,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Let one of you handle all of it',
        outcome:
            'Simple, and the one who did not look had no idea where '
            'it went.',
        happiness: -2,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Avoid the subject',
        outcome: 'The argument came back in a different shape.',
        happiness: -5,
        teaches: FinanceConcept.budgetRule,
      ),
    ],
  ),
  LifeEvent(
    id: 'f_wedding_invite',
    prompt: 'A close friend is getting married and you are invited.',
    icon: Icons.favorite_rounded,
    minAge: 20,
    maxAge: 70,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Go, with a thoughtful gift (80 coins)',
        outcome: 'A lovely day. The gift was noticed and the memory lasts.',
        money: -80,
        happiness: 7,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Go, with a smaller gift (30 coins)',
        outcome:
            'Nobody remembers the price of a gift. They remember you '
            'were there.',
        money: -30,
        happiness: 6,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Send your best wishes and stay home',
        outcome: 'A quiet weekend, and a small distance you noticed later.',
        happiness: -2,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 'f_sibling_loan',
    prompt: 'A brother or sister asks to borrow 100 coins until payday.',
    icon: Icons.family_restroom_rounded,
    minAge: 20,
    maxAge: 65,
    minMoney: 100,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Lend it and expect it back',
        outcome:
            'It came back late. It is easier to lend than to ask for '
            'it back.',
        money: -100,
        happiness: 1,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Give a smaller amount, as a gift',
        outcome:
            'You never asked for it back, and that made it easier for '
            'both of you.',
        money: -40,
        happiness: 3,
        teaches: FinanceConcept.emergencyFund,
      ),
      LifeChoice(
        label: 'Help them make a plan instead',
        outcome: 'Harder, and it was the thing that actually helped.',
        smarts: 5,
        happiness: 2,
        teaches: FinanceConcept.emergencyFund,
      ),
    ],
  ),
  LifeEvent(
    id: 'f_family_reunion',
    prompt: 'The whole family is meeting up for a reunion. It is a long trip.',
    icon: Icons.groups_rounded,
    minAge: 12,
    maxAge: 90,
    requiresParent: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Go, and stay the whole weekend (60 coins)',
        outcome:
            'Cousins you had not seen in years, and a photo on every '
            'wall.',
        money: -60,
        happiness: 8,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Go for the day',
        outcome: 'A long drive and a good few hours.',
        money: -20,
        happiness: 4,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Send a card',
        outcome: 'They missed you. You missed them too.',
        happiness: -2,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 'f_first_steps',
    prompt: 'Your child takes their first steps, straight towards you.',
    icon: Icons.child_care_rounded,
    minAge: 20,
    maxAge: 55,
    requiresChild: true,
    choices: [
      LifeChoice(
        label: 'Get down on the floor and cheer',
        outcome: 'You will remember this for the rest of your life.',
        happiness: 10,
      ),
      LifeChoice(
        label: 'Film it for the family',
        outcome:
            'Everybody watched it twice. You watched it a lot more '
            'than that.',
        happiness: 8,
      ),
    ],
  ),
  LifeEvent(
    id: 'f_child_allowance',
    prompt: 'Your child asks for an allowance.',
    icon: Icons.savings_rounded,
    minAge: 26,
    maxAge: 60,
    requiresChild: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Yes, in return for small jobs',
        outcome:
            'They learned that money comes from doing something, which '
            'is the first lesson.',
        money: -10,
        happiness: 3,
        smarts: 3,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Yes, with a jar for saving',
        outcome:
            'A jar for spending and a jar for later. They were proud '
            'of both.',
        money: -10,
        happiness: 4,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Buy things when they ask',
        outcome: 'It was easier and they never learned what things cost.',
        money: -30,
        happiness: 1,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),
  LifeEvent(
    id: 'f_school_play',
    prompt:
        'Your child is in the school play. It clashes with a work '
        'deadline.',
    icon: Icons.theater_comedy_rounded,
    minAge: 28,
    maxAge: 55,
    requiresChild: true,
    requiresJob: true,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Go, and finish the work later',
        outcome:
            'They looked for you in the audience and found you. A late '
            'night was worth it.',
        happiness: 9,
        health: -1,
      ),
      LifeChoice(
        label: 'Ask a colleague to cover for you',
        outcome: 'A favour owed, and a happy child.',
        happiness: 7,
      ),
      LifeChoice(
        label: 'Stay and finish',
        outcome:
            'The deadline was met. The play is a memory you only '
            'heard about.',
        happiness: -6,
        smarts: 1,
      ),
    ],
  ),
  LifeEvent(
    id: 'f_friend_moves',
    prompt: 'A good friend tells you they are moving to another city.',
    icon: Icons.local_shipping_rounded,
    minAge: 10,
    maxAge: 70,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Plan a visit and keep in touch',
        outcome:
            'A weekly message turned into a real habit. Distance is '
            'less than you think.',
        happiness: 5,
      ),
      LifeChoice(
        label: 'Throw them a goodbye party (40 coins)',
        outcome: 'A good send-off, and a promise to call.',
        money: -40,
        happiness: 6,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Let it fade',
        outcome: 'It did. You think of them sometimes.',
        happiness: -4,
      ),
    ],
  ),
  LifeEvent(
    id: 'f_new_neighbour',
    prompt: 'A new neighbor moves in next door and waves.',
    icon: Icons.waving_hand_rounded,
    minAge: 12,
    maxAge: 85,
    repeatable: true,
    choices: [
      LifeChoice(
        label: 'Bring over something to say welcome',
        outcome: 'It cost almost nothing and you became friends.',
        happiness: 5,
        addRelationship: 'A friendly neighbor',
      ),
      LifeChoice(
        label: 'Wave back',
        outcome: 'Friendly enough. You nod when you meet.',
        happiness: 1,
      ),
    ],
  ),
];
