import 'package:flutter/material.dart';

/// Data model for the Money Habits feature: a habit catalog with adjustable
/// dollar amounts, structured "challenges" of related habits, and a savings
/// jar that fills up and moods off habit activity specifically (kept
/// independent of the player's overall XP/level, which reacts to unrelated
/// things like stock trades and quizzes).
///
/// This is a daily-money-habit tracker in the same broad genre as a habit
/// app that gamifies a different domain (recurring tasks, an adjustable
/// per-task amount, a growing companion) — the domain here is entirely
/// budgeting/saving, not carbon tracking, on purpose: it's Budget Buddy's
/// actual mission, not a borrowed one.

enum HabitCategory {
  cutSpending('Cut Spending', Icons.local_offer_rounded, Color(0xFFFF8474)),
  saveMore('Save More', Icons.savings_rounded, Color(0xFF4BD2A3)),
  smartHabits('Smart Habits', Icons.psychology_rounded, Color(0xFF69C6FF));

  const HabitCategory(this.label, this.icon, this.accent);
  final String label;
  final IconData icon;
  final Color accent;
}

/// A bundle of the two stats Money Habits tracks. Immutable and additive,
/// so running totals are just repeated `+`.
@immutable
class HabitImpact {
  const HabitImpact({this.moneySavedUsd = 0, this.choicesKept = 0});

  static const HabitImpact zero = HabitImpact();

  final double moneySavedUsd;

  /// Habit-building actions that don't have a direct dollar figure (e.g.
  /// "track every expense today") still count toward this.
  final double choicesKept;

  HabitImpact operator +(HabitImpact other) => HabitImpact(
    moneySavedUsd: moneySavedUsd + other.moneySavedUsd,
    choicesKept: choicesKept + other.choicesKept,
  );

  HabitImpact scale(double factor) => HabitImpact(
    moneySavedUsd: moneySavedUsd * factor,
    choicesKept: choicesKept * factor,
  );

  factory HabitImpact.fromMap(Map<String, dynamic> map) => HabitImpact(
    moneySavedUsd: _readDouble(map['money_saved_usd']),
    choicesKept: _readDouble(map['choices_kept']),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'money_saved_usd': moneySavedUsd,
    'choices_kept': choicesKept,
  };
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

/// Describes a numeric knob a habit can be adjusted by before saving/
/// completing it (e.g. "how many dollars"). Habits without one are a flat,
/// one-tap completion.
@immutable
class HabitAdjustableParam {
  const HabitAdjustableParam({
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.defaultValue,
  });

  final String label;
  final String unit;
  final double min;
  final double max;
  final double step;
  final double defaultValue;
}

/// A catalog entry in the "Activity" browser. `impactPerUnit` is the
/// impact of a single unit of the adjustable param, or of one flat
/// completion when [adjustable] is null.
@immutable
class HabitTemplate {
  const HabitTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.blurb,
    required this.impactPerUnit,
    this.adjustable,
    this.icon = Icons.savings_rounded,
  });

  final String id;
  final String title;
  final HabitCategory category;
  final String blurb;
  final HabitImpact impactPerUnit;
  final HabitAdjustableParam? adjustable;
  final IconData icon;

  bool get isAdjustable => adjustable != null;

  HabitImpact impactFor(double units) => impactPerUnit.scale(units);
}

HabitTemplate? habitById(String id) {
  for (final habit in habitCatalog) {
    if (habit.id == id) return habit;
  }
  return null;
}

