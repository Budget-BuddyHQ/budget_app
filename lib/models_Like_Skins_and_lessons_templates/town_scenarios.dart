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
