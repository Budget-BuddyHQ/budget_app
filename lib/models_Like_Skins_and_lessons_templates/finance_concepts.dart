import 'package:flutter/material.dart';

/// The financial ideas Budget Buddy actually tries to teach, in one place.
///
/// **Why this file exists.** The app had grown a lot of *features* — a life
/// sim, a town, an arcade, a market board, a habit tracker — and a player
/// could enjoy all of them without ever being told what any of it meant in
/// real money terms. Choices moved numbers up and down; nothing ever said
/// *why* one choice was better, or named the idea behind it so a player
/// could carry it out of the game.
///
/// This is that missing layer. A [FinanceConcept] is a single idea, written
/// at two reading levels, that gets attached to the moments where the game
/// already makes the player decide something. The game keeps being a game;
/// it just stops being silent about what it is teaching.
///
/// Two reading levels because the Academy now runs from ages 4-6 upward
/// (`AgeStage.earlyChildhood`). The same event can therefore teach a six
/// year old and a nineteen year old without writing two games — see
/// [FinanceConceptInfo.explainerFor].
enum FinanceConcept {
  needsVsWants,
  opportunityCost,
  payYourselfFirst,
  budgetRule,
  emergencyFund,
  compoundGrowth,
  interestCost,
  creditScore,
  inflation,
  diversification,
  incomeVsWealth,
  insurance,
  taxes,
  impulseSpending,
  sunkCost,
  lifestyleCreep,
}

extension FinanceConceptInfo on FinanceConcept {
  /// Short name, used as a card title and on the "money ideas you've met"
  /// list. Deliberately plain English, not jargon — "What it really costs"
  /// rather than "Opportunity cost" — with the textbook term introduced in
  /// the body once the plain idea has landed.
  String get label => switch (this) {
    FinanceConcept.needsVsWants => 'Needs vs wants',
    FinanceConcept.opportunityCost => 'What it really costs',
    FinanceConcept.payYourselfFirst => 'Pay yourself first',
    FinanceConcept.budgetRule => 'The 50/30/20 budget',
    FinanceConcept.emergencyFund => 'Emergency fund',
    FinanceConcept.compoundGrowth => 'Money that grows itself',
    FinanceConcept.interestCost => 'Borrowing costs extra',
    FinanceConcept.creditScore => 'Credit score',
    FinanceConcept.inflation => 'Prices creep up',
    FinanceConcept.diversification => "Don't put it all in one place",
    FinanceConcept.incomeVsWealth => 'Earning vs keeping',
    FinanceConcept.insurance => 'Insurance',
    FinanceConcept.taxes => 'Taxes',
    FinanceConcept.impulseSpending => 'Impulse buying',
    FinanceConcept.sunkCost => 'Money already gone',
    FinanceConcept.lifestyleCreep => 'Lifestyle creep',
  };

  /// A one-glyph shorthand for the idea.
  ///
  /// Sits alongside [icon] rather than replacing it: Material icons carry
  /// the app's own styling and tint to any accent colour, which is what a
  /// list row wants, while an emoji survives at 10px inside a chip where a
  /// tinted vector turns into a smudge. Both are used, in different places.
  ///
  /// These read as *pictures of the idea*, not decoration — a basket for
  /// needs versus wants, an umbrella for the emergency fund — so a reader
  /// too young for the label still gets a hook.
  String get emoji => switch (this) {
    FinanceConcept.needsVsWants => '\u{1F9FA}',
    FinanceConcept.opportunityCost => '\u{2696}',
    FinanceConcept.payYourselfFirst => '\u{1F437}',
    FinanceConcept.budgetRule => '\u{1F4CA}',
    FinanceConcept.emergencyFund => '\u{2602}',
    FinanceConcept.compoundGrowth => '\u{1F331}',
    FinanceConcept.interestCost => '\u{1F4B3}',
    FinanceConcept.creditScore => '\u{1F3AF}',
    FinanceConcept.inflation => '\u{1F388}',
    FinanceConcept.diversification => '\u{1F95A}',
    FinanceConcept.incomeVsWealth => '\u{1F45B}',
    FinanceConcept.insurance => '\u{1F6E1}',
    FinanceConcept.taxes => '\u{1F9FE}',
    FinanceConcept.impulseSpending => '\u{26A1}',
    FinanceConcept.sunkCost => '\u{1F573}',
    FinanceConcept.lifestyleCreep => '\u{1F6CD}',
  };

