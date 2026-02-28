import 'package:flutter/material.dart';
import 'dart:math' as math;

// --- State Management Placeholder ---
class _GameData {
  int shellCoins = 1250;
  int kingdomLevel = 1;
}

class TownSquareScreen extends StatefulWidget {
  const TownSquareScreen({super.key});

  @override
  _TownSquareScreenState createState() => _TownSquareScreenState();
}

// 3. Technical Fix: Use TickerProviderStateMixin for multiple animations
class _TownSquareScreenState extends State<TownSquareScreen>
    with TickerProviderStateMixin {
  final _GameData _gameData = _GameData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 2. The Ground: Tiled texture background
          _buildTiledBackground(),

          // The Isometric UI
          Stack(
            children: [
              // Further-away items are drawn first
              _buildIsometricBuilding(
                name: "Ancient Library",
                icon: Icons.menu_book,
                baseColor: const Color(0xFFa0522d), // Sienna brown
                roofColor: const Color(0xFF8b4513), // Saddle brown
                top: 150,
                left: 30,
                onTap: () => _showSnackBar("Entering the Library for a lesson..."),
              ),
              _buildIsometricBuilding(
                name: "The Great Bank",
                icon: Icons.account_balance,
                baseColor: const Color(0xFFc0c0c0), // Silver
                roofColor: const Color(0xFFffd700), // Gold
                top: 100,
                left: MediaQuery.of(context).size.width / 2 - 60,
                isLarge: true,
                onTap: () => _showSnackBar("Visiting the Great Bank..."),
              ),
              _buildIsometricBuilding(
                name: "Bounty Board",
                icon: Icons.assignment,
                baseColor: const Color(0xFFd2b48c), // Tan
                roofColor: const Color(0xFFcd853f), // Peru
                top: 250,
                left: MediaQuery.of(context).size.width - 130,
                onTap: () => _showSnackBar("Checking the Bounty Board..."),
              ),
            ],
          ),

          // 4. Top Bar (The Stats)
          _buildTopStatsBar(),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.blueGrey.shade800,
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _buildTopStatsBar() {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Wood-grain texture simulation
          gradient: const LinearGradient(
            colors: [Color(0xFF6f4e37), Color(0xFF5a3e2b)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF4a2e1b), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Level indicator with Progress Glow
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                // Progress Glow
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Colors.yellow, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Lvl: ${_gameData.kingdomLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Shell-Coins display
            Row(
              children: [
                const Text(
                  'Shell-Coins:',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_gameData.shellCoins}',
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIsometricBuilding({
    required String name,
    required IconData icon,
    required Color baseColor,
    required Color roofColor,
    required double top,
    required double left,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final double buildingWidth = isLarge ? 120 : 90;
    final double buildingHeight = isLarge ? 100 : 70;
    final double roofHeight = 30;

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: name,
          child: SizedBox(
            width: buildingWidth,
            height: buildingHeight + roofHeight + 30, // Extra space for floating icon
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Building Base
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: buildingWidth,
                    height: buildingHeight,
                    decoration: BoxDecoration(
                      color: baseColor,
                      border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                // Building Roof
                Positioned(
                  top: 20,
                  left: -buildingWidth * 0.1,
                  child: _IsometricRoof(
                    width: buildingWidth * 1.2,
                    height: roofHeight,
                    color: roofColor,
                  ),
                ),
                 // 3. Floating Icon
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _FloatingIcon(icon: icon),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({super.key, required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: -10),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: child,
        );
      },
      child: Icon(
        icon,
        color: Colors.white.withValues(alpha: 0.9),
        size: 32,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.5),blurRadius: 8),
        ],
      ),
    );
  }
}

class _IsometricRoof extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _IsometricRoof({required this.width, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _RoofPainter(color),
    );
  }
}

class _RoofPainter extends CustomPainter {
  final Color color;
  _RoofPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height * 0.5)
      ..close();
    canvas.drawPath(path, paint);

    final Paint borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

Widget _buildTiledBackground() {
  return CustomPaint(
    painter: _TiledBackgroundPainter(),
    child: Container(),
  );
}

class _TiledBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base grass color
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF3a7d44));

    finalPaint(color, opacity) => Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Draw textured patches
    for (int i = 0; i < 50; i++) {
      final x = math.Random().nextDouble() * size.width;
      final y = math.Random().nextDouble() * size.height;
      final radius = math.Random().nextDouble() * 30 + 10;
      // Grass texture
      canvas.drawCircle(Offset(x, y), radius, finalPaint(const Color(0xFF4a8d54), 0.5));
    }
     for (int i = 0; i < 15; i++) {
      final x = math.Random().nextDouble() * size.width;
      final y = math.Random().nextDouble() * size.height;
      final radius = math.Random().nextDouble() * 10 + 5;
      // Stone clusters
      canvas.drawCircle(Offset(x, y), radius, finalPaint(Colors.grey.shade600, 0.8));
      canvas.drawCircle(Offset(x + 5, y + 5), radius * 0.8, finalPaint(Colors.grey.shade500, 0.9));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
