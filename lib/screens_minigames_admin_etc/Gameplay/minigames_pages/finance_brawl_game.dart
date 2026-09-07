import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import '../../../models_Like_Skins_and_lessons_templates/brawl_enemies.dart';
import '../../../models_Like_Skins_and_lessons_templates/reading_grade.dart';
import '../../../models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_assets.dart';
import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../widgets_custom_lotties/game_toast.dart';
import '../../../widgets_custom_lotties/fitted_label.dart';
import '../../../widgets_custom_lotties/money_glyphs.dart';
import '../../../widgets_custom_lotties/pixel_kit.dart';
import '../../../models_Like_Skins_and_lessons_templates/brawl_questions_extra.dart';
import '../../../themes_colors/app_theme.dart';

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

/// The extra bank, adapted to the game's own question type.
///
/// Kept as a separate model in `brawl_questions_extra.dart` so the bank can
/// grow without this 3,800-line file growing with it, and so the questions can
/// be tested without pumping a game.
final List<FinanceQuestion> _extraBrawlQuestions = kBrawlExtraQuestions
    .map(
      (q) => FinanceQuestion(
        question: q.question,
        options: q.options,
        correctIndex: q.correctIndex,
        explanation: q.explanation,
      ),
    )
    .toList(growable: false);

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

/// One offer on the level-up screen.
///
/// Carries its current level so the card can say **Lv 2 → 3** rather than
/// repeating the same sentence every time it appears. That difference is most
/// of what makes a run feel like it is going somewhere: an upgrade you have
/// taken three times should look different from one you have never seen.
class BrawlUpgrade {
  const BrawlUpgrade({
    required this.name,
    required this.description,
    required this.icon,
    required this.action,
    this.level = 0,
    this.maxLevel = 0,
  });

  final String name;
  final String description;
  final IconData icon;
  final VoidCallback action;

  /// How many times this has been taken already.
  final int level;

  /// 0 for the handful of one-off effects that do not level.
  final int maxLevel;

  bool get isLevelled => maxLevel > 0;

  /// "Lv 2 → 3", or "MAX" on the last step.
  String get levelLabel {
    if (!isLevelled) return '';
    if (level + 1 >= maxLevel) return 'Lv $level → MAX';
    return 'Lv $level → ${level + 1}';
  }
}

const Color _brawlInk = Color(0xFF071711);
const Color _brawlPanel = Color(0xFF10281F);
const Color _brawlPanelDeep = Color(0xFF0A1814);
const Color _brawlBorder = Color(0xFF1F4D3E);
const Color _brawlMint = Color(0xFF85EFAC);
const Color _brawlGold = Color(0xFFE1BB72);
const Color _brawlBlue = Color(0xFF6CB6DA);
const Color _brawlRed = Color(0xFFE25C5C);
const Color _brawlDanger = Color(0xFFFF2F55);

class FinanceBrawlScreen extends StatefulWidget {
  const FinanceBrawlScreen({super.key});

  @override
  State<FinanceBrawlScreen> createState() => _FinanceBrawlScreenState();
}

