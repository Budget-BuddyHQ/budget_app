import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'Gameplay/town_square_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(
      FadePageRoute(
        builder: (context) => const TownSquareScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return _ParallaxBackground(progress: _bgController.value);
            },
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth =
                    math.min(constraints.maxWidth * 0.9, 520.0);
                final titleSize =
                    math.min(constraints.maxWidth * 0.12, 44.0);

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF6EE),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.account_balance_wallet,
                                            size: 54,
                                            color: Color(0xFF1B3B2A),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _RpgTitle(
                                  text: 'BUDGET BUDDY',
                                  fontSize: titleSize,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Your forest of financial mastery awaits.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Flexible(
                            flex: 2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Gold Saved',
                                    value: '1,250',
                                    icon: Icons.savings,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Current Level',
                                    value: '7',
                                    icon: Icons.shield,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Flexible(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GlowingGameButton(
                                  label: 'Start Game',
                                  onPressed: _startGame,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Press to enter the Town Square',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Text(
                                'Tip: Every lesson completed strengthens your kingdom.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 12,
                                ),
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
        ],
      ),
    );
  }
}

class FadePageRoute<T> extends MaterialPageRoute<T> {
  FadePageRoute({required super.builder});

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    return FadeTransition(opacity: curve, child: child);
  }
}

class _ParallaxBackground extends StatelessWidget {
  final double progress;

  const _ParallaxBackground({required this.progress});

  @override
  Widget build(BuildContext context) {
    final shift = (progress - 0.5) * 40;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F2E1E),
                Color(0xFF1E4D3D),
                Color(0xFF1B3329),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, shift),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: CustomPaint(
              painter: _MapHintPainter(progress: progress),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.2, -0.4),
                radius: 1.0,
                colors: [
                  const Color(0xFF59C173).withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapHintPainter extends CustomPainter {
  final double progress;

  _MapHintPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF8CCF9A).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final dotPaint = Paint()
      ..color = const Color(0xFFE0F7E8).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final tile = 90.0;
    final offset = progress * tile;

    for (double x = -size.height; x < size.width + size.height; x += tile) {
      final start = Offset(x - offset, -size.height);
      final end = Offset(x + size.height - offset, size.height * 2);
      canvas.drawLine(start, end, linePaint);

      final start2 = Offset(x - offset, size.height * 2);
      final end2 = Offset(x + size.height - offset, -size.height);
      canvas.drawLine(start2, end2, linePaint);
    }

    for (double y = 80; y < size.height; y += 140) {
      for (double x = 60; x < size.width; x += 160) {
        final jitter = math.sin(progress * math.pi * 2 + x * 0.01) * 6;
        canvas.drawCircle(Offset(x + jitter, y), 6, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapHintPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _RpgTitle extends StatelessWidget {
  final String text;
  final double fontSize;

  const _RpgTitle({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            fontFamily: 'Baloo2',
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black.withValues(alpha: 0.85),
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            fontFamily: 'Baloo2',
            color: const Color(0xFFEAF6EE),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFBFFFD2), size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class GlowingGameButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const GlowingGameButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  State<GlowingGameButton> createState() => _GlowingGameButtonState();
}

class _GlowingGameButtonState extends State<GlowingGameButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _updateGlow() {
    if (_hovered || _pressed) {
      if (!_glowController.isAnimating) {
        _glowController.repeat(reverse: true);
      }
    } else {
      _glowController.stop();
      _glowController.value = 0;
    }
  }

  void _setHover(bool value) {
    if (_hovered == value) return;
    setState(() {
      _hovered = value;
    });
    _updateGlow();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
    _updateGlow();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = _glowController.value;
        final pressOffset = _pressed ? 4.0 : 0.0;
        final glowColor =
            const Color(0xFF9CFF7A).withValues(alpha: 0.25 + glow * 0.35);

        return MouseRegion(
          onEnter: (_) => _setHover(true),
          onExit: (_) => _setHover(false),
          child: GestureDetector(
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.onPressed,
            child: SizedBox(
              height: 58,
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E6C3A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOut,
                    transform: Matrix4.translationValues(0, pressOffset, 0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF3CCB74),
                          Color(0xFF2E9F5C),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor,
                          blurRadius: 18 + glow * 10,
                          spreadRadius: 1 + glow * 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