  IconData get icon => switch (this) {
    FinanceConcept.needsVsWants => Icons.shopping_basket_rounded,
    FinanceConcept.opportunityCost => Icons.compare_arrows_rounded,
    FinanceConcept.payYourselfFirst => Icons.savings_rounded,
    FinanceConcept.budgetRule => Icons.pie_chart_rounded,
    FinanceConcept.emergencyFund => Icons.umbrella_rounded,
    FinanceConcept.compoundGrowth => Icons.trending_up_rounded,
    FinanceConcept.interestCost => Icons.credit_card_rounded,
    FinanceConcept.creditScore => Icons.speed_rounded,
    FinanceConcept.inflation => Icons.local_grocery_store_rounded,
    FinanceConcept.diversification => Icons.scatter_plot_rounded,
    FinanceConcept.incomeVsWealth => Icons.account_balance_wallet_rounded,
    FinanceConcept.insurance => Icons.health_and_safety_rounded,
    FinanceConcept.taxes => Icons.receipt_long_rounded,
    FinanceConcept.impulseSpending => Icons.flash_on_rounded,
    FinanceConcept.sunkCost => Icons.history_toggle_off_rounded,
    FinanceConcept.lifestyleCreep => Icons.moving_rounded,
  };

  Color get accent => switch (this) {
    FinanceConcept.needsVsWants ||
    FinanceConcept.budgetRule ||
    FinanceConcept.payYourselfFirst => const Color(0xFF4BD2A3),
    FinanceConcept.compoundGrowth ||
    FinanceConcept.diversification ||
    FinanceConcept.incomeVsWealth => const Color(0xFF69C6FF),
    FinanceConcept.interestCost ||
    FinanceConcept.creditScore ||
    FinanceConcept.impulseSpending ||
    FinanceConcept.lifestyleCreep => const Color(0xFFFF8FB1),
    _ => const Color(0xFFFFD45C),
  };

  /// For ages roughly 4-10: one concrete sentence, no percentages, no
  /// abstractions, framed around things a young child actually handles
  /// (pocket money, snacks, toys).
  String get kidExplainer => switch (this) {
    FinanceConcept.needsVsWants =>
      'Some things you NEED, like food and a warm coat. Some things you '
          'just WANT, like sweets and toys. Needs go first.',
    FinanceConcept.opportunityCost =>
      'If you spend your money on one thing, you cannot spend it on '
          'something else. Picking one means saying no to the other.',
    FinanceConcept.payYourselfFirst =>
      'When you get money, put a little into savings BEFORE you spend any '
          'of it. Then the saving actually happens.',
    FinanceConcept.budgetRule =>
      'A budget is a plan for your money: some for things you need, a '
          'little for fun, and always some to save.',
    FinanceConcept.emergencyFund =>
      'Keep some money hidden away for surprises, like when something '
          'breaks. Then a surprise is not a disaster.',
    FinanceConcept.compoundGrowth =>
      'Money you save can slowly grow all by itself, like a seed turning '
          'into a tree. The longer you leave it, the bigger it gets.',
    FinanceConcept.interestCost =>
      'If you borrow money, you have to pay back MORE than you borrowed. '
          'Borrowing is never free.',
    FinanceConcept.creditScore =>
      'Grown-ups get a score for paying people back on time. A good score '
          'means people trust you with money.',
    FinanceConcept.inflation =>
      'Things slowly get more expensive over time. The same sweet costs '
          'more when you are older than it does today.',
    FinanceConcept.diversification =>
      'Do not keep all your eggs in one basket. If you drop it, you lose '
          'everything at once.',
    FinanceConcept.incomeVsWealth =>
      'Getting lots of money is not the same as KEEPING it. What you keep '
          'is what counts.',
    FinanceConcept.insurance =>
      'You pay a little bit regularly so that if something bad happens, '
          'you do not have to pay a huge amount all at once.',
    FinanceConcept.taxes =>
      'A small part of what grown-ups earn goes to pay for shared things '
          'like schools, roads and hospitals.',
    FinanceConcept.impulseSpending =>
      'When you REALLY want something right now, wait a day. Often you '
          'stop wanting it, and you keep your money.',
    FinanceConcept.sunkCost =>
      'Money you already spent is gone. Do not keep going with something '
          'you do not like just because you paid for it.',
    FinanceConcept.lifestyleCreep =>
      'When you get more money it is tempting to spend more too. If you '
          'always spend it all, more money does not help.',
  };

