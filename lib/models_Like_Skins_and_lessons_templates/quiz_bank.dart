/// The Academy question bank.
///
/// Authoring rules, kept deliberately strict because the previous bank failed
/// all three and let players pass without learning anything:
///
///  1. **Spread the answer key.** 30 of the old 34 questions had the correct
///     answer at index 1, so "always pick B" scored ~88%. [answerKeyIsBalanced]
///     is asserted by a test.
///  2. **Every distractor is a real misconception**, not a joke. "Just the
///     colour of the card" teaches nothing; "The card with the highest limit"
///     is a mistake teenagers actually make.
///  3. **Every question explains itself.** [QuizQuestion.explanation] is
///     required, and questions carry the misconception behind the most tempting
///     wrong answer so the review screen can address it directly.
library;

/// How demanding a question is. Practice sets lead with [core]; unit tests mix
/// in [stretch] items that need two ideas combined.
enum QuizDifficulty { core, stretch }

/// A single multiple-choice item.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.skillId,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.misconception,
    this.difficulty = QuizDifficulty.core,
  });

  final String id;

  /// Groups questions for mastery tracking. See [QuizSkills].
  final String skillId;

  final String prompt;
  final List<String> options;
  final int correctIndex;

  /// Shown after answering, whether right or wrong.
  final String explanation;

  /// What choosing the most tempting wrong answer usually means. Surfaced on
  /// the review screen for missed questions.
  final String? misconception;

  final QuizDifficulty difficulty;

  String get correctOption => options[correctIndex];
}

/// Stable skill identifiers, used for per-skill mastery in the learning path.
class QuizSkills {
  QuizSkills._();

  static const String budgetBasics = 'budget_basics';
  static const String income = 'income';
  static const String expenses = 'expenses';
  static const String saving = 'saving';
  static const String budgetBuilding = 'budget_building';
  static const String credit = 'credit';
  static const String investingBasics = 'investing_basics';
  static const String banking = 'banking';
  static const String emergencyFund = 'emergency_fund';
  static const String goals = 'goals';
  static const String payYourself = 'pay_yourself_first';
  static const String sinkingFunds = 'sinking_funds';
  static const String savingsAccounts = 'savings_accounts';
  static const String automation = 'automation';
  static const String irregularCosts = 'irregular_costs';
  static const String whyInvest = 'why_invest';
  static const String risk = 'risk';
  static const String assetTypes = 'asset_types';
  static const String compounding = 'compounding';
  static const String investorMindset = 'investor_mindset';
  static const String payStub = 'pay_stub';
  static const String jobOffers = 'job_offers';
  static const String livingCosts = 'living_costs';
  static const String taxes = 'taxes';
  static const String moneyPlan = 'money_plan';
  static const String shareOwnership = 'share_ownership';
  static const String priceMovement = 'price_movement';
  static const String diversification = 'diversification';
  static const String tradingCosts = 'trading_costs';
  static const String timeInMarket = 'time_in_market';

  /// Human-readable name for the mastery breakdown in the learning path.
  static String label(String skillId) => switch (skillId) {
    budgetBasics => 'Budgeting basics',
    income => 'Income',
    expenses => 'Expenses',
    saving => 'Saving',
    budgetBuilding => 'Building a budget',
    credit => 'Credit and debt',
    investingBasics => 'Investing intro',
    banking => 'Banking tools',
    emergencyFund => 'Emergency funds',
    goals => 'Financial goals',
    payYourself => 'Pay yourself first',
    sinkingFunds => 'Sinking funds',
    savingsAccounts => 'Savings accounts',
    automation => 'Automation',
    irregularCosts => 'Irregular costs',
    whyInvest => 'Why invest',
    risk => 'Risk and diversification',
    assetTypes => 'Stocks, bonds, funds',
    compounding => 'Compound growth',
    investorMindset => 'Investor mindset',
    payStub => 'Reading a pay stub',
    jobOffers => 'Comparing job offers',
    livingCosts => 'Living costs',
    taxes => 'Taxes',
    moneyPlan => 'Personal money plan',
    shareOwnership => 'What a share is',
    priceMovement => 'Why prices move',
    diversification => 'Diversification',
    tradingCosts => 'Trading costs',
    timeInMarket => 'Time in the market',
    _ => skillId,
  };
}

// ---------------------------------------------------------------------------
// Unit 1 — Budgeting
// ---------------------------------------------------------------------------

const List<QuizQuestion> _unit1Practice = <QuizQuestion>[
  QuizQuestion(
    id: 'u1p1',
    skillId: QuizSkills.budgetBasics,
    prompt:
        'What makes something a budget rather than just a record of spending?',
    options: [
      'It is written down instead of kept in your head',
      'It covers a whole year at a time',
      'It only counts money going out, not money coming in',
      'It plans what money will do before it is spent',
    ],
    correctIndex: 3,
    explanation:
        'A budget is forward-looking: you decide where money goes before it '
        'moves. A record of what you already spent is tracking, which is useful '
        'but is a different job.',
    misconception:
        'Tracking and budgeting get mixed up. Tracking tells you what happened; '
        'budgeting decides what happens next.',
  ),
  QuizQuestion(
    id: 'u1p2',
    skillId: QuizSkills.budgetBasics,
    prompt:
        'You take home \$400 a month. Under the 50/30/20 rule, how much goes to '
        'savings or paying down debt?',
    options: ['\$80', '\$120', '\$200', '\$40'],
    correctIndex: 0,
    explanation:
        '20% of \$400 is \$80. The other slices would be \$200 for needs (50%) '
        'and \$120 for wants (30%).',
    misconception:
        'Picking \$120 means you used the 30% wants slice instead of the 20% '
        'savings slice.',
  ),
  QuizQuestion(
    id: 'u1p3',
    skillId: QuizSkills.budgetBasics,
    prompt:
        'Your budget says \$60 for food this month, but you have already spent '
        '\$75 and it is only the 20th. What is the most useful next step?',
    options: [
      'Stop tracking food until next month starts',
      'Delete the food category since it clearly does not work',
      'Move money from another category and adjust next month\'s food number',
      'Keep spending and assume it will balance out',
    ],
    correctIndex: 2,
    explanation:
        'Going over a category is information, not failure. You cover the gap '
        'from somewhere specific so the total still works, then set a more '
        'realistic number next month.',
    misconception:
        'Many people abandon a budget the first time they break it. A budget '
        'you revise is working; a budget you ignore is not.',
    difficulty: QuizDifficulty.stretch,
  ),
];

