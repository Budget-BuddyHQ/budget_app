import 'package:flutter/foundation.dart';

/// Depth and citations layered on top of the Academy's lesson library.
///
/// **Why this is a separate file rather than edits in place.** The lesson
/// library is a 1,700-line `const` map inside the detail screen. Two things
/// were asked of it — every lesson should carry a real, checkable source, and
/// the lessons themselves are too short — and doing either by editing 53
/// entries in a screen file produces an unreviewable diff and grows a file
/// that is already too big. Keyed side-tables merge at render time instead, so
/// the content edits live in one place and read as content.
///
/// **The rule this file exists to enforce:** *every lesson is sourced.* An app
/// that teaches money to children is making claims, and a learner or a parent
/// is entitled to ask "says who?". `test/lesson_sources_test.dart` fails the
/// build if any lesson has no citation, if a citation points at an id that
/// does not exist, or if a source is not on the trusted-publisher list.

/// One extra passage appended to a lesson.
@immutable
class DeepDive {
  const DeepDive({required this.title, required this.content});

  final String title;
  final String content;
}

/// Extra sections appended after a lesson's own, in order.
///
/// These are written to add the thing the short version leaves out: a number,
/// a mechanism, or the sentence that tells you what to actually do. A lesson
/// that says "compound interest is powerful" and stops has taught a slogan.
const Map<String, List<DeepDive>> kLessonDeepDives = <String, List<DeepDive>>{
  // ---------------- Unit 1 · Money Is Real (ages 4-6) ----------------
  'lesson_46': [
    DeepDive(
      title: 'Money only works because everyone agrees',
      content:
          'A dollar bill is a piece of paper. It buys things because '
          'everyone agrees it is worth a dollar. That agreement is what '
          'money is — not the paper. People have used shells, salt and '
          'beads the same way.',
    ),
    DeepDive(
      title: 'Coins and bills are for the same job',
      content:
          'A hundred pennies and one dollar bill are worth exactly the '
          'same. Bigger coins are not always worth more — a dime is '
          'smaller than a nickel and worth twice as much. The number on '
          'it is what counts, not the size.',
    ),
  ],
  'lesson_47': [
    DeepDive(
      title: 'The price is not the same everywhere',
      content:
          'The same toy can cost different amounts in different shops. '
          'That is why grown-ups sometimes check two places before they '
          'buy. Checking is not being difficult — it is how you keep the '
          'extra money.',
    ),
    DeepDive(
      title: 'When you cannot buy both',
      content:
          'If you have five dollars and two things cost five dollars '
          'each, you can only take one home. That feeling — picking one '
          'and putting the other back — is what grown-ups call a budget.',
    ),
  ],
  'lesson_48': [
    DeepDive(
      title: 'Saving is just "not yet"',
      content:
          'Money in a piggy bank is not gone. It is waiting. Every time '
          'you put a coin in instead of spending it, you are moving a '
          'small treat now into a bigger one later.',
    ),
    DeepDive(
      title: 'Give it a name',
      content:
          'A jar labelled "bike" fills up faster than a jar labelled '
          '"saving". Naming the goal turns every coin into progress you '
          'can see, which is the whole trick behind the jar on the Daily '
          'tab of this app.',
    ),
  ],

  // ---------------- Unit 2 · Saving and Spending ----------------
  'lesson_49': [
    DeepDive(
      title: 'Earning means someone valued your work',
      content:
          'An allowance for chores, a paid job at fourteen, a salary at '
          'thirty — all the same shape. Someone wanted something done and '
          'traded money for it. The number changes; the deal does not.',
    ),
    DeepDive(
      title: 'Money you earn feels different',
      content:
          'People are measurably more careful with money they earned than '
          'with money they were given. That is worth knowing about '
          'yourself before you have a paycheck.',
    ),
  ],
  'lesson_50': [
    DeepDive(
      title: 'The test that actually works',
      content:
          'A need is something that goes wrong if you skip it: food, a '
          'roof, getting to school, medicine. A want is everything else — '
          'and wants are allowed. The point is not to have no wants, it is '
          'to know which is which before you spend.',
    ),
    DeepDive(
      title: 'Needs can hide inside wants',
      content:
          'You need shoes. You do not need those shoes. Most spending '
          'traps live in that gap, which is why the app has a whole unit '
          'about it later ("Wants Wearing a Needs Costume").',
    ),
  ],
  'lesson_51': [
    DeepDive(
      title: 'Three jars beat one',
      content:
          'Spend, save, give. Splitting money the moment it arrives — '
          'rather than at the end, out of whatever is left — is the same '
          'idea adults call "pay yourself first". Starting it with three '
          'jars at eight years old is the easiest version there is.',
    ),
  ],
  'lesson_52': [
    DeepDive(
      title: 'Why a bank is safer than a drawer',
      content:
          'Money in a US bank account is insured by the FDIC up to '
          '250,000 dollars per depositor, per bank, per ownership '
          'category. If the bank fails, that money is still yours. A '
          'drawer offers no such promise.',
    ),
    DeepDive(
      title: 'Banks pay you to keep it there',
      content:
          'A savings account pays interest — a small amount of money for '
          'letting the bank hold yours. It is the first time most people '
          'earn money without doing any work for it.',
    ),
  ],

  // ---------------- Unit 3 · Budgeting ----------------
  'lesson_1': [
    DeepDive(
      title: 'Why 50/30/20 and not some other split',
      content:
          'It is a starting point, not a law. Fifty percent to needs, '
          'thirty to wants, twenty to savings and debt payoff. Its value '
          'is that it is simple enough to actually use — a budget with '
          'nineteen categories is a budget you abandon in March.',
    ),
    DeepDive(
      title: 'Adjust the split, keep the habit',
      content:
          'If rent eats sixty percent where you live, the answer is not to '
          'give up on budgeting — it is 60/20/20, deliberately. What '
          'matters is that every dollar has a job before it arrives.',
    ),
  ],
  'lesson_2': [
    DeepDive(
      title: 'Gross is not what you get',
      content:
          'A job advertised at 3,000 dollars a month does not put 3,000 in '
          'your account. Federal income tax, Social Security at 6.2 '
          'percent and Medicare at 1.45 percent come out first, along with '
          'state tax in most states. Budget from take-home, never from the '
          'headline.',
    ),
    DeepDive(
      title: 'Irregular income needs a different rule',
      content:
          'If your income varies — tips, shifts, freelance — budget from '
          'your *lowest* recent month rather than your average. The months '
          'above it become savings instead of surprises.',
    ),
  ],
  'lesson_3': [
    DeepDive(
      title: 'Fixed, variable, and the one people forget',
      content:
          'Fixed costs are the same every month (rent, phone). Variable '
          'costs move (food, fuel). The third kind is periodic: insurance, '
          'car registration, holidays — big, predictable, and not monthly, '
          'which is exactly why they wreck budgets.',
    ),
    DeepDive(
      title: 'Track for one month before you cut anything',
      content:
          'Almost nobody guesses their own spending accurately. Thirty '
          'days of writing it down beats any amount of estimating, and it '
          'is usually the subscriptions and the small food purchases that '
          'surprise people.',
    ),
  ],
  'lesson_4': [
    DeepDive(
      title: 'Rate matters less than habit at the start',
      content:
          'On 500 dollars, the difference between a 0.5 percent and a 4 '
          'percent savings account is about 18 dollars a year. On 50,000 '
          'it is 1,750. Chase the rate once the balance is large; until '
          'then, the amount you put in is the whole game.',
    ),
  ],
  'lesson_savings_goal': [
    DeepDive(
      title: 'A goal without a date is a wish',
      content:
          'Write the amount, the date and the weekly number: "600 dollars '
          'by June, so 25 a week." Now every week has a pass/fail you can '
          'see, which is what turns a goal into something you can '
          'actually stick to.',
    ),
  ],
  'lesson_5': [
    DeepDive(
      title: 'Build it on last month, not on hope',
      content:
          'A budget made of what you *wish* you spent fails in week two. '
          'Start from what you actually spent last month, then change one '
          'category at a time.',
    ),
    DeepDive(
      title: 'A budget you review is a budget that survives',
      content:
          'Fifteen minutes, same day each month. Not to feel bad about '
          'overspending — to move the numbers so next month is right. '
          'Budgets are drafts.',
    ),
  ],

  // ---------------- Unit 4 · Spending Traps ----------------
  'lesson_31': [
    DeepDive(
      title: 'The upgrade trick',
      content:
          'You need a phone. You do not need the newest phone. Sellers '
          'attach a genuine need to an expensive version of it, and the '
          'need makes the price feel already-decided. Separate the two '
          'questions: do I need this thing, and do I need this version.',
    ),
  ],
  'lesson_32': [
    DeepDive(
      title: 'Ads are aimed, not broadcast',
      content:
          'Online ads are chosen for you from what you have watched, '
          'searched and bought. When an ad feels uncannily well-timed, '
          'that is not luck — it is the product working. Knowing that is '
          'most of the defence.',
    ),
    DeepDive(
      title: 'Sponsored is an ad with a friend’s face',
      content:
          'A creator you like being paid to mention something is an '
          'advertisement. US rules require it to be disclosed, which is '
          'what "#ad", "sponsored" and "paid partnership" mean. Look for '
          'the label before you take the recommendation.',
    ),
  ],
  'lesson_33': [
    DeepDive(
      title: 'Two currencies, one wallet',
      content:
          'Games sell you gems, then price items in gems. The second '
          'currency exists so you stop converting to real money in your '
          'head. Do the conversion anyway: it is the only way to know what '
          'you just spent.',
    ),
    DeepDive(
      title: 'Loot boxes are priced like gambling',
      content:
          'A random reward for a fixed price has the same shape as a slot '
          'machine, including the part where the near-misses keep you '
          'going. Several countries regulate them for exactly that reason.',
    ),
  ],
  'lesson_34': [
    DeepDive(
      title: 'Why a day works',
      content:
          'Urgency is manufactured — countdown timers, "only 3 left", '
          'limited drops. Waiting 24 hours does not cost you anything real '
          'and removes the pressure the seller added. Most wants do not '
          'survive the wait, and the ones that do were worth buying.',
    ),
  ],
  'lesson_35': [
    DeepDive(
      title: 'The four signs, every time',
      content:
          'Scammers pretend to be an organisation you know; say there is a '
          'problem or a prize; pressure you to act immediately; and tell '
          'you to pay in a specific, hard-to-reverse way — gift cards, '
          'wire transfer, crypto. Any one of those four is a reason to '
          'stop.',
    ),
    DeepDive(
      title: 'Real organisations never do this',
      content:
          'No government agency, bank or game company will ask for a gift '
          'card, a password, or a code from your text messages. If '
          'someone does, it is a scam — no exceptions worth learning.',
    ),
  ],

  // ---------------- Unit 5 · Saving Systems ----------------
  'lesson_11': [
    DeepDive(
      title: 'Automatic beats disciplined',
      content:
          'A transfer scheduled for payday moves the money before you can '
          'decide otherwise. This is not a trick on yourself so much as an '
          'admission that willpower is a bad thing to build a system on.',
    ),
  ],
  'lesson_12': [
    DeepDive(
      title: 'A sinking fund is a bill you pay early',
      content:
          'A 600-dollar insurance payment due in six months is 100 dollars '
          'a month starting now. Nothing about the cost changes. What '
          'changes is that it stops arriving as a crisis.',
    ),
  ],
  'lesson_13': [
    DeepDive(
      title: 'What to actually compare',
      content:
          'APY (not "interest rate" — APY includes compounding), monthly '
          'fees, minimum balance, and how long a transfer takes to arrive. '
          'A headline rate with a 12-dollar monthly fee is worse than a '
          'lower rate with none until your balance is fairly large.',
    ),
    DeepDive(
      title: 'Check that it is insured',
      content:
          'Look for FDIC (banks) or NCUA (credit unions). Both cover '
          '250,000 dollars per depositor, per institution, per ownership '
          'category. Apps that are not banks sometimes pass your money '
          'through to one — worth checking which.',
    ),
  ],
  'lesson_14': [
    DeepDive(
      title: 'Automate the boring parts only',
      content:
          'Automate saving and fixed bills. Do not automate the variable '
          'spending you are trying to control — the point of automation is '
          'to remove decisions you already made, not to hide decisions you '
          'still need to make.',
    ),
  ],
  'lesson_15': [
    DeepDive(
      title: 'The list is short and it is the same for everyone',
      content:
          'Car repair, medical bill, phone replacement, travel for a '
          'family event, a gap between jobs. Write your own version once. '
          'It stops being an emergency the moment it is on a list with a '
          'number next to it.',
    ),
  ],

  // ---------------- Unit 6 · Money by the Numbers ----------------
  'lesson_36': [
    DeepDive(
      title: 'The three you will use forever',
      content:
          'Percent of a number (20 percent of 60 is 12), percent change '
          '(from 50 to 60 is +20 percent), and percentage points (a rate '
          'going 4 to 6 is two points, not "two percent"). Almost every '
          'money argument that goes wrong goes wrong on the third one.',
    ),
    DeepDive(
      title: 'Percent-off is not percent-back',
      content:
          'A price cut 20 percent then raised 20 percent does not return '
          'to where it started: 100 becomes 80 becomes 96. The second '
          'percentage is taken from a smaller number.',
    ),
  ],
  'lesson_37': [
    DeepDive(
      title: 'When a mean lies to you',
      content:
          'Average salary at a company where one founder earns ten million '
          'is meaningless. The median — the middle person — describes the '
          'typical case. Whenever a number is about people and money, ask '
          'which one you are being shown.',
    ),
  ],
  'lesson_38': [
    DeepDive(
      title: 'Read the axes first',
      content:
          'Before the line, read the time span and what the vertical axis '
          'starts at. A chart of one day and a chart of ten years tell '
          'completely different stories about the same investment.',
    ),
  ],
  'lesson_39': [
    DeepDive(
      title: 'The truncated axis',
      content:
          'A vertical axis that starts at 98 instead of 0 turns a 2 '
          'percent wobble into a mountain. It is the single most common '
          'way an honest number becomes a misleading picture.',
    ),
    DeepDive(
      title: 'Cherry-picked start dates',
      content:
          '"Up 80 percent!" is a claim about a start date as much as about '
          'a price. Ask what happens to the number if the chart starts a '
          'year earlier.',
    ),
  ],
  'lesson_40': [
    DeepDive(
      title: 'Categories beat receipts',
      content:
          'You do not need every transaction. Five or six categories, '
          'totalled weekly, tells you everything a spreadsheet of 400 rows '
          'does — and you will still be doing it in three months.',
    ),
  ],

  // ---------------- Unit 7 · Credit ----------------
  'lesson_6': [
    DeepDive(
      title: 'What a credit score is actually made of',
      content:
          'Payment history is the largest single factor, followed by how '
          'much of your available credit you are using. Length of history, '
          'the mix of account types and recent applications make up the '
          'rest. Nothing on that list is "how much money you have" — a '
          'score measures how you handle borrowing, not wealth.',
    ),
    DeepDive(
      title: 'The minimum payment is the trap',
      content:
          'Paying only the minimum on a card is how a 1,000-dollar balance '
          'at 24 percent APR takes years to clear and costs more in '
          'interest than the original purchase. Card statements are '
          'required to show you that comparison — read that box.',
    ),
    DeepDive(
      title: 'You are entitled to your report for free',
      content:
          'AnnualCreditReport.com is the federally authorised site for '
          'free reports from the three nationwide bureaus. Checking your '
          'own report never lowers your score, and errors on it are '
          'common enough to be worth looking for.',
    ),
  ],
  'lesson_7': [
    DeepDive(
      title: 'Investing is not saving, and that is the point',
      content:
          'Savings keep their value and are there when you need them. '
          'Investments can fall, and are expected to grow more over long '
          'periods because of that risk. Money you need within about five '
          'years does not belong in the market.',
    ),
  ],
  'lesson_8': [
    DeepDive(
      title: 'Checking, savings, and why both',
      content:
          'A checking account is for money moving through — bills, card '
          'payments. A savings account is for money standing still, and '
          'pays interest for it. Keeping them separate is what stops '
          'savings quietly becoming spending.',
    ),
    DeepDive(
      title: 'Overdraft is a loan you did not ask for',
      content:
          'Overdraft coverage lets a payment go through when the balance '
          'is short — and charges a flat fee, often around 35 dollars, '
          'which can be more than the purchase. In the US you have to opt '
          'in for debit-card overdraft, and you can opt out.',
    ),
  ],
  'lesson_9': [
    DeepDive(
      title: 'Three to six months, but start with one',
      content:
          'The standard advice is three to six months of essential '
          'expenses. That number is paralysing at the start, so aim for '
          'one month first, then one more. Most financial emergencies are '
          'smaller than a month of expenses.',
    ),
  ],
  'lesson_10': [
    DeepDive(
      title: 'Goals need a horizon, not just an amount',
      content:
          'Short (under two years) belongs in savings. Medium (two to '
          'five) in something conservative. Long (five plus) is where '
          'investing earns its risk. Sorting goals by *when* is what tells '
          'you where the money should sit.',
    ),
  ],

  // ---------------- Unit 8 · Real-World Money Moves ----------------
  'lesson_21': [
    DeepDive(
      title: 'The lines that are always there',
      content:
          'Gross pay, federal income tax withheld, Social Security (6.2 '
          'percent of wages up to an annual cap), Medicare (1.45 percent '
          'with no cap), usually state tax, then net pay. Anything else — '
          'insurance, retirement — is a deduction you chose.',
    ),
    DeepDive(
      title: 'Check it, because payroll makes mistakes',
      content:
          'Hours, rate, overtime and your withholding elections are all '
          'worth checking on the first stub of a new job and after any '
          'raise. An error caught in month one is a conversation; caught '
          'in month nine it is a repayment.',
    ),
  ],
  'lesson_22': [
    DeepDive(
      title: 'Salary is only part of the offer',
      content:
          'An employer match on retirement contributions, health cover, '
          'paid leave and commuting cost can be worth thousands. A job '
          'paying 2,000 less with a 5 percent match on a 45,000 salary is '
          'ahead within a year.',
    ),
  ],
  'lesson_23': [
    DeepDive(
      title: 'Rent is not the cost of renting',
      content:
          'Add utilities, internet, renters insurance, deposit, and the '
          'cost of getting to work from that address. Two apartments with '
          'the same rent routinely differ by hundreds a month once those '
          'are counted.',
    ),
    DeepDive(
      title: 'The 30 percent guideline and its limits',
      content:
          'Keeping housing under about 30 percent of gross income is a '
          'common rule of thumb. In expensive cities it is often not '
          'achievable, and the honest response is to plan for the real '
          'number rather than to pretend the rule was met.',
    ),
  ],
  'lesson_24': [
    DeepDive(
      title: 'Withholding is an estimate, not the bill',
      content:
          'Tax is withheld from every paycheck as a guess at your annual '
          'liability. Filing a return reconciles the guess — a refund '
          'means you over-paid all year, which is not free money, it is '
          'your money returned without interest.',
    ),
    DeepDive(
      title: 'Marginal rates only apply to the top slice',
      content:
          'Moving into a higher tax bracket does not tax all your income '
          'at the higher rate — only the part above the threshold. "A '
          'raise pushed me into a higher bracket so I earn less" is not '
          'how the system works.',
    ),
  ],
  'lesson_25': [
    DeepDive(
      title: 'One page, reviewed quarterly',
      content:
          'Income, fixed costs, savings targets, debts with rates, and '
          'the next three goals. A plan longer than a page does not get '
          'read, and a plan that never gets read is a document rather than '
          'a plan.',
    ),
  ],

  // ---------------- Unit 9 · Investing Basics ----------------
  'lesson_16': [
    DeepDive(
      title: 'Inflation is why cash alone loses',
      content:
          'If prices rise about 3 percent a year, money under a mattress '
          'buys about 26 percent less after ten years. Investing is not '
          'about getting rich quickly — for most people it is about not '
          'going quietly backwards.',
    ),
  ],
  'lesson_17': [
    DeepDive(
      title: 'Diversification is the one free lunch',
      content:
          'Holding many unrelated investments lowers the damage any single '
          'one can do without lowering expected return in proportion. It '
          'is the rare case in finance where you get something for '
          'nothing.',
    ),
    DeepDive(
      title: 'Your employer is already a concentrated bet',
      content:
          'Holding a lot of your own company stock means your job and '
          'your savings depend on the same company. When it goes wrong it '
          'goes wrong in both places at once.',
    ),
  ],
  'lesson_18': [
    DeepDive(
      title: 'Three things, three jobs',
      content:
          'A stock is part-ownership of a company. A bond is a loan to a '
          'government or company that pays interest. A fund holds many of '
          'either, so one purchase buys a spread.',
    ),
  ],
  'lesson_19': [
    DeepDive(
      title: 'The arithmetic that makes it worth it',
      content:
          '200 dollars a month for 40 years at 7 percent is about 96,000 '
          'contributed and roughly half a million at the end. The gap '
          'between those two numbers is compounding, and almost all of it '
          'happens in the final decade.',
    ),
    DeepDive(
      title: 'Compounding works against you too',
      content:
          'Credit card interest compounds on the same maths. At 24 percent '
          'APR a balance you never add to still grows — which is why '
          'paying down high-rate debt is a guaranteed return no investment '
          'can promise.',
    ),
  ],
  'lesson_20': [
    DeepDive(
      title: 'Time in the market, not timing the market',
      content:
          'Missing a handful of the best days in a decade removes a large '
          'share of the total return, and those days cluster right next to '
          'the worst ones. Selling during a fall is how people miss both.',
    ),
  ],

  // ---------------- Unit 10 · Stocks and Trading ----------------
  'lesson_26': [
    DeepDive(
      title: 'A share is a claim, not a ticket',
      content:
          'Owning a share makes you a part-owner with a claim on the '
          'company\'s future profits — and usually a vote. The price moves '
          'because expectations about those profits move, not because the '
          'ticker is popular.',
    ),
  ],
  'lesson_27': [
    DeepDive(
      title: 'Price is agreement, not value',
      content:
          'A quoted price is simply what a buyer and a seller last agreed '
          'on. It changes when expectations change — earnings, rates, '
          'news, or nothing anyone can name.',
    ),
  ],
  'lesson_28': [
    DeepDive(
      title: 'Why an index fund is the default answer',
      content:
          'It buys a whole market in one purchase, at very low cost, with '
          'no need to pick winners. Most professional active funds fail to '
          'beat their index over long periods after fees.',
    ),
  ],
  'lesson_29': [
    DeepDive(
      title: 'The spread is a cost with no line item',
      content:
          'Buy at the ask, sell at the bid; the gap between them is what '
          'the trade cost you before any commission. On thinly traded '
          'things that gap can be larger than any fee you were shown.',
    ),
    DeepDive(
      title: 'One percent, forty years',
      content:
          'A 1 percent annual fee sounds small and removes roughly a '
          'quarter of a portfolio\'s final value over a working lifetime. '
          'Fees are the one part of investing you can control exactly.',
    ),
  ],
  'lesson_30': [
    DeepDive(
      title: 'Boring is a strategy',
      content:
          'Regular contributions to a diversified, low-cost fund, left '
          'alone through falls, is the approach with the most evidence '
          'behind it. It is unexciting on purpose — excitement in a '
          'portfolio is usually risk you did not price.',
    ),
  ],

  // ---------------- Unit 11 · Retirement and the 401(k) ----------------
  'lesson_41': [
    DeepDive(
      title: 'The tax break is the whole point',
      content:
          'Retirement accounts trade a rule — you cannot touch it until '
          'about 59 and a half without a penalty — for tax treatment you '
          'cannot get anywhere else. The lock is what pays for the '
          'advantage.',
    ),
  ],
  'lesson_42': [
    DeepDive(
      title: 'A match is an instant, guaranteed return',
      content:
          'If an employer matches 100 percent of the first 5 percent you '
          'contribute, every dollar you put in up to that point becomes '
          'two. No investment offers a certain 100 percent return; '
          'contributing less than the match is leaving pay behind.',
    ),
  ],
  'lesson_43': [
    DeepDive(
      title: 'Pay tax now or pay it later',
      content:
          'Traditional contributions reduce your taxable income today and '
          'are taxed on withdrawal. Roth contributions are made from '
          'taxed income and come out tax-free. The choice turns on '
          'whether your tax rate is likely higher now or later — which is '
          'why Roth often suits someone early in their career.',
    ),
  ],
  'lesson_44': [
    DeepDive(
      title: 'Ten years of head start beats thirty of catching up',
      content:
          'Someone investing from 25 to 35 and then stopping usually ends '
          'up ahead of someone who starts at 35 and contributes until 65, '
          'at the same rate. The early money has the most time to '
          'compound, and time cannot be bought back later.',
    ),
  ],
  'lesson_45': [
    DeepDive(
      title: 'Vesting decides what is actually yours',
      content:
          'Your own contributions are always yours. The employer\'s match '
          'may vest over several years, so leaving early can forfeit part '
          'of it. Worth knowing the schedule before timing a job change.',
    ),
    DeepDive(
      title: 'Do not cash it out when you leave',
      content:
          'Rolling an old plan into a new one or into an IRA keeps the tax '
          'treatment. Cashing out triggers income tax and usually a 10 '
          'percent early-withdrawal penalty — and removes the decades of '
          'compounding that were the point.',
    ),
  ],

  // ------------------- Unit 12 · Big Purchases -------------------
  'lesson_53': [
    DeepDive(
      title: 'Work it out per year, not per purchase',
      content:
          'Insurance, fuel, servicing, tyres, tax and the odd repair are '
          'the yearly figure that decides whether a car fits your budget. '
          'A cheap car with expensive insurance can cost more per year '
          'than a pricier one with cheap everything.',
    ),
    DeepDive(
      title: 'The repair fund is part of owning a car',
      content:
          'Older cars are cheaper to buy and more likely to need work. '
          'That is a fair trade only if the money for the work exists. '
          'Setting aside a fixed amount monthly turns a breakdown from a '
          'crisis into an errand.',
    ),
  ],
  'lesson_54': [
    DeepDive(
      title: 'Multiply before you sign',
      content:
          'Payment times term is the total you will hand over. Compare '
          'that to the price of the car. The gap is what borrowing cost '
          'you, and seeing it as one number is what makes a long term '
          'feel as expensive as it is.',
    ),
    DeepDive(
      title: 'Owing more than it is worth',
      content:
          'A long loan on a fast-depreciating car can leave you owing '
          'more than the car would sell for. That matters the moment you '
          'need to sell or the car is written off, because the loan does '
          'not disappear with the vehicle.',
    ),
  ],
  'lesson_55': [
    DeepDive(
      title: 'Read the ending, not the kitchen',
      content:
          'Notice period, what happens if you leave early, who fixes '
          'what, and the conditions for getting the deposit back. Those '
          'clauses decide what the year actually costs you; the worktops '
          'do not.',
    ),
    DeepDive(
      title: 'Your credit file shows up here first',
      content:
          'For many people a rental application is the first time a thin '
          'or damaged credit file has a visible cost — a larger deposit, '
          'a guarantor, or a rejection. It is a good reason to have '
          'looked at your report before you need it.',
    ),
  ],
  'lesson_56': [
    DeepDive(
      title: 'The list nobody budgets for',
      content:
          'A flat rarely comes with a bed, curtains, cookware, a bin, or '
          'a shower curtain. None of it is expensive alone and all of it '
          'lands in the same week. Writing the list before you move turns '
          'a surprise into a plan.',
    ),
  ],
  'lesson_57': [
    DeepDive(
      title: 'Waiting has a return',
      content:
          'Six months of saving can move you from financing at a high '
          'rate to paying outright, or from a shaky car to a reliable '
          'one. That is a real return on doing nothing, and it is the '
          'option nobody in a showroom will raise.',
    ),
  ],

  // --------------- Unit 13 · Protecting Your Money ---------------
  'lesson_58': [
    DeepDive(
      title: 'Why speed matters',
      content:
          'The damage from a stolen identity compounds: one opened '
          'account becomes several, and each takes its own paperwork to '
          'unwind. Reporting early is less about catching anyone than '
          'about limiting how much there is to fix.',
    ),
    DeepDive(
      title: 'The affidavit is the useful part',
      content:
          'Banks and bureaus want a formal statement, not a phone call. '
          'IdentityTheft.gov produces exactly that document alongside a '
          'checklist, which is why it is the first stop rather than the '
          'bank.',
    ),
  ],
  'lesson_59': [
    DeepDive(
      title: 'Freeze versus fraud alert',
      content:
          'A fraud alert asks lenders to take extra care and is easy to '
          'set. A freeze blocks access to the file outright and is '
          'stronger. A freeze is the better default; an alert is what you '
          'use when you need the file reachable.',
    ),
    DeepDive(
      title: 'It does not hurt your score',
      content:
          'A freeze restricts who can see the file. It does not change '
          'what is in it, and it is not a negative mark. The common worry '
          'that freezing looks bad to lenders is simply not how it works.',
    ),
  ],
  'lesson_60': [
    DeepDive(
      title: 'Stagger them',
      content:
          'Because there are three bureaus, requesting from a different '
          'one every few months gives you a look at your file several '
          'times a year rather than all at once — the cheapest fraud '
          'monitoring available.',
    ),
  ],
  'lesson_61': [
    DeepDive(
      title: 'A flat fee on a small purchase is a huge rate',
      content:
          'Think of an overdraft fee as the price of a very short loan. '
          'A fixed charge to cover a few dollars for a few days works out '
          'at a rate no credit card would be allowed to advertise.',
    ),
  ],
  'lesson_62': [
    DeepDive(
      title: 'Write it down as you go',
      content:
          'Date, who you spoke to, what they promised. It takes seconds '
          'and it is the difference between a complaint that resolves and '
          'one that becomes your word against a call centre\'s.',
    ),
    DeepDive(
      title: 'Ask a collector to validate',
      content:
          'Debts are sold on, often with incomplete records, and '
          'collectors sometimes pursue the wrong person or an amount that '
          'is wrong. Requesting validation before paying is a normal '
          'step, not an admission of anything.',
    ),
  ],
};

