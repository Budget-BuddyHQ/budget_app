import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../widgets_custom_lotties/game_toast.dart';

class FinanceBrawlCloseResult {
  const FinanceBrawlCloseResult({
    required this.goldEarned,
    required this.xpEarned,
    required this.syncState,
  });

  final int goldEarned;
  final int xpEarned;
  final StatsActionResult syncState;
}

class FinanceQuestion {
  const FinanceQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class ShuffledQuizQuestion {
  ShuffledQuizQuestion({
    required this.question,
    required this.shuffledOptions,
    required this.correctOptionText,
    required this.explanation,
  });

  final String question;
  final List<String> shuffledOptions;
  final String correctOptionText;
  final String explanation;
}

class BrawlUpgrade {
  const BrawlUpgrade({
    required this.name,
    required this.description,
    required this.icon,
    required this.action,
  });

  final String name;
  final String description;
  final IconData icon;
  final VoidCallback action;
}

class FinanceBrawlScreen extends StatefulWidget {
  const FinanceBrawlScreen({super.key});

  @override
  State<FinanceBrawlScreen> createState() => _FinanceBrawlScreenState();
}

class _FinanceBrawlScreenState extends State<FinanceBrawlScreen> with TickerProviderStateMixin {
  late final Ticker _ticker;
  final FocusNode _keyboardFocusNode = FocusNode();
  
  late Size _canvasSize;
  Offset _playerPos = const Offset(800, 800); 
  final double _playerRadius = 24.0;
  
  // Finance Overhaul: Balance instead of health
  int _bankBalance = 10000;
  final int _maxBankBalance = 10000;
  
  final double _mapWidth = 1600.0;
  final double _mapHeight = 1600.0;
  
  final List<Offset> _treePositions = [];
  final double _treeRadius = 20.0;
  final List<Offset> _rockPositions = [];
  final double _rockRadius = 14.0;
  
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  
  int _debtsCleared = 0;
  int _debtsNeededForLevelUp = 6;
  int _wave = 1;
  int _goldAccumulated = 0;
  int _xpAccumulated = 0;
  bool _isGameOver = false;
  bool _isSavingAndExiting = false;
  bool _bossActive = false;
  
  final double _attackSpeedMultiplier = 1.0;
  double _coinDamage = 35.0;
  final double _coinSpeed = 380.0;
  int _coinStreamCount = 1;
  double _playerSpeed = 220.0;

  // Emergency Fund Shield Mechanics
  int _emergencyFundLevel = 0;
  double _shieldAngle = 0.0;
  double _shieldDamageCooldown = 0.0;

  double _lastSpawnTime = 0.0;
  double _lastAttackTime = 0.0;
  double _totalElapsedTime = 0.0;
  
  final List<_FinancialLiability> _liabilities = [];
  final List<_CoinProjectile> _coins = [];
  final List<_Particle> _particles = [];
  final List<_TreasureChest> _chests = [];
  final double _chestRadius = 18.0;
  final Random _rand = Random();

  bool _isQuizOpen = false;
  bool _isUpgradeChoiceOpen = false;
  
  int _quizCorrectCount = 0;
  int _quizQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswerSubmitted = false;
  List<ShuffledQuizQuestion> _activeQuizQuestions = [];

