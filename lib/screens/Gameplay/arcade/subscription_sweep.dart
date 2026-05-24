import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers/user_stats_controller.dart';
import '../../../services/supabase_service.dart';

class SubscriptionSweepCloseResult {
  const SubscriptionSweepCloseResult({
    required this.goldEarned,
    required this.xpEarned,
    required this.literacyPointsEarned,
    required this.finalBalance,
    required this.finalHappiness,
    required this.syncState,
  });

  final int goldEarned;
  final int xpEarned;
  final int literacyPointsEarned;
  final int finalBalance;
  final int finalHappiness;
  final SyncState syncState;
}

class SubscriptionSweepScreen extends StatefulWidget {
  const SubscriptionSweepScreen({super.key});

  @override
  State<SubscriptionSweepScreen> createState() =>
      _SubscriptionSweepScreenState();
}

class _SubscriptionSweepScreenState extends State<SubscriptionSweepScreen> {
  static const int _roundDays = 14;
  static const int _monthlyIncome = 600;
  static const int _savingsGoal = 150;

  late final List<_SubscriptionOffer> _deck;
  final List<_Subscription> _activeSubscriptions = <_Subscription>[];

  int _day = 1;
  int _balance = _monthlyIncome;
  int _avoidedCost = 0;
  int _moneySpent = 0;
  int _savingDecisions = 0;
  int _spendingDecisions = 0;
  int _trashDecisions = 0;
  int _nextOfferIndex = 0;
  int _happiness = 6;
  bool _claiming = false;
  String _statusMessage =
      'Review cost, keep the essentials, and cancel the rest before tomorrow’s charge.';
  bool _ended = false;
  bool _reviewShown = false;

  _SubscriptionOffer? _currentOffer;

  @override
  void initState() {
    super.initState();
    _deck = _buildOfferDeck();
    _resetGame();
  }

  void _resetGame() {
    _activeSubscriptions
      ..clear()
      ..addAll(_startingSubscriptions());
    _day = 1;
    _balance = _monthlyIncome;
    _avoidedCost = 0;
    _moneySpent = 0;
    _savingDecisions = 0;
    _spendingDecisions = 0;
    _trashDecisions = 0;
    _nextOfferIndex = 0;
    _ended = false;
    _reviewShown = false;
    _statusMessage =
        'Review cost, keep the essentials, and cancel the rest before tomorrow’s charge.';
    _nextOffer();
  }

  List<_Subscription> _startingSubscriptions() {
    return <_Subscription>[
      _Subscription(
        name: 'Music Streaming',
        category: 'Entertainment',
        monthlyCost: 11,
        essential: false,
      ),
      _Subscription(
        name: 'Gaming Pass',
        category: 'Entertainment',
        monthlyCost: 18,
        essential: false,
      ),
      _Subscription(
        name: 'Fitness App',
        category: 'Health',
        monthlyCost: 15,
        essential: true,
      ),
      _Subscription(
        name: 'Cloud Storage',
        category: 'Utilities',
        monthlyCost: 4,
        essential: true,
      ),
    ];
  }

