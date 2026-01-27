import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';


class CoinCollectorGame extends StatefulWidget {
  const CoinCollectorGame({super.key});

  @override
  State<CoinCollectorGame> createState() => _CoinCollectorGameState();
}

class _CoinCollectorGameState extends State<CoinCollectorGame> {
  int _score = 0;
  int _timeLeft = 30;
  bool _isPlaying = false;
  Timer? _gameTimer;
  final List<Coin> _coins = [];
  final Random _random = Random();
  Timer? _coinSpawnTimer;

  @override
  void dispose() {
    _gameTimer?.cancel();
    _coinSpawnTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = 30;
      _isPlaying = true;
      _coins.clear();
    });

    // Countdown timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endGame();
        }
      });
    });

    // Spawn coins every 800ms
    _coinSpawnTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (_isPlaying && _coins.length < 12) {
        _spawnCoin();
      }
    });
  }

  void _spawnCoin() {
    setState(() {
      _coins.add(
        Coin(
          id: DateTime.now().millisecondsSinceEpoch,
          x: _random.nextDouble() * 0.8,
          y: _random.nextDouble() * 0.7,
          value: _random.nextBool() ? 1 : 5, // Random $1 or $5 coins
        ),
      );
    });
  }

  void _collectCoin(Coin coin) {
    if (_isPlaying) {
      setState(() {
        _score += coin.value;
        _coins.remove(coin);
      });
    }
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
    });
    _gameTimer?.cancel();
    _coinSpawnTimer?.cancel();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over! 🎉'),
        content: Text(
          'Your Score: \$$_score\n\n${_getScoreMessage()}',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getScoreMessage() {
    if (_score >= 50) return 'Amazing! You\'re a money master! 💰';
    if (_score >= 30) return 'Great job! Keep saving! 🌟';
    if (_score >= 15) return 'Good effort! Practice makes perfect! 👍';
    return 'Nice try! Let\'s play again! 😊';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Collector Game'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade100, Colors.orange.shade300],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Score and Time Display
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Score Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$$_score',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Timer Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.blue, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            '${_timeLeft}s',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _timeLeft <= 5 ? Colors.red : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Game Area
              Expanded(
                child: _isPlaying
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: _coins.map((coin) {
                              return Positioned(
                                left: coin.x * constraints.maxWidth,
                                top: coin.y * constraints.maxHeight,
                                child: GestureDetector(
                                  onTap: () => _collectCoin(coin),
                                  child: TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 300),
                                    builder: (context, double value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: coin.value == 5
                                                ? Colors.amber.shade400
                                                : Colors.yellow.shade600,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color.fromRGBO(0, 0, 0, 0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              '\$${coin.value}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              size: 100,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Coin Collector Challenge!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Tap coins to collect money!\n\$1 coins = 1 point\n\$5 coins = 5 points\n\nYou have 30 seconds!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _startGame,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 8,
                              ),
                              child: const Text(
                                'Start Game',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Coin model class
class Coin {
  final int id;
  final double x;
  final double y;
  final int value;

  Coin({
    required this.id,
    required this.x,
    required this.y,
    required this.value,
  });
}