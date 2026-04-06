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
  static const Color _accent = Color(0xFF85EFAC);
  static const int _roundSeconds = 45;
  static const double _baseMoveSpeed = 440;
  static const double _baseAcceleration = 2400;
  static const double _baseFriction = 2100;
  static const double _maxPlayerTilt = 0.18;

  final math.Random _random = math.Random();
  final FocusNode _focusNode = FocusNode();
  final List<_FallingPickup> _pickups = <_FallingPickup>[];

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
  bool _leftKeyHeld = false;
  bool _rightKeyHeld = false;

  int _money = 1200;
  int _score = 0;
  int _timeLeft = _roundSeconds;
  int _streak = 0;
  int _bestStreak = 0;
  int _wave = 1;
  double _dangerMeter = 0;
  double _intensity = 1;
  double _gameTime = 0; // Added for visual effects
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
    _focusNode.dispose();
    _ticker?.dispose();
    _spawnTimer?.cancel();
    _countdownTimer?.cancel();
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
      _streak = 0;
      _bestStreak = 0;
      _wave = 1;
      _dangerMeter = 0;
      _intensity = 1;
      _gameTime = 0;
      _started = true;
      _finished = false;
      _claiming = false;
      _didClaim = false;
      _pickups.clear();
      _playerX = math.max(0, (_arenaSize.width - _playerWidth) / 2).toDouble();
      _playerVelocity = 0;
      _playerTilt = 0;
      _lastFrame = Duration.zero;
    });

    _focusNode.requestFocus();

    _spawnTimer?.cancel();
    _countdownTimer?.cancel();

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
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
      _leftKeyHeld = false;
      _rightKeyHeld = false;
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
    
    _gameTime += deltaSeconds; // Track total time for visual effects

    _updatePlayer(deltaSeconds);
    _updatePickups(deltaSeconds);

    if (mounted) {
      setState(() {});
    }
  }

  void _updatePlayer(double deltaSeconds) {
    final targetDirection = (_movingRight ? 1.0 : 0.0) - (_movingLeft ? 1.0 : 0.0);
    final targetVelocity = targetDirection * (_baseMoveSpeed * _intensity.clamp(1, 1.8));
    final changeRate = targetDirection == 0 ? _baseFriction : _baseAcceleration;

    if (_playerVelocity < targetVelocity) {
      _playerVelocity = math.min(
        targetVelocity,
        _playerVelocity + changeRate * deltaSeconds,
      );
    } else if (_playerVelocity > targetVelocity) {
      _playerVelocity = math.max(
        targetVelocity,
        _playerVelocity - changeRate * deltaSeconds,
      );
    }

    _playerX += _playerVelocity * deltaSeconds;
    _playerX = _playerX
        .clamp(0, math.max(0, _arenaSize.width - _playerWidth))
        .toDouble();

    final tiltTarget = (_playerVelocity / (_baseMoveSpeed * 1.15)).clamp(-1.0, 1.0).toDouble();
    _playerTilt += (tiltTarget - _playerTilt) * math.min(1, deltaSeconds * 10);
    _playerTilt = _playerTilt.clamp(-_maxPlayerTilt, _maxPlayerTilt).toDouble();
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
    _updateDifficulty();

    if (_money <= 0) {
      _money = 0;
      _finishGame();
    }
  }

  void _handlePickupCollision(_FallingPickup pickup) {
    HapticFeedback.lightImpact();
    if (pickup.kind == _PickupKind.need) {
      _streak += 1;
      _bestStreak = math.max(_bestStreak, _streak);
      final streakBonus = 1 + ((_streak - 1) ~/ 4);
      _money += 26 + (pickup.amount ~/ 14) + streakBonus * 4;
      _score += 14 + streakBonus * 6;
      _dangerMeter = math.max(0, _dangerMeter - 0.12);
    } else {
      _streak = 0;
      _money -= 32 + (pickup.amount ~/ 8);
      _score = math.max(0, _score - 14);
      _dangerMeter = (_dangerMeter + 0.18).clamp(0, 1).toDouble();
    }
  }

  void _handleMissedPickup(_FallingPickup pickup) {
    if (pickup.kind == _PickupKind.need) {
      _streak = 0;
      _money -= 18 + (pickup.amount ~/ 16);
      _score = math.max(0, _score - 10);
      _dangerMeter = (_dangerMeter + 0.10).clamp(0, 1).toDouble();
    } else {
      _score += 8;
      _dangerMeter = math.max(0, _dangerMeter - 0.06);
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

    final wantBias = (0.38 + (_wave * 0.05) + (_dangerMeter * 0.1))
        .clamp(0.38, 0.7)
        .toDouble();
    final isNeed = _random.nextDouble() > wantBias;
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
        y: -height - 12,
        width: width,
        height: height,
        speed: (205 + _random.nextDouble() * 95) * _intensity,
        tilt: (_random.nextDouble() - 0.5) * 0.2,
      ),
    );
  }

  void _updateDifficulty() {
    final elapsedSeconds = (_roundSeconds - _timeLeft).clamp(0, _roundSeconds);
    final computedWave = 1 + (elapsedSeconds ~/ 12);
    _wave = computedWave.clamp(1, 4);
    _intensity = (1 + elapsedSeconds / 36 + (_dangerMeter * 0.18)).clamp(1.0, 1.7).toDouble();
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
    _playerVelocity = (delta * 18).clamp(-_baseMoveSpeed, _baseMoveSpeed).toDouble();
    setState(() {});
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!_started || _finished) {
      return;
    }

    final isLeft = event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA;
    final isRight = event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD;

    if (!isLeft && !isRight) {
      return;
    }

    if (event is KeyDownEvent) {
      if (isLeft && !_leftKeyHeld) {
        _leftKeyHeld = true;
        _movingLeft = true;
        HapticFeedback.selectionClick();
      }
      if (isRight && !_rightKeyHeld) {
        _rightKeyHeld = true;
        _movingRight = true;
        HapticFeedback.selectionClick();
      }
    } else if (event is KeyUpEvent) {
      if (isLeft) {
        _leftKeyHeld = false;
        _movingLeft = false;
      }
      if (isRight) {
        _rightKeyHeld = false;
        _movingRight = false;
      }
    }
  }

  String _gradeMessage() {
    if (_score >= 240) {
      return 'Epic minigame energy. You chained essentials and ruled the arena.';
    }
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
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
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
                  streak: _streak,
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
                    'Collect NEEDS, dodge WANTS, build a streak, and survive each wave. Hold the arrow keys, press A/D, or drag your hero to glide left and right.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RoundPulseBar(
                  label: 'Wave $_wave',
                  value: _dangerMeter,
                  caption: _dangerMeter > 0.66
                      ? 'Pressure is rising - shiny wants are flooding in.'
                      : _dangerMeter > 0.33
                          ? 'Steady pace - keep the streak alive.'
                          : 'You are in control - stack clean catches.',
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _syncArenaSize(constraints.biggest);
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
                                  painter: _ArenaPainter(
                                    gameTime: _gameTime,
                                    dangerMeter: _dangerMeter,
                                  ),
                                ),
                              ),
                              for (final pickup in _pickups)
                                Positioned(
                                  left: pickup.x,
                                  top: pickup.y,
                                  child: _PickupCard(pickup: pickup),
                                ),
                              // REMOVED AnimatedPositioned TO FIX LAG
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
                                      bestStreak: _bestStreak,
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
                          _leftKeyHeld = true;
                        },
                        onUp: () {
                          _movingLeft = false;
                          _leftKeyHeld = false;
                        },
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
                          _rightKeyHeld = true;
                        },
                        onUp: () {
                          _movingRight = false;
                          _rightKeyHeld = false;
                        },
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
    required this.tilt,
  });

  final String label;
  final int amount;
  final _PickupKind kind;
  double width;
  double height;
  final double speed;
  final double tilt;
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
    required this.streak,
  });

  final int money;
  final int score;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;
        final chips = [
          Expanded(
            child: _TopChip(
              label: '\$$money',
              icon: Icons.account_balance_wallet_rounded,
            ),
          ),
          Expanded(
            child: _TopChip(
              label: '$score pts',
              icon: Icons.workspace_premium_rounded,
            ),
          ),
          Expanded(
            child: _TopChip(
              label: '${streak}x streak',
              icon: Icons.local_fire_department_rounded,
            ),
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              Row(
                children: [
                  chips[0],
                  const SizedBox(width: 10),
                  chips[1],
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [chips[2]]),
            ],
          );
        }

        return Row(
          children: [
            chips[0],
            const SizedBox(width: 10),
            chips[1],
            const SizedBox(width: 10),
            chips[2],
          ],
        );
      },
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
      // FITTED BOX ADDED TO PREVENT OVERFLOW
      child: FittedBox(
        fit: BoxFit.scaleDown,
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

    final Color accent =
        isNeed ? const Color(0xFF73E9A6) : const Color(0xFFFFB084);
    final Color accentDark =
        isNeed ? const Color(0xFF39C97A) : const Color(0xFFFF8D5C);
    final IconData icon =
        isNeed ? Icons.check_circle_rounded : Icons.shopping_bag_rounded;

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
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    height: 1.0,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                icon,
                size: 16,
                color: accentDark,
              ),
            ],
          ),
          const Spacer(),
          Text(
            pickup.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF17382D),
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: accent.withValues(alpha: 0.7),
                width: 1,
              ),
            ),
            child: Text(
              '\$${pickup.amount}',
              style: const TextStyle(
                color: Color(0xFF355E4E),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
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
      angle: tilt,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: width * 0.14,
            right: width * 0.14,
            bottom: -8,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF85EFAC).withOpacity(0.25),
              ),
            ),
          ),
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9DFFBF), Color(0xFF4DD78E)],
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
          ),
        ],
      ),
    );
  }
}

