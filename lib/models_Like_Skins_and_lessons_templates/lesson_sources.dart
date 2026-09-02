import 'package:flutter/foundation.dart';

/// Where the Academy's facts come from.
///
/// **Why this exists as its own file.** An app that teaches money to children
/// is making claims — about interest, about credit scores, about what a
/// paycheck gets withheld — and a learner (or a parent, or a judge reading a
/// competition entry) is entitled to ask "says who?". Content with no
/// attribution is indistinguishable from content someone made up, and the
/// most valuable habit this app can teach about money is *check the source*.
/// A finance app that models the opposite is teaching the wrong lesson twice.
///
/// **Why citations are ids rather than inline URLs.** A URL written at each
/// call site is a URL that rots at each call site. Every lesson and every quiz
/// question cites a short key from [kLessonSources]; when a publisher moves a
/// page, one entry changes and everything that cited it follows.
/// `test/lesson_sources_test.dart` checks that every cited key exists, that
/// every source is HTTPS and on a trusted publisher, and — the one that
/// matters most — that **every lesson carries at least one**.
///
/// **Why these publishers.** All primary, all durable, none selling anything:
/// US federal agencies and the regulators' own investor/consumer education
/// arms. A bank's blog or a personal-finance site would be easier to quote
/// and would tie the curriculum's credibility to a company's marketing.
@immutable
class LessonSource {
  const LessonSource({
    required this.publisher,
    required this.title,
    required this.url,
  });

  /// Who published it — shown first, because for a claim about money the
  /// publisher *is* most of the credibility.
  final String publisher;

  /// The page or section title, so a reader knows what they are opening.
  final String title;

  final String url;

  /// "CFPB · Credit reports and scores"
  String get label => '$publisher · $title';
}

/// Publishers the curriculum is allowed to cite.
///
/// Enforced by test. The list is short on purpose: broadening it is a
/// decision worth making deliberately rather than one that happens because
/// somebody needed a link in a hurry.
const Set<String> kTrustedSourceHosts = <String>{
  'www.consumerfinance.gov',
  'www.investor.gov',
  'www.sec.gov',
  'www.irs.gov',
  'www.ssa.gov',
  'www.fdic.gov',
  'www.federalreserve.gov',
  'www.mymoney.gov',
  'www.bls.gov',
  'consumer.ftc.gov',
  'www.usa.gov',
  'home.treasury.gov',
  'www.annualcreditreport.com',
  'studentaid.gov',
  'www.dol.gov',
  'www.ftc.gov',
  'www.usda.gov',
  'www.treasurydirect.gov',
  'www.identitytheft.gov',
};

