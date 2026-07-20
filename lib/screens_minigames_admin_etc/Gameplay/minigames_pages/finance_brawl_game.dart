import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers_that_updates_stats/user_stats_controller.dart';
import '../../../widgets_custom_lotties/game_toast.dart';

class FinanceBrawlCloseResult {
  const FinanceBrawlCloseResult({
    required this.goldEarned,
    required this.xpEarned,
    required this.syncState,
  });

  final int goldEarned;
  final int xpEarned;
  final StatsActionResult syncState;
}

class FinanceQuestion {
  const FinanceQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class ShuffledQuizQuestion {
  ShuffledQuizQuestion({
    required this.question,
    required this.shuffledOptions,
    required this.correctOptionText,
    required this.explanation,
  });

  final String question;
  final List<String> shuffledOptions;
  final String correctOptionText;
  final String explanation;
}

class BrawlUpgrade {
  const BrawlUpgrade({
    required this.name,
    required this.description,
    required this.icon,
    required this.action,
  });

  final String name;
  final String description;
  final IconData icon;
  final VoidCallback action;
}

class FinanceBrawlScreen extends StatefulWidget {
  const FinanceBrawlScreen({super.key});

  @override
  State<FinanceBrawlScreen> createState() => _FinanceBrawlScreenState();
}

class _FinanceBrawlScreenState extends State<FinanceBrawlScreen> with TickerProviderStateMixin {
  late final Ticker _ticker;
  final FocusNode _keyboardFocusNode = FocusNode();
  
  late Size _canvasSize;
  Offset _playerPos = const Offset(800, 800); 
  final double _playerRadius = 22.0;
  int _playerHp = 100;
  final int _playerMaxHp = 100;
  
  final double _mapWidth = 1600.0;
  final double _mapHeight = 1600.0;
  
  final List<Offset> _treePositions = [];
  final double _treeRadius = 20.0;
  final List<Offset> _rockPositions = [];
  final double _rockRadius = 14.0;
  
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  
  int _kills = 0;
  int _killsNeededForLevelUp = 6;
  int _wave = 1;
  int _goldAccumulated = 0;
  int _xpAccumulated = 0;
  bool _isGameOver = false;
  bool _isSavingAndExiting = false;
  bool _bossActive = false;
  
  double _attackSpeedMultiplier = 1.0;
  double _projectileDamage = 25.0;
  final double _projectileSpeed = 360.0;
  int _projectileCount = 1;
  double _playerSpeed = 210.0;

  double _lastSpawnTime = 0.0;
  double _lastAttackTime = 0.0;
  double _totalElapsedTime = 0.0;
  
  final List<_Monster> _monsters = [];
  final List<_Projectile> _projectiles = [];
  final List<_Particle> _particles = [];
  final List<_TreasureChest> _chests = [];
  final double _chestRadius = 16.0;
  final Random _rand = Random();

  bool _isQuizOpen = false;
  bool _isUpgradeChoiceOpen = false;
  
  int _quizCorrectCount = 0;
  int _quizQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswerSubmitted = false;
  List<ShuffledQuizQuestion> _activeQuizQuestions = [];

