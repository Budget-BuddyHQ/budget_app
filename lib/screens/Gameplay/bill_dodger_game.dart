import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BillDodgerGameScreen extends StatefulWidget {
  const BillDodgerGameScreen({super.key});

  @override
  State<BillDodgerGameScreen> createState() => _BillDodgerGameScreenState();
}

class _BillDodgerGameScreenState extends State<BillDodgerGameScreen>
    with SingleTickerProviderStateMixin {
  static const Color background = Color(0xFF1A4D3D);
  static const Color cardBg = Color(0xFF254E3F);
  static const Color cardBorder = Color(0xFF3B6B59);
  static const Color accent = Color(0xFF85EFAC);
  static const Color wantColor = Color(0xFFFF8A80);
  static const Color needColor = Color(0xFF8BE9B3);
  static const Color textMuted = Colors.white70;

  static const double laneWidth = 104;
  static const double itemWidth = 88;
  static const double itemHeight = 58;
  static const double playerSize = 68;

  final Random _random = Random();

  late final AnimationController _controller;

  Timer? _spawnTimer;
  Timer? _clockTimer;

  final List<FallingBillItem> _items = [];

  // Game tuning
  final int startingMoney = 1200;
  final int bonusAmount = 35;
  final int penaltyAmount = 45;
  final int startingTime = 45;

  int money = 1200;
  int score = 0;
  int timeLeft = 45;
  double playerX = 1.0; // continuous position across 3 lanes
  double playerVelocity = 0.0;
  bool movingLeft = false;
  bool movingRight = false;
  bool gameStarted = false;
  bool gameOver = false;
  bool showInstructions = true;

  @override
  void initState() {
    super.initState();

    money = startingMoney;
    timeLeft = startingTime;

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
      gameStarted = true;
      gameOver = false;
      showInstructions = false;
      money = startingMoney;
      score = 0;
      timeLeft = startingTime;
      playerX = 1.0;
      playerVelocity = 0.0;
      movingLeft = false;
      movingRight = false;
      _items.clear();
    });

    _controller.repeat();

    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      _spawnItem();
    });

    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || gameOver) return;
      setState(() {
        timeLeft--;
      });

      if (timeLeft <= 0 || money <= 0) {
        _endGame();
      }
    });
  }

  void _endGame() {
    _spawnTimer?.cancel();
    _clockTimer?.cancel();
    _controller.stop();

    setState(() {
      gameOver = true;
      gameStarted = false;
    });
  }

  void _tick() {
    if (!mounted || gameOver) return;

    const double speed = 3.8;
    final double playAreaHeight = MediaQuery.of(context).size.height * 0.72;

    for (final item in _items) {
      item.y += speed;
    }

    // Continuous player movement with velocity and easing
    if (movingLeft) {
      playerVelocity -= 0.005;
    }
    if (movingRight) {
      playerVelocity += 0.005;
    }

    playerVelocity = playerVelocity.clamp(-0.16, 0.16);
    playerX += playerVelocity;
    playerX = playerX.clamp(0.0, 2.0);

    // Friction / gradual stop
    if (!movingLeft && !movingRight) {
      playerVelocity *= 0.92;
      if (playerVelocity.abs() < 0.002) {
        playerVelocity = 0.0;
      }
    }

    final double playerY = playAreaHeight - playerSize - 16;
    final double playerLeft = _playerLeft(playerX, MediaQuery.of(context).size.width - 32);

    final List<FallingBillItem> toRemove = [];

    for (final item in _items) {
      final bool verticalHit =
          item.y + itemHeight >= playerY && item.y <= playerY + playerSize;

      final double itemLeft = _laneLeft(item.lane, MediaQuery.of(context).size.width - 32);
      final bool horizontalHit = playerLeft < itemLeft + itemWidth && playerLeft + playerSize > itemLeft;

      if (verticalHit && horizontalHit && !item.resolved) {
        item.resolved = true;

        if (item.type == BillType.need) {
          money += bonusAmount;
          score += 12;
        } else {
          money -= penaltyAmount;
          score = max(0, score - 8);
        }

        toRemove.add(item);
      } else if (item.y > playAreaHeight + 12) {
        // If a NEED is missed, small consequence.
        if (item.type == BillType.need && !item.resolved) {
          money -= 20;
          score = max(0, score - 4);
        } else if (item.type == BillType.want && !item.resolved) {
          // Good job dodging a want.
          score += 5;
        }

        toRemove.add(item);
      }
    }

    _items.removeWhere((item) => toRemove.contains(item));

    if (money <= 0) {
      _endGame();
    } else {
      setState(() {});
    }
  }

  void _spawnItem() {
    if (!mounted || gameOver) return;

    final bool spawnNeed = _random.nextBool();

    final List<_BillData> source =
        spawnNeed ? _needItems : _wantItems;

    final _BillData data = source[_random.nextInt(source.length)];

    // 3 lanes
    final int lane = _random.nextInt(3);

    _items.add(
      FallingBillItem(
        lane: lane,
        y: -itemHeight,
        label: data.label,
        amount: data.amount,
        type: spawnNeed ? BillType.need : BillType.want,
      ),
    );

    setState(() {});
  }

  void _moveLeft() {
    if (!gameStarted) return;
    movingLeft = true;
    movingRight = false;
    playerVelocity = (playerVelocity - 0.02).clamp(-0.16, 0.16);
  }

  void _moveRight() {
    if (!gameStarted) return;
    movingRight = true;
    movingLeft = false;
    playerVelocity = (playerVelocity + 0.02).clamp(-0.16, 0.16);
  }

  void _stopMovement() {
    movingLeft = false;
    movingRight = false;
  }

  String _moneyText(int value) {
    final sign = value < 0 ? '-' : '';
    return '$sign\$${value.abs()}';
  }

  String _gradeMessage() {
    if (score >= 180) return 'Excellent impulse control.';
    if (score >= 120) return 'Great job separating needs from wants.';
    if (score >= 70) return 'Solid effort — keep practicing.';
    return 'You are learning. Try to protect your essentials first.';
  }

  @override
