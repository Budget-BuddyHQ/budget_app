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
  int _nextOfferIndex = 0;
  int _happiness = 6;
  bool _claiming = false;
  String _statusMessage =
      'Review cost, keep the essentials, and cancel the rest before tomorrow’s charge.';
  bool _ended = false;

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
    _nextOfferIndex = 0;
    _ended = false;
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
      final moodPenalty = offer.happinessImpact > 0 ? 1 : 0;
      _happiness = math.max(0, _happiness - moodPenalty);
      _statusMessage =
          'You canceled $offerTitle. You avoided $offerCost/month${moodPenalty > 0 ? ' but you miss the feel-good boost.' : ''}';
      return;
    }

    if (action == _SubscriptionAction.pause) {
      _avoidedCost += offerCost;
      final moodPenalty = offer.happinessImpact > 0 ? 1 : 0;
      _happiness = math.max(0, _happiness - moodPenalty);
      _statusMessage =
          'You postponed $offerTitle. The cost is stalled, but the temptation stays.';
      return;
    }

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
  double get _goalPercent => (_balance / _savingsGoal).clamp(0.0, 1.0);

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
                (subscription) => _SubscriptionTile(subscription: subscription),
              ),
              const SizedBox(height: 16),
              _currentOffer == null
                  ? _EndOfRoundSummary(
                      balance: _balance,
                      avoidedCost: _avoidedCost,
                      savingsGoal: _savingsGoal,
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
                  color: Colors.white.withOpacity(0.76),
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
                            color: Colors.white.withOpacity(0.18),
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
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$savingsGoal',
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
                      '${(goalPercent * 100).round()}% to goal',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
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
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
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
              color: Colors.white.withOpacity(0.72),
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
          style: TextStyle(color: Colors.white.withOpacity(0.72), height: 1.45),
        ),
      ],
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({required this.subscription});

  final _Subscription subscription;

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
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.16)),
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
                  '${subscription.monthlyCost}/month • ${subscription.category}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
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
        color: Colors.white.withOpacity(0.05),
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
              color: Colors.white.withOpacity(0.76),
              height: 1.45,
            ),
          ),
          if (offer.hiddenRenewal) ...[
            const SizedBox(height: 10),
            Text(
              'The free trial will convert automatically if you do not cancel it.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.60),
                fontSize: 12,
              ),
            ),
          ],
          if (offer.monthlyCost > 0) ...[
            const SizedBox(height: 14),
            Text(
              'Cost: \$$offer.monthlyCost/month',
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (offer.trialDays > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${offer.trialDays}-day free trial',
              style: TextStyle(color: Colors.white.withOpacity(0.64)),
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
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
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
                    side: BorderSide(color: Colors.red.withOpacity(0.26)),
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
  });

  final int balance;
  final int avoidedCost;
  final int savingsGoal;

  @override
  Widget build(BuildContext context) {
    final reachedGoal = balance >= savingsGoal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
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
          const SizedBox(height: 12),
          Text(
            reachedGoal
                ? 'You reached your savings goal. Nice work keeping extras under control.'
                : 'You fell short of the goal. Next round, cancel or pause more optional plans early.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              height: 1.45,
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
    this.paused = false,
    this.isTrial = false,
    this.trialDaysRemaining = 0,
    this.hiddenRenewal = false,
  });

  _Subscription.empty()
    : name = '',
      category = '',
      monthlyCost = 0,
      essential = false,
      paused = false,
      isTrial = false,
      trialDaysRemaining = 0,
      hiddenRenewal = false;

  final String name;
  final String category;
  int monthlyCost;
  final bool essential;
  bool paused;
  bool isTrial;
  int trialDaysRemaining;
  final bool hiddenRenewal;

  bool get isEmpty => name.isEmpty;
}
