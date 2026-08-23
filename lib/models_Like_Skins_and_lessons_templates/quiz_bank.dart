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

  // Unit 7 — Spending Traps (middle school)
  static const String wantsVsNeeds = 'wants_vs_needs';
  static const String advertising = 'advertising';
  static const String digitalSpending = 'digital_spending';
  static const String impulseControl = 'impulse_control';
  static const String scams = 'scams';

  // Unit 8 — Money by the Numbers (high school)
  static const String percentages = 'percentages';
  static const String averages = 'averages';
  static const String chartReading = 'chart_reading';
  static const String misleadingCharts = 'misleading_charts';
  static const String spendingTracking = 'spending_tracking';

  // Unit 9 — Retirement and the 401(k) (adult)
  static const String retirementAccounts = 'retirement_accounts';
  static const String employerMatch = 'employer_match';
  static const String rothVsTraditional = 'roth_vs_traditional';
  static const String startingEarly = 'starting_early';
  static const String feesAndVesting = 'fees_vesting';

  // Unit 10 — Money Is Real (ages 4-6)
  static const String earlyMoneyBasics = 'early_money_basics';
  static const String earlySaving = 'early_saving';

  // Unit 11 — Saving and Spending (ages 7-10)
  static const String allowanceEarning = 'allowance_earning';
  static const String simpleSavingsPlan = 'simple_savings_plan';

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
    wantsVsNeeds => 'Wants vs needs',
    advertising => 'Spotting advertising',
    digitalSpending => 'Digital and in-game spending',
    impulseControl => 'Impulse control',
    scams => 'Scams and fake deals',
    percentages => 'Percentages',
    averages => 'Averages and medians',
    chartReading => 'Reading charts',
    misleadingCharts => 'Misleading charts',
    spendingTracking => 'Tracking your spending',
    retirementAccounts => 'Retirement accounts',
    employerMatch => 'Employer match',
    rothVsTraditional => 'Roth vs traditional',
    startingEarly => 'Starting early',
    feesAndVesting => 'Fees and vesting',
    earlyMoneyBasics => 'What money is',
    earlySaving => 'Saving in a piggy bank',
    allowanceEarning => 'Earning an allowance',
    simpleSavingsPlan => 'Making a simple plan',
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
  QuizQuestion(
    id: 'u5q4',
    skillId: QuizSkills.taxes,
    prompt: 'Which form tells your employer how much tax to withhold?',
    options: ['W-2', 'W-4', 'Form 1040', 'A sales receipt'],
    correctIndex: 1,
    explanation:
        'The W-4 is the employee withholding form. A W-2 reports what you '
        'earned and what was withheld after the year is over.',
  ),
  QuizQuestion(
    id: 'u5q5',
    skillId: QuizSkills.taxes,
    prompt: 'Payroll taxes mainly fund:',
    options: [
      'Social Security and Medicare',
      'Private schools',
      'Sports teams',
      'Your employer\'s profits',
    ],
    correctIndex: 0,
    explanation:
        'Payroll taxes include Social Security and Medicare taxes. They are '
        'separate from ordinary federal income tax withholding.',
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
  QuizQuestion(
    id: 'u5t7',
    skillId: QuizSkills.taxes,
    prompt: r'A $80 pair of jeans has 6% sales tax. The total price is:',
    options: [r'$80.60', r'$84.80', r'$86.00', r'$88.00'],
    correctIndex: 1,
    explanation:
        r'6% of $80 is $4.80, so the total is $84.80. Sales tax is added at '
        'purchase rather than withheld from a paycheck.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u5t8',
    skillId: QuizSkills.taxes,
    prompt: 'A tax credit is different from a deduction because a credit:',
    options: [
      'Lowers taxable income before tax is calculated',
      'Only applies to sales tax',
      'Lowers the actual tax bill dollar-for-dollar',
      'Increases withholding automatically',
    ],
    correctIndex: 2,
    explanation:
        'Deductions reduce taxable income. Credits reduce the tax owed after '
        'the bill is calculated.',
  ),
  QuizQuestion(
    id: 'u5t9',
    skillId: QuizSkills.taxes,
    prompt:
        'Lucas earned summer lifeguard wages below the filing threshold, but '
        'tax was withheld. A smart next step is to:',
    options: [
      'Ignore it because filing is impossible',
      'File if needed or useful so withheld tax can be refunded',
      'Claim payroll taxes from his employer in cash',
      'Wait three years before checking the W-2',
    ],
    correctIndex: 1,
    explanation:
        'Even when income is low enough that filing may not be required, filing '
        'can still be useful if income tax was withheld and a refund is due.',
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
  'quiz_7': _unit7Quiz,
  'test_7': _unit7Test,
  'quiz_8': _unit8Quiz,
  'test_8': _unit8Test,
  'quiz_9': _unit9Quiz,
  'test_9': _unit9Test,
  'quiz_10': _unit10Quiz,
  'test_10': _unit10Test,
  'quiz_11': _unit11Quiz,
  'test_11': _unit11Test,
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
    prompt:
        'Selling everything during a sharp crash most often backfires because:',
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
      'unit_7': _unit7Practice,
      'unit_8': _unit8Practice,
      'unit_9': _unit9Practice,
      'unit_10': _unit10Practice,
      'unit_11': _unit11Practice,
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

// ---------------------------------------------------------------------------
// Unit 7 - Spending Traps (ages 11-13)
// ---------------------------------------------------------------------------

const List<QuizQuestion> _unit7Practice = <QuizQuestion>[
  QuizQuestion(
    id: 'u7p1',
    skillId: QuizSkills.wantsVsNeeds,
    prompt: 'Which of these is a need rather than a want?',
    options: [
      'The bus fare that gets you to school',
      'The newest phone when yours still works',
      'A skin for your favourite game',
      'Concert tickets your friends are buying',
    ],
    correctIndex: 0,
    explanation:
        'A need is something your day genuinely stops working without. '
        'Everything else is a want, no matter how badly you want it.',
    misconception:
        'Wanting something a lot does not promote it to a need. Urgency is a '
        'feeling; necessity is a fact.',
  ),
  QuizQuestion(
    id: 'u7p2',
    skillId: QuizSkills.advertising,
    prompt: 'A creator you follow is paid to show a product. That makes them:',
    options: [
      'A neutral reviewer, since they used it',
      'An advertisement with a friendly face',
      'Legally required to dislike it',
      'Irrelevant to your decision either way',
    ],
    correctIndex: 1,
    explanation:
        'Paid promotion is advertising. It can still be honest, but it was '
        'bought, and you should weigh it that way.',
    misconception:
        'Trusting a recommendation because the person feels familiar is '
        'exactly the effect the sponsor paid for.',
  ),
  QuizQuestion(
    id: 'u7p3',
    skillId: QuizSkills.digitalSpending,
    prompt: 'You spend 800 in-game coins that cost real money. You have:',
    options: [
      'Spent nothing, since coins are not real',
      'Spent only if you buy more coins later',
      'Spent real money already, when you bought the coins',
      'Made an investment you can cash out',
    ],
    correctIndex: 2,
    explanation:
        'The real cost happened when you converted money into coins. Game '
        'currency is designed to make that moment feel far away.',
    misconception:
        'Treating in-game currency as free is the whole reason it exists as a '
        'separate currency.',
  ),
  QuizQuestion(
    id: 'u7p4',
    skillId: QuizSkills.impulseControl,
    prompt: 'What does a 24-hour rule mostly protect you from?',
    options: [
      'Prices going up overnight',
      'Ever buying anything fun',
      'Running out of storage space',
      'Buying because of how you felt for ten minutes',
    ],
    correctIndex: 3,
    explanation:
        'A day is long enough for the excitement to fade. If you still want it '
        'tomorrow, it was probably a real want.',
  ),
];

const List<QuizQuestion> _unit7Quiz = <QuizQuestion>[
  QuizQuestion(
    id: 'u7q1',
    skillId: QuizSkills.wantsVsNeeds,
    prompt:
        'You have 40 coins. Lunch costs 15, and a limited-time skin costs 35. '
        'What does the wants-versus-needs test say?',
    options: [
      'Buy the skin - limited time means it is urgent',
      'Cover the 15 first, then decide about the rest',
      'Split it evenly so both get something',
      'Skip lunch, since you can eat at home later',
    ],
    correctIndex: 1,
    explanation:
        'Needs get funded first, then wants compete for what is left. '
        '"Limited time" is a pressure tactic, not a reason.',
    misconception:
        'Scarcity language is engineered to make wants feel like needs.',
  ),
  QuizQuestion(
    id: 'u7q2',
    skillId: QuizSkills.advertising,
    prompt: 'The main job of an advert is to:',
    options: [
      'Inform you accurately about all options',
      'Compare the product fairly with rivals',
      'Change how you feel so you act',
      'Warn you about the weaknesses of the product',
    ],
    correctIndex: 2,
    explanation:
        'Adverts sell a feeling first and a product second. Knowing that is '
        'most of the defence.',
  ),
  QuizQuestion(
    id: 'u7q3',
    skillId: QuizSkills.digitalSpending,
    prompt:
        'A game sells coins in bundles: 100 for 1 unit, or 1200 for 10. Why '
        'is the big bundle offered?',
    options: [
      'It is cheaper per coin, so more money gets spent up front',
      'Small bundles are illegal in most places',
      'Large bundles have better graphics',
      'It costs the company more to sell small ones',
    ],
    correctIndex: 0,
    explanation:
        'A better unit price is real - but the design goal is a bigger single '
        'payment and a balance you will feel obliged to use.',
    misconception:
        'A discount per unit is only a saving if you were going to buy that '
        'much anyway.',
  ),
  QuizQuestion(
    id: 'u7q4',
    skillId: QuizSkills.scams,
    prompt: 'A message says you won a prize but must pay postage first. This:',
    options: [
      'Is normal for large prizes',
      'Is safe if the postage is small',
      'Is fine if the sender knows your name',
      'Is an advance-fee scam - real prizes never charge you',
    ],
    correctIndex: 3,
    explanation:
        'Any prize that requires a payment from you is not a prize. The small '
        'fee is the entire point of the scam.',
  ),
  QuizQuestion(
    id: 'u7q5',
    skillId: QuizSkills.impulseControl,
    prompt: 'Which habit best reduces regret purchases?',
    options: [
      'Keeping a written list of what you are saving for',
      'Removing the price from your mind while shopping',
      'Buying quickly before you talk yourself out of it',
      'Only shopping when you feel low',
    ],
    correctIndex: 0,
    explanation:
        'A concrete goal gives every impulse something to lose to. Without one, '
        'every purchase competes against nothing.',
  ),
];

const List<QuizQuestion> _unit7Test = <QuizQuestion>[
  QuizQuestion(
    id: 'u7t1',
    skillId: QuizSkills.wantsVsNeeds,
    prompt: 'The clearest sign something is a want, not a need, is that:',
    options: [
      'It costs more than 50 coins',
      'Your day still works without it',
      'Your friends do not have one',
      'It is sold online rather than in shops',
    ],
    correctIndex: 1,
    explanation:
        'Price does not decide the category. A cheap thing you do not need is '
        'still a want; an expensive bus pass can still be a need.',
  ),
  QuizQuestion(
    id: 'u7t2',
    skillId: QuizSkills.advertising,
    prompt:
        'An advert shows people laughing on a beach holding a drink. What is '
        'being sold?',
    options: [
      'Information about the ingredients',
      'A comparison against other drinks',
      'The feeling of belonging, attached to the drink',
      'A discount for buying today',
    ],
    correctIndex: 2,
    explanation:
        'Almost nothing in that advert is about the product. The association '
        'is the product.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u7t3',
    skillId: QuizSkills.digitalSpending,
    prompt: 'Why do games use their own currency instead of real prices?',
    options: [
      'It is required by app stores',
      'It converts more accurately',
      'It reduces their taxes',
      'It hides the real cost behind an extra conversion step',
    ],
    correctIndex: 3,
    explanation:
        'One extra step between your money and the purchase is enough to blunt '
        'the feeling of spending. That is the design.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u7t4',
    skillId: QuizSkills.scams,
    prompt: 'Which is the strongest warning sign of a scam?',
    options: [
      'Pressure to act right now and keep it quiet',
      'A website that looks slightly old',
      'A brand name you have not heard of',
      'A price lower than a shop nearby',
    ],
    correctIndex: 0,
    explanation:
        'Urgency plus secrecy is the signature. It exists to stop you asking '
        'an adult you trust.',
    misconception:
        'Scams are not identified by how polished they look - plenty look '
        'excellent.',
  ),
  QuizQuestion(
    id: 'u7t5',
    skillId: QuizSkills.impulseControl,
    prompt:
        'You want a 60-coin item and earn 15 a week. Waiting 24 hours means:',
    options: [
      'You lose the item permanently',
      'You still need four weeks either way, so nothing is lost by thinking',
      'The price will drop automatically',
      'You should buy it on credit instead',
    ],
    correctIndex: 1,
    explanation:
        'When you cannot afford it today anyway, the only thing waiting costs '
        'you is the impulse - and that is the thing worth losing.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u7t6',
    skillId: QuizSkills.wantsVsNeeds,
    prompt: 'Two friends both call a new console a need. The honest test is:',
    options: [
      'Whether more than half your friends agree',
      'Whether the shop calls it essential',
      'Whether skipping it actually breaks something in your week',
      'Whether you have wanted it for over a month',
    ],
    correctIndex: 2,
    explanation:
        'Wanting something for a long time makes it a persistent want, not a '
        'need. The test is consequence, not duration or popularity.',
  ),
];

// ---------------------------------------------------------------------------
// Unit 8 - Money by the Numbers (ages 14-17)
// ---------------------------------------------------------------------------

const List<QuizQuestion> _unit8Practice = <QuizQuestion>[
  QuizQuestion(
    id: 'u8p1',
    skillId: QuizSkills.percentages,
    prompt: 'A 200-coin jacket is 25% off. You pay:',
    options: ['175', '150', '160', '125'],
    correctIndex: 1,
    explanation: '25% of 200 is 50, so the price is 200 - 50 = 150.',
  ),
  QuizQuestion(
    id: 'u8p2',
    skillId: QuizSkills.averages,
    prompt: 'The average of 4, 6 and 20 is:',
    options: ['6', '8', '10', '30'],
    correctIndex: 2,
    explanation: '4 + 6 + 20 = 30, divided by 3 gives 10.',
    misconception:
        'The average here is larger than two of the three values - one big '
        'number drags it up. That is exactly why medians exist.',
  ),
  QuizQuestion(
    id: 'u8p3',
    skillId: QuizSkills.chartReading,
    prompt: 'On a price chart, the horizontal axis almost always shows:',
    options: ['Time', 'Number of buyers', 'Company profit', 'Risk level'],
    correctIndex: 0,
    explanation:
        'Price on the vertical, time on the horizontal. Check both labels '
        'before reading any shape into the line.',
  ),
  QuizQuestion(
    id: 'u8p4',
    skillId: QuizSkills.spendingTracking,
    prompt: 'The most useful thing tracking your spending gives you is:',
    options: [
      'A guarantee you will spend less',
      'Proof for your parents',
      'A tidier phone home screen',
      'Real numbers instead of a guess about where money went',
    ],
    correctIndex: 3,
    explanation:
        'Tracking does not stop spending by itself. It replaces a vague memory '
        'with data you can actually act on.',
  ),
];

const List<QuizQuestion> _unit8Quiz = <QuizQuestion>[
  QuizQuestion(
    id: 'u8q1',
    skillId: QuizSkills.percentages,
    prompt: 'A price falls 50%, then rises 50%. Compared with the start it is:',
    options: [
      'Back where it started',
      'Still down 25%',
      'Up 25%',
      'Impossible to tell',
    ],
    correctIndex: 1,
    explanation:
        '100 falls to 50, then rises by half of 50 to 75. Percentages apply to '
        'whatever the current number is, not the original.',
    misconception:
        'Adding and subtracting the same percentage does not cancel out - this '
        'trips up far more adults than teenagers.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u8q2',
    skillId: QuizSkills.averages,
    prompt:
        'Nine people earn 30 and one earns 1000. Which better describes a '
        'typical earner?',
    options: [
      'The average, 127',
      'The median, 30',
      'The highest value, 1000',
      'The total, 1270',
    ],
    correctIndex: 1,
    explanation:
        'The median is the middle value, so one extreme cannot drag it. When a '
        'headline quotes an average income, ask what the median was.',
  ),
  QuizQuestion(
    id: 'u8q3',
    skillId: QuizSkills.misleadingCharts,
    prompt: 'A chart whose vertical axis starts at 98 instead of 0 will:',
    options: [
      'Show the data more accurately',
      'Hide the largest values',
      'Make small changes look dramatic',
      'Have no effect on how it reads',
    ],
    correctIndex: 2,
    explanation:
        'A truncated axis stretches tiny movements into cliffs. Always check '
        'where the vertical axis begins.',
  ),
  QuizQuestion(
    id: 'u8q4',
    skillId: QuizSkills.chartReading,
    prompt: 'A line that looks calm over a year and wild over a day means:',
    options: [
      'The day view is zoomed in, so normal noise fills the screen',
      'Something serious happened that day',
      'The yearly chart is wrong',
      'The company changed its share count',
    ],
    correctIndex: 0,
    explanation:
        'Zoom changes the story. The same 1% wobble is invisible on a year and '
        'looks like a crash on an hour.',
  ),
  QuizQuestion(
    id: 'u8q5',
    skillId: QuizSkills.spendingTracking,
    prompt:
        'You tracked a month and found 40% went to food delivery. The useful '
        'next step is:',
    options: [
      'Stop tracking, since you already know now',
      'Set a specific limit for that one category and watch it',
      'Cut every category by 40%',
      'Assume next month will be different',
    ],
    correctIndex: 1,
    explanation:
        'Data is only worth collecting if it changes a decision. One targeted '
        'limit beats a vague resolve to spend less.',
  ),
];

const List<QuizQuestion> _unit8Test = <QuizQuestion>[
  QuizQuestion(
    id: 'u8t1',
    skillId: QuizSkills.percentages,
    prompt: 'Which is the largest amount of money?',
    options: ['20% of 400', '5% of 2000', '50% of 150', 'They are all equal'],
    correctIndex: 1,
    explanation:
        '20% of 400 is 80, 5% of 2000 is 100, and 50% of 150 is 75. The '
        'smallest-looking rate wins because its base is far bigger.',
    misconception:
        'A larger percentage of a smaller base is often less money. The base '
        'matters as much as the rate.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u8t2',
    skillId: QuizSkills.averages,
    prompt: 'An average is a poor summary when the data:',
    options: [
      'Contains a few extreme values',
      'Has more than ten entries',
      'Is measured in coins',
      'Was collected over a year',
    ],
    correctIndex: 0,
    explanation:
        'Outliers pull the mean toward themselves. In skewed data the median '
        'describes the typical case far better.',
  ),
  QuizQuestion(
    id: 'u8t3',
    skillId: QuizSkills.misleadingCharts,
    prompt:
        'An advert shows a fund\'s best 3 months out of 5 years. The problem:',
    options: [
      'The chart type is wrong',
      'Three months is too short to plot',
      'Past results are always irrelevant',
      'The window was chosen after the fact to flatter the result',
    ],
    correctIndex: 3,
    explanation:
        'Cherry-picking the window is the oldest trick in financial marketing. '
        'Ask what the full period looks like.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u8t4',
    skillId: QuizSkills.chartReading,
    prompt: 'Before drawing any conclusion from a chart, check:',
    options: [
      'Both axis labels and the time range',
      'The colour scheme',
      'Whether the line is straight',
      'How many people shared it',
    ],
    correctIndex: 0,
    explanation:
        'Axes and range decide what the shape means. The shape alone means '
        'nothing.',
  ),
  QuizQuestion(
    id: 'u8t5',
    skillId: QuizSkills.spendingTracking,
    prompt:
        'You spend 12 a week on a subscription you use twice a year. Over a '
        'year that is roughly:',
    options: ['144', '624', '96', '312'],
    correctIndex: 1,
    explanation:
        '12 x 52 = 624. Small recurring amounts are where tracking pays for '
        'itself - nobody notices 12 a week until they annualise it.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u8t6',
    skillId: QuizSkills.percentages,
    prompt: 'Your 500-coin holding grows 10%, then loses 10%. You now have:',
    options: ['500', '505', '495', '450'],
    correctIndex: 2,
    explanation:
        '500 becomes 550, then loses 55 to land at 495. Gains and losses of the '
        'same percentage never cancel exactly.',
  ),
];

// ---------------------------------------------------------------------------
// Unit 9 - Retirement and the 401(k) (ages 21+)
// ---------------------------------------------------------------------------

const List<QuizQuestion> _unit9Practice = <QuizQuestion>[
  QuizQuestion(
    id: 'u9p1',
    skillId: QuizSkills.retirementAccounts,
    prompt: 'A 401(k) is best described as:',
    options: [
      'A savings account your employer controls',
      'A tax-advantaged account you invest in through work',
      'A loan against your future salary',
      'A government pension paid automatically',
    ],
    correctIndex: 1,
    explanation:
        'The money is yours and you choose the investments inside it. The tax '
        'treatment is what makes it different from an ordinary account.',
  ),
  QuizQuestion(
    id: 'u9p2',
    skillId: QuizSkills.employerMatch,
    prompt:
        'Your employer matches 100% of the first 4% you contribute. Skipping '
        'that 4% means:',
    options: [
      'Turning down a 4% raise you already earned',
      'Nothing, since you can catch up later',
      'A smaller tax bill this year',
      'Better take-home pay overall',
    ],
    correctIndex: 0,
    explanation:
        'A match is part of your compensation. Not contributing enough to get '
        'it is leaving agreed pay on the table.',
  ),
  QuizQuestion(
    id: 'u9p3',
    skillId: QuizSkills.rothVsTraditional,
    prompt: 'With a Roth account you pay tax:',
    options: [
      'Never, on anything',
      'Twice - going in and coming out',
      'Now, on the money going in',
      'Only if you withdraw early',
    ],
    correctIndex: 2,
    explanation:
        'Roth means tax paid up front, and qualified withdrawals later come '
        'out untaxed. Traditional is the reverse.',
  ),
  QuizQuestion(
    id: 'u9p4',
    skillId: QuizSkills.startingEarly,
    prompt: 'The main advantage of starting at 22 rather than 35 is:',
    options: [
      'Lower fees for young investors',
      'Higher returns are offered early on',
      'Guaranteed employer bonuses',
      'Thirteen extra years of compounding on every coin',
    ],
    correctIndex: 3,
    explanation:
        'Time is the input you can never buy back later. The early coins do '
        'the most work because they compound the longest.',
  ),
];

const List<QuizQuestion> _unit9Quiz = <QuizQuestion>[
  QuizQuestion(
    id: 'u9q1',
    skillId: QuizSkills.employerMatch,
    prompt:
        'You earn 40,000 and your employer matches 50% of the first 6% you put '
        'in. Contributing the full 6% earns you:',
    options: ['600', '1,200', '2,400', 'Nothing extra'],
    correctIndex: 1,
    explanation:
        '6% of 40,000 is 2,400, and the employer adds half of that: 1,200.',
    misconception:
        'Read match formulas carefully - "50% of the first 6%" is not the same '
        'as "6%".',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u9q2',
    skillId: QuizSkills.rothVsTraditional,
    prompt: 'You expect to earn much more later. That leans toward:',
    options: [
      'Traditional, to pay tax at the higher future rate',
      'Roth, paying tax now while your rate is low',
      'Neither - the choice never matters',
      'Whichever has the larger balance',
    ],
    correctIndex: 1,
    explanation:
        'Pay the tax when your rate is lowest. Early career is usually that '
        'moment, which is why Roth suits people starting out.',
  ),
  QuizQuestion(
    id: 'u9q3',
    skillId: QuizSkills.feesAndVesting,
    prompt: 'A vesting schedule decides:',
    options: [
      'How your money is invested',
      'When you can retire',
      'When employer contributions become permanently yours',
      'What tax rate applies to withdrawals',
    ],
    correctIndex: 2,
    explanation:
        'Your own contributions are always yours. The match may need a few '
        'years of service before you keep it if you leave.',
  ),
  QuizQuestion(
    id: 'u9q4',
    skillId: QuizSkills.retirementAccounts,
    prompt: 'Withdrawing from a retirement account at 30 usually means:',
    options: [
      'A penalty plus tax, on top of losing the growth',
      'A small paperwork fee only',
      'No consequence if you repay within a year',
      'The employer must approve it first',
    ],
    correctIndex: 0,
    explanation:
        'Early withdrawal costs you three ways: penalty, tax, and every year '
        'of compounding that money would have done.',
  ),
  QuizQuestion(
    id: 'u9q5',
    skillId: QuizSkills.feesAndVesting,
    prompt: 'A fund charging 1% a year instead of 0.05% matters because:',
    options: [
      'One percent is a legal maximum',
      'Cheaper funds always perform better',
      'Fees are charged only in losing years',
      'Over decades that gap compounds into a large share of your balance',
    ],
    correctIndex: 3,
    explanation:
        'Fees are subtracted every year, including the years your money was '
        'compounding. Small percentages become large sums over 40 years.',
  ),
];

const List<QuizQuestion> _unit9Test = <QuizQuestion>[
  QuizQuestion(
    id: 'u9t1',
    skillId: QuizSkills.startingEarly,
    prompt:
        'A saves 200 a month from 25 to 35, then stops. B saves 200 a month '
        'from 35 to 65. At 65, at the same return, typically:',
    options: [
      'B is far ahead, having saved three times as much',
      'A is often ahead or level, despite saving far less',
      'They finish exactly equal',
      'Neither grows without new contributions',
    ],
    correctIndex: 1,
    explanation:
        'A\'s ten years of contributions had thirty extra years to grow, which '
        'usually beats B\'s larger but later total. This is the whole argument '
        'for starting early.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u9t2',
    skillId: QuizSkills.employerMatch,
    prompt: 'The first priority in a retirement plan is usually to:',
    options: [
      'Pick the fund with last year\'s best return',
      'Max out contributions immediately whatever your debts',
      'Contribute at least enough to get the full employer match',
      'Wait until you earn more',
    ],
    correctIndex: 2,
    explanation:
        'The match is an immediate, guaranteed return no fund can promise. It '
        'comes before fund-picking or chasing performance.',
  ),
  QuizQuestion(
    id: 'u9t3',
    skillId: QuizSkills.rothVsTraditional,
    prompt: 'Traditional contributions lower your tax bill:',
    options: [
      'In the year you contribute, with tax due on withdrawal',
      'In retirement only',
      'In both years equally',
      'Never - the benefit is purely psychological',
    ],
    correctIndex: 0,
    explanation:
        'Traditional defers the tax. Roth prepays it. Which wins depends on '
        'your tax rate now versus later.',
  ),
  QuizQuestion(
    id: 'u9t4',
    skillId: QuizSkills.feesAndVesting,
    prompt: 'You leave a job two years into a four-year vesting schedule:',
    options: [
      'You lose everything in the account',
      'You keep your own contributions and a partial share of the match',
      'You keep all of it regardless',
      'The account is frozen until you retire',
    ],
    correctIndex: 1,
    explanation:
        'Your contributions are never at risk. How much of the employer money '
        'you keep depends on the schedule.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u9t5',
    skillId: QuizSkills.retirementAccounts,
    prompt: 'Money inside a retirement account is:',
    options: [
      'Held as cash until you retire',
      'Automatically split across every fund available',
      'Invested in whatever you choose from the plan menu',
      'Managed by the government',
    ],
    correctIndex: 2,
    explanation:
        'The account is a wrapper, not an investment. Contributions left '
        'unallocated can sit in cash for years, earning almost nothing.',
    misconception:
        'Opening the account is not the same as investing the money in it - a '
        'genuinely common and expensive mistake.',
  ),
  QuizQuestion(
    id: 'u9t6',
    skillId: QuizSkills.startingEarly,
    prompt: 'The reason 20-somethings are told to start now is that:',
    options: [
      'Returns are higher for younger investors',
      'Contribution limits shrink with age',
      'Employers only match under 30',
      'The cheapest years to buy are the ones you cannot get back',
    ],
    correctIndex: 3,
    explanation:
        'Nothing about the market favours the young. What favours them is the '
        'number of years left for compounding to run.',
  ),
];

// ---------------------------------------------------------------------------
// Unit 10 — Money Is Real (ages 4-6)
// ---------------------------------------------------------------------------

const List<QuizQuestion> _unit10Practice = <QuizQuestion>[
  QuizQuestion(
    id: 'u10p1',
    skillId: QuizSkills.earlyMoneyBasics,
    prompt: 'What can you use money for?',
    options: [
      'Buying things you need or want',
      'Making it rain outside',
      'Turning it into candy by itself',
      'Cleaning your toys by itself',
    ],
    correctIndex: 0,
    explanation:
        'Money is what people trade for the things they need or want, like '
        'food, clothes, or a toy.',
  ),
  QuizQuestion(
    id: 'u10p2',
    skillId: QuizSkills.earlyMoneyBasics,
    prompt: 'Where does most money come from?',
    options: [
      'People earn it by working, or get it as a gift',
      'It grows on trees',
      'Everyone is born with a big pile of it',
      'It only exists inside video games',
    ],
    correctIndex: 0,
    explanation:
        'Grown-ups usually earn money by working. Sometimes money is given as '
        'a gift too, like on a birthday.',
  ),
  QuizQuestion(
    id: 'u10p3',
    skillId: QuizSkills.earlySaving,
    prompt: 'What is a piggy bank for?',
    options: [
      'Keeping money safe until you want to use it later',
      'Feeding a real pig',
      'Throwing coins away',
      'Making a loud noise',
    ],
    correctIndex: 0,
    explanation:
        'A piggy bank holds onto your coins for you, so they are still there '
        'later when you want them.',
  ),
];

const List<QuizQuestion> _unit10Quiz = <QuizQuestion>[
  QuizQuestion(
    id: 'u10q1',
    skillId: QuizSkills.earlyMoneyBasics,
    prompt: 'Why do stores ask for money when you buy something?',
    options: [
      'Money is how you trade for the things you want',
      'Stores like the sound coins make',
      'It makes the toy work better',
      'The cashier keeps every toy for themselves',
    ],
    correctIndex: 0,
    explanation:
        'Buying something means trading your money for it. That is what '
        'money is for.',
  ),
  QuizQuestion(
    id: 'u10q2',
    skillId: QuizSkills.earlyMoneyBasics,
    prompt: 'Which of these do you pay for with money?',
    options: [
      'Sunshine',
      'A hug from a friend',
      'A new toy at the store',
      'A rainbow',
    ],
    correctIndex: 2,
    explanation:
        'A toy at the store costs money. Sunshine, hugs, and rainbows are '
        'free.',
  ),
  QuizQuestion(
    id: 'u10q3',
    skillId: QuizSkills.earlySaving,
    prompt: 'If you save one coin every week, what happens over many weeks?',
    options: [
      'Nothing changes',
      'You end up with more coins than you started with',
      'Your coins disappear',
      'The piggy bank eats them',
    ],
    correctIndex: 1,
    explanation:
        'Every coin you save adds to the ones already there, so your savings '
        'grow bigger over time.',
  ),
  QuizQuestion(
    id: 'u10q4',
    skillId: QuizSkills.earlySaving,
    prompt:
        'You get two coins and put both in your piggy bank instead of '
        'spending them. What did you just do?',
    options: ['Lost your coins', 'Spent your coins', 'Traded your coins', 'Saved your coins'],
    correctIndex: 3,
    explanation:
        'Putting money away instead of spending it right away is called '
        'saving.',
  ),
];

const List<QuizQuestion> _unit10Test = <QuizQuestion>[
  QuizQuestion(
    id: 'u10t1',
    skillId: QuizSkills.earlyMoneyBasics,
    prompt: 'What is money used for?',
    options: [
      'Trading for things you need or want',
      'Decorating your room',
      'Making your food taste better',
      'Nothing — it is just for looking at',
    ],
    correctIndex: 0,
    explanation: 'Money is a tool people trade for things they need or want.',
  ),
  QuizQuestion(
    id: 'u10t2',
    skillId: QuizSkills.earlySaving,
    prompt: 'Why might you choose to save a coin instead of spending it right away?',
    options: [
      'So it disappears faster',
      'So you have it later for something you want more',
      'Coins are not allowed to be spent',
      'Saving makes the coin bigger',
    ],
    correctIndex: 1,
    explanation:
        'Saving means waiting, so the money is still there when you decide '
        'you really want something.',
  ),
  QuizQuestion(
    id: 'u10t3',
    skillId: QuizSkills.earlyMoneyBasics,
    prompt: 'A grown-up goes to work. Why?',
    options: [
      'To pass the time',
      'To earn money',
      'Because toys are boring',
      'Because the store told them to',
    ],
    correctIndex: 1,
    explanation:
        'Working is one of the main ways grown-ups earn the money they use '
        'to buy things.',
  ),
  QuizQuestion(
    id: 'u10t4',
    skillId: QuizSkills.earlySaving,
    prompt: 'Where is a good safe place to keep coins you want to save?',
    options: ['On the floor', 'In a piggy bank', 'Outside in the rain', 'In your mouth'],
    correctIndex: 1,
    explanation: 'A piggy bank keeps your coins together and safe until you need them.',
  ),
  QuizQuestion(
    id: 'u10t5',
    skillId: QuizSkills.earlyMoneyBasics,
    prompt: 'You want a toy at the store. What do you need to get it?',
    options: [
      'Enough money to pay for it',
      'A loud voice',
      'A different toy to trade the cashier',
      'Nothing, toys are free',
    ],
    correctIndex: 0,
    explanation: 'Buying something at a store means paying enough money for it.',
  ),
  QuizQuestion(
    id: 'u10t6',
    skillId: QuizSkills.earlySaving,
    prompt: 'You have 3 coins. You spend all 3 on candy. How many coins are left to save?',
    options: ['3', '2', '1', '0'],
    correctIndex: 3,
    explanation: 'Spending all of your coins means none are left to save.',
  ),
  QuizQuestion(
    id: 'u10t7',
    skillId: QuizSkills.earlyMoneyBasics,
    prompt: 'Which one of these is something you would buy with money?',
    options: ['A birthday balloon', 'The moon', 'A cloud', 'A shadow'],
    correctIndex: 0,
    explanation:
        'A balloon is something a store sells, so you would pay money for '
        'it. The moon, clouds, and shadows are not for sale.',
  ),
];

// ---------------------------------------------------------------------------
// Unit 11 — Saving and Spending (ages 7-10)
// ---------------------------------------------------------------------------

const List<QuizQuestion> _unit11Practice = <QuizQuestion>[
  QuizQuestion(
    id: 'u11p1',
    skillId: QuizSkills.allowanceEarning,
    prompt: 'What is an allowance?',
    options: [
      'Money you get, often for doing chores or as a regular gift',
      'A rule that stops you from ever spending money',
      'A kind of bank account only adults can open',
      'Money you find on the ground',
    ],
    correctIndex: 0,
    explanation:
        'An allowance is money a kid gets on a regular basis — sometimes for '
        'doing chores, sometimes just as a set amount.',
  ),
  QuizQuestion(
    id: 'u11p2',
    skillId: QuizSkills.wantsVsNeeds,
    prompt: 'Which of these is a want, not a need?',
    options: ['A warm coat in winter', 'A new video game', 'Food for dinner', 'A place to sleep'],
    correctIndex: 1,
    explanation:
        'A need is something you cannot really do without. A video game is '
        'fun, but you can live without it — that makes it a want.',
  ),
  QuizQuestion(
    id: 'u11p3',
    skillId: QuizSkills.simpleSavingsPlan,
    prompt: 'You get \$10. What is a simple plan for it?',
    options: [
      'Decide how much to save and how much to spend, before spending any',
      'Spend all of it the same day without thinking',
      'Give it all away right away',
      'Hide it and forget where it is',
    ],
    correctIndex: 0,
    explanation:
        'A simple plan just means deciding ahead of time how much you will '
        'save and how much you will spend, instead of spending first and '
        'thinking later.',
  ),
];

const List<QuizQuestion> _unit11Quiz = <QuizQuestion>[
  QuizQuestion(
    id: 'u11q1',
    skillId: QuizSkills.allowanceEarning,
    prompt: 'Doing a chore to earn money is an example of:',
    options: [
      'Saving',
      'Spending',
      'Earning',
      'Borrowing',
    ],
    correctIndex: 2,
    explanation: 'Earning means getting money in exchange for doing something, like a chore.',
  ),
  QuizQuestion(
    id: 'u11q2',
    skillId: QuizSkills.wantsVsNeeds,
    prompt: 'Your shoes have holes and hurt your feet. New shoes are a:',
    options: ['Want', 'Need', 'Trick', 'Toy'],
    correctIndex: 1,
    explanation: 'Shoes that actually work are a need — you use them every day and cannot go without them.',
  ),
  QuizQuestion(
    id: 'u11q3',
    skillId: QuizSkills.simpleSavingsPlan,
    prompt: 'You get \$5 a week. You decide to save \$2 and spend \$3 every week. This is called:',
    options: ['A trade', 'A plan', 'A loan', 'A gift'],
    correctIndex: 1,
    explanation: 'Deciding ahead of time how to split your money between saving and spending is a plan.',
  ),
  QuizQuestion(
    id: 'u11q4',
    skillId: QuizSkills.banking,
    prompt: 'Why might a family keep money in a bank instead of just at home?',
    options: [
      'Banks pay you to watch your money',
      'Banks keep money safer than a drawer at home',
      'Banks turn money into gold',
      'It is a rule that money must live in a bank',
    ],
    correctIndex: 1,
    explanation:
        'Banks are built to keep money safe — safer than leaving cash lying '
        'around the house.',
  ),
];

const List<QuizQuestion> _unit11Test = <QuizQuestion>[
  QuizQuestion(
    id: 'u11t1',
    skillId: QuizSkills.allowanceEarning,
    prompt: 'Which of these is a way to earn money?',
    options: [
      'Doing chores for a parent who pays you',
      'Wishing really hard',
      'Waiting for money to appear',
      'Asking a stranger for money',
    ],
    correctIndex: 0,
    explanation: 'Doing a chore for pay is a simple, real way kids earn money.',
  ),
  QuizQuestion(
    id: 'u11t2',
    skillId: QuizSkills.wantsVsNeeds,
    prompt: 'Which of these is a need?',
    options: ['A poster for your wall', 'Dinner tonight', 'A new toy', 'Extra stickers'],
    correctIndex: 1,
    explanation: 'Food is something your body needs regularly — that makes it a need, not a want.',
  ),
  QuizQuestion(
    id: 'u11t3',
    skillId: QuizSkills.simpleSavingsPlan,
    prompt: 'You want to buy a \$20 toy. You save \$5 a week. About how many weeks until you can buy it?',
    options: ['1 week', '2 weeks', '4 weeks', '10 weeks'],
    correctIndex: 2,
    explanation: 'Saving \$5 a week for 4 weeks adds up to \$20.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u11t4',
    skillId: QuizSkills.banking,
    prompt: 'A bank is a place that mainly:',
    options: [
      'Sells toys',
      'Keeps money safe and helps people save it',
      'Gives away free money to anyone who asks',
      'Only lets grown-ups inside',
    ],
    correctIndex: 1,
    explanation: 'A bank\'s main job is keeping money safe and helping people save and manage it.',
  ),
  QuizQuestion(
    id: 'u11t5',
    skillId: QuizSkills.allowanceEarning,
    prompt: 'You do the dishes every day and get \$1 each time. After 5 days, how much have you earned?',
    options: ['\$1', '\$3', '\$5', '\$10'],
    correctIndex: 2,
    explanation: '\$1 a day for 5 days adds up to \$5.',
    difficulty: QuizDifficulty.stretch,
  ),
  QuizQuestion(
    id: 'u11t6',
    skillId: QuizSkills.wantsVsNeeds,
    prompt: 'Why is it useful to know the difference between a need and a want?',
    options: [
      'So you always buy wants first',
      'So you can decide what really matters before you spend',
      'Needs are not allowed to be bought',
      'It has no real use',
    ],
    correctIndex: 1,
    explanation:
        'Knowing needs from wants helps you decide what to spend money on '
        'first when you cannot buy everything.',
  ),
  QuizQuestion(
    id: 'u11t7',
    skillId: QuizSkills.simpleSavingsPlan,
    prompt: 'What is the first step in making a simple money plan?',
    options: [
      'Spend everything, then see what is left',
      'Decide how much to save before you spend anything',
      'Ask a friend to hold your money',
      'Forget about the money completely',
    ],
    correctIndex: 1,
    explanation:
        'A plan works best when you decide the saving amount first, before '
        'any spending happens.',
  ),
];
