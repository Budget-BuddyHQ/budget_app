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
  static const Color _gold = Color(0xFFFFD45C);
  static const Color _needColor = Color(0xFF85EFAC);
  static const Color _wantColor = Color(0xFFFFB084);
  static const int _roundSeconds = 45;

  final math.Random _random = math.Random();
  final List<_FallingPickup> _pickups = <_FallingPickup>[];
  final FocusNode _focusNode = FocusNode(debugLabel: 'BillDodgerArena');

  Ticker? _ticker;
  Timer? _spawnTimer;
  Timer? _countdownTimer;
  Duration _lastFrame = Duration.zero;

  Size _arenaSize = Size.zero;
  double _playerX = 0;
  double _playerVelocity = 0;
  double _playerTilt = 0;
  bool _movingLeft = false;
  bool _movingRight = false;

  int _money = 1200;
  int _score = 0;
  int _timeLeft = _roundSeconds;
  bool _started = false;
  bool _finished = false;
  bool _claiming = false;
  bool _didClaim = false;

  double get _playerWidth {
    final width = _arenaSize.width <= 0 ? 380.0 : _arenaSize.width;
    return (width * 0.18).clamp(76.0, 112.0).toDouble();
  }

  double get _playerHeight => _playerWidth * 0.92;

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
    _focusNode.dispose();
    super.dispose();
  }

  void _syncArenaSize(Size newSize) {
    if (_arenaSize == Size.zero) {
      _arenaSize = newSize;
      _playerX = math.max(0, (_arenaSize.width - _playerWidth) / 2).toDouble();
      return;
    }

    if (_arenaSize == newSize) {
      return;
    }

    final previousWidth = _arenaSize.width <= 0 ? newSize.width : _arenaSize.width;
    final previousHeight =
        _arenaSize.height <= 0 ? newSize.height : _arenaSize.height;
    final widthRatio = newSize.width / previousWidth;
    final heightRatio = newSize.height / previousHeight;

    _arenaSize = newSize;
    _playerX = (_playerX * widthRatio)
        .clamp(0, math.max(0, _arenaSize.width - _playerWidth))
        .toDouble();

    for (final pickup in _pickups) {
      pickup.width = _pickupWidthForArena();
      pickup.height = pickup.width * 0.74;
      pickup.x = (pickup.x * widthRatio)
          .clamp(0, math.max(0, _arenaSize.width - pickup.width))
          .toDouble();
      pickup.y = (pickup.y * heightRatio)
          .clamp(-pickup.height * 2, _arenaSize.height + pickup.height)
          .toDouble();
    }
  }

  void _startGame() {
    HapticFeedback.lightImpact();
    _focusNode.requestFocus();
    setState(() {
      _money = 1200;
      _score = 0;
      _timeLeft = _roundSeconds;
      _started = true;
      _finished = false;
      _claiming = false;
      _didClaim = false;
      _movingLeft = false;
      _movingRight = false;
      _playerVelocity = 0;
      _playerTilt = 0;
      _pickups.clear();
      _playerX = math.max(0, (_arenaSize.width - _playerWidth) / 2).toDouble();
      _lastFrame = Duration.zero;
    });

    _spawnTimer?.cancel();
    _countdownTimer?.cancel();

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 560), (_) {
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
      _playerVelocity = 0;
      _playerTilt = 0;
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
    const acceleration = 1520.0;
    const friction = 1860.0;
    const maxSpeed = 560.0;

    final input = (_movingRight ? 1.0 : 0.0) - (_movingLeft ? 1.0 : 0.0);

    if (input != 0) {
      _playerVelocity += input * acceleration * deltaSeconds;
    } else if (_playerVelocity != 0) {
      final drag = friction * deltaSeconds;
      if (_playerVelocity.abs() <= drag) {
        _playerVelocity = 0;
      } else {
        _playerVelocity -= _playerVelocity.sign * drag;
      }
    }

    _playerVelocity = _playerVelocity.clamp(-maxSpeed, maxSpeed).toDouble();
    _playerX += _playerVelocity * deltaSeconds;

    final maxX = math.max(0, _arenaSize.width - _playerWidth).toDouble();
    if (_playerX <= 0) {
      _playerX = 0;
      _playerVelocity = math.max(0, _playerVelocity).toDouble();
    } else if (_playerX >= maxX) {
      _playerX = maxX;
      _playerVelocity = math.min(0, _playerVelocity);
    }

    _playerTilt = (_playerVelocity / maxSpeed).clamp(-1.0, 1.0).toDouble();
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
      _money -= 36;
      _score = math.max(0, _score - 12);
    }
  }

  void _handleMissedPickup(_FallingPickup pickup) {
    if (pickup.kind == _PickupKind.need) {
      _money -= 20;
      _score = math.max(0, _score - 8);
    } else {
      _score += 6;
    }
  }

  double _pickupWidthForArena() {
    final width = _arenaSize.width <= 0 ? 380.0 : _arenaSize.width;
    return (width * 0.23).clamp(82.0, 104.0).toDouble();
  }

  void _spawnPickup() {
    if (!_started || _finished || _arenaSize == Size.zero) {
      return;
    }

    final isNeed = _random.nextBool();
    final pool = isNeed ? _needPool : _wantPool;
    final data = pool[_random.nextInt(pool.length)];
    final width = _pickupWidthForArena();
    final height = width * 0.74;
    final maxX = math.max(0, _arenaSize.width - width).toDouble();
    final padding = math.max(8, _arenaSize.width * 0.03).toDouble();
    final x = padding +
        (_random.nextDouble() * math.max(0, maxX - padding * 2).toDouble());

    _pickups.add(
      _FallingPickup(
        label: data.label,
        amount: data.amount,
        kind: isNeed ? _PickupKind.need : _PickupKind.want,
        x: x,
        y: -height - 12,
        width: width,
        height: height,
        speed: (_arenaSize.height * (0.30 + _random.nextDouble() * 0.12))
            .clamp(220.0, 360.0)
            .toDouble(),
      ),
    );
  }

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    final isPressed = event is KeyDownEvent || event is KeyRepeatEvent;
    final isReleased = event is KeyUpEvent;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _movingLeft = isPressed ? true : isReleased ? false : _movingLeft;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _movingRight = isPressed ? true : isReleased ? false : _movingRight;
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) &&
        isPressed &&
        !_claiming) {
      if (!_started) {
        _startGame();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
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
          '+${projected.goldEarned} gold - +${projected.xpEarned} XP - ${result.message}',
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
    _playerVelocity = delta * 22;
    _playerTilt = (_playerVelocity / 560).clamp(-1.0, 1.0).toDouble();
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
          child: Focus(
            autofocus: true,
            focusNode: _focusNode,
            onKeyEvent: _handleKey,
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
                            fontSize: 24,
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
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: const Text(
                      'Collect NEEDS, dodge WANTS, and glide smoothly across the arena. Hold the arrows, use your keyboard, or drag your turtle left and right.',
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
                        _syncArenaSize(constraints.biggest);

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _focusNode.requestFocus(),
                            onHorizontalDragUpdate: (details) {
                              _moveByDrag(details.delta.dx);
                            },
                            child: Stack(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF103225),
                                        Color(0xFF173B2D),
                                        Color(0xFF0B2018),
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
                                Positioned(
                                  left: _playerX,
                                  top: _playerY,
                                  child: _PlayerAvatar(
                                    width: _playerWidth,
                                    height: _playerHeight,
                                    tilt: _playerTilt,
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
                          background: Colors.white.withValues(alpha: 0.06),
                          onDown: () {
                            HapticFeedback.lightImpact();
                            _focusNode.requestFocus();
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
                            _focusNode.requestFocus();
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
  double width;
  double height;
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.92), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 12,
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
    required this.tilt,
  });

  final double width;
  final double height;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt * 0.18,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFB7F7D0), Color(0xFF4DD78E)],
          ),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.46), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF85EFAC).withValues(alpha: 0.24),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 10,
              child: Container(
                width: width * 0.46,
                height: height * 0.34,
                decoration: BoxDecoration(
                  color: const Color(0xFF103225).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.savings_rounded,
                  color: Color(0xFF103225),
                  size: 34,
                ),
              ),
            ),
          ],
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
      color: Colors.black.withValues(alpha: 0.34),
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
      width: 430,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF113528),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
            'Bill Dodger now uses acceleration, friction, keyboard controls, and drag movement so it feels closer to a real arcade glide.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(
                child: _HintBadge(
                  icon: Icons.keyboard_rounded,
                  label: 'Arrow keys',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _HintBadge(
                  icon: Icons.swipe_rounded,
                  label: 'Drag to steer',
                ),
              ),
            ],
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

class _HintBadge extends StatelessWidget {
  const _HintBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFFD45C), size: 18),
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
        color: const Color(0xFF113528),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ResultChip(label: 'Score', value: '$score', accent: const Color(0xFFFFD45C)),
              _ResultChip(label: 'Money', value: '\$$money', accent: const Color(0xFF85EFAC)),
              _ResultChip(
                label: 'Gold',
                value: '+${rewards.goldEarned}',
                accent: const Color(0xFFFFD45C),
              ),
              _ResultChip(
                label: 'XP',
                value: '+${rewards.xpEarned}',
                accent: const Color(0xFF85EFAC),
              ),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
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
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final coinPaint = Paint()
      ..color = const Color(0x22FFD45C)
      ..style = PaintingStyle.fill;

    for (var index = 1; index <= 3; index++) {
      final x = size.width * (index / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lanePaint);
    }

    canvas.drawLine(
      Offset(18, size.height - 100),
      Offset(size.width - 18, size.height - 100),
      shimmerPaint,
    );

    for (var index = 0; index < 14; index++) {
      final dx = (size.width / 14) * index + 12;
      final double  dy = 30 + (index.isEven ? 8 : 0);
      canvas.drawCircle(Offset(dx, dy), 3.5, coinPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
