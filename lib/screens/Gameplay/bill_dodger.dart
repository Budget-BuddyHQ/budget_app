import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_stats_controller.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_toast.dart';

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

class BillDodgerScreen extends StatefulWidget {
  const BillDodgerScreen({super.key});

  @override
  State<BillDodgerScreen> createState() => _BillDodgerScreenState();
}

class _BillDodgerScreenState extends State<BillDodgerScreen>
    with TickerProviderStateMixin {
  static const Color _background = Color(0xFF071711);
  static const Color _panel = Color(0xFF113528);
  static const Color _accent = Color(0xFF85EFAC);
  static const Color _needColor = Color(0xFF85EFAC);
  static const Color _wantColor = Color(0xFFFFB084);
  static const int _roundSeconds = 45;

  final math.Random _random = math.Random();
  final List<_FallingPickup> _pickups = <_FallingPickup>[];

  Ticker? _ticker;
  Timer? _spawnTimer;
  Timer? _countdownTimer;
  Duration _lastFrame = Duration.zero;

  Size _arenaSize = Size.zero;
  double _playerX = 0;
  bool _movingLeft = false;
  bool _movingRight = false;

  int _money = 1200;
  int _score = 0;
  int _timeLeft = _roundSeconds;
  bool _started = false;
  bool _finished = false;
  bool _claiming = false;
  bool _didClaim = false;

  double get _playerWidth => _arenaSize.width <= 0
      ? 86
      : (_arenaSize.width.clamp(320.0, 800.0) as double) * 0.18;

  double get _playerHeight => _playerWidth * 0.88;

  double get _playerY =>
      math.max(0, _arenaSize.height - _playerHeight - 18).toDouble();

  Rect get _playerRect => Rect.fromLTWH(
        _playerX,
        _playerY,
        _playerWidth,
        _playerHeight,
      );

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _spawnTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    HapticFeedback.lightImpact();
    setState(() {
      _money = 1200;
      _score = 0;
      _timeLeft = _roundSeconds;
      _started = true;
      _finished = false;
      _claiming = false;
      _didClaim = false;
      _pickups.clear();
      _playerX = math.max(0, (_arenaSize.width - _playerWidth) / 2).toDouble();
      _lastFrame = Duration.zero;
    });

    _spawnTimer?.cancel();
    _countdownTimer?.cancel();

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 620), (_) {
      _spawnPickup();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_started || _finished) {
        return;
      }
      setState(() {
        _timeLeft -= 1;
      });
      if (_timeLeft <= 0 || _money <= 0) {
        _finishGame();
      }
    });

    _ticker?.start();
  }

  void _finishGame() {
    _spawnTimer?.cancel();
    _countdownTimer?.cancel();
    _ticker?.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      _started = false;
      _finished = true;
      _movingLeft = false;
      _movingRight = false;
    });
  }

  void _onTick(Duration elapsed) {
    if (!_started || _finished || _arenaSize == Size.zero) {
      return;
    }

    if (_lastFrame == Duration.zero) {
      _lastFrame = elapsed;
      return;
    }

    final deltaSeconds =
        ((elapsed - _lastFrame).inMicroseconds / Duration.microsecondsPerSecond)
            .clamp(0.0, 0.032)
            .toDouble();
    _lastFrame = elapsed;

    _updatePlayer(deltaSeconds);
    _updatePickups(deltaSeconds);

    if (mounted) {
      setState(() {});
    }
  }

  void _updatePlayer(double deltaSeconds) {
    const speed = 320.0;
    double direction = 0;
    if (_movingLeft) {
      direction -= 1;
    }
    if (_movingRight) {
      direction += 1;
    }

    _playerX += direction * speed * deltaSeconds;
    _playerX = _playerX
        .clamp(0, math.max(0, _arenaSize.width - _playerWidth))
        .toDouble();
  }

  void _updatePickups(double deltaSeconds) {
    final toRemove = <_FallingPickup>[];

    for (final pickup in _pickups) {
      pickup.y += pickup.speed * deltaSeconds;
      final pickupRect = Rect.fromLTWH(
        pickup.x,
        pickup.y,
        pickup.width,
        pickup.height,
      );

      if (pickupRect.overlaps(_playerRect) && !pickup.resolved) {
        pickup.resolved = true;
        _handlePickupCollision(pickup);
        toRemove.add(pickup);
        continue;
      }

      if (pickup.y > _arenaSize.height + pickup.height) {
        _handleMissedPickup(pickup);
        toRemove.add(pickup);
      }
    }

    _pickups.removeWhere(toRemove.contains);

    if (_money <= 0) {
      _money = 0;
      _finishGame();
    }
  }

  void _handlePickupCollision(_FallingPickup pickup) {
    HapticFeedback.lightImpact();
    if (pickup.kind == _PickupKind.need) {
      _money += 28;
      _score += 16;
    } else {
      _money -= 34;
      _score = math.max(0, _score - 12);
    }
  }

  void _handleMissedPickup(_FallingPickup pickup) {
    if (pickup.kind == _PickupKind.need) {
      _money -= 22;
      _score = math.max(0, _score - 8);
    } else {
      _score += 6;
    }
  }

  void _spawnPickup() {
    if (!_started || _finished || _arenaSize == Size.zero) {
      return;
    }

    final isNeed = _random.nextBool();
    final data = (isNeed ? _needPool : _wantPool)[
      _random.nextInt(isNeed ? _needPool.length : _wantPool.length)
    ];

    final width = math.min(98.0, _arenaSize.width * 0.24).toDouble();
    final height = width * 0.72;
    final maxX = math.max(0, _arenaSize.width - width).toDouble();
    final lanePadding = math.max(6, _arenaSize.width * 0.02).toDouble();
    final x = lanePadding +
        (_random.nextDouble() * math.max(0, maxX - lanePadding * 2).toDouble());

    _pickups.add(
      _FallingPickup(
        label: data.label,
        amount: data.amount,
        kind: isNeed ? _PickupKind.need : _PickupKind.want,
        x: x,
        y: -height - 10,
        width: width,
        height: height,
        speed: 210 + _random.nextDouble() * 90,
      ),
    );
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
              'Leave Bill Dodger?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Your current round will end if you leave now.',
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

  BillDodgerCloseResult _projectedResult(SyncState syncState) {
    final finalMoney = _money.clamp(0, 999999).toInt();
    final goldEarned = math.max(32, finalMoney ~/ 46 + _score ~/ 5);
    final xpEarned = math.max(48, 40 + _score ~/ 2);
    final literacyEarned = math.max(18, 18 + _score ~/ 6);

    return BillDodgerCloseResult(
      goldEarned: goldEarned,
      xpEarned: xpEarned,
      literacyPointsEarned: literacyEarned,
      finalMoney: finalMoney,
      finalScore: _score,
      syncState: syncState,
    );
  }

  Future<void> _claimRewards() async {
    if (_claiming || _didClaim) {
      return;
    }

    HapticFeedback.lightImpact();
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
    final result = await controller.applyChallengePayload(
      <String, dynamic>{
        'status': 'completed',
        'gold_earned': projected.goldEarned,
        'xp_earned': projected.xpEarned,
        'literacy_points_earned': projected.literacyPointsEarned,
        'title': 'Bill Dodger Rewards',
        'description':
            'You collected essentials, dodged wants, and banked your reward.',
      },
    );

    if (!mounted) {
      return;
    }

    _didClaim = true;
    GameToast.show(
      context,
      title: 'Rewards banked',
      message:
          '+${projected.goldEarned} gold • +${projected.xpEarned} XP • ${result.message}',
      icon: Icons.stars_rounded,
      accent: _accent,
    );

    Navigator.of(context).pop(
      BillDodgerCloseResult(
        goldEarned: projected.goldEarned,
        xpEarned: projected.xpEarned,
        literacyPointsEarned: projected.literacyPointsEarned,
        finalMoney: projected.finalMoney,
        finalScore: projected.finalScore,
        syncState: result.syncState,
      ),
    );
  }

  void _moveByDrag(double delta) {
    if (!_started || _finished) {
      return;
    }
    _playerX = (_playerX + delta)
        .clamp(0, math.max(0, _arenaSize.width - _playerWidth))
        .toDouble();
    setState(() {});
  }

  String _gradeMessage() {
    if (_score >= 200) {
      return 'Elite budget instincts. You guarded every essential like a pro.';
    }
    if (_score >= 140) {
      return 'Strong discipline. You kept wants from wrecking the round.';
    }
    if (_score >= 90) {
      return 'Nice work. You are building faster decision-making every run.';
    }
    return 'Good practice round. Focus on catching needs early and dodging shiny wants.';
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

    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        final shouldLeave = await _confirmExit();
                        if (!mounted || !shouldLeave) {
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Bill Dodger',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _TopChip(
                      label: '${_timeLeft}s',
                      icon: Icons.timer_rounded,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TopStatsRow(
                  money: _money,
                  score: _score,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Text(
                    'Collect NEEDS, dodge WANTS, and glide smoothly across the arena. Hold the arrows or drag your hero left and right.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _arenaSize = constraints.biggest;
                      if (!_started && !_finished) {
                        _playerX = math.max(
                          0,
                          (_arenaSize.width - _playerWidth) / 2,
                        ).toDouble();
                      } else {
                        _playerX = _playerX.clamp(
                          0,
                          math.max(0, _arenaSize.width - _playerWidth),
                        ).toDouble();
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (details) {
                            _moveByDrag(details.delta.dx);
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF103225),
                                      const Color(0xFF173B2D),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ArenaPainter(),
                                ),
                              ),
                              for (final pickup in _pickups)
                                Positioned(
                                  left: pickup.x,
                                  top: pickup.y,
                                  child: _PickupCard(pickup: pickup),
                                ),
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 60),
                                curve: Curves.linear,
                                left: _playerX,
                                top: _playerY,
                                child: _PlayerAvatar(
                                  width: _playerWidth,
                                  height: _playerHeight,
                                ),
                              ),
                              if (!_started && !_finished)
                                Positioned.fill(
                                  child: _OverlayCenter(
                                    child: _IntroCard(onStart: _startGame),
                                  ),
                                ),
                              if (_finished)
                                Positioned.fill(
                                  child: _OverlayCenter(
                                    child: _ResultsCard(
                                      score: _score,
                                      money: _money,
                                      message: _gradeMessage(),
                                      rewards: projected,
                                      claiming: _claiming,
                                      onReplay: _startGame,
                                      onClaim: _claimRewards,
                                    ),
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ControlButton(
                        icon: Icons.arrow_left_rounded,
                        label: 'Hold Left',
                        accent: Colors.white,
                        background: Colors.white.withOpacity(0.06),
                        onDown: () {
                          HapticFeedback.lightImpact();
                          _movingLeft = true;
                        },
                        onUp: () => _movingLeft = false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ControlButton(
                        icon: Icons.arrow_right_rounded,
                        label: 'Hold Right',
                        accent: const Color(0xFF103225),
                        background: _accent,
                        onDown: () {
                          HapticFeedback.lightImpact();
                          _movingRight = true;
                        },
                        onUp: () => _movingRight = false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PickupKind { need, want }

class _PickupData {
  const _PickupData({
    required this.label,
    required this.amount,
  });

  final String label;
  final int amount;
}

class _FallingPickup {
  _FallingPickup({
    required this.label,
    required this.amount,
    required this.kind,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
  });

  final String label;
  final int amount;
  final _PickupKind kind;
  final double width;
  final double height;
  final double speed;
  double x;
  double y;
  bool resolved = false;
}

const List<_PickupData> _needPool = [
  _PickupData(label: 'Rent', amount: 600),
  _PickupData(label: 'Groceries', amount: 90),
  _PickupData(label: 'Utilities', amount: 120),
  _PickupData(label: 'Medicine', amount: 45),
  _PickupData(label: 'Gas', amount: 50),
  _PickupData(label: 'Internet', amount: 70),
];

const List<_PickupData> _wantPool = [
  _PickupData(label: 'Takeout', amount: 25),
  _PickupData(label: 'Streaming', amount: 18),
  _PickupData(label: 'Skins', amount: 15),
  _PickupData(label: 'Fancy Coffee', amount: 9),
  _PickupData(label: 'Impulse Buy', amount: 35),
  _PickupData(label: 'New Shoes', amount: 90),
];

class _TopStatsRow extends StatelessWidget {
  const _TopStatsRow({
    required this.money,
    required this.score,
  });

  final int money;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TopChip(
            label: '\$$money',
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TopChip(
            label: '$score pts',
            icon: Icons.workspace_premium_rounded,
          ),
        ),
      ],
    );
  }
}

class _TopChip extends StatelessWidget {
  const _TopChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF85EFAC), size: 18),
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

class _PickupCard extends StatelessWidget {
  const _PickupCard({
    required this.pickup,
  });

  final _FallingPickup pickup;

  @override
  Widget build(BuildContext context) {
    final isNeed = pickup.kind == _PickupKind.need;
    final accent = isNeed ? const Color(0xFF85EFAC) : const Color(0xFFFFB084);

    return Container(
      width: pickup.width,
      height: pickup.height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isNeed ? 'Need' : 'Want',
              style: const TextStyle(
                color: Color(0xFF103225),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          Text(
            pickup.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF17382D),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          Text(
            '\$${pickup.amount}',
            style: const TextStyle(
              color: Color(0xFF355E4E),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF85EFAC), Color(0xFF4DD78E)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.42), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF85EFAC).withOpacity(0.22),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Color(0xFF103225),
          size: 34,
        ),
      ),
    );
  }
}

