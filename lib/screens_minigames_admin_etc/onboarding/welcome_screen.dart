import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_assets.dart';
import '../../navigation_tools_and_animation/fade_page_route.dart';
import '../auth/auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return _WelcomeBackground(progress: _floatController.value);
            },
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = math.min(constraints.maxWidth * 0.9, 520.0);
                final titleSize = math.min(constraints.maxWidth * 0.12, 40.0);

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            final offset =
                                math.sin(_floatController.value * math.pi * 2) *
                                8;
                            return Transform.translate(
                              offset: Offset(0, offset),
                              child: child,
                            );
                          },
                          child: Column(
                            children: [
                              Hero(
                                tag: 'budget-buddy-logo',
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF0C2418,
                                    ).withValues(alpha: 0.42),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF3CCB74,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 34,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    AppAssets.coolTurtle,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stack) =>
                                        const Icon(
                                          Icons.account_balance_wallet,
                                          size: 60,
                                          color: Color(0xFFB8F5D1),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'BUDGET BUDDY',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.baloo2(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        _WelcomeActionButton(
                          label: 'Join the Squad',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              FadePageRoute(
                                builder: (context) =>
                                    const AuthScreen(mode: AuthMode.signUp),
                              ),
                            );
                          },
                          primary: true,
                        ),
                        const SizedBox(height: 16),
                        _WelcomeActionButton(
                          label: 'Welcome Back',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              FadePageRoute(
                                builder: (context) =>
                                    const AuthScreen(mode: AuthMode.login),
                              ),
                            );
                          },
                          primary: false,
                        ),
                      ],
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

class _WelcomeBackground extends StatelessWidget {
  final double progress;

  const _WelcomeBackground({required this.progress});

  @override
  Widget build(BuildContext context) {
    final glowShift = (progress - 0.5) * 0.4;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.villageMapBackground,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0C2418).withValues(alpha: 0.55),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.3, -0.4 + glowShift),
                radius: 0.9,
                colors: [
                  const Color(0xFF78E08F).withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -80,
          top: 120,
          child: _GlowOrb(
            size: 220,
            color: const Color(0xFF3CCB74).withValues(alpha: 0.25),
          ),
        ),
        Positioned(
          right: -60,
          bottom: 80,
          child: _GlowOrb(
            size: 200,
            color: const Color(0xFFF4D06F).withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _WelcomeActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _WelcomeActionButton({
    required this.label,
    required this.onPressed,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final background = primary
        ? const Color(0xFF3CCB74)
        : Colors.white.withValues(alpha: 0.08);
    final textColor = primary ? const Color(0xFF0F2E1E) : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: primary ? 10 : 2,
          shadowColor: Colors.black.withValues(alpha: 0.4),
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