  List<_SubscriptionOffer> _buildOfferDeck() {
    return <_SubscriptionOffer>[
      const _SubscriptionOffer(
        title: 'MovieMax Premium',
        description:
            'Free for 7 days, then \$12/month. Start watching instantly, cancel before it converts.',
        monthlyCost: 12,
        trialDays: 7,
        essential: false,
        hiddenRenewal: true,
        happinessImpact: 2,
      ),
      const _SubscriptionOffer(
        title: 'AI Homework Helper',
        description: 'Your ticket to better grades. Never be confused again.',
        monthlyCost: 12,
        essential: false,
        happinessImpact: 1,
      ),
      const _SubscriptionOffer(
        title: 'Extra Phone Storage',
        description:
            'Never lose another photo. Keep everything safe for just \$3/month.',
        monthlyCost: 3,
        essential: false,
        happinessImpact: 1,
      ),
      const _SubscriptionOffer(
        title: 'Snack Box Delivery',
        description:
            'Monthly treats delivered to your door. Convenience that feels earned.',
        monthlyCost: 25,
        essential: false,
        happinessImpact: 4,
      ),
      const _SubscriptionOffer(
        title: 'Cloud Vault Secure',
        description:
            'Encrypted storage for \$7/month. Keep your data locked and easy to reach.',
        monthlyCost: 7,
        essential: true,
        happinessImpact: 0,
      ),
      const _SubscriptionOffer(
        title: 'Study Skill Library',
        description:
            'A premium lesson library for \$10/month. Learn faster with the path laid out.',
        monthlyCost: 10,
        essential: false,
        happinessImpact: 2,
      ),
      const _SubscriptionOffer(
        title: 'Meal Planning Pro',
        description:
            'Weekly recipes and grocery lists for \$6/month. Useful if it replaces impulse food spending.',
        monthlyCost: 6,
        essential: false,
        happinessImpact: 1,
      ),
      const _SubscriptionOffer(
        title: 'Transit Tracker Plus',
        description:
            'Commute alerts and route planning for \$5/month. Practical, but only if you use transit often.',
        monthlyCost: 5,
        essential: true,
        happinessImpact: 0,
      ),
      const _SubscriptionOffer(
        title: 'Language Streak App',
        description:
            'Daily language lessons for \$9/month. Great habit, but easy to forget after the first week.',
        monthlyCost: 9,
        essential: false,
        happinessImpact: 2,
      ),
      const _SubscriptionOffer(
        title: 'Photo Filter Studio',
        description:
            'Premium filters and editing tools for \$8/month. Fun, but overlaps with tools you may already have.',
        monthlyCost: 8,
        essential: false,
        happinessImpact: 2,
      ),
      const _SubscriptionOffer(
        title: 'Budget Guard Alerts',
        description:
            'Low-balance warnings and bill reminders for \$4/month. Small cost, useful if it prevents late fees.',
        monthlyCost: 4,
        essential: true,
        happinessImpact: 0,
      ),
      const _SubscriptionOffer(
        title: 'Creator Template Club',
        description:
            'Design templates for \$14/month. Helpful for a project, expensive if it becomes shelfware.',
        monthlyCost: 14,
        essential: false,
        happinessImpact: 3,
      ),
      const _SubscriptionOffer(
        title: 'Student Discount',
        description:
            'A surprise discount lowers one current subscription by 20%.',
        monthlyCost: 0,
        isEvent: true,
        eventType: _SubscriptionEventType.discount,
      ),
      const _SubscriptionOffer(
        title: 'Price Increase',
        description: 'A service pushes up one plan by 20% this month.',
        monthlyCost: 0,
        isEvent: true,
        eventType: _SubscriptionEventType.priceIncrease,
      ),
      const _SubscriptionOffer(
        title: 'Duplicate Alert',
        description:
            'The system flags a repeat plan. Review your active list for savings.',
        monthlyCost: 0,
        isEvent: true,
        eventType: _SubscriptionEventType.duplicateDetected,
      ),
    ];
  }

  void _nextOffer() {
    if (_nextOfferIndex >= _deck.length) {
      _shuffleDeck();
      _nextOfferIndex = 0;
    }

    setState(() {
      _currentOffer = _deck[_nextOfferIndex++];
    });
  }

  void _shuffleDeck() {
    final random = math.Random(_balance + _day + _nextOfferIndex);
    _deck.shuffle(random);
  }

  int get _monthlyCharge {
    return _activeSubscriptions.fold<int>(0, (sum, subscription) {
      if (subscription.paused || subscription.isTrial) {
        return sum;
      }
      return sum + subscription.monthlyCost;
    });
  }

  int get _dailyCharge {
    final optionalCount = _activeSubscriptions
        .where((sub) => !sub.essential)
        .length;
    final lifestylePressure = math.max(0, optionalCount - 2) * 4;
    const baseDailyNeeds = 18;
    return ((_monthlyCharge / 7).ceil() + lifestylePressure + baseDailyNeeds)
        .clamp(1, _monthlyCharge + lifestylePressure + baseDailyNeeds);
  }