const List<QuizQuestion> _unit1Quiz = <QuizQuestion>[
  QuizQuestion(
    id: 'u1q1',
    skillId: QuizSkills.budgetBasics,
    prompt: 'In the 50/30/20 rule, what is the 20% for?',
    options: [
      'Savings or paying off debt',
      'Rent and utilities',
      'Entertainment and eating out',
      'Taxes taken from your pay',
    ],
    correctIndex: 0,
    explanation:
        '50% needs, 30% wants, 20% savings or debt payoff. The 20% is the slice '
        'that builds your future rather than covering today.',
    misconception:
        'Taxes are already gone before this rule applies — the split works on '
        'take-home pay, not gross pay.',
  ),
  QuizQuestion(
    id: 'u1q2',
    skillId: QuizSkills.income,
    prompt:
        'When building a budget, which income number should you plan around?',
    options: [
      'Gross income, because it is your real salary',
      'Whatever you expect to earn after a raise',
      'Net income, the amount that reaches your account',
      'Last year\'s average monthly income',
    ],
    correctIndex: 2,
    explanation:
        'Net income is what you can actually spend. Budgeting on gross pay '
        'commits money that taxes and deductions already took.',
    misconception:
        'Gross pay feels like "your" money because it is the number on the job '
        'offer, but you never receive it.',
  ),
  QuizQuestion(
    id: 'u1q3',
    skillId: QuizSkills.income,
    prompt:
        'Your hours change every week at a part-time job. What kind of income '
        'is that, and how should you budget it?',
    options: [
      'Fixed income — budget the same amount every month',
      'Variable income — budget around a low typical month',
      'Variable income — budget around your best month so far',
      'Fixed income — budget your average of the last three months',
    ],
    correctIndex: 1,
    explanation:
        'Hours that move make it variable income. Planning around a low typical '
        'month means a slow month does not break the budget, and good months '
        'create a surplus instead of a shortfall.',
    misconception:
        'Budgeting to your best month guarantees most months come up short.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u1q4',
    skillId: QuizSkills.expenses,
    prompt:
        'Which of these is hardest to classify as a clear "need" or "want"?',
    options: [
      'Rent for the place you live',
      'A phone plan you use for work and for gaming',
      'A concert ticket',
      'Groceries for the week',
    ],
    correctIndex: 1,
    explanation:
        'Plenty of real expenses are partly both. The phone is a need at some '
        'level of service and a want above it — the useful question is "how '
        'much of this is essential?", not "which box does it go in?".',
    misconception:
        'Needs and wants are treated as tidy categories, but the interesting '
        'decisions live in the overlap.',
    difficulty: QuizDifficulty.stretch,
  ),
];

const List<QuizQuestion> _unit1Test = <QuizQuestion>[
  QuizQuestion(
    id: 'u1t1',
    skillId: QuizSkills.budgetBasics,
    prompt: 'The main reason to budget is to:',
    options: [
      'Spend as little money as possible',
      'Decide what your money does before it leaves',
      'Prove to other people that you are responsible',
      'Avoid ever having to think about money again',
    ],
    correctIndex: 1,
    explanation:
        'Budgeting is about direction, not restriction. Spending less is '
        'sometimes the result, but the point is choosing where money goes.',
    misconception:
        '"Budget" sounds like "spend less". It actually means "spend on '
        'purpose", which can include planning for fun.',
  ),
  QuizQuestion(
    id: 'u1t2',
    skillId: QuizSkills.income,
    prompt: 'Gross pay of \$1,000 with \$180 withheld means your net pay is:',
    options: ['\$1,180', '\$1,000', '\$820', '\$180'],
    correctIndex: 2,
    explanation:
        r'Net = gross − deductions, so $1,000 − $180 = $820. That $820 is the '
        'number your budget is allowed to use.',
  ),
  QuizQuestion(
    id: 'u1t3',
    skillId: QuizSkills.expenses,
    prompt:
        'You review last month and find 14 small food-delivery charges you do '
        'not remember. What does this best demonstrate?',
    options: [
      'Delivery apps are a scam',
      'Your bank made an error',
      'You should never order food',
      'Small repeated costs add up invisibly without tracking',
    ],
    correctIndex: 3,
    explanation:
        'Individually forgettable purchases are exactly what tracking is for. '
        'Fourteen \$9 orders is \$126 — a number worth deciding on rather than '
        'drifting into.',
    misconception:
        'People look for one big leak. Budgets more often bleed from many '
        'small, repeated ones.',
  ),
  QuizQuestion(
    id: 'u1t4',
    skillId: QuizSkills.saving,
    prompt: '"Pay yourself first" means:',
    options: [
      'Buy something you want before paying bills',
      'Move money to savings before other spending happens',
      'Give yourself an allowance from your savings',
      'Save only what is left at the end of the month',
    ],
    correctIndex: 1,
    explanation:
        'Savings is treated as the first bill, not the leftovers. Leftovers are '
        'unreliable; a transfer on payday is not.',
    misconception:
        'It sounds like "treat yourself first". It means your future self gets '
        'paid before anyone else.',
  ),
  QuizQuestion(
    id: 'u1t5',
    skillId: QuizSkills.saving,
    prompt:
        'Which saves more over a year: \$10 every week, or \$150 whenever you '
        'happen to have spare cash (which turns out to be three times)?',
    options: [
      r'The $150 deposits, because larger amounts matter more',
      'It is impossible to compare them',
      'They are identical',
      r'The weekly $10, at $520 versus $450',
    ],
    correctIndex: 3,
    explanation:
        r'$10 × 52 = $520, while three $150 deposits total $450. Consistency '
        'usually beats occasional bursts, and it is easier to plan around.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u1t6',
    skillId: QuizSkills.budgetBuilding,
    prompt:
        'You build a budget and it balances perfectly to \$0 left over, with '
        'nothing set aside for surprises. What is the weakness?',
    options: [
      'Nothing — a balanced budget is the goal',
      'Any unexpected cost has to become debt or break the plan',
      'You should always have money left unassigned',
      'It means you did the arithmetic wrong',
    ],
    correctIndex: 1,
    explanation:
        'A budget with no slack is fragile. One flat tyre turns into borrowed '
        'money, which is why an emergency buffer is part of the plan and not an '
        'optional extra.',
    misconception:
        'Balancing to zero looks like success, but "assigned to savings" and '
        '"assigned to nothing" are very different kinds of zero.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u1t7',
    skillId: QuizSkills.budgetBuilding,
    prompt: 'How often should a budget be revisited?',
    options: [
      'Once, when you first make it',
      'Only when something goes wrong',
      'Regularly, because income and costs change',
      'Every single day without exception',
    ],
    correctIndex: 2,
    explanation:
        'A budget is a working document. Reviewing it on a regular rhythm — '
        'monthly is common — keeps it matched to what your life actually costs.',
  ),
];

