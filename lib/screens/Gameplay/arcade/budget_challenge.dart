import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers/user_stats_controller.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/game_toast.dart';

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

class BudgetChallengeScreen extends StatefulWidget {
  const BudgetChallengeScreen({super.key});

  @override
  State<BudgetChallengeScreen> createState() => _BudgetChallengeScreenState();
}

class _BudgetChallengeScreenState extends State<BudgetChallengeScreen> {
  static const int _budgetLimit = 120;
  static const List<_BudgetChoice> _choices = <_BudgetChoice>[
    _BudgetChoice(label: 'Groceries', cost: 35, essential: true),
    _BudgetChoice(label: 'Bus Pass', cost: 25, essential: true),
    _BudgetChoice(label: 'Medicine', cost: 18, essential: true),
    _BudgetChoice(label: 'School Supplies', cost: 22, essential: true),
    _BudgetChoice(label: 'Streaming', cost: 16, essential: false),
    _BudgetChoice(label: 'Sneakers', cost: 60, essential: false),
    _BudgetChoice(label: 'Takeout', cost: 24, essential: false),
    _BudgetChoice(label: 'Gaming Skin', cost: 12, essential: false),
  ];

  final Set<String> _selectedLabels = <String>{};
  bool _claiming = false;

  int get _spent => _selectedChoices.fold<int>(0, (sum, item) => sum + item.cost);
  int get _remaining => _budgetLimit - _spent;

  List<_BudgetChoice> get _selectedChoices => _choices
      .where((choice) => _selectedLabels.contains(choice.label))
      .toList(growable: false);

  int get _score {
    final essentialsPicked =
        _selectedChoices.where((choice) => choice.essential).length;
    final wantsPicked =
        _selectedChoices.where((choice) => !choice.essential).length;
    final budgetPenalty = _remaining < 0 ? _remaining.abs() : 0;
    return math.max(
      0,
      (essentialsPicked * 28) - (wantsPicked * 12) - budgetPenalty,
    );
  }

  void _toggleChoice(_BudgetChoice choice) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedLabels.contains(choice.label)) {
        _selectedLabels.remove(choice.label);
      } else {
        _selectedLabels.add(choice.label);
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

    if (_selectedLabels.isEmpty) {
      GameToast.show(
        context,
        title: 'Pick a few items first',
        message: 'Build a small budget before submitting the round.',
        icon: Icons.info_outline_rounded,
        accent: const Color(0xFFFFB084),
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
    );

    Navigator.of(context).pop(
      BudgetChallengeCloseResult(
        goldEarned: goldEarned,
        xpEarned: xpEarned,
        literacyPointsEarned: literacyEarned,
        score: _score,
        syncState: result.syncState,
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
        final shouldLeave = await _confirmExit();
        if (shouldLeave && mounted) {
          Navigator.of(context).pop();
        }
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
                      'Stay under $_budgetLimit gold, prioritize essentials, and avoid loading up on wants.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.45,
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
              ..._choices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BudgetChoiceTile(
                    choice: choice,
                    selected: _selectedLabels.contains(choice.label),
                    onTap: () => _toggleChoice(choice),
                  ),
                ),
              ),
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
    required this.label,
    required this.cost,
    required this.essential,
  });

  final String label;
  final int cost;
  final bool essential;
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
                    choice.essential ? 'Essential' : 'Want',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
