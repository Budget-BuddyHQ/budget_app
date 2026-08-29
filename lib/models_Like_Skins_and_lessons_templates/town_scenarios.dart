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
const Map<String, List<TownScenario>> kTownScenarios =
    <String, List<TownScenario>>{
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
int townScenarioIndexFor(String spotId, {DateTime? now, int extraCount = 0}) {
  final date = now ?? DateTime.now();
  final total = 1 + extraCount;
  if (total <= 1) return 0;
  // Day number since epoch, mixed with the spot id.
  final day = DateTime(date.year, date.month, date.day)
      .difference(DateTime(2020))
      .inDays;
  final mix = day * 31 + spotId.hashCode;
  return mix.abs() % total;
}

/// The prompt and choices [spot] is showing today.
({String prompt, List<TownChoice> choices}) townEncounterFor(
  TownSpot spot, {
  DateTime? now,
}) {
  final extras = kTownScenarios[spot.id] ?? const <TownScenario>[];
  final index = townScenarioIndexFor(
    spot.id,
    now: now,
    extraCount: extras.length,
  );
  if (index == 0) {
    return (prompt: spot.prompt, choices: spot.choices);
  }
  final scenario = extras[index - 1];
  return (prompt: scenario.prompt, choices: scenario.choices);
}
