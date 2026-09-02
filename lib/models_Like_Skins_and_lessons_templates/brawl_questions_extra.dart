/// Two more categories for Finance Brawl, and one shape of question the
/// original bank did not have.
///
/// **What was missing.** The 100-question bank covers budgeting, savings,
/// credit, investing and retirement — the topics a curriculum lists. The two
/// added here are the ones a *player* meets first and most often:
///
/// * **Earning and work.** A first payslip, a tax code, a shift that pays more
///   but costs more to get to. This is the money most under-21s actually
///   handle, and the original bank went almost straight from "what is a
///   budget" to "what is a 401(k)".
/// * **Scams, fees and fine print.** Subscription traps, overdraft charges,
///   phishing, unit pricing. Recognising these is the single highest-value
///   thing this app can teach a teenager, and it was the thinnest area.
///
/// **Distractors are real misconceptions, not jokes.** "The colour of the
/// card" teaches nothing; "the card with the highest limit" is a mistake
/// teenagers actually make, and a player who picks it has learned something
/// when the explanation lands.
///
/// **On answer position:** every correct answer here is written at index 0,
/// which would be a serious flaw in a bank the game read literally — an
/// earlier Academy bank had the answer at index 1 for 30 of 34 questions, so
/// "always pick B" scored 88 percent without learning anything. Finance Brawl
/// shuffles options per encounter (`ShuffledQuizQuestion` carries
/// `shuffledOptions` plus `correctOptionText` rather than an index), so
/// position in this file never reaches a player. Writing the answer first
/// keeps the source readable; `test/brawl_extra_questions_test.dart` asserts
/// the shuffle is what the player actually sees, so the day that changes the
/// build fails rather than the game quietly becoming guessable.
library;

/// A Finance Brawl item. Mirrors the shape the game already uses; kept here
/// as plain data so the bank can grow without the 3,800-line game file
/// growing with it.
class BrawlQuestion {
  const BrawlQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  /// Groups questions for the weighted draw and for citing sources — see
  /// `kQuizSkillSources` for the same idea in the Academy.
  final String category;
}

const String kBrawlCategoryEarning = 'earning_and_work';
const String kBrawlCategoryFinePrint = 'scams_fees_fine_print';