const List<HabitTemplate> habitCatalog = <HabitTemplate>[
  // ---------------- Cut Spending ----------------
  HabitTemplate(
    id: 'skip_eating_out',
    title: 'Skip eating out today',
    category: HabitCategory.cutSpending,
    blurb: 'Cooking or packing instead of ordering keeps real money in your pocket.',
    impactPerUnit: HabitImpact(moneySavedUsd: 15, choicesKept: 1),
    icon: Icons.no_food_rounded,
  ),
  HabitTemplate(
    id: 'skip_coffee',
    title: 'Make coffee at home',
    category: HabitCategory.cutSpending,
    blurb: 'A few dollars a cup adds up fast over a week.',
    impactPerUnit: HabitImpact(moneySavedUsd: 5, choicesKept: 1),
    adjustable: HabitAdjustableParam(
      label: 'Times this week',
      unit: 'times',
      min: 1,
      max: 5,
      step: 1,
      defaultValue: 1,
    ),
    icon: Icons.coffee_rounded,
  ),
  HabitTemplate(
    id: 'no_impulse_buy',
    title: 'Skip an impulse buy',
    category: HabitCategory.cutSpending,
    blurb: 'Something you almost bought without thinking — and didn\'t.',
    impactPerUnit: HabitImpact(moneySavedUsd: 20, choicesKept: 1),
    icon: Icons.remove_shopping_cart_rounded,
  ),
  HabitTemplate(
    id: 'cancel_unused_sub',
    title: 'Cancel an unused subscription',
    category: HabitCategory.cutSpending,
    blurb: 'A subscription you forgot about is money leaking out every month.',
    impactPerUnit: HabitImpact(moneySavedUsd: 12, choicesKept: 1),
    icon: Icons.unsubscribe_rounded,
  ),
  HabitTemplate(
    id: 'use_a_coupon',
    title: 'Use a coupon or discount code',
    category: HabitCategory.cutSpending,
    blurb: 'A discount you actually used instead of letting it expire.',
    impactPerUnit: HabitImpact(moneySavedUsd: 1),
    adjustable: HabitAdjustableParam(
      label: 'Dollars saved',
      unit: 'dollars',
      min: 1,
      max: 30,
      step: 1,
      defaultValue: 5,
    ),
    icon: Icons.local_activity_rounded,
  ),
  // ---------------- Save More ----------------
  HabitTemplate(
    id: 'save_pocket_change',
    title: 'Save today\'s spare change',
    category: HabitCategory.saveMore,
    blurb: 'Loose change adds up when it actually makes it to savings.',
    impactPerUnit: HabitImpact(moneySavedUsd: 1),
    adjustable: HabitAdjustableParam(
      label: 'Dollars set aside',
      unit: 'dollars',
      min: 1,
      max: 10,
      step: 0.5,
      defaultValue: 2,
    ),
    icon: Icons.savings_rounded,
  ),
  HabitTemplate(
    id: 'round_up_savings',
    title: 'Round up a purchase to savings',
    category: HabitCategory.saveMore,
    blurb: 'The spare change from rounding up goes straight to savings instead of nowhere.',
    impactPerUnit: HabitImpact(moneySavedUsd: 3),
    icon: Icons.trending_up_rounded,
  ),
  HabitTemplate(
    id: 'sell_something',
    title: 'Sell something you don\'t use',
    category: HabitCategory.saveMore,
    blurb: 'Clutter is money sitting still — selling it turns it back into cash.',
    impactPerUnit: HabitImpact(moneySavedUsd: 1),
    adjustable: HabitAdjustableParam(
      label: 'Dollars earned',
      unit: 'dollars',
      min: 5,
      max: 100,
      step: 5,
      defaultValue: 20,
    ),
    icon: Icons.sell_rounded,
  ),
  HabitTemplate(
    id: 'pack_lunch',
    title: 'Pack lunch instead of buying',
    category: HabitCategory.saveMore,
    blurb: 'Buying lunch out every day is one of the fastest ways a budget quietly breaks.',
    impactPerUnit: HabitImpact(moneySavedUsd: 10, choicesKept: 1),
    icon: Icons.lunch_dining_rounded,
  ),
  HabitTemplate(
    id: 'set_aside_allowance',
    title: 'Set aside part of your allowance',
    category: HabitCategory.saveMore,
    blurb: 'Paying your future self first is the whole trick to saving.',
    impactPerUnit: HabitImpact(moneySavedUsd: 1),
    adjustable: HabitAdjustableParam(
      label: 'Dollars',
      unit: 'dollars',
      min: 1,
      max: 20,
      step: 1,
      defaultValue: 5,
    ),
    icon: Icons.account_balance_wallet_rounded,
  ),
  // ---------------- Smart Habits ----------------
  HabitTemplate(
    id: 'track_every_expense',
    title: 'Track every expense today',
    category: HabitCategory.smartHabits,
    blurb: 'You can\'t fix what you don\'t see — one full day of tracking shows the leaks.',
    impactPerUnit: HabitImpact(choicesKept: 1),
    icon: Icons.receipt_long_rounded,
  ),
  HabitTemplate(
    id: 'compare_prices',
    title: 'Compare prices before buying',
    category: HabitCategory.smartHabits,
    blurb: 'A minute of comparing prices usually pays for itself.',
    impactPerUnit: HabitImpact(moneySavedUsd: 8, choicesKept: 1),
    icon: Icons.compare_arrows_rounded,
  ),
  HabitTemplate(
    id: 'make_a_budget_check',
    title: 'Check your budget before spending',
    category: HabitCategory.smartHabits,
    blurb: 'Looking before you spend catches problems before they happen, not after.',
    impactPerUnit: HabitImpact(choicesKept: 1),
    icon: Icons.fact_check_rounded,
  ),
  HabitTemplate(
    id: 'wait_24_hours',
    title: 'Wait 24 hours before a big purchase',
    category: HabitCategory.smartHabits,
    blurb: 'A day\'s wait is enough to tell a want from a need most of the time.',
    impactPerUnit: HabitImpact(moneySavedUsd: 25, choicesKept: 1),
    icon: Icons.hourglass_bottom_rounded,
  ),
  HabitTemplate(
    id: 'review_subscriptions',
    title: 'Review your subscriptions list',
    category: HabitCategory.smartHabits,
    blurb: 'A quick audit is the easiest way to find money you forgot you were spending.',
    impactPerUnit: HabitImpact(choicesKept: 1),
    icon: Icons.checklist_rounded,
  ),
  HabitTemplate(
    id: 'set_a_savings_goal',
    title: 'Set a savings goal for the week',
    category: HabitCategory.smartHabits,
    blurb: 'A number to aim for turns "save more" into something you can actually hit.',
    impactPerUnit: HabitImpact(choicesKept: 1),
    icon: Icons.flag_rounded,
  ),
];

