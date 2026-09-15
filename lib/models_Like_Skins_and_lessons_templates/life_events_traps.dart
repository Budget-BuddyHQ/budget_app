import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_sim_models.dart';

/// Scams, fees and fine print — the things that actually take money off the
/// people this app is for.
///
/// **Why this pack exists.** The rest of the simulation is about decisions
/// where both options are honest: save or spend, rent or buy, index fund or
/// savings account. That is most of financial literacy and it is not all of
/// it. The money a fifteen-year-old actually loses is rarely lost to a bad
/// investment. It goes to a free trial that started charging, a subscription
/// nobody cancelled, a game currency bought at three in the morning, an
/// overdraft fee on a £4 coffee, or somebody on the internet who was very
/// friendly and then needed a gift card.
///
/// None of that was in the game.
///
/// **The rule these are written to.** Every one of them is survivable and
/// none of them are a trick. A scam event that punishes you for picking the
/// wrong option teaches "the game is out to get me", which generalises to
/// nothing. What these teach is the *shape* — what the pitch sounds like from
/// the inside, before you know how it ends. So:
///
/// * **The tell is always in the prompt.** Urgency, a stranger who found you,
///   a guaranteed return, a payment method that cannot be reversed. A player
///   who reads carefully can spot every one of these, which is the actual
///   transferable skill.
/// * **The careful option is never free.** Cancelling the trial takes a
///   reminder; reading the terms costs an evening; declining the friend's
///   crypto tip costs you the story where it went up. Making caution
///   costless would misrepresent why people do not do it.
/// * **Getting caught is not fatal.** Real amounts, in the tens and low
///   hundreds, and the outcome text says what to do next rather than what you
///   should have done. The one thing a child who has just been scammed needs
///   is to tell somebody, and the events say so.
///
/// **On the gambling ones.** `t_loot_box` and `t_skin_gamble` are in here
/// deliberately, and they are the ones closest to this app's own machinery —
/// Budget Buddy has a case-opening screen with a ratchet sound on it. A game
/// that teaches money to children while running an unexamined loot box would
/// be teaching the wrong thing much more effectively than any lesson teaches
/// the right one. So the sim names the mechanic, gives the real odds, and the
/// house edge is stated in the outcome rather than implied.
const List<LifeEvent> kLifeEventsTraps = <LifeEvent>[
  // --- Subscriptions and fine print ------------------------------------
  LifeEvent(
    id: 't_free_trial',
    prompt:
        'A month free, cancel any time. It wants a card number up front, and '
        'the cancel link is not on this page.',
    icon: Icons.card_membership_rounded,
    minAge: 13,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Sign up and set a reminder for day 28',
        outcome:
            'Free month, cancelled on time, cost nothing. The reminder is the '
            'entire trick — the business model is people who mean to cancel.',
        happiness: 4,
        smarts: 6,
        teaches: FinanceConcept.impulseSpending,
      ),
      LifeChoice(
        label: 'Sign up and deal with it later',
        outcome:
            'Later did not happen. \$11.99 a month for fourteen months before '
            'you noticed it on a statement: \$167 for a thing you used twice.',
        money: -167,
        happiness: -4,
        smarts: 4,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Skip it — you know what you are like',
        outcome:
            'Slightly boring, entirely free. Knowing which kind of person you '
            'are is worth more than any budgeting app.',
        smarts: 5,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
  LifeEvent(
    id: 't_subscription_audit',
    prompt:
        'Your bank app can list every recurring payment. You have never '
        'looked at that screen.',
    icon: Icons.receipt_long_rounded,
    minAge: 16,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Go through all of them',
        outcome:
            'Four you forgot, two you were paying twice. Cancelling took '
            'twenty minutes and saved \$31 a month — \$372 a year, for one '
            'evening.',
        money: 96,
        happiness: 5,
        smarts: 8,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Not now',
        outcome:
            'The money keeps going out. Small recurring costs are the hardest '
            'kind to notice, because no single month ever feels wrong.',
        money: -84,
        smarts: 2,
        teaches: FinanceConcept.lifestyleCreep,
      ),
    ],
  ),

  // --- Fees ------------------------------------------------------------
  LifeEvent(
    id: 't_overdraft',
    prompt:
        'Your balance is \$3.10 and a \$4 coffee just went through. The bank '
        'let it happen.',
    icon: Icons.local_cafe_rounded,
    minAge: 16,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Pay the fee and turn overdrafts off',
        outcome:
            'A \$35 fee on a \$4 coffee. You switched the setting so the card '
            'gets declined next time instead — a declined card is embarrassing '
            'for ten seconds and free forever.',
        money: -35,
        happiness: -3,
        smarts: 8,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Pay it and carry on',
        outcome:
            '\$35, then \$35 again in March, then \$35 in June. The fee is not '
            'the problem, the setting that allows it is.',
        money: -105,
        happiness: -6,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Ring the bank and ask them to drop it',
        outcome:
            'They dropped it. Banks refund first-time fees far more often than '
            'anybody asks — the call took four minutes.',
        money: -4,
        happiness: 4,
        smarts: 10,
        teaches: FinanceConcept.interestCost,
      ),
    ],
  ),
  LifeEvent(
    id: 't_buy_now_pay_later',
    prompt:
        'Four payments of \$22, no interest. It is at the checkout of '
        'everything now and it is one tap.',
    icon: Icons.shopping_bag_rounded,
    minAge: 15,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Use it, and pay all four on time',
        outcome:
            'Genuinely free this time. The catch is not this purchase, it is '
            'that a \$88 thing now feels like a \$22 thing, and you will make '
            'that trade again next week.',
        money: -88,
        happiness: 5,
        smarts: 4,
        teaches: FinanceConcept.lifestyleCreep,
      ),
      LifeChoice(
        label: 'Use it, and miss one',
        outcome:
            'A \$7 late fee, then another. "No interest" is true and it is not '
            'the same as "no cost" — the fees are where the money is.',
        money: -102,
        happiness: -5,
        smarts: 8,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Wait and pay for it outright next month',
        outcome:
            'You waited. About a third of the things people split into four '
            'payments stop looking necessary if you leave them a month.',
        money: -88,
        happiness: 3,
        smarts: 7,
        teaches: FinanceConcept.impulseSpending,
      ),
    ],
  ),

  // --- Actual scams -----------------------------------------------------
  LifeEvent(
    id: 't_gift_card_scam',
    prompt:
        'A message from someone claiming to be your school office. There is a '
        'problem with your account, it is urgent, and they need you to buy '
        'gift cards and send the codes.',
    icon: Icons.warning_amber_rounded,
    minAge: 11,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Show an adult before doing anything',
        outcome:
            'Not the school. No real organisation has ever been paid in gift '
            'card codes — that is the whole tell, and it works at any age.',
        happiness: 4,
        smarts: 14,
        teaches: FinanceConcept.impulseSpending,
      ),
      LifeChoice(
        label: 'Do it — it sounded serious',
        outcome:
            'The codes were spent within a minute and gift cards cannot be '
            'reversed, which is exactly why they asked for them. \$60 gone. '
            'You told someone, which is the part that matters.',
        money: -60,
        happiness: -8,
        smarts: 12,
        teaches: FinanceConcept.impulseSpending,
      ),
      LifeChoice(
        label: 'Ring the school on the number you already had',
        outcome:
            'Engaged, then answered, then confused — because it was never '
            'them. Calling back on a number you looked up yourself beats every '
            'kind of caller ID.',
        happiness: 3,
        smarts: 16,
        teaches: FinanceConcept.impulseSpending,
      ),
    ],
  ),
  LifeEvent(
    id: 't_crypto_friend',
    prompt:
        'A friend has tripled their money in a month on something you have '
        'not heard of. They are annoyed you are not in yet.',
    icon: Icons.currency_bitcoin_rounded,
    minAge: 15,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Put in what you could afford to lose',
        outcome:
            'Down 70% by autumn. The money was small enough not to matter, '
            'which is the only reason this is a story and not a problem.',
        money: -120,
        happiness: -3,
        smarts: 10,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Put in everything you had',
        outcome:
            'Down 70% on all of it. The friend had been up on paper and never '
            'sold. Almost nobody who tells you about a win has taken it.',
        money: -640,
        happiness: -12,
        smarts: 14,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Ask what happens if it goes down',
        outcome:
            'They did not have an answer. "It only goes up" is not a plan, and '
            'the question costs nothing to ask.',
        smarts: 12,
        happiness: 2,
        teaches: FinanceConcept.diversification,
      ),
    ],
  ),
  LifeEvent(
    id: 't_fake_job',
    prompt:
        'A job offer arrived that you did not apply for. Work from home, good '
        'money — but they need \$95 up front for the equipment.',
    icon: Icons.work_off_rounded,
    minAge: 16,
    weight: 0.95,
    choices: [
      LifeChoice(
        label: 'Walk away',
        outcome:
            'A real employer has never charged you to start. Money moves from '
            'them to you, in that direction, always.',
        smarts: 12,
        happiness: 2,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Pay it — the money was good',
        outcome:
            '\$95, no equipment, no replies. The good money was the bait and '
            'the fee was the entire business.',
        money: -95,
        happiness: -7,
        smarts: 10,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),
  LifeEvent(
    id: 't_influencer_tip',
    prompt:
        'Someone with 900,000 followers is very confident about a stock. The '
        'post has a countdown on it.',
    icon: Icons.trending_up_rounded,
    minAge: 15,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Check whether they were paid to post it',
        outcome:
            'They were. It was in grey text at the bottom. Somebody being '
            'confident and somebody being right are unrelated, and the '
            'countdown was there to stop you checking.',
        smarts: 14,
        happiness: 2,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Buy before the countdown ends',
        outcome:
            'It had already peaked by the time the post reached you — that is '
            'what the countdown is for. Down \$180.',
        money: -180,
        happiness: -6,
        smarts: 10,
        teaches: FinanceConcept.impulseSpending,
      ),
    ],
  ),

  // --- The mechanic this app itself runs -------------------------------
  LifeEvent(
    id: 't_loot_box',
    prompt:
        'A game you play sells boxes. The thing you want is a 0.6% chance, and '
        'the boxes are \$2.30 each.',
    icon: Icons.casino_rounded,
    minAge: 10,
    // Shown to 9-to-12s and up, never to the 4-to-8 band, whose characters
    // can reach age 10 in a couple of minutes of tapping.
    showsGamblingMechanic: true,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Work out what it would actually cost',
        outcome:
            'At 0.6%, it takes about 115 boxes to be even likely — roughly '
            '\$265 for one item. Written down it stopped being tempting, '
            'which is why it is never written down.',
        smarts: 14,
        happiness: 2,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Buy ten and see',
        outcome:
            'Nothing. Ten tries at 0.6% is a 6% chance overall, so this was '
            'the likely outcome rather than bad luck — and the next ten are '
            'the same odds as the first ten.',
        money: -23,
        happiness: -2,
        smarts: 8,
        teaches: FinanceConcept.sunkCost,
      ),
      LifeChoice(
        label: 'Keep going — you are due',
        outcome:
            'You were not due. Each box forgets the last one, and \$140 later '
            'the feeling that you must be close is the product being sold.',
        money: -140,
        happiness: -8,
        smarts: 12,
        teaches: FinanceConcept.sunkCost,
      ),
    ],
  ),
  LifeEvent(
    id: 't_skin_gamble',
    prompt:
        'A site will let you bet the item you own for a shot at a better one. '
        'It says the odds are fair.',
    icon: Icons.swap_horiz_rounded,
    minAge: 13,
    showsGamblingMechanic: true,
    weight: 0.85,
    choices: [
      LifeChoice(
        label: 'Read what "fair" means here',
        outcome:
            'Fair meant a 5% cut on every trade. The odds were honest and the '
            'house still wins, because the house is not betting — it is '
            'charging. That is true of every site like it.',
        smarts: 14,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Trade it',
        outcome:
            'Gone. These sites almost never check age, which should tell you '
            'what they are, and the item is not coming back.',
        money: -55,
        happiness: -9,
        smarts: 10,
        teaches: FinanceConcept.sunkCost,
      ),
    ],
  ),

  // --- Being on the other end of it ------------------------------------
  LifeEvent(
    id: 't_lent_to_friend',
    prompt:
        'A friend needs \$70 until the end of the month. They have asked '
        'before and it took a while.',
    icon: Icons.handshake_rounded,
    minAge: 14,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Give what you can afford to lose, as a gift',
        outcome:
            'They paid most of it back and the friendship survived. Lending to '
            'friends works far better when you have already decided you are '
            'not getting it back.',
        money: -45,
        happiness: 6,
        smarts: 8,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Lend it and expect it back',
        outcome:
            'You got \$20 of it and stopped asking. The money was survivable; '
            'spending four months quietly annoyed was the actual cost.',
        money: -50,
        happiness: -5,
        smarts: 6,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Say no, and mean it kindly',
        outcome:
            'Awkward for an afternoon. "I cannot do it this month" is a whole '
            'sentence and it does not need a reason attached.',
        happiness: -2,
        smarts: 9,
        teaches: FinanceConcept.needsVsWants,
      ),
    ],
  ),
];