// ---------------------------------------------------------------------------
// Unit 2 — Credit
// ---------------------------------------------------------------------------

const List<QuizQuestion> _unit2Practice = <QuizQuestion>[
  QuizQuestion(
    id: 'u2p1',
    skillId: QuizSkills.credit,
    prompt: 'Paying only the minimum on a credit card each month means:',
    options: [
      'The balance is cleared over a fixed, short schedule',
      'Your credit limit automatically increases',
      'You avoid interest entirely',
      'Interest keeps accruing and the balance shrinks very slowly',
    ],
    correctIndex: 3,
    explanation:
        'The minimum is designed to keep the account current, not to clear it. '
        'Interest is charged on what remains, so a balance paid at the minimum '
        'can take years and cost more than the original purchase.',
    misconception:
        '"Minimum payment" reads like "the amount I am supposed to pay". It is '
        'the least you can pay without penalty — a floor, not a plan.',
  ),
  QuizQuestion(
    id: 'u2p2',
    skillId: QuizSkills.credit,
    prompt: 'Which habit tends to help a credit score the most?',
    options: [
      'Paying on time, every time',
      'Carrying a balance so there is activity to report',
      'Opening several new cards in the same month',
      'Using the entire available limit each month',
    ],
    correctIndex: 0,
    explanation:
        'Payment history is the single biggest factor. You do not need to carry '
        'debt to build credit — paying in full and on time does it.',
    misconception:
        'The myth that "you need to carry a balance to build credit" costs '
        'people real interest for no benefit.',
  ),
];

const List<QuizQuestion> _unit2Quiz = <QuizQuestion>[
  QuizQuestion(
    id: 'u2q1',
    skillId: QuizSkills.credit,
    prompt: 'Credit is best described as:',
    options: [
      'Money the bank gives you as a reward',
      'A discount on things you buy',
      'Borrowed money you use now and repay later, usually with interest',
      'A type of savings account',
    ],
    correctIndex: 2,
    explanation:
        'Credit moves spending forward in time. Whatever you buy with it, you '
        'still pay for — plus interest if you do not clear it quickly.',
  ),
  QuizQuestion(
    id: 'u2q2',
    skillId: QuizSkills.investingBasics,
    prompt:
        'An investment advertising much higher returns than everything else:',
    options: [
      'Is carrying more risk, even if that is not advertised',
      'Has found a way to beat the market safely',
      'Is guaranteed by the government',
      'Is always a scam',
    ],
    correctIndex: 0,
    explanation:
        'Return and risk travel together. Higher advertised returns mean a '
        'higher chance of loss — not necessarily fraud, but never free money.',
    misconception:
        'The two failure modes are believing every high return is safe, and '
        'assuming every high return is a scam. The truth is "priced risk".',
  ),
  QuizQuestion(
    id: 'u2q3',
    skillId: QuizSkills.banking,
    prompt: 'When comparing two bank accounts, which comparison matters least?',
    options: [
      'Monthly maintenance and overdraft fees',
      'How quickly transfers clear',
      'Which card design looks better',
      'Whether the app supports the alerts you need',
    ],
    correctIndex: 2,
    explanation:
        'Fees, transfer speed and tooling change what the account costs and how '
        'usable it is. Card design does not.',
  ),
];