const List<BrawlQuestion> kBrawlExtraQuestions = <BrawlQuestion>[
  // ================= EARNING AND WORK =================
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'Your payslip shows gross pay of \$400 and net pay of \$332. '
        'Where did the \$68 go?',
    options: [
      'Withheld for taxes and payroll deductions',
      'A fee the employer charges for processing wages',
      'Held back until the end of the year as a bonus',
      'Lost to rounding on the hours worked',
    ],
    correctIndex: 0,
    explanation:
        'Federal income tax, Social Security at 6.2 percent and Medicare at '
        '1.45 percent come out of every paycheck, along with state tax in '
        'most states.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question: 'What does "gross pay" mean?',
    options: [
      'Pay before any taxes or deductions are taken out',
      'The money that actually lands in your bank account',
      'Overtime pay only',
      'Pay after tax but before insurance',
    ],
    correctIndex: 0,
    explanation:
        'Gross is the headline number; net is what reaches you. Budget from '
        'net — budgeting from gross is how people plan to spend money that '
        'was never going to arrive.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'Job A pays \$14/hour with no travel cost. Job B pays '
        '\$16/hour but costs \$6 a day to reach. On a 5-hour shift, which '
        'pays more?',
    options: [
      'Job B, by \$4',
      'Job A, by \$4',
      'They pay exactly the same',
      'Job B, by \$10',
    ],
    correctIndex: 0,
    explanation:
        'Job B is \$80 less \$6 travel, so \$74. Job A is \$70. The gap is '
        'much smaller than the hourly rates suggest, and on a short shift it '
        'flips entirely.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question: 'A raise moves you into a higher tax bracket. What happens?',
    options: [
      'Only the income above the threshold is taxed at the higher rate',
      'All of your income is now taxed at the higher rate',
      'You take home less money than before the raise',
      'The higher rate applies retroactively to last year',
    ],
    correctIndex: 0,
    explanation:
        'Brackets are marginal. A raise never leaves you worse off — "it '
        'pushed me into a higher bracket so I earn less" is not how the '
        'system works.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'Which of these is part of the value of a job offer besides '
        'salary?',
    options: [
      'An employer match on retirement contributions',
      'The colour of the uniform',
      'How the company logo looks',
      'The office postcode',
    ],
    correctIndex: 0,
    explanation:
        'A 5 percent match on a \$45,000 salary is \$2,250 a year. Health '
        'cover, paid leave and commuting cost belong in the comparison too.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question: 'What is a W-4 form used for in the US?',
    options: [
      'Telling your employer how much tax to withhold from your pay',
      'Filing your annual tax return',
      'Applying for unemployment benefits',
      'Opening a retirement account',
    ],
    correctIndex: 0,
    explanation:
        'The W-4 sets your withholding. Getting it wrong means either a large '
        'refund (you lent the government money for free) or a bill in April.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'You are paid \$15/hour and work 42 hours in a week that '
        'qualifies for overtime. What is typically true of hours 41 and 42?',
    options: [
      'They are usually paid at 1.5 times the normal rate',
      'They are unpaid',
      'They are paid at half the normal rate',
      'They roll over to next week',
    ],
    correctIndex: 0,
    explanation:
        'Under the Fair Labor Standards Act, non-exempt employees generally '
        'earn time-and-a-half beyond 40 hours in a week.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'Your income varies month to month from tips. What should you '
        'budget from?',
    options: [
      'Your lowest recent month',
      'Your best month ever',
      'Your average month',
      'Next month\'s hoped-for total',
    ],
    correctIndex: 0,
    explanation:
        'Budgeting from the floor means the good months become savings '
        'instead of surprises, and a bad month is not a crisis.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'What is the difference between an employee and an independent '
        'contractor for tax purposes?',
    options: [
      'Contractors usually have no tax withheld and owe it themselves',
      'Contractors pay no tax at all',
      'Employees must file quarterly, contractors annually',
      'There is no difference',
    ],
    correctIndex: 0,
    explanation:
        'A contractor\'s payment arrives whole, which feels like more money '
        'until the tax bill arrives. Setting a share aside as it comes in is '
        'the whole discipline.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question: 'Why is it worth checking your first pay stub carefully?',
    options: [
      'Payroll errors are common and easier to fix immediately',
      'It is legally required to check it',
      'The stub expires after a week',
      'It determines your credit score',
    ],
    correctIndex: 0,
    explanation:
        'An error caught in month one is a conversation. The same error '
        'caught in month nine is a repayment.',
  ),

  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'You are offered \$18/hour as a contractor or \$15/hour as an '
        'employee. What is the catch with the higher number?',
    options: [
      'A contractor pays both halves of Social Security and Medicare',
      'Contractors are paid less often than employees',
      'Contractor pay is taxed at double the normal rate',
      'There is no catch — \$18 is simply better',
    ],
    correctIndex: 0,
    explanation:
        'An employer normally pays half of the 15.3 percent Social Security '
        'and Medicare bill. A contractor pays all of it, plus their own '
        'insurance and unpaid time off — so the headline rate has to be '
        'noticeably higher to come out even.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'Your employer matches 50 percent of what you put into a '
        'retirement plan, up to 6 percent of your pay. You contribute '
        'nothing. What are you giving up?',
    options: [
      'A 50 percent return on the first 6 percent, before any investing',
      'Nothing — the match is only paid at retirement',
      'A small tax refund',
      'Access to the plan for the rest of your career',
    ],
    correctIndex: 0,
    explanation:
        'A match is the only place anyone reliably offers you 50 cents for a '
        'dollar. Contributing less than the match is turning down part of '
        'your own pay.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'Two offers: \$52,000 with no benefits, or \$47,000 with health '
        'cover worth \$5,400 a year. Which pays more?',
    options: [
      'The \$47,000 offer, once the benefit is counted',
      'The \$52,000 offer, because salary is what counts',
      'They are identical',
      'Impossible to compare',
    ],
    correctIndex: 0,
    explanation:
        '\$47,000 plus \$5,400 of cover is \$52,400 of value, and the cover is '
        'bought with untaxed money. Comparing salaries alone is how people '
        'take the worse of two offers.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'You are paid weekly and your rent is monthly. What catches '
        'people out?',
    options: [
      'Most months have four paydays, but four of them have five',
      'Weekly pay is taxed more heavily',
      'Rent must legally be paid on a payday',
      'Nothing — weekly and monthly always line up',
    ],
    correctIndex: 0,
    explanation:
        'Fifty-two weeks does not divide into twelve months. Budgeting as if '
        'every month has four paydays leaves four months a year short, and '
        'four with an unplanned surplus.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question: 'What is a W-4 for?',
    options: [
      'Telling your employer how much tax to withhold from each paycheck',
      'Reporting your income to the IRS at the end of the year',
      'Claiming unemployment benefits',
      'Opening a retirement account',
    ],
    correctIndex: 0,
    explanation:
        'The W-4 sets withholding; the W-2 reports what was actually earned '
        'and withheld. Getting the W-4 badly wrong means either a large bill '
        'in April or a year of lending the government money for free.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'A raise takes you from \$44,000 to \$46,000 and pushes part of '
        'your income into a higher tax bracket. What happens?',
    options: [
      'Only the amount above the bracket line is taxed at the higher rate',
      'Your whole income is taxed at the higher rate',
      'You take home less than before the raise',
      'The raise is taxed at 100 percent until the next year',
    ],
    correctIndex: 0,
    explanation:
        'Brackets are marginal. A raise can never leave you with less take-home '
        'pay, and the belief that it can is the most common tax myth there is.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'Your side business made \$3,000 this year. What should you '
        'expect?',
    options: [
      'To owe self-employment tax and income tax on the profit',
      'Nothing — side income under \$5,000 is tax free',
      'To be taxed only if you registered a company',
      'To pay tax on the \$3,000 of revenue, not the profit',
    ],
    correctIndex: 0,
    explanation:
        'Self-employment income is taxable from the first dollar, on profit '
        'rather than revenue — so what you spent to earn it matters, and so '
        'does keeping the receipts.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'You are asked for your salary expectation in a first '
        'interview. What is the most useful thing to have done beforehand?',
    options: [
      'Looked up what the role pays at similar employers',
      'Decided the lowest number you would accept',
      'Worked out what you need to cover rent',
      'Nothing — the employer names the number',
    ],
    correctIndex: 0,
    explanation:
        'What you need and what the job pays are unrelated. Knowing the market '
        'rate turns the question from a guess into a fact, and several states '
        'now require the range to be posted.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question: 'Overtime rules in the US generally require what?',
    options: [
      'Time and a half beyond 40 hours a week for covered workers',
      'Double pay for any work after 5pm',
      'Extra pay only for weekend shifts',
      'Nothing — overtime pay is always voluntary',
    ],
    correctIndex: 0,
    explanation:
        'The Fair Labor Standards Act sets 1.5x beyond 40 hours for '
        'non-exempt employees. Whether you are exempt depends on the job, not '
        'on what the contract calls you.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryEarning,
    question:
        'You are paid \$1,400 a month and your fixed costs are \$1,250. '
        'What does that leave you exposed to?',
    options: [
      'Any single unplanned cost, because \$150 absorbs almost nothing',
      'Nothing — you are ahead every month',
      'Higher taxes next year',
      'A lower credit score automatically',
    ],
    correctIndex: 0,
    explanation:
        'A 90 percent fixed-cost ratio means one flat tyre is a crisis. The '
        'point of watching the ratio rather than the balance is that the '
        'balance looks fine right up until it does not.',
  ),
  // ================= SCAMS, FEES AND FINE PRINT =================
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'Someone claiming to be from your bank asks you to pay a fee '
        'in gift cards. What is this?',
    options: [
      'A scam — no legitimate organisation asks to be paid in gift cards',
      'A normal way banks collect small charges',
      'A limited-time promotional payment method',
      'Standard practice for online-only banks',
    ],
    correctIndex: 0,
    explanation:
        'Gift-card payment is one of the four classic scam signs, alongside '
        'impersonating a known organisation, inventing urgency, and claiming '
        'there is a problem or a prize.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'A "free 30-day trial" asks for card details. What usually '
        'happens on day 31?',
    options: [
      'You are charged automatically unless you cancel',
      'The trial simply stops with no charge',
      'You get a reminder email and then choose',
      'The company calls you to confirm',
    ],
    correctIndex: 0,
    explanation:
        'The card is collected because the default is to charge. Setting a '
        'reminder for day 28 is what turns a trial back into a free trial.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'A 400ml bottle costs \$2 and a 1 litre bottle costs \$4.20. '
        'Which is better value?',
    options: [
      'The 1 litre bottle',
      'The 400ml bottle',
      'They are identical value',
      'Not enough information',
    ],
    correctIndex: 0,
    explanation:
        '\$5.00 per litre versus \$4.20 per litre. Unit price is the only '
        'honest comparison, and it is why shelf labels print it.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question: 'What is an overdraft fee?',
    options: [
      'A charge for a payment that goes through when your balance is short',
      'Interest paid to you on a high balance',
      'A fee for closing an account early',
      'A monthly account maintenance charge',
    ],
    correctIndex: 0,
    explanation:
        'Often around \$35 — sometimes more than the purchase that triggered '
        'it. In the US you have to opt in for debit-card overdraft, and you '
        'can opt back out.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'An email from "your streaming service" says your account is '
        'locked and links to a login page. What should you do?',
    options: [
      'Go to the service\'s app or website yourself instead of using the link',
      'Click the link and sign in quickly before it expires',
      'Reply with your password to verify',
      'Forward it to friends to check if they got it too',
    ],
    correctIndex: 0,
    explanation:
        'Phishing works by supplying the door. Reaching the site the way you '
        'normally do removes the attacker\'s control of where you land.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'A shop membership costs \$4/month for 10 percent off. You '
        'spend about \$15 a month there. Is it worth it?',
    options: [
      'No — you would need to spend \$40 a month to break even',
      'Yes — 10 percent off is always worth having',
      'Yes — memberships always include extra perks',
      'It depends on the shop\'s opening hours',
    ],
    correctIndex: 0,
    explanation:
        '10 percent of \$15 is \$1.50 against a \$4 fee. The break-even sum '
        'works on every subscription: divide the fee by the discount rate.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question: 'What does APR tell you that a monthly interest rate does not?',
    options: [
      'The yearly cost of borrowing, including certain fees',
      'The exact amount you will repay',
      'How long the loan lasts',
      'Your credit score',
    ],
    correctIndex: 0,
    explanation:
        'APR exists so two loans can be compared on one number. "Only 2 '
        'percent a month" is close to 27 percent a year once it compounds.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'A price is cut 20 percent, then raised 20 percent. Compared '
        'with the start, the price is now:',
    options: [
      'Lower than it started',
      'Exactly where it started',
      'Higher than it started',
      'Impossible to determine',
    ],
    correctIndex: 0,
    explanation:
        '100 becomes 80 becomes 96. The second percentage is taken from a '
        'smaller number, which is why stacked percentages never simply add.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'How often can you get your credit report for free from the '
        'federally authorised site?',
    options: [
      'Regularly, at no cost, from AnnualCreditReport.com',
      'Once in a lifetime',
      'Only after being denied a loan',
      'Never — reports always cost money',
    ],
    correctIndex: 0,
    explanation:
        'Checking your own report never lowers your score, and errors on '
        'reports are common enough to be worth looking for.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'A game sells "gems", and items are priced in gems rather than '
        'dollars. Why?',
    options: [
      'So you stop converting the cost to real money in your head',
      'Because gems are cheaper to process than card payments',
      'Because the law requires an in-game currency',
      'To make refunds easier',
    ],
    correctIndex: 0,
    explanation:
        'A second currency breaks the link to real money. Doing the '
        'conversion anyway is the only way to know what you just spent.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'A free trial asks for your card and says "cancel any time". '
        'What actually happens on day 31?',
    options: [
      'You are charged automatically unless you cancelled first',
      'You are emailed to ask whether you want to continue',
      'The trial simply ends',
      'The card is charged \$1 as a formality',
    ],
    correctIndex: 0,
    explanation:
        'The card is there because the default is to charge it. A reminder set '
        'for two days before the trial ends costs nothing and is the whole '
        'defence.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'A store card offers 20 percent off today if you open an '
        'account. The card charges 29 percent APR. When is this a good deal?',
    options: [
      'Only if you clear the balance in full before interest starts',
      'Always, because 20 percent beats 29 percent',
      'Only on purchases over \$500',
      'Never, under any circumstances',
    ],
    correctIndex: 0,
    explanation:
        'A one-off 20 percent saving against 29 percent a year is fine for a '
        'week and terrible for a year. The discount is the bait; the interest '
        'is the business.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'Buy-now-pay-later splits a \$200 purchase into four payments '
        'of \$50 with no interest. What is the risk?',
    options: [
      'Late fees, and losing track of several overlapping plans at once',
      'It always damages your credit score',
      'The retailer can reclaim the item without notice',
      'There is none — no interest means no risk',
    ],
    correctIndex: 0,
    explanation:
        'The interest really is zero. The cost shows up as late fees and as '
        'four or five plans running at the same time, each small enough to '
        'forget and large enough together to matter.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'A caller says they are from your bank\'s fraud team and asks '
        'you to read out the code they just texted you. What is happening?',
    options: [
      'They are trying to complete a login or transfer that needs that code',
      'Standard bank identity verification',
      'A test of your account security',
      'Nothing unusual — codes are meant to be shared with staff',
    ],
    correctIndex: 0,
    explanation:
        'A one-time code proves *you* are doing something. No real bank asks '
        'for one, and the request itself is the evidence that somebody else is '
        'already partway into your account.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'Two boxes of the same cereal: 340g for \$4.00, or 500g for '
        '\$5.50. Which is cheaper per gram?',
    options: [
      'The 500g box, at 1.1 cents a gram against 1.18',
      'The 340g box',
      'They are identical',
      'Impossible to say without the brand',
    ],
    correctIndex: 0,
    explanation:
        'Unit price is the only honest comparison, and it is printed on the '
        'shelf label in most shops. Bigger is usually but not always cheaper '
        'per gram — which is exactly why it is worth checking.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'An investment promises "guaranteed 12 percent monthly '
        'returns". What does the word "guaranteed" tell you?',
    options: [
      'That it is almost certainly a fraud',
      'That it is insured by the government',
      'That the returns are lower risk than a savings account',
      'That it has been approved by the SEC',
    ],
    correctIndex: 0,
    explanation:
        'No real investment guarantees a return, and 12 percent a month is '
        '289 percent a year. Guaranteed high returns is the single most '
        'reliable marker of a Ponzi scheme.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'A rent-to-own shop offers a \$600 laptop for \$25 a week over '
        '18 months. What does it cost?',
    options: [
      'About \$1,950 — more than three times the price',
      'About \$700',
      '\$600, spread out',
      'Impossible to work out',
    ],
    correctIndex: 0,
    explanation:
        '78 weeks at \$25 is \$1,950. Rent-to-own is legal and it is the most '
        'expensive way to buy anything — the weekly number is small precisely '
        'so the total is never spoken aloud.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'Your bank offers "overdraft protection" so payments go through '
        'when your balance is short. What does it usually cost?',
    options: [
      'A flat fee of roughly \$35 for each payment it covers',
      'Nothing, which is why it is called protection',
      'Interest of about 5 percent a year',
      'A one-off charge when you enable it',
    ],
    correctIndex: 0,
    explanation:
        'It is opt-in, and declining it means the payment is refused instead. '
        'A declined card is embarrassing for a minute; \$35 for covering \$12 '
        'is the most expensive borrowing most people ever do.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'A "0% APR for 12 months" card charges deferred interest. You '
        'still owe \$100 at month 13. What are you charged interest on?',
    options: [
      'The whole original balance, backdated to the purchase date',
      'The \$100 that is still outstanding',
      'Nothing, if most of it was paid on time',
      'A flat late fee only',
    ],
    correctIndex: 0,
    explanation:
        'Deferred interest is not the same as 0 percent. Missing the deadline '
        'by a dollar can trigger a year of interest on the full amount, which '
        'is why the payoff date matters more than the rate.',
  ),
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question:
        'An airline fare is \$39, but checkout shows \$118. What '
        'happened?',
    options: [
      'Seat, bag and service fees were added after the headline price',
      'The price rose while you were browsing',
      'Tax is charged at 200 percent on flights',
      'A booking error',
    ],
    correctIndex: 0,
    explanation:
        'Unbundling puts the smallest possible number on the advert and moves '
        'the rest to checkout. The only price worth comparing between sellers '
        'is the one on the final screen.',
  ),
];