  final List<FinanceQuestion> _questionBank = const [
    // -------------------------------------------------------------
    // BUDGETING & MONEY MANAGEMENT (1-20)
    // -------------------------------------------------------------
    FinanceQuestion(
      question: "What is an 'emergency fund' generally used for?",
      options: [
        "Buying concert tickets",
        "Unexpected critical expenses like medical bills",
        "Investing in volatile trendy stocks",
        "Paying for streaming subscriptions"
      ],
      correctIndex: 1,
      explanation: "An emergency fund protects you against unexpected setbacks without ruining your budget or forcing you into debt.",
    ),
    FinanceQuestion(
      question: "What does 'paying yourself first' mean in budgeting?",
      options: [
        "Buy clothes before paying bills",
        "Put money into savings as soon as you are paid before spending the rest",
        "Give cash to family immediately",
        "Spend your entire check on leisure items"
      ],
      correctIndex: 1,
      explanation: "Prioritizing savings goals first guarantees you build financial security instead of saving only leftover pennies.",
    ),
    FinanceQuestion(
      question: "What is the primary goal of creating a monthly zero-based budget?",
      options: [
        "To spend every dollar on entertainment",
        "To ensure Income minus Expenses equals zero by allocating every dollar a purpose",
        "To reduce your bank account balance to zero",
        "To eliminate all future tax obligations"
      ],
      correctIndex: 1,
      explanation: "A zero-based budget assigns every dollar of income to savings, bills, or spending so nothing goes untracked.",
    ),
    FinanceQuestion(
      question: "Which of the following is considered a variable expense?",
      options: [
        "Fixed monthly rent",
        "Groceries and utility bills",
        "Car loan payment",
        "Annual insurance premium"
      ],
      correctIndex: 1,
      explanation: "Variable expenses fluctuate month to month based on usage and personal choices, unlike fixed rent payments.",
    ),
    FinanceQuestion(
      question: "What is the popular 50/30/20 budgeting rule framework?",
      options: [
        "50% Investments, 30% Savings, 20% Taxes",
        "50% Needs, 30% Wants, 20% Savings/Debt repayment",
        "50% Rent, 30% Food, 20% Travel",
        "50% Debt, 30% Needs, 20% Entertainment"
      ],
      correctIndex: 1,
      explanation: "The 50/30/20 guideline suggests spending 50% on essential needs, 30% on discretionary wants, and 20% on financial goals.",
    ),
    FinanceQuestion(
      question: "What is a 'sinking fund' used for?",
      options: [
        "Paying off defaulted loans",
        "Saving gradually over time for a specific anticipated future expense",
        "A bank account that charges negative interest",
        "An automated stock trading account"
      ],
      correctIndex: 1,
      explanation: "A sinking fund lets you set aside small monthly amounts for planned future costs like car maintenance or holidays.",
    ),
    FinanceQuestion(
      question: "Which expenditure is categorized as a 'Need' rather than a 'Want'?",
      options: [
        "Designer shoes",
        "Essential prescription medication",
        "Video game subscriptions",
        "Dining out at steak houses"
      ],
      correctIndex: 1,
      explanation: "Needs are basic items essential for survival, healthcare, shelter, and employment.",
    ),
    FinanceQuestion(
      question: "How many months of living expenses are typically recommended for a full emergency fund?",
      options: [
        "1 to 2 weeks",
        "3 to 6 months",
        "3 to 5 years",
        "10 years"
      ],
      correctIndex: 1,
      explanation: "Financial advisors generally recommend keeping 3 to 6 months of basic living costs in liquid savings.",
    ),
    FinanceQuestion(
      question: "What happens if you overdraw your checking account without overdraft protection?",
      options: [
        "The bank gives you free credit",
        "The transaction is declined or you incur an overdraft fee",
        "Your credit score increases",
        "Your account is converted into a CD"
      ],
      correctIndex: 1,
      explanation: "Attempting to spend more than your account balance leads to declined transactions or high overdraft penalties.",
    ),
    FinanceQuestion(
      question: "What is opportunistic 'lifestyle creep'?",
      options: [
        "Increasing your savings when your salary drops",
        "Increasing discretionary spending as your income rises, preventing wealth accumulation",
        "Moving into a smaller apartment to save money",
        "Automating bill payments every month"
      ],
      correctIndex: 1,
      explanation: "Lifestyle creep occurs when raises or bonuses trigger higher spending on luxury items instead of boosting savings.",
    ),
    FinanceQuestion(
      question: "Why should you track your daily cash flow and micro-purchases?",
      options: [
        "To satisfy bank auditors",
        "To spot hidden money leaks like forgotten recurring subscriptions",
        "To calculate capital gains taxes on coffee",
        "To double your checking account balance"
      ],
      correctIndex: 1,
      explanation: "Small unmonitored purchases add up rapidly over time and can drain hundreds of dollars from your budget.",
    ),
    FinanceQuestion(
      question: "What is gross income?",
      options: [
        "Income left after taxes and deductions",
        "Total money earned before taxes and payroll deductions are subtracted",
        "Money earned solely from investment dividends",
        "Income spent strictly on household bills"
      ],
      correctIndex: 1,
      explanation: "Gross income is your raw total compensation before income tax, insurance premiums, and retirement contributions are removed.",
    ),
    FinanceQuestion(
      question: "What is net income (take-home pay)?",
      options: [
        "Total salary before tax",
        "The actual money deposited into your account after taxes and deductions",
        "Total profit from selling a house",
        "Total interest paid on credit cards"
      ],
      correctIndex: 1,
      explanation: "Net income is the actual usable money available to spend or save after all paystub withholdings.",
    ),
    FinanceQuestion(
      question: "Which tool automatically moves money into savings without manual intervention?",
      options: [
        "Manual wire transfer",
        "Automated direct deposit allocation or recurring bank transfers",
        "Paper check writing",
        "ATM cash withdrawal"
      ],
      correctIndex: 1,
      explanation: "Automated recurring transfers remove human discipline hurdles and ensure consistent savings habit building.",
    ),
    FinanceQuestion(
      question: "What is an opportunity cost in personal finance?",
      options: [
        "The interest charged by a bank loan",
        "The potential gain lost from another alternative when one choice is made",
        "The tax deduction on charitable donations",
        "The fee charged to open a savings account"
      ],
      correctIndex: 1,
      explanation: "Opportunity cost is the trade-off value—spending \$100 on shoes today means losing future interest if invested.",
    ),
    FinanceQuestion(
      question: "What is the envelope budgeting method?",
      options: [
        "Mailing checks to creditors in physical paper envelopes",
        "Allocating strict cash amounts into labeled envelopes for specific spending categories",
        "Storing investment certificates in a safe",
        "Filing tax returns through postal delivery"
      ],
      correctIndex: 1,
      explanation: "Envelope budgeting relies on cash envelopes for categories like groceries—when the cash runs out, spending stops.",
    ),
    FinanceQuestion(
      question: "Why is discretionary spending dangerous if unmonitored?",
      options: [
        "It lowers your tax refund automatically",
        "It can silently eat into funds required for essential living expenses and debt payments",
        "It causes instant bank account termination",
        "It freezes your credit score"
      ],
      correctIndex: 1,
      explanation: "Discretionary non-essential spending easily expands, causing missed savings targets or unpaid essential bills.",
    ),
    FinanceQuestion(
      question: "Which of these is a fixed expense?",
      options: [
        "Weekly grocery runs",
        "Fixed-rate apartment lease payment",
        "Electric heating bill in winter",
        "Dining out expenses"
      ],
      correctIndex: 1,
      explanation: "Fixed expenses stay predictable and identical in cost across every payment cycle, simplifying planning.",
    ),
    FinanceQuestion(
      question: "What does the term 'solvency' mean for an individual?",
      options: [
        "Having zero cash in hand",
        "Possessing total assets that exceed total financial liabilities and debt",
        "Having multiple credit card accounts open",
        "Earning income solely from dividends"
      ],
      correctIndex: 1,
      explanation: "Solvency means your overall assets outweigh what you owe, ensuring long-term financial stability.",
    ),
    FinanceQuestion(
      question: "What is a major risk of not maintaining a financial buffer?",
      options: [
        "Higher investment returns",
        "Forced reliance on high-interest debt when unexpected costs occur",
        "Decreased tax liability",
        "Lower insurance premiums"
      ],
      correctIndex: 1,
      explanation: "Without savings, sudden repairs or emergencies force people to use high-cost loans or credit cards.",
    ),

    // -------------------------------------------------------------
    // SAVINGS & INTEREST (21-40)
    // -------------------------------------------------------------
    FinanceQuestion(
      question: "If you leave \$100 in a savings account with a 5% annual simple interest rate, how much is there after 1 year?",
      options: ["\$105", "\$100", "\$150", "\$110"],
      correctIndex: 0,
      explanation: "Simple interest calculates 5% of \$100, which yields \$5, bringing your total account balance to \$105.",
    ),
    FinanceQuestion(
      question: "What is compound interest?",
      options: [
        "Interest earned only on your original cash deposit",
        "Interest earned on both your initial principal and previously accumulated interest",
        "A flat fee charged by banks to hold cash",
        "Tax applied directly to high net worth individuals"
      ],
      correctIndex: 1,
      explanation: "Compound interest creates snowball growth because your earned interest generates its own interest over time.",
    ),
    FinanceQuestion(
      question: "What does 'APY' stand for on a bank savings account?",
      options: [
        "Annual Percentage Yield",
        "Automated Payment Year",
        "Asset Allocation Profit Yield",
        "Average Principal Yield"
      ],
      correctIndex: 0,
      explanation: "APY reflects the actual total interest earned over a year, accounting for compounding frequency.",
    ),
    FinanceQuestion(
      question: "What is the 'Rule of 72' used to estimate?",
      options: [
        "The number of years required to double an investment at a fixed interest rate",
        "The percentage of income to spend on housing",
        "The age everyone must retire",
        "The maximum credit score attainable"
      ],
      correctIndex: 0,
      explanation: "Dividing 72 by your annual interest rate gives the approximate years it takes for your principal to double.",
    ),
    FinanceQuestion(
      question: "At a 6% annual return rate, roughly how many years will it take your money to double (Rule of 72)?",
      options: ["12 years", "6 years", "72 years", "18 years"],
      correctIndex: 0,
      explanation: "72 divided by 6 equals 12 years to double your initial capital investment.",
    ),
    FinanceQuestion(
      question: "What primary benefit does a High-Yield Savings Account (HYSA) offer over standard checking?",
      options: [
        "Free stock trades",
        "Significantly higher interest rates while retaining liquid FDIC protection",
        "Unlimited cash withdrawals without limits",
        "Zero taxes on earned interest"
      ],
      correctIndex: 1,
      explanation: "HYSAs provide superior interest rates compared to traditional accounts while keeping money secure and accessible.",
    ),
    FinanceQuestion(
      question: "What is a Certificate of Deposit (CD)?",
      options: [
        "A volatile cryptocurrency asset",
        "A savings instrument that locks up funds for a fixed term in exchange for a higher fixed interest rate",
        "A credit card reward voucher",
        "A government bond with floating rates"
      ],
      correctIndex: 1,
      explanation: "CDs lock up your deposit for a set timeframe; early withdrawals usually trigger interest penalties.",
    ),
    FinanceQuestion(
      question: "What institution in the US insures individual bank deposits up to \$250,000?",
      options: [
        "FDIC (Federal Deposit Insurance Corporation)",
        "SEC (Securities and Exchange Commission)",
        "IRS (Internal Revenue Service)",
        "Federal Reserve Board"
      ],
      correctIndex: 0,
      explanation: "The FDIC guarantees member bank deposits, protecting consumer funds even if the bank defaults.",
    ),
    FinanceQuestion(
      question: "How does inflation impact cash sitting in a standard 0.01% savings account?",
      options: [
        "Increases purchasing power rapidly",
        "Reduces real purchasing power over time because consumer prices outpace account interest",
        "Has no effect on real value",
        "Multiplies the principal balance automatically"
      ],
      correctIndex: 1,
      explanation: "If inflation is 3% and interest is 0.01%, your real purchasing power drops by roughly 3% each year.",
    ),
    FinanceQuestion(
      question: "What is the difference between simple interest and compound interest?",
      options: [
        "Simple interest grows exponentially; Compound interest grows linearly",
        "Simple interest is calculated only on principal; Compound interest earns interest on interest",
        "Simple interest applies only to stocks; Compound interest applies to loans",
        "There is no functional difference"
      ],
      correctIndex: 1,
      explanation: "Simple interest stays flat, whereas compound interest compounds continuously, driving long-term growth.",
    ),
    FinanceQuestion(
      question: "If interest compounds monthly versus annually at the same nominal rate, which yields more money?",
      options: [
        "Annual compounding",
        "Monthly compounding",
        "They yield the exact same amount",
        "Neither yields interest"
      ],
      correctIndex: 1,
      explanation: "More frequent compounding periods calculate interest on newly added gains faster, resulting in higher overall yield.",
    ),
    FinanceQuestion(
      question: "What is a money market savings account?",
      options: [
        "A high-risk stock account",
        "An interest-bearing deposit account offering higher rates and limited check-writing features",
        "A physical vault for cash and gold",
        "An uninsured investment fund"
      ],
      correctIndex: 1,
      explanation: "Money market accounts combine competitive interest rates with basic transactional access like debit cards or checks.",
    ),
    FinanceQuestion(
      question: "What penalty do you usually face for withdrawing money early from a fixed CD?",
      options: [
        "Permanent account suspension",
        "Loss of a portion of accumulated interest earnings",
        "A credit score reduction of 100 points",
        "Forfeiture of all original principal deposits"
      ],
      correctIndex: 1,
      explanation: "Banks assess an early withdrawal penalty equal to a set number of months of interest if you cash out a CD early.",
    ),
    FinanceQuestion(
      question: "What is liquidity in personal finance?",
      options: [
        "The total amount of debt owed",
        "How quickly and easily an asset can be converted into cash without losing value",
        "The interest rate on a mortgage",
        "The profit made from stock sales"
      ],
      correctIndex: 1,
      explanation: "Cash in a checking account is highly liquid, whereas real estate is illiquid because selling takes time.",
    ),
    FinanceQuestion(
      question: "Why are physical cash savings stored under a mattress risky?",
      options: [
        "It gains too much interest to track",
        "It earns 0% yield, suffers full inflation loss, and lacks fire or theft insurance protection",
        "The government taxes hidden physical cash twice",
        "It automatically degrades into unreadable paper"
      ],
      correctIndex: 1,
      explanation: "Unbanked cash loses real value to inflation and lacks deposit insurance against disaster or theft.",
    ),
    FinanceQuestion(
      question: "What is 'nominal interest rate'?",
      options: [
        "The interest rate after adjusting for inflation",
        "The stated interest rate before adjusting for inflation",
        "The maximum rate charged by credit cards",
        "The fee charged for international bank transfers"
      ],
      correctIndex: 1,
      explanation: "The nominal rate is the baseline advertised rate, whereas the real rate subtracts current inflation.",
    ),
    FinanceQuestion(
      question: "What is 'real interest rate'?",
      options: [
        "The nominal interest rate minus the current inflation rate",
        "The total rate including bank service fees",
        "The interest rate on payday loans",
        "The rate guaranteed by FDIC insurance"
      ],
      correctIndex: 0,
      explanation: "Real interest rate reflects actual purchasing power growth by taking inflation into account.",
    ),
    FinanceQuestion(
      question: "If your savings account earns 4% APY and annual inflation is 3%, what is your real rate of return?",
      options: ["7%", "1%", "12%", "0.75%"],
      correctIndex: 1,
      explanation: "Subtract 3% inflation from 4% APY to get a real purchasing power gain of 1%.",
    ),
    FinanceQuestion(
      question: "What does the NCUA insure in the financial system?",
      options: [
        "Traditional commercial bank deposits",
        "Deposits at credit unions up to \$250,000",
        "Stock market brokerages",
        "Private peer-to-peer loans"
      ],
      correctIndex: 1,
      explanation: "The National Credit Union Administration (NCUA) provides insurance protection for credit union accounts.",
    ),
    FinanceQuestion(
      question: "What is a CD Ladder strategy?",
      options: [
        "Borrowing money from multiple CDs at once",
        "Dividing funds across CDs maturing at staggered intervals to maintain liquidity and interest yields",
        "Paying off high-interest CDs first",
        "Buying stocks through a bank certificate"
      ],
      correctIndex: 1,
      explanation: "Staggering CD maturity dates ensures regular access to maturing cash while capturing higher long-term yields.",
    ),

    // -------------------------------------------------------------
    // CREDIT, DEBT & LOANS (41-60)
    // -------------------------------------------------------------
    FinanceQuestion(
      question: "What is the difference between a credit card and a debit card?",
      options: [
        "Debit cards borrow funds from a bank; Credit cards tap your checking balance directly.",
        "Credit cards instantly withdraw money you currently own; Debit cards act as loans.",
        "Debit cards deduct funds immediately from checking; Credit cards loan funds up to a set limit.",
        "There is no functional financial operational difference."
      ],
      correctIndex: 2,
      explanation: "Debit draws cash directly from your bank balance; credit is a revolving loan you must repay.",
    ),
    FinanceQuestion(
      question: "Which component has the single largest impact on calculating your FICO credit score?",
      options: [
        "Length of credit history",
        "Payment history (paying bills on time)",
        "Types of credit used",
        "Total number of credit inquiries"
      ],
      correctIndex: 1,
      explanation: "Payment history accounts for roughly 35% of your total credit score, making on-time payments essential.",
    ),
    FinanceQuestion(
      question: "What is a credit utilization ratio?",
      options: [
        "The total amount of debt paid off per year",
        "The percentage of your total available credit lines that you are currently using",
        "The interest rate charged on mortgage loans",
        "The ratio of income to credit card rewards points"
      ],
      correctIndex: 1,
      explanation: "Credit utilization measures used credit against overall limits. Keeping it under 30% helps protect credit scores.",
    ),
    FinanceQuestion(
      question: "What is the 'debt avalanche' debt payoff strategy?",
      options: [
        "Paying off debts from smallest balance to largest balance",
        "Paying minimums on all debts while directing extra funds to the loan with the highest interest rate",
        "Filing for bankruptcy immediately",
        "Consolidating all loans into a single low-interest credit card"
      ],
      correctIndex: 1,
      explanation: "The debt avalanche mathematically minimizes interest costs by targeting high-APR balances first.",
    ),
    FinanceQuestion(
      question: "What is the 'debt snowball' strategy made popular by financial planners?",
      options: [
        "Targeting the debt with the highest interest rate first",
        "Paying off debts from smallest total dollar balance to largest to gain psychological momentum",
        "Stopping all payments until loans enter default",
        "Transferring debt to overseas accounts"
      ],
      correctIndex: 1,
      explanation: "Debt snowball focuses on quick psychological wins by eliminating small debts first.",
    ),
    FinanceQuestion(
      question: "What happens if you only pay the minimum monthly balance on a high-APR credit card?",
      options: [
        "Your debt disappears within 12 months",
        "Compounding high interest causes you to take years or decades to pay off the balance",
        "The card issuer waives remaining interest charges",
        "Your credit score automatically maxes out"
      ],
      correctIndex: 1,
      explanation: "Minimum payments cover mostly interest, leaving the core principal virtually unchanged for long periods.",
    ),
    FinanceQuestion(
      question: "What is collateral in the context of a secured loan?",
      options: [
        "A cash bonus given by lenders",
        "An asset pledged as security for loan repayment, subject to seizure upon default",
        "The total interest accumulated over a loan's term",
        "The credit score of a co-signer"
      ],
      correctIndex: 1,
      explanation: "Secured loans (like auto loans or mortgages) use physical property as collateral to back the loan.",
    ),
    FinanceQuestion(
      question: "Which of these is an example of an unsecured loan?",
      options: [
        "A traditional home mortgage",
        "An auto loan backed by a vehicle title",
        "A standard personal credit card",
        "A pawn shop pawn loan"
      ],
      correctIndex: 2,
      explanation: "Credit cards are unsecured loans—lenders approve them based on creditworthiness without physical collateral.",
    ),
    FinanceQuestion(
      question: "What is APR in personal credit agreements?",
      options: [
        "Annual Percentage Rate",
        "Average Principal Return",
        "Automated Payment Recovery",
        "Annual Profit Ratio"
      ],
      correctIndex: 0,
      explanation: "APR represents the total annualized cost of borrowing, including interest rates and required finance fees.",
    ),
    FinanceQuestion(
      question: "What is a grace period on a standard credit card?",
      options: [
        "A time window where you can spend unlimited funds without credit limits",
        "The period between billing cycles where no interest accrues if the balance is paid in full",
        "The time given to pay off defaulted debts after bankruptcy",
        "A period where credit card annual fees are waived"
      ],
      correctIndex: 1,
      explanation: "Paying your statement balance in full before the grace period ends lets you avoid paying interest entirely.",
    ),
    FinanceQuestion(
      question: "What impact does closing an old, paid-off credit card account have on your credit score?",
      options: [
        "Always increases your score immediately",
        "Can lower your score by reducing overall available credit and shortening average credit history",
        "Has zero effect on credit calculations",
        "Erases late payment history permanently"
      ],
      correctIndex: 1,
      explanation: "Closing old accounts shrinks total credit lines (raising utilization) and reduces average credit account age.",
    ),
    FinanceQuestion(
      question: "What is predatory lending?",
      options: [
        "Low-rate government student loans",
        "Unfair or deceptive loan practices using exorbitant rates and hidden fees targeting vulnerable borrowers",
        "Standard high-yield bank savings products",
        "Interest-free promotional financing"
      ],
      correctIndex: 1,
      explanation: "Predatory lenders take advantage of borrowers using misleading terms, extreme interest rates, and excessive trap fees.",
    ),
    FinanceQuestion(
      question: "Why are payday loans considered highly financially dangerous?",
      options: [
        "They require high credit scores to qualify",
        "They charge extreme annualized interest rates (often 300%–400%+) that create debt traps",
        "They require valuable real estate assets as collateral",
        "They lock up funds for 10 years"
      ],
      correctIndex: 1,
      explanation: "Payday loans carry triple-digit annualized interest rates that trap borrowers in continuous refinancing cycles.",
    ),
    FinanceQuestion(
      question: "What is debt consolidation?",
      options: [
        "Refusing to pay multiple bills until debt is forgiven",
        "Combining multiple loans into a single new loan, ideally with a lower combined interest rate",
        "Declaring Chapter 7 bankruptcy",
        "Converting debt directly into corporate stock"
      ],
      correctIndex: 1,
      explanation: "Consolidation merges multiple debts into a single monthly payment to simplify tracking and lower overall interest rates.",
    ),
    FinanceQuestion(
      question: "What is a hard inquiry (hard pull) on a credit report?",
      options: [
        "Checking your own credit score on a mobile app",
        "A formal credit check performed by a potential lender when you apply for new credit",
        "A annual audit by the Internal Revenue Service",
        "An automated account review by an existing lender"
      ],
      correctIndex: 1,
      explanation: "Hard inquiries occur during loan applications and can temporarily drop your credit score by a few points.",
    ),
    FinanceQuestion(
      question: "What is a co-signer legally obligated to do on a loan?",
      options: [
        "Nothing unless they choose to help",
        "Assume full equal responsibility for paying off the loan if the primary borrower fails to pay",
        "Pay only 10% of remaining missed payments",
        "Receive monthly dividend checks from the lender"
      ],
      correctIndex: 1,
      explanation: "Co-signers accept full legal responsibility for debt repayment if the main borrower misses payments or defaults.",
    ),
    FinanceQuestion(
      question: "What constitutes 'good debt' in financial planning strategy?",
      options: [
        "Debt used to finance luxury vacations",
        "Low-interest debt used to acquire assets that appreciate or increase earning potential over time",
        "High-interest cash advances spent on dining out",
        "Overdraft balances on retail checking accounts"
      ],
      correctIndex: 1,
      explanation: "Debt used for mortgages or education can expand net worth or future income, unlike high-cost consumer debt.",
    ),
    FinanceQuestion(
      question: "What is a balance transfer credit card designed for?",
      options: [
        "Earning high cash back on grocery purchases",
        "Moving high-interest debt onto a new card with a temporary 0% promotional APR period",
        "Converting cash directly into foreign currency",
        "Waiving federal student loan debts"
      ],
      correctIndex: 1,
      explanation: "Balance transfers let you pause interest charges temporarily so you can pay down debt principal faster.",
    ),
    FinanceQuestion(
      question: "What is the typical range for FICO credit scores in the United States?",
      options: ["0 to 100", "300 to 850", "100 to 500", "500 to 1000"],
      correctIndex: 1,
      explanation: "FICO credit scores range from 300 to 850, with scores above 740 generally considered excellent.",
    ),
    FinanceQuestion(
      question: "What happens when a loan goes into default status?",
      options: [
        "The loan interest rate drops to zero",
        "The lender considers the contract breached, demand full repayment, and can begin collections",
        "The debt is automatically erased after 30 days",
        "The government pays off the balance"
      ],
      correctIndex: 1,
      explanation: "Default occurs after prolonged missed payments, leading to legal action, debt collections, and severe credit damage.",
    ),

    // -------------------------------------------------------------
    // INVESTING & CAPITAL MARKETS (61-80)
    // -------------------------------------------------------------
    FinanceQuestion(
      question: "Which investment carries the risk of losing your original principal capital?",
      options: [
        "A FDIC-insured High-Yield Savings Account",
        "Purchasing individual shares of corporate equity stock",
        "A bank Certificate of Deposit (CD)",
        "A standard cash checking account"
      ],
      correctIndex: 1,
      explanation: "Stocks fluctuate based on business performance and broader economic conditions, meaning capital is at risk.",
    ),
    FinanceQuestion(
      question: "What represents partial ownership in a public corporate entity?",
      options: [
        "A corporate bond",
        "A share of stock (equity)",
        "A treasury bill",
        "A certificate of deposit"
      ],
      correctIndex: 1,
      explanation: "Buying stock gives you equity—a small piece of direct ownership in that business.",
    ),
    FinanceQuestion(
      question: "What is a corporate or government bond?",
      options: [
        "Direct ownership shares in a private startup",
        "A debt security where an investor loans capital to an entity for fixed interest payments",
        "An insurance contract protecting against stock market crashes",
        "A cash savings account at a local credit union"
      ],
      correctIndex: 1,
      explanation: "Bonds are IOUs—you lend money to a government or corporation, and they pay you regular interest until maturity.",
    ),
    FinanceQuestion(
      question: "What is asset allocation diversification?",
      options: [
        "Putting 100% of capital into a single top-performing stock",
        "Spreading investments across diverse asset classes and industries to minimize portfolio risk",
        "Moving all wealth into physical cash under a mattress",
        "Trading options contracts with maximum leverage"
      ],
      correctIndex: 1,
      explanation: "Diversification reduces risk—if one asset or sector crashes, other investments help buffer the loss.",
    ),
    FinanceQuestion(
      question: "What is an Index Fund?",
      options: [
        "A fund managed by an individual selecting hot daily stocks",
        "A low-cost investment fund designed to track a specific benchmark index like the S&P 500",
        "A high-interest government savings vehicle",
        "A speculative foreign exchange trading contract"
      ],
      correctIndex: 1,
      explanation: "Index funds track entire market segments, providing broad diversification and lower management fees.",
    ),
    FinanceQuestion(
      question: "What is a corporate dividend payment?",
      options: [
        "A penalty fee paid by corporations when revenues decline",
        "A portion of company profits distributed directly to equity shareholders",
        "The interest rate charged on business loans",
        "The initial price of an IPO stock share"
      ],
      correctIndex: 1,
      explanation: "Dividends are cash payments companies make to reward shareholders out of accumulated profits.",
    ),
    FinanceQuestion(
      question: "What is the S&P 500 index?",
      options: [
        "A list of the 500 highest tax-paying individuals",
        "A stock market index tracking the performance of 500 of the largest public companies in the US",
        "A government bond paying 5% interest annually",
        "The top 500 commercial banks in North America"
      ],
      correctIndex: 1,
      explanation: "The S&P 500 is widely considered the primary benchmark for overall US stock market performance.",
    ),
    FinanceQuestion(
      question: "What does Dollar-Cost Averaging (DCA) involve?",
      options: [
        "Timing the market to buy only at absolute rock-bottom lows",
        "Investing a fixed dollar amount into assets at regular intervals regardless of market fluctuations",
        "Selling all investments whenever stock prices decline by 5%",
        "Converting foreign currencies into US dollars daily"
      ],
      correctIndex: 1,
      explanation: "DCA builds investment consistency and eliminates emotion by buying more shares when prices are low and fewer when high.",
    ),
    FinanceQuestion(
      question: "What is a Mutual Fund?",
      options: [
        "A pooled investment vehicle managed by professionals that buys a basket of stocks, bonds, or securities",
        "A joint bank account opened between family members",
        "A peer-to-peer loan agreement",
        "A government insurance policy for home buyers"
      ],
      correctIndex: 0,
      explanation: "Mutual funds pool money from many investors to buy diversified portfolios managed by professional teams.",
    ),
    FinanceQuestion(
      question: "What is market volatility?",
      options: [
        "The absolute guarantee of losing money in stocks",
        "The rate and magnitude of price fluctuations for a security or market over time",
        "The total transaction fee charged by online brokerages",
        "The legal limit on how high a stock price can rise"
      ],
      correctIndex: 1,
      explanation: "High volatility means asset prices swing wildly in short periods, whereas low volatility indicates stable pricing.",
    ),
    FinanceQuestion(
      question: "What is an Exchange-Traded Fund (ETF)?",
      options: [
        "A fund traded on stock exchanges throughout the day, holding a basket of underlying assets",
        "A wire transfer between international banks",
        "An electronic check processor",
        "A tax refund bond issued by state governments"
      ],
      correctIndex: 0,
      explanation: "ETFs operate similarly to mutual funds, but trade like individual stocks on an exchange throughout market hours.",
    ),
    FinanceQuestion(
      question: "What is the relationship between risk and return in investing?",
      options: [
        "Higher potential returns generally require taking on higher risk of capital loss",
        "Low-risk investments always produce higher long-term returns",
        "Risk and return operate with zero mathematical connection",
        "High returns guarantee absolute capital protection"
      ],
      correctIndex: 0,
      explanation: "Higher prospective returns exist to compensate investors for taking on greater risk of potential loss.",
    ),
    FinanceQuestion(
      question: "What is a capital gain?",
      options: [
        "The profit realized when an asset is sold for a higher price than its original purchase cost",
        "The initial capital deposited into a checking account",
        "The annual salary earned by corporate executives",
        "The dividend income earned from holding bonds"
      ],
      correctIndex: 0,
      explanation: "A capital gain is achieved when you sell an asset (like stock or real estate) for more than you originally paid.",
    ),
    FinanceQuestion(
      question: "What is an Initial Public Offering (IPO)?",
      options: [
        "A company's final liquidation sale during bankruptcy",
        "The first sale of stock issued by a private company to the public market",
        "An international tax treaty on corporate bonds",
        "A bank's promotional interest rate for new accounts"
      ],
      correctIndex: 1,
      explanation: "An IPO marks a private business's transition to a public company by issuing shares on a stock exchange.",
    ),
    FinanceQuestion(
      question: "What characterizes a 'Bull Market'?",
      options: [
        "A prolonged period of declining stock prices and economic pessimism",
        "A market environment with rising asset prices and strong economic confidence",
        "A market where trading is suspended due to technical errors",
        "A period with high inflation and zero interest rates"
      ],
      correctIndex: 1,
      explanation: "Bull markets describe sustained periods of rising asset prices and optimistic investor sentiment.",
    ),
    FinanceQuestion(
      question: "What characterizes a 'Bear Market'?",
      options: [
        "A prolonged price drop, typically 20% or more from recent peaks, accompanied by negative sentiment",
        "A surge in stock prices across all economic sectors",
        "A market where only government bonds are traded",
        "A period of unprecedented corporate dividend payouts"
      ],
      correctIndex: 0,
      explanation: "Bear markets occur when market indices drop 20% or more from recent highs amid economic uncertainty.",
    ),
    FinanceQuestion(
      question: "What is a market expense ratio in mutual funds or ETFs?",
      options: [
        "The total tax paid on capital gains",
        "The annual percentage fee charged to investors to cover fund management and administrative operational costs",
        "The interest rate paid on margin loans",
        "The cost to open a brokerage account"
      ],
      correctIndex: 1,
      explanation: "Expense ratios represent annual operational costs deducted from your total investment returns in a fund.",
    ),
    FinanceQuestion(
      question: "Why can market timing be dangerous for retail investors?",
      options: [
        "It guarantees you pay double income taxes",
        "Predicting exact market tops and bottoms is nearly impossible, often leading to buying high and selling low",
        "Brokerages prohibit buying stocks more than once a month",
        "It eliminates all potential capital losses automatically"
      ],
      correctIndex: 1,
      explanation: "Trying to time the market often backfires when investors miss out on the market's best recovery days.",
    ),
    FinanceQuestion(
      question: "What is a Real Estate Investment Trust (REIT)?",
      options: [
        "A government agency that builds public roads",
        "A company that owns or finances income-producing real estate and trades on stock exchanges like equities",
        "A mortgage loan given exclusively to first-time homebuyers",
        "An insurance policy covering rental apartment property damage"
      ],
      correctIndex: 1,
      explanation: "REITs let investors buy shares in large real estate portfolios without physically buying or managing property.",
    ),
    FinanceQuestion(
      question: "What does liquidity risk mean for an investor?",
      options: [
        "The risk that a bank goes completely out of business",
        "The risk that an investor cannot sell an asset quickly enough to prevent a loss or meet obligation costs",
        "The risk that dividends are paid in foreign currency",
        "The risk of interest rates dropping to zero"
      ],
      correctIndex: 1,
      explanation: "Liquidity risk happens when you hold an illiquid asset (like artwork or real estate) that cannot be sold fast for cash.",
    ),

    // -------------------------------------------------------------
    // RETIREMENT & TAXES (81-100)
    // -------------------------------------------------------------
    FinanceQuestion(
      question: "What primary tax advantage does a traditional 401(k) retirement plan offer?",
      options: [
        "Contributions are made with pre-tax income, lowering your current taxable income for the year",
        "Withdrawals in retirement are 100% tax-free",
        "The government matches 50% of all contributions automatically",
        "Money can be withdrawn tax-free at any age"
      ],
      correctIndex: 0,
      explanation: "Traditional 401(k) contributions are pre-tax, reducing your tax burden today, though withdrawals in retirement are taxed.",
    ),
    FinanceQuestion(
      question: "How does a Roth IRA differ from a Traditional IRA?",
      options: [
        "Roth IRA contributions are made with post-tax dollars, allowing tax-free qualified withdrawals in retirement",
        "Traditional IRAs offer tax-free withdrawals in retirement; Roth IRAs do not",
        "Roth IRAs are only available through corporate employers",
        "There are no differences between these retirement accounts"
      ],
      correctIndex: 0,
      explanation: "Roth IRAs use after-tax dollars today, so your investments grow tax-free and withdrawals in retirement are tax-free.",
    ),
    FinanceQuestion(
      question: "What is an employer 401(k) match?",
      options: [
        "A mandatory tax paid to the federal government",
        "Free money contributed by your employer up to a specific percentage of your salary when you contribute to your 401(k)",
        "A government program for low-income workers",
        "A loan taken out against your future retirement balance"
      ],
      correctIndex: 1,
      explanation: "An employer match is essentially free compensation—failing to contribute enough to grab the full match leaves money on the table.",
    ),
    FinanceQuestion(
      question: "What standard penalty usually applies to early withdrawals from retirement accounts before age 59½?",
      options: [
        "Forfeiture of all invested principal",
        "A 10% IRS early withdrawal tax penalty plus income taxes on pre-tax distributions",
        "A 50-point drop in credit score",
        "Mandatory community service"
      ],
      correctIndex: 1,
      explanation: "Cashing out retirement accounts early incurs a 10% federal penalty plus standard income taxes on pre-tax balances.",
    ),
    FinanceQuestion(
      question: "What is vesting in an employer retirement contribution plan?",
      options: [
        "The process of selecting mutual funds inside your account",
        "The timeline or process by which an employee gains full ownership of employer-matched funds",
        "The age at which you must legally retire",
        "A legal exemption from state income taxes"
      ],
      correctIndex: 1,
      explanation: "Vesting determines how much of your employer's matched contributions you get to keep if you leave the company.",
    ),
    FinanceQuestion(
      question: "What does progressive income taxation mean in practice?",
      options: [
        "Everyone pays the exact same flat tax percentage regardless of income",
        "Tax rates increase incrementally in higher income brackets as taxable income rises",
        "Taxes are paid continuously every week through bank transfers",
        "High earners pay zero income taxes"
      ],
      correctIndex: 1,
      explanation: "Progressive tax systems charge higher tax rates on higher portions of income across escalating tax brackets.",
    ),
    FinanceQuestion(
      question: "What is a standard tax deduction?",
      options: [
        "A flat dollar amount that reduces the total portion of your overall income subject to taxation",
        "A cash payment sent directly from the IRS to every citizen annually",
        "The total amount withheld from a monthly paycheck",
        "A tax penalty charged on unpaid credit card debts"
      ],
      correctIndex: 0,
      explanation: "The standard deduction reduces your taxable income, lowering the overall tax amount you owe.",
    ),
    FinanceQuestion(
      question: "What is the difference between a tax deduction and a tax credit?",
      options: [
        "Tax deductions directly lower taxes owed dollar-for-dollar; Tax credits lower taxable income",
        "Tax deductions lower taxable income; Tax credits reduce your total calculated tax bill dollar-for-dollar",
        "Deductions apply only to businesses; Credits apply only to retirees",
        "They are two terms for the exact same tax benefit"
      ],
      correctIndex: 1,
      explanation: "Credits directly reduce your total tax bill dollar-for-dollar, making them generally more valuable than deductions.",
    ),
    FinanceQuestion(
      question: "What is a Health Savings Account (HSA)?",
      options: [
        "A high-interest account used to buy health insurance policies",
        "A tax-advantaged account used for qualified medical expenses, featuring pre-tax contributions and tax-free growth",
        "A government emergency grant given during illness",
        "A credit card issued by hospitals"
      ],
      correctIndex: 1,
      explanation: "HSAs offer a triple tax advantage: pre-tax contributions, tax-free investment growth, and tax-free withdrawals for medical costs.",
    ),
    FinanceQuestion(
      question: "What is a Required Minimum Distribution (RMD)?",
      options: [
        "The minimum amount you must contribute to a 401(k) each year",
        "The legally mandated minimum amount you must withdraw annually from tax-deferred retirement accounts starting at a specific age",
        "The minimum check required to open an IRA account",
        "The base Social Security payment given to retirees"
      ],
      correctIndex: 1,
      explanation: "The IRS requires retirees to start withdrawing minimum amounts from tax-deferred accounts so those funds can finally be taxed.",
    ),
    FinanceQuestion(
      question: "What is the primary function of Social Security in the US?",
      options: [
        "To fund public university education expenses",
        "A federal social insurance program providing retirement income, disability benefits, and survivor support",
        "A private investment bank managed by Congress",
        "A mandatory health insurance company for young workers"
      ],
      correctIndex: 1,
      explanation: "Social Security provides safety-net income for retirees, disabled individuals, and surviving dependents.",
    ),
    FinanceQuestion(
      question: "What are FICA payroll deductions on your paystub?",
      options: [
        "Private health insurance premiums",
        "Mandatory taxes funding Social Security and Medicare programs",
        "Contributions to state college savings plans",
        "Union dues and administrative costs"
      ],
      correctIndex: 1,
      explanation: "FICA taxes are automatically deducted from paychecks to fund Social Security and Medicare systems.",
    ),
    FinanceQuestion(
      question: "What is a capital gains tax?",
      options: [
        "A tax charged on physical inventory stored in retail stores",
        "A tax levied on profits made from selling an investment asset like stock or real estate",
        "A tax assessed on personal checking account deposits",
        "A fee paid when opening a new brokerage account"
      ],
      correctIndex: 1,
      explanation: "Capital gains tax applies when you sell an asset for a higher price than you paid to purchase it.",
    ),
    FinanceQuestion(
      question: "What distinguishes short-term capital gains from long-term capital gains for taxes?",
      options: [
        "Short-term applies to assets held for 1 year or less and is taxed at higher ordinary income rates",
        "Long-term applies to assets sold within 30 days and is completely tax-exempt",
        "Short-term capital gains are taxed at 0% across all income levels",
        "There is no difference in tax rates"
      ],
      correctIndex: 0,
      explanation: "Holding assets for over a year qualifies them for lower long-term capital gains tax rates compared to short-term rates.",
    ),
    FinanceQuestion(
      question: "What is a 529 College Savings Plan?",
      options: [
        "A state-sponsored tax-advantaged savings plan designed specifically for future education costs",
        "A loan program offering guaranteed 1% interest rates to high school students",
        "A retirement plan exclusively for public school teachers",
        "A tax credit given to families with more than five children"
      ],
      correctIndex: 0,
      explanation: "529 plans allow investments to grow tax-free when used for qualified education expenses like tuition and books.",
    ),
    FinanceQuestion(
      question: "What does tax-loss harvesting involve?",
      options: [
        "Filing income tax returns late to delay payment",
        "Selling investments at a loss to offset capital gains tax liabilities from profitable investments",
        "Hiding investment gains in offshore bank accounts",
        "Claiming fake business expenses on personal taxes"
      ],
      correctIndex: 1,
      explanation: "Tax-loss harvesting balances out taxable capital gains by strategically realizing losses on underperforming assets.",
    ),
    FinanceQuestion(
      question: "What is a pension plan?",
      options: [
        "An individual savings account opened at a retail bank",
        "An employer-sponsored retirement plan that guarantees a fixed monthly payout based on salary and tenure",
        "A short-term loan used to buy property",
        "A stock option given to entry-level workers"
      ],
      correctIndex: 1,
      explanation: "Pensions are defined-benefit plans where employers guarantee retirement payouts based on salary and service length.",
    ),
    FinanceQuestion(
      question: "What is marginal tax rate?",
      options: [
        "The overall average percentage of total income paid in taxes",
        "The tax rate applied to the very last dollar of your taxable income in your highest bracket",
        "The tax rate paid on property taxes",
        "The flat tax rate applied to food purchases"
      ],
      correctIndex: 1,
      explanation: "Your marginal tax rate is the highest bracket tier that applies to your top slice of earned income.",
    ),
    FinanceQuestion(
      question: "What is effective tax rate?",
      options: [
        "The highest tax bracket rate you reach",
        "The actual percentage of your total income paid in taxes after accounting for deductions and brackets",
        "The sales tax percentage in your home city",
        "The penalty rate charged on late tax returns"
      ],
      correctIndex: 1,
      explanation: "Effective tax rate is calculated by dividing your total calculated tax paid by your overall gross income.",
    ),
    FinanceQuestion(
      question: "Why should young adults start saving for retirement early?",
      options: [
        "To get an immediate exemption from paying all federal taxes",
        "To harness decades of compound growth, allowing small contributions today to multiply significantly over time",
        "Because credit card companies require retirement accounts to open cards",
        "Because bank accounts expire if not tied to a 401(k)"
      ],
      correctIndex: 1,
      explanation: "Starting early gives compounding more time to work—a head start of 10 years can double your ultimate retirement nest egg.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 20; i++) {
      Offset pos = Offset(_rand.nextDouble() * (_mapWidth - 200) + 100, _rand.nextDouble() * (_mapHeight - 200) + 100);
      if ((pos - const Offset(800, 800)).distance > 150) _treePositions.add(pos);
    }
    for (int i = 0; i < 20; i++) {
      Offset pos = Offset(_rand.nextDouble() * (_mapWidth - 200) + 100, _rand.nextDouble() * (_mapHeight - 200) + 100);
      if ((pos - const Offset(800, 800)).distance > 150) _rockPositions.add(pos);
    }

    _ticker = createTicker(_updateGameLoop);
    _ticker.start();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _ticker.dispose();
    super.dispose();
  }