class _RoundPulseBar extends StatelessWidget {
  const _RoundPulseBar({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final double value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${(clamped * 100).round()}%',
                style: TextStyle(
                  color: Color.lerp(
                    const Color(0xFF85EFAC),
                    const Color(0xFFFFB084),
                    clamped,
                  ),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(
                      const Color(0xFF73E9A6),
                      const Color(0xFFFF8D5C),
                      clamped,
                    ) ??
                    const Color(0xFF73E9A6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              color: Colors.white.withOpacity(0.74),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveModalWrapper extends StatelessWidget {
  const _ResponsiveModalWrapper({
    required this.maxWidth,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = math.min(maxWidth, constraints.maxWidth);

        return Center( 
          child: Container(
            constraints: BoxConstraints(maxWidth: width),
            child: SingleChildScrollView(
              child: IntrinsicHeight( 
                child: child,
              ),
            ),
          ),
        );
      },
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
    return _ResponsiveModalWrapper(
      maxWidth: 430,
      child: Container(
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
              'Bill Dodger now feels closer to a fast arcade minigame: smoother motion, wave pressure, and keyboard support for testing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.74),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HintBadge(
                  icon: Icons.keyboard_rounded,
                  label: 'Arrow keys / A-D',
                ),
                _HintBadge(
                  icon: Icons.swipe_rounded,
                  label: 'Drag to steer',
                ),
                _HintBadge(
                  icon: Icons.bolt_rounded,
                  label: 'Build streaks',
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
    required this.bestStreak,
    required this.message,
    required this.rewards,
    required this.claiming,
    required this.onReplay,
    required this.onClaim,
  });

  final int score;
  final int money;
  final int bestStreak;
  final String message;
  final BillDodgerCloseResult rewards;
  final bool claiming;
  final VoidCallback onReplay;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return _ResponsiveModalWrapper(
      maxWidth: 440,
      child: Container(
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
                _ResultChip(
                  label: 'Best Streak',
                  value: '${bestStreak}x',
                  accent: const Color(0xFF85EFAC),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 170,
                  child: CustomButton(
                    label: 'Play Again',
                    onPressed: onReplay,
                    style: const CustomButtonStyle.secondary(),
                  ),
                ),
                SizedBox(
                  width: 170,
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

// REWRITTEN PAINTER FOR DYNAMIC SCROLLING GRID
class _ArenaPainter extends CustomPainter {
  _ArenaPainter({
    required this.gameTime,
    required this.dangerMeter,
  });

  final double gameTime;
  final double dangerMeter;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.5;

    final shimmerPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // The floor moves faster as the danger meter rises
    final speedMultiplier = 150.0 + (dangerMeter * 250.0);
    final gridSize = 90.0;
    
    // Calculate the Y offset to create the illusion of forward movement
    final yOffset = (gameTime * speedMultiplier) % gridSize;

    // Draw horizontal scrolling lines
    for (double y = yOffset; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw vertical perspective lanes
    for (var index = 1; index <= 3; index++) {
      final x = size.width * (index / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Static danger-zone warning line at the bottom
    canvas.drawLine(
      Offset(18, size.height - 100),
      Offset(size.width - 18, size.height - 100),
      shimmerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArenaPainter oldDelegate) {
    return oldDelegate.gameTime != gameTime || oldDelegate.dangerMeter != dangerMeter;
  }
}