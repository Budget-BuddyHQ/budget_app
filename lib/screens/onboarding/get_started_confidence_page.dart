// lib/screens/get_started_confidence_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../Gameplay/main_game_screen.dart';

class TurtleThumbShape extends SliderComponentShape {
  final double thumbRadius;

  const TurtleThumbShape({this.thumbRadius = 14});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    final rect = Rect.fromCenter(
      center: center,
      width: thumbRadius * 2,
      height: thumbRadius * 2,
    );

    final paint = Paint()..color = Colors.transparent;
    canvas.drawRect(rect, paint);

    final image = AssetImage('assets/images/logo.png');

    final imageStream = image.resolve(ImageConfiguration.empty);
    imageStream.addListener(
      ImageStreamListener((imageInfo, _) {
        final img = imageInfo.image;

        paintImage(
          canvas: canvas,
          rect: rect,
          image: img,
          fit: BoxFit.contain,
        );
      }),
    );
  }
}


class GetStartedConfidencePage extends StatefulWidget {
  const GetStartedConfidencePage({super.key});

  @override
  State<GetStartedConfidencePage> createState() =>
      _GetStartedConfidencePageState();
}

class _GetStartedConfidencePageState extends State<GetStartedConfidencePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  static const Color deepForest = Color(0xFF1B3329);
  static const Color forestGreen = Color(0xFF2E4A3D);
  static const Color darkGreen = Color(0xFF0F2018);
  static const Color limeAccent = Color(0xFF76FF03);

  double _confidenceValue = 2.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainGameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(opacity: curve, child: child);
        },
      ),
    );
  }

  String get _confidenceLabel {
    if (_confidenceValue <= 1) return 'Just getting started';
    if (_confidenceValue <= 2) return 'Still learning';
    if (_confidenceValue <= 3) return 'Pretty comfortable';
    if (_confidenceValue <= 4) return 'Very confident';
    return 'Money pro';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deepForest, forestGreen, darkGreen],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAnimatedItem(
                      0,
                      Center(
                        child: Container(
                          height: 92,
                          width: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                              color: limeAccent.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: limeAccent.withValues(alpha: 0.18),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: limeAccent,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildAnimatedItem(
                      1,
                      const Text(
                        'Set Your Confidence',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildAnimatedItem(
                      2,
                      Text(
                        'Help us tailor your Budget Buddy experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildAnimatedItem(
                      3,
                      FractionallySizedBox(
                        widthFactor: 0.96,
                        child: _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel(
                                'How confident do you feel with money?',
                              ),
                              const SizedBox(height: 18),

                              Text(
                                _confidenceLabel,
                                style: TextStyle(
                                  color: limeAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 14),

                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: limeAccent,
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.18),
                                  thumbColor: limeAccent,
                                  overlayColor:
                                      limeAccent.withValues(alpha: 0.18),
                                  trackHeight: 6,
                                  thumbShape: const TurtleThumbShape(),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 20,
                                  ),
                                ),
                                child: Slider(
                                  value: _confidenceValue,
                                  min: 0,
                                  max: 4,
                                  divisions: 4,
                                  onChanged: (value) {
                                    setState(() {
                                      _confidenceValue = value;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 4),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Totally new',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.72,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'I know my stuff',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.72,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildAnimatedItem(
                      4,
                      FractionallySizedBox(
                        widthFactor: 0.96,
                        child: ElevatedButton(
                          onPressed: _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: limeAccent,
                            foregroundColor: deepForest,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: limeAccent.withValues(alpha: 0.45),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildAnimatedItem(
                      5,
                      Column(
                        children: [
                          Text(
                            'You are all set! Your customized app is now ready.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(index * 0.08, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(index * 0.08, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }
}