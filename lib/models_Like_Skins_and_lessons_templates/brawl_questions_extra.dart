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
    question: 'Your payslip shows gross pay of \$400 and net pay of \$332. '
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
    question: 'Job A pays \$14/hour with no travel cost. Job B pays '
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
    question: 'Which of these is part of the value of a job offer besides '
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
    question: 'You are paid \$15/hour and work 42 hours in a week that '
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
    question: 'Your income varies month to month from tips. What should you '
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
    question: 'What is the difference between an employee and an independent '
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

  // ================= SCAMS, FEES AND FINE PRINT =================
  BrawlQuestion(
    category: kBrawlCategoryFinePrint,
    question: 'Someone claiming to be from your bank asks you to pay a fee '
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
    question: 'A "free 30-day trial" asks for card details. What usually '
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
    question: 'A 400ml bottle costs \$2 and a 1 litre bottle costs \$4.20. '
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
    question: 'An email from "your streaming service" says your account is '
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
    question: 'A shop membership costs \$4/month for 10 percent off. You '
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
    question: 'A price is cut 20 percent, then raised 20 percent. Compared '
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
    question: 'How often can you get your credit report for free from the '
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
    question: 'A game sells "gems", and items are priced in gems rather than '
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
];