const List<QuizQuestion> _unit2Test = <QuizQuestion>[
  QuizQuestion(
    id: 'u2t1',
    skillId: QuizSkills.credit,
    prompt:
        r'A $500 balance at 24% APR, paying $25 a month, will take roughly:',
    options: [
      'Under 3 months',
      'About 6 months',
      'About 2 years',
      'It never gets paid off',
    ],
    correctIndex: 2,
    explanation:
        r'Interest of roughly $10 in the first month means only about $15 of '
        r'that $25 reduces the balance. It takes around 24 months and well over '
        r'$100 in interest.',
    misconception:
        r'People divide $500 by $25 and expect 20 months with no interest. '
        'Interest is exactly what makes the real answer worse.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u2t2',
    skillId: QuizSkills.credit,
    prompt: 'The difference between a debit card and a credit card is that:',
    options: [
      'Debit spends money you already have; credit borrows it',
      'Credit cards cannot be used online',
      'Debit cards always charge interest',
      'There is no real difference any more',
    ],
    correctIndex: 0,
    explanation:
        'Debit draws on your own balance. Credit creates a debt you settle '
        'later, which is why only one of them can charge interest.',
  ),
  QuizQuestion(
    id: 'u2t3',
    skillId: QuizSkills.investingBasics,
    prompt: 'Higher potential investment return usually comes with:',
    options: [
      'A guaranteed payout schedule',
      'More uncertainty about the outcome',
      'Lower fees',
      'Government protection against loss',
    ],
    correctIndex: 1,
    explanation:
        'Uncertainty is the price of higher expected return. If an option '
        'genuinely had high return and no risk, everyone would take it and the '
        'return would fall.',
  ),
  QuizQuestion(
    id: 'u2t4',
    skillId: QuizSkills.emergencyFund,
    prompt: 'The main purpose of an emergency fund is to:',
    options: [
      'Earn the highest interest rate available',
      'Pay for holidays without guilt',
      'Replace your regular savings goals',
      'Keep an unexpected cost from becoming new debt',
    ],
    correctIndex: 3,
    explanation:
        'An emergency fund is insurance for your budget. Its job is absorbing '
        'surprises, which is why access matters more than interest rate.',
    misconception:
        'Chasing yield on emergency money often locks it up — exactly when you '
        'need it liquid.',
  ),
  QuizQuestion(
    id: 'u2t5',
    skillId: QuizSkills.emergencyFund,
    prompt: 'Where does emergency money belong?',
    options: [
      'In a separate account you can reach within a day or two',
      'In the same account you spend from daily',
      'In whatever investment grew fastest last year',
      'In cash under your mattress',
    ],
    correctIndex: 0,
    explanation:
        'Separate stops it being spent by accident; reachable means it works in '
        'an actual emergency. Investments can be down exactly when you need to '
        'withdraw.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u2t6',
    skillId: QuizSkills.goals,
    prompt: 'Which is the strongest financial goal as written?',
    options: [
      'Save more money this year',
      'Get better with money',
      r'Save $600 for a laptop by December, $50 a month',
      'Stop wasting money on things I do not need',
    ],
    correctIndex: 2,
    explanation:
        'It names an amount, a deadline and a monthly step, so you can tell at '
        'any point whether you are on track. The others cannot be checked.',
  ),
  QuizQuestion(
    id: 'u2t7',
    skillId: QuizSkills.banking,
    prompt: 'An overdraft fee is charged when:',
    options: [
      'You transfer money between your own accounts',
      'Your account earns interest',
      'You check your balance too often',
      'You spend more than your account holds',
    ],
    correctIndex: 3,
    explanation:
        'Spending past your balance means the bank covers the gap and charges '
        'for it. Low-balance alerts are the cheapest defence.',
  ),
];

// ---------------------------------------------------------------------------
// Unit 3 — Saving systems
// ---------------------------------------------------------------------------

const List<QuizQuestion> _unit3Practice = <QuizQuestion>[
  QuizQuestion(
    id: 'u3p1',
    skillId: QuizSkills.sinkingFunds,
    prompt:
        r'You know a $240 insurance bill lands in 6 months. A sinking fund '
        'approach means:',
    options: [
      r'Paying the $240 from whatever is available that month',
      'Hoping for a bonus before then',
      'Putting it on a credit card and paying it off later',
      r'Setting aside $40 a month starting now',
    ],
    correctIndex: 3,
    explanation:
        r'$240 ÷ 6 = $40 a month. The bill still costs the same; the sinking '
        'fund stops it landing on one month all at once.',
  ),
  QuizQuestion(
    id: 'u3p2',
    skillId: QuizSkills.automation,
    prompt: 'The main advantage of automatic transfers to savings is that:',
    options: [
      'They earn a higher interest rate than manual ones',
      'They remove the need to decide again every month',
      'They are impossible to cancel',
      'Banks pay you a bonus for using them',
    ],
    correctIndex: 1,
    explanation:
        'Automation moves the decision from every month to once. It works '
        'because it stops relying on willpower at the moment of temptation.',
    misconception:
        'The money is not special because it moved automatically — the benefit '
        'is entirely behavioural.',
  ),
];

const List<QuizQuestion> _unit3Quiz = <QuizQuestion>[
  QuizQuestion(
    id: 'u3q1',
    skillId: QuizSkills.payYourself,
    prompt: '"Pay yourself first" is most effective when:',
    options: [
      'You save whatever remains at month end',
      'You wait until you get a raise',
      'You save only in months with no big expenses',
      'The transfer happens automatically on payday',
    ],
    correctIndex: 3,
    explanation:
        'Saving on payday, before spending starts, is what makes it reliable. '
        'Anything that depends on leftovers competes with everything else.',
  ),
  QuizQuestion(
    id: 'u3q2',
    skillId: QuizSkills.sinkingFunds,
    prompt: 'A sinking fund and an emergency fund differ because:',
    options: [
      'A sinking fund is for a known upcoming cost; an emergency fund is for surprises',
      'A sinking fund is for surprises; an emergency fund is for planned costs',
      'They are two names for the same thing',
      'Only one of them belongs in a budget',
    ],
    correctIndex: 0,
    explanation:
        'Known and dated goes in a sinking fund. Unknown and unwelcome is what '
        'the emergency fund is for. Using one for the other leaves a gap.',
    misconception:
        'Draining the emergency fund for a predictable annual bill is the most '
        'common version of this mix-up.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u3q3',
    skillId: QuizSkills.savingsAccounts,
    prompt: 'For money you may need next week, the most important feature is:',
    options: [
      'The highest possible interest rate',
      'A long lock-in period for better returns',
      'Quick, penalty-free access',
      'Investment growth potential',
    ],
    correctIndex: 2,
    explanation:
        'Short-horizon money is judged on access, not yield. A great rate you '
        'cannot reach in time is worth nothing to you.',
  ),
];