Widget build(BuildContext context) {
  final double totalWidth = MediaQuery.of(context).size.width - 32;
  final double playAreaWidth = totalWidth;
  final double playAreaHeight = MediaQuery.of(context).size.height * 0.72;

  return Scaffold(
    backgroundColor: background,
    appBar: AppBar(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Bill Dodger',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TopStatsBar(
              money: money,
              score: score,
              timeLeft: timeLeft,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InstructionCard(
                    showInstructions: showInstructions,
                    startingMoney: startingMoney,
                    bonusAmount: bonusAmount,
                    penaltyAmount: penaltyAmount,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      width: playAreaWidth,
                      height: playAreaHeight,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Focus(
                          autofocus: true,
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft) {
                                _moveLeft();
                                return KeyEventResult.handled;
                              } else if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowRight) {
                                _moveRight();
                                return KeyEventResult.handled;
                              }
                            } else if (event is KeyUpEvent) {
                              if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowLeft ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.arrowRight) {
                                _stopMovement();
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: GestureDetector(
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity == null) return;
                              if (details.primaryVelocity! < 0) {
                                _moveLeft();
                              } else if (details.primaryVelocity! > 0) {
                                _moveRight();
                              }
                            },
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _LanePainter(),
                                  ),
                                ),

                                Positioned(
                                  top: 12,
                                  left: 12,
                                  right: 12,
                                  child: Row(
                                    children: [
                                      _LegendPill(
                                        label: 'Collect NEEDS',
                                        color: needColor,
                                        icon: Icons.check_circle,
                                      ),
                                      const SizedBox(width: 8),
                                      _LegendPill(
                                        label: 'Dodge WANTS',
                                        color: wantColor,
                                        icon: Icons.close_rounded,
                                      ),
                                    ],
                                  ),
                                ),

                                ..._items.map((item) {
                                  final double left =
                                      _laneLeft(item.lane, playAreaWidth);

                                  return Positioned(
                                    left: left,
                                    top: item.y,
                                    child: _FallingBillCard(item: item),
                                  );
                                }),

                                Positioned(
                                  left: _playerLeft(playerX, playAreaWidth),
                                  top: playAreaHeight - playerSize - 16,
                                  child: _TurtlePlayer(size: playerSize),
                                ),

                                if (!gameStarted && !gameOver)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.22),
                                      child: Center(
                                        child: ElevatedButton(
                                          onPressed: _startGame,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: accent,
                                            foregroundColor: background,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 28,
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: const Text(
                                            'Start Game',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                if (gameOver)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.42),
                                      child: Center(
                                        child: Container(
                                          margin: const EdgeInsets.all(20),
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF214737),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border:
                                                Border.all(color: cardBorder),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Round Complete',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Final Score: $score',
                                                style: const TextStyle(
                                                  color: accent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Ending Money: \$${money.clamp(0, 999999)}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                _gradeMessage(),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton(
                                                onPressed: _startGame,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: accent,
                                                  foregroundColor: background,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: const Text('Play Again'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PriceGuideCard(
                    startingMoney: startingMoney,
                    bonusAmount: bonusAmount,
                    penaltyAmount: penaltyAmount,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  double _laneLeft(int lane, double playAreaWidth) {
    final double totalLaneWidth = playAreaWidth / 3;
    return lane * totalLaneWidth + (totalLaneWidth - itemWidth) / 2;
  }

  double _playerLeft(double playerX, double playAreaWidth) {
    final double totalLaneWidth = playAreaWidth / 3;
    return playerX * totalLaneWidth + (totalLaneWidth - playerSize) / 2 + 10;
  }
}

enum BillType { need, want }

class FallingBillItem {
  FallingBillItem({
    required this.lane,
    required this.y,
    required this.label,
    required this.amount,
    required this.type,
    this.resolved = false,
  });

  final int lane;
  double y;
  final String label;
  final int amount;
  final BillType type;
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

  @override //here 
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4E3B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF85EFAC),
            child: Text('🐢', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
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
  const _StatText({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.showInstructions,
    required this.startingMoney,
    required this.bonusAmount,
    required this.penaltyAmount,
  });

  final bool showInstructions;
  final int startingMoney;
  final int bonusAmount;
  final int penaltyAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF254E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B6B59)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFF85EFAC), size: 18),
              SizedBox(width: 8),
              Text(
                'How Bill Dodger Works',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Bills fall from the top. Move left or right to collect NEEDS and avoid WANTS. The game teaches needs vs. wants and impulse control.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 10),
          Text(
            'Start with \$$startingMoney • NEED bonus +\$$bonusAmount • WANT penalty -\$$penaltyAmount',
            style: const TextStyle(
              color: Color(0xFF85EFAC),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showInstructions) ...[
            const SizedBox(height: 8),
            const Text(
              'Swipe across the game area or use the arrow buttons below.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
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
        color: const Color(0xFF18392E).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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

  final FallingBillItem item;

  @override
  Widget build(BuildContext context) {
    final bool isNeed = item.type == BillType.need;
    final Color chipColor = isNeed
        ? const Color(0xFF8BE9B3)
        : const Color(0xFFFF8A80);

    return Container(
      width: 88,
      height: 58,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF7F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNeed
              ? const Color(0xFFBCEFD1)
              : const Color(0xFFFFC4BF),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: chipColor,
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
            ],
          ),
          const Spacer(),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF17382D),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '\$${item.amount}',
            style: const TextStyle(
              color: Color(0xFF355E4E),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _TurtlePlayer extends StatelessWidget {
  const _TurtlePlayer({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF85EFAC),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.32),
          width: 2,
        ),
      ),
      child: const Center(
        child: Text(
          '🐢',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}

class _ControlsCard extends StatelessWidget {
  const _ControlsCard({
    required this.onLeft,
    required this.onRight,
  });

  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF254E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B6B59)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Controls',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLeft,
                  icon: const Icon(Icons.arrow_left_rounded),
                  label: const Text('Move Left'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRight,
                  icon: const Icon(Icons.arrow_right_rounded),
                  label: const Text('Move Right'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF85EFAC),
                    foregroundColor: const Color(0xFF1A4D3D),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceGuideCard extends StatelessWidget {
  const _PriceGuideCard({
    required this.startingMoney,
    required this.bonusAmount,
    required this.penaltyAmount,
  });

  final int startingMoney;
  final int bonusAmount;
  final int penaltyAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF254E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B6B59)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: Color(0xFF85EFAC), size: 18),
              SizedBox(width: 8),
              Text(
                'Learning Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Needs are essential payments like rent, groceries, medicine, and utilities. Wants are optional or impulse purchases. In this game, collecting a Need rewards you, while getting hit by a Want costs you money.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final double laneWidth = size.width / 3;

    for (int i = 1; i < 3; i++) {
      final x = laneWidth * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lanePaint);
    }

    final Paint dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (double y = 60; y < size.height; y += 24) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}