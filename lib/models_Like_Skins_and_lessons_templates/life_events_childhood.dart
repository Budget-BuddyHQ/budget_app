import 'package:flutter/material.dart';

import 'finance_concepts.dart';
import 'life_sim_models.dart';

/// The school years, where money first belongs to you.
///
/// **The gap this closes.** Counting eligible events by age put ages 5 to 15
/// at 20–23, against 60–70 for every adult year. A run plays eighteen turns
/// through childhood before it reaches twenty, so the thinnest stretch of the
/// pool was also the *opening* of the game — the first ten minutes a new
/// player sees, and the whole of what the 4–12 audience plays.
///
/// **Why these are shaped differently from the adult pack.** An adult event is
/// about which system you want to be inside. A child's is about the first time
/// an idea shows up at all: that a thing has a price, that waiting can be
/// worth money, that a friend's spending is not a budget, that money you lend
/// a friend is usually a gift. The sums are pocket-sized on purpose — a
/// nine-year-old learns nothing from a mortgage — but the shape of the
/// decision is the same one they will meet at thirty with three more zeroes.
///
/// Every one of them has a choice a child would actually make and is not
/// punished for. Nothing here teaches that spending is a mistake; several
/// options spend the money and are the better answer for it.
const List<LifeEvent> kLifeEventsChildhood = <LifeEvent>[
  // --- Money that is yours for the first time ------------------------
  LifeEvent(
    id: 'c_first_pocket_money',
    prompt:
        'You get pocket money for the first time. \$3 a week, and nobody is '
        'telling you what to do with it.',
    icon: Icons.volunteer_activism_rounded,
    minAge: 5,
    maxAge: 11,
    weight: 1.3,
    choices: [
      LifeChoice(
        label: 'Spend it the same day, every week',
        outcome:
            'Twelve weeks of sweets and nothing to show for it. Which is a '
            'perfectly normal way to start, and now you know what \$36 spent '
            'without a plan feels like.',
        happiness: 5,
        smarts: 2,
      ),
      LifeChoice(
        label: 'Keep \$1 back every week',
        outcome:
            'Twelve weeks later you have \$12 and you did not miss the dollar. '
            'That is the whole trick — a small amount taken off the top before '
            'you start spending is the one nobody notices.',
        happiness: 2,
        smarts: 6,
        teaches: FinanceConcept.payYourselfFirst,
      ),
      LifeChoice(
        label: 'Split it: some now, some in the jar',
        outcome:
            'Two dollars for this week, one for later. A plan that leaves room '
            'for the thing you actually wanted is the kind you are still using '
            'at forty.',
        happiness: 4,
        smarts: 5,
        teaches: FinanceConcept.budgetRule,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_price_tag',
    prompt:
        'You ask for something in a shop and get told what it costs. It is the '
        'first time the number has meant anything.',
    icon: Icons.sell_rounded,
    minAge: 4,
    maxAge: 9,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Ask why it costs that much',
        outcome:
            'Nobody has a tidy answer, which is itself the answer: a price is '
            'what somebody thinks you will pay. Asking the question early is '
            'worth more than any single fact about money.',
        smarts: 7,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Ask how many weeks of pocket money that is',
        outcome:
            'Four weeks. Suddenly it is not "\$12", it is "a month", and a '
            'month is a thing you can feel. Converting a price into your own '
            'time is the most useful sum there is.',
        smarts: 8,
        teaches: FinanceConcept.opportunityCost,
      ),
      LifeChoice(
        label: 'Ask for it anyway',
        outcome:
            'You get a no, and it is not a lesson about being greedy — it is '
            'the first time you have run into the fact that money runs out '
            'even for grown-ups.',
        happiness: -1,
        smarts: 3,
      ),
    ],
  ),

  // --- Wanting things ------------------------------------------------
  LifeEvent(
    id: 'c_saving_for_the_thing',
    prompt:
        'The thing you want costs \$40. You have \$11 and \$3 a week coming '
        'in.',
    icon: Icons.savings_rounded,
    minAge: 6,
    maxAge: 13,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Wait the ten weeks',
        outcome:
            'Ten weeks is a long time when you are nine, and you got there. '
            'The thing you waited for is the one you still have in a year — '
            'that turns out to be true at every age.',
        money: -40,
        happiness: 8,
        smarts: 7,
        teaches: FinanceConcept.payYourselfFirst,
      ),
      LifeChoice(
        label: 'Buy something smaller now instead',
        outcome:
            'You have something today and the \$40 thing is no closer. Not a '
            'disaster — but this is the exact move that keeps people from ever '
            'reaching the big thing, and it is worth knowing you made it.',
        money: -11,
        happiness: 4,
        smarts: 4,
        teaches: FinanceConcept.impulseSpending,
      ),
      LifeChoice(
        label: 'Ask to do jobs to get there faster',
        outcome:
            'Six weeks instead of ten. There are two ways to close a gap — '
            'spend less or earn more — and almost everybody only ever thinks '
            'of the first one.',
        money: -40,
        happiness: 7,
        smarts: 8,
        teaches: FinanceConcept.incomeVsWealth,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_friend_has_one',
    prompt:
        'Everyone in your class has the new thing. You are the one who does '
        'not.',
    icon: Icons.groups_rounded,
    minAge: 7,
    maxAge: 15,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Ask for it, urgently',
        outcome:
            'You get it, or you do not, and either way the class has moved on '
            'to something else by the spring. Almost nothing that feels this '
            'urgent at nine is still urgent at ten.',
        happiness: 3,
        smarts: 3,
      ),
      LifeChoice(
        label: 'Wait and see if you still want it in a month',
        outcome:
            'You did not. A month is the cheapest test there is, and it works '
            'just as well on a \$900 phone at twenty-five as it does on this.',
        happiness: 1,
        smarts: 8,
        teaches: FinanceConcept.impulseSpending,
      ),
      LifeChoice(
        label: 'Save for it yourself',
        outcome:
            'It takes ages and it is yours. Something you bought with your own '
            'money is treated differently — that is not a moral, it is just '
            'what everybody does.',
        money: -25,
        happiness: 6,
        smarts: 7,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),

  // --- Earning --------------------------------------------------------
  LifeEvent(
    id: 'c_chores_deal',
    prompt:
        'You are offered \$5 a week for doing the dishes every night. Every '
        'night.',
    icon: Icons.cleaning_services_rounded,
    minAge: 7,
    maxAge: 14,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Take it',
        outcome:
            'Seven nights for \$5 is about 70c a night. Low, and it is the '
            'first wage you ever negotiated, which makes it worth more than '
            'the money.',
        money: 20,
        happiness: -2,
        smarts: 6,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Ask for \$8',
        outcome:
            'You settle at \$6.50. Asking cost you nothing and got you 30% — '
            'the single highest-return thing most people never do.',
        money: 26,
        happiness: -2,
        smarts: 9,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Say no — your evenings are worth more',
        outcome:
            'A completely valid answer, and the reasoning is the point: you '
            'worked out what your time was worth and this was under it. Most '
            'adults never do that sum either.',
        smarts: 7,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_lemonade_stand',
    prompt:
        'You and a friend want to run a stall. Cups, lemons and sugar come to '
        '\$9.',
    icon: Icons.local_drink_rounded,
    minAge: 7,
    maxAge: 14,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Charge 50c and sell 30 cups',
        outcome:
            '\$15 in, \$9 out, \$6 between two of you. You just met the only '
            'sum in business that matters: what came in minus what it cost, '
            'not what came in.',
        money: 3,
        happiness: 6,
        smarts: 8,
        teaches: FinanceConcept.incomeVsWealth,
      ),
      LifeChoice(
        label: 'Charge \$2 and sell 6 cups',
        outcome:
            '\$12 in against \$9, so \$3 — less money and far less work. Two '
            'completely different prices can land close together, which is why '
            'guessing at one is expensive.',
        money: 1,
        happiness: 4,
        smarts: 8,
      ),
      LifeChoice(
        label: 'Give it away free',
        outcome:
            'You are \$9 down and the street likes you. Sometimes that is '
            'exactly the trade you wanted — it just helps to know you made it '
            'on purpose.',
        money: -9,
        happiness: 9,
        smarts: 5,
        addTrait: LifeTrait.generous,
      ),
    ],
  ),

  // --- Losing it ------------------------------------------------------
  LifeEvent(
    id: 'c_lost_the_money',
    prompt: 'The \$10 you were saving is not in your coat pocket any more.',
    icon: Icons.search_off_rounded,
    minAge: 6,
    maxAge: 14,
    weight: 0.9,
    choices: [
      LifeChoice(
        label: 'Turn the house upside down',
        outcome:
            'Not found. It is a rotten feeling and it is also the reason '
            'people keep money somewhere that is not a coat pocket.',
        money: -10,
        happiness: -5,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Start keeping it in one place from now on',
        outcome:
            'The tin, the jar, the account — it does not matter which, only '
            'that there is exactly one of them. Money you cannot find is money '
            'you do not have.',
        money: -10,
        happiness: -3,
        smarts: 8,
        teaches: FinanceConcept.payYourselfFirst,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_broke_a_window',
    prompt:
        'The ball went through next door\'s window. Replacing it is \$60 and '
        'you have \$14.',
    icon: Icons.report_problem_rounded,
    minAge: 8,
    maxAge: 15,
    weight: 0.8,
    choices: [
      LifeChoice(
        label: 'Own up and offer what you have',
        outcome:
            'The rest gets covered and you pay yours back over a term. Owning '
            'a cost you cannot afford yet is the hardest version of this and '
            'the one that goes best.',
        money: -14,
        happiness: -3,
        smarts: 9,
        teaches: FinanceConcept.interestCost,
      ),
      LifeChoice(
        label: 'Say nothing',
        outcome:
            'It comes out anyway, and the window still costs \$60. The bill '
            'did not get smaller while you were hoping — that is the part '
            'worth remembering.',
        happiness: -6,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Ask to work it off',
        outcome:
            'Eight weekends of jobs. Long, fair, and the first time you have '
            'converted a debt into hours — which is what every debt is, '
            'underneath.',
        happiness: -4,
        smarts: 8,
        teaches: FinanceConcept.interestCost,
      ),
    ],
  ),

  // --- Money between friends ------------------------------------------
  LifeEvent(
    id: 'c_lend_a_friend',
    prompt: 'A friend asks to borrow \$5 until next week.',
    icon: Icons.handshake_rounded,
    minAge: 7,
    maxAge: 15,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Lend it',
        outcome:
            'You get it back, or you do not, and either way you have learned '
            'the rule: only lend a friend an amount you would have been happy '
            'to give them.',
        money: -5,
        happiness: 2,
        smarts: 7,
        addTrait: LifeTrait.generous,
      ),
      LifeChoice(
        label: 'Give it instead of lending it',
        outcome:
            'Same \$5, no week of wondering, no awkward reminder. Half the '
            'time this is what a small loan between friends turns into '
            'anyway — you just did it on purpose.',
        money: -5,
        happiness: 5,
        smarts: 8,
        addTrait: LifeTrait.generous,
      ),
      LifeChoice(
        label: 'Say no',
        outcome:
            'Allowed. "No" is a complete sentence about money and it is a lot '
            'easier at eight than the first time you have to say it at '
            'twenty-eight.',
        smarts: 6,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_swap_cards',
    prompt:
        'Someone offers you three of their cards for your one rare one. Three '
        'is more than one.',
    icon: Icons.style_rounded,
    minAge: 6,
    maxAge: 13,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Do the swap — three beats one',
        outcome:
            'By the next week you have worked out that the rare one was worth '
            'more than the three together. Counting things is not the same as '
            'valuing them.',
        happiness: -2,
        smarts: 7,
        teaches: FinanceConcept.needsVsWants,
      ),
      LifeChoice(
        label: 'Ask around what the rare one usually goes for',
        outcome:
            'Two minutes of asking and you know the answer. Finding the going '
            'rate before you trade is the whole of what a market is.',
        happiness: 3,
        smarts: 9,
        teaches: FinanceConcept.diversification,
      ),
      LifeChoice(
        label: 'Keep it — you like it',
        outcome:
            'Also a real reason. Something can be worth keeping because you '
            'want it rather than because of the number, as long as you are not '
            'pretending the number is the reason.',
        happiness: 4,
        smarts: 5,
      ),
    ],
  ),

  // --- Seeing how it works --------------------------------------------
  LifeEvent(
    id: 'c_school_trip',
    prompt:
        'A school trip costs \$25. The letter says money is available for '
        'anyone who needs it.',
    icon: Icons.directions_bus_rounded,
    minAge: 8,
    maxAge: 15,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Go, and pay the \$25',
        outcome:
            'Worth it. Some spending buys a day you still remember at thirty, '
            'and treating every cost as a loss is its own kind of mistake.',
        money: -25,
        happiness: 8,
        smarts: 4,
      ),
      LifeChoice(
        label: 'Ask about the help quietly',
        outcome:
            'You go, and nobody in the class knows which is which. Asking for '
            'help you are entitled to is not a smaller version of paying — it '
            'is the thing the fund exists for.',
        happiness: 7,
        smarts: 8,
      ),
      LifeChoice(
        label: 'Skip it',
        outcome:
            'You keep the \$25 and hear about the trip for a fortnight. Saving '
            'has a cost too, and it is worth being honest about what it was.',
        happiness: -3,
        smarts: 5,
        teaches: FinanceConcept.opportunityCost,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_charity_drive',
    prompt:
        'The school is collecting for a food bank. You have \$4 on you and '
        'plans for it.',
    icon: Icons.favorite_rounded,
    minAge: 6,
    maxAge: 15,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Give the lot',
        outcome:
            'Generous, and the thing to notice is that you felt it — giving '
            'that costs nothing is a nice gesture, and giving that costs '
            'something is the other kind.',
        money: -4,
        happiness: 6,
        smarts: 5,
        addTrait: LifeTrait.generous,
      ),
      LifeChoice(
        label: 'Give \$1',
        outcome:
            'A dollar you can repeat every week beats four you can only do '
            'once. That is true of giving and of saving, for exactly the same '
            'reason.',
        money: -1,
        happiness: 4,
        smarts: 8,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Keep it this time',
        outcome:
            'Also fine, and nobody needs to justify it. Giving is part of a '
            'budget like everything else, which means sometimes the answer is '
            'not this week.',
        smarts: 4,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_card_at_the_shop',
    prompt:
        'A grown-up taps a card and walks out with the shopping. No money '
        'changed hands at all.',
    icon: Icons.credit_card_rounded,
    minAge: 5,
    maxAge: 11,
    weight: 1.1,
    choices: [
      LifeChoice(
        label: 'Decide the card must be free money',
        outcome:
            'Everyone thinks this at six, and a surprising number of people '
            'still half-believe it at twenty-six. The card is a message, not '
            'a source.',
        smarts: 3,
      ),
      LifeChoice(
        label: 'Ask where the money actually goes',
        outcome:
            'It comes out of an account somebody filled up by working. A card '
            'moves money that already exists — knowing that early is most of '
            'what keeps people out of trouble later.',
        smarts: 9,
        teaches: FinanceConcept.creditScore,
      ),
      LifeChoice(
        label: 'Ask to see the receipt',
        outcome:
            'Twelve things, a total, and a running number at the bottom. The '
            'receipt is the first budget most people ever look at.',
        smarts: 8,
        teaches: FinanceConcept.budgetRule,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_birthday_money',
    prompt: 'Birthday cards. \$50 in total, and it is entirely yours.',
    icon: Icons.cake_rounded,
    minAge: 6,
    maxAge: 15,
    weight: 1.2,
    choices: [
      LifeChoice(
        label: 'Spend the lot this weekend',
        outcome:
            'A very good weekend. By Wednesday it is gone and you can name two '
            'of the things — which is worth knowing about yourself rather than '
            'feeling bad about.',
        money: -50,
        happiness: 8,
        smarts: 3,
        teaches: FinanceConcept.impulseSpending,
      ),
      LifeChoice(
        label: 'Put half away and spend half',
        outcome:
            'Twenty-five for now, twenty-five in the jar. Nobody has ever '
            'regretted this split, which is roughly why it is the one grown '
            'people are still using.',
        money: -25,
        happiness: 6,
        smarts: 8,
        teaches: FinanceConcept.budgetRule,
      ),
      LifeChoice(
        label: 'Save it all towards something bigger',
        outcome:
            'Hard at eleven, and the \$50 becomes the start of something worth '
            'far more than \$50 of sweets. Just make sure the bigger thing is '
            'real, or the money sits there being nothing.',
        happiness: 2,
        smarts: 9,
        teaches: FinanceConcept.payYourselfFirst,
      ),
    ],
  ),
  LifeEvent(
    id: 'c_bank_account_opened',
    prompt:
        'Someone takes you to open your first account. There is a card with '
        'your name printed on it.',
    icon: Icons.account_balance_rounded,
    minAge: 9,
    maxAge: 16,
    weight: 1.0,
    choices: [
      LifeChoice(
        label: 'Put everything in',
        outcome:
            'Safer than the tin and it earns a little. The trade is that it is '
            'no longer three seconds away, which is a feature about as often '
            'as it is a problem.',
        happiness: 3,
        smarts: 7,
        teaches: FinanceConcept.compoundGrowth,
      ),
      LifeChoice(
        label: 'Ask what interest means',
        outcome:
            'The bank pays you a little for leaving it there. Small enough to '
            'ignore at \$40 and the entire reason saving works at \$40,000 — '
            'same rule, different zeroes.',
        smarts: 10,
        teaches: FinanceConcept.compoundGrowth,
      ),
      LifeChoice(
        label: 'Keep some in cash where you can see it',
        outcome:
            'Sensible. Money you can see gets spent more carefully than money '
            'you cannot, and at this age seeing it is most of the point.',
        happiness: 2,
        smarts: 6,
      ),
    ],
  ),
];