const List<QuizQuestion> _unit3Test = <QuizQuestion>[
  QuizQuestion(
    id: 'u3t1',
    skillId: QuizSkills.payYourself,
    prompt:
        r'You earn $800 a month and want to save 15%. Paying yourself first '
        'means:',
    options: [
      r'Spending normally, then saving if $120 is left',
      r'Transferring $120 on payday, then budgeting the remaining $680',
      r'Saving $120 only in months with no unusual costs',
      r'Saving $80 now and $40 later to be safe',
    ],
    correctIndex: 1,
    explanation:
        r'15% of $800 is $120, moved first. The budget then works with $680, '
        'which is the honest amount available to spend.',
  ),
  QuizQuestion(
    id: 'u3t2',
    skillId: QuizSkills.sinkingFunds,
    prompt: 'Which cost is the best fit for a sinking fund?',
    options: [
      'A sudden trip to the dentist',
      'A car repair you did not see coming',
      'An annual subscription that renews every March',
      'Losing your job unexpectedly',
    ],
    correctIndex: 2,
    explanation:
        'Known amount and known date makes it plannable. The other three are '
        'exactly what an emergency fund exists for.',
  ),
  QuizQuestion(
    id: 'u3t3',
    skillId: QuizSkills.savingsAccounts,
    prompt:
        'One account pays 4% but locks money for a year; another pays 2% with '
        'instant access. For an emergency fund you should:',
    options: [
      'Take the 4% — the extra return is worth it',
      'Avoid both and keep the cash at home',
      'Split it evenly regardless of the goal',
      'Take the 2% because access is the point of the fund',
    ],
    correctIndex: 3,
    explanation:
        'Locking emergency money defeats its purpose. The 2% difference is '
        'small next to being unable to reach it during the emergency.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u3t4',
    skillId: QuizSkills.automation,
    prompt: 'A risk of fully automating your money is that:',
    options: [
      'Automatic transfers stop working after a year',
      'Interest is not paid on automated deposits',
      'You can stop noticing subscriptions and drift out of date',
      'Banks charge extra for automation',
    ],
    correctIndex: 2,
    explanation:
        'Automation removes friction in both directions — good habits and '
        'forgotten charges alike. A periodic review is what keeps it honest.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u3t5',
    skillId: QuizSkills.irregularCosts,
    prompt:
        r'Gifts, car servicing and school trips cost about $720 a year in total. '
        'The cleanest way to handle them is:',
    options: [
      r'Add $60 a month to the budget as a category',
      'Deal with each one when it arrives',
      'Put them on credit and pay them off over the year',
      'Leave them out because they are not monthly',
    ],
    correctIndex: 0,
    explanation:
        r'$720 ÷ 12 = $60. Turning lumpy annual costs into a flat monthly line '
        'is what stops them feeling like emergencies.',
  ),
  QuizQuestion(
    id: 'u3t6',
    skillId: QuizSkills.saving,
    prompt: 'Saving works best when it is treated as:',
    options: [
      'A reward for a good month',
      'A required bill with a due date',
      'Something to start once you earn more',
      'Whatever is left in the account before payday',
    ],
    correctIndex: 1,
    explanation:
        'Bills get paid because they are scheduled and expected. Giving savings '
        'the same status is what makes it survive a busy month.',
  ),
];

// ---------------------------------------------------------------------------
// Unit 4 — Investing basics
// ---------------------------------------------------------------------------

const List<QuizQuestion> _unit4Practice = <QuizQuestion>[
  QuizQuestion(
    id: 'u4p1',
    skillId: QuizSkills.whyInvest,
    prompt: 'Money sitting in a 0% account while prices rise 3% a year is:',
    options: [
      'Growing slowly',
      'Staying exactly the same in value',
      'Losing purchasing power',
      'Protected from inflation',
    ],
    correctIndex: 2,
    explanation:
        'The number in the account does not change, but what it buys shrinks by '
        'about 3% a year. That gap is the main argument for investing '
        'long-horizon money.',
    misconception:
        'A balance that never drops feels safe. Inflation makes "safe" and "no '
        'loss" different things.',
  ),
  QuizQuestion(
    id: 'u4p2',
    skillId: QuizSkills.risk,
    prompt: 'Diversification reduces risk by:',
    options: [
      'Guaranteeing you never lose money',
      'Spreading money so one bad outcome does less damage',
      'Picking only the investments that go up',
      'Keeping everything in the single safest asset',
    ],
    correctIndex: 1,
    explanation:
        'Diversifying does not remove risk, it stops any single failure being '
        'decisive. A broad fund can still fall — just not to zero because one '
        'company collapsed.',
  ),
];

const List<QuizQuestion> _unit4Quiz = <QuizQuestion>[
  QuizQuestion(
    id: 'u4q1',
    skillId: QuizSkills.whyInvest,
    prompt: 'The main reason people invest rather than only save is:',
    options: [
      'Investing cannot lose money over long periods',
      'Savings accounts are not safe',
      'To grow money faster than prices rise, over long horizons',
      'Because investing is required for a good credit score',
    ],
    correctIndex: 2,
    explanation:
        'Investing trades short-term certainty for a better shot at long-term '
        'growth above inflation. That trade only makes sense with time.',
  ),
  QuizQuestion(
    id: 'u4q2',
    skillId: QuizSkills.risk,
    prompt:
        'You put all your savings into one company\'s stock because a friend '
        'says it will double. The clearest problem is:',
    options: [
      'Concentrated risk — one outcome decides everything',
      'Stocks are always a bad idea',
      'You should have waited for the price to fall',
      'One company is too small to invest in',
    ],
    correctIndex: 0,
    explanation:
        'The issue is not that stocks are bad, it is that everything depends on '
        'a single outcome you cannot control or predict.',
    misconception:
        'A confident tip feels like information. Concentration is risky '
        'regardless of how certain the tip sounded.',
  ),
  QuizQuestion(
    id: 'u4q3',
    skillId: QuizSkills.assetTypes,
    prompt: 'Buying a share of stock means you:',
    options: [
      'Have lent money to the company',
      'Have insured yourself against losses',
      'Are guaranteed a fixed annual payment',
      'Own a small piece of the company',
    ],
    correctIndex: 3,
    explanation:
        'Stock is ownership; a bond is lending. That difference is why stock '
        'has no guaranteed payment but shares in the upside.',
  ),
];

