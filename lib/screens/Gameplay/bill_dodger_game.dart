import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../services/supabase_service.dart';

class BillDodgerCloseResult {
  const BillDodgerCloseResult({
    required this.goldEarned,
    required this.xpEarned,
    required this.literacyPointsEarned,
    required this.finalMoney,
    required this.finalScore,
    required this.syncState,
  });

  final int goldEarned;
  final int xpEarned;
  final int literacyPointsEarned;
  final int finalMoney;
  final int finalScore;
  final SyncState syncState;
}

class BillDodgerGameScreen extends StatefulWidget {
  const BillDodgerGameScreen({super.key});

  @override
  State<BillDodgerGameScreen> createState() => _BillDodgerGameScreenState();
}

class _BillDodgerGameScreenState extends State<BillDodgerGameScreen>
    with SingleTickerProviderStateMixin {
  static const Color background = Color(0xFF092A20);
  static const Color panel = Color(0xFF113A2D);
  static const Color panelSoft = Color(0xFF1B4737);
  static const Color accent = Color(0xFF85EFAC);
  static const Color needColor = Color(0xFF8BE9B3);
  static const Color wantColor = Color(0xFFFF8A80);
  static const int totalLanes = 3;
  static const int startingMoney = 1200;
  static const int roundLengthSeconds = 45;

  final Random _random = Random();
  final List<_FallingItem> _items = <_FallingItem>[];

  late final AnimationController _controller;
  Timer? _spawnTimer;
  Timer? _clockTimer;

  int money = startingMoney;
  int score = 0;
  int timeLeft = roundLengthSeconds;
  int currentLane = 1;
  bool gameStarted = false;
  bool gameOver = false;
  bool _submittingReward = false;
  bool _rewardClaimed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_tick);
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _clockTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      money = startingMoney;
      score = 0;
      timeLeft = roundLengthSeconds;
      currentLane = 1;
      gameStarted = true;
      gameOver = false;
      _submittingReward = false;
      _rewardClaimed = false;
      _items.clear();
    });

    _spawnTimer?.cancel();
    _clockTimer?.cancel();
    _controller.repeat();

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 850), (_) {
      _spawnItem();
    });

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || gameOver || !gameStarted) {
        return;
      }
      setState(() {
        timeLeft -= 1;
      });
      if (timeLeft <= 0 || money <= 0) {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    _spawnTimer?.cancel();
    _clockTimer?.cancel();
    _controller.stop();
    if (mounted) {
      setState(() {
        gameStarted = false;
        gameOver = true;
      });
    }
  }

  void _spawnItem() {
    if (!mounted || !gameStarted || gameOver) {
      return;
    }

    final isNeed = _random.nextBool();
    final pool = isNeed ? _needItems : _wantItems;
    final data = pool[_random.nextInt(pool.length)];

    _items.add(
      _FallingItem(
        lane: _random.nextInt(totalLanes),
        y: -72,
        amount: data.amount,
        label: data.label,
        kind: isNeed ? _BillItemKind.need : _BillItemKind.want,
      ),
    );

    setState(() {});
  }

  void _tick() {
    if (!mounted || !gameStarted || gameOver) {
      return;
    }

    const double speed = 4.2;
    final itemBottomLimit = MediaQuery.of(context).size.height * 0.56;
    final List<_FallingItem> toRemove = <_FallingItem>[];

    for (final item in _items) {
      item.y += speed;

      final playerRowTop = itemBottomLimit - 16;
      final collided =
          item.lane == currentLane &&
          item.y >= playerRowTop - 14 &&
          item.y <= playerRowTop + 38;

      if (collided && !item.resolved) {
        item.resolved = true;
        if (item.kind == _BillItemKind.need) {
          money += 35;
          score += 12;
        } else {
          money -= 45;
          score = max(0, score - 10);
        }
        toRemove.add(item);
        continue;
      }

      if (item.y > itemBottomLimit + 90) {
        if (item.kind == _BillItemKind.need) {
          money -= 25;
          score = max(0, score - 5);
        } else {
          score += 5;
        }
        toRemove.add(item);
      }
    }

    _items.removeWhere((item) => toRemove.contains(item));

    if (money <= 0) {
      money = 0;
      _finishGame();
      return;
    }

    setState(() {});
  }

  void _moveLeft() {
    if (!gameStarted) {
      return;
    }
    setState(() {
      currentLane = max(0, currentLane - 1);
    });
  }

  void _moveRight() {
    if (!gameStarted) {
      return;
    }
    setState(() {
      currentLane = min(totalLanes - 1, currentLane + 1);
    });
  }

  BillDodgerCloseResult _projectedResult(SyncState syncState) {
    final finalMoney = money.clamp(0, 999999);
    final goldEarned = max(24, finalMoney ~/ 42 + score ~/ 4);
    final xpEarned = max(40, 30 + score ~/ 2);
    final literacyEarned = max(18, 20 + score ~/ 5);

    return BillDodgerCloseResult(
      goldEarned: goldEarned,
      xpEarned: xpEarned,
      literacyPointsEarned: literacyEarned,
      finalMoney: finalMoney,
      finalScore: score,
      syncState: syncState,
    );
  }

  Future<void> _claimRewardsAndExit() async {
    if (_submittingReward || _rewardClaimed) {
      return;
    }

    setState(() {
      _submittingReward = true;
    });

    final projected = _projectedResult(
      const SyncState(
        synced: false,
        usedCache: true,
        message: 'Saving locally...',
      ),
    );
    final controller = context.read<UserStatsController>();
    final actionResult = await controller.applyChallengePayload(
      <String, dynamic>{
        'status': 'completed',
        'gold_earned': projected.goldEarned,
        'xp_earned': projected.xpEarned,
        'literacy_points_earned': projected.literacyPointsEarned,
        'title': 'Bill Dodger Rewards',
        'description':
            'Collected essentials, dodged wasteful spending, and banked the rewards.',
      },
    );

    if (!mounted) {
      return;
    }

    _rewardClaimed = true;
    Navigator.of(context).pop(
      BillDodgerCloseResult(
        goldEarned: projected.goldEarned,
        xpEarned: projected.xpEarned,
        literacyPointsEarned: projected.literacyPointsEarned,
        finalMoney: projected.finalMoney,
        finalScore: projected.finalScore,
        syncState: actionResult.syncState,
      ),
    );
  }

  String _gradeMessage() {
    if (score >= 180) return 'Excellent impulse control.';
    if (score >= 120) return 'Great job separating needs from wants.';
    if (score >= 70) return 'Solid effort - keep practicing.';
    return 'You are learning. Protect essentials first.';
  }

  @override
  Widget build(BuildContext context) {
    final projected = _projectedResult(
      const SyncState(
        synced: false,
        usedCache: true,
        message: 'Projected rewards',
      ),
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        title: const Text('Bill Dodger'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              _TopStatsBar(
                money: money,
                score: score,
                timeLeft: timeLeft,
              ),
              const SizedBox(height: 14),
              _InfoCard(
                title: 'How Bill Dodger Works',
                icon: Icons.receipt_long_rounded,
                child: const Text(
                  'Collect NEEDS like rent and groceries. Dodge WANTS like impulse buys and subscriptions. Swipe or tap the arrows to move.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final laneWidth = constraints.maxWidth / totalLanes;
                    final playerTop = constraints.maxHeight - 98;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              panelSoft,
                              panel,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: GestureDetector(
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity < 0) {
                              _moveLeft();
                            } else if (velocity > 0) {
                              _moveRight();
                            }
                          },
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: Size.infinite,
                                painter: _LanePainter(),
                              ),
                              Positioned(
                                top: 14,
                                left: 14,
                                right: 14,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: const [
                                    _LegendPill(
                                      label: 'Collect NEEDS',
                                      color: needColor,
                                      icon: Icons.check_circle_rounded,
                                    ),
                                    _LegendPill(
                                      label: 'Dodge WANTS',
                                      color: wantColor,
                                      icon: Icons.close_rounded,
                                    ),
                                  ],
                                ),
                              ),
                              for (final item in _items)
                                Positioned(
                                  left: item.lane * laneWidth + (laneWidth - 96) / 2,
                                  top: item.y,
                                  child: _FallingBillCard(item: item),
                                ),
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOutCubic,
                                left: currentLane * laneWidth + (laneWidth - 72) / 2,
                                top: playerTop,
                                child: const _PlayerToken(),
                              ),
                              if (!gameStarted && !gameOver)
                                Positioned.fill(
                                  child: _CenterOverlay(
                                    child: ElevatedButton(
                                      onPressed: _startGame,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accent,
                                        foregroundColor: background,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 26,
                                          vertical: 14,
                                        ),
                                      ),
                                      child: const Text('Start Round'),
                                    ),
                                  ),
                                ),
                              if (gameOver)
                                Positioned.fill(
                                  child: _CenterOverlay(
                                    child: _ResultsCard(
                                      score: score,
                                      money: money,
                                      gradeMessage: _gradeMessage(),
                                      rewards: projected,
                                      submitting: _submittingReward,
                                      onReplay: _startGame,
                                      onClaim: _claimRewardsAndExit,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _moveLeft,
                      icon: const Icon(Icons.arrow_left_rounded),
                      label: const Text('Move Left'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _moveRight,
                      icon: const Icon(Icons.arrow_right_rounded),
                      label: const Text('Move Right'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _InfoCard(
                title: 'Learning Goal',
                icon: Icons.menu_book_rounded,
                child: Text(
                  'Needs keep your life stable. Wants can be fun, but they should not knock out your budget. This game builds fast decision-making around essentials.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BillItemKind { need, want }

class _FallingItem {
  _FallingItem({
    required this.lane,
    required this.y,
    required this.amount,
    required this.label,
    required this.kind,
    this.resolved = false,
  });

  final int lane;
  double y;
  final int amount;
  final String label;
  final _BillItemKind kind;
  bool resolved;
}

class _BillData {
  const _BillData(this.label, this.amount);

  final String label;
  final int amount;
}

const List<_BillData> _needItems = [
  _BillData('Rent', 600),
  _BillData('Groceries', 85),
  _BillData('Utilities', 120),
  _BillData('Medicine', 40),
  _BillData('Gas', 55),
  _BillData('Internet', 65),
];

const List<_BillData> _wantItems = [
  _BillData('Takeout', 24),
  _BillData('Streaming', 18),
  _BillData('Game Skin', 15),
  _BillData('Fancy Coffee', 9),
  _BillData('New Shoes', 90),
  _BillData('Impulse Buy', 35),
];

class _TopStatsBar extends StatelessWidget {
  const _TopStatsBar({
    required this.money,
    required this.score,
    required this.timeLeft,
  });

  final int money;
  final int score;
  final int timeLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _BillDodgerGameScreenState.panelSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x1F85EFAC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/UI1/src/assets/f0dfd56a541371c704f7587e4add851958a11a86.png',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _StatText(label: 'Money', value: '\$$money'),
                _StatText(label: 'Score', value: '$score'),
                _StatText(label: 'Time', value: '${timeLeft}s'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatText extends StatelessWidget {
  const _StatText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _BillDodgerGameScreenState.panelSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _BillDodgerGameScreenState.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xD916392E),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FallingBillCard extends StatelessWidget {
  const _FallingBillCard({required this.item});

  final _FallingItem item;

  @override
  Widget build(BuildContext context) {
    final isNeed = item.kind == _BillItemKind.need;
    return Container(
      width: 96,
      height: 62,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF7F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNeed ? const Color(0xFFBCEFD1) : const Color(0xFFFFC4BF),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isNeed
                  ? _BillDodgerGameScreenState.needColor
                  : _BillDodgerGameScreenState.wantColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isNeed ? 'Need' : 'Want',
              style: const TextStyle(
                color: Color(0xFF103124),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF17382D),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '\$${item.amount}',
            style: const TextStyle(color: Color(0xFF355E4E), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _PlayerToken extends StatelessWidget {
  const _PlayerToken();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _BillDodgerGameScreenState.accent,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          'assets/UI1/src/assets/f0dfd56a541371c704f7587e4add851958a11a86.png',
        ),
      ),
    );
  }
}

class _CenterOverlay extends StatelessWidget {
  const _CenterOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.30),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.score,
    required this.money,
    required this.gradeMessage,
    required this.rewards,
    required this.submitting,
    required this.onReplay,
    required this.onClaim,
  });

  final int score;
  final int money;
  final String gradeMessage;
  final BillDodgerCloseResult rewards;
  final bool submitting;
  final VoidCallback onReplay;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF214737),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Round Complete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Final Score: $score',
            style: const TextStyle(
              color: _BillDodgerGameScreenState.accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ending Money: \$${money.clamp(0, 999999)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Text(
            gradeMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            '+${rewards.goldEarned} gold | +${rewards.xpEarned} XP | +${rewards.literacyPointsEarned} literacy',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _BillDodgerGameScreenState.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReplay,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  child: const Text('Play Again'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: submitting ? null : onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _BillDodgerGameScreenState.accent,
                    foregroundColor: _BillDodgerGameScreenState.background,
                  ),
                  child: Text(submitting ? 'Saving...' : 'Claim Rewards'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.1;
    final laneWidth = size.width / _BillDodgerGameScreenState.totalLanes;

    for (var i = 1; i < _BillDodgerGameScreenState.totalLanes; i++) {
      final x = laneWidth * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lanePaint);
    }

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (double y = 90; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