  final List<FinanceQuestion> _questionBank = const [
    FinanceQuestion(
      question: "What is an 'emergency fund' generally used for?",
      options: ["Buying concerts tickets", "Unexpected critical expenses like medical bills", "Investing in volatile trendy stocks", "Paying for streaming subscriptions"],
      correctIndex: 1,
      explanation: "An emergency fund protects you against unexpected setbacks without ruining your budget or going into debt.",
    ),
    FinanceQuestion(
      question: "If you leave \$100 in a savings account with a 5% annual interest rate, how much is there after 1 year?",
      options: ["\$105", "\$100", "\$150", "\$110"],
      correctIndex: 0,
      explanation: "Simple interest calculates 5% of \$100, which yields \$5, bringing your total account value up to \$105.",
    ),
    FinanceQuestion(
      question: "What does 'inflation' do to your money's purchasing power over time?",
      options: ["Increases your purchasing power", "Keeps it exactly identical", "Decreases its value, making goods cost more", "Multiplies your cash balances automatically"],
      correctIndex: 2,
      explanation: "Inflation represents the general increase in prices, meaning your standard dollar buys less in the future.",
    ),
    FinanceQuestion(
      question: "Which of these features carries a risk of losing your original principal investment?",
      options: ["A certified High-Yield Savings Account", "Purchasing individual shares of corporate stocks", "A bank certificate of deposit (CD)", "A standard cash checking account"],
      correctIndex: 1,
      explanation: "Stocks fluctuate dynamically based on business health and public markets, meaning you can lose value.",
    ),
    FinanceQuestion(
      question: "What is the difference between a credit card and a debit card?",
      options: [
        "Debit cards borrow funds from a bank; Credit cards tap your checking balance directly.",
        "Credit cards instantly withdraw money you currently own; Debit cards act as loans.",
        "Debit cards deduct funds immediately from your checking account; Credit cards loan funds up to a limit.",
        "There is no functional financial operational difference."
      ],
      correctIndex: 2,
      explanation: "Debit is your own cash immediately. Credit is borrowing bank funds that must be paid back later.",
    ),
    FinanceQuestion(
      question: "What does 'paying yourself first' mean in budgeting?",
      options: ["Buy clothes before paying bills", "Put money into savings as soon as you are paid before spending the rest", "Give cash to family immediately", "Spend your entire check on leisure items"],
      correctIndex: 1,
      explanation: "Prioritizing savings goals first guarantees you build financial security instead of only saving left-over pennies.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 20; i++) {
      Offset pos = Offset(_rand.nextDouble() * (_mapWidth - 200) + 100, _rand.nextDouble() * (_mapHeight - 200) + 100);
      if ((pos - const Offset(800, 800)).distance > 150) _treePositions.add(pos);
    }
    for (int i = 0; i < 20; i++) {
      Offset pos = Offset(_rand.nextDouble() * (_mapWidth - 200) + 100, _rand.nextDouble() * (_mapHeight - 200) + 100);
      if ((pos - const Offset(800, 800)).distance > 150) _rockPositions.add(pos);
    }

    _ticker = createTicker(_updateGameLoop);
    _ticker.start();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _ticker.dispose();
    super.dispose();
  }

  bool _isCollidingWithObstacles(Offset pos, double radius) {
    for (final tree in _treePositions) {
      if ((pos - tree).distance < (radius + _treeRadius)) return true;
    }
    for (final rock in _rockPositions) {
      if ((pos - rock).distance < (radius + _rockRadius)) return true;
    }
    return false;
  }