  /// For roughly 11 and up: the same idea with the real term, a number, and
  /// something the reader could actually act on.
  String get explainer => switch (this) {
    FinanceConcept.needsVsWants =>
      'A need keeps you housed, fed, healthy and able to work. A want is '
          'everything else. Most overspending is not one huge mistake — it '
          'is wants quietly getting filed as needs.',
    FinanceConcept.opportunityCost =>
      'The real price of anything is what you gave up to get it. Spending '
          '\$200 on headphones does not cost \$200 — it costs the \$200 '
          'plus whatever that money would have become if you had invested '
          'it instead.',
    FinanceConcept.payYourselfFirst =>
      'Move money to savings the day you get paid, not whatever is left at '
          'the end of the month — because the honest answer is usually '
          'nothing is left. Automating the transfer beats willpower.',
    FinanceConcept.budgetRule =>
      'A common starting split is 50% of take-home pay on needs, 30% on '
          'wants, 20% to savings and debt. It is a starting point, not a '
          'law — but if your needs are far above 50%, that is the number '
          'to fix first.',
    FinanceConcept.emergencyFund =>
      'Three to six months of essential expenses, kept somewhere boring '
          'and reachable. Its job is not to earn — it is to stop one bad '
          'month from turning into high-interest debt.',
    FinanceConcept.compoundGrowth =>
      'Growth earns growth. At about 7% a year, money roughly doubles '
          'every 10 years — so \$1,000 invested at 20 is worth far more at '
          '60 than \$1,000 invested at 50. Time is the ingredient you '
          'cannot buy later.',
    FinanceConcept.interestCost =>
      'Carry a \$1,000 balance at 24% APR and paying only the minimum can '
          'take years and cost hundreds in interest. Compound growth works '
          'exactly as hard against you when you are the borrower.',
    FinanceConcept.creditScore =>
      'A number lenders use to price the risk of lending to you. Payment '
          'history is the single biggest input — one missed payment hurts '
          'more than most people expect, and a better score means a '
          'cheaper mortgage later.',
    FinanceConcept.inflation =>
      'Prices rise over time, so cash loses buying power just sitting '
          'still. At 3% inflation, \$100 buys about \$74 worth of goods in '
          '10 years. Doing nothing is also a decision.',
    FinanceConcept.diversification =>
      'Spreading money across many investments means one failure is a '
          'dent, not a wipeout. It is the one protection you get without '
          'having to predict anything correctly.',
    FinanceConcept.incomeVsWealth =>
      'Wealth is what you keep, not what you earn. A high earner who '
          'spends everything has no wealth; a modest earner who saves '
          'steadily builds it. The gap between the two numbers is the '
          'whole game.',
    FinanceConcept.insurance =>
      'You trade a small, predictable cost for protection against a rare, '
          'unaffordable one. Insure what would financially ruin you; '
          'self-insure the small stuff.',
    FinanceConcept.taxes =>
      'Money is withheld from your pay before you see it. Knowing the '
          'difference between gross and take-home pay is what stops a '
          'salary number from being misleading when you budget.',
    FinanceConcept.impulseSpending =>
      'A 24-hour wait on any non-essential purchase kills most impulse '
          'buys, because the urge fades faster than the money comes back. '
          'The urge is the thing being sold to you.',
    FinanceConcept.sunkCost =>
      'Money already spent cannot be recovered by spending more. Judge the '
          'next decision on what happens next, not on what it already cost '
          'you to get here.',
    FinanceConcept.lifestyleCreep =>
      'When income rises, spending quietly rises to match, so the raise '
          'never turns into savings. Deciding in advance where a raise '
          'goes is what turns earning more into having more.',
  };

