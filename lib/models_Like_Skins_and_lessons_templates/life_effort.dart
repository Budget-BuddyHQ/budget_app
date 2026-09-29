import 'life_sim_models.dart';

/// How much of a year one person has.
///
/// # The exploit this closes
///
/// Reported as *"make sure the player cannot spam the same option, like
/// working out to become happy"*, and it was true of almost every button in
/// the menus. A fading-returns rule existed, but it had been wired into
/// exactly one action (`exercise`). Everything else paid in full, every time:
///
///  * **Work a side job** paid 40 to 100 coins per tap while happiness was
///    clamped at zero, so nothing ever made the next tap cost anything. It was
///    an infinite-money button, in a game whose leaderboard ranks net worth.
///  * **Ask for a raise** could be tapped until it landed, at a 30% chance a
///    go, for 400 to 1,000 a year each time.
///  * **Go out**, **spend time with somebody** and **study** were free stat
///    bumps for a child, tappable forever.
///
/// Any game where the best move is pressing one button repeatedly has stopped
/// being about choices, and this one is meant to be about trade-offs.
///
/// # Why it is a budget, and why it fades
///
/// A year has room for a limited amount of anything. So each action has a
/// small number of uses per year, and each use lands at a fraction of the last:
/// the first workout of a year changes you, the fourth barely registers.
///
/// A hard once-a-year limit would read as the game refusing you. A fading
/// return reads as the truth it models, which is why it is a curve rather than
/// a wall.
///
/// This is also a lesson in its own right. **Time is a budget**, and spending
/// it on one thing is a choice not to spend it on another. That is opportunity
/// cost, which the Academy teaches with money and this teaches with hours.
///
/// Kept in its own file, away from the controller and from Flutter, so the
/// rules can be read in one place and tested as rules.
class EffortRules {
  const EffortRules._();

  /// What each use lands at, in order, for every action that has a budget.
  ///
  /// The length of the list **is** the yearly limit. `invest` and `findJob` are
  /// absent on purpose: putting money to work is limited by having the money,
  /// and there is nothing to spam about looking for a job you already lack.
  static const Map<LifeAction, List<double>> tiers = <LifeAction, List<double>>{
    LifeAction.study: <double>[1.0, 0.5, 0.25],
    LifeAction.library: <double>[1.0, 0.5, 0.25],
    LifeAction.exercise: <double>[1.0, 0.5, 0.25],
    LifeAction.goOut: <double>[1.0, 0.5, 0.25],
    LifeAction.practice: <double>[1.0, 0.5, 0.25],
    LifeAction.sideJob: <double>[1.0, 0.5, 0.25],
    LifeAction.spendTime: <double>[1.0, 0.5, 0.25],
    LifeAction.doctor: <double>[1.0, 0.5],
    LifeAction.buyGift: <double>[1.0, 0.5],
    LifeAction.volunteer: <double>[1.0, 0.5],
    LifeAction.workHarder: <double>[1.0, 0.5],
    LifeAction.network: <double>[1.0, 0.5],
    // Asking twice in a year is not a second chance, it is a worse first ask.
    LifeAction.askForRaise: <double>[1.0],
    // Applications are limited by time and by nerve, not by anything that pays.
    LifeAction.applyJob: <double>[1.0, 1.0, 1.0],
    LifeAction.applyPromotion: <double>[1.0],
    LifeAction.applyCollege: <double>[1.0, 1.0, 1.0],
    // People are not a button. Most of a year is enough for a few good moments.
    LifeAction.conversation: <double>[1.0, 1.0, 0.5, 0.5, 0.25],
    LifeAction.compliment: <double>[1.0, 0.5, 0.25],
    LifeAction.askMoney: <double>[1.0],
    LifeAction.date: <double>[1.0, 0.5, 0.25],
    // A stake is a stake. It does not shrink, but it does run out.
    LifeAction.gamble: <double>[1.0, 1.0, 1.0],
  };

  /// How many uses [action] has in a year, or null when it is not limited.
  static int? capFor(LifeAction action) => tiers[action]?.length;

  /// What the next use lands at, given [used] so far this year.
  ///
  /// 1.0 for anything unlimited, 0.0 once the year has no room left.
  static double yieldAt(LifeAction action, int used) {
    final table = tiers[action];
    if (table == null) return 1.0;
    if (used < 0) return table.first;
    if (used >= table.length) return 0.0;
    return table[used];
  }

  /// The player-facing state of one action's budget.
  static ActionBudget budget(LifeAction action, int used) =>
      ActionBudget(action: action, used: used);
}

/// One action's allowance for the current year, as the menu shows it.
class ActionBudget {
  const ActionBudget({required this.action, required this.used});

  final LifeAction action;

  /// Uses so far this year.
  final int used;

  /// Whether this action is limited at all.
  bool get limited => EffortRules.capFor(action) != null;

  /// Uses in the whole year, or 0 when unlimited.
  int get cap => EffortRules.capFor(action) ?? 0;

  /// Uses still available. Meaningless for an unlimited action.
  int get left => limited ? (cap - used).clamp(0, cap) : 0;

  bool get exhausted => limited && left == 0;

  /// What the next use will land at.
  double get nextYield => EffortRules.yieldAt(action, used);

  /// True once the next use is worth less than the last.
  bool get fading => limited && !exhausted && nextYield < 1.0;

  /// A short line for the menu row, or null for an unlimited action.
  ///
  /// Says the trade in plain words. "2 left this year" is the budget; "half
  /// strength now" is why the third tap of the same button is a poor one.
  String? get label {
    if (!limited) return null;
    if (exhausted) return 'Done for this year';
    final noun = left == 1 ? 'use' : 'uses';
    if (nextYield >= 1.0) return '$left $noun left this year';
    final pct = (nextYield * 100).round();
    return '$left $noun left · pays $pct% now';
  }
}
