import 'town_age_bands.dart';
import 'town_spot_models.dart';

/// Extra encounters for the Adventure town's six buildings.
///
/// **The problem this solves.** The town is a fixed map with six fixed spots,
/// and each spot had exactly one prompt and one set of choices. So the second
/// visit to the Corner Store was the first visit again, word for word, and by
/// the third the town had nothing left to say — the map was fine, the
/// *content* was one deep.
///
/// Building more map is the expensive answer. This is the cheap one that
/// actually addresses the complaint: each spot now has several encounters and
/// the town picks a different set each day. Six buildings with one scene each
/// is six things to do; six buildings with five scenes each is thirty, from
/// data alone, on the same art.
///
/// **Why by day rather than at random.** A scene that rerolls every time you
/// walk in is a slot machine, and it destroys the one thing that makes the
/// walk meaningful — that you went there to do a specific thing. Fixed for
/// the day means the town has a *state* you can plan around, and tomorrow it
/// has a different one.
///
/// Every scenario follows the same rule as the originals: no choice is purely
/// wrong, and every outcome line explains the money idea rather than scoring
/// it. Walking there is the game; the decision is the lesson.

/// One self-contained encounter at a spot.
class TownScenario {
  const TownScenario({
    required this.id,
    required this.prompt,
    required this.choices,
  });

  final String id;
  final String prompt;
  final List<TownChoice> choices;
}