/// Which sources back each lesson. See [kLessonSources] for the catalogue.
///
/// Every lesson id in the curriculum must appear here, and the test suite
/// enforces it. Quizzes and unit tests inherit their unit's sources, so they
/// are not listed separately.
const Map<String, List<String>> kLessonCitations = <String, List<String>>{
  // Unit 1 · Money Is Real
  'lesson_46': ['fed_currency', 'treasury_currency', 'cfpb_money_as_you_grow'],
  'lesson_47': ['cfpb_money_as_you_grow', 'mymoney_home'],
  'lesson_48': ['cfpb_money_as_you_grow', 'fdic_insurance'],

  // Unit 2 · Saving and Spending
  'lesson_49': ['cfpb_money_as_you_grow', 'dol_minimum_wage'],
  'lesson_50': ['cfpb_budget', 'mymoney_home'],
  'lesson_51': ['cfpb_money_as_you_grow', 'cfpb_budget'],
  'lesson_52': ['fdic_insurance', 'cfpb_savings'],

  // Unit 3 · Budgeting
  'lesson_1': ['cfpb_budget', 'mymoney_home'],
  'lesson_2': ['irs_withholding', 'bls_earnings'],
  'lesson_3': ['cfpb_budget', 'bls_cpi'],
  'lesson_4': ['cfpb_savings', 'investor_compound'],
  'lesson_savings_goal': ['cfpb_savings', 'cfpb_budget'],
  'lesson_5': ['cfpb_budget', 'mymoney_home'],

  // Unit 4 · Spending Traps
  'lesson_31': ['cfpb_budget', 'ftc_scams'],
  'lesson_32': ['ftc_scams', 'usa_gov_money'],
  'lesson_33': ['ftc_scams', 'cfpb_complaints'],
  'lesson_34': ['cfpb_budget', 'ftc_scams'],
  'lesson_35': ['ftc_scams', 'ftc_identity_theft'],

  // Unit 5 · Saving Systems
  'lesson_11': ['cfpb_savings', 'mymoney_home'],
  'lesson_12': ['cfpb_emergency_fund', 'cfpb_budget'],
  'lesson_13': [
    'fdic_insurance',
    'cfpb_savings',
    'treasurydirect_savings_bonds',
  ],
  'lesson_14': ['cfpb_savings', 'cfpb_budget'],
  'lesson_15': ['cfpb_emergency_fund', 'usa_gov_money'],

  // Unit 6 · Money by the Numbers
  'lesson_36': ['bls_cpi', 'investor_compound'],
  'lesson_37': ['bls_earnings', 'bls_cpi'],
  'lesson_38': ['investor_home', 'sec_index_funds'],
  'lesson_39': ['investor_home', 'sec_index_funds'],
  'lesson_40': ['cfpb_budget', 'mymoney_home'],

  // Unit 7 · Credit
  'lesson_6': [
    'cfpb_credit_reports',
    'cfpb_credit_cards',
    'annualcreditreport',
    'cfpb_debt_collection',
    'ftc_credit',
  ],
  'lesson_7': ['investor_home', 'investor_diversification'],
  'lesson_8': ['fdic_insurance', 'cfpb_savings', 'cfpb_overdraft'],
  'lesson_9': ['cfpb_emergency_fund', 'usa_gov_money'],
  'lesson_10': ['investor_compound', 'ssa_retirement'],

  // Unit 8 · Real-World Money Moves
  'lesson_21': ['irs_withholding', 'ssa_taxes'],
  'lesson_22': ['bls_earnings', 'dol_401k'],
  'lesson_23': ['cfpb_renting', 'bls_cpi', 'cfpb_auto_loans'],
  'lesson_24': ['irs_withholding', 'irs_understanding_taxes'],
  'lesson_25': ['cfpb_budget', 'studentaid_home', 'studentaid_loans'],

  // Unit 9 · Investing Basics
  'lesson_16': ['investor_home', 'investor_compound'],
  'lesson_17': ['investor_diversification', 'investor_risk'],
  'lesson_18': ['sec_index_funds', 'investor_home'],
  'lesson_19': ['investor_compound', 'investor_home'],
  'lesson_20': ['investor_risk', 'sec_index_funds'],

  // Unit 10 · Stocks and Trading
  'lesson_26': ['investor_home', 'sec_index_funds'],
  'lesson_27': ['investor_home', 'investor_risk'],
  'lesson_28': ['investor_diversification', 'sec_index_funds'],
  'lesson_29': ['investor_fees', 'sec_index_funds'],
  'lesson_30': ['investor_compound', 'investor_risk'],

  // Unit 11 · Retirement and the 401(k)
  'lesson_41': ['irs_retirement_plans', 'ssa_retirement'],
  'lesson_42': ['dol_401k', 'irs_retirement_plans'],
  'lesson_43': ['irs_retirement_plans', 'investor_home'],
  'lesson_44': ['investor_compound', 'irs_retirement_plans'],
  'lesson_45': ['dol_401k', 'investor_fees'],

  // Unit 12 · Big Purchases
  'lesson_53': ['cfpb_auto_loans', 'usa_gov_money'],
  'lesson_54': ['cfpb_auto_loans', 'cfpb_credit_cards'],
  'lesson_55': ['cfpb_renting', 'cfpb_credit_reports'],
  'lesson_56': ['cfpb_renting', 'cfpb_budget'],
  'lesson_57': ['cfpb_auto_loans', 'cfpb_savings'],

  // Unit 13 · Protecting Your Money
  'lesson_58': ['identitytheft_gov', 'ftc_identity_theft'],
  'lesson_59': ['ftc_identity_theft', 'cfpb_credit_reports'],
  'lesson_60': ['annualcreditreport', 'cfpb_credit_reports'],
  'lesson_61': ['cfpb_overdraft', 'usa_gov_money'],
  'lesson_62': ['cfpb_complaints', 'cfpb_debt_collection'],
};