const List<QuizQuestion> _unit4Test = <QuizQuestion>[
  QuizQuestion(
    id: 'u4t1',
    skillId: QuizSkills.assetTypes,
    prompt: 'Which best describes a bond?',
    options: [
      'Part-ownership of a company',
      'A basket of many different stocks',
      'A savings account with a debit card',
      'A loan you make in exchange for interest',
    ],
    correctIndex: 3,
    explanation:
        'A bond is debt: you lend, they repay with interest. That is why bonds '
        'usually move less than stocks and pay less over long periods.',
  ),
  QuizQuestion(
    id: 'u4t2',
    skillId: QuizSkills.assetTypes,
    prompt: 'An index fund is popular with beginners mainly because it:',
    options: [
      'Guarantees a positive return every year',
      'Is chosen by an expert who beats the market',
      'Buys a wide slice of the market at low cost',
      'Avoids all exposure to falling prices',
    ],
    correctIndex: 2,
    explanation:
        'Broad exposure plus low fees means diversification without needing to '
        'pick winners. It still falls when the market falls.',
    misconception:
        '"Safe" and "diversified" get confused. An index fund spreads risk; it '
        'does not remove it.',
  ),
  QuizQuestion(
    id: 'u4t3',
    skillId: QuizSkills.compounding,
    prompt:
        r'$1,000 growing 10% a year is worth about $1,100 after one year. After '
        'two years it is closest to:',
    options: [r'$1,200', r'$1,210', r'$1,100', r'$2,000'],
    correctIndex: 1,
    explanation:
        r'Year two earns 10% on $1,100, not on the original $1,000 — that extra '
        r'$10 is compounding. Small early, enormous over decades.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u4t4',
    skillId: QuizSkills.compounding,
    prompt: 'Compound growth rewards which factor the most?',
    options: [
      'Time invested',
      'How often you check the balance',
      'How many different apps you use',
      'Investing one large amount rather than several small ones',
    ],
    correctIndex: 0,
    explanation:
        'Compounding multiplies with time. Starting earlier with less usually '
        'beats starting later with more, which is the single strongest argument '
        'for beginning young.',
  ),
  QuizQuestion(
    id: 'u4t5',
    skillId: QuizSkills.investorMindset,
    prompt:
        'The market drops 15% and your long-term fund falls with it. The usual '
        'best response is:',
    options: [
      'Sell immediately to stop further losses',
      'Move everything into whatever went up last month',
      'Stick to the plan if your timeline has not changed',
      'Borrow money to buy much more',
    ],
    correctIndex: 2,
    explanation:
        'Selling after a fall converts a paper loss into a real one and usually '
        'means buying back higher. Downturns are part of the return you were '
        'paid to accept.',
    misconception:
        'Acting feels safer than waiting, so panic selling reads as "doing '
        'something responsible".',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u4t6',
    skillId: QuizSkills.risk,
    prompt:
        'Money you need in six months generally should not be invested in stocks because:',
    options: [
      'Stocks are not allowed for short periods',
      'Six months is not enough time to recover from a drop',
      'Short-term investing has higher fees',
      'You would earn too much and owe tax',
    ],
    correctIndex: 1,
    explanation:
        'Stocks reward patience. Over six months a fall may not have time to '
        'recover, so short-horizon money belongs somewhere stable.',
  ),
];

// ---------------------------------------------------------------------------
// Unit 5 — Real-world money moves
// ---------------------------------------------------------------------------

const List<QuizQuestion> _unit5Practice = <QuizQuestion>[
  QuizQuestion(
    id: 'u5p1',
    skillId: QuizSkills.payStub,
    prompt: 'On a pay stub, "year to date" (YTD) shows:',
    options: [
      'What you will earn by December',
      'Your hourly rate multiplied by 52',
      'This period\'s pay only',
      'The total so far this year, across all pay periods',
    ],
    correctIndex: 3,
    explanation:
        'YTD accumulates from the start of the year. It is the quickest way to '
        'check that your pay and deductions look right over time.',
  ),
  QuizQuestion(
    id: 'u5p2',
    skillId: QuizSkills.livingCosts,
    prompt:
        'Rent is advertised at \$900. Which cost is most often forgotten when '
        'working out what a place really costs?',
    options: [
      'Utilities, deposit and getting to work',
      'The rent itself',
      'The colour of the walls',
      'Nothing — rent is the full cost',
    ],
    correctIndex: 0,
    explanation:
        'Advertised rent is a floor. Utilities, a deposit up front and commuting '
        'can add hundreds a month, which is what makes a "cheap" place expensive.',
  ),
];