  void _updateGameLoop(Duration elapsed) {
    if (_isQuizOpen || _isUpgradeChoiceOpen || _isGameOver || _isSavingAndExiting) return;

    final double dt = (elapsed.inMicroseconds / 1000000.0) - _totalElapsedTime;
    _totalElapsedTime = elapsed.inMicroseconds / 1000000.0;

    if (dt <= 0 || dt > 0.1) return;

    setState(() {
      // 1. Process Keyboard Movement Vectors
      double dx = 0.0;
      double dy = 0.0;
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) || _pressedKeys.contains(LogicalKeyboardKey.keyW)) dy -= 1.0;
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) || _pressedKeys.contains(LogicalKeyboardKey.keyS)) dy += 1.0;
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || _pressedKeys.contains(LogicalKeyboardKey.keyA)) dx -= 1.0;
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) || _pressedKeys.contains(LogicalKeyboardKey.keyD)) dx += 1.0;

      if (dx != 0 || dy != 0) {
        double len = sqrt(dx * dx + dy * dy);
        Offset dynamicStep = Offset(dx / len, dy / len) * _playerSpeed * dt;
        
        Offset targetX = Offset((_playerPos.dx + dynamicStep.dx).clamp(_playerRadius, _mapWidth - _playerRadius), _playerPos.dy);
        if (!_isCollidingWithObstacles(targetX, _playerRadius)) _playerPos = targetX;

        Offset targetY = Offset(_playerPos.dx, (_playerPos.dy + dynamicStep.dy).clamp(_playerRadius, _mapHeight - _playerRadius));
        if (!_isCollidingWithObstacles(targetY, _playerRadius)) _playerPos = targetY;
      }

      // 1b. Handle Treasure Chest collection
      for (int i = _chests.length - 1; i >= 0; i--) {
        final chest = _chests[i];
        double dist = (_playerPos - chest.pos).distance;
        if (dist < (_playerRadius + _chestRadius)) {
          _chests.removeAt(i);
          int healthBonus = (_playerHp / 2).floor();
          if (healthBonus < 1) healthBonus = 1;
          _playerHp = min(_playerMaxHp, _playerHp + healthBonus);

          GameToast.show(
            context,
            title: "TREASURE CLAIMED!",
            message: "Recovered +$healthBonus HP from the market windfall!",
            icon: Icons.card_giftcard_rounded,
            accent: const Color(0xFFE1BB72),
          );
        }
      }

      // 2. Weapon Auto-Firing
      _lastAttackTime += dt;
      double currentAttackCooldown = 0.6 / _attackSpeedMultiplier;
      if (_lastAttackTime >= currentAttackCooldown && _monsters.isNotEmpty) {
        _lastAttackTime = 0;
        _fireProjectiles();
      }

      // 3. Spawning Swarms or Boss Entities
      if (_wave % 5 == 0) {
        if (!_bossActive && _monsters.isEmpty) {
          _spawnBoss();
        }
      } else {
        _lastSpawnTime += dt;
        double spawnInterval = max(0.18, 1.6 - (_wave * 0.16));
        if (_lastSpawnTime >= spawnInterval) {
          _lastSpawnTime = 0;
          _spawnMonster();
        }
      }

      // 4. Projectile Vector Updates and Obstacle Hits
      for (int i = _projectiles.length - 1; i >= 0; i--) {
        final p = _projectiles[i];
        p.pos += p.velocity * dt;
        
        if (_isCollidingWithObstacles(p.pos, 4.0)) {
          _projectiles.removeAt(i);
          continue;
        }

        if (p.pos.dx < 0 || p.pos.dx > _mapWidth || p.pos.dy < 0 || p.pos.dy > _mapHeight) {
          _projectiles.removeAt(i);
        }
      }

      // 5. Intelligent Monster Movement & Slide-Routing Around Obstacles
      for (int i = _monsters.length - 1; i >= 0; i--) {
        final m = _monsters[i];
        Offset direction = _playerPos - m.pos;
        double dist = direction.distance;
        
        if (dist > 2) {
          Offset dirNormalized = direction / dist;
          Offset step = dirNormalized * m.speed * dt;
          Offset targetPos = m.pos + step;

          if (!_isCollidingWithObstacles(targetPos, m.radius)) {
            m.pos = targetPos;
          } else {
            Offset slideLeft = Offset(-dirNormalized.dy, dirNormalized.dx) * m.speed * dt;
            Offset slideRight = Offset(dirNormalized.dy, -dirNormalized.dx) * m.speed * dt;
            
            Offset testLeft = m.pos + slideLeft;
            Offset testRight = m.pos + slideRight;
            
            if (!_isCollidingWithObstacles(testLeft, m.radius)) {
              m.pos = testLeft;
            } else if (!_isCollidingWithObstacles(testRight, m.radius)) {
              m.pos = testRight;
            } else {
              m.pos -= dirNormalized * (m.speed * 0.4) * dt;
            }
          }
        }

        if (dist < (_playerRadius + m.radius)) {
          _playerHp -= (m.dps * dt).ceil();
          if (_playerHp <= 0) {
            _playerHp = 0;
            _endGame();
          }
        }
      }

      // 6. Projectile Collisions on Mobs
      for (int pIdx = _projectiles.length - 1; pIdx >= 0; pIdx--) {
        final p = _projectiles[pIdx];
        bool projectileDestroyed = false;

        for (int mIdx = _monsters.length - 1; mIdx >= 0; mIdx--) {
          final m = _monsters[mIdx];
          double dist = (p.pos - m.pos).distance;

          if (dist < (m.radius + 5)) {
            m.hp -= p.damage;
            projectileDestroyed = true;
            _spawnExplosion(m.pos, m.color);

            if (m.hp <= 0) {
              _monsters.removeAt(mIdx);
              _kills++;
              _goldAccumulated += m.goldValue;
              _xpAccumulated += m.isBoss ? 50 : 5;

              if (m.isBoss) {
                _bossActive = false;
                _chests.add(_TreasureChest(pos: m.pos));
                _triggerQuizGate();
              } else if (_wave % 5 != 0 && _kills >= _killsNeededForLevelUp) {
                _triggerQuizGate();
              }
            }
            break;
          }
        }
        if (projectileDestroyed) {
          _projectiles.removeAt(pIdx);
        }
      }

      // 7. Particle Physics Lifecycles
      for (int i = _particles.length - 1; i >= 0; i--) {
        final part = _particles[i];
        part.pos += part.velocity * dt;
        part.life -= dt;
        if (part.life <= 0) {
          _particles.removeAt(i);
        }
      }
    });
  }

  void _spawnMonster() {
    if (!mounted) return;
    
    double angle = _rand.nextDouble() * pi * 2;
    double spawnDist = 520.0; 
    double x = (_playerPos.dx + cos(angle) * spawnDist).clamp(20.0, _mapWidth - 20.0);
    double y = (_playerPos.dy + sin(angle) * spawnDist).clamp(20.0, _mapHeight - 20.0);

    Color monsterColor = const Color(0xFFE25C5C);
    double hp = 30.0 + (_wave * 9);
    double speed = 85.0 + _rand.nextInt(35); 
    double radius = 13.0;
    int gold = 4;

    if (_wave >= 3 && _rand.nextDouble() > 0.6) {
      monsterColor = const Color(0xFFA65CE2); 
      hp *= 1.8;
      radius = 17.0;
      gold = 9;
    }

    _monsters.add(_Monster(
      pos: Offset(x, y),
      hp: hp,
      maxHp: hp,
      speed: speed,
      radius: radius,
      color: monsterColor,
      dps: 14.0 + (_wave * 3.0),
      goldValue: gold,
    ));
  }

  void _spawnBoss() {
    _bossActive = true;
    double angle = _rand.nextDouble() * pi * 2;
    double x = (_playerPos.dx + cos(angle) * 400.0).clamp(60.0, _mapWidth - 60.0);
    double y = (_playerPos.dy + sin(angle) * 400.0).clamp(60.0, _mapHeight - 60.0);

    _monsters.add(_Monster(
      pos: Offset(x, y),
      hp: 350.0 + (_wave * 80.0),
      maxHp: 350.0 + (_wave * 80.0),
      speed: 105.0,
      radius: 36.0,
      color: const Color(0xFFFF2F55),
      dps: 35.0 + (_wave * 5.0),
      goldValue: 120,
      isBoss: true,
    ));

    GameToast.show(
      context,
      title: "BOSS ENCOUNTER",
      message: "Systemic market risk detected! Defeat the Boss to advance.",
      icon: Icons.warning_amber_rounded,
      accent: const Color(0xFFFF2F55),
    );
  }

  void _fireProjectiles() {
    var sortedMonsters = List<_Monster>.from(_monsters);
    sortedMonsters.sort((a, b) => (a.pos - _playerPos).distance.compareTo((b.pos - _playerPos).distance));

    int shots = min(_projectileCount, sortedMonsters.length);
    for (int i = 0; i < shots; i++) {
      final target = sortedMonsters[i];
      Offset direction = target.pos - _playerPos;
      double dist = direction.distance;
      if (dist == 0) continue;
      
      Offset normalizedVelocity = (direction / dist) * _projectileSpeed;
      _projectiles.add(_Projectile(
        pos: _playerPos,
        velocity: normalizedVelocity,
        damage: _projectileDamage,
      ));
    }
  }

  void _spawnExplosion(Offset center, Color color) {
    for (int i = 0; i < 6; i++) {
      double angle = _rand.nextDouble() * pi * 2;
      double pSpeed = 60.0 + _rand.nextDouble() * 50;
      _particles.add(_Particle(
        pos: center,
        velocity: Offset(cos(angle), sin(angle)) * pSpeed,
        color: color,
        life: 0.22,
      ));
    }
  }

  void _triggerQuizGate() {
    var pooledQuestions = List<FinanceQuestion>.from(_questionBank)..shuffle(_rand);
    var chosenRawQuestions = pooledQuestions.take(3).toList();
    
    _activeQuizQuestions = chosenRawQuestions.map((q) {
      List<String> optionsCopy = List<String>.from(q.options);
      String correctText = optionsCopy[q.correctIndex];
      optionsCopy.shuffle(_rand);
      
      return ShuffledQuizQuestion(
        question: q.question,
        shuffledOptions: optionsCopy,
        correctOptionText: correctText,
        explanation: q.explanation,
      );
    }).toList();
    
    _quizCorrectCount = 0;
    _quizQuestionIndex = 0;
    _selectedAnswerIndex = null;
    _isAnswerSubmitted = false;
    _isQuizOpen = true;
  }

  void _submitQuizAnswer() {
    if (_selectedAnswerIndex == null || _isAnswerSubmitted) return;

    setState(() {
      _isAnswerSubmitted = true;
      final currentQuestion = _activeQuizQuestions[_quizQuestionIndex];
      if (currentQuestion.shuffledOptions[_selectedAnswerIndex!] == currentQuestion.correctOptionText) {
        _quizCorrectCount++;
      }
    });
  }

  void _nextQuizQuestion() {
    setState(() {
      if (_quizQuestionIndex < 2) {
        _quizQuestionIndex++;
        _selectedAnswerIndex = null;
        _isAnswerSubmitted = false;
      } else {
        _isQuizOpen = false;
        if (_quizCorrectCount == 3) {
          _isUpgradeChoiceOpen = true;
        } else {
          _kills = 0; 
          _wave++;
          _killsNeededForLevelUp = 6 + (_wave * 3);
          GameToast.show(
            context,
            title: "Quiz Result: $_quizCorrectCount/3",
            message: "Get a perfect 3/3 for upgrades! Grid reinforced.",
            icon: Icons.school_rounded,
            accent: const Color(0xFFE1BB72),
          );
        }
      }
    });
  }

  List<BrawlUpgrade> _getUpgradeOptions() {
    return [
      BrawlUpgrade(
        name: "Liquid Capital Multiplier",
        description: "Fire an extra automatic defensive projectile (+1 Projectile)",
        icon: Icons.toll_rounded,
        action: () => _projectileCount++,
      ),
      BrawlUpgrade(
        name: "Compound Fire Rate",
        description: "Speed up firing frequency cycle intervals (+35% Attack Speed)",
        icon: Icons.trending_up_rounded,
        action: () => _attackSpeedMultiplier += 0.35,
      ),
      BrawlUpgrade(
        name: "High Yield Attack Value",
        description: "Increase basic damage output forces (+15 Damage)",
        icon: Icons.gavel_rounded,
        action: () => _projectileDamage += 15,
      ),
      BrawlUpgrade(
        name: "Diversified Asset Runspeed",
        description: "Boost movement agility velocity vectors (+40 Speed)",
        icon: Icons.directions_run_rounded,
        action: () => _playerSpeed += 40.0,
      ),
    ]..shuffle(_rand);
  }

  void _selectUpgrade(BrawlUpgrade choice) {
    setState(() {
      choice.action();
      _isUpgradeChoiceOpen = false;
      
      _kills = 0;
      _wave++;
      _killsNeededForLevelUp = 6 + (_wave * 3);
      
      GameToast.show(
        context,
        title: "Upgrade Active!",
        message: "${choice.name} initialized. Next wave incoming.",
        icon: Icons.bolt_rounded,
        accent: const Color(0xFF85EFAC),
      );
    });
  }

  void _endGame() {
    _isGameOver = true;
    _ticker.stop();
  }

  Future<void> _exitAndSyncData() async {
    if (_isSavingAndExiting) return;
    setState(() {
      _isSavingAndExiting = true;
    });

    final controller = context.read<UserStatsController>();
    
    final Map<String, dynamic> payload = {
      'gold_earned': _goldAccumulated,
      'xp_earned': _xpAccumulated,
      'literacy_points': _wave * 12,
      'title': 'Finance Brawl Run Complete',
      'description': 'Reached Wave $_wave and cleared $_kills monsters safely.',
    };

    StatsActionResult syncResult = await controller.applyChallengePayload(payload);

    if (mounted) {
      Navigator.of(context).pop(FinanceBrawlCloseResult(
        goldEarned: _goldAccumulated,
        xpEarned: _xpAccumulated,
        syncState: syncResult,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UserStatsController>();
    final equippedSkinId = controller.stats.equippedSkin;

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          _pressedKeys.add(event.logicalKey);
        } else if (event is KeyUpEvent) {
          _pressedKeys.remove(event.logicalKey);
        }
        return KeyEventResult.handled;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1E19),
        body: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

            double camX = (_canvasSize.width / 2) - _playerPos.dx;
            double camY = (_canvasSize.height / 2) - _playerPos.dy;

            if (_canvasSize.width < _mapWidth) {
              camX = camX.clamp(_canvasSize.width - _mapWidth, 0.0);
            } else {
              camX = (_canvasSize.width - _mapWidth) / 2;
            }

            if (_canvasSize.height < _mapHeight) {
              camY = camY.clamp(_canvasSize.height - _mapHeight, 0.0);
            } else {
              camY = (_canvasSize.height - _mapHeight) / 2;
            }

            return Stack(
              children: [
                ClipRect(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _BrawlPainter(
                      playerPos: _playerPos,
                      playerRadius: _playerRadius,
                      playerHp: _playerHp,
                      playerMaxHp: _playerMaxHp,
                      monsters: _monsters,
                      projectiles: _projectiles,
                      particles: _particles,
                      chests: _chests,
                      chestRadius: _chestRadius,
                      equippedSkinId: equippedSkinId,
                      treePositions: _treePositions,
                      treeRadius: _treeRadius,
                      rockPositions: _rockPositions,
                      rockRadius: _rockRadius,
                      mapWidth: _mapWidth,
                      mapHeight: _mapHeight,
                      camOffset: Offset(camX, camY),
                    ),
                  ),
                ),

                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1814).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1F4D3E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _wave % 5 == 0 ? "BOSS WAVE $_wave" : "WAVE $_wave",
                              style: TextStyle(color: _wave % 5 == 0 ? const Color(0xFFFF2F55) : const Color(0xFF85EFAC), fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _wave % 5 == 0 ? "Defeat the Systemic Threat!" : "Kills: $_kills / $_killsNeededForLevelUp",
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1814).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF1F4D3E)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.toll_rounded, color: Color(0xFFE1BB72), size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  "$_goldAccumulated",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFE25C5C).withValues(alpha: 0.955),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            onPressed: () {
                              _ticker.stop();
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF10281F),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1F4D3E))),
                                  title: const Text("PAUSE & BANK REWARDS?", style: TextStyle(color: Color(0xFF85EFAC), fontWeight: FontWeight.w900)),
                                  content: Text("Do you want to leave right now? Current accumulated earnings ($_goldAccumulated gold) will be stored safely."),
                                  actions: [
                                    TextButton(
                                      child: const Text("RESUME GAME", style: TextStyle(color: Colors.white60)),
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        _ticker.start();
                                      },
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE25C5C)),
                                      child: const Text("SAVE AND QUIT"),
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        _exitAndSyncData();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                if (_isQuizOpen) _buildQuizOverlay(),
                if (_isUpgradeChoiceOpen) _buildUpgradeOverlay(),
                if (_isGameOver || _isSavingAndExiting) _buildGameOverOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuizOverlay() {
    final q = _activeQuizQuestions[_quizQuestionIndex];
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            color: const Color(0xFF12231C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFF6CB6DA), width: 2)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("LITERACY CHECKPOINT (${_quizQuestionIndex + 1}/3)", style: const TextStyle(color: Color(0xFF6CB6DA), fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 16),
                  Text(q.question, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  ...List.generate(q.shuffledOptions.length, (idx) {
                    Color optionBorderColor = Colors.white.withValues(alpha: 0.12);
                    Color optionBgColor = const Color(0xFF0A1612);
                    final optionText = q.shuffledOptions[idx];

                    if (_isAnswerSubmitted) {
                      if (optionText == q.correctOptionText) {
                        optionBorderColor = const Color(0xFF85EFAC);
                        optionBgColor = const Color(0xFF143525);
                      } else if (_selectedAnswerIndex == idx) {
                        optionBorderColor = const Color(0xFFE25C5C);
                        optionBgColor = const Color(0xFF381B1B);
                      }
                    } else if (_selectedAnswerIndex == idx) {
                      optionBorderColor = const Color(0xFF6CB6DA);
                      optionBgColor = const Color(0xFF14222B);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: _isAnswerSubmitted ? null : () => setState(() => _selectedAnswerIndex = idx),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: optionBgColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: optionBorderColor, width: 2)),
                          child: Text(optionText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }),
                  if (_isAnswerSubmitted) ...[
                    const SizedBox(height: 10),
                    Text(q.explanation, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6CB6DA), foregroundColor: Colors.black),
                    onPressed: _selectedAnswerIndex == null ? null : (_isAnswerSubmitted ? _nextQuizQuestion : _submitQuizAnswer),
                    child: Text(_isAnswerSubmitted ? "CONTINUE" : "SUBMIT ANSWER", style: const TextStyle(fontWeight: FontWeight.w900)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeOverlay() {
    final upgrades = _getUpgradeOptions().take(3).toList();
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("PROFIT CHANNELS UNLOCKED!", style: TextStyle(color: Color(0xFFE1BB72), fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: upgrades.map((up) {
                return Container(
                  width: 175,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    color: const Color(0xFF14241F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE1BB72), width: 1.5)),
                    child: InkWell(
                      onTap: () => _selectUpgrade(up),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(up.icon, color: const Color(0xFFE1BB72), size: 28),
                            const SizedBox(height: 14),
                            Text(up.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                            const SizedBox(height: 10),
                            Text(up.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isSavingAndExiting ? "SAVING DATA..." : "RUN TERMINATED", style: TextStyle(color: _isSavingAndExiting ? const Color(0xFF85EFAC) : const Color(0xFFE25C5C), fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Text("Gold Banked: +$_goldAccumulated gold", style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 32),
            if (!_isSavingAndExiting)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF85EFAC), foregroundColor: Colors.black),
                onPressed: _exitAndSyncData,
                child: const Text("BANK REWARDS & EXIT", style: TextStyle(fontWeight: FontWeight.w900)),
              )
          ],
        ),
      ),
    );
  }
}

class _Monster {
  _Monster({
    required this.pos,
    required this.hp,
    required this.maxHp,
    required this.speed,
    required this.radius,
    required this.color,
    required this.dps,
    required this.goldValue,
    this.isBoss = false,
  });

  Offset pos;
  double hp;
  double maxHp;
  double speed;
  double radius;
  Color color;
  double dps;
  int goldValue;
  bool isBoss;
}

class _Projectile {
  _Projectile({required this.pos, required this.velocity, required this.damage});
  Offset pos;
  Offset velocity;
  double damage;
}

class _Particle {
  _Particle({required this.pos, required this.velocity, required this.color, required this.life});
  Offset pos;
  Offset velocity;
  Color color;
  double life;
}

class _TreasureChest {
  _TreasureChest({required this.pos});
  final Offset pos;
}

class _BrawlPainter extends CustomPainter {
  _BrawlPainter({
    required this.playerPos,
    required this.playerRadius,
    required this.playerHp,
    required this.playerMaxHp,
    required this.monsters,
    required this.projectiles,
    required this.particles,
    required this.chests,
    required this.chestRadius,
    required this.equippedSkinId,
    required this.treePositions,
    required this.treeRadius,
    required this.rockPositions,
    required this.rockRadius,
    required this.mapWidth,
    required this.mapHeight,
    required this.camOffset,
  });

  final Offset playerPos;
  final double playerRadius;
  final int playerHp;
  final int playerMaxHp;
  final List<_Monster> monsters;
  final List<_Projectile> projectiles;
  final List<_Particle> particles;
  final List<_TreasureChest> chests;
  final double chestRadius;
  final String equippedSkinId;
  
  final List<Offset> treePositions;
  final double treeRadius;
  final List<Offset> rockPositions;
  final double rockRadius;
  final double mapWidth;
  final double mapHeight;
  final Offset camOffset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(camOffset.dx, camOffset.dy);

    canvas.drawRect(Rect.fromLTWH(0, 0, mapWidth, mapHeight), Paint()..color = const Color(0xFF1E3A2B));
    final grassPaint = Paint()..color = const Color(0xFF244433);
    for (double x = 0; x < mapWidth; x += 160) {
      for (double y = 0; y < mapHeight; y += 160) {
        canvas.drawRect(Rect.fromLTWH(x, y, 80, 80), grassPaint);
        canvas.drawRect(Rect.fromLTWH(x + 80, y + 80, 80, 80), grassPaint);
      }
    }

    canvas.drawRect(Rect.fromLTWH(0, 0, mapWidth, mapHeight), Paint()..color = const Color(0xFF9E4242)..strokeWidth = 10..style = PaintingStyle.stroke);

    final rockPaint = Paint()..color = const Color(0xFF5A635E);
    for (final rock in rockPositions) {
      canvas.drawCircle(rock, rockRadius, rockPaint);
      canvas.drawCircle(rock + const Offset(5, 3), rockRadius * 0.7, rockPaint);
    }

    final treeTrunkPaint = Paint()..color = const Color(0xFF4A2F13);
    final treeLeavesPaint = Paint()..color = const Color(0xFF165231);
    for (final tree in treePositions) {
      canvas.drawRect(Rect.fromCenter(center: tree, width: 8, height: 26), treeTrunkPaint);
      canvas.drawCircle(tree - const Offset(0, 14), treeRadius, treeLeavesPaint);
    }

    for (final m in monsters) {
      canvas.drawCircle(m.pos, m.radius, Paint()..color = m.color);

      double hpPercent = (m.hp / m.maxHp).clamp(0.0, 1.0);
      final barW = m.radius * 2.2;
      final barH = m.isBoss ? 7.0 : 4.0;
      final barLeft = m.pos.dx - (barW / 2);
      final barTop = m.pos.dy - m.radius - (m.isBoss ? 14 : 8);

      canvas.drawRect(Rect.fromLTWH(barLeft, barTop, barW, barH), Paint()..color = Colors.black45);
      canvas.drawRect(Rect.fromLTWH(barLeft, barTop, barW * hpPercent, barH), Paint()..color = m.isBoss ? const Color(0xFFFF2F55) : const Color(0xFFE25C5C));
    }

    final pPaint = Paint()..color = const Color(0xFF58C7FF);
    for (final p in projectiles) {
      canvas.drawCircle(p.pos, 5.0, pPaint);
    }

    for (final part in particles) {
      canvas.drawCircle(part.pos, 2.5, Paint()..color = part.color.withValues(alpha: (part.life / 0.22).clamp(0.0, 1.0)));
    }

    final chestPaint = Paint()..color = const Color(0xFFE1BB72);
    final chestTrimPaint = Paint()..color = const Color(0xFF8C6621);
    for (final chest in chests) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: chest.pos, width: chestRadius * 2, height: chestRadius * 1.5),
          const Radius.circular(4),
        ),
        chestPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(chest.pos.dx - chestRadius, chest.pos.dy - 2, chestRadius * 2, 4),
        chestTrimPaint,
      );
    }

    canvas.drawCircle(playerPos, playerRadius, Paint()..color = const Color(0xFF0F261D));
    canvas.drawCircle(playerPos, playerRadius, Paint()..color = const Color(0xFF85EFAC)..strokeWidth = 3.0..style = PaintingStyle.stroke);

    final textPainter = TextPainter(
      text: TextSpan(text: equippedSkinId.isNotEmpty ? equippedSkinId.characters.first.toUpperCase() : 'B', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, playerPos - Offset(textPainter.width / 2, textPainter.height / 2));

    double playerHpPercent = (playerHp / playerMaxHp).clamp(0.0, 1.0);
    final pBarW = 68.0;
    final pBarH = 6.0;
    canvas.drawRect(Rect.fromLTWH(playerPos.dx - (pBarW / 2), playerPos.dy + playerRadius + 10, pBarW, pBarH), Paint()..color = Colors.black87);
    canvas.drawRect(Rect.fromLTWH(playerPos.dx - (pBarW / 2), playerPos.dy + playerRadius + 10, pBarW * playerHpPercent, pBarH), Paint()..color = const Color(0xFF85EFAC));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrawlPainter oldDelegate) => true;
}