import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../services_backend_and_other_services/app_sound_service.dart';
import '../../../services_backend_and_other_services/supabase_service.dart';
import '../../../widgets_custom_lotties/custom_button.dart';
import '../../../widgets_custom_lotties/game_toast.dart';

const List<String> _essentialCategories = <String>[
  'Groceries',
  'Transit',
  'Medicine',
  'School Supplies',
];

class BudgetChallengeCloseResult {
  const BudgetChallengeCloseResult({
    required this.goldEarned,
    required this.xpEarned,
    required this.literacyPointsEarned,
    required this.score,
    required this.syncState,
  });

  final int goldEarned;
  final int xpEarned;
  final int literacyPointsEarned;
  final int score;
  final SyncState syncState;
}

class _BudgetChallengeSummaryData {
  const _BudgetChallengeSummaryData({
    required this.scenarioTitle,
    required this.score,
    required this.spent,
    required this.remaining,
    required this.goldEarned,
    required this.xpEarned,
    required this.literacyPointsEarned,
    required this.selectedChoices,
    required this.syncState,
  });

  final String scenarioTitle;
  final int score;
  final int spent;
  final int remaining;
  final int goldEarned;
  final int xpEarned;
  final int literacyPointsEarned;
  final List<_BudgetChoice> selectedChoices;
  final SyncState syncState;

  int get essentialsPicked =>
      selectedChoices.where((choice) => choice.essential).length;

  int get wantsPicked =>
      selectedChoices.where((choice) => !choice.essential).length;

  int get coveredCategories =>
      selectedChoices.map((choice) => choice.category).toSet().length;

  List<String> get missingEssentialCategories => _essentialCategories
      .where(
        (category) => !selectedChoices.any(
          (choice) => choice.essential && choice.category == category,
        ),
      )
      .toList(growable: false);

  bool get stayedUnderBudget => remaining >= 0;

  String get grade {
    if (score >= 110 && stayedUnderBudget && missingEssentialCategories.isEmpty) {
      return 'A';
    }
    if (score >= 85 && stayedUnderBudget && missingEssentialCategories.length <= 1) {
      return 'B';
    }
    if (score >= 55) {
      return 'C';
    }
    if (score >= 25) {
      return 'D';
    }
    return 'F';
  }

  String get headline {
    if (grade == 'A') {
      return 'Smart basket. Strong priorities.';
    }
    if (grade == 'B') {
      return 'Solid budgeting with room to tighten up.';
    }
    if (grade == 'C') {
      return 'Decent start, but some choices diluted the plan.';
    }
    if (grade == 'D') {
      return 'The basket drifted away from the essentials.';
    }
    return 'This round needs a reset on priorities.';
  }

  String get lesson {
    if (!stayedUnderBudget) {
      return 'Going over budget wipes out the value of premium picks fast. Lock in the essential categories first, then downgrade tiers before adding wants.';
    }
    if (missingEssentialCategories.isNotEmpty) {
      return 'Some essential categories were left uncovered. When money is tight, the goal is usually to cover every need at a lower tier before upgrading one category too far.';
    }
    if (wantsPicked > 0) {
      return 'A few wants made the basket harder to balance. Optional spending is not automatically wrong, but it should come after your essential categories are stabilized.';
    }
    if (remaining > 25) {
      return 'You kept a healthy cushion. That extra room can protect you from emergencies or let you upgrade one category more intentionally next round.';
    }
    return 'You made disciplined tradeoffs across the categories. That is what realistic budgeting usually looks like when income cannot support premium choices everywhere.';
  }

  String get nextTip {
    if (missingEssentialCategories.contains('Transit')) {
      return 'Commuting is easy to underestimate. Cover transport early so getting to work or school does not become its own financial problem.';
    }
    if (missingEssentialCategories.contains('Groceries')) {
      return 'Food should usually be one of the first categories covered. Even a basic groceries tier is stronger than skipping the category entirely.';
    }
    if (wantsPicked > 0) {
      return 'Try another round where you fill every essential category at the basic or standard tier first, then see whether any money is left for wants.';
    }
    return 'Next time, compare whether one premium upgrade was worth more than covering two standard-tier needs. That tradeoff is the core skill this challenge is training.';
  }
}