  /// Picks the reading level.
  ///
  /// [simple] comes from the **player's** self-declared age band
  /// (`AgeBand.prefersSimpleWording`), **not** the in-game character's age —
  /// a nine year old playing a 40-year-old character still needs the
  /// nine-year-old wording, and a nineteen year old playing a child does
  /// not. Defaults to the older copy, which is the safer fallback when the
  /// player never told us their age.
  String explainerFor({bool simple = false}) =>
      simple ? kidExplainer : explainer;

  /// One concrete thing the reader could do this week. Kept separate from
  /// the explainer so the UI can show "what it is" and "what to do" as
  /// visually distinct steps.
  String get tryThis => switch (this) {
    FinanceConcept.needsVsWants =>
      'Look at the last five things you bought. Mark each one N or W.',
    FinanceConcept.opportunityCost =>
      'Next time you nearly buy something, name what else that money could '
          'have done.',
    FinanceConcept.payYourselfFirst =>
      'Decide an amount to save the moment money arrives — even 10%.',
    FinanceConcept.budgetRule =>
      'Add up last month. What percent actually went to needs?',
    FinanceConcept.emergencyFund =>
      'Work out one month of your essentials. That is your first target.',
    FinanceConcept.compoundGrowth =>
      'Try a compound-interest calculator with your own numbers and 40 '
          'years.',
    FinanceConcept.interestCost =>
      'Find the APR on any card or loan you can see. Was it what you '
          'expected?',
    FinanceConcept.creditScore =>
      'Learn which of your bills are reported to credit agencies.',
    FinanceConcept.inflation =>
      'Ask someone older what their first wage was, and what rent cost '
          'then.',
    FinanceConcept.diversification =>
      'Check whether your savings all sit in one place or several.',
    FinanceConcept.incomeVsWealth =>
      'Work out your own gap: money in, minus money out, last month.',
    FinanceConcept.insurance =>
      'List what you own that you genuinely could not afford to replace.',
    FinanceConcept.taxes =>
      'Find the gap between gross and take-home on a real payslip.',
    FinanceConcept.impulseSpending =>
      'Put one thing in a cart and leave it 24 hours before deciding.',
    FinanceConcept.sunkCost =>
      'Name one thing you keep paying for out of habit, not use.',
    FinanceConcept.lifestyleCreep =>
      'Decide now where your next raise or gift money goes.',
  };
}

/// Stable string ids for persistence — [FinanceConcept.name] would also
/// work, but going through an explicit map means renaming an enum value
/// can't silently orphan a player's saved progress.
const Map<FinanceConcept, String> kFinanceConceptIds = <FinanceConcept, String>{
  FinanceConcept.needsVsWants: 'needs_vs_wants',
  FinanceConcept.opportunityCost: 'opportunity_cost',
  FinanceConcept.payYourselfFirst: 'pay_yourself_first',
  FinanceConcept.budgetRule: 'budget_rule',
  FinanceConcept.emergencyFund: 'emergency_fund',
  FinanceConcept.compoundGrowth: 'compound_growth',
  FinanceConcept.interestCost: 'interest_cost',
  FinanceConcept.creditScore: 'credit_score',
  FinanceConcept.inflation: 'inflation',
  FinanceConcept.diversification: 'diversification',
  FinanceConcept.incomeVsWealth: 'income_vs_wealth',
  FinanceConcept.insurance: 'insurance',
  FinanceConcept.taxes: 'taxes',
  FinanceConcept.impulseSpending: 'impulse_spending',
  FinanceConcept.sunkCost: 'sunk_cost',
  FinanceConcept.lifestyleCreep: 'lifestyle_creep',
};

FinanceConcept? financeConceptFromId(String id) {
  for (final entry in kFinanceConceptIds.entries) {
    if (entry.value == id) return entry.key;
  }
  return null;
}