const List<QuizQuestion> _unit5Quiz = <QuizQuestion>[
  QuizQuestion(
    id: 'u5q1',
    skillId: QuizSkills.payStub,
    prompt: 'Gross pay and net pay differ because of:',
    options: [
      'Bank transfer delays',
      'Taxes and other deductions',
      'Rounding by your employer',
      'Overtime being paid separately',
    ],
    correctIndex: 1,
    explanation:
        'Deductions — tax, and often insurance or retirement contributions — '
        'come out between gross and net. Net is what lands.',
  ),
  QuizQuestion(
    id: 'u5q2',
    skillId: QuizSkills.jobOffers,
    prompt:
        r'Job A pays $19/hour with no benefits. Job B pays $17/hour with health '
        'cover and a transport pass. Comparing them properly means:',
    options: [
      'Always taking the higher hourly rate',
      'Valuing the benefits and adding them to the hourly rate',
      'Ignoring benefits because they are not cash',
      'Choosing whichever starts sooner',
    ],
    correctIndex: 1,
    explanation:
        r'Benefits are pay in another form. If cover and transport are worth $4 '
        r'an hour to you, Job B is effectively $21 — ahead of Job A.',
    misconception:
        'Hourly rate is the visible number, so it dominates the comparison even '
        'when benefits are worth more.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u5q3',
    skillId: QuizSkills.taxes,
    prompt: 'Withholding on your paycheck is:',
    options: [
      'A fee your employer keeps',
      'An optional savings scheme',
      'Tax sent to the government on your behalf during the year',
      'A penalty for earning too much',
    ],
    correctIndex: 2,
    explanation:
        'Your employer forwards estimated tax as you earn. At filing time the '
        'estimate is reconciled, which is why refunds and bills both happen.',
  ),
];

const List<QuizQuestion> _unit5Test = <QuizQuestion>[
  QuizQuestion(
    id: 'u5t1',
    skillId: QuizSkills.payStub,
    prompt:
        r'Your stub shows gross $1,400, tax $210, retirement $70. Net pay is:',
    options: [r'$1,400', r'$1,190', r'$1,120', r'$1,260'],
    correctIndex: 2,
    explanation:
        r'$1,400 − $210 − $70 = $1,120. Both deductions come out, even though '
        'the retirement one is still your money.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u5t2',
    skillId: QuizSkills.taxes,
    prompt: 'A large tax refund usually means:',
    options: [
      'You earned extra money from the government',
      'Your employer underpaid you',
      'You made a mistake that will be penalised',
      'You overpaid during the year and are getting it back',
    ],
    correctIndex: 3,
    explanation:
        'A refund returns your own overpaid money. It is pleasant, but it also '
        'means that cash sat with the government instead of with you all year.',
    misconception:
        'Refunds get treated as a windfall rather than a correction.',
  ),
  QuizQuestion(
    id: 'u5t3',
    skillId: QuizSkills.livingCosts,
    prompt:
        r'Take-home pay is $2,000/month. A common guideline caps housing at '
        'about 30%, which is:',
    options: [r'$600', r'$300', r'$900', r'$1,000'],
    correctIndex: 0,
    explanation:
        r'30% of $2,000 is $600. It is a guideline rather than a law, but going '
        'far above it squeezes everything else.',
  ),
  QuizQuestion(
    id: 'u5t4',
    skillId: QuizSkills.jobOffers,
    prompt:
        'Beyond pay and benefits, which factor most affects what a job is '
        'really worth to you?',
    options: [
      'The job title',
      'Commute cost and hours you cannot control',
      'How large the company is',
      'Whether the office looks modern',
    ],
    correctIndex: 1,
    explanation:
        'Time and travel are real costs. An extra hour commuting each way is '
        'roughly ten unpaid hours a week.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u5t5',
    skillId: QuizSkills.moneyPlan,
    prompt: 'A personal money plan should start with:',
    options: [
      'Picking investments',
      'Opening as many accounts as possible',
      'Knowing your net income and what you actually spend',
      'Setting a target net worth for age 40',
    ],
    correctIndex: 2,
    explanation:
        'Every later decision rests on those two numbers. Choosing investments '
        'before knowing your cash flow is building the roof first.',
  ),
  QuizQuestion(
    id: 'u5t6',
    skillId: QuizSkills.moneyPlan,
    prompt:
        'You have an emergency fund, no high-interest debt, and money left each '
        'month. The usual next step is:',
    options: [
      'Invest the surplus toward long-term goals',
      'Increase spending to match your income',
      'Move everything into a checking account',
      'Stop budgeting since things are going well',
    ],
    correctIndex: 0,
    explanation:
        'With the safety net in place and expensive debt gone, surplus money '
        'has time to work. Letting spending rise to absorb it is the default '
        'that quietly cancels the progress.',
    misconception:
        'Lifestyle creep is invisible because nothing goes wrong — the surplus '
        'just stops existing.',
    difficulty: QuizDifficulty.stretch,
  ),
];

// ---------------------------------------------------------------------------
// Lookup
// ---------------------------------------------------------------------------

/// Questions keyed by the lesson-graph node id they belong to.
const Map<String, List<QuizQuestion>> quizBank = <String, List<QuizQuestion>>{
  'quiz_1': _unit1Quiz,
  'test_1': _unit1Test,
  'quiz_2': _unit2Quiz,
  'test_2': _unit2Test,
  'quiz_3': _unit3Quiz,
  'test_3': _unit3Test,
  'quiz_4': _unit4Quiz,
  'test_4': _unit4Test,
  'quiz_5': _unit5Quiz,
  'test_5': _unit5Test,
  'quiz_6': _unit6Quiz,
  'test_6': _unit6Test,
};

// ---------------------------------------------------------------------------
// Unit 6 — Stocks and Trading
// ---------------------------------------------------------------------------