class _FinanceBrawlScreenState extends State<FinanceBrawlScreen>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  final FocusNode _keyboardFocusNode = FocusNode();

  late Size _canvasSize;
  Offset _playerPos = const Offset(800, 800);
  final double _playerRadius = 24.0;

  ui.Image? _treeImage;
  ui.Image? _rockImage;
  ui.Image? _dollarImage;
  ui.Image? _enemyOneImage;
  ui.Image? _enemyTwoImage;
  ui.Image? _bossImage;
  ui.Image? _chestImage;

  /// The player's own uploaded profile picture, drawn inside the player token.
  /// Null until it loads, or permanently null when they haven't uploaded one —
  /// the painter falls back to a letter in that case.
  ui.Image? _profileImage;
  String? _profileImageUrlLoaded;

  // 3. Add the loading helper method:
  Future<void> _loadbrawlTreeSprite() async {
    final ByteData data = await rootBundle.load(AppAssets.brawlTreeSprite);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _treeImage = fi.image;
      });
    }
  }

  Future<void> _loadbrawlRockSprite() async {
    final ByteData data = await rootBundle.load(AppAssets.brawlRockSprite);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _rockImage = fi.image;
      });
    }
  }

  Future<void> _loadbrawlDollarSprite() async {
    final ByteData data = await rootBundle.load(AppAssets.brawlDollarSprite);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _dollarImage = fi.image;
      });
    }
  }

  Future<void> _loadbrawlEnemyOneSprite() async {
    final ByteData data = await rootBundle.load(AppAssets.brawlEnemyOneSprite);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _enemyOneImage = fi.image;
      });
    }
  }

  Future<void> _loadbrawlEnemyTwoSprite() async {
    final ByteData data = await rootBundle.load(AppAssets.brawlEnemyTwoSprite);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _enemyTwoImage = fi.image;
      });
    }
  }

  Future<void> _loadbrawlBossSprite() async {
    final ByteData data = await rootBundle.load(AppAssets.brawlBossSprite);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _bossImage = fi.image;
      });
    }
  }

  Future<void> _loadbrawlChestSprite() async {
    final ByteData data = await rootBundle.load(AppAssets.brawlChestSprite);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _chestImage = fi.image;
      });
    }
  }

  /// Resolves the profile picture URL into a raw [ui.Image] the canvas can
  /// draw. Unlike the sprites above this is a network image, so it goes
  /// through the image cache rather than rootBundle, and failure is silent —
  /// a broken avatar should never take the game down.
  void _loadProfileImage(String url) {
    if (url.isEmpty || url == _profileImageUrlLoaded) {
      return;
    }
    _profileImageUrlLoaded = url;
    final stream = NetworkImage(
      url,
    ).resolve(const ImageConfiguration(size: Size(96, 96)));
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (mounted) {
          setState(() => _profileImage = info.image);
        }
      },
      onError: (_, _) {
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  // Finance Overhaul: Balance instead of health
  int _bankBalance = 10000;
  final int _maxBankBalance = 10000;

  final double _mapWidth = 2400.0;
  final double _mapHeight = 2400.0;

  final List<Offset> _treePositions = [];
  final double _treeRadius = 35.0;
  final List<Offset> _rockPositions = [];
  final double _rockRadius = 20.0;

  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Offset? _touchMoveAnchor;
  Offset _touchMoveVector = Offset.zero;
  Offset _touchMoveKnob = Offset.zero;

  int _debtsCleared = 0;
  int _debtsNeededForLevelUp = 6;
  int _wave = 1;
  int _goldAccumulated = 0;
  int _xpAccumulated = 0;
  bool _isGameOver = false;
  bool _isSavingAndExiting = false;
  bool _bossActive = false;

  /// Fire-rate scale. No longer final: "Compound Interest" raises it, which
  /// is the upgrade that makes every other weapon modifier land more often.
  double _attackSpeedMultiplier = 1.0;
  double _coinDamage = 35.0;

  // ---- Weapon modifiers -------------------------------------------------
  //
  // there were five upgrades and four of them were just flat number bumps,
  // so a long run felt identical to a short one but with bigger digits.
  // these change *how* you shoot rather than how hard, which is what lets a
  // build actually go overpowered — that surviv.io thing where a fight you
  // were losing turns into a lawnmower.
  //
  // they stack multiplicatively with the flat ones on purpose. spread x
  // splash x pierce is where the whole power fantasy lives

  /// Extra coins per shot, fanned around the aim line.
  /// How many times each levelled upgrade has been taken.
  ///
  /// **Why levels rather than a bag of one-shot pickups.** The original pool
  /// offered the same eight sentences forever, so a run's shape was decided
  /// by which of them the shuffle happened to show you and there was no such
  /// thing as committing to a build. Levelled tracks fix both halves: taking
  /// Rapid Payments three times is a *decision* with a visible number
  /// attached, and a maxed track leaves the pool — so the offers narrow as a
  /// run goes on and the last few choices are between things you actually
  /// want. That is the survivor-style loop the game was reaching for.
  final Map<String, int> _upgradeLevels = <String, int>{};

  int _levelOf(String id) => _upgradeLevels[id] ?? 0;

  int _spreadShots = 0;

  /// Radius of the damage burst when a coin lands. Zero disables it.
  double _splashRadius = 0;

  /// Enemies each coin passes through before expiring.
  int _pierceCount = 0;

  /// Coins released in a ring on a timer. Zero disables the nova entirely.
  int _novaCoins = 0;
  double _novaTimer = 0;
  static const double _novaInterval = 3.2;
  final double _coinSpeed = 380.0;
  int _coinStreamCount = 1;
  double _playerSpeed = 220.0;

  // Emergency Fund Shield Mechanics
  int _emergencyFundLevel = 0;
  double _shieldAngle = 0.0;
  double _shieldDamageCooldown = 0.0;

  double _lastSpawnTime = 0.0;
  double _lastAttackTime = 0.0;
  double _lastBossAttackTime = 0.0; // Boss shooting cooldown tracking
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
        "Unexpected critical expenses like medical bills or repairs",
        "Investing in high-risk stocks",
        "Paying monthly bills",
      ],
      correctIndex: 1,
      explanation:
          "An emergency fund protects you against unexpected setbacks without forcing you into debt.",
    ),
    FinanceQuestion(
      question: "What does 'paying yourself first' mean in budgeting?",
      options: [
        "Set aside savings as soon as you are paid before spending the rest",
        "Buy new clothes before paying your electric and water bills",
        "Give cash to family members immediately upon receiving your paycheck",
        "Spend your entire paycheck on entertainment on payday",
      ],
      correctIndex: 0,
      explanation:
          "Prioritizing savings goals first guarantees you build financial security instead of saving leftover pennies.",
    ),
    FinanceQuestion(
      question:
          "What is the primary goal of creating a monthly zero-based budget?",
      options: [
        "To spend every dollar on entertainment",
        "To lower your bank account balance to zero",
        "To assign every dollar a purpose so Income minus Expenses equals zero",
        "To eliminate all future tax obligations",
      ],
      correctIndex: 2,
      explanation:
          "A zero-based budget assigns every dollar of income to savings, bills, or spending so nothing goes untracked.",
    ),
    FinanceQuestion(
      question: "Which of the following is considered a variable expense?",
      options: [
        "Fixed monthly rent",
        "Car loan payment",
        "Annual insurance premium",
        "Groceries and utility bills",
      ],
      correctIndex: 3,
      explanation:
          "Variable expenses fluctuate month to month based on usage and personal choices, unlike fixed rent payments.",
    ),
    FinanceQuestion(
      question: "What is the popular 50/30/20 budgeting rule framework?",
      options: [
        "50% Needs, 30% Wants, 20% Savings/Debt",
        "50% Investments, 30% Savings, 20% Taxes",
        "50% Rent, 30% Food, 20% Travel",
        "50% Debt, 30% Needs, 20% Fun",
      ],
      correctIndex: 0,
      explanation:
          "The 50/30/20 guideline suggests spending 50% on essential needs, 30% on discretionary wants, and 20% on financial goals.",
    ),
    FinanceQuestion(
      question: "What is a 'sinking fund' used for?",
      options: [
        "Paying off defaulted loans",
        "An account charging negative interest",
        "Saving over time for a specific expected future cost",
        "An automated stock trading account",
      ],
      correctIndex: 2,
      explanation:
          "A sinking fund lets you set aside small monthly amounts for planned future costs like car maintenance or holidays.",
    ),
    FinanceQuestion(
      question:
          "Which expenditure is categorized as a 'Need' rather than a 'Want'?",
      options: [
        "Designer shoes",
        "Essential prescription medication",
        "Video game subscriptions",
        "Dining out at restaurants",
      ],
      correctIndex: 1,
      explanation:
          "Needs are basic items essential for survival, healthcare, shelter, and employment.",
    ),
    FinanceQuestion(
      question:
          "How many months of living expenses are typically recommended for a full emergency fund?",
      options: ["1 to 2 weeks", "3 to 5 years", "3 to 6 months", "10 years"],
      correctIndex: 2,
      explanation:
          "Financial advisors generally recommend keeping 3 to 6 months of basic living costs in liquid savings.",
    ),
    FinanceQuestion(
      question:
          "What happens if you overdraw your checking account without overdraft protection?",
      options: [
        "The bank gives you free credit",
        "Your credit score increases",
        "Your account is converted into a CD",
        "The payment is declined or you incur an overdraft fee",
      ],
      correctIndex: 3,
      explanation:
          "Attempting to spend more than your account balance leads to declined transactions or overdraft penalties.",
    ),
    FinanceQuestion(
      question: "What is opportunistic 'lifestyle creep'?",
      options: [
        "Increasing spending as income rises, preventing wealth accumulation",
        "Increasing your savings when your salary drops unexpectedly",
        "Moving into a smaller apartment to save money on utility bills",
        "Automating bill payments every month through your mobile app",
      ],
      correctIndex: 0,
      explanation:
          "Lifestyle creep occurs when raises or bonuses trigger higher spending on luxury items instead of boosting savings.",
    ),
    FinanceQuestion(
      question:
          "Why should you track your daily cash flow and micro-purchases?",
      options: [
        "To satisfy bank auditors",
        "To spot hidden leaks like forgotten recurring subscriptions",
        "To calculate capital gains taxes on coffee",
        "To double your checking account balance",
      ],
      correctIndex: 1,
      explanation:
          "Small unmonitored purchases add up rapidly over time and can drain hundreds of dollars from your budget.",
    ),
    FinanceQuestion(
      question: "What is gross income?",
      options: [
        "Income left after taxes and deductions",
        "Money earned solely from investment dividends",
        "Total earnings before taxes and deductions are removed",
        "Income spent strictly on household bills",
      ],
      correctIndex: 2,
      explanation:
          "Gross income is your raw total compensation before income tax, insurance premiums, and retirement contributions are removed.",
    ),
    FinanceQuestion(
      question: "What is net income (take-home pay)?",
      options: [
        "Total salary before tax",
        "Total profit from selling a house",
        "Total interest paid on credit cards",
        "The money deposited into your account after taxes and deductions",
      ],
      correctIndex: 3,
      explanation:
          "Net income is the actual usable money available to spend or save after all paystub withholdings.",
    ),
    FinanceQuestion(
      question:
          "Which tool automatically moves money into savings without manual intervention?",
      options: [
        "Recurring automatic bank transfers or direct deposit allocations",
        "Manual wire transfer",
        "Paper check writing",
        "ATM cash withdrawal",
      ],
      correctIndex: 0,
      explanation:
          "Automated recurring transfers remove human discipline hurdles and ensure consistent savings habit building.",
    ),
    FinanceQuestion(
      question: "What is an opportunity cost in personal finance?",
      options: [
        "The interest charged by a bank loan",
        "The tax deduction on charitable donations",
        "The potential gain lost from one choice when another option is taken",
        "The fee charged to open a savings account",
      ],
      correctIndex: 2,
      explanation:
          "Opportunity cost is the trade-off value—spending \$100 on shoes today means losing future interest if invested.",
    ),
    FinanceQuestion(
      question: "What is the envelope budgeting method?",
      options: [
        "Mailing checks to creditors in physical paper envelopes",
        "Allocating set cash amounts into envelopes for specific spending categories",
        "Storing investment certificates in a safe",
        "Filing tax returns through postal delivery",
      ],
      correctIndex: 1,
      explanation:
          "Envelope budgeting relies on cash envelopes for categories like groceries—when the cash runs out, spending stops.",
    ),
    FinanceQuestion(
      question: "Why is discretionary spending dangerous if unmonitored?",
      options: [
        "It lowers your tax refund automatically",
        "It causes instant bank account termination",
        "It freezes your credit score",
        "It can consume funds needed for essential bills and debt payments",
      ],
      correctIndex: 3,
      explanation:
          "Discretionary non-essential spending easily expands, causing missed savings targets or unpaid essential bills.",
    ),
    FinanceQuestion(
      question: "Which of these is a fixed expense?",
      options: [
        "Weekly grocery runs",
        "Fixed apartment lease payment",
        "Electric heating bill in winter",
        "Dining out expenses",
      ],
      correctIndex: 1,
      explanation:
          "Fixed expenses stay predictable and identical in cost across every payment cycle, simplifying planning.",
    ),
    FinanceQuestion(
      question: "What does the term 'solvency' mean for an individual?",
      options: [
        "Having zero cash in hand",
        "Having multiple credit card accounts open",
        "Having total assets that exceed your total debts and financial liabilities",
        "Earning income solely from dividends",
      ],
      correctIndex: 2,
      explanation:
          "Solvency means your overall assets outweigh what you owe, ensuring long-term financial stability.",
    ),
    FinanceQuestion(
      question: "What is a major risk of not maintaining a financial buffer?",
      options: [
        "Relying on high-interest debt when unexpected costs happen",
        "Higher investment returns",
        "Decreased tax liability",
        "Lower insurance premiums",
      ],
      correctIndex: 0,
      explanation:
          "Without savings, sudden repairs or emergencies force people to use high-cost loans or credit cards.",
    ),

    // -------------------------------------------------------------
    // SAVINGS & INTEREST (21-40)
    // -------------------------------------------------------------
    FinanceQuestion(
      question:
          "If you leave \$100 in a savings account with a 5% annual simple interest rate, how much is there after 1 year?",
      options: ["\$105", "\$100", "\$150", "\$110"],
      correctIndex: 0,
      explanation:
          "Simple interest calculates 5% of \$100, which yields \$5, bringing your total account balance to \$105.",
    ),
    FinanceQuestion(
      question: "What is compound interest?",
      options: [
        "Interest earned only on your original cash deposit",
        "Interest earned on principal plus past earned interest",
        "A flat fee charged by banks to hold cash",
        "Tax applied directly to high net worth individuals",
      ],
      correctIndex: 1,
      explanation:
          "Compound interest creates snowball growth because your earned interest generates its own interest over time.",
    ),
    FinanceQuestion(
      question: "What does 'APY' stand for on a bank savings account?",
      options: [
        "Annual Percentage Yield",
        "Automated Payment Year",
        "Asset Allocation Profit Yield",
        "Average Principal Yield",
      ],
      correctIndex: 0,
      explanation:
          "APY reflects the actual total interest earned over a year, accounting for compounding frequency.",
    ),
    FinanceQuestion(
      question: "What is the 'Rule of 72' used to estimate?",
      options: [
        "The percentage of income to spend on housing",
        "The age everyone must retire",
        "The maximum credit score attainable",
        "How long it takes an investment to double at a given rate",
      ],
      correctIndex: 3,
      explanation:
          "Dividing 72 by your annual interest rate gives the approximate years it takes for your principal to double.",
    ),
    FinanceQuestion(
      question:
          "At a 6% annual return rate, roughly how many years will it take your money to double (Rule of 72)?",
      options: ["12 years", "6 years", "72 years", "18 years"],
      correctIndex: 0,
      explanation:
          "72 divided by 6 equals 12 years to double your initial capital investment.",
    ),
    FinanceQuestion(
      question:
          "What primary benefit does a High-Yield Savings Account (HYSA) offer over standard checking?",
      options: [
        "Free stock trades",
        "Higher interest rates while keeping FDIC insurance and easy cash access",
        "Unlimited cash withdrawals without limits",
        "Zero taxes on earned interest",
      ],
      correctIndex: 1,
      explanation:
          "HYSAs provide superior interest rates compared to traditional accounts while keeping money secure and accessible.",
    ),
    FinanceQuestion(
      question: "What is a Certificate of Deposit (CD)?",
      options: [
        "A volatile cryptocurrency asset",
        "A credit card reward voucher",
        "A savings product locking money for a set term for fixed interest",
        "A government bond with floating rates",
      ],
      correctIndex: 2,
      explanation:
          "CDs lock up your deposit for a set timeframe; early withdrawals usually trigger interest penalties.",
    ),
    FinanceQuestion(
      question:
          "What institution in the US insures individual bank deposits up to \$250,000?",
      options: [
        "FDIC (Federal Deposit Insurance Corporation)",
        "SEC (Securities and Exchange Commission)",
        "IRS (Internal Revenue Service)",
        "Federal Reserve Board",
      ],
      correctIndex: 0,
      explanation:
          "The FDIC guarantees member bank deposits, protecting consumer funds even if the bank defaults.",
    ),
    FinanceQuestion(
      question:
          "How does inflation impact cash sitting in a standard 0.01% savings account?",
      options: [
        "Increases purchasing power rapidly",
        "It loses purchasing power because price increases outpace savings interest",
        "Has no effect on real value",
        "Multiplies the principal balance automatically",
      ],
      correctIndex: 1,
      explanation:
          "If inflation is 3% and interest is 0.01%, your real purchasing power drops by roughly 3% each year.",
    ),
    FinanceQuestion(
      question:
          "What is the difference between simple interest and compound interest?",
      options: [
        "Simple interest grows exponentially; Compound interest grows linearly",
        "Simple interest applies only to stocks; Compound interest applies to loans",
        "There is no functional difference",
        "Simple interest applies only to principal; Compound interest earns interest on prior interest",
      ],
      correctIndex: 3,
      explanation:
          "Simple interest stays flat, whereas compound interest compounds continuously, driving long-term growth.",
    ),
    FinanceQuestion(
      question:
          "If interest compounds monthly versus annually at the same nominal rate, which yields more money?",
      options: [
        "Annual compounding",
        "Monthly compounding",
        "They yield the exact same amount",
        "Neither yields interest",
      ],
      correctIndex: 1,
      explanation:
          "More frequent compounding periods calculate interest on newly added gains faster, resulting in higher overall yield.",
    ),
    FinanceQuestion(
      question: "What is a money market savings account?",
      options: [
        "A high-risk stock account",
        "A physical vault for cash and gold",
        "A savings account that offers check writing and higher interest",
        "An uninsured investment fund",
      ],
      correctIndex: 2,
      explanation:
          "Money market accounts combine competitive interest rates with basic transactional access like debit cards or checks.",
    ),
    FinanceQuestion(
      question:
          "What penalty do you usually face for withdrawing money early from a fixed CD?",
      options: [
        "Loss of a portion of accumulated interest earnings",
        "Permanent account suspension",
        "A credit score reduction of 100 points",
        "Forfeiture of all original principal deposits",
      ],
      correctIndex: 0,
      explanation:
          "Banks assess an early withdrawal penalty equal to a set number of months of interest if you cash out a CD early.",
    ),
    FinanceQuestion(
      question: "What is liquidity in personal finance?",
      options: [
        "The total amount of debt owed",
        "How quickly an asset converts to cash without losing value",
        "The interest rate on a mortgage",
        "The profit made from stock sales",
      ],
      correctIndex: 1,
      explanation:
          "Cash in a checking account is highly liquid, whereas real estate is illiquid because selling takes time.",
    ),
    FinanceQuestion(
      question: "Why are physical cash savings stored under a mattress risky?",
      options: [
        "It gains too much interest to track",
        "The government taxes hidden physical cash twice",
        "It automatically degrades into unreadable paper",
        "It earns zero interest, loses purchasing power to inflation, and can be stolen or damaged",
      ],
      correctIndex: 3,
      explanation:
          "Unbanked cash loses real value to inflation and lacks deposit insurance against disaster or theft.",
    ),
    FinanceQuestion(
      question: "What is 'nominal interest rate'?",
      options: [
        "The stated interest rate before adjusting for inflation",
        "The interest rate after adjusting for inflation",
        "The maximum rate charged by credit cards",
        "The fee charged for international bank transfers",
      ],
      correctIndex: 0,
      explanation:
          "The nominal rate is the baseline advertised rate, whereas the real rate subtracts current inflation.",
    ),
    FinanceQuestion(
      question: "What is 'real interest rate'?",
      options: [
        "The total rate including bank service fees",
        "The interest rate on payday loans",
        "The nominal interest rate minus the inflation rate",
        "The rate guaranteed by FDIC insurance",
      ],
      correctIndex: 2,
      explanation:
          "Real interest rate reflects actual purchasing power growth by taking inflation into account.",
    ),
    FinanceQuestion(
      question:
          "If your savings account earns 4% APY and annual inflation is 3%, what is your real rate of return?",
      options: ["7%", "1%", "12%", "0.75%"],
      correctIndex: 1,
      explanation:
          "Subtract 3% inflation from 4% APY to get a real purchasing power gain of 1%.",
    ),
    FinanceQuestion(
      question: "What does the NCUA insure in the financial system?",
      options: [
        "Traditional commercial bank deposits",
        "Deposits at credit unions up to \$250,000",
        "Stock market brokerages",
        "Private peer-to-peer loans",
      ],
      correctIndex: 1,
      explanation:
          "The National Credit Union Administration (NCUA) provides insurance protection for credit union accounts.",
    ),
    FinanceQuestion(
      question: "What is a CD Ladder strategy?",
      options: [
        "Borrowing money from multiple CDs at once",
        "Staggering multiple CD maturity dates to keep liquidity while earning higher rates",
        "Paying off high-interest CDs first",
        "Buying stocks through a bank certificate",
      ],
      correctIndex: 1,
      explanation:
          "Staggering CD maturity dates ensures regular access to maturing cash while capturing higher long-term yields.",
    ),

    // -------------------------------------------------------------
    // CREDIT, DEBT & LOANS (41-60)
    // -------------------------------------------------------------
    FinanceQuestion(
      question:
          "What is the difference between a credit card and a debit card?",
      options: [
        "Debit cards borrow funds from a bank; Credit cards tap your checking balance directly.",
        "Credit cards instantly withdraw money you currently own; Debit cards act as loans.",
        "Debit cards pull money directly from checking; Credit cards use borrowed credit lines.",
        "There is no functional financial operational difference.",
      ],
      correctIndex: 2,
      explanation:
          "Debit draws cash directly from your bank balance; credit is a revolving loan you must repay.",
    ),
    FinanceQuestion(
      question:
          "Which component has the single largest impact on calculating your FICO credit score?",
      options: [
        "Length of credit history",
        "Types of credit used",
        "Total number of credit inquiries",
        "Payment history (paying bills on time)",
      ],
      correctIndex: 3,
      explanation:
          "Payment history accounts for roughly 35% of your total credit score, making on-time payments essential.",
    ),
    FinanceQuestion(
      question: "What is a credit utilization ratio?",
      options: [
        "The percentage of your total available credit lines currently in use",
        "The total amount of debt paid off per year",
        "The interest rate charged on mortgage loans",
        "The ratio of income to credit card rewards points",
      ],
      correctIndex: 0,
      explanation:
          "Credit utilization measures used credit against overall limits. Keeping it under 30% helps protect credit scores.",
    ),
    FinanceQuestion(
      question: "What is the 'debt avalanche' debt payoff strategy?",
      options: [
        "Paying off debts from smallest balance to largest balance",
        "Paying minimums on all balances while putting extra money toward the debt with the highest interest rate",
        "Filing for bankruptcy immediately",
        "Consolidating all loans into a single low-interest credit card",
      ],
      correctIndex: 1,
      explanation:
          "The debt avalanche mathematically minimizes interest costs by targeting high-APR balances first.",
    ),
    FinanceQuestion(
      question:
          "What is the 'debt snowball' strategy made popular by financial planners?",
      options: [
        "Targeting the debt with the highest interest rate first",
        "Stopping all payments until loans enter default",
        "Paying off smallest balances first for momentum",
        "Transferring debt to overseas accounts",
      ],
      correctIndex: 2,
      explanation:
          "Debt snowball focuses on quick psychological wins by eliminating small debts first.",
    ),
    FinanceQuestion(
      question:
          "What happens if you only pay the minimum monthly balance on a high-APR credit card?",
      options: [
        "Your debt disappears within 12 months",
        "High interest makes repayment take years, drastically raising the total cost",
        "The card issuer waives remaining interest charges",
        "Your credit score automatically maxes out",
      ],
      correctIndex: 1,
      explanation:
          "Minimum payments cover mostly interest, leaving the core principal virtually unchanged for long periods.",
    ),
    FinanceQuestion(
      question: "What is collateral in the context of a secured loan?",
      options: [
        "A cash bonus given by lenders",
        "An asset pledged to secure a loan, which the lender can take if you default",
        "The total interest accumulated over a loan's term",
        "The credit score of a co-signer",
      ],
      correctIndex: 1,
      explanation:
          "Secured loans (like auto loans or mortgages) use physical property as collateral to back the loan.",
    ),
    FinanceQuestion(
      question: "Which of these is an example of an unsecured loan?",
      options: [
        "A traditional home mortgage",
        "An auto loan backed by a vehicle title",
        "A standard personal credit card",
        "A pawn shop pawn loan",
      ],
      correctIndex: 2,
      explanation:
          "Credit cards are unsecured loans—lenders approve them based on creditworthiness without physical collateral.",
    ),
    FinanceQuestion(
      question: "What is APR in personal credit agreements?",
      options: [
        "Annual Percentage Rate",
        "Average Principal Return",
        "Automated Payment Recovery",
        "Annual Profit Ratio",
      ],
      correctIndex: 0,
      explanation:
          "APR represents the total annualized cost of borrowing, including interest rates and required finance fees.",
    ),
    FinanceQuestion(
      question: "What is a grace period on a standard credit card?",
      options: [
        "A time window where you can spend unlimited funds without credit limits",
        "The time given to pay off defaulted debts after bankruptcy",
        "A period where credit card annual fees are waived",
        "The window where no interest accrues if you pay the balance in full",
      ],
      correctIndex: 3,
      explanation:
          "Paying your statement balance in full before the grace period ends lets you avoid paying interest entirely.",
    ),
    FinanceQuestion(
      question:
          "What impact does closing an old, paid-off credit card account have on your credit score?",
      options: [
        "Always increases your score immediately",
        "It can lower your score by reducing available credit and shortening credit history age",
        "Has zero effect on credit calculations",
        "Erases late payment history permanently",
      ],
      correctIndex: 1,
      explanation:
          "Closing old accounts shrinks total credit lines (raising utilization) and reduces average credit account age.",
    ),
    FinanceQuestion(
      question: "What is predatory lending?",
      options: [
        "Low-rate government student loans",
        "Deceptive or unfair loan practices with extreme interest rates and hidden fees",
        "Standard high-yield bank savings products",
        "Interest-free promotional financing",
      ],
      correctIndex: 1,
      explanation:
          "Predatory lenders take advantage of borrowers using misleading terms, extreme interest rates, and excessive trap fees.",
    ),
    FinanceQuestion(
      question: "Why are payday loans considered highly financially dangerous?",
      options: [
        "They require high credit scores to qualify",
        "They require valuable real estate assets as collateral",
        "They carry extremely high annual interest rates that trap borrowers in debt cycles",
        "They lock up funds for 10 years",
      ],
      correctIndex: 2,
      explanation:
          "Payday loans carry triple-digit annualized interest rates that trap borrowers in continuous refinancing cycles.",
    ),
    FinanceQuestion(
      question: "What is debt consolidation?",
      options: [
        "Merging multiple debts into a single loan, ideally with a lower interest rate",
        "Refusing to pay multiple bills until debt is forgiven",
        "Declaring Chapter 7 bankruptcy",
        "Converting debt directly into corporate stock",
      ],
      correctIndex: 0,
      explanation:
          "Consolidation merges multiple debts into a single monthly payment to simplify tracking and lower overall interest rates.",
    ),
    FinanceQuestion(
      question: "What is a hard inquiry (hard pull) on a credit report?",
      options: [
        "Checking your own credit score on a mobile app",
        "A credit check performed by a lender when you apply for a new line of credit",
        "An annual audit by the Internal Revenue Service",
        "An automated account review by an existing lender",
      ],
      correctIndex: 1,
      explanation:
          "Hard inquiries occur during loan applications and can temporarily drop your credit score by a few points.",
    ),
    FinanceQuestion(
      question: "What is a co-signer legally obligated to do on a loan?",
      options: [
        "Nothing unless they choose to help",
        "Pay only 10% of remaining missed payments",
        "Receive monthly dividend checks from the lender",
        "Pay back the loan in full if the main borrower misses payments or defaults",
      ],
      correctIndex: 3,
      explanation:
          "Co-signers accept full legal responsibility for debt repayment if the main borrower misses payments or defaults.",
    ),
    FinanceQuestion(
      question: "What constitutes 'good debt' in financial planning strategy?",
      options: [
        "Debt used to finance luxury vacations",
        "Low-interest debt used to buy assets that grow in value or increase income",
        "High-interest cash advances spent on dining out",
        "Overdraft balances on retail checking accounts",
      ],
      correctIndex: 1,
      explanation:
          "Debt used for mortgages or education can expand net worth or future income, unlike high-cost consumer debt.",
    ),
    FinanceQuestion(
      question: "What is a balance transfer credit card designed for?",
      options: [
        "Earning high cash back on grocery purchases",
        "Moving debt from a high-interest card to one with a lower or 0% introductory rate",
        "Converting cash directly into foreign currency",
        "Waiving federal student loan debts",
      ],
      correctIndex: 1,
      explanation:
          "Balance transfers let you pause interest charges temporarily so you can pay down debt principal faster.",
    ),
    FinanceQuestion(
      question:
          "What is the typical range for FICO credit scores in the United States?",
      options: ["0 to 100", "300 to 850", "100 to 500", "500 to 1000"],
      correctIndex: 1,
      explanation:
          "FICO credit scores range from 300 to 850, with scores above 740 generally considered excellent.",
    ),
    FinanceQuestion(
      question: "What happens when a loan goes into default status?",
      options: [
        "The loan interest rate drops to zero",
        "The debt is automatically erased after 30 days",
        "The lender can demand full payment immediately and send the debt to collections",
        "The government pays off the balance",
      ],
      correctIndex: 2,
      explanation:
          "Default occurs after prolonged missed payments, leading to legal action, debt collections, and severe credit damage.",
    ),

    // -------------------------------------------------------------
    // INVESTING & CAPITAL MARKETS (61-80)
    // -------------------------------------------------------------
    FinanceQuestion(
      question:
          "Which investment carries the risk of losing your original principal capital?",
      options: [
        "An FDIC-insured High-Yield Savings Account",
        "Individual stocks",
        "A bank Certificate of Deposit (CD)",
        "A standard cash checking account",
      ],
      correctIndex: 1,
      explanation:
          "Stocks fluctuate based on business performance and broader economic conditions, meaning capital is at risk.",
    ),
    FinanceQuestion(
      question:
          "What represents partial ownership in a public corporate entity?",
      options: [
        "A corporate bond",
        "A share of stock",
        "A treasury bill",
        "A certificate of deposit",
      ],
      correctIndex: 1,
      explanation:
          "Buying stock gives you equity—a small piece of direct ownership in that business.",
    ),
    FinanceQuestion(
      question: "What is a corporate or government bond?",
      options: [
        "Direct ownership shares in a private startup",
        "A loan you make to an organization that pays you back with interest",
        "An insurance contract protecting against stock market crashes",
        "A cash savings account at a local credit union",
      ],
      correctIndex: 1,
      explanation:
          "Bonds are IOUs—you lend money to a government or corporation, and they pay you regular interest until maturity.",
    ),
    FinanceQuestion(
      question: "What is asset allocation diversification?",
      options: [
        "Putting 100% of capital into a single top-performing stock",
        "Moving all wealth into physical cash under a mattress",
        "Spreading investments across different asset types to lower risk",
        "Trading options contracts with maximum leverage",
      ],
      correctIndex: 2,
      explanation:
          "Diversification reduces risk—if one asset or sector crashes, other investments help buffer the loss.",
    ),
    FinanceQuestion(
      question: "What is an Index Fund?",
      options: [
        "A fund managed by an individual selecting hot daily stocks",
        "A fund that tracks a market benchmark like the S&P 500",
        "A high-interest government savings vehicle",
        "A speculative foreign exchange trading contract",
      ],
      correctIndex: 1,
      explanation:
          "Index funds track entire market segments, providing broad diversification and lower management fees.",
    ),
    FinanceQuestion(
      question: "What is a corporate dividend payment?",
      options: [
        "A distribution of company earnings paid directly to shareholders",
        "A penalty fee paid by corporations when revenues decline",
        "The interest rate charged on business loans",
        "The initial price of an IPO stock share",
      ],
      correctIndex: 0,
      explanation:
          "Dividends are cash payments companies make to reward shareholders out of accumulated profits.",
    ),
    FinanceQuestion(
      question: "What is the S&P 500 index?",
      options: [
        "A list of the 500 highest tax-paying individuals",
        "A government bond paying 5% interest annually",
        "The top 500 commercial banks in North America",
        "An index measuring the stock performance of 500 large public US companies",
      ],
      correctIndex: 3,
      explanation:
          "The S&P 500 is widely considered the primary benchmark for overall US stock market performance.",
    ),
    FinanceQuestion(
      question: "What does Dollar-Cost Averaging (DCA) involve?",
      options: [
        "Timing the market to buy only at absolute rock-bottom lows",
        "Investing a fixed dollar amount on a regular schedule regardless of share price",
        "Selling all investments whenever stock prices decline by 5%",
        "Converting foreign currencies into US dollars daily",
      ],
      correctIndex: 1,
      explanation:
          "DCA builds investment consistency and eliminates emotion by buying more shares when prices are low and fewer when high.",
    ),
    FinanceQuestion(
      question: "What is a Mutual Fund?",
      options: [
        "An investment pool of money from many buyers used to purchase a portfolio of securities",
        "A joint bank account opened between family members",
        "A peer-to-peer loan agreement",
        "A government insurance policy for home buyers",
      ],
      correctIndex: 0,
      explanation:
          "Mutual funds pool money from many investors to buy diversified portfolios managed by professional teams.",
    ),
    FinanceQuestion(
      question: "What is market volatility?",
      options: [
        "The absolute guarantee of losing money in stocks",
        "The total transaction fee charged by online brokerages",
        "How quickly and drastically investment prices move up or down",
        "The legal limit on how high a stock price can rise",
      ],
      correctIndex: 2,
      explanation:
          "High volatility means asset prices swing wildly in short periods, whereas low volatility indicates stable pricing.",
    ),
    FinanceQuestion(
      question: "What is an Exchange-Traded Fund (ETF)?",
      options: [
        "A pooled investment fund that trades on stock exchanges like an individual stock",
        "A wire transfer between international banks",
        "An electronic check processor",
        "A tax refund bond issued by state governments",
      ],
      correctIndex: 0,
      explanation:
          "ETFs operate similarly to mutual funds, but trade like individual stocks on an exchange throughout market hours.",
    ),
    FinanceQuestion(
      question:
          "What is the relationship between risk and return in investing?",
      options: [
        "Higher potential returns come with higher potential risk",
        "Low-risk investments always produce higher long-term returns",
        "Risk and return operate with zero mathematical connection",
        "High returns guarantee absolute capital protection",
      ],
      correctIndex: 0,
      explanation:
          "Higher prospective returns exist to compensate investors for taking on greater risk of potential loss.",
    ),
    FinanceQuestion(
      question: "What is a capital gain?",
      options: [
        "The profit earned when an asset sells for more than its buy price",
        "The initial capital deposited into a checking account",
        "The annual salary earned by corporate executives",
        "The dividend income earned from holding bonds",
      ],
      correctIndex: 0,
      explanation:
          "A capital gain is achieved when you sell an asset (like stock or real estate) for more than you originally paid.",
    ),
    FinanceQuestion(
      question: "What is an Initial Public Offering (IPO)?",
      options: [
        "A company's final liquidation sale during bankruptcy",
        "The first time a company offers its shares to the general public",
        "An international tax treaty on corporate bonds",
        "A bank's promotional interest rate for new accounts",
      ],
      correctIndex: 1,
      explanation:
          "An IPO marks a private business's transition to a public company by issuing shares on a stock exchange.",
    ),
    FinanceQuestion(
      question: "What characterizes a 'Bull Market'?",
      options: [
        "A prolonged period of declining stock prices and economic pessimism",
        "A market condition where asset prices are rising or expected to rise",
        "A market where trading is suspended due to technical errors",
        "A period with high inflation and zero interest rates",
      ],
      correctIndex: 1,
      explanation:
          "Bull markets describe sustained periods of rising asset prices and optimistic investor sentiment.",
    ),
    FinanceQuestion(
      question: "What characterizes a 'Bear Market'?",
      options: [
        "A sustained drop in stock prices, usually 20% or more from recent peaks",
        "A surge in stock prices across all economic sectors",
        "A market where only government bonds are traded",
        "A period of unprecedented corporate dividend payouts",
      ],
      correctIndex: 0,
      explanation:
          "Bear markets occur when market indices drop 20% or more from recent highs amid economic uncertainty.",
    ),
    FinanceQuestion(
      question: "What is a market expense ratio in mutual funds or ETFs?",
      options: [
        "The total tax paid on capital gains",
        "The interest rate paid on margin loans",
        "The annual percentage fee paid to cover fund management costs",
        "The cost to open a brokerage account",
      ],
      correctIndex: 2,
      explanation:
          "Expense ratios represent annual operational costs deducted from your total investment returns in a fund.",
    ),
    FinanceQuestion(
      question: "Why can market timing be dangerous for retail investors?",
      options: [
        "It guarantees you pay double income taxes",
        "Predicting market turns is tough and can cause you to buy high and sell low",
        "Brokerages prohibit buying stocks more than once a month",
        "It eliminates all potential capital losses automatically",
      ],
      correctIndex: 1,
      explanation:
          "Trying to time the market often backfires when investors miss out on the market's best recovery days.",
    ),
    FinanceQuestion(
      question: "What is a Real Estate Investment Trust (REIT)?",
      options: [
        "A government agency that builds public roads",
        "A company that owns or funds income-producing real estate and trades like a stock",
        "A mortgage loan given exclusively to first-time homebuyers",
        "An insurance policy covering rental apartment property damage",
      ],
      correctIndex: 1,
      explanation:
          "REITs let investors buy shares in large real estate portfolios without physically buying or managing property.",
    ),
    FinanceQuestion(
      question: "What does liquidity risk mean for an investor?",
      options: [
        "The risk that a bank goes completely out of business",
        "The risk that you cannot sell an asset quickly for fair market value",
        "The risk that dividends are paid in foreign currency",
        "The risk of interest rates dropping to zero",
      ],
      correctIndex: 1,
      explanation:
          "Liquidity risk happens when you hold an illiquid asset (like artwork or real estate) that cannot be sold fast for cash.",
    ),

    // -------------------------------------------------------------
    // RETIREMENT & TAXES (81-100)
    // -------------------------------------------------------------
    FinanceQuestion(
      question:
          "What primary tax advantage does a traditional 401(k) retirement plan offer?",
      options: [
        "Contributions reduce your current taxable income because they are made pre-tax",
        "Withdrawals in retirement are 100% tax-free",
        "The government matches 50% of all contributions automatically",
        "Money can be withdrawn tax-free at any age",
      ],
      correctIndex: 0,
      explanation:
          "Traditional 401(k) contributions are pre-tax, reducing your tax burden today, though withdrawals in retirement are taxed.",
    ),
    FinanceQuestion(
      question: "How does a Roth IRA differ from a Traditional IRA?",
      options: [
        "Roth IRAs use after-tax contributions so qualified retirement withdrawals are tax-free",
        "Traditional IRAs offer tax-free withdrawals in retirement; Roth IRAs do not",
        "Roth IRAs are only available through corporate employers",
        "There are no differences between these retirement accounts",
      ],
      correctIndex: 0,
      explanation:
          "Roth IRAs use after-tax dollars today, so your investments grow tax-free and withdrawals in retirement are tax-free.",
    ),
    FinanceQuestion(
      question: "What is an employer 401(k) match?",
      options: [
        "A mandatory tax paid to the federal government",
        "Extra funds added by your employer to your retirement account up to a certain limit",
        "A government program for low-income workers",
        "A loan taken out against your future retirement balance",
      ],
      correctIndex: 1,
      explanation:
          "An employer match is essentially free compensation—failing to contribute enough to grab the full match leaves money on the table.",
    ),
    FinanceQuestion(
      question:
          "What standard penalty usually applies to early withdrawals from retirement accounts before age 59½?",
      options: [
        "Forfeiture of all invested principal",
        "A 50-point drop in credit score",
        "A 10% early withdrawal penalty plus income tax",
        "Mandatory community service",
      ],
      correctIndex: 2,
      explanation:
          "Cashing out retirement accounts early incurs a 10% federal penalty plus standard income taxes on pre-tax balances.",
    ),
    FinanceQuestion(
      question: "What is vesting in an employer retirement contribution plan?",
      options: [
        "The process of selecting mutual funds inside your account",
        "The time required to gain full ownership of employer-contributed matching funds",
        "The age at which you must legally retire",
        "A legal exemption from state income taxes",
      ],
      correctIndex: 1,
      explanation:
          "Vesting determines how much of your employer's matched contributions you get to keep if you leave the company.",
    ),
    FinanceQuestion(
      question: "What does progressive income taxation mean in practice?",
      options: [
        "Everyone pays the exact same flat tax percentage regardless of income",
        "Tax rates rise step-by-step as taxable income moves into higher brackets",
        "Taxes are paid continuously every week through bank transfers",
        "High earners pay zero income taxes",
      ],
      correctIndex: 1,
      explanation:
          "Progressive tax systems charge higher tax rates on higher portions of income across escalating tax brackets.",
    ),
    FinanceQuestion(
      question: "What is a standard tax deduction?",
      options: [
        "A fixed amount that reduces the portion of your total income that gets taxed",
        "A cash payment sent directly from the IRS to every citizen annually",
        "The total amount withheld from a monthly paycheck",
        "A tax penalty charged on unpaid credit card debts",
      ],
      correctIndex: 0,
      explanation:
          "The standard deduction reduces your taxable income, lowering the overall tax amount you owe.",
    ),
    FinanceQuestion(
      question:
          "What is the difference between a tax deduction and a tax credit?",
      options: [
        "Tax deductions directly lower taxes owed dollar-for-dollar; Tax credits lower taxable income",
        "Deductions apply only to businesses; Credits apply only to retirees",
        "Deductions lower taxable income; Credits directly cut your total tax bill dollar-for-dollar",
        "They are two terms for the exact same tax benefit",
      ],
      correctIndex: 2,
      explanation:
          "Credits directly reduce your total tax bill dollar-for-dollar, making them generally more valuable than deductions.",
    ),
    FinanceQuestion(
      question: "What is a Health Savings Account (HSA)?",
      options: [
        "A high-interest account used to buy health insurance policies",
        "A tax-advantaged account meant for eligible medical expenses",
        "A government emergency grant given during illness",
        "A credit card issued by hospitals",
      ],
      correctIndex: 1,
      explanation:
          "HSAs offer a triple tax advantage: pre-tax contributions, tax-free investment growth, and tax-free withdrawals for medical costs.",
    ),
    FinanceQuestion(
      question: "What is a Required Minimum Distribution (RMD)?",
      options: [
        "The minimum amount you must contribute to a 401(k) each year",
        "The minimum check required to open an IRA account",
        "The base Social Security payment given to retirees",
        "The annual minimum withdrawal required from tax-deferred accounts at a certain age",
      ],
      correctIndex: 3,
      explanation:
          "The IRS requires retirees to start withdrawing minimum amounts from tax-deferred accounts so those funds can finally be taxed.",
    ),
    FinanceQuestion(
      question: "What is the primary function of Social Security in the US?",
      options: [
        "To fund public university education expenses",
        "A government program offering income to retirees, disabled individuals, and survivors",
        "A private investment bank managed by Congress",
        "A mandatory health insurance company for young workers",
      ],
      correctIndex: 1,
      explanation:
          "Social Security provides safety-net income for retirees, disabled individuals, and surviving dependents.",
    ),
    FinanceQuestion(
      question: "What are FICA payroll deductions on your paystub?",
      options: [
        "Private health insurance premiums",
        "Mandatory payroll taxes used to support Social Security and Medicare",
        "Contributions to state college savings plans",
        "Union dues and administrative costs",
      ],
      correctIndex: 1,
      explanation:
          "FICA taxes are automatically deducted from paychecks to fund Social Security and Medicare systems.",
    ),
    FinanceQuestion(
      question: "What is a capital gains tax?",
      options: [
        "A tax charged on physical inventory stored in retail stores",
        "A tax paid on the profit earned from selling an investment or property",
        "A tax assessed on personal checking account deposits",
        "A fee paid when opening a new brokerage account",
      ],
      correctIndex: 1,
      explanation:
          "Capital gains tax applies when you sell an asset for a higher price than you paid to purchase it.",
    ),
    FinanceQuestion(
      question:
          "What distinguishes short-term capital gains from long-term capital gains for taxes?",
      options: [
        "Long-term applies to assets sold within 30 days and is completely tax-exempt",
        "Short-term capital gains are taxed at 0% across all income levels",
        "Short-term gains (held 1 year or less) face higher ordinary income tax rates",
        "There is no difference in tax rates",
      ],
      correctIndex: 2,
      explanation:
          "Holding assets for over a year qualifies them for lower long-term capital gains tax rates compared to short-term rates.",
    ),
    FinanceQuestion(
      question: "What is a 529 College Savings Plan?",
      options: [
        "A state-sponsored account designed to save for future education costs with tax advantages",
        "A loan program offering guaranteed 1% interest rates to high school students",
        "A retirement plan exclusively for public school teachers",
        "A tax credit given to families with more than five children",
      ],
      correctIndex: 0,
      explanation:
          "529 plans allow investments to grow tax-free when used for qualified education expenses like tuition and books.",
    ),
    FinanceQuestion(
      question: "What does tax-loss harvesting involve?",
      options: [
        "Filing income tax returns late to delay payment",
        "Selling losing investments to lower taxes on capital gains from profitable ones",
        "Hiding investment gains in offshore bank accounts",
        "Claiming fake business expenses on personal taxes",
      ],
      correctIndex: 1,
      explanation:
          "Tax-loss harvesting balances out taxable capital gains by strategically realizing losses on underperforming assets.",
    ),
    FinanceQuestion(
      question: "What is a pension plan?",
      options: [
        "An individual savings account opened at a retail bank",
        "An employer plan providing guaranteed lifetime retirement payments based on tenure",
        "A short-term loan used to buy property",
        "A stock option given to entry-level workers",
      ],
      correctIndex: 1,
      explanation:
          "Pensions are defined-benefit plans where employers guarantee retirement payouts based on salary and service length.",
    ),
    FinanceQuestion(
      question: "What is marginal tax rate?",
      options: [
        "The overall average percentage of total income paid in taxes",
        "The tax percentage applied to the highest tier of your earnings",
        "The tax rate paid on property taxes",
        "The flat tax rate applied to food purchases",
      ],
      correctIndex: 1,
      explanation:
          "Your marginal tax rate is the highest bracket tier that applies to your top slice of earned income.",
    ),
    FinanceQuestion(
      question: "What is effective tax rate?",
      options: [
        "The highest tax bracket rate you reach",
        "The actual average percentage of your overall income paid in taxes",
        "The sales tax percentage in your home city",
        "The penalty rate charged on late tax returns",
      ],
      correctIndex: 1,
      explanation:
          "Effective tax rate is calculated by dividing your total calculated tax paid by your overall gross income.",
    ),
    FinanceQuestion(
      question: "Why should young adults start saving for retirement early?",
      options: [
        "To get an immediate exemption from paying all federal taxes",
        "Because credit card companies require retirement accounts to open cards",
        "Because bank accounts expire if not tied to a 401(k)",
        "To maximize compound interest over time",
      ],
      correctIndex: 3,
      explanation:
          "Starting early gives compounding more time to work—a head start of 10 years can double your ultimate retirement nest egg.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadbrawlTreeSprite();
    _loadbrawlRockSprite();
    _loadbrawlDollarSprite();
    _loadbrawlEnemyOneSprite();
    _loadbrawlEnemyTwoSprite();
    _loadbrawlBossSprite();
    _loadbrawlChestSprite();

    const Offset playerStartPos = Offset(800, 800);
    const double minTreeRockDistance =
        55.0; // _treeRadius (35) + _rockRadius (20)
    const double minRockRockDistance = 40.0; // _rockRadius (20) * 2

    // Generate Tree Positions
    for (int i = 0; i < 20; i++) {
      Offset pos = Offset.zero;
      bool isValidPosition = false;
      int attempts = 0;

      // Limits at 100 attempts to prevent an infinite loop
      while (!isValidPosition && attempts < 100) {
        attempts++;
        pos = Offset(
          _rand.nextDouble() * (_mapWidth - 200) + 100,
          _rand.nextDouble() * (_mapHeight - 200) + 100,
        );

        // Ensure distance from player safe zone
        if ((pos - playerStartPos).distance > 150) {
          isValidPosition = true;
        }
      }

      if (isValidPosition) {
        _treePositions.add(pos);
      }
    }

    // Generate Rock Positions (checking against player, trees, and existing rocks)
    for (int i = 0; i < 20; i++) {
      Offset pos = Offset.zero;
      bool isValidPosition = false;
      int attempts = 0;

      while (!isValidPosition && attempts < 100) {
        attempts++;
        pos = Offset(
          _rand.nextDouble() * (_mapWidth - 200) + 100,
          _rand.nextDouble() * (_mapHeight - 200) + 100,
        );

        // Check safe distance from player starting position
        if ((pos - playerStartPos).distance <= 150) continue;

        // Check safe distance from all generated trees
        bool overlapsTree = _treePositions.any(
          (tree) => (pos - tree).distance < minTreeRockDistance,
        );
        if (overlapsTree) continue;

        // Check safe distance from already placed rocks
        bool overlapsRock = _rockPositions.any(
          (rock) => (pos - rock).distance < minRockRockDistance,
        );
        if (overlapsRock) continue;

        isValidPosition = true;
      }

      if (isValidPosition) {
        _rockPositions.add(pos);
      }
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
    if (_isQuizOpen ||
        _isUpgradeChoiceOpen ||
        _isGameOver ||
        _isSavingAndExiting) {
      return;
    }

    final double dt = (elapsed.inMicroseconds / 1000000.0) - _totalElapsedTime;
    _totalElapsedTime = elapsed.inMicroseconds / 1000000.0;

    if (dt <= 0 || dt > 0.1) return;

    setState(() {
      // 1. Keyboard Movement Vectors
      double dx = 0.0;
      double dy = 0.0;
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyW)) {
        dy -= 1.0;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyS)) {
        dy += 1.0;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
        dx -= 1.0;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
        dx += 1.0;
      }
      dx += _touchMoveVector.dx;
      dy += _touchMoveVector.dy;

      if (dx != 0 || dy != 0) {
        double len = sqrt(dx * dx + dy * dy);
        Offset dynamicStep = Offset(dx / len, dy / len) * _playerSpeed * dt;

        Offset targetX = Offset(
          (_playerPos.dx + dynamicStep.dx).clamp(
            _playerRadius,
            _mapWidth - _playerRadius,
          ),
          _playerPos.dy,
        );
        if (!_isCollidingWithObstacles(targetX, _playerRadius)) {
          _playerPos = targetX;
        }

        Offset targetY = Offset(
          _playerPos.dx,
          (_playerPos.dy + dynamicStep.dy).clamp(
            _playerRadius,
            _mapHeight - _playerRadius,
          ),
        );
        if (!_isCollidingWithObstacles(targetY, _playerRadius)) {
          _playerPos = targetY;
        }
      }

      // 1b. Handle Treasure Chest Collection
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
          Offset shieldPos =
              _playerPos +
              Offset(cos(angleOffset), sin(angleOffset)) * shieldRadius;

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

      // 3a. Automatic Player Coin Firing
      _lastAttackTime += dt;
      double currentAttackCooldown = 0.55 / _attackSpeedMultiplier;
      if (_lastAttackTime >= currentAttackCooldown && _liabilities.isNotEmpty) {
        _lastAttackTime = 0;
        _fireCoins();
      }

      // The nova runs on its own clock rather than off the aimed shot, so it
      // keeps covering the player's back while they are running away from a
      // wave rather than only when they are shooting into it.
      if (_novaCoins > 0) {
        _novaTimer += dt;
        if (_novaTimer >= _novaInterval) {
          _novaTimer = 0;
          _fireNova();
        }
      }

      // 3b. Automatic Boss Projectile Firing
      if (_bossActive) {
        _lastBossAttackTime += dt;
        double bossAttackCooldown = max(0.8, 1.8 - ((_wave ~/ 5) * 0.15));

        if (_lastBossAttackTime >= bossAttackCooldown) {
          _lastBossAttackTime = 0.0;

          final boss = _liabilities.firstWhere(
            (mob) => mob.isBoss,
            orElse: () => _liabilities.first,
          );
          if (boss.isBoss) {
            Offset direction = _playerPos - boss.pos;
            double dist = direction.distance;

            if (dist > 0) {
              double projectileSpeed = 260.0 + ((_wave ~/ 5) * 20.0);
              Offset normalizedVelocity = (direction / dist) * projectileSpeed;
              double bossDamage = 400.0 + (_wave * 120.0);

              _coins.add(
                _CoinProjectile(
                  pos: boss.pos,
                  velocity: normalizedVelocity,
                  damage: bossDamage,
                  isEnemyProjectile: true,
                  radius: 18.0,
                ),
              );
            }
          }
        }
      }

      // 4. Spawning Debts / Boss Market Crises
      if (_wave % 5 == 0) {
        // Boss Wave: Wait until all standard liabilities are cleared before spawning the boss
        if (!_bossActive && _liabilities.isEmpty) {
          _spawnMarketCrashBoss();
        }
      } else {
        _bossActive = false;

        // Calculate how many enemies have been created this wave
        int totalEnemiesThisWave = _debtsCleared + _liabilities.length;

        // Stop spawning if we reached the required count for this wave
        if (totalEnemiesThisWave < _debtsNeededForLevelUp) {
          _lastSpawnTime += dt;
          double spawnInterval = max(0.2, 1.5 - (_wave * 0.12));
          if (_lastSpawnTime >= spawnInterval) {
            _lastSpawnTime = 0;
            _spawnLiability();
          }
        }
      }

      // 5. Projectiles Movement
      for (int i = _coins.length - 1; i >= 0; i--) {
        final coin = _coins[i];
        coin.pos += coin.velocity * dt;

        if (_isCollidingWithObstacles(coin.pos, coin.radius)) {
          _coins.removeAt(i);
          continue;
        }

        if (coin.pos.dx < 0 ||
            coin.pos.dx > _mapWidth ||
            coin.pos.dy < 0 ||
            coin.pos.dy > _mapHeight) {
          _coins.removeAt(i);
        }
      }

      // 6. Liability Movement & Continuous Tangent Sliding
      for (int i = _liabilities.length - 1; i >= 0; i--) {
        final mob = _liabilities[i];
        Offset moveDir = _playerPos - mob.pos;
        double dist = moveDir.distance;

        if (dist > 2) {
          moveDir = moveDir / dist; // Normalize direction vector toward player

          // Check collisions against Trees
          for (final treePos in _treePositions) {
            final offsetToMob = mob.pos - treePos;
            final distToTree = offsetToMob.distance;
            final minAllowedDist = (_treeRadius * 0.75) + mob.radius;

            if (distToTree < minAllowedDist && distToTree > 0) {
              // 1. Push mob out so it sits cleanly on the edge
              final collisionNormal = offsetToMob / distToTree;
              mob.pos = treePos + (collisionNormal * minAllowedDist);

              // 2. Calculate tangent vector along circle curve
              final tangent = Offset(-collisionNormal.dy, collisionNormal.dx);
              final dot = (moveDir.dx * tangent.dx) + (moveDir.dy * tangent.dy);
              final slideDir = dot >= 0 ? tangent : tangent * -1;

              // 3. Blend 80% slide along edge + 20% gentle push outward
              moveDir = (slideDir * 0.8) + (collisionNormal * 0.2);
              if (moveDir.distance > 0) {
                moveDir = moveDir / moveDir.distance;
              }
            }
          }

          // Check collisions against Rocks
          for (final rockPos in _rockPositions) {
            final offsetToMob = mob.pos - rockPos;
            final distToRock = offsetToMob.distance;
            final minAllowedDist = (_rockRadius * 0.75) + mob.radius;

            if (distToRock < minAllowedDist && distToRock > 0) {
              // 1. Push mob out so it sits cleanly on the edge
              final collisionNormal = offsetToMob / distToRock;
              mob.pos = rockPos + (collisionNormal * minAllowedDist);

              // 2. Calculate tangent vector along circle curve
              final tangent = Offset(-collisionNormal.dy, collisionNormal.dx);
              final dot = (moveDir.dx * tangent.dx) + (moveDir.dy * tangent.dy);
              final slideDir = dot >= 0 ? tangent : tangent * -1;

              // 3. Blend 80% slide along edge + 20% gentle push outward
              moveDir = (slideDir * 0.8) + (collisionNormal * 0.2);
              if (moveDir.distance > 0) {
                moveDir = moveDir / moveDir.distance;
              }
            }
          }

          // Apply the final smooth movement step
          mob.pos += moveDir * mob.speed * dt;
        }

        // Drains Bank Balance when touching player directly
        if (dist < (_playerRadius + mob.radius)) {
          int drain = (mob.drainRate * dt).ceil();
          _bankBalance -= drain;
          if (_bankBalance <= 0) {
            _bankBalance = 0;
            _endGame();
          }
          double mobDrain = ((35.0 * 2) * dt);

          mob.principalRemaining -= mobDrain;
          _spawnExplosion(mob.pos, mob.color);
          if (mob.principalRemaining <= 0) {
            _onLiabilityCleared(i, mob);
          }
        }
      }

      // 7. Projectile Collisions
      for (int cIdx = _coins.length - 1; cIdx >= 0; cIdx--) {
        final coin = _coins[cIdx];
        bool coinDestroyed = false;

        if (coin.isEnemyProjectile) {
          // Boss Projectile hits Player
          double distToPlayer = (coin.pos - _playerPos).distance;
          if (distToPlayer < (_playerRadius + coin.radius)) {
            coinDestroyed = true;
            _bankBalance -= coin.damage.toInt();
            _spawnExplosion(_playerPos, const Color(0xFFFF2F55));

            if (_bankBalance <= 0) {
              _bankBalance = 0;
              _endGame();
            }
          }
        } else {
          // Player Coin hits Liabilities
          for (int mIdx = _liabilities.length - 1; mIdx >= 0; mIdx--) {
            final mob = _liabilities[mIdx];
            double dist = (coin.pos - mob.pos).distance;

            if (dist < (mob.radius + coin.radius)) {
              // A piercing coin must not tick the same debt every frame while
              // it travels through it, so each coin remembers what it has
              // already hit.
              if (coin.hitIds.contains(identityHashCode(mob))) continue;
              coin.hitIds.add(identityHashCode(mob));

              mob.principalRemaining -= coin.damage;
              _spawnExplosion(mob.pos, mob.color);
              final impact = mob.pos;

              if (mob.principalRemaining <= 0) {
                _onLiabilityCleared(mIdx, mob);
              }
              // Splash after the direct hit, so a coin that kills its target
              // still clears the cluster around it.
              _applySplash(impact, coin.damage * 0.55);

              if (coin.pierce > 0) {
                coin.pierce--;
              } else {
                coinDestroyed = true;
              }
              break;
            }
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

  /// The most recent archetype spawned, so the wave-end card can say what it
  /// was. Shown after the fight rather than during it: a sentence about
  /// payday loans lands the moment one has just drained your balance, and is
  /// noise while it is doing it.
  BrawlEnemy? _lastEnemySeen;

  void _spawnLiability() {
    if (!mounted) return;

    double angle = _rand.nextDouble() * pi * 2;
    double spawnDist = 520.0;
    double x = (_playerPos.dx + cos(angle) * spawnDist).clamp(
      20.0,
      _mapWidth - 20.0,
    );
    double y = (_playerPos.dy + sin(angle) * spawnDist).clamp(
      20.0,
      _mapHeight - 20.0,
    );

    // Incremental Health and Damage scaling per wave
    double scaleFactor = pow(1.12, _wave - 1).toDouble();

    // The roster used to be four names sharing one stat block, plus a single
    // real variant at wave 3. Four labels on one enemy teaches that a payday
    // loan and an auto loan are the same thing, which is both false and the
    // opposite of the point. See `brawl_enemies.dart`: each archetype's
    // *behaviour* is the lesson.
    final archetype = pickEnemy(_wave, _rand.nextDouble());
    _lastEnemySeen = archetype;

    final baseHp = (40.0 + (_wave * 10)) * scaleFactor;
    final baseDrain = (450.0 + (_wave * 50.0)) * scaleFactor;

    // Swarms share one spawn point so they arrive together and read as a
    // group -- subscription creep is only a lesson if you see five of them at
    // once.
    for (var i = 0; i < archetype.swarmCount; i++) {
      final spread = archetype.swarmCount == 1 ? 0.0 : (i - 2) * 34.0;
      final hp = baseHp * archetype.hpScale;

      _liabilities.add(
        _FinancialLiability(
          name: archetype.name,
          pos: Offset(
            (x + spread).clamp(20.0, _mapWidth - 20.0),
            (y + spread * 0.5).clamp(20.0, _mapHeight - 20.0),
          ),
          principalRemaining: hp,
          maxPrincipal: hp,
          speed: (85.0 + _rand.nextInt(30)) * archetype.speedScale,
          radius: archetype.radius,
          color: archetype.color,
          drainRate: baseDrain * archetype.drainScale,
          rewardGold: archetype.goldReward,
          isEnemyTwo: archetype.isElite,
        ),
      );
    }
  }

  void _spawnMarketCrashBoss() {
    _bossActive = true;
    double angle = _rand.nextDouble() * pi * 2;
    double x = (_playerPos.dx + cos(angle) * 400.0).clamp(
      60.0,
      _mapWidth - 60.0,
    );
    double y = (_playerPos.dy + sin(angle) * 400.0).clamp(
      60.0,
      _mapHeight - 60.0,
    );

    List<String> bossTitles = [
      "MARKET CRASH",
      "HYPERINFLATION",
      "LIQUIDITY CRISIS",
      "RECESSION SPIRAL",
    ];
    String title = bossTitles[(_wave ~/ 5 - 1) % bossTitles.length];

    double bossMultiplier = pow(1.45, (_wave ~/ 5) - 1).toDouble();
    double hp = (500.0 + (_wave * 120.0)) * bossMultiplier;

    _liabilities.add(
      _FinancialLiability(
        name: title,
        pos: Offset(x, y),
        principalRemaining: hp,
        maxPrincipal: hp,
        speed: 120.0 + ((_wave ~/ 5) * 20.0),
        radius: 100.0,
        color: const Color(0xFFFF2F55),
        drainRate: (750.0 + (_wave * 80.0)) * bossMultiplier,
        rewardGold: 150,
        isBoss: true,
      ),
    );

    GameToast.show(
      context,
      title: "SYSTEMIC RISK DETECTED",
      message:
          "$title event! Pay off liability reserves before balance drains!",
      icon: Icons.warning_amber_rounded,
      accent: const Color(0xFFFF2F55),
    );
  }

  void _fireCoins() {
    var sortedLiabilities = List<_FinancialLiability>.from(_liabilities);
    sortedLiabilities.sort(
      (a, b) => (a.pos - _playerPos).distance.compareTo(
        (b.pos - _playerPos).distance,
      ),
    );

    int shots = min(_coinStreamCount, sortedLiabilities.length);
    for (int i = 0; i < shots; i++) {
      final target = sortedLiabilities[i];
      Offset direction = target.pos - _playerPos;
      double dist = direction.distance;
      if (dist == 0) continue;
      final aim = direction / dist;

      // Shotgun spread: the aimed coin plus a symmetric fan either side.
      // Spread is drawn around the *aim line* rather than around the player,
      // so extra pellets still travel toward the threat instead of spraying
      // into empty grass.
      final pellets = 1 + _spreadShots;
      const spreadArc = 0.42; // radians between outermost pellets
      for (int p = 0; p < pellets; p++) {
        final t = pellets == 1 ? 0.0 : (p / (pellets - 1)) - 0.5;
        final angle = atan2(aim.dy, aim.dx) + t * spreadArc;
        _coins.add(
          _CoinProjectile(
            pos: _playerPos,
            velocity: Offset(cos(angle), sin(angle)) * _coinSpeed,
            damage: _coinDamage,
            radius: 7.0,
            pierce: _pierceCount,
          ),
        );
      }
    }
  }

  /// A ring of coins in every direction.
  ///
  /// Deliberately on its own timer rather than tied to the aimed shot: its
  /// job is to cover the player's back while they are running, which is the
  /// thing that stops a dense wave being a death sentence.
  void _fireNova() {
    if (_novaCoins <= 0) return;
    for (int i = 0; i < _novaCoins; i++) {
      final angle = (i / _novaCoins) * pi * 2;
      _coins.add(
        _CoinProjectile(
          pos: _playerPos,
          velocity: Offset(cos(angle), sin(angle)) * (_coinSpeed * 0.8),
          damage: _coinDamage * 0.7,
          radius: 6.0,
          pierce: _pierceCount,
        ),
      );
    }
  }

  /// Damages everything within [_splashRadius] of a landed coin.
  ///
  /// Returns nothing: cleared debts are handled inline so the caller does not
  /// have to re-scan the list it is already iterating backwards.
  void _applySplash(Offset centre, double damage) {
    if (_splashRadius <= 0) return;
    _spawnExplosion(centre, const Color(0xFFFFD45C));
    for (int i = _liabilities.length - 1; i >= 0; i--) {
      final mob = _liabilities[i];
      if ((mob.pos - centre).distance > _splashRadius) continue;
      mob.principalRemaining -= damage;
      if (mob.principalRemaining <= 0) {
        _onLiabilityCleared(i, mob);
      }
    }
  }

  void _spawnExplosion(Offset center, Color color) {
    for (int i = 0; i < 6; i++) {
      double angle = _rand.nextDouble() * pi * 2;
      double pSpeed = 60.0 + _rand.nextDouble() * 50;
      _particles.add(
        _Particle(
          pos: center,
          velocity: Offset(cos(angle), sin(angle)) * pSpeed,
          color: color,
          life: 0.22,
        ),
      );
    }
  }

  void _triggerQuizGate() {
    // The 100-question bank plus the two categories in
    // `brawl_questions_extra.dart` — earning/work and scams/fees/fine print,
    // the two areas an under-21 player actually meets first and the two the
    // original bank was thinnest on.
    //
    // **Filtered by age, which it was not.** The Academy was routed and this
    // was not, so a player who set their age to "8 or under" was asked "What
    // is a CD Ladder strategy?" — correct answer: "staggering multiple CD
    // maturity dates to keep liquidity while earning higher rates". Every
    // test passed, because nothing tested the game that kept its own bank.
    final band = context.read<UserStatsController>().stats.ageBand;
    final all = <FinanceQuestion>[..._questionBank, ..._extraBrawlQuestions];

    var pooledQuestions = all.where((q) {
      if (readingGrade(q.question) > band.maxReadingGrade) return false;
      // A topic check as well as a grade. "What is a CD Ladder?" is four
      // words and scores as easy prose; it is still meaningless to an
      // eight-year-old, and the grade alone cannot see that.
      if (band.blocksAdultTopics && mentionsAdultTopic(q.question)) {
        return false;
      }
      return true;
    }).toList();

    // Never leave the player staring at a checkpoint with nothing in it. A
    // question slightly too hard beats a gate that cannot be passed.
    if (pooledQuestions.length < 3) pooledQuestions = all;

    pooledQuestions = pooledQuestions..shuffle(_rand);
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
      if (currentQuestion.shuffledOptions[_selectedAnswerIndex!] ==
          currentQuestion.correctOptionText) {
        _quizCorrectCount++;
      }
    });
  }

  void _nextQuizQuestion() {
    setState(() {
      final total = _activeQuizQuestions.length;
      if (_quizQuestionIndex < total - 1) {
        _quizQuestionIndex++;
        _selectedAnswerIndex = null;
        _isAnswerSubmitted = false;
        return;
      }

      _isQuizOpen = false;

      // A perfect round lets you pick an upgrade. Getting most of them right
      // still earns one at random — going from "nearly perfect" to nothing at
      // all made the gate feel punishing rather than motivating.
      if (_quizCorrectCount == total) {
        _isUpgradeChoiceOpen = true;
        return;
      }

      _debtsCleared = 0;
      _wave++;
      _bossActive = false;
      _debtsNeededForLevelUp = 6 + (_wave * 3);

      final earnedConsolation = total > 1 && _quizCorrectCount >= total - 1;
      if (earnedConsolation) {
        final bonus = _getUpgradeOptions().first;
        bonus.action();
        GameToast.show(
          context,
          title: "Quiz Score: $_quizCorrectCount/$total",
          message: "${bonus.name} granted. Answer all $total for your pick!",
          icon: Icons.school_rounded,
          accent: const Color(0xFF85EFAC),
        );
        return;
      }

      GameToast.show(
        context,
        title: "Quiz Score: $_quizCorrectCount/$total",
        message:
            "Score $total/$total for income upgrades! Market grid reinforced.",
        icon: Icons.school_rounded,
        accent: const Color(0xFFE1BB72),
      );
    });
  }

  /// The levelled upgrade tracks, in the order they were designed rather than
  /// the order they appear — [_getUpgradeOptions] shuffles.
  ///
  /// Each entry says what it does *at the level you are about to take*, so a
  /// player can compare three offers on their actual effect instead of on a
  /// slogan. Caps exist so a track ends: an upgrade that can be taken forever
  /// makes every other offer a mistake by wave fifteen.
  List<BrawlUpgrade> _upgradeTracks() {
    BrawlUpgrade track({
      required String id,
      required String name,
      required IconData icon,
      required int maxLevel,
      required String Function(int next) describe,
      required void Function() apply,
    }) {
      final level = _levelOf(id);
      return BrawlUpgrade(
        name: name,
        description: describe(level + 1),
        icon: icon,
        level: level,
        maxLevel: maxLevel,
        action: () {
          _upgradeLevels[id] = level + 1;
          apply();
        },
      );
    }

    return <BrawlUpgrade>[
      // ---- Fire rate ------------------------------------------------
      // Named directly in the brief, and the most-wanted upgrade in any game
      // of this shape: it multiplies everything else you have taken.
      track(
        id: 'fire_rate',
        name: 'Rapid Payments',
        icon: Icons.speed_rounded,
        maxLevel: 8,
        describe: (next) =>
            'Pay out 18% faster · ${(pow(1.18, next) * 100 - 100).round()}% '
            'total fire rate',
        apply: () => _attackSpeedMultiplier *= 1.18,
      ),
      // ---- Pierce ---------------------------------------------------
      track(
        id: 'pierce',
        name: 'Debt Consolidation',
        icon: Icons.compress_rounded,
        maxLevel: 6,
        describe: (next) => next == 1
            ? 'Payments punch through one extra debt'
            : 'Punch through $next extra debts per coin',
        apply: () => _pierceCount += 1,
      ),
      // ---- Spread ---------------------------------------------------
      track(
        id: 'spread',
        name: 'Diversified Portfolio',
        icon: Icons.call_split_rounded,
        maxLevel: 5,
        describe: (next) => next == 1
            ? 'Fan every payment into a 3-coin spread'
            : '${1 + next * 2} coins per shot',
        apply: () => _spreadShots += 2,
      ),
      // ---- Splash ---------------------------------------------------
      track(
        id: 'splash',
        name: 'Market Contagion',
        icon: Icons.blur_on_rounded,
        maxLevel: 6,
        describe: (next) => next == 1
            ? 'Payments splash, damaging nearby debts'
            : 'Splash radius ${62 + (next - 1) * 25}',
        apply: () => _splashRadius += _splashRadius == 0 ? 62 : 25,
      ),
      // ---- Orbiting ring --------------------------------------------
      track(
        id: 'nova',
        name: 'Dividend Burst',
        icon: Icons.brightness_7_rounded,
        maxLevel: 5,
        describe: (next) => next == 1
            ? 'Release a ring of coins every few seconds'
            : 'Denser dividend ring (${8 + (next - 1) * 4} coins)',
        apply: () => _novaCoins += _novaCoins == 0 ? 8 : 4,
      ),
      // ---- Streams --------------------------------------------------
      track(
        id: 'streams',
        name: 'Multiple Income Streams',
        icon: Icons.payments_rounded,
        maxLevel: 5,
        describe: (next) => '${next + 1} simultaneous coin streams',
        apply: () => _coinStreamCount++,
      ),
      // ---- Damage ---------------------------------------------------
      track(
        id: 'damage',
        name: 'Job Promotion',
        icon: Icons.trending_up_rounded,
        maxLevel: 10,
        describe: (next) => '+30 payment damage · ${30 * next} total',
        apply: () => _coinDamage += 30,
      ),
      // ---- Shield ---------------------------------------------------
      track(
        id: 'shield',
        name: 'Emergency Fund',
        icon: Icons.shield_rounded,
        maxLevel: 5,
        describe: (next) => next == 1
            ? 'A revolving cash shield damages debts that touch you'
            : 'Wider shield, harder contact (Level $next)',
        apply: () => _emergencyFundLevel++,
      ),
      // ---- Movement -------------------------------------------------
      track(
        id: 'speed',
        name: 'Liquid Assets',
        icon: Icons.directions_run_rounded,
        maxLevel: 5,
        describe: (next) => '+40 movement speed · ${40 * next} total',
        apply: () => _playerSpeed += 40.0,
      ),
    ];
  }

  /// The upgrade pool, for tests.
  ///
  /// The levels live in this `State` and the level-up sheet only appears
  /// several waves into a run, so the alternative to a seam is a test that
  /// plays the game for a minute to check a list — slow, flaky, and testing
  /// the wave pacing rather than the upgrade rules.
  @visibleForTesting
  List<BrawlUpgrade> getUpgradeOptionsForTest() => _getUpgradeOptions();

  /// Three offers, drawn from tracks that are not yet maxed.
  ///
  /// Maxed tracks leaving the pool is the whole design: the choices narrow as
  /// the run goes on, so the last few are between things you actively want
  /// rather than between eight sentences you have already read.
  ///
  /// The cash top-up is kept separate and unlevelled — it is a consolation
  /// prize, and it is appended only when fewer than three tracks remain so it
  /// can never crowd out a real upgrade.
  List<BrawlUpgrade> _getUpgradeOptions() {
    final available =
        _upgradeTracks().where((u) => u.level < u.maxLevel).toList()
          ..shuffle(_rand);

    if (available.length < 3) {
      available.add(
        BrawlUpgrade(
          name: 'Performance Bonus',
          description: 'Add 10% to your bank balance (max \$10,000)',
          icon: Icons.savings,
          action: () {
            final bonus = (_bankBalance * 0.1).round();
            _bankBalance = (_bankBalance + bonus).clamp(0, 10000);
          },
        ),
      );
    }
    return available;
  }

  void _selectUpgrade(BrawlUpgrade choice) {
    setState(() {
      choice.action();
      _isUpgradeChoiceOpen = false;

      _debtsCleared = 0;
      _wave++;
      _bossActive = false;
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
      'description':
          'Reached Wave $_wave and cleared $_debtsCleared liabilities.',
    };

    StatsActionResult syncResult = await controller.applyChallengePayload(
      payload,
    );

    if (mounted) {
      Navigator.of(context).pop(
        FinanceBrawlCloseResult(
          goldEarned: _goldAccumulated,
          xpEarned: _xpAccumulated,
          syncState: syncResult,
        ),
      );
    }
  }

  void _startTouchMove(DragStartDetails details) {
    _keyboardFocusNode.requestFocus();
    setState(() {
      _touchMoveAnchor = details.localPosition;
      _touchMoveVector = Offset.zero;
      _touchMoveKnob = Offset.zero;
    });
  }

  void _updateTouchMove(DragUpdateDetails details) {
    final anchor = _touchMoveAnchor ?? details.localPosition;
    final delta = details.localPosition - anchor;
    final distance = delta.distance;
    final vector = distance <= 6 ? Offset.zero : delta / distance;
    setState(() {
      _touchMoveVector = vector;
      _touchMoveKnob = vector * min(distance, 38.0);
    });
  }

  void _stopTouchMove([DragEndDetails? _]) {
    if (_touchMoveAnchor == null && _touchMoveVector == Offset.zero) {
      return;
    }
    setState(() {
      _touchMoveAnchor = null;
      _touchMoveVector = Offset.zero;
      _touchMoveKnob = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UserStatsController>();
    final equippedSkinId = controller.stats.equippedSkin;
    _loadProfileImage(controller.stats.profileImageUrl);

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
        backgroundColor: _brawlInk,
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
                Positioned.fill(
                  child: Image.asset(
                    AppAssets.brawlGrasstile,
                    repeat: ImageRepeat.repeat,
                    filterQuality: FilterQuality.none,
                  ),
                ),
                Positioned.fill(
                  child: ColoredBox(color: _brawlInk.withValues(alpha: 0.42)),
                ),
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
                      treeImage: _treeImage,
                      rockImage: _rockImage,
                      dollarImage: _dollarImage,
                      profileImage: _profileImage,
                      enemyOneImage: _enemyOneImage,
                      enemyTwoImage: _enemyTwoImage,
                      bossImage: _bossImage,
                      chestImage: _chestImage,
                    ),
                  ),
                ),

                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: _startTouchMove,
                    onPanUpdate: _updateTouchMove,
                    onPanEnd: _stopTouchMove,
                    onPanCancel: _stopTouchMove,
                  ),
                ),

                if (_touchMoveAnchor != null)
                  Positioned(
                    left: (_touchMoveAnchor!.dx - 54).clamp(
                      12.0,
                      max(12.0, _canvasSize.width - 120),
                    ),
                    top: (_touchMoveAnchor!.dy - 54).clamp(
                      MediaQuery.of(context).padding.top + 72,
                      max(
                        MediaQuery.of(context).padding.top + 72,
                        _canvasSize.height - 126,
                      ),
                    ),
                    child: IgnorePointer(
                      child: _TouchJoystick(knobOffset: _touchMoveKnob),
                    ),
                  ),

                // The wave/net-worth HUD and the gold/exit controls used to
                // be two independently `Positioned` widgets — one centred
                // across almost the full screen width, the other pinned to
                // the right edge with no awareness of the first one's
                // width. On a narrow phone the HUD's right panel extended
                // under the floating gold badge and exit button instead of
                // making room for them, so "Don't Let it Hit Zero!" got
                // clipped behind the coin icon. One Row sharing one width
                // budget — the HUD panels flex, the controls stay
                // fixed-size — so there is exactly one place they can
                // divide the space, not two independently-guessed ones.
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildHud(context)),
                            const SizedBox(width: 10),
                            _buildRightControls(context),
                          ],
                        ),
                      ),
                    ),
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

  Widget _buildHud(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // One measurement for both panels.
        //
        // Each panel used to run its own `LayoutBuilder` and reach its own
        // conclusion. Measuring here instead does two things: the pair can
        // never disagree about their own layout, and — the reason this moved
        // — a `LayoutBuilder` inside a panel makes the panel impossible to
        // put in an `IntrinsicHeight`, which is what equalises their heights.
        //
        // The panels sit side by side with a 10px gap, so each gets a little
        // under half. The thresholds are per-panel, hence the halving.
        final panelWidth = (constraints.maxWidth - 10) / 2;
        return _buildHudRow(panelWidth);
      },
    );
  }

  Widget _buildHudRow(double panelWidth) {
    final tight = panelWidth < 150;
    final veryTight = panelWidth < 112;
    final isCrisis = _wave % 5 == 0;
    final balanceAccent = _bankBalance < 2500 ? _brawlDanger : _brawlMint;

    final wavePanel = _HudStatPanel(
      tight: tight,
      veryTight: veryTight,
      icon: Icons.waves_rounded,
      label: isCrisis ? 'CRISIS' : 'WAVE',
      value: 'WAVE $_wave',
      detail: isCrisis ? 'Neutralize Market Crisis' : 'Debts Paid',
      accent: isCrisis ? _brawlDanger : _brawlMint,
      alignStart: false,
      // The count the player is actually tracking toward their next upgrade.
      progress: HudProgress(
        current: _debtsCleared,
        total: _debtsNeededForLevelUp,
      ),
    );

    final balancePanel = _HudStatPanel(
      tight: tight,
      veryTight: veryTight,
      icon: Icons.account_balance_wallet_rounded,
      label: 'NET WORTH',
      value: '\$$_bankBalance',
      detail: "Don't Let it Hit Zero!",
      accent: balanceAccent,
      alignStart: false,
      // Both panels carry a bar so the two boxes are the same height by
      // construction. Reported as "the header box sizes in finance brawl are
      // all different sizes, making it visually jarring" — the wave panel drew
      // a bar and a caption where this one drew a single line, so two boxes
      // with identical borders sat side by side at different heights, and the
      // difference changed as the layout got tighter.
      //
      // Not a spacer dressed up as content. This panel's flavour line was
      // "Don't Let it Hit Zero!", which is precisely what a bar says better
      // than a sentence — and says at a glance, mid-fight, which is the only
      // time anybody reads it.
      progress: HudProgress(
        current: _bankBalance,
        total: _maxBankBalance,
        label: "Don't hit zero",
      ),
    );

    // Both panels the same height, always.
    //
    // Reported as "the header box sizes in finance brawl are all different
    // sizes, making it visually jarring", and the cause is structural rather
    // than a spacing mistake: the wave panel draws a progress bar plus its
    // caption (~30px) where the net-worth panel draws a single flavour line
    // (~14px). `Expanded` equalises their *widths* and says nothing about
    // height, so two boxes with identical borders sat side by side at
    // visibly different sizes — and the difference moved, because the wave
    // panel loses its bar at narrow widths.
    //
    // `IntrinsicHeight` + `stretch` makes the shorter one adopt the taller
    // one's height. The alternative — padding the shorter panel by a fixed
    // amount to match — only lines up for one font size and one text scale,
    // and silently stops lining up the next time either panel's contents
    // change. This cannot drift, because nothing states the height.
    //
    // Cost is one extra layout pass over two leaf panels. That is cheap
    // enough for a per-frame HUD, and the correctness is worth more than the
    // pass.
    // No IntrinsicHeight, and not for want of trying. `FittedLabel`,
    // `_PixelPanel` and `PixelProgressBar` all use `LayoutBuilder`, and
    // Flutter asserts that a LayoutBuilder cannot report intrinsic
    // dimensions — so wrapping these panels in one throws rather than
    // aligning them. The heights match because both panels now render the
    // same widgets, which needs no measurement at all.
    // Default alignment, deliberately. `stretch` was tried and cannot work
    // here: this row sits inside a top-aligned `Align`, so its height is
    // unbounded, and stretching against an unbounded cross axis asks the
    // children for an infinite height. It is not needed either — with both
    // panels rendering the same widgets there is nothing left to equalise.
    return Row(
      children: [
        Expanded(child: wavePanel),
        const SizedBox(width: 10),
        Expanded(child: balancePanel),
      ],
    );
  }

  Widget _buildRightControls(BuildContext context) {
    final rewardPanel = _PixelPanel(
      accent: _brawlGold,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppAssets.kitIconCoin, width: 20, height: 20),
          const SizedBox(width: 7),
          FittedLabel(
            '$_goldAccumulated',
            style: AppTheme.numeric(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final exitButton = _PixelIconButton(
      icon: Icons.logout_rounded,
      accent: _brawlRed,
      tooltip: 'Pause and quit',
      onPressed: () => _showPauseDialog(context),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [rewardPanel, const SizedBox(width: 10), exitButton],
    );
  }

  void _showPauseDialog(BuildContext context) {
    _ticker.stop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _PixelPanel(
            accent: _brawlMint,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'PAUSE & BANK?',
                  style: GoogleFonts.pixelifySans(
                    color: _brawlMint,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Exit now and store $_goldAccumulated gold safely.',
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    _PixelButton(
                      label: 'RESUME',
                      accent: Colors.white70,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _ticker.start();
                      },
                    ),
                    _PixelButton(
                      label: 'SAVE + QUIT',
                      accent: _brawlRed,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _exitAndSyncData();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizOverlay() {
    final q = _activeQuizQuestions[_quizQuestionIndex];
    return _BrawlOverlayBackdrop(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _PixelPanel(
            accent: _brawlBlue,
            padding: const EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "LITERACY CHECKPOINT (${_quizQuestionIndex + 1}/3)",
                    style: AppTheme.numeric(
                      color: _brawlBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Same fault as the Academy's quiz prompt: a question
                  // whose content is often a number, in a font whose 5 and 8
                  // differ by a few pixel columns. See `AppTheme.numeric`.
                  Text(
                    q.question,
                    style: AppTheme.numeric(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(q.shuffledOptions.length, (idx) {
                    Color optionBorderColor = Colors.white.withValues(
                      alpha: 0.12,
                    );
                    Color optionBgColor = const Color(0xFF0A1612);
                    final optionText = q.shuffledOptions[idx];

                    if (_isAnswerSubmitted) {
                      if (optionText == q.correctOptionText) {
                        optionBorderColor = _brawlMint;
                        optionBgColor = const Color(0xFF143525);
                      } else if (_selectedAnswerIndex == idx) {
                        optionBorderColor = _brawlRed;
                        optionBgColor = const Color(0xFF381B1B);
                      }
                    } else if (_selectedAnswerIndex == idx) {
                      optionBorderColor = _brawlBlue;
                      optionBgColor = const Color(0xFF14222B);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: _isAnswerSubmitted
                            ? null
                            : () => setState(() => _selectedAnswerIndex = idx),
                        child: _PixelPanel(
                          accent: optionBorderColor,
                          background: optionBgColor,
                          padding: const EdgeInsets.all(13),
                          dense: true,
                          child: Text(
                            optionText,
                            style: GoogleFonts.quicksand(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_isAnswerSubmitted) ...[
                    const SizedBox(height: 10),
                    Text(
                      q.explanation,
                      style: GoogleFonts.quicksand(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _PixelButton(
                    accent: _brawlBlue,
                    onPressed: _selectedAnswerIndex == null
                        ? null
                        : (_isAnswerSubmitted
                              ? _nextQuizQuestion
                              : _submitQuizAnswer),
                    label: _isAnswerSubmitted ? "CONTINUE" : "SUBMIT ANSWER",
                  ),
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
    return _BrawlOverlayBackdrop(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "PROFIT CHANNELS UNLOCKED!",
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(
                  color: _brawlGold,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Pick a build path",
                style: GoogleFonts.quicksand(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w800,
                ),
              ),
              // What you just fought, and why it behaved that way.
              //
              // Shown **here** rather than mid-fight on purpose. A sentence
              // about payday loans lands the moment one has finished draining
              // half your balance, and is noise while it is doing it. This is
              // also the only pause in the game, so it is the only place a
              // player will actually read.
              if (_lastEnemySeen != null) ...[
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: _lastEnemySeen!.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _lastEnemySeen!.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _lastEnemySeen!.name.toUpperCase(),
                        style: GoogleFonts.pixelifySans(
                          color: _lastEnemySeen!.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _lastEnemySeen!.lesson,
                        style: AppTheme.numeric(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Three cards side by side needs real width. Below ~520px
              // each card gets barely 150px, which broke words mid-syllable
              // ("Perfor / mance Bonus", "Job Pr / omotio / n") and made the
              // whole choice unreadable. Under that threshold they stack
              // into a single column instead, where each card has the full
              // width and the text simply wraps normally.
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 520;
                  final cards = [
                    for (final up in upgrades)
                      _UpgradeCard(
                        upgrade: up,
                        stacked: stack,
                        onTap: () => _selectUpgrade(up),
                      ),
                  ];

                  if (stack) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            cards[i],
                            if (i != cards.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            Expanded(child: cards[i]),
                            if (i != cards.length - 1)
                              const SizedBox(width: 14),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    final accent = _isSavingAndExiting ? _brawlMint : _brawlRed;
    return _BrawlOverlayBackdrop(
      padding: const EdgeInsets.all(24),
      opacity: 0.9,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: _PixelPanel(
            accent: accent,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isSavingAndExiting ? "SAVING DATA..." : "BANKRUPT!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pixelifySans(
                    color: accent,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isSavingAndExiting
                      ? "Banking your run rewards."
                      : "Your bank balance reached zero.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 22),
                _PixelPanel(
                  accent: _brawlGold,
                  background: _brawlPanelDeep,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  dense: true,
                  child: Text(
                    "GOLD BANKED: +$_goldAccumulated",
                    textAlign: TextAlign.center,
                    style: AppTheme.numeric(
                      color: _brawlGold,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (!_isSavingAndExiting)
                  _PixelButton(
                    accent: _brawlMint,
                    onPressed: _exitAndSyncData,
                    label: "BANK REWARDS & EXIT",
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrawlOverlayBackdrop extends StatelessWidget {
  const _BrawlOverlayBackdrop({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.opacity = 0.85,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.brawlGrasstile,
          repeat: ImageRepeat.repeat,
          filterQuality: FilterQuality.none,
        ),
        ColoredBox(color: Colors.black.withValues(alpha: opacity)),
        Padding(padding: padding, child: child),
      ],
    );
  }
}

class _PixelPanel extends StatelessWidget {
  const _PixelPanel({
    required this.child,
    required this.accent,
    this.background,
    this.padding = const EdgeInsets.all(12),
    this.dense = false,
  });

  final Widget child;
  final Color accent;
  final Color? background;
  final EdgeInsetsGeometry padding;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? _brawlPanel;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg.withValues(alpha: dense ? 0.94 : 0.96),
        borderRadius: BorderRadius.circular(dense ? 6 : 8),
        border: Border.all(color: accent.withValues(alpha: 0.78), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 0,
            spreadRadius: 2,
            offset: const Offset(3, 3),
          ),
          BoxShadow(
            color: _brawlBorder.withValues(alpha: 0.65),
            blurRadius: 0,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _TouchJoystick extends StatelessWidget {
  const _TouchJoystick({required this.knobOffset});

  final Offset knobOffset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _brawlPanelDeep.withValues(alpha: 0.46),
          border: Border.all(
            color: _brawlMint.withValues(alpha: 0.55),
            width: 2,
          ),
        ),
        child: Center(
          child: Transform.translate(
            offset: knobOffset,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brawlMint.withValues(alpha: 0.72),
                border: Border.all(color: Colors.white70, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Something countable a HUD panel can draw as a bar.
///
/// Exists so the panel can tell the difference between a *flavour* line
/// ("Don't Let it Hit Zero!") and a *progress* line ("Debts Paid 3/12").
/// Only the second one is information the player is tracking, and only the
/// second one therefore has to survive a narrow phone.
@immutable
class HudProgress {
  const HudProgress({
    required this.current,
    required this.total,
    this.label,
  });

  final int current;
  final int total;

  /// Shown under the bar instead of `current / total`.
  ///
  /// The net-worth panel already prints the balance as its headline number,
  /// so repeating "8400 / 10000" underneath would be the same figure twice
  /// in one small box. It says what the bar *means* instead.
  final String? label;

  /// Guards a zero total rather than letting it become NaN and blank the bar.
  double get fraction => total <= 0 ? 0 : (current / total).clamp(0.0, 1.0);

  String get caption => label ?? '$current / $total';
}

class _HudStatPanel extends StatelessWidget {
  const _HudStatPanel({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
    required this.tight,
    required this.veryTight,
    this.alignStart = false,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color accent;

  /// Width decisions, made once by the row that owns both panels.
  ///
  /// **Not measured here on purpose.** These used to come from a
  /// `LayoutBuilder` inside this widget, which had two costs. It made the
  /// panel impossible to put inside an `IntrinsicHeight` — Flutter asserts
  /// that a LayoutBuilder cannot report intrinsic dimensions — so the two
  /// panels could never be made the same height. And it let each panel reach
  /// its own conclusion about whether to drop its icon, so in principle the
  /// pair could disagree with each other about their own layout.
  final bool tight;
  final bool veryTight;

  final bool alignStart;

  /// When set, the panel draws a bar instead of the flavour line — and keeps
  /// it at every width. See the comment at the render site.
  final HudProgress? progress;

  @override
  Widget build(BuildContext context) {
    // Two of these panels sit beside a gold chip and an exit button. On a
    // phone that leaves each panel ~119px, and the 32px icon plus padding
    // eats ~65px of it — so the text column had about 54px to render
    // "Debts Paid 4/6" in. Nothing fits there at a readable size, which is
    // why these were the last labels still showing "Debts …" / "Don't …"
    // after the ellipsis sweep: `FittedLabel` correctly refused to shrink
    // that far and fell back to truncating.
    //
    // The fix is the layout, not the text. Below ~150px the panel drops the
    // icon and the flavour line and keeps what the player actually needs
    // mid-fight — the label and the number.
    return _PixelPanel(
      accent: accent,
      background: _brawlPanelDeep,
      padding: EdgeInsets.symmetric(
        horizontal: tight ? 8 : 12,
        vertical: tight ? 7 : 10,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!veryTight) ...[
            _PixelIconBadge(icon: icon, accent: accent, size: tight ? 24 : 32),
            SizedBox(width: tight ? 6 : 9),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: alignStart
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedLabel(
                  label,
                  alignment: alignStart
                      ? Alignment.centerLeft
                      : Alignment.center,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Money in the game's own display face rather than in a
                // text font. `canRender` guards it: a figure that is half
                // art and half fallback text looks worse than one drawn
                // entirely in the text font, so anything with a character
                // the glyph set lacks stays as it was.
                if (MoneyGlyphs.canRender(value))
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: alignStart
                        ? Alignment.centerLeft
                        : Alignment.center,
                    child: MoneyGlyphs(value, height: tight ? 17 : 22),
                  )
                else
                  FittedLabel(
                    value,
                    alignment: alignStart
                        ? Alignment.centerLeft
                        : Alignment.center,
                    style: GoogleFonts.pixelifySans(
                      color: accent,
                      fontSize: tight ? 16 : 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                // Progress survives at every width; flavour does not.
                //
                // This used to drop `detail` entirely below 150px, which
                // meant the panel hid "Debts Paid 3/12" — the number
                // telling the player how far they are from the next
                // upgrade — on exactly the phones where the HUD is
                // tightest. A bar is legible at any width, so nothing has
                // to be dropped to make room, and it answers "how much
                // further" at a glance in a way the sentence never did.
                if (progress != null) ...[
                  SizedBox(height: tight ? 4 : 5),
                  PixelProgressBar(
                    value: progress!.fraction,
                    height: tight ? 12 : 14,
                    fillAsset: accent == _brawlDanger
                        ? AppAssets.kitBarFillRed
                        : AppAssets.kitBarFillGreen,
                  ),
                  const SizedBox(height: 3),
                  FittedLabel(
                    progress!.caption,
                    alignment: alignStart
                        ? Alignment.centerLeft
                        : Alignment.center,
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: tight ? 10 : 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ] else if (!tight)
                  // Panels with nothing to measure keep the old flavour
                  // line, and it is still the first thing to go.
                  FittedLabel(
                    detail,
                    alignment: alignStart
                        ? Alignment.centerLeft
                        : Alignment.center,
                    style: GoogleFonts.quicksand(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One upgrade choice.
///
/// Two layouts on purpose. Side by side (wide screens) it is a centred
/// column — icon over name over description. Stacked (narrow screens) it
/// turns on its side into icon-beside-text, which is what actually makes
/// the copy readable: a full-width row gives the description a sane line
/// length instead of a ~150px column that hyphenates words in half.
class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.upgrade,
    required this.stacked,
    required this.onTap,
  });

  final BrawlUpgrade upgrade;
  final bool stacked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nameText = Text(
      upgrade.name,
      textAlign: stacked ? TextAlign.left : TextAlign.center,
      style: GoogleFonts.pixelifySans(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: stacked ? 15 : 14,
        height: 1.1,
      ),
    );
    final descText = Text(
      upgrade.description,
      textAlign: stacked ? TextAlign.left : TextAlign.center,
      style: GoogleFonts.quicksand(
        color: Colors.white.withValues(alpha: 0.72),
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    );

    // "Lv 2 → 3", or nothing for the one-off cash bonus. Without it a player
    // taking Rapid Payments for the fourth time sees the identical card they
    // saw the first time, and a build stops feeling like it is being built.
    final levelChip = upgrade.isLevelled
        ? Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _brawlGold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _brawlGold.withValues(alpha: 0.42)),
            ),
            child: Text(
              upgrade.levelLabel,
              style: GoogleFonts.pixelifySans(
                color: _brawlGold,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : const SizedBox.shrink();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(stacked ? 12 : 14),
        decoration: BoxDecoration(
          color: _brawlPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _brawlGold.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: stacked
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PixelIconBadge(icon: upgrade.icon, accent: _brawlGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        nameText,
                        const SizedBox(height: 4),
                        descText,
                        Align(
                          alignment: Alignment.centerLeft,
                          child: levelChip,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PixelIconBadge(icon: upgrade.icon, accent: _brawlGold),
                  const SizedBox(height: 12),
                  nameText,
                  const SizedBox(height: 8),
                  Expanded(child: Center(child: descText)),
                  levelChip,
                ],
              ),
      ),
    );
  }
}

class _PixelIconBadge extends StatelessWidget {
  const _PixelIconBadge({
    required this.icon,
    required this.accent,
    this.size = 40,
  });

  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: accent.withValues(alpha: 0.70), width: 2),
      ),
      child: Icon(icon, color: accent, size: size * 0.55),
    );
  }
}

class _PixelIconButton extends StatelessWidget {
  const _PixelIconButton({
    required this.icon,
    required this.accent,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color accent;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: _PixelPanel(
          accent: accent,
          background: _brawlPanelDeep,
          padding: const EdgeInsets.all(11),
          dense: true,
          child: Icon(icon, color: accent, size: 21),
        ),
      ),
    );
  }
}

class _PixelButton extends StatelessWidget {
  const _PixelButton({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final effectiveAccent = enabled
        ? accent
        : Colors.white.withValues(alpha: 0.26);

    return Opacity(
      opacity: enabled ? 1 : 0.52,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: _PixelPanel(
          accent: effectiveAccent,
          background: enabled ? _brawlPanelDeep : const Color(0xFF111A17),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          dense: true,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.pixelifySans(
              color: enabled && accent != Colors.white70
                  ? effectiveAccent
                  : Colors.white.withValues(alpha: 0.78),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
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
    this.isEnemyTwo = true,
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
  bool isEnemyTwo;
}

class _CoinProjectile {
  _CoinProjectile({
    required this.pos,
    required this.velocity,
    required this.damage,
    this.isEnemyProjectile = false,
    this.radius = 7.0,
    this.pierce = 0,
  });

  Offset pos;
  Offset velocity;
  double damage;
  final bool isEnemyProjectile;
  final double radius;

  /// How many more enemies this coin can pass through before it is spent.
  ///
  /// Zero is the old behaviour: hit one thing, disappear. Pierce is what
  /// turns a crowd from a wall into a queue, which is the single biggest
  /// difference between "hard" and "unfair" once waves get dense.
  int pierce;

  /// Enemies already hit, so one coin cannot damage the same debt twice on
  /// consecutive frames while passing through it.
  final Set<int> hitIds = <int>{};
}

class _Particle {
  _Particle({
    required this.pos,
    required this.velocity,
    required this.color,
    required this.life,
  });
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
    this.treeImage,
    this.rockImage,
    this.dollarImage,
    this.profileImage,
    this.enemyOneImage,
    this.enemyTwoImage,
    this.bossImage,
    this.chestImage,
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
  final ui.Image? treeImage;
  final ui.Image? rockImage;
  final ui.Image? dollarImage;

  /// The player's uploaded avatar, or null to fall back to a letter.
  final ui.Image? profileImage;
  final ui.Image? enemyOneImage;
  final ui.Image? enemyTwoImage;
  final ui.Image? bossImage;
  final ui.Image? chestImage;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(camOffset.dx, camOffset.dy);
    // -------------------------------------------------------------------------
    // SMOOTH RETRO STONE BORDER (No Spikes - Clean Rim Only)
    // -------------------------------------------------------------------------
    const double wallThickness = 20.0;
    const double segmentLength = 24.0;

    final baseStonePaint = Paint()
      ..color = const Color(0xFF595858)
      ..style = PaintingStyle.stroke
      ..strokeWidth = wallThickness;

    final highlightPaint = Paint()
      ..color = const Color(0xFF6E7681)
      ..strokeWidth = 1.5;

    final shadowPaint = Paint()
      ..color = const Color(0xFF6E7681)
      ..strokeWidth = 1.5;

    final innerLinePaint = Paint()
      ..color = const Color(0xFF484F58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(
        -wallThickness / 2,
        -wallThickness / 2,
        mapWidth + wallThickness,
        mapHeight + wallThickness,
      ),
      baseStonePaint,
    );

    canvas.drawLine(
      Offset(-wallThickness, -wallThickness),
      Offset(mapWidth + wallThickness, -wallThickness),
      highlightPaint,
    );

    canvas.drawLine(
      Offset(-wallThickness, -wallThickness),
      Offset(-wallThickness, mapHeight + wallThickness),
      highlightPaint,
    );

    canvas.drawLine(
      Offset(-wallThickness, mapHeight + wallThickness),
      Offset(mapWidth + wallThickness, mapHeight + wallThickness),
      shadowPaint,
    );

    canvas.drawLine(
      Offset(mapWidth + wallThickness, -wallThickness),
      Offset(mapWidth + wallThickness, mapHeight + wallThickness),
      shadowPaint,
    );

    for (double x = 0; x < mapWidth; x += segmentLength) {
      // Top Wall Seams
      canvas.drawLine(Offset(x, -wallThickness), Offset(x, 0), highlightPaint);

      canvas.drawLine(
        Offset(x, mapHeight),
        Offset(x, mapHeight + wallThickness),
        shadowPaint,
      );
    }

    for (double y = 0; y < mapHeight; y += segmentLength) {
      // Left Wall Seams
      canvas.drawLine(Offset(-wallThickness, y), Offset(0, y), highlightPaint);
      // Right Wall Seams
      canvas.drawLine(
        Offset(mapWidth, y),
        Offset(mapWidth + wallThickness, y),
        shadowPaint,
      );
    }

    // 4. Crisp Inner Line Framing the Arena Field
    canvas.drawRect(Rect.fromLTWH(0, 0, mapWidth, mapHeight), innerLinePaint);

    for (final rock in rockPositions) {
      if (rockImage != null) {
        final Rect rockRect = Rect.fromCenter(
          center: rock,
          width: rockRadius * 2.4, // Adjust size multiplier as needed
          height: rockRadius * 2.4,
        );
        paintImage(
          canvas: canvas,
          rect: rockRect,
          image: rockImage!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none, // Keeps pixel art crisp!
        );
      } else {
        // Fallback circle while loading
        final rockPaint = Paint()..color = const Color(0xFF5A635E);
        canvas.drawCircle(rock, rockRadius, rockPaint);
      }
    }

    for (final tree in treePositions) {
      if (treeImage != null) {
        final Rect treeRect = Rect.fromCenter(
          center: tree,
          width: treeRadius * 5,
          height: treeRadius * 5.9,
        );
        paintImage(
          canvas: canvas,
          rect: treeRect,
          image: treeImage!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none, // Retains crisp pixel art!
        );
      } else {
        // Fallback drawing while image loads
        final treeTrunkPaint = Paint()..color = const Color(0xFF4A2F13);
        final treeLeavesPaint = Paint()..color = const Color(0xFF165231);
        canvas.drawRect(
          Rect.fromCenter(center: tree, width: 8, height: 26),
          treeTrunkPaint,
        );
        canvas.drawCircle(
          tree - const Offset(0, 14),
          treeRadius,
          treeLeavesPaint,
        );
      }
    }

    // Track occupied bounding boxes to prevent overlapping label text
    //final List<Rect> drawnLabelBounds = [];

    // Sort so boss labels are evaluated first and given render priority
    final sortedLiabilities = List<_FinancialLiability>.from(liabilities)
      ..sort((a, b) => (b.isBoss ? 1 : 0).compareTo(a.isBoss ? 1 : 0));

    for (final mob in sortedLiabilities) {
      // 1. Select the correct sprite based on enemy hierarchy
      ui.Image? spriteToDraw;

      if (mob.isBoss) {
        spriteToDraw = bossImage;
      } else if (mob.isEnemyTwo) {
        spriteToDraw = enemyTwoImage;
      } else {
        spriteToDraw = enemyOneImage;
      }

      // 2. Render Sprite or Fallback Circle
      if (spriteToDraw != null) {
        final Rect enemyRect = Rect.fromCircle(
          center: mob.pos,
          radius: mob.radius,
        );
        paintImage(
          canvas: canvas,
          rect: enemyRect,
          image: spriteToDraw,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none, // Keeps pixel art sharp!
        );
      } else {
        canvas.drawCircle(mob.pos, mob.radius, Paint()..color = mob.color);
      }

      // 3. Health Bar Rendering
      double hpPercent = (mob.principalRemaining / mob.maxPrincipal).clamp(
        0.0,
        1.0,
      );
      final barW = mob.radius * 2.2;
      final barH = mob.isBoss ? 8.0 : 4.0;
      final barLeft = mob.pos.dx - (barW / 2);
      final barTop = mob.pos.dy - mob.radius - (mob.isBoss ? 18 : 10);

      canvas.drawRect(
        Rect.fromLTWH(barLeft, barTop, barW, barH),
        Paint()..color = Colors.black45,
      );

      canvas.drawRect(
        Rect.fromLTWH(barLeft, barTop, barW * hpPercent, barH),
        Paint()
          ..color = mob.isBoss
              ? const Color(0xFFFF2F55)
              : const Color(0xFFE25C5C),
      );
    }
    // Render Projectiles (Player Coins vs Boss Threat Spheres)
    final playerCoinPaint = Paint()..color = const Color(0xFFFFD700);
    final playerCoinBorder = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final bossCoinPaint = Paint()..color = const Color(0xFFFF0033);
    final bossCoinBorder = Paint()
      ..color = const Color(0xFF8B0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final coin in coins) {
      if (coin.isEnemyProjectile) {
        canvas.drawCircle(coin.pos, coin.radius, bossCoinPaint);
        canvas.drawCircle(coin.pos, coin.radius, bossCoinBorder);
      } else {
        canvas.drawCircle(coin.pos, coin.radius, playerCoinPaint);
        canvas.drawCircle(coin.pos, coin.radius, playerCoinBorder);
      }
    }

    for (final part in particles) {
      canvas.drawCircle(
        part.pos,
        2.5,
        Paint()
          ..color = part.color.withValues(
            alpha: (part.life / 0.22).clamp(0.0, 1.0),
          ),
      );
    }

    for (final chest in chests) {
      if (chestImage != null) {
        final Rect chestRect = Rect.fromCenter(
          center: chest.pos,
          width: chestRadius * 2.8,
          height: chestRadius * 2.8,
        );
        paintImage(
          canvas: canvas,
          rect: chestRect,
          image: chestImage!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none, // Keeps pixel art crisp
        );
      } else {
        // Fallback circle while image asset is loading
        final chestPaint = Paint()..color = const Color(0xFFE1BB72);
        canvas.drawCircle(chest.pos, chestRadius, chestPaint);
      }
    }

    if (emergencyFundLevel > 0) {
      const double billWidth = 84.0;
      const double billHeight = 52.0;

      final double shieldRadius = 55.0 + (emergencyFundLevel * 10.0);
      final int shieldCount = min(4, 1 + emergencyFundLevel);

      for (int s = 0; s < shieldCount; s++) {
        final double angleOffset = shieldAngle + (s * (2 * pi / shieldCount));
        final Offset shieldPos =
            playerPos +
            Offset(cos(angleOffset), sin(angleOffset)) * shieldRadius;

        canvas.save();

        canvas.translate(shieldPos.dx, shieldPos.dy);
        canvas.rotate(angleOffset + (pi / 2));

        final Rect billRect = Rect.fromCenter(
          center: Offset.zero,
          width: billWidth,
          height: billHeight,
        );

        if (dollarImage != null) {
          paintImage(
            canvas: canvas,
            rect: billRect,
            image: dollarImage!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          );
        } else {
          final fallbackPaint = Paint()..color = const Color(0xFF00FF88);
          canvas.drawRect(billRect, fallbackPaint);
        }

        canvas.restore();
      }
    }

    // Player
    canvas.drawCircle(
      playerPos,
      playerRadius,
      Paint()..color = const Color(0xFF0F261D),
    );
    canvas.drawCircle(
      playerPos,
      playerRadius,
      Paint()
        ..color = const Color(0xFF85EFAC)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke,
    );

    // The player token used to draw the first letter of the equipped skin id,
    // which is why it read as a flat "C" — the skin happened to start with one.
    // If they have uploaded a profile picture, draw that instead, clipped to
    // the same circle so it sits inside the existing ring.
    final avatar = profileImage;
    if (avatar != null) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(
          Rect.fromCircle(center: playerPos, radius: playerRadius - 2),
        ),
      );
      paintImage(
        canvas: canvas,
        rect: Rect.fromCircle(center: playerPos, radius: playerRadius - 2),
        image: avatar,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
      canvas.restore();
    } else {
      final textPainter = TextPainter(
        text: TextSpan(
          text: equippedSkinId.isNotEmpty
              ? equippedSkinId.characters.first.toUpperCase()
              : '\$',
          style: GoogleFonts.pixelifySans(
            color: Color(0xFF85EFAC),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        playerPos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Player Balance HUD Bar
    double playerBalancePercent = (bankBalance / maxBankBalance).clamp(
      0.0,
      1.0,
    );
    final pBarW = 72.0;
    final pBarH = 6.0;
    canvas.drawRect(
      Rect.fromLTWH(
        playerPos.dx - (pBarW / 2),
        playerPos.dy + playerRadius + 10,
        pBarW,
        pBarH,
      ),
      Paint()..color = Colors.black87,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        playerPos.dx - (pBarW / 2),
        playerPos.dy + playerRadius + 10,
        pBarW * playerBalancePercent,
        pBarH,
      ),
      Paint()..color = const Color(0xFF85EFAC),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrawlPainter oldDelegate) => true;
}