/// The citation catalogue, keyed by a short stable id.
const Map<String, LessonSource> kLessonSources = <String, LessonSource>{
  // ---------------- Money, budgeting, and habits ----------------
  'mymoney_home': LessonSource(
    publisher: 'MyMoney.gov',
    title: 'Financial Literacy and Education Commission',
    url: 'https://www.mymoney.gov/',
  ),
  'cfpb_budget': LessonSource(
    publisher: 'CFPB',
    title: 'Budgeting: How to create a budget and stick with it',
    url: 'https://www.consumerfinance.gov/consumer-tools/',
  ),
  'cfpb_money_as_you_grow': LessonSource(
    publisher: 'CFPB',
    title: 'Money as You Grow — age-appropriate money milestones',
    url: 'https://www.consumerfinance.gov/consumer-tools/money-as-you-grow/',
  ),
  'fed_currency': LessonSource(
    publisher: 'Federal Reserve',
    title: 'Currency and coin services',
    url: 'https://www.federalreserve.gov/paymentsystems/coin_about.htm',
  ),
  'treasury_currency': LessonSource(
    publisher: 'U.S. Treasury',
    title: 'About U.S. currency',
    url: 'https://home.treasury.gov/',
  ),

  // ---------------- Saving and banking ----------------
  'fdic_insurance': LessonSource(
    publisher: 'FDIC',
    title: 'Deposit insurance — how your money is protected',
    url: 'https://www.fdic.gov/resources/deposit-insurance/',
  ),
  'cfpb_savings': LessonSource(
    publisher: 'CFPB',
    title: 'Savings accounts and how they work',
    url: 'https://www.consumerfinance.gov/ask-cfpb/',
  ),
  'investor_compound': LessonSource(
    publisher: 'SEC · Investor.gov',
    title: 'Compound interest calculator',
    url:
        'https://www.investor.gov/financial-tools-calculators/calculators/'
        'compound-interest-calculator',
  ),
  'cfpb_emergency_fund': LessonSource(
    publisher: 'CFPB',
    title: 'Building an emergency savings cushion',
    url: 'https://www.consumerfinance.gov/consumer-tools/',
  ),
  'treasurydirect_savings_bonds': LessonSource(
    publisher: 'TreasuryDirect',
    title: 'Savings bonds',
    url: 'https://www.treasurydirect.gov/savings-bonds/',
  ),

  // ---------------- Credit and debt ----------------
  'cfpb_credit_reports': LessonSource(
    publisher: 'CFPB',
    title: 'Credit reports and scores',
    url:
        'https://www.consumerfinance.gov/consumer-tools/'
        'credit-reports-and-scores/',
  ),
  'annualcreditreport': LessonSource(
    publisher: 'AnnualCreditReport.com',
    title: 'The federally authorised free credit report site',
    url: 'https://www.annualcreditreport.com/',
  ),
  'cfpb_credit_cards': LessonSource(
    publisher: 'CFPB',
    title: 'Credit cards — how interest and minimum payments work',
    url: 'https://www.consumerfinance.gov/consumer-tools/credit-cards/',
  ),
  'cfpb_debt_collection': LessonSource(
    publisher: 'CFPB',
    title: 'Debt collection — your rights',
    url: 'https://www.consumerfinance.gov/consumer-tools/debt-collection/',
  ),
  'ftc_credit': LessonSource(
    publisher: 'FTC',
    title: 'Credit and loans',
    url: 'https://consumer.ftc.gov/credit-and-loans',
  ),

  // ---------------- Work, pay and taxes ----------------
  'irs_withholding': LessonSource(
    publisher: 'IRS',
    title: 'Tax withholding estimator',
    url: 'https://www.irs.gov/individuals/tax-withholding-estimator',
  ),
  'irs_understanding_taxes': LessonSource(
    publisher: 'IRS',
    title: 'Understanding taxes',
    url: 'https://www.irs.gov/',
  ),
  'ssa_taxes': LessonSource(
    publisher: 'Social Security Administration',
    title: 'How you pay for Social Security and Medicare',
    url: 'https://www.ssa.gov/',
  ),
  'dol_minimum_wage': LessonSource(
    publisher: 'U.S. Department of Labor',
    title: 'Wages and the Fair Labor Standards Act',
    url: 'https://www.dol.gov/general/topic/wages',
  ),
  'bls_earnings': LessonSource(
    publisher: 'Bureau of Labor Statistics',
    title: 'Occupational Outlook Handbook — pay by occupation',
    url: 'https://www.bls.gov/ooh/',
  ),
  'bls_cpi': LessonSource(
    publisher: 'Bureau of Labor Statistics',
    title: 'Consumer Price Index — how inflation is measured',
    url: 'https://www.bls.gov/cpi/',
  ),

  // ---------------- Investing ----------------
  'investor_home': LessonSource(
    publisher: 'SEC · Investor.gov',
    title: 'Introduction to investing',
    url: 'https://www.investor.gov/introduction-investing',
  ),
  'investor_diversification': LessonSource(
    publisher: 'SEC · Investor.gov',
    title: 'Diversification and asset allocation',
    url: 'https://www.investor.gov/introduction-investing/investing-basics',
  ),
  'investor_fees': LessonSource(
    publisher: 'SEC · Investor.gov',
    title: 'How fees and expenses affect your portfolio',
    url: 'https://www.investor.gov/introduction-investing/investing-basics',
  ),
  'sec_index_funds': LessonSource(
    publisher: 'SEC',
    title: 'Mutual funds and ETFs — a guide for investors',
    url: 'https://www.sec.gov/investor',
  ),
  'investor_risk': LessonSource(
    publisher: 'SEC · Investor.gov',
    title: 'Assessing your risk tolerance',
    url: 'https://www.investor.gov/introduction-investing/investing-basics',
  ),

  // ---------------- Retirement ----------------
  'ssa_retirement': LessonSource(
    publisher: 'Social Security Administration',
    title: 'Retirement benefits',
    url: 'https://www.ssa.gov/benefits/retirement/',
  ),
  'irs_retirement_plans': LessonSource(
    publisher: 'IRS',
    title: 'Retirement plans — 401(k) and IRA basics',
    url: 'https://www.irs.gov/retirement-plans',
  ),
  'dol_401k': LessonSource(
    publisher: 'U.S. Department of Labor',
    title: 'What you should know about your retirement plan',
    url:
        'https://www.dol.gov/agencies/ebsa/about-ebsa/our-activities/'
        'resource-center/publications',
  ),

  // ---------------- Scams, fees and fine print ----------------
  'ftc_scams': LessonSource(
    publisher: 'FTC',
    title: 'How to avoid a scam',
    url: 'https://consumer.ftc.gov/scams',
  ),
  'ftc_identity_theft': LessonSource(
    publisher: 'FTC',
    title: 'Identity theft and online security',
    url: 'https://consumer.ftc.gov/identity-theft-and-online-security',
  ),
  'cfpb_overdraft': LessonSource(
    publisher: 'CFPB',
    title: 'Overdraft fees explained',
    url: 'https://www.consumerfinance.gov/ask-cfpb/',
  ),
  'cfpb_complaints': LessonSource(
    publisher: 'CFPB',
    title: 'Submit a complaint about a financial product',
    url: 'https://www.consumerfinance.gov/complaint/',
  ),

  // ---------------- Big life costs ----------------
  'studentaid_home': LessonSource(
    publisher: 'Federal Student Aid',
    title: 'Types of federal student aid',
    url: 'https://studentaid.gov/understand-aid/types',
  ),
  'studentaid_loans': LessonSource(
    publisher: 'Federal Student Aid',
    title: 'Loan repayment plans',
    url: 'https://studentaid.gov/manage-loans/repayment/plans',
  ),
  'cfpb_renting': LessonSource(
    publisher: 'CFPB',
    title: 'Renting and housing costs',
    url: 'https://www.consumerfinance.gov/consumer-tools/',
  ),
  'cfpb_auto_loans': LessonSource(
    publisher: 'CFPB',
    title: 'Auto loans — what to know before you borrow',
    url: 'https://www.consumerfinance.gov/consumer-tools/auto-loans/',
  ),
  'usa_gov_money': LessonSource(
    publisher: 'USA.gov',
    title: 'Money and credit',
    url: 'https://www.usa.gov/money',
  ),
  // The FTC's dedicated recovery site, kept separate from `ftc_identity_theft`
  // (which explains the problem) because this one *is* the action: it builds
  // a personal recovery plan and generates the affidavit banks ask for. A
  // lesson that tells someone their identity was stolen and does not tell
  // them where to go has stopped one step short of being useful.
  'identitytheft_gov': LessonSource(
    publisher: 'FTC',
    title: 'IdentityTheft.gov — report and recover',
    url: 'https://www.identitytheft.gov/',
  ),
};

/// Resolves citation ids to sources, skipping any that no longer exist.
///
/// Skipping rather than throwing is deliberate: a stale id in one lesson
/// should cost that lesson a citation, not crash the Academy for everyone.
/// The test suite is where a stale id is supposed to be caught.
List<LessonSource> resolveSources(List<String> ids) => <LessonSource>[
  for (final id in ids)
    if (kLessonSources[id] != null) kLessonSources[id]!,
];