class _OverlayCenter extends StatelessWidget {
  const _OverlayCenter({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.32),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.onStart,
  });

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF163729),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Catch needs. Dodge wants.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bill Dodger now uses smooth free movement, tighter collisions, and safer bounds for mobile screens.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.74),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          CustomButton(
            label: 'Start Round',
            onPressed: onStart,
            prefixIcon: const Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFF103225),
            ),
            style: const CustomButtonStyle.primary(),
          ),
        ],
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.score,
    required this.money,
    required this.message,
    required this.rewards,
    required this.claiming,
    required this.onReplay,
    required this.onClaim,
  });

  final int score;
  final int money;
  final String message;
  final BillDodgerCloseResult rewards;
  final bool claiming;
  final VoidCallback onReplay;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF163729),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Round Complete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ResultChip(label: 'Score', value: '$score'),
              _ResultChip(label: 'Money', value: '\$$money'),
              _ResultChip(label: 'Gold', value: '+${rewards.goldEarned}'),
              _ResultChip(label: 'XP', value: '+${rewards.xpEarned}'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Play Again',
                  onPressed: onReplay,
                  style: const CustomButtonStyle.secondary(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Claim Rewards',
                  isLoading: claiming,
                  onPressed: onClaim,
                  style: const CustomButtonStyle.primary(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
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

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.background,
    required this.onDown,
    required this.onUp,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color background;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArenaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lanePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    final shimmerPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i <= 3; i++) {
      final x = size.width * (i / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lanePaint);
    }

    canvas.drawLine(
      Offset(18, size.height - 100),
      Offset(size.width - 18, size.height - 100),
      shimmerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