  void _applyDailyCharge() {
    final charge = _dailyCharge;
    _balance -= charge;
    _moneySpent += charge;
    if (_balance < 0) {
      _balance = 0;
      _statusMessage =
          'Your budget drained from too many recurring plans. You ran out of money.';
      return;
    }
    _statusMessage =
        'Today’s subscription and living costs deducted $charge from your balance.';
  }

  void _advanceTrials() {
    for (final subscription in _activeSubscriptions) {
      if (!subscription.isTrial) {
        continue;
      }

      subscription.trialDaysRemaining -= 1;
      if (subscription.trialDaysRemaining <= 0) {
        subscription.isTrial = false;
        _statusMessage =
            '${subscription.name} converted to a paid subscription at ${subscription.monthlyCost}/month.';
      }
    }
  }

  void _applyEvent(_SubscriptionOffer eventOffer) {
    final activeCount = _activeSubscriptions.length;
    if (activeCount == 0) {
      _statusMessage = 'No active subscriptions to affect this event.';
      return;
    }

    final index = math.Random(
      _balance + _day + activeCount,
    ).nextInt(activeCount);
    final impacted = _activeSubscriptions[index];
    final impactedName = impacted.name;

    switch (eventOffer.eventType) {
      case _SubscriptionEventType.discount:
        final saved = (impacted.monthlyCost * 0.20).round();
        impacted.monthlyCost = math.max(1, impacted.monthlyCost - saved);
        _statusMessage =
            'Student discount applied to $impactedName. You saved $saved this month.';
        break;
      case _SubscriptionEventType.priceIncrease:
        final increase = (impacted.monthlyCost * 0.20).round();
        impacted.monthlyCost += increase;
        _statusMessage =
            '$impactedName increased by $increase/month. Watch your budget.';
        break;
      case _SubscriptionEventType.duplicateDetected:
        _statusMessage =
            'Duplicate subscription detected. Review your active list for savings.';
        break;
      case null:
        _statusMessage = 'No event applied.';
    }
  }

  void _takeAction(_SubscriptionAction action) {
    if (_ended || _currentOffer == null) {
      return;
    }

    HapticFeedback.lightImpact();

    if (_currentOffer!.isEvent) {
      _applyEvent(_currentOffer!);
    } else {
      _resolveOffer(action, _currentOffer!);
    }

    _applyDailyCharge();
    _advanceTrials();
    _day += 1;

    if (_day > _roundDays || _balance <= 0) {
      _finishGame();
      return;
    }

    _nextOffer();
  }

  void _resolveOffer(_SubscriptionAction action, _SubscriptionOffer offer) {
    final offerTitle = offer.title;
    final offerCost = offer.monthlyCost;

    if (action == _SubscriptionAction.cancel) {
      _avoidedCost += offerCost;
      _savingDecisions += 1;
      final moodPenalty = offer.happinessImpact > 0 ? 1 : 0;
      _happiness = math.max(0, _happiness - moodPenalty);
      _statusMessage =
          'You canceled $offerTitle. You avoided $offerCost/month${moodPenalty > 0 ? ' but you miss the feel-good boost.' : ''}';
      return;
    }

    if (action == _SubscriptionAction.pause) {
      _avoidedCost += offerCost;
      _savingDecisions += 1;
      final moodPenalty = offer.happinessImpact > 0 ? 1 : 0;
      _happiness = math.max(0, _happiness - moodPenalty);
      _statusMessage =
          'You postponed $offerTitle. The cost is stalled, but the temptation stays.';
      return;
    }

    _spendingDecisions += 1;
    final existing = _activeSubscriptions.firstWhere(
      (subscription) => subscription.name == offer.title,
      orElse: () => _Subscription.empty(),
    );

    if (!existing.isEmpty) {
      _statusMessage = 'You already have $offerTitle on your plan.';
      return;
    }

    _activeSubscriptions.add(
      _Subscription(
        name: offerTitle,
        category: 'Flexible',
        monthlyCost: offerCost,
        essential: offer.essential,
        isTrial: offer.trialDays > 0,
        trialDaysRemaining: offer.trialDays,
        hiddenRenewal: offer.hiddenRenewal,
        canTrash: true,
      ),
    );

    _happiness = math.min(10, _happiness + offer.happinessImpact);
    final tag = offer.trialDays > 0 ? 'trial' : 'plan';
    _statusMessage =
        'You kept $offerTitle and added it to your active $tag. It feels like a win.';
  }

