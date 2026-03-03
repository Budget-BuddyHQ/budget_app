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

class _TownSquareScreenState extends State<TownSquareScreen>
    with TickerProviderStateMixin {
  final _GameData _gameData = _GameData();
  late AnimationController _turtleController;

  @override
  void initState() {
    super.initState();
    // Animation for the Turtle "Breathing"
    _turtleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _turtleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3a7d44), // Fallback color
      body: Stack(
        children: [
          // 1. PERFORMANCE FIX: RepaintBoundary
          // This tells Flutter to cache this complex background as a single image.
          // It stops the "Lag" immediately.
          const RepaintBoundary(
            child: _CachedBackground(),
          ),

          // 2. The Isometric World (Scrollable for "Big World" feel)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 1.2, // Wider world
              height: MediaQuery.of(context).size.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // --- Buildings ---
                  
                  // The Library (Back Left)
                  _ProdigyBuilding(
                    top: 180,
                    left: 40,
                    label: "Library",
                    icon: Icons.auto_stories,
                    roofColor: const Color(0xFF8D6E63), // Brown
                    wallColor: const Color(0xFFD7CCC8), // Tan
                    onTap: () => _showSnackBar("Entering the Library..."),
                  ),

                  // The Bounty Board (Far Right)
                  _ProdigyBuilding(
                    top: 280,
                    left: 300,
                    label: "Quests",
                    icon: Icons.assignment_late,
                    roofColor: const Color(0xFFE65100), // Orange
                    wallColor: const Color(0xFFFFCC80), // Light Orange
                    scale: 0.8,
                    onTap: () => _showSnackBar("Checking Quests..."),
                  ),

                  // The Great Bank (Center - Main Attraction)
                  _ProdigyBuilding(
                    top: 120,
                    left: 160,
                    label: "The Bank",
                    icon: Icons.account_balance,
                    roofColor: const Color(0xFFFFD700), // Gold
                    wallColor: const Color(0xFFECEFF1), // Marble White
                    isLarge: true,
                    onTap: () => _showSnackBar("Visiting the Bank..."),
                  ),

                  // --- The Mascot (Turtle) ---
                  Positioned(
                    top: 350,
                    left: 180,
                    child: AnimatedBuilder(
                      animation: _turtleController,
                      builder: (context, child) {
                        return Transform.translate(
                          // Simple "Breathing" up/down motion
                          offset: Offset(0, _turtleController.value * 10),
                          child: child,
                        );
                      },
                      child: _buildTurtleMascot(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. UI Overlay (Top Bar)
          _buildTopStatsBar(),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 1),
    ));
  }

  Widget _buildTopStatsBar() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4E342E), // Dark Wood
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8D6E63), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Level Badge
            Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Lvl ${_gameData.kingdomLevel}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Roboto'), // Use a game font if you have one
                ),
              ],
            ),
            // Coin Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${_gameData.shellCoins}',
                    style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTurtleMascot() {
    return Column(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.greenAccent.shade400,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
               BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,5))
            ]
          ),
          child: const Center(child: Icon(Icons.mood, size: 40, color: Colors.white)),
        ),
        Container(
          margin: const EdgeInsets.only(top: 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10)
          ),
          child: const Text("You", style: TextStyle(color: Colors.white, fontSize: 10)),
        )
      ],
    );
  }
}

// --- NEW COMPONENT: 2.5D Building Block ---
class _ProdigyBuilding extends StatelessWidget {
  final double top;
  final double left;
  final String label;
  final IconData icon;
  final Color roofColor;
  final Color wallColor;
  final bool isLarge;
  final double scale;
  final VoidCallback onTap;

  const _ProdigyBuilding({
    required this.top,
    required this.left,
    required this.label,
    required this.icon,
    required this.roofColor,
    required this.wallColor,
    required this.onTap,
    this.isLarge = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    double size = isLarge ? 100 : 70;
    size = size * scale;

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            // Floating Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            
            // The Building Stack
            SizedBox(
              height: size * 1.2,
              width: size,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Shadow
                  Container(
                    height: 15,
                    width: size * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  
                  // Main Block (Wall)
                  Container(
                    height: size * 0.8,
                    width: size * 0.9,
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      color: wallColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12, width: 2),
                      boxShadow: [
                         BoxShadow(color: Colors.black26, offset: const Offset(4, 4), blurRadius: 0)
                      ]
                    ),
                    child: Center(
                      child: Icon(icon, size: size * 0.4, color: Colors.black12),
                    ),
                  ),

                  // Roof (The "3D" Pop)
                  Positioned(
                    top: 0,
                    child: Container(
                      height: size * 0.4,
                      width: size,
                      decoration: BoxDecoration(
                        color: roofColor,
                        borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.white24, width: 2),
                         boxShadow: [
                           BoxShadow(color: Colors.black26, offset: const Offset(0, 4), blurRadius: 4)
                         ]
                      ),
                      child: Center(
                        child: Icon(icon, color: Colors.white.withOpacity(0.9), size: size * 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- OPTIMIZED BACKGROUND ---
class _CachedBackground extends StatelessWidget {
  const _CachedBackground();

  @override
  Widget build(BuildContext context) {
    // We create the custom paint here once.
    return CustomPaint(
      painter: _TiledBackgroundPainter(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}

class _TiledBackgroundPainter extends CustomPainter {
  // Define positions ONCE so they don't move on repaint.
  // In a real app, pass these in via constructor.
  // For now, we use a fixed seed for 'randomness' that stays the same.

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF4CAF50); // Base Grass
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Grid Pattern (Prodigy style tiles)
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    double tileSize = 60;
    for (double x = 0; x < size.width; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Decor Elements (Fixed Seed)
    final random = math.Random(42); // FIXED SEED = No Jittering/Lag
    
    for (int i = 0; i < 20; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = const Color(0xFF388E3C)); // Dark grass tuft
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}