const List<QuizQuestion> _unit6Practice = <QuizQuestion>[
  QuizQuestion(
    id: 'u6p1',
    skillId: QuizSkills.shareOwnership,
    prompt: 'Owning one share of a company means you own:',
    options: [
      'A loan the company must repay you',
      'A real fraction of that business',
      'A guarantee of future dividends',
      'A fixed amount of the company\'s cash',
    ],
    correctIndex: 1,
    explanation:
        'A share is ownership — a genuine slice of the business and whatever '
        'it earns. It is not a loan, and nothing about it is guaranteed.',
  ),
  QuizQuestion(
    id: 'u6p2',
    skillId: QuizSkills.diversification,
    prompt: 'Your whole portfolio is in one company. That is mainly:',
    options: [
      'Efficient, because you can follow it closely',
      'Concentration risk',
      'Diversification',
      'A guaranteed higher return',
    ],
    correctIndex: 1,
    explanation:
        'Everything riding on one outcome is concentration risk. One bad '
        'result takes the whole portfolio with it.',
  ),
  QuizQuestion(
    id: 'u6p3',
    skillId: QuizSkills.tradingCosts,
    prompt: 'You buy and immediately sell the same share. You most likely:',
    options: [
      'Break exactly even',
      'Lose the spread',
      'Make a small profit',
      'Pay nothing, since there is no commission',
    ],
    correctIndex: 1,
    explanation:
        'You buy at the ask and sell at the lower bid. That gap is a real '
        'cost even when no fee is listed.',
  ),
];

const List<QuizQuestion> _unit6Quiz = <QuizQuestion>[
  QuizQuestion(
    id: 'u6q1',
    skillId: QuizSkills.shareOwnership,
    prompt: 'A share priced at 8 coins is:',
    options: [
      'Always cheaper value than one priced at 800 coins',
      'Not necessarily cheap — it depends what you get for it',
      'A sign the company is failing',
      'Better for beginners by definition',
    ],
    correctIndex: 1,
    explanation:
        'Share price alone says nothing about value. A company can split its '
        'ownership into more pieces and each piece costs less without the '
        'business being worth any less.',
  ),
  QuizQuestion(
    id: 'u6q2',
    skillId: QuizSkills.priceMovement,
    prompt:
        'A company reports record profits and the share price falls. The most '
        'likely reason is:',
    options: [
      'The report must have been wrong',
      'Investors expected even better results',
      'Profits always push prices down',
      'Someone made a trading error',
    ],
    correctIndex: 1,
    explanation:
        'Prices move on expectations, not just results. Beating last year but '
        'missing what the market priced in still reads as a disappointment.',
  ),
  QuizQuestion(
    id: 'u6q3',
    skillId: QuizSkills.priceMovement,
    prompt: 'A holding you plan to keep for years drops 1.5% today. This is:',
    options: [
      'A signal to sell immediately',
      'Normal day-to-day noise',
      'Proof the company is in trouble',
      'A reason to check the price hourly',
    ],
    correctIndex: 1,
    explanation:
        'Moves of a percent or two happen constantly and usually reflect '
        'nothing about the underlying business.',
  ),
];

const List<QuizQuestion> _unit6Test = <QuizQuestion>[
  QuizQuestion(
    id: 'u6t1',
    skillId: QuizSkills.diversification,
    prompt: 'The clearest reason to hold an index fund is that it:',
    options: [
      'Guarantees you cannot lose money',
      'Spreads your money across many companies in one purchase',
      'Always beats picking individual stocks in any given year',
      'Removes the need to ever review your plan',
    ],
    correctIndex: 1,
    explanation:
        'One index fund holds hundreds of companies, so a single failure is a '
        'dent rather than a disaster. It does not guarantee gains.',
  ),
  QuizQuestion(
    id: 'u6t2',
    skillId: QuizSkills.tradingCosts,
    prompt: 'You want to buy only if the price drops to a level you choose:',
    options: [
      'Use a market order',
      'Use a limit order',
      'Buy now and sell later if it drops',
      'There is no way to do this',
    ],
    correctIndex: 1,
    explanation:
        'A limit order only fills at your price or better. A market order '
        'takes whatever price is available right now.',
  ),
  QuizQuestion(
    id: 'u6t3',
    skillId: QuizSkills.timeInMarket,
    prompt: 'Selling everything during a sharp crash most often backfires because:',
    options: [
      'Selling is never allowed',
      'The strongest recovery days tend to come soon after the worst days',
      'Prices never fall twice in a row',
      'You always pay a penalty fee',
    ],
    correctIndex: 1,
    explanation:
        'The best days cluster right after the worst ones. Selling to escape '
        'the drop usually means missing the rebound too.',
  ),
  QuizQuestion(
    id: 'u6t4',
    skillId: QuizSkills.timeInMarket,
    prompt: 'The most reliable protection against panic-selling is:',
    options: [
      'Watching the market more closely',
      'Deciding your rule in advance, while things are calm',
      'Only investing when prices are rising',
      'Keeping your holdings secret',
    ],
    correctIndex: 1,
    explanation:
        'A rule written before a crash — hold, or buy more — beats a decision '
        'made while watching the number fall.',
  ),
];

/// Extra practice items per unit, used by the "Practice" action in the
/// learning path and by the review flow for missed skills.
const Map<String, List<QuizQuestion>> practiceBank =
    <String, List<QuizQuestion>>{
      'unit_1': _unit1Practice,
      'unit_2': _unit2Practice,
      'unit_3': _unit3Practice,
      'unit_4': _unit4Practice,
      'unit_5': _unit5Practice,
      'unit_6': _unit6Practice,
    };

List<QuizQuestion> quizFor(String nodeId) =>
    quizBank[nodeId] ?? const <QuizQuestion>[];

List<QuizQuestion> practiceFor(String unitId) =>
    practiceBank[unitId] ?? const <QuizQuestion>[];

Iterable<QuizQuestion> get allQuizQuestions sync* {
  for (final list in quizBank.values) {
    yield* list;
  }
  for (final list in practiceBank.values) {
    yield* list;
  }
}

/// Guards against the answer-key bias that made the previous bank trivially
/// gameable: no single option position may hold more than 40% of the answers.
bool get answerKeyIsBalanced {
  final counts = <int, int>{};
  var total = 0;
  for (final question in allQuizQuestions) {
    counts.update(
      question.correctIndex,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    total++;
  }
  if (total == 0) {
    return true;
  }
  return counts.values.every((count) => count / total <= 0.4);
}
