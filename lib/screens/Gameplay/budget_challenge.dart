import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_toast.dart';

class BudgetChallengeCloseResult {
  const BudgetChallengeCloseResult({
    required this.goldEarned,
    required this.xpEarned,
    required this.literacyPointsEarned,
    required this.totalSpent,
    required this.totalValue,
    required this.finalScore,
    required this.level,
    required this.syncState,
  });

  final int goldEarned;
  final int xpEarned;
  final int literacyPointsEarned;
  final int totalSpent;
  final int totalValue;
  final int finalScore;
  final int level;
  final SyncState syncState;
}

class BudgetChallengeScreen extends StatefulWidget {
  const BudgetChallengeScreen({super.key, this.level = 1});

  final int level;

  @override
  State<BudgetChallengeScreen> createState() => _BudgetChallengeScreenState();
}

class _BudgetChallengeScreenState extends State<BudgetChallengeScreen>
    with TickerProviderStateMixin {
  static const Color _background = Color(0xFF071711);
  static const Color _surface = Color(0xFF123427);
  static const Color _surface2 = Color(0xFF1A4D3D);
  static const Color _accent = Color(0xFF85EFAC);
  static const Color _gold = Color(0xFFFFD45C);
  static const Color _good = Color(0xFF56D27B);
  static const Color _risky = Color(0xFFFFB74D);
  static const Color _bad = Color(0xFFFF7B72);

  late final AnimationController _timerController;
  late final AnimationController _pulseController;
  final math.Random _random = math.Random();

  Timer? _gameTimer;
  late List<_ItemCategory> _categories;
  final Map<String, int> _selectedOptions = <String, int>{};

  int _timeLeft = 0;
  bool _gameStarted = false;
  bool _gameEnded = false;
  bool _isSaving = false;
  bool _panicMode = false;

  int _totalSpent = 0;
  int _totalValue = 0;
  int _essentialCount = 0;
  int _selectedCount = 0;
  int _timeBonus = 0;
  int _budgetPenalty = 0;
  int _essentialPenalty = 0;
  int _balanceBonus = 0;
  int _finalScore = 0;

  String? _liveMessage;
  Color _liveMessageColor = Colors.white70;
  BudgetChallengeCloseResult? _projectedResult;

  int get _budget => math.max(26, 50 - ((widget.level - 1) * 6));
  int get _timeLimit => 35;
  int get _requiredEssentials =>
      _categories.where((category) => category.isEssential).length;

  @override
  void initState() {
    super.initState();
    _buildCategories();
    _timeLeft = _timeLimit;
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _timeLimit),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
    _recalculateStats();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _timerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _buildCategories() {
    int vary(int base, [int spread = 2]) => base + _random.nextInt(spread);

    _categories = <_ItemCategory>[
      _ItemCategory(
        name: 'Milk',
        icon: Icons.local_drink_rounded,
        isEssential: true,
        description: 'Pick a carton that balances nutrition and price.',
        options: <_ItemOption>[
          _ItemOption(
            name: 'Store Brand',
            price: vary(3),
            value: 4,
            note: 'Cheapest, but basic quality.',
          ),
          _ItemOption(
            name: 'Premium Brand',
            price: vary(5),
            value: 7,
            note: 'Better quality for a moderate jump.',
          ),
          _ItemOption(
            name: 'Organic',
            price: vary(7),
            value: 10,
            note: 'Highest quality, but expensive.',
          ),
        ],
      ),
      _ItemCategory(
        name: 'Bread',
        icon: Icons.bakery_dining_rounded,
        isEssential: true,
        description: 'The wrong pick can waste value fast.',
        options: <_ItemOption>[
          _ItemOption(
            name: 'White Bread',
            price: vary(2),
            value: 3,
            note: 'Low-cost, low-value.',
          ),
          _ItemOption(
            name: 'Whole Wheat',
            price: vary(3),
            value: 6,
            note: 'Efficient and balanced.',
          ),
          _ItemOption(
            name: 'Artisan Loaf',
            price: vary(6),
            value: 9,
            note: 'Strong value, but can strain the budget.',
          ),
        ],
      ),
      _ItemCategory(
        name: 'Eggs',
        icon: Icons.egg_alt_rounded,
        isEssential: true,
        description: 'A strong value category if you shop smart.',
        options: <_ItemOption>[
          _ItemOption(
            name: 'Dozen Eggs',
            price: vary(4),
            value: 5,
            note: 'Safe baseline choice.',
          ),
          _ItemOption(
            name: 'Organic Eggs',
            price: vary(6),
            value: 8,
            note: 'Good value if budget allows.',
          ),
          _ItemOption(
            name: 'Free Range',
            price: vary(8),
            value: 11,
            note: 'High quality, risky when funds are tight.',
          ),
        ],
      ),
      _ItemCategory(
        name: 'Apples',
        icon: Icons.apple_rounded,
        isEssential: false,
        description: 'Optional item. Can help your score, or drain the budget.',
        options: <_ItemOption>[
          _ItemOption(
            name: 'Skip',
            price: 0,
            value: 0,
            note: 'No spend, no value.',
          ),
          _ItemOption(
            name: 'Bag of Apples',
            price: vary(3),
            value: 5,
            note: 'Efficient optional add-on.',
          ),
          _ItemOption(
            name: 'Premium Fruit Pack',
            price: vary(6),
            value: 8,
            note: 'Useful, but easy to overspend on.',
          ),
        ],
      ),
      _ItemCategory(
        name: 'Cheese',
        icon: Icons.lunch_dining_rounded,
        isEssential: false,
        description: 'Optional item with strong value swings.',
        options: <_ItemOption>[
          _ItemOption(
            name: 'Skip',
            price: 0,
            value: 0,
            note: 'Save every dollar.',
          ),
          _ItemOption(
            name: 'Cheddar',
            price: vary(4),
            value: 6,
            note: 'Solid optional pickup.',
          ),
          _ItemOption(
            name: 'Gourmet Cheese',
            price: vary(7),
            value: 9,
            note: 'Big value, but high risk.',
          ),
        ],
      ),
    ];
  }

  void _startGame() {
    HapticFeedback.lightImpact();
    _gameTimer?.cancel();
    _timerController
      ..reset()
      ..forward();

    setState(() {
      _selectedOptions.clear();
      _buildCategories();
      _timeLeft = _timeLimit;
      _gameStarted = true;
      _gameEnded = false;
      _panicMode = false;
      _isSaving = false;
      _projectedResult = null;
      _liveMessage = 'Build a high-value cart without blowing the budget.';
      _liveMessageColor = Colors.white70;
      _recalculateStats();
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_gameStarted || _gameEnded) {
        timer.cancel();
        return;
      }

      setState(() {
        _timeLeft -= 1;
        if (_timeLeft <= 5 && !_panicMode) {
          _panicMode = true;
          HapticFeedback.mediumImpact();
        }
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          _finishRound();
        }
      });
    });
  }

  void _selectOption(_ItemCategory category, int optionIndex) {
    if (!_gameStarted || _gameEnded) {
      return;
    }

    final _ItemOption option = category.options[optionIndex];

    setState(() {
      _selectedOptions[category.name] = optionIndex;
      _recalculateStats();
      final _ChoiceFeedback feedback = _feedbackForOption(category, option);
      _liveMessage = feedback.message;
      _liveMessageColor = feedback.color;
    });

    if (_liveMessageColor == _good) {
      HapticFeedback.selectionClick();
    } else if (_liveMessageColor == _risky) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _recalculateStats() {
    _totalSpent = 0;
    _totalValue = 0;
    _essentialCount = 0;
    _selectedCount = 0;

    for (final _ItemCategory category in _categories) {
      final int? selectedIndex = _selectedOptions[category.name];
      if (selectedIndex == null) {
        continue;
      }
      final _ItemOption option = category.options[selectedIndex];
      _selectedCount += 1;
      _totalSpent += option.price;
      _totalValue += option.value;
      if (category.isEssential && option.price > 0) {
        _essentialCount += 1;
      }
    }
  }

  void _finishRound() {
    if (_gameEnded) {
      return;
    }

    _gameTimer?.cancel();
    _timerController.stop();

    _recalculateStats();

    _timeBonus = _timeLeft * 2;
    _budgetPenalty = _totalSpent > _budget ? (_totalSpent - _budget) * 4 : 0;
    _essentialPenalty = _essentialCount < _requiredEssentials
        ? (_requiredEssentials - _essentialCount) * 18
        : 0;

    final bool selectedAllEssentials = _essentialCount == _requiredEssentials;
    final bool underBudget = _totalSpent <= _budget;
    final int optionalSelections = _categories
        .where((category) => !category.isEssential)
        .where((category) {
          final int? index = _selectedOptions[category.name];
          return index != null && category.options[index].price > 0;
        })
        .length;

    _balanceBonus = 0;
    if (selectedAllEssentials && underBudget) {
      _balanceBonus += 12;
    }
    if (_totalValue >= (_totalSpent + 8)) {
      _balanceBonus += 8;
    }
    if (optionalSelections == 1 && underBudget) {
      _balanceBonus += 4;
    }

    _finalScore =
        (_totalValue * 3) - (_totalSpent * 2) + _timeBonus + _balanceBonus;
    _finalScore -= _budgetPenalty + _essentialPenalty;

    final bool strongRun = selectedAllEssentials && underBudget && _finalScore >= 35;
    final int goldEarned = math.max(10, 20 + (_finalScore ~/ 3));
    final int xpEarned = math.max(8, 12 + (_finalScore ~/ 4));
    final int literacyEarned = strongRun ? 12 : 6;

    _projectedResult = BudgetChallengeCloseResult(
      goldEarned: goldEarned,
      xpEarned: xpEarned,
      literacyPointsEarned: literacyEarned,
      totalSpent: _totalSpent,
      totalValue: _totalValue,
      finalScore: _finalScore,
      level: widget.level,
      syncState: const SyncState(
        synced: false,
        usedCache: true,
        message: 'Projected rewards',
      ),
    );

    setState(() {
      _gameEnded = true;
      _liveMessage = strongRun
          ? 'Great run. You balanced speed, value, and budget.'
          : underBudget
              ? 'Not bad. Improve value efficiency next round.'
              : 'You overspent. Trim risky upgrades next round.';
      _liveMessageColor = strongRun
          ? _good
          : underBudget
              ? _risky
              : _bad;
    });
  }

  Future<void> _claimRewardsAndExit() async {
    final BudgetChallengeCloseResult? projected = _projectedResult;
    if (projected == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final bool success = _totalSpent <= _budget && _essentialCount == _requiredEssentials;

    try {
      final UserStatsController controller = context.read<UserStatsController>();
      final actionResult = await controller.applyChallengePayload(<String, Object>{
        'gold_earned': projected.goldEarned,
        'xp_earned': projected.xpEarned,
        'literacy_points_earned': projected.literacyPointsEarned,
        'title': 'Budget Challenge Reward',
        'description': success
            ? 'You built a smart cart under pressure.'
            : 'Challenge completed. Review your choices and improve your cart.',
      });

      if (!mounted) {
        return;
      }

      GameToast.show(
        context,
        title: success ? 'Smart Cart!' : 'Round Logged',
        message:
            '+${projected.goldEarned} gold • +${projected.xpEarned} XP • ${actionResult.message}',
        icon: success
            ? Icons.shopping_basket_rounded
            : Icons.receipt_long_rounded,
        accent: _accent,
      );

      Navigator.of(context).pop(
        BudgetChallengeCloseResult(
          goldEarned: projected.goldEarned,
          xpEarned: projected.xpEarned,
          literacyPointsEarned: projected.literacyPointsEarned,
          totalSpent: projected.totalSpent,
          totalValue: projected.totalValue,
          finalScore: projected.finalScore,
          level: projected.level,
          syncState: actionResult.syncState,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      GameToast.show(
        context,
        title: 'Save failed',
        message: 'Reward sync failed. Try again in a moment.',
        icon: Icons.cloud_off_rounded,
        accent: _bad,
      );
    }
  }

  _ChoiceFeedback _feedbackForOption(_ItemCategory category, _ItemOption option) {
    if (option.price == 0) {
      return const _ChoiceFeedback(
        message: 'Skipping preserves budget, but adds no value.',
        color: Color(0xFFFFB74D),
      );
    }

    final double efficiency = option.value / option.price;
    final bool riskyForBudget = (_totalSpent > _budget);

    if (category.isEssential && efficiency >= 1.7 && !riskyForBudget) {
      return _ChoiceFeedback(
        message: '${option.name} is a strong essential value pick.',
        color: _good,
      );
    }
    if (riskyForBudget || efficiency < 1.1) {
      return _ChoiceFeedback(
        message: '${option.name} is flashy, but weak for this budget.',
        color: _bad,
      );
    }
    return _ChoiceFeedback(
      message: '${option.name} is viable, but watch the remaining budget.',
      color: _risky,
    );
  }

  String _gradeLabel() {
    if (_finalScore >= 55) {
      return 'Financial Strategist';
    }
    if (_finalScore >= 35) {
      return 'Smart Saver';
    }
    if (_finalScore >= 15) {
      return 'Budget Builder';
    }
    return 'Needs More Balance';
  }

  Future<bool> _confirmExit() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: const Color(0xFF214C3D),
              title: const Text(
                'Exit Budget Challenge?',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Leaving now will end the current round.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? result) async {
      if (didPop) {
        return;
      }
      final bool shouldPop = await _confirmExit();
      if (shouldPop && mounted) {
        Navigator.of(context).pop(result);
      }
    },
    child: Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Budget Challenge'),
        backgroundColor: _surface2,
        foregroundColor: Colors.white,
        actions: <Widget>[
          if (_gameStarted && !_gameEnded)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (BuildContext context, Widget? child) {
                    final bool danger = _panicMode;
                    final double scale =
                        danger ? 1 + (_pulseController.value * 0.05) : 1;

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: danger
                              ? _bad.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: danger
                                ? _bad
                                : Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.timer_rounded,
                              size: 15,
                              color: danger ? _bad : Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_timeLeft',
                              style: TextStyle(
                                color: danger ? _bad : Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              if (!_gameStarted) _buildStartScreen() else _buildGameScreen(),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStartScreen() {
    return Expanded(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF123427), Color(0xFF0D241C)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _accent.withValues(alpha: 0.10),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_checkout_rounded,
                      color: _accent,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        Text(
                          'Build the smartest cart.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Fast decisions. Real tradeoffs. Better rewards.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _InfoPill(icon: Icons.savings_rounded, label: 'Budget \$$_budget'),
                  _InfoPill(icon: Icons.timer_rounded, label: '$_timeLimit seconds'),
                  _InfoPill(icon: Icons.star_rounded, label: 'Value > Price wins'),
                  _InfoPill(icon: Icons.bolt_rounded, label: 'Time bonus active'),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: const <Widget>[
                    _StartFeatureRow(
                      icon: Icons.check_circle_rounded,
                      title: 'Essentials matter',
                      subtitle: 'You must cover every essential category to avoid heavy penalties.',
                    ),
                    SizedBox(height: 14),
                    _StartFeatureRow(
                      icon: Icons.auto_graph_rounded,
                      title: 'Cheapest is not always best',
                      subtitle: 'Higher-cost options can still be smart if their value is strong enough.',
                    ),
                    SizedBox(height: 14),
                    _StartFeatureRow(
                      icon: Icons.insights_rounded,
                      title: 'Live feedback',
                      subtitle: 'Every tap updates your budget, score pressure, and strategy hint.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CustomButton(
                      label: 'Start Challenge',
                      onPressed: _startGame,
                      prefixIcon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFF103225),
                      ),
                      style: const CustomButtonStyle.primary(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final double budgetRatio = (_totalSpent / _budget).clamp(0.0, 1.3);
    final int remaining = _budget - _totalSpent;

    return Expanded(
      child: Column(
        children: <Widget>[
          _buildTopStats(budgetRatio, remaining),
          const SizedBox(height: 12),
          _buildLiveFeedbackCard(),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: <Widget>[
                ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _categories.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildCategoryCard(_categories[index]);
                  },
                ),
                if (_gameEnded)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.34),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      child: _buildSummaryCard(),
                    ),
                  ),
              ],
            ),
          ),
          if (!_gameEnded) ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'Finish Round',
                onPressed: _finishRound,
                prefixIcon: const Icon(
                  Icons.flag_rounded,
                  color: Color(0xFF103225),
                ),
                style: const CustomButtonStyle.primary(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopStats(double budgetRatio, int remaining) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  label: 'Budget',
                  value: '\$$_budget',
                  icon: Icons.account_balance_wallet_rounded,
                  accent: _accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Spent',
                  value: '\$$_totalSpent',
                  icon: Icons.shopping_bag_rounded,
                  accent: _totalSpent > _budget ? _bad : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Value',
                  value: '$_totalValue',
                  icon: Icons.auto_awesome_rounded,
                  accent: _gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: budgetRatio > 1 ? 1 : budgetRatio,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                remaining >= 10
                    ? _good
                    : remaining >= 0
                        ? _risky
                        : _bad,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text(
                remaining >= 0
                    ? '\$$remaining left'
                    : '\$${remaining.abs()} over budget',
                style: TextStyle(
                  color: remaining >= 0 ? Colors.white70 : _bad,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Essentials: $_essentialCount / $_requiredEssentials',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveFeedbackCard() {
    final int scorePreview = (_totalValue * 3) - (_totalSpent * 2);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.tips_and_updates_rounded, color: _liveMessageColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _liveMessage ?? 'Select items to see live strategy feedback.',
                  style: TextStyle(
                    color: _liveMessageColor,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _MiniMetric(label: 'Preview', value: '$scorePreview'),
              _MiniMetric(label: 'Time Bonus', value: '+${_timeLeft * 2}'),
              _MiniMetric(label: 'Selected', value: '$_selectedCount/${_categories.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_ItemCategory category) {
    final int? selectedIndex = _selectedOptions[category.name];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF183D30),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(category.icon, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (category.isEssential) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Essential',
                              style: TextStyle(
                                color: Color(0xFF103225),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List<Widget>.generate(category.options.length, (int index) {
            final _ItemOption option = category.options[index];
            final bool selected = selectedIndex == index;
            final double efficiency = option.price == 0 ? 0 : option.value / option.price;
            final Color borderColor = selected
                ? _accent
                : efficiency >= 1.6
                    ? _good.withValues(alpha: 0.55)
                    : efficiency < 1.1 && option.price > 0
                        ? _bad.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.08);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _selectOption(category, index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? _accent.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
                  ),
                  child: Row(
                    children: <Widget>[
                      Radio<int>(
                        value: index,
                        groupValue: selectedIndex,
                        activeColor: _accent,
                        onChanged: (_) => _selectOption(category, index),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    option.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '\$${option.price}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.note,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                _OptionTag(label: 'Value ${option.value}', color: _gold),
                                _OptionTag(
                                  label: option.price == 0
                                      ? 'Efficiency —'
                                      : 'Efficiency ${efficiency.toStringAsFixed(1)}',
                                  color: efficiency >= 1.6
                                      ? _good
                                      : efficiency < 1.1 && option.price > 0
                                          ? _bad
                                          : _risky,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final BudgetChallengeCloseResult? projected = _projectedResult;
    if (projected == null) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 470),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF113528),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.insights_rounded, color: _accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Round Summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _gradeLabel(),
                        style: TextStyle(
                          color: _liveMessageColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _SummaryChip(label: 'Spent', value: '\$$_totalSpent', accent: Colors.white),
                _SummaryChip(label: 'Value', value: '$_totalValue', accent: _gold),
                _SummaryChip(label: 'Score', value: '$_finalScore', accent: _accent),
              ],
            ),
            const SizedBox(height: 16),
            _ScoreRow(label: 'Value score', value: '+${_totalValue * 3}', color: _good),
            _ScoreRow(label: 'Spend cost', value: '-${_totalSpent * 2}', color: _bad),
            _ScoreRow(label: 'Time bonus', value: '+$_timeBonus', color: _gold),
            _ScoreRow(label: 'Balance bonus', value: '+$_balanceBonus', color: _accent),
            _ScoreRow(label: 'Budget penalty', value: '-$_budgetPenalty', color: _bad),
            _ScoreRow(label: 'Essential penalty', value: '-$_essentialPenalty', color: _bad),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Projected rewards',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _RewardStat(
                          label: 'Gold',
                          value: '+${projected.goldEarned}',
                          accent: _gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RewardStat(
                          label: 'XP',
                          value: '+${projected.xpEarned}',
                          accent: _accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RewardStat(
                          label: 'Literacy',
                          value: '+${projected.literacyPointsEarned}',
                          accent: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _startGame,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Play Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: _isSaving ? 'Saving...' : 'Claim & Return',
                    onPressed: _isSaving
                      ? null
                      : () async {
                          await _claimRewardsAndExit();
                        },
                    prefixIcon: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF103225),
                    ),
                    style: const CustomButtonStyle.primary(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCategory {
  const _ItemCategory({
    required this.name,
    required this.icon,
    required this.isEssential,
    required this.description,
    required this.options,
  });

  final String name;
  final IconData icon;
  final bool isEssential;
  final String description;
  final List<_ItemOption> options;
}

class _ItemOption {
  const _ItemOption({
    required this.name,
    required this.price,
    required this.value,
    required this.note,
  });

  final String name;
  final int price;
  final int value;
  final String note;
}

class _ChoiceFeedback {
  const _ChoiceFeedback({required this.message, required this.color});

  final String message;
  final Color color;
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: _BudgetChallengeScreenState._gold, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartFeatureRow extends StatelessWidget {
  const _StartFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _BudgetChallengeScreenState._accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _BudgetChallengeScreenState._accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OptionTag extends StatelessWidget {
  const _OptionTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardStat extends StatelessWidget {
  const _RewardStat({
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