/// Extra scenarios per spot id. The spot's own prompt/choices remain scenario
/// zero, so this file only carries what is new.
const Map<String, List<TownScenario>>
kTownScenarios = <String, List<TownScenario>>{
  // ---------------------------------------------------------------
  'spot_store': [
    TownScenario(
      id: 'store_till_snack',
      prompt:
          'The queue at the till runs past a rack of chocolate. \$1.80, '
          'and you are already holding what you came for.',
      choices: [
        TownChoice(
          label: 'Add it to the basket',
          outcome:
              'That rack is there because it works — the till queue is the '
              'one place in the shop where you are standing still with '
              'nothing to do. Twice a week is \$187 a year.',
          gold: -2,
          xp: 5,
          literacy: 6,
        ),
        TownChoice(
          label: 'Put it back',
          outcome:
              'The whole trick of an impulse buy is that it is decided in '
              'the four seconds before you pay. Deciding before you get in '
              'the queue is the counter to it.',
          xp: 9,
          literacy: 9,
        ),
        TownChoice(
          label: 'Buy it, but skip tomorrow',
          outcome:
              'A real budget has room for treats. What it does not have is '
              'room for treats that were never counted — you just counted '
              'this one, which is the difference.',
          gold: -2,
          xp: 8,
          literacy: 8,
        ),
      ],
    ),
    TownScenario(
      id: 'store_own_brand',
      prompt:
          'Same cereal, two boxes. The name you know is \$4.50; the '
          'shop own-label beside it is \$2.20.',
      choices: [
        TownChoice(
          label: 'Take the brand you know',
          outcome:
              'Sometimes worth it — a brand you trust saves you the risk of '
              'wasting \$2.20 on something nobody eats. Just know you paid '
              '\$2.30 for the certainty.',
          gold: -5,
          xp: 5,
          literacy: 6,
        ),
        TownChoice(
          label: 'Try the own label once',
          outcome:
              'One box is a cheap experiment. If it is fine you save \$2.30 '
              'every time from now on; if it is not, you are out \$2.20 and '
              'you know.',
          gold: -2,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Read both lists and buy neither today',
          outcome:
              'Often the same factory and nearly the same list — the gap you '
              'would pay for is frequently the box. You have enough at home '
              'this week, so knowing costs you nothing.',
          xp: 9,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'store_reduced_shelf',
      prompt:
          'The reduced shelf has bread at half price, going out of date '
          'tomorrow. You have plenty of bread at home.',
      choices: [
        TownChoice(
          label: 'Buy two — half price is half price',
          outcome:
              'Half price on food you will not eat is not a saving, it is a '
              'cheaper way to throw money away. The discount only counts if '
              'you would have bought it anyway.',
          gold: -3,
          xp: 5,
          literacy: 7,
        ),
        TownChoice(
          label: 'Walk past',
          outcome:
              'Right call today. The reduced shelf is genuinely good value '
              'for something you were already going to buy — and a trap for '
              'everything else.',
          xp: 9,
          literacy: 9,
        ),
        TownChoice(
          label: 'Buy one and freeze it',
          outcome:
              'This is the version that works: the date only matters if the '
              'food has to be eaten by then. A freezer turns a deadline into '
              'a real saving.',
          gold: -2,
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'store_sale',
      prompt:
          'A sign says BUY 2 GET 1 FREE on drinks — \$3 each. You came '
          'in for one.',
      choices: [
        TownChoice(
          label: 'Buy three for \$6',
          outcome:
              'You spent \$6 to save \$3 on something you did not come '
              'for. A deal that makes you buy more is a deal for the '
              'shop.',
          gold: -6,
          xp: 5,
        ),
        TownChoice(
          label: 'Buy the one you came for',
          outcome:
              'You spent \$3 and got exactly what you wanted. Skipping a '
              'discount is allowed — the saving is only real if you '
              'wanted the extra.',
          gold: -3,
          xp: 6,
          literacy: 7,
        ),
        TownChoice(
          label: 'Check the price per litre first',
          outcome:
              'The big bottle is cheaper per litre than three smalls, '
              'even without the offer. Unit price beats the sign on the '
              'shelf almost every time.',
          gold: -4,
          xp: 8,
          literacy: 9,
        ),
        TownChoice(
          label: 'Drink the water you brought',
          outcome:
              'Nothing spent. Every scene in this town has a way out that '
              'costs nothing — if a shop has arranged things so it feels '
              'like there is not one, that is the arrangement talking.',
          xp: 7,
          literacy: 8,
        ),
      ],
    ),
    TownScenario(
      id: 'store_impulse',
      prompt:
          'By the till: sweets, a phone charger, and a magazine. You '
          'have \$5 left and nothing on your list.',
      choices: [
        TownChoice(
          label: 'Grab the sweets',
          outcome:
              'The till aisle exists for exactly that. Everything within '
              'arm\'s reach of a queue was put there because waiting '
              'makes people buy.',
          gold: -3,
          xp: 3,
        ),
        TownChoice(
          label: 'Buy the charger — you keep losing yours',
          outcome:
              'Not an impulse buy if it replaces something you actually '
              'need. The test is whether you would have driven here for '
              'it.',
          gold: -5,
          xp: 6,
          literacy: 6,
        ),
        TownChoice(
          label: 'Keep the \$5',
          outcome:
              'The cheapest thing in every shop is the door. Your \$5 is '
              'still \$5.',
          xp: 7,
          literacy: 8,
        ),
      ],
    ),
    TownScenario(
      id: 'store_subscription',
      prompt:
          'The shop offers a \$4/month membership: 10% off everything. '
          'You spend about \$15 here a month.',
      choices: [
        TownChoice(
          label: 'Join — 10% off sounds good',
          outcome:
              '10% of \$15 is \$1.50 a month. The membership costs \$4. '
              'You are paying \$2.50 a month for the privilege.',
          gold: -4,
          xp: 5,
        ),
        TownChoice(
          label: 'Work out the break-even first',
          outcome:
              'You would need to spend \$40 a month here for the '
              'membership to pay for itself. It does not, so you skip '
              'it. That sum works on every subscription.',
          xp: 9,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask if there is a free loyalty card',
          outcome:
              'There is. Points, no monthly fee. Always ask what the free '
              'version of the paid thing is.',
          xp: 7,
          literacy: 8,
        ),
      ],
    ),
  ],

  // ---------------------------------------------------------------
  'spot_bank': [
    TownScenario(
      id: 'bank_overdraft_fee',
      prompt:
          'Your balance went \$12 below zero for two days. The statement '
          'shows a \$35 overdraft fee.',
      choices: [
        TownChoice(
          label: 'Pay it and move on',
          outcome:
              'You borrowed \$12 for two days and paid \$35 for it. As an '
              'interest rate that is astronomical, which is why an overdraft '
              'is the most expensive money most people ever borrow.',
          gold: -35,
          xp: 5,
          literacy: 7,
        ),
        TownChoice(
          label: 'Ask the bank to refund it',
          outcome:
              'They often will, once, if you ask politely and it is your '
              'first. Fees are frequently a policy rather than a law — it '
              'costs one phone call to find out.',
          gold: -10,
          xp: 9,
          literacy: 9,
        ),
        TownChoice(
          label: 'Turn off overdraft cover instead',
          outcome:
              'Then the payment is declined rather than fee-charged. A '
              'declined card is embarrassing for a minute; \$35 is '
              'embarrassing for a week.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'bank_auto_save',
      prompt:
          'The clerk offers to set up an automatic transfer to savings the '
          'day after your money arrives.',
      choices: [
        TownChoice(
          label: 'Set it for \$10 a week',
          outcome:
              'This is pay-yourself-first, and it works because it happens '
              'before you see the money. \$10 a week is \$520 a year with no '
              'willpower involved.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Set it for \$60 a week',
          outcome:
              'Ambitious, and the usual outcome is that you move it back the '
              'first tight month and stop trusting the system. A transfer you '
              'never cancel beats a bigger one you do.',
          xp: 7,
          literacy: 8,
        ),
        TownChoice(
          label: 'Save whatever is left at month end',
          outcome:
              'Almost nothing is ever left — spending expands to fill the '
              'account. Saving last is the plan that fails quietly, which is '
              'why the order matters more than the amount.',
          xp: 5,
          literacy: 7,
        ),
      ],
    ),
    TownScenario(
      id: 'bank_atm_fee',
      prompt:
          'The cash machine outside warns of a \$3.50 charge. Your own '
          'bank machine is a six-minute walk away.',
      choices: [
        TownChoice(
          label: 'Pay the \$3.50 — you are in a hurry',
          outcome:
              'Sometimes six minutes really is worth \$3.50. The trap is '
              'doing it weekly without noticing: that is \$182 a year for '
              'standing in a slightly closer spot.',
          gold: -4,
          xp: 5,
          literacy: 7,
        ),
        TownChoice(
          label: 'Walk to your own bank',
          outcome:
              'Six minutes for \$3.50 is \$35 an hour, tax free. Framed that '
              'way most people walk.',
          xp: 9,
          literacy: 9,
        ),
        TownChoice(
          label: 'Get cashback at the shop instead',
          outcome:
              'Free at the till in most shops, and it was the option nobody '
              'advertised. The cheapest route is often the one with no sign '
              'pointing at it.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'bank_interest',
      prompt:
          'The teller explains two accounts: one pays 0.1% a year, the '
          'other 4% but you must leave the money for a year.',
      choices: [
        TownChoice(
          label: 'Take the 4% — more is better',
          outcome:
              'More interest, less access. Fine for money you will not '
              'need; painful if the car breaks next month.',
          xp: 6,
          literacy: 6,
        ),
        TownChoice(
          label: 'Ask what happens if you need it early',
          outcome:
              'There is a penalty that wipes out several months of '
              'interest. Now you can actually compare the two — that '
              'question is the whole decision.',
          xp: 9,
          literacy: 10,
        ),
        TownChoice(
          label: 'Split it between both',
          outcome:
              'Some earning, some reachable. Splitting is what people do '
              'when they genuinely do not know which they will need.',
          xp: 8,
          literacy: 9,
        ),
      ],
    ),
    TownScenario(
      id: 'bank_overdraft',
      prompt:
          'A form asks whether you want overdraft coverage — payments go '
          'through even when your balance is short.',
      choices: [
        TownChoice(
          label: 'Say yes, so nothing gets declined',
          outcome:
              'A declined card is embarrassing for a second. An overdraft '
              'fee is often about \$35 — sometimes more than the thing '
              'you bought.',
          gold: -35,
          xp: 5,
          literacy: 6,
        ),
        TownChoice(
          label: 'Say no',
          outcome:
              'The payment is declined instead of charged. You have to '
              'opt in to debit-card overdraft in the US, and you can opt '
              'back out at any time.',
          xp: 8,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask about a low-balance alert instead',
          outcome:
              'Free, and it solves the actual problem — not knowing the '
              'balance was low — rather than charging you for it.',
          xp: 9,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'bank_insurance',
      prompt:
          'A poster reads: "Deposits insured up to \$250,000." Someone '
          'in the queue asks what that actually means.',
      choices: [
        TownChoice(
          label: 'It means the bank promises to be careful',
          outcome:
              'Not quite. It means a US government agency — the FDIC — '
              'repays your deposits if the bank itself fails.',
          xp: 4,
        ),
        TownChoice(
          label: 'It means your money is safe even if the bank fails',
          outcome:
              'Exactly. Up to \$250,000 per depositor, per bank, per '
              'ownership category. It is the reason a bank beats a '
              'drawer.',
          xp: 9,
          literacy: 10,
        ),
        TownChoice(
          label: 'It only covers savings, not checking',
          outcome:
              'Both are covered. So are money market deposit accounts '
              'and CDs — investments held at the bank are not.',
          xp: 5,
          literacy: 6,
        ),
      ],
    ),
    TownScenario(
      id: 'bank_car_loan',
      prompt:
          'Two loans for the same \$6,000 car at 6%: three years, or six '
          'years with lower payments.',
      choices: [
        TownChoice(
          label: 'Take the three years',
          outcome:
              'The payments are higher and you pay about \$570 in interest. '
              'Paying a loan off sooner costs less overall, though it costs '
              'more each month.',
          xp: 10,
          literacy: 12,
        ),
        TownChoice(
          label: 'Take the six years',
          outcome:
              'Easier each month, and about \$1,150 in interest. The car is '
              'worth much less by the time it is paid off.',
          xp: 8,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask for the total cost of each',
          outcome:
              'The number to compare is what you pay in the end and not what '
              'you pay a month. Lenders show the monthly figure because it '
              'looks small.',
          xp: 14,
          literacy: 14,
        ),
      ],
    ),
    TownScenario(
      id: 'bank_mortgage_rate',
      prompt:
          'A mortgage rate can be fixed at 5%, or start at 4% and move with '
          'the market.',
      choices: [
        TownChoice(
          label: 'Fix it at 5%',
          outcome:
              'You know what you will pay every month for years. Certainty has '
              'a price, and you pay it in a rate that is a little higher today.',
          xp: 10,
          literacy: 12,
        ),
        TownChoice(
          label: 'Take the 4% that moves',
          outcome:
              'Cheaper to start, and it could be much dearer in two years. It '
              'is a bet on which way rates go, and nobody knows.',
          xp: 8,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask what the rate could rise to',
          outcome:
              'The worst case is the number to plan around. If you could not '
              'pay it, the cheap start is not really cheap.',
          xp: 14,
          literacy: 14,
        ),
      ],
    ),
  ],

  // ---------------------------------------------------------------
  'spot_school': [
    TownScenario(
      id: 'school_lunch_plan',
      prompt:
          'You get \$25 for lunches this week. The canteen meal is \$6 and '
          'a packed lunch costs about \$2.',
      choices: [
        TownChoice(
          label: 'Buy lunch every day',
          outcome:
              'Five canteen meals is \$30 out of \$25 — you run out on '
              'Friday. Not a disaster, but it was arithmetic you could have '
              'done on Monday.',
          gold: -25,
          xp: 5,
          literacy: 7,
        ),
        TownChoice(
          label: 'Pack lunch, buy on Friday',
          outcome:
              'Four packed at \$2 plus one canteen day is \$14, leaving '
              '\$11. A budget that keeps one thing you look forward to is a '
              'budget you will still be following in March.',
          gold: -14,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Pack from the cupboard and keep the \$25',
          outcome:
              'The food is already bought, so the whole \$25 survives the '
              'week. It works, and the thing to watch is whether you stick '
              'to it — the strictest plan is not always the one that lasts.',
          xp: 9,
          literacy: 9,
        ),
      ],
    ),
    TownScenario(
      id: 'school_bake_sale',
      prompt:
          'The class bake sale needs a price. Ingredients cost \$18 and you '
          'have 40 cupcakes.',
      choices: [
        TownChoice(
          label: 'Charge 50c each',
          outcome:
              'Forty at 50c is \$20 against \$18 of ingredients — you raise '
              '\$2 for a day of work. Cheap is not the same as generous when '
              'the point was to raise money.',
          gold: 2,
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'Charge \$1.50 each',
          outcome:
              'Sell them all and you clear \$42. Price has to cover the cost '
              'first and the profit second — that order is the whole of '
              'running anything.',
          gold: 42,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Charge \$3 and expect to sell half',
          outcome:
              'Twenty at \$3 is \$60 minus \$18, so \$42 as well — and you '
              'still have twenty cupcakes. Two very different plans can land '
              'on the same number.',
          gold: 42,
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'school_group_gift',
      prompt:
          'Six of you are buying a \$54 leaving present for a teacher. Two '
          'people say they are short this week.',
      choices: [
        TownChoice(
          label: 'Split it six ways anyway',
          outcome:
              '\$9 each, and two people quietly go without something else. '
              'An even split is only fair when everyone is in the same '
              'position, which is rarely checked.',
          gold: -9,
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'Cover their share yourself',
          outcome:
              'You pay \$27 instead of \$9. Generous, and worth being honest '
              'about: lending inside a friendship group usually turns into '
              'giving, so decide to give on purpose.',
          gold: -27,
          xp: 8,
          literacy: 9,
        ),
        TownChoice(
          label: 'Find a \$30 present instead',
          outcome:
              '\$5 each and nobody is squeezed. Changing the size of the '
              'problem is a move people forget they have — the present was '
              'never the fixed part.',
          gold: -5,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Make something between the six of you',
          outcome:
              'Costs nothing but time, and it sidesteps the real problem: '
              'two people were about to be pushed into spending they could '
              'not afford so that nobody had to say so out loud.',
          xp: 9,
          literacy: 9,
        ),
      ],
    ),
    TownScenario(
      id: 'school_percent',
      prompt:
          'A worksheet on the desk: "A \$50 jacket is 20% off, then 10% '
          'off at the till. What do you pay?"',
      choices: [
        TownChoice(
          label: '\$35 — that is 30% off',
          outcome:
              'A common trap. The second discount comes off the reduced '
              'price, not the original, so the two do not simply add.',
          xp: 5,
        ),
        TownChoice(
          label: '\$36',
          outcome:
              'Right. \$50 less 20% is \$40; \$40 less 10% is \$36. '
              'Stacked percentages always come off a smaller number each '
              'time.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask to see the till receipt to check',
          outcome:
              'Also right, and the more useful habit — checking beats '
              'assuming the sign was honest.',
          xp: 8,
          literacy: 8,
        ),
      ],
    ),
    TownScenario(
      id: 'school_average',
      prompt:
          'A careers poster claims "average starting pay: \$92,000". '
          'Nine of the ten graduates listed earn about \$40,000.',
      choices: [
        TownChoice(
          label: 'Believe the poster',
          outcome:
              'One very high earner can drag an average anywhere. The '
              'number is true and still misleading.',
          xp: 3,
        ),
        TownChoice(
          label: 'Ask for the median instead',
          outcome:
              'The median is the middle person — about \$40,000 here. '
              'For anything about people and money, the median is the '
              'honest number.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask how many graduates replied',
          outcome:
              'Also sharp. A survey only the successful answered says '
              'more about who replied than about the job.',
          xp: 9,
          literacy: 9,
        ),
      ],
    ),
    TownScenario(
      id: 'school_open_day',
      prompt:
          'A careers evening. One stall is for a trade that pays while you '
          'learn. One is for a degree with three years of fees.',
      choices: [
        TownChoice(
          label: 'Talk to the trade stall',
          outcome:
              'Earning while you learn means starting with no debt. Trades also '
              'pay well because fewer people do them.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Talk to the degree stall',
          outcome:
              'Some jobs really do need one. Ask what people earn after it and '
              'what they owe, so the cost is a number and not a feeling.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask both what they earn after five years',
          outcome:
              'The best question at any stall. A course is an investment, and '
              'the return is what you earn after it, less what it cost.',
          xp: 14,
          literacy: 14,
        ),
      ],
    ),
    TownScenario(
      id: 'school_second_hand_books',
      prompt:
          'The textbook is \$60 new, \$25 second-hand, or free from the '
          'library for the term.',
      choices: [
        TownChoice(
          label: 'Buy it new (\$60)',
          outcome:
              'You have it forever and it is yours to mark. Most books are used '
              'for one term and never opened again, so that is paying for a '
              'shelf.',
          gold: -20,
          xp: 4,
          literacy: 6,
        ),
        TownChoice(
          label: 'Buy it second-hand (\$25)',
          outcome:
              'Same words for less than half. Somebody else paid for the '
              'newness, and you paid for the book.',
          gold: -10,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Borrow it from the library',
          outcome:
              'Free. The trade is that somebody else may have it when you want '
              'it, and that is a small cost to plan around.',
          xp: 12,
          literacy: 12,
        ),
      ],
    ),
  ],

  // ---------------------------------------------------------------
  'spot_job': [
    TownScenario(
      id: 'job_first_payslip',
      prompt:
          'Your first payslip. You worked 20 hours at \$12, so you expected '
          '\$240 — the bank got \$203.',
      choices: [
        TownChoice(
          label: 'Assume you were underpaid',
          outcome:
              'Worth checking, but the usual answer is tax and other '
              'deductions. Gross is what you earned; net is what arrives, '
              'and the payslip lists every step between them.',
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'Read every line on the slip',
          outcome:
              'Income tax, national insurance, maybe a pension '
              'contribution. Nobody teaches you to read this and it is the '
              'one document that explains where your money actually goes.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Budget from \$203, not \$240',
          outcome:
              'The right habit for the rest of your life. Planning off gross '
              'pay is how people end a month 15% short and cannot say why.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'job_tips_week',
      prompt:
          'The cafe pays \$9 an hour plus tips. Last week tips were \$80; '
          'this week they were \$18.',
      choices: [
        TownChoice(
          label: 'Budget on a good week',
          outcome:
              'Planning off \$80 means most weeks come up short. Variable '
              'income has to be budgeted from the low end, with the good '
              'weeks treated as extra rather than as normal.',
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'Budget on the base wage only',
          outcome:
              'Safe, and it turns every tip into savings rather than into '
              'rent. This is how people with irregular income stay steady.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Average the last eight weeks',
          outcome:
              'The middle answer, and a good one once you have eight weeks '
              'to average. Two data points is not a pattern — that is the '
              'part people get wrong.',
          xp: 9,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'job_ask_for_more',
      prompt:
          'You have worked here a year with no rise. The new starter is on '
          'the same rate as you.',
      choices: [
        TownChoice(
          label: 'Say nothing and hope it is noticed',
          outcome:
              'Rises are usually asked for rather than offered. Waiting is a '
              'strategy, it is just one with a very low success rate.',
          xp: 5,
          literacy: 7,
        ),
        TownChoice(
          label: 'Ask, with a list of what you do now',
          outcome:
              'The ask that works is evidence, not feeling: what you handle '
              'that you did not a year ago. Worst case they say no and you '
              'know where you stand.',
          gold: 30,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Find out what the job pays elsewhere first',
          outcome:
              'Knowing the market rate turns a request into a fact. It also '
              'tells you whether the answer to a no is to stay or to look.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'job_two_offers',
      prompt:
          'Two weekend jobs. One pays \$14/hour with no travel. The '
          'other pays \$16/hour but costs \$6 a day to get to.',
      choices: [
        TownChoice(
          label: 'Take the \$16 job — higher rate',
          outcome:
              'On a 5-hour shift that is \$80 less \$6 travel, so \$74. '
              'The \$14 job pays \$70. Closer than the headline, and it '
              'flips on a short shift.',
          gold: 74,
          xp: 7,
          literacy: 8,
        ),
        TownChoice(
          label: 'Work out the take-home per shift first',
          outcome:
              'The right move: compare what reaches your pocket, not the '
              'advertised rate. Travel, hours and unpaid breaks all come '
              'off the top.',
          gold: 74,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Take the \$14 job for the shorter day',
          outcome:
              '\$70 and two hours of your life back. Time has a value '
              'too — the trick is to price it deliberately rather than '
              'ignore it.',
          gold: 70,
          xp: 8,
          literacy: 7,
        ),
      ],
    ),
    TownScenario(
      id: 'job_paystub',
      prompt:
          'Your first pay stub says GROSS \$320, NET \$268. The board '
          'clerk asks if you know where the rest went.',
      choices: [
        TownChoice(
          label: 'The employer kept it',
          outcome:
              'No — it was withheld for tax. Federal income tax, Social '
              'Security at 6.2%, Medicare at 1.45%, usually state tax '
              'too.',
          gold: 268,
          xp: 4,
        ),
        TownChoice(
          label: 'Tax and payroll deductions',
          outcome:
              'Right. Withholding is an estimate of your annual tax bill, '
              'taken a paycheck at a time. Filing a return settles up.',
          gold: 268,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Check the hours and rate on the stub',
          outcome:
              'Worth doing every first stub — payroll makes mistakes, and '
              'one caught in month one is a conversation rather than a '
              'repayment.',
          gold: 268,
          xp: 9,
          literacy: 9,
        ),
      ],
    ),
    TownScenario(
      id: 'job_promotion_case',
      prompt:
          'Your manager mentions a promotion is coming. You could ask for '
          'the pay that goes with it.',
      choices: [
        TownChoice(
          label: 'Ask, with a list of what you have done',
          outcome:
              'Asking with evidence is the strongest way to ask. It gives them '
              'something to say yes to, and it costs an hour to write.',
          gold: 20,
          xp: 12,
          literacy: 12,
        ),
        TownChoice(
          label: 'Accept the title and say nothing',
          outcome:
              'You got the title and the old pay. A promotion without a raise '
              'is more work for the same money, and it is easiest to raise '
              'before you say yes.',
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'Wait for them to raise it',
          outcome:
              'They might. Many people wait for years for a question that only '
              'they were going to ask.',
          xp: 4,
          literacy: 6,
        ),
      ],
    ),
  ],

  // ---------------------------------------------------------------
  'spot_home': [
    TownScenario(
      id: 'home_bill_spike',
      prompt:
          'The heating bill is \$140 this month against \$85 last month. '
          'Nothing obvious has changed.',
      choices: [
        TownChoice(
          label: 'Pay it and hope it settles',
          outcome:
              'It might. But a bill that doubles is either a colder month, a '
              'price rise or a fault, and all three are worth knowing about '
              'before the next one arrives.',
          gold: -14,
          xp: 5,
          literacy: 7,
        ),
        TownChoice(
          label: 'Compare it to the same month last year',
          outcome:
              'The only honest comparison for anything seasonal. January '
              'against December tells you about the weather; January against '
              'January tells you about your bill.',
          gold: -14,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Read the meter yourself before paying',
          outcome:
              'Free, and it settles it. A bill that jumped with no change in '
              'the house is very often an estimate rather than a reading — '
              'and an estimate you correct is money you get back.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'home_subscriptions',
      prompt:
          'Your statement shows six subscriptions. You can name four of '
          'them and you used two this month.',
      choices: [
        TownChoice(
          label: 'Cancel the ones you cannot name',
          outcome:
              'A subscription is designed to be forgotten — that is the '
              'business model. Twenty minutes on the statement usually pays '
              'better than any coupon.',
          gold: 18,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Keep them — they are only a few dollars',
          outcome:
              'Six at \$6 is \$432 a year. Small recurring costs are hard to '
              'feel and easy to add up, which is exactly why they are sold '
              'monthly rather than yearly.',
          gold: -6,
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'Set a reminder to review them every six months',
          outcome:
              'The version that keeps working. One cancellation session '
              'fixes today; a recurring review fixes the next three years.',
          gold: 12,
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'home_repair_or_replace',
      prompt:
          'The washing machine needs a \$120 repair. A new one is \$430 and '
          'this one is eight years old.',
      choices: [
        TownChoice(
          label: 'Repair it',
          outcome:
              'A quarter of the price for maybe two more years. That is a '
              'good trade if it holds — the risk is paying \$120 and then '
              '\$430 anyway six months later.',
          gold: -12,
          xp: 8,
          literacy: 9,
        ),
        TownChoice(
          label: 'Replace it',
          outcome:
              'More now, and the honest way to compare is cost per year: '
              '\$430 over ten years beats \$120 over two. The bigger number '
              'is not automatically the worse one.',
          gold: -43,
          xp: 9,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask the repairer what usually fails next',
          outcome:
              'The one question that turns a guess into a decision. Somebody '
              'who fixes these all week knows whether eight years is old for '
              'this machine.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'home_bills',
      prompt:
          'Three envelopes on the mat: electricity \$60, a birthday '
          'card, and a "final notice" for a \$12 subscription you forgot.',
      choices: [
        TownChoice(
          label: 'Pay the electricity, cancel the subscription',
          outcome:
              'Needs first, then plug the leak. A forgotten \$12 a month '
              'is \$144 a year for something you did not use.',
          gold: -60,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Pay both to be safe',
          outcome:
              'The bill is paid and so is another month of something you '
              'do not want. "Deal with it later" is how subscriptions '
              'survive.',
          gold: -72,
          xp: 5,
        ),
        TownChoice(
          label: 'Leave them for now',
          outcome:
              'The electricity bill does not go away, and late fees are '
              'the most avoidable money you will ever spend.',
          xp: 3,
          literacy: 4,
        ),
      ],
    ),
    TownScenario(
      id: 'home_jar',
      prompt:
          'Your savings jar has \$40. A friend is selling a bike for '
          '\$55, and you were saving for a \$120 console.',
      choices: [
        TownChoice(
          label: 'Buy the bike — it is a good price',
          outcome:
              'You cannot: you have \$40. Wanting something now does not '
              'create the other \$15, which is the whole reason people '
              'get into debt.',
          xp: 5,
        ),
        TownChoice(
          label: 'Keep saving for the console',
          outcome:
              'A goal you already chose beats a goal that turned up '
              'today. Every jar with a name on it wins more often than a '
              'jar labelled "saving".',
          xp: 9,
          literacy: 9,
        ),
        TownChoice(
          label: 'Change the goal to the bike, on purpose',
          outcome:
              'Also fine — as long as it is a decision, not a drift. '
              'Changing your mind deliberately is not the same as giving '
              'up on a plan.',
          xp: 8,
          literacy: 8,
        ),
      ],
    ),
    TownScenario(
      id: 'home_moving_day',
      prompt:
          'You are moving. A van is \$80. A friend with a car is free. '
          'Leaving before the lease ends costs a \$150 fee.',
      choices: [
        TownChoice(
          label: 'Ask the friend with the car',
          outcome:
              'Free, and it takes two trips. A favour is a price paid in time '
              'and thanks, and it is worth knowing you are paying it.',
          xp: 10,
          literacy: 8,
        ),
        TownChoice(
          label: 'Hire the van (\$80)',
          outcome:
              'Quick and done in a day. Paying to save time is a fair trade '
              'when the time is worth more than the fee.',
          gold: -10,
          xp: 8,
          literacy: 8,
        ),
        TownChoice(
          label: 'Wait until the lease ends',
          outcome:
              'You avoided the \$150 fee by waiting. Read the end date first: '
              'the cost of leaving early is in the contract you signed.',
          xp: 12,
          literacy: 12,
        ),
      ],
    ),
  ],

  // ---------------------------------------------------------------
  'spot_market': [
    TownScenario(
      id: 'market_end_of_day',
      prompt:
          'It is nearly closing and the stalls are cutting prices to '
          'avoid carrying stock home.',
      choices: [
        TownChoice(
          label: 'Buy whatever is cheapest',
          outcome:
              'You come away with things you did not plan to eat. A '
              'discount on the wrong item is still money spent on the '
              'wrong item.',
          gold: -6,
          xp: 5,
          literacy: 6,
        ),
        TownChoice(
          label: 'Buy the things on your list, at the lower price',
          outcome:
              'The list is what turns a sale into a saving. Same discount, '
              'entirely different outcome.',
          gold: -4,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Come back tomorrow morning instead',
          outcome:
              'Better stock, higher price. There is no version of this '
              'where you get both — that is what a trade-off is.',
          xp: 8,
          literacy: 7,
        ),
      ],
    ),
    TownScenario(
      id: 'market_haggle',
      prompt:
          'The stallholder says \$20 for the jacket. It has been on the '
          'rail for three weeks.',
      choices: [
        TownChoice(
          label: 'Pay the \$20',
          outcome:
              'A fair price and no fuss. Haggling is not compulsory, and '
              'it is worth knowing that the first number is often not the '
              'last one.',
          gold: -20,
          xp: 5,
        ),
        TownChoice(
          label: 'Offer \$14',
          outcome:
              'You settle at \$16. Asking cost nothing and saved \$4 — the '
              'worst that happens when you ask is that the answer is no.',
          gold: -16,
          xp: 10,
          literacy: 9,
        ),
        TownChoice(
          label: 'Leave it',
          outcome:
              'You keep the \$20 and do not own a jacket. Walking away is '
              'the strongest position in any negotiation, which is why it '
              'has to be real.',
          xp: 8,
          literacy: 8,
        ),
      ],
    ),
    TownScenario(
      id: 'market_bulk',
      prompt:
          'A sack of rice is \$18 and would last two months. A small bag '
          'is \$4 and lasts a fortnight.',
      choices: [
        TownChoice(
          label: 'Buy the sack',
          outcome:
              'Four fortnights for \$18 instead of \$16 — barely cheaper, '
              'and you paid it all today. Buying in bulk needs both the '
              'space and the cash up front.',
          gold: -18,
          xp: 7,
          literacy: 9,
        ),
        TownChoice(
          label: 'Buy the small bag',
          outcome:
              'More expensive per meal, and you keep \$14 for whatever '
              'else this fortnight brings. Poverty is expensive precisely '
              'because of this trade.',
          gold: -4,
          xp: 8,
          literacy: 10,
        ),
        TownChoice(
          label: 'Work out the price per meal first, and buy neither today',
          outcome:
              'The sack is 11c a meal, the bag 14c. Real but small — and '
              'now it is a number instead of a feeling. You have enough '
              'in for this week anyway.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'market_broken_scale',
      prompt:
          'The stall weighs your bag and charges \$7. You are fairly sure '
          'it was closer to \$5 worth.',
      choices: [
        TownChoice(
          label: 'Pay and say nothing',
          outcome:
              'Two dollars, and the same again next week and the week '
              'after. Small overcharges survive because nobody thinks one '
              'is worth the awkwardness.',
          gold: -7,
          xp: 4,
          literacy: 7,
        ),
        TownChoice(
          label: 'Ask them to weigh it again',
          outcome:
              'It was the scale. Checking a total is not accusing anybody '
              'of anything, and it is the only way an error ever gets '
              'found.',
          gold: -5,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Leave the bag',
          outcome:
              'You keep the \$7 and go without. Fair enough — though the '
              'question would probably have sorted it.',
          xp: 6,
          literacy: 6,
        ),
      ],
    ),
  ],

  // ---------------------------------------------------------------
  'spot_cafe': [
    TownScenario(
      id: 'cafe_loyalty',
      prompt:
          'A loyalty card: nine drinks and the tenth is free. Each one is '
          '\$4.50.',
      choices: [
        TownChoice(
          label: 'Take the card and start filling it',
          outcome:
              'You spend \$40.50 to get \$4.50 back — a 10% discount on '
              'money you were going to spend anyway, or an excellent '
              'reason to come nine more times.',
          gold: -5,
          xp: 6,
          literacy: 9,
        ),
        TownChoice(
          label: 'Take the card but do not change your habits',
          outcome:
              'The right way to hold one. A loyalty scheme is only a '
              'discount if it does not alter what you buy.',
          gold: -5,
          xp: 9,
          literacy: 10,
        ),
        TownChoice(
          label: 'Decline it',
          outcome:
              'Nothing lost. The card is free and so is saying no to one '
              'more small thing to keep track of.',
          xp: 7,
          literacy: 6,
        ),
      ],
    ),
    TownScenario(
      id: 'cafe_round',
      prompt:
          'Four of you are here. Someone suggests getting rounds instead '
          'of paying separately.',
      choices: [
        TownChoice(
          label: 'Get the first round',
          outcome:
              'Rounds are fair only if everybody buys one and everybody '
              'wants the same number. Neither is usually true, and the '
              'person who leaves early wins.',
          gold: -18,
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'Pay for your own',
          outcome:
              'Slightly awkward for four seconds and exactly right for '
              'the rest of the evening. Splitting evenly is not the same '
              'as splitting fairly.',
          gold: -5,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Just have water',
          outcome:
              'Free, and nobody minds nearly as much as you expect. '
              'Turning up is the part your friends wanted.',
          xp: 8,
          literacy: 7,
        ),
      ],
    ),
    TownScenario(
      id: 'cafe_upsell',
      prompt: '"Make it a large for 80c?" The large is nearly twice the size.',
      choices: [
        TownChoice(
          label: 'Yes — it is better value',
          outcome:
              'It genuinely is, per millilitre. It is also 80c you were '
              'not going to spend, on a drink you did not need to be '
              'bigger.',
          gold: -5,
          xp: 6,
          literacy: 9,
        ),
        TownChoice(
          label: 'No, the small is what you wanted',
          outcome:
              'Better value per unit is only value if you wanted the '
              'units. This is the whole upsell in one sentence.',
          gold: -4,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Just ask for tap water',
          outcome:
              'Free, and it turns out it was thirst rather than the '
              'drink. Naming what you actually wanted is most of the '
              'skill.',
          xp: 9,
          literacy: 8,
        ),
      ],
    ),
    TownScenario(
      id: 'cafe_tip',
      prompt:
          'The card machine offers 10%, 15% or 20%, with no obvious way '
          'to choose something else.',
      choices: [
        TownChoice(
          label: 'Tap 20% because it is highlighted',
          outcome:
              'The highlighted one is the default because defaults win. '
              'That is a design decision somebody made about your money.',
          gold: -6,
          xp: 5,
          literacy: 9,
        ),
        TownChoice(
          label: 'Find the "custom" option',
          outcome:
              'It is usually there, one tap further on. Noticing that a '
              'screen is steering you is worth more than the difference.',
          gold: -5,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Skip the tip screen and tip in cash on the way out',
          outcome:
              'You choose the number, and it reaches the person more '
              'directly. Same money, different route, and you decided '
              'both — the screen decided neither.',
          xp: 9,
          literacy: 8,
        ),
      ],
    ),
  ],

  // ---------------------------------------------------------------
  'spot_clinic': [
    TownScenario(
      id: 'clinic_prescription',
      prompt:
          'The branded medicine is \$32. The pharmacist mentions the '
          'generic is \$6 and chemically identical.',
      choices: [
        TownChoice(
          label: 'Take the branded one',
          outcome:
              '\$26 for a name and a nicer box. Sometimes that buys '
              'confidence, which is worth something — just not usually '
              '\$26.',
          gold: -32,
          xp: 5,
          literacy: 8,
        ),
        TownChoice(
          label: 'Take the generic',
          outcome:
              'Same active ingredient, same regulator, one fifth of the '
              'price. Asking "is there a generic" is the single most '
              'reliable saving in a pharmacy.',
          gold: -6,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask whether you need it at all',
          outcome:
              'For this, rest would do. The cheapest prescription is the '
              'one that turns out to be optional.',
          xp: 9,
          literacy: 9,
        ),
      ],
    ),
    TownScenario(
      id: 'clinic_dental',
      prompt:
          'A check-up is \$45. You last went three years ago and nothing '
          'hurts.',
      choices: [
        TownChoice(
          label: 'Book it',
          outcome:
              '\$45 for nothing being wrong is what prevention costs. It '
              'never feels worth it, which is precisely why it is.',
          gold: -45,
          xp: 9,
          literacy: 10,
        ),
        TownChoice(
          label: 'Wait until something hurts',
          outcome:
              'A filling is \$180 and a crown is \$900. Waiting is only '
              'cheaper until it is not, and you do not get to choose when '
              'that is.',
          xp: 5,
          literacy: 9,
        ),
        TownChoice(
          label: 'Check whether it is covered',
          outcome:
              'Some of it is. The number of people paying for something '
              'they are already covered for is not small.',
          gold: -15,
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'clinic_bill_shock',
      prompt:
          'A bill arrives for a visit you thought was covered. It is '
          '\$260 and the codes mean nothing to you.',
      choices: [
        TownChoice(
          label: 'Pay it',
          outcome:
              'Settled, and possibly wrong. Medical billing errors are '
              'common enough that paying without reading is a real cost.',
          gold: -60,
          xp: 4,
          literacy: 7,
        ),
        TownChoice(
          label: 'Ask for an itemised bill',
          outcome:
              'Two of the lines were charged twice. You are entitled to '
              'the detail, and asking for it is the only way anybody ever '
              'finds these.',
          gold: -30,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask about a payment plan',
          outcome:
              'Most providers have one and almost none advertise it. The '
              'bill does not shrink, but it stops being this month\'s '
              'problem all at once.',
          xp: 9,
          literacy: 9,
        ),
      ],
    ),
    TownScenario(
      id: 'clinic_sick_day',
      prompt:
          'You are ill on a work day. Staying home costs a day\'s pay; '
          'going in costs the rest of the week.',
      choices: [
        TownChoice(
          label: 'Go in anyway',
          outcome:
              'You get through today and lose three days later. Working '
              'through it is borrowing from next week at a bad rate.',
          gold: -20,
          xp: 5,
          literacy: 8,
        ),
        TownChoice(
          label: 'Stay home',
          outcome:
              'A day\'s pay, and back to normal on Thursday. Health is '
              'the asset every other one depends on.',
          gold: -30,
          xp: 9,
          literacy: 9,
        ),
        TownChoice(
          label: 'Check whether you have sick pay',
          outcome:
              'You do, and you had never looked. Knowing what your job '
              'actually gives you is worth an evening of reading, once.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
  ],

  // ---------------------------------------------------------------
  'spot_library': [
    TownScenario(
      id: 'library_free_stuff',
      prompt:
          'The noticeboard lists what your card gets you: books, films, '
          'newspapers, and free access to three paid learning sites.',
      choices: [
        TownChoice(
          label: 'Get the card',
          outcome:
              'Free, five minutes, and it replaces about \$300 a year of '
              'subscriptions. Almost nobody does it, which is the only '
              'strange part.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Keep paying for the streaming one',
          outcome:
              'Better catalogue, and you are paying for convenience — '
              'which is fine when it is a decision rather than a habit.',
          gold: -12,
          xp: 5,
          literacy: 7,
        ),
        TownChoice(
          label: 'Take a photo of the list for later',
          outcome:
              'Later never comes for most of these. Still, knowing the '
              'free version exists is what makes the paid one a choice.',
          xp: 7,
          literacy: 7,
        ),
      ],
    ),
    TownScenario(
      id: 'library_study_room',
      prompt:
          'You need somewhere quiet for three hours. The library room is '
          'free to book; the cafe costs whatever you drink.',
      choices: [
        TownChoice(
          label: 'Book the room',
          outcome:
              'Three hours, nothing spent, and better light. The place '
              'that wants to sell you something is rarely the cheapest '
              'place to sit.',
          xp: 10,
          literacy: 9,
        ),
        TownChoice(
          label: 'Go to the cafe',
          outcome:
              'Two drinks and a pastry is \$11 for the privilege of '
              'sitting. Occasionally worth it; rarely worth it three '
              'times a week.',
          gold: -11,
          xp: 5,
          literacy: 7,
        ),
        TownChoice(
          label: 'Work at home for free',
          outcome:
              'Free and you got half as much done. Time is a cost too, '
              'and it is the one people forget to count.',
          xp: 7,
          literacy: 8,
        ),
      ],
    ),
    TownScenario(
      id: 'library_money_talk',
      prompt:
          'A free evening talk: "Understanding your payslip". Two hours, '
          'no sales pitch, run by the council.',
      choices: [
        TownChoice(
          label: 'Go',
          outcome:
              'Two hours, and you can now read the document that decides '
              'what you take home. Free financial education with nothing '
              'to sell is rare enough to be worth the evening.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Skip it — payslips are self-explanatory',
          outcome:
              'They are not, and the people who say so are usually the '
              'ones being taxed wrong. No harm done tonight.',
          xp: 5,
          literacy: 6,
        ),
        TownChoice(
          label: 'Go, and check who is running it first',
          outcome:
              'Council-run, no product at the end. The single most useful '
              'question about any free money advice is who paid for it.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'library_late_fee',
      prompt:
          'Two books are three weeks overdue. The fine is 20c a day and '
          'caps at \$8.',
      choices: [
        TownChoice(
          label: 'Pay the fine and move on',
          outcome:
              '\$8 for forgetting. Cheap as lessons go, and the cap is '
              'why — most late fees in the real world do not have one.',
          gold: -8,
          xp: 7,
          literacy: 9,
        ),
        TownChoice(
          label: 'Set a reminder for the next lot',
          outcome:
              'The fine was never really about the books. Every recurring '
              'date you do not track is a small charge waiting to happen.',
          gold: -8,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask whether they still run fine amnesty',
          outcome:
              'They do, in January. Asking whether a charge can be waived '
              'works surprisingly often, and never costs anything.',
          xp: 9,
          literacy: 9,
        ),
      ],
    ),
  ],

  // ---------------------------------------------------------------
  'spot_pawn': [
    TownScenario(
      id: 'pawn_quick_cash',
      prompt:
          'Rent is short by \$70 and payday is nine days away. They will '
          'lend \$70 against your watch for \$95 back.',
      choices: [
        TownChoice(
          label: 'Take it',
          outcome:
              '\$25 to borrow \$70 for nine days. As a yearly rate that is '
              'over 1,400% — and it is still sometimes the only door open, '
              'which is the part worth understanding.',
          gold: 70,
          xp: 6,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask the landlord for nine days first',
          outcome:
              'They say yes. The cheapest loan available is almost always '
              'the conversation you were too embarrassed to have.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Sell something you do not use instead',
          outcome:
              'Slower, and you keep the watch. Selling is final; '
              'borrowing is final *and* expensive.',
          gold: 55,
          xp: 9,
          literacy: 9,
        ),
      ],
    ),
    TownScenario(
      id: 'pawn_phone_value',
      prompt: 'Your two-year-old phone cost \$900. The counter offer is \$120.',
      choices: [
        TownChoice(
          label: 'Take the \$120',
          outcome:
              '\$780 of value gone in two years — about \$1 a day. That is '
              'what owning the newest thing costs, and it is worth knowing '
              'the number before the next one.',
          gold: 120,
          xp: 8,
          literacy: 10,
        ),
        TownChoice(
          label: 'Keep using it',
          outcome:
              'Every extra year you keep it drops that daily cost. The '
              'cheapest phone anybody owns is the one they already have.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Trade it in against a new one',
          outcome:
              'The trade-in is generous and the new contract is not. '
              'Discounts attached to a two-year commitment are priced '
              'accordingly.',
          gold: 60,
          xp: 6,
          literacy: 9,
        ),
      ],
    ),
    TownScenario(
      id: 'pawn_buy_second_hand',
      prompt:
          'A guitar in the window: \$85, against \$260 new. It needs '
          'strings.',
      choices: [
        TownChoice(
          label: 'Buy it',
          outcome:
              'A third of the price for something already past its worst '
              'depreciation. Second-hand is where the discount for '
              'somebody else\'s impatience lives.',
          gold: -85,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Buy new instead',
          outcome:
              'A warranty, a shop to go back to, and \$175. Sometimes '
              'that is the right trade — as long as you know that is what '
              'you bought.',
          gold: -260,
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'Borrow one first and see if you stick with it',
          outcome:
              'Most instruments are played for three weeks. Finding out '
              'for free is worth more than either price.',
          xp: 10,
          literacy: 9,
        ),
      ],
    ),
    TownScenario(
      id: 'pawn_ring',
      prompt:
          'A ring you were given. They offer \$40 for the gold weight and '
          'nothing for anything else.',
      choices: [
        TownChoice(
          label: 'Sell it',
          outcome:
              '\$40, and it is gone. A pawn shop prices metal, not '
              'meaning — which is the right way round for them and rarely '
              'for you.',
          gold: 40,
          xp: 5,
          literacy: 8,
        ),
        TownChoice(
          label: 'Keep it',
          outcome:
              'Not everything you own is an asset to be optimised. Knowing '
              'which things are outside the spreadsheet is part of being '
              'good with money, not a failure of it.',
          xp: 10,
          literacy: 9,
        ),
        TownChoice(
          label: 'Get it valued somewhere else first',
          outcome:
              'A jeweller says \$150 for the workmanship. One offer is '
              'never a price — it is one person\'s opinion of one.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'pawn_sell_scooter',
      prompt:
          'You have an old scooter. The pawn shop offers \$80 today. '
          'Selling it online might get \$140 but takes a few weeks.',
      choices: [
        TownChoice(
          label: 'Take the \$80 today',
          outcome:
              'Quick money, and less of it. The \$60 gap is what you paid for '
              'it being over this afternoon.',
          gold: 20,
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'List it online for \$140',
          outcome:
              'More money for more effort and time. Whether \$60 is worth a few '
              'weeks depends on whether you need the cash now.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask the shop if they can do \$110',
          outcome:
              'Most offers have room in them. The first number is where a '
              'conversation starts, and it is not the price.',
          gold: 30,
          xp: 12,
          literacy: 12,
        ),
      ],
    ),
  ],

  // ---------------------------------------------------------------
  'spot_park': [
    TownScenario(
      id: 'park_free_day',
      prompt:
          'A clear Saturday. The festival across town is \$25 in; the park '
          'has a band on for nothing.',
      choices: [
        TownChoice(
          label: 'Go to the festival',
          outcome:
              'Bigger, louder, \$25 plus whatever you eat there. Worth it '
              'sometimes — the trap is assuming the paid version is '
              'automatically the better day.',
          gold: -25,
          xp: 6,
        ),
        TownChoice(
          label: 'Stay for the free band',
          outcome:
              'A good afternoon for nothing. Towns are full of these and '
              'almost nobody looks for them, because nothing is spent on '
              'advertising them.',
          xp: 10,
          literacy: 9,
        ),
        TownChoice(
          label: 'Both — band now, festival next year',
          outcome:
              'You get the free one today and the paid one becomes a '
              'decision rather than a default. Spacing things out is the '
              'quietest saving there is.',
          xp: 9,
          literacy: 8,
        ),
      ],
    ),
    TownScenario(
      id: 'park_running',
      prompt:
          'The gym is \$45 a month. The park has a free running group on '
          'Wednesdays.',
      choices: [
        TownChoice(
          label: 'Join the gym',
          outcome:
              '\$540 a year, and the equipment is genuinely better. The '
              'question is not whether it is good — it is whether you will '
              'go in March.',
          gold: -45,
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'Try the running group first',
          outcome:
              'Free, and you find out whether you actually turn up before '
              'committing \$540. Trying the free version first is the '
              'cheapest test there is.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Neither, for now',
          outcome:
              'Nothing spent and nothing changed. An honest no beats a '
              'membership you will cancel in April.',
          xp: 7,
          literacy: 7,
        ),
      ],
    ),
    TownScenario(
      id: 'park_ice_cream',
      prompt:
          'A van by the gate. \$5 for a cone, and you are not especially '
          'hungry.',
      choices: [
        TownChoice(
          label: 'Buy one',
          outcome:
              'Nice, and gone in four minutes. Spending on a small good '
              'moment is what money is for — as long as it is not every '
              'time you walk past.',
          gold: -5,
          xp: 6,
        ),
        TownChoice(
          label: 'Walk on',
          outcome:
              'You are not hungry, and in ten minutes you will not '
              'remember the van. Most impulses are settled entirely by '
              'walking another hundred metres.',
          xp: 9,
          literacy: 9,
        ),
        TownChoice(
          label: 'Decide before you get to the gate next time',
          outcome:
              'The decision is easier made anywhere except standing in '
              'front of it. That is the whole reason the van is by the '
              'gate.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'park_charity_run',
      prompt:
          'A charity 5k next month: \$20 to enter, and they ask you to '
          'raise \$100 in sponsorship.',
      choices: [
        TownChoice(
          label: 'Enter and raise the money',
          outcome:
              'You are \$20 down and the shelter is \$100 up. Giving other '
              'people\'s money away is still giving, and it is how most '
              'charity actually works.',
          gold: -20,
          xp: 10,
          literacy: 9,
        ),
        TownChoice(
          label: 'Donate \$20 directly instead',
          outcome:
              'All of it arrives and none of it is spent on medals and '
              'timing chips. Less fun, more efficient — both are real '
              'answers.',
          gold: -20,
          xp: 9,
          literacy: 10,
        ),
        TownChoice(
          label: 'Run it on your own for free',
          outcome:
              'Same 5k, no entry fee, no sponsorship to chase. The event '
              'was never the running.',
          xp: 8,
          literacy: 7,
        ),
      ],
    ),
  ],

  // ---------------------------------------------------------------
  'spot_notice': [
    TownScenario(
      id: 'notice_text_scam',
      prompt:
          'A text: "Your parcel is held. Pay a \$2 redelivery fee at this '
          'link." You are expecting a parcel.',
      choices: [
        TownChoice(
          label: 'Pay the \$2 — it is tiny',
          outcome:
              'The \$2 was never the point; the card details were. A fee '
              'small enough not to think about is the whole design of this '
              'one.',
          gold: -2,
          xp: 5,
          literacy: 8,
        ),
        TownChoice(
          label: 'Open the courier app instead',
          outcome:
              'Right move. Never follow the link you were sent — go to the '
              'company the way you normally would and check there. A real '
              'problem will be waiting for you.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Delete it because you are not expecting one',
          outcome:
              'These land in the week everyone is expecting a parcel, which '
              'is why they work. Coincidence is a tool, not proof.',
          xp: 9,
          literacy: 9,
        ),
      ],
    ),
    TownScenario(
      id: 'notice_room_share',
      prompt:
          'A card offers a room at \$400 a month, "bills included, no '
          'deposit, cash only, move in today".',
      choices: [
        TownChoice(
          label: 'Take it — cheap and quick',
          outcome:
              'Cash only and no paperwork means no proof you paid and no '
              'rights if it goes wrong. The saving is real and so is what '
              'you gave up for it.',
          gold: -40,
          xp: 5,
          literacy: 8,
        ),
        TownChoice(
          label: 'Ask for a written agreement',
          outcome:
              'A tenancy agreement protects the tenant more than the '
              'landlord. Anyone unwilling to put the terms in writing has '
              'told you something.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Visit before agreeing anything',
          outcome:
              'Obvious and constantly skipped when a place looks cheap. '
              '"Move in today" exists to stop you doing exactly this.',
          xp: 9,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'notice_charity',
      prompt:
          'Someone is collecting for a local shelter. They want a monthly '
          'direct debit rather than the \$5 in your pocket.',
      choices: [
        TownChoice(
          label: 'Sign up for \$10 a month',
          outcome:
              'Charities push monthly because it is worth far more than a '
              'one-off, which is fair — as long as it is a number you '
              'reviewed rather than one agreed on a pavement.',
          gold: -10,
          xp: 7,
          literacy: 9,
        ),
        TownChoice(
          label: 'Give the \$5 and nothing ongoing',
          outcome:
              'Perfectly good. Giving is part of a budget like anything '
              'else, and the amount you can repeat matters more than the '
              'amount you can manage once.',
          gold: -5,
          xp: 9,
          literacy: 9,
        ),
        TownChoice(
          label: 'Look the charity up and donate later',
          outcome:
              'Registered charities are listed publicly and take two minutes '
              'to check. Wanting to give and wanting to give to *this* are '
              'different decisions.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'notice_scam',
      prompt:
          'A flyer: "YOU HAVE WON \$500! Claim within 24 hours. Small '
          '\$20 processing fee — pay by gift card."',
      choices: [
        TownChoice(
          label: 'Pay the \$20 — \$500 is worth it',
          outcome:
              'Gone. Gift-card payment, a prize you did not enter for, '
              'and a 24-hour deadline: three of the four classic scam '
              'signs in one flyer.',
          gold: -20,
          xp: 4,
          literacy: 6,
        ),
        TownChoice(
          label: 'Ignore it',
          outcome:
              'Correct. Nobody legitimate asks for a fee to release a '
              'prize, and nobody legitimate asks to be paid in gift '
              'cards.',
          xp: 9,
          literacy: 10,
        ),
        TownChoice(
          label: 'Report it to the notice board keeper',
          outcome:
              'Best answer. Reporting is what stops the next person '
              'falling for it — the FTC takes reports for exactly this.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'notice_job_ad',
      prompt:
          'An ad offers \$400 a week working from home. It asks for your '
          'bank details up front "to set up payroll".',
      choices: [
        TownChoice(
          label: 'Send the details — it is just payroll',
          outcome:
              'A real employer collects bank details *after* hiring you, '
              'through a process you can verify. Up front, before an '
              'interview, is the tell.',
          xp: 4,
          literacy: 6,
        ),
        TownChoice(
          label: 'Ask to meet or video-call first',
          outcome:
              'Reasonable, and scammers usually vanish at this point. '
              'Wanting to know who you are working for is not rude.',
          xp: 9,
          literacy: 9,
        ),
        TownChoice(
          label: 'Look up the company before replying',
          outcome:
              'Ten minutes of searching costs nothing and catches most of '
              'these. No search results at all is itself an answer.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
  ],
  // ---------------------------------------------------------------
  'spot_gym': [
    TownScenario(
      id: 'gym_free_week',
      prompt:
          'The desk offers a free week. Signing up asks for your card, and '
          'the membership starts by itself when the week ends.',
      choices: [
        TownChoice(
          label: 'Sign up and set a reminder for day six',
          outcome:
              'You used the free week and cancelled before it charged. Free '
              'trials that renew on their own count on you forgetting the date.',
          xp: 12,
          literacy: 12,
        ),
        TownChoice(
          label: 'Sign up and forget about it',
          outcome:
              'The card was charged on day eight. A trial that renews by itself '
              'is a subscription with a delay on it, and the date is the whole '
              'trick.',
          gold: -20,
          xp: 4,
          literacy: 8,
        ),
        TownChoice(
          label: 'Skip the trial',
          outcome:
              'Nothing lost, and nothing learned about whether you would like '
              'it. Some people are better off never handing over a card for '
              'something free.',
          xp: 6,
          literacy: 4,
        ),
      ],
    ),
    TownScenario(
      id: 'gym_trainer',
      prompt:
          'A trainer sells ten sessions for \$20, or one session for \$3. '
          'He says the ten are "the best value".',
      choices: [
        TownChoice(
          label: 'Buy the ten (\$20)',
          outcome:
              'Cheaper per session if you use every one. Use four and each cost '
              '\$5, which is more than buying one at a time. A bundle only '
              'saves money if you finish it.',
          gold: -20,
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'Buy one (\$3)',
          outcome:
              'You paid for what you were sure of. If you like it, the next one '
              'is a fresh choice instead of a sum already spent.',
          gold: -3,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Ask if unused sessions can be refunded',
          outcome:
              'Asking cost nothing. The terms on a bundle are worth knowing '
              'before you pay, because they are hardest to change after.',
          xp: 12,
          literacy: 12,
        ),
      ],
    ),
    TownScenario(
      id: 'gym_new_year',
      prompt:
          'A sign at the desk: "Today only, twelve months for \$120, half '
          'price." It is January and the queue is long.',
      choices: [
        TownChoice(
          label: 'Join today (\$20 deposit)',
          outcome:
              'A deadline like "today only" is there to stop you thinking. A '
              'real bargain is still a bargain tomorrow.',
          gold: -20,
          xp: 4,
          literacy: 6,
        ),
        TownChoice(
          label: 'Come back tomorrow and ask',
          outcome:
              'The same offer was on the desk. A price that vanishes if you '
              'sleep on it is a sales technique and not a price.',
          xp: 12,
          literacy: 12,
        ),
        TownChoice(
          label: 'Use the free track until March',
          outcome:
              'If you are still going in March, join then. You paid nothing to '
              'find out whether it will stick.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'gym_water',
      prompt:
          'A bottle of water at the desk is \$3. There is a tap fifteen '
          'steps away and a bottle in your bag.',
      choices: [
        TownChoice(
          label: 'Buy one (\$3)',
          outcome:
              'It is only \$3. Three times a week is about \$470 in a few '
              'years, and no single one of them is the problem.',
          gold: -3,
          xp: 3,
          literacy: 6,
        ),
        TownChoice(
          label: 'Fill your own from the tap',
          outcome:
              'Free, and it tastes the same. Small habits repeated are where '
              'most of a budget is quietly won or lost.',
          xp: 8,
          literacy: 10,
        ),
        TownChoice(
          label: 'Buy one and refill it every time',
          outcome:
              'You spent \$3 once and never again. Buying something you will '
              'reuse is a different purchase from one you drink.',
          gold: -3,
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
  ],
  // ---------------------------------------------------------------
  'spot_campus': [
    TownScenario(
      id: 'campus_grant_loan',
      prompt:
          'Two offers on the desk: a \$500 grant you never repay, and a '
          '\$500 loan at 6% interest a year.',
      choices: [
        TownChoice(
          label: 'Take the grant',
          outcome:
              'Free money is the best kind, and it is worth checking for before '
              'anything else. Grants and scholarships do not need paying back.',
          gold: 20,
          xp: 10,
          literacy: 12,
        ),
        TownChoice(
          label: 'Take the loan',
          outcome:
              'You get the money now and pay back more than you got. At 6% a '
              'year, \$500 costs about \$30 extra for each year it is owed. '
              'Borrowing is fine when it buys something worth more.',
          xp: 8,
          literacy: 12,
        ),
        TownChoice(
          label: 'Ask for both',
          outcome:
              'You are allowed to ask. Grants and loans are not either-or, and '
              'the person at the desk cannot offer what they are not asked '
              'about.',
          xp: 12,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'campus_part_time',
      prompt:
          'The campus cafe wants somebody for eight hours a week. It pays '
          '\$8 an hour, and the shifts fall on study days.',
      choices: [
        TownChoice(
          label: 'Take the job',
          outcome:
              'Earning while you study means less to borrow and less time to '
              'study. Both are true, and the trade is yours to weigh.',
          gold: 25,
          xp: 10,
          literacy: 8,
        ),
        TownChoice(
          label: 'Say no and study',
          outcome:
              'Your time stayed on the course. It costs the pay and it may save '
              'a resit. There is no free option, only the one you would rather '
              'have.',
          xp: 8,
          literacy: 8,
        ),
        TownChoice(
          label: 'Ask for fewer hours',
          outcome:
              'People say yes to a smaller ask more often than they expect. '
              'Fewer hours is a way of buying part of both.',
          gold: 12,
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'campus_course_choice',
      prompt:
          'Two courses. One costs \$3,000 a year and leads to jobs that '
          'start at about \$30,000. The other costs \$1,500 and leads to '
          'about \$26,000.',
      choices: [
        TownChoice(
          label: 'Work out what each pays back',
          outcome:
              'The cheaper one costs half and pays 87% as much. Cost against '
              'what it earns is the comparison that counts, and the price alone '
              'is not.',
          xp: 12,
          literacy: 14,
        ),
        TownChoice(
          label: 'Take the dearer one',
          outcome:
              'It may be right. The extra \$1,500 a year buys about \$4,000 '
              'more pay, which is worth it if you finish and the job is there.',
          xp: 8,
          literacy: 8,
        ),
        TownChoice(
          label: 'Take the cheaper one',
          outcome:
              'Less to borrow and less to lose if plans change. A smaller bet '
              'is easier to walk away from.',
          xp: 8,
          literacy: 8,
        ),
      ],
    ),
    TownScenario(
      id: 'campus_essay_deadline',
      prompt:
          'The scholarship form wants a 300 word essay and a reference. The '
          'deadline is tomorrow, and about ten people apply for each one '
          'that is given.',
      choices: [
        TownChoice(
          label: 'Write it tonight',
          outcome:
              'One in ten for \$500 is worth \$50 of chances for an evening. '
              'That beats most part-time pay, which is why the odds are better '
              'than they feel.',
          xp: 12,
          literacy: 14,
        ),
        TownChoice(
          label: 'Ask for a day more',
          outcome:
              'Some offices say yes. Asking is free and the worst answer is the '
              'one you already have.',
          xp: 10,
          literacy: 8,
        ),
        TownChoice(
          label: 'Skip it, the odds are low',
          outcome:
              'You kept your evening. Low odds and a small effort is still '
              'often a good bet, and nobody wins a form they did not send.',
          xp: 4,
          literacy: 6,
        ),
      ],
    ),
  ],
  // ---------------------------------------------------------------
  'spot_housing': [
    TownScenario(
      id: 'housing_rent_or_buy',
      prompt:
          'A flat is \$600 a month to rent. A small house is \$90,000 to '
          'buy. The agent says rent is "dead money".',
      choices: [
        TownChoice(
          label: 'Ask what buying costs on top',
          outcome:
              'A deposit, a loan with interest, repairs and tax. The agent is '
              'right that rent builds nothing, and wrong that owning is free of '
              'costs.',
          xp: 12,
          literacy: 14,
        ),
        TownChoice(
          label: 'Sign for the flat',
          outcome:
              'You keep your savings free and somebody else fixes the roof. '
              'Renting is a fair choice, and what you pay does not come back.',
          gold: -10,
          xp: 6,
          literacy: 8,
        ),
        TownChoice(
          label: 'Say you are not ready yet',
          outcome:
              'Waiting is allowed. Not being ready is a good reason not to '
              'sign, as long as the rent you pay meanwhile is a choice.',
          xp: 8,
          literacy: 6,
        ),
      ],
    ),
    TownScenario(
      id: 'housing_deposit',
      prompt:
          'The landlord wants a deposit of two months rent upfront, and the '
          'first month as well.',
      choices: [
        TownChoice(
          label: 'Ask what it covers and when it comes back',
          outcome:
              'A deposit is yours if nothing is broken. Asking in writing what '
              'counts as damage is the difference between getting it back and '
              'not.',
          xp: 12,
          literacy: 12,
        ),
        TownChoice(
          label: 'Pay it and move in',
          outcome:
              'It is money tied up for as long as you live there. Take photos '
              'on the day you move in, so what was already broken is not blamed '
              'on you.',
          gold: -15,
          xp: 8,
          literacy: 8,
        ),
        TownChoice(
          label: 'Look for somewhere with a smaller deposit',
          outcome:
              'Cheaper to start, and often dearer each month. The upfront cost '
              'and the monthly cost are different numbers, and a place can win '
              'one and lose the other.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'housing_bills',
      prompt:
          'The rent includes water. Electricity is extra, and the agent '
          'says winter bills are "a bit higher".',
      choices: [
        TownChoice(
          label: 'Ask what last winter cost',
          outcome:
              'Past bills are the best guide to next ones. The agent has them, '
              'and asking is the cheapest way to find a cost that is not on the '
              'advert.',
          xp: 12,
          literacy: 12,
        ),
        TownChoice(
          label: 'Sign and see',
          outcome:
              'Sometimes it works out. If it does not, you learn the real '
              'monthly cost after you have committed to it.',
          gold: -8,
          xp: 6,
          literacy: 6,
        ),
        TownChoice(
          label: 'Choose the place with everything included',
          outcome:
              'One number is easier to plan around, and it usually costs a '
              'little more for the certainty. You are paying for a smaller '
              'surprise.',
          xp: 10,
          literacy: 10,
        ),
      ],
    ),
    TownScenario(
      id: 'housing_flatmate',
      prompt:
          'A flatmate would halve the rent. A friend is keen. So is a '
          'stranger from an advert who offers to pay a month early.',
      choices: [
        TownChoice(
          label: 'Share with the friend',
          outcome:
              'Half the rent and somebody you know. Put in writing who pays '
              'what, because money is what friendships most often come apart '
              'over.',
          xp: 12,
          literacy: 12,
        ),
        TownChoice(
          label: 'Share with the stranger',
          outcome:
              'Also half the rent, and less you know. A month paid early is a '
              'nice sign and not a reference. Meet them and ask about the last '
              'place.',
          xp: 8,
          literacy: 8,
        ),
        TownChoice(
          label: 'Live alone and pay it all',
          outcome:
              'Your own space at twice the cost. Some people rightly pay that, '
              'and it helps to see the price of the quiet as a number.',
          gold: -10,
          xp: 6,
          literacy: 8,
        ),
      ],
    ),
  ],
  // ---------------------------------------------------------------
  'spot_pet': [
    TownScenario(
      id: 'pet_insurance',
      prompt:
          'Pet insurance is \$15 a month. A vet bill for a broken leg can '
          'be \$400.',
      choices: [
        TownChoice(
          label: 'Take the insurance (\$15)',
          outcome:
              'A small sure cost to avoid a big unlikely one. That is all '
              'insurance is, and it only pays if the bad day comes.',
          gold: -15,
          xp: 8,
          literacy: 10,
        ),
        TownChoice(
          label: 'Save \$15 a month yourself',
          outcome:
              'Your own pot works too, if you really put it in every month and '
              'leave it. It is the same protection, and it depends on you.',
          xp: 12,
          literacy: 12,
        ),
        TownChoice(
          label: 'Do nothing',
          outcome:
              'If nothing goes wrong you are ahead. If a leg breaks, the whole '
              '\$400 is yours in one go. That is a bet, and it is fine to see '
              'it as one.',
          xp: 4,
          literacy: 6,
        ),
      ],
    ),
    TownScenario(
      id: 'pet_sale_toys',
      prompt:
          'A basket of toys is half price. Your pet already ignores the '
          'four toys it has.',
      choices: [
        TownChoice(
          label: 'Buy the lot',
          outcome:
              'Half price on something you did not need is still money spent. A '
              'discount is a reason to buy only if you were going to buy '
              'anyway.',
          gold: -12,
          xp: 4,
          literacy: 8,
        ),
        TownChoice(
          label: 'Buy the one chew toy',
          outcome:
              'A small buy of the thing that gets used. The sale did not make '
              'the rest of it a need.',
          gold: -3,
          xp: 8,
          literacy: 8,
        ),
        TownChoice(
          label: 'Walk on',
          outcome:
              'You kept it all. What a pet likes most is you, and the toys are '
              'mostly for us.',
          xp: 8,
          literacy: 6,
        ),
      ],
    ),
    TownScenario(
      id: 'pet_adopt_or_buy',
      prompt:
          'A breeder wants \$600 for a puppy. The shelter wants \$80 for a '
          'dog that is already vaccinated.',
      choices: [
        TownChoice(
          label: 'Ask what the \$600 buys',
          outcome:
              'Sometimes a lot, sometimes a name. A higher price is not the '
              'same as better, and the right question is what you are getting '
              'for the difference.',
          xp: 12,
          literacy: 12,
        ),
        TownChoice(
          label: 'Go to the shelter (\$80)',
          outcome:
              'Cheaper to begin with, and the shots are done. The daily cost is '
              'the same either way, which is why it is the running bill that '
              'matters most.',
          gold: -10,
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Wait a month and look at both',
          outcome:
              'Waiting for a big choice costs nothing, and prices for a pet are '
              'best judged when you are not already in love with one.',
          xp: 10,
          literacy: 8,
        ),
      ],
    ),
    TownScenario(
      id: 'pet_holiday',
      prompt:
          'You are away for a week. Boarding costs \$140. A neighbour will '
          'look in for \$40. A friend has offered for free.',
      choices: [
        TownChoice(
          label: 'Ask the friend',
          outcome:
              'Free, and it is a favour, not a saving. Favours are worth '
              'something, and remembering to return one is what keeps them '
              'coming.',
          xp: 10,
          literacy: 10,
        ),
        TownChoice(
          label: 'Pay the neighbour (\$40)',
          outcome:
              'You paid for reliability and kept the friendship out of it. '
              'Paying is often the price of not owing anybody.',
          gold: -10,
          xp: 8,
          literacy: 8,
        ),
        TownChoice(
          label: 'Book the boarding (\$140)',
          outcome:
              'The dearest, and the surest. Whether that is worth it depends on '
              'how much a mistake would cost you, and not on the price.',
          gold: -20,
          xp: 6,
          literacy: 8,
        ),
      ],
    ),
  ],
};

/// Which scenario a spot is running today.
///
/// Index 0 is the spot's own built-in encounter; 1.. are [kTownScenarios].
/// Derived from the date and the spot id, so:
///
/// * every spot shows something different from its neighbours on the same
///   day (the id is part of the hash);
/// * the town is *stable within a day*, so a player can walk out and back in
///   without the scene rerolling — that reroll would turn a decision into a
///   slot machine and remove the reason to have walked there;
/// * it changes tomorrow, which is the variety the town was missing.
int townScenarioIndexFor(
  String spotId, {
  DateTime? now,
  int extraCount = 0,
  int? lifeAge,
  String? conditionId,
}) {
  final date = now ?? DateTime.now();
  final total = 1 + extraCount;
  if (total <= 1) return 0;
  // Day number since epoch, mixed with the spot id.
  final day = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(2020)).inDays;
  // ...and with the character's age, when the town was opened from a life.
  //
  // The calendar day alone is right for a player wandering the town on its
  // own, and wrong the moment the town is part of a run: a life plays out
  // sixty-odd years inside one afternoon, so every building said exactly the
  // same thing at seven as it did at seventy. Walking back into the bank a
  // decade later and finding the identical conversation is the clearest way
  // to tell somebody that nothing they do out here matters.
  //
  // **The age is hashed, not multiplied.** The first version used
  // `age * 17`, and a test that sampled ages ten years apart found every
  // sample landing on the same scene. That is not a bad choice of constant,
  // it is arithmetic: a spot with five scenes takes the index mod 5, and
  // `10 * m` is divisible by 5 for *every* m — so no linear mix can survive
  // a player ageing in round decades, which is exactly how somebody skims a
  // life. Hashing the pair breaks the stride.
  //
  // **`Object.hash` cannot be used here**, which is not obvious and cost a
  // flaky test to find. Dart seeds string hashing per isolate, so
  // `Object.hash(spotId, age)` returns a *different* number in every process
  // — meaning the scene a player got for a given day and age changed every
  // time they reopened the app. There is a test one group below called "the
  // rotation is stable within a day", and it only ever passed because it
  // compared two calls inside one process. A stable hash is the whole point
  // of the mix, so it has to be one this file computes itself.
  // The age is folded into the hashed *string*, not multiplied into the sum.
  // Multiplying is what the paragraph above warns against and I put it back
  // by accident on the first pass at this: `age * 7919` is linear, a spot
  // with five scenes takes the index mod 5, and every age in the test's
  // decade-spaced sample landed on the same scene again. Hashing the pair is
  // the only part that breaks the stride.
  // The day, the age, and **what kind of day it is**.
  //
  // Adding the condition is what makes the town survive being walked around
  // twice in one sitting. Before it, the index moved with the calendar day
  // and the character's age and nothing else — so a player who left the town
  // and came straight back at the same age got the identical conversation in
  // every building, which is the thing that reads as "the scenes repeat".
  // The condition is rolled per *visit* (see `TownCondition`), so stepping
  // outside and back in genuinely re-deals the town while staying fixed for
  // as long as you are inside it.
  //
  // It is thematically right as well as cheap: what the cafe says on a rainy
  // day and what it says on market day should not be the same sentence.
  final mix =
      day * 31 + _stableHash('$spotId:${lifeAge ?? 0}:${conditionId ?? ''}');
  return mix.abs() % total;
}

/// FNV-1a over the code units. Deterministic across processes, machines and
/// releases, which `String.hashCode` and [Object.hash] are not.
int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < value.length; i++) {
    hash ^= value.codeUnitAt(i);
    // Kept inside 32 bits so the result is identical on the web's doubles and
    // on native 64-bit ints.
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

/// The extra scenarios [spot] may offer a character of [lifeAge].
///
/// Filtered through [townScenarioMinAge], so what a building has to say
/// genuinely changes as the character grows up rather than only *which* of a
/// fixed set it picks. See `town_age_bands.dart` for why a six-year-old was
/// being asked how they planned to cover the rent.
///
/// **A missing or zero age means no life is in progress**, and then nothing
/// is filtered. The town is still somewhere a player can walk around on its
/// own, and there it has no character whose age could gate anything — the
/// existing contract that `lifeAge: null` and `lifeAge: 0` behave identically
/// is load-bearing and tested. It costs nothing either: `OutingPermission`
/// refuses to let anyone under six leave the house, so a real life never asks
/// this question with an age below that.
List<TownScenario> townScenariosFor(TownSpot spot, {int? lifeAge}) {
  final extras = kTownScenarios[spot.id] ?? const <TownScenario>[];
  if (lifeAge == null || lifeAge <= 0) return extras;
  return extras
      .where((scenario) => lifeAge >= townScenarioMinAge(scenario.id))
      .toList(growable: false);
}

/// The encounter [spot] is showing today.
///
/// `id` identifies the *conversation*, not the building, and it is what stops
/// the town being a gold tap: `AdventureWorldScreen` records the ids it has
/// already paid out for, so walking out and straight back in re-deals the
/// scenes without re-arming the rewards. The spot's built-in encounter is
/// index 0 and has no scenario id of its own, so it gets one derived from the
/// spot.
({String id, String prompt, List<TownChoice> choices}) townEncounterFor(
  TownSpot spot, {
  DateTime? now,
  int? lifeAge,
  String? conditionId,
}) {
  final extras = townScenariosFor(spot, lifeAge: lifeAge);
  final index = townScenarioIndexFor(
    spot.id,
    now: now,
    extraCount: extras.length,
    lifeAge: lifeAge,
    conditionId: conditionId,
  );
  if (index == 0) {
    return (id: '${spot.id}_base', prompt: spot.prompt, choices: spot.choices);
  }
  final scenario = extras[index - 1];
  return (id: scenario.id, prompt: scenario.prompt, choices: scenario.choices);
}