class BudgetChallengeScreen extends StatefulWidget {
  const BudgetChallengeScreen({super.key});

  @override
  State<BudgetChallengeScreen> createState() => _BudgetChallengeScreenState();
}

class _BudgetChallengeScreenState extends State<BudgetChallengeScreen> {
  static const List<_BudgetChoice> _choices = <_BudgetChoice>[
    _BudgetChoice(
      category: 'Groceries',
      label: 'Bare minimum groceries',
      tierLabel: 'Basic',
      description: 'Cheap staples and no extras.',
      cost: 20,
      essential: true,
      qualityScore: 1,
    ),
    _BudgetChoice(
      category: 'Groceries',
      label: 'Balanced groceries',
      tierLabel: 'Standard',
      description: 'A healthier weekly basket with better coverage.',
      cost: 34,
      essential: true,
      qualityScore: 2,
    ),
    _BudgetChoice(
      category: 'Groceries',
      label: 'Premium groceries',
      tierLabel: 'Premium',
      description: 'Higher-quality items and convenience buys.',
      cost: 52,
      essential: true,
      qualityScore: 3,
    ),
    _BudgetChoice(
      category: 'Transit',
      label: 'Basic commute plan',
      tierLabel: 'Basic',
      description: 'Bus fare or shared rides only when necessary.',
      cost: 12,
      essential: true,
      qualityScore: 1,
    ),
    _BudgetChoice(
      category: 'Transit',
      label: 'Monthly transit pass',
      tierLabel: 'Standard',
      description: 'Reliable transport for the whole month.',
      cost: 24,
      essential: true,
      qualityScore: 2,
    ),
    _BudgetChoice(
      category: 'Transit',
      label: 'Ride-share heavy commute',
      tierLabel: 'Premium',
      description: 'Fast and flexible, but much more expensive.',
      cost: 42,
      essential: true,
      qualityScore: 3,
    ),
    _BudgetChoice(
      category: 'Medicine',
      label: 'Generic medicine',
      tierLabel: 'Basic',
      description: 'Low-cost version that still covers the need.',
      cost: 14,
      essential: true,
      qualityScore: 1,
    ),
    _BudgetChoice(
      category: 'Medicine',
      label: 'Standard medicine plan',
      tierLabel: 'Standard',
      description: 'Reliable treatment with less compromise.',
      cost: 23,
      essential: true,
      qualityScore: 2,
    ),
    _BudgetChoice(
      category: 'Medicine',
      label: 'Brand-name medicine plan',
      tierLabel: 'Premium',
      description: 'Highest comfort, highest cost.',
      cost: 37,
      essential: true,
      qualityScore: 3,
    ),
    _BudgetChoice(
      category: 'School Supplies',
      label: 'Basic supplies bundle',
      tierLabel: 'Basic',
      description: 'Just enough to cover the essentials.',
      cost: 16,
      essential: true,
      qualityScore: 1,
    ),
    _BudgetChoice(
      category: 'School Supplies',
      label: 'Standard supplies bundle',
      tierLabel: 'Standard',
      description: 'More durable tools and fewer compromises.',
      cost: 26,
      essential: true,
      qualityScore: 2,
    ),
    _BudgetChoice(
      category: 'School Supplies',
      label: 'Premium supplies bundle',
      tierLabel: 'Premium',
      description: 'Branded extras and convenience upgrades.',
      cost: 41,
      essential: true,
      qualityScore: 3,
    ),
    _BudgetChoice(
      category: 'Entertainment',
      label: 'One low-cost subscription',
      tierLabel: 'Basic',
      description: 'A small optional treat that fits tight budgets better.',
      cost: 8,
      essential: false,
      qualityScore: 1,
    ),
    _BudgetChoice(
      category: 'Entertainment',
      label: 'Streaming bundle',
      tierLabel: 'Standard',
      description: 'More fun, but it starts competing with essentials.',
      cost: 16,
      essential: false,
      qualityScore: 2,
    ),
    _BudgetChoice(
      category: 'Entertainment',
      label: 'Premium entertainment plan',
      tierLabel: 'Premium',
      description: 'Several paid subscriptions and extras.',
      cost: 28,
      essential: false,
      qualityScore: 3,
    ),
    _BudgetChoice(
      category: 'Personal',
      label: 'Basic treat purchase',
      tierLabel: 'Basic',
      description: 'A small want that does not sink the plan by itself.',
      cost: 10,
      essential: false,
      qualityScore: 1,
    ),
    _BudgetChoice(
      category: 'Personal',
      label: 'Standard personal splurge',
      tierLabel: 'Standard',
      description: 'Looks affordable until the essential gaps show up.',
      cost: 22,
      essential: false,
      qualityScore: 2,
    ),
    _BudgetChoice(
      category: 'Personal',
      label: 'Premium splurge',
      tierLabel: 'Premium',
      description: 'A flashy want that heavily crowds out needs.',
      cost: 40,
      essential: false,
      qualityScore: 3,
    ),
  ];
  static const List<_BudgetScenario> _scenarios = <_BudgetScenario>[
    _BudgetScenario(
      title: 'Reduced Hours Week',
      description:
          'Your paycheck came in short this week, so you need to stretch every dollar across the essentials.',
      budgetLimit: 96,
    ),
    _BudgetScenario(
      title: 'Unexpected Co-Pay',
      description:
          'A surprise health expense took part of your budget before shopping even started.',
      budgetLimit: 92,
    ),
    _BudgetScenario(
      title: 'Textbook Month',
      description:
          'School costs are hitting harder than usual, so upgrades in one category may force cuts somewhere else.',
      budgetLimit: 98,
    ),
  ];