/// Which sources back each quiz **skill**.
///
/// Keyed by skill rather than by question on purpose. There are 161 questions
/// and 40-odd skills, and a citation per question would be 161 places for a
/// dead URL to hide — while the honest answer is the same for all of them:
/// every question about credit is answered by the same CFPB pages that back
/// the credit lessons. Grouping by skill keeps one source of truth for one
/// topic, which is also what makes it maintainable.
///
/// `test/lesson_sources_test.dart` requires that every skill a live question
/// uses appears here, so adding a question in a new topic area forces the
/// question's author to say where the answer comes from.
const Map<String, List<String>> kQuizSkillSources = <String, List<String>>{
  // Unit 3 · Budgeting
  'budget_basics': ['cfpb_budget', 'mymoney_home'],
  'income': ['irs_withholding', 'bls_earnings'],
  'expenses': ['cfpb_budget', 'bls_cpi'],
  'saving': ['cfpb_savings', 'investor_compound'],
  'budget_building': ['cfpb_budget', 'mymoney_home'],

  // Unit 7 · Credit and the wider toolkit
  'credit': ['cfpb_credit_reports', 'cfpb_credit_cards', 'annualcreditreport'],
  'investing_basics': ['investor_home', 'investor_diversification'],
  'banking': ['fdic_insurance', 'cfpb_overdraft'],
  'emergency_fund': ['cfpb_emergency_fund', 'usa_gov_money'],
  'goals': ['cfpb_savings', 'investor_compound'],

  // Unit 5 · Saving systems
  'pay_yourself_first': ['cfpb_savings', 'mymoney_home'],
  'sinking_funds': ['cfpb_emergency_fund', 'cfpb_budget'],
  'savings_accounts': ['fdic_insurance', 'treasurydirect_savings_bonds'],
  'automation': ['cfpb_savings', 'cfpb_budget'],
  'irregular_costs': ['cfpb_emergency_fund', 'cfpb_budget'],

  // Unit 9 · Investing basics
  'why_invest': ['investor_home', 'bls_cpi'],
  'risk': ['investor_risk', 'investor_diversification'],
  'asset_types': ['sec_index_funds', 'investor_home'],
  'compounding': ['investor_compound'],
  'investor_mindset': ['investor_risk', 'sec_index_funds'],

  // Unit 8 · Real-world money moves
  'pay_stub': ['irs_withholding', 'ssa_taxes'],
  'job_offers': ['bls_earnings', 'dol_401k'],
  'living_costs': ['cfpb_renting', 'cfpb_auto_loans'],
  'taxes': ['irs_understanding_taxes', 'irs_withholding'],
  'money_plan': ['cfpb_budget', 'studentaid_loans'],

  // Unit 10 · Stocks and trading
  'share_ownership': ['investor_home', 'sec_index_funds'],
  'price_movement': ['investor_home', 'investor_risk'],
  'diversification': ['investor_diversification', 'sec_index_funds'],
  'trading_costs': ['investor_fees', 'sec_index_funds'],
  'time_in_market': ['investor_compound', 'investor_risk'],

  // Unit 4 · Spending traps
  'wants_vs_needs': ['cfpb_budget', 'cfpb_money_as_you_grow'],
  'advertising': ['ftc_scams', 'usa_gov_money'],
  'digital_spending': ['ftc_scams', 'cfpb_complaints'],
  'impulse_control': ['cfpb_budget', 'ftc_scams'],
  'scams': ['ftc_scams', 'ftc_identity_theft'],

  // Unit 6 · Money by the numbers
  'percentages': ['bls_cpi', 'investor_compound'],
  'averages': ['bls_earnings', 'bls_cpi'],
  'chart_reading': ['investor_home', 'sec_index_funds'],
  'misleading_charts': ['investor_home', 'sec_index_funds'],
  'spending_tracking': ['cfpb_budget', 'mymoney_home'],

  // Unit 11 · Retirement
  'retirement_accounts': ['irs_retirement_plans', 'ssa_retirement'],
  'employer_match': ['dol_401k', 'irs_retirement_plans'],
  'roth_vs_traditional': ['irs_retirement_plans'],
  'starting_early': ['investor_compound', 'irs_retirement_plans'],
  'fees_vesting': ['dol_401k', 'investor_fees'],

  // Unit 1-2 · The youngest units
  'early_money_basics': ['cfpb_money_as_you_grow', 'fed_currency'],
  'allowance_earning': ['cfpb_money_as_you_grow', 'dol_minimum_wage'],
  'early_saving': ['cfpb_money_as_you_grow', 'fdic_insurance'],
  'simple_savings_plan': ['cfpb_money_as_you_grow', 'cfpb_budget'],

  // Credit, in the detail the question bank goes into
  'credit_score': ['cfpb_credit_reports', 'annualcreditreport'],
  'minimum_payments': ['cfpb_credit_cards', 'cfpb_debt_collection'],
  'interest_rates': ['cfpb_credit_cards', 'investor_compound'],

  // Unit 12 · Big Purchases
  'car_costs': ['cfpb_auto_loans', 'usa_gov_money'],
  'loan_offers': ['cfpb_auto_loans', 'cfpb_credit_cards'],
  'renting': ['cfpb_renting', 'cfpb_credit_reports'],
  'move_in_costs': ['cfpb_renting', 'cfpb_budget'],
  'buy_or_wait': ['cfpb_auto_loans', 'cfpb_savings'],

  // Unit 13 · Protecting Your Money
  'identity_theft': ['identitytheft_gov', 'ftc_identity_theft'],
  'credit_freeze': ['ftc_identity_theft', 'cfpb_credit_reports'],
  'credit_reports': ['annualcreditreport', 'cfpb_credit_reports'],
  'avoidable_fees': ['cfpb_overdraft', 'usa_gov_money'],
  'complaints': ['cfpb_complaints', 'cfpb_debt_collection'],
};