  bool _isCollidingWithObstacles(Offset pos, double radius) {
    for (final tree in _treePositions) {
      if ((pos - tree).distance < (radius + _treeRadius)) return true;
    }
    for (final rock in _rockPositions) {
      if ((pos - rock).distance < (radius + _rockRadius)) return true;
    }
    return false;
  }

  void _updateGameLoop(Duration elapsed) {
    if (_isQuizOpen || _isUpgradeChoiceOpen || _isGameOver || _isSavingAndExiting) return;

    final double dt = (elapsed.inMicroseconds / 1000000.0) - _totalElapsedTime;
    _totalElapsedTime = elapsed.inMicroseconds / 1000000.0;

    if (dt <= 0 || dt > 0.1) return;

    setState(() {
      // 1. Keyboard Movement Vectors
      double dx = 0.0;
      double dy = 0.0;
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) || _pressedKeys.contains(LogicalKeyboardKey.keyW)) dy -= 1.0;
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) || _pressedKeys.contains(LogicalKeyboardKey.keyS)) dy += 1.0;
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || _pressedKeys.contains(LogicalKeyboardKey.keyA)) dx -= 1.0;
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) || _pressedKeys.contains(LogicalKeyboardKey.keyD)) dx += 1.0;

      if (dx != 0 || dy != 0) {
        double len = sqrt(dx * dx + dy * dy);
        Offset dynamicStep = Offset(dx / len, dy / len) * _playerSpeed * dt;
        
        Offset targetX = Offset((_playerPos.dx + dynamicStep.dx).clamp(_playerRadius, _mapWidth - _playerRadius), _playerPos.dy);
        if (!_isCollidingWithObstacles(targetX, _playerRadius)) _playerPos = targetX;

        Offset targetY = Offset(_playerPos.dx, (_playerPos.dy + dynamicStep.dy).clamp(_playerRadius, _mapHeight - _playerRadius));
        if (!_isCollidingWithObstacles(targetY, _playerRadius)) _playerPos = targetY;
      }

      // 1b. Handle Treasure Chest (Market Windfall) Collection
      for (int i = _chests.length - 1; i >= 0; i--) {
        final chest = _chests[i];
        double dist = (_playerPos - chest.pos).distance;
        if (dist < (_playerRadius + _chestRadius)) {
          _chests.removeAt(i);
          
          // 50% current health / balance boost
          int balanceBonus = (_bankBalance / 2).floor();
          if (balanceBonus < 250) balanceBonus = 250;
          
          _bankBalance = min(_maxBankBalance, _bankBalance + balanceBonus);

          GameToast.show(
            context,
            title: "MARKET WINDFALL!",
            message: "Capital reserve recovered +\$$balanceBonus net worth!",
            icon: Icons.card_giftcard_rounded,
            accent: const Color(0xFFE1BB72),
          );
        }
      }

      // 2. Rotate Emergency Fund Shield
      if (_emergencyFundLevel > 0) {
        _shieldAngle += (1.8 + (_emergencyFundLevel * 0.4)) * dt;
        _shieldDamageCooldown += dt;

        double shieldRadius = 55.0 + (_emergencyFundLevel * 10.0);
        int shieldCount = min(4, 1 + _emergencyFundLevel);
        
        for (int s = 0; s < shieldCount; s++) {
          double angleOffset = _shieldAngle + (s * (2 * pi / shieldCount));
          Offset shieldPos = _playerPos + Offset(cos(angleOffset), sin(angleOffset)) * shieldRadius;

          for (int mIdx = _liabilities.length - 1; mIdx >= 0; mIdx--) {
            final mob = _liabilities[mIdx];
            if ((shieldPos - mob.pos).distance < (mob.radius + 14.0)) {
              if (_shieldDamageCooldown >= 0.15) {
                mob.principalRemaining -= (20.0 + (_emergencyFundLevel * 15.0));
                _spawnExplosion(mob.pos, const Color(0xFF85EFAC));

                if (mob.principalRemaining <= 0) {
                  _onLiabilityCleared(mIdx, mob);
                }
              }
            }
          }
        }
        if (_shieldDamageCooldown >= 0.15) _shieldDamageCooldown = 0.0;
      }

      // 3. Automatic Coin Firing
      _lastAttackTime += dt;
      double currentAttackCooldown = 0.55 / _attackSpeedMultiplier;
      if (_lastAttackTime >= currentAttackCooldown && _liabilities.isNotEmpty) {
        _lastAttackTime = 0;
        _fireCoins();
      }

      // 4. Spawning Debts / Boss Market Crises
      if (_wave % 5 == 0) {
        if (!_bossActive && _liabilities.isEmpty) {
          _spawnMarketCrashBoss();
        }
      } else {
        _lastSpawnTime += dt;
        double spawnInterval = max(0.2, 1.5 - (_wave * 0.12));
        if (_lastSpawnTime >= spawnInterval) {
          _lastSpawnTime = 0;
          _spawnLiability();
        }
      }

      // 5. Coin Projectiles Vector Updates
      for (int i = _coins.length - 1; i >= 0; i--) {
        final coin = _coins[i];
        coin.pos += coin.velocity * dt;
        
        if (_isCollidingWithObstacles(coin.pos, 4.0)) {
          _coins.removeAt(i);
          continue;
        }

        if (coin.pos.dx < 0 || coin.pos.dx > _mapWidth || coin.pos.dy < 0 || coin.pos.dy > _mapHeight) {
          _coins.removeAt(i);
        }
      }

      // 6. Liability Movement & Obstacle Slide-Routing
      for (int i = _liabilities.length - 1; i >= 0; i--) {
        final mob = _liabilities[i];
        Offset direction = _playerPos - mob.pos;
        double dist = direction.distance;
        
        if (dist > 2) {
          Offset dirNormalized = direction / dist;
          Offset step = dirNormalized * mob.speed * dt;
          Offset targetPos = mob.pos + step;

          if (!_isCollidingWithObstacles(targetPos, mob.radius)) {
            mob.pos = targetPos;
          } else {
            Offset slideLeft = Offset(-dirNormalized.dy, dirNormalized.dx) * mob.speed * dt;
            Offset slideRight = Offset(dirNormalized.dy, -dirNormalized.dx) * mob.speed * dt;
            
            Offset testLeft = mob.pos + slideLeft;
            Offset testRight = mob.pos + slideRight;
            
            if (!_isCollidingWithObstacles(testLeft, mob.radius)) {
              mob.pos = testLeft;
            } else if (!_isCollidingWithObstacles(testRight, mob.radius)) {
              mob.pos = testRight;
            } else {
              mob.pos -= dirNormalized * (mob.speed * 0.4) * dt;
            }
          }
        }

        // Drains Bank Balance when touching player
        if (dist < (_playerRadius + mob.radius)) {
          int drain = (mob.drainRate * dt).ceil();
          _bankBalance -= drain;
          if (_bankBalance <= 0) {
            _bankBalance = 0;
            _endGame();
          }
        }
      }

      // 7. Coin Collisions on Liabilities
      for (int cIdx = _coins.length - 1; cIdx >= 0; cIdx--) {
        final coin = _coins[cIdx];
        bool coinDestroyed = false;

        for (int mIdx = _liabilities.length - 1; mIdx >= 0; mIdx--) {
          final mob = _liabilities[mIdx];
          double dist = (coin.pos - mob.pos).distance;

          if (dist < (mob.radius + 6.0)) {
            mob.principalRemaining -= coin.damage;
            coinDestroyed = true;
            _spawnExplosion(mob.pos, mob.color);

            if (mob.principalRemaining <= 0) {
              _onLiabilityCleared(mIdx, mob);
            }
            break;
          }
        }
        if (coinDestroyed) {
          _coins.removeAt(cIdx);
        }
      }

      // 8. Particle Lifecycles
      for (int i = _particles.length - 1; i >= 0; i--) {
        final part = _particles[i];
        part.pos += part.velocity * dt;
        part.life -= dt;
        if (part.life <= 0) {
          _particles.removeAt(i);
        }
      }
    });
  }

  void _onLiabilityCleared(int index, _FinancialLiability mob) {
    _liabilities.removeAt(index);
    _debtsCleared++;
    _goldAccumulated += mob.rewardGold;
    _xpAccumulated += mob.isBoss ? 80 : 8;

    if (mob.isBoss) {
      _bossActive = false;
      _chests.add(_TreasureChest(pos: mob.pos));
      _triggerQuizGate();
    } else if (_wave % 5 != 0 && _debtsCleared >= _debtsNeededForLevelUp) {
      _triggerQuizGate();
    }
  }

  void _spawnLiability() {
    if (!mounted) return;
    
    double angle = _rand.nextDouble() * pi * 2;
    double spawnDist = 520.0; 
    double x = (_playerPos.dx + cos(angle) * spawnDist).clamp(20.0, _mapWidth - 20.0);
    double y = (_playerPos.dy + sin(angle) * spawnDist).clamp(20.0, _mapHeight - 20.0);

    // Incremental Health and Damage scaling per wave
    double scaleFactor = pow(1.12, _wave - 1).toDouble(); 
    
    List<String> debtNames = ["Credit Card Debt", "Payday Loan", "Medical Bill", "Auto Loan"];
    String name = debtNames[_rand.nextInt(debtNames.length)];
    
    Color color = const Color(0xFFE25C5C);
    double hp = (40.0 + (_wave * 10)) * scaleFactor;
    double speed = 85.0 + _rand.nextInt(30); 
    double radius = 15.0;
    int gold = 5;

    if (_wave >= 3 && _rand.nextDouble() > 0.6) {
      name = "Subprime Mortgage";
      color = const Color(0xFFA65CE2); 
      hp *= 1.8;
      radius = 19.0;
      gold = 12;
    }

    _liabilities.add(_FinancialLiability(
      name: name,
      pos: Offset(x, y),
      principalRemaining: hp,
      maxPrincipal: hp,
      speed: speed,
      radius: radius,
      color: color,
      drainRate: (450.0 + (_wave * 50.0)) * scaleFactor,
      rewardGold: gold,
    ));
  }

  void _spawnMarketCrashBoss() {
    _bossActive = true;
    double angle = _rand.nextDouble() * pi * 2;
    double x = (_playerPos.dx + cos(angle) * 400.0).clamp(60.0, _mapWidth - 60.0);
    double y = (_playerPos.dy + sin(angle) * 400.0).clamp(60.0, _mapHeight - 60.0);

    List<String> bossTitles = ["MARKET CRASH", "HYPERINFLATION", "LIQUIDITY CRISIS", "RECESSION SPIRAL"];
    String title = bossTitles[(_wave ~/ 5 - 1) % bossTitles.length];

    // Major exponential scaling for bosses every 5 levels
    double bossMultiplier = pow(1.45, (_wave ~/ 5) - 1).toDouble();
    double hp = (500.0 + (_wave * 120.0)) * bossMultiplier;

    _liabilities.add(_FinancialLiability(
      name: title,
      pos: Offset(x, y),
      principalRemaining: hp,
      maxPrincipal: hp,
      speed: 95.0,
      radius: 40.0,
      color: const Color(0xFFFF2F55),
      drainRate: (750.0 + (_wave * 80.0)) * bossMultiplier,
      rewardGold: 150,
      isBoss: true,
    ));

    GameToast.show(
      context,
      title: "SYSTEMIC RISK DETECTED",
      message: "$title event! Pay off liability reserves before balance drains!",
      icon: Icons.warning_amber_rounded,
      accent: const Color(0xFFFF2F55),
    );
  }

  void _fireCoins() {
    var sortedLiabilities = List<_FinancialLiability>.from(_liabilities);
    sortedLiabilities.sort((a, b) => (a.pos - _playerPos).distance.compareTo((b.pos - _playerPos).distance));

    int shots = min(_coinStreamCount, sortedLiabilities.length);
    for (int i = 0; i < shots; i++) {
      final target = sortedLiabilities[i];
      Offset direction = target.pos - _playerPos;
      double dist = direction.distance;
      if (dist == 0) continue;
      
      Offset normalizedVelocity = (direction / dist) * _coinSpeed;
      _coins.add(_CoinProjectile(
        pos: _playerPos,
        velocity: normalizedVelocity,
        damage: _coinDamage,
      ));
    }
  }

  void _spawnExplosion(Offset center, Color color) {
    for (int i = 0; i < 6; i++) {
      double angle = _rand.nextDouble() * pi * 2;
      double pSpeed = 60.0 + _rand.nextDouble() * 50;
      _particles.add(_Particle(
        pos: center,
        velocity: Offset(cos(angle), sin(angle)) * pSpeed,
        color: color,
        life: 0.22,
      ));
    }
  }

  void _triggerQuizGate() {
    var pooledQuestions = List<FinanceQuestion>.from(_questionBank)..shuffle(_rand);
    var chosenRawQuestions = pooledQuestions.take(3).toList();
    
    _activeQuizQuestions = chosenRawQuestions.map((q) {
      List<String> optionsCopy = List<String>.from(q.options);
      String correctText = optionsCopy[q.correctIndex];
      optionsCopy.shuffle(_rand);
      
      return ShuffledQuizQuestion(
        question: q.question,
        shuffledOptions: optionsCopy,
        correctOptionText: correctText,
        explanation: q.explanation,
      );
    }).toList();
    
    _quizCorrectCount = 0;
    _quizQuestionIndex = 0;
    _selectedAnswerIndex = null;
    _isAnswerSubmitted = false;
    _isQuizOpen = true;
  }

  void _submitQuizAnswer() {
    if (_selectedAnswerIndex == null || _isAnswerSubmitted) return;

    setState(() {
      _isAnswerSubmitted = true;
      final currentQuestion = _activeQuizQuestions[_quizQuestionIndex];
      if (currentQuestion.shuffledOptions[_selectedAnswerIndex!] == currentQuestion.correctOptionText) {
        _quizCorrectCount++;
      }
    });
  }

  void _nextQuizQuestion() {
    setState(() {
      if (_quizQuestionIndex < 2) {
        _quizQuestionIndex++;
        _selectedAnswerIndex = null;
        _isAnswerSubmitted = false;
      } else {
        _isQuizOpen = false;
        if (_quizCorrectCount == 3) {
          _isUpgradeChoiceOpen = true;
        } else {
          _debtsCleared = 0; 
          _wave++;
          _debtsNeededForLevelUp = 6 + (_wave * 3);
          GameToast.show(
            context,
            title: "Quiz Score: $_quizCorrectCount/3",
            message: "Score 3/3 for income upgrades! Market grid reinforced.",
            icon: Icons.school_rounded,
            accent: const Color(0xFFE1BB72),
          );
        }
      }
    });
  }

  List<BrawlUpgrade> _getUpgradeOptions() {
    return [
      BrawlUpgrade(
        name: "Multiple Income Streams",
        description: "Fire an extra simultaneous coin stream (+1 Coin Attack)",
        icon: Icons.payments_rounded,
        action: () => _coinStreamCount++,
      ),
      BrawlUpgrade(
        name: "Job Promotion",
        description: "Increase coin payload value (+30 Payment Damage)",
        icon: Icons.trending_up_rounded,
        action: () => _coinDamage += 30,
      ),
      BrawlUpgrade(
        name: "Establish Emergency Fund",
        description: _emergencyFundLevel == 0 
            ? "Create revolving cash shield damaging touching debts" 
            : "Expand cash shield radius & contact damage (Level ${_emergencyFundLevel + 1})",
        icon: Icons.shield_rounded,
        action: () => _emergencyFundLevel++,
      ),
      BrawlUpgrade(
        name: "Liquid Asset Speed",
        description: "Boost movement agility velocity vectors (+40 Speed)",
        icon: Icons.directions_run_rounded,
        action: () => _playerSpeed += 40.0,
      ),
    ]..shuffle(_rand);
  }

  void _selectUpgrade(BrawlUpgrade choice) {
    setState(() {
      choice.action();
      _isUpgradeChoiceOpen = false;
      
      _debtsCleared = 0;
      _wave++;
      _debtsNeededForLevelUp = 6 + (_wave * 3);
      
      GameToast.show(
        context,
        title: "Upgrade Active!",
        message: "${choice.name} initialized. Next wave incoming.",
        icon: Icons.bolt_rounded,
        accent: const Color(0xFF85EFAC),
      );
    });
  }

  void _endGame() {
    _isGameOver = true;
    _ticker.stop();
  }

  Future<void> _exitAndSyncData() async {
    if (_isSavingAndExiting) return;
    setState(() {
      _isSavingAndExiting = true;
    });

    final controller = context.read<UserStatsController>();
    
    final Map<String, dynamic> payload = {
      'gold_earned': _goldAccumulated,
      'xp_earned': _xpAccumulated,
      'literacy_points': _wave * 15,
      'title': 'Finance Brawl Run Complete',
      'description': 'Reached Wave $_wave and cleared $_debtsCleared liabilities.',
    };

    StatsActionResult syncResult = await controller.applyChallengePayload(payload);

    if (mounted) {
      Navigator.of(context).pop(FinanceBrawlCloseResult(
        goldEarned: _goldAccumulated,
        xpEarned: _xpAccumulated,
        syncState: syncResult,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UserStatsController>();
    final equippedSkinId = controller.stats.equippedSkin;

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          _pressedKeys.add(event.logicalKey);
        } else if (event is KeyUpEvent) {
          _pressedKeys.remove(event.logicalKey);
        }
        return KeyEventResult.handled;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1E19),
        body: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

            double camX = (_canvasSize.width / 2) - _playerPos.dx;
            double camY = (_canvasSize.height / 2) - _playerPos.dy;

            if (_canvasSize.width < _mapWidth) {
              camX = camX.clamp(_canvasSize.width - _mapWidth, 0.0);
            } else {
              camX = (_canvasSize.width - _mapWidth) / 2;
            }

            if (_canvasSize.height < _mapHeight) {
              camY = camY.clamp(_canvasSize.height - _mapHeight, 0.0);
            } else {
              camY = (_canvasSize.height - _mapHeight) / 2;
            }

            return Stack(
              children: [
                ClipRect(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _BrawlPainter(
                      playerPos: _playerPos,
                      playerRadius: _playerRadius,
                      bankBalance: _bankBalance,
                      maxBankBalance: _maxBankBalance,
                      liabilities: _liabilities,
                      coins: _coins,
                      particles: _particles,
                      chests: _chests,
                      chestRadius: _chestRadius,
                      emergencyFundLevel: _emergencyFundLevel,
                      shieldAngle: _shieldAngle,
                      equippedSkinId: equippedSkinId,
                      treePositions: _treePositions,
                      treeRadius: _treeRadius,
                      rockPositions: _rockPositions,
                      rockRadius: _rockRadius,
                      mapWidth: _mapWidth,
                      mapHeight: _mapHeight,
                      camOffset: Offset(camX, camY),
                    ),
                  ),
                ),

                // Top Dashboard HUD
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1814).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1F4D3E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _wave % 5 == 0 ? "CRISIS WAVE $_wave" : "WAVE $_wave",
                              style: TextStyle(color: _wave % 5 == 0 ? const Color(0xFFFF2F55) : const Color(0xFF85EFAC), fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _wave % 5 == 0 ? "Neutralize Market Crisis!" : "Debts Paid: $_debtsCleared / $_debtsNeededForLevelUp",
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // Bank Balance HUD
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1814).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF85EFAC)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("NET WORTH BALANCE", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(
                              "\$$_bankBalance",
                              style: TextStyle(
                                color: _bankBalance < 2500 ? const Color(0xFFFF2F55) : const Color(0xFF85EFAC),
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1814).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF1F4D3E)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.toll_rounded, color: Color(0xFFE1BB72), size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  "$_goldAccumulated",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFE25C5C).withValues(alpha: 0.95),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            onPressed: () {
                              _ticker.stop();
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF10281F),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1F4D3E))),
                                  title: const Text("PAUSE & BANK EARNINGS?", style: TextStyle(color: Color(0xFF85EFAC), fontWeight: FontWeight.w900)),
                                  content: Text("Do you want to exit? Accumulated interest gains ($_goldAccumulated gold) will be stored safely."),
                                  actions: [
                                    TextButton(
                                      child: const Text("RESUME GAME", style: TextStyle(color: Colors.white60)),
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        _ticker.start();
                                      },
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE25C5C)),
                                      child: const Text("SAVE AND QUIT"),
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        _exitAndSyncData();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                if (_isQuizOpen) _buildQuizOverlay(),
                if (_isUpgradeChoiceOpen) _buildUpgradeOverlay(),
                if (_isGameOver || _isSavingAndExiting) _buildGameOverOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuizOverlay() {
    final q = _activeQuizQuestions[_quizQuestionIndex];
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            color: const Color(0xFF12231C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFF6CB6DA), width: 2)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("LITERACY CHECKPOINT (${_quizQuestionIndex + 1}/3)", style: const TextStyle(color: Color(0xFF6CB6DA), fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 16),
                  Text(q.question, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  ...List.generate(q.shuffledOptions.length, (idx) {
                    Color optionBorderColor = Colors.white.withValues(alpha: 0.12);
                    Color optionBgColor = const Color(0xFF0A1612);
                    final optionText = q.shuffledOptions[idx];

                    if (_isAnswerSubmitted) {
                      if (optionText == q.correctOptionText) {
                        optionBorderColor = const Color(0xFF85EFAC);
                        optionBgColor = const Color(0xFF143525);
                      } else if (_selectedAnswerIndex == idx) {
                        optionBorderColor = const Color(0xFFE25C5C);
                        optionBgColor = const Color(0xFF381B1B);
                      }
                    } else if (_selectedAnswerIndex == idx) {
                      optionBorderColor = const Color(0xFF6CB6DA);
                      optionBgColor = const Color(0xFF14222B);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: _isAnswerSubmitted ? null : () => setState(() => _selectedAnswerIndex = idx),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: optionBgColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: optionBorderColor, width: 2)),
                          child: Text(optionText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }),
                  if (_isAnswerSubmitted) ...[
                    const SizedBox(height: 10),
                    Text(q.explanation, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6CB6DA), foregroundColor: Colors.black),
                    onPressed: _selectedAnswerIndex == null ? null : (_isAnswerSubmitted ? _nextQuizQuestion : _submitQuizAnswer),
                    child: Text(_isAnswerSubmitted ? "CONTINUE" : "SUBMIT ANSWER", style: const TextStyle(fontWeight: FontWeight.w900)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeOverlay() {
    final upgrades = _getUpgradeOptions().take(3).toList();
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("PROFIT CHANNELS UNLOCKED!", style: TextStyle(color: Color(0xFFE1BB72), fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: upgrades.map((up) {
                return Container(
                  width: 175,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    color: const Color(0xFF14241F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE1BB72), width: 1.5)),
                    child: InkWell(
                      onTap: () => _selectUpgrade(up),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(up.icon, color: const Color(0xFFE1BB72), size: 28),
                            const SizedBox(height: 14),
                            Text(up.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                            const SizedBox(height: 10),
                            Text(up.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isSavingAndExiting ? "SAVING DATA..." : "BANKRUPT!", style: TextStyle(color: _isSavingAndExiting ? const Color(0xFF85EFAC) : const Color(0xFFE25C5C), fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text("Your bank balance reached zero.", style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 24),
            Text("Gold Banked: +$_goldAccumulated gold", style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 32),
            if (!_isSavingAndExiting)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF85EFAC), foregroundColor: Colors.black),
                onPressed: _exitAndSyncData,
                child: const Text("BANK REWARDS & EXIT", style: TextStyle(fontWeight: FontWeight.w900)),
              )
          ],
        ),
      ),
    );
  }
}

class _FinancialLiability {
  _FinancialLiability({
    required this.name,
    required this.pos,
    required this.principalRemaining,
    required this.maxPrincipal,
    required this.speed,
    required this.radius,
    required this.color,
    required this.drainRate,
    required this.rewardGold,
    this.isBoss = false,
  });

  String name;
  Offset pos;
  double principalRemaining;
  double maxPrincipal;
  double speed;
  double radius;
  Color color;
  double drainRate;
  int rewardGold;
  bool isBoss;
}

class _CoinProjectile {
  _CoinProjectile({required this.pos, required this.velocity, required this.damage});
  Offset pos;
  Offset velocity;
  double damage;
}

class _Particle {
  _Particle({required this.pos, required this.velocity, required this.color, required this.life});
  Offset pos;
  Offset velocity;
  Color color;
  double life;
}

class _TreasureChest {
  _TreasureChest({required this.pos});
  final Offset pos;
}

class _BrawlPainter extends CustomPainter {
  _BrawlPainter({
    required this.playerPos,
    required this.playerRadius,
    required this.bankBalance,
    required this.maxBankBalance,
    required this.liabilities,
    required this.coins,
    required this.particles,
    required this.chests,
    required this.chestRadius,
    required this.emergencyFundLevel,
    required this.shieldAngle,
    required this.equippedSkinId,
    required this.treePositions,
    required this.treeRadius,
    required this.rockPositions,
    required this.rockRadius,
    required this.mapWidth,
    required this.mapHeight,
    required this.camOffset,
  });

  final Offset playerPos;
  final double playerRadius;
  final int bankBalance;
  final int maxBankBalance;
  final List<_FinancialLiability> liabilities;
  final List<_CoinProjectile> coins;
  final List<_Particle> particles;
  final List<_TreasureChest> chests;
  final double chestRadius;
  final int emergencyFundLevel;
  final double shieldAngle;
  final String equippedSkinId;
  
  final List<Offset> treePositions;
  final double treeRadius;
  final List<Offset> rockPositions;
  final double rockRadius;
  final double mapWidth;
  final double mapHeight;
  final Offset camOffset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(camOffset.dx, camOffset.dy);

    // Map background
    canvas.drawRect(Rect.fromLTWH(0, 0, mapWidth, mapHeight), Paint()..color = const Color(0xFF1E3A2B));
    final grassPaint = Paint()..color = const Color(0xFF244433);
    for (double x = 0; x < mapWidth; x += 160) {
      for (double y = 0; y < mapHeight; y += 160) {
        canvas.drawRect(Rect.fromLTWH(x, y, 80, 80), grassPaint);
        canvas.drawRect(Rect.fromLTWH(x + 80, y + 80, 80, 80), grassPaint);
      }
    }

    // Border
    canvas.drawRect(Rect.fromLTWH(0, 0, mapWidth, mapHeight), Paint()..color = const Color(0xFF9E4242)..strokeWidth = 10..style = PaintingStyle.stroke);

    // Obstacles
    final rockPaint = Paint()..color = const Color(0xFF5A635E);
    for (final rock in rockPositions) {
      canvas.drawCircle(rock, rockRadius, rockPaint);
    }

    final treeTrunkPaint = Paint()..color = const Color(0xFF4A2F13);
    final treeLeavesPaint = Paint()..color = const Color(0xFF165231);
    for (final tree in treePositions) {
      canvas.drawRect(Rect.fromCenter(center: tree, width: 8, height: 26), treeTrunkPaint);
      canvas.drawCircle(tree - const Offset(0, 14), treeRadius, treeLeavesPaint);
    }

    // Render Liabilities (Debts / Market Crises)
    for (final mob in liabilities) {
      canvas.drawCircle(mob.pos, mob.radius, Paint()..color = mob.color);

      // Remaining Principal Bar
      double hpPercent = (mob.principalRemaining / mob.maxPrincipal).clamp(0.0, 1.0);
      final barW = mob.radius * 2.2;
      final barH = mob.isBoss ? 7.0 : 4.0;
      final barLeft = mob.pos.dx - (barW / 2);
      final barTop = mob.pos.dy - mob.radius - (mob.isBoss ? 16 : 10);

      canvas.drawRect(Rect.fromLTWH(barLeft, barTop, barW, barH), Paint()..color = Colors.black45);
      canvas.drawRect(Rect.fromLTWH(barLeft, barTop, barW * hpPercent, barH), Paint()..color = mob.isBoss ? const Color(0xFFFF2F55) : const Color(0xFFE25C5C));

      // Label debt name
      final textPainter = TextPainter(
        text: TextSpan(text: mob.name, style: TextStyle(color: Colors.white70, fontSize: mob.isBoss ? 12 : 9, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, mob.pos - Offset(textPainter.width / 2, mob.radius + (mob.isBoss ? 32 : 22)));
    }

    // Render Flying Gold Coins
    final coinPaint = Paint()..color = const Color(0xFFFFD700);
    final coinBorderPaint = Paint()..color = const Color(0xFFB8860B)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (final coin in coins) {
      canvas.drawCircle(coin.pos, 7.0, coinPaint);
      canvas.drawCircle(coin.pos, 7.0, coinBorderPaint);
    }

    // Particles
    for (final part in particles) {
      canvas.drawCircle(part.pos, 2.5, Paint()..color = part.color.withValues(alpha: (part.life / 0.22).clamp(0.0, 1.0)));
    }

    // Render Market Windfall Chests
    final chestPaint = Paint()..color = const Color(0xFFE1BB72);
    final chestTrimPaint = Paint()..color = const Color(0xFF8C6621);
    for (final chest in chests) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: chest.pos, width: chestRadius * 2, height: chestRadius * 1.5),
          const Radius.circular(4),
        ),
        chestPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(chest.pos.dx - chestRadius, chest.pos.dy - 2, chestRadius * 2, 4),
        chestTrimPaint,
      );
    }

    // Render Emergency Fund Spinning Cash Shields
    if (emergencyFundLevel > 0) {
      double shieldRadius = 55.0 + (emergencyFundLevel * 10.0);
      int shieldCount = min(4, 1 + emergencyFundLevel);
      final shieldPaint = Paint()..color = const Color(0xFF85EFAC);
      
      for (int s = 0; s < shieldCount; s++) {
        double angleOffset = shieldAngle + (s * (2 * pi / shieldCount));
        Offset shieldPos = playerPos + Offset(cos(angleOffset), sin(angleOffset)) * shieldRadius;

        canvas.drawCircle(shieldPos, 10.0, shieldPaint);
        canvas.drawCircle(shieldPos, 10.0, Paint()..color = Colors.black45..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }

    // Player
    canvas.drawCircle(playerPos, playerRadius, Paint()..color = const Color(0xFF0F261D));
    canvas.drawCircle(playerPos, playerRadius, Paint()..color = const Color(0xFF85EFAC)..strokeWidth = 3.0..style = PaintingStyle.stroke);

    final textPainter = TextPainter(
      text: TextSpan(text: equippedSkinId.isNotEmpty ? equippedSkinId.characters.first.toUpperCase() : '\$', style: const TextStyle(color: Color(0xFF85EFAC), fontWeight: FontWeight.w900, fontSize: 18)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, playerPos - Offset(textPainter.width / 2, textPainter.height / 2));

    // Player Balance HUD Bar
    double playerBalancePercent = (bankBalance / maxBankBalance).clamp(0.0, 1.0);
    final pBarW = 72.0;
    final pBarH = 6.0;
    canvas.drawRect(Rect.fromLTWH(playerPos.dx - (pBarW / 2), playerPos.dy + playerRadius + 10, pBarW, pBarH), Paint()..color = Colors.black87);
    canvas.drawRect(Rect.fromLTWH(playerPos.dx - (pBarW / 2), playerPos.dy + playerRadius + 10, pBarW * playerBalancePercent, pBarH), Paint()..color = const Color(0xFF85EFAC));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrawlPainter oldDelegate) => true;
}