  final Map<String, String> _selectedByCategory = <String, String>{};
  late final _BudgetScenario _scenario;
  bool _claiming = false;

  int get _budgetLimit => _scenario.budgetLimit;
  int get _spent => _selectedChoices.fold<int>(0, (sum, item) => sum + item.cost);
  int get _remaining => _budgetLimit - _spent;

  List<_BudgetChoice> get _selectedChoices => _choices
      .where((choice) => _selectedByCategory[choice.category] == choice.label)
      .toList(growable: false);

  List<String> get _categories => _choices
      .map((choice) => choice.category)
      .toSet()
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _scenario = _scenarios[math.Random().nextInt(_scenarios.length)];
  }

  int get _score {
    final essentialChoices =
        _selectedChoices.where((choice) => choice.essential).toList();
    final wantChoices =
        _selectedChoices.where((choice) => !choice.essential).toList();
    final missedEssentials = _essentialCategories
        .where(
          (category) => !essentialChoices.any(
            (choice) => choice.category == category,
          ),
        )
        .length;
    final essentialValue = essentialChoices.fold<int>(
      0,
      (sum, choice) => sum + 12 + (choice.qualityScore * 12),
    );
    final wantPenalty = wantChoices.fold<int>(
      0,
      (sum, choice) => sum + 8 + (choice.qualityScore * 8),
    );
    final budgetPenalty = _remaining < 0 ? _remaining.abs() * 2 : 0;
    final allEssentialBonus = missedEssentials == 0 ? 14 : 0;

    return math.max(
      0,
      essentialValue - wantPenalty - budgetPenalty - (missedEssentials * 30) + allEssentialBonus,
    );
  }

  void _toggleChoice(_BudgetChoice choice) {
    HapticFeedback.selectionClick();
    AppSoundService.play(AppSoundEffect.selection);
    setState(() {
      if (_selectedByCategory[choice.category] == choice.label) {
        _selectedByCategory.remove(choice.category);
      } else {
        _selectedByCategory[choice.category] = choice.label;
      }
    });
  }

  Future<bool> _confirmExit() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF163729),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Leave Budget Challenge?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Your current picks will be lost if you leave now.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _submitBudget() async {
    if (_claiming) {
      return;
    }

    if (_selectedByCategory.isEmpty) {
      GameToast.show(
        context,
        title: 'Pick a few items first',
        message: 'Build a small budget before submitting the round.',
        icon: Icons.info_outline_rounded,
        accent: const Color(0xFFFFB084),
        soundEffect: AppSoundEffect.error,
      );
      return;
    }

    setState(() => _claiming = true);

    final goldEarned = math.max(24, 30 + (_score ~/ 3));
    final xpEarned = math.max(20, 24 + (_score ~/ 2));
    final literacyEarned = math.max(10, 12 + (_score ~/ 5));

    final result = await context.read<UserStatsController>().applyChallengePayload(
      <String, dynamic>{
        'status': 'completed',
        'gold_earned': goldEarned,
        'xp_earned': xpEarned,
        'literacy_points_earned': literacyEarned,
        'title': 'Budget Challenge Rewards',
        'description':
            'Completed a spending-priority round and synced the rewards.',
      },
    );

    if (!mounted) {
      return;
    }

    GameToast.show(
      context,
      title: 'Budget locked in',
      message: '+$goldEarned gold • +$xpEarned XP • ${result.message}',
      icon: Icons.check_circle_rounded,
      accent: const Color(0xFF78C69B),
      soundEffect: AppSoundEffect.celebration,
    );

    final summary = _BudgetChallengeSummaryData(
      scenarioTitle: _scenario.title,
      score: _score,
      spent: _spent,
      remaining: _remaining,
      goldEarned: goldEarned,
      xpEarned: xpEarned,
      literacyPointsEarned: literacyEarned,
      selectedChoices: List<_BudgetChoice>.from(_selectedChoices),
      syncState: result.syncState,
    );

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<BudgetChallengeCloseResult>(
        builder: (_) => _BudgetChallengeSummaryScreen(summary: summary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final navigator = Navigator.of(context);
        final shouldLeave = await _confirmExit();
        if (!mounted || !shouldLeave) {
          return;
        }
        navigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF071711),
        appBar: AppBar(
          backgroundColor: const Color(0xFF071711),
          foregroundColor: Colors.white,
          title: const Text('Budget Challenge'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF78C69B).withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Build a smart basket',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scenario: ${_scenario.title}. Stay under $_budgetLimit gold, cover each essential category, and expect that premium options will crowd something else out.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF78C69B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF78C69B).withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        _scenario.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.76),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _BudgetBadge(
                          label: 'Spent',
                          value: '$_spent',
                          accent: const Color(0xFFFFD45C),
                        ),
                        _BudgetBadge(
                          label: 'Remaining',
                          value: '$_remaining',
                          accent: _remaining >= 0
                              ? const Color(0xFF78C69B)
                              : const Color(0xFFFF8A80),
                        ),
                        _BudgetBadge(
                          label: 'Score',
                          value: '$_score',
                          accent: const Color(0xFF6CB6DA),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ..._categories.map((category) {
                final categoryChoices = _choices
                    .where((choice) => choice.category == category)
                    .toList(growable: false);
                final selectedLabel = _selectedByCategory[category];
                final isEssential = categoryChoices.first.essential;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BudgetCategoryCard(
                    title: category,
                    subtitle: isEssential
                        ? 'Pick one tier only. Mixing basic and standard choices is usually the only way to cover all needs.'
                        : 'Optional category. Add it only if your essential categories are already protected.',
                    accent: isEssential
                        ? const Color(0xFF78C69B)
                        : const Color(0xFFFFB084),
                    children: categoryChoices
                        .map(
                          (choice) => Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _BudgetChoiceTile(
                              choice: choice,
                              selected: selectedLabel == choice.label,
                              onTap: () => _toggleChoice(choice),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                );
              }),
              const SizedBox(height: 8),
              CustomButton(
                label: 'Submit Budget',
                isLoading: _claiming,
                onPressed: _submitBudget,
                prefixIcon: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF103225),
                ),
                style: const CustomButtonStyle.primary(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetChoice {
  const _BudgetChoice({
    required this.category,
    required this.label,
    required this.tierLabel,
    required this.description,
    required this.cost,
    required this.essential,
    required this.qualityScore,
  });

  final String category;
  final String label;
  final String tierLabel;
  final String description;
  final int cost;
  final bool essential;
  final int qualityScore;
}

class _BudgetScenario {
  const _BudgetScenario({
    required this.title,
    required this.description,
    required this.budgetLimit,
  });

  final String title;
  final String description;
  final int budgetLimit;
}

class _BudgetBadge extends StatelessWidget {
  const _BudgetBadge({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetChoiceTile extends StatelessWidget {
  const _BudgetChoiceTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _BudgetChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = choice.essential
        ? const Color(0xFF78C69B)
        : const Color(0xFFFFB084);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.48)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                choice.essential
                    ? Icons.checkroom_rounded
                    : Icons.shopping_bag_rounded,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    choice.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${choice.tierLabel} • ${choice.essential ? 'Essential' : 'Optional'}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    choice.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.66),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${choice.cost}g',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? accent : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  const _BudgetCategoryCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.children,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              height: 1.45,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _BudgetChallengeSummaryScreen extends StatelessWidget {
  const _BudgetChallengeSummaryScreen({
    required this.summary,
  });

  final _BudgetChallengeSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final accent = summary.grade == 'A' || summary.grade == 'B'
        ? const Color(0xFF78C69B)
        : summary.grade == 'C'
            ? const Color(0xFFFFD45C)
            : const Color(0xFFFF8A80);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF071711),
        appBar: AppBar(
          backgroundColor: const Color(0xFF071711),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: const Text('Budget Summary'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: accent.withValues(alpha: 0.26)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grade ${summary.grade}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      summary.scenarioTitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.64),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      summary.headline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      summary.lesson,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.74),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _BudgetBadge(
                          label: 'Score',
                          value: '${summary.score}',
                          accent: accent,
                        ),
                        _BudgetBadge(
                          label: 'Spent',
                          value: '${summary.spent}',
                          accent: const Color(0xFFFFD45C),
                        ),
                        _BudgetBadge(
                          label: 'Left',
                          value: '${summary.remaining}',
                          accent: summary.stayedUnderBudget
                              ? const Color(0xFF78C69B)
                              : const Color(0xFFFF8A80),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _BudgetBadge(
                      label: 'Covered Needs',
                      value: '${summary.essentialsPicked}',
                      accent: const Color(0xFF78C69B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BudgetBadge(
                      label: 'Optional Picks',
                      value: '${summary.wantsPicked}',
                      accent: const Color(0xFFFFB084),
                    ),
                  ),
                ],
              ),
              if (summary.missingEssentialCategories.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SummaryPanel(
                  title: 'Missing Essential Categories',
                  icon: Icons.warning_amber_rounded,
                  accent: const Color(0xFFFF8A80),
                  child: Text(
                    summary.missingEssentialCategories.join(' • '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _SummaryPanel(
                title: 'What You Chose',
                icon: Icons.shopping_basket_rounded,
                accent: const Color(0xFF6CB6DA),
                child: Column(
                  children: summary.selectedChoices
                      .map(
                        (choice) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Icon(
                                choice.essential
                                    ? Icons.check_circle_rounded
                                    : Icons.remove_circle_outline_rounded,
                                color: choice.essential
                                    ? const Color(0xFF78C69B)
                                    : const Color(0xFFFFB084),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${choice.category}: ${choice.label}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${choice.tierLabel} tier',
                                      style: TextStyle(
                                        color: (choice.essential
                                                ? const Color(0xFF78C69B)
                                                : const Color(0xFFFFB084))
                                            .withValues(alpha: 0.92),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${choice.cost}g',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 14),
              _SummaryPanel(
                title: 'Next Time',
                icon: Icons.lightbulb_rounded,
                accent: const Color(0xFFFFD45C),
                child: Text(
                  summary.nextTip,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SummaryPanel(
                title: 'Rewards Earned',
                icon: Icons.workspace_premium_rounded,
                accent: const Color(0xFF78C69B),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '+${summary.goldEarned} gold • +${summary.xpEarned} XP • +${summary.literacyPointsEarned} literacy',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary.syncState.message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: 'Finish Challenge',
                onPressed: () {
                  Navigator.of(context).pop(
                    BudgetChallengeCloseResult(
                      goldEarned: summary.goldEarned,
                      xpEarned: summary.xpEarned,
                      literacyPointsEarned: summary.literacyPointsEarned,
                      score: summary.score,
                      syncState: summary.syncState,
                    ),
                  );
                },
                prefixIcon: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF103225),
                ),
                style: const CustomButtonStyle.primary(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