/// A single node inside a [HabitChallenge] — same prerequisite-chain shape
/// as Academy's `Lesson` (a flat `List<String>` of ids), but kept as its
/// own type rather than reusing `Lesson`, which carries Academy-specific
/// baggage (age stages, quiz node types) that doesn't apply here.
@immutable
class ChallengeTask {
  const ChallengeTask({
    required this.id,
    required this.challengeId,
    required this.order,
    required this.templateId,
    this.prerequisites = const <String>[],
    this.resource,
  });

  final String id;
  final String challengeId;
  final int order;

  /// Links back to the catalog entry that supplies title/icon/impact.
  final String templateId;
  final List<String> prerequisites;

  /// A short "why this matters" line shown alongside the habit in the challenge.
  final String? resource;

  HabitTemplate? get template => habitById(templateId);
}

@immutable
class HabitChallenge {
  const HabitChallenge({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.tasks,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final HabitCategory category;
  final List<ChallengeTask> tasks;
}

const List<HabitChallenge> habitChallenges = <HabitChallenge>[
  HabitChallenge(
    id: 'challenge_cut_spending',
    title: 'Cut the Spending Leaks',
    subtitle: 'Find the money quietly slipping away',
    description:
        'A guided first pass at spending — four small habits that plug the '
        'most common leaks once they\'re routine.',
    category: HabitCategory.cutSpending,
    tasks: <ChallengeTask>[
      ChallengeTask(
        id: 'challenge_spend_1',
        challengeId: 'challenge_cut_spending',
        order: 1,
        templateId: 'cancel_unused_sub',
        resource: 'Forgotten subscriptions are one of the sneakiest budget leaks.',
      ),
      ChallengeTask(
        id: 'challenge_spend_2',
        challengeId: 'challenge_cut_spending',
        order: 2,
        templateId: 'skip_eating_out',
        prerequisites: <String>['challenge_spend_1'],
        resource: 'Eating out even once a week can outweigh a whole grocery budget.',
      ),
      ChallengeTask(
        id: 'challenge_spend_3',
        challengeId: 'challenge_cut_spending',
        order: 3,
        templateId: 'no_impulse_buy',
        prerequisites: <String>['challenge_spend_2'],
        resource: 'Impulse buys feel small in the moment and add up fast in a month.',
      ),
      ChallengeTask(
        id: 'challenge_spend_4',
        challengeId: 'challenge_cut_spending',
        order: 4,
        templateId: 'use_a_coupon',
        prerequisites: <String>['challenge_spend_3'],
        resource: 'A discount only counts if you remember to actually use it.',
      ),
    ],
  ),
  HabitChallenge(
    id: 'challenge_save_more',
    title: 'Build Your Savings',
    subtitle: 'Turn small habits into real savings',
    description:
        'Saving rarely happens by accident — this path builds four habits '
        'that make it automatic instead.',
    category: HabitCategory.saveMore,
    tasks: <ChallengeTask>[
      ChallengeTask(
        id: 'challenge_save_1',
        challengeId: 'challenge_save_more',
        order: 1,
        templateId: 'save_pocket_change',
        resource: 'Spare change only builds savings if it actually gets saved.',
      ),
      ChallengeTask(
        id: 'challenge_save_2',
        challengeId: 'challenge_save_more',
        order: 2,
        templateId: 'round_up_savings',
        prerequisites: <String>['challenge_save_1'],
        resource: 'Rounding up turns every purchase into a tiny savings deposit.',
      ),
      ChallengeTask(
        id: 'challenge_save_3',
        challengeId: 'challenge_save_more',
        order: 3,
        templateId: 'pack_lunch',
        prerequisites: <String>['challenge_save_2'],
        resource: 'Packed lunch money can go straight into savings instead.',
      ),
      ChallengeTask(
        id: 'challenge_save_4',
        challengeId: 'challenge_save_more',
        order: 4,
        templateId: 'set_aside_allowance',
        prerequisites: <String>['challenge_save_3'],
        resource: 'Paying yourself first is the single biggest lever in saving.',
      ),
    ],
  ),
  HabitChallenge(
    id: 'challenge_smart_habits',
    title: 'Think Before You Spend',
    subtitle: 'Build the habits behind good decisions',
    description:
        'The biggest money wins usually come from a pause, not a discount — '
        'these habits build that pause in.',
    category: HabitCategory.smartHabits,
    tasks: <ChallengeTask>[
      ChallengeTask(
        id: 'challenge_smart_1',
        challengeId: 'challenge_smart_habits',
        order: 1,
        templateId: 'track_every_expense',
        resource: 'You can\'t manage what you don\'t track.',
      ),
      ChallengeTask(
        id: 'challenge_smart_2',
        challengeId: 'challenge_smart_habits',
        order: 2,
        templateId: 'compare_prices',
        prerequisites: <String>['challenge_smart_1'],
        resource: 'A minute of comparing prices usually pays for itself.',
      ),
      ChallengeTask(
        id: 'challenge_smart_3',
        challengeId: 'challenge_smart_habits',
        order: 3,
        templateId: 'wait_24_hours',
        prerequisites: <String>['challenge_smart_2'],
        resource: 'A day\'s wait is usually enough to tell a want from a need.',
      ),
      ChallengeTask(
        id: 'challenge_smart_4',
        challengeId: 'challenge_smart_habits',
        order: 4,
        templateId: 'set_a_savings_goal',
        prerequisites: <String>['challenge_smart_3'],
        resource: 'A number to aim for turns "save more" into something real.',
      ),
    ],
  ),
];

HabitChallenge? habitChallengeById(String id) {
  for (final challenge in habitChallenges) {
    if (challenge.id == id) return challenge;
  }
  return null;
}

/// Fill stages for the savings jar, keyed off its own independent XP
/// counter (`habit_xp`) rather than the player's overall level — so the
/// jar reacts only to money-habit activity, not stock trades or quizzes.
enum JarStage {
  empty(0, 'Empty Jar', Icons.savings_outlined),
  started(60, 'Coin Jar', Icons.savings_rounded),
  halfFull(220, 'Full Wallet', Icons.account_balance_wallet_rounded),
  overflowing(600, 'Piggy Bank Pro', Icons.workspace_premium_rounded);

  const JarStage(this.xpThreshold, this.label, this.icon);

  final int xpThreshold;
  final String label;
  final IconData icon;

  static JarStage forXp(int xp) {
    var result = JarStage.empty;
    for (final stage in JarStage.values) {
      if (xp >= stage.xpThreshold) {
        result = stage;
      }
    }
    return result;
  }

  JarStage? get next {
    final index = JarStage.values.indexOf(this);
    final nextIndex = index + 1;
    return nextIndex < JarStage.values.length
        ? JarStage.values[nextIndex]
        : null;
  }

  /// 0..1 progress toward [next], or 1.0 if already at the final stage.
  double progressToNext(int xp) {
    final target = next;
    if (target == null) {
      return 1.0;
    }
    final span = target.xpThreshold - xpThreshold;
    if (span <= 0) {
      return 1.0;
    }
    return ((xp - xpThreshold) / span).clamp(0.0, 1.0);
  }
}

/// Mood is always derived from days since the last habit completion, never
/// stored — so it can never go stale or drift out of sync.
enum JarMood {
  onARoll('On a Roll', Color(0xFF4BD2A3)),
  steady('Steady', Color(0xFFF2C66D)),
  slipping('Slipping', Color(0xFFFF8474));

  const JarMood(this.label, this.color);

  final String label;
  final Color color;

  static JarMood forDaysSinceActive(int days) {
    if (days <= 1) return JarMood.onARoll;
    if (days <= 4) return JarMood.steady;
    return JarMood.slipping;
  }
}

/// Small date-key helpers shared by the weekly tracker and the calendar
/// heatmap, mirroring `DailyPlanController`'s local yyyy-mm-dd key format.
abstract final class HabitDateKeys {
  static String keyFor(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  static String todayKey([DateTime? now]) => keyFor(now ?? DateTime.now());

  /// The last [count] day keys, oldest first, ending today — the weekly
  /// tracker's 7 grid columns.
  static List<String> lastDayKeys(int count, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return List<String>.generate(
      count,
      (i) => keyFor(today.subtract(Duration(days: count - 1 - i))),
    );
  }

  static int daysSince(String? dateKey, {DateTime? now}) {
    if (dateKey == null || dateKey.isEmpty) {
      return 999;
    }
    final parsed = DateTime.tryParse(dateKey);
    if (parsed == null) {
      return 999;
    }
    final today = now ?? DateTime.now();
    return DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime(parsed.year, parsed.month, parsed.day)).inDays;
  }

  /// Drops every key older than [trailingDays] relative to [now]/today —
  /// keeps the weekly log and activity calendar from growing unboundedly.
  static Map<String, T> pruneToTrailing<T>(
    Map<String, T> source,
    int trailingDays, {
    DateTime? now,
  }) {
    final cutoff = (now ?? DateTime.now()).subtract(
      Duration(days: trailingDays),
    );
    final result = <String, T>{};
    for (final entry in source.entries) {
      final parsed = DateTime.tryParse(entry.key);
      if (parsed != null && !parsed.isBefore(cutoff)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}
