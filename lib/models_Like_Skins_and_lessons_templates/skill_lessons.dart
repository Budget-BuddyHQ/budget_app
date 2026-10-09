import 'lesson.dart';
import 'lesson_data.dart';

/// Which lesson teaches each quiz skill, per unit.
///
/// The app description promises that a wrong answer points you at "the
/// direct lessons that the user missed the question on". The results screen
/// named the *topic* of a missed question and its right answer, but not
/// which lesson to go back to, because nothing linked the two. Every unit's
/// quiz skills line up one to one with its lessons, so this is a table
/// rather than a guess. A skill can appear in two units (banking, saving,
/// needs vs wants), which is why it is keyed by unit first.
///
/// `test/missed_question_lessons_test.dart` checks every skill used in every
/// quiz and test resolves to a real lesson in its own unit.
///
/// Generated from the lesson titles; edit the table, not the ids.
const Map<String, Map<String, String>>
kSkillLessonByUnit = <String, Map<String, String>>{
  'unit_10': <String, String>{
    'early_money_basics': 'lesson_46', // What Is Money?
    'early_saving': 'lesson_48', // Saving in a Piggy Bank
  },
  'unit_11': <String, String>{
    'allowance_earning': 'lesson_49', // Earning an Allowance
    'banking': 'lesson_52', // Why Banks Keep Money Safe
    'simple_savings_plan': 'lesson_51', // Making a Simple Plan
    'wants_vs_needs': 'lesson_50', // Needs vs Wants
  },
  'unit_1': <String, String>{
    'budget_basics': 'lesson_1', // Introduction to Budgeting
    'income': 'lesson_2', // Understanding Income
    'expenses': 'lesson_3', // Expenses and Spending
    'saving': 'lesson_4', // Saving Strategies
    'budget_building': 'lesson_5', // Building Your Budget
  },
  'unit_7': <String, String>{
    'advertising': 'lesson_32', // How Ads Are Aimed at You
    'digital_spending': 'lesson_33', // In-Game Money Is Still Money
    'impulse_control': 'lesson_34', // The 24-Hour Rule
    'scams': 'lesson_35', // Scams, Free Gifts and Too-Good Deals
    'wants_vs_needs': 'lesson_31', // Wants Wearing a Needs Costume
  },
  'unit_3': <String, String>{
    'pay_yourself_first': 'lesson_11', // Pay Yourself First
    'sinking_funds': 'lesson_12', // Sinking Funds
    'savings_accounts': 'lesson_13', // Choosing Savings Accounts
    'automation': 'lesson_14', // Automating Good Habits
    'irregular_costs': 'lesson_15', // Preparing for Irregular Costs
    'saving': 'lesson_11', // Pay Yourself First
  },
  'unit_8': <String, String>{
    'percentages': 'lesson_36', // Percentages You Actually Use
    'averages': 'lesson_37', // Average vs Median
    'chart_reading': 'lesson_38', // Reading a Price Chart
    'misleading_charts': 'lesson_39', // How Charts Mislead
    'spending_tracking': 'lesson_40', // Tracking Your Own Spending Data
  },
  'unit_2': <String, String>{
    'credit': 'lesson_6', // Credit and Debt Management
    'investing_basics': 'lesson_7', // Introduction to Investing
    'banking': 'lesson_8', // Banking and Financial Tools
    'emergency_fund': 'lesson_9', // Emergency Planning
    'goals': 'lesson_10', // Long-Term Financial Goals
  },
  'unit_5': <String, String>{
    'pay_stub': 'lesson_21', // Reading a Pay Stub
    'job_offers': 'lesson_22', // Comparing Job Offers
    'living_costs': 'lesson_23', // Rent, Utilities, and Living Costs
    'taxes': 'lesson_24', // Taxes and Withholding
    'money_plan': 'lesson_25', // Building a Personal Money Plan
  },
  'unit_12': <String, String>{
    'car_costs': 'lesson_53', // What a Car Really Costs
    'loan_offers': 'lesson_54', // Reading a Loan Offer
    'renting': 'lesson_55', // Renting Your First Place
    'move_in_costs': 'lesson_56', // The Move-In Bill
    'buy_or_wait': 'lesson_57', // Buy, Lease, or Wait
  },
  'unit_4': <String, String>{
    'why_invest': 'lesson_16', // Why People Invest
    'risk': 'lesson_17', // Risk and Diversification
    'asset_types': 'lesson_18', // Stocks, Bonds, and Funds
    'compounding': 'lesson_19', // Compound Growth
    'investor_mindset': 'lesson_20', // Long-Term Investor Mindset
  },
  'unit_6': <String, String>{
    'share_ownership': 'lesson_26', // What a Share Really Is
    'price_movement': 'lesson_27', // Why Prices Move
    'diversification': 'lesson_28', // Risk, Diversification, and Index Funds
    'trading_costs': 'lesson_29', // Orders, Spreads, and Fees
    'time_in_market': 'lesson_30', // Time in the Market
  },
  'unit_9': <String, String>{
    'retirement_accounts': 'lesson_41', // Why Retirement Accounts Exist
    'employer_match': 'lesson_42', // The Employer Match
    'roth_vs_traditional': 'lesson_43', // Roth vs Traditional
    'starting_early': 'lesson_44', // Starting Early Beats Saving More
    'fees_vesting': 'lesson_45', // Fees, Vesting and Job Changes
  },
  'unit_13': <String, String>{
    'identity_theft': 'lesson_58', // How Identity Theft Happens
    'credit_freeze': 'lesson_59', // Freezing Your Credit
    'credit_reports': 'lesson_60', // Reading Your Credit Report
    'avoidable_fees': 'lesson_61', // Fees You Can Turn Off
    'complaints': 'lesson_62', // When Something Goes Wrong
  },
};

/// The lesson that teaches [skillId], preferring [unitId]'s own lesson.
/// Falls back to any unit that teaches it, for practice runs that mix units.
Lesson? lessonForSkill(String skillId, {String? unitId}) {
  final id =
      kSkillLessonByUnit[unitId]?[skillId] ??
      kSkillLessonByUnit.values
          .map((m) => m[skillId])
          .whereType<String>()
          .firstOrNull;
  if (id == null) return null;
  for (final unit in lessonUnits) {
    for (final lesson in unit.lessons) {
      if (lesson.id == id) return lesson;
    }
  }
  return null;
}

/// The unit [lesson] belongs to.
LessonUnit? unitOfLesson(Lesson lesson) {
  for (final unit in lessonUnits) {
    if (unit.lessons.any((l) => l.id == lesson.id)) return unit;
  }
  return null;
}