  void _finishGame() {
    setState(() {
      _ended = true;
      _currentOffer = null;
      _statusMessage = _balance <= 0
          ? 'You ran out of money before the round ended. Cancel more plans earlier next time.'
          : 'Round over — bank your rewards with Exit or play again to tighten the sweep.';
    });
    _showReviewDialogOnce();
  }

  void _trashSubscription(_Subscription subscription) {
    if (_ended || !subscription.canTrash) {
      return;
    }

    final penalty = math.max(1, (subscription.monthlyCost * 0.10).ceil());
    HapticFeedback.mediumImpact();
    setState(() {
      _activeSubscriptions.remove(subscription);
      _balance = math.max(0, _balance - penalty);
      _moneySpent += penalty;
      _avoidedCost += subscription.monthlyCost;
      _savingDecisions += 1;
      _trashDecisions += 1;
      _happiness = math.max(0, _happiness - (subscription.essential ? 1 : 0));
      _statusMessage =
          'You trashed ${subscription.name}. The cancellation fee cost \$$penalty, but you avoided \$${subscription.monthlyCost}/month going forward.';
    });

    if (_balance <= 0) {
      _finishGame();
    }
  }

  void _showReviewDialogOnce() {
    if (_reviewShown) {
      return;
    }
    _reviewShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ended) {
        return;
      }
      _showReviewDialog();
    });
  }

  Future<void> _showReviewDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF163729),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Subscription Review',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReviewStat(label: 'Money spent', value: '\$$_moneySpent'),
            _ReviewStat(label: 'Saving decisions', value: '$_savingDecisions'),
            _ReviewStat(
              label: 'Spending decisions',
              value: '$_spendingDecisions',
            ),
            _ReviewStat(label: 'Trashed after signup', value: '$_trashDecisions'),
            const SizedBox(height: 12),
            Text(
              _reviewAdvice,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String get _reviewAdvice {
    if (_balance < _savingsGoal) {
      return 'Next time, protect the savings goal first. Trials and cheap plans still add pressure once daily costs start stacking.';
    }
    if (_spendingDecisions > _savingDecisions) {
      return 'You finished above the goal, but you kept more offers than you cut. Try canceling duplicates earlier to make the round less risky.';
    }
    if (_trashDecisions > 0) {
      return 'Good recovery. Trashing a bad signup can save money, but the 10% fee means catching duplicates before accepting them is stronger.';
    }
    return 'Strong sweep. You kept recurring costs controlled and left enough room for the savings target.';
  }

  SubscriptionSweepCloseResult _projectedResult(SyncState syncState) {
    final finalBalance = _balance.clamp(0, 999999);
    final goldEarned = math.max(
      24,
      finalBalance ~/ 20 + _avoidedCost ~/ 4 + _happiness * 2,
    );
    final xpEarned = math.max(34, _happiness * 5 + _day + _avoidedCost ~/ 5);
    final literacyEarned = math.max(12, _happiness * 2 + _avoidedCost ~/ 6);

    return SubscriptionSweepCloseResult(
      goldEarned: goldEarned,
      xpEarned: xpEarned,
      literacyPointsEarned: literacyEarned,
      finalBalance: finalBalance,
      finalHappiness: _happiness,
      syncState: syncState,
    );
  }

  Future<void> _bankRewards() async {
    if (_claiming || !_ended) {
      return;
    }

    setState(() {
      _claiming = true;
    });

    final projected = _projectedResult(
      const SyncState(
        synced: false,
        usedCache: true,
        message: 'Saving locally...',
      ),
    );

    final controller = context.read<UserStatsController>();
    final result = await controller.applyChallengePayload(<String, dynamic>{
      'status': 'completed',
      'gold_earned': projected.goldEarned,
      'xp_earned': projected.xpEarned,
      'literacy_points_earned': projected.literacyPointsEarned,
      'title': 'Subscription Sweep Rewards',
      'description': 'You finished the sweep and banked the budget win.',
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _claiming = false;
    });

    Navigator.of(context).pop(
      SubscriptionSweepCloseResult(
        goldEarned: projected.goldEarned,
        xpEarned: projected.xpEarned,
        literacyPointsEarned: projected.literacyPointsEarned,
        finalBalance: projected.finalBalance,
        finalHappiness: projected.finalHappiness,
        syncState: result.syncState,
      ),
    );
  }

  int get _savingsProgress => math.max(0, _balance - _savingsGoal);
  double get _goalPercent => (_balance / _monthlyIncome).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071711),
      appBar: AppBar(
        title: const Text('Subscription Sweep'),
        backgroundColor: const Color(0xFF071711),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: ListView(
            children: [
              _GameSummaryCard(
                monthlyIncome: _monthlyIncome,
                balance: _balance,
                savingsGoal: _savingsGoal,
                savingsProgress: _savingsProgress,
                goalPercent: _goalPercent,
                day: _day,
                roundDays: _roundDays,
                happiness: _happiness,
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Active subscriptions',
                subtitle:
                    'Your current recurring costs. Pause the tempting extras before they strike again.',
              ),
              const SizedBox(height: 12),
              ..._activeSubscriptions.map(
                (subscription) => _SubscriptionTile(
                  subscription: subscription,
                  onTrash: subscription.canTrash
                      ? () => _trashSubscription(subscription)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _currentOffer == null
                  ? _EndOfRoundSummary(
                      balance: _balance,
                      avoidedCost: _avoidedCost,
                      savingsGoal: _savingsGoal,
                      moneySpent: _moneySpent,
                      savingDecisions: _savingDecisions,
                      spendingDecisions: _spendingDecisions,
                    )
                  : _currentOffer!.isEvent
                  ? _EventCard(
                      offer: _currentOffer!,
                      onContinue: () =>
                          _takeAction(_SubscriptionAction.keep),
                    )
                  : _OfferCard(
                      offer: _currentOffer!,
                      onKeep: () => _takeAction(_SubscriptionAction.keep),
                      onPause: () => _takeAction(_SubscriptionAction.pause),
                      onCancel: () => _takeAction(_SubscriptionAction.cancel),
                    ),
              const SizedBox(height: 12),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (_ended)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF58C7FF),
                          foregroundColor: const Color(0xFF071711),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _resetGame,
                        child: const Text('Play Again'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _claiming ? null : _bankRewards,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(_claiming ? 'Saving…' : 'Exit to arcade'),
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
}

class _GameSummaryCard extends StatelessWidget {
  const _GameSummaryCard({
    required this.monthlyIncome,
    required this.balance,
    required this.savingsGoal,
    required this.savingsProgress,
    required this.goalPercent,
    required this.day,
    required this.roundDays,
    required this.happiness,
  });

  final int monthlyIncome;
  final int balance;
  final int savingsGoal;
  final int savingsProgress;
  final double goalPercent;
  final int day;
  final int roundDays;
  final int happiness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF11322E), Color(0xFF0F241F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Metric(label: 'Income', value: '$monthlyIncome'),
              const SizedBox(width: 12),
              _Metric(label: 'Balance', value: '$balance'),
              const SizedBox(width: 12),
              _Metric(label: 'Mood', value: '$happiness/10'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Savings Goal',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$$savingsGoal target',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: goalPercent,
                        minHeight: 8,
                        color: const Color(0xFF58C7FF),
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      savingsProgress > 0
                          ? '\$$savingsProgress above goal'
                          : '\$${savingsGoal - balance} short of goal',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$day / $roundDays',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({required this.subscription, required this.onTrash});

  final _Subscription subscription;
  final VoidCallback? onTrash;

  @override
  Widget build(BuildContext context) {
    final color = subscription.essential
        ? const Color(0xFF85EFAC)
        : const Color(0xFFD49B7E);
    final badge = subscription.isTrial
        ? 'TRIAL'
        : subscription.paused
        ? 'PAUSED'
        : subscription.essential
        ? 'PRIORITY'
        : 'FLEXIBLE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${subscription.monthlyCost}/month - ${subscription.category}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 12,
                  ),
                ),
                if (onTrash != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Trash fee: 10% of monthly cost',
                    style: TextStyle(
                      color: Colors.redAccent.withValues(alpha: 0.82),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          if (onTrash != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Trash subscription',
              onPressed: onTrash,
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.redAccent,
            ),
          ],
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.offer, required this.onContinue});

  final _SubscriptionOffer offer;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD166).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFFD166).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notification_important_outlined,
                color: Color(0xFFFFD166),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  offer.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            offer.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This is an alert, not a subscription offer. Review your active list, then continue to the next day.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD166),
                foregroundColor: const Color(0xFF071711),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('CONTINUE'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.onKeep,
    required this.onPause,
    required this.onCancel,
  });

  final _SubscriptionOffer offer;
  final VoidCallback onKeep;
  final VoidCallback onPause;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            offer.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              height: 1.45,
            ),
          ),
          if (offer.hiddenRenewal) ...[
            const SizedBox(height: 10),
            Text(
              'The free trial will convert automatically if you do not cancel it.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 12,
              ),
            ),
          ],
          if (offer.monthlyCost > 0) ...[
            const SizedBox(height: 14),
            Text(
              'Cost: \$${offer.monthlyCost}/month',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (offer.trialDays > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${offer.trialDays}-day free trial',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.64)),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onKeep,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF85EFAC),
                    foregroundColor: const Color(0xFF071711),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('KEEP'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onPause,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('PAUSE'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.26)),
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('CANCEL'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EndOfRoundSummary extends StatelessWidget {
  const _EndOfRoundSummary({
    required this.balance,
    required this.avoidedCost,
    required this.savingsGoal,
    required this.moneySpent,
    required this.savingDecisions,
    required this.spendingDecisions,
  });

  final int balance;
  final int avoidedCost;
  final int savingsGoal;
  final int moneySpent;
  final int savingDecisions;
  final int spendingDecisions;

  @override
  Widget build(BuildContext context) {
    final reachedGoal = balance >= savingsGoal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Round summary',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Final balance: \$$balance',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Avoided recurring cost: \$$avoidedCost/month',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Money spent: \$$moneySpent',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Decisions: $savingDecisions saving / $spendingDecisions spending',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            reachedGoal
                ? 'You reached your savings goal. Nice work keeping extras under control.'
                : 'You fell short of the goal. Next round, cancel or pause more optional plans early.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStat extends StatelessWidget {
  const _ReviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

enum _SubscriptionAction { keep, pause, cancel }

enum _SubscriptionEventType { discount, priceIncrease, duplicateDetected }

class _SubscriptionOffer {
  const _SubscriptionOffer({
    required this.title,
    required this.description,
    required this.monthlyCost,
    this.trialDays = 0,
    this.essential = false,
    this.isEvent = false,
    this.hiddenRenewal = false,
    this.happinessImpact = 0,
    this.eventType,
  });

  final String title;
  final String description;
  final int monthlyCost;
  final int trialDays;
  final bool essential;
  final bool isEvent;
  final bool hiddenRenewal;
  final int happinessImpact;
  final _SubscriptionEventType? eventType;
}

class _Subscription {
  _Subscription({
    required this.name,
    required this.category,
    required this.monthlyCost,
    required this.essential,
    bool? paused,
    bool? isTrial,
    int? trialDaysRemaining,
    bool? hiddenRenewal,
    bool? canTrash,
  }) : paused = paused ?? false,
       isTrial = isTrial ?? false,
       trialDaysRemaining = trialDaysRemaining ?? 0,
       hiddenRenewal = hiddenRenewal ?? false,
       canTrash = canTrash ?? false;

  _Subscription.empty()
    : name = '',
      category = '',
      monthlyCost = 0,
      essential = false,
      paused = false,
      isTrial = false,
      trialDaysRemaining = 0,
      hiddenRenewal = false,
      canTrash = false;

  final String name;
  final String category;
  int monthlyCost;
  final bool essential;
  bool paused;
  bool isTrial;
  int trialDaysRemaining;
  final bool hiddenRenewal;
  final bool canTrash;

  bool get isEmpty => name.isEmpty;
}
